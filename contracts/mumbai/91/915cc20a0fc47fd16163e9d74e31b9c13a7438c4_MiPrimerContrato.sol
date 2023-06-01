/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContrato {
    // unit: unsigned integer (Entero sin signo)
    // rango de unit256: [0 - 2^256 - 1]
    // Todas las unitX ocupan el mismo espacio de memoria en el SC
    uint256  edad = 234;

    // Solidity ha creado el getter de manera automatica.
    uint256 public anio = 2023;

    // valores default
    // Solidity define valores por defecto, dependiendo del tipo de dato.
    bool public esDeNoche;
    uint256 public cantidadDeAl;

    // getter
    // Es un metodo de lectura
    // view: se usa en metodos de solo lectura
    // public: sera usado por usuarios externos
    // private/internal: no sera usado por usuario externos

    function obtenerEdad() public view returns(uint256) {
        return edad;
    }

    // Settter
    // Metodo que escribe que guarda informacion
    function cambiarEdad(uint256 nuevaEdad) public {
        edad = nuevaEdad;
    }

}