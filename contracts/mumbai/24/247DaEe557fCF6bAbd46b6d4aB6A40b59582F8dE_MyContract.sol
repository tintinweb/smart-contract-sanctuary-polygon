/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// Definizione dello smart contract
pragma solidity 0.8.0;
//SPDX-License-Identifier: UNLICENSED"
contract MyContract {
    // Struttura per memorizzare le informazioni
    struct Item {
        string description;
        uint256 date;
        bytes32[] imageHashes;
    }
    
    // Mapping per associare un hash ad un item
    mapping(bytes32 => Item) public items;

    // Evento per notificare l'aggiunta di un item
    event ItemAdded(bytes32 hash);

    // Funzione per aggiungere un item
    function addItem(string memory _description, uint256 _date, bytes[] memory _images) public {
        // Calcola l'hash delle immagini
        bytes32[] memory imageHashes = new bytes32[](_images.length);
        for (uint i = 0; i < _images.length; i++) {
            imageHashes[i] = keccak256(_images[i]);
        }
        
        // Crea un nuovo item
        bytes32 hash = keccak256(abi.encodePacked(_description, _date, imageHashes));
        Item memory newItem = Item(_description, _date, imageHashes);
        
        // Aggiunge l'item al mapping
        items[hash] = newItem;
        
        // Emesso l'evento ItemAdded
        emit ItemAdded(hash);
    }
}