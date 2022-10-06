/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract JonasCoin { 
    
    // Guarde el “maxTotalSupply” inicializado a un número

    uint256 maxTotalSupply = 5000; // declaracion  y asignacion variable maxTotalSupply
    
    // Una función llamada “setMaxTotalSupply” para modificar esa variable

    function setMaxTotalSupply (uint256 newMaxTotalSupply) external {
        maxTotalSupply = newMaxTotalSupply;
    }

    // Una función llamada “getMaxTotalSupply” que devuelva el maxTotalSupply

    function getMaxTotalSupply () external view returns (uint256) {
        return maxTotalSupply;
    }

    //Guarde el “owner” inicializado a una address

    address owner = 0xD3afcA4c828808BEA4a63D85b0A5225aDB9eA8a2; // declaracion  y asignacion variable maxTotalSupply

    //Una función llamada “getOwner” que nos devuelva la dirección del owner

    function getOwner () external view returns (address) {
        return owner;
    }

}