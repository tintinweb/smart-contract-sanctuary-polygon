/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Messagebox {
    string public message;
    address public owner;
    
    constructor ()  {
        message = "Hello World!";
        owner = msg.sender;
    }
    
    function setMessage(string memory _new_message) public {
        require(msg.sender == owner, "not allowed to change message");
        message = _new_message;
    }

    function destroySC() public {
        selfdestruct(payable(msg.sender));
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
    
}