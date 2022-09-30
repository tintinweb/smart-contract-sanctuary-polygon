/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract MyFirstNftRas {

//6).Guarde el nombre del token

    string name = "RasCoin" ;

//7).Guarde el símbolo del token  (symbol)

    string symbol= "RAS" ;

//1).Guarde el “maxTotalSupply” inicializado a un número

    uint256 maxTotalSupply = 10000;

    uint256 circulatingTotalSupply = 5000;

//4).Guarde el “owner” inicializado a una address.

    address currentOwnerAdress= 0xb87B03Fba8D60A6Eb00F1c203Cb91A611E3ABbFb ;

//3).Una función llamada “getMaxTotalSupply” que devuelva el maxTotalSupply

    function getMaxTotalSupply () external view returns (uint256) {
        return maxTotalSupply ;
    }

    function getCirculatingTotalSupply () external view returns (uint256) {
        return circulatingTotalSupply ;
    }

//5).Una función llamada “getOwner” que nos devuelva la dirección del owner.

    function getOwner () external view returns (address) {
        return currentOwnerAdress ;
    }

//2).Una función llamada “setMaxTotalSupply” para modificar esa variable.

    function setMaxTotalSupply (uint256 newMaxTotalSupply) internal  {
        maxTotalSupply = newMaxTotalSupply ;
    }

    function setNewOwner (address newOwner) internal  {
        currentOwnerAdress = newOwner ;
    }


}