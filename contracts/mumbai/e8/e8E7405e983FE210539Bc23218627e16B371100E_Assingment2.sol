/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Assingment2 {
    //Variable declarations
    string private firstName;
    string private lastName;

    // @notice Initializes state variables
    constructor() {
        firstName = "Nick";
        lastName = "Szabo";
    }

    // @notice Retrives initializes values for state variables
    // @return First and second string value
    function retrieveWords() external view returns(string memory, string memory) {
        return (firstName, lastName);
    }
}