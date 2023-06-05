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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

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
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
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

/// @title IRentLendMarketplace
/// @author LYNC WORLD (https://lync.world)
/// @notice This is the interface for the RentLendMarketplace contract
interface IRentLendMarketplace {

    /// @notice NFTStandard is an enum that represents the NFT standard of the NFTs being listed.
    /// @notice E721 represents the ERC721 NFT standard.
    /// @notice E1155 represents the ERC1155 NFT standard.
    enum NFTStandard {
        E721,
        E1155
    }

    /// @notice LendStatus is an enum that represents the status of the lending order.
    /// @notice LISTED represents the lending order is listed.
    /// @notice DELISTED represents the lending order is delisted.
    enum LendStatus {
        LISTED,
        DELISTED
    }

    /// @notice RentStatus is an enum that represents the status of the renting order.
    /// @notice RENTED represents the renting order is rented.
    /// @notice RETURNED represents the renting order is returned.
    enum RentStatus {
        RENTED,
        RETURNED
    } 

    /// @notice Lending is a struct that represents the lending order.
    /// @param lendingId is the unique id of the lending order.
    /// @param nftStandard is the NFT standard of the NFTs being listed.
    /// @param nftAddress is the address of the NFT contract.
    /// @param tokenId is the id of the NFT.
    /// @param lenderAddress is the address of the lender.
    /// @param tokenQuantity is the quantity of the NFTs being listed.
    /// @param pricePerDay is the price per day of the NFTs being listed.
    /// @param maxRentDuration is the maximum rent duration of the NFTs being listed.
    /// @param tokenQuantityAlreadyRented is the quantity of the NFTs already rented.
    /// @param renterKeyArray is the array of the renter keys.
    /// @param lendStatus is the status of the lending order.
    /// @param chain is the chain of the NFTs being listed.
    struct Lending {
        uint256 lendingId;
        NFTStandard nftStandard;
        address nftAddress;
        uint256 tokenId;
        address payable lenderAddress;
        uint256 tokenQuantity;
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenQuantityAlreadyRented;
        uint256[] renterKeyArray;
        LendStatus lendStatus;
        string chain;
    }

    /// @notice Renting is a struct that represents the renting order.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the id of the lending order.
    /// @param renterAddress is the address of the renter.
    /// @param tokenQuantityRented is the quantity of the NFTs rented.
    /// @param startTimeStamp is the start timestamp of the renting order.
    /// @param rentedDuration is the rented duration of the renting order.
    /// @param rentedPricePerDay is the rented price per day of the renting order.
    /// @param refundRequired is the boolean value that represents if a refund is required during the settlement or not.
    /// @dev Refund might be required if the lender does not hold its part of the deal throughout the renting period.
    /// @param refundEndTimeStamp is the timestamp upto which the order was valid. Ideally, it should be zero.
    /// @param rentStatus is the status of the renting order.
    struct Renting {
        uint256 rentingId;
        uint256 lendingId;
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 startTimeStamp;
        uint256 rentedDuration;
        uint256 rentedPricePerDay;
        bool refundRequired;
        uint256 refundEndTimeStamp;
        RentStatus rentStatus;
    }

    /// @notice PriceNotMet is an error that is emitted when the price is not met.
    error PriceNotMet(uint256 lendingId, uint256 price);

    /// @notice PriceMustBeAboveZero is an error that is emitted when the price is provided as zero in some function.
    error PriceMustBeAboveZero();

    /// @notice RentDurationNotAcceptable is an error that is emitted when the rent duration is not acceptable.
    error RentDurationNotAcceptable(uint256 maxRentDuration);

    /// @notice InvalidOrderIdInput is an error that is emitted when the order id of lending or renting order is invalid.
    error InvalidOrderIdInput(uint256 orderId);

    /// @notice InvalidCaller is an error that is emitted when the caller of the function is invalid.
    error InvalidCaller(address expectedAddress, address callerAddress);

    /// @notice InvalidNFTStandard is an error that is emitted when the NFT standard is invalid.
    error InvalidNFTStandard(address nftAddress);

    /// @notice InvalidInputs is an error that is emitted when the inputs are invalid.
    error InvalidInputs(
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    );

    /// @notice Lent is an event that is emitted when a lending order is listed.
    /// @param lendingId is the unique id of the lending order.
    /// @param nftStandard is the NFT standard of the NFTs being listed.
    /// @param nftAddress is the address of the NFT contract.
    /// @param tokenId is the token id of the NFT.
    /// @param lenderAddress is the address of the lender.
    /// @param tokenQuantity is the quantity of the NFTs being listed.
    /// @param pricePerDay is the price per day of the NFTs being listed.
    /// @param maxRentDuration is the maximum rent duration of the NFTs being listed.
    /// @param lendStatus is the status of the lending order.
    event Lent(
        uint256 indexed lendingId,
        NFTStandard nftStandard,
        address nftAddress,
        uint256 tokenId,
        address indexed lenderAddress,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration,
        LendStatus lendStatus
    );

    /// @notice LendingUpdated is an event that is emitted when a lending order is updated.
    /// @param lendingId is the unique id of the lending order.
    /// @param tokenQuantity is the quantity of the NFTs being listed.
    /// @param pricePerDay is the price per day of the NFTs being listed.
    /// @param maxRentDuration is the maximum rent duration of the NFTs being listed.
    event LendingUpdated(
        uint256 indexed lendingId,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    /// @notice Rented is an event that is emitted when a renting order is created.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the id of the lending order.
    /// @param renterAddress is the address of the renter.
    /// @param tokenQuantityRented is the quantity of the NFTs rented.
    /// @param rentedDuration is the rented duration of the renting order.
    /// @param rentStatus is the status of the renting order.
    event Rented(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityRented,
        uint256 rentedDuration,
        RentStatus rentStatus
    );

    /// @notice Returned is an event that is emitted when a renting order is returned.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the lending id of the associated lending order.
    /// @param renterAddress is the address of the renter.
    /// @param tokenQuantityReturned is the quantity of the NFTs returned.
    /// @param rentStatus is the status of the renting order.
    event Returned(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityReturned,
        RentStatus rentStatus
    );

    /// @notice Refunded is an event that is emitted when a renting order is refunded due to the 
    /// lender not holding its end of the deal throughout the renting period.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the lending id of the associated lending order.
    /// @param renterAddress is the address of the renter.
    /// @param refundAmount is the amount of refund.
    /// @param refundTokenQuantity is the quantity of the NFTs refunded.
    /// @param rentStatus is the status of the renting order.
    event Refunded(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 refundAmount,
        uint256 refundTokenQuantity,
        RentStatus rentStatus
    );

    /// @notice DeListed is an event that is emitted when a lending order is de-listed.
    /// @param lendingId is the unique id of the lending order.
    /// @param lendStatus is the status of the lending order.
    event DeListed(uint256 indexed lendingId, LendStatus lendStatus);

    /// @notice lend is a function that is used to list a lending order.
    /// @notice The caller of this function must be the owner of the NFTs being lent.
    /// @param _nftStandard is the NFT standard of the NFTs being lent.
    /// @param _nftAddress is the address of the NFT contract.
    /// @param _tokenId is the token id of the NFT.
    /// @param _tokenQuantity is the quantity of the NFTs being lent.
    /// @param _price is the price per day of the NFTs being lent.
    /// @param _maxRentDuration is the maximum rent duration of the NFTs being lent.
    function lend(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external;

    /// @notice modifyLending is a function that is used to modify a lending order.
    /// @notice The caller of this function must be the lister of the lending order.
    /// @param _lendingId is the unique id of the lending order.
    /// @param _tokenQtyToAdd is the quantity of the NFTs being added. Pass in zero to not modify this.
    /// @param _newPrice is the new price per day of the NFTs being listed. Pass in zero to not modify this.
    /// @param _newMaxRentDuration is the new maximum rent duration of the NFTs being listed. Pass in zero to not modify this.
    function modifyLending(
        uint256 _lendingId,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external;
    
    /// @notice cancelLending is a function that is used to cancel a lending order.
    /// @notice The caller of this function must be the lister of the lending order.
    /// @param _lendingId is the unique id of the lending order.
    function cancelLending(uint256 _lendingId) external; 

    /// @notice rent is a function that is used to rent a lending order.
    /// @notice Anyone can call this function.
    /// @notice The caller of this function must send in the exact amount of ETH required to rent the NFTs.
    /// @param _lendingId is the unique id of the lending order.
    /// @param _tokenQuantity is the quantity of the NFTs being rented.
    /// @param _duration is the duration of the renting order.
    function rent(
        uint256 _lendingId,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable;

    /// @notice calculateCost is a function that is used to calculate the cost of renting NFTs.
    /// @param _pricePerDay is the price per day of the NFTs being rented.
    /// @param _duration is the duration for which the NFTs are being rented.
    /// @param qty is the quantity of the NFTs being rented.
    /// @return cost is the total cost for renting the NFTs.
    function calculateCost(
        uint256 _pricePerDay,
        uint256 _duration,
        uint256 qty
    ) external pure returns (uint256 cost);

    /// @notice returnRented is a function that is used to return a renting order.
    /// @notice The caller of this function must be the renter of the renting order.
    /// @param _rentingID is the unique id of the renting order.
    /// @param _tokenQuantity is the quantity of the NFTs being returned.
    function returnRented(uint256 _rentingID, uint256 _tokenQuantity) external;

    /// @notice getLendingData is a function that is used to get the data of a lending order.
    /// @param _lendingId is the unique id of the lending order.
    /// @return All the data of the lending order.
    function getLendingData(
        uint256 _lendingId
    ) external view returns (Lending memory);

    /// @notice setAdmin is a function that is used to set the admin address.
    /// @notice The caller of this function must be the current admin.
    /// @param _newAddress is the address of the new admin.
    function setAdmin(address _newAddress) external;

    /// @notice setFeesForAdmin is a function that is used to set the fees percentage for the admin.
    /// @notice The caller of this function must be the current admin.
    /// @param _percentFees is the new fees percentage for the admin.
    function setFeesForAdmin(uint256 _percentFees) external;

    /// @notice setMinRentDueSeconds is a function that is used to set the minimum rent duration.
    /// @notice The caller of this function must be the current admin.
    /// @param _minDuration is the new minimum rent duration.
    function setMinRentDueSeconds(uint256 _minDuration) external;

    /// @notice withdrawableAmount is a function that is used to get the amount of ETH that can be withdrawn by the admin.
    /// @return The amount of ETH that can be withdrawn by the admin.
    function withdrawableAmount() external view returns (uint256);

    /// @notice withdrawFunds is a function that is used to withdraw the fees earned by the admin.
    /// @notice The caller of this function must be the current admin.
    function withdrawFunds() external;

    /// @notice setAutomationAddress is a function that is used to set the address of the chainlink automation contract.
    /// @notice The caller of this function must be the current admin.
    /// @param _automation is the address of the chainlink automation contract.
    function setAutomationAddress(address _automation) external;

    /// @notice isERC721 is a function that returns whether an NFT is ERC721 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC721 or not.
    function isERC721(address nftAddress) external view returns (bool);

    /// @notice isERC1155 is a function that returns whether an NFT is ERC1155 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC1155 or not.
    function isERC1155(address nftAddress) external view returns (bool);

    /// @notice automationAddress is a function that is used to get the address of the chainlink automation contract.
    function automationAddress() external view returns (address);

    /// @notice checkReturnRefundAutomation is a function that is used to check, return and refund NFTs.
    /// @notice This function is called by the chainlink automation contract.
    function checkReturnRefundAutomation() external;

    /// @notice getExpiredRentings is a function that is used to get the expired renting orders.
    /// @return The ids of the expired renting orders and the number of expired renting orders.
    /// @dev This function will be used by the chainlink automation contract.
    function getExpiredRentings() external view returns (uint256[] memory, uint256);

    /// @notice getRefundRentings is a function that is used to get the refund required renting orders.
    /// @return The ids of the refund required renting orders and the number of refund required renting orders.
    /// @dev This function will be used by the chainlink automation contract.
    function getRefundRentings() external view returns (uint256[] memory, uint256);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IRentLendMarketplace.sol";

/// @title RentLendMarketplace Contract
/// @author LYNC WORLD (https://lync.world)
/// @notice This contract is used for lending and renting NFTs.
/// @dev This contract uses orderbook model for lending and renting.
/// @dev This contract is used with chainlink automation contract to automate some of the processes.
contract RentLendMarketplace is ReentrancyGuard, IRentLendMarketplace {

    using ERC165Checker for address;
   
    /// @dev ERC-721 interface id
    bytes4 private constant IID_IERC721 = type(IERC721).interfaceId;

    /// @dev ERC-1155 interface id
    bytes4 private constant IID_IERC1155 = type(IERC1155).interfaceId;
    
    /// @notice Address of the admin of the contract
    address payable public adminAddress;

    /// @notice Lending order counter to keep track of the number of orders and to generate unique order ids
    uint256 public lendingCtr;

    /// @notice Renting order counter to keep track of the number of orders and to generate unique order ids
    uint256 public rentingCtr;

    /// @notice Percent fees that will be charged from the renter
    uint256 public percentFeesAdmin;

    /// @notice Minimum rent duration in seconds
    uint256 public minRentDueSeconds;

    /// @notice Address of the chainlink automation contract
    address public automationAddress;
    
    /// @notice withdrawableAmount is the amount that can be withdrawn by the admin
    uint256 public withdrawableAmount;

    /// @notice Keeps a check whether user has listed a particular NFT previously or not
    /// @dev NFT Address => Token Id => user address = bool
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public userListedNFTBefore;

    /// @notice Array of active lending order ids
    uint256[] public activeLendingsKeys;

    /// @notice Mapping of lending order ids to lending orders
    /// @dev Lending struct is defined in IRentLendMarketplace
    mapping(uint256 => Lending) public lendings;

    /// @notice Array of active renting order ids
    uint256[] public activeRentingsKeys;

    /// @notice Mapping of renting order ids to renting orders
    /// @dev Renting struct is defined in IRentLendMarketplace
    mapping(uint256 => Renting) public rentings;

    /// @notice Modifier to check if the caller is admin
    modifier onlyAdmin() {
        if (msg.sender != adminAddress) {
            revert InvalidCaller(adminAddress, msg.sender);
        }
        _;
    }

    /// @notice Constructor which sets the admin address, minRentDuration, fees percent and order counters
    constructor() {
        lendingCtr = 0;
        rentingCtr = 0;
        percentFeesAdmin = 4;
        minRentDueSeconds = 86400;
        adminAddress = payable(msg.sender);
    }

    /// @notice lend is a function that is used to list a lending order.
    /// @notice The caller of this function must be the owner of the NFTs being lent.
    /// @param _nftStandard is the NFT standard of the NFTs being lent.
    /// @param _nftAddress is the address of the NFT contract.
    /// @param _tokenId is the token id of the NFT.
    /// @param _tokenQuantity is the quantity of the NFTs being lent.
    /// @param _price is the price per day of the NFTs being lent.
    /// @param _maxRentDuration is the maximum rent duration of the NFTs being lent.
    function lend(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external {
        bool listed = userListedNFTBefore[_nftAddress][_tokenId][
            msg.sender
        ];

        require(
            !listed,
            "NFT already lent Please modify"
        );

        if (_nftStandard == NFTStandard.E721) {
            if (!isERC721(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }
            require(
                _tokenQuantity == 1,
                "Token qty can't be more than 1"
            );

            address ownerOf = IERC721(_nftAddress).ownerOf(_tokenId);
            require(ownerOf == msg.sender, "You do not own the NFT");
        } else if (_nftStandard == NFTStandard.E1155) {
            if (!isERC1155(_nftAddress)) {
                revert InvalidNFTStandard(_nftAddress);
            }

            uint256 ownerAmount = IERC1155(_nftAddress).balanceOf(
                msg.sender,
                _tokenId
            );
            require(
                ownerAmount >= _tokenQuantity,
                "Not enough NFTs or already lent"
            );
        }

        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (_maxRentDuration < minRentDueSeconds) {
            revert RentDurationNotAcceptable(_maxRentDuration);
        }
        _createNewOrder(
            _nftStandard,
            _nftAddress,
            _tokenId,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            msg.sender
        );
        emit Lent(
            lendingCtr,
            _nftStandard,
            _nftAddress,
            _tokenId,
            msg.sender,
            _tokenQuantity,
            _price,
            _maxRentDuration,
            LendStatus.LISTED
        );
    }

    /// @notice _createNewOrder is an internal function that is used to create a new lending order.
    /// @param _nftStandard is the NFT standard of the NFTs being lent.
    /// @param _nftAddress is the address of the NFT contract.
    /// @param _tokenId is the token id of the NFT.
    /// @param _tokenQuantity is the quantity of the NFTs being lent.
    /// @param _price is the price per day of the NFTs being lent.
    /// @param _maxRentDuration is the maximum rent duration of the NFTs being lent.
    /// @param _lenderAddress is the address of the lender.
    function _createNewOrder(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration,
        address _lenderAddress
    ) internal {
        lendingCtr++;

        Lending memory lendingCache;
        lendingCache.lendingId = lendingCtr;
        lendingCache.nftStandard = _nftStandard;
        lendingCache.nftAddress = _nftAddress;
        lendingCache.tokenId = _tokenId;
        lendingCache.lenderAddress = payable(_lenderAddress);
        lendingCache.tokenQuantity = _tokenQuantity;
        lendingCache.pricePerDay = _price;
        lendingCache.maxRentDuration = _maxRentDuration;
        lendingCache.tokenQuantityAlreadyRented = 0;
        lendingCache.lendStatus = LendStatus.LISTED;
        lendings[lendingCtr] = lendingCache;

        activeLendingsKeys.push(lendingCtr);
        userListedNFTBefore[_nftAddress][_tokenId][
            _lenderAddress
        ] = true;
    }

    /// @notice modifyLending is a function that is used to modify a lending order.
    /// @notice The caller of this function must be the lister of the lending order.
    /// @param _lendingId is the unique id of the lending order.
    /// @param _tokenQtyToAdd is the quantity of the NFTs being added. Pass in zero to not modify this.
    /// @param _newPrice is the new price per day of the NFTs being listed. Pass in zero to not modify this.
    /// @param _newMaxRentDuration is the new maximum rent duration of the NFTs being listed. Pass in zero to not modify this.
    function modifyLending(
        uint256 _lendingId,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.lenderAddress != msg.sender) {
            revert InvalidCaller(lendingStorage.lenderAddress, msg.sender);
        }
        uint256 ownerHas = 1;
        if (lendingStorage.nftStandard == NFTStandard.E1155) {
            IERC1155 nft = IERC1155(lendingStorage.nftAddress);
            ownerHas = nft.balanceOf(msg.sender, lendingStorage.tokenId);
        } 
        require(
            lendingStorage.lendStatus == LendStatus.LISTED,
            "Item delisted!"
        );
        if (_tokenQtyToAdd > 0) {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "maxRent input < minRentDuration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
                lendingStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "maxRent input < minRentDuration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
            }
            require(
                ownerHas >=
                    lendingStorage.tokenQuantityAlreadyRented +
                        lendingStorage.tokenQuantity +
                        _tokenQtyToAdd,
                "Not enough tokens in wallet!"
            );
            lendingStorage.tokenQuantity += _tokenQtyToAdd;
        } else {
            if (_newPrice > 0) {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "maxRent input < minRentDuration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                }
                lendingStorage.pricePerDay = _newPrice;
            } else {
                if (_newMaxRentDuration > 0) {
                    require(
                        _newMaxRentDuration >= minRentDueSeconds,
                        "maxRent input < minRentDuration"
                    );
                    lendingStorage.maxRentDuration = _newMaxRentDuration;
                } else {
                    revert InvalidInputs(
                        _tokenQtyToAdd,
                        _newPrice,
                        _newMaxRentDuration
                    );
                }
            }
        }

        emit LendingUpdated(
            _lendingId,
            lendingStorage.tokenQuantity,
            lendingStorage.pricePerDay,
            lendingStorage.maxRentDuration
        );
    }

    /// @notice cancelLending is a function that is used to cancel a lending order.
    /// @notice The caller of this function must be the lister of the lending order.
    /// @dev Order items must not be rented out to cancel the order.
    /// @param _lendingId is the unique id of the lending order.
    function cancelLending(uint256 _lendingId) external {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];
        if (lendingStorage.lenderAddress != msg.sender) {
            revert InvalidCaller(lendingStorage.lenderAddress, msg.sender);
        }

        require(
            lendingStorage.lendStatus == LendStatus.LISTED,
            "Lending order already delisted!"
        );

        require(
            lendingStorage.tokenQuantityAlreadyRented == 0,
            "Can't cancel! Items being rented"
        );

        lendingStorage.tokenQuantity = 0;

        lendingStorage.lendStatus = LendStatus.DELISTED;
        _removeEntryFromArray(activeLendingsKeys, _lendingId);

        userListedNFTBefore[lendingStorage.nftAddress][
            lendingStorage.tokenId
        ][msg.sender] = false;

        emit DeListed(_lendingId, lendingStorage.lendStatus);
    }

    /// @notice rent is a function that is used to rent a lending order.
    /// @notice Anyone can call this function.
    /// @notice The caller of this function must send in the exact amount of ETH required to rent the NFTs.
    /// @param _lendingId is the unique id of the lending order.
    /// @param _tokenQuantity is the quantity of the NFTs being rented.
    /// @param _duration is the duration of the renting order.
    function rent(
        uint256 _lendingId,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable {
        if (_lendingId > lendingCtr) {
            revert InvalidOrderIdInput(_lendingId);
        }
        Lending storage lendingStorage = lendings[_lendingId];

        require(
            msg.sender != lendingStorage.lenderAddress,
            "Owned NFTs cannot be rented"
        );

        require(
            lendingStorage.lendStatus != LendStatus.DELISTED,
            "This order is delisted"
        );
        require(
            lendingStorage.tokenQuantity >= _tokenQuantity,
            "Not enough tokens available!"
        );

        if (_duration > lendingStorage.maxRentDuration) {
            revert RentDurationNotAcceptable(_duration);
        }
        uint256 cost = calculateCost(
            lendingStorage.pricePerDay,
            _duration,
            _tokenQuantity
        );
        if (msg.value != cost) {
            revert PriceNotMet(_lendingId, cost);
        }

        _updateRenting(lendingStorage, _tokenQuantity, _duration);

        emit Rented(
            rentingCtr,
            _lendingId,
            msg.sender,
            _tokenQuantity,
            _duration,
            RentStatus.RENTED
        );
    }

    /// @notice calculateCost is a function that is used to calculate the cost of renting NFTs.
    /// @dev This function should be called before renting NFTs to get the exact cost.
    /// @param _pricePerDay is the price per day of the NFTs being rented.
    /// @param _duration is the duration for which the NFTs are being rented.
    /// @param _qty is the quantity of the NFTs being rented.
    /// @return cost is the total cost for renting the NFTs.
    function calculateCost(
        uint256 _pricePerDay,
        uint256 _duration,
        uint256 _qty
    ) public pure returns (uint256 cost) {
        cost = ((_pricePerDay * _duration * _qty) / 86400);
    }

    /// @notice _updateRenting is an internal function that is used to update the renting order.
    /// @dev This function is called by the rent function.
    /// @param lendingStorage is the storage pointer of the lending order.
    /// @param _tokenQuantity is the quantity of the NFTs being rented.
    /// @param _duration is the duration for which the NFTs are being rented.
    function _updateRenting(
        Lending storage lendingStorage,
        uint256 _tokenQuantity,
        uint256 _duration
    ) internal {
        rentingCtr++;
        lendingStorage.tokenQuantity =
            lendingStorage.tokenQuantity -
            _tokenQuantity;

        lendingStorage.tokenQuantityAlreadyRented =
            lendingStorage.tokenQuantityAlreadyRented +
            _tokenQuantity;

        Renting memory rentingCache;
        rentingCache.rentingId = rentingCtr;
        rentingCache.lendingId = lendingStorage.lendingId;
        rentingCache.rentStatus = RentStatus.RENTED;

        rentingCache.renterAddress = msg.sender;
        rentingCache.rentedDuration = _duration;
        rentingCache.tokenQuantityRented += _tokenQuantity;
        rentingCache.startTimeStamp = block.timestamp;
        rentingCache.rentedPricePerDay = lendingStorage.pricePerDay;
        rentingCache.refundRequired = false;
        rentingCache.refundEndTimeStamp = 0;

        rentings[rentingCtr] = rentingCache;

        lendingStorage.renterKeyArray.push(rentingCtr);
        activeRentingsKeys.push(rentingCtr);
    }

    /// @notice returnRented is a function that is used to return the rented NFTs.
    /// @notice Only the renter can call this function.
    /// @param _rentingID is the unique id of the renting order.
    /// @param _tokenQuantity is the quantity of the NFTs being returned.
    /// @dev This function can be used to partially return the rented NFTs.
    function returnRented(uint256 _rentingID, uint256 _tokenQuantity) external {
        if (_rentingID > rentingCtr) {
            revert InvalidOrderIdInput(_rentingID);
        }
        Renting storage rentingStorage = rentings[_rentingID];
        uint256 _lendingId = rentingStorage.lendingId;
        Lending storage lendingStorage = lendings[_lendingId];
        require(
            rentingStorage.renterAddress == msg.sender,
            "Caller is not the renter!"
        );

        require(
            rentingStorage.tokenQuantityRented >= _tokenQuantity,
            "Not enough tokens rented"
        );

        lendingStorage.tokenQuantity =
            lendingStorage.tokenQuantity +
            _tokenQuantity;

        lendingStorage.tokenQuantityAlreadyRented =
            lendingStorage.tokenQuantityAlreadyRented -
            _tokenQuantity;

        rentingStorage.tokenQuantityRented =
            rentingStorage.tokenQuantityRented -
            _tokenQuantity;

        if (rentingStorage.tokenQuantityRented == 0) {
            rentingStorage.rentStatus = RentStatus.RETURNED;
            _removeEntryFromArray(lendingStorage.renterKeyArray, _rentingID);
            _removeEntryFromArray(activeRentingsKeys, _rentingID);
        }

        if (!rentingStorage.refundRequired) {
            uint256 _lenderPayout = calculateCost(
                rentingStorage.rentedPricePerDay,
                rentingStorage.rentedDuration,
                _tokenQuantity
            );

            _splitFunds(_lenderPayout, lendingStorage.lenderAddress);
        } else {
            uint256 costTotalDuration = calculateCost(
                rentingStorage.rentedPricePerDay,
                rentingStorage.rentedDuration,
                _tokenQuantity
            );

            uint256 actualLenderPayout = calculateCost(
                rentingStorage.rentedPricePerDay,
                rentingStorage.refundEndTimeStamp -
                    rentingStorage.startTimeStamp,
                _tokenQuantity
            );

            _splitFunds(actualLenderPayout, lendingStorage.lenderAddress);

            uint256 _refundAmount = costTotalDuration - actualLenderPayout;
            payable(rentingStorage.renterAddress).transfer(_refundAmount);

            emit Refunded(
                _rentingID,
                _lendingId,
                msg.sender,
                _refundAmount,
                _tokenQuantity,
                rentingStorage.rentStatus
            );
        }

        emit Returned(
            _rentingID,
            _lendingId,
            msg.sender,
            _tokenQuantity,
            rentingStorage.rentStatus
        );
    }

    /// @notice _removeEntryFromArray is an internal function that is used to remove an entry from an array.
    /// @param arrayStorage is the storage pointer of the array.
    /// @param _entry is the entry to be removed from the array.
    function _removeEntryFromArray(
        uint256[] storage arrayStorage,
        uint256 _entry
    ) internal {
        for (uint256 i = 0; i < arrayStorage.length;) {
            if (arrayStorage[i] == _entry) {
                arrayStorage[i] = arrayStorage[arrayStorage.length - 1];
                arrayStorage.pop();
                break;
            }
            unchecked {
              i++;
            }
        }
    }

    /// @notice getLendingData is a function that is used to get the data of a lending order.
    /// @param _lendingId is the unique id of the lending order.
    /// @return All the data of the lending order.
    function getLendingData(
        uint256 _lendingId
    ) public view returns (Lending memory) {
        Lending memory listing = lendings[_lendingId];
        return listing;
    }

    /// @notice _splitFunds is an internal function that is used to split the funds between the lender and the admin.
    /// @param _totalAmount is the total amount to be split.
    /// @param _lenderAddress is the address of the lender.
    function _splitFunds(
        uint256 _totalAmount,
        address _lenderAddress
    ) internal {
        require(_totalAmount != 0, "totalAmount must be > 0");
        uint256 amountToSeller = (_totalAmount * (100 - percentFeesAdmin)) /
            100;
        withdrawableAmount =
            withdrawableAmount +
            (_totalAmount - amountToSeller);

        payable(_lenderAddress).transfer(amountToSeller);
    }

    /// @notice setAdmin is a function that is used to set the admin address.
    /// @notice The caller of this function must be the current admin.
    /// @param _newAddress is the address of the new admin.
    function setAdmin(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "Admin address can't be null!");
        adminAddress = payable(_newAddress);
    }

    /// @notice setFeesForAdmin is a function that is used to set the fees percentage for the admin.
    /// @notice The caller of this function must be the current admin.
    /// @param _percentFees is the new fees percentage for the admin.
    function setFeesForAdmin(uint256 _percentFees) external onlyAdmin {
        require(_percentFees < 100, "Fees cannot exceed 100%");
        percentFeesAdmin = _percentFees;
    }

    /// @notice setMinRentDueSeconds is a function that is used to set the minimum rent duration.
    /// @notice The caller of this function must be the current admin.
    /// @param _minDuration is the new minimum rent duration.
    function setMinRentDueSeconds(uint256 _minDuration) external onlyAdmin {
        minRentDueSeconds = _minDuration;
    }

    /// @notice isERC721 is a function that returns whether an NFT is ERC721 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC721 or not.
    function isERC721(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }

    /// @notice isERC1155 is a function that returns whether an NFT is ERC1155 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC1155 or not.
    function isERC1155(address nftAddress) public view returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }

    /// @notice withdrawFunds is a function that is used to withdraw the fees earned by the admin.
    /// @notice The caller of this function must be the current admin.
    function withdrawFunds() external onlyAdmin {
        require(withdrawableAmount > 0, "No more funds to withdraw");
        payable(msg.sender).transfer(withdrawableAmount);
        withdrawableAmount = 0;
    }

    // ------------------------------ Automation functions -------------------------------- //

    /// @notice setAutomationAddress is a function that is used to set the automation address.
    /// @notice The caller of this function must be the current admin.
    /// @param _automation is the address of the automation contract.
    /// @dev The automation address can't be zero address.
    function setAutomationAddress(address _automation) external onlyAdmin {
        require(_automation != address(0), "Automation address can't be null");
        automationAddress = _automation;
    }

    /// @notice checkReturnRefundAutomation is a function that is used to check, return and refund NFTs.
    /// @notice This function is called by the chainlink automation contract.
    /// @dev The caller of this function must be the automation contract.
    /// @dev This function will revert if the automation address is not set.
    function checkReturnRefundAutomation() external {
        require(
            automationAddress != address(0),
            "No automation address set yet!"
        );
        require(
            msg.sender == automationAddress,
            "Unauthorized caller!"
        );
        (uint256[] memory getExpired, uint256 toUpdate) = getExpiredRentings();
        if (toUpdate > 0) {
            _returnRentedUsingAutomation(getExpired, toUpdate);
        }
        (
            uint256[] memory getRefundRequireds,
            uint256 toRefund
        ) = getRefundRentings();
        if (toRefund > 0) {
            _markRefundsAndDelistUsingAutomation(getRefundRequireds, toRefund);
        }
    }

    /// @notice getExpiredRentings is a function that is used to get the expired renting orders.
    /// @return The ids of the expired renting orders and the number of expired renting orders.
    /// @dev This function will be used by the chainlink automation contract.
    /// @dev This function can be used by anyone to get the expired renting orders.
    function getExpiredRentings()
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arrLength = activeRentingsKeys.length;
        uint256[] memory tempArray = new uint256[](arrLength);
        uint256 j = 0;
        for (uint256 i = 0; i < activeRentingsKeys.length;) {
            uint256 _rentingId = activeRentingsKeys[i];
            if (
                block.timestamp >=
                rentings[_rentingId].startTimeStamp +
                    rentings[_rentingId].rentedDuration
            ) {
                tempArray[j] = _rentingId;
                unchecked {
                  j++;
                }
            }
            unchecked {
              i++;
            }
        }
        return (tempArray, j);
    }

    /// @notice _returnRentedUsingAutomation is an internal function that is used to return the expired renting orders.
    /// @param _rentingIDs is the ids of the expired renting orders.
    /// @param length is the number of expired renting orders.
    /// @dev This function comes into play when the automation contract calls the checkReturnRefundAutomation function.
    /// @dev This function settles the funds and updates the renting orders as required.
    function _returnRentedUsingAutomation(
        uint256[] memory _rentingIDs,
        uint256 length
    ) internal {
        require(length != 0, "The renters Array is Empty");

        for (uint256 i = 0; i < length;) {
            uint256 _rentingId = _rentingIDs[i];
            Renting storage rentingStorage = rentings[_rentingId];

            Lending storage lendingStorage = lendings[rentingStorage.lendingId];

            lendingStorage.tokenQuantity += rentingStorage.tokenQuantityRented;
            lendingStorage.tokenQuantityAlreadyRented -= rentingStorage
                .tokenQuantityRented;

            rentingStorage.rentStatus = RentStatus.RETURNED;

            _removeEntryFromArray(lendingStorage.renterKeyArray, _rentingId);
            _removeEntryFromArray(activeRentingsKeys, _rentingId);

            // Funds settlement
            if (!rentingStorage.refundRequired) {
                // calculate the amount to be paid to the lender
                uint256 _lenderPayout = calculateCost(
                    rentingStorage.rentedPricePerDay,
                    rentingStorage.rentedDuration,
                    rentingStorage.tokenQuantityRented
                );

                _splitFunds(_lenderPayout, lendingStorage.lenderAddress);
            } else {
                // actual cost if the lender owned the item for whole rent duration time
                uint256 costTotalDuration = calculateCost(
                    rentingStorage.rentedPricePerDay,
                    rentingStorage.rentedDuration,
                    rentingStorage.tokenQuantityRented
                );

                // calculate the amount to be paid to the lender for how much time the item was owned by lender
                uint256 actualLenderPayout = calculateCost(
                    rentingStorage.rentedPricePerDay,
                    rentingStorage.refundEndTimeStamp -
                        rentingStorage.startTimeStamp,
                    rentingStorage.tokenQuantityRented
                );

                _splitFunds(actualLenderPayout, lendingStorage.lenderAddress);

                // refund remaining amount to renter
                uint256 _refundAmount = costTotalDuration - actualLenderPayout;
                payable(rentingStorage.renterAddress).transfer(_refundAmount);

                emit Refunded(
                    _rentingId,
                    rentingStorage.lendingId,
                    rentingStorage.renterAddress,
                    _refundAmount,
                    rentingStorage.tokenQuantityRented,
                    rentingStorage.rentStatus
                );
            }

            rentingStorage.tokenQuantityRented = 0;

            emit Returned(
                _rentingId,
                rentingStorage.lendingId,
                rentingStorage.renterAddress,
                rentingStorage.tokenQuantityRented,
                RentStatus.RETURNED
            );
            unchecked {
              i++;
            }
        }
    }

    /// @notice getRefundRentings is a function that is used to get the refund required renting orders.
    /// @return The ids of the refund required renting orders and the number of refund required renting orders.
    /// @dev This function will be used by the chainlink automation contract.
    /// @dev This function can be used by anyone to get the refund required renting orders.
    function getRefundRentings()
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 arrLength = activeRentingsKeys.length;
        uint256[] memory tempArray = new uint256[](arrLength);
        uint256 j = 0;
        for (uint256 i = 0; i < activeRentingsKeys.length;) {
            uint256 _rentingId = activeRentingsKeys[i];

            Renting memory rentingCache = rentings[_rentingId];
            if (!rentingCache.refundRequired) {
                Lending memory lendingCache = lendings[rentingCache.lendingId];

                if (lendingCache.nftStandard == NFTStandard.E721) {
                    IERC721 nft721 = IERC721(lendingCache.nftAddress);
                    try nft721.ownerOf(lendingCache.tokenId) {
                        if (
                            nft721.ownerOf(lendingCache.tokenId) !=
                            lendingCache.lenderAddress
                        ) {
                            tempArray[j] = _rentingId;
                            unchecked {
                              j++;
                            }
                        }
                    } catch {
                        tempArray[j] = _rentingId;
                        unchecked {
                          j++;
                        }
                    }
                } else {
                    IERC1155 nft1155 = IERC1155(lendingCache.nftAddress);
                    if (
                        nft1155.balanceOf(
                            lendingCache.lenderAddress,
                            lendingCache.tokenId
                        ) < lendingCache.tokenQuantity
                    ) {
                        tempArray[j] = _rentingId;
                        unchecked {
                          j++;
                        }
                    }
                }
            }
            unchecked {
              i++;
            }
        }
        return (tempArray, j);
    }

    /// @notice _markRefundsAndDelistUsingAutomation is an internal function that is used to mark the refund required renting orders and delist the lending order.
    /// @param _rentingIDs is the ids of the refund required renting orders.
    /// @param length is the number of refund required renting orders.
    /// @dev This function comes into play when the automation contract calls the checkReturnRefundAutomation function.
    /// @dev This function marks the refund required renting orders and delists the lending order.
    /// @dev The marked refund required renting orders will be refunded during the settlement process.
    function _markRefundsAndDelistUsingAutomation(
        uint256[] memory _rentingIDs,
        uint256 length
    ) internal {
        require(length != 0, "The renters Array is Empty");

        for (uint256 i = 0; i < length;) {
            uint256 _rentingId = _rentingIDs[i];
            Renting storage rentingStorage = rentings[_rentingId];
            rentingStorage.refundRequired = true;
            rentingStorage.refundEndTimeStamp = block.timestamp;
            Lending storage lendingStorage = lendings[rentingStorage.lendingId];

            lendingStorage.tokenQuantity = 0;

            lendingStorage.lendStatus = LendStatus.DELISTED;
            _removeEntryFromArray(activeLendingsKeys, rentingStorage.lendingId);

            userListedNFTBefore[lendingStorage.nftAddress][
                lendingStorage.tokenId
            ][lendingStorage.lenderAddress] = false;

            emit DeListed(rentingStorage.lendingId, lendingStorage.lendStatus);
            unchecked {
              i++;
            }
        }
    }
    
    /// @notice React to receiving Ether
    receive() external payable {}
}