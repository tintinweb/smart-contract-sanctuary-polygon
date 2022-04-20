/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

pragma solidity ^0.8.7;

contract HelloWorld {

    string public message;

    // A special function only run during the creation of the contract
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}