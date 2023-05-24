/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract Worshop {
    string saludo = "hola";
    uint256 public edad = 33;
    uint anio;

    function leerAnio() public view returns(uint256) {
        return anio;
    }

function actualizarEdad(uint256 nuevaEdad) public {
    edad = nuevaEdad;
   }
}