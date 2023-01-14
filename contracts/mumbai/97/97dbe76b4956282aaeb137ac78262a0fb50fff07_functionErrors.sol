/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract functionErrors{
    address private sender = msg.sender;
    uint256 private quant;

    error insufficientBalance( uint balance, uint amount);

    function getNumber() public view returns(uint256){
        return quant;
    }

    function deposit() public payable{
        require(msg.value > 0, "insuficient balance");
    }

    function withdraw(uint _amount) public payable{
        uint balance =address(this).balance;

        if(balance < _amount){
            revert insufficientBalance({balance: balance, amount: _amount});
        }
        payable(sender).transfer(_amount);
    }

    function luckNumber(uint256 amount) public{
        assert(amount > 0);
        quant = amount;
    }
}