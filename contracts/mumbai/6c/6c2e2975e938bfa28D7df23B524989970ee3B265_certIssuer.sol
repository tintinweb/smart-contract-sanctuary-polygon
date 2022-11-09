/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

/**
*Submitted for verification at polygonscan.com on 2022-09-28
*/
// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.7;



contract certIssuer{
    struct Dados{
        uint Hash;
        string aluno;
        string matricula;
        string curso;
        string instituicao;
        string data;
        string link; 
        string cpf;
    }

    //constructor() private {}

    Dados[] certificados;
    Dados private dado;
    uint count;

       mapping(uint => Dados) Dado;

    constructor() {
        count = 0;
    }


 //   function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
//        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
//    }
    function addCert(uint  _hash, string memory _aluno, string memory _matricula, string memory _curso , string memory _instituicao, string memory _data, string memory _link, string memory _cpf) public {

        dado = Dados(_hash,_aluno,_matricula,_curso,_instituicao,_data,_link,_cpf);
        certificados.push(dado); 
        count++;

    }
    function printAllCert() public view returns (Dados[] memory) {
        Dados[] memory index = new Dados[](count);
          for (uint i = 0; i <= count; i++){
            Dados storage dados = Dado[i];
            index[i]= dados;
        }
        return index;
    }

       function certExist(uint _hash) public view returns (uint) {
        for (uint i = 0; i <= count; i++){
            Dados storage dados = Dado[i];
            if (dados.Hash == _hash){
                return i; 
            } 
        }
        return count+1;
    }

   function getNumCert() public view returns (uint) {
        return count;
    }

        function getCertByHash(uint _hash) public view returns (Dados[] memory) {
        Dados[] memory index = new Dados[](1);
        uint i = 0;

        uint indexValue = certExist(_hash);
        if (indexValue <= count) {
            Dados storage dados = Dado[indexValue];
            index[i]=dados;
            i++;
        } 
        return index;
    }
}