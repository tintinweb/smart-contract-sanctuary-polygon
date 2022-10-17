// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LawFirmContract {

    // Law Firm Entity & Attributes
    struct LawFirm {
        string name;
        address walletAddress;
    } 
    // Law Firm Array Position 0 --> Law Firm Struct
    LawFirm[] public lawFirms;

    // Client Entity & Attributes
    struct Client {
        string name;
        address walletAddress;
    }
    // Client Array Position 0 --> Client Struct
    Client[] public clients;
 
    // Legal Document Entity & Attributes
    struct LegalDocument {
        string name;
        string docIPFSURI;
    }
    // Legal Document Array Position 0 --> Legal Document Struct
    LegalDocument[] public legalDocuments;

    // map law firms to clients
    mapping(uint256 => Client[]) public lawFirmToClient; // Law Firm Array Position to *Client Structs

    // map law firms to legal documents (before item 'Ownership Transfer')
    // To identify law firm that uploaded the legal document
    mapping(uint256 => LegalDocument[]) public lawFirmToLegalDocument; // Law Firm Array Position to *Legal Document Structs

    // map clients to legal documents (after item 'Ownership Transfer')
    // To identify client that purchased the legal document from 'x' Law Firm
    mapping(uint256 => LegalDocument[]) public clientToLegalDocument; // Client Array Position to *LegalDocumentStructs

   // map legal documents to owners
   // To identify current owner of the legal document
   mapping(uint256 => address) public legalDocumentToOwner; // Legal Document Array Position to Current Owner Wallet Address (LawFirm / Client)
    
    // Functions
    // addLawFirm - done by Ebric
    function addLawFirm(string memory _name, address _walletAddress) public returns(uint256) {
        // add Law Firm into Law Firm Array
        LawFirm memory lawFirm = LawFirm(_name, _walletAddress);
        lawFirms.push(lawFirm);
        uint256 lawFirmArrayPosition = lawFirms.length-1;
        return lawFirmArrayPosition;
    }

    // addClient - done by LawFirm
    function addClient(string memory _name, address _walletAddress, uint256 _lawFirmArrayPosition) public returns(uint256) {
        // add Client into Client Array
        Client memory client = Client(_name, _walletAddress);
        clients.push(client);
        uint256 clientArrayPosition = clients.length-1;

        // map law firm to client
        lawFirmToClient[_lawFirmArrayPosition].push(client);

        // return value
        return clientArrayPosition;   
    }

    // addLegalDocument - done by LawFirm
    function addLegalDocument(string memory _name, string memory _docIPFSURI, uint256 _lawFirmArrayPosition) public returns(uint256) {
        // add Legal Document into Legal Document Array
        LegalDocument memory legalDocument = LegalDocument(_name, _docIPFSURI);
        legalDocuments.push(legalDocument);
        uint256 legalDocumentArrayPosition = legalDocuments.length-1;

        // map law firm to legal document
        lawFirmToLegalDocument[_lawFirmArrayPosition].push(legalDocument);

        // map legal document to its current owner (Law Firm)
        LawFirm memory lawFirm = lawFirms[_lawFirmArrayPosition];
        legalDocumentToOwner[legalDocumentArrayPosition] = lawFirm.walletAddress;

        // return value
        return legalDocumentArrayPosition;
    }

    // transferOwnershipOfLegalDocument - done by LawFirm (payable)
    function transferOwnershipOfLegalDocument(uint256 _legalDocumentArrayPosition, uint256 _clientArrayPosition) public {
        // create instance of Legal Document from _legalDocumentArrayPosition
        LegalDocument memory legalDocument = legalDocuments[_legalDocumentArrayPosition];

        // map client to legal document
        clientToLegalDocument[_clientArrayPosition].push(legalDocument);

        // map legal document to its current owner (Client)
        Client memory client = clients[_clientArrayPosition];
        legalDocumentToOwner[_legalDocumentArrayPosition] = client.walletAddress;
    }


}