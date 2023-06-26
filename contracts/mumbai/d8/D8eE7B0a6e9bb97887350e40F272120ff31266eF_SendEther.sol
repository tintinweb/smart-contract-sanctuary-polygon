/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SendEther {
    function sendViaTransfer(address payable _to) public payable  {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to, uint256 _mount) public payable {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(_mount);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to, uint256 _mount) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: _mount}("");
        require(sent, "Failed to send Ether");
    }
}