// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // ERC721
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // ERC721Enumerable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // ERC721URIStorage
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../src/erc20/SlimeToken.sol"; // self made token

// I think I should make a factory to create erc721
// I think this factory will use to produce some upgrade nft.
contract UpgradeToken is ERC721, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard {
    struct UpgradeType {
        uint256 types;
    }
    address ADMIN;
    mapping(uint256 => UpgradeType) upgradeList;

    constructor() ERC721("Upgrade Sliime", "UPS") {
        ADMIN = msg.sender;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint path = upgradeList[_tokenId].types;

        return ""; // redirect by different types
    }

    function doMint(
        address _to,
        uint256 _tokenId,
        uint256 taskLevel
    ) public nonReentrant {
        // notes: 這邊我會再想想看 要不要這樣做 :/ 
        // use a random number alike to control the types
        uint256 randomTypes = ((gasleft() % 3) + 1) * (10 ** (taskLevel * 2));

        _safeMint(_to, _tokenId);

        upgradeList[_tokenId].types = randomTypes;
    }
}

// this one should be an erc721
contract Slime is ERC721Enumerable, Ownable {
    mapping(address => uint256) public mintTimes;
    mapping(uint => SlimeData) public slimeTypes;
    uint public tokenId;
    uint constant MAX_SUPPLY = 1_000_000; // not sure to use this yet.
    uint constant DEFAUL_TOKEN_NEED = 1e18;

    UpgradeToken upgradeToken = new UpgradeToken();
    SlimeToken slimeToken = new SlimeToken();

    struct SlimeData {
        uint types;
        uint tokenNeed;
        uint level;
    }

    constructor() ERC721("A Slime NFT", "SlimeT") Ownable(msg.sender) {}

    function mintOneSlime() public payable {
        tokenId = totalSupply();
        if (msg.value == 0) {
            require(mintTimes[msg.sender] == 0, "Free mint only for the very first time.");
            _safeMint(msg.sender, tokenId);
            slimeTypes[_tokenId].tokenNeed = DEFAUL_TOKEN_NEED;
        } else {
            require(mintTimes[msg.sender] < 3,"You can not mint more than three times in one address.");
            // require(balanceOf(msg.sender) <= 3,"one address can have 3 at time");

            _safeMint(msg.sender, tokenId);
            slimeTypes[_tokenId].tokenNeed = DEFAUL_TOKEN_NEED;
        }
        mintTimes[msg.sender] += 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint path = slimeTypes[_tokenId].types;

        // I'm going to create a metadata in pinata of ipfs
        // structure should be like: https://ipfs....../slimes/path
        // represent all king of slime in different path.

        return ""; // redirect by different types
    }

    function upgrade(uint256 _tokenId, uint256 slimeTokenAmount, uint256 upgradeTokenId) external {
        // 先檢查這個 user 的餘額足夠嗎
        require(SlimeToken.balanceOf(msg.sender) >= slimeTokenAmount,"you don't have enough token, go earning some.");
        // 這裡要用 這個tokenId 的資料結構來判斷需要多少$$
        require(slimeTokenAmount > slimeTypes[_tokenId].tokenNeed,"you need to put more token to upgrade now.");
        // 判斷道具是不是屬於他ㄉ
        require(msg.sender == UpgradeToken.ownerOf(upgradeTokenId),"you don't own this upgrade nft");
        // upgrade 這個 slime 的路徑 與 升級所需的 token 數量
        slimeTypes[_tokenId].tokenNeed = slimeTypes[_tokenId].tokenNeed * 2;

        slimeTypes[_tokenId].types = upgradeToken.upgradeList(upgradeTokenId).types + slimeTypes[_tokenId].types;

        slimeTypes[_tokenId].level + 1;

        // pass 檢查後： burn and upgrade
        UpgradeToken._burn(upgradeTokenId);
        SlimeToken._burn(msg.sender, slimeTokenAmount);
    }

    function missionCompleted(uint256 taskLevel, uint256 slimeTokenAmount,bool getUpgradeTokenAmount) external {
        // need to think how to protect this method ???

        // mint a upgrade token
        slimeToken._mint(msg.sender, slimeTokenAmount);

        if (getUpgradeTokenAmount) {
            upgradeToken.doMint(msg.sender, upgradeToken.totalSupply(), taskLevel);
        }
    }
}
