/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

pragma solidity ^0.8.0;

contract SimpleStorage {
    //Storage. Persists in between transactions
    uint x;

    //Allows the unsigned integer stored to be changed
    function set(uint newValue) public {
        x = newValue;
    }
    
    //Returns the currently stored unsigned integer
    function get() public returns (uint) {
        return x;
    }
}