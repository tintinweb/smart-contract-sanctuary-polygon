/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

pragma solidity ^0.4.24;  //  0.4.25 - 0.5

contract begin {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public constant returns (uint) {
        return storedData;
    }

}