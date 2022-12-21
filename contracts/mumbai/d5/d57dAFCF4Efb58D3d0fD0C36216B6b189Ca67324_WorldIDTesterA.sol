// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";

contract WorldIDTesterA {

    event UserVerified(address indexed user);
    event AdminAdded(address indexed newAdmin, address indexed addedBy);
    event AdminDeleted(address indexed deletedAdmin, address indexed deletedBy);

    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();
 
    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    address public worldcoin;  //note: this is immutable in Worlcoin's example contract and private

    /// @dev worldcoin action id used in verifyAndExecute
    string public actionId = "";

    /// @dev whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(uint256 => bool) public nullifierHashes;  // nullifier hash => bool

    /// @dev whether the address (World ID signal) has successfully been through the verify process
    mapping(address => bool) public isVerified; // user address => bool

    /// @dev whether the address is a contract admin
    mapping(address => bool) public isAdmin;   // admin address => bool

    /// @dev count of contract admins
    uint public adminsCount;


    constructor (IWorldID _worldId) {
        require(_worldId != IWorldID(address(0)), "zero address is invalid");
        isAdmin[msg.sender] = true;
        adminsCount = 1;
        worldId = _worldId;
    }


    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further details)
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demostrates the claimer is registered with World ID (returned by the JS widget).
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function verifyAndExecute(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        // First, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );

        // We now record the user has done this, so they can't do it again (proof of uniqueness)
        nullifierHashes[nullifierHash] = true;

        // Finally, execute your logic here, for example issue a token, NFT, etc...
        // Make sure to emit some kind of event afterwards!
        isVerified[signal] = true;
        emit UserVerified(signal);
    }


    /// @dev enforce only contract administrators allowed
    modifier onlyAdmins {
        require(isAdmin[msg.sender], "only admins");
        _;
    }


    /// @dev add a contract administrator
    function addAdmin(address _newAdmin) external onlyAdmins {
        ++adminsCount;
        isAdmin[_newAdmin] = true;
        emit AdminAdded(_newAdmin, msg.sender);
    }


    /// @dev delete a contract administrator. there must be at least one admin
    function deleteAdmin(address _admin) external onlyAdmins {
        require(adminsCount > 1, "can't delete last admin");
        --adminsCount;
        isAdmin[_admin] = false;
        emit AdminDeleted(_admin, msg.sender);
    }

    
    /// @dev to allow the worldcoin action id to be set/changed
    function setActionId(string calldata _actionId) external onlyAdmins {
        actionId = _actionId;
    }

    
    /// @dev allow a contract admin to set isVerified true/false for an address
    function setIsVerified(address _userAddr, bool _verified) external onlyAdmins {
        isVerified[_userAddr] = _verified;
    }

    
    /// @dev allow msg.sender to set isVerified true/false for itself
    function setIsVerified(bool _verified) external {
        isVerified[msg.sender] = _verified;
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