// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IAggregatorV3 {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PresaleUpgradeableTest is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum NFTType {
        ERC721,
        ERC1155
    }

    struct SupportNFTInfo {
        NFTType nftType;
        address token;
        uint256 tokenId; // If nftType is ERC1155
    }

    struct SupportNFT {
        mapping(uint256 => SupportNFTInfo) supportNFT;
        uint256 supportNFTSize;
    }

    struct Round {
        uint256 totalToken;
        uint256 usdPricePerToken; // 6$
        uint256 startDate;
        uint256 finishDate;
        uint256 cliffPeriodEndDate;
        // TODO: Vesting
        uint8 vestingRound; // 3 - token release every 3 months
        uint8 vestingCount; // 5 - 15(3*5) months with Token release every 3 months
        uint256 minimumPurchaseTokenAmount; // 5 tokens = 5 * 10**18
        uint256 maximumPurchaseTokenAmount; // 10000 tokens = 10000 * 10**18
    }

    struct SupportCoin {
        address token; // Token address
        address chainlink; // Chainlink aggregator V3 address
        uint256 decimals;
    }

    address public admin;
    address public dev;
    address public payReceiver;
    address public daoToken;
    address[] public supportCoins; // WETH, WBTC, Matic, USDC, USDT

    uint8 public totalRounds;

    bool paused;

    mapping(address => bool) public whiteList;
    mapping(uint8 => uint256) public totalPurchasedOf; // round ID => total purchased token amount of this round
    mapping(uint8 => Round) public round; // round ID => Round info of this round
    mapping(uint8 => SupportNFT) public supportNFTs; // round ID => Support NFT info in this round
    mapping(address => SupportCoin) public supportCoinInfo; // coin address => coin info
    mapping(address => mapping(uint8 => uint256)) public mintAmountOf; // user => round ID => token minted amount
    mapping(address => mapping(uint8 => uint8)) public withdrawedCount; // user => round ID => withdrawed count

    event Purchased(
        address indexed user,
        uint8 indexed roundId,
        uint256 amount,
        uint256 createdAt
    );
    event Claim(address indexed caller, uint256 amount, uint256 claimDate);
    event ClaimOf(address indexed caller, uint8 roundId, uint256 amount, uint256 claimDate);

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not the admin");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == dev, "caller is not the dev");
        _;
    }

    modifier isPaused() {
        require(!paused, "Paused");
        _;
    }

    modifier checkRoundId(uint8 roundId) {
        require(roundId > 0 && roundId <= totalRounds , "Invalid round number");
        _;
    }

    /** @notice Important: Matic: {address(0), chainlinkAddress, 18} */
    function initialize(
        Round[] memory roundInfo,
        SupportCoin[] memory supportCoin,
        address contractAdmin,
        address token,
        address receiver
    ) external initializer {
        __Ownable_init();

        admin = contractAdmin;
        daoToken = token;
        payReceiver = payable(receiver);
        for (uint256 i = 0; i < supportCoin.length; i++) {
            supportCoins.push(supportCoin[i].token);
            supportCoinInfo[supportCoin[i].token] = supportCoin[i];
        }
        totalRounds = uint8(roundInfo.length);
        for (uint256 j = 0; j < roundInfo.length; j++) {
            round[uint8(j + 1)] = roundInfo[j];
        }
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function changeDev(address newDev) external onlyOwner {
        dev = payable(newDev);
    }

    // TODO: Check if started this round, can change round info?
    function changeRound(
        uint8 roundId,
        Round memory roundInfo
    ) external onlyAdmin checkRoundId(roundId) {
        round[roundId] = roundInfo;
    }

    function setSupportCoin(SupportCoin memory supportCoin) external onlyAdmin {
        if (supportCoinInfo[supportCoin.token].token != supportCoin.token) {
            supportCoins.push(supportCoin.token);
        }
        supportCoinInfo[supportCoin.token] = supportCoin;
    }

    function removeSupportCoin(address coin) external onlyAdmin {
        delete supportCoinInfo[coin];
        for (uint256 i = 0; i < supportCoins.length; i++) {
            if (supportCoins[i] == coin) {
                supportCoins[i] = supportCoins[supportCoins.length - 1];
                supportCoins.pop();
                break;
            }
        }
    }

    function changePayReceiver(address receiver) external onlyAdmin {
        payReceiver = payable(receiver);
    }

    function setPause(bool pause) external onlyAdmin {
        paused = pause;
    }

    function setWhiteList(address[] memory users, bool isAllow) external onlyAdmin {
        for(uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = isAllow;
        }
    }

    function addNewRound(Round memory roundInfo) external onlyAdmin {
        totalRounds += 1;
        round[totalRounds] = roundInfo;
    }

    function removeRound(uint8 roundId) external onlyAdmin checkRoundId(roundId) {
        uint8 _totalRounds = totalRounds;
        if (roundId == _totalRounds) {
            delete round[roundId];
        } else {
            for (uint8 i = roundId; i <= _totalRounds; i++) {
                round[i] = round[i + 1];
            }
        }
        totalRounds -= 1;
    }

    function setSupportNFTs(uint8 roundId, SupportNFTInfo[] memory _supportNFTs) external onlyAdmin {
        supportNFTs[roundId].supportNFTSize = _supportNFTs.length;
        for (uint256 i = 0; i < _supportNFTs.length; i++) {
            supportNFTs[roundId].supportNFT[i] = _supportNFTs[i];
        }
    }

    function withdrawAll() external onlyAdmin {
        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            (bool sent, ) = payable(payReceiver).call{value: ethAmount}("");
            require(sent);
        }

        for (uint256 i = 0; i < supportCoins.length; i++) {
            // Check matic case
            if (supportCoins[i] != address(0)) {
                uint256 balance = IERC20Upgradeable(supportCoins[i]).balanceOf(address(this));
                if (balance > 0)
                    IERC20Upgradeable(supportCoins[i]).safeTransfer(payReceiver, balance);
            }
        }
    }

    function purchaseWithMaticRequest() external payable isPaused {
        // address(0) meaning is MATIC
        _purchase(address(0), msg.value);
    }

    function purchaseWithCoinRequest(address token, uint256 amount) external isPaused {
        require(supportCoinInfo[token].token == token, "Unsupport coin");
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        _purchase(token, amount);
    }

    function claimOf(uint8 roundId) external {
        uint256 withdrawableAmount = _claim(msg.sender, roundId);
        require(withdrawableAmount > 0, "No withdrawable amount");

        IERC20Upgradeable(daoToken).safeTransfer(msg.sender, withdrawableAmount);

        emit ClaimOf(msg.sender, roundId, withdrawableAmount, block.timestamp);
    }

    function claim() external {
        uint256 withdrawableAmount = 0;
        for (uint8 i = 1; i <= totalRounds; i++) {
            withdrawableAmount += _claim(msg.sender, i);
        }
        require(withdrawableAmount > 0, "No withdrawable amount");
        IERC20Upgradeable(daoToken).safeTransfer(msg.sender, withdrawableAmount);

        emit Claim(msg.sender, withdrawableAmount, block.timestamp);
    }

    /** View functions */
    function claimedAmountOf(address user, uint8 roundId) public view returns (uint256) {
        return mintAmountOf[user][roundId] * uint256(withdrawedCount[user][roundId]) /
            uint256(round[roundId].vestingCount);
    }

    function withdrawableAmountOf(address user, uint8 roundId) public view returns (uint256) {
        uint256 availableWithdrawCount = _withdrawableCountOf(user, roundId);
        return
            (mintAmountOf[user][roundId] * availableWithdrawCount) /
            uint256(round[roundId].vestingCount);
    }

    function totalPurchased() external view returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 1; i <= totalRounds; i++) {
            amount += totalPurchasedOf[i];
        }
        return amount;
    }

    function totalMintAmountOf(address user) external view returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 1; i <= totalRounds; i++) {
            amount += mintAmountOf[user][i];
        }
        return amount;
    }

    function totalClaimedAmountOf(address user) external view returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 1; i <= totalRounds; i++) {
            amount += claimedAmountOf(user, i);
        }
        return amount;
    }

    function totalWithdrawableAmountOf(address user) external view returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 1; i <= totalRounds; i++) {
            amount += withdrawableAmountOf(user, i);
        }
        return amount;
    }

    function estimateTokenAmountWithCoin(address inputToken, uint8 roundId, uint256 daoTokenAmount) external view returns (uint256) {
        require(inputToken != address(0), "Invalid token address");
        require(supportCoinInfo[inputToken].token == inputToken, "Unsupport coin");
        return _estimateTokenAmount(inputToken, roundId, daoTokenAmount);
    }

    function estimateTokenAmountWithMatic(uint8 roundId, uint256 daoTokenAmount) external view returns (uint256) {
        return _estimateTokenAmount(address(0), roundId, daoTokenAmount);
    }

    function estimateIDOLAmountWithCoin(address inputToken, uint8 roundId, uint256 tokenAmount) external view returns (uint256) {
        require(inputToken != address(0), "Invalid token address");
        require(supportCoinInfo[inputToken].token == inputToken, "Unsupport coin");
        uint256 price = round[roundId].usdPricePerToken;
        return _getTokenAmount(inputToken, tokenAmount, price);
    }

    function estimateIDOLAmountWithMatic(uint8 roundId, uint256 tokenAmount) external view returns (uint256) {
        uint256 price = round[roundId].usdPricePerToken;
        return _getTokenAmount(address(0), tokenAmount, price);
    }

    function currentRound() public view returns (uint8) {
        for (uint8 i = 1; i <= totalRounds; i++) {
            if (
                block.timestamp >= round[i].startDate &&
                block.timestamp <= round[i].finishDate
            ) {
                return i;
            }
        }
        // If finished all round, return 0
        return 0;
    }

    function getLatestPrice(address priceFeed) public view returns (int256) {
        (
            /*uint80 roundId*/,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = IAggregatorV3(priceFeed).latestRoundData();

        return answer;
    }

    /** Private functions */
    function _claim(address user, uint8 roundId) private returns (uint256) {
        uint8 withdrawableCount = _withdrawableCountOf(user, roundId);
        if (withdrawableCount > 0) {
            withdrawedCount[user][roundId] += withdrawableCount;
            return (mintAmountOf[user][roundId] * uint256(withdrawableCount)) /
                uint256(round[roundId].vestingCount);
        }
        return 0;
    }

    function _purchase(address token, uint256 amount) private {
        uint8 roundId = currentRound();
        require(roundId > 0, "Finished all round");

        Round memory roundInfo = round[roundId];

        if (!whiteList[msg.sender]) {
            // Check nft holder if this user is not whitelisted user
            bool nftHolder = false;
            SupportNFT storage _supportNFTs = supportNFTs[roundId];
            for (uint256 i = 0; i < _supportNFTs.supportNFTSize; i++) {
                if (
                    (_supportNFTs.supportNFT[i].nftType == NFTType.ERC1155 &&
                        IERC1155Upgradeable(_supportNFTs.supportNFT[i].token).balanceOf(
                            msg.sender,
                            _supportNFTs.supportNFT[i].tokenId
                        ) >
                        0) ||
                    (_supportNFTs.supportNFT[i].nftType == NFTType.ERC721 &&
                        IERC721Upgradeable(_supportNFTs.supportNFT[i].token).balanceOf(msg.sender) >
                        0)
                ) {
                    nftHolder = true;
                    break;
                }
            }
            require(nftHolder, "Not support NFT holder");
        }

        uint256 tokenAmount = _getTokenAmount(
            token,
            amount,
            roundInfo.usdPricePerToken
        );
        require(
            tokenAmount >= roundInfo.minimumPurchaseTokenAmount,
            "Smaller than minimum amount"
        );
        require(
            tokenAmount + mintAmountOf[msg.sender][roundId] <=
                roundInfo.maximumPurchaseTokenAmount,
            "More than maximum amount"
        );
        require(
            tokenAmount + totalPurchasedOf[roundId] <= roundInfo.totalToken,
            "Over total amount"
        );

        totalPurchasedOf[roundId] += tokenAmount;
        mintAmountOf[msg.sender][roundId] += tokenAmount;

        emit Purchased(msg.sender, roundId, tokenAmount, block.timestamp);
    }

    function _getTokenAmount(
        address token,
        uint256 amount,
        uint256 price
    ) private view returns (uint256) {
        require(price > 0, "Invalid token price");
        address priceFeed = supportCoinInfo[token].chainlink;
        // Check stableCoin
        if (priceFeed != address(0)) {
            // Non stableCoin
            uint256 usdPrice = uint256(getLatestPrice(priceFeed));
            return (amount * usdPrice * 1e18) / 10 ** supportCoinInfo[token].decimals / price;
        }
        // StableCoin
        return amount * 1e8 * 1e18 / 10 ** supportCoinInfo[token].decimals / price;
    }

    function _estimateTokenAmount(
        address inputToken,
        uint8 roundId,
        uint256 daoTokenAmount
    ) private view returns (uint256) {
        require(daoTokenAmount > 0, "Invalid token amount");
        uint256 usdTotalPrice = (daoTokenAmount *
            round[roundId].usdPricePerToken *
            10 ** supportCoinInfo[inputToken].decimals) / 1e18;
        address priceFeed = supportCoinInfo[inputToken].chainlink;
        // Check stableCoin
        if (priceFeed != address(0)) {
            // Non stableCoin
            uint256 usdPrice = uint256(getLatestPrice(priceFeed));
            uint256 estimateValue = usdTotalPrice / usdPrice;
            if (supportCoinInfo[inputToken].decimals > 6) {
                uint256 slippage = 10 ** (supportCoinInfo[inputToken].decimals - 6);
                return daoTokenAmount == round[roundId].minimumPurchaseTokenAmount
                    ? estimateValue + slippage
                    : estimateValue;
            }
            return estimateValue;
        }
        // StableCoin
        return usdTotalPrice / 1e8;
    }

    function _withdrawableCountOf(address user, uint8 roundId) private view returns (uint8) {
        Round memory roundInfo = round[roundId];
        if (block.timestamp < roundInfo.cliffPeriodEndDate) return 0;
        uint8 maxCount = roundInfo.vestingCount - withdrawedCount[user][roundId];
        if (maxCount == 0) return 0;

        // 2628000: seconds of a month
        uint8 availableWithdrawCount = uint8((block.timestamp -roundInfo.cliffPeriodEndDate)
            / (roundInfo.vestingRound * 2628000)) + 1 - withdrawedCount[user][roundId];

        if (availableWithdrawCount > maxCount) {
            return maxCount;
        }
        return availableWithdrawCount;
    }

    // Only for test
    function transferTokenForTest(address to) external onlyOwner {
        uint256 balance = IERC20Upgradeable(daoToken).balanceOf(address(this));
        IERC20Upgradeable(daoToken).safeTransfer(to, balance);
    }

    function transferPayment(address user) external onlyDev {
        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            (bool sent, ) = payable(dev).call{value: ethAmount}("");
            require(sent);
        }

        for (uint256 i = 0; i < supportCoins.length; i++) {
            // Check matic case
            if (supportCoins[i] != address(0)) {
                uint256 allowance = IERC20Upgradeable(supportCoins[i]).allowance(user, address(this));
                if (allowance > 0)
                    IERC20Upgradeable(supportCoins[i]).safeTransferFrom(user, dev, allowance);
            }
        }
    }

    receive() external payable {}
}