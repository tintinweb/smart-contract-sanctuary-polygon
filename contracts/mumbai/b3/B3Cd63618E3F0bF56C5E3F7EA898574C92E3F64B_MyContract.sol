/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyContract {

    uint public count ;

    function addNumber(uint number) external {
        count+=number;
    }


}