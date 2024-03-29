/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContrato {
    uint256 edad = 234;
    uint256 public anio = 2023;

    function obtenerEdad() public view returns(uint256) {
        return edad;
    }

    function cambiarEdad(uint256 nuevaEdad) public {
        edad = nuevaEdad;
    }
}