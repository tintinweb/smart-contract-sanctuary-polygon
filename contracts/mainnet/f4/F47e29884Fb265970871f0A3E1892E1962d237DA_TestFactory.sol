// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITestBaseCollection {
    /// @dev Not enough `_msgSender()` balance
    error InsufficientBalance();

    /// @dev The collection `cap` == `minted`
    error SoldOut();

    /// @dev Cannot mint to the zero address.
    error MintToZeroAddress();

    /// @dev The quantity of tokens minted must be more than zero.
    error MintZeroQuantity();

    /// @dev The`quantity` minted exceeds the safety limit
    error MintQuantityExceedsLimit();

    /// @dev TokenID must exist to mint an item
    error MintNonExistingItem();

    /// @dev Trying to enable already limited collection
    error AlreadyLimitedCollection();

    /// @dev The value cannot be zero
    error SetToZeroQuantity();

    /// @dev Cannot create item with tokenId == 0
    error UnableToSetTokenIdWithZeroValue();

    /// @dev Cap cannot be 0 or less than the previous cap set
    error UnableToIncreaseCap();

    /// @dev Revert when price * quantity != msg.value
    error InvalidMintAmount();

    /// @dev Add existing tokenId
    error TokenIdAlreadyExist();

    /// @dev caller is not aiskin factory
    error CallerNotAiskinFactory();

    /// @dev Calling non existing token id
    error NonExistingTokenId();

    event CreateItem(
        uint256 indexed tokenId,
        address indexed collection,
        uint256 cap,
        uint256 priceInWei,
        bool limited
    );

    event MintItem(
        address operator,
        address indexed to,
        address indexed creator,
        uint256 indexed tokenId,
        uint256 price,
        uint256 amount
    );

    event IncreaseCap(uint256 indexed tokenId, uint256 oldCap, uint256 newCap);

    event EnableLimitedCollection(uint256 tokenId);

    struct Item {
        uint256 tokenId;
        address creator;
        address tokenPayment;
        uint256 priceInWei;
        uint256 shareFee;
        uint256 cap;
        uint256 minted;
        bool limited;
    }

    /**
     * @dev Create item on master collection, Emits {IBaseCollection-CreateItem}.
     *
     * Requires:
     *  - caller must be factory address
     *
     * @param tokenId The item token id
     * @param creator The item owner/creator
     * @param tokenPayment The item token payment address. address(0) for native token
     * @param priceInWei The item mint price in wei
     * @param shareFee The sale share fee percent
     * @param cap The item cap/supply
     * @param limited If true, allow creator/owner to update the cap/supply
     */
    function createItem(
        uint256 tokenId,
        address creator,
        address tokenPayment,
        uint256 priceInWei,
        uint256 shareFee,
        uint256 cap,
        bool limited
    ) external payable;

    /**
     * @dev Allows the factory to mint a certain amount of items after creating an item.
     *
     * Requirements:
     *  - Caller must be the factory address.
     *  - `preMinted` must be greater than zero.
     *
     * @param creator The item creator.
     * @param tokenId The token ID of the item to mint.
     * @param preMinted The amount of items to mint.
     */
    function mintItemOnPublish(
        address creator,
        uint256 tokenId,
        uint256 preMinted
    ) external;

    /**
     * @dev Mint item to address
     *
     * @param to The address to mint
     * @param tokenId The token id to mint
     * @param amount The amount to mint
     */
    function mintItem(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external payable;

    /**
     * @dev Limit tokenId supply to the current cap. enabling item that already limited will revert {IBaseCollection-AlreadyLimitedCollection}. Emits {IBaseCollection-EnableLimitedCollection}
     *
     * Note: limited item cannot increase supply
     *
     * Requirements:
     *  - tokenId must not limited == True. See {IBaseCollection-Item} struct
     *
     * @param tokenId The token id to limit
     */
    function enableLimited(uint256 tokenId) external;

    /**
     *  @dev Can only increase item that is not limited and new cap must not less than item minted else it will revert {IBaseCollection-UnableToIncreaseCap}.
     *  Emits {IBaseCollection-IncreaseCap}
     *
     * Requirements:
     *  - caller must be creator or collection owner
     *
     * @param tokenId The item token id to increase supply
     * @param cap The item supply
     */
    function increaseCap(uint256 tokenId, uint256 cap) external;

    /**
     * @dev Getter for Item struct by tokenId. See {IBaseCollection-Item}
     *
     * @param tokenId The item token id
     */
    function getItemInfo(uint256 tokenId) external view returns (Item memory);

    /**
     * @dev Getter for aiskin factory address
     */
    function aiskinFactory() external view returns (address);

    /**
     * @dev Getter for contract name
     */
    function name() external view returns (string calldata);

    /**
     * @dev Getter for contract symbol
     */
    function symbol() external view returns (string calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ITestBaseCollection} from "./ITestBaseCollection.sol";

interface ITestDropCollection is ITestBaseCollection {
    /**
     * @dev caller is not the owner
     */
    error CallerNotOwner();

    /**
     * @dev Create initialize minimal proxy collection. See {ERC-1167: https://eips.ethereum.org/EIPS/eip-1167}
     *
     * @param aiskinFactory The askin factory address
     * @param owner The contract owner/creator
     * @param name The contract name. See {IBaseCollection-name}
     * @param symbol The contract symbol. See (IBaseCollection-symbol)
     */
    function initialize(
        address aiskinFactory,
        address owner,
        string memory name,
        string memory symbol
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITestFactory {
    /// @dev implementation must be on whitelist
    error InvalidImplementation();

    /// @dev fee/share not enough
    error InsufficientPaymentBalance();

    /// @dev setting zero address to beneficiary
    error BeneficiarySetToZeroAddress();

    /// @dev only allow creator/ownner to create item
    error CallerNotOwner();

    /// @dev deadline most > block.timestamp
    error DeadlineExpired();

    /// @dev collection that not created from aiskin factory
    error UnsupportedCollection();

    /// @dev caller not valid signer
    error Unauthorized(bytes32 role, address signer);

    /// @dev User set item mint price is less than the required minimum mint value. See {AISKinFactory-_tokenPaymentMinimumMintPrice}
    error MintPriceLessMinMintRequirement();

    event SetImplementation(uint96 typeId, address implementation);

    event CreateCollection(
        address indexed creator,
        address indexed collectionAddress,
        string collectionName,
        string symbol,
        uint256 timestamp
    );

    event SetMasterCollection(
        address indexed caller,
        address oldAddrs,
        address newAddrs
    );

    event SetTreasury(
        address indexed caller,
        address oldAddrs,
        address newAddrs
    );

    event AddTokenPaymentMinimumMintPrice(
        address indexed caller,
        address tokenPayment,
        uint256 minMintPrice
    );

    event UpdateMintShareFee(
        address indexed caller,
        uint256 oldShare,
        uint256 newShare
    );

    event UpdateFreebiesPublishAmount(
        address indexed caller,
        uint256 oldAmount,
        uint256 newAmount
    );

    event UpdateRoyaltyInfo(
        address indexed caller,
        RoyaltyInfo oldRoyaltyInfo,
        RoyaltyInfo newRoyaltyInfo
    );

    event UpdateBaseToken(
        address indexed caller,
        address oldBaseToken,
        address newBaseToken
    );

    event UpdateCreateCollectionFee(
        address indexed caller,
        uint256 oldFee,
        uint256 newFee
    );

    event UpdatePublishItemFee(
        address indexed caller,
        uint256 oldFee,
        uint256 newFee
    );

    struct ShareOverride {
        bool isOverride;
        uint256 share;
    }

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    struct PublishItemParams {
        uint256 tokenId;
        uint256 deadline;
        address collection;
        uint256 cap;
        address tokenPayment;
        uint256 priceInWei;
        bool limited;
        uint256 preMinted;
    }

    /**
     * @dev Create a creator onwed collection using `minimal proxy contract` (ERC-1167).
     *
     * Reference:
     *  See {ERC-1167: https://eips.ethereum.org/EIPS/eip-1167} for Minimal Proxy Contract
     *
     * Note:
     * - creator needs to pay fee to create new collection. See {AISkinCollection-_createCollectionFee}
     *
     * @param typeId The minimal proxy implementation typeId. See {IAISkinFactory-setImplementation}
     * @param name The contract name
     * @param symbol The contract symbol
     */
    function createCollection(
        uint96 typeId,
        string memory name,
        string memory symbol
    ) external payable;

    /**
     * @dev Publish a new item in either the master collection or the creator's collection. This action emits an {IBaseCollection-CreateItem} event in the target collection.
     *
     * Requirements:
     *  - A signature is necessary to publish a new item in a collection.
     *  - The signature signer address must possess either the `PUBLISHER_SIGNER` or `FREE_PUBLISHER_SIGNER` role.
     *
     * Note:
     *  - A signer with the `keccak256(PUBLISHER_SIGNER)` role requires the caller/creator to pay a fee when publishing an item.
     *  - A signer with the `keccak256(FREE_PUBLISHER_SIGNER)` role allows publishing without payment validation.
     *
     * @param params A struct containing the following fields:
     *  - tokenId: The unique identifier of the token.
     *  - deadline: The timestamp for the signature's expiration.
     *  - collection: The address of the collection where the item will be published.
     *  - cap: The maximum supply of the collection.
     *  - tokenPayment: The address for the item's token payment. Use address(0) for native tokens.
     *  - priceInWei: The item's mint price in wei.
     *  - limited: If true, allows the creator/owner to update the cap/supply.
     *  - preMinted: The number of tokens to be minted for the creator's address.
     * @param signature The signature of the signer to be validated.
     */
    function publishItem(
        PublishItemParams memory params,
        bytes memory signature
    ) external payable;

    /**
     * @dev Update number of freebies upon publishing. Emits {IAISkinFactory-UpdateFreebiesPublishAmount}
     *
     * Requirements:
     *  - caller must have keccak256(MANAGER_ROLE) role
     *
     * @param amount The freebies amount
     */
    function updateFreebiesPublishAmount(uint256 amount) external;

    /**
     * @dev Set minimal proxy implementation. See {EIP-1167: https://eips.ethereum.org/EIPS/eip-1167}
     *
     * @param typeId The implementation id
     * @param impl The implementation address
     */
    function setImplementation(uint96 typeId, address impl) external;

    /**
     * @dev Set aiskin master collection address. Emits {IAISkinFactory-SetMasterCollection}
     *
     * Requirements:
     * - caller must have keccak256(MANAGER_ROLE) role
     *
     * @param masterCollection The master collection address
     */
    function setMasterCollection(address masterCollection) external;

    /**
     * @dev Treasury address receives payments when creator publishes item or create collection. See {IASkinCollection-publishItem} {IAISkinCollection-createCollection}
     *
     * @param treasury The treasury address
     */
    function setTreasury(address treasury) external;

    /**
     * @dev Update aiskin default item mint share. Emits {IAISkinFactory-UpdateMintShare}
     *
     * Requirements:
     *  - caller must have keccak256(MANAGER_ROLE) role
     *
     * @param defaultShare The mint default share
     */
    function updateMintShareFee(uint256 defaultShare) external;

    /**
     * @dev Modify the baseToken. Emits {IAISkinFactory-UpdateBaseToken} event.
     *
     * Requirements:
     *  - caller must have keccak256(MANAGER_ROLE) role
     *
     * @param baseToken he updated base token address.
     */
    function updateBaseToken(address baseToken) external;

    /**
     * @dev Add minimum token mint price for token payment. Emits {AddTokenPaymentMinimumMintPrice}
     *
     * Requirements:
     *  - caller must have keccak256(MANAGER_ROLE) role
     *
     * @param tokenPayment The token to used for payment
     * @param minimumMintPrice The minimum mint value
     */
    function addTokenPaymentMinMintPrice(
        address tokenPayment,
        uint256 minimumMintPrice
    ) external;

    /**
     * @dev Update aiskin royalty info. Emits {IAISkinFactory-RoyaltyInfo}
     *
     * Requirements:
     *  - caller must have keccak256(MANAGER_ROLE) role
     *
     * @param receiver The royalty receiver
     * @param royaltyFraction The royalty fraction
     */
    function updateRoyaltyInfo(
        address receiver,
        uint96 royaltyFraction
    ) external;

    /**
     * @dev Updates the fee associated with creating a new collection. Emits {UpdateCreateCollectionFee}
     *
     * Requirements:
     *  - Caller must have keccak256(MANAGER_ROLE) role
     *
     * @param createCollectionFee The new fee for creating a collection
     */
    function updateCreateCollectionFee(uint256 createCollectionFee) external;

    /**
     * @dev Updates the fee for publishing a new item in a creator's collection or the master collection. Emits {UpdatePublishItemFee}
     *
     * Requirements:
     *  - Caller must have keccak256(MANAGER_ROLE) role
     *
     * @param publishItemFee The new fee for publishing an item.
     */
    function updatePublishItemFee(uint256 publishItemFee) external;

    /**
     * @dev Get Minimal Proxy Implementation. See {https://eips.ethereum.org/EIPS/eip-712},
     *  return address(0) if `typeId` does not exist
     *
     * @param typeId The implementation Id
     */
    function getImplementation(uint96 typeId) external view returns (address);

    /**
     * @dev Getter for creator created collections. See {IAISkinFactory-createCollection}
     * @param creator The collection owner
     */
    function getCreatorCollections(
        address creator
    ) external view returns (address[] memory);

    /**
     * @dev Determine the fee necessary for the creator to mint a specific amount of tokens.
     *
     * This function calculates the cost, in wei, that the creator needs to pay in order to mint a given
     * quantity of tokens (specified by {preMinted}) to their own address, based on the collection's mint fee price.
     *
     * @param preMinted The desired quantity of tokens to be minted and assigned to the creator's address.
     * @param mintPriceInWei The mint fee price for the collection, expressed in wei.
     */
    function calculateCreatorPublishPremintFee(
        uint256 preMinted,
        uint256 mintPriceInWei
    ) external view returns (uint256);

    /**
     * @dev Check if collection address is on aiskin whitelisted collection. See {AISkinFactory-_collections}
     *
     * @return True if collection is whitelisted else False
     */
    function isValidCollection(address collection) external view returns (bool);

    /**
     * @dev Getter for treasury address
     */
    function getTreasury() external view returns (address);

    /**
     * @dev Getter for aiskin master collection address
     */
    function getAiskinMasterCollection() external view returns (address);

    /**
     * @dev Getter for aiskin mint share fee points
     */
    function getMintShareFee() external view returns (uint256);

    /**
     * @dev Getter for amount of token to mint on creator upon publishing new item
     */
    function getPublishFreebiesAmount() external view returns (uint256);

    /**
     * @dev Getter for collection address by index
     *
     * @param index The collection index
     */
    function getCollectionAt(uint256 index) external view returns (address);

    /**
     * @dev Getter for royalty info. See {IAISkinFactory-RoyaltyInfo}
     *
     * @return (royaltyReceiver, royaltyFraction)
     */
    function getRoyaltyInfo() external view returns (address, uint96);

    /**
     * @dev Getter for baseToken address
     */
    function getBaseToken() external view returns (address);

    /**
     * @dev Getter for creator collection fee. See {IAISkinFactory-createCollection}
     */
    function getCreateCollectionFee() external view returns (uint256);

    /**
     * @dev Getter for publish item fee. See {IAISkinFactory-publishItem}
     */
    function getPublishItemFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ITestBaseCollection} from "./ITestBaseCollection.sol";

interface ITestMasterCollection is ITestBaseCollection {
    /// @dev Caller doesnt have `role` permission to call the function
    error Unauthorized(bytes32 role);

    /// @dev Revert when _aiskins[n].refCollection == address(0)
    error TransferDropCollection();

    /// @dev Only creator can call function
    error CallerNotCreator();

    /// @dev Unable to create Item that already exist on Drop Collection
    error TokenIdExistOnDropCollection();

    /// @dev Emits an event once a user mints an item in the drop collection. This action restricts the user from listing their copy in the master collection, provided the exchange honors the EIP-5192 standard. See {https://eips.ethereum.org/EIPS/eip-5192}
    event Locked(uint256 tokenId);

    /**
     * @notice Creator created collection registered on AISkinMasterCollection
     *
     * @dev Register created creator collection on aiskin master collection. If `tokenId` already registered/whitelisted, Revert {TokenIdAlreadyExist}
     *
     * Requirements:
     *  - caller must have FACTORY_ROLE. See {AISkinMasterCollection-FACTORY_ROLE}
     *
     * @param tokenId The collection token id
     * @param collection The creator collection address
     */
    function registerDropItem(
        uint256 tokenId,
        address collection,
        uint256 cap,
        uint256 priceInWei,
        bool limited
    ) external;

    /// @dev Emits events from clone collection to master collection. Note: can only be called by clone collections
    function emitTransferSingle(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Triggered by creator collection address when multiple items are minted or transfered. Emits {IERC1155-TransferBatch}
     *
     * Requirements:
     *  - caller must be clone collection address. See {IAISkinFactory-isValidCollection}
     *
     * @param operator The operator
     * @param from The from
     * @param to  The to
     * @param ids The Ids
     * @param amounts The amounts
     */
    function emitTransferBatch(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    /**
     * @dev Getter for creators items ids
     *
     * @param creator The creator address
     */
    function getCreatorItemIds(
        address creator
    ) external view returns (uint256[] memory);

    /**
     * @dev Getter for base uri
     */
    function getBaseUri() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ITestFactory} from "./interfaces/ITestFactory.sol";
import {ITestMasterCollection} from "./interfaces/ITestMasterCollection.sol";
import {ITestDropCollection} from "./interfaces/ITestDropCollection.sol";
import {ITestBaseCollection} from "./interfaces/ITestBaseCollection.sol";

contract TestFactory is AccessControl, EIP712, ITestFactory, ReentrancyGuard {
    using Address for address;
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// ============== ACCESS CONTROL ============= ///
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    // PUBLISHER_SIGNER
    bytes32 public constant PUBLISHER_SIGNER = keccak256("PUBLISHER_SIGNER");
    // FREE_PUBLISHER_SIGNER
    bytes32 public constant FREE_PUBLISHER_SIGNER =
        keccak256("FREE_PUBLISHER_SIGNER");

    /// ==============  712 Structure  ============= ///
    string private constant _DOMAIN_NAME = "AISkins";
    bytes32 private constant _TOKENID_PERMIT_TYPEHASH =
        keccak256(
            "AISkins(address creator,uint256 tokenId,uint256 deadline,address collection,uint256 cap,address tokenPayment,uint256 priceInWei,bool limited,uint256 preMinted)"
        );

    address public masterCollection;

    // token payment address for mint and publish
    address private _baseToken;
    // fee for creating new collection
    uint256 private _createCollectionFee;
    // fee on publishing item
    uint256 private _publishItemFee;

    // Mint fee receiver
    address private _treasury;
    // Default Mint fee share
    uint256 private _mintShareFee = 250;
    // free mint on creator address
    uint256 private _publishFreebiesAmount = 1;

    RoyaltyInfo private aiskinRoyaltyInfo;

    // list of collections created using aiskins factory
    EnumerableSet.AddressSet private _collections;

    // set of implementation that aiskins supported
    // typeId -> contract implementation
    mapping(uint96 => address) private _implementations;

    // tokenPayment -> mint fee in wei
    mapping(address => uint256) private _tokenPaymentMinimumMintPrice;

    // track the users created collection
    // creator -> collections
    mapping(address => address[]) private _creatorCollections;

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            revert Unauthorized(MANAGER_ROLE, _msgSender());
        }
        _;
    }

    constructor(
        address treasury,
        address baseToken,
        uint256 createCollectionFee,
        uint256 publishItemFee,
        address royaltyReceiver,
        uint96 royaltyFraction
    ) EIP712(_DOMAIN_NAME, "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _treasury = treasury;

        _baseToken = baseToken;
        _createCollectionFee = createCollectionFee;
        _publishItemFee = publishItemFee;

        aiskinRoyaltyInfo = RoyaltyInfo({
            receiver: royaltyReceiver,
            royaltyFraction: royaltyFraction
        });
    }

    function createCollection(
        uint96 typeId,
        string memory name,
        string memory symbol
    ) external payable override nonReentrant {
        address implementation = _implementations[typeId];

        if (
            implementation == address(0) ||
            !implementation.supportsInterface(
                type(ITestDropCollection).interfaceId
            )
        ) {
            revert InvalidImplementation();
        }

        _collectPayment(_baseToken, _msgSender(), _createCollectionFee);

        address deployedCollection = Clones.clone(implementation);
        ITestDropCollection collection = ITestDropCollection(
            deployedCollection
        );

        collection.initialize(address(this), _msgSender(), name, symbol);

        _collections.add(deployedCollection);
        _creatorCollections[_msgSender()].push(deployedCollection);

        emit CreateCollection(
            _msgSender(),
            deployedCollection,
            name,
            symbol,
            block.timestamp
        );
    }

    function publishItem(
        PublishItemParams memory params,
        bytes memory signature
    ) external payable override nonReentrant {
        _validateDeadline(params.deadline);
        _validateCollection(params.collection);
        _validateMintPrice(params.tokenPayment, params.priceInWei);

        address tokenIdSigner = _getTokenIdSigner(
            _msgSender(),
            params.tokenId,
            params.deadline,
            params.collection,
            params.cap,
            params.tokenPayment,
            params.priceInWei,
            params.limited,
            params.preMinted,
            signature
        );

        _validateSigner(tokenIdSigner);

        if (!_isFreePublish(tokenIdSigner)) {
            _collectPayment(_baseToken, _msgSender(), _publishItemFee);
        }

        _publishItem(
            params.collection,
            params.tokenId,
            _msgSender(),
            params.tokenPayment,
            params.priceInWei,
            _mintShareFee,
            params.cap,
            params.preMinted,
            params.limited
        );
    }

    function setImplementation(
        uint96 typeId,
        address implementation
    ) external override onlyManager {
        _implementations[typeId] = implementation;
        emit SetImplementation(typeId, implementation);
    }

    function setMasterCollection(
        address _masterCollection
    ) external override onlyManager {
        emit SetMasterCollection(
            _msgSender(),
            masterCollection,
            _masterCollection
        );
        masterCollection = _masterCollection;
    }

    function updateFreebiesPublishAmount(
        uint256 amount
    ) external override onlyManager {
        emit UpdateFreebiesPublishAmount(
            _msgSender(),
            _publishFreebiesAmount,
            amount
        );
        _publishFreebiesAmount = amount;
    }

    function setTreasury(address treasury) external override onlyManager {
        emit SetTreasury(_msgSender(), _treasury, treasury);
        _treasury = treasury;
    }

    function updateMintShareFee(
        uint256 newMintShare
    ) external override onlyManager {
        emit UpdateMintShareFee(_msgSender(), _mintShareFee, newMintShare);
        _mintShareFee = newMintShare;
    }

    function addTokenPaymentMinMintPrice(
        address tokenPayment,
        uint256 minimumMintPrice
    ) external override onlyManager {
        emit AddTokenPaymentMinimumMintPrice(
            _msgSender(),
            tokenPayment,
            minimumMintPrice
        );
        _tokenPaymentMinimumMintPrice[tokenPayment] = minimumMintPrice;
    }

    function updateRoyaltyInfo(
        address receiver,
        uint96 royaltyFraction
    ) external override onlyManager {
        RoyaltyInfo memory royaltyInfo = RoyaltyInfo({
            receiver: receiver,
            royaltyFraction: royaltyFraction
        });
        emit UpdateRoyaltyInfo(_msgSender(), aiskinRoyaltyInfo, royaltyInfo);
        aiskinRoyaltyInfo = royaltyInfo;
    }

    function updateBaseToken(address baseToken) external override onlyManager {
        emit UpdateBaseToken(_msgSender(), _baseToken, baseToken);
        _baseToken = baseToken;
    }

    function updateCreateCollectionFee(
        uint256 createCollectionFee
    ) external override onlyManager {
        emit UpdateCreateCollectionFee(
            _msgSender(),
            _createCollectionFee,
            createCollectionFee
        );
        _createCollectionFee = createCollectionFee;
    }

    function updatePublishItemFee(
        uint256 publishItemFee
    ) external override onlyManager {
        emit UpdatePublishItemFee(
            _msgSender(),
            _publishItemFee,
            publishItemFee
        );
        _publishItemFee = publishItemFee;
    }

    function calculateCreatorPublishPremintFee(
        uint256 preMinted,
        uint256 mintPriceInWei
    ) public view override returns (uint256) {
        uint256 totalPrice = (preMinted - _publishFreebiesAmount) *
            mintPriceInWei;
        uint256 preMintFee = (totalPrice * _mintShareFee) / 10_000;

        return preMintFee;
    }

    function isValidCollection(
        address collection
    ) public view override returns (bool) {
        return _collections.contains(collection);
    }

    function getCollectionAt(
        uint256 index
    ) external view override returns (address) {
        return _collections.at(index);
    }

    function getImplementation(
        uint96 typeId
    ) external view override returns (address) {
        return _implementations[typeId];
    }

    function getCreatorCollections(
        address creator
    ) external view override returns (address[] memory) {
        return _creatorCollections[creator];
    }

    function getPublishFreebiesAmount()
        external
        view
        override
        returns (uint256)
    {
        return _publishFreebiesAmount;
    }

    function getAiskinMasterCollection()
        external
        view
        override
        returns (address)
    {
        return masterCollection;
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function getMintShareFee() external view override returns (uint256) {
        return _mintShareFee;
    }

    function getRoyaltyInfo() external view override returns (address, uint96) {
        return (aiskinRoyaltyInfo.receiver, aiskinRoyaltyInfo.royaltyFraction);
    }

    function getBaseToken() external view override returns (address) {
        return _baseToken;
    }

    function getCreateCollectionFee() external view override returns (uint256) {
        return _createCollectionFee;
    }

    function getPublishItemFee() external view override returns (uint256) {
        return _publishItemFee;
    }

    /**
     * @dev Simulate signature signed by AISkin
     */
    function simulateSignature(
        address caller,
        uint256 tokenId,
        uint256 deadline,
        address collection,
        uint256 cap,
        address tokenPayment,
        uint256 priceInWei,
        bool limited,
        uint256 preMinted,
        bytes memory signature
    ) external view returns (address) {
        return
            _getTokenIdSigner(
                caller,
                tokenId,
                deadline,
                collection,
                cap,
                tokenPayment,
                priceInWei,
                limited,
                preMinted,
                signature
            );
    }

    /**
     * @dev Return domain separateor based on ERC712 impl. See {https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator}
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl) returns (bool) {
        return
            interfaceId == type(ITestFactory).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _validateDeadline(uint256 deadline) internal view {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
    }

    function _validateCollection(address collection) internal view {
        if (collection != masterCollection && !isValidCollection(collection)) {
            revert UnsupportedCollection();
        }
    }

    function _validateMintPrice(
        address tokenPayment,
        uint256 priceInWei
    ) internal view {
        if (priceInWei < _tokenPaymentMinimumMintPrice[tokenPayment]) {
            revert MintPriceLessMinMintRequirement();
        }
    }

    function _validateSigner(address tokenIdSigner) internal view {
        if (!_isValidSigner(tokenIdSigner)) {
            revert Unauthorized(PUBLISHER_SIGNER, tokenIdSigner);
        }
    }

    /**
     * @dev Get signer address based on {_TOKENID_PERMIT_TYPEHASH} structs and bytes `signature`. See {https://eips.ethereum.org/EIPS/eip-712#specification-of-the-eth_signtypeddata-json-rpc}
     */
    function _getTokenIdSigner(
        address caller,
        uint256 tokenId,
        uint256 deadline,
        address collection,
        uint256 cap,
        address tokenPayment,
        uint256 priceInWei,
        bool limited,
        uint256 preMinted,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 structHash = keccak256(
            abi.encode(
                _TOKENID_PERMIT_TYPEHASH,
                caller,
                tokenId,
                deadline,
                collection,
                cap,
                tokenPayment,
                priceInWei,
                limited,
                preMinted
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        return ECDSA.recover(hash, signature);
    }

    /**
     * @dev Return `True` if signer has `keccack256(PUBLISHER_SIGNER)` or `keccack256(FREE_PUBLISHER_SIGNER)` roles otherwise `False`
     *
     * @param signer The signature signer address. See {TestFactory-_getTokenIdSigner}
     */
    function _isValidSigner(address signer) internal view returns (bool) {
        return
            hasRole(PUBLISHER_SIGNER, signer) ||
            hasRole(FREE_PUBLISHER_SIGNER, signer);
    }

    /**
     * @dev Check if signer has `keccack256(FREE_PUBLISHER_SIGNER) role
     *
     * @param signer The signature signer address. See {TestFactory-_getTokenIdSigner}
     */
    function _isFreePublish(address signer) internal view returns (bool) {
        return hasRole(FREE_PUBLISHER_SIGNER, signer);
    }

    function _collectPayment(
        address tokenPayment,
        address sender,
        uint256 amount
    ) internal {
        if (tokenPayment != address(0)) {
            require(
                IERC20(tokenPayment).transferFrom(sender, _treasury, amount)
            );
        } else {
            if (msg.value != amount) revert InsufficientPaymentBalance();
            Address.sendValue(payable(_treasury), amount);
        }
    }

    function _publishItem(
        address collection,
        uint256 tokenId,
        address creator,
        address tokenPayment,
        uint256 priceInWei,
        uint256 mintShareFee,
        uint256 cap,
        uint256 preMinted,
        bool limited
    ) internal {
        ITestBaseCollection(collection).createItem(
            tokenId,
            creator,
            tokenPayment,
            priceInWei,
            mintShareFee,
            cap,
            limited
        );

        if (collection != masterCollection) {
            ITestMasterCollection(masterCollection).registerDropItem(
                tokenId,
                collection,
                cap,
                priceInWei,
                limited
            );
        }

        if (preMinted > 0) {
            if (preMinted > _publishFreebiesAmount) {
                uint256 preMintFee = calculateCreatorPublishPremintFee(
                    preMinted,
                    priceInWei
                );
                _collectPayment(tokenPayment, creator, preMintFee);
            }

            ITestBaseCollection(collection).mintItemOnPublish(
                creator,
                tokenId,
                preMinted
            );
        }
    }
}