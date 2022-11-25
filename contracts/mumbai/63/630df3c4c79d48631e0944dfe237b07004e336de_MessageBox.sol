/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MessageBox {
    string[] mensaje;
    address public propietario;

    constructor()  {
        mensaje.push("Hello world");
        propietario = msg.sender;
    }
    
    function addMessage(string memory nuevoMensaje) public {
         mensaje.push(nuevoMensaje);
    }

    function getMessages() public view returns(string[] memory)  {
        return mensaje;
    }

    function destruirSC() public {
        require(msg.sender == propietario, "solo el propietario puede llamar a esta funcion");
        selfdestruct(payable(propietario));
    }

}