// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EticasaNotarizzazione {
    struct Record {
        string text;
        uint timestamp;
        address notarizedBy;
    }

    // Mappatura da ID a Record notarizzato
    mapping(uint => Record) private _records;
    // Contatore per generare ID unici
    uint private _currentId;
    // Proprietario del contratto
    address private _owner;
    // Mappatura degli indirizzi autorizzati
    mapping(address => bool) private _authorized;

    // Evento emesso quando un nuovo testo viene notarizzato
    event TextNotarized(uint id, string text, address notarizedBy, uint timestamp);

    constructor() {
        _currentId = 0;
        _owner = msg.sender;
        _authorized[_owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "EticasaNotarizzazione: Chiamante non proprietario");
        _;
    }

    modifier onlyAuthorized() {
        require(_authorized[msg.sender], "EticasaNotarizzazione: Chiamante non autorizzato");
        _;
    }

    function authorizeAddress(address user) external onlyOwner {
        _authorized[user] = true;
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    function notarizeText(string calldata text) external onlyAuthorized returns (uint) {
        // Incrementa l'ID corrente
        _records[++_currentId] = Record(text, block.timestamp, msg.sender);

        // Emette un evento per informare gli ascoltatori che un nuovo testo è stato notarizzato
        emit TextNotarized(_currentId, text, msg.sender, block.timestamp);
        
        // Restituisce l'ID del testo notarizzato
        return _currentId;
    }

    function getText(uint id) external view returns (string memory) {
        // Controlla che l'ID esista
        require(bytes(_records[id].text).length != 0, "EticasaNotarizzazione: ID non esistente");

        // Recupera il testo notarizzato con l'ID dato
        return _records[id].text;
    }

    function getRecord(uint id) external view returns (string memory text, uint timestamp, address notarizedBy) {
        // Controlla che l'ID esista
        require(bytes(_records[id].text).length != 0, "EticasaNotarizzazione: ID non esistente");

        // Recupera il record notarizzato con l'ID dato
        return (_records[id].text, _records[id].timestamp, _records[id].notarizedBy);
    }
}