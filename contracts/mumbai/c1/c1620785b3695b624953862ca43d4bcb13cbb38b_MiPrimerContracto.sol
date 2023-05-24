/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract MiPrimerContracto {
    string saludo = "Hola desde el Workshop";

    // Valor maximo de uint256: 0 hasta 2ˆ256 -1
    // unit significa unsigned integer
    // unsigned significa sin signo (números positivos + 0)
    // si le ponemos public a una variable, Solidity crea su getter
    uint256 edad = 33;

    // Solidity inicializa todas las variables a un valor por defecto
    // El valor por defecto depende del tipo de dato
    // uint256 => 0
    // string => ""
    // bool => false
    // En solidity no existe undefined o null
    uint256 anio;


    // getter
    // nos permite leer variables del smart contract
    // read-only: solo lectura (no altera ninguna variable)
    // public: indica que este método será usado por usuarios externos
    // view: se añade a métodos de solo lectura
    // todo método de lectura especifica los tipos de datos a ser devueltos
    function leerAnio() public view returns (uint256) {
        return anio;
    }

    // setter
    function actualizarEdad(uint256 nuevaEdad) public {
        edad = nuevaEdad;
    }
}