/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Ficheros {
    uint256 public myBalance;

    struct Estructura_Ficheros {
        string descripcion;
        int fecha;
        string codificacion;
    }

    mapping(uint256 => Estructura_Ficheros) public Escrituras_indice;
    uint256[] public Array_Escrituras;

    function Registrar(string memory _descripcion, int _fecha, string memory _codificacion) public {
        Escrituras_indice[Array_Escrituras.length] = Estructura_Ficheros(
        _descripcion,
        _fecha,
        _codificacion
        );
        Array_Escrituras.push(Array_Escrituras.length);
    }

    function getElements() public view returns (Estructura_Ficheros[] memory) {
        uint256 arrayLength = Array_Escrituras.length;

        Estructura_Ficheros[] memory result = new Estructura_Ficheros[](
            arrayLength
        );

        for (uint256 i = 0; i < arrayLength; i++) {
            uint256 key = Array_Escrituras[i];
            result[i] = Escrituras_indice[key];
        }
        return result;
    }


}