pragma solidity 0.8.13;

contract TestSum {
    struct input{
        uint256 a;
        uint256 b;
    }

    function sum(input calldata i) public returns (uint256) {
        return i.a + i.b;
    }

    function sum2(uint256 a, uint256 b) public returns (uint256) {
        return a + b;
    }
}