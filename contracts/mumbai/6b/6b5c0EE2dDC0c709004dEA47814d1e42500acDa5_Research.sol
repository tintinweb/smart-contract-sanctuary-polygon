/**
 *Submitted for verification at polygonscan.com on 2022-04-15
*/

//SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract Research {

    address private _creator;
    uint32 private _countVotes;
    uint8[] private _listOfVotes;
    /**
     * uint8: Número candidato
     * uint32: Quantidade de votos
     */    
    mapping(uint8 => uint32) private _candidates;
    /**
     * uint8: Título do eleitor
     * uint8: Número do candidato
     */
    mapping(uint8 => uint8) private _mappingOfVotes;

    constructor() {     
        _creator = msg.sender;
        _countVotes = 0;
        _candidates[13] = 0; //Lula
        _candidates[23] = 0; //Bolsonaro
        _candidates[12] = 0; //Ciro
        _candidates[45] = 0; //Joao Doria
        _candidates[1] = 0; //Nulos, Brancos, Não sabem        
    }
    
    function vote(uint8 voterId, uint8 candidateNumber) external { 
        bool voteExist = voteExists(voterId);
        require(voteExist != true, "Vote exists!");        

        _candidates[candidateNumber]++;
        _mappingOfVotes[voterId] = candidateNumber;
        _listOfVotes.push(voterId);
        _countVotes++;

        
    }

    function voteExists(uint8 voterId) private view returns (bool) {
        return _mappingOfVotes[voterId] != 0;
    }

    function getNumberOfVotesPerCandidate(uint8 candidateNumber) external view returns (uint32) {
        return _candidates[candidateNumber];
    }

    function viewMyVote(uint8 voterId) external view returns (uint8) {
        return _mappingOfVotes[voterId];
    }

    function getListOfVotes() external view returns (uint8[] memory) {
        require(_creator == msg.sender, "Not authorized");

        return _listOfVotes;
    } 

    function getCreator() external view returns (address) {
        return _creator;
    }

    function killContract() external payable {
        require(_creator == msg.sender, "Not authorized");
        selfdestruct(payable(_creator));
    }
}