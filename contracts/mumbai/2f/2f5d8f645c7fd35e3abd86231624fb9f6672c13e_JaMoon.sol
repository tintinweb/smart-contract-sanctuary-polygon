/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract JaMoon {
    event Swap(
        string cid
    );

    function swap(string memory cid) public {
        emit Swap(cid);
    }
}