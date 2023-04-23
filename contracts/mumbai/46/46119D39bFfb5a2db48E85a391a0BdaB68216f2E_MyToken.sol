/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract MyToken {
    uint public mintTokenNumber;
    uint public totalSupply;
    mapping (address => uint) private balances;

    constructor(uint _mintTokenNumber) {
        mintTokenNumber = _mintTokenNumber;
    }

    function mint() external payable{
        balances[msg.sender] += mintTokenNumber;
        totalSupply += mintTokenNumber;        
    }

    function balanceOf(address account) view public returns (uint){
        return balances[account];
    }

}