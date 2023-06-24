// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DoubleCall {
    event Eject(address ejectedAddress);
    address[] public ejectedList;
    address[] public userList;


    constructor() {
        ejectedList.push(address(1));
        ejectedList.push(address(2));
        ejectedList.push(address(3));
    }


    function replaceUserWithCurrent(address currentUser) public {
        address ejectedUser = ejectedList[ejectedList.length - 1];
        ejectedList.pop();
        emit Eject(ejectedUser);
        userList.push(currentUser);
    }
}