/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0
/*
Extended version of 1_Storage.sol
v0.1 - 24.11.2022
by baumann.at
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve values in variables
 */
contract cb_Storage {

    uint256 number;
    string public message;
    address owner;

    /**
     * @dev constructs contract, stores value in variable
     * @param value value to store
     */
    constructor (uint256 value)  {
        number = value;
        message = 'initialized';
        owner = msg.sender;
    }

    /**
     * @dev Store value in variable
     * @param value value to store
     */
    function setNumber(uint256 value) public {
        number = value;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getNumber() public view returns (uint256){
        return number;
    }

    /**
     * @dev Add value to variable
     * @param value to store
     */
    function addNumber(uint value) public {
        number += value;
    }

    /**
     * @dev Subtract value from variable, check if > 0
     * @param value to store
     */
    function subNumber(uint value) public {
        if (value > number) {
            number = 0;
        } else {
            number -= value;
        }
    }

    /**
     * @dev Store value in variable
     * @param value value to store
     */
    function setMessage(string memory value) public {
        message = value;
    }

    /**
     * @dev Return message 
     * @return value of 'message'
     */
    function getMessage() public view returns(string memory) {
        return message;
    }

    /**
     * @dev Return value 
     * @return a secret message, only if called by owner
     */
    function getSecretMessage() public view returns(string memory) {
        require(msg.sender == owner, "Only contract owner can call this function!");
        return "some secret message ...";
    }
}