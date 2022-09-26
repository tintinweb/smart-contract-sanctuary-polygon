/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract KatacroketCoin{
    uint256 maxTotalSupply = 10000000; // state veriable / storage
    string tokenName = "KatacroketCoin";
    string tokenSymbol = "KCT";
    address owner = 0x3d91aE34907b282034283D4b28A3724deC3B3b48;

    modifier onlyOwner {
    require(owner == msg.sender);
    _;   // <--- note the '_', which represents the modified function's body
    }

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    function  getMaxTotalSupply() external view returns (uint256) {
        return  maxTotalSupply;
    }

    function getTokenName() external view returns (string memory) {
        return tokenName;
    }

    function getTokenSymbol() external view returns (string memory) {
        return string.concat("The symbol of this fantastic token is: ", tokenSymbol);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

}