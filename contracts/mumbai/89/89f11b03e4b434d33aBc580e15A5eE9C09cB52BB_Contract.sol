// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract  Contract {

    string  public message;

    function setMessage (string memory _message) public  {
        message = _message;
    }

}