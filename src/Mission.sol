// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./nft/slime/Slime.sol";

contract Mission {

  enum MissionCate {
    Level,
    Amount
  }

  struct MissionType {
    uint256 missionId;
    MissionCate cate;
    uint256 completedCondition;
    uint256 rewardLevel;
  }

  MissionType[2] public missionList;
  Slime slime;
  mapping(uint256 => mapping(address => bool)) public attendMissionList;

  constructor(address _slimeAddr) {
    slime = Slime(_slimeAddr);
    missionList[0] = MissionType(0, MissionCate.Level, 1, 0);
    missionList[1] = MissionType(1, MissionCate.Amount, 1, 1);
  }

  function checkUserAttended(uint256 _missionId) public returns (bool) {
    return attendMissionList[_missionId][msg.sender];
  }

  function attendMission(uint256 _missionId) public {
    attendMissionList[_missionId][msg.sender] = true;
  } 

  function checkMissionCompleted(uint256 _missionId, uint256 _slimeTokenId) public returns (bool, uint256) {
    require(attendMissionList[_missionId][msg.sender], "you need to attend mission first");

    MissionCate missionCategory = missionList[_missionId].cate;

    if(missionCategory == MissionCate.Level) {
      require(Slime(slime).getSlimeLevel(_slimeTokenId) >= missionList[_missionId].completedCondition, "slime's level is not enough.");
      return (true, missionList[_missionId].rewardLevel);
    }else if(missionCategory == MissionCate.Amount){
      require(Slime(slime).balanceOf(msg.sender) >= missionList[_missionId].completedCondition, "slime's amount is not enough.");
      return (true, missionList[_missionId].rewardLevel);
    }else {
      revert("sorry, mission category is not exist.");
      return (false, 0);
    }
  }
}
