/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

pragma solidity ^0.8.7;

contract Context {
    string _message;
    // constructor () internal { }
    
    function getMessage() public view returns (string memory) {
        return _message;
    }

    function setMessage(string memory message) public{
         _message = message;
    }
}