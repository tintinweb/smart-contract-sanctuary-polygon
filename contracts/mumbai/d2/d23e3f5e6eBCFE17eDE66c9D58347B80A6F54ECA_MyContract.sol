// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    constructor() {}

    uint numero = 0;


    function sumar() public{
        numero++;
    } 

    function verNumero() public view returns(uint){
        return numero;
    }

    function eliminarNumero()public{
        numero = 0;
    }
}