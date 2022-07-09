/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

pragma solidity ^0.8.15;

contract HelloWorld {
    string message;

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}