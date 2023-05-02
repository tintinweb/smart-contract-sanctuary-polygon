/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test {

uint nombre;

function getNombre() public view returns (uint) { 
    return nombre;

}

function setNombre(uint _nombre) public {
    nombre = _nombre;

}

}