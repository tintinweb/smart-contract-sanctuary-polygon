// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Mango{


    function createSmartWallet(address _creatorAddress) public view returns(bool isCreated){
        if(_creatorAddress == msg.sender){
            return true;
        }
        else{
            return false;
        }
    }
}