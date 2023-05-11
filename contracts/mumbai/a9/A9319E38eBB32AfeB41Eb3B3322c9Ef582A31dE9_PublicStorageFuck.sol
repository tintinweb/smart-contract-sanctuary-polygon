/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract PublicStorageFuck {
    mapping(address => mapping(string => string)) public Storage;
    uint cost = 12555;
    address payable owner = payable(0x53B824334c4462aAd8cf7B31fa2c873F5f438f89);

    // constructor(uint _cost){
    //     cost = _cost;
    // }


    function saveData(string memory key, string memory value) public payable{
        require(msg.value >= cost, "not enough sssshit");
        Storage[msg.sender][key] = value;
        owner.transfer(msg.value);

    }

}