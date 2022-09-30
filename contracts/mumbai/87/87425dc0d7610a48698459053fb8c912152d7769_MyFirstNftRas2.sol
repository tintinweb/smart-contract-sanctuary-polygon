/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract MyFirstNftRas2 {

    string name = "RasCoin" ;

    string symbol= "RAS" ;

    uint256 maxTotalSupply = 10000;

    uint256 circulatingTotalSupply = 5000;

    address currentOwnerAdress= 0xb87B03Fba8D60A6Eb00F1c203Cb91A611E3ABbFb ;

    function getTotalSupply () external view returns (uint256) {
        return maxTotalSupply ;
    }

    function getCirculatingTotalSupply () external view returns (uint256) {
        return circulatingTotalSupply ;
    }

    function getOwner () external view returns (address) {
        return currentOwnerAdress ;
    }

    function setMaxTotalSupply (uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply ;
    }

    function setNewOwner (address newOwner) external {
        currentOwnerAdress = newOwner ;
    }


}