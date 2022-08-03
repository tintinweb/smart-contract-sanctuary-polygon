/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MesaRecomendaciones {

    struct Recomendacion {
        string recomendacion;
        string tipo;
        string precio;
        string activo;
        string cliente;
        uint fecha;
    }

    Recomendacion[] public recomendaciones;
    uint256 public totalRecomendaciones;
    address public maestro = address(0xaEeaA55ED4f7df9E4C5688011cEd1E2A1b696772);

    constructor() {}

    function agregarRecomendacion(string memory _recomendacion,  string memory _tipo, string memory _precio, string memory _activo, string memory _cliente) public {
        require(msg.sender == maestro, "solo maestro.");
        recomendaciones.push(Recomendacion({
            recomendacion: _recomendacion,
            tipo: _tipo,
            precio: _precio,
            activo: _activo,
            cliente: _cliente,
            fecha: block.timestamp
        }));
        totalRecomendaciones++;
    }

    /*function verRecomendacion(uint256 recomendacionID) public view returns(string memory recomendacion, string memory tipo, string memory precio, string memory activo, string memory cliente, uint fecha) {
        Recomendacion memory rec = recomendaciones[recomendacionID];

        recomendacion = rec.recomendacion;
        tipo = rec.tipo;
        precio = rec.precio;
        activo = rec.activo;
        cliente = rec.cliente;
        fecha = rec.fecha;

        return(recomendacion, tipo, precio, activo, cliente, fecha);
    }*/
}