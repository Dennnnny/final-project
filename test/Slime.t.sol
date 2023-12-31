// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/nft/slime/Slime.sol";
import "../src/erc20/SlimeToken.sol";

contract SlimeTest is Test {
    Slime slime;
    UpgradeToken upgradeToken;
    SlimeToken slimeToken;
    address user = makeAddr("user");
    address mintedUser = makeAddr("mintedUser");
    address anotherUser = makeAddr("anotherUser");

    function setUp() public {
        slime = new Slime();
        upgradeToken = slime.upgradeToken();
        slimeToken = slime.slimeToken();
    }

    function mintSlimeToUser() public {
        // give user a tokenId=0 with level=0
        upgradeToken.doMint(user, 0, 0);

        // create a slime to user
        vm.startPrank(user);
        slime.mintOneSlime();

        assertEq(slime.balanceOf(user), 1);
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

        // mint with paid => success
        deal(user, 3 ether);
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

        // test upgrade:
        // before upgrade 
        assertEq(slime.tokenURI(0), "0");

        deal(address(slimeToken), user, 2 ether);

        assertEq(slimeToken.balanceOf(user), 2 ether);

        slime.upgrade(0, 2 ether, 0);

        assertEq(slime.getSlimeLevel(0), 1);

        assertEq(slime.tokenURI(0), Strings.toString(upgradeToken.getUpgradeTypes(0)));
    }

    function testUpgradeWithRevert() public {
        mintSlimeToUser();

        // 
        vm.expectRevert("you don't have enough token, go earning some.");
        slime.upgrade(0, 2 ether, 0);

        // 
        deal(address(slimeToken), user, 2 ether);
        vm.expectRevert("you need to put more token to upgrade now.");
        slime.upgrade(0, 1 ether, 0);

        //
        deal(address(slimeToken), anotherUser, 2 ether);
        vm.startPrank(anotherUser);
        vm.expectRevert("you don't own this upgrade nft.");
        slime.upgrade(0, 2 ether, 0);
        vm.stopPrank();

        //
        vm.startPrank(user);
        slime.missionCompleted(1, 2 ether, true);
        vm.expectRevert("upgrade token level should have same level as your slime.");
        slime.upgrade(0, 2 ether, 1);
        
    }
}

contract UpgradeNftTest is Test {
    UpgradeToken upgradeToken;

    address user = makeAddr("user");

    function setUp() public {
        upgradeToken = new UpgradeToken();
    }

    function testNFTBasic() public {
        assertEq(upgradeToken.name(), "Upgrade Sliime");
    }

    function testMint() public {
        vm.startPrank(user);

        upgradeToken.doMint(address(user), 0, 0);

        assertEq(upgradeToken.balanceOf(user), 1);

        assertLe(upgradeToken.getUpgradeTypes(0), 3);
    }

    function testBurn() public {
        vm.startPrank(user);

        upgradeToken.doMint(address(user), 0, 0);

        upgradeToken.doBurn(0);

        vm.expectRevert(); // revert: did not exist
        upgradeToken.ownerOf(0);
    }

}
