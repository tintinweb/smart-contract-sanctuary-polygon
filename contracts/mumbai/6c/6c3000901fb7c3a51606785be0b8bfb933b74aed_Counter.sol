/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// File: Counter.sol



pragma solidity >=0.7.0 <0.9.0;

contract Counter {

    uint public count = 0;

    function increament() public returns (uint) {
        
        return ++count;
    }

}