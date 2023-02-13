/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Likes {

    event Like(string indexed fullTableNameHash, string fullTableName, address indexed user);
    event Unlike(string indexed fullTableNameHash, string fullTableName,  address indexed user);

    function like(string memory fullTableName) public {
        emit Like(fullTableName, fullTableName, msg.sender);
    }

    function unlike(string memory fullTableName) public {
        emit Unlike(fullTableName, fullTableName, msg.sender);
    }
}