// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721URIStorage.sol";  // Importa il contratto ERC721URIStorage per gestire gli NFT
import "Counters.sol";  // Importa il contratto Counters per gestire i contatori

contract GameItem is ERC721URIStorage {  // Definisce il contratto GameItem e lo eredita da ERC721URIStorage
    using Counters for Counters.Counter; // Using  - ogni volta che si utilizza la struttura Counter, si può chiamare direttamente i suoi metodi, come increment(), senza dover specificare ogni volta il nome della struttura.
    Counters.Counter private _tokenIds;  // Crea un contatore privato per gli ID dei token

    constructor() ERC721("GameItem2", "ITM") {}  // Costruttore del contratto che chiama il costruttore del contratto ERC721 e gli assegna il nome "GameItem" e il simbolo "ITM"

    function awardItem(address player, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();  // Crea un nuovo ID del token tramite il contatore
        _mint(player, newItemId);  // Crea un nuovo token e lo assegna al giocatore specificato
        _setTokenURI(newItemId, tokenURI);  // Imposta l'URI del token tramite il parametro fornito

        _tokenIds.increment();  // Incrementa il contatore degli ID dei token
        return newItemId;  // Restituisce l'ID del nuovo token creato
    }
}