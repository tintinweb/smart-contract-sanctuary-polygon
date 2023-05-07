/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContrato {
 
    string saludo = "Hola";

    
    function cambiarSaludo(string memory nuevoSaludo) public {
        saludo = nuevoSaludo;
    }

    
    function leerSaludo() public view returns (string memory) {
        return saludo;
    }
}