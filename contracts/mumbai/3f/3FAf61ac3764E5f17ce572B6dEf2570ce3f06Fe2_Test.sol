pragma solidity 0.8.0;

contract Test {
    uint256 public myval;

    function setMyval(uint256 _val) public returns (uint256) {
        myval = _val;
        return myval;
    }
}