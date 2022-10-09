/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

pragma solidity ^0.8.4;

contract A {

    string public message;
    constructor() {  
        message = "hello!";
    }

    function update(string memory _message) public {
        message = _message;    
    }

}