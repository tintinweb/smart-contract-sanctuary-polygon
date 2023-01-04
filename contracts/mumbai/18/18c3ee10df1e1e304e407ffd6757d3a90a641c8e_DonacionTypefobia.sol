/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract DonacionTypefobia {
    address private admin;
    address public creador;
    uint256 public total;
    uint256 public dnID;
    mapping(uint256 => address) public donaciones;

    event Donacion(address indexed Donador, uint indexed Monto);

    constructor() {
        // Admin será la única persona que puede sacar el dinero del contrato
        admin = address(0x87c9ADAEA58209abc771bFF5F70bFE71535D67df);
        creador = msg.sender;
    }

    function fondos() public view returns(uint256) {
        return address(this).balance;
    }

    function donar() public payable  {
        require(msg.value >= 0.01 ether, "La donaci\u00F3n m\u00EDnima es de 0.01 MATIC");
        donaciones[dnID] = msg.sender;
        dnID++;
        total += msg.value;
        emit Donacion(msg.sender, msg.value);
    }

    function retirarFondos(uint256 monto) public payable {
        require(msg.sender == admin, "Solo el administrador puede retirar los fondos");
        payable(admin).transfer(monto);
    }

    receive() external payable {
        // Esta función permitirá recibir donaciones sin restricción de monto
        // por medio de una llamada de bajo nivel, pero no serán indexadas
        donaciones[dnID] = msg.sender;
        dnID++;
        total += msg.value;
    }
}