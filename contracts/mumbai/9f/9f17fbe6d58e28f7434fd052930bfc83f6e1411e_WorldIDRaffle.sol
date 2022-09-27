// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC721 } from 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';
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

    /// @notice The adddress of the ERC721 to be raffled off
    address nftContractAddress;
        
    /// @notice The tokenId of the ERC721 to be raffled off
    uint256 nftTokenId;

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
    /// @param _nftContractAddress The raffled nft's contract address
    /// @param _nftTokenId The tokenId of the nft
    /// @dev Make sure the owner has approved this contract to transfer the nft
    constructor(
        IWorldID _worldId,
        uint256 _groupId,
        string memory _actionId,
        address _nftContractAddress,
        uint256 _nftTokenId,
        uint256 _numberOfMinutes
    ) {
        worldId = _worldId;
        groupId = _groupId;
        actionId = abi.encodePacked(_actionId).hashToField();
        nftContractAddress = _nftContractAddress;
        nftTokenId = _nftTokenId;
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
        address winner = subscribers[index];

        IERC721 contractAddress = IERC721(nftContractAddress);
        contractAddress.safeTransferFrom(msg.sender, winner, nftTokenId);

        emit WinnerPicked(winner);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                            UPDATE RAFFLE LOGIC                         ///
    //////////////////////////////////////////////////////////////////////////////

    /// TODO 
    /// @notice Reset the raffle with a new ERC721, list of subscribers and time block 
    /// _token The ERC721 token that will be raffled off
    // function restartRaffle(ERC721 _token) public {
    //     if (msg.sender != manager) revert Unauthorized();
    //     emit RaffleUpdated(_token);
    // }

    ///////////////////////////////////////////////////////////////////////////////
    ///                            RANDOM LOGIC                                ///
    //////////////////////////////////////////////////////////////////////////////

    function random() private view returns(uint){
         return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, subscribers))); // would like to make this better, but for fine for MVP
     }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}