// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VerificationCheck {
    string public s;
    uint256 public i;

    constructor(string memory _s, uint256 _i) {
        s = _s;
        i = _i;
    }

    function setInt(uint256 _i) external {
        i = _i;
    }

    function setString(string calldata _s) external {
        s = _s;
    }
}