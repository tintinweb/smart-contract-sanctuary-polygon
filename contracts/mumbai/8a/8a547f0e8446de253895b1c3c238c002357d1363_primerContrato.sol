/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract primerContrato{
    //storage (memoria permamente)
    string saludo = "hola";

    // Métodos:
    // setters (modificar o escribir informacion)
    // getter (leer informacion)

    // Visibilidad en funciones:
    // public: el metodo puede ser usado o llamado por un usuario externo
    // private: solo puedo ser usado dentro del contrato.
    // internal:
    // external: 
    // view: indica que el metodo es de solo lectura.

    // Método setter:
    function cambiarSaludo(string memory nuevo_saludo) public {
        saludo = nuevo_saludo;
    }

    // Método getter:
    function leerSaludo() public view returns(string memory) {
        return saludo;
    }
}