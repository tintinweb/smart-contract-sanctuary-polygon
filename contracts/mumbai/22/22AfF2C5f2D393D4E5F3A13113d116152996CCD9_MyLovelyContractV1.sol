//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MyLovelyContractV1{
    string public alert;

    //no constructors for upgradeable contracts

    function retrunValue(string memory alertv2) public returns(string memory){
        alert = alertv2;
        return alert;
    }

}