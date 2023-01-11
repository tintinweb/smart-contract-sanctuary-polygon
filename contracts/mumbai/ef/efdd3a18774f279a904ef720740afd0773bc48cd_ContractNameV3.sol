/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ContractNameV3 {

    bool internal initialized;
    uint public a;
    
    function initial(uint a_) external {
        a = a + a_;
    }

    function increment() external {
        a++;
    }

    function decrement() external {
        a--;
    }
}