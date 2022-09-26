/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract GreinCoin {
    uint256 maxTotalSupply = 1000;
    string name = "Grein";
    string symbol = "GRN";
    address owner = 0x49fA62108dE1A881DfB36fFFABa6093BAf7f1622;

    function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function getSymbol() external view returns (string memory) {
        return symbol;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getSender() external view returns (address) {
        return msg.sender;
    }
  
}