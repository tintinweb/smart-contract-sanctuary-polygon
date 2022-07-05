/**
 *Submitted for verification at polygonscan.com on 2022-07-05
*/

// File: HelloWorld_flat.sol


// File: HelloWorld.sol

pragma solidity ^0.5.10;

contract HelloWorld {

    string public message;

    constructor(string memory initMessage) public {
       
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}