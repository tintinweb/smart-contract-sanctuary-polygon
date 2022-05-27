//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract SignedDigitalAsset {

    // The owner of the contract
    address public owner;
    // Name of the institution (for reference purposes only)
    // string public institution;
    // Storage for linking the signatures to the digital fingerprints
    mapping (bytes32 => string) fingerprintSignatureMapping;
    // Event functionality
    event SignatureAdded (string digitalFingerprint, string signature, uint256 timestamp);
    // Modifier restricting only the owner of this contract to perform certain operations
    modifier isOwner() { if (msg.sender != owner) revert(); _; }
    // Constructor of the Signed Digital Asset contract.
    constructor() {
        owner = msg.sender;
    }

    // Adds a new signature and links it to its corresponding digital fingerprint
    function addSignature(string memory digitalFingerprint, string memory signature)
        public
        isOwner {
        // Add signature to the mapping
        fingerprintSignatureMapping [keccak256(abi.encode(digitalFingerprint))] = signature;
        // Broadcast the token added event
        emit SignatureAdded(digitalFingerprint, signature, block.timestamp);
    }
    // Removes a signature from this contract
    function removeSignature(string memory digitalFingerprint)
        public
        isOwner {
        // Replaces an existing Signature with empty string
        fingerprintSignatureMapping [keccak256(abi.encode(digitalFingerprint))] = "";
    }

    // Removes the entire contract from the blockchain and invalidates all signatures
    function removeSdaContract()
        public
        isOwner {
        selfdestruct (payable(owner));
    }

}