/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
contract FootballTeam {
    struct Player {
        string name;
        string position;
    }

    mapping(uint => Player) public Titolari;
    mapping(uint => Player) public Panchinari;

    uint public titolariCount;
    uint public panchinariCount;

    function addTitolare(string memory _name, string memory _position) public {
        require(titolariCount < 11, "Numero massimo di titolari raggiunto");
        Titolari[titolariCount] = Player(_name, _position);
        titolariCount++;
    }

    function addPanchinaro(string memory _name, string memory _position) public {
        require(panchinariCount < 15, "Numero massimo di panchinari raggiunto");
        Panchinari[panchinariCount] = Player(_name, _position);
        panchinariCount++;
    }

    function removeTitolare(uint _index) public {
        require(_index < titolariCount, "Indice fuori dai limiti");
        delete Titolari[_index];
    }

    function removePanchinaro(uint _index) public {
        require(_index < panchinariCount, "Indice fuori dai limiti");
        delete Panchinari[_index];
    }

    function getTitolari() public view returns (Player[] memory) {
        Player[] memory players = new Player[](titolariCount);
        for (uint i = 0; i < titolariCount; i++) {
            players[i] = Titolari[i];
        }
        return players;
    }

    function getPanchinari() public view returns (Player[] memory) {
        Player[] memory players = new Player[](panchinariCount);
        for (uint i = 0; i < panchinariCount; i++) {
            players[i] = Panchinari[i];
        }
        return players;
    }
}