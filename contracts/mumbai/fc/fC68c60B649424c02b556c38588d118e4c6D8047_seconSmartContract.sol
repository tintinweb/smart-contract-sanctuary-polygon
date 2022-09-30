/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract seconSmartContract {
    uint256 maxTotalSupply = 50;

    function getMaxTotalSuplly() external view returns(uint256) {
        return maxTotalSupply;
    }

    function getOwner() external pure returns(address) {
        address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        return owner;
    }

    string name = "ypmancoin";

    function getNameToken() external view returns(string memory) {
        return name;
    }

    string symbol = "YP";

    function getSymbolToken() external view returns(string memory) {
        return symbol;
    }
}