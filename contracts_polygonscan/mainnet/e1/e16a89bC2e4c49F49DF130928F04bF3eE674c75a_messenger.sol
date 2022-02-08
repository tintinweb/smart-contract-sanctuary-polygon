/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract messenger {

    mapping(address => bytes) userToPubKey;

    function setPublicKey(bytes memory _publicKey) public {
        userToPubKey[msg.sender] = _publicKey;
    }

    function publicKey(address user) public view returns(bytes memory){
        return userToPubKey[user];
    }

    event NewMessage(address from, address to, string message);

    function sendMessage(
        address to,
        string memory message
    ) public {
        emit NewMessage(msg.sender, to, message);
    }
}