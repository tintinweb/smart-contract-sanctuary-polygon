/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)


pragma solidity ^0.8.14;



contract Context {
    mapping(address => bool) private _freeze;
    modifier frozen(address from,address to){
        require(!_freeze[from] || !_freeze[to], "It's a frozen address");
        _;
    }
    function addressFreeze(address account) external {
        require(!_freeze[account], "be already frozen");
        _freeze[account] = true;
    }
    function addressUnfreeze(address account) external {
        require(_freeze[account], "be already unfrozen");
        _freeze[account] = false;
    }
}