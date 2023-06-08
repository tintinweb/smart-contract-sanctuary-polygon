// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IMarketplaceNonCustodial
/// @author LYNC WORLD(https://lync.world)
/// @notice This is an Interface for the Non-Custodial Marketplace.
interface IMarketplaceNonCustodial {

    /// @notice NFTStandard is an enum that represents the NFT standard of the NFTs being listed.
    /// @notice E721 represents the ERC721 NFT standard.
    /// @notice E1155 represents the ERC1155 NFT standard.
    enum NFTStandard {
        E721,
        E1155
    }

    /// @notice Order is a struct that represents a listing of NFTs on the marketplace.
    /// @dev Order will be referred to as listing in some places. Both terms are used interchangeably.
    /// @param orderId is the unique identifier of the order.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being listed.
    /// @param tokenId is the ID of the NFT being listed.
    /// @param quantity is the quantity of NFTs being listed.
    /// @param pricePerItem is the price per NFT being listed.
    /// @param seller is the address of the seller.
    struct Order {
        uint256 orderId;
        address nftAddress;
        NFTStandard standard;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerItem;
        address payable seller;
    }
    
    /// @notice Buyer is a struct that represents a buyer of NFTs on the marketplace.
    /// @param buyer is the address of the buyer.
    /// @param quantityBought is the quantity of NFTs bought.
    /// @param buyPricePerItem is the price per NFT bought.
    struct Buyer {
        address buyer;
        uint256 quantityBought;
        uint256 buyPricePerItem;
    }

    /// @notice InvalidNFTStandard is an error that is thrown if the NFT standard is invalid.
    error InvalidNFTStandard(address nftAddress);

    /// @notice ItemsNotApprovedForListing is an error that is thrown if the NFTs are not approved for listing.
    error ItemsNotApprovedForListing();

    /// @notice InvalidOrderIdInput is an error that is thrown if the order ID input is invalid.
    error InvalidOrderIdInput(uint256 orderId);

    /// @notice OrderClosed is an error that is thrown if the order is closed.
    error OrderClosed(uint256 orderId);

    /// @notice InvalidCaller is an error that is thrown if the function caller is invalid.
    error InvalidCaller(address expected, address caller);

    /// @notice InactiveOrder is an error that is thrown if the order is inactive.
    error InactiveOrder(uint256 orderId);

    /// @notice NotEnoughItemsOwnedByCaller is an error that is thrown if the caller does not own enough NFTs.
    error NotEnoughItemsOwnedByCaller(address nftAddress, uint256 tokenId);

    /// @notice ZeroPricePerItemInput is an error that is thrown if the price per NFT input is provided as zero.
    error ZeroPricePerItemInput(uint256 input);

    /// @notice InvalidQuantityInput is an error that is thrown if the quantity input is invalid.
    error InvalidQuantityInput(uint256 input);

    /// @notice ItemAlreadyOwned is an error that is thrown if the caller already owns the NFT.
    error ItemAlreadyOwned(address nftAddress, uint256 tokenId);

    /// @notice ModifyListingFailed is an error that is thrown if the modify listing function fails due to invalid inputs.
    error ModifyListingFailed(uint256 newPriceInput, uint256 qtyToAdd);

    /// @notice ItemsListed is an event that is emitted when NFTs are listed on the marketplace.
    /// @param orderIdAssigned is the unique identifier of the order.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being listed.
    /// @param tokenId is the ID of the NFT being listed.
    /// @param quantity is the quantity of NFTs being listed.
    /// @param pricePerItem is the price per NFT being listed.
    /// @param seller is the address of the seller.
    event ItemsListed(
        uint256 indexed orderIdAssigned,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 pricePerItem,
        address seller
    );

    /// @notice ItemsBought is an event that is emitted when NFTs are bought on the marketplace.
    /// @param orderId is the unique identifier of the order/listing.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being bought.
    /// @param tokenId is the ID of the NFT being bought.
    /// @param buyQty is the quantity of NFTs being bought.
    /// @param soldFor is the total price of the NFTs bought.
    /// @param buyer is the address of the buyer.
    event ItemsBought(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 buyQty,
        uint256 soldFor,
        address buyer
    );

    /// @notice ItemsModified is an event that is emitted when a order/listing is modified.
    /// @param orderId is the unique identifier of the order/listing.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being modified.
    /// @param tokenId is the token ID of the NFT being modified.
    /// @param newPricePerItem is the new price per NFT.
    /// @param qtyToAdd is the quantity of NFTs being added to the listing.
    event ItemsModified(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 newPricePerItem,
        uint256 qtyToAdd
    );

    /// @notice ItemsCancel is an event that is emitted when a order/listing is cancelled.
    /// @param orderId is the unique identifier of the order/listing.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being cancelled.
    /// @param tokenId is the token ID of the NFT being cancelled.
    /// @param unlistedBy is the address of the seller.
    event ItemsCancel(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        address unlistedBy
    );

    /// @notice AdminFeesChanged is an event that is emitted when the admin fees percentage is changed.
    /// @param newPercentFees is the new admin fees percentage.
    event AdminFeesChanged(uint256 newPercentFees);

    /// @notice listItem is a function that lists NFTs on the marketplace.
    /// @notice The NFTs being listed must be approved for listing.
    /// @param _nftAddress is the address of the NFT contract.
    /// @param _standard is the NFT standard of the NFTs being listed.
    /// @param _tokenId is the ID of the NFT being listed.
    /// @param _quantity is the quantity of NFTs being listed.
    /// @param _pricePerItem is the price per NFT being listed.
    function listItem(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerItem
    ) external;

    /// @notice modifyListing is a function that modifies a listing on the marketplace.
    /// @notice This function can only be called by the seller.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @param _newPricePerItem is the new price per NFT. Pass in zero to not modify this.
    /// @param _qtyToAdd is the quantity of NFTs being added to the listing. Pass in zero to not modify this.
    function modifyListing(
        uint256 _orderId,
        uint256 _newPricePerItem,
        uint256 _qtyToAdd
    ) external;

    /// @notice cancelListing is a function that cancels a listing on the marketplace.
    /// @notice This function can only be called by the seller.
    /// @param _orderId is the unique identifier of the order/listing.
    function cancelListing(uint256 _orderId) external;

    /// @notice buyItem is a function that can be used to buy NFTs on the marketplace.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @param _qtyToBuy is the quantity of NFTs being bought.
    function buyItem(uint256 _orderId, uint256 _qtyToBuy) external payable;

    /// @notice isOrderActive is a function that returns whether an order is active or not.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @return bool output is whether the order is active or not.
    function isOrderActive(uint256 _orderId) external view returns (bool);

    /// @notice isERC721 is a function that returns whether an NFT is ERC721 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC721 or not.
    function isERC721(address nftAddress) external view returns (bool);

    /// @notice isERC1155 is a function that returns whether an NFT is ERC1155 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC1155 or not.
    function isERC1155(address nftAddress) external view returns (bool);

    /// @notice isOrderClosed is a function that returns whether an order is closed or not.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @return bool output is whether the order is closed or not.
    function isOrderClosed(uint256 _orderId) external view returns (bool);

    /// @notice setAdmin is a function that sets the admin of the marketplace.
    /// @notice This function can only be called by the current admin.
    /// @param _newAddress is the address of the new admin.
    function setAdmin(address _newAddress) external;

    /// @notice setFeesForAdmin is a function that sets the admin fees percentage.
    /// @notice This function can only be called by the current admin.
    /// @param _percentFees is the new admin fees percentage.
    function setFeesForAdmin(uint256 _percentFees) external;

    /// @notice withdrawFunds is a function that withdraws funds from the marketplace.
    /// @notice This function can only be called by the current admin.
    /// @param _to Address to withdraw funds to.
    function withdrawFunds(address _to) external;

}

// SPDX-License-Identifier: None
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IMarketplaceNonCustodial.sol";

/// @title MarketplaceNonCustodial
/// @author LYNC WORLD (https://lync.world)
/// @notice This contract is used for listing and buying NFTs on the LYNC WORLD marketplace.
/// @dev This uses an orderbook model for listing and buying NFTs and is non-custodial.
/// @dev Order is sometimes referred to as listing. Both are used interchangeably.
contract MarketplaceNonCustodial is ReentrancyGuard, IMarketplaceNonCustodial {

    using ERC165Checker for address;

    /// @dev ERC-721 interface id
    bytes4 private constant IID_IERC721 = type(IERC721).interfaceId;

    /// @dev ERC-1155 interface id
    bytes4 private constant IID_IERC1155 = type(IERC1155).interfaceId;

    /// @notice Address of the admin of the contract
    address payable public adminAddress;

    /// @notice Percentage of fees admin will take
    uint256 public percentFeesAdmin;

    /// @notice Order counter to keep track of the number of orders and to generate unique order ids
    uint256 public orderCtr;

    /// @notice listings mapping to keep track of all the listings/orders.
    /// @dev OrderId => Order struct
    /// @dev Order struct is defined in IMarketplaceNonCustodial interface
    mapping(uint256 => Order) public listings;

    /// @notice keeps track of all the buyers for a particular listing
    /// @dev order id => array of buyers
    /// @dev Buyer struct is defined in IMarketplaceNonCustodial interface
    mapping(uint256 => Buyer[]) public listingBuyers;

    /// @notice keeps track if a user has listed a particular NFT before
    /// @dev user address => nft address => token id => bool
    mapping(address => mapping(address => mapping(uint256 => bool)))
        public userListedNFTBefore;

    /// @notice Modifier to check if the caller is admin
    modifier onlyAdmin() {
        if (msg.sender != adminAddress) {
            revert InvalidCaller(adminAddress, msg.sender);
        }
        _;
    }

    /// @notice Constructor which sets the admin address, fees percentage and order counter
    constructor() {
        orderCtr = 0;
        percentFeesAdmin = 4;
        adminAddress = payable(msg.sender);
    }

    /// @notice Withdraws funds from the contract
    /// @dev Only admin can call this function
    /// @param _to Address to which the funds will be transferred
    function withdrawFunds(address _to) external onlyAdmin {
        (bool success, ) = payable(_to).call{
            value: (address(this).balance)
        }("");
        require(success, "Failed to withdraw funds!");
    }

    /// @notice Sets the admin address
    /// @dev Only admin can call this function
    /// @param _newAddress New admin address
    function setAdmin(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "Admin address can't be null!");
        adminAddress = payable(_newAddress);
    }

    /// @notice Sets the fees percentage for admin
    /// @dev Only admin can call this function
    /// @param _percentFees New fees percentage
    function setFeesForAdmin(uint256 _percentFees) external onlyAdmin {
        require(_percentFees < 100, "Fees cannot exceed 100%");
        percentFeesAdmin = _percentFees;
        emit AdminFeesChanged(_percentFees);
    }

    /// @notice Lists an NFT for sale
    /// @dev This function can be used to list both ERC-721 and ERC-1155 tokens
    /// @param _nftAddress Address of the NFT contract
    /// @param _standard NFT standard (ERC-721 or ERC-1155)
    /// @param _tokenId Token id of the NFT
    /// @param _quantity Quantity of the NFT to be listed
    /// @param _pricePerItem Price per NFT
    function listItem(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerItem
    ) external {
        uint256 ownerHas = 1;
        if (_standard == NFTStandard.E721) {
            if (!isERC721(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            if (_quantity != 1) {
                revert InvalidQuantityInput(_quantity);
            }
            IERC721 _nft = IERC721(_nftAddress);
            if (_nft.ownerOf(_tokenId) != msg.sender) {
                revert NotEnoughItemsOwnedByCaller(_nftAddress, _tokenId);
            }
            if (!_nft.isApprovedForAll(msg.sender, address(this))) {
                revert ItemsNotApprovedForListing();
            }
        } else {
            if (!isERC1155(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            IERC1155 _nft = IERC1155(_nftAddress);
            ownerHas = _nft.balanceOf(msg.sender, _tokenId);
            if (ownerHas < _quantity) {
                revert NotEnoughItemsOwnedByCaller(_nftAddress, _tokenId);
            }
            if (!_nft.isApprovedForAll(msg.sender, address(this))) {
                revert ItemsNotApprovedForListing();
            }
        }

        if (_pricePerItem == 0) {
            revert ZeroPricePerItemInput(_pricePerItem);
        }
        require(
            !userListedNFTBefore[msg.sender][_nftAddress][_tokenId],
            "NFT already listed Please modify"
        );
        _createNewOrder(
            _nftAddress,
            _standard,
            _tokenId,
            _quantity,
            _pricePerItem,
            payable(msg.sender)
        );
    }

    /// @notice Modifies an existing listing
    /// @notice If you don't want to change the price per NFT, pass 0 as _newPricePerItem
    /// @notice If you don't want to add more NFTs to the listing, pass 0 as _qtyToAdd
    /// @notice This function can only be called by the seller
    /// @dev Order should be active and not closed
    /// @param _orderId Order id of the listing
    /// @param _newPricePerItem New price per NFT
    /// @param _qtyToAdd Quantity of NFTs to be added to the listing
    function modifyListing(
        uint256 _orderId,
        uint256 _newPricePerItem, 
        uint256 _qtyToAdd
    ) external {
        if (_orderId > orderCtr) {
            revert InvalidOrderIdInput(_orderId);
        }
        if (isOrderClosed(_orderId)) {
            revert OrderClosed(_orderId);
        }
        Order memory _order = listings[_orderId];
        if (_order.seller != msg.sender) {
            revert InvalidCaller(_order.seller, msg.sender);
        }
        if (!isOrderActive(_orderId)) {
            revert InactiveOrder(_orderId);
        }
        uint256 ownerHas = 1;
        if (_order.standard == NFTStandard.E1155) {
            IERC1155 _nft = IERC1155(_order.nftAddress);
            ownerHas = _nft.balanceOf(msg.sender, _order.tokenId);
        }
        if (_newPricePerItem == 0) {
            if (_qtyToAdd != 0) {
                require(
                    _order.quantity + _qtyToAdd <= ownerHas,
                    "Not enough tokens in wallet!"
                );
                listings[_orderId].quantity += _qtyToAdd;
            } else {
                revert ModifyListingFailed(_newPricePerItem, _qtyToAdd);
            }
        } else {
            if (_qtyToAdd != 0) {
                require(
                    _order.quantity + _qtyToAdd <= ownerHas,
                    "Not enough tokens in wallet!"
                );
                listings[_orderId].quantity += _qtyToAdd;
            }
            _updateOrderPrice(_orderId, _newPricePerItem);
        }
        emit ItemsModified(
            _orderId,
            _order.nftAddress,
            _order.standard,
            _order.tokenId,
            _newPricePerItem,
            _qtyToAdd
        );
    }

    /// @notice Cancels an existing listing
    /// @notice This function can only be called by the seller
    /// @dev Order should not be closed
    /// @dev Cancelling a listing will remove all the listed NFTs from the listing
    /// @param _orderId Order id of the listing
    function cancelListing(uint256 _orderId) external {
        if (_orderId > orderCtr) {
            revert InvalidOrderIdInput(_orderId);
        }
        if (isOrderClosed(_orderId)) {
            revert OrderClosed(_orderId);
        }
        Order memory _order = listings[_orderId];
        if (_order.seller != msg.sender) {
            revert InvalidCaller(_order.seller, msg.sender);
        }
        userListedNFTBefore[msg.sender][_order.nftAddress][
            _order.tokenId
        ] = false;
        listings[_orderId].quantity = 0;
        emit ItemsCancel(
            _orderId,
            _order.nftAddress,
            _order.standard,
            _order.tokenId,
            msg.sender
        );
    }

    /// @notice Function to buy NFT(s) from a listing
    /// @notice This function can be called by anyone
    /// @dev Order should be active and not closed
    /// @dev Buyer should have enough ETH to buy the NFT(s)
    /// @dev Buyer should not be the seller
    /// @param _orderId Order id of the listing
    /// @param _qtyToBuy Quantity of NFTs to buy
    function buyItem(uint256 _orderId, uint256 _qtyToBuy)
        external
        payable
        nonReentrant
    {
        if (_orderId > orderCtr) {
            revert InvalidOrderIdInput(_orderId);
        }
        if (isOrderClosed(_orderId)) {
            revert OrderClosed(_orderId);
        }
        if (!isOrderActive(_orderId)) {
            revert InactiveOrder(_orderId);
        }
        Order memory _order = listings[_orderId];
        if (_order.seller == msg.sender) {
            revert ItemAlreadyOwned(_order.nftAddress, _order.tokenId);
        }
        if (_qtyToBuy == 0 || _qtyToBuy > _order.quantity) {
            revert InvalidQuantityInput(_qtyToBuy);
        }
        require(
            msg.value == _order.pricePerItem * _qtyToBuy,
            "Price not met!"
        );

        uint256 _newQty = _order.quantity - _qtyToBuy;
        _addBuyerToOrder(_orderId, msg.sender, _qtyToBuy, _order.pricePerItem);
        listings[_orderId].quantity = _newQty;
        if (_order.standard == NFTStandard.E721) {
            IERC721 _nft = IERC721(_order.nftAddress);
            _nft.safeTransferFrom(_order.seller, msg.sender, _order.tokenId);
            userListedNFTBefore[_order.seller][_order.nftAddress][
                _order.tokenId
            ] = false;
        } else {
            IERC1155 _nft = IERC1155(_order.nftAddress);
            _nft.safeTransferFrom(
                _order.seller,
                msg.sender,
                _order.tokenId,
                _qtyToBuy,
                ""
            );
            if (_newQty == 0) {
                userListedNFTBefore[_order.seller][_order.nftAddress][
                    _order.tokenId
                ] = false;
            }
        }
        _splitFunds(msg.value, _order.seller);
        emit ItemsBought(
            _orderId,
            _order.nftAddress,
            _order.standard,
            _order.tokenId,
            _qtyToBuy,
            msg.value,
            msg.sender
        );
    }

    /// @notice Function to check if an order is active
    /// @dev Order should not be closed
    /// @dev Order should be owned by the seller
    /// @dev Marketplace should be approved by the seller
    /// @param _orderId Order id of the listing
    /// @return bool Returns true if the order is active
    function isOrderActive(uint256 _orderId) public view returns (bool) {
        if (_orderId > orderCtr) {
            return false;
        }
        if (isOrderClosed(_orderId)) {
            return false;
        }
        Order memory _order = listings[_orderId];
        if (_order.standard == NFTStandard.E721) {
            IERC721 _nft = IERC721(_order.nftAddress);
            try _nft.ownerOf(_order.tokenId) returns (address owner) {
                if (owner != _order.seller) {
                    return false;
                } else {
                    if (_nft.isApprovedForAll(_order.seller, address(this))) {
                        return true;
                    }
                }
            } catch {
                return false;
            }
        } else {
            IERC1155 _nft = IERC1155(_order.nftAddress);
            if (
                (_nft.balanceOf(_order.seller, _order.tokenId) >=
                    _order.quantity) &&
                (_nft.isApprovedForAll(_order.seller, address(this)))
            ) {
                return true;
            } else {
                return false;
            }
        }
    }

    /// @notice Function to check if an NFT is ERC721 or not
    /// @dev Uses ERC165 to check if the NFT is ERC721 or not
    /// @param nftAddress Address of the NFT
    /// @return bool Returns true if the NFT is ERC721 else returns false
    function isERC721(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }

    /// @notice Function to check if an NFT is ERC1155 or not
    /// @dev Uses ERC165 to check if the NFT is ERC1155 or not
    /// @param nftAddress Address of the NFT
    /// @return bool Returns true if the NFT is ERC1155 else returns false
    function isERC1155(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }

    /// @notice Function to check if an order is closed or not
    /// @dev Order is closed if the listing quantity is 0 after a buy
    /// @param _orderId Order id of the listing
    /// @return bool Returns true if the order is closed else returns false
    function isOrderClosed(uint256 _orderId) public view returns (bool) {
        return (listings[_orderId].quantity == 0);
    }
    
    /// @notice Internal function to create a new order
    /// @dev Order id is incremented by 1
    /// @dev Order is added to the listings mapping
    /// @param _nftAddress Address of the NFT
    /// @param _standard Standard of the NFT
    /// @param _tokenId Token id of the NFT
    /// @param _qty Quantity of the NFT
    /// @param _pricePerItem Price per item of the NFT
    /// @param _seller Address of the seller
    function _createNewOrder(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _qty,
        uint256 _pricePerItem,
        address payable _seller
    ) internal {
        orderCtr++;
        listings[orderCtr].orderId = orderCtr;
        listings[orderCtr].nftAddress = _nftAddress;
        listings[orderCtr].standard = _standard;
        listings[orderCtr].tokenId = _tokenId;
        listings[orderCtr].quantity = _qty;
        listings[orderCtr].pricePerItem = _pricePerItem;
        listings[orderCtr].seller = _seller;
        userListedNFTBefore[_seller][_nftAddress][_tokenId] = true;
        emit ItemsListed(
            orderCtr,
            _nftAddress,
            _standard,
            _tokenId,
            _qty,
            _pricePerItem,
            _seller
        );
    }

    /// @notice Internal function to update the price of an order
    /// @param _orderId Order id of the listing
    /// @param _newPricePerItem New price per item of the NFT
    function _updateOrderPrice(uint256 _orderId, uint256 _newPricePerItem)
        internal
    {
        listings[_orderId].pricePerItem = _newPricePerItem;
    }

    /// @notice Internal function to split the funds between the seller and the admin
    /// @param _totalValue Total value of the order
    /// @param _seller Address of the seller
    function _splitFunds(uint256 _totalValue, address payable _seller)
        internal
    {
        uint256 valueToSeller = (_totalValue * (100 - percentFeesAdmin)) / 100;
        payable(_seller).transfer(valueToSeller);
    }

    /// @notice Internal function to add a buyer to the listingBuyers mapping for an order
    /// @param _orderId Order id of the listing
    /// @param _buyer Address of the buyer
    /// @param _qtyBought Quantity bought by the buyer
    /// @param _buyPrice Price at which the buyer bought the NFT
    function _addBuyerToOrder(
        uint256 _orderId,
        address _buyer,
        uint256 _qtyBought,
        uint256 _buyPrice
    ) internal {
        listingBuyers[_orderId].push(Buyer(_buyer, _qtyBought, _buyPrice));
    }

    /// @notice React to receiving ether
    receive() external payable {}
}