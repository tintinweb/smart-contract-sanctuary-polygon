/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MesaRecomendaciones {

    struct Recomendacion {
        string dato11;
        string dato22;
        string dato33;
        string dato44;
        string dato55;
        string dato66;
        uint fecha;
    }

    Recomendacion[] public recomendaciones;
    uint256 public totalRecomendaciones;
    address public maestro = address(0xaEeaA55ED4f7df9E4C5688011cEd1E2A1b696772);

    constructor() {}

    function agregarRecomendacion(string memory _dato11, string memory _dato22, string memory _dato33, string memory _dato44, string memory _dato55, string memory _dato66) public {
        require(msg.sender == maestro, "solo maestro.");
        recomendaciones.push(Recomendacion({
            dato11: _dato11,
            dato22: _dato22,
            dato33: _dato33,
            dato44: _dato44,
            dato55: _dato55,
            dato66: _dato66,
            fecha: block.timestamp
        }));
        totalRecomendaciones++;
    }
}