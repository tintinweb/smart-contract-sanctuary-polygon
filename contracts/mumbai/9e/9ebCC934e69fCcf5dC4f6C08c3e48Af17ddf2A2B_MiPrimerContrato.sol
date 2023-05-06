// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract MiPrimerContrato {
    // storage - almacenamiento eterno
    string saludo;

    // métodos
    function set(string memory _nuevoSaludo) public {
        saludo = _nuevoSaludo; // no se necesita 'this'
    }

    function get() public view returns (string memory) {
        return saludo;
    }
}