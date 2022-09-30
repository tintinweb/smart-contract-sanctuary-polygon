/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: GNU
pragma solidity 0.8.12;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract DumbOracle {
    //stores last value given (the fear and greed index) and a counter for how many times it has been updated.

    uint256 public updates;
    uint256 public fng_index;

    /**
     * @dev updates the value and increments updates
     * @param value value to store as fng_index
     */
    function update(uint256 value) external {
        fng_index = value;
        updates += 1;
    }

}