/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity  0.8.18;

contract MiPrimerContrato {
    // storage (memoria permanete)
    // metodos
    string saludo = "hola";
   
    function cambiarSaludo(string memory NuevoSaludo) public {
        saludo = NuevoSaludo;

    }

    // vamos a crear un metodo getter o de lectura
    function leersaludo() public view returns(string memory) {
        return saludo;
    }
        
}