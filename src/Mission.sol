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

  uint256 constant CURRENT_MISSION_AMOUNT = 2;
  MissionType[CURRENT_MISSION_AMOUNT] public missionList;
  Slime slime;
  mapping(uint256 => mapping(address => bool)) public attendMissionList;

  constructor(address _slimeAddr) {
    slime = Slime(_slimeAddr);
    missionList[0] = MissionType(0, MissionCate.Level, 1, 0);
    missionList[1] = MissionType(1, MissionCate.Amount, 1, 1);
  }

  function getTotalMissions() public view returns (uint256) {
    return missionList.length;
  }

  function checkUserAttended(uint256 _missionId, address attender) public returns (bool) {
    return attendMissionList[_missionId][attender];
  }

  function attendMission(uint256 _missionId, address attender) public {
    require(_missionId < CURRENT_MISSION_AMOUNT, "missionId is not exist yet.");
    attendMissionList[_missionId][attender] = true;
  } 

  function checkMissionCompleted( address attender, uint256 _missionId, uint256 _slimeTokenId) public returns (bool, uint256) {
    require(attendMissionList[_missionId][attender], "you need to attend mission first.");
    MissionCate missionCategory = missionList[_missionId].cate;

    if(missionCategory == MissionCate.Level) {
      require(Slime(slime).getSlimeLevel(_slimeTokenId) >= missionList[_missionId].completedCondition, "slime's level is not enough.");
      return (true, missionList[_missionId].rewardLevel);
    }
    if(missionCategory == MissionCate.Amount){
      require(Slime(slime).balanceOf(attender) >= missionList[_missionId].completedCondition, "slime's amount is not enough.");
      return (true, missionList[_missionId].rewardLevel);
    }
  }
}
