// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
/// Attempting to compose an asset wihtout having an associated Catalog
error RMRKNotComposableAsset();
/// Attempting to unequip an item that isn't equipped
error RMRKNotEquipped();
/// Attempting to interact with a management function without being the smart contract's owner
error RMRKNotOwner();
/// Attempting to interact with a function without being the owner or contributor of the collection
error RMRKNotOwnerOrContributor();
/// Attempting to transfer the ownership to the 0x0 address
error RMRKNewOwnerIsZeroAddress();
/// Attempting to assign a 0x0 address as a contributor
error RMRKNewContributorIsZeroAddress();
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

//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.18;

/**
 * @title RMRK ERC721 Wrapper Deployer Interface
 * @notice This is interface is for an intermediary contract whose only purpose is to deploy Wrapped Collections.
 * @dev This contract does not have any validation, it is kept the minimal possible to avoid breaking the size limit.
 */
interface IRMRKERC721WrapperDeployer {
    /**
     * @notice Deploys a new Wrapped Collection.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param originalCollection The address of the original collection
     * @param maxSupply The maximum supply of the wrapped collection
     * @param royaltiesRecipient The address of the royalties recipient
     * @param royaltyPercentageBps The royalty percentage in basis points
     * @param collectionMetadataURI The metadata URI of the wrapped collection
     * @return wrappedCollection The address of the newly deployed wrapped collection
     */
    function wrapCollection(
        address originalCollection,
        uint256 maxSupply,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory collectionMetadataURI
    ) external returns (address wrappedCollection);
}

//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.18;

/**
 * @title RMRK Wrapped Equippable Interface
 * @notice This is the minimal interface that the Wrapper contract needs to be able to access on the Wrapped Collections.
 */
interface IRMRKWrappedEquippable {
    /**
     * @notice Sets the payment data for individual wrap payments.
     * @param erc20TokenAddress The address of the ERC20 token used for payment
     * @param individualWrappingPrice The price of wrapping an individual token
     * @param beneficiary The address of the beneficiary
     * @param prePaidTokenWraps Whether the collection owner prepaid for individual token wraps, in which case, nothing
     *  is charged.
     */
    function setPaymentData(
        address erc20TokenAddress,
        uint256 individualWrappingPrice,
        address beneficiary,
        bool prePaidTokenWraps
    ) external;
}

//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/access/Ownable.sol";
import "./IRMRKWrappedEquippable.sol";
import "./IRMRKERC721WrapperDeployer.sol";

error CollectionAlreadyWrapped();
error CollectionIsNotWrapped();
error NotEnoughAllowance();
error OnlyCollectionOwnerCanWrap();

/**
 * @title RMRK ERC721 Wrapper
 * @notice This contract is used to wrap ERC721 collections.
 * @dev Only the owner of the collection can wrap it.
 */
contract RMRKERC721Wrapper is Ownable {
    /**
     * @notice Emitted when a collection is wrapped.
     * @param originalCollection The address of the original collection
     * @param wrappedCollection The address of the newly deployed wrapped collection
     * @param prepaidForTokens Whether the collection owner prepaid for individual token wraps
     */
    event WrappedCollection(
        address indexed originalCollection,
        address indexed wrappedCollection,
        bool prepaidForTokens
    );

    mapping(address => address) private _originalToWrappedCollection;
    mapping(address => address) private _wrappedToOriginalCollection;
    IRMRKERC721WrapperDeployer private _deployer;
    address private _beneficiary;
    address private _erc20TokenAddress;
    uint256 private _collectionWrappingPrice;
    uint256 private _individualWrappingPrice;
    uint256 private _prepayDiscountBPS;

    /**
     * @notice Initializes the contract.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param erc20TokenAddress The address of the ERC20 token used for payment
     * @param collectionWrappingPrice The price of wrapping a collection
     * @param individualWrappingPrice The price of wrapping an individual token
     * @param prepayDiscountBPS The discount in basis points when prepaying for individual token wraps
     * @param beneficiary The address of the beneficiary
     * @param deployer The address of the deployer contract
     */
    constructor(
        address erc20TokenAddress,
        uint256 collectionWrappingPrice,
        uint256 individualWrappingPrice,
        uint256 prepayDiscountBPS,
        address beneficiary,
        address deployer
    ) {
        _erc20TokenAddress = erc20TokenAddress;
        _collectionWrappingPrice = collectionWrappingPrice;
        _individualWrappingPrice = individualWrappingPrice;
        _prepayDiscountBPS = prepayDiscountBPS;
        _beneficiary = beneficiary;
        _deployer = IRMRKERC721WrapperDeployer(deployer);
    }

    // -------------- GETTERS --------------

    /**
     * @notice Returns the address of the ERC20 token used for payment.
     * @return erc20TokenAddress The address of the ERC20 token used for payment
     */
    function getErc20TokenAddress() public view returns (address) {
        return _erc20TokenAddress;
    }

    /**
     * @notice Returns the price of wrapping a collection.
     * @return collectionWrappingPrice The price of wrapping a collection
     */
    function getcollectionWrappingPrice() public view returns (uint256) {
        return _collectionWrappingPrice;
    }

    /**
     * @notice Returns the price of wrapping an individual token.
     * @return individualWrappingPrice The price of wrapping an individual token
     */
    function getIndividualWrappingPrice() public view returns (uint256) {
        return _individualWrappingPrice;
    }

    /**
     * @notice Returns the discount in basis points when prepaying for individual token wraps.
     * @return prepayDiscountBPS The discount in basis points when prepaying for individual token wraps
     */
    function getPrepayDiscountBPS() public view returns (uint256) {
        return _prepayDiscountBPS;
    }

    /**
     * @notice Returns the address of the beneficiary.
     * @return beneficiary The address of the beneficiary
     */
    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @notice Returns the address of the deployer contract.
     * @return deployer The address of the deployer contract
     */
    function getDeployer() public view returns (address) {
        return address(_deployer);
    }

    /**
     * @notice Returns the address of the wrapped collection corresponding to an original collection.
     * @param originalCollection The address of the original collection
     * @return wrappedCollection The address of the wrapped collection
     */
    function getWrappedCollection(
        address originalCollection
    ) public view returns (address wrappedCollection) {
        return _originalToWrappedCollection[originalCollection];
    }

    /**
     * @notice Returns the address of the original collection corresponding to a wrapped collection.
     * @param wrappedCollection The address of the wrapped collection
     * @return originalCollection The address of the original collection
     */
    function getOriginalCollection(
        address wrappedCollection
    ) public view returns (address originalCollection) {
        return _wrappedToOriginalCollection[wrappedCollection];
    }

    // -------------- ADMIN SETTERS --------------

    /**
     * @notice Sets the address of the ERC20 token used for payment.
     * @param erc20TokenAddress The address of the ERC20 token used for payment
     */
    function setErc20TokenAddress(address erc20TokenAddress) public onlyOwner {
        _erc20TokenAddress = erc20TokenAddress;
    }

    /**
     * @notice Sets the price of wrapping a collection.
     * @param collectionWrappingPrice The price of wrapping a collection
     */
    function setCollectionWrappingPrice(
        uint256 collectionWrappingPrice
    ) public onlyOwner {
        _collectionWrappingPrice = collectionWrappingPrice;
    }

    /**
     * @notice Sets the price of wrapping an individual token.
     * @param individualWrappingPrice The price of wrapping an individual token
     */
    function setIndividualWrappingPrice(
        uint256 individualWrappingPrice
    ) public onlyOwner {
        _individualWrappingPrice = individualWrappingPrice;
    }

    /**
     * @notice Sets the discount in basis points when prepaying for individual token wraps.
     * @param prepayDiscountBPS The discount in basis points when prepaying for individual token wraps
     */
    function setPrepayDiscountBPS(uint256 prepayDiscountBPS) public onlyOwner {
        _prepayDiscountBPS = prepayDiscountBPS;
    }

    /**
     * @notice Sets the address of the beneficiary.
     * @param beneficiary The address of the beneficiary
     */
    function setBeneficiary(address beneficiary) public onlyOwner {
        _beneficiary = beneficiary;
    }

    /**
     * @notice Sets the address of the deployer contract.
     * @param deployer The address of the deployer contract
     */
    function setDeployer(address deployer) public onlyOwner {
        _deployer = IRMRKERC721WrapperDeployer(deployer);
    }

    // -------------- WRAPPING --------------

    /**
     * @notice Wraps a collection.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param originalCollection The address of the original collection
     * @param maxSupply The maximum supply of the wrapped collection
     * @param royaltiesRecipient The address of the royalties recipient
     * @param royaltyPercentageBps The royalty percentage in basis points
     * @param collectionMetadataURI The metadata URI of the wrapped collection
     * @param prePayTokenWraps Whether to prepay for individual token wraps
     */
    function wrapCollection(
        address originalCollection,
        uint256 maxSupply,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory collectionMetadataURI,
        bool prePayTokenWraps
    ) external {
        if (_originalToWrappedCollection[originalCollection] != address(0))
            revert CollectionAlreadyWrapped();

        address collectionOwner = Ownable(originalCollection).owner();
        if (collectionOwner != _msgSender())
            revert OnlyCollectionOwnerCanWrap();

        uint256 price = _collectionWrappingPrice;
        if (prePayTokenWraps) {
            price +=
                (_individualWrappingPrice * maxSupply * _prepayDiscountBPS) /
                10000;
        }
        _chargeWrappingFee(_msgSender(), price);

        address wrappedCollection = _deployer.wrapCollection(
            originalCollection,
            maxSupply,
            royaltiesRecipient,
            royaltyPercentageBps,
            collectionMetadataURI
        );
        IRMRKWrappedEquippable(wrappedCollection).setPaymentData(
            _erc20TokenAddress,
            _individualWrappingPrice,
            _beneficiary,
            prePayTokenWraps
        );

        _originalToWrappedCollection[originalCollection] = wrappedCollection;
        _wrappedToOriginalCollection[wrappedCollection] = originalCollection;

        emit WrappedCollection(
            originalCollection,
            wrappedCollection,
            prePayTokenWraps
        );
    }

    /**
     * @notice Charges the wrapping fee and sends it to the beneficiary.
     * @param chargeTo The address to charge the fee to
     * @param value The amount to charge
     */
    function _chargeWrappingFee(address chargeTo, uint256 value) private {
        if (
            IERC20(_erc20TokenAddress).allowance(chargeTo, address(this)) <
            value
        ) revert NotEnoughAllowance();
        IERC20(_erc20TokenAddress).transferFrom(chargeTo, _beneficiary, value);
    }
}