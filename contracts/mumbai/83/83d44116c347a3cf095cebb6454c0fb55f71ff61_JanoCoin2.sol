/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract JanoCoin2 {
    uint256 maxTotalSupply = 2022;
    string tokenName = "JanoCoin2";
    string tokenSymbol = "JC2";
    address owner = 0x16b3Aa0c8a5A7c7958A4eF2F8BB6E6D4095E49a8;

    function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

    function getTokenName() external view returns (string memory) {
        return string.concat("The token name is: ", tokenName);
    }

    function getTokenSymbol() external view returns (string memory) {
        return string.concat("The token symbol is: ", tokenSymbol);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }
    
}