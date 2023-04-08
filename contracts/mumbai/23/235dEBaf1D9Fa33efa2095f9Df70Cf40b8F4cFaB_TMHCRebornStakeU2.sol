// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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
interface IERC20Permit {
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

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPermissions.sol";
import "../lib/TWStrings.sol";

/**
 *  @title   Permissions
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms
 */
contract Permissions is IPermissions {
    /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
    mapping(bytes32 => mapping(address => bool)) private _hasRole;

    /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
    mapping(bytes32 => bytes32) private _getRoleAdmin;

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     *  @notice         Checks whether an account has a particular role.
     *  @dev            Returns `true` if `account` has been granted `role`.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _hasRole[role][account];
    }

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(bytes32 role, address account) public view returns (bool) {
        if (!_hasRole[role][address(0)]) {
            return _hasRole[role][account];
        }

        return true;
    }

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view override returns (bytes32) {
        return _getRoleAdmin[role];
    }

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account to which the role is being granted.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);
        if (_hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);
        _revokeRole(role, account);
    }

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        if (msg.sender != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin[role];
        _getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        _hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        _checkRole(role, account);
        delete _hasRole[role][account];
        emit RoleRevoked(role, account, msg.sender);
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPermissionsEnumerable.sol";
import "./Permissions.sol";

/**
 *  @title   PermissionsEnumerable
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms.
 *           Also provides interfaces to view all members with a given role, and total count of members.
 */
contract PermissionsEnumerable is IPermissionsEnumerable, Permissions {
    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
    mapping(bytes32 => RoleMembers) private roleMembers;

    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        uint256 currentIndex = roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (hasRole(role, address(0)) && i == roleMembers[role].indexOf[address(0)]) {
                check += 1;
            }
        }
    }

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        uint256 currentIndex = roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].index;
        roleMembers[role].index += 1;

        roleMembers[role].members[idx] = account;
        roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].indexOf[account];

        delete roleMembers[role].members[idx];
        delete roleMembers[role].indexOf[account];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IPermissions {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./IPermissions.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IPermissionsEnumerable is IPermissions {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * [forum post](https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296)
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev String operations.
 */
library TWStrings {
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

import "./module/NTS-Multi.sol";
import "./module/RewardVault.sol";


contract TMHCRebornStakeU2 is PermissionsEnumerable, Initializable, ReentrancyGuard, NTStakeMulti{
    // TMHC Reborn Stake Upgradeable Contract Release version 0.2
    // Staking pool onwer / admin
    address private owner;
    // Operation status of the Pool.
    bool public PauseStake;
    // Claim operation status of the Pool.
    bool public PauseClaim;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/ 

    constructor(IERC1155 _EditionToken, IERC721 _NFTtoken, NTSRewardVault _RewardVault, NTSUserManager _userStorage, NTSGradeStorage _gradeStorage, uint256 _rewardPerHour, uint256 _rewardPerHourSub, address _owner) initializer {
        owner = _owner;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        tmhcToken = _EditionToken;
        momoToken = _NFTtoken;
        rewardVault = _RewardVault;
        userStorage = _userStorage;
        gradeStorage = _gradeStorage;
        rewardPerHour = _rewardPerHour;
        rewardPerHourSub = _rewardPerHourSub;
        PauseStake = false;
        PauseClaim = false;
    }

    /*///////////////////////////////////////////////////////////////
                            Basic Staking Info
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Returns an array of token IDs representing all the TMHC tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked TMHC tokens.
    */
    function getStakedTMHC(address player) public view returns(uint16[] memory stakedIds){
        return userStorage.getStakedUserTmhc(player);
    }

    /**
    * @dev Returns an array of token IDs representing all the MOMO tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked MOMO tokens.
    */
    function getStakedMOMO(address player) public view returns(uint16[] memory stakedIds){
        return userStorage.getStakedUserMomo(player);
    }

    /**
    * @dev Returns an array of token IDs representing all the team tokens staked by the caller.
    * @return stakedIds An array of token IDs representing all the staked team tokens.
    */
    function getStakedTeam(address player) public view returns(uint16[] memory stakedIds){
        return userStorage.getStakedUserTeam(player);
    }

    /**
    * @dev Returns an array of boost IDs representing all the boosts for the specified team staked by the caller.
    * @param _staketeam The team ID whose boost IDs are being returned.
    * @return _TeamBoostRate An Staked team boost rate.
    */
    function getBoostsRate(address player, uint16 _staketeam) public view returns(uint256 _TeamBoostRate){
        return _getTeamBoostRate(player, _staketeam);
        
    }

    function getBoostIds(uint16 _staketeam) public view returns(uint16[] memory boostIds){
        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        return _inStakedteam.boostIds;
    }

    /*///////////////////////////////////////////////////////////////
                        Single Stake Interface
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Stakes the specified tokens of the given token type for the caller.
    * @param _tokenType The type of the tokens to be staked (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to be staked.
    */
    function stake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        require(!PauseStake, "Stacking pool is currently paused.");
        _stake(msg.sender, _tokenType, _tokenIds);
    }

    /**
    * @dev Claims the reward for the specified token of the given token type for the caller.
    * @param _tokenType The type of the token for which the reward is claimed (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the token for which the reward is claimed.
    */
    function claim(uint _tokenType, uint16 _tokenId) external nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claim(msg.sender, _tokenType, _tokenId);
    }

    function claimBatch(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimBatch(msg.sender, _tokenType, _tokenIds);
    }

    /**
    * @dev Claims the rewards for all staked tokens of the caller.
    */
    function claimAll() external nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimAll(msg.sender);
    }

    /**
    * @dev Unstakes the specified tokens of the given token type for the caller.
    * @param _tokenType The type of the tokens to be unstaked (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to be unstaked.
    */
    function unStake(uint _tokenType, uint16[] calldata _tokenIds) external nonReentrant {
        require(!PauseStake, "Stacking pool is currently paused.");
        _unStake(msg.sender, _tokenType, _tokenIds);
    }

    /**
    * @dev Calculates the reward for the specified token of the given token type for the caller.
    * @param _tokenType The type of the token for which the reward is to be calculated (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the token for which the reward is to be calculated.
    * @return _Reward The amount of reward for the specified token.
    */
    function calReward(address player, uint _tokenType, uint16 _tokenId) external view returns(uint256 _Reward){
        return _calReward(player, _tokenType, _tokenId);
    }

    /**
    * @dev Calculates the total reward for all staked tokens of the caller.
    * @return _totalReward The total reward amount for all staked tokens of the caller.
    */
    function calRewardAll(address player) external view returns(uint256 _totalReward){
        return _calRewardAll(player);
    }

    /*///////////////////////////////////////////////////////////////
                         Multi Stake Interface
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Stakes the specified team leader and boosts for the caller.
    * @param _leaderId The ID of the team leader to be staked.
    * @param _boostIds An array of IDs of the boosts to be staked.
    */
    function stakeTeam(uint16 _leaderId ,uint16[] calldata _boostIds) external nonReentrant{
        require(!PauseStake, "Stacking pool is currently paused.");
        _stakeTeam(msg.sender, _leaderId, _boostIds);
    }

    /**
    * @dev Claims the reward for the specified team leader and all the boosts for the caller.
    * @param _leaderId The ID of the team leader for which the rewards are claimed.
    */
    function claimTeam(uint16 _leaderId) external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeam(msg.sender, _leaderId);
    }

    function claimTeamBatch(uint16[] calldata _leaderIds) external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamBatch(msg.sender, _leaderIds);
    }

    /**
    * @dev Claims the rewards for all staked team leaders and their boosts for the caller.
    */
    function claimTeamAll() external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamAll(msg.sender);
    }

    /**
    * @dev Unstakes the specified team leaders and boosts for the caller.
    * @param _leaderIds An array of IDs of the team leaders to be unstaked.
    */
    function unStakeTeam(uint16[] calldata _leaderIds) external nonReentrant{
        require(!PauseStake, "Stacking pool is currently paused.");
        _unStakeTeam(msg.sender, _leaderIds);
    }

    function refreshTeamAll() external nonReentrant{
        _refreshAllTeam(msg.sender);
    }

    /**
    * @dev Calculates the total reward for the specified staked team.
    * @param _staketeam The ID of the team for which the reward is to be calculated.
    * @return _TotalReward The total reward amount for the specified staked team.
    */
    function calRewardTeam(address player, uint16 _staketeam) external view returns(uint256 _TotalReward){
        return _calRewardTeam(player, _staketeam);
    }

    /**
    * @dev Calculates the total reward for all staked teams of the caller.
    * @return _TotalReward The total reward amount for all staked teams of the caller.
    */
    function calRewardTeamAll(address player) external view returns (uint256 _TotalReward){
        return _calRewardTeamAll(player);
    }

    /**
    * @dev Calculates the boost rate for the specified staked team.
    * @param _staketeam The ID of the team for which the boost rate is to be calculated.
    * @return _boostrate The boost rate for the specified staked team.
    */
    function calTeamBoost(address player, uint16 _staketeam) external view returns(uint256 _boostrate){
        return _getTeamBoostRate(player, _staketeam);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/


    /**
    * @dev Sets the reward amount per hour for the stake.
    * @param _rewardPerHour The reward amount per hour.
    */
    function setRewardPeHour(uint256 _rewardPerHour) external onlyRole(DEFAULT_ADMIN_ROLE){
        rewardPerHour = _rewardPerHour;
    }

    function setRewardPeHourSub(uint256 _rewardPerHourSub) external onlyRole(DEFAULT_ADMIN_ROLE){
        rewardPerHourSub = _rewardPerHourSub;
    }

    /**
    * @dev Pauses the staking pool.
    * @param _status The status of the pause.
    */
    function setPausePool(bool _status) external onlyRole(DEFAULT_ADMIN_ROLE){
        PauseStake = _status;
    }

    /**
    * @dev Pauses the claim of rewards.
    * @param _status The status of the pause.
    */
    function setPauseCalim(bool _status) external onlyRole(DEFAULT_ADMIN_ROLE){
        PauseClaim = _status;
    }

    /**
    * @dev Allow the admin to claim the user's staking reward for a specific token.
    * @param _player The user address to claim the reward for.
    * @param _tokenType The type of token to claim reward for.
    * @param _tokenId The token id to claim reward for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaim(address _player, uint _tokenType, uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claim(_player, _tokenType, _tokenId);
    }

    function adminClaimBatch(address _player, uint _tokenType, uint16[] calldata _tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimBatch(_player, _tokenType, _tokenIds);
    }

    /**
    * @dev Allow the admin to claim all the user's staking rewards.
    * @param _player The user address to claim the rewards for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaimAll(address _player) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(!PauseClaim, "The claim is currently paused.");
        _claimAll(_player);
    }

    /**
    * @dev Allow the admin to claim the team's staking reward for a specific leader.
    * @param _player The user address to claim the reward for.
    * @param _leaderId The leader id to claim reward for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaimTeam(address _player, uint16 _leaderId) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeam(_player, _leaderId);
    }

    function adminClaimTeamBatch(address _player, uint16[] calldata _leaderIds) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamBatch(_player, _leaderIds);
    }

    /**
    * @dev Allow the admin to claim all the team's staking rewards.
    * @param _player The user address to claim the rewards for.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - Claim must not be paused.
    */
    function adminClaimTeamAll(address _player) external nonReentrant{
        require(!PauseClaim, "The claim is currently paused.");
        _claimTeamAll(_player);
    }


    /*///////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Returns an array of all users who have interacted with the contract.
    * @return _usersArray An array of addresses representing all the users who have interacted with the contract.
    */
    function getUsersArray() public view returns(address[] memory _usersArray){
        _usersArray = userStorage.getUsersArray();
    }

    /**
    * @dev Returns the count of all users who have interacted with the contract.
    * @return _userCount The count of all users who have interacted with the contract.
    */
    function getUserCount() public view returns(uint256 _userCount){
        address[] memory _usersArray = userStorage.getUsersArray();
        return _usersArray.length;
    }

    /**
    * @dev Returns the amount of claimed NTS tokens for the single staking pool.
    * @return _singleClaimed The amount of claimed NTS tokens for the single staking pool.
    */
    function getSingleClaimed() public view returns(uint256 _singleClaimed){
        return _getSingleClaimed();
    }

    /**
    * @dev Returns the amount of unclaimed NTS tokens for the single staking pool.
    * @return _singleUnClaim The amount of unclaimed NTS tokens for the single staking pool.
    */
    function getSingleUnClaim() public view returns(uint256 _singleUnClaim){
        return _getSingleUnClaim();
    }

    /**
    * @dev Returns the amount of claimed NTS tokens for the team staking pool.
    * @return _teamClaimed The amount of claimed NTS tokens for the team staking pool.
    */
    function getTeamClaimed() public view returns(uint256 _teamClaimed){
        return _getTeamClaimed();
    }

    /**
    * @dev Returns the amount of unclaimed NTS tokens for the team staking pool.
    * @return _teamUnClaim The amount of unclaimed NTS tokens for the team staking pool.
    */
    function getTeamUnClaim() public view returns(uint256 _teamUnClaim){
        return _getTeamUnClaim();
    }
}

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTSGradeStorage is PermissionsEnumerable{
    uint8[] nftGrades;
    uint16[5] boostBonus = [10,30,100,300,0];

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/
    function getNftGrade(uint16 _tokenId) public view returns(uint8 _grade){
        return nftGrades[_tokenId];
    }

    function getBoostBonus(uint8 _grade) public view returns(uint16 _boost){
        return boostBonus[_grade];
    }

    function getNftBonus(uint16 _tokenId) external view returns(uint16 _boost){
        uint8 _nftGrade = getNftGrade(_tokenId);
        return getBoostBonus(_nftGrade);
    }

    /**
    * @dev Sets the MOMO grades to be used for calculating the bonus rate.
    * @param _momogrades An array of MOMO grades to be added to the existing grades.
    * Requirements:
    * - The function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    */
    function setAddMomoGrades(uint8[] calldata _momogrades) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint256 i = 0; i < _momogrades.length; i++){
            nftGrades.push(_momogrades[i]);
        }
    }

    /**
    * @dev Sets the bonus rates for each token grade.
    * @param _gradesbonus An array of bonus rates for each token grade.
    * Requirements:
    * - The function can only be called by an account with the DEFAULT_ADMIN_ROLE.
    */
    function setGradesBonus(uint8[5] calldata _gradesbonus) external onlyRole(DEFAULT_ADMIN_ROLE){
        boostBonus = _gradesbonus;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./GradeStorage.sol";
import "./RewardVault.sol";
import "./UserStorage.sol";

contract NTSBase {
    // Staking target ERC1155 NFT contract - TMHC
    IERC1155 public tmhcToken;
    // Staking target ERC721 NFT contract - MOMO
    IERC721 public momoToken;
    // Reward ERC20 Token contract
    NTSRewardVault public rewardVault;

    NTSUserManager public userStorage;

    NTSGradeStorage public gradeStorage;
    
    // Reward per Hour - TMHC
    uint256 public rewardPerHour;    
    // Reward per Hour - MOMO
    uint256 public rewardPerHourSub;


    event Staked(address indexed user, uint tokenType, uint16 [] indexed tokenId);       
    event unStaked(address indexed user, uint tokenType, uint16[] boostId);    
    event RewardPaid(address indexed user, uint256 reward);

}

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./NTS-Single.sol";

contract NTStakeMulti is NTStakeSingle {

    // Event emitted when a user stakes their team.
    event StakedTeam(address indexed user, uint16 indexed leaderId, uint16[] boostId);
    // Event emitted when a user unstakes their team.
    event unStakedTeam(address indexed user, uint16 indexed leaderId);

    uint256 internal teamStakeClaimed;

    /**
     * @dev Check if the player is the owner of the leader token.
     */
    function chkLeaderOwner(address player, uint16 _leaderId) internal view returns (bool) {
        return tmhcToken.balanceOf(player, _leaderId) == 1;
    }

    /**
     * @dev Check if the player is the owner of the boost token.
     */
    function chkBoostOwner(address player, uint16 _boostId) internal view returns (bool) {
        return momoToken.ownerOf(_boostId) == player;
    }

    /**
     * @dev Check if the player owns both the leader and boost tokens.
     */
    function chkOwnerAll(address player, uint16 _leaderId, uint16[] memory _boostIds) internal view returns (bool){
        if(chkLeaderOwner(player, _leaderId) == false){ return false;}
        for (uint16 i = 0; i < _boostIds.length; i++) {
            if(chkBoostOwner(player, _boostIds[i]) == false){ return false;}
        }
        return true;
    }

    function _getTeamBoostRate(address player, uint16 _staketeam) internal view returns (uint256 _boostRates) {
        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        uint16[] memory _boostIds = _inStakedteam.boostIds;
        // Add bonus rewards for each boost owned by the team.
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            if(!chkBoostOwner(player, _boostId)) { _boostRates = 0; return _boostRates; }
            uint16 _boostRate = gradeStorage.getNftBonus(_boostId); //gradesBonus[_boostGrade];
            _boostRates = _boostRates + _boostRate;
        }
        return _boostRates;
    }

    /**
     * @dev Check if the player needs to refresh their staking status.
     */
    function chkRefresh(address player, uint16 _staketeam) internal view returns (bool) {
        NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_staketeam);
        if(!chkLeaderOwner(player, _staketeam) && _inStakedtmhc.stakeowner == player){
            return true;
        }

        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        uint16[] memory _boostIds = _inStakedteam.boostIds;
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_boostId);
            if(!chkBoostOwner(player, _boostId) && _inStakedmomo.stakeowner == player){
                return true;
            }
        }
        return false;
    }

    /*///////////////////////////////////////////////////////////////
                Team Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/
    /**
    * @dev Stake a team by staking a leader NFT and booster NFTs.
    * @param _leaderId ID of the leader NFT to stake.
    * @param _boostIds Array of IDs of booster NFTs to stake.
    */
    function _stakeTeam(address _player, uint16 _leaderId, uint16[] calldata _boostIds) internal {
        require(chkOwnerAll(_player, _leaderId, _boostIds), "Not NFT owner.");
        NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_leaderId);
        require(_inStakedtmhc.stakeowner != _player, "TMHC already staked.");
        require(_boostIds.length <= 5, "A maximum of 5 booster NFTs are available.");
        require(_boostIds.length >= 1, "A minimum of 1 booster NFTs are available.");


        // Stake each booster NFT.
        for (uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_boostId);
            require(_inStakedmomo.stakeowner != _player, "MOMO already staked.");

            _inStakedmomo.staketeam = _leaderId;
            _inStakedmomo.stakeowner = _player;
        }

        // Stake the leader NFT.
        _inStakedtmhc.staketeam = _leaderId;
        _inStakedtmhc.stakeowner = _player;

        // Add user to the user list.
        userStorage.procAddUser(_player);
        // Add the staked team to the user's staked team list.
        userStorage.pushStakedTeam(_player, _leaderId);

        // Add the staked team to the global staked team list.
        NTSUserManager.StakeTeam memory _newTeam = NTSUserManager.StakeTeam(_player, _boostIds, block.timestamp);
        userStorage.setInStakedTeam(_leaderId, _newTeam);

        // Emit an event to indicate that a team has been staked.
        emit StakedTeam(_player, _leaderId, _boostIds);
    }

    /**
    * @dev Calculates the reward for a staked team.
    * @param _staketeam The ID of the staked team to calculate the reward for.
    * @return _totalReward The calculated reward for the staked team.
    */
    function _calRewardTeam(address player, uint16 _staketeam) internal view returns (uint256 _totalReward) {
        // If the sender is not the stakeowner of the team, return 0.
        if(!chkLeaderOwner(player, _staketeam)) { _totalReward=0; return _totalReward; }

        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
                // Get the boost IDs and last update block for the staked team.
        uint256 _lastUpdateTime = _inStakedteam.lastUpdateTime;

        // Calculate the base TMHC reward for the team.
        uint256 _tmhcReward = ((block.timestamp - _lastUpdateTime) * rewardPerHour) / 3600;

        // Add bonus rewards for each boost owned by the team.
        uint256 _boostRate = _getTeamBoostRate(player, _staketeam);
        if(_boostRate == 0) { _totalReward=0; return _totalReward; }
        _boostRate = _boostRate / 100;
        _totalReward = _tmhcReward + (_tmhcReward * _boostRate);

        return _totalReward;
    }

    /**
    * @dev Calculates the total reward for all staked teams of the caller.
    * @return _TotalReward The total calculated reward for all staked teams of the caller.
    */
    function _calRewardTeamAll(address _player) internal view returns (uint256 _TotalReward) {
        // Get the IDs of all staked teams owned by the caller.
        uint16[] memory _myStakeTeam = userStorage.getStakedUserTeam(_player);
        uint256 _totalReward = 0;

        // Calculate the total reward for all owned staked teams.
        for(uint16 i = 0; i < _myStakeTeam.length; i++) {
            _totalReward = _totalReward + _calRewardTeam(_player, _myStakeTeam[i]);
        }

        return _totalReward;
    }

    /**
    * @dev Unsets all boosts for a staked team when the team is unstaked.
    * @param _staketeam The ID of the staked team to unset boosts for.
    */
    function _unsetAllBoost(uint16 _staketeam) internal {
        // Unset all boosts for the staked team.
        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        uint16[] memory _boostIds = _inStakedteam.boostIds;
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            if(momoToken.ownerOf(_boostId) == msg.sender) {
                // If the caller is the owner of the boost, unset the boost's staked team.
                userStorage.delInStakedMOMO(_boostId);
            }
        }
    }

    function _refreshTeam(address _player, uint16 _staketeam) internal {
        if(chkRefresh(_player, _staketeam)){
            userStorage.popStakedTeam(_player, _staketeam);
            // If the caller has no staked teams, remove their stake from the users list.
            userStorage.procDelUser(_player);
        }else{
            return;
        }

        NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_staketeam);
        if(!chkLeaderOwner(_player, _staketeam) && _inStakedteam.stakeowner == _player){
            userStorage.delInStakedTMHC(_staketeam);
        }

        uint16[] memory _boostIds = _inStakedteam.boostIds;
        for(uint16 i = 0; i < _boostIds.length; i++) {
            uint16 _boostId = _boostIds[i];
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_boostId);
            if(!chkBoostOwner(msg.sender, _boostId) && _inStakedmomo.stakeowner == msg.sender){
                userStorage.delInStakedMOMO(_boostId);
            }
        }
    }

    /**
    * @dev Refreshes all staked teams owned by the caller by verifying ownership and updating their boosts.
    */
    function _refreshAllTeam(address _player) internal {
        // Get the IDs of all staked teams owned by the caller.
        uint16[] memory _myStakeTeam = userStorage.getStakedUserTeam(_player);

        // Refresh each staked team owned by the caller.
        for(uint16 i = 0; i < _myStakeTeam.length; i++) {
            _refreshTeam(_player, _myStakeTeam[i]);
        }
    }

    /**
    * @dev Calculates the reward for the staked team with the given leader NFT ID, transfers the reward to the caller, updates the staked team's last update block, and emits a RewardPaid event.
    * @param _leaderId The ID of the staked team's leader NFT.
    */
    function _claimTeam(address _player, uint16 _leaderId) internal {
        // Calculate the reward for the staked team.
        uint256 _myReward = _calRewardTeam(_player, _leaderId);
        if(_myReward > 0){
            // Transfer the reward to the caller.
            rewardVault.transferToken(_player, _myReward);
            // Update the last update block for the staked team.
            userStorage.setInStakedTeamTime(_leaderId);
            // Emit a RewardPaid event to indicate that the reward has been paid.
            teamStakeClaimed = teamStakeClaimed + _myReward;
            emit RewardPaid(_player, _myReward);
        }
    }

    function _claimTeamBatch(address _player, uint16[] calldata _leaderIds) internal{
        for(uint16 i = 0; i < _leaderIds.length; i++) {
            uint16 _leaderId = _leaderIds[i];
            _claimTeam(_player, _leaderId);
        }
    }

    /**
    * @dev Calculates the total reward for all staked teams owned by the caller, transfers the reward to the caller using the transferToken function of the ERC-20 reward token, updates the last update block for each staked team, and emits a RewardPaid event.
    */
    function _claimTeamAll(address _player) internal {
        // claim for each staked team owned by the caller.
        uint16[] memory _myStakeTeam = userStorage.getStakedUserTeam(_player);
        for(uint16 i = 0; i < _myStakeTeam.length; i++) {
            _claimTeam(_player, _myStakeTeam[i]);
        }
    }

    /**
    * @dev Unstakes the teams with the given leader NFT IDs owned by the caller, calculates the reward for each team, transfers the rewards to the caller, removes the staked teams and associated boosts from the caller's stakedteam array, and emits an unStakedTeam event for each team that was unstaked.
    * @param _leaderIds An array of leader NFT IDs corresponding to the staked teams to be unstaked.
    */
    function _unStakeTeam(address _player, uint16[] calldata _leaderIds) internal {
        for(uint16 i = 0; i < _leaderIds.length; i++) {
            uint16 _leaderId = _leaderIds[i];
            // Check that the caller is the owner of the TMHC NFT, is the owner of the staked team, and the TMHC NFT is on the staked team.
            require(tmhcToken.balanceOf(_player, _leaderId) == 1, "not TMHC owner.");
            NTSUserManager.StakeTeam memory _inStakedteam = userStorage.getInStakedTeam(_leaderId);
            require(_inStakedteam.stakeowner == _player, "not Team owner.");
            NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_leaderId);
            require(_inStakedtmhc.staketeam != 0 , "TMHC is not on the team.");
            // Delete TMHC data
            userStorage.delInStakedTMHC(_leaderId);
            // Calculate the reward for the staked team.
            uint256 _myReward = _calRewardTeam(_player, _leaderId);
            // Transfer the reward to the caller.
            rewardVault.transferToken(_player, _myReward);
            // Emit a RewardPaid event to indicate that the reward has been paid.
            emit RewardPaid(_player, _myReward);

            // Remove the staked team from the caller's stakedteam array.
            userStorage.popStakedTeam(_player, _leaderId);

            // Unset all boosts associated with the staked team.
            _unsetAllBoost(_leaderId);
            // Delete the staked user from the user mapping if the user no longer has any staked teams.
            userStorage.procDelUser(_player);
            // Emit an unStakedTeam event to indicate that the team has been unstaked.
            emit unStakedTeam(_player, _leaderId);
        }
    }

    /**
    * @dev A function to get the total unclaimed rewards across all staking players.
    * @return _totalUnClaim The total amount of unclaimed rewards.
    */
    function _getTeamUnClaim() internal view returns (uint256 _totalUnClaim) {
        address[] memory _usersArray = userStorage.getUsersArray();
        for(uint256 i = 0; i < _usersArray.length; i++)
        {   
            address _player = _usersArray[i];
            _totalUnClaim = _totalUnClaim + _calRewardTeamAll(_player);
        }
        return _totalUnClaim;
    }

    /**
    * @dev Returns the total amount of rewards claimed for team staking.
    * @return _teamStakeClaimed The total amount of rewards claimed for team staking.
    */
    function _getTeamClaimed() internal view returns(uint256 _teamStakeClaimed){
        return teamStakeClaimed;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./NTS-Base.sol";

contract NTStakeSingle is NTSBase{

    uint256 internal SingleStakeClaimed;
    /*///////////////////////////////////////////////////////////////
               Single Stake / Rewards / unStake cycle
    //////////////////////////////////////////////////////////////*/
    
    //Step1. Start single staking
    function _stake(address player, uint _tokenType, uint16[] calldata _tokenIds) internal {
        // tokenType 0 is for TMHC, and 1 is for MOMO.
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");

        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // Check the ownership and the staking status of the token.
                require(tmhcToken.balanceOf(player, _tokenId) == 1, "not TMHC owner.");
                NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_tokenId);
                require(_inStakedtmhc.staketeam == 0, "MOMO is part of the team.");
                require(_inStakedtmhc.stakeowner != player, "TMHC already staked.");

                // Add the user to the system if they haven't staked before.
                userStorage.procAddUser(player);
                // Add the staking to the user's information.
                userStorage.pushStakedTmhc(player, _tokenId);
                // Save the staking information.
                NTSUserManager.StakeTMHC memory _staketmhc = NTSUserManager.StakeTMHC(player, 0, block.timestamp);
                userStorage.setInStakedTMHC(_tokenId, _staketmhc);
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // Check the ownership and the staking status of the token.
                require(momoToken.ownerOf(_tokenId) == player, "not MOMO owner.");
                NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_tokenId);
                require(_inStakedmomo.staketeam == 0, "MOMO is part of the team.");
                require(_inStakedmomo.stakeowner != player, "MOMO already staked.");

                // Add the user to the system if they haven't staked before.
                userStorage.procAddUser(player);
                // Add the staking to the user's information.
                userStorage.pushStakedMomo(player, _tokenId);
                // Save the staking information.
                NTSUserManager.StakeMOMO memory _stakemomo = NTSUserManager.StakeMOMO(player, 0, block.timestamp);
                userStorage.setInStakedMOMO(_tokenId, _stakemomo);
            }
        }
        emit Staked(player, _tokenType, _tokenIds);    // Emit the staking event.
    }

    // Step2-1. Calculation reward
    /**
    * @dev Calculates the reward for a staked token.
    * @param _tokenType The type of the staked token (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the staked token.
    * @return _Reward The amount of reward for the staked token.
    */
    function _calReward(address player, uint _tokenType, uint16 _tokenId) internal view returns (uint256 _Reward){
        // The tokenType can be either 0 for TMHC or 1 for MOMO.
        uint256 _stakeTime = 0;
        if(_tokenType==0)
        {
            // TMHC
            NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_tokenId);
            // Check if the token is owned by the caller and if it is already staked.
            if(tmhcToken.balanceOf(player, _tokenId) == 1 && _inStakedtmhc.stakeowner == player && _inStakedtmhc.staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = block.timestamp - _inStakedtmhc.lastUpdateTime;
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
            // Calculate the reward based on the stake time and rewardPerHour.
            _Reward = ((_stakeTime * rewardPerHour) / 3600);
        }else if(_tokenType==1){
            // MOMO
            NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_tokenId);
            // Check if the token is owned by the caller and if it is already staked.
            if(momoToken.ownerOf(_tokenId) == player && _inStakedmomo.stakeowner == player && _inStakedmomo.staketeam == 0){
                // If the token is already staked, calculate the stake time.
                _stakeTime = block.timestamp - _inStakedmomo.lastUpdateTime;
            }else{
                // If the token is not owned by the caller or not staked, return 0 as the reward.
                return 0;
            }
            // Calculate the reward based on the stake time and rewardPerHourSub.
            _Reward = ((_stakeTime * rewardPerHourSub) / 3600);
        }

        return _Reward;
    }

    // Step2-2. Clculation rewalrd all stake
    /**
    * @dev Calculates the total reward for all staked tokens of the caller.
    * @return _totalReward The total reward amount for all staked tokens of the caller.
    */
    function _calRewardAll(address _player) internal view returns(uint256 _totalReward){
        // Get the list of staked TMHC and MOMO tokens for the caller.
        uint16[] memory _stakedtmhc = userStorage.getStakedUserTmhc(_player);
        uint16[] memory _stakedmomo = userStorage.getStakedUserMomo(_player);

        // Loop through all staked TMHC tokens and calculate the reward for each.
        for (uint16 i = 0; i < _stakedtmhc.length; i++){
            uint16 _tokenId = _stakedtmhc[i];
            _totalReward = _totalReward + _calReward(_player, 0, _tokenId);
        }

        // Loop through all staked MOMO tokens and calculate the reward for each.
        for (uint16 i = 0; i < _stakedmomo.length; i++){
            uint16 _tokenId = _stakedmomo[i];
            _totalReward = _totalReward + _calReward(_player, 1, _tokenId);
        }
        return _totalReward;
    }

    // Step3. Claim reward
    /**
    * @dev Claims the reward for a staked token and transfers it to the caller's address.
    * @param _tokenType The type of the staked token (0 for TMHC, 1 for MOMO).
    * @param _tokenId The ID of the staked token.
    */
    function _claim(address _player, uint _tokenType, uint16 _tokenId) internal {
        // Calculate the reward for the staked token.
        uint256 _myReward = _calReward(_player, _tokenType, _tokenId);
        
        if(_myReward > 0){
            // Transfer the reward tokens to the caller using the transferToken function of the ERC-20 token.
            rewardVault.transferToken(_player, _myReward);
            // Reset the last update block for the staked token.
            if(_tokenType==0){
                userStorage.setInStakedTMHCTime(_tokenId);
            }else if(_tokenType==1){
                userStorage.setInStakedMOMOTime(_tokenId);
            }
            // Update the user's total rewards earned and store the reward payment information.
            userStorage.addRewardsEarned(_player, _myReward);
            SingleStakeClaimed = SingleStakeClaimed + _myReward;
            // Emit an event to indicate that the reward has been paid.
            emit RewardPaid(_player, _myReward);
        }
    }

    function _claimBatch(address _player, uint _tokenType, uint16[] calldata _tokenIds) internal {
        for(uint16 i = 0; i < _tokenIds.length; i++)
        {
            _claim(_player, 0, _tokenIds[i]);
        }
    }

    // Step4. Claim reward all stake
    /**
    * @dev Claims the rewards for all staked tokens of the caller and transfers them to the caller's address.
    */
    function _claimAll(address _player) internal {
        // claim all staked tokens of the caller.
        uint16[] memory _stakedtmhc = userStorage.getStakedUserTmhc(_player);
        uint16[] memory _stakedmomo = userStorage.getStakedUserMomo(_player);
        for(uint16 i = 0; i < _stakedtmhc.length; i++)
        {
            _claim(_player, 0, _stakedtmhc[i]);
        }

        for(uint16 i = 0; i < _stakedmomo.length; i++)
        {
            _claim(_player, 1, _stakedmomo[i]);
        }
    }

    // Step5. unstake single staking
    /**
    * @dev Unstakes the specified tokens of the specified token type and transfers the rewards to the caller's address.
    * @param _tokenType The type of the tokens to unstake (0 for TMHC, 1 for MOMO).
    * @param _tokenIds An array of token IDs to unstake.
    */
    function _unStake(address _player, uint _tokenType, uint16[] calldata _tokenIds) internal {
        require(_tokenType == 0 || _tokenType == 1, "Invalid tokentype.");
        // Token type 0 represents TMHC and 1 represents MOMO.
        if(_tokenType==0)
        {
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // TMHC
                // Check if the caller is the owner of the token and if the token is already staked.
                require(tmhcToken.balanceOf(_player, _tokenId) == 1, "not TMHC owner.");
                NTSUserManager.StakeTMHC memory _inStakedtmhc = userStorage.getStakedTMHC(_tokenId);
                require(_inStakedtmhc.stakeowner == _player, "TMHC not staked.");
                require(_inStakedtmhc.staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_player, _tokenType, _tokenId);
                // Remove the staked token from the user's stakedtmhc array.
                userStorage.popStakedTmhc(_player, _tokenId);
                userStorage.delInStakedTMHC(_tokenId);
            }
        }else if(_tokenType==1){
            for (uint16 i = 0; i < _tokenIds.length; i++) {
                uint16 _tokenId = _tokenIds[i];
                // MOMO
                // Check if the caller is the owner of the token and if the token is already staked.
                require(momoToken.ownerOf(_tokenId) == _player, "not MOMO owner.");
                NTSUserManager.StakeMOMO memory _inStakedmomo = userStorage.getStakedMOMO(_tokenId);
                require(_inStakedmomo.stakeowner == _player, "MOMO not staked.");
                require(_inStakedmomo.staketeam == 0 , "TMHC is on the team.");
                // Claim the reward before unstaking the token.
                _claim(_player, _tokenType, _tokenId);
                // Remove the staked token from the user's stakedmomo array.
                userStorage.popStakedMomo(_player, _tokenId);
                userStorage.delInStakedMOMO(_tokenId);
            }
        }else{
            revert("Invalid tokentype.");
        }
        // Delete the user from the users mapping if they have no staked tokens.
        userStorage.procDelUser(_player);
        // Emit an event to indicate that the tokens have been unstaked.
        emit unStaked(_player, _tokenType, _tokenIds);    
    }

    /**
    * @dev A function to get the total unclaimed rewards across all staking players.
    * @return _totalUnClaim The total amount of unclaimed rewards.
    */
    function _getSingleUnClaim() internal view returns (uint256 _totalUnClaim) {
        address[] memory _usersArray = userStorage.getUsersArray();
        for(uint256 i = 0; i < _usersArray.length; i++)
        {   
            address _player = _usersArray[i];
            _totalUnClaim = _totalUnClaim + _calRewardAll(_player);
        }
        return _totalUnClaim;
    }

    /**
    * @dev Returns the total amount of rewards claimed for single staking.
    * @return _SingleStakeClaimed The total amount of rewards claimed for single staking.
    */
    function _getSingleClaimed() internal view returns(uint256 _SingleStakeClaimed){
        return SingleStakeClaimed;
    }
}

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

/**
 * @title NTSRewardVault
 * @dev Contract to manage the rewards tokens accepted and transferred in the system.
 */
contract NTSRewardVault is PermissionsEnumerable {
    using SafeERC20 for IERC20;
    IERC20 private _acceptedToken;

    /**
     * @dev Initializes the contract by setting the acceptedToken and granting the DEFAULT_ADMIN_ROLE to the deployer.
     * @param acceptedToken The token that will be accepted and transferred as reward.
     */
    constructor(IERC20 acceptedToken) {
        _acceptedToken = acceptedToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Allows anyone to deposit tokens into the contract as a reward.
     * @param amount The amount of tokens to be transferred.
     */
    function receiveToken(uint256 amount) external {
        _acceptedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to transfer tokens as rewards to a recipient.
     * @param recipient The address to which the tokens will be transferred.
     * @param amount The amount of tokens to be transferred.
     */
    function transferToken(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        _acceptedToken.safeTransfer(recipient, amount);
    }

    /**
     * @dev Returns the balance of the acceptedToken held in the contract.
     * @return The balance of the acceptedToken.
     */
    function getTokenBalance() public view returns (uint256) {
        return _acceptedToken.balanceOf(address(this));
    }

    /**
     * @dev Allows the DEFAULT_ADMIN_ROLE to set a new address to the DEFAULT_ADMIN_ROLE.
     * @param _address The address to which the DEFAULT_ADMIN_ROLE will be granted.
     */
    function setRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE){
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }
}

// SPDX-License-Identifier: UNLICENSED

/* 
*This code is subject to the Copyright License
* Copyright (c) 2023 Sevenlinelabs
* All rights reserved.
*/
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract NTSUserManager is PermissionsEnumerable{
    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    struct StakeUser{
        uint256 rewardsEarned;
        uint16[] stakedteam;
        uint16[] stakedtmhc;
        uint16[] stakedmomo;
    }

    // Staking user array for cms.
    address[] internal usersArray;
    mapping(address=>StakeUser) internal users;

    // Stores staking information based on MOMO NFT ownership.
    struct StakeMOMO {
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateTime;
    }

    // Stores staking information based on TMHC NFT ownership.
    struct StakeTMHC {
        address stakeowner;
        uint16 staketeam;
        uint256 lastUpdateTime;
    }

    // Arrays to store staking information for MOMO and TMHC NFTs respectively.
    StakeMOMO[10000] internal inStakedmomo;
    StakeTMHC[10000] internal inStakedtmhc;

    // Structure that represents a staked team.
    struct StakeTeam {
        address stakeowner; // Address of the team's stakeowner.
        uint16[] boostIds; // IDs of the team's boosts.
        uint256 lastUpdateTime; // Block number of the last update to the team's stake.
    }

    // Array that stores all staked teams.
    StakeTeam[10000] internal inStakedteam;

    /*///////////////////////////////////////////////////////////////
                         Stake Item Storage
    //////////////////////////////////////////////////////////////*/

    // @dev MOMO Stake
    function getStakedMOMO(uint16 _tokenId) external view returns(StakeMOMO memory){
        return inStakedmomo[_tokenId];
    }
    function setInStakedMOMO(uint16 _tokenId, StakeMOMO memory stake) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedmomo.length, "_tokenId out of bounds");
        inStakedmomo[_tokenId] = stake;
    }
    function setInStakedMOMOTime(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        inStakedmomo[_tokenId].lastUpdateTime = block.timestamp;
    }
    function delInStakedMOMO(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedmomo.length, "_tokenId out of bounds");
        delete inStakedmomo[_tokenId];
    }

    // @dev TMHC Stake
    function getStakedTMHC(uint16 _tokenId) external view returns(StakeTMHC memory values){
        return inStakedtmhc[_tokenId];
    }
    function setInStakedTMHC(uint16 _tokenId, StakeTMHC memory stake) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedtmhc.length, "_tokenId out of bounds");
        inStakedtmhc[_tokenId] = stake;
    }
    function setInStakedTMHCTime(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        inStakedtmhc[_tokenId].lastUpdateTime = block.timestamp;
    }
    function delInStakedTMHC(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(_tokenId < inStakedtmhc.length, "_tokenId out of bounds");
        delete inStakedtmhc[_tokenId];
    }

    // @dev Team Stake
    function setInStakedTeam(uint16 _tokenId, StakeTeam memory stake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenId < inStakedteam.length, "_tokenId out of bounds");
        inStakedteam[_tokenId] = stake;
    }
    function getInStakedTeam(uint16 _tokenId) external view returns (StakeTeam memory) {
        require(_tokenId < inStakedteam.length, "_tokenId out of bounds");
        return inStakedteam[_tokenId];
    }
    function setInStakedTeamTime(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        inStakedteam[_tokenId].lastUpdateTime = block.timestamp;
    }
    function delInStakedTeam(uint16 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenId < inStakedteam.length, "_tokenId out of bounds");
        delete inStakedteam[_tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                              User Storage
    //////////////////////////////////////////////////////////////*/

    // Get rewardsEarned for a user
    function getRewardsEarned(address user) external view returns (uint256) {
        return users[user].rewardsEarned;
    }

    // Get stakedteam for a user
    function getStakedUserTeam(address user) external view returns (uint16[] memory) {
        return users[user].stakedteam;
    }

    // Get stakedtmhc for a user
    function getStakedUserTmhc(address user) external view returns (uint16[] memory) {
        return users[user].stakedtmhc;
    }

    // Get stakedmomo for a user
    function getStakedUserMomo(address user) external view returns (uint16[] memory) {
        return users[user].stakedmomo;
    }

    // Add rewardsEarned for a user
    function addRewardsEarned(address user, uint256 rewards) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].rewardsEarned = users[user].rewardsEarned + rewards;
    }

    // Push team id to stakedteam for a user
    function pushStakedTeam(address user, uint16 teamId) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].stakedteam.push(teamId);
    }

    // Push tmhc id to stakedtmhc for a user
    function pushStakedTmhc(address user, uint16 tmhcId) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].stakedtmhc.push(tmhcId);
    }

    // Push momo id to stakedmomo for a user
    function pushStakedMomo(address user, uint16 momoId) external onlyRole(DEFAULT_ADMIN_ROLE){
        users[user].stakedmomo.push(momoId);
    }

    // Pop a specific team id from stakedteam for a user
    function popStakedTeam(address user, uint16 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint16[] storage teamArray = users[user].stakedteam;
        uint256 length = teamArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (teamArray[i] == tokenId) {
                // Swap the last element with the element to delete
                teamArray[i] = teamArray[length - 1];
                // Remove the last element
                teamArray.pop();
                return;
            }
        }
        revert("Token ID not found in stakedteam array");
    }

    // Pop a specific tmhc id from stakedtmhc for a user
    function popStakedTmhc(address user, uint16 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint16[] storage tmhcArray = users[user].stakedtmhc;
        uint256 length = tmhcArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (tmhcArray[i] == tokenId) {
                // Swap the last element with the element to delete
                tmhcArray[i] = tmhcArray[length - 1];
                // Remove the last element
                tmhcArray.pop();
                return;
            }
        }
        revert("Token ID not found in stakedtmhc array");
    }

    // Pop a specific momo id from stakedmomo for a user
    function popStakedMomo(address user, uint16 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint16[] storage momoArray = users[user].stakedmomo;
        uint256 length = momoArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (momoArray[i] == tokenId) {
                // Swap the last element with the element to delete
                momoArray[i] = momoArray[length - 1];
                // Remove the last element
                momoArray.pop();
                return;
            }
        }
        revert("Token ID not found in stakedmomo array");
    }

    function getUsersArray() public view returns (address[] memory) {
        return usersArray;
    }


    /**
    * @dev Adds the caller's address to the usersArray if they have no staked tokens.
    */
    function procAddUser(address _player) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(users[_player].stakedtmhc.length == 0 && users[_player].stakedmomo.length == 0 && users[_player].stakedteam.length ==0){
            usersArray.push(_player);
        }
    }

    /**
    * @dev Deletes the caller's address from the usersArray if they have no staked tokens.
    */
    function procDelUser(address _player) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        if(users[_player].stakedtmhc.length == 0 && users[_player].stakedmomo.length == 0 && users[_player].stakedteam.length ==0){
            address[] memory _userArray = usersArray;
            for(uint256 i = 0; i <_userArray.length; i++){
                if(_userArray[i] == _player){
                    usersArray[i] = _userArray[_userArray.length-1];
                    usersArray.pop();
                }
            }
        }
    }

    function resetInStakedTMHC() external onlyRole(DEFAULT_ADMIN_ROLE){
        delete inStakedtmhc;
    }

    function resetInStakedMOMO() external onlyRole(DEFAULT_ADMIN_ROLE){
        delete inStakedmomo;
    }

    function resetInStakedTEAM() external onlyRole(DEFAULT_ADMIN_ROLE){
        delete inStakedteam;
    }

    function resetUsers() external onlyRole(DEFAULT_ADMIN_ROLE){
        address[] memory userKeys = getUsersArray();
        for (uint256 i = 0; i < userKeys.length; i++) {
            delete users[userKeys[i]];
        }
        delete usersArray;
    }


}