/**
 *Submitted for verification at polygonscan.com on 2022-10-15
*/

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

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

pragma solidity ^0.8.13;

// Raffle smart contract
contract Raffle {
    using ByteHasher for bytes;
    address public manager;
    uint256 public participantCount;
    uint256 public immutable groupId = 1;
    address[] public participants;
    IWorldID public immutable worldId;

    mapping(address => bool) public isRegistered;
    mapping(uint256 => bool) internal nullifierHashes;

    constructor(IWorldID _worldId) payable {
        worldId = _worldId;
        // groupId = _groupId; // use default of 1 for MVP
        manager = msg.sender;
    }

    function enterRaffle(
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        require(
            isRegistered[msg.sender] == false,
            "This wallet is already registered"
        );
        require(
            nullifierHashes[nullifierHash] == false,
            "You have already entered the raffle"
        );

        // Verify proof of humanhood
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(msg.sender).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this)).hashToField(),
            proof
        );
        // increase count
        ++participantCount;
        // add human id to map of registered humans
        nullifierHashes[nullifierHash] = true;
        // add address to map of registered
        isRegistered[msg.sender] = true;
        // add address to array of participants for selecting winner
        participants.push(msg.sender);

        // emit ReceiverRegistered(msg.sender);
    }

    function pickWinner() public {
        require(msg.sender == manager, "Only the manager can pick a winner");
        require(participantCount > 0, "There are no raffle participants");
        require(address(this).balance > 0, "Raffle prize has not been set");

        // draw random ticket
        uint256 index = random() % participantCount;
        address winner = participants[index];

        // remove winner from array and decrease count
        participants[index] = participants[participantCount - 1];
        delete participants[participantCount - 1];
        participantCount--;

        // send the balance to the winner
        payable(winner).transfer(address(this).balance);
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants
                    )
                )
            );
    }
}