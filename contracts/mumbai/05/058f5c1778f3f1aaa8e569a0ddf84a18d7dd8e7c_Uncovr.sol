/**
 *Submitted for verification at polygonscan.com on 2022-08-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Uncovr{ 

    address owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,'Only for Owner');
        _;
    }
    mapping(address=> uint256) accountToId;
    mapping(address =>uint256) accountToSpentMoney;
    mapping(address =>uint256) accountToSpendableMoney; 
    uint256 lockPool;
    uint256 adminPool;
    uint256 bufferAmount;

    function lockMoney(uint256 _amount) public {
        require(accountToSpendableMoney[msg.sender] >= _amount,"You need to fund your account");
        accountToSpendableMoney[msg.sender] -= _amount;
        accountToSpentMoney[msg.sender] += _amount;
        lockPool += _amount;

    }

    function approveFeedback(uint256 _amount, address[] memory _addresses) public {
        uint256 totalMoney = _amount*_addresses.length;
        uint256 adminCut = totalMoney/100*10;
        uint256 individualPayout = (totalMoney-adminCut)/_addresses.length;
        require(accountToSpentMoney[msg.sender]>=totalMoney,"Not enough funds!");
        for(uint256 i=0; i<_addresses.length;i++){
            accountToSpendableMoney[_addresses[i]]+=individualPayout;
        }
        adminPool+=adminCut;
    }   

    function fundAccountFromOwner(uint256 _amount, address _id) public{
        accountToSpendableMoney[_id] += _amount;
    }
}