// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Meta.sol";


interface ICarchainNFT {
      function getMetadata(uint256 _id)
        external
        view
        returns (
        address owner, string memory hash, string memory make, string memory model, uint256 year, string memory vin, string memory engine, string memory colour, string memory plate, uint256 mileage
        );

      function vins(string memory _vin) external view returns (uint256);  
}

contract CarchainDocuVerify is AccessControlMixin, NativeMetaTransaction, ContextMixin {
    mapping(address=>bool) public verifiers;
    mapping(string=>CarDocument) public carDocuments;
    mapping(string=>Document) public documents;
    mapping(string=>string[]) public hashesByVIN;

    ICarchainNFT carchainNFT;

    event CarDocumentCreated(address indexed _creator, string _hash);
    event DocumentCreated(address indexed _creator, string _hash);

    struct CarDocument {
        bool valid;
        address verifiedBy;
        uint256 verifiedOn;
        string make;
        string model;
        string vin;
        uint256 mileage;
    }

    struct Document {
        bool valid;
        address verifiedBy;
        uint256 verifiedOn;
        string name;
        string otherFields;
    }

    constructor(address _carchainNFT) {
        _setupContractId("CarchainDocuVerify");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _initializeEIP712('CarchainDocuVerify');

        carchainNFT = ICarchainNFT(_carchainNFT);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    function addDocument(string memory _hash, string memory _name, string memory _otherFields) public {
        require(verifiers[_msgSender()] || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Invalid caller");
        require(!documents[_hash].valid, "Already exists");

        documents[_hash].valid = true;
        documents[_hash].verifiedBy = _msgSender();
        documents[_hash].verifiedOn = block.timestamp;
        documents[_hash].name = _name;
        documents[_hash].otherFields = _otherFields;

        emit DocumentCreated(_msgSender(), _hash);
    }

    function addCarDocument(string memory _hash, string memory _make, string memory _model, string memory _vin, uint256 _mileage) public {
        require(verifiers[_msgSender()] || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Invalid caller");
        require(!carDocuments[_hash].valid, "Already exists");

        carDocuments[_hash].valid = true;
        carDocuments[_hash].verifiedBy = _msgSender();
        carDocuments[_hash].verifiedOn = block.timestamp;
        carDocuments[_hash].make = _make;
        carDocuments[_hash].model = _model;
        carDocuments[_hash].vin = _vin;
        carDocuments[_hash].mileage = _mileage;

        hashesByVIN[_vin].push(_hash);

        emit CarDocumentCreated(_msgSender(), _hash);    
    }

    function getCarDocument(string memory _hash) external view returns (bool valid, uint256 tokenId, address verifiedBy, uint256 verifiedOn, string memory make, string memory model, string memory vin, uint256 mileage) {
        CarDocument memory data = carDocuments[_hash];
        return (data.valid, carchainNFT.vins(data.vin), data.verifiedBy, data.verifiedOn, data.make, data.model, data.vin, data.mileage);
    }

    function _setVerifier(address _who, bool _status) public only(DEFAULT_ADMIN_ROLE) {
        verifiers[_who] = _status;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}