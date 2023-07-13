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

import "../multiasset/IERC5773.sol";

/**
 * @title IERC6220
 * @author RMRK team
 * @notice Interface smart contract of the RMRK equippable module.
 */
interface IERC6220 is IERC5773 {
    /**
     * @notice Used to store the core structure of the `Equippable` RMRK lego.
     * @return assetId The ID of the asset equipping a child
     * @return childAssetId The ID of the asset used as equipment
     * @return childId The ID of token that is equipped
     * @return childEquippableAddress Address of the collection to which the child asset belongs to
     */
    struct Equipment {
        uint64 assetId;
        uint64 childAssetId;
        uint256 childId;
        address childEquippableAddress;
    }

    /**
     * @notice Used to provide a struct for inputing equip data.
     * @dev Only used for input and not storage of data.
     * @return tokenId ID of the token we are managing
     * @return childIndex Index of a child in the list of token's active children
     * @return assetId ID of the asset that we are equipping into
     * @return slotPartId ID of the slot part that we are using to equip
     * @return childAssetId ID of the asset that we are equipping
     */
    struct IntakeEquip {
        uint256 tokenId;
        uint256 childIndex;
        uint64 assetId;
        uint64 slotPartId;
        uint64 childAssetId;
    }

    /**
     * @notice Used to notify listeners that a child's asset has been equipped into one of its parent assets.
     * @param tokenId ID of the token that had an asset equipped
     * @param assetId ID of the asset associated with the token we are equipping into
     * @param slotPartId ID of the slot we are using to equip
     * @param childId ID of the child token we are equipping into the slot
     * @param childAddress Address of the child token's collection
     * @param childAssetId ID of the asset associated with the token we are equipping
     */
    event ChildAssetEquipped(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed slotPartId,
        uint256 childId,
        address childAddress,
        uint64 childAssetId
    );

    /**
     * @notice Used to notify listeners that a child's asset has been unequipped from one of its parent assets.
     * @param tokenId ID of the token that had an asset unequipped
     * @param assetId ID of the asset associated with the token we are unequipping out of
     * @param slotPartId ID of the slot we are unequipping from
     * @param childId ID of the token being unequipped
     * @param childAddress Address of the collection that a token that is being unequipped belongs to
     * @param childAssetId ID of the asset associated with the token we are unequipping
     */
    event ChildAssetUnequipped(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed slotPartId,
        uint256 childId,
        address childAddress,
        uint64 childAssetId
    );

    /**
     * @notice Used to notify listeners that the assets belonging to a `equippableGroupId` have been marked as
     *  equippable into a given slot and parent
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `slotPartId` of the `parentAddress` collection
     * @param slotPartId ID of the slot part of the catalog into which the parts belonging to the equippable group
     *  associated with `equippableGroupId` can be equipped
     * @param parentAddress Address of the collection into which the parts belonging to `equippableGroupId` can be
     *  equipped
     */
    event ValidParentEquippableGroupIdSet(
        uint64 indexed equippableGroupId,
        uint64 indexed slotPartId,
        address parentAddress
    );

    /**
     * @notice Used to equip a child into a token.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function equip(IntakeEquip memory data) external;

    /**
     * @notice Used to unequip child from parent token.
     * @dev This can only be called by the owner of the token or by an account that has been granted permission to
     *  manage the given token by the current owner.
     * @param tokenId ID of the parent from which the child is being unequipped
     * @param assetId ID of the parent's asset that contains the `Slot` into which the child is equipped
     * @param slotPartId ID of the `Slot` from which to unequip the child
     */
    function unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) external;

    /**
     * @notice Used to check whether the token has a given child equipped.
     * @dev This is used to prevent from transferring a child that is equipped.
     * @param tokenId ID of the parent token for which we are querying for
     * @param childAddress Address of the child token's smart contract
     * @param childId ID of the child token
     * @return A boolean value indicating whether the child token is equipped into the given token or not
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) external view returns (bool);

    /**
     * @notice Used to verify whether a token can be equipped into a given parent's slot.
     * @param parent Address of the parent token's smart contract
     * @param tokenId ID of the token we want to equip
     * @param assetId ID of the asset associated with the token we want to equip
     * @param slotId ID of the slot that we want to equip the token into
     * @return A boolean indicating whether the token with the given asset can be equipped into the desired slot
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) external view returns (bool);

    /**
     * @notice Used to get the Equipment object equipped into the specified slot of the desired token.
     * @dev The `Equipment` struct consists of the following data:
     *  [
     *      assetId,
     *      childAssetId,
     *      childId,
     *      childEquippableAddress
     *  ]
     * @param tokenId ID of the token for which we are retrieving the equipped object
     * @param targetCatalogAddress Address of the `Catalog` associated with the `Slot` part of the token
     * @param slotPartId ID of the `Slot` part that we are checking for equipped objects
     * @return The `Equipment` struct containing data about the equipped object
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) external view returns (Equipment memory);

    /**
     * @notice Used to get the asset and equippable data associated with given `assetId`.
     * @param tokenId ID of the token for which to retrieve the asset
     * @param assetId ID of the asset of which we are retrieving
     * @return metadataURI The metadata URI of the asset
     * @return equippableGroupId ID of the equippable group this asset belongs to
     * @return catalogAddress The address of the catalog the part belongs to
     * @return partIds An array of IDs of parts included in the asset
     */
    function getAssetAndEquippableData(
        uint256 tokenId,
        uint64 assetId
    )
        external
        view
        returns (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            uint64[] memory partIds
        );
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
/// Attempting to pass an epired ECDSA deadline
error RMRKExpiredDeadline();
/// Attempting to use ID 0, which is not supported
/// @dev The ID 0 in RMRK suite is reserved for empty values. Guarding against its use ensures the expected operation
error RMRKIdZeroForbidden();
/// Attempting to interact with an asset, using index greater than number of assets
error RMRKIndexOutOfRange();
/// Attempting to reclaim a child that can't be reclaimed
error RMRKInvalidChildReclaim();
/// Attempting to use and invalid ECDSA signature
error RMRKInvalidSignature();
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

import "../equippable/IERC6220.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKBulkWriter
 * @author RMRK team
 * @notice Smart contract of the RMRK Bulk Writer module.
 * @dev Extra utility functions for RMRK contracts.
 */
contract RMRKBulkWriter {
    /**
     * @notice Used to provide a struct for inputing unequip data.
     * @dev Only used for input and not storage of data.
     * @return assetId ID of the asset that we are equipping into
     * @return slotPartId ID of the slot part that we are using to unequip
     */
    struct IntakeUnequip {
        uint64 assetId;
        uint64 slotPartId;
    }

    /**
     * @notice Reverts if the caller is not the owner of the token.
     * @param collection Address of the collection that this contract is managing
     * @param tokenId ID of the token we are managing
     */
    modifier onlyTokenOwner(address collection, uint256 tokenId) {
        _checkTokenOwner(collection, tokenId);
        _;
    }

    /**
     * @notice Initializes the contract.
     */
    constructor() {}

    /**
     * @notice Replaces the current equipped child in the asset and slot combination with the given one.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param collection Address of the collection that this contract is managing
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function replaceEquip(
        address collection,
        IERC6220.IntakeEquip memory data
    ) public onlyTokenOwner(collection, data.tokenId) {
        IERC6220(collection).unequip(
            data.tokenId,
            data.assetId,
            data.slotPartId
        );
        IERC6220(collection).equip(data);
    }

    /**
     * @notice Performs multiple unequip and/or equip operations.
     * @dev Unequip operations must run first.
     * @dev Unequip operations do not need to be related to the equip operations; this method does not force you to only equip the assets into the slots that were unequipped.
     * @dev `tokenId` is included as a parameter to be able to do a single check for ownership.
     * @dev Every `tokenId` in the `IntakeEquip` structs must match the `tokenId` passed as the argument.
     * @dev The `IntakeUnequip` stuct contains the following data:
     *  [
     *      assetId,
     *      slotPartId,
     *  ]
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param collection Address of the collection that this contract is managing
     * @param tokenId ID of the token we are managing
     * @param unequips[] An array of `IntakeUnequip` structs specifying the slots to unequip
     * @param equips[] An array of `IntakeEquip` structs specifying the slots to equip
     */
    function bulkEquip(
        address collection,
        uint256 tokenId,
        IntakeUnequip[] memory unequips,
        IERC6220.IntakeEquip[] memory equips
    ) public onlyTokenOwner(collection, tokenId) {
        uint256 length = unequips.length;
        for (uint256 i; i < length; ) {
            IERC6220(collection).unequip(
                tokenId,
                unequips[i].assetId,
                unequips[i].slotPartId
            );
            unchecked {
                ++i;
            }
        }
        length = equips.length;
        for (uint256 i; i < length; ) {
            if (equips[i].tokenId != tokenId) {
                revert RMRKCanOnlyDoBulkOperationsWithOneTokenAtATime();
            }
            IERC6220(collection).equip(equips[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Validates that the caller is the owner of the token.
     * @dev Reverts if the caller is not the owner of the token.
     * @param collection Address of the collection that this contract is managing
     * @param tokenId ID of the token we are managing
     */
    function _checkTokenOwner(
        address collection,
        uint256 tokenId
    ) internal view {
        address tokenOwner = IERC721(collection).ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            revert RMRKCanOnlyDoBulkOperationsOnOwnedTokens();
        }
    }
}