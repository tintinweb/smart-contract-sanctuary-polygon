/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract OrganigrammaAziendale {
    
    struct Dipendente {
        string nome;
        string posizione;
        string dipartimento;
    }

    mapping(address => Dipendente) public dipendenti;
    address[] public listaDipendenti;
    address public presidente;

    function aggiungiDipendente(string memory _nome, string memory _posizione, string memory _dipartimento) public {
        require(bytes(_nome).length > 0, "Il nome del dipendente e richiesto.");
        require(bytes(_posizione).length > 0, "La posizione del dipendente e richiesta.");
        require(bytes(_dipartimento).length > 0, "Il dipartimento del dipendente e richiesto.");

        Dipendente storage dipendente = dipendenti[msg.sender];
        dipendente.nome = _nome;
        dipendente.posizione = _posizione;
        dipendente.dipartimento = _dipartimento;

        listaDipendenti.push(msg.sender);
    }

    function getDipendenti() public view returns (address[] memory) {
        return listaDipendenti;
    }

    function getDipendente(address _indirizzo) public view returns (string memory, string memory, string memory) {
        return (dipendenti[_indirizzo].nome, dipendenti[_indirizzo].posizione, dipendenti[_indirizzo].dipartimento);
    }

    function rimuoviDipendente(address _indirizzo) public {
    require(bytes(dipendenti[_indirizzo].nome).length > 0, "Il dipendente non esiste.");

    delete dipendenti[_indirizzo];

    for (uint i=0; i<listaDipendenti.length; i++) {
        if (listaDipendenti[i] == _indirizzo) {
            listaDipendenti[i] = listaDipendenti[listaDipendenti.length-1];
            delete listaDipendenti[listaDipendenti.length-1];
            listaDipendenti.pop();
            break;
            }
        }
    }

    function assegnaPresidenza() public {
        require(presidente == address(0), "Il presidente e gia stato assegnato.");
        presidente = msg.sender;
        Dipendente storage dipendente = dipendenti[msg.sender];
        dipendente.nome = "Presidente";
        dipendente.posizione = "Presidente";
        dipendente.dipartimento = "Direzione";
        listaDipendenti.push(msg.sender);
    }

    function getPresidente() public view returns (string memory, string memory, string memory) {
        require(presidente != address(0), "Il presidente non e ancora stato assegnato.");
        return (dipendenti[presidente].nome, dipendenti[presidente].posizione, dipendenti[presidente].dipartimento);
    }
}