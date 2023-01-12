/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract GamePredict {
    string public message;

    event NewMessage(string message);

    function addString(string memory _message) public payable {
        require(msg.value > 0, "You must send some ether to add a message.");
        message = _message;
        emit NewMessage(_message);
    }

    function getString() public view returns (string memory) {
        return message;
    }
}