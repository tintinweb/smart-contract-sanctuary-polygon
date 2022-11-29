// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./_ERC20.sol";
contract fizi is _ERC20 {
    constructor () _ERC20("fizi" , "Was"){
        _balances[msg.sender]=1000000;
    }
}