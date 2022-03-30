/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

//SPDX-License-Identifier:MIT


pragma solidity ^0.8.6;

contract MyFirstPolygonContract{

    string private name;
    uint private amount;


    function setName(string memory newName) public {
        name = newName;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function setAmount(uint newAmount) public{
        amount = newAmount;
    
    }

    function getAmount() public view returns (uint) {
        return amount;
    }




}