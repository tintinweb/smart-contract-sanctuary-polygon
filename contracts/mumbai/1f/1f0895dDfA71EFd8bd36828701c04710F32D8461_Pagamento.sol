/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pagamento {
    address payable public vendedor;
    mapping(address => uint256) public montantePendente;

    event PagamentoRecebido(address pagador, uint256 valor);

    constructor(address payable _vendedor) {
        vendedor = _vendedor;
    }

    function pagar(uint256 montante) external payable {
        require(montante > 0, "O montante do pagamento deve ser maior que zero");
        require(msg.value >= montante, "O valor enviado nao e suficiente para o montante especificado");

        montantePendente[msg.sender] += montante;

        emit PagamentoRecebido(msg.sender, montante);
    }

    function transferirPagamento() external {
        uint256 montante = montantePendente[msg.sender];
        require(montante > 0, "Nao ha montante pendente para transferir");

        montantePendente[msg.sender] = 0;
        (bool success, ) = vendedor.call{value: montante}("");
        require(success, "Falha na transferencia de pagamento");
    }
}