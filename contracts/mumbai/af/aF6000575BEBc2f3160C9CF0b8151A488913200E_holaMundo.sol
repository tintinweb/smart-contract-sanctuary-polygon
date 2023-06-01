/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract holaMundo {
    string private mensaje;

    function mensaje_getter() external view returns(string memory){
        return(mensaje);
    }

    function mensaje_setter(string calldata _mensaje) external {
        mensaje = _mensaje;
    }
}