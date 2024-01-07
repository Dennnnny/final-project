// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this one should be an erc20
contract SlimeToken is ERC20 {

    address ADMIN;
    constructor(address _addr) ERC20("slime token", "SLT") {
        ADMIN = _addr;
    }

    modifier only_admin {
        require(msg.sender == ADMIN);
        _;
    }

    function doMint(address account, uint256 amount) public only_admin {
        _mint(account, amount);
    }
    function doBurn(address account, uint256 amount) public only_admin {
        _burn(account, amount);
    }
}
