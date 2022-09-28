/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract PacheraCoin {
    uint256 maxTotalSupply = 333;
    string symbol = "PACH";
    string name = "Pachera";

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    function getMaxTotalSupply() external view returns (uint256) {
        return maxTotalSupply;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function getSymbol() external view returns (string memory) {
        return symbol;
    }

    function getOwner() external pure returns (address) {
        address owner = 0x73E112D9a2B5E5e04d6b7ef2C9eE5Ceea236978f;
        return owner;
    }

    function getSender() external view returns (address) {
        return msg.sender;
    }
}