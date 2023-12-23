// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this one should be an erc20
contract SlimeToken is ERC20 {
    constructor() ERC20("slime token", "SLT") {}
}
