/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//Crea un Smart Contract llamado “TuNombreCoin”
contract JorgeCoin  {
    //Guarde el nombre del token
    //Guarde el símbolo del token  (symbol)
    //Guarde el “maxTotalSupply” inicializado a un número
    //Guarde el “owner” inicializado a una address
    string TokenName = "JorgeCoin";
    string TokenSymbol = "JRG";
    uint maxTotalSupply = 555;
    address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    //Una función llamada “setMaxTotalSupply” para modificar esa variable.
    //Una función llamada “getMaxTotalSupply” que devuelva el maxTotalSupply
    function getmaxTotalSupply() public view returns (uint){
        return maxTotalSupply;
    }

    function setmaxTotalSupply(uint newMaxTotalSupply) public {
        maxTotalSupply = newMaxTotalSupply;
    }
    //Una función llamada “getOwner” que nos devuelva la dirección del owner.
     function getowner() public view returns (address){
        return owner;
    }
}