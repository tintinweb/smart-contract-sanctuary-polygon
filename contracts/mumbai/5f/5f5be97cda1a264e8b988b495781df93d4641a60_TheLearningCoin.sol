/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract TheLearningCoin {
    uint256 MaxTotalSupply = 500;
    address owner = 0x23E579fD443f3723a2b2840eb7b101B0B8a0964e;
    string TokenName = "The Learning Coin";
    string Symbol = "TLC";

    
    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        MaxTotalSupply = newMaxTotalSupply;
    }

    function getMaxTotalSupply() external view returns (uint256) {
        return MaxTotalSupply;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getTokenName() external view returns (string memory) {
        return TokenName;
    }

    function getSymbol() external view returns (string memory) {
        return Symbol;
    }
}

// Practice smart contract from lesson n2 with Berenu.