/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

pragma solidity ^0.5.10;

contract HelloWorld{
    string public mesg ;

    constructor() public {
        mesg = "hola";
    }

    function update(string memory newMessage) public {
        mesg=newMessage;
    }
}