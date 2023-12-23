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
        vm.expectRevert("Free mint only for the very first time");
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
            "You can not mint more than three times in one address"
        );
        slime.mintOneSlime{value: 1 ether}();
    }
}
