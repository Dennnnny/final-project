// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Mission.sol";
import "../src/nft/slime/Slime.sol";

contract MissionTest is Test {
    Mission mission;
    Slime slime = new Slime();

    address user = makeAddr("user");

    function setUp() public {
        mission = new Mission(address(slime));
    }

    function testBasicMission() public {
      assertEq(mission.getTotalMissions(), 2);
    }

    function testUserAttendMission() public {
      vm.startPrank(user);
      mission.attendMission(0);
      assertEq(mission.checkUserAttended(0), true);
    }

    function testUserAttendMission_1_AndCompleted() public {
      vm.startPrank(user);
      assertEq(slime.balanceOf(user), 0);
      slime.mintOneSlime();
      assertEq(slime.balanceOf(user), 1);

      vm.expectRevert("you need to attend mission first.");
      mission.checkMissionCompleted(1, 0);

      mission.attendMission(1);
      (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(1, 0);

      assertEq(completed, true);
      assertEq(rewardLevel, 1);
    }

    function testCheckMissionCompletedRevert() public {
      vm.startPrank(user);
      {
        mission.attendMission(0);
        vm.expectRevert("slime's level is not enough.");
        (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(0, 0);
      }
      {
        mission.attendMission(1);
        vm.expectRevert("slime's amount is not enough.");
        (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(1, 0);
      }
      {
        vm.expectRevert("missionId is not exist yet.");
        mission.attendMission(2);
      }
    }


}
