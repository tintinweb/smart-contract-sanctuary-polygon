/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;



contract NFTSTORE {


mapping(address _billetera=> bool conectado) public usuariosConectado;

    function usuarioConectado(address _billetera) public {
        usuariosConectado[_billetera] = true;
    }
    function usuarioDesConectado(address _billetera) public {
        usuariosConectado[_billetera] = false;
    }
}