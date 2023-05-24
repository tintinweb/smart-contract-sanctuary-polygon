/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract SegundaClase {
    string saludo = "Hola desde el Taller";
    
    // Valor máximo de uint256:0 hasta 2^256 -1
    // uint significa entero sin signo
    // unsigned significa sin signo (números positivos + 0)
    // si le ponemos publico a una variable, Solidity crea su getter
    uint256  public edad = 33;

    // Solidity inicializa todas las variables a un valor por defecto
    // El valor por defecto depende del tipo de dato
    // uint256 => 0
    // cadena => ""
    // booleano => falso
    // En solidez no existe indefinido o nulo
    uint256 anio; 


    // getter
    // nos permite leer variables del smart contract
    // read-only: solo lectura (no altera ninguna variable)
    // public: indica que este metodo sera usado por usuarios externos
    // view: se añade a métodos de solo lectura
    // todo método de lectura especifica los tipos de datos a ser devueltos
    function leerAnio() public view returns(uint256) {
        return anio;
    }

    // colocador
    function actualizarEdad(uint256 nuevaEdad) public {
        edad = nuevaEdad;
    }
}