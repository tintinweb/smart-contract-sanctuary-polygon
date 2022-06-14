// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// Successful test. Output variable: `amount`
/// @param amount test variable.
error TestError(uint256 amount);

contract ErrorTest {
    
    function testErrors(uint256 amount) external {
        revert TestError(amount);
    }
}