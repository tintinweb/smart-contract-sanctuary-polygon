// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test {
    uint256 public counter;

    function increase() external {
        counter += 1;
    }

    function reverter(bool _isRevert) external pure returns (bool) {
        require(!_isRevert, "Some message");

        return true;
    }
}