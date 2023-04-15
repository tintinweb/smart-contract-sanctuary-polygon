/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract myPrimerContrato {

// variables siempre son tipadas y siempre empiezan inicializadas
    uint256 a =10;
    string saludo = "hola!";
    bool esCierto= false;


    uint otroEntero;
    string otroString;
    bool otroBool;


// todo parametro debe llevar su tipo de dato
    function cambiarSaludo(string memory nuevoSaludo) public  {
        saludo = nuevoSaludo;
    }

// visibilidad de la funcion
// - public: si quiere ser usado desde afuera
// - internal: solo si se llamara dentro del contarto y cuandos sea HEREDADO
// - private: solo si se usara dentro SOLO y UNICAMENTE en este contrato
// visbilidad de getter y setter
// - view: solo es lectura
// - 

// getter -> como leer info , metodos de solo lectura, no existe cmabio de estado, suelen ser view
// setter -> metofdos para asignar valores
    function leerSaludo() public view returns(string memory) {
        return saludo; 
    }


}