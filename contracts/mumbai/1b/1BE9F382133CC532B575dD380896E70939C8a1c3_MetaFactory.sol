// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "../library/RMRKErrors.sol";

/**
 * @title Ownable
 * @author RMRK team
 * @notice A minimal ownable smart contractf or owner and contributors.
 * @dev This smart contract is based on "openzeppelin's access/Ownable.sol".
 */
contract Ownable is Context {
    address private _owner;
    mapping(address => uint256) private _contributors;

    /**
     * @notice Used to anounce the transfer of ownership.
     * @param previousOwner Address of the account that transferred their ownership role
     * @param newOwner Address of the account receiving the ownership role
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Event that signifies that an address was granted contributor role or that the permission has been
     *  revoked.
     * @dev This can only be triggered by a current owner, so there is no need to include that information in the event.
     * @param contributor Address of the account that had contributor role status updated
     * @param isContributor A boolean value signifying whether the role has been granted (`true`) or revoked (`false`)
     */
    event ContributorUpdate(address indexed contributor, bool isContributor);

    /**
     * @dev Reverts if called by any account other than the owner or an approved contributor.
     */
    modifier onlyOwnerOrContributor() {
        _onlyOwnerOrContributor();
        _;
    }

    /**
     * @dev Reverts if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Initializes the contract by setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @notice Returns the address of the current owner.
     * @return Address of the current owner
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Leaves the contract without owner. Functions using the `onlyOwner` modifier will be disabled.
     * @dev Can only be called by the current owner.
     * @dev Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is
     *  only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Can only be called by the current owner.
     * @param newOwner Address of the new owner's account
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert RMRKNewOwnerIsZeroAddress();
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Internal function without access restriction.
     * @dev Emits ***OwnershipTransferred*** event.
     * @param newOwner Address of the new owner's account
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Adds or removes a contributor to the smart contract.
     * @dev Can only be called by the owner.
     * @dev Emits ***ContributorUpdate*** event.
     * @param contributor Address of the contributor's account
     * @param grantRole A boolean value signifying whether the contributor role is being granted (`true`) or revoked
     *  (`false`)
     */
    function manageContributor(
        address contributor,
        bool grantRole
    ) external onlyOwner {
        if (contributor == address(0)) revert RMRKNewContributorIsZeroAddress();
        grantRole
            ? _contributors[contributor] = 1
            : _contributors[contributor] = 0;
        emit ContributorUpdate(contributor, grantRole);
    }

    /**
     * @notice Used to check if the address is one of the contributors.
     * @param contributor Address of the contributor whose status we are checking
     * @return Boolean value indicating whether the address is a contributor or not
     */
    function isContributor(address contributor) public view returns (bool) {
        return _contributors[contributor] == 1;
    }

    /**
     * @notice Used to verify that the caller is either the owner or a contributor.
     * @dev If the caller is not the owner or a contributor, the execution will be reverted.
     */
    function _onlyOwnerOrContributor() private view {
        if (owner() != _msgSender() && !isContributor(_msgSender()))
            revert RMRKNotOwnerOrContributor();
    }

    /**
     * @notice Used to verify that the caller is the owner.
     * @dev If the caller is not the owner, the execution will be reverted.
     */
    function _onlyOwner() private view {
        if (owner() != _msgSender()) revert RMRKNotOwner();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC6454
 * @author RMRK team
 * @notice A minimal extension to identify the transferability of Non-Fungible Tokens.
 */
interface IERC6454 is IERC165 {
    /**
     * @notice Used to check whether the given token is transferable or not.
     * @dev If this function returns `false`, the transfer of the token MUST revert execution.
     * @dev If the tokenId does not exist, this method MUST revert execution, unless the token is being checked for
     *  minting.
     * @param tokenId ID of the token being checked
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @return Boolean value indicating whether the given token is transferable
     */
    function isTransferable(
        uint256 tokenId,
        address from,
        address to
    ) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

/// @title RMRKErrors
/// @author RMRK team
/// @notice A collection of errors used in the RMRK suite
/// @dev Errors are kept in a centralised file in order to provide a central point of reference and to avoid error
///  naming collisions due to inheritance

/// Attempting to grant the token to 0x0 address
error ERC721AddressZeroIsNotaValidOwner();
/// Attempting to grant approval to the current owner of the token
error ERC721ApprovalToCurrentOwner();
/// Attempting to grant approval when not being owner or approved for all should not be permitted
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
/// Attempting to get approvals for a token owned by 0x0 (considered non-existent)
error ERC721ApprovedQueryForNonexistentToken();
/// Attempting to grant approval to self
error ERC721ApproveToCaller();
/// Attempting to use an invalid token ID
error ERC721InvalidTokenId();
/// Attempting to mint to 0x0 address
error ERC721MintToTheZeroAddress();
/// Attempting to manage a token without being its owner or approved by the owner
error ERC721NotApprovedOrOwner();
/// Attempting to mint an already minted token
error ERC721TokenAlreadyMinted();
/// Attempting to transfer the token from an address that is not the owner
error ERC721TransferFromIncorrectOwner();
/// Attempting to safe transfer to an address that is unable to receive the token
error ERC721TransferToNonReceiverImplementer();
/// Attempting to transfer the token to a 0x0 address
error ERC721TransferToTheZeroAddress();
/// Attempting to grant approval of assets to their current owner
error RMRKApprovalForAssetsToCurrentOwner();
/// Attempting to grant approval of assets without being the caller or approved for all
error RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
/// Attempting to incorrectly configue a Catalog item
error RMRKBadConfig();
/// Attempting to set the priorities with an array of length that doesn't match the length of active assets array
error RMRKBadPriorityListLength();
/// Attempting to add an asset entry with `Part`s, without setting the `Catalog` address
error RMRKCatalogRequiredForParts();
/// Attempting to transfer a soulbound (non-transferrable) token
error RMRKCannotTransferSoulbound();
/// Attempting to accept a child that has already been accepted
error RMRKChildAlreadyExists();
/// Attempting to interact with a child, using index that is higher than the number of children
error RMRKChildIndexOutOfRange();
/// Attempting to find the index of a child token on a parent which does not own it.
error RMRKChildNotFoundInParent();
/// Attempting to pass collaborator address array and collaborator permission array of different lengths
error RMRKCollaboratorArraysNotEqualLength();
/// Attempting to register a collection that is already registered
error RMRKCollectionAlreadyRegistered();
/// Attempting to manage or interact with colleciton that is not registered
error RMRKCollectionNotRegistered();
/// Attempting to equip a `Part` with a child not approved by the Catalog
error RMRKEquippableEquipNotAllowedByCatalog();
/// Attempting to use ID 0, which is not supported
/// @dev The ID 0 in RMRK suite is reserved for empty values. Guarding against its use ensures the expected operation
error RMRKIdZeroForbidden();
/// Attempting to interact with an asset, using index greater than number of assets
error RMRKIndexOutOfRange();
/// Attempting to reclaim a child that can't be reclaimed
error RMRKInvalidChildReclaim();
/// Attempting to interact with an end-user account when the contract account is expected
error RMRKIsNotContract();
/// Attempting to interact with a contract that had its operation locked
error RMRKLocked();
/// Attempting to add a pending child after the number of pending children has reached the limit (default limit is 128)
error RMRKMaxPendingChildrenReached();
/// Attempting to add a pending asset after the number of pending assets has reached the limit (default limit is
///  128)
error RMRKMaxPendingAssetsReached();
/// Attempting to burn a total number of recursive children higher than maximum set
/// @param childContract Address of the collection smart contract in which the maximum number of recursive burns was reached
/// @param childId ID of the child token at which the maximum number of recursive burns was reached
error RMRKMaxRecursiveBurnsReached(address childContract, uint256 childId);
/// Attempting to mint a number of tokens that would cause the total supply to be greater than maximum supply
error RMRKMintOverMax();
/// Attempting to mint a nested token to a smart contract that doesn't support nesting
error RMRKMintToNonRMRKNestableImplementer();
/// Attempting to pass complementary arrays of different lengths
error RMRKMismachedArrayLength();
/// Attempting to transfer a child before it is unequipped
error RMRKMustUnequipFirst();
/// Attempting to nest a child over the nestable limit (current limit is 100 levels of nesting)
error RMRKNestableTooDeep();
/// Attempting to nest the token to own descendant, which would create a loop and leave the looped tokens in limbo
error RMRKNestableTransferToDescendant();
/// Attempting to nest the token to a smart contract that doesn't support nesting
error RMRKNestableTransferToNonRMRKNestableImplementer();
/// Attempting to nest the token into itself
error RMRKNestableTransferToSelf();
/// Attempting to interact with an asset that can not be found
error RMRKNoAssetMatchingId();
/// Attempting to manage an asset without owning it or having been granted permission by the owner to do so
error RMRKNotApprovedForAssetsOrOwner();
/// Attempting to interact with a token without being its owner or having been granted permission by the
///  owner to do so
/// @dev When a token is nested, only the direct owner (NFT parent) can mange it. In that case, approved addresses are
///  not allowed to manage it, in order to ensure the expected behaviour
error RMRKNotApprovedOrDirectOwner();
/// Attempting to manage a collection without being the collection's collaborator
error RMRKNotCollectionCollaborator();
/// Attemting to manage a collection without being the collection's issuer
error RMRKNotCollectionIssuer();
/// Attempting to manage a collection without being the collection's issuer or collaborator
error RMRKNotCollectionIssuerOrCollaborator();
/// Attempting to compose an asset wihtout having an associated Catalog
error RMRKNotComposableAsset();
/// Attempting to unequip an item that isn't equipped
error RMRKNotEquipped();
/// Attempting to interact with a management function without being the smart contract's owner
error RMRKNotOwner();
/// Attempting to interact with a function without being the owner or contributor of the collection
error RMRKNotOwnerOrContributor();
/// Attempting to manage a collection without being the specific address
error RMRKNotSpecificAddress();
/// Attempting to manage a token without being its owner
error RMRKNotTokenOwner();
/// Attempting to transfer the ownership to the 0x0 address
error RMRKNewOwnerIsZeroAddress();
/// Attempting to assign a 0x0 address as a contributor
error RMRKNewContributorIsZeroAddress();
/// Attemtping to use `Ownable` interface without implementing it
error RMRKOwnableNotImplemented();
/// Attempting an operation requiring the token being nested, while it is not
error RMRKParentIsNotNFT();
/// Attempting to add a `Part` with an ID that is already used
error RMRKPartAlreadyExists();
/// Attempting to use a `Part` that doesn't exist
error RMRKPartDoesNotExist();
/// Attempting to use a `Part` that is `Fixed` when `Slot` kind of `Part` should be used
error RMRKPartIsNotSlot();
/// Attempting to interact with a pending child using an index greater than the size of pending array
error RMRKPendingChildIndexOutOfRange();
/// Attempting to add an asset using an ID that has already been used
error RMRKAssetAlreadyExists();
/// Attempting to equip an item into a slot that already has an item equipped
error RMRKSlotAlreadyUsed();
/// Attempting to equip an item into a `Slot` that the target asset does not implement
error RMRKTargetAssetCannotReceiveSlot();
/// Attempting to equip a child into a `Slot` and parent that the child's collection doesn't support
error RMRKTokenCannotBeEquippedWithAssetIntoSlot();
/// Attempting to compose a NFT of a token without active assets
error RMRKTokenDoesNotHaveAsset();
/// Attempting to determine the asset with the top priority on a token without assets
error RMRKTokenHasNoAssets();
/// Attempting to accept or transfer a child which does not match the one at the specified index
error RMRKUnexpectedChildId();
/// Attempting to reject all pending assets but more assets than expected are pending
error RMRKUnexpectedNumberOfAssets();
/// Attempting to reject all pending children but children assets than expected are pending
error RMRKUnexpectedNumberOfChildren();
/// Attempting to accept or reject an asset which does not match the one at the specified index
error RMRKUnexpectedAssetId();
/// Attempting an operation expecting a parent to the token which is not the actual one
error RMRKUnexpectedParent();
/// Attempting not to pass an empty array of equippable addresses when adding or setting the equippable addresses
error RMRKZeroLengthIdsPassed();
/// Attempting to set the royalties to a value higher than 100% (10000 in base points)
error RMRKRoyaltiesTooHigh();
/// Attempting to do a bulk operation on a token that is not owned by the caller
error RMRKCanOnlyDoBulkOperationsOnOwnedTokens();
/// Attempting to do a bulk operation with multiple tokens at a time
error RMRKCanOnlyDoBulkOperationsWithOneTokenAtATime();

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC5773
 * @author RMRK team
 * @notice Interface smart contract of the RMRK multi asset module.
 */
interface IERC5773 is IERC165 {
    /**
     * @notice Used to notify listeners that an asset object is initialized at `assetId`.
     * @param assetId ID of the asset that was initialized
     */
    event AssetSet(uint64 indexed assetId);

    /**
     * @notice Used to notify listeners that an asset object at `assetId` is added to token's pending asset
     *  array.
     * @param tokenIds An array of token IDs that received a new pending asset
     * @param assetId ID of the asset that has been added to the token's pending assets array
     * @param replacesId ID of the asset that would be replaced
     */
    event AssetAddedToTokens(
        uint256[] tokenIds,
        uint64 indexed assetId,
        uint64 indexed replacesId
    );

    /**
     * @notice Used to notify listeners that an asset object at `assetId` is accepted by the token and migrated
     *  from token's pending assets array to active assets array of the token.
     * @param tokenId ID of the token that had a new asset accepted
     * @param assetId ID of the asset that was accepted
     * @param replacesId ID of the asset that was replaced
     */
    event AssetAccepted(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed replacesId
    );

    /**
     * @notice Used to notify listeners that an asset object at `assetId` is rejected from token and is dropped
     *  from the pending assets array of the token.
     * @param tokenId ID of the token that had an asset rejected
     * @param assetId ID of the asset that was rejected
     */
    event AssetRejected(uint256 indexed tokenId, uint64 indexed assetId);

    /**
     * @notice Used to notify listeners that token's prioritiy array is reordered.
     * @param tokenId ID of the token that had the asset priority array updated
     */
    event AssetPrioritySet(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners that owner has granted an approval to the user to manage the assets of a
     *  given token.
     * @dev Approvals must be cleared on transfer
     * @param owner Address of the account that has granted the approval for all token's assets
     * @param approved Address of the account that has been granted approval to manage the token's assets
     * @param tokenId ID of the token on which the approval was granted
     */
    event ApprovalForAssets(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @notice Used to notify listeners that owner has granted approval to the user to manage assets of all of their
     *  tokens.
     * @param owner Address of the account that has granted the approval for all assets on all of their tokens
     * @param operator Address of the account that has been granted the approval to manage the token's assets on all of
     *  the tokens
     * @param approved Boolean value signifying whether the permission has been granted (`true`) or revoked (`false`)
     */
    event ApprovalForAllForAssets(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @notice Accepts an asset at from the pending array of given token.
     * @dev Migrates the asset from the token's pending asset array to the token's active asset array.
     * @dev Active assets cannot be removed by anyone, but can be replaced by a new asset.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits an {AssetAccepted} event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset expected to be in the index
     */
    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external;

    /**
     * @notice Rejects an asset from the pending array of given token.
     * @dev Removes the asset from the token's pending asset array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits a {AssetRejected} event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset expected to be in the index
     */
    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external;

    /**
     * @notice Rejects all assets from the pending array of a given token.
     * @dev Effecitvely deletes the pending array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     * @dev Emits a {AssetRejected} event with assetId = 0.
     * @param tokenId ID of the token of which to clear the pending array.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from rejecting assets which
     *  arrive just before this operation.
     */
    function rejectAllAssets(uint256 tokenId, uint256 maxRejections) external;

    /**
     * @notice Sets a new priority array for a given token.
     * @dev The priority array is a non-sequential list of `uint64`s, where the lowest value is considered highest
     *  priority.
     * @dev Value `0` of a priority is a special case equivalent to unitialized.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - The length of `priorities` must be equal the length of the active assets array.
     * @dev Emits a {AssetPrioritySet} event.
     * @param tokenId ID of the token to set the priorities for
     * @param priorities An array of priorities of active assets. The succesion of items in the priorities array
     *  matches that of the succesion of items in the active array
     */
    function setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) external;

    /**
     * @notice Used to retrieve IDs of the active assets of given token.
     * @dev Asset data is stored by reference, in order to access the data corresponding to the ID, call
     *  `getAssetMetadata(tokenId, assetId)`.
     * @dev You can safely get 10k
     * @param tokenId ID of the token to retrieve the IDs of the active assets
     * @return An array of active asset IDs of the given token
     */
    function getActiveAssets(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    /**
     * @notice Used to retrieve IDs of the pending assets of given token.
     * @dev Asset data is stored by reference, in order to access the data corresponding to the ID, call
     *  `getAssetMetadata(tokenId, assetId)`.
     * @param tokenId ID of the token to retrieve the IDs of the pending assets
     * @return An array of pending asset IDs of the given token
     */
    function getPendingAssets(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    /**
     * @notice Used to retrieve the priorities of the active resoources of a given token.
     * @dev Asset priorities are a non-sequential array of uint64 values with an array size equal to active asset
     *  priorites.
     * @param tokenId ID of the token for which to retrieve the priorities of the active assets
     * @return An array of priorities of the active assets of the given token
     */
    function getActiveAssetPriorities(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    /**
     * @notice Used to retrieve the asset that will be replaced if a given asset from the token's pending array
     *  is accepted.
     * @dev Asset data is stored by reference, in order to access the data corresponding to the ID, call
     *  `getAssetMetadata(tokenId, assetId)`.
     * @param tokenId ID of the token to check
     * @param newAssetId ID of the pending asset which will be accepted
     * @return ID of the asset which will be replaced
     */
    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) external view returns (uint64);

    /**
     * @notice Used to fetch the asset metadata of the specified token's active asset with the given index.
     * @dev Assets are stored by reference mapping `_assets[assetId]`.
     * @dev Can be overriden to implement enumerate, fallback or other custom logic.
     * @param tokenId ID of the token from which to retrieve the asset metadata
     * @param assetId Asset Id, must be in the active assets array
     * @return The metadata of the asset belonging to the specified index in the token's active assets
     *  array
     */
    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) external view returns (string memory);

    // Approvals

    /**
     * @notice Used to grant permission to the user to manage token's assets.
     * @dev This differs from transfer approvals, as approvals are not cleared when the approved party accepts or
     *  rejects an asset, or sets asset priorities. This approval is cleared on token transfer.
     * @dev Only a single account can be approved at a time, so approving the `0x0` address clears previous approvals.
     * @dev Requirements:
     *
     *  - The caller must own the token or be an approved operator.
     *  - `tokenId` must exist.
     * @dev Emits an {ApprovalForAssets} event.
     * @param to Address of the account to grant the approval to
     * @param tokenId ID of the token for which the approval to manage the assets is granted
     */
    function approveForAssets(address to, uint256 tokenId) external;

    /**
     * @notice Used to retrieve the address of the account approved to manage assets of a given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param tokenId ID of the token for which to retrieve the approved address
     * @return Address of the account that is approved to manage the specified token's assets
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) external view returns (address);

    /**
     * @notice Used to add or remove an operator of assets for the caller.
     * @dev Operators can call {acceptAsset}, {rejectAsset}, {rejectAllAssets} or {setPriority} for any token
     *  owned by the caller.
     * @dev Requirements:
     *
     *  - The `operator` cannot be the caller.
     * @dev Emits an {ApprovalForAllForAssets} event.
     * @param operator Address of the account to which the operator role is granted or revoked from
     * @param approved The boolean value indicating whether the operator role is being granted (`true`) or revoked
     *  (`false`)
     */
    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) external;

    /**
     * @notice Used to check whether the address has been granted the operator role by a given address or not.
     * @dev See {setApprovalForAllForAssets}.
     * @param owner Address of the account that we are checking for whether it has granted the operator role
     * @param operator Address of the account that we are checking whether it has the operator role or not
     * @return A boolean value indicating wehter the account we are checking has been granted the operator role
     */
    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC6059
 * @author RMRK team
 * @notice Interface smart contract of the RMRK nestable module.
 */
interface IERC6059 is IERC165 {
    /**
     * @notice The core struct of RMRK ownership.
     * @dev The `DirectOwner` struct is used to store information of the next immediate owner, be it the parent token or
     *  the externally owned account.
     * @dev If the token is owned by the externally owned account, the `tokenId` should equal `0`.
     * @param tokenId ID of the parent token
     * @param ownerAddress Address of the owner of the token. If the owner is another token, then the address should be
     *  the one of the parent token's collection smart contract. If the owner is externally owned account, the address
     *  should be the address of this account
     * @param isNft A boolean value signifying whether the token is owned by another token (`true`) or by an externally
     *  owned account (`false`)
     */
    struct DirectOwner {
        uint256 tokenId;
        address ownerAddress;
    }

    /**
     * @notice Used to notify listeners that the token is being transferred.
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from Address of the previous immediate owner, which is a smart contract if the token was nested.
     * @param to Address of the new immediate owner, which is a smart contract if the token is being nested.
     * @param fromTokenId ID of the previous parent token. If the token was not nested before, the value should be `0`
     * @param toTokenId ID of the new parent token. If the token is not being nested, the value should be `0`
     * @param tokenId ID of the token being transferred
     */
    event NestTransfer(
        address indexed from,
        address indexed to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 indexed tokenId
    );

    /**
     * @notice Used to notify listeners that a new token has been added to a given token's pending children array.
     * @dev Emitted when a child NFT is added to a token's pending array.
     * @param tokenId ID of the token that received a new pending child token
     * @param childIndex Index of the proposed child token in the parent token's pending children array
     * @param childAddress Address of the proposed child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     */
    event ChildProposed(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    /**
     * @notice Used to notify listeners that a new child token was accepted by the parent token.
     * @dev Emitted when a parent token accepts a token from its pending array, migrating it to the active array.
     * @param tokenId ID of the token that accepted a new child token
     * @param childIndex Index of the newly accepted child token in the parent token's active children array
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     */
    event ChildAccepted(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    /**
     * @notice Used to notify listeners that all pending child tokens of a given token have been rejected.
     * @dev Emitted when a token removes all a child tokens from its pending array.
     * @param tokenId ID of the token that rejected all of the pending children
     */
    event AllChildrenRejected(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners a child token has been transferred from parent token.
     * @dev Emitted when a token transfers a child from itself, transferring ownership to the root owner.
     * @param tokenId ID of the token that transferred a child token
     * @param childIndex Index of a child in the array from which it is being transferred
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     * @param fromPending A boolean value signifying whether the token was in the pending child tokens array (`true`) or
     *  in the active child tokens array (`false`)
     * @param toZero A boolean value signifying whether the token is being transferred to the `0x0` address (`true`) or
     *  not (`false`)
     */
    event ChildTransferred(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId,
        bool fromPending,
        bool toZero
    );

    /**
     * @notice The core child token struct, holding the information about the child tokens.
     * @return tokenId ID of the child token in the child token's collection smart contract
     * @return contractAddress Address of the child token's smart contract
     */
    struct Child {
        uint256 tokenId;
        address contractAddress;
    }

    /**
     * @notice Used to retrieve the *root* owner of a given token.
     * @dev The *root* owner of the token is an externally owned account (EOA). If the given token is child of another
     *  NFT, this will return an EOA address. Otherwise, if the token is owned by an EOA, this EOA wil be returned.
     * @param tokenId ID of the token for which the *root* owner has been retrieved
     * @return owner The *root* owner of the token
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Used to retrieve the immediate owner of the given token.
     * @dev If the immediate owner is another token, the address returned, should be the one of the parent token's
     *  collection smart contract.
     * @param tokenId ID of the token for which the RMRK owner is being retrieved
     * @return Address of the given token's owner
     * @return The ID of the parent token. Should be `0` if the owner is an externally owned account
     * @return The boolean value signifying whether the owner is an NFT or not
     */
    function directOwnerOf(
        uint256 tokenId
    ) external view returns (address, uint256, bool);

    /**
     * @notice Used to burn a given token.
     * @dev When a token is burned, all of its child tokens are recursively burned as well.
     * @dev When specifying the maximum recursive burns, the execution will be reverted if there are more children to be
     *  burned.
     * @dev Setting the `maxRecursiveBurn` value to 0 will only attempt to burn the specified token and revert if there
     *  are any child tokens present.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @param tokenId ID of the token to burn
     * @param maxRecursiveBurns Maximum number of tokens to recursively burn
     * @return Number of recursively burned children
     */
    function burn(
        uint256 tokenId,
        uint256 maxRecursiveBurns
    ) external returns (uint256);

    /**
     * @notice Used to add a child token to a given parent token.
     * @dev This adds the child token into the given parent token's pending child tokens array.
     * @dev Requirements:
     *
     *  - `directOwnerOf` on the child contract must resolve to the called contract.
     *  - the pending array of the parent contract must not be full.
     * @param parentId ID of the parent token to receive the new child token
     * @param childId ID of the new proposed child token
     * @param data Additional data with no specified format
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) external;

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) external;

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     * Requirements:
     *
     * - `parentId` must exist
     * @param parentId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from rejecting children which
     *  arrive just before this operation.
     */
    function rejectAllChildren(
        uint256 parentId,
        uint256 maxRejections
    ) external;

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of
     *  `to` being the `0x0` address.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of
     *  the parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) external;

    /**
     * @notice Used to retrieve the active child tokens of a given parent token.
     * @dev Returns array of Child structs existing for parent token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the active child tokens
     * @return An array of Child structs containing the parent token's active child tokens
     */
    function childrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    /**
     * @notice Used to retrieve the pending child tokens of a given parent token.
     * @dev Returns array of pending Child structs existing for given parent.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the pending child tokens
     * @return An array of Child structs containing the parent token's pending child tokens
     */
    function pendingChildrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    /**
     * @notice Used to retrieve a specific active child token for a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the child is being retrieved
     * @param index Index of the child token in the parent token's active child tokens array
     * @return A Child struct containing data about the specified child
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    /**
     * @notice Used to retrieve a specific pending child token from a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the pending child token is being retrieved
     * @param index Index of the child token in the parent token's pending child tokens array
     * @return A Child struct containting data about the specified child
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    /**
     * @notice Used to transfer the token into another token.
     * @param from Address of the direct owner of the token to be transferred
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token being transferred
     * @param destinationId ID of the token to receive the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../interfaces/IRMRKExtended.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/access/Ownable.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/extension/soulbound/IERC6454.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC6059.sol";

error InvalidNumberOfAssets();
error InvalidNumberOfDestinationIds();
error InvalidNumberOfToAddresses();
error NotOwnerOrContributor();

contract MetaFactory is ERC721Holder {
    event NewRmrkNft(uint256 tokenId, address indexed rmrkCollectionContract);
    event NewRmrkAsset(
        uint256 assetId,
        uint256 tokenId,
        address indexed rmrkCollectionContract
    );

    modifier onlyCollectionOwner(address collection) {
        _checkCollectionOwner(collection);
        _;
    }

    /**
     * @notice Creates a new asset entry and adds it to the token
     * @param collection The address of the RMRK collection
     * @param tokenId The ID of the token
     * @param asset The asset to set
     */
    function createNewAssetAndAddToToken(
        address collection,
        uint256 tokenId,
        string calldata asset
    ) public onlyCollectionOwner(collection) {
        _createNewAssetAndAddToToken(collection, tokenId, asset);
    }

    function _createNewAssetAndAddToToken(
        address collection,
        uint256 tokenId,
        string calldata asset
    ) private {
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));

        // Resource is autoaccepted if it is a RMRK implementation and it is the first asset, or it is owned by the caller
        IRMRKExtended(collection).addAssetToToken(
            tokenId,
            assetId,
            0 // 0 is the default value as we don't overwrite anything
        );

        emit NewRmrkAsset(assetId, tokenId, collection);
    }

    function mintTokenWithAsset(
        address collection,
        string calldata asset,
        address to
    ) public payable onlyCollectionOwner(collection) {
        uint256 tokenId = IRMRKExtended(collection).mint{value: msg.value}(
            to,
            1
        );

        _createNewAssetAndAddToToken(collection, tokenId, asset);
        emit NewRmrkNft(tokenId, collection);
    }

    // @dev If collection uses soulbound, only the first asset is accepted
    function mintTokenWithMultipleAssets(
        address collection,
        string[] calldata assets,
        address to
    ) public payable onlyCollectionOwner(collection) {
        bool isSoulbound = IERC165(collection).supportsInterface(
            type(IERC6454).interfaceId
        );
        uint256 tokenId;
        if (isSoulbound) {
            // Mint directly to destination
            tokenId = IRMRKExtended(collection).mint{value: msg.value}(to, 1);
        } else {
            // Mint to this contract first, so all assets are auto accepted
            tokenId = IRMRKExtended(collection).mint{value: msg.value}(
                address(this),
                1
            );
        }

        for (uint256 i; i < assets.length; ) {
            _createNewAssetAndAddToToken(collection, tokenId, assets[i]);
            unchecked {
                ++i;
            }
        }

        if (!isSoulbound) {
            // Transfer to destination
            IERC721(collection).safeTransferFrom(address(this), to, tokenId);
        }
        emit NewRmrkNft(tokenId, collection);
    }

    function mintMultipleTokensWithSameAsset(
        address collection,
        string calldata asset,
        address[] calldata toAddresses,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));
        uint256 individualValue = msg.value / amount;
        for (uint256 i; i < amount; ) {
            uint256 tokenId = IRMRKExtended(collection).mint{
                value: individualValue
            }(toAddresses[i], 1);
            // Resource is autoaccepted if it is a RMRK implementation because it is the first asset
            IRMRKExtended(collection).addAssetToToken(
                tokenId,
                assetId,
                0 // 0 is the default value as we don't overwrite anything
            );
            emit NewRmrkNft(tokenId, collection);
            unchecked {
                ++i;
            }
        }
    }

    function mintMultipleTokensWithSameAssetSameAddress(
        address collection,
        string calldata asset,
        address toAddress,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));
        uint256 firstTokenId = IRMRKExtended(collection).mint{value: msg.value}(
            toAddress,
            amount
        );
        _mintMultipleTokensWithExistingAssetSameAddress(
            collection,
            assetId,
            amount,
            firstTokenId
        );
    }

    function mintMultipleTokensWithExistingAssetSameAddress(
        address collection,
        uint64 assetId,
        address toAddress,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        uint256 firstTokenId = IRMRKExtended(collection).mint{value: msg.value}(
            toAddress,
            amount
        );
        _mintMultipleTokensWithExistingAssetSameAddress(
            collection,
            assetId,
            amount,
            firstTokenId
        );
    }

    function _mintMultipleTokensWithExistingAssetSameAddress(
        address collection,
        uint64 assetId,
        uint256 amount,
        uint256 firstTokenId
    ) private {
        for (uint256 i; i < amount; ) {
            // Resource is autoaccepted if it is a RMRK implementation because it is the first asset
            IRMRKExtended(collection).addAssetToToken(
                firstTokenId + i,
                assetId,
                0 // 0 is the default value as we don't overwrite anything
            );
            emit NewRmrkNft(firstTokenId + i, collection);
            unchecked {
                ++i;
            }
        }
    }

    function mintMultipleTokensWithDifferentAsset(
        address collection,
        string[] calldata assets,
        address[] calldata toAddresses,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        if (assets.length != amount) {
            revert InvalidNumberOfAssets();
        }
        if (toAddresses.length != amount) {
            revert InvalidNumberOfToAddresses();
        }

        uint256 individualValue = msg.value / amount;
        for (uint256 i; i < amount; ) {
            uint256 tokenId = IRMRKExtended(collection).mint{
                value: individualValue
            }(toAddresses[i], 1);
            _createNewAssetAndAddToToken(collection, tokenId, assets[i]);
            emit NewRmrkNft(tokenId, collection);
            unchecked {
                ++i;
            }
        }
    }

    function nestMintTokenWithAsset(
        address collection,
        string calldata asset,
        address to,
        uint256 destinationId
    ) public payable onlyCollectionOwner(collection) {
        _nestMintTokenWithAsset(
            collection,
            asset,
            to,
            destinationId,
            msg.value
        );
    }

    // @dev If collection uses soulbound, only the first asset is accepted
    function nestMintTokenWithMultipleAssets(
        address collection,
        string[] calldata assets,
        address to,
        uint256 destinationId
    ) public payable onlyCollectionOwner(collection) {
        bool isSoulbound = IERC165(collection).supportsInterface(
            type(IERC6454).interfaceId
        );
        uint256 tokenId;
        if (isSoulbound) {
            // Mint directly to destination
            tokenId = IRMRKExtended(collection).nestMint{value: msg.value}(
                to,
                1,
                destinationId
            );
        } else {
            // Mint to this contract first, so all assets are auto accepted
            tokenId = IRMRKExtended(collection).mint{value: msg.value}(
                address(this),
                1
            );
        }

        for (uint256 i; i < assets.length; ) {
            _createNewAssetAndAddToToken(collection, tokenId, assets[i]);
            unchecked {
                ++i;
            }
        }

        if (!isSoulbound) {
            // Transfer to destination
            IERC6059(collection).nestTransferFrom(
                address(this),
                to,
                tokenId,
                destinationId,
                ""
            );
        }
        emit NewRmrkNft(tokenId, collection);
    }

    function _nestMintTokenWithAsset(
        address collection,
        string calldata asset,
        address to,
        uint256 destinationId,
        uint256 individualValue
    ) private {
        uint256 tokenId = IRMRKExtended(collection).nestMint{
            value: individualValue
        }(to, 1, destinationId);

        _createNewAssetAndAddToToken(collection, tokenId, asset);
        emit NewRmrkNft(tokenId, collection);
    }

    function nestMintMultipleTokensWithSameAsset(
        address collection,
        string calldata asset, // Same asset for all tokens
        address to, // We expect the destination collection to be the same for all tokens
        uint256[] calldata destinationIds, // We expect the destination collection to be different for all tokens
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        if (destinationIds.length != amount) {
            revert InvalidNumberOfDestinationIds();
        }

        uint256 individualValue = msg.value / amount;
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));
        for (uint256 i; i < amount; ) {
            uint256 tokenId = IRMRKExtended(collection).nestMint{
                value: individualValue
            }(to, 1, destinationIds[i]);
            // Resource is autoaccepted if it is a RMRK implementation because it is the first asset
            IRMRKExtended(collection).addAssetToToken(
                tokenId,
                assetId,
                0 // 0 is the default value as we don't overwrite anything
            );
            emit NewRmrkNft(tokenId, collection);
            unchecked {
                ++i;
            }
        }
    }

    function nestMintMultipleTokensWithDifferentAsset(
        address collection,
        string[] calldata assets, // One asset per token
        address to, // We expect the destination collection to be the same for all tokens
        uint256[] calldata destinationIds, // We expect the destination collection to be different for all tokens
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        if (destinationIds.length != amount) {
            revert InvalidNumberOfDestinationIds();
        }
        if (assets.length != amount) {
            revert InvalidNumberOfAssets();
        }

        uint256 individualValue = msg.value / amount;
        for (uint256 i; i < amount; ) {
            _nestMintTokenWithAsset(
                collection,
                assets[i],
                to,
                destinationIds[i],
                individualValue
            );
            unchecked {
                ++i;
            }
        }
    }

    function _checkCollectionOwner(address collection) internal view {
        if (
            Ownable(collection).owner() != msg.sender &&
            !Ownable(collection).isContributor(msg.sender)
        ) {
            revert NotOwnerOrContributor();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@rmrk-team/evm-contracts/contracts/RMRK/multiasset/IERC5773.sol";

interface IRMRKExtended is IERC5773 {
    /**
     * @notice EXTENDED functions not available in the standard RMRK MultiResource interface
     */

    function addAssetEntry(
        string memory metadataURI
    ) external returns (uint256);

    function addAssetToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 replacesAssetWithId
    ) external;

    function mint(
        address to,
        uint256 numToMint
    ) external payable returns (uint256);

    function nestMint(
        address to,
        uint256 numToMint,
        uint256 destinationId
    ) external payable returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
}