/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MesaRecomendaciones {

    struct Recomendacion {
        string recomendacion;
        string activo;
        string cliente;
        uint fecha;
    }

    Recomendacion[] private recomendaciones;
    uint256 public totalRecomendaciones;
    address public maestro = address(0xaEeaA55ED4f7df9E4C5688011cEd1E2A1b696772);

    constructor() {}

    function agregarRecomendacion(string memory _recomendacion, string memory _activo, string memory _cliente) public {
        require(msg.sender == maestro, "solo maestro.");
        recomendaciones.push(Recomendacion({
            recomendacion: _recomendacion,
            activo: _activo,
            cliente: _cliente,
            fecha: block.timestamp
        }));
        totalRecomendaciones++;
    }

    function verRecomendacion(uint256 recomendacionID) public view returns(Recomendacion memory) {
        return recomendaciones[recomendacionID];
    }
}