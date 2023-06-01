/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// the name in my file not is necessary match with my name file.
// but is good practice this.
contract MyFirstContract {
 // uint: unsigned integer (enetro sin signo)
 // rango: [0 - 2^256 - 1]
    uint256 age = 200;
    uint256 public anio = 2023;
    uint256 public salary;
    bool public isActive;
    // In solidity not exist null and undefined like in javascript
    // view is only to read method
    // publc: is to use external users
    // private/internal: can´t use to external users

    function getAge() public view returns(uint256) {
        return age;
    }

    function changeAge(uint256 newAge) public {
        age = newAge;
    }
}