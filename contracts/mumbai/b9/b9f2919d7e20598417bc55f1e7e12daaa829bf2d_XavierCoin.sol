/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Ejercicio 2:  Crea un Smart Contract llamado “TuNombreCoin” que:

contract XavierCoin {

    // Guarde el “maxTotalSupply” inicializado a un número:
        uint256 maxTotalSupply = 100; // Variable de estado. Se almacena en el storage. Se declaran y asignan en la misma línea de código.

    // Una función llamada “setMaxTotalSupply” para modificar esa variable:
        // Estructura: function nameFunction(tipoVariable_1 newName_1, tipoVariable_2 newName_2) visibilidad mutabilidad returns (tipoVariable) {}
        //  *visibilidad: external or internal
        //  *Si la variable a devolver es una variable de estado / variable global debermos añadir "view" detrás de la visibilidad.
        //  *Si la variable a devolver es una variable local debermos añadir "pure" detrás de la visibilidad.
        //  *Las variables globales ha estan predefinidas. Pj: msg.sender
        //  *Si la función pretende modificar el valor de la variable de estado en la blockchain, deberemos eliminar el atributo "view"

        function setMaxTotalSupply (uint256 newMaxTotalSupply) external { 
            maxTotalSupply = newMaxTotalSupply;
        }
    // Una función llamada “getMaxTotalSupply” que devuelva el maxTotalSupply:
        function getMaxTotalSupply() external view returns (uint256) {
            return maxTotalSupply;
        }
    // Guarde el “owner” inicializado a una address:
        address owner = msg.sender;

    // Una función llamada “getOwner” que nos devuelva la dirección del owner:
        function getContractOwner() external view returns (address){
            return owner;
        }

    // Guarde el nombre del token:
        string coinName = "XavierCoin";

        function getCoinName() external view returns (string memory) {
            return coinName;
        }

    // Guarde el símbolo del token (symbol):
        string coinSymbol = "$XAV";
        
        function getCoinSymbol() external view returns (string memory) {
            return coinSymbol;
        }

    //El smart contract debe estar verificado y publicado en Mumbai. Además, debe haber una tx modificando el maxTotalSupply.

}