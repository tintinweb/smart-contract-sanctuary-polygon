// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract DepositarCryptos {

    struct Cuenta {
        uint256 saldo;
        bytes10 moneda;
    }

    mapping(address => mapping(bytes10 => Cuenta)) cuentas;

    function depositar(uint256 cantidad, bytes10 moneda) external payable {
        require(msg.value == cantidad, "Cantidad es incorrecta");
        Cuenta storage cuenta = cuentas[msg.sender][moneda];
        cuenta.saldo += cantidad;

        if(cuenta.moneda == "")
            cuenta.moneda = moneda;
    }

    function retirar(uint256 cantidad, bytes10 moneda, address payable wallet) external {
        Cuenta storage cuenta = cuentas[msg.sender][moneda];
        require(cuenta.saldo >= cantidad, "Saldo insuficiente");

        (bool success,) = wallet.call{value: cantidad}("");
        require(success, "No se ha realizado el retiro");

        cuenta.saldo -= cantidad;
    }

    function saldo(bytes10 moneda) external view returns(uint256){
        return cuentas[msg.sender][moneda].saldo;
    }
}