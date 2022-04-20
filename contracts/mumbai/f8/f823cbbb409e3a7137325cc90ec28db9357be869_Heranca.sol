/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Heranca {
// 0xAf793B6CB781a344e89eC15d40bF2Ae337323036

    mapping(string => uint) public valorAReceber;
    // address é um tipo de variável
    address public owner = msg.sender;

    function escreveValor(string memory _nome, uint valor) public {
        require(msg.sender == owner);
        valorAReceber[_nome] = valor;
    }

    // visibilidade: public, private, external, internal
    function pegaValor(string memory _nome) public view returns (uint) {
        return valorAReceber[ _nome];
    }
}