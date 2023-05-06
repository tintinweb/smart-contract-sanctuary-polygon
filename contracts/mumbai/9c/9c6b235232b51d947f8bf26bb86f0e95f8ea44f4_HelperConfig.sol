// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract HelperConfig {
    // chain id names
    mapping(uint256 => string) public chainNames;

    constructor() {
        chainNames[1] = "mainnet";
        chainNames[5] = "goerli";
    }
}