// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Legalbox {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
    struct LegalDocument { 
        string ownerUsername; // owner's username in Legalbox
        string title;
        string description;
        string ipfsHash;
        uint256 timestamp; //timestamp of the current block in seconds since the epoch
    }

    uint256 public legalDocumentCount;
    uint256 public legalDocumentIDCount;

    // string[] public ownerUsernameArray;
    // uint256[] public legalDocumentIDs;
    LegalDocument[] public legalDocumentArray;

    mapping(string => uint256[]) public ownerUsernameToLegalDocumentIDs;
    mapping(string => uint256[]) public ipfsHashToLegalDocumentIDs;
    // mapping (uint256 => LegalDocument) public legalDocumentIDToLegalDocument;

    event LegalDocumentIPFSHashStored(uint256 legalDocumentID, string ownerUsername, string title, string description, string ipfsHash, uint256 timestamp);
    // event RetrieveLegalDocumentIDsByOwnerUsername(string ownerUsername, uint256[] legalDocumentIDs);
    // event RetrieveLegalDocumentIDsByIPFSHash(string ipfsHash, uint256[] legalDocumentIDs);
    // event RetrieveLegalDocumentIDsByTitle(string title, uint256[] legalDocumentIDs);
    // event RetrieveLegalDocumentIDsByDescription(string description, uint256[] legalDocumentIDs);
    // event RetrieveLegalDocumentIDsByTimestamp(uint256 timestamp, uint256[] legalDocumentIDs);
    // event RetrieveLegalDocumentCount(uint256 legalDocumentCount);
    // event RetrieveLegalDocumentByLegalDocumentID(uint256 legalDocumentID, string ownerUsername, string title, string description, string ipfsHash, uint256 timestamp);
   
   function storeLegalDocumentIPFSHash(string memory _ownerUsername, string memory _title, string memory _description, string memory _ipfsHash) public onlyOwner 
    returns(uint256, string memory, string memory, string memory, string memory, uint256){
        require(bytes(_ipfsHash).length > 0, "Invalid IPFS hash");

        // store legalDocument in mapping legalDocumentIDToLegalDocument
        legalDocumentIDCount += 1;
        LegalDocument memory newLegalDocument = LegalDocument(_ownerUsername, _title, _description, _ipfsHash, block.timestamp);
        // legalDocumentIDs.push(legalDocumentIDCount);
        legalDocumentArray.push(newLegalDocument);
        // legalDocumentIDToLegalDocument[legalDocumentIDCount] = newLegalDocument;
        
        // store legalDocument in mapping ownerUsernameToLegalDocument
        // ownerUsernameArray.push(_ownerUsername);
        ownerUsernameToLegalDocumentIDs[_ownerUsername].push(legalDocumentIDCount);

        // increment legalDocumentCount tracker
        ipfsHashToLegalDocumentIDs[_ipfsHash].push(legalDocumentIDCount);
        legalDocumentCount += 1;

        emit LegalDocumentIPFSHashStored(legalDocumentIDCount, _ownerUsername, _title, _description, _ipfsHash, block.timestamp);
        return (legalDocumentIDCount, _ownerUsername, _title, _description, _ipfsHash, block.timestamp);
    }

    function getLegalDocumentIDsByOwnerUsername(string memory _ownerUsername) public view returns(uint256[] memory){
        return ownerUsernameToLegalDocumentIDs[_ownerUsername];
    }

    // function getLegalDocumentCount() public returns(uint256) {
    //     emit RetrieveLegalDocumentCount(legalDocumentCount);
    //     return (legalDocumentCount);
    // }

        function getLegalDocumentByLegalDocumentID(uint256 _legalDocumentID)
    public view returns(uint256, string memory, string memory, string memory, string memory, uint256){
        LegalDocument memory tempLegalDocument = legalDocumentArray[_legalDocumentID - 1];
        return (_legalDocumentID, tempLegalDocument.ownerUsername, tempLegalDocument.title, tempLegalDocument.description, 
        tempLegalDocument.ipfsHash, tempLegalDocument.timestamp);
    }

    // function getLegalDocumentIDsByOwnerUsername(string memory _ownerUsername) public returns(string memory, uint256[] memory){
    //    uint256[] memory tempLegalDocumentIDs = ownerUsernameToLegalDocumentIDs[_ownerUsername];
     
    //    emit RetrieveLegalDocumentIDsByOwnerUsername(_ownerUsername, tempLegalDocumentIDs);
    //    return(_ownerUsername, tempLegalDocumentIDs);
    // }

    function getLegalDocumentIDsByIPFSHash(string memory _ipfsHash) public view returns(uint256[] memory){
         return ipfsHashToLegalDocumentIDs[_ipfsHash];
    }

    // function getLegalDocumentByLegalDocumentID(uint256 _legalDocumentID) public returns(uint256, string memory, string memory, string memory,
    // string memory, uint256){
    //    LegalDocument memory tempLegalDocument = legalDocumentIDToLegalDocument[_legalDocumentID];


    //     emit RetrieveLegalDocumentByLegalDocumentID(_legalDocumentID, tempLegalDocument.ownerUsername, tempLegalDocument.title,
    //     tempLegalDocument.description, tempLegalDocument.ipfsHash, tempLegalDocument.timestamp);
    //     return (_legalDocumentID, tempLegalDocument.ownerUsername, tempLegalDocument.title,
    //     tempLegalDocument.description, tempLegalDocument.ipfsHash, tempLegalDocument.timestamp);
    // }

    // function getLegalDocumentIDsByIPFSHash(string memory _ipfsHash) public returns(string memory, uint256[] memory){
    //     uint256[] memory tempLegalDocumentIDs = new uint256[](legalDocumentIDCount);
    //     uint256 tempLegalDocumentIDsArrayIndex = 0;

    //    for(uint256 i = 1; i <= legalDocumentIDCount; i++) {
    //         if(keccak256(abi.encodePacked(legalDocumentIDToLegalDocument[i].ipfsHash)) == keccak256(abi.encodePacked(_ipfsHash))) {
    //             tempLegalDocumentIDs[tempLegalDocumentIDsArrayIndex] = i;
    //             tempLegalDocumentIDsArrayIndex += 1;
    //         }
    //    }

    //    emit RetrieveLegalDocumentIDsByIPFSHash(_ipfsHash, tempLegalDocumentIDs);
    //    return (_ipfsHash, tempLegalDocumentIDs);
    // }

    //  function getLegalDocumentIDsByTitle(string memory _title) public returns(string memory, uint256[] memory){
    //     uint256[] memory tempLegalDocumentIDs = new uint256[](legalDocumentIDCount);
    //     uint256 tempLegalDocumentIDsArrayIndex = 0;

    //    for(uint256 i = 1; i <= legalDocumentIDCount; i++) {
    //         if(keccak256(abi.encodePacked(legalDocumentIDToLegalDocument[i].title)) == keccak256(abi.encodePacked(_title))) {
    //             tempLegalDocumentIDs[tempLegalDocumentIDsArrayIndex] = i;
    //             tempLegalDocumentIDsArrayIndex += 1;
    //         }
    //    }

    //    emit RetrieveLegalDocumentIDsByTitle(_title, tempLegalDocumentIDs);
    //    return (_title, tempLegalDocumentIDs);
    // }

    // function getLegalDocumentIDsByDescription(string memory _description) public returns(string memory, uint256[] memory){
    //     uint256[] memory tempLegalDocumentIDs = new uint256[](legalDocumentIDCount);
    //     uint256 tempLegalDocumentIDsArrayIndex = 0;

    //    for(uint256 i = 1; i <= legalDocumentIDCount; i++) {
    //         if(keccak256(abi.encodePacked(legalDocumentIDToLegalDocument[i].description)) == keccak256(abi.encodePacked(_description))) {
    //             tempLegalDocumentIDs[tempLegalDocumentIDsArrayIndex] = i;
    //             tempLegalDocumentIDsArrayIndex += 1;
    //         }
    //    }

    //    emit RetrieveLegalDocumentIDsByDescription(_description, tempLegalDocumentIDs);
    //    return (_description, tempLegalDocumentIDs);
    // }

    // function getLegalDocumentIDsByTimestamp(uint256 _timestamp) public returns(uint256, uint256[] memory){
    //     uint256[] memory tempLegalDocumentIDs = new uint256[](legalDocumentIDCount);
    //     uint256 tempLegalDocumentIDsArrayIndex = 0;

    //    for(uint256 i = 1; i <= legalDocumentIDCount; i++) {
    //         if(keccak256(abi.encodePacked(legalDocumentIDToLegalDocument[i].timestamp)) == keccak256(abi.encodePacked(_timestamp))) {
    //             tempLegalDocumentIDs[tempLegalDocumentIDsArrayIndex] = i;
    //             tempLegalDocumentIDsArrayIndex += 1;
    //         }
    //    }

    //    emit RetrieveLegalDocumentIDsByTimestamp(_timestamp, tempLegalDocumentIDs);
    //    return (_timestamp, tempLegalDocumentIDs);
    // }
}