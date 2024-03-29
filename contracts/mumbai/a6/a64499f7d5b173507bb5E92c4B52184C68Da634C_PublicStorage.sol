/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract PublicStorage {
    mapping(address => mapping(string => string)) public Storage;
    uint cost;
    address payable owner;
    constructor(uint _cost){
        owner = payable(msg.sender);
        cost = _cost;

    }

    function saveData(string memory key, string memory value) public payable{
        require(msg.value >= cost, "not enough value");
        Storage[msg.sender][key] = value;
        owner.transfer(msg.value);

    }

}