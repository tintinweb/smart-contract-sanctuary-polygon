/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/MarketPlace.sol


pragma solidity ^0.8.0;









// interface ERC721IF {
//     function ownerOf(uint256) external view returns (address);
// }

interface stakableInterface {
    function walletOfOwner(address _owner) external view returns (uint256[] memory); 
}

contract CrazyBearsMarketplaceV1 is ERC1155Holder, IERC721Receiver, Ownable, ReentrancyGuard {

    struct Item {
        address id;
        uint8 itemType; // 1: ERC721, 2: ERC1155, 3: WL spots, 4: Raffle Entry, 999: Other
        string name;
        string imageUrl;
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 totalSupply;
        uint256 purchased;
        uint256 costId;
        uint256 price;
        bool active;
    }

    struct Cost {
        uint256 id;
        address contractAddress;
        uint256 tokenId;
        uint8 costType; // 1: ERC1155, 2: ERC20
    }

    // event Staked(address indexed user, uint256 tokenId, uint256 fieldId, uint timestamp);

    using SafeMath for uint256;
    // address public stakableContractAddress;
    // IERC721 stakeableContract;
    // bool public paused = false;
    // mapping(uint => StakedToken) tokenById;
    // mapping(address => mapping(uint => uint[])) tokenByUser;
    // mapping(uint => StakingField) fields;
    // mapping(uint => FieldReward) rewards;
    // mapping(bytes32 => uint) tokenGrades;
    // uint hashLoop = 1;
    // BoostItem boostItem;

    // Reward Boost.
    // uint public ogBoostPercent;
    // uint public balanceBoostCount1;
    // uint public balanceBoostPercent1;
    // uint public balanceBoostCount2;
    // uint public balanceBoostPercent2;
    // uint public balanceBoostCount3;
    // uint public balanceBoostPercent3;
    // mapping(address => mapping(uint256 => TokenModel)) erc721tokens;
    // mapping(address => mapping(uint256 => TokenModel)) erc1155tokens;

    uint randNonce = 0;
    Item[] public items;
    mapping(address => Item) public itemsById;
    mapping(uint256 => Cost) public costs;
    mapping(address => address[]) public purchasedUsers;

    constructor() {
        
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        // TokenModel memory token = TokenModel(0, operator, from, tokenId, 1);
        // erc721tokens[operator][tokenId] = token;
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual override returns(bytes4) {
        // if (erc1155tokens[operator][tokenId].tokenId != 0 && erc1155tokens[operator][tokenId].contractAddress != address(0)) {
        //     erc1155tokens[operator][tokenId].amount = erc1155tokens[operator][tokenId].amount + amount;
        //     erc1155tokens[operator][tokenId].from = from;
        // } else {
        //     TokenModel memory token = TokenModel(1, operator, from, tokenId, amount);
        //     erc1155tokens[operator][tokenId] = token;
        // }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) public virtual override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function withdraw721Token(address _contractAddress, uint256 _tokenId) public onlyOwner
    {
        IERC721(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function withdraw1155Token(address _contractAddress, uint256 _tokenId, uint256 _amount) public onlyOwner
    {
        IERC1155(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
    }

    function getItemId() internal returns(address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, ++randNonce)))));
    }

    function setItemProps(address _itemId, string memory _name, string memory _imageUrl) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "This item does not exits.");
        uint index;
        for (index = 0; index < items.length; index ++){
            if (items[index].id == _itemId) {
                break;
            }
        }
        require(index < items.length, "NFT with that ID was not found.");
        item.name = _name;
        item.imageUrl = _imageUrl;

        items[index].name = _name;
        items[index].imageUrl = _imageUrl;
    }

    function setItemActive(address _itemId, bool _active) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "This item does not exits.");
        uint index;
        for (index = 0; index < items.length; index ++){
            if (items[index].id == _itemId) {
                break;
            }
        }
        require(index < items.length, "NFT with that ID was not found.");
        item.active = _active;
        items[index].active = _active;
    }

    function setItemPrice(address _itemId, uint256 _price) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "This item does not exits.");
        uint index;
        for (index = 0; index < items.length; index ++){
            if (items[index].id == _itemId) {
                break;
            }
        }
        require(index < items.length, "NFT with that ID was not found.");
        item.price = _price;
        items[index].price = _price;
    }

    function setItemCost(address _itemId, uint256 _costId) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "This item does not exits.");
        uint index;
        for (index = 0; index < items.length; index ++){
            if (items[index].id == _itemId) {
                break;
            }
        }
        require(index < items.length, "NFT with that ID was not found.");
        item.costId = _costId;
        items[index].costId = _costId;
    }

    function setCost(uint256 _costId, uint8 _costType, address _contractAddress, uint256 _tokenId) public onlyOwner {
        costs[_costId] = Cost(_costId, _contractAddress, _tokenId, _costType);
    }

    function add721TokenItem(string memory _name, string memory _imageUrl, address _contractAddress, uint256 _tokenId, uint256 _costId, uint256 _price, bool _active) public onlyOwner {
        IERC721 nftContract = IERC721(_contractAddress);
        require(nftContract.ownerOf(_tokenId) == address(this), "There is no target token in the contract. Please transfer the token to this contract first.");
        address itemId = getItemId();
        Item memory newItem = Item(itemId, 1, _name, _imageUrl, _contractAddress, _tokenId, 1, 1, 0, _costId, _price, _active);
        itemsById[itemId] = newItem;
        items.push(newItem);
    }

    function add1155TokenItem(string memory _name, string memory _imageUrl, address _contractAddress, uint256 _tokenId, uint256 _costId, uint256 _amount, uint256 _totalSupply, uint256 _price, bool _active) public onlyOwner {
        IERC1155 nftContract = IERC1155(_contractAddress);
        require(nftContract.balanceOf(address(this), _tokenId) >= _amount.mul(_totalSupply), "There is no target token in the contract. Please transfer the token to this contract first.");
        address itemId = getItemId();
        Item memory newItem = Item(itemId, 2, _name, _imageUrl, _contractAddress, _tokenId, _amount, _totalSupply, 0, _costId, _price, _active);
        itemsById[itemId] = newItem;
        items.push(newItem);
    }

    function removeItem(address _itemId) public onlyOwner {
        Item storage item = itemsById[_itemId];
        require(item.id != address(0), "This item does not exists.");

        uint index;
        for (index = 0; index < items.length; index ++){
            if (items[index].id == _itemId) {
                break;
            }
        }
        require(index < items.length, "NFT with that ID was not found.");
        items[index] = items[(items.length - 1)];
        items.pop();

        if (item.itemType == 1) {
            IERC721 nftContract = IERC721(item.contractAddress);
            if (nftContract.ownerOf(item.tokenId) == address(this)) {
                withdraw721Token(item.contractAddress, item.tokenId);
            }
        } else if (item.itemType == 2) {
            IERC1155 nftContract = IERC1155(item.contractAddress);
            if (nftContract.balanceOf(address(this), item.tokenId) >= item.amount) {
                withdraw1155Token(item.contractAddress, item.tokenId, item.amount);
            }
        }

        item.id = address(0);
        item.name = "";
        item.imageUrl = "";
        item.contractAddress = address(0);
        item.tokenId = 0;
        item.amount = 0;
        item.purchased = 0;
        item.active = false;
    }

    function isValidItem(address _itemId) internal view {
        Item memory item = itemsById[_itemId];
        require(item.id != address(0), "This item does not exists.");
        require(item.itemType != 0, "This item does not exists.");
        require(item.costId != 0, "This item does not exists.");
        require(item.active, "This item does not exists.");
        require(item.purchased >= item.amount, "Already sold out");
    }

    function purchase(address _itemId) public {
        isValidItem(_itemId);
        Item storage item = itemsById[_itemId];
        Cost memory cost = costs[item.costId];
        require(cost.id != 0 && cost.costType != 0, "Invalid cost.");
        uint256 costAmount = item.price;
        require(costAmount > 0, "Invalid cost.");
        if (cost.costType == 1) {
            IERC1155 costContract = IERC1155(cost.contractAddress);
            require(costContract.isApprovedForAll(msg.sender, address(this)), "Is not approved for all.");
            require(costContract.balanceOf(msg.sender, cost.tokenId) >= costAmount, "The balance is not sufficient.");
            costContract.safeTransferFrom(msg.sender, address(this), cost.tokenId, costAmount, "");
        } else {
            IERC20 costContract = IERC20(cost.contractAddress);
            require(costContract.balanceOf(msg.sender) >= costAmount, "The balance is not sufficient.");
            require(costContract.allowance(msg.sender, address(this)) >= costAmount, "Is not approved for cost amount.");
            costContract.transferFrom(msg.sender, address(this), costAmount);
        }

        if (item.itemType == 1) {
            IERC721(item.contractAddress).safeTransferFrom(address(this), msg.sender, item.tokenId);
        } else if (item.itemType == 2) {
            IERC1155(item.contractAddress).safeTransferFrom(address(this), msg.sender, item.tokenId, 1, "");
        }
        item.purchased++;
        purchasedUsers[_itemId].push(msg.sender);
    }

    // function pause() public onlyOwner {
    //     paused = true;
    // }

    // function unpause() public onlyOwner {
    //     paused = false;
    // }

    // function isValidField(uint _fieldId) public view returns (bool) {
    //     return fields[_fieldId].fieldId > 0;
    // }

    // function isActiveField(uint _fieldId) public view returns (bool) {
    //     return fields[_fieldId].active;
    // }

    // function toBytes(uint256 x) internal pure returns (bytes memory b) {
    //     b = new bytes(32);
    //     assembly { mstore(add(b, 32), x) }
    // }

    // function toBytes(bytes32 x) internal pure returns (bytes memory b) {
    //     b = new bytes(32);
    //     assembly { mstore(add(b, 32), x) }
    // }

    // function getTokenHash (uint256 _tokenId) internal view returns (bytes32) {
    //     bytes memory tokenIdByte = toBytes(_tokenId);
    //     bytes32 hash = keccak256(tokenIdByte);
    //     for (uint i = 0; i < hashLoop; i++) {
    //         bytes memory b = toBytes(hash);
    //         hash = keccak256(b);
    //     }
    //     return hash;
    // }

    // function setTokenGrades(uint256[] memory _tokenIds, uint8[] memory _grade, uint256 _hashLoop) public onlyOwner {
    //     require(_tokenIds.length == _grade.length, "Array length does not match.");
    //     require(_hashLoop > 0, "Invalid hash loop value.");
    //     hashLoop = _hashLoop;
    //     uint index;
    //     for (index = 0; index < _tokenIds.length; index ++) {
    //         bytes32 hash = getTokenHash(_tokenIds[index]);
    //         tokenGrades[hash] = _grade[index];
    //     }
    // }

    // function getTokenGrade(uint256 _tokenId) internal view returns (uint) {
    //     bytes32 hash = getTokenHash(_tokenId);
    //     return tokenGrades[hash];
    // }

    // function setReward(uint256 _rewardId, address _contractAddress, uint256 _tokenId, uint _common, uint _rare, uint _epic, uint _legendary, uint _special) public onlyOwner {
    //     FieldReward memory reward;
    //     reward.rewardId = _rewardId;
    //     reward.contractAddress = _contractAddress;
    //     reward.tokenId = _tokenId;
    //     reward.common = _common;
    //     reward.rare = _rare;
    //     reward.epic = _epic;
    //     reward.legendary = _legendary;
    //     reward.special = _special;
    //     rewards[_rewardId] = reward;
    // }

    // function getRewardTokenId(uint256 _fieldId) public view returns (uint) {
    //     uint rewardId = fields[_fieldId].rewardId;
    //     if (rewardId == 0) {
    //         return 0;
    //     }
    //     return rewards[rewardId].tokenId;
    // }

    // function getRewardAmount(uint256 _fieldId, uint _grade) public view returns (uint) {
    //     uint rewardId = fields[_fieldId].rewardId;
    //     if (rewardId == 0) {
    //         return 0;
    //     }
    //     if (_grade == 4) {
    //         return rewards[rewardId].special;
    //     }
    //     if (_grade == 3) {
    //         return rewards[rewardId].legendary;
    //     }
    //     if (_grade == 2) {
    //         return rewards[rewardId].epic;
    //     }
    //     if (_grade == 1) {
    //         return rewards[rewardId].rare;
    //     }
    //     return rewards[rewardId].common;
    // }

    // function setField(uint256 _fieldId, bool _active, uint256 _rewardId) public onlyOwner {
    //     require(_fieldId > 0, "Invalid field ID.");
    //     StakingField memory field;
    //     field.fieldId = _fieldId;
    //     field.active = _active;
    //     field.rewardId = _rewardId;
    //     fields[_fieldId] = field;
    // }

    // function setFieldActive(uint256 _fieldId, bool _active) public onlyOwner {
    //     require(fields[_fieldId].fieldId != 0, "That staking field is not exists.");
    //     fields[_fieldId].active = _active;
    // }

    // function setStakable(address _contractAddress) public onlyOwner {
    //     stakableContractAddress = _contractAddress;
    //     stakeableContract = IERC721(stakableContractAddress);
    // }

    // function endField(uint _fieldId) public onlyOwner {
    //     fields[_fieldId].endTime = block.timestamp;
    //     fields[_fieldId].active = false;
    // }

    // function setEndTime(uint _fieldId, uint _endTime) public onlyOwner {
    //     fields[_fieldId].endTime = _endTime;
    // }

    // function endTime(uint _fieldId) public view returns (uint) {
    //     return fields[_fieldId].endTime;
    // }

    // function setBalanceBoost(uint _balanceBoostCount1, uint _balanceBoostPercent1, uint _balanceBoostCount2, uint _balanceBoostPercent2, uint _balanceBoostCount3, uint _balanceBoostPercent3) public onlyOwner {
    //     balanceBoostCount1 = _balanceBoostCount1;
    //     balanceBoostCount2 = _balanceBoostCount2;
    //     balanceBoostCount3 = _balanceBoostCount3;
    //     balanceBoostPercent1 = _balanceBoostPercent1;
    //     balanceBoostPercent2 = _balanceBoostPercent2;
    //     balanceBoostPercent3 = _balanceBoostPercent3;
    // }

    // function setOgBoost(uint _ogBoostPercent) public onlyOwner {
    //     ogBoostPercent = _ogBoostPercent;
    // }

    // function setBoostItem(address _contractAddress, uint[] memory _tokenIds, uint _boostPercent) public onlyOwner {
    //     boostItem.contractAddress = _contractAddress;
    //     boostItem.tokenIds = _tokenIds;
    //     boostItem.boostPercent = _boostPercent;
    // }

    // function getBoostItemPercent() public view returns (uint) {
    //     return boostItem.boostPercent;
    // }

    // function _stake(address _from, uint256 _tokenId, uint256 _fieldId) internal returns (StakedToken memory) {
    //     require(!paused, "the contract is paused");
    //     require(isValidField(_fieldId), "Invalid field");
    //     require(isActiveField(_fieldId), "Inactive field");
    //     require(fields[_fieldId].endTime == 0 || fields[_fieldId].endTime > block.timestamp, "Ended field");
    //     require(stakeableContract.ownerOf(_tokenId) != address(this), "Token is already staked in this contract");
    //     stakeableContract.safeTransferFrom(_from, address(this), _tokenId);
    //     require(stakeableContract.ownerOf(_tokenId) == address(this), "Failed to take possession of NFT");

    //     StakedToken memory staking;
    //     staking.tokenId = _tokenId;
    //     staking.user = _from;
    //     staking.since = block.timestamp;
    //     staking.fieldId = _fieldId;

    //     tokenById[_tokenId] = staking;
    //     tokenByUser[_from][_fieldId].push(_tokenId);
    //     return staking;
    // }

    // function stake(uint256 _tokenId, uint256 _fieldId) public {
    //     require(stakeableContract.isApprovedForAll(msg.sender, address(this)), "You need to approval for all tokens.");
    //     StakedToken memory staked = _stake(msg.sender, _tokenId, _fieldId);
    //     emit Staked(msg.sender, _tokenId, _fieldId, staked.since);
    // }

    // function stakeAll(uint256 _fieldId) public {
    //     require(stakeableContract.isApprovedForAll(msg.sender, address(this)), "You need to approval for all tokens.");
    //     uint[] memory _tokens = stakableInterface(stakableContractAddress).walletOfOwner(msg.sender);
    //     uint _tNum = _tokens.length;
    //     StakedToken memory staked;
    //     for(uint i=0; i < _tNum; i++){
    //         if (!isStaked(_tokens[i])) {
    //             staked = _stake(msg.sender, _tokens[i], _fieldId);
    //         }
    //     }
    //     emit StakedAll(msg.sender, _tokens, _fieldId, staked.since);
    // }

    // function batchStake(uint256[] memory _tokenIds, uint256[] memory _fieldIds) public {
    //     require(stakeableContract.isApprovedForAll(msg.sender, address(this)), "You need to approval for all tokens.");
    //     require(_tokenIds.length == _fieldIds.length, "Array length does not match.");
    //     uint _tNum = _tokenIds.length;
    //     StakedToken memory staked;
    //     for(uint i=0; i < _tNum; i++){
    //         if (!isStaked(_tokenIds[i])) {
    //             staked = _stake(msg.sender, _tokenIds[i], _fieldIds[i]);
    //             emit Staked(msg.sender, _tokenIds[i], _fieldIds[i], staked.since);
    //         }
    //     }
    // }

    // function getOwner(uint256 _tokenID) public view returns (address){
    //     return tokenById[_tokenID].user;
    // }

    // function isStaked(uint256 _tokenID) public view returns (bool){
    //     return tokenById[_tokenID].user != address(0);
    // }

    // function isItemBoosted(address _owner) public view returns (bool) {
    //     if (boostItem.contractAddress == address(0)) {
    //         return false;
    //     }
    //     for (uint i = 0; i < boostItem.tokenIds.length; i ++){
    //         if (IERC721(boostItem.contractAddress).ownerOf(boostItem.tokenIds[i]) == _owner) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // function getTokenStakedField(uint256 _tokenID) public view returns (uint){
    //     return tokenById[_tokenID].fieldId;
    // }

    // function getLastUpdated(uint256 _tokenID) public view returns (uint){
    //     return tokenById[_tokenID].since;
    // }

    // function getTokensOfOwner(address _owner, uint _fieldId) public view returns ( uint [] memory){
    //     uint[] memory ownersTokens;
    //     ownersTokens = tokenByUser[_owner][_fieldId];      
    //     return ownersTokens;
    // }

    // function getRewardFromTokenId(uint256 _tokenID) internal view returns (FieldReward memory) {
    //     uint fieldId = tokenById[_tokenID].fieldId;
    //     StakingField memory field = fields[fieldId];
    //     uint rewardId = field.rewardId;
    //     FieldReward memory reward = rewards[rewardId];
    //     return reward;
    // }

    // function checkReward(uint256 _tokenId) public view returns (uint) {
    //     address user = tokenById[_tokenId].user;
    //     if (user == address(0)) {
    //         return 0;
    //     }
    //     FieldReward memory reward = getRewardFromTokenId(_tokenId);
    //     uint tokenGrade = getTokenGrade(_tokenId);
    //     uint amountPerDay = reward.common;
    //     if (tokenGrade == 1) {
    //         amountPerDay = reward.rare;
    //     } else if (tokenGrade == 2) {
    //         amountPerDay = reward.epic;
    //     } else if (tokenGrade == 3) {
    //         amountPerDay = reward.legendary;
    //     } else if (tokenGrade == 4) {
    //         amountPerDay = reward.special;
    //     }

    //     uint fieldId = tokenById[_tokenId].fieldId;
    //     uint timeNow = block.timestamp;
    //     uint timeSince = tokenById[_tokenId].since;
    //     if (fields[fieldId].endTime > 0) {
    //         timeNow = fields[fieldId].endTime;
    //         if (timeNow <= timeSince) {
    //             return 0;
    //         }
    //     }
    //     uint passedSec = timeNow.sub(timeSince);
    //     uint passedDays = passedSec.div(86400);
    //     uint tokenEarned = passedDays.mul(amountPerDay);

    //     // OG Boost.
    //     if (_tokenId <= 500 && ogBoostPercent > 0) {
    //         tokenEarned = tokenEarned.mul(ogBoostPercent);
    //         tokenEarned = tokenEarned.div(100);
    //     }

    //     // Balance Boost.
    //     uint stakingCount = tokenByUser[user][fieldId].length;
    //     if (stakingCount >= balanceBoostCount3) {
    //         tokenEarned = tokenEarned.mul(balanceBoostPercent3);
    //         tokenEarned = tokenEarned.div(100);
    //     } else if (stakingCount >= balanceBoostCount2) {
    //         tokenEarned = tokenEarned.mul(balanceBoostPercent2);
    //         tokenEarned = tokenEarned.div(100);
    //     } else if (stakingCount >= balanceBoostCount1) {
    //         tokenEarned = tokenEarned.mul(balanceBoostPercent1);
    //         tokenEarned = tokenEarned.div(100);
    //     }

    //     // Item Boost.
    //     if (boostItem.contractAddress != address(0)) {
    //         for (uint i = 0; i < boostItem.tokenIds.length; i ++){
    //             if (IERC721(boostItem.contractAddress).ownerOf(boostItem.tokenIds[i]) == user) {
    //                 tokenEarned = tokenEarned.mul(boostItem.boostPercent);
    //                 tokenEarned = tokenEarned.div(100);
    //                 break;
    //             }
    //         }
    //     }

    //     return tokenEarned;
    // }

    // function checkFieldReward(address _owner, uint256 _fieldId) public view returns (uint256) {
    //     uint256[] memory tokenIds = tokenByUser[_owner][_fieldId];
    //     uint256 total = 0;
    //     for (uint i = 0; i < tokenIds.length; i ++){
    //         uint256 tokenID = tokenIds[i];
    //         total += checkReward(tokenID);
    //     }
    //     return total;
    // }

    // function receiveReward(uint256 _tokenID) nonReentrant public {
    //     require(!paused, "the contract is paused");
    //     require(tokenById[_tokenID].user == msg.sender, "That NFT does not belong to you.");
    //     uint fieldId = tokenById[_tokenID].fieldId;
    //     StakingField memory field = fields[fieldId];
    //     uint rewardId = field.rewardId;
    //     FieldReward memory reward = rewards[rewardId];
    //     uint rewardTokenId = reward.tokenId;
    //     IERC1155 rewardContract = IERC1155(reward.contractAddress);

    //     uint earned = checkReward(_tokenID);
    //     if (earned > 0) {
    //         if (rewardContract.balanceOf(address(this), rewardTokenId) <= earned) {
    //             rewardInterface(reward.contractAddress).mint(address(this), rewardTokenId, (earned + 1000));
    //         }
    //         rewardContract.safeTransferFrom(address(this), msg.sender, rewardTokenId, earned, '');
    //     }
    //     tokenById[_tokenID].since = block.timestamp;
    // }

    // function unstake(uint256 _tokenID) public {
    //     require(!paused, "the contract is paused");
    //     receiveReward(_tokenID);
    //     _unstake(_tokenID);
    // }

    // function _unstake(uint256 _tokenID) internal {
    //     address user = tokenById[_tokenID].user;
    //     StakedToken storage staking = tokenById[_tokenID];
    //     uint256 fieldId = staking.fieldId;
    //     uint256[] storage stakedNFTs = tokenByUser[user][fieldId];
    //     uint index;
    //     for (index = 0; index < stakedNFTs.length; index ++){
    //         if (stakedNFTs[index] == _tokenID) {
    //             break;
    //         }
    //     }
    //     require(index < stakedNFTs.length, "NFT with that ID was not found.");
    //     stakedNFTs[index] = stakedNFTs[(stakedNFTs.length - 1)];
    //     stakedNFTs.pop();
    //     staking.user = address(0);
    //     stakeableContract.safeTransferFrom(address(this), user, _tokenID);
    //     emit Unstaked(user, _tokenID, fieldId, block.timestamp);
    // }

    // function batchReceiveReward(uint256[] memory _tokenIds) public {
    //     for (uint i = 0; i < _tokenIds.length; i ++){
    //         uint256 tokenID = _tokenIds[i];
    //         receiveReward(tokenID);
    //     }
    // }

    // function batchUnstake(uint256[] memory _tokenIds) public {
    //     for (uint i = 0; i < _tokenIds.length; i ++){
    //         receiveReward(_tokenIds[i]);
    //     }
    //     for (uint i = 0; i < _tokenIds.length; i ++){
    //         _unstake(_tokenIds[i]);
    //     }
    // }

    // function receiveRewardAll(address _owner, uint256 _fieldId) public {
    //     uint256[] memory tokenIds = tokenByUser[_owner][_fieldId];
    //     for (uint index = 0; index < tokenIds.length; index ++){
    //         uint _tokenID = tokenIds[index]; 
    //         receiveReward(_tokenID);
    //     }
    // }

    // function unstakeAll(uint256 _fieldId) public {
    //     receiveRewardAll(msg.sender, _fieldId);
    //     sendBackAllTokens(msg.sender, _fieldId);
    // }

    // function mintReward(uint256 rewardId, uint256 amount) public onlyOwner {
    //     FieldReward memory reward = rewards[rewardId];
    //     uint rewardTokenId = reward.tokenId;
    //     rewardInterface(reward.contractAddress).mint(address(this), rewardTokenId, amount);
    // }

    // function emergencyReturn(address _owner, uint _fieldId) public onlyOwner {      
    //     sendBackAllTokens(_owner, _fieldId);
    // }

    // function sendBackAllTokens(address _owner, uint _fieldId) internal {
    //     uint256[] storage stakedNFTs = tokenByUser[_owner][_fieldId];
    //     while (stakedNFTs.length > 0) {
    //         uint index = stakedNFTs.length - 1;
    //         uint _tokenID = stakedNFTs[index]; 
    //         StakedToken storage staking = tokenById[_tokenID];
    //         stakedNFTs.pop();
    //         staking.user = address(0);
    //         stakeableContract.safeTransferFrom(address(this), msg.sender, _tokenID); 
    //     }
    // }
}