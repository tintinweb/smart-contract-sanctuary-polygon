/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
// File: Exchange.sol



pragma solidity ^0.8.15;



contract ExchangeTest {

    mapping(address => uint) public pets;



    function addPets(address _petaddress, uint _value) external {

        pets[_petaddress] = _value;

    }

}