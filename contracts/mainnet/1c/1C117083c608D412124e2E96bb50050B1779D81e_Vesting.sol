// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IVesting.sol";
    /**
    * @title Vesting contract
    * @notice The Vesting contract exists in a single instance and helps manage the vesting processes for all successful TGEs.
    * @dev The vesting setup is performed by passing a value as one of the fields of the TGEInfo structure called "vestingParams", which is a structure of IVesting.VestingParams. This set of settings allows you to specify:
    - what portion of the tokens will be released and directed to the buyer's wallet within the purchase transaction (using the TGE:purchase method);
    - what portion of the tokens will be available for claim after the cliff period and the duration of this period;
    - what percentage of the remaining tokens will be distributed equally over equal time intervals (as well as the number and duration of these intervals).
    Any of these fields can accept zero values, for example, you can set the distribution of tokens without a cliff period or, conversely, split the receipt of values into two parts (immediately and after some time), without specifying time intervals.
    @dev For each TGE, a list of Resolvers can be assigned, i.e., addresses that can stop the vesting program for a specific user. 
    The list of resolvers is immutable for each individual TGE and is set at the time of its launch (it can be stored in the proposal data for creating the TGE beforehand).
    */
contract Vesting is Initializable, IVesting {
    using SafeERC20Upgradeable for IToken;

    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10 ** 4;

    // STORAGE

    /// @notice Registry contract address
    IRegistry public registry;

    /// @notice Mapping that stores the total amount of tokens locked in vesting for each conducted TGE.
    /// @dev Claiming tokens does not modify these data; they are used to calculate the amount of tokens that can be claimed by a specific address and to determine the total amount of tokens in vesting for a given account.
    /// @dev In the event of vesting cancellation for a specific address in any TGE, the value under the TGE address key is decreased by the full amount of tokens locked in vesting for that address.
    mapping(address => uint256) public totalVested;

    /// @notice Mapping (tge, account) to amount of tokens vested to that account in TGE
    /// @dev The vesting contract does not store tokens, but it contains records of which address is entitled to what amount of tokens for which TGE when the conditions set in the settings are met. This means that minting these tokens only occurs when the owner of the address requests them, prior to that, they are not included in totalSupply or balances. No record in Vesting can affect the vote calculation for Governance.
    mapping(address => mapping(address => uint256)) public vested;

    /// @notice Mapping that stores the total amount of tokens vested by a specific address for a given TGE.
    /// @dev This parameter increases every time a successful transaction is made to the Claim method by an address.
    mapping(address => mapping(address => uint256)) public claimed;

    /// @notice Mapping of flags indicating whether the TVL threshold set in the TGE conditions has been reached by the pool.
    /// @dev It is one of the two conditions under which users can claim tokens reserved for them under the vesting program.
    mapping(address => bool) public claimTVLReached;

    /// @notice Mapping that shows the amount of tokens that will not be transferred to the user during claiming due to the cancellation of vesting by a resolver.
    mapping(address => mapping(address => uint256)) public resolved;

    // EVENTS

    /**
    * @dev This event is emitted when new token units are vested due to token purchase.
    * @param tge TGE contract address
    * @param account Account address
    * @param amount Amount of tokens vested for the account
    */
    event Vested(address tge, address account, uint256 amount);

    /**
    * @dev This event is emitted for each token claiming by users.
    * @param tge TGE contract address
    * @param account Account address that requested the token claiming
    * @param amount Amount of claimed tokens
    */
    event Claimed(address tge, address account, uint256 amount);

    /**
    * @dev This event is emitted when vesting is canceled for a specific account and TGE.
    * @param tge TGE contract address
    * @param account Account address
    * @param amount Amount of tokens that will not be distributed to this address due to the cancellation
    */
    event Cancelled(address tge, address account, uint256 amount);

    // MODIFIERS

    /// @notice Modifier allows the method to be called only by the TGE contract.
    /// @dev This modifier is commonly used for calling the `vest` method, which registers the arrival of new token units into vesting as a result of a successful `purchase` method call in the TGE contract.
    modifier onlyTGE() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }
    
    /// @notice Modifier allows the method to be called only by an account that has the role of `SERVICE_MANAGER` in the Service contract.
    /// @dev It restricts access to certain privileged actions that are reserved for the manager.
    modifier onlyManager() {
        IService service = registry.service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier allows the method to be called only by an account whose address is specified in the list of resolvers for a given TGE.
    modifier onlyResolverOrTGE(address tge) {
        if (msg.sender != tge) {
            address[] memory resolvers = ITGE(tge)
                .getInfo()
                .vestingParams
                .resolvers;
            bool isResolver;
            for (uint256 i = 0; i < resolvers.length; i++) {
                if (resolvers[i] == msg.sender) {
                    isResolver = true;
                    break;
                }
            }
            require(isResolver, ExceptionsLibrary.NOT_RESOLVER);
        }
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer
     * @dev This method replaces the constructor for upgradeable contracts. Additionally, it sets the address of the Registry contract in the contract's storage.
     * @param registry_ Protocol registry address
     */
    function initialize(IRegistry registry_) external initializer {
        registry = registry_;
    }

    // PUBLIC FUNCTIONS

    /**
    * @notice Method for increasing the token balance in vesting for a specific TGE contract.
    * @dev This method is called only by the TGE contract and results in the creation of a new entry or an increase in the existing value in the vested mapping for the TGE key and the specified account. After this, the account is reserved the ability to mint and receive new token units in case the conditions specified in the vesting program for this TGE are met.
    * @param to Account address that received the vested tokens
    * @param amount Amount of tokens to vest
     */
    function vest(address to, uint256 amount) external onlyTGE {
        totalVested[msg.sender] += amount;
        vested[msg.sender][to] += amount;

        emit Vested(msg.sender, to, amount);
    }

    /**
    * @notice Method for recording the occurrence of one of two conditions for token unlocking.
    * @dev This method can only be called by the address with the SERVICE_MANAGER role in the Service contract. It is a trusted way to load data into the source of truth about the TVL events achieved by the pool, as specified in the parameters of the vesting program.
    * @param tge TGE contract address
     */
    function setClaimTVLReached(address tge) external onlyManager {
        require(
            ITGE(tge).state() == ITGE.State.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        claimTVLReached[tge] = true;
    }

    /**
    * @notice Cancels vesting for the specified account and TGE contract addresses.
    * @dev Calling this method is only possible by the address specified in the resolvers list for the specific TGE, and it leads to resetting the token balance in vesting for the specified address, depriving it of the ability to make successful token claiming within the specified TGE.
    * @param tge TGE contract address
    * @param account Account address
     */
    function cancel(
        address tge,
        address account
    ) external onlyResolverOrTGE(tge) {
        uint256 amount = vestedBalanceOf(tge, account);

        vested[tge][account] -= amount;
        totalVested[tge] -= amount;

        resolved[tge][account] += amount;

        emit Cancelled(tge, account, amount);
    }

    /**
    * @notice Method to issue and transfer unlocked tokens to the transaction sender's address.
    * @dev This method is executed with the specified TGE, for which the currently unlocked token volume is calculated. Calling the method results in the issuance and transfer of the entire calculated token volume to the sender's address.
    * @param tge TGE contract address
     */
    function claim(address tge) external {
        uint256 amount = claimableBalanceOf(tge, msg.sender);
        require(amount > 0, ExceptionsLibrary.CLAIM_NOT_AVAILABLE);

        claimed[tge][msg.sender] += amount;
        totalVested[tge] -= amount;

        address token = ITGE(tge).token();
        uint256 tokenId = ITGE(tge).tokenId();
        if (ITGE(tge).isERC1155TGE()) {
            ITokenERC1155(token).setTGEVestedTokens(
                ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) - amount,
                tokenId
            );

            ITokenERC1155(token).mint(msg.sender, tokenId, amount);
        } else {
            IToken(token).setTGEVestedTokens(
                IToken(token).getTotalTGEVestedTokens() - amount
            );

            IToken(token).mint(msg.sender, amount);
        }

        IToken(token).service().registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IVesting.claim.selector, tge)
        );

        emit Claimed(tge, msg.sender, amount);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
    * @notice This method returns the vesting parameters specified for a specific TGE.
    * @param tge TGE contract address
    * @return VestingParams Vesting settings
     */
    function vestingParams(
        address tge
    ) public view returns (VestingParams memory) {
        return ITGE(tge).getInfo().vestingParams;
    }

    /**
    * @notice This method validates the vesting program parameters proposed for use in the created TGE contract.
    * @param params Vesting program parameters
    * @return bool True if params are valid (reverts otherwise)
     */
    function validateParams(
        VestingParams memory params
    ) public pure returns (bool) {
        require(
            params.cliffShare + params.spans * params.spanShare <= DENOM,
            ExceptionsLibrary.SHARES_SUM_EXCEEDS_ONE
        );
        return true;
    }

    /**
    * @notice This method returns the number of token units that have been unlocked for a specific account within the vesting program of a particular TGE.
    * @dev The returned value is the total sum of all quantities after all token unlocks that have occurred for this account within this TGE. In other words, claimed tokens are also part of this response.
    * @param tge TGE contract address
    * @param account Account address
    * @return uint256 Number of unlocked token units
     */
    function unlockedBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        // In active or failed TGE nothing is unlocked
        if (ITGE(tge).state() != ITGE.State.Successful) {
            return 0;
        }

        // Is claim TVL is non-zero and is not reached, nothing is unlocked
        VestingParams memory params = vestingParams(tge);
        if (params.claimTVL > 0 && !claimTVLReached[tge]) {
            return 0;
        }

        // Determine unlocked amount
        uint256 tgeEnd = ITGE(tge).getEnd();
        if (block.number < tgeEnd + params.cliff) {
            // If cliff is not exceeded, nothing is unlocked yet
            return 0;
        } else if (
            block.number <
            tgeEnd + params.cliff + params.spans * params.spanDuration
        ) {
            // If cliff is reached, but not all the period passed, calculate vested amount
            uint256 spansUnlocked = (block.number - tgeEnd - params.cliff) /
                params.spanDuration;
            uint256 totalShare = params.cliffShare +
                spansUnlocked *
                params.spanShare;
            return (vested[tge][account] * totalShare) / DENOM;
        } else {
            // Otherwise everything is unlocked
            return vested[tge][account];
        }
    }

    /**
    * @notice This method returns the currently available amount of token units that an account can claim within the specified TGE.
    * @dev This method takes into account previous claimings made by the account.
    * @param tge TGE contract address
    * @param account Account address
    * @return uin256 Number of claimable token units
     */
    function claimableBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        return unlockedBalanceOf(tge, account) - claimed[tge][account];
    }

    /**
    * @notice This method shows the remaining tokens that are still vested for a given address.
    * @dev This method shows both still locked token units and already unlocked units ready for claiming.
    * @param tge TGE contract address
    * @param account Account address
    * @return uint256 Number of token units vested
     */
    function vestedBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        return vested[tge][account] - claimed[tge][account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";

import "./governor/IGovernanceSettings.sol";

interface ICustomProposal {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
/**
 * @title Invoice Interface
 * @notice These structures are used to describe an instance of an invoice.
 * @dev The storage of invoices is managed in Invoice.sol in the `invoices` variable.
*/
interface IInvoice {
    /** 
    * @notice This interface contains a data structure that describes the payment rules for an invoice. 
    * @dev This data is used to validate the payment transaction, determine the state of the invoice, and so on. This data is formed from the input of the invoice creator.
    * @param amount Amount to be paid
    * @param unitOfAccount The address of the token contract that can be used to make the payment (a zero address assumes payment in native ETH)
    * @param expirationBlock The block at which the invoice expires
    * @param description Description of the invoice
    * @param whitelist A whitelist of payers. An empty array denotes a public invoice.
    */
    struct InvoiceCore {
        uint256 amount;
        address unitOfAccount;
        uint256 expirationBlock;
        string description;
        address[] whitelist;
    }
    /**
    * @notice This interface is used to store complete records of invoices, including their current state, metadata, and payment rules.
    * @dev This data is automatically formed when the invoice is created and changes when state-changing transactions are executed.
    * @param core Payment rules (user input)
    * @param invoiceId Invoice identifier
    * @param createdBy The creator of the invoice
    * @param isPaid Flag indicating whether the invoice has been successfully paid
    * @param isCanceled Flag indicating whether the invoice has been canceled
    */
    struct InvoiceInfo {
        InvoiceCore core;
        uint256 invoiceId;
        address createdBy;
        bool isPaid;
        bool isCanceled;
    }
    /**
    * @notice Encoding the states of an individual invoice
    * @dev None - for a non-existent invoice, Paid, Expired, Canceled - are completed invoice states where payment is not possible.
    */
    enum InvoiceState {
        None,
        Active,
        Paid,
        Expired,
        Canceled
    }

    function createInvoice(address pool, InvoiceCore memory core) external;

    function payInvoice(address pool, uint256 invoiceId) external payable;

    function cancelInvoice(address pool, uint256 invoiceId) external;

    function setInvoiceCanceled(address pool, uint256 invoiceId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./registry/ICompaniesRegistry.sol";

import "./governor/IGovernor.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(
        ICompaniesRegistry.CompanyInfo memory companyInfo_
    ) external;

    function setNewOwnerWithSettings(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_
    ) external;

    function propose(
        address proposer,
        uint256 proposalType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId);

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function setProposalIdToTGE(address tge) external;

    function cancelProposal(uint256 proposalId) external;

    function setSettings(
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function getGovernanceToken() external view returns (IToken);

    function tokenExists(IToken token_) external view returns (bool);

    function tokenTypeByAddress(
        address token_
    ) external view returns (IToken.TokenType);

    function isValidProposer(address account) external view returns (bool);

    function isPoolSecretary(address account) external view returns (bool);

    function isLastProposalIdByTypeActive(
        uint256 type_
    ) external view returns (bool);

    function validateGovernanceSettings(
        IGovernanceSettings.NewGovernanceSettings memory settings
    ) external pure;

    function getPoolSecretary() external view returns (address[] memory);

    function getPoolExecutor() external view returns (address[] memory);

    function setCompanyInfo(
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein,
        string memory _dateOfIncorporation,
        string memory _OAuri
    ) external;

    function castVote(uint256 proposalId, bool support) external;

    function executeProposal(uint256 proposalId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "./ITGE.sol";
import "./ICustomProposal.sol";
import "./registry/IRecordsRegistry.sol";
import "./registry/ICompaniesRegistry.sol";
import "./registry/IRegistry.sol";
import "./IToken.sol";
import "./IInvoice.sol";
import "./IVesting.sol";
import "./ITokenFactory.sol";
import "./ITGEFactory.sol";
import "./IPool.sol";
import "./governor/IGovernanceSettings.sol";

interface IService is IAccessControlEnumerableUpgradeable {
    function ADMIN_ROLE() external view returns (bytes32);

    function WHITELISTED_USER_ROLE() external view returns (bytes32);

    function SERVICE_MANAGER_ROLE() external view returns (bytes32);

    function EXECUTOR_ROLE() external view returns (bytes32);

    function createPool(
        ICompaniesRegistry.CompanyInfo memory companyInfo
    ) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(
        IRecordsRegistry.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external;

    function setProtocolCollectedFee(
        address _token,
        uint256 _protocolTokenFee
    ) external;

    function registry() external view returns (IRegistry);

    function vesting() external view returns (IVesting);

    function tokenFactory() external view returns (ITokenFactory);

    function tgeFactory() external view returns (ITGEFactory);

    function invoice() external view returns (IInvoice);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(
        uint256 amount
    ) external view returns (uint256);

    function getProtocolCollectedFee(
        address token_
    ) external view returns (uint256);

    function poolBeacon() external view returns (address);

    function tgeBeacon() external view returns (address);

    function tokenBeacon() external view returns (address);

    function tokenERC1155Beacon() external view returns (address);

    function customProposal() external view returns (ICustomProposal);

    function validateTGEInfo(
        ITGE.TGEInfo calldata info,
        uint256 cap,
        uint256 totalSupply,
        IToken.TokenType tokenType
    ) external view;

    function getPoolAddress(
        ICompaniesRegistry.CompanyInfo memory info
    ) external view returns (address);

    function paused() external view returns (bool);

    function addInvoiceEvent(
        address pool,
        uint256 invoiceId
    ) external returns (uint256);

    function purchasePool(
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external payable;

    function transferPurchasedPoolByService(
        address newowner,
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";
import "./IVesting.sol";

interface ITGE {
    /**
    * @notice This structure defines comprehensive TGE settings, including Vesting, Lockup, and distribution rules for these tokens.
    * @dev Initially, such a structure appears as a parameter when creating a proposal in CustomProposal, after which the data from the structure is placed in the storage of the deployed TGE contract.
    * @dev In addition, these data are used as an argument in its original form in the TGEFactory contract, including when creating the initial TGE by the pool owner without a proposal.
    * @param price The price of one token in the smallest unitOfAccount (1 wei when defining the price in ETH, 0.000001 USDT when defining the price in USDT, etc.)
    * @param hardcap The maximum number of tokens that can be sold (note the ProtocolTokenFee for Governance Tokens)
    * @param softcap The minimum number of tokens that buyers must acquire for the TGE to be considered successful
    * @param minPurchase The minimum number of tokens that can be purchased by a single account (minimum one-time purchase)
    * @param maxPurchase The maximum number of tokens that can be purchased by a single account in total during the launched TGE 
    * @param duration The duration of the event in blocks, after which the TGE status will be forcibly changed from Active to another
    * @param vestingParams Vesting settings for tokens acquired during this TGE
    * @param userWhiteList A list of addresses allowed to participate in this TGE. Leave the list empty to make the TGE public.
    * @param unitOfAccount The address of the ERC20 or compatible token contract, in the smallest units of which the price of one token is determined
    * @param lockupDuration The duration of token lockup (in blocks), one of two independent lockup conditions.
    * @param lockupTVL The minimum total pool balance in USD, one of two independent lockup conditions.
    */

    struct TGEInfo {
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 duration;
        IVesting.VestingParams vestingParams;
        address[] userWhitelist;
        address unitOfAccount;
        uint256 lockupDuration;
        uint256 lockupTVL;
    }

    function initialize(
        address _service,
        address _token,
        uint256 _tokenId,
        string memory _uri,
        TGEInfo calldata _info,
        uint256 _protocolFee
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (address);

    function tokenId() external view returns (uint256);

    function state() external view returns (State);

    function getInfo() external view returns (TGEInfo memory);

    function transferUnlocked() external view returns (bool);

    function purchaseOf(address user) external view returns (uint256);

    function redeemableBalanceOf(address user) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function getEnd() external view returns (uint256);

    function totalPurchased() external view returns (uint256);

    function isERC1155TGE() external view returns (bool);

    function purchase(uint256 amount) external payable;

    function transferFunds() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";
import "./governor/IGovernanceSettings.sol";

interface ITGEFactory {
    function createSecondaryTGE(
        address token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createSecondaryTGEERC1155(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;

    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "./IService.sol";

interface IToken is IVotesUpgradeable, IERC20Upgradeable {
    /**
    * @notice This structure is used to define the parameters of ERC20 tokens issued by the protocol for pools.
    * @dev This structure is suitable for both Governance and Preference tokens if they are based on ERC20.
    * @param tokenType Numeric code for the token type
    * @param name Full name of the token
    * @param symbol Ticker symbol (short name) of the token
    * @param description Description of the token
    * @param cap Maximum allowable token issuance
    * @param decimals Number of decimal places for the token (precision)
    */
    struct TokenInfo {
        TokenType tokenType;
        string name;
        string symbol;
        string description;
        uint256 cap;
        uint8 decimals;
    }
    /**
    * @notice Token type encoding
    */
    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        IService service_,
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function cap() external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge) external;

    function setTGEVestedTokens(uint256 amount) external;

    function setProtocolFeeReserved(uint256 amount) external;

    function getTotalTGEVestedTokens() external view returns (uint256);

    function getTotalProtocolFeeReserved() external view returns (uint256);

    function totalSupplyWithReserves() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function delegate(
        address delegatee
    ) external; 
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./IService.sol";
import "./IToken.sol";

interface ITokenERC1155 is IERC1155Upgradeable {
    function initialize(
        IService service_,
        address pool_,
        IToken.TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 tokenId, uint256 amount) external;

    function burn(address from, uint256 tokenId, uint256 amount) external;

    function cap(uint256 tokenId) external view returns (uint256);

    function unlockedBalanceOf(
        address account,
        uint256 tokenId
    ) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function lastTokenId() external view returns (uint256);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (IToken.TokenType);

    function lastTGE(uint256 tokenId) external view returns (address);

    function getTGEList(
        uint256 tokenId
    ) external view returns (address[] memory);

    function isPrimaryTGESuccessful(
        uint256 tokenId
    ) external view returns (bool);

    function addTGE(address tge, uint256 tokenId) external;

    function setTGEVestedTokens(uint256 amount, uint256 tokenId) external;

    function setProtocolFeeReserved(uint256 amount, uint256 tokenId) external;

    function getTotalTGEVestedTokens(
        uint256 tokenId
    ) external view returns (uint256);

    function getTotalProtocolFeeReserved(
        uint256 tokenId
    ) external view returns (uint256);

    function totalSupplyWithReserves(
        uint256 tokenId
    ) external view returns (uint256);

    function setURI(uint256 tokenId, string memory tokenURI) external;

    function setTokenIdCap(uint256 _tokenId, uint256 _cap) external;

    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    function setLastTokenId(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";

interface ITokenFactory {
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (address token);

    function createTokenERC1155(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (address token);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVesting {
    /**
     * @notice This interface describes a vesting program for tokens distributed within a specific TGE.
     * @dev Such data is stored in the TGE contracts in the TGEInfo public info.
     * @param vestedShare The percentage of tokens that participate in the vesting program (not distributed until conditions are met)
     * @param cliff Cliff period (in blocks)
     * @param cliffShare The portion of tokens that are distributed
     * @param spans The number of periods for distributing the remaining tokens in vesting in equal shares
     * @param spanDuration The duration of one such period (in blocks)
     * @param spanShare The percentage of the total number of tokens in vesting that corresponds to one such period
     * @param claimTVL The minimum required TVL of the pool after which it will be possible to claim tokens from vesting. Optional parameter (0 if this condition is not needed)
     * @param resolvers A list of addresses that can cancel the vesting program for any address from the TGE participants list
     */
    struct VestingParams {
        uint256 vestedShare;
        uint256 cliff;
        uint256 cliffShare;
        uint256 spans;
        uint256 spanDuration;
        uint256 spanShare;
        uint256 claimTVL;
        address[] resolvers;
    }

    function vest(address to, uint256 amount) external;

    function cancel(address tge, address account) external;

    function validateParams(
        VestingParams memory params
    ) external pure returns (bool);

    function vested(
        address tge,
        address account
    ) external view returns (uint256);

    function totalVested(address tge) external view returns (uint256);

    function vestedBalanceOf(
        address tge,
        address account
    ) external view returns (uint256);

    function claim(address tge) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGovernanceSettings {
    /**
     * @notice This structure specifies and stores the Governance settings for each individual pool.
     * @dev More information on the thresholds (proposal, quorum, decision) and creating proposals can be found in the "Other Entities" section.
     * @param proposalThreshold_ The proposal threshold (specified in token units with decimals taken into account)
     * @param quorumThreshold_ The quorum threshold (specified as a percentage)
     * @param decisionThreshold_ The decision threshold (specified as a percentage)
     * @param votingDuration_ The duration of the voting period (specified in blocks)
     * @param transferValueForDelay_ The minimum amount in USD for which a transfer from the pool wallet will be subject to a del
     * @param executionDelays_ List of execution delays specified in blocks for different types of proposals
     * @param votingStartDelay The delay before voting starts for newly created proposals, specified in blocks
     */
    struct NewGovernanceSettings {
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 votingDuration;
        uint256 transferValueForDelay;
        uint256[4] executionDelays;
        uint256 votingStartDelay;
    }

    function setGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/registry/IRecordsRegistry.sol";

interface IGovernor {
    /**
     * @notice Struct with proposal core data
     * @dev This interface specifies the Governance settings that existed in the pool at the time of proposal creation, as well as the service data (to which addresses and with what messages and amounts of ETH should be sent) of the scenario that should be executed in case of a positive voting outcome.
     * @param targets A list of addresses to be called in case of a positive voting outcome
     * @param values The amounts of wei to be sent to the addresses from targets
     * @param callDatas The 'calldata' messages to be attached to transactions
     * @param quorumThreshold The quorum, expressed as a percentage with DENOM taken into account
     * @param decisionThreshold The decision-making threshold, expressed as a percentage with DENOM taken into account
     * @param executionDelay The number of blocks that must pass since the creation of the proposal for it to be considered launched
     */
    struct ProposalCoreData {
        address[] targets;
        uint256[] values;
        bytes[] callDatas;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 executionDelay;
    }

    /**
     * @notice This interface specifies information about the subject of the voting, intended for human perception.
     * @dev Struct with proposal metadata
     * @param proposalType The digital code of the proposal type
     * @param description The public description of the proposal
     * @param metaHash The identifier of the private proposal description stored on the backend
     */
    struct ProposalMetaData {
        IRecordsRegistry.EventType proposalType;
        string description;
        string metaHash;
    }

    function proposalState(uint256 proposalId)
        external
        view
        returns (uint256 state);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../IService.sol";

interface IGovernorProposals {
    function service() external view returns (IService);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ITGE.sol";
import "../IToken.sol";

interface ICompaniesRegistry {
    /**
    * @notice This is how immutable data about companies is stored
    * @dev For companies listed for sale, this data is stored in the Registry in mapping(uint256 => CompanyInfo) public companies. Additionally, this data is duplicated in the Pool contract in IRegistry.CompanyInfo public companyInfo.
    * @param jurisdiction Numeric code for the jurisdiction (region where the company is registered)
    * @param entityType Numeric code for the type of organization
    * @param ein Unique registration number (uniqueness is checked within a single jurisdiction)
    * @param dateOfIncorporation Date of company registration (in the format provided by the jurisdiction)
    * @param fee Fost of the company in wei ETH
    */ 
    struct CompanyInfo {
        uint256 jurisdiction;
        uint256 entityType;
        string ein;
        string dateOfIncorporation;
        uint256 fee;
    }

    function lockCompany(
        uint256 jurisdiction,
        uint256 entityType
    ) external returns (CompanyInfo memory);

    function createCompany(
        CompanyInfo calldata info
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRecordsRegistry {
    /**
     * @notice In the section of the Registry contract that contains records of the type of deployed user contract, the following numeric encoding of contract types is used.
     * @dev TGE is both a type of user contract and an event for which the contract was deployed.
     **/
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        PreferenceToken,
        TGE
    }
    /**
     * @notice Encoding of the registered event type
     */
    enum EventType {
        None,
        Transfer,
        TGE,
        GovernanceSettings
    }

    /**
     * @notice This structure is used for contracts storing in the CompanyDAO ecosystem.
     * @dev The Registry contract stores data about deployed user contracts in `ContractInfo[] public contractRecords`, where records receive a sequential and pool-independent numbering.
     * @param addr Deployed contract address
     * @param contractType Digital code of contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    /**
     * @notice Using this data, you can refer to the contract of a specific pool to get more detailed information about the proposal.
     * @dev The Registry contract stores data about proposals launched by users in `ProposalInfo[] public proposalRecords`, where records receive a sequential and pool-independent numbering.
     * @param pool Pool contract in which the proposal was launched
     * @param proposalId Internal proposal identifier for the pool
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    /**
     * @dev The Registry contract stores data about all events that have taken place in `Event[] public events`, where records receive a sequential and pool-independent numbering.
     * @param eventType Code of event type
     * @param pool Address of the pool to which this event relates
     * @param eventContract Address of the event contract, if the event type implies the deployment of a separate contract
     * @param proposalId Internal proposal identifier for the pool, the execution of which led to the launch of this event
     * @param metaHash Hash identifier of the private description stored on the backend
     */
    struct Event {
        EventType eventType;
        address pool;
        address eventContract;
        uint256 proposalId;
        string metaHash;
    }

    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external returns (uint256 index);

    function addProposalRecord(
        address pool,
        uint256 proposalId
    ) external returns (uint256 index);

    function addEventRecord(
        address pool,
        EventType eventType,
        address eventContract,
        uint256 proposalId,
        string calldata metaHash
    ) external returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICompaniesRegistry.sol";
import "./ITokensRegistry.sol";
import "./IRecordsRegistry.sol";
import "../IService.sol";

interface IRegistry is ITokensRegistry, ICompaniesRegistry, IRecordsRegistry {
    function service() external view returns (IService);

    function COMPANIES_MANAGER_ROLE() external view returns (bytes32);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function log(
        address sender,
        address receiver,
        uint256 value, 
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokensRegistry {
    function isTokenWhitelisted(address token) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ExceptionsLibrary {
    string public constant ADDRESS_ZERO = "ADDRESS_ZERO";
    string public constant INCORRECT_ETH_PASSED = "INCORRECT_ETH_PASSED";
    string public constant NO_COMPANY = "NO_COMPANY";
    string public constant INVALID_TOKEN = "INVALID_TOKEN";
    string public constant NOT_POOL = "NOT_POOL";
    string public constant NOT_TGE = "NOT_TGE";
    string public constant NOT_Registry = "NOT_Registry";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant NOT_SERVICE = "NOT_SERVICE";
    string public constant WRONG_STATE = "WRONG_STATE";
    string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string public constant CLAIM_NOT_AVAILABLE = "CLAIM_NOT_AVAILABLE";
    string public constant NO_LOCKED_BALANCE = "NO_LOCKED_BALANCE";
    string public constant LOCKUP_TVL_REACHED = "LOCKUP_TVL_REACHED";
    string public constant HARDCAP_OVERFLOW = "HARDCAP_OVERFLOW";
    string public constant MAX_PURCHASE_OVERFLOW = "MAX_PURCHASE_OVERFLOW";
    string public constant HARDCAP_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_OVERFLOW_REMAINING_SUPPLY";
    string public constant HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY";
    string public constant MIN_PURCHASE_UNDERFLOW = "MIN_PURCHASE_UNDERFLOW";
    string public constant LOW_UNLOCKED_BALANCE = "LOW_UNLOCKED_BALANCE";
    string public constant ZERO_PURCHASE_AMOUNT = "ZERO_PURCHASE_AMOUNTs";
    string public constant NOTHING_TO_REDEEM = "NOTHING_TO_REDEEM";
    string public constant RECORD_IN_USE = "RECORD_IN_USE";
    string public constant INVALID_EIN = "INVALID_EIN";
    string public constant VALUE_ZERO = "VALUE_ZERO";
    string public constant ALREADY_SET = "ALREADY_SET";
    string public constant VOTING_FINISHED = "VOTING_FINISHED";
    string public constant ALREADY_EXECUTED = "ALREADY_EXECUTED";
    string public constant ACTIVE_TGE_EXISTS = "ACTIVE_TGE_EXISTS";
    string public constant INVALID_VALUE = "INVALID_VALUE";
    string public constant INVALID_CAP = "INVALID_CAP";
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
    string public constant INVALID_USER = "INVALID_USER";
    string public constant NOT_LAUNCHED = "NOT_LAUNCHED";
    string public constant LAUNCHED = "LAUNCHED";
    string public constant VESTING_TVL_REACHED = "VESTING_TVL_REACHED";
    string public constant WRONG_TOKEN_ADDRESS = "WRONG_TOKEN_ADDRESS";
    string public constant GOVERNANCE_TOKEN_EXISTS = "GOVERNANCE_TOKEN_EXISTS";
    string public constant THRESHOLD_NOT_REACHED = "THRESHOLD_NOT_REACHED";
    string public constant UNSUPPORTED_TOKEN_TYPE = "UNSUPPORTED_TOKEN_TYPE";
    string public constant ALREADY_VOTED = "ALREADY_VOTED";
    string public constant ZERO_VOTES = "ZERO_VOTES";
    string public constant ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS =
        "ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS";
    string public constant EMPTY_ADDRESS = "EMPTY_ADDRESS";
    string public constant NOT_VALID_PROPOSER = "NOT_VALID_PROPOSER";
    string public constant SHARES_SUM_EXCEEDS_ONE = "SHARES_SUM_EXCEEDS_ONE";
    string public constant NOT_RESOLVER = "NOT_RESOLVER";
    string public constant NOT_REGISTRY = "NOT_REGISTRY";
    string public constant INVALID_TARGET = "INVALID_TARGET";
    string public constant NOT_TGE_FACTORY = "NOT_TGE_FACTORY";
    string public constant WRONG_AMOUNT = "WRONG_AMOUNT";
    string public constant WRONG_BLOCK_NUMBER = "WRONG_BLOCK_NUMBER";
    string public constant NOT_VALID_EXECUTOR = "NOT_VALID_EXECUTOR";
    string public constant POOL_PAUSED = "POOL_PAUSED";
    string public constant NOT_INVOICE_MANAGER = "NOT_INVOICE_MANAGER";
    string public constant WRONG_RESOLVER = "WRONG_RESOLVER";
    string public constant INVALID_PURCHASE_AMOUNT = "INVALID_PURCHASE_AMOUNT";
}