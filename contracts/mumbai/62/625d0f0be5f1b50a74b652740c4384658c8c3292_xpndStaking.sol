/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// Sources flattened with hardhat v2.7.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/access/[email protected]

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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File @openzeppelin/contracts/security/[email protected]

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

// File contracts/xpndStaking.sol

pragma solidity 0.8.10;

contract xpndStaking is Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    // addReward will add to default reward buckets 0, 1, 2 and 3
    // this is required when a pool is not active
    uint256[4] public defaultRewardBuckets;

    struct PoolConfig {
        uint32 periodStaking; // staking period in days
        uint256 proportionalRewardShare; // pool reward proportion from all pools
    }

    // This will be updated in addPool when createPools
    // is called 4 times with values for different pools
    PoolConfig[] public poolTypes;

    // Info of each pool instance when a new pool is created.
    struct PoolInfo {
        uint8 poolType;
        uint16 poolInstance; // pool id for this instance of the pool type
        uint32 endOfPool; // time when pool ended
        uint32 timeAccepting; // days to accept deposit, defaults to pool duration
        uint32 startOfDeposit; // timestamp when pool started
        uint256 totalStaked; // total tokens staked by all users
        uint256 poolReward; // total rewards collected in the pool.
        mapping(address => uint16[]) poolStakeByAddress; // map user address to stake id array
    }

    // map pool id to poolInfo.
    mapping(uint16 => PoolInfo) poolById;
    // map stake id to stake info.
    mapping(uint16 => StakeInfo) stakeById;

    // these lists will store poolInstance Ids for the 4 pool types
    mapping(uint8 => uint16[]) listOfAllPoolIds;

    // Whenever manager starts a new pool counter will increase
    uint16 public poolInstanceCounter;
    // Whenever a new stake is created counter will increase
    uint16 public stakeIdCounter;

    // total weightage of all reward pools
    uint256 public totalRewardPercent;

    //state of staking to confirm it is paused or being
    bool public paused;

    // Info of each stake
    struct StakeInfo {
        bool settled; // withdraw status, true if stake was withdrawen
        uint16 poolInstance; // pool id where deposit was made
        uint32 depositTime; // time deposit was staked
        uint256 stakeAmount; // amount of tokens staked
    }

    // Status of pool
    enum PoolStatus {
        NOTSTARTED,
        OPEN,
        CLOSED
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // value for minutes in a day
    uint32 private MINUTES_IN_DAY;

    IERC20 public token;

    mapping(uint16 => uint16[]) stakeIdsByPoolInstance;
    mapping(address => uint16[]) poolInstancesByOwnerAddress;
    mapping(address => uint16[]) stakesIdsByOwnerAddress;
    mapping(string => bytes32) internal Roles;

    event Stake(
        address indexed user,
        uint256 indexed poolInstance,
        uint256 amount
    );

    event WithdrawAll(address indexed user, uint256 amount);

    event PoolStarted(
        uint16 indexed poolInstance,
        uint8 poolType,
        uint32 startOfDeposit
    );

    event PoolUpdated(uint16 indexed poolInstance, uint32 startOfDeposit);

    constructor(IERC20 _token) {
        token = _token;
        paused = false;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        MINUTES_IN_DAY = 1; // 24 * 60 for mainnet, 1 for testnet

        createPools();
    }

    modifier notPaused() {
        require(paused == false);
        _;
    }

    /**
     * @notice Set staking state paused or not
     * @dev Set staking pause state to true or false
     */
    function setPauseState(bool pausedState)
        public
        onlyRole(PAUSER_ROLE)
        returns (bool)
    {
        paused = pausedState;
        return paused;
    }

    /**
     * @notice Notice if staking is paused or not
     * @dev Create pool instance of specified type
     * @return current state of staking: true or false
     */
    function getStakingPausedState() public view returns (bool) {
        return paused;
    }

    /**
     * @notice Start staking specific pool
     * @dev Create pool instance of specified type
     * @param _poolType Type of pool, 0, 1, 2, 3
     * @param _timeAccepting Period of time that use can deposit. 0: accept throughout pull duration time
     * @param _startTime Start time of staking
     * @param _initialReward Initial Reward when start staking
     */
    function _startStaking(
        uint8 _poolType,
        uint32 _timeAccepting,
        uint32 _startTime,
        uint256 _initialReward
    ) internal onlyRole(MANAGER_ROLE) notPaused {
        require(_poolType < poolTypes.length, "Invalid poolInstance");

        require(
            _startTime >= block.timestamp,
            "Staking cannot start before now"
        );

        require(
            _startTime <= block.timestamp + 180 * MINUTES_IN_DAY * 60,
            "Staking cannot start after more than 6 months"
        );

        if (_timeAccepting == 0) {
            _timeAccepting = poolTypes[_poolType].periodStaking;
        }
        uint256 poolIDLength = listOfAllPoolIds[_poolType].length;

        if (_initialReward > 0) {
            token.safeTransferFrom(msg.sender, address(this), _initialReward);
        }

        if (poolIDLength == 0) {
            createPoolInstance(
                _poolType,
                _timeAccepting,
                _startTime,
                _initialReward
            );
        } else {
            uint16 latestPoolId = listOfAllPoolIds[_poolType][poolIDLength - 1];
            PoolInfo storage latestPool = poolById[latestPoolId];
            // create new pool only if latest pool has not closed
            if (
                (latestPool.startOfDeposit +
                    poolTypes[_poolType].periodStaking *
                    MINUTES_IN_DAY *
                    60) < _startTime
            ) {
                uint256 latestPoolReward = latestPool.poolReward;

                uint16[] memory stakeIdArray = stakeIdsByPoolInstance[
                    latestPoolId
                ];
                uint256 totalRewardsToTransfer = 0;
                for (uint256 i = 0; i < stakeIdArray.length; i++) {
                    totalRewardsToTransfer += computeRewards(stakeIdArray[i]);
                }

                uint256 residualRewards = latestPoolReward -
                    totalRewardsToTransfer;

                createPoolInstance(
                    _poolType,
                    _timeAccepting,
                    _startTime,
                    _initialReward + residualRewards
                );
            }
        }
    }

    /**
     * @notice Start staking specific pool
     * @dev Create pool instance of specified type
     * @param _poolType Type of pool, 0, 1, 2, 3
     * @param _timeAccepting Period of time that use can deposit. 0: accept throughout pull duration time
     */
    function startStaking(uint8 _poolType, uint32 _timeAccepting)
        public
        onlyRole(MANAGER_ROLE)
        notPaused
    {
        _startStaking(_poolType, _timeAccepting, uint32(block.timestamp), 0);
    }

    /**
     * @notice Start staking specific pool later
     * @dev Create pool instance of specified type
     * @param _poolType Type of pool, 0, 1, 2, 3
     * @param _startTime Start time of staking
     */
    function startStakingLater(uint8 _poolType, uint32 _startTime)
        public
        onlyRole(MANAGER_ROLE)
        notPaused
    {
        if (_startTime == 0) {
            _startTime = uint32(block.timestamp);
        }

        require(
            _startTime >= block.timestamp,
            "Staking cannot start before now"
        );
        _startStaking(_poolType, 0, _startTime, 0);
    }

    /**
     * @notice Start staking specific pool later with initial reward
     * @dev Create pool instance of specified type
     * @param _poolType Type of pool, 0, 1, 2, 3
     * @param _startTime Start time of staking
     * @param _initialReward Initial Reward when start staking
     */
    function startStakingWithReward(
        uint8 _poolType,
        uint32 _startTime,
        uint256 _initialReward
    ) public onlyRole(MANAGER_ROLE) notPaused {
        if (_startTime == 0) {
            _startTime = uint32(block.timestamp);
        }
        require(_initialReward > 0, "Initial Reward should not be zero");
        _startStaking(_poolType, 0, _startTime, _initialReward);
    }

    /**
     * @notice Start staking all pools(0,1,2 and 3)
     * @dev Create pool a instance for all pool types
     */
    function startStakingAllPools() external onlyRole(MANAGER_ROLE) notPaused {
        for (uint8 poolType = 0; poolType < poolTypes.length; poolType++) {
            _startStaking(poolType, 0, uint32(block.timestamp), 0);
        }
    }

    /**
     * @notice Start staking list of pools(e.g. 0 and 3)
     * @dev Create pool a instance for all pool types
     */
    function startStakingPools(
        uint8[] memory poolTypeList,
        uint256[] memory initialRewardList
    ) external onlyRole(MANAGER_ROLE) notPaused {
        require(poolTypeList.length <= 4, "Length of Pool List is invalid.");
        require(
            poolTypeList.length == initialRewardList.length,
            "Length of Pool List and Initial Reward List is invalid."
        );

        for (uint256 i = 0; i < poolTypeList.length; i++) {
            uint8 poolType = poolTypeList[i];
            _startStaking(
                poolType,
                0,
                uint32(block.timestamp),
                initialRewardList[i]
            );
        }
    }

    /**
     * @notice Add reward amount
     * @dev Add reward amount, reward is distributed to all pool types based on reward percent in pool config
     * @param _amount Amount to add reward
     */
    function addRewards(uint256 _amount) external nonReentrant notPaused {
        require(_amount > 0, "err _amount=0");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        for (uint8 poolType = 0; poolType < poolTypes.length; ++poolType) {
            uint256 poolInstanceLength = listOfAllPoolIds[poolType].length;
            if (poolInstanceLength == 0) {
                defaultRewardBuckets[poolType] +=
                    (_amount * poolTypes[poolType].proportionalRewardShare) /
                    totalRewardPercent;
            } else {
                uint16 currentPoolId = listOfAllPoolIds[poolType][
                    poolInstanceLength - 1
                ];
                // check if pool has ended
                if (
                    poolTypes[poolType].periodStaking *
                        MINUTES_IN_DAY *
                        60 +
                        poolById[currentPoolId].startOfDeposit >
                    block.timestamp
                ) {
                    // pool has not ended, reward should be added to current pool
                    poolById[currentPoolId].poolReward +=
                        (_amount *
                            poolTypes[poolType].proportionalRewardShare) /
                        totalRewardPercent;
                } else {
                    // latest poolType pool has ended, reward should be collected in
                    // default bucket and added to the new instance of poolType when it starts
                    defaultRewardBuckets[poolType] +=
                        (_amount *
                            poolTypes[poolType].proportionalRewardShare) /
                        totalRewardPercent;
                }
            }
        }
    }

    /**
     * @notice Deposit tokens to stake in _poolType
     * @dev Create stakeInfo in latest pool instance of the specified pool type
     * @param _poolType Type of pool to stake in(0, 1, 2 or 3)
     * @param _amount Amount to stake
     */
    function stake(uint8 _poolType, uint256 _amount)
        external
        nonReentrant
        notPaused
    {
        require(_poolType < poolTypes.length, "err _poolType is invalid");
        require(_amount > 0, "err _amount=0");

        uint16[] memory poolInstances = listOfAllPoolIds[_poolType];
        require(poolInstances.length > 0, "err no active pool of _poolType");

        uint16 latestPoolId = poolInstances[poolInstances.length - 1];
        PoolInfo storage poolInfo = poolById[latestPoolId];

        require(
            poolInfo.startOfDeposit < block.timestamp,
            "pool has not started accepting deposit."
        );
        require(
            poolInfo.startOfDeposit +
                poolInfo.timeAccepting *
                MINUTES_IN_DAY *
                60 >
                block.timestamp,
            "pool staking has ended."
        );

        token.safeTransferFrom(address(msg.sender), address(this), _amount);

        poolInfo.totalStaked += _amount;

        uint16[] storage stakeIdArray = poolInfo.poolStakeByAddress[msg.sender];

        stakeIdCounter++;

        StakeInfo memory stakeInfo = StakeInfo({
            depositTime: uint32(block.timestamp),
            poolInstance: latestPoolId,
            stakeAmount: _amount,
            settled: false
        });

        // TODO:: Some of these may be redundant after requirements and UI
        // are finalised
        stakeIdArray.push(stakeIdCounter);
        stakeById[stakeIdCounter] = stakeInfo;
        stakeIdsByPoolInstance[latestPoolId].push(stakeIdCounter);
        stakesIdsByOwnerAddress[msg.sender].push(stakeIdCounter);
        poolInstancesByOwnerAddress[msg.sender].push(latestPoolId);

        emit Stake(msg.sender, _poolType, _amount);
    }

    /**
     * @notice Withdraw all stakes for a user
     * @dev Withdraw all stakes for a user from all pool instances of all pool types
     */
    function withdrawAll() external nonReentrant notPaused {
        uint16[] memory poolInstanceArray = poolInstancesByOwnerAddress[
            msg.sender
        ];
        require(0 < poolInstanceArray.length, "User never staked.");

        uint256 totalToWithdraw = 0;

        for (uint256 index = 0; index < poolInstanceArray.length; index++) {
            uint16 poolInstance = poolInstanceArray[index];

            PoolInfo storage poolInfo = poolById[poolInstance];
            PoolConfig memory poolConfig = poolTypes[poolInfo.poolType];

            if (
                poolInfo.startOfDeposit +
                    poolConfig.periodStaking *
                    MINUTES_IN_DAY *
                    60 >
                block.timestamp
            ) continue;

            uint16[] storage stakeIdArray = poolInfo.poolStakeByAddress[
                msg.sender
            ];

            for (uint256 i = 0; i < stakeIdArray.length; i++) {
                uint16 stakeId = stakeIdArray[i];
                totalToWithdraw += computeSettlement(stakeId);
            }
        }

        token.safeTransfer(msg.sender, totalToWithdraw);

        emit WithdrawAll(msg.sender, totalToWithdraw);
    }

    // -- Internal Functions --

    /**
     * @notice Create 4 types of pool
     * @dev Create 4 types of pool, function is called in contructor.
     */
    function createPools() internal {
        addPool(90, 250);
        addPool(180, 1000);
        addPool(365, 2250);
        addPool(730, 6500);
    }

    /**
     * @notice Add pool with staking period and reward percent
     * @dev Add pool config.
     * @param _periodStaking staking period of pool
     * @param _rewardPercent Reward percent of pool
     */
    function addPool(uint32 _periodStaking, uint256 _rewardPercent) internal {
        require(
            _periodStaking <= 730,
            "periodStaking must be less than 730 days"
        );

        totalRewardPercent = totalRewardPercent + _rewardPercent;
        poolTypes.push(
            PoolConfig({
                periodStaking: _periodStaking,
                proportionalRewardShare: _rewardPercent
            })
        );
    }

    /**
     * @notice This will be called by startStaking method after validation
     * @dev Add pool instance info
     * @param _poolType Pool type to add pool instance
     * @param _timeAccepting Accepting time that user can deposit 0 indicates accept throughout pool duration
     * @param _initialReward Initial Reward when start staking
     */
    function createPoolInstance(
        uint8 _poolType,
        uint32 _timeAccepting,
        uint32 _startTime,
        uint256 _initialReward
    ) internal {
        poolInstanceCounter++;
        listOfAllPoolIds[_poolType].push(poolInstanceCounter);

        // Add all the pool information to pool by Id mapping
        poolById[poolInstanceCounter].poolType = _poolType;
        poolById[poolInstanceCounter].poolInstance = poolInstanceCounter;
        poolById[poolInstanceCounter].startOfDeposit = _startTime;
        poolById[poolInstanceCounter].timeAccepting = _timeAccepting;
        poolById[poolInstanceCounter].totalStaked = 0;
        poolById[poolInstanceCounter].poolReward =
            defaultRewardBuckets[_poolType] +
            _initialReward;

        poolById[poolInstanceCounter].endOfPool =
            _startTime +
            uint32(poolTypes[_poolType].periodStaking * MINUTES_IN_DAY * 60);

        emit PoolStarted(poolInstanceCounter, _poolType, _startTime);
    }

    /**
     * @notice This will be called by startStaking method after validation
     * @dev Add pool instance info
     * @param _poolInstance pool instance
     * @param _startTime Start time of pool
     */
    function updatePoolInstance(uint16 _poolInstance, uint32 _startTime)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(_poolInstance <= poolInstanceCounter, "Invalid pool instance");

        poolById[_poolInstance].startOfDeposit = _startTime;
        poolById[_poolInstance].endOfPool =
            _startTime +
            uint32(
                poolTypes[_poolInstance].periodStaking * MINUTES_IN_DAY * 60
            );

        emit PoolUpdated(_poolInstance, _startTime);
    }

    // -- Informational Functions --

    /**
     * @notice Get rewards which have not been claimed by stake id
     * @dev Return based on stake info
     * @param _stakeId Stake ID to calculate
     * @return Amount of reward
     */
    function getPendingRewards(uint16 _stakeId)
        external
        view
        returns (uint256)
    {
        require(_stakeId <= stakeIdCounter, "Invalid stakeID");
        StakeInfo memory stakeInfo = stakeById[_stakeId];
        uint256 rewards;
        if (stakeInfo.settled) {
            rewards = 0;
        } else {
            rewards = computeRewards(_stakeId);
        }
        return rewards;
    }

    /**
     * @notice Get rewards by stake id
     * @dev Return based on stake info
     * @param _stakeId Stake ID to calculate
     * @return Amount of reward
     */
    function getRewards(uint16 _stakeId) external view returns (uint256) {
        uint256 rewards;
        rewards = computeRewards(_stakeId);
        return rewards;
    }

    /**
     * @notice Get rewards by stake id
     * @dev Return based on stake info
     * @param _stakeId Stake ID to calculate
     * @return rewards of reward
     */
    function computeRewards(uint16 _stakeId) internal view returns (uint256) {
        require(_stakeId <= stakeIdCounter, "Invalid stakeID");

        StakeInfo memory stakeInfo = stakeById[_stakeId];
        PoolInfo storage poolInfo = poolById[stakeInfo.poolInstance];
        PoolConfig memory poolConfig = poolTypes[poolInfo.poolType];
        uint256 rewards;

        if (poolInfo.endOfPool == stakeInfo.depositTime) {
            rewards = 0;
        } else {
            rewards =
                (((poolInfo.poolReward * stakeInfo.stakeAmount) /
                    poolInfo.totalStaked) *
                    (poolInfo.endOfPool - stakeInfo.depositTime)) /
                (MINUTES_IN_DAY * 60 * poolConfig.periodStaking);
        }
        return rewards;
    }

    /**
     * @notice Compute the total amount of tokens the user needs to withdraw
     * @dev Returns withdraw amount. interal function
     * @param stakeId Stake index
     * @return withdrawAmount Total amount of tokens the user needs to withdraw
     */
    function computeSettlement(uint16 stakeId)
        internal
        returns (uint256 withdrawAmount)
    {
        StakeInfo storage stakeInfo = stakeById[stakeId];
        if (stakeInfo.settled) {
            withdrawAmount = 0;
        } else {
            withdrawAmount += stakeInfo.stakeAmount;
            withdrawAmount += computeRewards(stakeId);
            stakeInfo.settled = true;
        }
    }

    /**
     * @notice Get pool instances
     * @dev Returns pool instance ids in a pool
     * @param _poolType Pool type to get pool instances
     * @return Pool Instances in a pool
     */
    function getPoolInstances(uint8 _poolType)
        external
        view
        returns (uint16[] memory)
    {
        require(_poolType < poolTypes.length, "Invalid pool Type");
        return listOfAllPoolIds[_poolType];
    }

    function getPoolInfo(uint16 poolInstance)
        external
        view
        returns (
            uint8 poolType,
            uint256 startOfDeposit,
            uint256 totalStaked,
            uint256 poolReward,
            uint256 endOfDeposit,
            PoolStatus poolStatus
        )
    {
        poolType = poolById[poolInstance].poolType;
        startOfDeposit = poolById[poolInstance].startOfDeposit;
        totalStaked = poolById[poolInstance].totalStaked;
        poolReward = poolById[poolInstance].poolReward;
        endOfDeposit = poolById[poolInstance].endOfPool;

        poolStatus = block.timestamp < startOfDeposit
            ? PoolStatus.NOTSTARTED
            : block.timestamp < endOfDeposit
            ? PoolStatus.OPEN
            : PoolStatus.CLOSED;
    }

    /**
     * @notice Get latest pool instances for pool type
     * @dev Returns latest pool instance id for all pool types
     * @return Array of pool instance ids
     */
    function getCurrentPools() external view returns (uint16[] memory) {
        uint16[] memory poolIDs = new uint16[](poolTypes.length);

        for (uint8 index = 0; index < (uint8)(poolTypes.length); index++) {
            uint256 poolIDLength = listOfAllPoolIds[index].length;
            if (poolIDLength == 0) continue;
            uint16 latestPoolId = listOfAllPoolIds[index][poolIDLength - 1];
            poolIDs[index] = latestPoolId;
        }

        return poolIDs;
    }

    /**
     * @notice Get pool config
     * @dev Returns pool config
     * @param _poolType Pool type to get config
     * @return Pool config
     */
    function getPoolConfig(uint8 _poolType)
        external
        view
        returns (PoolConfig memory)
    {
        return poolTypes[_poolType];
    }

    /**
     * @notice Get stake ids
     * @dev Returns all stake ids for a user
     * @param _owner User address to get stake ids
     * @return Array of stake ids
     */
    function getMyStakes(address _owner)
        external
        view
        returns (uint16[] memory)
    {
        return stakesIdsByOwnerAddress[_owner];
    }

    /**
     * @notice Get stake information
     * @dev Returns stake info based for stakeById
     * @param _stakeId Stake Id to get stake information
     * @return Stake Info
     */
    function getStakeInfo(uint16 _stakeId)
        external
        view
        returns (StakeInfo memory)
    {
        require(_stakeId <= stakeIdCounter, "Invalid stake id");

        return stakeById[_stakeId];
    }

    /**
     * @notice Get pool instances
     * @dev Returns pool instances base on listOfAllPoolIds
     * @param _poolType Pool type to get pool instances
     * @return Array of pool instance
     */
    function getAllPoolInstance(uint8 _poolType)
        external
        view
        returns (uint16[] memory)
    {
        require(_poolType < poolTypes.length, "Invalid pool type");

        return listOfAllPoolIds[_poolType];
    }

    /**
     * @notice Get all stakes in pool instance
     * @dev Returns all stake ids in pool instance refering stakeIdsByPoolInstance
     * @param _poolInstance Pool instance to get stake Ids
     * @return Array of stake ids
     */
    function getAllStakesByPoolInstance(uint16 _poolInstance)
        external
        view
        returns (uint16[] memory)
    {
        require(_poolInstance < poolInstanceCounter, "Invalid pool instance");

        return stakeIdsByPoolInstance[_poolInstance];
    }

    /**
     * @notice Get pool length
     * @dev Returns length of pool types
     * @return Pool length
     */
    function poolLength() external view returns (uint256) {
        return poolTypes.length;
    }
}