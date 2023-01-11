/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ContractNameV2 {

    bool internal initialized;
    uint public a;
    
    function initialize(uint a_) external {
        require(!initialized, "Contract is already initialized");
        a = a_;
        initialized = true;
    }

    function increment() external {
        a++;
    }

    function decrement() external {
        a--;
    }
}