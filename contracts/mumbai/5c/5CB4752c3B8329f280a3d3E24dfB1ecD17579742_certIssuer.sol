/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

/**
*Submitted for verification at polygonscan.com on 2022-09-28
*/
// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract certIssuer{
    struct Dados{
        uint id;
        string aluno;
        string matricula;
        string curso;
        string instituicao;
        string data;
        string link; 
        string cpf;
    }

    Dados[] certificados;
    Dados private dado;
    function add(uint  _id, string memory _aluno, string memory _matricula, string memory _curso , string memory _instituicao, string memory _data, string memory _link, string memory _cpf) public {
        
        dado = Dados(_id,_aluno,_matricula,_curso,_instituicao,_data,_link,_cpf);
        certificados.push(dado); 
    }
}