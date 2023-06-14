/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BNBStorage {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        // Permitir depósitos desde cualquier billetera
        require(msg.value > 0, "El valor del deposito debe ser mayor a cero");
    }

    function withdraw() external {
        require(msg.sender == owner, "Solo el propietario puede realizar retiros");
        uint256 balance = address(this).balance;
        require(balance > 0, "No hay BNB para retirar");
        payable(msg.sender).transfer(balance);
    }
}