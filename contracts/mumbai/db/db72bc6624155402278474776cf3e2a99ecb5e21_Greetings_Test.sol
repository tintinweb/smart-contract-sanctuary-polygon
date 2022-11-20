/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//Every transaction on Ethereum Virtual Machine costs us some amount of Gas. The lower the Gas consumption the better is your Solidity code. The Gas consumption of Memory is not very significant as compared to the gas consumption of Storage. Therefore, it is always better to use Memory for intermediate calculations and store the final result in Storage.
//1. State variables and Local Variables of structs, array are always stored in storage by default.
//2. Function arguments are in memory.
//3. Whenever a new instance of an array is created using the keyword ‘memory’, a new copy of that variable is created. Changing the array value of the new instance does not affect the original array.

contract Greetings_Test {
    string public name;
    string public greetingPrefix = "Hello ";

    constructor(string memory initialName) {
        name = initialName;
    }

    function setName(string memory newName) public {
        name = newName;
    }

    function getGreeting() public view returns (string memory) {
        return string(abi.encodePacked(greetingPrefix,name));
    }
}