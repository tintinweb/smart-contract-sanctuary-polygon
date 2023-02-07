/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

error sameStorageValue();

contract SimpleStorage {

    uint public storedData;  //Do not set 0 manually it wastes gas!

    event setOpenDataEvent(); 

    function set(uint x) public {
        if(storedData == x) { revert sameStorageValue(); }        
        storedData = x;
        emit setOpenDataEvent();
    }

}