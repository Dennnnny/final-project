// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/nft/slime/Slime.sol";
import "../src/erc20/SlimeToken.sol";
import "../src/Mission.sol";
import "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract SlimeTest is Test {
    Slime slime;
    UpgradeToken upgradeToken;
    SlimeToken slimeToken;
    Mission mission;
    VRFCoordinatorV2Mock mock;
    address user = makeAddr("user");
    address mintedUser = makeAddr("mintedUser");
    address anotherUser = makeAddr("anotherUser");
    address admin;
    address owner = makeAddr("owner");

    function setUp() public {
        vm.prank(address(this));
        mock = new VRFCoordinatorV2Mock(100000000000000000,1000000000);
        vm.prank(address(this));
        (uint64 subId) = mock.createSubscription();
        
        slime = new Slime(subId, address(mock));
        admin = address(slime);

        vm.prank(address(this));
        mock.addConsumer(subId, address(slime.chainlink()));
        mock.fundSubscription(subId, 100000 ether);

        upgradeToken = slime.upgradeToken();
        slimeToken = slime.slimeToken();
        mission = slime.mission();
    }

    function mintSlimeToUser() public {
        // give user a tokenId=0 with level=0
        // create a slime to user
        vm.startPrank(user);
        slime.mintOneSlime();

        assertEq(slime.balanceOf(user), 1);
        vm.stopPrank();
    }

    function testNFTBasic() public {
        assertEq(slime.name(), "A Slime NFT");
    }

    function testUserMint() public {
        vm.startPrank(user);

        // first mint, will pass
        slime.mintOneSlime();

        assertEq(slime.mintTimes(user), 1);

        // second mint without pay => revert
        vm.expectRevert("Free mint only for the very first time.");
        slime.mintOneSlime();

        deal(user, 3 ether);

        vm.expectRevert("at least 0.001 ether to mint new one.");
        slime.mintOneSlime{value: 0.0001 ether}();

        // mint with paid => success
        slime.mintOneSlime{value: 1 ether}();

        assertEq(slime.mintTimes(user), 2);

        // mint third times should pass too
        slime.mintOneSlime{value: 1 ether}();

        assertEq(slime.mintTimes(user), 3);

        // mint fourth time fail!
        vm.expectRevert(
            "You can not mint more than three times in one address."
        );
        slime.mintOneSlime{value: 1 ether}();
    }

    function testUpgradeSlime() public {
        mintSlimeToUser();

        vm.prank(admin);
        upgradeToken.doMint(user, 0, 0);

        // test upgrade:
        // before upgrade 
        vm.startPrank(user);
        assertEq(slime.tokenURI(0), "https://ipfs.io/ipfs/QmUFa7YuvhFDEB1oxUgBUVvsFLrC25xASwBZmpF5cEQzxX/0.png");

        deal(address(slimeToken), user, 2 ether);

        assertEq(slimeToken.balanceOf(user), 2 ether);

        slime.upgrade(0, 2 ether, 0);

        assertEq(slime.getSlimeLevel(0), 1);

        assertEq(slime.tokenURI(0), string(abi.encodePacked("https://ipfs.io/ipfs/QmUFa7YuvhFDEB1oxUgBUVvsFLrC25xASwBZmpF5cEQzxX/", Strings.toString(upgradeToken.getUpgradeTypes(0)), ".png")));
    }

    function testUpgradeWithRevert() public {
        mintSlimeToUser();

        vm.prank(admin);
        upgradeToken.doMint(user, 0, 0);

        vm.startPrank(user);
        vm.expectRevert("you don't have enough token, go earning some.");
        slime.upgrade(0, 2 ether, 0);

        // 
        deal(address(slimeToken), user, 2 ether);
        vm.expectRevert("you need to put more token to upgrade now.");
        slime.upgrade(0, 1 ether, 0);

        //
        deal(address(slimeToken), anotherUser, 2 ether);
        vm.startPrank(anotherUser);
        vm.expectRevert("you are not owner.");
        slime.upgrade(0, 2 ether, 0);
        vm.stopPrank();

        vm.startPrank(anotherUser);
        slime.mintOneSlime();
        vm.stopPrank();

        vm.prank(admin);
        upgradeToken.doMint(anotherUser, 1, 0);

        vm.startPrank(user);
        vm.expectRevert("you don't own this upgrade nft.");
        slime.upgrade(0, 2 ether, 1);
        vm.stopPrank();
        
    }
    
    function testGoAdventrue() public {
        vm.expectRevert("you need at least one slime to go adventure.");
        slime.goAdventrue();

        mintSlimeToUser();

        vm.startPrank(user);
        assertEq(slime.canSlimeGoAdventure(), true);
        assertEq(slime.getSlimeLeaveAt(), 0);

        slime.goAdventrue();

        assertEq(slime.canSlimeGoAdventure(), false);
        assertEq(slime.getSlimeLeaveAt(), block.timestamp);

        vm.expectRevert("slimes are already on the adventure.");
        slime.goAdventrue();
        vm.stopPrank();
    }

    function testReturnWithRewards() public {
        vm.expectRevert("your slimes are not going out.");
        slime.returnWithRewards();

        uint256 postSlimeTokenBalance = slimeToken.balanceOf(user);
        uint256 postUpgradeTokenBalance = upgradeToken.balanceOf(user);
        mintSlimeToUser();
        vm.startPrank(user);
        slime.goAdventrue();

        vm.expectRevert("slime will go out at least 30 minutes.");
        slime.returnWithRewards();

        vm.warp(block.timestamp + 1000);

        slime.requestRandomNumber();
        mock.fulfillRandomWords(1, address(slime.chainlink()));
        // in test case this will be great

        slime.returnWithRewards();
        assertGt( slimeToken.balanceOf(user), postSlimeTokenBalance);
        assertGt( upgradeToken.balanceOf(user), postUpgradeTokenBalance);
        vm.stopPrank();
    }

    function testReturnRewardWithWorstSituation() public {

        vm.prank(user);
        (bool success) = slimeToken.approve(address(slime), 10 ether);
        deal(address(slimeToken), user, 10 ether);
        uint256 postSlimeTokenBalance = slimeToken.balanceOf(user);

        mintSlimeToUser();
        vm.startPrank(user);
        slime.goAdventrue();

        vm.expectRevert("slime will go out at least 30 minutes.");
        slime.returnWithRewards();

        vm.warp(block.timestamp + 1000);

        slime.requestRandomNumber();
        mock.fulfillRandomWords(1, address(slime.chainlink()));
        slime.requestRandomNumber();
        mock.fulfillRandomWords(2, address(slime.chainlink()));
        // in test case this will be worst

        slime.returnWithRewards();
        assertLt( slimeToken.balanceOf(user), postSlimeTokenBalance);
        vm.stopPrank();
    }

    function testReturnRewardWithGoodSituation() public {
        uint256 postSlimeTokenBalance = slimeToken.balanceOf(user);
        uint256 postUpgradeTokenBalance = upgradeToken.balanceOf(user);

        mintSlimeToUser();
        vm.startPrank(user);
        slime.goAdventrue();

        vm.expectRevert("slime will go out at least 30 minutes.");
        slime.returnWithRewards();

        vm.warp(block.timestamp + 1000);

        slime.requestRandomNumber();
        slime.requestRandomNumber();
        slime.requestRandomNumber();
        mock.fulfillRandomWords(3, address(slime.chainlink()));
        // in test case this will be gooood

        slime.returnWithRewards();
        assertGt( slimeToken.balanceOf(user), postSlimeTokenBalance);
        assertEq( upgradeToken.balanceOf(user), postUpgradeTokenBalance);
        vm.stopPrank();

    }

    function testRequestRandomNumber() public {
        slime.requestRandomNumber();
    }
    

    function testAttendMission() public {
        vm.startPrank(user);
        slime.attendMission(0);

        assertEq(slime.mission().checkUserAttended(0, user), true);

        vm.expectRevert("you already attend this mission.");
        slime.attendMission(0);
    }

    function testMissionCompleted() public {
        uint256 postUpgradeTokenBalance = upgradeToken.balanceOf(user);
        uint256 postSlimeTokenBalance = slimeToken.balanceOf(user);

        mintSlimeToUser();
        vm.startPrank(user);
        slime.attendMission(1);

        slime.completeMission(1,0);

        assertGt(upgradeToken.balanceOf(user), postUpgradeTokenBalance);
        assertGt(slimeToken.balanceOf(user), postSlimeTokenBalance);
    }
}
