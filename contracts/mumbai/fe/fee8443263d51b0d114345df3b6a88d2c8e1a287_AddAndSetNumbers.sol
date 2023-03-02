/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

pragma solidity ^0.8.0;

contract AddAndSetNumbers {
    uint256 public myNumber;

    function setNumber(uint256 number) public {
        myNumber = number;
    }

    function getNumber() public view returns (uint256) {
        return myNumber;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
}