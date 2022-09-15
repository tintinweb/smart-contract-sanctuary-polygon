/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

pragma solidity ^0.5.10;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}