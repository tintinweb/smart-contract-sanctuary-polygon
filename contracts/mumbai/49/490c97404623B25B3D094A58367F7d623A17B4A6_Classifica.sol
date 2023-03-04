/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract Classifica {
    
    struct Squadra {
        uint posizione;
        string nome;
        uint punti;
        uint retiSegnate;
        uint retiSubite;
        int diffReti;
    }
    
    mapping(address => Squadra) public squadre;
    address[] public listaSquadre;
    
    function inserisciSquadra(address addr, string memory nome, uint punti, uint retiSegnate, uint retiSubite) public {
        require(listaSquadre.length < 20, "Classifica piena");
        squadre[addr] = Squadra(listaSquadre.length + 1, nome, punti, retiSegnate, retiSubite, int(retiSegnate) - int(retiSubite));
        listaSquadre.push(addr);
    }
    
    function aggiornaPunti(address addr, uint punti) public {
        squadre[addr].punti = punti;
    }
    
    function aggiornaRetiSegnate(address addr, uint retiSegnate) public {
        squadre[addr].retiSegnate = retiSegnate;
        squadre[addr].diffReti = int(retiSegnate) - int(squadre[addr].retiSubite);
    }
    
    function aggiornaRetiSubite(address addr, uint retiSubite) public {
        squadre[addr].retiSubite = retiSubite;
        squadre[addr].diffReti = int(squadre[addr].retiSegnate) - int(retiSubite);
    }
    
    function getListaSquadre() public view returns (address[] memory) {
        return listaSquadre;
    }
    
    function getSquadra(address addr) public view returns (uint, string memory, uint, uint, uint, int) {
        Squadra storage s = squadre[addr];
        return (s.posizione, s.nome, s.punti, s.retiSegnate, s.retiSubite, s.diffReti);
    }
}