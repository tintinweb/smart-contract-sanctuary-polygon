/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

contract Monitor {

    address payable sensors;
    address payable users;
    address payable drivers;

    uint ID = 0;

    struct Tank{
        uint ID;
        string name;
        uint level;
        uint temp;
        uint humidity;
        uint preassure;
        uint ph;
        bool exists;
    }

    // Tank[] tanks;

    mapping(uint => Tank) public tank_by_ID;

    function addTank(string memory _name) public {
        require(msg.sender != address(0));
        tank_by_ID[ID] = Tank(ID, _name, 0, 0, 0, 0, 0, true); 
        ID ++;
    }

    function refreshData(uint _id, uint _level, uint _temp, uint _humidity, uint _preassure, uint _ph) public { // añadir _name para perfmitir variar el nombre
        require(msg.sender != address(0));
        require(tank_by_ID[_id].exists, "Tank does not exists.");
        tank_by_ID[_id] = Tank(_id, tank_by_ID[_id].name, _level, _temp, _humidity, _preassure, _ph, true); // añadir _name para perfmitir variar el nombre

    }
}