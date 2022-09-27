/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract LauraCoin {
    uint256 maxTotalSupply = 3333;
    string name = "Laura";
    string symbol = "LAU";
    address owner = 0xA23debA903483Fc651C09918e358DFC3C5318025;

    function getMaxTotalSupply () external view returns (uint256) {
        return maxTotalSupply;
    }
    
    function setMaxTotalSupply (uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    function getOwner () external view returns (address) {
        return owner;
    }

    function getName () external view returns (string memory) {
        return name;
    }

    function getSymbol () external view returns (string memory) {
        return symbol;
    }
}