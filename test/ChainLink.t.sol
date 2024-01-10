// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Mission.sol";
import "../src/ChainlinkVRF.sol";
import "../src/nft/slime/Slime.sol";
import "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract ChainLinkTest is Test {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    
    VRFCoordinatorV2Mock mock;
    ChainlinkVRF chainlink;

    address user = makeAddr("user");

    function setUp() public {
        vm.prank(address(this));
        mock = new VRFCoordinatorV2Mock(100000000000000000,1000000000);
        vm.prank(address(this));
        (uint64 subId) = mock.createSubscription();

        chainlink = new ChainlinkVRF( user,  subId,  address(mock));
        vm.prank(address(this));
        mock.addConsumer(subId, address(chainlink));
        mock.fundSubscription(subId, 100000 ether);
    }

    function testRequestRandomWords() public {
        vm.expectEmit();
        emit RequestSent(1,1);
        vm.prank(user);
        assertEq(chainlink.requestRandomWords(), 1);
        assertEq(chainlink.requestIds(0), 1);
        assertEq(chainlink.lastRequestId(), 1);
        vm.prank(user);
        assertEq(chainlink.requestRandomWords(), 2);
        assertEq(chainlink.requestIds(1), 2);
        assertEq(chainlink.lastRequestId(), 2);

        vm.expectRevert("Only callable by owner");
        chainlink.requestRandomWords();
    }

	function testFulfill() public {
		assertEq(chainlink.randomNum(), 0);
		vm.prank(user);
		assertEq(chainlink.requestRandomWords(), 1);
		vm.prank(user);
		mock.fulfillRandomWords(1, address(chainlink));
		assertGt(chainlink.randomNum(), 0);

		(bool fulfill, uint256[] memory randNum) = chainlink.getRequestStatus(1);
		assertEq(fulfill, true);
		assertEq(randNum[0], chainlink.randomNum());

	}
}
