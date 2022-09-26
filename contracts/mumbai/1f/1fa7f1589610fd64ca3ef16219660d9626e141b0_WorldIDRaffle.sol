// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import { ERC721 } from 'solmate/tokens/ERC721.sol';
import { IWorldID } from 'world-id-contracts/interfaces/IWorldID.sol';
import { ByteHasher } from 'world-id-contracts/libraries/ByteHasher.sol';

/// @title World ID Raffle example
/// @author Ted Palmer
/// @notice Template contract for raffling nfts to World ID users
contract WorldIDRaffle {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when trying to update the raffle information without being the manager
    error Unauthorized();

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a user subscribes to the raffle
    /// @param subscriber The address that subscribed to the raffle
    event Subscribed(address subscriber);

    /// @notice Emitted when the raffle information is changed
    /// @param token The ERC721 token that the winner will receive
    // event RaffleUpdated(ERC721 token);

    /// @notice Emitted when the raffle is ended and the winner has been sent the ERC721
    /// @param winner The address that won the raffle
    event WinnerPicked(address winner);

    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @dev The WorldID instance that will be used for managing groups and verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group whose participants can claim this airdrop
    uint256 internal immutable groupId;

    /// @dev The World ID Action ID
    uint256 internal immutable actionId;

    /// @notice The ERC721 token to be raffled and transferred to the winner
    // ERC721 public immutable token;

    /// @notice The length of the raffle in minutes
    uint256 numberOfMinutes;

    /// @notice The address that manages this raffle, which is allowed to update and redeploy new raffles.
    address public immutable manager = msg.sender;

    /// @notice The list of registered subscribers to the raffle
    address[] public subscribers;

    /// @dev Whether a nullifier hash has been used already. Used to prevent double-signaling
    mapping(uint256 => bool) internal nullifierHashes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTOR                              ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Deploys a WorldIDAirdrop instance
    /// @param _worldId The WorldID instance that will manage groups and verify proofs
    /// @param _groupId The ID of the Semaphore group World ID is using (`1`)
    /// @param _actionId The actionId as registered in the developer portal
    // / _token The ERC721 token that will be raffled off
    constructor(
        IWorldID _worldId,
        uint256 _groupId,
        string memory _actionId,
        // ERC721 _token,
        uint256 _numberOfMinutes
    ) {
        worldId = _worldId;
        groupId = _groupId;
        actionId = abi.encodePacked(_actionId).hashToField();
        // token = _token;
        numberOfMinutes = _numberOfMinutes;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                             SUBSCRIBE LOGIC                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Subscribe to the raffle
    /// @param signal The user's wallet address and also the signal of the ZKP
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero knowledge proof that demonstrates the claimer has a verified World ID (returned by the JS widget).
    function verifyAndSubscribe(
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
            abi.encodePacked(signal).hashToField(), // The signal of the proof
            nullifierHash,
            actionId,
            proof
        );

        // We now record the user has done this, so they can't do it again (proof of uniqueness)
        nullifierHashes[nullifierHash] = true;

        // Finally, execute your logic here
        subscribers.push(msg.sender);
        emit Subscribed(msg.sender);
    }


    ///////////////////////////////////////////////////////////////////////////////
    ///                            PICK WINNER AND TRANSFER                    ///
    //////////////////////////////////////////////////////////////////////////////

    function pickWinnerAndTransfer() public payable {
        if (msg.sender != manager) revert Unauthorized();
        require(block.timestamp >= (numberOfMinutes * 1 minutes));

        //randomly select a winner from the list of subscribers
        uint index = random() % subscribers.length;
        emit WinnerPicked(subscribers[index]);
        // subscribers[index].transfer(this.balance);
        // subscribers = new address[](0);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                            UPDATE RAFFLE LOGIC                         ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Restart the raffle with a new ERC721, list of subscribers and time block 
    /// _token The ERC721 token that will be raffled off
    // function restartRaffle(ERC721 _token) public {
    //     if (msg.sender != manager) revert Unauthorized();

    //     token = _token;
    //     emit RaffleUpdated(_token);
    // }

    ///////////////////////////////////////////////////////////////////////////////
    ///                            RANDOM LOGIC                                ///
    //////////////////////////////////////////////////////////////////////////////


    function random() private view returns(uint){
         return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, subscribers))); // would like to make this better, but for fine for MVP
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