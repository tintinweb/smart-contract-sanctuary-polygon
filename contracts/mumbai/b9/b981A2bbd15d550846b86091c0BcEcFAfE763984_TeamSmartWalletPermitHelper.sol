// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Tax} from "../taxes/Tax.sol";
import {Signature} from "../../utils/Signature.sol";

/**
 * @title IEscrow
 * @notice This interface outlines the functions necessary for an escrow system in a marketplace trading ERC721 and ERC20 tokens.
 * @dev Any contract implementing this interface can act as an escrow in the marketplace.
 */
interface IEscrow is IMarketHubRegistrar, IERC165 {
    /**
     * @dev Emitted when a sale is created.
     */
    event CreateSale(
        uint256 saleId,
        State state,
        address buyer,
        address spender,
        address erc20,
        uint256 price,
        uint256 taxes,
        address seller,
        address erc721,
        uint256 tokenId,
        string metadata
    );

    /**
     * @dev Emitted when a sale's state is updated.
     */
    event UpdateSale(uint256 saleId, State newState);

    /**
     * @dev Emitted when a sale's tax is updated.
     */
    event SaleTaxesUpdated(uint256 saleId, uint256 amount, uint256 countryCode, uint256 regionCode);

    /**
     * @notice Updates the sales tax for a pre-pending sale.
     * @param _saleId The id of the sale.
     * @param _taxes The new taxes to collect in ERC20 tokens.
     */
    function updateSaleTaxesToCollect(uint256 _saleId, Tax memory _taxes) external;

    /**
     * @dev Emitted when a royalty is paid out.
     */
    event RoyaltyPayout(uint256 saleId, address receiver, uint256 amount);

    /**
     * @dev Emitted when a commission is paid out.
     */
    event CommissionPayout(uint256 saleId, address receiver, uint256 amount);

    /**
     * @dev Emitted when a sale is completed and any on-chain tax are collected/to be remitted.
     */
    event TaxCollected(uint256 saleId, address receiver, uint256 taxes, uint256 country, uint256 region);

    /**
     * @dev Emitted when a sale is complete.
     */
    event SaleComplete(uint256 saleId, uint256 payoutAmount);

    /**
     * @dev Emitted when a sale is cancelled.
     */
    event SaleCancelled(uint256 saleId, address erc20ReturnedTo, address erc721ReturnedTo);

    /**
     * @dev Emitted when the challenge window for buyers is changed.
     */
    event BuyerChallengeWindowChanged(uint256 numberOfHours);

    /**
     * @dev Emitted when the funding window for a sale is changed.
     */
    event SaleFundingWindowChanged(uint256 numberOfHours);

    /**
     * @notice Represents the different states a sale can be in.
     */
    enum State {
        AwaitingSettlement,
        AwaitingERC20Deposit,
        PendingSale,
        ProcessingSale,
        ShippingToBuyer,
        Received,
        ShippingToColleForAuthentication,
        ColleProcessingSale,
        ShippingToColleForDispute,
        IssueWithDelivery,
        IssueWithProduct,
        SaleCancelled,
        SaleSuccess
    }

    /**
     * @notice Represents a sale.
     */
    struct Sale {
        uint256 id;
        address buyer;
        address spender;
        address erc20;
        uint256 price;
        Tax taxes;
        address seller;
        address erc721;
        uint256 tokenId;
        State state;
        uint256 createdTimestamp;
        uint256 receivedTimestamp;
    }

    /**
     * @notice Sets the time window during which buyers can challenge a sale.
     * @param _hours The new challenge window in hours.
     */
    function setBuyerChallengeWindow(uint256 _hours) external;

    /**
     * @notice Returns the current challenge window for buyers.
     * @return uint256 The challenge window in hours.
     */
    function buyerChallengeWindow() external view returns (uint256);

    /**
     * @notice Sets the time window during which a sale can be funded.
     * Can only be called by the colle.
     * @param _hours The new funding window in hours.
     */
    function setSaleFundingWindow(uint256 _hours) external;

    /**
     * @notice Returns the current funding window for buyers.
     * @return uint256 The funding window in hours.
     */
    function saleFundingWindow() external view returns (uint256);

    /**
     * @notice Creates a new sale.
     * @param _buyer The buyer's address.
     * @param _spender The address spending the ERC20 tokens.
     * @param _erc20 The address of the ERC20 token being used as currency.
     * @param _price The price in ERC20 tokens.
     * @param _taxes The taxes to collect in ERC20 tokens.
     * @param _seller The seller's address.
     * @param _erc721 The address of the ERC721 token being sold.
     * @param _tokenId The id of the ERC721 token being sold.
     * @param _payNow Whether the buyer pays immediately or not.
     */
    function createSale(
        address _buyer,
        address _spender,
        address _erc20,
        uint256 _price,
        Tax memory _taxes,
        address _seller,
        address _erc721,
        uint256 _tokenId,
        bool _payNow
    ) external;

    /**
     * @notice Returns details of a sale.
     * @param _saleId The id of the sale.
     * @return Sale The details of the sale.
     */
    function getSale(uint256 _saleId) external view returns (Sale memory);

    /**
     * @notice Checks if a particular ERC721 token is currently part of an active sale.
     * @param _erc721 The address of the ERC721 token.
     * @param _tokenId The id of the ERC721 token.
     * @return bool Whether the token is part of an active sale or not.
     */
    function hasActiveSale(address _erc721, uint256 _tokenId) external view returns (bool);

    /**
     * @notice Updates the state of a sale.
     * @param _saleId The id of the sale.
     * @param _newState The new state of the sale.
     */
    function updateSale(uint256 _saleId, State _newState) external;

    /**
     * @notice Allows a signer to permit the update of a sale's state.
     * @param _saleId The id of the sale.
     * @param _newState The new state of the sale.
     * @param _signature The signer's signature, deadline and signer address.
     */
    function permitUpdateSale(uint256 _saleId, State _newState, Signature memory _signature) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title IMarketHubRegistrar
 * @dev This contract defines the interface for registering and unregistering to the MarketHub.
 */
interface IMarketHubRegistrar {
    /**
     * @dev Emitted when a marketHub is registered.
     */
    event RegisteredMarketHub(address marketHub);

    /**
     * @dev Emitted when a marketHub is registered.
     */
    event UnregisteredMarketHub(address marketHub);

    /**
     * @dev Register the calling contract to the MarketHub.
     * Only contracts that meet certain criteria may successfully register.
     */
    function register() external;

    /**
     * @dev Unregister the calling contract from the MarketHub.
     * Only contracts that are currently registered can successfully unregister.
     */
    function unregister() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

struct Tax {
    uint256 amount;
    uint256 countryCode;
    uint256 regionCode;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IERC1155ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import {IEscrow} from "../marketplace/escrow/IEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Tax} from "../marketplace/taxes/Tax.sol";
import {Signature} from "../utils/Signature.sol";

/**
 * @title TeamSmartWallet
 *
 * @notice A smart contract for managing access-controlled and upgradable smart wallets for teams.
 * Includes capabilities for trading NFTs, managing financials, and upgrading the smart wallet.
 *
 * @dev The contract uses OpenZeppelin's AccessControlUpgradeable for access control functionality,
 * and UUPSUpgradeable for the upgradeability. It implements the IERC721ReceiverUpgradeable and
 * IERC1155ReceiverUpgradeable interfaces to enable receiving NFTs, and uses the SignatureValidator
 * contract to enable off-chain approval of transactions.
 */
interface ITeamSmartWallet is IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
    /**
     * @dev Emitted when a admin consents to a contract upgade.
     */
    event AllowUpgrade(bool isAllowed);

    /**
     * @dev Emitted when the registered MarketHub is updated.
     */
    event UpdateMarketHub(address marketHub);

    /**
     * @notice Sets the address of the MarketHub contract.
     * @param _marketHub The new MarketHub contract address.
     */
    function setMarketHub(address _marketHub) external;

    /**
     * @notice This function is used to execute raw transactions.
     * @dev Can only be called by the DEFAULT_ADMIN_ROLE. Calls an arbitrary function in a smart contract.
     * @param _target The target smart contract address.
     * @param _value The amount of native token to be sent.
     * @param _data The raw data representing a function and its parameters in the smart contract.
     * @return success Boolean indicator for the status of transaction execution.
     * @return returnData Data returned from function call.
     */
    function executeRawTransaction(
        address _target,
        uint256 _value,
        bytes memory _data
    ) external returns (bool success, bytes memory returnData);

    /**
     * @notice This function is used to transfer ERC721 NFTs from this contract to another address.
     * @dev Can only be called by the FINANCIAL_ROLE.
     * @param _collection The address of the NFT collection.
     * @param _recipient The address to receive the NFT.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferERC721(address _collection, address _recipient, uint256 _tokenId) external;

    /**
     * @notice This function is used to list a token for trading.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to list.
     * @param _erc20 The address of the ERC20 token to be used for payment.
     * @param _price The listing price of the token.
     */
    function list(address _collection, uint256 _tokenId, address _erc20, uint256 _price) external;

    /**
     * @notice This function is used to delist a token from trading.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to delist.
     * @param _erc20 The address of the ERC20 token previously used for payment.
     */
    function delist(address _collection, uint256 _tokenId, address _erc20) external;

    /**
     * @notice This function is used to buy a listed token.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _collection The address of the collection contract to which the token belongs.
     * @param _tokenId The ID of the token to be bought.
     * @param _erc20 The address of the ERC20 token to be used as the payment currency.
     * @param _taxes The taxes to be paid.
     * @param _payNow Specifies if payment will be made now or later.
     * @param _signature The buyer's signature, address and deadline.
     */
    function buy(
        address _collection,
        uint256 _tokenId,
        address _erc20,
        Tax memory _taxes,
        bool _payNow,
        Signature memory _signature
    ) external;

    /**
     * @notice This function is used to make an offer for a token.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to offer.
     * @param _erc20 The address of the ERC20 token to be used for payment.
     * @param _price The offered price for the token.
     */
    function offer(address _collection, uint256 _tokenId, address _erc20, uint256 _price) external;

    /**
     * @notice This function is used to revoke an offer for a token.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token for which the offer is revoked.
     * @param _erc20 The address of the ERC20 token previously used for the offer.
     */
    function revokeOffer(address _collection, uint256 _tokenId, address _erc20) external;

    /**
     * @notice This function is used to accept an offer for a token.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _buyer The address of the buyer whose offer is being accepted.
     * @param _erc20 The address of the ERC20 token used in the offer.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token for which the offer is accepted.
     */
    function acceptOffer(address _buyer, address _erc20, address _collection, uint256 _tokenId) external;

    /**
     * @notice This function is used to update the state of a sale.
     * @dev Can only be called by the TRADING_ROLE.
     * @param _saleId The ID of the sale to update.
     * @param _newState The new state of the sale.
     */
    function updateSale(uint256 _saleId, IEscrow.State _newState) external;

    /**
     * @notice This function allows the caller to perform a native transfer.
     * @dev The caller must be a user with the FINANCIAL_ROLE.
     * @param _recipient The address of the recipient.
     * @param _amount The amount to transfer.
     */
    function transferNative(address payable _recipient, uint256 _amount) external;

    /**
     * @notice This function allows a user to approve a ERC20 transfer.
     * @dev The function must be called by a user with the FINANCIAL_ROLE.
     * @param _token The ERC20 token to approve.
     * @param _spender The address of the spender.
     * @param _amount The amount to approve.
     */
    function approveERC20(IERC20 _token, address _spender, uint256 _amount) external returns (bool);

    /**
     * @notice This function allows the caller permit to perform a ERC20 transfer.
     * @dev The function must be called by a user with the FINANCIAL_ROLE.
     * @param _token The ERC20 token to transfer.
     * @param _recipient The address of the recipient.
     * @param _amount The amount to transfer.
     */
    function transferERC20(address _token, address _recipient, uint256 _amount) external returns (bool);

    /**
     * @notice This function allows the caller to approve a ERC721 transfer.
     * @dev The function must be called by a user with the FINANCIAL_ROLE.
     * @param _token The ERC721 token to approve.
     * @param _to The address to approve.
     * @param _tokenId The ID of the token to approve.
     */
    function approveERC721(address _token, address _to, uint256 _tokenId) external;

    /**
     * @notice This function allows a caller to approve or revoke approval of an operator to transfer any NFT by the owner.
     * @dev The function must be called by a user with the FINANCIAL_ROLE.
     * @param _erc721 The ERC721 contract to approve.
     * @param _operator The address to approve.
     * @param _approved The approval status.
     */
    function setApprovalForAllERC721(address _erc721, address _operator, bool _approved) external;

    /**
     * @notice This function allows a caller to set approval for all ERC1155 tokens.
     * @dev The function must be called by a user with the FINANCIAL_ROLE.
     * @param _erc1155 The ERC1155 token contract.
     * @param _operator The operator to be approved or disapproved.
     * @param _approved Approval status to set for the operator.
     */
    function setApprovalForAllERC1155(address _erc1155, address _operator, bool _approved) external;

    /**
     * @notice This function allows a caller to perform a ERC1155 transfer.
     * @dev The function must be called by a user with the FINANCIAL_ROLE.
     * @param _erc1155 The ERC1155 token contract.
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _id The ID of the token to transfer.
     * @param _amount The amount of the token to transfer.
     */
    function transferFromERC1155(address _erc1155, address _from, address _to, uint256 _id, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ITeamSmartWalletHelper
 *
 * @notice A smart wallet which helps users more easily access TeamSmartWallet functionality
 */
interface ITeamSmartWalletHelper {
    /**
     * @notice Initialize function used instead of constructor to properly support proxy contracts.
     * @param _teamSmartWallet The TeamSmartWallet associated with this helper.
     */
    function initialize(address _teamSmartWallet) external;

    /**
     * @notice Function to permanently renounce this helper from a team.
     */
    function unregister() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {SignatureValidator, Signature} from "../utils/SignatureValidator.sol";
import {ITeamSmartWallet, IERC20, IEscrow} from "./ITeamSmartWallet.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ITeamSmartWalletHelper} from "./ITeamSmartWalletHelper.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Tax} from "../marketplace/taxes/Tax.sol";

/**
 * @title TeamSmartWalletPermitHelper
 *
 * @notice A smart contract for managing permit calls on behalf of a TeamSmartWallet.
 *
 * @dev It follows EIP-712 standard to allow permit access.
 */
contract TeamSmartWalletPermitHelper is ITeamSmartWalletHelper, SignatureValidator, Initializable {
    /// @notice Role that allows a user to execute trading functions
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;

    /// @notice Role that allows a user to execute trading functions
    bytes32 public constant TRADING_ROLE = keccak256("TRADING_ROLE");

    /// @notice Role that allows a user to execute financial functions
    bytes32 public constant FINANCIAL_ROLE = keccak256("FINANCIAL_ROLE");

    /// @notice Role that allows a user to upgrade the smart contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    ITeamSmartWallet public teamSmartWallet; // The TeamSmartWallet it assists with

    /**
     * @notice Initialize function used instead of constructor to properly support proxy contracts.
     * @param _teamSmartWallet The TeamSmartWallet associated with this helper.
     */
    function initialize(address _teamSmartWallet) public initializer {
        teamSmartWallet = ITeamSmartWallet(_teamSmartWallet);
        __SignatureValidator_init("TeamSmartWalletPermitHelper", "v1.0");
    }

    /**
     * @notice Modifier to check if signer has a given role.
     * @param _role The role to check.
     * @param _signature The signer struct containing the signature, signer and deadline.
     * @param _permitHash The EIP-712 hash to validate.
     */
    modifier isSignerAndSignatureValid(
        bytes32 _role,
        Signature memory _signature,
        bytes32 _permitHash
    ) {
        require(IAccessControl(address(teamSmartWallet)).hasRole(_role, _signature.signer), "Signer missing role");
        validateSignatureAndUpdateNonce(_signature, _permitHash);
        _;
    }

    /**
     * @notice Function to permanently renounce this helper from a team.
     */
    function unregister() public {
        require(
            IAccessControl(address(teamSmartWallet)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller cannot unregister"
        );
        address teamSmartWalletAddress = address(teamSmartWallet);
        teamSmartWallet = ITeamSmartWallet(address(0));

        IAccessControl(address(teamSmartWalletAddress)).renounceRole(DEFAULT_ADMIN_ROLE, address(this));
        IAccessControl(address(teamSmartWalletAddress)).renounceRole(TRADING_ROLE, address(this));
        IAccessControl(address(teamSmartWalletAddress)).renounceRole(FINANCIAL_ROLE, address(this));
        IAccessControl(address(teamSmartWalletAddress)).renounceRole(UPGRADER_ROLE, address(this));
    }

    /**
     * @notice This function is used to grant a role to a user using a permit mechanism.
     * @dev The permit must be signed by a user with the DEFAULT_ADMIN_ROLE.
     * @param _role The role to grant.
     * @param _user The address of the user to grant the role to.
     * @param _signature The signers signature, address and deadline.
     */
    function permitGrantRole(
        bytes32 _role,
        address _user,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(DEFAULT_ADMIN_ROLE, _signature, _getPermitGrantRoleHash(_signature, _role, _user))
    {
        IAccessControl(address(teamSmartWallet)).grantRole(_role, _user);
    }

    /**
     * @notice This function is used to revoke a role from a user using a permit mechanism.
     * @dev The permit must be signed by a user with the DEFAULT_ADMIN_ROLE.
     * @param _role The role to revoke.
     * @param _user The address of the user from whom to revoke the role.
     * @param _signature The signers signature, address and deadline.
     */
    function permitRevokeRole(
        bytes32 _role,
        address _user,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(DEFAULT_ADMIN_ROLE, _signature, _getPermitRevokeRoleHash(_signature, _role, _user))
    {
        IAccessControl(address(teamSmartWallet)).revokeRole(_role, _user);
    }

    /**
     * @notice This function allows a signed permit to perform a native transfer.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _recipient The address of the recipient.
     * @param _amount The amount to transfer.
     * @param _signature The signers signature, address and deadline.
     */
    function permitTransferNative(
        address payable _recipient,
        uint256 _amount,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(FINANCIAL_ROLE, _signature, _getPermitTransferHash(_signature, _recipient, _amount))
    {
        teamSmartWallet.transferNative(_recipient, _amount);
    }

    /**
     * @notice This function allows a signed permit to approve a ERC20 transfer.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _token The ERC20 token to approve.
     * @param _spender The address of the spender.
     * @param _amount The amount to approve.
     * @param _signature The signers signature, address and deadline.
     */
    function permitApproveERC20(
        IERC20 _token,
        address _spender,
        uint256 _amount,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitApproveERC20Hash(_signature, _token, _spender, _amount)
        )
        returns (bool)
    {
        return teamSmartWallet.approveERC20(_token, _spender, _amount);
    }

    /**
     * @notice This function allows a signed permit to perform a ERC20 transfer.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _token The ERC20 token to transfer.
     * @param _recipient The address of the recipient.
     * @param _amount The amount to transfer.
     * @param _signature The signers signature, address and deadline.
     */
    function permitTransferERC20(
        address _token,
        address _recipient,
        uint256 _amount,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitTransferERC20Hash(_signature, _token, _recipient, _amount)
        )
        returns (bool)
    {
        return teamSmartWallet.transferERC20(_token, _recipient, _amount);
    }

    /**
     * @notice This function allows a signed permit to approve a ERC721 transfer.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _token The ERC721 token to approve.
     * @param _to The address to approve.
     * @param _tokenId The ID of the token to approve.
     * @param _signature The signers signature, address and deadline.
     */
    function permitApproveERC721(
        address _token,
        address _to,
        uint256 _tokenId,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitApproveERC721Hash(_signature, _token, _to, _tokenId)
        )
    {
        teamSmartWallet.approveERC721(_token, _to, _tokenId);
    }

    /**
     * @notice This function allows a signed permit to approve or revoke approval of an operator to transfer any NFT by the owner.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _erc721 The ERC721 contract to approve.
     * @param _operator The address to approve.
     * @param _approved The approval status.
     * @param _signature The signers signature, address and deadline.
     */
    function permitSetApprovalForAllERC721(
        address _erc721,
        address _operator,
        bool _approved,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitSetApprovalForAllERC721Hash(_signature, _erc721, _operator, _approved)
        )
    {
        teamSmartWallet.setApprovalForAllERC721(_erc721, _operator, _approved);
    }

    /**
     * @notice This function allows a signed permit to perform a ERC721 transfer.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _token The ERC721 token to transfer.
     * @param _recipient The address of the recipient.
     * @param _tokenId The ID of the token to transfer.
     * @param _signature The signers signature, address and deadline.
     */
    function permitTransferERC721(
        address _token,
        address _recipient,
        uint256 _tokenId,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitTransferERC721Hash(_signature, _token, _recipient, _tokenId)
        )
    {
        teamSmartWallet.transferERC721(_token, _recipient, _tokenId);
    }

    /**
     * @notice This function allows a signed permit to set approval for all ERC1155 tokens.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _erc1155 The ERC1155 token contract.
     * @param _operator The operator to be approved or disapproved.
     * @param _approved Approval status to set for the operator.
     * @param _signature The signers signature, address and deadline.
     */
    function permitSetApprovalForAllERC1155(
        address _erc1155,
        address _operator,
        bool _approved,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitSetApprovalForAllERC1155Hash(_signature, _erc1155, _operator, _approved)
        )
    {
        teamSmartWallet.setApprovalForAllERC1155(_erc1155, _operator, _approved);
    }

    /**
     * @notice This function allows a signed permit to perform a ERC1155 transfer.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _erc1155 The ERC1155 token contract.
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _id The ID of the token to transfer.
     * @param _amount The amount of the token to transfer.
     * @param _signature The signers signature, address and deadline.
     */
    function permitTransferFromERC1155(
        address _erc1155,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            FINANCIAL_ROLE,
            _signature,
            _getPermitTransferFromERC1155Hash(_signature, _erc1155, _from, _to, _id, _amount)
        )
    {
        teamSmartWallet.transferFromERC1155(_erc1155, _from, _to, _id, _amount);
    }

    /**
     * @notice This function allows a signed permit to list an NFT for sale.
     * @dev The permit must be signed by a user with the FINANCIAL_ROLE.
     * @param _collection The NFT collection contract.
     * @param _tokenId The ID of the NFT to list.
     * @param _erc20 The ERC20 token in which the NFT will be priced.
     * @param _price The listing price of the NFT.
     * @param _signature The signers signature, address and deadline.
     */
    function permitList(
        address _collection,
        uint256 _tokenId,
        address _erc20,
        uint256 _price,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            TRADING_ROLE,
            _signature,
            _getPermitListHash(_signature, _collection, _tokenId, _erc20, _price)
        )
    {
        teamSmartWallet.list(_collection, _tokenId, _erc20, _price);
    }

    /**
     * @notice This function allows a signed permit to delist an NFT from sale.
     * @dev The permit must be signed by a user with the TRADING_ROLE.
     * @param _collection The NFT collection contract.
     * @param _tokenId The ID of the NFT to delist.
     * @param _erc20 The ERC20 token in which the NFT is priced.
     * @param _signature The signers signature, address and deadline.
     */
    function permitDelist(
        address _collection,
        uint256 _tokenId,
        address _erc20,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            TRADING_ROLE,
            _signature,
            _getPermitDelistHash(_signature, _collection, _tokenId, _erc20)
        )
    {
        teamSmartWallet.delist(_collection, _tokenId, _erc20);
    }

    /**
     * @notice This function allows a signed permit to buy an NFT.
     * @dev The permit must be signed by a user with the TRADING_ROLE.
     * @param _collection The NFT collection contract.
     * @param _tokenId The ID of the NFT to buy.
     * @param _erc20 The ERC20 token in which the NFT is priced.
     * @param _taxes Taxes to be paid on the purchase.
     * @param _payNow Whether the buyer will pay now or later.
     * @param _taxesSignature Signature from the relayer signing the taxes.
     * @param _buySignature Signature from the user invoking the buy.
     */
    function permitBuy(
        address _collection,
        uint256 _tokenId,
        address _erc20,
        Tax memory _taxes,
        bool _payNow,
        Signature memory _taxesSignature,
        Signature memory _buySignature
    )
        public
        isSignerAndSignatureValid(
            TRADING_ROLE,
            _buySignature,
            _getPermitBuyHash(_buySignature, _collection, _tokenId, _erc20, _payNow)
        )
    {
        teamSmartWallet.buy(_collection, _tokenId, _erc20, _taxes, _payNow, _taxesSignature);
    }

    /**
     * @notice This function allows a signed permit to make an offer for an NFT.
     * @dev The permit must be signed by a user with the TRADING_ROLE.
     * @param _collection The NFT collection contract.
     * @param _tokenId The ID of the NFT to make an offer for.
     * @param _erc20 The ERC20 token in which the offer is priced.
     * @param _price The offering price.
     * @param _signature The signers signature, address and deadline.
     */
    function permitOffer(
        address _collection,
        uint256 _tokenId,
        address _erc20,
        uint256 _price,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            TRADING_ROLE,
            _signature,
            _getPermitOfferHash(_signature, _collection, _tokenId, _erc20, _price)
        )
    {
        teamSmartWallet.offer(_collection, _tokenId, _erc20, _price);
    }

    /**
     * @notice This function allows a signed permit to revoke an offer for an NFT.
     * @dev The permit must be signed by a user with the TRADING_ROLE.
     * @param _collection The NFT collection contract.
     * @param _tokenId The ID of the NFT for which to revoke the offer.
     * @param _erc20 The ERC20 token in which the offer is priced.
     * @param _signature The signers signature, address and deadline.
     */
    function permitRevokeOffer(
        address _collection,
        uint256 _tokenId,
        address _erc20,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            TRADING_ROLE,
            _signature,
            _getPermitRevokeOfferHash(_signature, _collection, _tokenId, _erc20)
        )
    {
        teamSmartWallet.revokeOffer(_collection, _tokenId, _erc20);
    }

    /**
     * @notice This function allows a signed permit to accept an offer for an NFT.
     * @dev The permit must be signed by a user with the TRADING_ROLE.
     * @param _buyer The address of the user who made the offer.
     * @param _erc20 The ERC20 token in which the offer is priced.
     * @param _collection The NFT collection contract.
     * @param _tokenId The ID of the NFT for which to accept the offer.
     * @param _signature The signers signature, address and deadline.
     */
    function permitAcceptOffer(
        address _buyer,
        address _erc20,
        address _collection,
        uint256 _tokenId,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(
            TRADING_ROLE,
            _signature,
            _getPermitAcceptOfferHash(_signature, _buyer, _erc20, _collection, _tokenId)
        )
    {
        teamSmartWallet.acceptOffer(_buyer, _erc20, _collection, _tokenId);
    }

    /**
     * @notice This function allows a signed permit to update the state of a sale.
     * @dev The permit must be signed by a user with the TRADING_ROLE.
     * @param _saleId The ID of the sale to update.
     * @param _newState The new state of the sale.
     * @param _signature The signers signature, address and deadline.
     */
    function permitUpdateSale(
        uint256 _saleId,
        IEscrow.State _newState,
        Signature memory _signature
    )
        public
        isSignerAndSignatureValid(TRADING_ROLE, _signature, _getPermitUpdateSaleHash(_signature, _saleId, _newState))
    {
        teamSmartWallet.updateSale(_saleId, _newState);
    }

    /**
     * @notice Generates a unique hash to be signed for granting a role to a user.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _role The role identifier to grant.
     * @param _user The address of the user to grant the role to.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitGrantRoleHash(
        Signature memory _signature,
        bytes32 _role,
        address _user
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("GrantRole(address owner,bytes32 role,address user,uint256 deadline,uint256 nonce)"),
                    _signature.signer,
                    _role,
                    _user,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for revoking a role from a user.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _role The role identifier to revoke.
     * @param _user The address of the user from whom to revoke the role.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitRevokeRoleHash(
        Signature memory _signature,
        bytes32 _role,
        address _user
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("RevokeRole(address owner,bytes32 role,address user,uint256 deadline,uint256 nonce)"),
                    _signature.signer,
                    _role,
                    _user,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for transferring native token (such as ETH) from the owner to the recipient.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _recipient The address of the user to whom the token will be transferred.
     * @param _amount The amount of token to transfer.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitTransferHash(
        Signature memory _signature,
        address _recipient,
        uint256 _amount
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Transfer(address owner,address recipient,uint256 amount,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _recipient,
                    _amount,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for approving an ERC20 token allowance.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _token The ERC20 token to approve.
     * @param _spender The address of the user to grant the allowance to.
     * @param _amount The amount of tokens to approve.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitApproveERC20Hash(
        Signature memory _signature,
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "ApproveERC20(address owner,address token,address spender,uint256 amount,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    address(_token),
                    _spender,
                    _amount,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for transferring ERC20 tokens.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _token The ERC20 token to transfer.
     * @param _recipient The address of the user to whom the tokens will be transferred.
     * @param _amount The amount of tokens to transfer.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitTransferERC20Hash(
        Signature memory _signature,
        address _token,
        address _recipient,
        uint256 _amount
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "TransferERC20(address owner,address token,address recipient,uint256 amount,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _token,
                    _recipient,
                    _amount,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for approving an ERC721 token transfer.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _token The ERC721 token to approve.
     * @param _to The address of the user to whom the token transfer will be approved.
     * @param _tokenId The ID of the token to approve.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitApproveERC721Hash(
        Signature memory _signature,
        address _token,
        address _to,
        uint256 _tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "ApproveERC721(address owner,address token,address to,uint256 tokenId,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    address(_token),
                    _to,
                    _tokenId,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for approving a operator to transfer all NFTs by the owner.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _erc721 The ERC721 contract to approve.
     * @param _operator The address of the user to whom the token transfer will be approved.
     * @param _approved The approval status of the operator.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitSetApprovalForAllERC721Hash(
        Signature memory _signature,
        address _erc721,
        address _operator,
        bool _approved
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "SetApprovalForAllERC721(address signer,address erc721,address operator,bool approved,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _erc721,
                    _operator,
                    _approved,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for transferring an ERC721 token.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _token The ERC721 token to transfer.
     * @param _recipient The address of the user to whom the token will be transferred.
     * @param _tokenId The ID of the token to transfer.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitTransferERC721Hash(
        Signature memory _signature,
        address _token,
        address _recipient,
        uint256 _tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "TransferERC721(address owner,address token,address recipient,uint256 tokenId,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _token,
                    _recipient,
                    _tokenId,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for listing a token on a marketplace.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to list.
     * @param _erc20 The address of the ERC20 token to accept as payment.
     * @param _price The price at which the token will be listed.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitListHash(
        Signature memory _signature,
        address _collection,
        uint256 _tokenId,
        address _erc20,
        uint256 _price
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "List(address owner,address collection,uint256 tokenId,address erc20,uint256 price,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _collection,
                    _tokenId,
                    _erc20,
                    _price,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for delisting a token from the marketplace.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to delist.
     * @param _erc20 The address of the ERC20 token used in the original listing.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitDelistHash(
        Signature memory _signature,
        address _collection,
        uint256 _tokenId,
        address _erc20
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Delist(address owner,address collection,uint256 tokenId,address erc20,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _collection,
                    _tokenId,
                    _erc20,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for buying a token from the marketplace.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The buyers signature, address and deadline.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to buy.
     * @param _erc20 The address of the ERC20 token used to pay.
     * @param _payNow A boolean that indicates if the payment should be made immediately.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitBuyHash(
        Signature memory _signature,
        address _collection,
        uint256 _tokenId,
        address _erc20,
        bool _payNow
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Buy(address buyer,address collection,uint256 tokenId,address erc20,bool payNow,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _collection,
                    _tokenId,
                    _erc20,
                    _payNow,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for offering to buy a token from the marketplace.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token to buy.
     * @param _erc20 The address of the ERC20 token used to pay.
     * @param _price The price at which the offer is made.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitOfferHash(
        Signature memory _signature,
        address _collection,
        uint256 _tokenId,
        address _erc20,
        uint256 _price
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Offer(address offerer,address collection,uint256 tokenId,address erc20,uint256 price,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _collection,
                    _tokenId,
                    _erc20,
                    _price,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for revoking an offer from the marketplace.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token involved in the offer.
     * @param _erc20 The address of the ERC20 token used in the offer.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitRevokeOfferHash(
        Signature memory _signature,
        address _collection,
        uint256 _tokenId,
        address _erc20
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "RevokeOffer(address owner,address collection,uint256 tokenId,address erc20,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _collection,
                    _tokenId,
                    _erc20,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for accepting an offer from the marketplace.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _buyer The address of the user who made the offer.
     * @param _erc20 The address of the ERC20 token used in the offer.
     * @param _collection The address of the token's collection.
     * @param _tokenId The ID of the token involved in the offer.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitAcceptOfferHash(
        Signature memory _signature,
        address _buyer,
        address _erc20,
        address _collection,
        uint256 _tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "AcceptOffer(address owner,address buyer,address erc20,address collection,uint256 tokenId,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _buyer,
                    _erc20,
                    _collection,
                    _tokenId,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for updating the state of a sale.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _saleId The ID of the sale to update.
     * @param _newState The new state of the sale.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitUpdateSaleHash(
        Signature memory _signature,
        uint256 _saleId,
        IEscrow.State _newState
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "UpdateSale(address signer,uint256 saleId,uint256 newState,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _saleId,
                    uint256(_newState),
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for setting an operator's approval status on all tokens of a certain ERC1155 contract for a user.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _erc1155 The address of the ERC1155 contract.
     * @param _operator The address of the operator.
     * @param _approved Whether the operator is approved or not.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitSetApprovalForAllERC1155Hash(
        Signature memory _signature,
        address _erc1155,
        address _operator,
        bool _approved
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "SetApprovalForAllERC1155(address signer,address erc1155,address operator,bool approved,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _erc1155,
                    _operator,
                    _approved,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }

    /**
     * @notice Generates a unique hash to be signed for transferring a certain amount of a specific ERC1155 token from one address to another.
     * @dev This method is compliant with the EIP712 standard.
     * @param _signature The signers signature, address and deadline.
     * @param _erc1155 The address of the ERC1155 contract.
     * @param _from The address from which the tokens will be transferred.
     * @param _to The address to which the tokens will be transferred.
     * @param _id The ID of the token to transfer.
     * @param _value The amount of the token to transfer.
     * @return A unique hash that represents the requested operation.
     */
    function _getPermitTransferFromERC1155Hash(
        Signature memory _signature,
        address _erc1155,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "TransferFromERC1155(address signer,address erc1155,address from,address to,uint256 id,uint256 value,uint256 deadline,uint256 nonce)"
                    ),
                    _signature.signer,
                    _erc1155,
                    _from,
                    _to,
                    _id,
                    _value,
                    _signature.deadline,
                    nonces(_signature.signer)
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

struct Signature {
    address signer;
    uint256 deadline;
    bytes signature;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Signature} from "./Signature.sol";

/// @title SignatureValidator
/// @dev This contract validates the signatures associated with EIP-712 typed structures.
contract SignatureValidator {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // @dev Each address has a nonce that is incremented after each use.
    mapping(address => Counters.Counter) private _nonces;

    // @dev Domain name and version for EIP712 signatures
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    string private name_;
    string private version_;

    /// @notice Initializes the `DOMAIN_SEPARATOR` value.
    /// @dev The function is meant to be called in the constructor of the contract implementing this logic.
    // solhint-disable-next-line func-name-mixedcase
    function __SignatureValidator_init(string memory _name, string memory _version) internal {
        name_ = _name;
        version_ = _version;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Validates a signature.
    /// @dev This modifier checks if the signature associated with a `_permitHash` is valid.
    /// @param _signature The signer struct containing the signature, signer and deadline.
    /// @param _permitHash The EIP-712 permit hash.
    modifier isValidSignature(Signature memory _signature, bytes32 _permitHash) {
        validateSignatureAndUpdateNonce(_signature, _permitHash);
        _;
    }

    /// @notice Validates a signature.
    /// @dev This function checks if the signature associated with a `_permitHash` is valid.
    /// @param _signature The signer struct containing the signature, signer and deadline.
    /// @param _permitHash The EIP-712 permit hash.
    function validateSignatureAndUpdateNonce(Signature memory _signature, bytes32 _permitHash) internal {
        bytes32 permitHash = keccak256(
            abi.encodePacked(
                "\x19\x01", // EIP191: Indicates EIP712
                DOMAIN_SEPARATOR,
                _permitHash
            )
        );

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= _signature.deadline, "Expired deadline");
        address verifiedSigner = permitHash.recover(_signature.signature);
        require(verifiedSigner == _signature.signer, "Invalid signature");
        Counters.Counter storage nonce = _nonces[_signature.signer];
        nonce.increment();
    }

    /// @notice Returns the nonce associated with a user.
    /// @dev The nonce is incremented after each use.
    /// @param _user The user's address.
    /// @return Returns the current nonce value.
    function nonces(address _user) public view returns (uint256) {
        return _nonces[_user].current();
    }

    /// @notice Returns the EIP712 domain separator components.
    /// @dev This can be used to verify the domain of the EIP712 signature.
    /// @return name The domain name.
    /// @return version The domain version.
    /// @return chainId The current chain ID.
    /// @return verifyingContract The address of the verifying contract.
    function eip712Domain()
        public
        view
        virtual
        returns (string memory name, string memory version, uint256 chainId, address verifyingContract)
    {
        return (name_, version_, block.chainid, address(this));
    }
}