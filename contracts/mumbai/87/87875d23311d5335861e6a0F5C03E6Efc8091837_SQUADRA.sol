/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract SQUADRA {
    // Struttura dati per rappresentare un giocatore
    struct Player {
        string name;
        uint age;
        string position;
        uint price;
        bool forSale;
    }

    // Mapping per mantenere tutti i giocatori
    mapping(uint => Player) public players;
    uint public playerCount;

    // Variabile per mantenere l'indirizzo del proprietario del contratto
    address owner;

    // Costruttore per impostare l'indirizzo del proprietario del contratto
    constructor() {
        owner = msg.sender;
    }

    // Funzione per aggiungere un giocatore alla rosa
    function addPlayer(string memory _name, uint _age, string memory _position, uint _price, bool _forSale) public {
        playerCount ++;
        players[playerCount] = Player(_name, _age, _position, _price, _forSale);
    }

    // Funzione per aggiungere più giocatori alla rosa contemporaneamente
    function addAllPlayers(Player[] memory _players) public {
        for (uint i = 0; i < _players.length; i++) {
            addPlayer(_players[i].name, _players[i].age, _players[i].position, _players[i].price, _players[i].forSale);
        }
    }

    // Funzione per rimuovere un giocatore dalla rosa
    function removePlayer(uint _index) public {
        require(msg.sender == owner, 'Solo il proprietario del contratto puo eseguire questa operazione.');
        delete players[_index];
    }

    // Funzione per ottenere informazioni su un giocatore
    function getPlayer(uint _index) public view returns (string memory, uint, string memory, uint, bool) {
        return (players[_index].name, players[_index].age, players[_index].position, players[_index].price, players[_index].forSale);
    }

    // Funzione per trasferire un giocatore da un altro contratto SQUADRA
    function transferPlayer(SQUADRA from, uint _index) public {
        // require(msg.sender == owner, "Solo il proprietario del contratto puo eseguire questa operazione.");
        (string memory name, uint age, string memory position, uint price, bool forSale) = from.getPlayer(_index);
        Player memory player = Player(name, age, position, price, forSale);
        from.removePlayer(_index);
        addPlayer(player.name, player.age, player.position, player.price, player.forSale);
    }
    // Funzione per trasferire la proprietà del contratto ad un nuovoindirizzo
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Solo il wallet che ha deployato il contratto puo eseguire questa operazione.");
        owner = newOwner;
    }
     // Funzione per visualizzare tutti i giocatori nella rosa
    function getAllPlayers() public view returns (Player[] memory) {
        Player[] memory allPlayers = new Player[](playerCount);
        for (uint i = 1; i <= playerCount; i++) {
            allPlayers[i - 1] = players[i];
        }
        return allPlayers;
    }
        function deleteAllPlayers() public {
        for (uint256 i = 0; i < playerCount; i++) {
            delete players[i];
        }
        playerCount = 0;
    }
}