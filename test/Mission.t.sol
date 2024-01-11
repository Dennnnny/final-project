// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Mission.sol";
import "../src/nft/slime/Slime.sol";
import "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract MissionTest is Test {
    Mission mission;
    Slime slime; 
    VRFCoordinatorV2Mock mock;

    address user = makeAddr("user");

    function setUp() public {
        vm.prank(address(this));
        mock = new VRFCoordinatorV2Mock(100000000000000000,1000000000);
        vm.prank(address(this));
        (uint64 subId) = mock.createSubscription();

        slime = new Slime(subId, address(mock));
        mission = new Mission(address(slime));
    }

    function testBasicMission() public {
      assertEq(mission.getTotalMissions(), 2);
    }

    function testUserAttendMission() public {
      vm.startPrank(user);
      mission.attendMission(0, user);
      assertEq(mission.checkUserAttended(0, user), true);
      vm.stopPrank();
    }

    function testUserAttendMission_1_AndCompleted() public {
      vm.startPrank(user);
      assertEq(slime.balanceOf(user), 0);
      slime.mintOneSlime();
      assertEq(slime.balanceOf(user), 1);

      vm.expectRevert("you need to attend mission first.");
      mission.checkMissionCompleted(user, 1, 0);

      mission.attendMission(1, user);
      (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(user, 1, 0);

      assertEq(completed, true);
      assertEq(rewardLevel, 1);
      vm.stopPrank();
    }

    function testCheckMissionCompletedRevert() public {
      vm.startPrank(user);
      {
        mission.attendMission(0, user);
        vm.expectRevert("slime's level is not enough.");
        (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(user, 0, 0);
      }
      {
        mission.attendMission(1, user);
        vm.expectRevert("slime's amount is not enough.");
        (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(user, 1, 0);
      }
      {
        vm.expectRevert("missionId is not exist yet.");
        mission.attendMission(2, user);
      }
      vm.stopPrank();
    }


}
