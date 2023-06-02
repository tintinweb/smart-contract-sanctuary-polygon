// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MiPrimerContrato {
    uint256 anio;

    function guardarAnio(uint256 _nuevoAnio) public {
        anio = _nuevoAnio;
    }

    function obtenerAnio() public view returns (uint256) {
        return anio;
    }
}