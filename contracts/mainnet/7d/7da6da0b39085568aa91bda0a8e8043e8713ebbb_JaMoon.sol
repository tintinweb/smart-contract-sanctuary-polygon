/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract JaMoon {
    mapping(string => bool) hasSwapped;
    event Swap(
        string cid
    );

    function swap(string memory cid) public {
        require(hasSwapped[cid] == false,"Already registered swap using this cid");
        hasSwapped[cid] = true;
        emit Swap(cid);
    }
}