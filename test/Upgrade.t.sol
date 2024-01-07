// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/nft/upgrade/Upgrade.sol";

contract UpgradeNftTest is Test {
    UpgradeToken upgradeToken;

    address admin = makeAddr("admin");
    address user = makeAddr("user");

    function setUp() public {
        upgradeToken = new UpgradeToken(admin);
    }

    function testNFTBasic() public {
        assertEq(upgradeToken.name(), "Upgrade Sliime");
    }

    function testMint() public {
        vm.startPrank(admin);
        upgradeToken.doMint(address(user), 0, 0);
        vm.stopPrank();

        vm.startPrank(user);

        assertEq(upgradeToken.balanceOf(user), 1);

        assertLe(upgradeToken.getUpgradeTypes(0), 3);
    }

    function testBurn() public {
        vm.startPrank(admin);
        upgradeToken.doMint(address(user), 0, 0);

        upgradeToken.doBurn(0);

        vm.expectRevert(); // revert: did not exist
        upgradeToken.ownerOf(0);
    }

    function testTokenURI() public {
        vm.startPrank(admin);
        upgradeToken.doMint(address(user), 0, 0);
        upgradeToken.doMint(address(user), 1, 1);
        upgradeToken.doMint(address(user), 2, 2);
        vm.stopPrank();

        assertEq(upgradeToken.tokenURI(0), string(abi.encodePacked("https://ipfs.io/ipfs/QmQ8H1KoFRQDe12VHerrf9GmGdcpyMmuKcoAERefnm6ZXm/", Strings.toString(upgradeToken.getUpgradeTypes(0)), ".png")));
        assertEq(upgradeToken.tokenURI(1), string(abi.encodePacked("https://ipfs.io/ipfs/QmQ8H1KoFRQDe12VHerrf9GmGdcpyMmuKcoAERefnm6ZXm/", Strings.toString(upgradeToken.getUpgradeTypes(1)), ".png")));
        assertEq(upgradeToken.tokenURI(2), string(abi.encodePacked("https://ipfs.io/ipfs/QmQ8H1KoFRQDe12VHerrf9GmGdcpyMmuKcoAERefnm6ZXm/", Strings.toString(upgradeToken.getUpgradeTypes(2)), ".png")));
    }

    function testGetUpgradeLevels() public {
        vm.startPrank(admin);
        upgradeToken.doMint(address(user), 0, 1);
        upgradeToken.doMint(address(user), 1, 2);
        upgradeToken.doMint(address(user), 2, 4);
        upgradeToken.doMint(address(user), 3, 10);
        vm.stopPrank();

        assertEq(upgradeToken.getUpgradeLevel(2), 4);
        assertEq(upgradeToken.getUpgradeLevel(3), 10);
    }

}
