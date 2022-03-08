/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT
// Specifies that the source code is for a version
// of Solidity greater than 0.5.10
pragma solidity ^0.8.10;

// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.
contract show_CO2 {

    // The keyword "public" makes variables accessible from outside a contract
    // and creates a function that other contracts or SDKs can call to access the value
    int public emission;

    constructor() {
        emission = 0;
    }

    function get() public view returns(int){
        return emission;
    }

    function set(int new_emission) public{
        emission = new_emission;
    }

    function offset( int token_id, int amount) public{
       set(token_id * amount);
    }
}