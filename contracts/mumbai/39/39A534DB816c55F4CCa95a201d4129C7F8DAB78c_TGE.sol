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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITokenERC1155.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IVesting.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/IPausable.sol";

/**
    * @title Token Generation Event Contract
    * @notice The Token Generation Event (TGE) is the cornerstone of everything related to tokens issued on the CompanyDAO protocol. TGE contracts contain the rules and deadlines for token distribution events and can influence the pool's operational activities even after they have ended.
    The launch of the TGE event takes place simultaneously with the deployment of the contract, after which the option to purchase tokens becomes immediately available. Tokens purchased by a user can be partially or fully minted to the buyer's address and can also be placed in the vesting reserve either in full or for the remaining portion. Additionally, tokens acquired during the TGE and held in the buyer's balance may have their transfer functionality locked (the user owns, uses them as votes, delegates, but cannot transfer the tokens to another address).
    * @dev TGE events differ by the type of tokens being distributed:
    - Governance Token Generation Event
    - Preference Token Generation Event
    When deploying the TGE contract, among other arguments, the callData field contains the token field, which contains the address of the token contract that will interact with the TGE contract. The token type can be determined from the TokenType state variable of the token contract.
    Differences between these types:
    - Governance Token Generation Event involves charging a ProtocolTokenFee in the amount set in the Service:protocolTokenFee value (percentages in DENOM notation). This fee is collected through the transferFunds() transaction after the completion of the Governance token distribution event (the funds collected from buyers go to the pool balance, and the protocolTokenFee is minted and sent to the Service:protocolTreasury).
    - Governance Token Generation Event has a mandatory minPurchase limit equal to the Service:protocolTokenFee (in the smallest indivisible token parts, taking into account Decimals and DENOM). This is done to avoid rounding conflicts or overcharges when calculating the fee for each issued token volume.
    - In addition to being launched as a result of a proposal execution, a Governance Token Generation Event can be launched by the pool Owner as long as the pool has not acquired DAO status. Preference Token Generation Event can only be launched as a result of a proposal execution.
    - A successful Governance Token Generation Event (see TGE states later) leads to the pool becoming a DAO if it didn't previously have that status.
    @dev **TGE events differ by the number of previous launches:**
    - primary TGE
    - secondary TGE
    As long as the sum of the totalSupply and the vesting reserve of the distributed token does not equal the cap, a TGE can be launched to issue some more of these tokens.
    The first TGE for the distribution of any token is called primary, and all subsequent ones are called secondary.
    Differences between these types:
    - A transaction to launch a primary TGE involves the simultaneous deployment of the token contract, while a secondary TGE only works with an existing token contract.
    - A secondary TGE does not have a softcap parameter, meaning that after at least one minPurchase of tokens, the TGE is considered successful.
    - When validating the hardcap (i.e., the maximum possible number of tokens available for sale/distribution within the TGE) during the creation of a primary TGE, only a formal check is performed (hardcap must not be less than softcap and not greater than cap). For a secondary TGE, tokens that will be minted during vesting claims are also taken into account.
    - In case of failure of a primary TGE for any token, that token is not considered to have any application within the protocol. It is no longer possible to conduct a TGE for such a token.
    */

contract TGE is Initializable, ReentrancyGuardUpgradeable, ITGE {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    /// @notice The address of the ERC20/ERC1155 token being distributed in this TGE
    /// @dev Mandatory setting for TGE, only one token can be distributed in a single TGE event
    address public token;

    /// @notice The identifier of the ERC1155 token collection
    /// @dev For ERC1155, there is an additional restriction that units of only one collection of such tokens can be distributed in a single TGE
    uint256 public tokenId;

    /// @dev Parameters for conducting the TGE, described by the ITGE.sol:TGEInfo interface
    TGEInfo public info;

    /**
    * @notice A whitelist of addresses allowed to participate in this TGE
    * @dev A TGE can be public or private. To make the event public, simply leave the whitelist empty.
    The TGE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TGE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    */
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev The block on which the TGE contract was deployed and the event begins
    uint256 public createdAt;

    /// @dev A mapping that stores the amount of token units purchased by each address that plays a key role in the TGE.
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during the TGE
    uint256 public totalPurchased;

    /// @notice Achievement of the pool's TVL as specified by the vesting settings
    /// @dev A flag that irreversibly becomes True only if the pool for which the TGE is being conducted is able to reach or exceed its TVL value specified in the vesting parameters.
    bool public vestingTVLReached;

    /// @notice Achievement of the pool's TVL as specified by the lockup settings
    /// @dev A flag that irreversibly becomes True only if the pool for which the TGE is being conducted is able to reach or exceed its TVL value specified in the lockup parameters.
    bool public lockupTVLReached;

    /** 
    * @notice A mapping that contains the amount of token units placed in vesting for a specific account
    * @dev The TGE event may continue to affect other components of the protocol even after its completion and status change to "Successful" and, less frequently, "Failed". Vesting can be set up to distribute tokens over a significant period of time after the end of the TGE.
    The vesting time calculation begins with the block ending the TGE. The calculation of uniform time intervals is carried out either from the end of the cliff period block or each subsequent interval is counted from the end of the previous block.
    The Vesting.unlockedBalanceOf method shows how much of the tokens for a particular TGE may be available for a claim by an address if that address has not requested a withdrawal of any amount of tokens. The Vesting.claimableBalanceOf method shows how many tokens in total within a particular TGE an address has already requested and successfully received for withdrawal. Subtracting the second value from the first using the same arguments for method calls will give you the number of tokens currently available for withdrawal by that address.
    Additionally, one of the conditions for unlocking tokens under the vesting program can be setting a cumulative pool balance of a specified amount. The compliance with this condition starts to be tracked by the backend, and as soon as the pool balance reaches or exceeds the specified amount even for a moment, the backend, on behalf of the wallet with the SERVICE_MANAGER role, sends a transaction to the vesting contract's setClaimTVLReached(address tge) method. Executing this transaction changes the value of the flag in the mapping mapping(address => bool) with a key equal to the TGE address. Raising this flag is irreversible, meaning that a one-time occurrence of the condition guarantees that the token request now depends only on the second part of the conditions related to the passage of time. The calculation of the cliff period and additional distribution intervals is not related to raising this flag, both conditions are independent of each other, not mandatory for simultaneous use in settings, but mandatory for simultaneous compliance if they were used in one set of settings.
    The vesting of one TGE does not affect the vesting of another TGE.
    */
    mapping(address => uint256) public vestedBalanceOf;

    /// @dev Total number of tokens to be distributed within the vesting period
    uint256 public totalVested;

    /// @notice Protocol fee at the time of TGE creation
    /// @dev Since the protocol fee can be changed, the actual value at the time of contract deployment is fixed in the contract's memory to avoid dependencies on future states of the Service contract.
    uint256 public protocolFee;

    /// @notice Protocol fee payment
    /// @dev A flag that irreversibly becomes True after a successful transfer of the protocol fee to the address specified in the Service contract.
    /// @dev Used only for Governance Token Generation Event.
    bool public isProtocolTokenFeeClaimed;

    /// @dev Total number of token units that make up the protocol fee
    uint256 public totalProtocolFee;

    /** 
    * @notice Vesting contract address
    * @dev The TGE contract works closely with the Vesting contract, with a separate instance being issued for each token generation event, while there is only one Vesting contract. Together, they contain the most comprehensive information about a user's purchases, tokens in reserve but not yet issued, and the conditions for locking and unlocking tokens. Moreover, the TGE contract has a token buyback function under specific conditions (see the "Redeem" section for more details).
    One TGE contract is used for the distribution of only one protocol token (the token contract address is specified when launching the TGE). At any given time, there can be only one active TGE for a single token.
    */
    IVesting public vesting;

    // EVENTS

    /**
     * @dev Event emitted upon successful purchase (or distribution if the token unit price is 0)
     * @param buyer Address of the token recipient (buyer)
     * @param amount Number of token units acquired
     */
    event Purchased(address buyer, uint256 amount);

    /**
     * @dev Event emitted after successful claiming of the protocol fee
     * @param token Address of the token contract
     * @param tokenFee Amount of tokens transferred as payment for the protocol fee
     */
    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    /**
     * @dev Event emitted upon redeeming tokens in case of a failed TGE.
     * @param account Redeemer address
     * @param refundValue Refund value
     */
    event Redeemed(address account, uint256 refundValue);

    /**
     * @dev Event emitted upon transferring the raised funds to the pool contract address.
     * @param amount Amount of tokens/ETH transferred
     */
    event FundsTransferred(uint256 amount);

    event Refund(address account, uint256 amount);

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
     * @dev Constructor function, can only be called once. In this method, settings for the TGE event are assigned, such as the contract of the token implemented using TGE, as well as the TGEInfo structure, which includes the parameters of purchase, vesting, and lockup. If no lockup or vesting conditions were set for the TVL value when creating the TGE, then the TVL achievement flag is set to true from the very beginning.
     * @param _service Service contract
     * @param _token TGE's token
     * @param _tokenId TGE's tokenId
     * @param _tokenId ERC1155TGE's tokenId (token series)
     * @param _uri Metadata URL for the ERC1155 token collection
     * @param _info TGE parameters
     * @param _protocolFee Protocol fee snapshot
     */
    function initialize(
        address _service,
        address _token,
        uint256 _tokenId,
        string memory _uri,
        TGEInfo calldata _info,
        uint256 _protocolFee
    ) external initializer {
        __ReentrancyGuard_init();

        //if tge is creating for erc20 token
        tokenId = _tokenId;
        if (tokenId == 0) {
            IService(_service).validateTGEInfo(
                _info,
                IToken(_token).cap(),
                IToken(_token).totalSupplyWithReserves(),
                IToken(_token).tokenType()
            );
        } else {
            //if tge is creating for erc155 token
            if (ITokenERC1155(_token).cap(tokenId) != 0) {
                IService(_service).validateTGEInfo(
                    _info,
                    ITokenERC1155(_token).cap(tokenId),
                    ITokenERC1155(_token).totalSupplyWithReserves(tokenId),
                    IToken(_token).tokenType()
                );
            } else {
                ITokenERC1155(_token).setLastTokenId(_tokenId);
                ITokenERC1155(_token).setURI(_tokenId, _uri);
            }
        }
        vesting = IService(_service).vesting();
        token = _token;

        info = _info;
        protocolFee = _protocolFee;
        lockupTVLReached = (_info.lockupTVL == 0);

        for (uint256 i = 0; i < _info.userWhitelist.length; i++) {
            _isUserWhitelisted[_info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    /**
    * @notice This method is used for purchasing pool tokens.
    * @dev Any blockchain address can act as a buyer (TGE contract user) of tokens if the following conditions are met:
    - active event status (TGE.sol:state method returns the Active code value / "1")
    - the event is public (TGE.sol:info.Whitelist is empty) or the user's address is on the whitelist of addresses admitted to the event
    - the number of tokens purchased by the address is not less than TGE.sol:minPurchase (a common rule for all participants) and not more than TGE.sol:maxPurchaseOf(address) (calculated individually for each address)
    The TGEInfo of each such event also contains settings for the order in which token buyers receive their purchases and from when and to what extent they can start managing them.
    However, in any case, each address that made a purchase is mentioned in the TGE.sol:purchaseOf[] mapping. This record serves as proof of full payment for the purchase and confirmation of the buyer's status, even if as a result of the transaction, not a single token was credited to the buyer's address.
    After each purchase transaction, TGE.sol:purchase calculates what part of the purchase should be issued and immediately transferred to the buyer's balance, and what part should be left as a reserve (records, not issued tokens) in vesting until the prescribed settings for unlocking these tokens occur.
     */
    function purchase(
        uint256 amount
    )
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                purchasePrice
            );
        }
        this.proceedPurchase(msg.sender, amount);
    }

    /**
     * @notice Executes a token purchase for a given account using fiat during the token generation event (TGE).
     * @dev The function can only be called by an executor, when the contract state is active, the pool is not paused, and ensures no reentrancy.
     * @param account The address of the account to execute the purchase for.
     * @param amount The amount of tokens to be purchased.
     */

    function externalPurchase(
        address account,
        uint256 amount
    )
        external
        onlyExecutor
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        try this.proceedPurchase(account, amount) {
            return;
        } catch {
            _refund(account, amount);
            return;
        }
    }

    function _refund(address account, uint256 amount) private {
        uint256 refundValue = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }
        emit Refund(account, amount);
    }

    /**
    * @notice Redeem acquired tokens with a refund of the spent assets.
    * @dev In the contract of an unsuccessful TGE, the redeem() method becomes active, allowing any token buyer to return them to the contract for subsequent burning. As a result of this transaction, the records of the user's purchases within this TGE will be zeroed out (or reduced), and the spent ETH or ERC20 tokens will be returned to their balance.
    If the buyer has a record of tokens locked under the vesting program for this TGE, they will not be burned, and the record of the vesting payment will simply be deleted. In this case, the transaction will also end with a transfer of the spent funds back to the buyer.
    The buyer cannot return more tokens than they purchased in this TGE; this contract keeps a record of the user's total purchase amount and reduces it with each call of the redeem token method. This can happen if the purchased tokens were distributed to other wallets, and after the end of the TGE, the buyer requests redemption after each transfer back to the purchase address.
     */
    function redeem()
        external
        onlyState(State.Failed)
        nonReentrant
        whenPoolNotPaused
    {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        require(
            purchaseOf[msg.sender] > 0,
            ExceptionsLibrary.ZERO_PURCHASE_AMOUNT
        );

        uint256 refundAmount = 0;

        // Calculate redeem from vesting
        uint256 vestedBalance = vesting.vested(address(this), msg.sender);
        if (vestedBalance > 0) {
            // Account vested tokens
            purchaseOf[msg.sender] -= vestedBalance;
            refundAmount += vestedBalance;

            // Cancel vesting
            vesting.cancel(address(this), msg.sender);

            // Decrease reserved tokens
            if (isERC1155TGE()) {
                ITokenERC1155(token).setTGEVestedTokens(
                    ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) -
                        vestedBalance,
                    tokenId
                );
            } else {
                IToken(token).setTGEVestedTokens(
                    IToken(token).getTotalTGEVestedTokens() - vestedBalance
                );
            }
        }

        // Calculate redeemed balance
        uint256 balanceToRedeem;
        if (isERC1155TGE()) {
            balanceToRedeem = MathUpgradeable.min(
                ITokenERC1155(token).balanceOf(msg.sender, tokenId),
                purchaseOf[msg.sender]
            );
        } else {
            balanceToRedeem = MathUpgradeable.min(
                IToken(token).balanceOf(msg.sender),
                purchaseOf[msg.sender]
            );
        }
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            if (isERC1155TGE()) {
                ITokenERC1155(token).burn(msg.sender, tokenId, balanceToRedeem);
            } else {
                IToken(token).burn(msg.sender, balanceToRedeem);
            }
        }

        // Check that there is anything to refund
        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);

        // Transfer refund value
        uint256 refundValue = (refundAmount * info.price + (1 ether - 1)) /
            1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }

        // Decrease reserved protocol fee
        uint256 tokenFee = getProtocolTokenFee(refundAmount);
        if (tokenFee > 0) {
            totalProtocolFee -= tokenFee;
            if (isERC1155TGE()) {
                ITokenERC1155(token).setProtocolFeeReserved(
                    ITokenERC1155(token).getTotalProtocolFeeReserved(tokenId) -
                        tokenFee,
                    tokenId
                );
            } else {
                IToken(token).setProtocolFeeReserved(
                    IToken(token).getTotalProtocolFeeReserved() - tokenFee
                );
            }
        }

        // Emit event
        emit Redeemed(msg.sender, refundValue);
    }

    /// @dev Set the flag that the condition for achieving the pool balance of the value specified in the lockup settings is met. The action is irreversible.
    function setLockupTVLReached()
        external
        whenPoolNotPaused
        onlyManager
        onlyState(State.Successful)
    {
        // Check that TVL has not been reached yet
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);

        // Mark as reached
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev This method is used to perform the following actions for a successful TGE after its completion: transfer funds collected from buyers in the form of info.unitofaccount tokens or ETH to the address of the pool to which TGE belongs (if info.price is 0, then this action is not performed), as well as for Governance tokens make a minting of the percentage of the amount of all user purchases specified in the Service.sol protocolTokenFee contract and transfer it to the address specified in the Service.sol contract in the protocolTreasury() getter. Can be executed only once. Any address can call the method.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenPoolNotPaused
    {
        // Return if nothing to transfer
        if (totalPurchased == 0) {
            return;
        }

        // Claim protocol fee
        _claimProtocolTokenFee();

        // Transfer remaining funds to pool
        address unitOfAccount = info.unitOfAccount;

        address pool = IToken(token).pool();

        uint256 balance = 0;
        if (info.price != 0) {
            if (unitOfAccount == address(0)) {
                balance = address(this).balance;
                payable(pool).sendValue(balance);
            } else {
                balance = IERC20Upgradeable(unitOfAccount).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(unitOfAccount).safeTransfer(pool, balance);
            }
        }

        // Emit event
        emit FundsTransferred(balance);

        IToken(token).service().registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(ITGE.transferFunds.selector)
        );
    }

    /**
     * @notice This method is used to transfer funds raised during the TGE to the address of the pool contract that conducted the TGE.
     * @dev The method can be called by any address. For safe execution, this method does not take any call arguments and only triggers for successful TGEs.
     */
    function _claimProtocolTokenFee() private {
        // Return if already claimed
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        // Return for preference token
        if (IToken(token).tokenType() == IToken.TokenType.Preference) {
            return;
        }

        // Mark fee as claimed
        isProtocolTokenFeeClaimed = true;

        // Mint fee to treasury
        uint256 tokenFee = totalProtocolFee;
        if (totalProtocolFee > 0) {
            totalProtocolFee = 0;
            if (isERC1155TGE()) {
                ITokenERC1155(token).mint(
                    ITokenERC1155(token).service().protocolTreasury(),
                    tokenId,
                    tokenFee
                );
                ITokenERC1155(token).setProtocolFeeReserved(
                    ITokenERC1155(token).getTotalProtocolFeeReserved(tokenId) -
                        tokenFee,
                    tokenId
                );
            } else {
                IToken(token).mint(
                    IToken(token).service().protocolTreasury(),
                    tokenFee
                );
                IToken(token).setProtocolFeeReserved(
                    IToken(token).getTotalProtocolFeeReserved() - tokenFee
                );
            }
        }

        // Emit event
        emit ProtocolTokenFeeClaimed(token, tokenFee);
    }

    // VIEW FUNCTIONS

    /**
     * @dev Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TGE.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.hardcap - totalPurchased
            );
    }

    /**
    * @notice A state of a Token Generation Event
    * @dev A TGE event can be in one of the following states:
    - Active
    - Failed
    - Successful
    In TGEInfo, the three most important parameters used to determine the event's state are specified:
    - hardcap - the maximum number of tokens that can be distributed during the event (the value is stored considering the token's Decimals)
    - softcap - the minimum expected number of tokens that should be distributed during the event (the value is stored considering the token's Decimals)
    - duration - the duration of the event (the number of blocks since the TGE deployment transaction)
    A successful outcome of the event and the assignment of the "Successful" status to the TGE occurs if:
    - no fewer than duration blocks have passed since the TGE launch, and no fewer than softcap tokens have been acquired
    OR
    - 100% of the hardcap tokens have been acquired at any point during the event
    If no fewer than duration blocks have passed since the TGE launch and fewer than softcap tokens have been acquired, the event is considered "Failed".
    If fewer than 100% of the hardcap tokens have been acquired, but fewer than duration blocks have passed since the TGE launch, the event is considered "Active".
     * @return State code
     */
    function state() public view returns (State) {
        // If hardcap is reached TGE is successfull
        if (totalPurchased == info.hardcap) {
            return State.Successful;
        }

        // If deadline not reached TGE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If it's not primary TGE it's successfull (if anything is purchased)
        if (isERC1155TGE()) {
            if (
                address(this) != ITokenERC1155(token).getTGEList(tokenId)[0] &&
                totalPurchased > 0
            ) {
                return State.Successful;
            }
        } else {
            if (
                address(this) != IToken(token).getTGEList()[0] &&
                totalPurchased > 0
            ) {
                return State.Successful;
            }
        }

        // If softcap is reached TGE is successfull
        if (totalPurchased >= info.softcap && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TGE
        return State.Failed;
    }

    /**
     * @notice The given getter shows whether the transfer method is available for tokens that were distributed using a specific TGE contract. If the lockup period is over or if the lockup was not provided for this TGE, the getter always returns true.
     * @dev In contrast to vesting, lockup contains a simplified system of conditions (no additional distribution spread over equal time intervals), affects tokens located in the contract address, and does not involve actions related to minting or burning tokens.
    To configure lockup in TGEInfo, only two settings are specified: "lockupDuration" and "lockupTVL" (pool balance). The lockup duration is counted from the TGE creation block.
    Lockup locks the transfer of tokens purchased during the TGE for a period equal to the lockupDuration blocks and does not allow unlocking until the pool balance reaches lockupTVL. The address can use these tokens for Governance activities; they are on the balance and counted as votes.
    Unlocking by TVL occurs with a transaction similar to vesting. The SERVICE_MANAGER address can send a setLockupTVLReached() transaction to the TGE contract, which irreversibly changes the value of this condition flag to "true".
    Vesting and lockup are completely parallel entities. Tokens can be unlocked under the lockup program but remain in vesting. The lockup of one TGE does not affect the lockup of another TGE.
     * @return bool Is transfer available
     */
    function transferUnlocked() public view returns (bool) {
        return
            lockupTVLReached && block.number >= createdAt + info.lockupDuration;
    }

    /**
     * @dev Shows the number of TGE tokens blocked in this contract. If the lockup is completed or has not been assigned, the method returns 0 (all tokens on the address balance are available for transfer). If the lockup period is still active, then the difference between the tokens purchased by the user and those in the vesting is shown (both parameters are only for this TGE).
     * @param account Account address
     * @return Locked balance
     */
    function lockedBalanceOf(address account) external view returns (uint256) {
        return
            transferUnlocked()
                ? 0
                : (purchaseOf[account] -
                    vesting.vestedBalanceOf(address(this), account));
    }

    /**
     * @dev Shows the number of TGE tokens available for redeem for `account`
     * @param account Account address
     * @return Redeemable balance of the address
     */
    function redeemableBalanceOf(
        address account
    ) external view returns (uint256) {
        if (purchaseOf[account] == 0) return 0;
        if (state() != State.Failed) return 0;

        if (isERC1155TGE()) {
            return
                MathUpgradeable.min(
                    ITokenERC1155(token).balanceOf(account, tokenId) +
                        vesting.vestedBalanceOf(address(this), account),
                    purchaseOf[account]
                );
        } else {
            return
                MathUpgradeable.min(
                    IToken(token).balanceOf(account) +
                        vesting.vestedBalanceOf(address(this), account),
                    purchaseOf[account]
                );
        }
    }

    /**
     * @dev The given getter shows how much info.unitofaccount was collected within this TGE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price.
     * @return uint256 Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10 ** 18;
    }

    /**
     * @dev This getter shows the total value of all tokens that are in the vesting. Tokens that were transferred to user’s wallet addresses upon request for successful TGEs and that were burned as a result of user funds refund for unsuccessful TGEs are not taken into account.
     * @return uint256 Total value
     */
    function getTotalVestedValue() public view returns (uint256) {
        return (vesting.totalVested(address(this)) * info.price) / 10 ** 18;
    }

    /**
     * @dev This method returns the full list of addresses allowed to participate in the TGE.
     * @return address An array of whitelist addresses
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted.
     * @param account User address
     * @return 'True' if the whitelist is empty (public TGE) or if the address is found in the whitelist, 'False' otherwise.
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    /**
     * @dev This method indicates whether this event was launched to implement ERC1155 tokens.
     * @return bool Flag if ERC1155 TGE
     */
    function isERC1155TGE() public view returns (bool) {
        return tokenId == 0 ? false : true;
    }

    /**
     * @dev Returns the block number at which the event ends.
     * @return uint256 Block number
     */
    function getEnd() external view returns (uint256) {
        return createdAt + info.duration;
    }

    /**
    * @notice This method returns the immutable settings with which the TGE was launched.
    * @dev The rules for conducting an event are defined in the TGEInfo structure, which is passed within the calldata when calling one of the TGEFactory contract functions responsible for launching the TGE. For more information about the structure, see the "Interfaces" section. The variables mentioned below should be understood as attributes of the TGEInfo structure.
    A TGE can be public or private. To make the event public, simply leave the whitelist empty.
    The TGE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TGE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    * @return The settings in the form of a TGEInfo structure
    */
    function getInfo() external view returns (TGEInfo memory) {
        return info;
    }

    /**
     * @dev This method returns the number of tokens that are currently due as protocol fees during the TGE.
     * @return The number of tokens
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        if (IToken(token).tokenType() == IToken.TokenType.Preference) {
            return 0;
        }
        return (amount * protocolFee + (DENOM - 1)) / DENOM;
    }

    /// @notice Determine if a purchase is valid for a specific account and amount.
    /// @dev Returns true if the amount is within the permitted purchase range for the account.
    /// @param account The address of the account to validate the purchase for.
    /// @param amount The amount of the purchase to validate.
    /// @return A boolean value indicating if the purchase is valid.
    function validatePurchase(
        address account,
        uint256 amount
    ) public view returns (bool) {
        return amount >= info.minPurchase && amount <= maxPurchaseOf(account);
    }

    //PRIVATE FUNCTIONS

    function proceedPurchase(address account, uint256 amount) public {
        require(msg.sender == address(this), ExceptionsLibrary.INVALID_USER);

        require(
            validatePurchase(account, amount),
            ExceptionsLibrary.INVALID_PURCHASE_AMOUNT
        );

        // Accrue TGE stats
        totalPurchased += amount;
        purchaseOf[account] += amount;

        // Mint tokens directly to user
        uint256 vestedAmount = (amount *
            info.vestingParams.vestedShare +
            (DENOM - 1)) / DENOM;

        if (amount - vestedAmount > 0) {
            if (isERC1155TGE()) {
                ITokenERC1155(token).mint(
                    account,
                    tokenId,
                    amount - vestedAmount
                );
            } else {
                IToken(token).mint(account, amount - vestedAmount);
            }
        }

        // Vest tokens
        if (vestedAmount > 0) {
            if (isERC1155TGE()) {
                ITokenERC1155(token).setTGEVestedTokens(
                    ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) +
                        vestedAmount,
                    tokenId
                );
            } else {
                IToken(token).setTGEVestedTokens(
                    IToken(token).getTotalTGEVestedTokens() + vestedAmount
                );
            }

            vesting.vest(account, vestedAmount);
        }

        // Increase reserved protocol fee
        uint256 tokenFee = getProtocolTokenFee(amount);
        if (tokenFee > 0) {
            totalProtocolFee += tokenFee;
            if (isERC1155TGE()) {
                ITokenERC1155(token).setProtocolFeeReserved(
                    ITokenERC1155(token).getTotalProtocolFeeReserved(tokenId) +
                        tokenFee,
                    tokenId
                );
            } else {
                IToken(token).setProtocolFeeReserved(
                    IToken(token).getTotalProtocolFeeReserved() + tokenFee
                );
            }
        }

        // Emit event
        emit Purchased(account, amount);

        IToken(token).service().registry().log(
            account,
            address(this),
            0,
            abi.encodeWithSelector(ITGE.purchase.selector, amount)
        );
    }

    // MODIFIER

    /// @notice Modifier that allows the method to be called only if the TGE state is equal to the specified state.
    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that is whitelisted for the TGE or if the TGE is created as public.
    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.
    modifier onlyManager() {
        IService service = IToken(token).service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only if the pool associated with the event is not in a paused state.
    modifier whenPoolNotPaused() {
        require(
            !IPausable(IToken(token).pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }

    modifier onlyExecutor() {
        IService service = IToken(token).service();
        require(
            service.hasRole(service.EXECUTOR_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
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

interface IPausable {
    function paused() external view returns (bool);
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