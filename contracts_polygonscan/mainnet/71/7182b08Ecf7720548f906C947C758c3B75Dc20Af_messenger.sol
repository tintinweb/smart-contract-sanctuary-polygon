/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract messenger {

    mapping(address => string) userToPubKey;

    function setPublicKey(string memory _publicKey) public {
        userToPubKey[msg.sender] = _publicKey;
    }

    function publicKey(address user) public view returns(string memory){
        return userToPubKey[user];
    }

    event NewMessage(address from, address to, string subject, string message);

    function sendMessage(
        address to,
        string memory subject,
        string memory message
    ) public {
        emit NewMessage(msg.sender, to, subject, message);
    }
}