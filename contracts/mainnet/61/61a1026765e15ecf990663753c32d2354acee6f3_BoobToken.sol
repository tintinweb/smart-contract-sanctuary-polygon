// SPDX-License-Identifier: GPL-3.0
 
pragma solidity ^0.8.0;
 
import "./erc20.sol";
 
contract BoobToken is ERC20 {
    constructor() ERC20("Big Boobies Token", "BOOBS"){
        _mint(msg.sender,1000*10**18);
    }
}