// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV2 {
    uint256 public val;

    /**
     * initialized will be called only once using Box.sol
     */
    // function initialize(uint256 _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}