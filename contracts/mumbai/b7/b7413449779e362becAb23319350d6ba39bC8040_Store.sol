/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Store {

    // event for EVM logging
    event Added(string fragment);

    // event for EVM logging
    event Removed(string fragment);

    function add(string calldata _fragment) public {
        emit Added(_fragment);
    }

    function remove(string calldata _fragment) public {
        emit Removed(_fragment);
    }
}