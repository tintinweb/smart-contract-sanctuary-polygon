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
    
    Dipendente[] public organigramma;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo il presidente puo gestire l'organigramma");
        _;
    }
    
    function aggiungiDipendente(string memory nomeCognome, uint256 eta, string memory ruolo, string memory informazioniAggiuntive) public onlyOwner {
        organigramma.push(Dipendente(nomeCognome, eta, ruolo, informazioniAggiuntive));
    }
    
    function leggiDipendente(uint256 indice) public view returns (string memory, uint256, string memory, string memory) {
        require(indice < organigramma.length, "L'indice specificato non esiste");
        Dipendente storage dipendente = organigramma[indice];
        return (dipendente.nomeCognome, dipendente.eta, dipendente.ruolo, dipendente.informazioniAggiuntive);
    }
    function leggiOrganigramma() public view returns (Dipendente[] memory) {
    return organigramma;
    }
}