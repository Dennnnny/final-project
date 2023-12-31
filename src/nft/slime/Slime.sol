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
        uint256 level;
    }
    address ADMIN;
    mapping(uint256 => UpgradeType) public upgradeList;

    constructor() ERC721("Upgrade Sliime", "UPS") {
        ADMIN = msg.sender;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage)  returns (string memory) {
        uint path = upgradeList[_tokenId].types;

        return ""; // redirect by different types
    }

    /**
     * @dev mint function to create a upgrade token for slime to upgrade
     *
     * @param _to address representing the owner, basically refer to msg.sender.
     * @param _tokenId uint256, refer to this erc721 upgradeTokenId.
     * @param taskLevel uint256, will decide tokenURI path and this token's level
     */
    function doMint(
        address _to,
        uint256 _tokenId,
        uint256 taskLevel
    ) public nonReentrant {
        // use a random number alike to control the types
        uint256 randomTypes = ((gasleft() % 3) + 1) * (10 ** (taskLevel * 2));

        _safeMint(_to, _tokenId);

        upgradeList[_tokenId].types = randomTypes;
        upgradeList[_tokenId].level = taskLevel;
    }

    function doBurn (uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function getUpgradeTypes(uint256 _tokenId) public returns(uint256) {
        return upgradeList[_tokenId].types;
    }

    function getUpgradeLevel(uint256 _tokenId) public returns(uint256) {
        return upgradeList[_tokenId].level;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
      return super.supportsInterface(interfaceId);
    }
    
    function _update(
      address to,
      uint256 tokenId,
      address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
      return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
      super._increaseBalance(account, value);
    }
}

// this one should be an erc721
contract Slime is ERC721Enumerable, Ownable {
    mapping(address => uint256) public mintTimes;
    mapping(uint => SlimeData) public slimeTypes;
    uint public slimeTokenId;
    uint constant MAX_SUPPLY = 1_000_000; // not sure to use this yet.
    uint constant DEFAUL_TOKEN_NEED = 1e18;

    UpgradeToken public upgradeToken = new UpgradeToken();
    SlimeToken public slimeToken = new SlimeToken();

    struct SlimeData {
        uint types;
        uint tokenNeed;
        uint level;
    }

    constructor() ERC721("A Slime NFT", "SlimeT") Ownable(msg.sender) {}

    function mintOneSlime() public payable {
        slimeTokenId = totalSupply();
        if (msg.value == 0) {
            require(mintTimes[msg.sender] == 0, "Free mint only for the very first time.");
            _safeMint(msg.sender, slimeTokenId);
            slimeTypes[slimeTokenId].tokenNeed = DEFAUL_TOKEN_NEED;
        } else {
            require(mintTimes[msg.sender] < 3,"You can not mint more than three times in one address.");
            // require(balanceOf(msg.sender) <= 3,"one address can have 3 at time");

            _safeMint(msg.sender, slimeTokenId);
            slimeTypes[slimeTokenId].tokenNeed = DEFAUL_TOKEN_NEED;
        }
        mintTimes[msg.sender] += 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint path = slimeTypes[_tokenId].types;

        // I'm going to create a metadata in pinata of ipfs
        // structure should be like: https://ipfs....../slimes/path
        // represent all king of slime in different path.

        // return string(abi.encodePacked("https://xxx/", yourUint.toString())); // redirect by different types
        return string(path.toString());
    }

    function getSlimeLevel(uint256 _tokenId) public view returns (uint256) {
        return slimeTypes[_tokenId].level;
    }

    function upgrade(uint256 _tokenId, uint256 slimeTokenAmount, uint256 upgradeTokenId) external {
        // 先檢查這個 user 的餘額足夠嗎
        require(slimeToken.balanceOf(msg.sender) >= slimeTokenAmount,"you don't have enough token, go earning some.");
       
        // 這裡要用 這個tokenId 的資料結構來判斷需要多少$$
        require(slimeTokenAmount > slimeTypes[_tokenId].tokenNeed,"you need to put more token to upgrade now.");
       
        // 判斷道具是不是屬於他ㄉ
        require(msg.sender == upgradeToken.ownerOf(upgradeTokenId),"you don't own this upgrade nft.");

        // 判斷升級道具 level 是否跟 史萊姆的等級是相同 match
        require(upgradeToken.getUpgradeLevel(upgradeTokenId) == slimeTypes[_tokenId].level ,"upgrade token level should have same level as your slime.");

        // upgrade 這個 slime 的路徑 與 升級所需的 token 數量
        slimeTypes[_tokenId].tokenNeed = slimeTypes[_tokenId].tokenNeed * 2;

        slimeTypes[_tokenId].types = upgradeToken.getUpgradeTypes(upgradeTokenId) + slimeTypes[_tokenId].types;

        slimeTypes[_tokenId].level = slimeTypes[_tokenId].level + 1;

        // pass 檢查後： burn and upgrade
        upgradeToken.doBurn(upgradeTokenId);
        slimeToken.doBurn(msg.sender, slimeTokenAmount);
    }

    function missionCompleted(uint256 taskLevel, uint256 slimeTokenAmount,bool getUpgradeTokenAmount) external {
        // need to think how to protect this method ???

        // mint a upgrade token
        slimeToken.doMint(msg.sender, slimeTokenAmount);

        if (getUpgradeTokenAmount) {
            upgradeToken.doMint(msg.sender, upgradeToken.totalSupply(), taskLevel);
        }
    }

   
}
