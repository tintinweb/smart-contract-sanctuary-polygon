/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// File: adder_flat.sol


// File: adder.sol

pragma solidity ^0.8.0;

contract adder {

    uint256 value;

function addOne() public returns(uint256){
    value += 1;
    return value;
}
}