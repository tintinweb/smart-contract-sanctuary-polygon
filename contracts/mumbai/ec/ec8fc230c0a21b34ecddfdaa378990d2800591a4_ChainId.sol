// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.5;

pragma experimental ABIEncoderV2;

library ChainId {
    uint256 constant ethereum = 1;
    uint256 constant goerli = 5;
    uint256 constant optimism = 10;
    uint256 constant bsc = 56;
    uint256 constant polygon = 137;
    uint256 constant fantom = 250;
    uint256 constant arbitrum = 42161;
    uint256 constant celo = 42220;
    uint256 constant avalanche = 43114;
    uint256 constant mumbai = 80001;

    function getChainId() public pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}