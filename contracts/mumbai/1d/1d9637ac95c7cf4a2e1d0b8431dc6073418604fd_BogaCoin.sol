/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BogaCoin {
    uint256 maxTotalSupply = 1520;
    string name = "Byboga Coin";
    string symbol = "BBC";


    function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

    function setMaxTotalSuplly(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }
    
    function getOwner() external pure returns (address) {
        address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        return owner;
    }
    
    function getName() external view returns (string memory) {
        return name;
    }

    function getSymbol() external view returns (string memory) {
        return symbol;
    }

    function getSender() external view returns (address) {
        return msg.sender;
    }

}