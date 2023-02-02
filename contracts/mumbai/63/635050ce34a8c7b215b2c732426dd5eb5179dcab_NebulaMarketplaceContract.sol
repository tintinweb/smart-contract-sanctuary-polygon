/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// File: @openzeppelin\contracts\utils\Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin\contracts\utils\Context.sol


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

// File: @openzeppelin\contracts\access\Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


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

// File: @openzeppelin\contracts\interfaces\IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin\contracts\utils\introspection\ERC165Checker.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin\contracts\utils\introspection\ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin\contracts\token\ERC1155\utils\ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin\contracts\token\ERC1155\utils\ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol


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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\token\ERC1155\extensions\IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin\contracts\utils\Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin\contracts\token\ERC1155\ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin\contracts\security\Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin\contracts\utils\math\Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin\contracts\utils\Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: Contracts\ContextMixin.sol



pragma solidity ^0.8.4;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// File: Contracts\NebulaDropsCollectible.sol


/**
 __    __  ________  _______   __    __  __         ______  
|  \  |  \|        \|       \ |  \  |  \|  \       /      \ 
| $$\ | $$| $$$$$$$$| $$$$$$$\| $$  | $$| $$      |  $$$$$$\
| $$$\| $$| $$__    | $$__/ $$| $$  | $$| $$      | $$__| $$
| $$$$\ $$| $$  \   | $$    $$| $$  | $$| $$      | $$    $$
| $$\$$ $$| $$$$$   | $$$$$$$\| $$  | $$| $$      | $$$$$$$$
| $$ \$$$$| $$_____ | $$__/ $$| $$__/ $$| $$_____ | $$  | $$
| $$  \$$$| $$     \| $$    $$ \$$    $$| $$     \| $$  | $$
 \$$   \$$ \$$$$$$$$ \$$$$$$$   \$$$$$$  \$$$$$$$$ \$$   \$$
*/                                                           
                                                            
      
pragma solidity ^0.8.7;
//import "./IERC165.sol";
//import "@openzeppelin/contracts/utils/ContextMixin.sol";

contract NebulaDropsCollectible is ERC1155, Ownable ,
 //IERC165,
 IERC2981,  Pausable, ContextMixin {
    // Variables
    string private baseURI;
    string public name;
    
    
    uint256 public lastMintedTokenId = 0 /* 0 means no token minted..*/;
    // address public _defaultNebulaMarketplace;
    address[] public allowedMarketplaces;
    

    // We authorize an additional minter who is not the owner.
    // In practice, the owner will be the creator and will be able to manage their collection on 
    // And Uncut will be added as an additional authorized minter.
    address[] public _allowedMinters;

    // We authorize an additional minter who is not the owner.
    // In practice, the owner will be the creator and will be able to manage their collection on 
    // And Uncut will be added as an additional authorized minter.
    address public _dropOwner;

    // Total Allowed Tokens to set the max number of token(s) limit.
    uint256 public _artistRoyaltyPercentage;

    // Total Allowed Tokens to set the max number of token(s) limit.
    uint256 public _totalAllowedTokens;

    uint256 public _totalMintedTokens;

    // /* Drop(s) & Allowed Owner(s)..*/    
    // mapping(address => ApprovedArtists4Minting) public allowedArtistToMintTokens;
    // struct ApprovedArtists4Minting {
    //   address allowedMinter;
    //   address tokensOwner;
    //   uint256 totalTokens;
    // }

    // /* Token wise Minter Address..*/    
    // mapping(uint256 => address) public tokenMinter;

    // /* Drop(s) wise Minted Token(s)..*/    
    // mapping(address => MintedTokensByArtist) public mintedTokensByArtists;
    // struct MintedTokensByArtist {
    // //   string dropId;
    //   address allowedMinter;
    //   address tokensOwner; 
    //   uint256 tokensMinted; 
    // }




    /* Drop(s) Approved..*/
    event DropApproved( address allowedMinter,address tokensOwner);
    /* Token(s) Minted Event..*/
    event TokenMinted(address from, uint256 id);
    event TokensMinted(address from, uint256[] ids);

    
    constructor(string memory _name, string memory _uri, address _dropArtist, uint256 _totalTokens, uint256 _artistRoyaltyPercent, address _nebulaMarketplaceContract) 
    ERC1155(_uri) 
    { 
        require(_artistRoyaltyPercent < 100 , "Invalid Royalty Percentage!");
        require(_nebulaMarketplaceContract != address(0) , "Invalid Marketplace address!");

        setName(_name);  
        setURI(_uri);     
        _dropOwner = _dropArtist;
        _allowedMinters.push(_dropArtist);
        _totalAllowedTokens = _totalTokens;
        _artistRoyaltyPercentage = _artistRoyaltyPercent;
        //_defaultNebulaMarketplace = _nebulaMarketplaceContract;
         allowedMarketplaces.push(_nebulaMarketplaceContract);         
    }


    modifier onlyOwnerOrMinter() 
    {
                bool isAllowed = false;
                if(owner() == _msgSender())
                {
                    isAllowed = true;
                }
                else
                {
                    for(uint256 i = 0; i< _allowedMinters.length; i++ ){          
                                if(_allowedMinters[i]==_msgSender()) 
                                {
                                    isAllowed = true;
                                }
                        }
                } 
                require(isAllowed == true,   "Not authorized");    
            _;
    }


    function resetArtistRoyaltyPercentage(uint256 _percentage)
     public onlyOwner {
       _artistRoyaltyPercentage = _percentage;
    }

    function addMinter(address _minter)
     public onlyOwner {
        _allowedMinters.push(_minter);
    }

    function removeMinter(address _minter)
     public onlyOwner {
        for(uint256 i = 0; i< _allowedMinters.length; i++ ){
            if(_allowedMinters[i] == _minter){
            delete _allowedMinters[i];        
            }  
        }
    }


    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }



    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setURI(string memory _newuri) public onlyOwner {
        baseURI = _newuri;
        _setURI(_newuri);
    }



    /* this will add a new Marketplace address to allow participate in the nebula token's sell..*/
    function whitelistMarketplace(address _contractaddress) public onlyOwner{
        allowedMarketplaces.push(_contractaddress); 
    }

    /* this is to delete an item stored at a specific index in the array.  
     * Once you delete the item the value in the array is set back to 0 for a uint..*/
    function removeMarketplace(uint index) public onlyOwner{
        delete allowedMarketplaces[index];  
    }

    /* this will return a list of all whitelisted Marketplaces..*/
    function fetchWhitelistMarketplaces() public view returns(address[] memory) {
      return  allowedMarketplaces; 
    }


    // /* Approve owners to ..*/
    // function approveArtistToMint(address _allowedminter,address _tokensowner,uint256 _totaltokens) 
    // public onlyOwner
    // {
    //     allowedArtistToMintTokens[_allowedminter] =  ApprovedArtists4Minting (         
    //         _allowedminter,
    //         _tokensowner,
    //         _totaltokens
    //     );   
         
    //     /* Emit approved message...*/
    //     emit DropApproved(
    //         _allowedminter,
    //         _tokensowner 
    //     );
    // }


    // /* Reject approved drops..*/
    // function rejectApprovedDrops(address  _allowedminter) public onlyOwner{
    //     delete allowedArtistToMintTokens[_allowedminter];  
    // }

    // /* this will return a list of all whitelisted Marketplaces..*/
    // function fetchApprovedDropsList(address _allowedminter) public view returns(ApprovedArtists4Minting memory) {
    //   return allowedArtistToMintTokens[_allowedminter];  
    // }


    function mint(uint256 _amount) //, bool _cardpay
        public onlyOwnerOrMinter payable  
     {
        // // string memory _name, string memory _newuri, 
        // ApprovedArtists4Minting memory _approvedArtist =   allowedArtistToMintTokens[msg.sender];

        // require(address(_approvedArtist.allowedMinter) == msg.sender, "You are not allowed to mint the tokens for this drop.");

        /* Check whether it's first time minting..*/
       // if(mintedTokensByArtists[_dropid].tokensMinted > 0){
        require(_totalMintedTokens < _totalAllowedTokens, "Your total number of allowed Token(s) are already minted.");
        //}
 
        uint256 _id = (lastMintedTokenId+1);
       // address _tokensOwner = allowedArtistToMintTokens[msg.sender].tokensOwner;
        // /* Set name for Minting Token..*/
        // name = _approvedArtist.dropName;

        // /* Update baseURI according to new IPFS url..*/
        // baseURI = _approvedArtist.dropIPFSUri;

        // /* Set IPFS url..  */
        // _setURI(_approvedArtist.dropIPFSUri);

        /* Start minting a new token..*/
        _mint(_dropOwner, _id, _amount, '');
 
        // // Store Minter detail.
        // tokenMinter[_id]=_tokensOwner;

        // if(_cardpay == true)
        // {
        //     /* Transfer token to the real owner..*/
        //     _safeTransferFrom(msg.sender,  _tokensOwner, _id, _amount, '');
        // }

        /* Set approval for nebula marketplace as deafult marketplace..*/
        // _setApprovalForAll(_msgSender(), allowedMarketplaces[0], true);

       //  uint256 _mintedTokens = _totalMintedTokens + 1;

        // /* Store minted tokens details..*/
        // mintedTokensByArtists[msg.sender] =  MintedTokensByArtist (
        //             //_dropid,
        //             msg.sender, 
        //             _dropOwner,
        //             _mintedTokens
        //         );   


        /* Set last minted Token Id..*/
        lastMintedTokenId = _id;
        /* ​Update frontend application about the completion of minting process..  */
        emit TokenMinted(_dropOwner, _id);
    }


    function mintBatch( 
     uint256 _amount, 
     uint256  _numberOfTokensToMint) //, bool _cardpay
        public onlyOwnerOrMinter payable
    {
        // string memory _name, string memory _newuri, 
        // ApprovedArtists4Minting memory _approvedArtist =   allowedArtistToMintTokens[msg.sender];

       // require(_approvedArtist.allowedMinter == msg.sender, "You are not allowed to mint the tokens for this drop.");

        uint256 _mintedTokens = _totalMintedTokens + _numberOfTokensToMint;
        //  if(_totalMintedTokens > 0){
        //      _mintedTokens = _totalMintedTokens;
        //    }
        // _mintedTokens += _numberOfTokensToMint;
        require(_mintedTokens <= _totalAllowedTokens, "Your total number of allowed Token(s) are already minted.");

        // /* Set name for Minting Token..*/
        // name = _approvedArtist.dropName;

        // /* Update baseURI according to new IPFS url..*/
        // baseURI = _approvedArtist.dropIPFSUri;

        // /* Set IPFS url..  */
        // _setURI(_approvedArtist.dropIPFSUri);

        // address _tokensOwner = allowedArtistToMintTokens[msg.sender].tokensOwner;
        uint256[] memory _ids= new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint); 
        uint index = 0;
        for(uint256 i = (lastMintedTokenId+1); i<= (lastMintedTokenId + _numberOfTokensToMint); i++ ){
            _ids[index] = i;
            _amounts[index] = _amount;
            index += 1;

        // // Store Minter detail.
        // tokenMinter[i]=_tokensOwner;        
        }


        /* Start batch minting of the required number of tokens..*/
        _mintBatch(_dropOwner, _ids, _amounts, '');
        

        // if(_cardpay == true)
        // {
        //       /* Transfer tokens to the real owner..*/
        //       _safeBatchTransferFrom(msg.sender, _tokensOwner, _ids, _amounts, '');
        // }

        ///* Set approval for nebula marketplace as deafult marketplace..*/
        //_setApprovalForAll(_msgSender(), _defaultNebulaMarketplace, true);

        // /* Store minted tokens details..*/
        // mintedTokensByArtists[msg.sender] =  MintedTokensByArtist (
        //             msg.sender, 
        //             _dropOwner,
        //             _mintedTokens
        //         );


        /* Set last minted Token Id..*/
        lastMintedTokenId = _ids[_numberOfTokensToMint-1];
        
        /* ​Update frontend application about the completion of minting process..  */
        emit TokensMinted(_dropOwner, _ids);
    }




//     function fetchMinterAddress(uint256 _tokenId) public view returns(address) {
//         // Store Minter detail.
//         return tokenMinter[_tokenId];
//    }

        

    // /**
    //  * @dev See {IERC1155-setApprovalForAll}.
    //  */
    // function setApprovalForAll(address operator, bool approved) public virtual override { 
    //    // Do this on the wrapped contract directly. We can't do this here
    //     revert();
    // }

    //  /**
    //      * @dev .
    //      */
    //     function allowMarketPlacesToList(address operator, bool approved) public  { 
    //         bool isMarketplaceAllowed = false;
    //         for(uint i=0; i < allowedMarketplaces.length;i++)
    //         {
    //                 if(allowedMarketplaces[i]==operator) 
    //                 {
    //                     isMarketplaceAllowed = true;
    //                 }
    //         }

    //          require(isMarketplaceAllowed == true, "Contract Address is not whitelisted for the Nebula Tokens.");
    //         _setApprovalForAll(_msgSender(), operator, approved);
    //     }


    // Automatically approve Pre-Approved Marketplacesto trade our NFTs 
    // so that users do not need to pay gas fees
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Auto Apporve already granted Marketplaces..
        for(uint256 i = 0; i < allowedMarketplaces.length; i++ ){
            if (_operator == address(allowedMarketplaces[i])) {
                    return true;
                }
            } 

        // otherwise, use the default ERC1155.isApprovedForAll()
        return false;//super.isApprovedForAll(_owner, _operator);
    }



  /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _dropOwner = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }


    /**
     * Return royalty infos. We support different royalties for each token.
     */
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
    external
    view 
    override
        returns (address receiver, uint256 royaltyAmount)
    {   
        return (_dropOwner, (salePrice * _artistRoyaltyPercentage) / 100);
    }


    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

        
 
//     /**
//      * @dev See {IERC1155-name}
//      */

//     function getLastMintedTokenName() public view returns(string memory) {
//     return name;
//    }

//    /**
//      * @dev See {IERC1155-baseURI}
//      */

//     function getLastMintedTokenURI() public view returns(string memory) {
//     return baseURI;
//    }


   
    /**
     * @dev See {IERC1155-burn token}
     */

    function burn(uint256 id, uint256 amount) public onlyOwner{
        _burn(msg.sender, id, amount);
    }


    /**
     * @dev See {IERC1155-burn token in batch}
     */

    function burnBatch(uint256[] memory ids, uint256[] memory amounts) public onlyOwner{
        _burnBatch(msg.sender, ids, amounts);
    }

}

// File: Contracts\NebulaMarketplaceContract.sol


/**
 __    __  ________  _______   __    __  __         ______  
|  \  |  \|        \|       \ |  \  |  \|  \       /      \ 
| $$\ | $$| $$$$$$$$| $$$$$$$\| $$  | $$| $$      |  $$$$$$\
| $$$\| $$| $$__    | $$__/ $$| $$  | $$| $$      | $$__| $$
| $$$$\ $$| $$  \   | $$    $$| $$  | $$| $$      | $$    $$
| $$\$$ $$| $$$$$   | $$$$$$$\| $$  | $$| $$      | $$$$$$$$
| $$ \$$$$| $$_____ | $$__/ $$| $$__/ $$| $$_____ | $$  | $$
| $$  \$$$| $$     \| $$    $$ \$$    $$| $$     \| $$  | $$
*/

pragma solidity ^0.8.7;
/*
 * Smart contract allowing users to trade (list and buy) any NebulaDropsCollectible tokens.
 * Users can create public and private listings.
 * Users can set more addresses that can buy tokens (like whitelist).
 */

contract NebulaMarketplaceContract is Ownable, ERC1155Holder, ReentrancyGuard 
{

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    // Counters.Counter private _numOfTxs;
    // uint256 private _volume;

    uint256 private platformFee = 20; // In percentage %
    uint256 private sellerShare = 75; // In percentage %
    uint256 public ListingFee_ = 0.0001  * (10**18);

    event TokenListed(uint256 tokenId, address _contractAddress, address seller, uint256 amount, uint256 pricePerToken, address[] privateBuyer, bool privateSale);
    event TokenSold(uint256 tokenId,address _contractAddress, address seller, address buyer, uint256 amount, uint256 pricePerToken,uint soldCount, bool privateSale);
    event ListingDeleted( uint256 tokenId, address _contractAddress);

    mapping(address => mapping(uint256 => NFTListing)) private tokenIdToListing;
    NFTListing[] private listingsArray;

    struct ListedToken {
        uint256 tokenId;
        address contractAddress;
    }

    struct NFTListing {
        uint256 tokenId;
        address contractAddress;
        address  owner;
        address[] buyers; 
        uint256 amount;
        uint256 price;
        uint256 tokensAvailable;
        bool privateListing;
        bool sold;
        uint soldCount; 
    }

    struct Stats {
        uint256 volume;
        uint256 itemsSold;
    }

    modifier onlyItemOwner(address _contractAddress,uint256 _id) {
        require(
            tokenIdToListing[_contractAddress][_id].owner == msg.sender,
            "Only product owner can do this operation"
        );
        _;
    }

    modifier onlyItemOrMarketplaceOwner(address _contractAddress,uint256 _id) 
    {
                bool isAllowed = false;
                if(owner() == _msgSender())
                {
                    isAllowed = true;
                }
                else if(tokenIdToListing[_contractAddress][_id].owner == msg.sender) 
                {
                                    isAllowed = true;                                
                } 
                require(isAllowed == true,   "Only product or contract owner can do this operation");    
            _;
    }

    function updateListingPrice(uint _listingPrice) public onlyOwner payable nonReentrant{    
        ListingFee_ = _listingPrice;
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */    
    function listTokens(address _contractAddress, uint _firstTokenId, uint _lastTokenId,
    uint256 _amount, uint256 _price, address[] memory _privateBuyer) 
     public payable nonReentrant  
      {

        NebulaDropsCollectible tokenContract = NebulaDropsCollectible(_contractAddress);  

        require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");
        require(_firstTokenId <= _lastTokenId, "Invalid Token Ids!");      
        require(_amount > 0, "Amount must be greater than 0!");      
        require(_price > 0, "Price must be at least 1 wei");
        require(msg.value == ListingFee_, "Not enough amount for listing fee");             

        //Strings.toString(ListingFee_)

        // for(uint i=0; i<_tokenIds.length; i++)
        // { 
        //     require(tokenContract.balanceOf(msg.sender,  _tokenIds[i]) >= _amount, "Caller must own given token!");
        // }
        //uint256[]  _tokenIds = 

        bool privateListing = _privateBuyer.length>0;

        // Deducting Listing fee for this transaction.       
        (bool success, ) = (payable(owner())).call{value: ListingFee_}("");
        require(success, "Failed to deduct Listing fees!");

        for(uint i=_firstTokenId; i<=_lastTokenId; i++)
        {
            uint256 tokenId = i; 

            require(tokenContract.balanceOf(msg.sender, tokenId) >= _amount, "Caller must own given token!");
            require(tokenIdToListing[_contractAddress][tokenId].contractAddress != _contractAddress, "Token is already listed for this Smart Contract!");

            /* Transfer token to the contract...*/
            tokenContract.safeTransferFrom(msg.sender,address(this), tokenId, _amount, "");
  
            /* Add Token details to tokenList object...*/
            tokenIdToListing[_contractAddress][tokenId] = NFTListing(
                tokenId,
                _contractAddress,
                payable(msg.sender),
                _privateBuyer,
                _amount,
                _price,
                _amount,
                privateListing,
                false,
                0
              );

            /* Add Token details to ListingArrary...*/
            listingsArray.push(tokenIdToListing[_contractAddress][tokenId]);

            /* Emit the listed item detail...*/
            emit TokenListed(tokenId, _contractAddress, msg.sender, _amount, _price, _privateBuyer, privateListing);
        }
        //return _tokenIds;
    }


    function buyToken(address _contractAddress, uint256 _tokenId, uint256 _amount) public payable nonReentrant 
    {
        NebulaDropsCollectible tokenContract = NebulaDropsCollectible(_contractAddress);
        address _seller =tokenIdToListing[_contractAddress][_tokenId].owner;

        if(tokenIdToListing[_contractAddress][_tokenId].privateListing == true) {
            bool whitelisted = false;
            for(uint i=0; i<tokenIdToListing[_contractAddress][_tokenId].buyers.length; i++){
                if(tokenIdToListing[_contractAddress][_tokenId].buyers[i] == msg.sender) {
                    whitelisted = true;
                }
            }
            require(whitelisted == true, "Sale is private!");
        }

        require(msg.sender != _seller, "Can't buy your own tokens!");
        require(msg.value >= (tokenIdToListing[_contractAddress][_tokenId].price * _amount) * (10**18), "Insufficient funds!");
        require(tokenContract.balanceOf(address(this), tokenIdToListing[_contractAddress][_tokenId].tokenId) >= _amount, "Seller doesn't have enough tokens!");
        require(tokenIdToListing[_contractAddress][_tokenId].sold == false, "NFTListing not available anymore!");
        require(tokenIdToListing[_contractAddress][_tokenId].tokensAvailable >= _amount, "Not enough tokens left!");

        uint256 netAmount = (tokenIdToListing[_contractAddress][_tokenId].price * _amount) * (10**18); 

        // Get the creator share
        (address creatorAddress, uint256 creatorShare) = 
            getCreatorShare(
                tokenIdToListing[_contractAddress][_tokenId].contractAddress,
                _tokenId, 
                netAmount 
                );

        require(creatorAddress != address(0), "Do not have valid Owner detail.");
        require(creatorShare > 0, "Creator share should be greater than 0.");

        tokenIdToListing[_contractAddress][_tokenId].tokensAvailable -= _amount;

        if(tokenIdToListing[_contractAddress][_tokenId].privateListing == false){
           tokenIdToListing[_contractAddress][_tokenId].buyers.push(msg.sender);
        }

        if(tokenIdToListing[_contractAddress][_tokenId].tokensAvailable == 0) {
        tokenIdToListing[_contractAddress][_tokenId].sold = true;
        }

        // Set Owner for this token
        tokenIdToListing[_contractAddress][_tokenId].owner = payable(msg.sender);

        // Increase Number of sell or resell.
        tokenIdToListing[_contractAddress][_tokenId].soldCount += 1;
 
        /* Find listArrayIndex for the tokenId..*/
        uint256 _listIndex =  listArrayIndexByTokenId(_tokenId);
        require(_listIndex !=   1000000 /* non-existing token...*/, "Invalid Token detail!");
        listingsArray[_listIndex] = tokenIdToListing[_contractAddress][_tokenId];
 
       // Deducting Royalty fee for this transaction.       
       (bool successRoyalty, ) = creatorAddress.call{ value: creatorShare}(""); // Deducting Minter's Royalty fee.
       require(successRoyalty, "Failed to deduct Royalty fees!");

       // Deducting Platform fee for this transaction.       
       (bool successPlatform, ) = (owner()).call{ value: (netAmount * platformFee)/100 }(""); //  Deducting Platform fee for this transaction.
       require(successPlatform, "Failed to deduct Platform fees!");

       // Deducting Artist share for this transaction.       
       (bool successArtistShare, ) = _seller.call{ value: (netAmount * sellerShare)/100}(""); // Transfering seller's share to the Owner.
       require(successArtistShare, "Failed to deduct Artist Share!");

        // Transfer Token to buyers..
       tokenContract.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
   }


    function buyTokens(address _contractAddress, uint  _totalTokensToBuy, uint  _amount) public payable nonReentrant //uint256[] memory _tokenIds, uint256[] memory _amounts
    {         
        NebulaDropsCollectible tokenContract = NebulaDropsCollectible(_contractAddress);
        NFTListing[] memory _list = fetchAvailableMarketItems(_contractAddress);

        address _seller = _list[0].owner;
        // uint256 _tokenCost = _list[0].price * _amount;
        uint256 _totalPrice = _list[0].price * _amount * _totalTokensToBuy  * (10**18);

        require(msg.sender != _seller, "Can't buy your own tokens!");
        require(msg.value >= _totalPrice, "Insufficient funds!");

        for (uint256 idxValidation = 0; idxValidation < _totalTokensToBuy; idxValidation++) 
        {
           uint256 _tokenAmount = _amount;// _amounts[idxValidation];
           uint256 _tokenId = _list[idxValidation].tokenId; 

            if(tokenIdToListing[_contractAddress][_tokenId].privateListing == true) {
                bool whitelisted = false;
                for(uint i=0; i<tokenIdToListing[_contractAddress][_tokenId].buyers.length; i++){
                    if(tokenIdToListing[_contractAddress][_tokenId].buyers[i] == msg.sender) {
                        whitelisted = true;
                    }
                }
                require(whitelisted == true, "Sale is private!");
            }

            require(tokenContract.balanceOf(address(this), tokenIdToListing[_contractAddress][_tokenId].tokenId) >= _amount, "Seller doesn't have enough tokens!");
            require(tokenIdToListing[_contractAddress][_tokenId].sold == false, "NFTListing not available anymore!");
            require(tokenIdToListing[_contractAddress][_tokenId].tokensAvailable >= _tokenAmount, "Not enough tokens left!");            
       }

       // Deducting Platform fee for this transaction.       
       (bool successPlatform, ) = (owner()).call{ value: (_totalPrice * platformFee)/100 }(""); //  Deducting Platform fee for this transaction.
       require(successPlatform, "Failed to deduct Platform fees!");

       // Deducting Artist Share for this transaction.       
       (bool successArtistShare, ) = _seller.call{ value: (_totalPrice * sellerShare)/100}(""); // Transfering seller's share to the Owner.
       require(successArtistShare, "Failed to deduct Artist Share!");

        //////////////////////////////////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////////////////////////////////
 
        for (uint256 index = 0; index < _totalTokensToBuy; index++) 
        {     
            uint256 _tokenAmount = _amount;// _amounts[idxValidation];
            //uint256 _amount = _amounts[index];
            // uint256 _tokenId = _tokenIds[index];
            uint256 _tokenId = _list[index].tokenId; 
                         
            tokenIdToListing[_contractAddress][_tokenId].tokensAvailable -= _tokenAmount;
            if(tokenIdToListing[_contractAddress][_tokenId].privateListing == false){
                tokenIdToListing[_contractAddress][_tokenId].buyers.push(msg.sender);
            }
            if(tokenIdToListing[_contractAddress][_tokenId].tokensAvailable == 0) {
                tokenIdToListing[_contractAddress][_tokenId].sold = true;
            } 

            // Set Owner for this token
            tokenIdToListing[_contractAddress][_tokenId].owner = payable(msg.sender);

            // Increase Number of sell or resell.
            tokenIdToListing[_contractAddress][_tokenId].soldCount += 1;

            /* Find listArrayIndex for the tokenId..*/
            uint256 _listIndex =  listArrayIndexByTokenId(_tokenId);
            require(_listIndex !=   1000000 /* non-existing token...*/, "Invalid Token detail!");
            listingsArray[_listIndex] = tokenIdToListing[_contractAddress][_tokenId];

            emit TokenSold(
                _tokenId,
                _contractAddress,
                listingsArray[_listIndex].owner,
                msg.sender,
                _tokenAmount,
                listingsArray[_listIndex].price,
                listingsArray[_listIndex].soldCount,
                listingsArray[_listIndex].privateListing
            ); 
            
            uint256 netAmount = (listingsArray[_listIndex].price * _tokenAmount) * (10**18);  //* _totalTokensToBuy
            
            //require(1==2, Strings.toString(_list[index].tokenId));
            // Get the creator share
            (address creatorAddress, uint256 creatorShare) = 
            getCreatorShare(_list[index].contractAddress, _list[index].tokenId, netAmount);
   
            require(creatorAddress != address(0), "Do not have valid Owner detail.");
            require(creatorShare > 0, "Creator share should be greater than 0.");
 
            // Deducting Royalty fee for this transaction.       
            (bool successRoyalty, ) = creatorAddress.call{ value: creatorShare }(""); // Deducting Minter's Royalty fee.
            require(successRoyalty, "Failed to deduct Royalty fees!");
            tokenContract.safeTransferFrom(address(this), msg.sender, _tokenId, _tokenAmount, "");           
        }
    }


    function resellToken(address _contractAddress, uint256 _tokenId, uint256 _amount, uint256 _price, address[] memory _privateBuyer) 
        public payable nonReentrant 
        onlyItemOwner(_contractAddress,_tokenId)
        returns(uint256) {
        NebulaDropsCollectible tokenContract = NebulaDropsCollectible(_contractAddress);

        require(_amount > 0, "Amount must be greater than 0!");
        require(tokenContract.balanceOf(msg.sender, _tokenId) >= _amount, "Caller must own given token!"); 

        /* Deducting Platform fee for this transaction...*/   
        (bool successListingFee, ) = (owner()).call{value: ListingFee_}("");
        require(successListingFee, "Failed to deduct Listing fees!");


        /* Transfer token to the contract...*/
        tokenContract.safeTransferFrom(msg.sender, address(this), tokenIdToListing[_contractAddress][_tokenId].tokenId, _amount, "");   

        bool privateListing = _privateBuyer.length>0;

        if(tokenIdToListing[_contractAddress][_tokenId].contractAddress == address(0)) /* New Entry...*/
        {             
               tokenIdToListing[_contractAddress][_tokenId] = NFTListing
                        (
                            _tokenId, 
                            _contractAddress,
                            // payable(address(0)),
                            payable(msg.sender), 
                            _privateBuyer, 
                            _amount, 
                            _price, 
                            _amount,
                            privateListing, 
                            false,
                            tokenIdToListing[_contractAddress][_tokenId].soldCount
                            // , listingId
                        );
        }
        else{
                tokenIdToListing[_contractAddress][_tokenId].owner =  payable(msg.sender);
                tokenIdToListing[_contractAddress][_tokenId].buyers =  _privateBuyer;
                tokenIdToListing[_contractAddress][_tokenId].amount =  _amount;
                tokenIdToListing[_contractAddress][_tokenId].tokensAvailable = _amount;
                tokenIdToListing[_contractAddress][_tokenId].price =  _price;
                tokenIdToListing[_contractAddress][_tokenId].privateListing = privateListing;
                tokenIdToListing[_contractAddress][_tokenId].sold =  false;                    
        }
       
         /* Find listArrayIndex for the tokenId..*/
            uint256 _listIndex =  listArrayIndexByTokenId(_tokenId);
           
            if(_listIndex== 1000000) /* non-existing token...*/
            {
                    listingsArray.push(tokenIdToListing[_contractAddress][_tokenId]);
            }
            else {
                    listingsArray[_listIndex] = tokenIdToListing[_contractAddress][_tokenId];
            }

            /* Emit the listed item detail...*/
            emit TokenListed(_tokenId, _contractAddress, msg.sender, _amount, _price, _privateBuyer, privateListing);
 
        return _tokenId;
    }
 

    function deleteListingItem(address _contractAddress,uint256 _tokenId) public  onlyItemOrMarketplaceOwner(_contractAddress,_tokenId){
       // require(msg.sender == tokenIdToListing[_tokenId].owner, "Not caller's listing!");

        NebulaDropsCollectible tokenContract = NebulaDropsCollectible(tokenIdToListing[_contractAddress][_tokenId].contractAddress);
        require(tokenContract.balanceOf(address(this), _tokenId) >= 1, "Caller must own given token!"); 
        require(tokenIdToListing[_contractAddress][_tokenId].sold == false, "Listing not available!");
        
        // Transfer token back to the owner..
        tokenContract.safeTransferFrom(address(this), tokenIdToListing[_contractAddress][_tokenId].owner, _tokenId, tokenIdToListing[_contractAddress][_tokenId].tokensAvailable, "");           
     

        // tokenIdToListing[_contractAddress][_tokenId].sold = true;
        delete tokenIdToListing[_contractAddress][_tokenId];
        
        /* Find listArrayIndex for the tokenId..*/
        uint256 _listIndex =  listArrayIndexByTokenId(_tokenId);

        delete listingsArray[_listIndex];//.sold = true;

        emit ListingDeleted(_tokenId, tokenIdToListing[_contractAddress][_tokenId].contractAddress);
    }

    function deleteAllListingItems(address _contractAddress) public  onlyOwner
    {
       // require(msg.sender == tokenIdToListing[_tokenId].owner, "Not caller's listing!");

        NebulaDropsCollectible tokenContract = NebulaDropsCollectible(_contractAddress);
        
        NFTListing[] memory _list = fetchAvailableMarketItems(_contractAddress);

       // require(tokenContract.balanceOf(msg.sender, _tokenId) >= 1, "Caller must own given token!"); 
       // require(tokenIdToListing[_tokenId].sold == false, "Listing not available!");
       for(uint i=0; i<_list.length; i++)
        {
            uint256 _tokenId = _list[i].tokenId; 

            // Transfer token back to the owner..
            tokenContract.safeTransferFrom(address(this), _list[i].owner, _tokenId, _list[i].tokensAvailable, "");           
        

            // tokenIdToListing[_tokenId].sold = true;
            delete tokenIdToListing[_contractAddress][_tokenId];
            
            /* Find listArrayIndex for the tokenId..*/
            uint256 _listIndex =  listArrayIndexByTokenId(_tokenId);

            delete listingsArray[_listIndex];//.sold = true;

            emit ListingDeleted(_tokenId, tokenIdToListing[_contractAddress][_tokenId].contractAddress);
        }
    }


    function getCreatorShare(address contractAddress, uint256 tokenId, uint256 tokenPrice) private returns (address, uint256)   
    {
        // Check if Royalty Interface is supported
        if(ERC165Checker.supportsInterface(contractAddress,type(IERC2981).interfaceId)){

        // Get the creator share
        (address creatorAddress, uint256 creatorShare) = NebulaDropsCollectible(contractAddress).royaltyInfo(tokenId, tokenPrice);

        // // If the creator is also the seller, then do not explicitely return a creator share
        // if(creatorAddress == sellerAddress)
        // {
        // creatorShare = 0;
        // }

        // Return the creatorShare
        return (creatorAddress,creatorShare);
        
        }
        else{
        // If Royalty interface is not supported then we cannot provide a creator share
        return (address(0),0);
        }
    }


    function  viewAllListings() public view returns (NFTListing[] memory) {
        return listingsArray;
    }


    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (NFTListing[] memory) {

        uint256 itemCount=0;  
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < listingsArray.length; i++) {
          if(listingsArray[i].owner == msg.sender)
             { 
                 itemCount += 1;         
             }
        } 

        NFTListing[] memory items = new NFTListing[](itemCount);
        for (uint256 index = 0; index < listingsArray.length; index++) {  
          if(listingsArray[index].owner == msg.sender)
             { 
                NFTListing storage currentItem = listingsArray[index];
                items[currentIndex] = currentItem;
                currentIndex += 1;
             }            
        }
        return items;
    }



    function fetchStoredTokenDetail(address _contractAddress,uint256 _id) public view returns(NFTListing memory) {
        return tokenIdToListing[_contractAddress][_id];
    }
 


    function  fetchAllMarketItems(address _contractAddress) public view returns (NFTListing[] memory)
     {
        uint256 itemCount=0;  
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < listingsArray.length; i++) {
          if(listingsArray[i].contractAddress == _contractAddress)
             {
                 itemCount += 1;               
            }
        }        

        NFTListing[] memory items = new NFTListing[](itemCount);
        for (uint256 index = 0; index < listingsArray.length; index++) {  
          if(listingsArray[index].contractAddress == _contractAddress)
             { 
                NFTListing storage currentItem = listingsArray[index];
                items[currentIndex] = currentItem;
                currentIndex += 1;
             }            
        }
        return items;
    }
 


    /* Returns all unsold market items */
    function fetchAvailableMarketItems(address _contractAddress) public view returns (NFTListing[] memory) {
     
        uint256 itemCount=0;  
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < listingsArray.length; i++) {
          if(listingsArray[i].contractAddress == _contractAddress && listingsArray[i].sold == false)
            { itemCount += 1; }
        }
      
        NFTListing[] memory items = new NFTListing[](itemCount);
        for (uint256 index = 0; index < listingsArray.length; index++) {
          if(listingsArray[index].contractAddress == _contractAddress && listingsArray[index].sold == false)
             { 
                NFTListing storage currentItem = listingsArray[index];
                items[currentIndex] = currentItem;
                currentIndex += 1;
             }            
        }
        return items;
    }



    function listArrayIndexByTokenId(uint256 _tokenId) public view returns (uint256)
    {
        for (uint256 index = 0; index < listingsArray.length; index++) {
                if(listingsArray[index].tokenId ==_tokenId)
                {
                return index;
                }
            }
        return 1000000; /* non-existing token...*/
    }


    // function viewStats() public view returns(Stats memory) {
    //     return Stats(_volume, _numOfTxs.current());
    // }

    function withdrawFees() public onlyOwner payable nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

}