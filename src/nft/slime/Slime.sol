// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // ERC721
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // ERC721Enumerable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // ERC721URIStorage
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../src/erc20/SlimeToken.sol"; // self made token
import "../upgrade/Upgrade.sol"; // upgrade nft

// this one should be an erc721
contract Slime is ERC721Enumerable, Ownable, ReentrancyGuard {
    mapping(address => uint256) public mintTimes;
    mapping(uint => SlimeData) public slimeTypes;
    mapping(address => Task) public slimeTasks;
    uint public slimeTokenId;
    uint constant DEFAUL_TOKEN_NEED = 1e18;
    uint constant MINIMUM_BLOCK_TIME = 120; // 120 = 30min
    uint constant PROFIT_RATE = 1e15;
    uint constant MAX_PROFIT_PER_TIME = 1e18;

    UpgradeToken public upgradeToken = new UpgradeToken();
    SlimeToken public slimeToken = new SlimeToken();

    struct SlimeData {
        uint types;
        uint tokenNeed;
        uint level;
    }

    struct Task {
        bool ableToAdventure;
        uint leaveAt;
    }

    modifier isSlimeOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    constructor() ERC721("A Slime NFT", "SlimeT") Ownable(msg.sender) {}

    function mintOneSlime() public payable nonReentrant {
        slimeTokenId = totalSupply();
        if (msg.value == 0) {
            require(mintTimes[msg.sender] == 0, "Free mint only for the very first time.");
            _safeMint(msg.sender, slimeTokenId);
        } else {
            require(mintTimes[msg.sender] < 3,"You can not mint more than three times in one address.");
            // require(balanceOf(msg.sender) <= 3,"one address can have 3 at time");

            _safeMint(msg.sender, slimeTokenId);
        }
        slimeTypes[slimeTokenId] = SlimeData(0, DEFAUL_TOKEN_NEED, 0, true, 0);
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

    function canSlimeGoAdventrue() public view returns (uint256) {
        return slimeTasks[msg.sender].ableToAdventure;
    }

    function getSlimeLeaveAt() public view returns (uint256) {
        return slimeTasks[msg.sender].leaveAt;
    }

    function upgrade(uint256 _tokenId, uint256 slimeTokenAmount, uint256 upgradeTokenId) isSlimeOwner(_tokenId) external {
        // 先檢查這個 user 的餘額足夠嗎
        require(slimeToken.balanceOf(msg.sender) >= slimeTokenAmount,"you don't have enough token, go earning some.");
       
        // 這裡要用 這個tokenId 的資料結構來判斷需要多少$$
        require(slimeTokenAmount > slimeTypes[_tokenId].tokenNeed,"you need to put more token to upgrade now.");
       
        // 判斷道具是不是屬於他ㄉ
        require(msg.sender == upgradeToken.ownerOf(upgradeTokenId),"you don't own this upgrade nft.");

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

    function claimRewards(uint256 slimeTokenAmount, uint256 taskLevel, bool getUpgradeTokenAmount) external {
        // mint a upgrade token
        slimeToken.doMint(msg.sender, slimeTokenAmount);

        if (getUpgradeTokenAmount) {
            upgradeToken.doMint(msg.sender, upgradeToken.totalSupply(), taskLevel);
        }
    }

    function goAdventrue(uint256 _tokenId) public {
        require(canSlimeGoAdventrue(),"you can not let your slime go out.");

        slimeTasks[msg.sender].ableToAdventure = false;
        slimeTasks[msg.sender].leaveAt = block.timestamp;
    }

    function returnWithProfit(uint256 _tokenId) public {
        require(!canSlimeGoAdventrue(),"your slimes are not going out.");

        require(block.timestamp > getSlimeLeaveAt() + MINIMUM_BLOCK_TIME, "slime will go out at least 30 minutes.");

        uint256 times = block.timestamp - getSlimeLeaveAt();

        uint256 originProfit = times * PROFIT_RATE * balanceOf(msg.sender);

        uint256 profitAmount = originProfit > MAX_PROFIT_PER_TIME ? MAX_PROFIT_PER_TIME : originProfit;

        claimRewards(profitAmount, 0, false);
    }

   
}
