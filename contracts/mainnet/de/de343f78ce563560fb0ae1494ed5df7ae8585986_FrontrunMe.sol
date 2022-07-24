/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract FrontrunMe {
    bytes32 public hashedSecret; 

    constructor(bytes32 _secret) payable {
        hashedSecret = _secret;
    }

    receive() external payable {}

    function withdrawFunds(string memory _secret) public {
        require(keccak256(abi.encodePacked(_secret)) == hashedSecret, "Incorrect string");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}