/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

// File: contract-3741a30bf6.sol


pragma solidity ^0.8.4;
contract SimpleStorage {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}