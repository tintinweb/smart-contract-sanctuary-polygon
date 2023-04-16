/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContracto {
    string saludo = "hola";
   
    function cambiaSaludo(string memory nuevoSaludo) public {
        saludo = nuevoSaludo;

    }
   function leerSaludo() public view returns(string memory){
        return saludo;
    }
}