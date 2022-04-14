// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

//标准的ERC20代币
contract HLFToken is ERC20 {
    // "lfhuangToken","HLF","1000000000"
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply * 10**uint256(decimals()));
    }
}