//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract BoxV1 {
    uint256 val;

    function initialize(uint256 _val) public {
        val = _val;
    }
}