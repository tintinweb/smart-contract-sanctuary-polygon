/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContrato {
    // STORAGE
    // definir variables
    // uint256 => integer (entero)
    uint256 a = 10;
    string saludo = "Hola";
    bool esCierto = false;

    uint256 otroEntero; // Solidity assigna a otroEntero el valor de 0
    string otraCadena; // Solidity assigna a otraCadena el valor de ""
    bool otroBool; // Solidity assigna a otroBool el valor de false

    // definiar metodos (setter)
    // todo parámetro lleva su tipo de dato
    // definir visibilidad de la función
    //   - public: que será usado por un usuario
    //   - internal: no sera usado por un usuario. 
            // solo desde adentro del smart contract
    //   - private: que solo se puede usar dentro del smart contract
    //         los metodos definidos como internal se pueden heredar
    function cambiarSaludo(string memory nuevoSaludo) public {
        // cambio de estado (información)
        saludo = nuevoSaludo;
    }

    // definir getter (cómo leer información)
    // métodos de solo lectura (read-only)
    // no existe un cambio de estado
    // en Solidity los valores de retorno también llevan su tipo de dato
    // En general, los métodos getter son de visibilidad 'view'
    // Definimos si se puede usar este metodo desde afuera o no
    function leerSaludo() public view returns(string memory){
        return saludo;
    }

    // definir eventos
    // definir constantes
}