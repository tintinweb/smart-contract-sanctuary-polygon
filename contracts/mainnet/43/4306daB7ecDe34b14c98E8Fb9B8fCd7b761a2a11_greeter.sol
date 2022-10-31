pragma solidity ^0.8.0;

contract greeter {

    function test(uint num) public pure returns (uint numBis) {
        numBis = 2*num;
    }
}