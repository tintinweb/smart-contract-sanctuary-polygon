/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract OrganigrammaAziendale {
    
    address public owner;
    
    struct Dipendente {
        string nomeCognome;
        uint256 eta;
        string ruolo;
        string informazioniAggiuntive;
    }
    
    mapping (string => mapping (string => Dipendente)) organigramma;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo il presidente puo gestire l'organigramma");
        _;
    }
    
    function aggiungiDipendente(string memory categoria, string memory nomeCognome, uint256 eta, string memory ruolo, string memory informazioniAggiuntive) public onlyOwner {
        organigramma[categoria][ruolo] = Dipendente(nomeCognome, eta, ruolo, informazioniAggiuntive);
    }
    
    function leggiDipendente(string memory categoria, string memory ruolo) public view returns (string memory, uint256, string memory, string memory) {
        Dipendente storage dipendente = organigramma[categoria][ruolo];
        return (dipendente.nomeCognome, dipendente.eta, dipendente.ruolo, dipendente.informazioniAggiuntive);
    }
}