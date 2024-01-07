// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // ERC721
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // ERC721Enumerable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // ERC721URIStorage
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../src/erc20/SlimeToken.sol"; // self made token
import "../upgrade/Upgrade.sol"; // upgrade nft
import "../../Mission.sol";

contract Slime is ERC721Enumerable, Ownable, ReentrancyGuard {
    mapping(address => uint256) public mintTimes;
    mapping(uint => SlimeData) public slimeTypes;
    mapping(address => Task) public slimeTasks;
    uint public slimeTokenId;
    uint constant MINT_FEE = 1e15;
    uint constant DEFAUL_TOKEN_NEED = 1e18;
    uint constant MINIMUM_BLOCK_TIME = 120; // 120 = 30min
    uint constant PROFIT_RATE = 1e15;
    uint constant MAX_PROFIT_PER_TIME = 1e18;

    mapping(uint256 => mapping(address => bool)) public attendedMission;

    UpgradeToken public upgradeToken = new UpgradeToken(address(this));
    SlimeToken public slimeToken = new SlimeToken(address(this));
    Mission public mission = new Mission(address(this));

    struct SlimeData {
        uint types;
        uint tokenNeed;
        uint level;
    }

    struct Task {
        bool isOnTheAdventure;
        uint leaveAt;
    }

    modifier isSlimeOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender,"you are not owner.");
        _;
    }

    constructor() ERC721("A Slime NFT", "SlimeT") Ownable(msg.sender) {}

    function mintOneSlime() public payable nonReentrant {
        slimeTokenId = totalSupply();
        if (msg.value == 0) {
            require(mintTimes[msg.sender] == 0, "Free mint only for the very first time.");
            _safeMint(msg.sender, slimeTokenId);
        } else {
            require(msg.value >= MINT_FEE, "at least 0.001 ether to mint new one.");
            require(mintTimes[msg.sender] < 3,"You can not mint more than three times in one address.");

            _safeMint(msg.sender, slimeTokenId);
        }
        slimeTypes[slimeTokenId] = SlimeData(0, DEFAUL_TOKEN_NEED, 0);
        mintTimes[msg.sender] += 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint path = this.getSlimeTypes(_tokenId);

        return string(abi.encodePacked("https://ipfs.io/ipfs/QmUFa7YuvhFDEB1oxUgBUVvsFLrC25xASwBZmpF5cEQzxX/", Strings.toString(path), ".png")); // redirect by different types
    }

    function getSlimeLevel(uint256 _tokenId) public view returns (uint256) {
        return slimeTypes[_tokenId].level;
    }

    function getSlimeTypes(uint256 _tokenId) public view returns (uint256) {
        return slimeTypes[_tokenId].types;
    }

    function canSlimeGoAdventure() public view returns (bool) {
        return !slimeTasks[msg.sender].isOnTheAdventure;
    }

    function getSlimeLeaveAt() public view returns (uint256) {
        return slimeTasks[msg.sender].leaveAt;
    }

    function upgrade(uint256 _tokenId, uint256 slimeTokenAmount, uint256 upgradeTokenId) isSlimeOwner(_tokenId) external {
        // 先檢查這個 user 的餘額足夠嗎
        require(slimeToken.balanceOf(msg.sender) >= slimeTokenAmount, "you don't have enough token, go earning some.");
       
        // 這裡要用 這個tokenId 的資料結構來判斷需要多少$$
        require(slimeTokenAmount > slimeTypes[_tokenId].tokenNeed, "you need to put more token to upgrade now.");
       
        // 判斷道具是不是屬於他ㄉ
        require(msg.sender == upgradeToken.ownerOf(upgradeTokenId), "you don't own this upgrade nft.");

        // 判斷升級道具 level 是否跟 史萊姆的等級是相同 match
        require(upgradeToken.getUpgradeLevel(upgradeTokenId) == getSlimeLevel(_tokenId) ,"upgrade token level should have same level as your slime.");

        // upgrade 這個 slime 的路徑 與 升級所需的 token 數量
        slimeTypes[_tokenId].tokenNeed = slimeTypes[_tokenId].tokenNeed * 2;

        slimeTypes[_tokenId].types = upgradeToken.getUpgradeTypes(upgradeTokenId) + slimeTypes[_tokenId].types;

        slimeTypes[_tokenId].level = slimeTypes[_tokenId].level + 1;

        // pass 檢查後： burn and upgrade
        upgradeToken.doBurn(upgradeTokenId);
        slimeToken.doBurn(msg.sender, slimeTokenAmount);
    }

    function claimRewards(uint256 slimeTokenAmount, uint256 taskLevel, bool ableToGetUpgradeNft) internal {
        // mint a upgrade token
        slimeToken.doMint(msg.sender, slimeTokenAmount);

        if (ableToGetUpgradeNft) {
            upgradeToken.doMint(msg.sender, upgradeToken.totalSupply(), taskLevel);
        }
    }

    function goAdventrue() public {
        require(balanceOf(msg.sender) > 0, "you need at least one slime to go adventure.");
        require(canSlimeGoAdventure(),"slimes are already on the adventure.");

        slimeTasks[msg.sender].isOnTheAdventure = true;
        slimeTasks[msg.sender].leaveAt = block.timestamp;
    }

    function returnWithRewards() public {
        require(!canSlimeGoAdventure(),"your slimes are not going out.");

        require(block.timestamp > getSlimeLeaveAt() + MINIMUM_BLOCK_TIME, "slime will go out at least 30 minutes.");

        uint256 times = block.timestamp - getSlimeLeaveAt();

        uint256 originProfit = times * PROFIT_RATE * balanceOf(msg.sender);

        uint256 profitAmount = originProfit > MAX_PROFIT_PER_TIME ? MAX_PROFIT_PER_TIME : originProfit;

        slimeToken.doMint(msg.sender, profitAmount);
    }

    function attendMission(uint256 _missionId) public {
        require(!mission.checkUserAttended(_missionId, msg.sender), "you already attend this mission.");
        mission.attendMission(_missionId, msg.sender);
    }

    function completeMission(uint256 _missionId, uint256 _slimeTokenId) public {
        (bool completed, uint256 rewardLevel) = mission.checkMissionCompleted(msg.sender, _missionId, _slimeTokenId);
        require(completed, "mission is not completed.");
        uint256 rewardAmount = (1 + rewardLevel) * 1 ether;
        claimRewards(rewardAmount, rewardLevel, true);
    }

   
}
