/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PalaciosCryptoToken {
    uint256 maxTotalSupply = 1000000;
    string TokenName = "PalaciosCrypto";
    string TokenSymbol = "PLC";

    function setMaxTotalSupply(uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    function getmaxTotalSupply() external view returns(uint256){
        return maxTotalSupply;
    }

    function getOwner() external pure returns(address){
        address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        return owner;
    }

    function getTokenName() external view returns(string memory){
        return TokenName;
    }

    function getTokenSymbol() external view returns(string memory){
        return TokenSymbol;
    }
}