// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // ERC721
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // ERC721Enumerable
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../../src/erc20/Slimetoken.sol"; // self made token

// I think I should make a factory to create erc721
// I think this factory will use to produce some upgrade nft.
contract SlimeFactory {
    address ADMIN;

    constructor() {
        ADMIN = msg.sender;
    }
}

// this one should be an erc721
contract Slime is ERC721Enumerable, Ownable {
    mapping(address => uint256) public mintTimes;
    mapping(uint => SlimeData) public slimeTypes;
    uint public tokenId;
    uint constant MAX_SUPPLY = 1_000_000; // not sure to use this yet.

    struct SlimeData {
        uint type1;
        uint type2;
    }

    constructor() ERC721("A Slime NFT", "SlimeT") Ownable(msg.sender) {}

    function mintOneSlime() public payable {
        tokenId = totalSupply();
        if (msg.value == 0) {
            require(
                mintTimes[msg.sender] == 0,
                "Free mint only for the very first time"
            );
            _safeMint(msg.sender, tokenId);
        } else {
            require(
                mintTimes[msg.sender] < 3,
                "You can not mint more than three times in one address"
            );
            // require(balanceOf(msg.sender) <= 3,"one address can have 3 at time");

            _safeMint(msg.sender, tokenId);
        }
        mintTimes[msg.sender] += 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        uint path = slimeTypes[_tokenId].type1 + slimeTypes[_tokenId].type2;

        // I'm going to create a metadata in pinata of ipfs
        // structure should be like: https://ipfs....../slimes/path
        // represent all king of slime in different path.

        return ""; // redirect by different types
    }

    function upgrade(uint256 _tokenId, address upgradeNFT) external {
        // I want to check this upgrade nft token is comes from factory or not
        // not really know what to do right now
        //
        // and... also need slimeToken to do the upgrade
    }
}
