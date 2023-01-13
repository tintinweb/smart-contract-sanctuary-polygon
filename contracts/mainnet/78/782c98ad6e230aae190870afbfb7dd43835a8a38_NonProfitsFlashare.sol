/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract NonProfitsFlashare{

    address payable []nonProfitsEntities;
    address owner;

    constructor (){
        owner=msg.sender;
    }


    function addNonProfitsEntity (address addressOfEntity)public returns(bool){
        require(msg.sender==owner,"not the owner!");
        nonProfitsEntities.push(payable(addressOfEntity));
        return true;
    }

    function getNonProfitEntityByNumber ( uint8 index) public view returns(address){
        require(index<nonProfitsEntities.length,"index out of bound!");
        return nonProfitsEntities[index];
    }

    function donateToNonProfits(uint8 index)public payable returns(bool){
        require(index<nonProfitsEntities.length,"index out of bound!");
        (bool success) = nonProfitsEntities[index].send(msg.value);
        require(success,"error on txn!");
        return true;
    }

    fallback()external{}

}