// https://zkforms.crypto
/*
 *        _    _____                        
 *    ___| | _|  ___|__  _ __ _ __ ___  ___ 
 *   |_  / |/ / |_ / _ \| '__| '_ ` _ \/ __|
 *    / /|   <|  _| (_) | |  | | | | | \__ \
 *   /___|_|\_\_|  \___/|_|  |_| |_| |_|___/
 * oooooooooooooooooooooooooooooooooooooooooooooooooo
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier{
    function verifyProof(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[12] memory input) external returns (bool);
}

contract Forms {
    IVerifier public immutable verifier;

    // Poseidon Hash(formId, address) => boolean
    mapping(bytes32 => bool) public responses;

    // formIdHash => merkleRoot
    mapping(bytes32 => bytes32) merkleRoots;

    // owners => formIdHash
    mapping(address => bytes32) owners;

    event Responded(bytes32 indexed id, uint256 timestamp);
    
    constructor(IVerifier _verifier) { 
        verifier = _verifier; 
    }

    /** @dev Submit a response to the contract */
    function submit(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[12] memory input, bytes32 _root, bytes32 formIdHash, bytes32 _hash) public {
        bytes32 merkleRoot = getMerkleRoot(formIdHash);
        require(merkleRoot != "" && merkleRoot == _root, "Cannot find your merkle root"); 
        require(isResponded(_hash) == false, "Form already submitted");
        require(verifier.verifyProof(a, b, c, input), "Invalid proof");
        responses[_hash] == true;

        emit Responded(_hash, block.timestamp);
    }

    /** @dev whether user has already responded */
    function isResponded(bytes32 _hash) public view returns (bool) {
        return responses[_hash];
    }

    /** @dev get the formId's corresponding merkleRoot */
    function getMerkleRoot(bytes32 id) public view returns (bytes32) {
        return merkleRoots[id];
    }

    /** @dev set the formId's corresponding merkleRoot */
    function setMerkleRoot(bytes32 id, bytes32 root) public {
        require(getMerkleRoot(id) == "", "Merkle root already initialized");
        merkleRoots[id] = root;
        owners[msg.sender] = id;
    }

    /** @dev set the formId's corresponding merkleRoot */
    function updateMerkleRoot(bytes32 id, bytes32 root) public {
        require(owners[msg.sender] == id, "You are not the owner of this form");
        merkleRoots[id] = root;
    }
}