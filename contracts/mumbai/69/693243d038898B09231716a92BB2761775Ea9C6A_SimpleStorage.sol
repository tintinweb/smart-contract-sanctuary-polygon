/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    string private secret;

    function setSecret(string calldata _secret) public {
        secret = _secret;
    }

    function getSecret() public view returns (string memory) {
        return secret;
    }
}