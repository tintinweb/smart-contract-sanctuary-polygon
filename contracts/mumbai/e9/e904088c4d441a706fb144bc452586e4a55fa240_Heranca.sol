/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract Heranca {
    mapping  (string => uint) valorAReceber;

    function escreverValor ( string memory _nome,uint valor) public  {
        valorAReceber[_nome] = valor;
    }

    function pegarValor(string memory _nome) public view returns (uint){
        return valorAReceber[_nome];
    } 
}