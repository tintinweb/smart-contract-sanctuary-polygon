/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

pragma solidity ^0.8.0;

contract TestRevert {
    uint256 public value = 1;

    function setValue(uint256 newValue) external {
        require(newValue < 10, "newValue >= 9");

        value = newValue;
    }
}