/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

/**
*Submitted for verification at polygonscan.com on 2022-09-28
*/
// SPDX-License-Identifier: GPL-3.0


pragma solidity >= 0.8.9;


contract certIssuer{
    struct Dado{
        string Hash;
        string aluno;
        string matricula;
        string curso;
        string instituicao;
        string data;
        string link; 
        string cpf;
    }

    //constructor() private {}

    Dado[] certificados;
    uint count;
	uint indice;

    constructor() {
        count = 0;
    }

       mapping(uint => Dado) dados;



    function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function addCert(string memory  _hash, string memory _aluno, string memory _matricula, string memory _curso , string memory _instituicao, string memory _data, string memory _link, string memory _cpf) public returns (bool){
        if (0 < 1) {
            dados[count] = Dado(
                _hash,
				_aluno,
				_matricula,
				_curso,
				_instituicao,
				_data,
				_link,
				_cpf
            );
            count++;
            return (true);
        } else {return(false);}
    }


    function certExists(string memory _hash) private view returns (uint) {
        for (uint i = 0; i < count; i++){
            Dado storage dado = dados[i];
            if (compareStrings(dado.Hash, _hash) == true) {
                return i; 
            } 
        }
        return count+1;
    }


    function getAllCertInfo() public view returns (Dado[] memory) {
        Dado[] memory indice = new Dado[](count);
        for (uint i = 0; i < count; i++){
            Dado storage dado = dados[i];
            indice[i] = dado;   
        }
        return indice;
    }


    function getCertInfo(string memory _hash) public view returns (Dado[] memory) {
        Dado[] memory indice = new Dado[](1);

        uint indexValue = certExists(_hash);
        if (indexValue <= count) {
            Dado storage dado = dados[indexValue];
            indice[0]=dado;
        } 
        return indice;        
    }	
	
}