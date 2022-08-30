/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
contract HelloWorld {
    
    address[] public bought;

    // set the addresses in store
    function setStore(address[] memory _addresses) public returns(address[] memory) {
        bought = _addresses;
        return bought;  
    }
}