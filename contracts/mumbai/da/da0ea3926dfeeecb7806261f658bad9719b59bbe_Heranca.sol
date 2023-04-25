/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Heranca {
    mapping  (string => uint) valorAReceber;

    address public owner = msg.sender;

    function escreverValor ( string memory _nome,uint valor) public  {
        require(msg.sender == owner);
        valorAReceber[_nome] = valor;
    }

    function pegarValor(string memory _nome) public view returns (uint){
        return valorAReceber[_nome];
    } 
}