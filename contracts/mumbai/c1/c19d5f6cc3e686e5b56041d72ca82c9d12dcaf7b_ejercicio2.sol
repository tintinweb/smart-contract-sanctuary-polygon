/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ejercicio2 {
uint256 maxTotalSupply = 1000;


function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;

    }

 function getOwner () external pure returns (address) {
        address owner = 0x0Bcef0115CE317BEebC40F3b55314e98A8BBa1F0; // variable local / memory / volatil
        return owner;

    }


function getTokenName() external pure returns (string memory) {
        string memory tokenName = "fibopapitoken";
        return tokenName;
}

function getTokenTicker() external pure returns (string memory) {
        string memory tokenTicker = "FBT";
        return tokenTicker;
}
}