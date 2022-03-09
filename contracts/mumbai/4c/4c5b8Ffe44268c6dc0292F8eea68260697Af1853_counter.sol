/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract counter {
    uint public Count;

    function countMe() public virtual {
        Count ++;
    }
}