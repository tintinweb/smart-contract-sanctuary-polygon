/**
 *Submitted for verification at polygonscan.com on 2022-04-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract ESG {

    struct Document {
        bytes32 documentHash;
        bytes16 documentChecksum;
        uint8   hashFunction;
        uint8   hashSize;
        uint64  creationTimestamp;
        uint32  organisationId;
        uint32  documentId;
        uint32  statementId;
        uint8   statementRate;
        uint8   publiclyPublished;
        uint64  gracePeriodEndTimestamp;
        uint8   withdrawn;
    }

    mapping(uint32 => Document) public Documents;

    mapping(uint32 => uint32) public Organizations;

    address owner;
    string public baseUrl;
    string public gatewayUrl;
    uint32 internal documentCounter;

    //Events
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event BaseUrlSet(string oldBaseUrl, string  newBaseUrl);
    event GatewayUrlSet(string oldGatewayUrl, string newGatewayUrl);
    
    //Generic document events
    event DocumentCreated(uint32 indexed documentId, Document documentCreated);
    event DocumentPublished(uint32 indexed documentId, Document documentPublished);
    event DocumentWithdrawn(uint32 indexed documentId, Document documentWithdrawn);


    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        baseUrl = "http://127.0.0.1:4000/download/";
        // emit BaseUrlSet("",baseUrl);
        gatewayUrl = "http://127.0.0.1:4000/ipfs/";
        // emit GatewayUrlSet("",gatewayUrl);

    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    // function getOwner() external view returns (address) {
    //     return owner;
    // }

    function changeBaseUrl(string memory newBaseUrl) public isOwner {
        emit BaseUrlSet(baseUrl, newBaseUrl);
        baseUrl = newBaseUrl;
    }

    // function getBaseUrl() external view returns (string memory) {
    //     return baseUrl;
    // }

    function changeGatewayurl(string memory newGatewayUrl) public isOwner {
        emit GatewayUrlSet(gatewayUrl, newGatewayUrl);
        gatewayUrl = newGatewayUrl;
    }

    // function getGatewayUrl() external view returns (string memory) {
    //     return gatewayUrl;
    // }


    function createDocument(
                    
    bytes16 documentChecksum_,
    uint32 organisationId_,
    uint32 statementId_,
    uint8 statementRate_,
    uint8 publiclyPublished_,
    uint64 gracePeriodEndTimestamp_
    

    ) public isOwner returns (uint32){
        documentCounter = documentCounter+1;
        if (statementId_ != 0){
            require(Documents[statementId_].creationTimestamp > 0, "Statement does not exists!");
        }
        Document memory newDocument = Document({
            documentChecksum:documentChecksum_,
            documentHash:"",
            hashFunction:0,
            hashSize:0,
            creationTimestamp:uint64(block.timestamp),
            organisationId:organisationId_,
            documentId:documentCounter,
            statementId:statementId_,
            statementRate:statementRate_,
            publiclyPublished:publiclyPublished_,
            withdrawn:0,
            gracePeriodEndTimestamp:gracePeriodEndTimestamp_
            });
        Documents[documentCounter] = newDocument;
        emit DocumentCreated(newDocument.documentId, newDocument);
        return newDocument.documentId;
    }
    
    function permanentPublishDocument(uint32 documentId_, bytes32 documentHash_, uint8 hashFunction_, uint8 hashSize_) public isOwner returns(Document memory){
        require(Documents[documentId_].creationTimestamp > 0, "Document does not exists!");
        require(Documents[documentId_].withdrawn == 0, "Document has been withdrawn before the grace period end!");
        require(Documents[documentId_].gracePeriodEndTimestamp < block.timestamp, "This document cannot be publicly published yet!");
        Documents[documentId_].publiclyPublished = 1;
        Documents[documentId_].documentHash = documentHash_;
        Documents[documentId_].hashFunction = hashFunction_;
        Documents[documentId_].hashSize = hashSize_;
        emit DocumentPublished(documentId_, Documents[documentId_]);
        return Documents[documentId_];
    }

    function withdrawDocument(uint32 documentId_) public isOwner returns(Document memory){
        require(Documents[documentId_].creationTimestamp > 0, "Document does not exists!");
        require(Documents[documentId_].withdrawn == 0, "Document has already been withdrawn!");
        require(Documents[documentId_].gracePeriodEndTimestamp > block.timestamp, "This document cannot be withdrawn anymore!");
        Documents[documentId_].withdrawn = 1;
        emit DocumentWithdrawn(documentId_, Documents[documentId_]);
        return Documents[documentId_];
    }
}