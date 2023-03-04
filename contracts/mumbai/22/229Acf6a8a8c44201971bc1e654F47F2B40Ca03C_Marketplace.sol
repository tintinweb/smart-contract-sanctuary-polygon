// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IItemsIsERC1155 is IERC1155{

  function ADMIN_CREATOR (  ) external view returns ( bytes32 );
  function ADMIN_MINTER (  ) external view returns ( bytes32 );
  function CREATOR (  ) external view returns ( bytes32 );
  function MINTER (  ) external view returns ( bytes32 );
  function getTokenAddress (  ) external view returns ( address );
  function getMaxSupplyById ( uint256 ) external view returns ( uint256 );
  function addAdmin ( address ) external;
  function addAdminCreator ( address ) external;
  function addAdminMinter ( address ) external;
  function addCreator ( address ) external;
  function addItemSupply ( uint256, uint256 ) external;
  function addMinter ( address ) external;
  function adminMint ( address, uint256, uint256 ) external;
  function airdropItems ( address[] memory, uint256[] memory, uint256[] memory ) external;
  function batchAddItemSupply ( uint256[] memory, uint256[] memory ) external;
  function batchPurchaseItem ( uint256[] memory, uint256[] memory ) external;
  function batchCreateItem ( string[] memory, string[] memory, string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory ) external;
  function batchRemoveItemSupply ( uint256[] memory, uint256[] memory ) external;
  function batchUpdateItem ( uint256[] memory, string[] memory, string[] memory, string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory ) external;
  function purchaseItem ( uint256, uint256 ) external;
  function createItem ( string memory, string memory, string memory, uint256, uint256, uint256, uint256 ) external;
  function itemById ( uint256 ) external view returns ( uint256, string memory, string memory, string memory, uint256, uint256, uint256, uint256, uint256 );
  function mintedItemsByUser ( address, uint256 ) external view returns ( uint256 );
  function pause (  ) external;
  function removeItemSupply ( uint256, uint256 ) external;
  function revokeAdminCreator ( address ) external;
  function revokeAdminMinter ( address ) external;
  function revokeCreator ( address ) external;
  function revokeMinter ( address ) external;
  function unpause (  ) external;
  function updateItem ( uint256, string memory, string memory, string memory, uint256, uint256, uint256, uint256 ) external;
  function getItemPrice ( uint256 ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarketplace {

  function acceptBid ( uint256 ) external;
  function bidById ( uint256 ) external view returns ( address, uint256, uint256, uint256, uint256, bool, bool, bool );
  function bidsByAddress ( address, uint256 ) external view returns ( uint256 );
  function cancelBid ( uint256 ) external;
  function cancelList ( uint256 ) external;
  function createBid ( uint256, uint256, uint256, bool, uint256 ) external;
  function getActiveBidsByUser ( address ) external view returns ( uint256[] memory);
  function getActiveListingsByUser ( address ) external view returns ( uint256[] memory);
  function getBidsByTokenId ( uint256 ) external view returns ( uint256[] memory);
  function getBidsByUser ( address ) external view returns ( uint256[] memory);
  function getItemsWithActiveBid ( uint256[] memory ) external view returns ( uint256[] memory);
  function getItemsWithActiveListing ( uint256[] memory ) external view returns ( uint256[] memory);
  function getListingsByTokenId ( uint256 ) external view returns ( uint256[] memory);
  function getListingsByUser ( address ) external view returns ( uint256[] memory);
  function listItem ( uint256, uint256, uint256, bool, uint256 ) external;
  function listingById ( uint256 ) external view returns ( address, uint256, uint256, uint256, uint256, bool, bool, bool );
  function listingsByAddress ( address, uint256 ) external view returns ( uint256 );
  function purchaseListing ( uint256 ) external;
  function refundBids (  ) external;
  function refundListings (  ) external;
  function setItemsContract ( address ) external;
  function setTokenContract ( address ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/utils/Counters.sol";
import "../Token/ITokenIsERC20.sol";
import "../Items/IItemsIsERC1155.sol";
import "./IMarketplace.sol";

contract Marketplace is IMarketplace, Ownable, ERC1155Holder, ReentrancyGuard {

    IItemsIsERC1155 itemsContract;
    ITokenIsERC20 tokenContract;

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _listingIds;
    Counters.Counter private _bidIds;

    struct ListStruct {
        address seller;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 deadline;
        uint256 price;
        bool isDeadline;
        bool isSold;
        bool isCanceled;
    }

    struct BidStruct {
        address bidder;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 deadline;
        uint256 price;
        bool isDeadline;
        bool isAccepted;
        bool isCanceled;
    }

    mapping (uint => ListStruct) public listingById;
    mapping (uint => BidStruct) public bidById;

    mapping (address => uint256[]) public listingsByAddress;
    mapping (address => uint256[]) public bidsByAddress;

    event NewListing(uint256 _listingId, address indexed _seller, uint256 _tokenId, uint256 _amount, uint256 _deadline, bool _isDeadline, uint256 _price);
    event CanceledListing (uint _listingId, address indexed _seller, uint256 _tokenId, uint256 _amountOfToken);
    event NewSale(uint256 _listingId, address indexed _buyer, address indexed _seller, uint256 _tokenId, uint256 _amountOfToken, uint256 _price);

    event NewBid(uint256 _bidId, address indexed _bidder, uint256 _tokenId, uint256 _amount, uint256 _deadline, bool _isDeadline, uint256 _price);
    event CanceledBid (uint256 _bidId, address indexed _bidder, uint256 _tokenId, uint256 _amountOfToken);
    event BidAccepted(uint256 _bidId, address indexed _bidder, address indexed _seller, uint256 _tokenId, uint256 _amountOfToken, uint256 _price);

    constructor(address _tokenContract, address _itemsContract)  {
        tokenContract = ITokenIsERC20(_tokenContract);
        itemsContract = IItemsIsERC1155(_itemsContract);
    }

    /* ********************************** */
    /*               Listings             */
    /* ********************************** */

    function listItem(uint256 _tokenId, uint256 _amountOfToken, uint256 _deadline, bool _isDeadline, uint256 _price) external nonReentrant {
        require(_amountOfToken > 0, "Amount can't be 0");
        require(_price > 0, "Price can't be 0");
        require(itemsContract.balanceOf(msg.sender, _tokenId) >= _amountOfToken, "You don't have enough tokens to sell");

        itemsContract.safeTransferFrom(msg.sender, address(this), _tokenId, _amountOfToken, "");

        uint newSaleId = _listingIds.current();

        listingById[newSaleId] = ListStruct (
            msg.sender,
            _tokenId,
            _amountOfToken,
            block.timestamp + _deadline,
            _price,
            _isDeadline,
            false,
            false
        );

        listingsByAddress[msg.sender].push(newSaleId);

        _listingIds.increment();

        emit NewListing(
            newSaleId,
            msg.sender,
            _tokenId,
            _amountOfToken,
            _deadline,
            _isDeadline,
            _price
        );
    }

    function purchaseListing(uint256 _listingId) external nonReentrant {
        require(listingById[_listingId].seller != address(0), "Listing doesn't exist");
        require(listingById[_listingId].isSold != true, "Item already sold");
        require(listingById[_listingId].isCanceled != true, "Listing canceled");
        require(listingById[_listingId].seller != msg.sender, "You can't purchase your own item");
        uint256 salePrice = listingById[_listingId].price;
        require(tokenContract.balanceOf(msg.sender) >= salePrice, "You don't have enough token tokens to purchase this item");
        if (listingById[_listingId].isDeadline) {
            require(block.timestamp <= listingById[_listingId].deadline, "Listing expired");
        }

        // @notice send the tokens to the seller
        tokenContract.transferFrom(msg.sender, listingById[_listingId].seller, salePrice);

        // @notice send the item to the buyer
        itemsContract.safeTransferFrom(
            address(this),
            msg.sender,
            listingById[_listingId].tokenId,
            listingById[_listingId].amountOfToken,
            ""
        );

        listingById[_listingId].isSold = true;

        emit NewSale(
            _listingId,
            msg.sender,
            listingById[_listingId].seller,
            listingById[_listingId].tokenId,
            listingById[_listingId].amountOfToken,
            salePrice
        );
    }

    function cancelList(uint256 _listingId) external nonReentrant {
        require(listingById[_listingId].seller == msg.sender, "Should be the owner of the sell.");
        require(listingById[_listingId].isCanceled != true, "Offer already canceled.");
        require(listingById[_listingId].isSold != true, "Already sold.");

        listingById[_listingId].isCanceled = true;

        itemsContract.safeTransferFrom(
            address(this),
            msg.sender,
            listingById[_listingId].tokenId,
            listingById[_listingId].amountOfToken,
            ""
        );

        emit CanceledListing(
            _listingId,
            listingById[_listingId].seller,
            listingById[_listingId].tokenId,
            listingById[_listingId].amountOfToken
        );
    }

    function updateListPrice(uint256 _listingId, uint256 _newPrice) external {
        require(listingById[_listingId].seller == msg.sender, "Should be the owner of the list.");
        require(listingById[_listingId].isCanceled != true, "Offer already canceled.");
        require(listingById[_listingId].isSold != true, "Already sold.");
        require(_newPrice > 0, "Price can't be 0.");

        listingById[_listingId].price = _newPrice;
    }

    function increaseListDeadline(uint256 _listingId, uint256 _secondsToAdd) external {
        require(listingById[_listingId].seller == msg.sender, "Should be the owner of the list.");
        require(listingById[_listingId].isCanceled != true, "Offer already canceled.");
        require(listingById[_listingId].isSold != true, "Already sold.");
        require(listingById[_listingId].isDeadline == true, "No deadline set.");
        require(_secondsToAdd > 0, "Seconds to add can't be 0.");

        listingById[_listingId].deadline = listingById[_listingId].deadline + _secondsToAdd;
    }

    function getTotalListings() external view returns (uint256) {
        return _listingIds.current();
    }

    function getActiveListings() external view returns (uint256[] memory) {
        uint listingLength = _listingIds.current();
        uint256[] memory tmpList = new uint256[](listingLength);

        uint activeListingCount = 0;

        for (uint i = 0; i < listingLength; i++) {

            if (listingById[i].isSold == false && listingById[i].isCanceled == false) {
                tmpList[activeListingCount] = i;
                activeListingCount++;
            }
        }

        uint256[] memory activeListingList = new uint256[](activeListingCount);

        for (uint i = 0; i < activeListingCount; i++) {
            activeListingList[i] = tmpList[i];
        }

        return activeListingList;
    }

    function getListingsByUser(address _user) external view returns (uint256[] memory) {
        uint listingLength = listingsByAddress[_user].length;

        uint256[] memory listingIds = new uint256[](listingLength);

        for (uint i = 0; i < listingLength; i++) {
            listingIds[i] = listingsByAddress[_user][i];
        }

        return listingIds;
    }

    function getActiveListingsByUser(address _user) external view returns (uint256[] memory) {
        uint listingLength = listingsByAddress[_user].length;
        uint256[] memory tmpList = new uint256[](listingLength);

        uint activeListingsCount = 0;
        for (uint i = 0; i < listingLength; i++) {
            if (listingById[listingsByAddress[_user][i]].isSold == false && listingById[listingsByAddress[_user][i]].isCanceled == false) {
                tmpList[activeListingsCount] = listingsByAddress[_user][i];
                activeListingsCount++;
            }
        }

        uint256[] memory listingIds = new uint256[](activeListingsCount);

        for (uint i = 0; i < activeListingsCount; i++) {
            listingIds[i] = tmpList[i];
        }

        return listingIds;
    }

    function getListingsByTokenId(uint256 _tokenId) public view returns (uint256[] memory) {
        uint listingLength = _listingIds.current();
        uint256[] memory tmpList = new uint256[](listingLength);

        uint listingByTokenIdCount = 0;

        for (uint i = 0; i < listingLength; i++) {

            if (listingById[i].tokenId == _tokenId && listingById[i].isSold == false && listingById[i].isCanceled == false) {
                tmpList[listingByTokenIdCount] = i;
                listingByTokenIdCount++;
            }
        }

        uint256[] memory listingByTokenId = new uint256[](listingByTokenIdCount);

        for (uint i = 0; i < listingByTokenIdCount; i++) {
            listingByTokenId[i] = tmpList[i];
        }

        return listingByTokenId;
    }

    function getItemsWithActiveListing(uint256[] memory _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory tmpList = new uint256[](_tokenIds.length);

        uint activeListingsCount = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (getListingsByTokenId(_tokenIds[i]).length > 0) {
                tmpList[activeListingsCount] = _tokenIds[i];
                activeListingsCount++;
            }
        }

        uint256[] memory activeTokenIds = new uint256[](activeListingsCount);

        for (uint i = 0; i < activeListingsCount; i++) {
            activeTokenIds[i] = tmpList[i];
        }

        return activeTokenIds;
    }

    /* ********************************** */
    /*               Bids                 */
    /* ********************************** */

    function createBid(uint256 _tokenId, uint256 _amountOfToken, uint256 _deadLine, bool _isDeadLine, uint256 _price) external nonReentrant {
        require(_amountOfToken > 0, "Amount can't be 0");
        require(_price > 0, "Price can't be 0");
        require(tokenContract.balanceOf(msg.sender) >= _price, "You don't have enough token tokens to bid");
        require(itemsContract.getMaxSupplyById(_tokenId) > 0, "Item doesn't exist");

        tokenContract.transferFrom(msg.sender, address(this), _price);

        uint newBidId = _bidIds.current();

        bidById[newBidId] = BidStruct (
            msg.sender,
            _tokenId,
            _amountOfToken,
            block.timestamp + _deadLine,
            _price,
            _isDeadLine,
            false,
            false
        );

        bidsByAddress[msg.sender].push(newBidId);

        _bidIds.increment();

        emit NewBid(
            newBidId,
            msg.sender,
            _tokenId,
            _amountOfToken,
            _deadLine,
            _isDeadLine,
            _price
        );
    }

    function acceptBid(uint256 _bidId) external nonReentrant {
        require(bidById[_bidId].bidder != address(0), "Bid doesn't exist");
        require(bidById[_bidId].isAccepted != true, "Bid already accepted");
        require(bidById[_bidId].isCanceled != true, "Bid canceled");
        require(msg.sender != bidById[_bidId].bidder, "You can't accept your own bid");
        require(itemsContract.balanceOf(msg.sender, bidById[_bidId].tokenId) >= bidById[_bidId].amountOfToken, "You don't have enough tokens to accept this bid");

        if (bidById[_bidId].isDeadline) {
            require(block.timestamp <= bidById[_bidId].deadline, "Bid expired");
        }

        // @notice send the tokens to the selled
        tokenContract.transferFrom(address(this), msg.sender, bidById[_bidId].price);

        // @notice send the item to the bidder
        itemsContract.safeTransferFrom(
            msg.sender,
            bidById[_bidId].bidder,
            bidById[_bidId].tokenId,
            bidById[_bidId].amountOfToken,
            ""
        );

        bidById[_bidId].isAccepted = true;

        emit BidAccepted(
            _bidId,
            msg.sender,
            bidById[_bidId].bidder,
            bidById[_bidId].tokenId,
            bidById[_bidId].amountOfToken,
            bidById[_bidId].price
        );
    }

    function cancelBid(uint256 _bidId) external nonReentrant {
        require(bidById[_bidId].bidder == msg.sender, "Should be the owner of the bid.");
        require(bidById[_bidId].isCanceled != true, "Bid already canceled.");
        require(bidById[_bidId].isAccepted != true, "Bid already accepted.");

        bidById[_bidId].isCanceled = true;

        tokenContract.transferFrom(address(this), msg.sender, bidById[_bidId].price);

        emit CanceledBid(
            _bidId,
            bidById[_bidId].bidder,
            bidById[_bidId].tokenId,
            bidById[_bidId].amountOfToken
        );
    }

    function updateBidPrice(uint256 _bidId, uint256 _newPrice) external {
        require(bidById[_bidId].bidder == msg.sender, "Should be the owner of the bid.");
        require(bidById[_bidId].isCanceled != true, "Bid already canceled.");
        require(bidById[_bidId].isAccepted != true, "Bid already accepted.");
        require(_newPrice > 0, "Price can't be 0");

        uint oldPrice = bidById[_bidId].price;

        if (_newPrice > oldPrice) {
            require(tokenContract.balanceOf(msg.sender) >= _newPrice - oldPrice, "You don't have enough token tokens to bid");
            tokenContract.transferFrom(msg.sender, address(this), _newPrice - oldPrice);
        } else {
            tokenContract.transferFrom(address(this), msg.sender, oldPrice - _newPrice);
        }

        bidById[_bidId].price = _newPrice;
    }

    function increaseBidDeadline(uint256 _bidId, uint256 _secondsToAdd) external {
        require(bidById[_bidId].bidder == msg.sender, "Should be the owner of the bid.");
        require(bidById[_bidId].isCanceled != true, "Bid already canceled.");
        require(bidById[_bidId].isAccepted != true, "Bid already accepted.");
        require(bidById[_bidId].isDeadline, "No deadline set.");
        require(_secondsToAdd > 0, "Seconds to add can't be 0");

        bidById[_bidId].deadline += _secondsToAdd;
    }

    function getTotalBids() external view returns (uint256) {
        return _bidIds.current();
    }

    function getActiveBids() external view returns (uint256[] memory) {
        uint bidLength = _bidIds.current();
        uint256[] memory tmpList = new uint256[](bidLength);

        uint activeBidsCount = 0;

        for (uint i = 0; i < bidLength; i++) {
            if (bidById[i].isAccepted == false && bidById[i].isCanceled == false) {
                tmpList[activeBidsCount] = i;
                activeBidsCount++;
            }
        }

        uint256[] memory activeBids = new uint256[](activeBidsCount);

        for (uint i = 0; i < activeBidsCount; i++) {
            activeBids[i] = tmpList[i];
        }

        return activeBids;
    }

    function getBidsByUser(address _user) external view returns (uint256[] memory) {
        uint bidLength = bidsByAddress[_user].length;

        uint256[] memory bidIds = new uint256[](bidLength);

        for (uint i = 0; i < bidLength; i++) {
            bidIds[i] = bidsByAddress[_user][i];
        }

        return bidIds;
    }

    function getActiveBidsByUser(address _user) external view returns (uint256[] memory) {
        uint bidLength = bidsByAddress[_user].length;
        uint256[] memory tmpList = new uint256[](bidLength);

        uint activeBidsCount = 0;
        for (uint i = 0; i < bidLength; i++) {
            if (bidById[bidsByAddress[_user][i]].isAccepted == false && bidById[bidsByAddress[_user][i]].isCanceled == false) {
                tmpList[activeBidsCount] = bidsByAddress[_user][i];
                activeBidsCount++;
            }
        }

        uint256[] memory bidIds = new uint256[](activeBidsCount);

        for (uint i = 0; i < activeBidsCount; i++) {
            bidIds[i] = tmpList[i];
        }

        return bidIds;
    }

    function getBidsByTokenId(uint256 _tokenId) public view returns (uint256[] memory) {
        uint bidLength = _bidIds.current();
        uint256[] memory tmpList = new uint256[](bidLength);

        uint bidByTokenIdCount = 0;

        for (uint i = 0; i < bidLength; i++) {
            if (bidById[i].tokenId == _tokenId && bidById[i].isAccepted == false && bidById[i].isCanceled == false) {
                tmpList[bidByTokenIdCount] = i;
                bidByTokenIdCount++;
            }
        }

        uint256[] memory bidByTokenId = new uint256[](bidByTokenIdCount);

        for (uint i = 0; i < bidByTokenIdCount; i++) {
            bidByTokenId[i] = tmpList[i];
        }

        return bidByTokenId;
    }

    function getItemsWithActiveBid(uint256[] memory _tokenIds ) external view returns (uint256[] memory) {
        uint256[] memory tmpList = new uint256[](_tokenIds.length);

        uint tokenWithActiveBidCount = 0;

        for (uint i = 0; i < _tokenIds.length; i++) {
            if (getBidsByTokenId(_tokenIds[i]).length > 0) {
                tmpList[tokenWithActiveBidCount] = i;
                tokenWithActiveBidCount++;
            }
        }

        uint256[] memory itemsWithActiveBid = new uint256[](tokenWithActiveBidCount);

        for (uint i = 0; i < tokenWithActiveBidCount; i++) {
            itemsWithActiveBid[i] = tmpList[i];
        }

        return itemsWithActiveBid;

    }

    /* ********************************** */
    /*          Admin functions           */
    /* ********************************** */

    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = ITokenIsERC20(_tokenContract);
    }

    function setItemsContract(address _itemsContract) external onlyOwner {
        itemsContract = IItemsIsERC1155(_itemsContract);
    }

    function refundListings() external onlyOwner {
        uint listingLength = _listingIds.current();

        for (uint i = 0; i < listingLength; i++) {
            if (listingById[i].isSold == false && listingById[i].isCanceled == false) {
                listingById[i].isCanceled = true;
                itemsContract.safeTransferFrom(
                    address(this),
                    listingById[i].seller,
                    listingById[i].tokenId,
                    listingById[i].amountOfToken,
                    ""
                );
            }
        }
    }

    function refundBids() external onlyOwner {
        uint bidLength = _bidIds.current();

        for (uint i = 0; i < bidLength; i++) {
            if (bidById[i].isAccepted == false && bidById[i].isCanceled == false) {
                bidById[i].isCanceled = true;
                tokenContract.transferFrom(address(this), bidById[i].bidder, bidById[i].price);
            }
        }
    }



}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ITokenIsERC20 is IERC20, IAccessControl {

  function ADMIN_MINTER (  ) external view returns ( bytes32 );
  function MINTER (  ) external view returns ( bytes32 );
  function addAdmin ( address ) external;
  function addAdminMinter ( address ) external;
  function addMinter ( address ) external;
  function addUnlimitedAllowance ( address ) external;
  function airdrop ( address[] calldata, uint256[] calldata) external;
  function mint ( address, uint256 ) external;
  function pause (  ) external;
  function removeUnlimitedAllowance ( address ) external;
  function revokeAdminMinter ( address ) external;
  function revokeMinter ( address ) external;
  function takeSnapshot (  ) external;
  function unlimitedAllowance ( address ) external view returns ( bool );
  function unpause (  ) external;

}