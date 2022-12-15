/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Blog {

    struct Article{
        uint id;
        string titre;
        string texte;
        address auteur;
        uint timestamp;
    }

    mapping(uint => Article) public articles;

    address public auteur;

    uint public id = 0;

    event NouvelArticle(uint id, string titre, string texte, address auteur, uint timestamp);

    constructor() {
        auteur = msg.sender;
    }

    function creerArticle(string memory _titre, string memory _texte) public {
        id++;
        require(msg.sender == auteur, "Vous n'etes pas l'auteur");
        articles[id] = Article(id, _titre, _texte, msg.sender, block.timestamp);
        emit NouvelArticle(id, _titre, _texte, msg.sender, block.timestamp);
    }

    function modifierAuteur(address _newAuteur) public{
        require(auteur == msg.sender,"Vous n'etes pas l'auteur");
        auteur = _newAuteur;
    }
}