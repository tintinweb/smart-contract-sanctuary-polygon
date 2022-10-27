// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract TesteUsuario {

  constructor() {}

  uint256 numero;

  function adicionarNumero(uint256 _numero) public {
    numero = _numero; 
  }

  function verNumero() public view returns(uint256) {
    return numero;
  }

}