/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract JUVENTUS {
    // Struttura dati per rappresentare un giocatore
    struct Player {
        string name;
        uint age;
        string position;
    }

    // Mapping per mantenere tutti i giocatori
    mapping(uint => Player) public players;
    uint public playerCount;

    // Funzione per aggiungere un giocatore alla rosa
    function addPlayer(string memory _name, uint _age, string memory _position) public {
        playerCount ++;
        players[playerCount] = Player(_name, _age, _position);
    }

    // Funzione per aggiungere più giocatori alla rosa contemporaneamente
    function addAllPlayers(Player[] memory _players) public {
        for (uint i = 0; i < _players.length; i++) {
            addPlayer(_players[i].name, _players[i].age, _players[i].position);
        }
    }

    // Funzione per rimuovere un giocatore dalla rosa
    function removePlayer(uint _index) public {
        delete players[_index];
    }

    // Funzione per ottenere informazioni su un giocatore
    function getPlayer(uint _index) public view returns (string memory, uint, string memory) {
        return (players[_index].name, players[_index].age, players[_index].position);
    }

    // Funzione per trasferire un giocatore da un altro contratto ASROMA
    function transferPlayer(JUVENTUS _from, uint _index) public {
        (string memory name, uint age, string memory position) = _from.getPlayer(_index);
        Player memory player = Player(name, age, position);
        _from.removePlayer(_index);
        addPlayer(player.name, player.age, player.position);
    }
}