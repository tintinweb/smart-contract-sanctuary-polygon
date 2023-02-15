/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract HelloWorld {
    string mensaje;
    address public creador;

    constructor() {
        mensaje = "Hello World";
        creador = msg.sender;
    }

    function getMessage() public view returns(string memory) {
        return mensaje;
    }

    function setMessage(string memory nuevoMensaje) public {
        mensaje = nuevoMensaje;
    }

    function deleteSC() public {
        require(msg.sender == creador, "Solo el creador puede destruir el Smart Contract");
        selfdestruct(payable(creador));
    }
}