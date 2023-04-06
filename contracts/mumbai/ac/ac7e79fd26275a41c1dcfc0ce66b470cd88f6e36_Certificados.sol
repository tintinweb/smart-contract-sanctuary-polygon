/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT
/**
* @title certificadosDip
* @dev ContractDescription
* @custom:dev-run-script remix/certificados.sol
*/

contract certificadosDip {}

pragma solidity ^0.8.0;

contract Certificados {
    struct Certificado {
        uint id;
        string orgaoEmissor;
        string nomeAluno;
        uint cpf;
        string dataConclusao;
    }

    mapping(uint => Certificado) certificados;

    function salvarCertificado(uint _id, string memory _orgaoEmissor, string memory _nomeAluno, uint _cpf, string memory _dataConclusao) public {
        certificados[_id] = Certificado(_id, _orgaoEmissor, _nomeAluno, _cpf, _dataConclusao);
    }

    function enviarCertificado(uint _id, address payable _carteira1, address payable _carteira2) public {
        require(certificados[_id].id != 0, "Certificado nao encontrado");

        bytes memory payload = abi.encodePacked(certificados[_id].id, certificados[_id].orgaoEmissor, certificados[_id].nomeAluno, certificados[_id].cpf, certificados[_id].dataConclusao);

        (bool success1, ) = _carteira1.call{value: 0}(payload);
        require(success1, "Falha no envio para carteira 1");

        (bool success2, ) = _carteira2.call{value: 0}(payload);
        require(success2, "Falha no envio para carteira 2");
    }
}