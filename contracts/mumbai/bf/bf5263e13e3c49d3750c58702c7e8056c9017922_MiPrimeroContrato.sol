/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimeroContrato {
    string saludo = "Hola desde el Workshop";
    uint256 public edad = 33;
    uint256 anio;

    function leerAnio() public view returns(uint256) {
        return anio;
    }

    function actualizarEdad(uint256 nuevaEdad) public {
        edad = nuevaEdad;
    }
}