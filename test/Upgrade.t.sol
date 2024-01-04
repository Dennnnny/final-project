// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/nft/upgrade/Upgrade.sol";

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
