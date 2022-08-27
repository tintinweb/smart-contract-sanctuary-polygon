/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Migrator {
    
    uint256 private USDC_PEV1 = 4000;

    uint256 private PEV2_USDC = 240000000;

    uint256 private DECIMALS = 6;

    uint256 public operations = 0;

    function quote(uint256 amount) external view returns (uint256 usdc, uint256 pe) {
        usdc = amount * USDC_PEV1 / 10**DECIMALS;
        pe = usdc * PEV2_USDC / 10**DECIMALS;
    }

    function migrate(uint256 amount) external returns (uint256 usdc, uint256 pe) {
        usdc = amount * USDC_PEV1 / 10**DECIMALS;
        pe = usdc * PEV2_USDC / 10**DECIMALS;

        operations += 1;
    }
}