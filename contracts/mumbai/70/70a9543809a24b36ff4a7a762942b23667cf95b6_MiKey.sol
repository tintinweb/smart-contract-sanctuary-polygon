/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MiKey {
   string saludo = "Hola desde el workshop";

   //Valor máximo de uint256: 2^256 -1
   //unit unsigned integer
   //unsigned significa sin signo (npumero positivo +0 )
   //Si agregar public a uan variable solidity al compilar genera un getter
   uint256 edad = 23;

   //Solidity inicializa todas las variables por default es 0 o "", depende del tipo de dato
   //uint256 => 0
   //string => ""
   //bool => false
   //En solidity no existe el tipo de dato null y undefined
   uint256 public anio;


   //getter
   //nos permite leer variavles
   //el método será usado por usuarios externos --> public | internal
   //read-only: solo lectura
   //view: se añade método de solo lectura
   //todo mpetodo de lectura especifica los tipos de datos de ser vueltos

   function leerEdad () public  view returns(uint256) {
       return edad;
   }


   //setter
   
   function actualizarEdad(uint256 nuevaEdad) public {
       edad = nuevaEdad;
   } 

}