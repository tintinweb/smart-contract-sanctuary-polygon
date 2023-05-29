// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract MiPrimerContrato {
    string saludo;

    function set(string memory _nuevoSaludo) public {
        saludo = _nuevoSaludo;
    }

    function get() public view returns (string memory) {
        return saludo;
    }
}