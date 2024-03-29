// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkSubscriber.sol";
import "./interfaces/IImportedContracts.sol";
import "./mQuarkEntityDeployer.sol";
import "./utils/noDelegateCall.sol";

/**
 * @title ImportedContracts
 * @dev This contract is used to manage the external collections.
 *      It is used by the subscriber contract to subscribe to a entity.
 */
contract ImportedContracts is AccessControl, IImportedContracts {
  //* =============================== MAPPINGS ======================================================== *//
  // Mapping to store subscription information for tokens.
  // The outer mapping is indexed by the token owner's address.
  // The middle mapping is indexed by the token ID.
  // The inner mapping is indexed by the Entity ID.
  // Each subscription ID maps to a `TokenSubscriptionInfo` struct.
  mapping(address => mapping(uint256 => mapping(uint256 => TokenSubscriptionInfo))) private s_tokenSubscriptions;

  //* =============================== VARIABLES ======================================================= *//
  // Controller contract address to access the subscriber contract address.
  ImQuarkController public immutable s_controller;

  //* =============================== MODIFIERS ======================================================= *//
  modifier onlySubscriber() {
    if (s_controller.getSubscriberContract() != msg.sender) revert NotAuthorized("NA");
    _;
  }

  //* =============================== CONSTRUCTOR ===================================================== *//
  constructor(address _controller) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    s_controller = ImQuarkController(_controller);
  }

  //* =============================== FUNCTIONS ======================================================= *//

  //* ============== EXTERNAL ===========*//
  /**
   * @notice Subscribes to an entity by setting the subscription information.
   * @dev This function is accessible only to the subscriber.
   * @param _contract The address of the contract representing the entity.
   * @param _owner The address of the owner of the entity.
   * @param _tokenId The ID of the entity token.
   * @param _entityId The ID of the entity.
   * @param _entityDefaultUri The default URI of the entity.
   * Throws {NotOwner} if the caller is not the owner of the entity token.
   */
  function subscribeToEntity(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint256 _entityId,
    string calldata _entityDefaultUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner("NO",_tokenId);
    s_tokenSubscriptions[_contract][_tokenId][_entityId] = TokenSubscriptionInfo(true, _entityDefaultUri);
  }

  /**
   * @notice Subscribes to multiple entities by setting the subscription information for each entity.
   * @dev This function is accessible only to the subscriber.
   * @param _contract The address of the contract representing the entities.
   * @param _owner The address of the owner of the entities.
   * @param _tokenId The ID of the entity token.
   * @param _entityIds The IDs of the entities to subscribe to.
   * @param _entityDefaultUris The default URIs of the entities.
   * Throws {NotOwner} if the caller is not the owner of the entity token.
   */
  function subscribeToEntities(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint256[] calldata _entityIds,
    string[] calldata _entityDefaultUris
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner("NO",_tokenId);
    uint256 numberOfEntities = _entityIds.length;
    for (uint256 i = 0; i < numberOfEntities; i++) {
      s_tokenSubscriptions[_contract][_tokenId][_entityIds[i]] = TokenSubscriptionInfo(true, _entityDefaultUris[i]);
    }
  }

  /**
   * @notice Updates the URI of a specific entity slot.
   * @dev This function is accessible only to the subscriber.
   * @param _contract The address of the contract representing the entities.
   * @param _owner The address of the owner of the entities.
   * @param _entityId The ID of the entity.
   * @param _tokenId The ID of the entity token.
   * @param _updatedUri The updated URI of the entity slot.
   * Throws {NotOwner} if the caller is not the owner of the entity token.
   * Throws {Unsubscribed} if the entity slot is not subscribed.
   */
  function updateURISlot(
    address _contract,
    address _owner,
    uint256 _entityId,
    uint256 _tokenId,
    string calldata _updatedUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner("NO",_tokenId);
    if (!s_tokenSubscriptions[_contract][_tokenId][_entityId].isSubscribed) revert Unsubscribed("US",_tokenId, _entityId);
    s_tokenSubscriptions[_contract][_tokenId][_entityId].uri = _updatedUri;
  }

  /**
   * @notice Transfers the URI of a specific entity slot to a new URI.
   * @dev This function is accessible only to the subscriber.
   * @param _contract The address of the teoken contract.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token.
   * @param _entityId The ID of the entity.
   * @param _transferredUri The new URI to transfer the entity slot to.
   * Throws {NotOwner} if the caller is not the owner of the token.
   * Throws {Unsubscribed} if the entity slot is already subscribed.
   */
  function transferTokenEntityURI(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint256 _entityId,
    string calldata _transferredUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner("NO",_tokenId);
    if (s_tokenSubscriptions[_contract][_tokenId][_entityId].isSubscribed) revert Unsubscribed("US",_tokenId, _entityId);
    s_tokenSubscriptions[_contract][_tokenId][_entityId].uri = _transferredUri;
  }

  /**
   * @notice Resets the URI of a specific entity slot to its default URI.
   * @dev This function is accessible only to the subscriber.
   * @param _contract The address of the imported contract.
   * @param _owner The address of the token owner.
   * @param _tokenId The ID of the token.
   * @param _entityId The ID of the entity.
   * @param _entityDefaultUri The default URI to reset the entity slot to.
   * Throws {NotOwner} if the caller is not the owner of the token.
   * Throws {Unsubscribed} if the entity slot is already subscribed.
   */
  function resetSlotToDefault(
    address _contract,
    address _owner,
    uint256 _tokenId,
    uint256 _entityId,
    string calldata _entityDefaultUri
  ) external onlySubscriber {
    if (IERC721(_contract).ownerOf(_tokenId) != _owner) revert NotOwner("NO",_tokenId);
    if (s_tokenSubscriptions[_contract][_tokenId][_entityId].isSubscribed) revert Unsubscribed("US",_tokenId, _entityId);
    s_tokenSubscriptions[_contract][_tokenId][_entityId].uri = _entityDefaultUri;
  }

  //* ============== VIEW ===========*//
  /**
   * @notice Retrieves the URI of a specific entity slot within a token.
   * @param _contract The address of the imported contract.
   * @param _tokenId The ID of the token.
   * @param _entityId The ID of the entity.
   * @return The URI of the specified entity slot.
   */
  function tokenEntityURI(
    address _contract,
    uint256 _tokenId,
    uint256 _entityId
  ) external view returns (string memory) {
    return s_tokenSubscriptions[_contract][_tokenId][_entityId].uri;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection, TokenSubscriptionInfo} from "../lib/mQuarkStructs.sol";

interface IImportedContracts {
  /**
   * @notice Subscribes a token to an entity.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity.
   * @param entitySlotDefaultUri The default URI for the entity slot.
   */
  function subscribeToEntity(
    address _contract,
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata entitySlotDefaultUri
  ) external;

  /**
   * @notice Subscribes multiple tokens to entities.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityIds The IDs of the entities.
   * @param entitySlotDefaultUris The default URIs for the entity slots.
   */
  function subscribeToEntities(
    address _contract,
    address owner,
    uint256 tokenId,
    uint256[] calldata entityIds,
    string[] calldata entitySlotDefaultUris
  ) external;

  /**
   * @notice Updates the URI slot of a single token.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param entityId The ID of the entity.
   * @param tokenId The ID of the token.
   * @param updatedUri The updated, signed URI value.
   */
  function updateURISlot(
    address _contract,
    address owner,
    uint256 entityId,
    uint256 tokenId,
    string calldata updatedUri
  ) external;

  /**
   * @notice Returns the entity URI for the given token ID.
   * @param _contract The address of the contract.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @return The URI of the given token's entity slot.
   */
  function tokenEntityURI(address _contract, uint256 tokenId, uint256 entityId) external view returns (string memory);

  /**
   * @notice Transfers the token entity URI.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity.
   * @param soldUri The URI to be transferred.
   */
  function transferTokenEntityURI(
    address _contract,
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata soldUri
  ) external;

  /**
   * @notice Resets the slot to the default URI.
   * @param _contract The address of the contract.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity.
   * @param defaultUri The default URI to be set.
   */
  function resetSlotToDefault(
    address _contract,
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata defaultUri
  ) external;

  /// Throws if the caller is not the owner of the token.
  error NotOwner(string code, uint256 tokenId);

  /// Throws if the token is unsubscribed from the entity.
  error Unsubscribed(string code, uint256 tokenId, uint256 entityId);

  /// Throws if the caller is not authorized.
  error NotAuthorized(string code);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

interface IInitialisable {
  function initilasiable(
    Collection calldata _collection,
    address _collectionOwner,
    address _controller,
    bytes32 _merkleRoot,
    uint256 _mintRoyalty
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "./ImQuarkTemplate.sol";
import "./ImQuarkRegistry.sol";

interface ImQuarkController {
  /**
   * @notice Emitted when the address of the subscriber contract is set.
   * @param subscriber The address of the subscriber contract.
   */
  event SubscriberContractAddressSet(address subscriber);

  /**
   * @notice Emitted when the address of the template contract is set.
   * @param template The address of the template contract.
   */
  event TemplateContractAddressSet(address template);

  /**
   * @notice Emitted when the address of the registry contract is set.
   * @param registry The address of the registry contract.
   */
  event RegistryContractAddressSet(address registry);

  /**
   * @notice Emitted when the royalty percentage is set.
   * @param royalty The royalty percentage.
   */
  event RoyaltySet(uint256 royalty);

  /**
   * @notice Emitted when the prices of templates are set.
   * @param templateIds The IDs of the templates.
   * @param prices The corresponding prices for the templates.
   */
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);

  /**
   * @notice Emitted when the authorized withdrawal address is set.
   * @param authorizedWithdrawal The authorized withdrawal address.
   */
  event AuthorizedWithdrawalSet(address authorizedWithdrawal);

  /**
   * @notice Sets the prices for multiple templates.
   * @param templateIds The IDs of the templates.
   * @param prices The corresponding prices for the templates.
   */
  function setTemplatePrices(uint256[] calldata templateIds, uint256[] calldata prices) external;

  /**
   * @notice Sets the address of the template contract.
   * @param template The address of the template contract.
   */
  function setTemplateContractAddress(address template) external;

  /**
   * @notice Sets the address of the registry contract.
   * @param registry The address of the registry contract.
   */
  function setRegistryContract(address registry) external;

  /**
   * @notice Sets the royalty percentage.
   * @param royalty The royalty percentage to set.
   */
  function setRoyalty(uint256 royalty) external;

  /**
   * @notice Validates the authorization of a caller.
   * @param caller The address of the caller.
   * @return True if the caller is authorized, otherwise false.
   */
  function validateAuthorization(address caller) external view returns (bool);

  /**
   * @notice Retrieves the mint price for a template.
   * @param templateId The ID of the template.
   * @return The mint price of the template.
   */
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256);

  /**
   * @notice Retrieves the address of the subscriber contract.
   * @return The address of the subscriber contract.
   */
  function getSubscriberContract() external view returns (address);

  /**
   * @notice Retrieves the balance of an entity.
   * @param entityId The ID of the entity.
   * @return The balance of the entity.
   */
  function getEntityBalance(uint256 entityId) external view returns (uint256);

  /**
   * @notice Retrieves the implementation address for a given implementation type.
   * @param implementation The implementation type.
   * @return The implementation address.
   */
  function getImplementation(uint8 implementation) external view returns (address);

  /**
   * @notice Retrieves the royalty percentage.
   * @return The royalty percentage.
   */
  function getRoyalty() external view returns (uint256);

  /**
   * @notice Retrieves the authorized withdrawal address.
   * @return The authorized withdrawal address.
   */
  function getWithdrawalAddress() external view returns (address);

  /**
   * @notice Retrieves the royalty percentage and mint price for a template.
   * @param templateId The ID of the template.
   * @return The royalty percentage and mint price of the template.
   */
  function getRoyaltyAndMintPrice(uint256 templateId) external view returns (uint256, uint256);

  /// Throws if the lengths of the input arrays do not match.
  error ArrayLengthMismatch(string code);

  /// Throws if the provided template ID does not exist.
  error TemplateIdNotExist(string code);

  /// Throws if the provided royalty percentage is too high.
  error RoyaltyIsTooHigh(string code);

  /// Throws if the token owner is not the caller.
  error NotTokenOwner(string code); 
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection} from "../lib/mQuarkStructs.sol";

interface ImQuarkEntity {
  /**
   * @notice Emitted when a collection is created.
   * @param instanceAddress The address of the created collection contract instance.
   * @param verifier The address of the verifier contract.
   * @param controller The address of the controller contract.
   * @param entityId The ID of the entity associated with the collection.
   * @param collectionId The ID of the collection.
   * @param templateId The ID of the template associated with the collection.
   * @param mintPrice The price of minting a token in the collection.
   * @param totalSupply The total supply of tokens in the collection.
   * @param mintLimitPerWallet The maximum number of tokens that can be minted per wallet.
   * @param royalty The royalty percentage for the collection.
   * @param collectionURIs The URIs associated with the collection.
   * @param mintType The minting type of the collection.
   * @param dynamic A flag indicating if the collection has dynamic URIs.
   * @param free A flag indicating if the collection is free.
   * @param whiteListed A flag indicating if the collection is whitelisted.
   */
  event CollectionCreated(
    address instanceAddress,
    address verifier,
    address controller,
    uint256 entityId,
    uint64 collectionId,
    uint256 templateId,
    uint256 mintPrice,
    uint256 totalSupply,
    uint256 mintLimitPerWallet,
    uint256 royalty,
    string[] collectionURIs,
    uint8 mintType,
    bool dynamic,
    bool free,
    bool whiteListed
  );

  /**
   * @notice Emitted when an external collection is created.
   * @param collectionAddress The address of the created external collection contract.
   * @param entityId The ID of the entity associated with the collection.
   * @param templateId The ID of the template associated with the collection.
   * @param collectionId The ID of the collection.
   */
  event ExternalCollectionCreated(address collectionAddress, uint256 entityId, uint256 templateId, uint64 collectionId);

  /**
   * @notice Represents the parameters required to create a collection
   */
  struct CollectionParams {
    // The ID of the template associated with the collection
    uint256 templateId;
    // The URIs associated with the collection
    string[] collectionURIs;
    // The total supply of tokens in the collection
    uint256 totalSupply;
    // The price of minting a token in the collection
    uint256 mintPrice;
    // The maximum number of tokens that can be minted per wallet
    uint8 mintPerAccountLimit;
    // The name of the collection
    string name;
    // The symbol of the collection
    string symbol;
    // The address of the verifier contract
    address verifier;
    // A flag indicating if the collection is whitelisted
    bool isWhitelisted;
  }

  /**
   * @notice Creates a new collection with the provided parameters.
   * @param collectionParams The parameters to create the collection.
   * @param isDynamicUri A flag indicating if the collection has dynamic URIs.
   * @param ERCimplementation The implementation type of the ERC721 contract.
   * @param merkeRoot The Merkle root of the collection.
   * @return instance The address of the created collection contract instance.
   */
  function createCollection(
    CollectionParams calldata collectionParams,
    bool isDynamicUri,
    uint8 ERCimplementation,
    bytes32 merkeRoot
  ) external returns (address instance);

  /**
   * @notice Imports an external collection into the system.
   * @dev Only the owner can call this function.
   * @param templateId The template ID of the collection.
   * @param collectionAddress The address of the external collection contract.
   */
  function importExternalCollection(uint256 templateId, address collectionAddress) external;

  /**
   * @notice Adds a new collection to the entity.
   * @dev Only the entity contract can call this function.
   * @param collectionAddress The address of the collection contract.
   * @return uint64 The ID of the newly added collection.
   */
  function addNewCollection(address collectionAddress) external returns (uint64);

  /**
   * @notice Transfers a collection to an entity.
   * @dev Only the collection contract can call this function.
   * @param entity The address of the entity.
   * @param collectionId The ID of the collection.
   * @return mcollectionId The ID of the transferred collection in the entity.
   */
  function transferCollection(address entity, uint64 collectionId) external returns (uint64);

  /**
   * @notice Retrieves the ID of the last created collection.
   * @return The ID of the last created collection.
   */
  function getLastCollectionId() external view returns (uint64);

  /**
   * @notice Retrieves the address of a collection with the given collection ID.
   * @param collectionId The ID of the collection.
   * @return The address of the collection contract.
   */
  function getCollectionAddress(uint64 collectionId) external view returns (address);

  /// Throws if the provided URI length is invalid.
  error InvalidURILength(string code, uint256 uriLength);

  /// Throws if the provided template ID is invalid.
  error InvalidTemplate(string code, uint256 templateId);

  /// Throws if the provided collection price is invalid.
  error InvalidCollectionPrice(string code, uint256 mintPrice);

  /// Throws if the caller is not the owner of the collection.
  error NotCollectionOwner(string code, address collectionAddress);

  /// Throws if the collection contract does not support the ERC165 interface.
  error NoERC165Support(string code, address collectionAddress);

  /// Throws if the collection contract does not support the ERC721 interface.
  error NoERC721Support(string code, address collectionAddress);

  /// Throws if the collection address is not an external collection.
  error NotExternal(string code, address collectionAddress);

  /// Throws if the total supply of the collection is zero.
  error TotalSupplyIsZero(string code);

  /// Throws if the given collection ID is invalid.
  error InvalidCollection(string code, uint64 collectionId);

  /// Throws if the given entity address is invalid.
  error InvalidEntity(string code, address entity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ImQuarkEntity.sol";
import "./ImQuarkRegistry.sol";

interface ImQuarkEntityDeployer {
  /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return registry The address of the registry contract(factory).
  /// @return subscriber The address of the subscriber contract.
  /// @return owner The address of the owner of the newly created entity
  /// @return id The ID of the newly created entity
  function parameters() external view returns (ImQuarkRegistry registry, address subscriber, address owner, uint256 id);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {Collection, TokenSubscriptionInfo} from "../lib/mQuarkStructs.sol";

/**
 * @title ImQuarkNFT
 * @author Unbounded team
 * @notice Interface smart contract of the mQuark NFT protocol.
 */
interface ImQuarkNFT {
  /**
   * @notice Signals the minting of a new token.
   * @dev This event is emitted when a new token is created and assigned to the specified address.
   * @param tokenId ID of the newly minted token
   * @param to Address to which the token is assigned
   * @param entityId ID of the associated entity
   * @param templateId ID of the token's template
   * @param collectionId ID of the token's collection
   * @param amount Amount of tokens minted
   * @param uri URI associated with the token's metadata
   */
  event TokenMint(
    uint256 tokenId,
    address to,
    uint256 entityId,
    uint256 templateId,
    uint64 collectionId,
    uint256 amount,
    string uri
  );

  /**
   * @notice Signals the transfer of the collection from one entity to another.
   * @param newCollectionId The new ID of the collection in the new entity.
   * @param previousCollectionId The previous ID of the collection in the previous entity.
   * @param newEntityAddress The address of the new entity.
   */
  event CollectionTransferred(uint64 newCollectionId, uint64 previousCollectionId, address newEntityAddress);

  /**
   * @notice Signals the withdrawal of protocol funds.
   * @dev This event is emitted when funds are withdrawn from the protocol by the specified address.
   * @param to Address that receives the withdrawn funds
   * @param amount Amount of funds withdrawn
   * @param savedAmountOwner Amount of funds saved by the owner
   * @param totalWithdrawn Total amount of funds withdrawn so far
   */
  event WithdrawProtocol(address to, uint256 amount, uint256 savedAmountOwner, uint256 totalWithdrawn);

  /**
   * @notice Signals the withdrawal of funds.
   * @dev This event is emitted when funds are withdrawn by the specified address.
   * @param to Address that receives the withdrawn funds
   * @param amount Amount of funds withdrawn
   * @param royalty Royalty amount associated with the withdrawal
   * @param totalWithdrawn Total amount of funds withdrawn so far
   */
  event Withdraw(address to, uint256 amount, uint256 royalty, uint256 totalWithdrawn);

  /**
   * @notice Signals the update of royalty information.
   * @dev This event is emitted when the royalty percentage and receiver address are updated.
   * @param percentage Royalty percentage
   * @param receiver Address of the royalty receiver
   */
  event RoyaltyInfoUpdated(uint16 percentage, address receiver);

  /**
   * @notice Represents royalty information for minted tokens.
   */
  struct MintRoyalty {
    // Royalty amount for the token
    uint256 royalty;
    // Amount withdrawn by the owner
    uint256 withdrawnAmountByOwner;
    // Amount withdrawn by the protocol
    uint256 withdrawnAmountByProtocol;
    // Amount saved by the owner
    uint256 savedAmountOwner;
    // Total amount withdrawn for the token
    uint256 totalWithdrawn;
  }

  /**
   * @notice Mints a token with the given variation ID.
   * @dev Emits an {TokenMint} event.
   * @param variationId The ID of the token variation to mint.
   */
  function mint(uint256 variationId) external payable;

  /**
   * @notice Mints a token with a specified URI and signature.
   * @dev Emits an {TokenMint} event.
   * @param signer The address of the signer for the signature verification.
   * @param signature The signature used to verify the authenticity of the minting request.
   * @param uri The URI associated with the minted token.
   * @param salt The salt value used for the minting process.
   */
  function mintWithURI(
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Mints a token with a whitelist verification using Merkle proofs.
   * @dev Emits an {TokenMint} event.
   * @param merkleProof The array of Merkle proofs used for whitelist verification.
   * @param variationId The ID of the token variation to mint.
   */
  function mintWhitelist(bytes32[] memory merkleProof, uint256 variationId) external payable;

  /**
   * @notice Mints a token with a whitelist verification, specified URI, and signature.
   * @dev Emits an {TokenMint} event.
   * @param merkleProof The array of Merkle proofs used for whitelist verification.
   * @param signer The address of the signer for the signature verification.
   * @param signature The signature used to verify the authenticity of the minting request.
   * @param uri The URI associated with the minted token.
   * @param salt The salt value used for the minting process.
   */
  function mintWithURIWhitelist(
    bytes32[] memory merkleProof,
    address signer,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable;

  /**
   * @notice Subscribes an owner to a single entity for a specific token.
   * @param owner The address of the owner to subscribe.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity to subscribe to.
   * @param entitySlotDefaultUri The default URI associated with the entity slot.
   */
  function subscribeToEntity(
    address owner,
    uint256 tokenId,
    uint256 entityId,
    string calldata entitySlotDefaultUri
  ) external;

  /**
   * @notice Subscribes an owner to multiple entities for a specific token.
   * @param owner The address of the owner to subscribe.
   * @param tokenId The ID of the token.
   * @param entityIds The array of entity IDs to subscribe to.
   * @param entitySlotDefaultUris The array of default URIs associated with the entity slots.
   */
  function subscribeToEntities(
    address owner,
    uint256 tokenId,
    uint256[] calldata entityIds,
    string[] calldata entitySlotDefaultUris
  ) external;

  /**
   * @notice Updates the URI slot of a single token.
   * @dev The entity must sign the new URI with its wallet address.
   * @param owner The address of the token owner.
   * @param entityId The ID of the entity.
   * @param tokenId The ID of the token.
   * @param updatedUri The updated, signed URI value.
   */
  function updateURISlot(address owner, uint256 entityId, uint256 tokenId, string calldata updatedUri) external;

  /**
   * @notice Returns the entity URI for the given token ID.
   * @dev Each entity can assign slots to tokens, storing a URI that refers to something on the entity.
   * @dev Slots are viewable by other entities but modifiable only by the token owner with a valid signature from the entity.
   * @param tokenId  The ID of the token for which the entity URI is to be returned.
   * @param entityId The ID of the entity associated with the given token.
   * @return The URI of the entity slot for the given token.
   */
  function tokenEntityURI(uint256 tokenId, uint256 entityId) external view returns (string memory);

  /**
   * @notice Transfers the ownership of the collection to a new account.
   * @param newOwner The address of the new owner.
   */
  function transferCollectionOwnership(address newOwner) external;

  /**
   * @notice Initializes the contract with the specified parameters.
   * @dev This function is used to initialize the contract's state variables.
   * @param collection The Collection object representing the collection.
   * @param collectionOwner The address of the collection owner.
   * @param controller The address of the controller.
   * @param merkleRoot The root hash of the Merkle tree used for whitelist verification.
   * @param mintRoyalty The royalty percentage to be applied during token minting.
   */
  function initilasiable(
    Collection calldata collection,
    address collectionOwner,
    address controller,
    bytes32 merkleRoot,
    uint256 mintRoyalty
  ) external;

  /**
   * @notice Transfers the entity URI of a token to a new owner with the specified URI.
   * @dev This function is used to transfer the ownership of the entity URI associated with a token.
   * @param owner The address of the new owner of the token.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @param soldUri The URI to be transferred to the new owner.
   */
  function transferTokenEntityURI(address owner, uint256 tokenId, uint256 entityId, string calldata soldUri) external;

  /**
   * @notice Resets the entity slot of a token to its default URI.
   * @dev This function is used to reset the entity slot of a token to its default URI.
   * @param owner The address of the token owner.
   * @param tokenId The ID of the token.
   * @param entityId The ID of the entity associated with the token.
   * @param defaultUri The default URI to be set for the entity slot.
   */
  function resetSlotToDefault(address owner, uint256 tokenId, uint256 entityId, string calldata defaultUri) external;

  /**
   * @notice Retrieves information about the collection.
   * @dev This function returns various information about the collection.
   * @return entityId The ID of the entity associated with the collection.
   * @return collectionId The ID of the collection.
   * @return mintType The type of minting allowed for the collection.
   * @return mintPerAccountLimit The maximum number of tokens that can be minted per account.
   * @return isWhitelisted A flag indicating whether the collection is whitelisted.
   * @return isFree A flag indicating whether the minting is free for the collection.
   * @return templateId The ID of the collection template.
   * @return mintCount The current count of minted tokens in the collection.
   * @return totalSupply The total supply of tokens in the collection.
   * @return mintPrice The price of minting a token in the collection.
   * @return collectionURIs An array of URIs associated with the collection.
   * @return verifier The address of the verifier for the collection.
   */
  function getCollectionInfo()
    external
    view
    returns (
      uint256 entityId,
      uint64 collectionId,
      uint8 mintType,
      uint8 mintPerAccountLimit,
      bool isWhitelisted,
      bool isFree,
      uint256 templateId,
      uint256 mintCount,
      uint256 totalSupply,
      uint256 mintPrice,
      string[] memory collectionURIs,
      address verifier
    );

  /**
   * @notice Withdraws the available balance for the caller.
   */
  function withdraw() external;

  /**
   * @notice Allows the protocol to withdraw its available balance.
   */
  function protocolWithdraw() external;

  /// Thrown when attempting to access an invalid variation.
  error InvalidVariation(string code, uint256 variationId);

  /// Thrown when the collection is sold out and no more tokens can be minted.
  error CollectionIsSoldOut(string code);

  /// Thrown when attempting to perform a mint operation with an incorrect mint type.
  error WrongMintType(string code, uint8 mintType);

  /// Thrown when the payment is invalid or insufficient.
  error InvalidPayment(string code);

  /// Thrown when no payment is required for the minting operation.
  error NoPaymentRequired(string code);

  /// Thrown when the verification process fails.
  error VerificationFailed(string code);

  /// Thrown when the mint address is not whitelisted.
  error NotWhitelisted(string code);

  /// Thrown when the caller is not the owner of the specified token.
  error NotOwner(string code, uint256 tokenId);

  /// Thrown when attempting to access the entity slot of a token that is not subscribed to any entity.
  error Unsubscribed(string code, uint256 tokenId, uint256 entityId);

  /// Thrown when the signature provided is not operative.
  error InoperativeSignature(string code);

  /// Thrown when the caller is not authorized to perform the operation.
  error NotAuthorized(string code);

  /// Thrown when the caller has insufficient balance to perform the operation.
  error InsufficientBalance(string code);

  /// Thrown when the minting limit has been reached and no more tokens can be minted for an account.
  error MintLimitReached(string code);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ImQuarkEntity.sol";

interface ImQuarkRegistry {
  /**
   * Emitted when the subscriber contract address is set.
   *
   * @param subscriber The address of the subscriber contract.
   */
  event SubscriberSet(address subscriber);
  
  /**
   * Emitted when the controller contract address is set.
   *
   * @param controller The address of the controller contract.
   */
  event ControllerSet(address controller);

  /**
   * Emitted when the implementation contract address is set for a specific ID.
   *
   * @param id             The ID of the implementation.
   * @param implementation The address of the implementation contract.
   */
  event ImplementationSet(uint256 id, address implementation);
  
  /**
   * Emitted when an entity is registered to the contract.
   *
   * @param entity                The address of the entity.
   * @param contractAddress       The address of the contract.
   * @param entityId              The ID of the entity.
   * @param entityName            The name of the entity.
   * @param description           The description of the entity.
   * @param thumbnail             The thumbnail image URL of the entity.
   * @param entityDefaultSlotURI  The default URI for the entity's slots.
   * @param subscriptionPrice     The price for the entity's subscription slot.
   */
  event EntityRegistered(
    address entity,
    address contractAddress,
    uint256 entityId,
    string entityName,
    string description,
    string thumbnail,
    string entityDefaultSlotURI,
    uint256 subscriptionPrice
  );

  /**
   * Represents an entity registered in the contract.
   */
  struct Entity {
    // The creator address of the entity
    address creator;
    // The createed contract address of the entity's creator
    address contractAddress;
    // The unique ID of the entity
    uint256 id;
    // The name of the entity
    string name;
    // The description of the entity
    string description;
    // The thumbnail image of the entity
    string thumbnail;
    // The default URI for the entity's tokens
    string entitySlotDefaultURI;
  }

  /**
   * Sets the address of the controller.
   *
   * @param controller The address of the controller contract.
   */
  function setControllerAddress(address controller) external;

  /**
   * Sets the address of the subscriber.
   *
   * @param subscriber The address of the subscriber contract.
   */
  function setSubscriberAddress(address subscriber) external;

  /**
   * Sets the address of the implementation for a specific ID.
   *
   * @param id            The ID of the implementation.
   * @param implementation The address of the implementation contract.
   */
  function setImplementationAddress(uint8 id, address implementation) external;

  /**
   * Registers an entity to the contract.
   *
   * @param entityName            The name of the entity.
   * @param description           The description of the entity.
   * @param thumbnail             The URL of the entity's thumbnail image.
   * @param entitySlotDefaultURI  The default URI for the entity's tokens.
   * @param subscriptionPrice     The price of the entity's subscription slot.
   * @return                      The address of the entity contract.
   */
  function registerEntity(
    string calldata entityName,
    string calldata description,
    string calldata thumbnail,
    string calldata entitySlotDefaultURI,
    uint256 subscriptionPrice
  ) external returns (address);

  /**
   * Returns the entity ID for a given contract address.
   *
   * @param contractAddress The address of the contract.
   * @return                The entity ID.
   */
  function getEntityId(address contractAddress) external view returns (uint256);

  /**
   * Returns the contract address for a given entity ID.
   *
   * @param entityId The ID of the entity.
   * @return         The contract address.
   */
  function getEntityAddress(uint256 entityId) external view returns (address);

  /**
   * Returns the details of a registered entity.
   *
   * @param entityId               The ID of the entity.
   * @return contractAddress       Contract address
   * @return creator               Creator address
   * @return id                    ID
   * @return name                  Name
   * @return description           Description
   * @return thumbnail             Thumbnail
   * @return entitySlotDefaultURI  Slot default URI
   * */
  function getRegisteredEntity(
    uint256 entityId
  )
    external
    view
    returns (
      address contractAddress,
      address creator,
      uint256 id,
      string memory name,
      string memory description,
      string memory thumbnail,
      string memory entitySlotDefaultURI
    );

  /**
   * Returns the subscriber contract address.
   *
   * @return The subscriber contract address.
   */
  function getSubscriber() external view returns (address);

  /**
   * Returns the controller contract address.
   *
   * @return The controller contract address.
   */
  function getController() external view returns (address);

  /**
   * Returns the price of the entity's subscription slot.
   *
   * @param entityId The ID of the entity.
   * @return          The price of the subscription slot.
   */
  function getEntitySubscriptionPrice(uint256 entityId) external view returns (uint256);

  /**
   * Returns the last entity ID.
   *
   * @return The last entity ID.
   */
  function getLastEntityId() external view returns (uint256);

  /**
   * Returns the implementation contract address for a specific ID.
   *
   * @param implementation The ID of the implementation.
   * @return                The implementation contract address.
   */
  function getImplementation(uint8 implementation) external view returns (address);

  /**
   * Returns the controller and subscriber contract addresses.
   *
   * @return The controller and subscriber contract addresses.
   */
  function getControllerAndSubscriber() external view returns (address, address);

  /**
   * Returns a boolean indicating whether the entity is registered or not.
   *
   * @param contractAddress   The contract address of the entity.
   * @return                  A boolean indicating if the entity is registered.
   */
  function getEntityIsRegistered(address contractAddress) external view returns (bool);

  /// Throws if the given address is not registered.
  error EntityAddressNotRegistered(string code, address entity);

  /// Throws if the given ID is not registered.
  error EntityIdNotRegistered(string code, uint256 entity);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @title ImQuarkSubscriber
 * @author Unbounded team
 * @notice Interface smart contract of the mQuark Subscriber.
 */
interface ImQuarkSubscriber {
  /**
   * @notice Emitted when protocol funds are withdrawn to a specified address.
   * @param to The address to which the funds are withdrawn.
   * @param amount The amount of funds withdrawn.
   */
  event WithdrawProtocol(address to, uint256 amount);

  /**
   * @notice Emitted when funds are withdrawn from an entity to a specified address.
   * @param entityId The ID of the entity from which funds are withdrawn.
   * @param to The address to which the funds are withdrawn.
   * @param amount The amount of funds withdrawn.
   */
  event Withdraw(uint256 entityId, address to, uint256 amount);

  /**
   * @notice Emitted when the royalty percentage is set.
   * @param royalty The new royalty percentage.
   */
  event RoyaltySet(uint256 royalty);

  /**
   * @notice Emitted when the registry contract address is set.
   * @param registry The address of the registry contract.
   */
  event RegistrySet(address registry);

  /**
   * @notice Emitted when the controller contract address is set.
   * @param controller The address of the controller contract.
   */
  event ControllerSet(address controller);

  /**
   * @notice Emitted when the imported contracts address is set.
   * @param importedContracts The address of the imported contracts contract.
   */
  event ImportedContractsSet(address importedContracts);

  /**
   * @notice Emitted when a token is unlocked.
   * @param tokenId The ID of the unlocked token.
   * @param tokenContract The address of the token contract.
   * @param to The address to which the unlocked token is transferred.
   * @param amount The amount of unlocked tokens transferred.
   */
  event Unlocked(uint256 tokenId, address tokenContract, address to, uint256 amount);

  /**
   * @notice Emitted when the URI slot of a token is updated.
   * @param entityId The ID of the entity associated with the token.
   * @param tokenContract The address of the token contract.
   * @param tokenId The ID of the token whose URI slot is updated.
   * @param updatedUri The updated URI value.
   */
  event URISlotUpdated(uint256 entityId, address tokenContract, uint256 tokenId, string updatedUri);

  /**
   * @notice Emitted when multiple subscriptions are made in batch.
   * @param tokenId The ID of the token for which the subscriptions are made.
   * @param tokenContract The address of the token contract.
   * @param subscriptionIds The IDs of the subscriptions made.
   * @param to The address to which the token is subscribed.
   * @param defaultUris The default URIs associated with the subscriptions.
   * @param amount The total amount paid for the subscriptions.
   */
  event SubscribedBatch(
    uint256 tokenId,
    address tokenContract,
    uint256[] subscriptionIds,
    address to,
    string[] defaultUris,
    uint256 amount
  );

  /**
   * @notice Emitted when a single subscription is made.
   * @param tokenId The ID of the token for which the subscription is made.
   * @param tokenContract The address of the token contract.
   * @param subscriptionId The ID of the subscription made.
   * @param to The address to which the token is subscribed.
   * @param defaultUri The default URI associated with the subscription.
   * @param amount The amount paid for the subscription.
   */
  event Subscribed(
    uint256 tokenId,
    address tokenContract,
    uint256 subscriptionId,
    address to,
    string defaultUri,
    uint256 amount
  );

  /**
   * @notice Emitted when the signer address is set for an entity.
   * @param entityId The ID of the entity for which the signer address is set.
   * @param signer The address of the signer.
   */
  event SignerSet(uint256 entityId, address signer);

  /**
   * @notice Emitted when the subscription price is set for an entity.
   * @param entityId The ID of the entity for which the subscription price is set.
   * @param price The subscription price.
   */
  event SubscriptionPriceSet(uint256 entityId, uint256 price);

  /**
   * @notice Emitted when the default URI is set for an entity.
   * @param entityId The ID of the entity for which the default URI is set.
   * @param defaultURI The default URI.
   */
  event DefaultURISet(uint256 entityId, string defaultURI);

  /**
   * @notice Emitted when an entity is initialized.
   * @param contractAddress The address of the entity contract.
   * @param entityId The ID of the entity.
   * @param signer The address of the entity signer.
   * @param defaultURI The default URI associated with the entity.
   * @param price The subscription price of the entity.
   */
  event EntityInitialized(address contractAddress, uint256 entityId, address signer, string defaultURI, uint256 price);

  /**
   * @notice Emitted when the entity URI of a token is transferred to another token.
   * @param fromTokenContract The address of the token contract from which the entity URI is transferred.
   * @param fromTokenId The ID of the token from which the entity URI is transferred.
   * @param toTokenContract The address of the token contract to which the entity URI is transferred.
   * @param toTokenId The ID of the token to which the entity URI is transferred.
   * @param entityId The ID of the entity associated with the entity URI.
   * @param price The price associated with the entity URI transfer.
   * @param uri The entity URI being transferred.
   * @param from The address from which the entity URI is transferred.
   * @param to The address to which the entity URI is transferred.
   */
  event TokenEntityUriTransferred(
    address fromTokenContract,
    uint256 fromTokenId,
    address toTokenContract,
    uint256 toTokenId,
    uint256 entityId,
    uint256 price,
    string uri,
    address from,
    address to
  );

  /**
   * @dev Represents the configuration of a collection.
   */
  struct Collection {
    // The ID of the entity associated with the collection.
    uint256 entityId;
    // The ID of the template.
    uint256 templateId;
    // Indicates if the collection is free.
    bool free;
    // Indicates if the collection is external.
    bool isExternal;
    // The address of the collection's contract.
    address contractAddress;
  }

  /**
   * @dev Represents the configuration of an entity.
   */
  struct EntityConfig {
    // The ID of the entity.
    uint256 entityId;
    // The subscription price for the entity.
    uint256 subscriptionPrice;
    // The address of the entity's signer.
    address signer;
    // The default URI for the entity's tokens.
    string defaultURI;
    // Indicates if the entity configuration is set.
    bool set;
  }

  struct SellOrder {
    // The order maker (the person selling the URI)
    address payable seller;
    // The "from" token contract address
    address fromContractAddress;
    // The token id whose entity URI will be sold
    uint256 fromTokenId;
    // The entity's id whose owner is selling the URI
    uint256 entityId;
    // The URI that will be sold
    string slotUri;
    // The price required for the URI
    uint256 sellPrice;
    // The salt used to generate the order hash
    bytes salt;
  }

  struct BuyOrder {
    // The order executer (the person buying the URI)
    address buyer;
    // The order maker (the person selling the URI)
    address seller;
    // The "from" token contract address
    address fromContractAddress;
    // The token id whose entity URI will be sold
    uint256 fromTokenId;
    // The "to" token contract address
    address toContractAddress;
    // The token id whose entity URI will be sold
    uint256 toTokenId;
    // The entity's id whose owner is selling the URI
    uint256 entityId;
    // The URI that will be bought
    string slotUri;
    // The price required for the URI
    uint256 buyPrice;
    // The salt used to generate the order hash
    bytes salt;
  }

  /**
   * Initializes an entity with the specified configuration.
   *
   * @param contract_ The address of the entity's contract.
   * @param entityId The ID of the entity.
   * @param signer The address of the entity's signer.
   * @param defaultURI The default URI for the entity's tokens.
   * @param price The subscription price for the entity.
   */
  function initializeEntity(
    address contract_,
    uint256 entityId,
    address signer,
    string calldata defaultURI,
    uint256 price
  ) external;

  /**
   * @notice Sets the address of the registry contract.
   * @param registry The address of the registry contract.
   */
  function setRegistryAddress(address registry) external;

  /**
   * @notice Sets the royalty amount for the contract.
   * @param royalty The royalty amount to be set.
   */
  function setRoyalty(uint256 royalty) external;

  /**
   * @notice Sets the address of the controller contract.
   * @param controller The address of the controller contract.
   */
  function setControllerAddress(address controller) external;

  /**
   * @notice Sets the address of the external collection contract.
   * @param externalCollection The address of the external collection contract.
   */
  function setImportedContractsAddress(address externalCollection) external;

  /**
   * @notice Sets the default URI for a specific entity.
   * @param entityId The ID of the entity.
   * @param defaultURI The default URI to be set.
   */
  function setDefaultURI(uint256 entityId, string calldata defaultURI) external;

  /**
   * @notice Sets the subscription price for a specific entity.
   * @param entityId The ID of the entity.
   * @param price The subscription price to be set.
   */
  function setSubscriptionPrice(uint256 entityId, uint256 price) external;

  /**
   * @notice Sets the signer address for a specific entity.
   * @param entityId The ID of the entity.
   * @param signer The signer address to be set.
   */
  function setSigner(uint256 entityId, address signer) external;

  /**
   * @notice Sets the collection details.
   * @param free Whether the collection is free or not.
   * @param external_ Whether the collection is external or not.
   * @param entityId The ID of the entity associated with the collection.
   * @param templateId The template ID of the collection.
   * @param collectionAddress The address of the collection contract.
   */
  function setCollection(
    bool free,
    bool external_,
    uint256 entityId,
    uint256 templateId,
    address collectionAddress
  ) external;

  /**
   * @notice Subscribes to a specific subscription of a token.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @param subscriptionId The ID of the subscription.
   */
  function subscribeToEntity(uint256 tokenId, address tokenContract, uint256 subscriptionId) external payable;

  /**
   * @notice Subscribes to multiple subscriptions of a token.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @param subscriptionIds An array of subscription IDs.
   */
  function subscribeToEntities(
    uint256 tokenId,
    address tokenContract,
    uint256[] calldata subscriptionIds
  ) external payable;

  /**
   * @notice Unlocks a token by providing payment.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   */
  function unlockToken(uint256 tokenId, address tokenContract) external payable;

  /**
   * @notice Transfers the token's entity URI from the seller to the buyer.
   * @dev Requires valid signatures from both the seller and the buyer.
   * @param seller The sell order containing the seller's information.
   * @param buyer The buy order containing the buyer's information.
   * @param sellerSignature The signature of the seller.
   * @param buyerSignature The signature of the buyer.
   */
  function transferTokenEntityURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable;

  /**
   * @notice Updates the URI slot with the provided update information.
   * @dev Requires a valid signature.
   * @param signature The signature of the update.
   * @param updateInfo The update information.
   */
  function updateURISlot(bytes calldata signature, bytes calldata updateInfo) external;

  /**
   * @notice Checks if a token is subscribed to a specific subscription.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @param subscriptionId The ID of the subscription.
   * @return A boolean indicating whether the token is subscribed to the specified subscription or not.
   */
  function getIsSubscribed(uint256 tokenId, address tokenContract, uint256 subscriptionId) external view returns (bool);

  /**
   * @notice Retrieves the configuration of an entity.
   * @param entityId The ID of the entity.
   * @return entityId_ The ID of the entity.
   * @return subscriptionPrice The subscription price of the entity.
   * @return defaultURI The default URI of the entity.
   * @return uriSet The URI set status of the entity.
   * @return signer The address of the signer for the entity.
   */
  function getEntityConfig(
    uint256 entityId
  )
    external
    view
    returns (uint256 entityId_, uint256 subscriptionPrice, string memory defaultURI, bool uriSet, address signer);

  /**
   * @notice Retrieves the details of a collection.
   * @param contractAddress The address of the collection contract.
   * @return entityId The ID of the entity associated with the collection.
   * @return templateId The template ID of the collection.
   * @return free The free status of the collection.
   * @return isExternal The external status of the collection.
   * @return collectionAddress The address of the collection.
   */
  function getCollection(
    address contractAddress
  ) external view returns (uint256 entityId, uint256 templateId, bool free, bool isExternal, address collectionAddress);

  /**
   * @notice Checks if a token is unlocked.
   * @param tokenId The ID of the token.
   * @param tokenContract The address of the token contract.
   * @return A boolean indicating whether the token is unlocked or not.
   */
  function getIsUnlocked(uint256 tokenId, address tokenContract) external view returns (bool);

  /**
   * @notice Retrieves the balance of an entity.
   * @param entityId The ID of the entity.
   * @return The balance of the entity.
   */
  function getEntityBalance(uint256 entityId) external view returns (uint256);

  /**
   * @notice Checks if an address is registered as an entity.
   * @param address_ The address to check.
   * @return A boolean indicating whether the address is registered as an entity or not.
   */
  function getIsAddressRegisteredAsEntity(address address_) external view returns (bool);

  /**
   * @notice Calculates the total price for a batch subscription.
   * @param subscriptionIds An array of subscription IDs.
   * @return The total price for the batch subscription.
   */
  function calculateBatchSubscriptionPrice(uint256[] calldata subscriptionIds) external view returns (uint256);

  /**
   * @notice Withdraws funds from the entity balance.
   * @param entityId The ID of the entity.
   * @param amount The amount to withdraw.
   */
  function withdraw(uint256 entityId, uint256 amount) external;

  /**
   * @notice Withdraws protocol funds.
   * @param amount The amount to withdraw.
   */
  function withdrawProtocol(uint256 amount) external;

  /// The caller is unauthorized to perform the operation
  error NotAuthorized(string code, address caller);

  /// The caller is not the registry address
  error NotRegistry(string code, address caller);

  /// The caller is not the owner of the entity with the specified ID
  error NotEntityOwner(string code, uint256 entityId);

  /// The caller is not the owner of the collection with the specified address
  error NotCollectionOwner(string code, address collectionAddress);

  /// The subscription with the specified ID is already subscribed to by the given token and token contract
  error AlreadySubscribed(string code, uint256 subscriptionId, address InvalidTokenContract, uint256 tokenId);

  /// The entity with the specified ID does not exist
  error Unexist(string code, uint256 entityId);

  /// The token with the specified ID is locked by the given contract address
  error TokenLocked(string code, address contractAddress, uint256 tokenId);

  /// The payment amount is invalid
  error InvalidPayment(string code, uint256 amount);

  /// The token contract address is invalid
  error InvalidTokenContract(string code, address contractAddress);

  /// The entity with the specified ID is not subscribed to
  error Unsubscribed(string code, uint256 entityId);

  /// Verification of signature failed
  error VerificationFailed(string code);

  /// The collection is unknown
  error UnknownCollection(string code);

  /// The collection is not free
  error NotFreeCollection(string code);

  /// The token with the specified ID is already unlocked
  error AlreadyUnlocked(string code, uint256 tokenId);

  /// The provided signature is inoperative
  error InoperativeSignature(string code);

  /// The balance is insufficient to perform the operation
  error InsufficientBalance(string code);

  /// The caller is not the owner of the token with the specified ID
  error NotOwner(string code, uint256 tokenId);

  /// The caller is not the buyer to transfer the subscription metadata
  error UnauthorizedToTransfer(string code);

  /// The price does not match the expected value
  error PriceMismatch(string code);

  /// The sent amount is invalid
  error InvalidSentAmount(string code);

  /// The token does not match the expected value
  error TokenMismatch(string code);

  /// The given entity ID does not match the expected value
  error GivenEntityIdMismatch(string code);

  /// The seller address does not match the expected value
  error SellerAddressMismatch(string code);

  /// The URI does not match the expected value
  error UriMismatch(string code);

  /// The seller is not the signer
  error SellerIsNotTheSigner(string code);

  /// The buyer is not the signer
  error BuyerIsNotTheSigner(string code);

  /// Failed to send during the transfer
  error FailedToSent(string code);

  /// The collection at the specified token contract address is invalid
  error InvalidCollection(string code, address tokenContract);

  /// The royalty value is too high
  error RoyaltyIsTooHigh(string code);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ImQuarkTemplate {
  /**
   * @notice Emitted when a new category is created.
   * @param category The name of the category.
   * @param id The ID of the category.
   * @param selector The selector of the category.
   * @param uri The URI of the category.
   */
  event CategoryCreated(string category, uint256 id, bytes4 selector, string uri);

  /**
   * @notice Emitted when a new template is created.
   * @param templateId The ID of the created template.
   * @param uri The URI of the template.
   */
  event TemplateCreated(uint256 templateId, string uri);
  
  /**
   * @notice Emitted when categories are set for a group of templates.
   * @param category The name of the category.
   * @param templateIds The IDs of the templates associated with the category.
   */
  event CategoriesSet(string category, uint256[] templateIds);

  /**
   * @notice Emitted when a template is removed from a category.
   * @param category The name of the category.
   * @param templateId The ID of the removed template.
   */
  event CategoryRemoved(string category, uint256 templateId);

  struct Category {
    // The ID of the category
    uint256 id;
    // The selector of the category
    bytes4 selector;
    // The name of the category
    string name;
    // The URI of the category
    string uri;
  }

  /**
   * @notice Creates a new template with the given URI, which will be inherited by collections.
   * @param uri The metadata URI that will represent the template.
   */
  function createTemplate(string calldata uri) external;

  /**
   * @notice Creates multiple templates with the given URIs, which will be inherited by collections.
   * @param uris The metadata URIs that will represent the templates.
   */
  function createBatchTemplate(string[] calldata uris) external;

  /**
   * @notice Creates a new category with the given name and URI.
   * @param name The name of the category.
   * @param uri The metadata URI that will represent the category.
   */
  function createCategory(string calldata name, string calldata uri) external;

  /**
   * @notice Creates multiple categories with the given names and URIs.
   * @param names The names of the categories.
   * @param uris The metadata URIs that will represent the categories.
   */
  function createBatchCategory(string[] calldata names, string[] calldata uris) external;

  /**
   * @notice Sets the category for multiple templates.
   * @param category The name of the category.
   * @param templateIds_ The IDs of the templates to assign to the category.
   */
  function setTemplateCategory(string calldata category, uint256[] calldata templateIds_) external;

  /**
   * @notice Removes a category assignment from a template.
   * @param category The name of the category.
   * @param templateId The ID of the template to remove from the category.
   */
  function removeCategoryFromTemplate(string memory category, uint256 templateId) external;

  /**
   * @notice Retrieves all template IDs assigned to a specific category.
   * @param category The name of the category.
   * @return An array of template IDs assigned to the category.
   */
  function getAllCategoryTemplates(string memory category) external view returns (uint256[] memory);

  /**
   * @notice Retrieves a batch of template IDs assigned to a specific category based on an index range.
   * @param category The name of the category.
   * @param startIndex The start index of the batch.
   * @param batchLength The length of the batch.
   * @return An array of template IDs assigned to the category within the specified index range.
   */
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) external view returns (uint256[] memory);

  /**
   * @notice Retrieves the categories associated with a template based on its ID.
   * @param templateId The ID of the template.
   * @return An array of category names associated with the template.
   */
  function getTemplatesCategory(uint256 templateId) external view returns (string[] memory);

  /**
   * @notice Retrieves the number of templates assigned to a specific category.
   * @param category The name of the category.
   * @return The number of templates assigned to the category.
   */
  function getCategoryTemplateLength(string calldata category) external view returns (uint256);

  /**
   * @notice Retrieves category information by its name.
   * @param name The name of the category.
   * @return id The ID of the category.
   * @return selector The selector of the category.
   * @return uri The URI of the category.
   */
  function getCategoryByName(
    string calldata name
  ) external view returns (uint256 id, bytes4 selector, string memory uri);

  /**
   * @notice Retrieves category information by its ID.
   * @param id The ID of the category.
   * @return selector The selector of the category.
   * @return name The name of the category.
   * @return uri The URI of the category.
   */
  function getCategoryById(uint256 id) external view returns (bytes4 selector, string memory name, string memory uri);

  /**
   * @notice Retrieves category information by its selector.
   * @param selector The selector of the category.
   * @return id The ID of the category.
   * @return name The name of the category.
   * @return uri The URI of the category.
   */
  function getCategoryBySelector(
    bytes4 selector
  ) external view returns (uint256 id, string memory name, string memory uri);

  /**
   * @notice Retrieves the metadata URI of a template based on its ID.
   * @param templateId The ID of the template.
   * @return The metadata URI of the template.
   */
  function templateUri(uint256 templateId) external view returns (string memory);

  /**
   * @notice Retrieves the ID of the last created template.
   * @return The ID of the last created template.
   */
  function getLastTemplateId() external view returns (uint256);

  /**
   * @notice Checks if a template with the given ID exists.
   * @param templateId The ID of the template.
   * @return exist A boolean indicating if the template exists.
   */
  function isTemplateIdExist(uint256 templateId) external view returns (bool exist);

  /// Throws if a specified batch limit has been exceeded.
  error ExceedsLimit(string code);

  /// Throws if there is a mismatch in the length of arrays.
  error ArrayLengthMismatch(string code);

  /// Throws if the specified category does not exist.
  error UnexistingCategory(string code);

  /// Throws if the specified template does not exist.
  error UnexistingTemplate(string code);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IOwnable {
  function owner() external view returns (address);
  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @notice Represents the subscription information for a token.
 */
struct TokenSubscriptionInfo {
  // Indicates whether the token is subscribed or not
  bool isSubscribed;
  // The URI associated with the token
  string uri;
}

struct Collection {
  // The ID of the entity associated with the collection
  uint256 entityId;
  // The ID of the collection
  uint64 collectionId;
  // The type of minting for the collection
  uint8 mintType;
  // The maximum number of tokens that can be minted per wallet
  uint8 mintPerAccountLimit;
  // A flag indicating if the collection is whitelisted
  bool isWhitelisted;
  // A flag indicating if the collection is free
  bool isFree;
  // The ID of the template associated with the collection
  uint256 templateId;
  // The number of tokens minted in the collection
  uint256 mintCount;
  // The total supply of tokens in the collection
  uint256 totalSupply;
  // The price of minting a token in the collection
  uint256 mintPrice;
  // The available URIs associated with the collection
  string[] collectionURIs;
  // The name of the collection
  string name;
  // The symbol of the collection
  string symbol;
  // The address of the verifier
  address verifier;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ImQuarkNFT.sol";
import "./interfaces/ImQuarkRegistry.sol";
import "./interfaces/ImQuarkController.sol";
import "./interfaces/ImQuarkSubscriber.sol";
import "./interfaces/ImQuarkEntityDeployer.sol";
import "./interfaces/ImQuarkEntity.sol";
import "./interfaces/IInitialisable.sol";
import "./utils/noDelegateCall.sol";
import "./interfaces/IOwnable.sol";

contract mQuarkEntity is ImQuarkEntity, Ownable, NoDelegateCall, ReentrancyGuard {
  receive() external payable {}

  //* =============================== MAPPINGS ======================================================== *//

  // Mapping from collection ID to address.
  // Stores the addresses associated with each collection ID.
  mapping(uint64 => address) private s_allCollections;

  //* =============================== VARIABLES ======================================================= *//

  // The registry contract address.
  ImQuarkRegistry public immutable s_registry;

  // The subscriber contract address.
  address public immutable s_subscriber;

  // The ID of the entity.
  uint256 public immutable s_ID;

  // The last created collection ID.
  uint64 private s_lastCollectionId;

  //* =============================== MODIFIERS ======================================================= *//

  modifier onlyCollection(uint64 _collectionId) {
    require(s_allCollections[_collectionId] == msg.sender, "mQuarkEntity: caller is not the collection");
    _;
  }

  modifier onlyEntity() {
    require(s_registry.getEntityIsRegistered(msg.sender) == true, "mQuarkEntity: caller is not the entity");
    _;
  }

  //* =============================== CONSTRUCTOR ===================================================== *//

  constructor() {
    address m_owner;
    (s_registry, s_subscriber, m_owner, s_ID) = ImQuarkEntityDeployer(msg.sender).parameters();
    _transferOwnership(m_owner);
  }

  //* =============================== FUNCTIONS ======================================================= *//
  // * ============== EXTERNAL =========== *//
  /**
   * @notice Creates a new collection instance.
   * @dev Only the owner can call this function.
   * 
   * @param _collectionParams The parameters for the collection.
   *                          uint256 templateId        The ID of the template associated with the collection
   *                          string[] collectionURIs   The URIs associated with the collection
   *                          uint256 totalSupply       The total supply of tokens in the collection
   *                          uint256 mintPrice         The price of minting a token in the collection
   *                          uint8 mintPerAccountLimit The maximum number of tokens that can be minted per wallet
   *                          string name               The name of the collection
   *                          string symbol             The symbol of the collection
   *                          address verifier          The address of the verifier contract
   *                          bool isWhitelisted        A flag indicating if the collection is whitelisted
   * 
   * @param _isDynamicUri Flag indicating if the collection has dynamic URIs.
   * @param _ERCimplementation The implementation of the ERC contract.
   * @param _merkelRoot The Merkel root of the collection if it is whitelisted.
   * @return _instance The address of the new collection instance.
   * 
   * @dev If the isWhitelisted is set to true, the collection will be whitelisted and _merkleRoot will not be ignored.
   *      If the isWhitelisted is set to false, the collection will not be whitelisted and _merkleRoot will be ignored.
   * 
   * @dev If isDynamicUri set to true provided URIs will be ignored
   *      If isDynamicUri set to false provided URIs will be used
   */
  function createCollection(
    CollectionParams memory _collectionParams,
    bool _isDynamicUri,
    uint8 _ERCimplementation,
    bytes32 _merkelRoot
  ) external noDelegateCall onlyOwner returns (address _instance) {
    if (_collectionParams.collectionURIs.length > 1 && _isDynamicUri)
      revert InvalidURILength("IUL",_collectionParams.collectionURIs.length);
    if (_collectionParams.totalSupply == 0) revert TotalSupplyIsZero("TSZ");
    (address m_controller, address m_subscriber) = ImQuarkRegistry(s_registry).getControllerAndSubscriber();
    (uint256 m_royalty, uint256 m_limitMintPrice) = ImQuarkController(m_controller).getRoyaltyAndMintPrice(
      _collectionParams.templateId
    );

    if (m_limitMintPrice == 0) revert InvalidTemplate("IT",_collectionParams.templateId);
    if ((_collectionParams.mintPrice < m_limitMintPrice) && (_collectionParams.mintPrice != 0))
      revert InvalidCollectionPrice("ICP",_collectionParams.mintPrice);
    uint8 m_mintType;
    
    /// @notice Paid collection
    if (_collectionParams.mintPrice > 0) {
      if (_collectionParams.collectionURIs.length > 1) {
        m_mintType = _collectionParams.isWhitelisted ? 0 : 1;
        /// @notice 0 => paid | limited variation | whitelist
        /// @notice 1 => paid | limited variation | no whitelist
      } else {
        if (_isDynamicUri) {
          m_mintType = _collectionParams.isWhitelisted ? 2 : 3;
          /// @notice 2 => paid | dynamic variation | whitelist
          /// @notice 3 => paid | dynamic variation | no whitelist
        } else {
          m_mintType = _collectionParams.isWhitelisted ? 4 : 5;
          /// @notice 4 => paid | static variation | whitelist
          /// @notice 5 => paid | static variation | no whitelist
        }
      }
    } else {
      if (_collectionParams.collectionURIs.length > 1) {
        m_mintType = _collectionParams.isWhitelisted ? 6 : 7;
        /// @notice 6 => free | limited variation | whitelist
        /// @notice 7 => free | limited variation | no whitelist
      } else {
        if (_isDynamicUri) {
          m_mintType = _collectionParams.isWhitelisted ? 8 : 9;
          /// @notice 8 => free | dynamic variation | whitelist
          /// @notice 9 => free | dynamic variation | no whitelist
        } else {
          m_mintType = _collectionParams.isWhitelisted ? 10 : 11;
          /// @notice 10 => free | static variation | whitelist
          /// @notice 11 => free | static variation | no whitelist
        }
      }
    }

    string[] memory m_uris;
    bool m_free = _collectionParams.mintPrice == 0 ? true : false;

    m_uris = _isDynamicUri ? new string[](1) : _collectionParams.collectionURIs;

    _instance = Clones.clone(ImQuarkRegistry(s_registry).getImplementation(_ERCimplementation));

    Collection memory m_collection = Collection({
      collectionId: ++s_lastCollectionId,
      entityId: s_ID,
      templateId: _collectionParams.templateId,
      collectionURIs: _isDynamicUri ? new string[](1) : _collectionParams.collectionURIs,
      totalSupply: _collectionParams.totalSupply,
      mintPrice: _collectionParams.mintPrice,
      mintCount: 0,
      mintPerAccountLimit: _collectionParams.mintPerAccountLimit,
      name: _collectionParams.name,
      symbol: _collectionParams.symbol,
      verifier: _collectionParams.verifier,
      mintType: m_mintType,
      isWhitelisted: _collectionParams.isWhitelisted,
      isFree: m_free
    });
    
    bytes32 m_merkleRoot;
    
    m_collection.isWhitelisted ? m_merkleRoot = _merkelRoot : m_merkleRoot = bytes32(0);
    
    IInitialisable(_instance).initilasiable(m_collection, msg.sender, m_controller, m_merkleRoot, m_royalty);

    s_allCollections[m_collection.collectionId] = _instance;

    ImQuarkSubscriber(m_subscriber).setCollection(
      m_free,
      false,
      m_collection.entityId,
      _collectionParams.templateId,
      _instance
    );

    emit CollectionCreated(
      _instance,
      m_collection.verifier,
      m_controller,
      m_collection.entityId,
      m_collection.collectionId,
      m_collection.templateId,
      m_collection.mintPrice,
      m_collection.totalSupply,
      m_collection.mintPerAccountLimit,
      m_royalty,
      m_collection.collectionURIs,
      m_collection.mintType,
      _isDynamicUri,
      m_collection.isFree,
      m_collection.isWhitelisted
    );
  }

  /**
   * @notice Imports an external collection into the system.
   * @dev Only the owner can call this function.
   * @param _templateId The template ID of the collection.
   * @param _collectionAddress The address of the external collection contract.
   */
  function importExternalCollection(uint256 _templateId, address _collectionAddress) external onlyOwner noDelegateCall {
    if (IOwnable(_collectionAddress).owner() != msg.sender) revert NotCollectionOwner("NCO",_collectionAddress);
    try IERC165(_collectionAddress).supportsInterface(type(IERC721).interfaceId) returns (bool result) {
      if (result) {
        if (IERC165(_collectionAddress).supportsInterface(type(ImQuarkNFT).interfaceId))
          revert NotExternal("NE",_collectionAddress);
        address m_subscriber = ImQuarkRegistry(s_registry).getSubscriber();
        uint256 _entityId = s_ID;
        uint64 _collectionId = ++s_lastCollectionId;
        ImQuarkSubscriber(m_subscriber).setCollection(true, true, _entityId, _templateId, _collectionAddress);
        emit ExternalCollectionCreated(_collectionAddress, _entityId, _templateId, _collectionId);
      } else {
        revert NoERC721Support("N721",_collectionAddress);
      }
    } catch {
      revert NoERC165Support("N165",_collectionAddress);
    }
  }

  /**
   * @notice Transfers ownership of a collection to a new owner.
   * @dev Only the owner can call this function.
   * @param _newOwner The address of the new owner.
   * @param _collectionId The ID of the collection.
   */
  function transferOwnershipOfCollection(address _newOwner, uint64 _collectionId) external onlyOwner noDelegateCall {
    address m_collectionAddress = s_allCollections[_collectionId];
    if (m_collectionAddress == address(0)) revert InvalidCollection("IC",_collectionId);
    ImQuarkNFT(m_collectionAddress).transferCollectionOwnership(_newOwner);
  }

  /**
   * @notice Transfers a collection to an entity.
   * @dev Only the collection contract can call this function.
   * @param _entity The address of the entity.
   * @param _collectionId The ID of the collection.
   * @return m_collectionId The ID of the transferred collection in the entity.
   */
  function transferCollection(
    address _entity,
    uint64 _collectionId
  ) external noDelegateCall onlyCollection(_collectionId) returns (uint64 m_collectionId) {
    if (!s_registry.getEntityIsRegistered(_entity)) revert InvalidEntity("IE",_entity);
    address m_collectionAddress = s_allCollections[_collectionId];
    m_collectionId = ImQuarkEntity(_entity).addNewCollection(m_collectionAddress);
    delete s_allCollections[_collectionId];
  }

  /**
   * @notice Adds a new collection to the entity.
   * @dev Only the entity contract can call this function.
   * @param _collectionAddress The address of the collection contract.
   * @return uint64 The ID of the newly added collection.
   */
  function addNewCollection(address _collectionAddress) external noDelegateCall onlyEntity returns (uint64) {
    s_allCollections[++s_lastCollectionId] = _collectionAddress;
    return s_lastCollectionId;
  }

  /**
   * @notice Collects funds from multiple collections.
   * @dev Only the contract owner can call this function.
   * @param _ids The IDs of the collections to collect funds from.
   */
  function collectFunds(uint64[] calldata _ids) external onlyOwner noDelegateCall nonReentrant {
    uint256 m_length = _ids.length;
    address m_collection;
    for (uint256 i = 0; i < m_length; i++) {
      m_collection = (s_allCollections[_ids[i]]);
      if (m_collection == address(0)) revert InvalidCollection("IC",_ids[i]);
      ImQuarkNFT(m_collection).withdraw();
    }
  }

  /**
   * @notice Withdraws the accumulated balance from the contract.
   * @dev Only the owner can call this function.
   * @dev This function transfers the entire balance of the contract to the owner's address.
   * @dev If the transfer fails, it reverts with an error message.
   */
  function withdraw() external onlyOwner noDelegateCall {
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  // * ============== VIEW =============== *//
  /**
   * @notice Retrieves the address of a collection given its ID.
   * @param collectionId The ID of the collection.
   * @return The address of the collection.
   */
  function getCollectionAddress(uint64 collectionId) external view noDelegateCall returns (address) {
    return s_allCollections[collectionId];
  }

  /**
   * @notice Retrieves the ID of the last collection created.
   * @return The ID of the last collection.
   */
  function getLastCollectionId() external view noDelegateCall returns (uint64) {
    return s_lastCollectionId;
  }

  /**
   * @notice Retrieves the Ether balance of the contract.
   * @return The current balance of the contract in wei.
   */
  function getBalance() external view noDelegateCall returns (uint256) {
    return address(this).balance;
  }

  /**
   * @notice Retrieves information about the entity.
   * @return contractAddress The address of the entity contract.
   * @return creator The address of the entity creator.
   * @return id The ID of the entity.
   * @return name The name of the entity.
   * @return description The description of the entity.
   * @return thumbnail The URI of the entity's thumbnail image.
   * @return entitySlotDefaultURI The default URI for entity slots.
   */
  function getEntityInfo()
    external
    view
    noDelegateCall
    returns (
      address contractAddress,
      address creator,
      uint256 id,
      string memory name,
      string memory description,
      string memory thumbnail,
      string memory entitySlotDefaultURI
    )
  {
    return s_registry.getRegisteredEntity(s_ID);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./mQuarkEntity.sol";
import "./interfaces/ImQuarkRegistry.sol";

contract mQuarkEntityDeployer is ImQuarkEntityDeployer {
  struct Parameters {
    ImQuarkRegistry registry;
    address subscriber;
    address owner;
    uint256 id;
  }

  Parameters public override parameters;

  /**
   * @dev This function deploys a entity using the provided parameters. It does so by temporarily setting the
   *      parameters storage slot and then clearing it once the entity has been deployed.
   *
   * @param _registry              The registry address of the mQuark protocol
   * @param _subscriber            The subscriber address of the mQuark protocol
   * @param _owner                 The EOA address that is creating the entity
   * @param _id                    The uint value of the entity ID
   */
  function deploy(
    ImQuarkRegistry _registry,
    address _subscriber,
    address _owner,
    uint256 _id
  ) internal returns (address entity) {
    parameters = Parameters({registry: _registry, subscriber: _subscriber, owner: _owner, id: _id});
    entity = address(new mQuarkEntity{salt: keccak256(abi.encode(_registry, _owner, _id))}());
    delete parameters;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

contract NoDelegateCall {
  // adding no deligate call here for global access
  address private immutable s_original;


  constructor() {
    s_original = address(this);
  }



  function testNoDelegateCall() private view {
    require(address(this) == s_original);
  }



  /**
   * Prevents delegatecall into the modified method
   */
  modifier noDelegateCall() {
    testNoDelegateCall();
    _;
  }
}