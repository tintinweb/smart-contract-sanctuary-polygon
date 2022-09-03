/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// Tipo de licencia
// SPDX-License-Identifier: MIT

// Versión del compilador
pragma solidity 0.8.16;

// Empezamos cumpliendo con las reglas de estilo
// Todo el SC se desarrollara en ingles variables,comentarios,strings...
// Nombre del contrato "Storage" que coincidirá siempre con el nombre del fichero
// y siempre empezará en mayusculas.

contract Storage {

    // Asignamos una variable de tipo número entero. 
    // Uint 256 y uint es exactamente lo mismo las dos formas son correctas.
    uint256 number;

    // Vamos a desarrollar nuestra primera función 
    // Introduciremos dato en la variable "num" INPUT
    // Al nombre de la función la vamso a llamar "getNum" 
    // En visibilidad pondremos "public"
    // En el cuerpo le decimos a la variable number que tome el valor de num
    function getNum(uint num) public {
        number = num;
    }

    // Vamos a desarrollar la segunda función 
    // Esta nops devolvera los datos introducidos en la "function getNum" OUTPUT
    // Al nombre de la función la vamso a llamar "setNum" 
    // En visibilidad pondremos "public" 
    // en el ....   pondremos "view"
    // Utilizatremos returns ua que queremos que nos devuelva el dato de la variable
    // y indicamos entre parentesis el tipo de variable en este caso "uint"
    function setNum() public view returns (uint) {
        //en el cuerpo la instruccion "return" da la orden para quq se devuelva el valor de "number"
        return number;
    }
}

// ya tenemos nuestro primer contrato