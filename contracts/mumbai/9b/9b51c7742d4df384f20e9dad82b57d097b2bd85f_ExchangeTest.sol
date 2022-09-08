/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT
// File: Exchange.sol



pragma solidity ^0.8.15;



contract ExchangeTest {

    mapping(address => uint) public pets;

    event addPets (address _petaddress, uint _value);



    function addPet(address _petaddress, uint _value) external {

        pets[_petaddress] = _value;

        emit addPets(_petaddress, _value);

    }

}