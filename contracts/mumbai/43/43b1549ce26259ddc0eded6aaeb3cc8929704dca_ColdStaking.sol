/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

pragma solidity ^0.8.4;


//SPDX-License-Identifier: MIT
contract ColdStaking {
    mapping(address => uint256) private _balances;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
}