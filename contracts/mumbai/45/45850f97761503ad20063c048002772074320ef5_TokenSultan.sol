/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenSultan{

    string public Sultan;
    string public SLTN;
    uint256 public totalSupply;
    mapping (address => uint256) public balance; 

    constructor() {
        totalSupply = 100;
        balance[msg.sender] = totalSupply;
    }

    function transfer(address _receiver, uint256 _amount ) public {
        require(balance[msg.sender]>=_amount);
        balance[msg.sender] -= _amount;
        balance[_receiver] += _amount;
    }
}