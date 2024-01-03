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
        uint path = this.getUpgradeTypes(_tokenId);

        return string(abi.encodePacked("https://ipfs.io/ipfs/QmQ8H1KoFRQDe12VHerrf9GmGdcpyMmuKcoAERefnm6ZXm/", Strings.toString(path), ".png" )); // redirect by different types
    }

    /**
     * @dev mint function to create a upgrade token for slime to upgrade
     *
     * @param _to address representing the owner, basically refer to msg.sender.
     * @param _tokenId uint256, refer to this erc721 upgradeTokenId.
     * @param taskLevel uint256, will decide tokenURI path and this token's level
     */
    function doMint(address _to, uint256 _tokenId, uint256 taskLevel) public nonReentrant {
        // use a random number alike to control the types
        uint256 randomTypes = ((gasleft() % 3) + 1) * (10 ** (taskLevel * 2));

        _safeMint(_to, _tokenId);

        upgradeList[_tokenId].types = randomTypes;
        upgradeList[_tokenId].level = taskLevel;
    }

    /**
     * @dev burn the token
     */
    function doBurn (uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function getUpgradeTypes(uint256 _tokenId) public view returns(uint256) {
        return upgradeList[_tokenId].types;
    }

    function getUpgradeLevel(uint256 _tokenId) public view returns(uint256) {
        return upgradeList[_tokenId].level;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
      return super.supportsInterface(interfaceId);
    }
    
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
      return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
      super._increaseBalance(account, value);
    }
}
