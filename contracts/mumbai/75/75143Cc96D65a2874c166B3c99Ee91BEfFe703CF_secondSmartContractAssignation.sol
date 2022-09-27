/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract secondSmartContractAssignation {
    uint256 maxTotalSupply = 50000;
    string tokenName = "Second Assignament Smart Contract";
    string tokenSymbol = "SASC";

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external  { 
        maxTotalSupply = newMaxTotalSupply;
    }

    function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

    function getOwner() external pure returns (address) {
        address contractOwnwer = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        return contractOwnwer;
    }

    function getTokenName() external view returns (string memory) { 
        return tokenName;
    }

    function getTokenSymbol() external view returns (string memory) { 
        return tokenSymbol;
    }

}