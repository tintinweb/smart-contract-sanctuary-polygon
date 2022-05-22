//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20Permit.sol";

contract ERC20 is ERC20Permit{
    constructor(uint256 totalSupply) ERC20Permit("Wrapped Test Permit Token", "WTPT"){
        mint(msg.sender, totalSupply);
    }
}