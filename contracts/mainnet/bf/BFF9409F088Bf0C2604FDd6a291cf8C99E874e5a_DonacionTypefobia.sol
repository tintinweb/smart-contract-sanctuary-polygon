/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract DonacionTypefobia {
    struct TxInfo {
        address donador;
        uint256 monto;
    }

    address private admin;
    bool private bloqueado;
    uint256 private donacionID;
    uint256 public total;
    mapping(uint256 => TxInfo) public donaciones;

    event Donacion(address indexed Donador, uint256 indexed Monto);

    constructor() {
        // Admin será la única persona que puede sacar el dinero del contrato
        admin = msg.sender;
    }

    modifier soloAdmin() {
        require(msg.sender == admin, "Solo disponible para el administrador");
        _;
    }

    modifier noReentrada() {
        require(!bloqueado, "No re-entrada");
        bloqueado = true;
        _;
        bloqueado = false;
    }

    function fondos() public view returns (uint256) {
        return address(this).balance;
    }

    function registrarDonacion() private {
        donaciones[donacionID] = TxInfo(msg.sender, msg.value);
        donacionID++;
        total += msg.value;
    }

    function donar() public payable {
        require(msg.value >= 0.01 ether, "Debe ser mayor a 0.01 MATIC");
        registrarDonacion();
        emit Donacion(msg.sender, msg.value);
    }

    function cambiarAdmin(address nuevoAdmin) public soloAdmin {
        admin = nuevoAdmin;
    }

    function retirarFondos(uint256 monto) public soloAdmin noReentrada {
        require(
            monto <= address(this).balance,
            "El monto es mayor al balance del contrato"
        );
        payable(admin).transfer(monto);
    }

    receive() external payable {
        // Esta función permitirá recibir donaciones sin restricción de monto
        // por medio de una llamada de bajo nivel, pero no serán indexadas
        registrarDonacion();
    }
}