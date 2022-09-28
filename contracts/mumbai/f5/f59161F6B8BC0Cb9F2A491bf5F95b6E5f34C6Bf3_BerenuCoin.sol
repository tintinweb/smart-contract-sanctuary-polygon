/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BerenuCoin {
    uint256 maxTotalSupply = 1000;
    address owner = 0x75779c50E3234C4ebbf5912823a143Bc8162D4F0;
    string name = "BerenuCoin";
    string symbol = "BRC";

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function getSymbol() external view returns (string memory) {
        return symbol;
    }
}