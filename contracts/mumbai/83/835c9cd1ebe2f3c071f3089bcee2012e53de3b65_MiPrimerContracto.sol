/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContracto {
    // definir variable
    // wint256 => integer *(entero)
    uint256 a = 10;
    string saludo = "hola";
    bool esCierto = false;

    uint256 otroEntero; //otroEntero es 0 que es valor por defecto
    string otraCandena; // valor inicial cadena vacia ""
    bool otroBool; // valor inicial falso


    // definir metodos (setter)
    // todo parametro lleva su tipo de dato
    // definir visibilidad de la funcion
    // public que sera usado por un usuario
    // internal que sera usado por un usuario solo desde dentro del SM
    //           se puede heredar
    // Private: que solo se puede usar dentro del SC
    function cambiaSaludo(string memory nuevoSaludo) public {
        // cambio de estado (informacion)
        saludo = nuevoSaludo;

    }


    // definir getter , como leer informacion
    // metodos de solo lectura (read-only)
    // no existe un cambio de estado
    // en solidity los valores de retoron tambien llevan su tipo de dato
    // En general, los metodos getter son de visivilidad view
    // Definimos si se puede usar este metodo desde afuera o no
    function leerSaludo() public view returns(string memory){
        return saludo;
    }
}