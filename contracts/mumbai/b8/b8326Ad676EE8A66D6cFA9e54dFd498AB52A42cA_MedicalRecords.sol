pragma solidity ^0.8.9;

import { ByteHasher } from "./helpers/ByteHasher.sol";
import { IWorldID } from "./interfaces/IWorldID.sol";

contract MedicalRecords {

    using ByteHasher for bytes;

    error InvalidNullifier();

    IWorldID internal immutable worldId;

    uint256 internal immutable action;

    uint256 internal immutable groupId = 1;

    mapping(uint256 => bool) internal nullifierHashes;


    constructor(
        IWorldID _worldId,
        string memory _appId
    ) {
        worldId = _worldId;
        action = abi.encodePacked(_appId).hashToField();
    }

    struct record {
        uint256 userHash;
        address ownerWallet;
        string gender;
        string birthday;
        uint heightCM;
        uint weightKG;
        address[] contributors;
        string note;
        string[] images;
    }

    // struct Note {
    //     address author;
    //     string datetime;
    //     string content;
    // }

    mapping(uint256 => record) private records; // World ID to record

    // PREREQ CHECKS

    modifier onlyContributor(uint256 _userHash) {
        require(isContributor(_userHash), "Caller is not a contributor of the record");
        _;
    }

    modifier onlyOwner(uint256 _userHash) {
        require(records[_userHash].ownerWallet == msg.sender, "Caller is not the record owner");
        _;
    }

    modifier recordExists(uint256 _userHash) {
        require(records[_userHash].ownerWallet != address(0), "record does not exist for the wallet");
        _;
    }

    // WRITE

    function worldCoinAuth(
        uint256 _userHash,
        address _signal,
        uint256 _root,
        uint256[8] calldata _proof) public view {
        worldId.verifyProof(
            _root,
            groupId,
            abi.encodePacked(_signal).hashToField(),
            _userHash,
            action,
            _proof
        );
    }
    

    function createRecord(
        uint256 _userHash,
        string memory _gender,
        string memory _birthday,
        uint _heightCM,
        uint _weightKG,
        address _signal,
        uint256 _root,
        uint256[8] calldata _proof
    ) public {
        address from = msg.sender;

        require(records[_userHash].ownerWallet == address(0), "record already exists for the caller");

        // worldId.verifyProof(
        //     _root,
        //     groupId,
        //     abi.encodePacked(_signal).hashToField(),
        //     _userHash,
        //     action,
        //     _proof
        // );

        record memory newRecord;

        newRecord.userHash = _userHash;
        newRecord.ownerWallet = from;
        newRecord.gender = _gender;
        newRecord.birthday = _birthday;
        newRecord.heightCM = _heightCM;
        newRecord.weightKG = _weightKG;
        newRecord.note = "";

        records[_userHash] = newRecord;
    }

    function modifyRecord(uint256 _userHash, string memory _gender, uint _heightCM, uint _weightKG, string memory _note) public onlyContributor(_userHash) {
        records[_userHash].gender = _gender;
        records[_userHash].heightCM = _heightCM;
        records[_userHash].weightKG = _weightKG;
        records[_userHash].note = _note;
    }

    function changeWallet(
        uint256 _userHash,
        address _newAddress, 
        address _signal,
        uint256 _root,
        uint256[8] calldata proof) public onlyOwner(_userHash) {

        // worldId.verifyProof(
        //     _root,
        //     groupId,
        //     abi.encodePacked(_signal).hashToField(),
        //     _userHash,
        //     action,
        //     proof
        // );

        records[_userHash].ownerWallet = _newAddress;
    }

    // function addNote(uint256 _userHash, address _author, string memory _datetime, string memory _content) public onlyContributor(_userHash) {

    //     Note memory newNote;
    //     newNote.author = _author;
    //     newNote.datetime = _datetime;
    //     newNote.content = _content;

    //     records[_userHash].notes.push(newNote);
    // }

    function setContributors(uint256 _userHash, address[] memory _contributors) public onlyOwner(_userHash) {
        records[_userHash].contributors = _contributors;
    }

    function addImage(uint256 _userHash, string memory _image) public onlyContributor(_userHash) {
        records[_userHash].images.push(_image);
    }

    // READ

    function hasRecord(uint256 _userHash) public view returns (bool) {
        return records[_userHash].ownerWallet != address(0);
    }

    function isOwner(uint256 _userHash) public view recordExists(_userHash) returns (bool) {
        if(records[_userHash].ownerWallet == msg.sender) {
            return true;
        }
        return false;
    }

    function isContributor(uint256 _userHash) public view recordExists(_userHash) returns (bool) {
        if (isOwner(_userHash)) {
            return true;
        }

        for (uint256 i = 0; i < records[_userHash].contributors.length; i++) {
            if (records[_userHash].contributors[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function getRecord(uint256 _userHash) public view onlyContributor(_userHash) returns (record memory) {
        return records[_userHash];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}