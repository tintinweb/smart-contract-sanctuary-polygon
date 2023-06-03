/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

pragma solidity ^0.8.0;

contract UrnaEletronica {
    
    struct Candidato {
        string nome;
        uint256 votos;
    }
    
    mapping(address => bool) public eleitores;
    mapping(uint256 => Candidato) public candidatos;
    mapping(uint256 => mapping(address => bool)) public votosRegistrados;
    uint256 public totalCandidatos;
    bool public votacaoEncerrada;
    
    event VotoComputado(address eleitor, uint256 idCandidato);
    event NovoCandidato(uint256 idCandidato, string nomeCandidato);
    event EncerrarVotacao();
    
    constructor() {
        totalCandidatos = 0;
        votacaoEncerrada = false;
    }
    
    modifier apenasEleitores() {
        require(eleitores[msg.sender] == true, "");
        _;
    }
    
    modifier votacaoAberta() {
        require(votacaoEncerrada == false, "");
        _;
    }
    
    function adicionarCandidato(string memory nomeCandidato) public apenasEleitores votacaoAberta {
        totalCandidatos++;
        candidatos[totalCandidatos] = Candidato(nomeCandidato, 0);
        emit NovoCandidato(totalCandidatos, nomeCandidato);
    }
    
    function votar(uint256 idCandidato) public apenasEleitores votacaoAberta {
        require(idCandidato > 0 && idCandidato <= totalCandidatos);
        require(votosRegistrados[idCandidato][msg.sender] == false );
        
        candidatos[idCandidato].votos++;
        votosRegistrados[idCandidato][msg.sender] = true;
        eleitores[msg.sender] = false; // Impede que o mesmo eleitor vote mais de uma vez
        emit VotoComputado(msg.sender, idCandidato);
    }
    
    function encerrarVotacao() public apenasEleitores votacaoAberta {
        votacaoEncerrada = true;
        emit EncerrarVotacao();
    }
}