//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
    import './Counter.sol';

contract Test{
        using Counters for Counters.Counter;
string public hii='hello world';
    uint number;
function update(string memory message) public{hii=message;}
}