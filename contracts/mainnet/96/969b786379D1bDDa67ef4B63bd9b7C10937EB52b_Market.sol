// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

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
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Market
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IAdminPanel.sol';
import './interfaces/IMarket.sol';
import './NFTAssist.sol';
import './interfaces/IWETH.sol';

contract Market is IMarket, Ownable, NFTAssist, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public WETH;
    IAdminPanel public adminPanel;

    Offer[] private _offers;
    mapping(address => uint256[]) private _userOffers;
    mapping(address => bool) public validTokens;

    event OfferCreated(
        uint256 indexed timestamp,
        address indexed owner,
        uint256 indexed offerId
    );
    event OfferCanceled(
        uint256 indexed timestamp,
        address indexed owner,
        uint256 indexed offerId
    );
    event SellOfferAccepted(
        uint256 indexed timestamp,
        address seller,
        address buyer,
        uint256 indexed offerId
    );
    event BuyOfferAccepted(
        uint256 indexed timestamp,
        address seller,
        address buyer,
        uint256 indexed offerId
    );
    event OfferPriceChanged(
        uint256 indexed timestamp,
        uint256 oldPrice,
        uint256 newPrice,
        uint256 indexed offerId
    );
    event FulFill(
        uint256 indexed timestamp,
        uint256 indexed sellOfferId,
        uint256 indexed buyOfferId
    );

    constructor(address WETH_, address adminPanel_) {
        WETH = WETH_;
        adminPanel = IAdminPanel(adminPanel_);
    }

    modifier offerExists(uint256 offerId) {
        require(_offers[offerId].id < _offers.length, 'Offer does not exist');
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    /// @dev Creates a Buy offer and sets it's info for selected nft address and token id
    /// @param nft address of nft to buy
    /// @param tokenId token id of nft to buy
    /// @param price_ suggested price to buy nft
    /// @param token_ token address of suggested tokens amount
    function createBuyOffer(
        address nft,
        uint256 tokenId,
        uint256 price_,
        address token_
    ) external payable nonReentrant {
        require(adminPanel.validTokens(token_), 'Not allowed token selected');
        require(adminPanel.belongsToWhitelist(nft), 'NFT does not belong to whitelist');
        if (msg.value > 0) {
            if (msg.value < price_) revert NotEnoughETH();
            uint256 remain = msg.value - price_;
            if (remain > 0) payable(msg.sender).transfer(remain);
            require(token_ == WETH, 'Select weth as pay token, if you buy with eth');
            IWETH(payable(WETH)).deposit{value: price_}();
        } else {
            IERC20(token_).safeTransferFrom(msg.sender, address(this), price_);
        }
        Offer memory offer = Offer({
            id: _offers.length,
            nft: NFT({nftContract: nft, tokenId: tokenId}),
            owner: msg.sender,
            token: token_,
            timeStarted: block.timestamp,
            price: price_,
            status: Status.PENDING,
            direction: Direction.BUY
        });
        _offers.push(offer);
        _userOffers[msg.sender].push(offer.id);
        emit OfferCreated(block.timestamp, msg.sender, _offers.length - 1);
    }

    /// @dev Creates a sell offer and sets it for selected nft address and id only by nft owner
    /// @param nft staking nft address
    /// @param tokenId staking nft token id
    /// @param price_ amount of nft cost in selected token
    /// @param token_ selected token to pay nft seller
    function createSellOffer(
        address nft,
        uint256 tokenId,
        uint256 price_,
        address token_
    ) external {
        _checkOwnership(nft, tokenId);
        require(adminPanel.validTokens(token_), 'Not allowed token selected');
        require(adminPanel.belongsToWhitelist(nft), 'NFT does not belong to whitelist');
        _transferNFT(msg.sender, address(this), nft, tokenId);
        Offer memory offer = Offer({
            id: _offers.length,
            nft: NFT({nftContract: nft, tokenId: tokenId}),
            owner: msg.sender,
            token: token_,
            timeStarted: block.timestamp,
            price: price_,
            status: Status.PENDING,
            direction: Direction.SELL
        });
        _offers.push(offer);
        _userOffers[msg.sender].push(offer.id);
        emit OfferCreated(block.timestamp, msg.sender, _offers.length - 1);
    }

    /// @dev Cancel the offer handling all directoins by setting direction to null
    /// @param offerId id of the offer to cancel
    function cancelOffer(uint256 offerId) external offerExists(offerId) nonReentrant {
        Offer storage offer = _offers[offerId];

        require(offer.owner == msg.sender, 'Caller is not the creator of the offer');
        require(offer.status == Status.PENDING, 'Offer is not valid');
        offer.status = Status.CANCELED;

        if (offer.direction == Direction.BUY) {
            if (offer.token == address(WETH)) {
                IWETH(payable(WETH)).withdraw(offer.price);
                payable(msg.sender).transfer(offer.price);
            } else {
                IERC20(offer.token).transfer(msg.sender, offer.price);
            }
        } else if (offer.direction == Direction.SELL) {
            _transferNFT(
                address(this),
                msg.sender,
                offer.nft.nftContract,
                offer.nft.tokenId
            );
        } else {
            revert NotValidOffer();
        }

        emit OfferCanceled(block.timestamp, msg.sender, offer.id);
    }

    /// @dev Internal function to realize general sell offer acception:
    /// receives tokens, changes the offer status, transfers nft to buyer
    /// and calls internal fee transfering function
    /// @param offerId id of the sell offer to accept
    /// @param needTransfer internal flag, which shows does token tranfer needed,
    /// if nft is buying by the native is equal to false, else true
    /// @return token token address to pay nft owner
    /// @return fee the fee function return variable,
    /// profit of nft seller in selected token with taking account of fee
    /// @return owner the sell offer owner, also nft owner, who gets profit
    function _acceptSellOffer(uint256 offerId, bool needTransfer)
        internal
        returns (
            address,
            uint256,
            address
        )
    {
        Offer storage offer = _offers[offerId];
        require(offer.direction == Direction.SELL, 'Could not buy not selling nft');
        require(offer.status == Status.PENDING, 'Not valid offer');
        if (needTransfer)
            IERC20(offer.token).safeTransferFrom(msg.sender, address(this), offer.price);

        offer.status = Status.ACCEPTED;
        _transferNFT(address(this), msg.sender, offer.nft.nftContract, offer.nft.tokenId);
        emit SellOfferAccepted(block.timestamp, offer.owner, msg.sender, offerId);
        return (offer.token, _fee(offer.price, offer.token), offer.owner);
    }

    /// @dev Buying nft by the function caller only with selected token and price
    /// @param offerId id of the sell offer to accept
    function acceptSellOffer(uint256 offerId) external offerExists(offerId) {
        (address token, uint256 profit, address owner_) = _acceptSellOffer(offerId, true);
        IERC20(token).transfer(owner_, profit);
    }

    /// @dev Buying nft by the function caller only with ETH by selected price
    /// @param offerId id of the sell offer to accept
    function acceptSellOfferETH(uint256 offerId)
        external
        payable
        offerExists(offerId)
        nonReentrant
    {
        Offer memory offer = _offers[offerId];
        require(offer.token == WETH, 'This nft selling only for tokens');
        if (msg.value < offer.price) revert NotEnoughETH();
        uint256 remain = msg.value - offer.price;

        if (remain > 0) payable(msg.sender).transfer(remain);

        IWETH(payable(WETH)).deposit{value: offer.price}();
        (, uint256 profit, ) = _acceptSellOffer(offerId, false);
        IWETH(payable(WETH)).withdraw(profit);
        payable(offer.owner).transfer(profit);
    }

    /// @dev Sells nft to by offer owner with selected token and price
    /// @param offerId if of the buy offer to accept
    function acceptBuyOffer(uint256 offerId) external offerExists(offerId) nonReentrant {
        Offer storage offer = _offers[offerId];
        require(offer.direction == Direction.BUY, 'This is not buy offer');
        require(offer.status == Status.PENDING, 'Not valid offer');
        offer.status = Status.ACCEPTED;
        _checkOwnership(offer.nft.nftContract, offer.nft.tokenId);
        _transferNFT(msg.sender, offer.owner, offer.nft.nftContract, offer.nft.tokenId);
        if (offer.token != WETH) {
            IERC20(offer.token).transfer(msg.sender, _fee(offer.price, offer.token));
        } else {
            uint256 profit = _fee(offer.price, offer.token);
            IWETH(payable(WETH)).withdraw(profit);
            payable(msg.sender).transfer(profit);
        }
        emit BuyOfferAccepted(block.timestamp, offer.owner, msg.sender, offerId);
    }

    /// @dev if the offer is buy offer, then receives missing amount
    /// or sends extra tokens to offer owner, than in both ways changes offer price
    /// @param offerId id of the offer to change price
    /// @param newPrice new price of nft to buy or sell
    function changeOfferPrice(uint256 offerId, uint256 newPrice)
        external
        payable
        offerExists(offerId)
        nonReentrant
    {
        Offer storage offer = _offers[offerId];
        require(offer.owner == msg.sender, 'Caller is not the creator of the offer');
        require(offer.price != newPrice, 'New price is equal to old');
        uint256 oldPrice = offer.price;
        offer.price = newPrice;
        if (msg.value > 0) IWETH(payable(WETH)).deposit{value: msg.value}();
        if (offer.direction == Direction.BUY) {
            if (oldPrice > newPrice) {
                if (offer.token == WETH) {
                    IWETH(payable(WETH)).withdraw(oldPrice - newPrice);
                    payable(msg.sender).transfer(oldPrice - newPrice);
                } else {
                    IERC20(offer.token).transfer(msg.sender, oldPrice - newPrice);
                }
            } else {
                if (offer.token == WETH) {
                    if (msg.value < newPrice - oldPrice) revert NotEnoughETH();
                    uint256 remain = msg.value - (newPrice - oldPrice);
                    if (remain > 0) {
                        IWETH(payable(WETH)).withdraw(remain);
                        payable(msg.sender).transfer(remain);
                    }
                } else {
                    IERC20(offer.token).safeTransferFrom(
                        msg.sender,
                        address(this),
                        newPrice - oldPrice
                    );
                }
            }
        }
        emit OfferPriceChanged(block.timestamp, oldPrice, newPrice, offer.id);
    }

    /// @dev Allows to fulfill sell and buy offer with the same nft and parameters
    /// the function caller gets diff between sell and buy offers price
    /// @param sellOfferId id of sell offer to sell nft
    /// @param buyOfferId id of buy offer to buy nft
    function fulfillOffer(uint256 sellOfferId, uint256 buyOfferId)
        external
        offerExists(sellOfferId)
        offerExists(buyOfferId)
        nonReentrant
    {
        Offer storage buyOffer = _offers[buyOfferId];
        Offer storage sellOffer = _offers[sellOfferId];
        require(buyOffer.direction == Direction.BUY);
        require(sellOffer.direction == Direction.SELL);
        require(sellOffer.status == Status.PENDING);
        require(buyOffer.status == Status.PENDING);
        require(sellOffer.price <= buyOffer.price);
        require(sellOffer.nft.nftContract == buyOffer.nft.nftContract);
        require(sellOffer.nft.tokenId == buyOffer.nft.tokenId);
        require(sellOffer.token == buyOffer.token);

        buyOffer.status = Status.ACCEPTED;
        sellOffer.status = Status.ACCEPTED;
        uint256 fulfillProfit = buyOffer.price - sellOffer.price;
        if (sellOffer.token == WETH) {
            IWETH(payable(WETH)).withdraw(
                buyOffer.price - (buyOffer.price * adminPanel.feeX1000()) / 1000
            );
            payable(msg.sender).transfer(_fee(fulfillProfit, WETH));
            payable(sellOffer.owner).transfer(_fee(sellOffer.price, WETH));
        } else {
            IERC20(sellOffer.token).transfer(
                msg.sender,
                _fee(fulfillProfit, sellOffer.token)
            );
            IERC20(sellOffer.token).transfer(
                sellOffer.owner,
                _fee(sellOffer.price, sellOffer.token)
            );
        }
        _transferNFT(
            address(this),
            buyOffer.owner,
            buyOffer.nft.nftContract,
            buyOffer.nft.tokenId
        );

        emit FulFill(block.timestamp, sellOffer.id, buyOffer.id);
    }

    /// @dev Calculates fee amount and transfers it to fee address
    /// @param price the nft price in selected token
    /// @param token the fee transfer token
    /// @return profit with taking account of current fee
    function _fee(uint256 price, address token) internal returns (uint256) {
        IERC20(token).transfer(
            adminPanel.feeAddress(),
            (price * adminPanel.feeX1000()) / 1000
        );
        return price - (price * adminPanel.feeX1000()) / 1000;
    }

    /// @dev Allows to get all offers
    /// @return _offers array of all offers
    function offers() external view returns (Offer[] memory) {
        return _offers;
    }

    /// @dev Allows to get all offers of one selected user
    /// @param user address to get all offers for
    /// @return ids all offers id of selected user
    function userOffers(address user) external view returns (uint256[] memory) {
        return _userOffers[user];
    }

    /// @dev Sets new admin panel address
    /// @param newAdminPanel new admin panel address
    function setAdminPanel(address newAdminPanel) external onlyOwner {
        adminPanel = IAdminPanel(newAdminPanel);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFTAssist
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import './interfaces/INFTAssist.sol';

contract NFTAssist is INFTAssist, ERC1155Holder, ERC721Holder {
    using ERC165Checker for address;

    /// @dev Allows to show nft type of selected address
    /// @param token_ address of token to be interface checked
    /// @return interface type of nft
    function _getNFTType(address token_) internal view returns (NFTType) {
        if (token_.supportsInterface(type(IERC721).interfaceId)) return NFTType.ERC721;
        if (token_.supportsInterface(type(IERC1155).interfaceId)) return NFTType.ERC1155;
        else revert WrongNFTType();
    }

    /// @dev Transfers nft to selected address with interface type of nft
    /// @param from address who sends nft to new owner
    /// @param to address to receive nft
    /// @param nft address of nft to be bougth
    /// @param tokenId id of nft token to be bougth
    function _transferNFT(
        address from,
        address to,
        address nft,
        uint256 tokenId
    ) internal {
        NFTType nftType = _getNFTType(nft);
        if (nftType == NFTType.ERC721) IERC721(nft).transferFrom(from, to, tokenId);
        if (nftType == NFTType.ERC1155)
            IERC1155(nft).safeTransferFrom(from, to, tokenId, 1, '');
    }

    /// @dev Prevents actions with nft by not the owner
    /// @param nft address of owner nft
    /// @param tokenId owner's nft token id
    function _checkOwnership(address nft, uint256 tokenId) internal view {
        NFTType nftType = _getNFTType(nft);
        if (nftType == NFTType.ERC721)
            if (IERC721(nft).ownerOf(tokenId) != msg.sender) revert CallerIsNotNFTOwner();
        if (nftType == NFTType.ERC1155)
            if (IERC1155(nft).balanceOf(msg.sender, tokenId) == 0)
                revert CallerIsNotNFTOwner();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAdminPanel
 * @author gotbit
 */

interface IAdminPanel {
    /// @dev Adds nft address to whitelist
    /// @param nft_ nft address to add to whitelist
    function addToWhitelist(address nft_) external;

    /// @dev Removes nft adderess from whitelist
    /// @param nft_ nft address to be removed from whitelist
    function removeFromWhitelist(address nft_) external;

    /// @dev Allows to know does nft address belongs to whitelist or not
    /// @param nft_ nft address to check inside whitelist
    /// @return doesBelongsToWhitelist ture if address belongs to whitelist, false if not
    function belongsToWhitelist(address nft_) external view returns (bool);

    /// @dev Adds token to whitelist
    /// @param newToken token address to be added
    function addToken(address newToken) external;

    /// @dev Removes token from whitelist
    /// @param token token addres to be removed
    function removeToken(address token) external;

    /// @dev Allows to know token address belongs to token whitelist
    /// @param token token address to check inside whitelist
    /// @return doesBelongToTokenWhitelist is true when you can buy or sell with this token
    function validTokens(address token) external view returns (bool);

    /// @dev Allows to get fee reveiver address
    /// @return feeAddress address who receives fee
    function feeAddress() external view returns (address);

    /// @dev Allows to get fee amount x 1000
    /// @return feeX1000 fee amount muled on 1000
    function feeX1000() external view returns (uint256);

    /// @dev Allows admin to grant selected address a fee setter role
    /// @param newFeeSetter is address who can set fee amount and fee address
    function grantFeeSetterRole(address newFeeSetter) external;

    /// @dev Allows admin to grant selected address a whitelist setter role
    /// @param newWhitelistSetter is address who can add/remove payable
    /// tokens and nft's addresses to/from whitelist
    function grantWhitelistSetterRole(address newWhitelistSetter) external;

    /// @dev Allows admin to revoke fee setter from role selected address
    /// @param feeSetter is address who could not set fee amount and fee address
    function revokeFeeSetterRole(address feeSetter) external;

    /// @dev Allows admin to revoke a whitelist setter role from selected address
    /// @param whitelistSetter is address who could not add/remove payable
    /// tokens and nft's addresses to/from whitelist
    function revokeWhitelistSetterRole(address whitelistSetter) external;

    /// @dev Allows to get all tokens existing in whitelist
    /// @return addresses array of all whitelisted tokens adresses
    function getTokensList() external view returns (address[] memory);

    /// @dev Allows to get all nfts existing in whitelist
    /// @return addresses array of all whitelisted nfts addresses
    function getNFTsList() external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IMarket
 * @author gotbit
 */

import './INFTAssist.sol';

interface IMarket is INFTAssist {
    enum Direction {
        NULL,
        SELL,
        BUY
    }

    enum Status {
        NULL,
        PENDING,
        CANCELED,
        ACCEPTED
    }

    struct Offer {
        uint256 id;
        NFT nft;
        address owner;
        address token;
        uint256 timeStarted;
        uint256 price;
        Status status;
        Direction direction;
    }

    error NotEnoughETH();
    error NotValidOffer();

    /// @dev Creates a Buy offer and sets it's info for selected nft address and token id
    /// @param nft address of nft to buy
    /// @param tokenId token id of nft to buy
    /// @param price_ suggested price to buy nft
    /// @param token_ token address of suggested tokens amount
    function createBuyOffer(
        address nft,
        uint256 tokenId,
        uint256 price_,
        address token_
    ) external payable;

    /// @dev Creates a sell offer and sets it for selected nft address and id only by nft owner
    /// @param nft staking nft address
    /// @param tokenId staking nft token id
    /// @param price_ amount of nft cost in selected token
    /// @param token_ selected token to pay nft seller
    function createSellOffer(
        address nft,
        uint256 tokenId,
        uint256 price_,
        address token_
    ) external;

    /// @dev Cancel the offer handling all directoins by setting direction to null
    /// @param offerId id of the offer to cancel
    function cancelOffer(uint256 offerId) external;

    /// @dev Buying nft by the function caller only with selected token and price
    /// @param offerId id of the sell offer to accept
    function acceptSellOffer(uint256 offerId) external;

    /// @dev Buying nft by the function caller only with ETH by selected price
    /// @param offerId id of the sell offer to accept
    function acceptSellOfferETH(uint256 offerId) external payable;

    /// @dev Sells nft to by offer owner with selected token and price
    /// @param offerId if of the buy offer to accept
    function acceptBuyOffer(uint256 offerId) external;

    /// @dev if the offer is buy offer, then receives missing amount
    /// or sends extra tokens to offer owner, than in both ways changes offer price
    /// @param offerId id of the offer to change price
    /// @param newPrice new price of nft to buy or sell
    function changeOfferPrice(uint256 offerId, uint256 newPrice) external payable;

    /// @dev Allows to get all offers
    /// @return _offers array of all offers
    function offers() external view returns (Offer[] memory);

    /// @dev Allows to get all offers of one selected user
    /// @param user address to get all offers for
    /// @return ids all offers id of selected user
    function userOffers(address user) external view returns (uint256[] memory);

    /// @dev Allows to fulfill sell and buy offer with the same nft and parameters
    /// the function caller gets diff between sell and buy offers price
    /// @param sellOfferId id of sell offer to sell nft
    /// @param buyOfferId id of buy offer to buy nft
    function fulfillOffer(uint256 sellOfferId, uint256 buyOfferId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INFTAssist
 * @author gotbit
 */

interface INFTAssist {
    enum NFTType {
        NULL,
        ERC721,
        ERC1155
    }
    struct NFT {
        address nftContract;
        uint256 tokenId;
    }

    error WrongNFTType();
    error CallerIsNotNFTOwner();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IWETH
 * @author gotbit
 */

interface IWETH {
    fallback() external payable;

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}