/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// interface Task {
//     function add(address winner) external;
//     function lock() external; 
// }


// Find a way to add your address in `winners`.
contract Task{
    bool locked;
    address[] public winners;

    function add(address winner) public {
        locked = false;


        require(locked);
        winners.push(winner);
    }

    function lock() public {
        locked = true;
    }
}