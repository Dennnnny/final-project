// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/nft/slime/Slime.sol";

contract SlimeTest is Test {
    Slime slime;
    address user = makeAddr("user");
    address mintedUser = makeAddr("mintedUser");

    function setUp() public {
        slime = new Slime();
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
