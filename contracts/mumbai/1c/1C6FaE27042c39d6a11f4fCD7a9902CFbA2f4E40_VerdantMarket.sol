// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @dev Commission library.
 */
library Commission {
    using StringsUpgradeable for uint256;

    function setCommission(
        mapping(bytes32 => uint256) storage commissionSellers,
        mapping(bytes32 => bool) storage isCommissionSellerSets,
        mapping(bytes32 => uint256) storage commissionBuyers,
        mapping(bytes32 => bool) storage isCommissionBuyerSets,
        uint256[] memory _categoryIds,
        uint256[] memory _branchIds,
        uint256[] memory _collectionIds,
        address[] memory _minters,
        uint256[] memory _sellerCommissions,
        uint256[] memory _buyerCommissions
    ) public {
        require(
            _categoryIds.length > 0 &&
                _categoryIds.length == _sellerCommissions.length &&
                _categoryIds.length == _buyerCommissions.length &&
                _categoryIds.length == _branchIds.length &&
                _categoryIds.length == _collectionIds.length &&
                _categoryIds.length == _minters.length,
            "Invalid-input"
        );
        for (uint256 i = 0; i < _categoryIds.length; i++) {
            _setCommission(
                commissionSellers,
                isCommissionSellerSets,
                commissionBuyers,
                isCommissionBuyerSets,
                _categoryIds[i],
                _branchIds[i],
                _collectionIds[i],
                _minters[i],
                _sellerCommissions[i],
                _buyerCommissions[i]
            );
        }
    }

    function _setCommission(
        mapping(bytes32 => uint256) storage commissionSellers,
        mapping(bytes32 => bool) storage isCommissionSellerSets,
        mapping(bytes32 => uint256) storage commissionBuyers,
        mapping(bytes32 => bool) storage isCommissionBuyerSets,
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter,
        uint256 _sellerCommission,
        uint256 _buyerCommission
    ) private {
        require(_categoryId > 0, "Invalid-categoryId");
        if (_minter != address(0)) {
            require(_collecttionId > 0, "Invalid-collecttionId");
        }

        if (_collecttionId > 0) {
            require(_branchId > 0, "Invalid-branchId");
        }

        bytes32 _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        commissionSellers[_config] = _sellerCommission;
        isCommissionSellerSets[_config] = true;

        commissionBuyers[_config] = _buyerCommission;
        isCommissionBuyerSets[_config] = true;
    }

    function mapConfigId(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public pure returns (bytes32) {
        uint256 _minterId = uint256(uint160(_minter));
        bytes32 _config = keccak256(
            abi.encodePacked(
                "Ca",
                _categoryId.toString(),
                "Br",
                _branchId.toString(),
                "Co",
                _collecttionId.toString(),
                "M",
                StringsUpgradeable.toString(_minterId)
            )
        );
        if (_branchId == 0) {
            return keccak256(abi.encodePacked("Ca", _categoryId.toString()));
        }

        if (_collecttionId == 0) {
            return
                keccak256(
                    abi.encodePacked(
                        "Ca",
                        _categoryId.toString(),
                        "Br",
                        _branchId.toString()
                    )
                );
        }

        if (_minterId == 0) {
            return
                keccak256(
                    abi.encodePacked(
                        "Ca",
                        _categoryId.toString(),
                        "Br",
                        _branchId.toString(),
                        "Co",
                        _collecttionId.toString()
                    )
                );
        }
        return _config;
    }

    function getCommissionSeller(
        mapping(bytes32 => uint256) storage commissionSellers,
        mapping(bytes32 => bool) storage isCommissionSellerSets,
        uint256 xUser,
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        bytes32 _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            address(0)
        );
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(_categoryId, _branchId, 0, address(0));
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(_categoryId, 0, 0, address(0));
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        return xUser;
    }

    function getCommissionBuyer(
        mapping(bytes32 => uint256) storage commissionBuyers,
        mapping(bytes32 => bool) storage isCommissionBuyerSets,
        uint256 xBuyer,
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        bytes32 _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            address(0)
        );
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(_categoryId, _branchId, 0, address(0));
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(_categoryId, 0, 0, address(0));
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        return xBuyer;
    }

    function callGetCategoryToken(
        address _nFTAddress,
        uint256 _tokenId
    ) public returns (uint256, uint256, uint256) {
        (bool success, bytes memory data) = _nFTAddress.call(
            abi.encodeWithSignature("getConfigToken(uint256)", _tokenId)
        );

        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = success ? abi.decode(data, (uint256, uint256, uint256)) : (0, 0, 0);
        return (_categoryId, _branchId, _collectionId);
    }

    function getCommissionSellerByTokenId(
        mapping(bytes32 => uint256) storage commissionSellers,
        mapping(bytes32 => bool) storage isCommissionSellerSets,
        uint256 xUser,
        address _minter,
        address _nFTAddress,
        uint256 _tokenId
    ) public returns (uint256) {
        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(_nFTAddress, _tokenId);

        return
            getCommissionSeller(
                commissionSellers,
                isCommissionSellerSets,
                xUser,
                _categoryId,
                _branchId,
                _collectionId,
                _minter
            );
    }

    function getCommissionBuyerByTokenId(
        mapping(bytes32 => uint256) storage commissionBuyers,
        mapping(bytes32 => bool) storage isCommissionBuyerSets,
        uint256 xBuyer,
        address _minter,
        address _nFTAddress,
        uint256 _tokenId
    ) public returns (uint256) {
        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(_nFTAddress, _tokenId);

        return
            getCommissionBuyer(
                commissionBuyers,
                isCommissionBuyerSets,
                xBuyer,
                _categoryId,
                _branchId,
                _collectionId,
                _minter
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./StructLib.sol";
import "./Commission.sol";

/**
 * @dev Library for signature verification.
 */
library Payment {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    function setFloatingPaymentMethod(
        mapping(string => mapping(address => StructLib.AggregatorV3Path[]))
            storage storageAaggregatorV3Paths,
        mapping(address => bool) storage paymentMethod,
        string calldata _assetName,
        address _paymentToken,
        StructLib.AggregatorV3Path[] calldata _aggregatorV3Paths
    ) public {
        require(paymentMethod[_paymentToken], "Payment-token-not-support");
        delete storageAaggregatorV3Paths[_assetName][_paymentToken];

        for (uint256 i = 0; i < _aggregatorV3Paths.length; i++) {
            require(
                _aggregatorV3Paths[i].aggregatorV3 != address(0),
                "Invalid-address"
            );

            storageAaggregatorV3Paths[_assetName][_paymentToken].push(
                _aggregatorV3Paths[i]
            );
        }
    }

    function calBuyerCommission(
        mapping(bytes32 => uint256) storage commissionBuyers,
        mapping(bytes32 => bool) storage isCommissionBuyerSets,
        uint256 xBuyer,
        address _minter,
        address _nFTAddress,
        uint256 _tokenId,
        uint256 amount,
        uint256 serviceTaxPercentForBuyer,
        uint256 VATPercent
    ) public returns (StructLib.BuyerCommissionOutput memory) {
        require(serviceTaxPercentForBuyer <= 10000, "Invalid tax");

        uint256 commission = Commission.getCommissionBuyerByTokenId(
            commissionBuyers,
            isCommissionBuyerSets,
            xBuyer,
            _minter,
            _nFTAddress,
            _tokenId
        );

        uint256 commissionFromBuyer = (amount * commission) / (10 ** 4);
        uint256 amountToBuyer = amount + commissionFromBuyer;

        uint256 serviceTaxAmount = 0;
        if (serviceTaxPercentForBuyer > 0) {
            serviceTaxAmount =
                (commissionFromBuyer * serviceTaxPercentForBuyer) /
                (10 ** 4);
            amountToBuyer += serviceTaxAmount;
        }

        uint256 VATAmount = 0;
        if (VATPercent > 0) {
            VATAmount = (amountToBuyer * VATPercent) / (10 ** 4);
            amountToBuyer += VATAmount;
        }

        return
            StructLib.BuyerCommissionOutput(
                amountToBuyer,
                commissionFromBuyer,
                0,
                serviceTaxAmount,
                VATAmount
            );
    }

    function calBuyerCommissionHasSign(
        mapping(bytes32 => uint256) storage commissionBuyers,
        mapping(bytes32 => bool) storage isCommissionBuyerSets,
        uint256 xBuyer,
        address _minter,
        address _nFTAddress,
        uint256 _tokenId,
        bool isPercent,
        uint256 amount,
        uint256 promoCodeNft,
        uint256 promoCodeServiceFee,
        uint256 serviceTaxPercentForBuyer,
        uint256 VATPercent
    ) public returns (StructLib.BuyerCommissionOutput memory) {
        require(serviceTaxPercentForBuyer <= 10000, "Invalid tax");

        if (isPercent) {
            require(promoCodeNft <= 10000, "Invalid Nft code");
            require(promoCodeServiceFee <= 10000, "Invalid service code");
        }

        uint256 commission = Commission.getCommissionBuyerByTokenId(
            commissionBuyers,
            isCommissionBuyerSets,
            xBuyer,
            _minter,
            _nFTAddress,
            _tokenId
        );

        uint256 commissionFromBuyer = 0;
        uint256 amountToBuyer = 0;
        uint256 promocodeAmount = 0;

        if (isPercent) {
            uint256 _commissionAmount = (amount * commission) / (10 ** 4);
            uint256 _buyerAmount = (amount * ((10 ** 4) - promoCodeNft)) /
                (10 ** 4);
            commissionFromBuyer =
                (((_commissionAmount * ((10 ** 4) - promoCodeNft)) /
                    (10 ** 4)) * ((10 ** 4) - promoCodeServiceFee)) /
                (10 ** 4);

            amountToBuyer = _buyerAmount + commissionFromBuyer;
            promocodeAmount = _commissionAmount + amount - amountToBuyer;
        } else {
            uint256 _buyerAmount = amount > promoCodeNft
                ? amount - promoCodeNft
                : 0;
            uint256 _commissionAmount = (_buyerAmount * commission) / (10 ** 4);
            commissionFromBuyer = _commissionAmount > promoCodeServiceFee
                ? _commissionAmount - promoCodeServiceFee
                : 0;

            amountToBuyer = _buyerAmount + commissionFromBuyer;
            promocodeAmount = _commissionAmount + amount - amountToBuyer;
        }

        uint256 serviceTaxAmount = 0;
        if (serviceTaxPercentForBuyer > 0) {
            serviceTaxAmount =
                (commissionFromBuyer * serviceTaxPercentForBuyer) /
                (10 ** 4);
            amountToBuyer += serviceTaxAmount;
        }

        uint256 VATAmount = 0;
        if (VATPercent > 0) {
            VATAmount = (amount * VATPercent) / (10 ** 4);
            amountToBuyer += VATAmount;
        }

        return
            StructLib.BuyerCommissionOutput(
                amountToBuyer,
                commissionFromBuyer,
                promocodeAmount,
                serviceTaxAmount,
                VATAmount
            );
    }

    function convertFloatingPrie(
        address paymentToken,
        uint256 orderPrice,
        uint256 premiumPercent,
        StructLib.AggregatorV3Path[] memory _aggregatorV3Paths,
        uint256 RATE_DECIMALS
    ) public view returns (uint256 price, StructLib.PricePath[] memory paths) {
        uint256 tokenDecimals = IERC20MetadataUpgradeable(paymentToken)
            .decimals();

        uint256 rate = 10 ** RATE_DECIMALS;

        uint256 length = _aggregatorV3Paths.length;
        paths = new StructLib.PricePath[](length);
        for (uint256 i = 0; i < length; i++) {
            (uint80 roundId, int256 answer, , , ) = AggregatorV3Interface(
                _aggregatorV3Paths[i].aggregatorV3
            ).latestRoundData();
            paths[i] = StructLib.PricePath(
                _aggregatorV3Paths[i].aggregatorV3,
                _aggregatorV3Paths[i].isReverse,
                roundId
            );

            rate = _aggregatorV3Paths[i].isReverse
                ? (rate *
                    (10 **
                        AggregatorV3Interface(
                            _aggregatorV3Paths[i].aggregatorV3
                        ).decimals())) / uint256(answer)
                : (rate * uint256(answer)) /
                    (10 **
                        AggregatorV3Interface(
                            _aggregatorV3Paths[i].aggregatorV3
                        ).decimals());
        }

        price =
            ((((orderPrice * rate) * (10 ** tokenDecimals)) /
                (10 ** 18) /
                (10 ** RATE_DECIMALS)) * ((10 ** 4) + premiumPercent)) /
            (10 ** 4);
    }

    /**
     * @dev Matching order mechanism
     * @param _buyer is address of buyer
     * @param _paymentToken is payment method (USDT, BNB, ...)
     * @param _price is matched price
     */
    function matchOrder(
        address _buyer,
        address _paymentToken,
        StructLib.Order storage _order,
        uint256 _price,
        uint256 _commissionSellerPercent,
        uint256 _serviceTaxPercentForSeller,
        uint256 _commissionFromBuyer,
        uint256 _serviceTaxAmountForBuyer,
        uint256 _buyerPaidAmount,
        uint256 _VATAmount,
        StructLib.TaxReceiver[] memory _taxReceivers,
        bool _sellerGetVAT,
        address _feeTo,
        address _nFTAddress
    ) public {
        require(_serviceTaxPercentForSeller <= 10000, "Invalid tax");

        _order.commissionToSeller = (_price * _commissionSellerPercent) / 10000;

        uint256 _serviceTaxAmountForSeller = (_order.commissionToSeller *
            _serviceTaxPercentForSeller) / 10000;
        uint256 totalServiceTax = _serviceTaxAmountForBuyer +
            _serviceTaxAmountForSeller;

        uint256 taxToFeeTo = totalServiceTax;
        uint256 totalCommission = _commissionFromBuyer +
            _order.commissionToSeller;
        uint256 commissionToFeeTo = totalCommission;

        StructLib.TaxReceived[]
            memory _taxReceiveds = new StructLib.TaxReceived[](
                _taxReceivers.length
            );

        for (uint256 i = 0; i < _taxReceivers.length; i++) {
            uint256 receiveAmount = (totalCommission *
                _taxReceivers[i].taxPercent) / 10000;
            require(
                receiveAmount <= commissionToFeeTo,
                "Invalid-total-tax-percent"
            );
            commissionToFeeTo -= receiveAmount;

            if (_taxReceivers[i].isGST) {
                uint256 taxToReceiver = (totalServiceTax *
                    _taxReceivers[i].taxPercent) / 10000;
                receiveAmount += taxToReceiver;
                taxToFeeTo -= taxToReceiver;
            }

            _buyerPaidAmount -= receiveAmount;
            _taxReceiveds[i] = StructLib.TaxReceived(
                _taxReceivers[i].receiver,
                receiveAmount
            );
            paid(_paymentToken, _taxReceivers[i].receiver, receiveAmount);
        }

        uint256 amountToFeeTo = taxToFeeTo + commissionToFeeTo;
        if (!_sellerGetVAT) {
            amountToFeeTo += _VATAmount;
        }
        // send payment to feeTo
        paid(_paymentToken, _feeTo, amountToFeeTo);

        uint256 amountToSeller = _buyerPaidAmount - amountToFeeTo;

        // send payment to seller
        paid(_paymentToken, _order.owner, amountToSeller);

        // send nft to buyer
        IERC721Upgradeable(_nFTAddress).transferFrom(
            address(this),
            _buyer,
            _order.tokenId
        );

        _order.taxReceived = _taxReceiveds;
        _order.price = _price;
        _order.isOnsale = false;
        _order.commissionFromBuyer = _commissionFromBuyer;
    }

    function paid(address _token, address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid-address");
        IERC20MetadataUpgradeable(_token).safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./StructLib.sol";

/**
 * @dev Library for signature verification.
 */
library Signature {
    function verifyBuyMessage(
        bytes memory signature,
        uint256 _orderId,
        address _paymentToken,
        bool _isPercent,
        uint256 _promoCodeNft,
        uint256 _promoCodeServiceFee,
        uint256 _taxForBuyerPercent,
        uint256 _taxForSellerPercent,
        StructLib.TaxReceiver[] memory _taxReceivers,
        uint256 _signatureExpTime,
        address _nFTAddress,
        address _verifier
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        if (_signatureExpTime < block.timestamp) return false;
        bytes32 dataHash = encodeBuyData(
            _orderId,
            _nFTAddress,
            _paymentToken,
            _isPercent,
            _promoCodeNft,
            _promoCodeServiceFee,
            _taxForBuyerPercent,
            _taxForSellerPercent,
            _taxReceivers,
            _signatureExpTime
        );
        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == _verifier;
    }

    function encodeBuyData(
        uint256 _orderId,
        address _token,
        address _paymentToken,
        bool _isPercent,
        uint256 _promoCodeNft,
        uint256 _promoCodeServiceFee,
        uint256 _taxForBuyerPercent,
        uint256 _taxForSellerPercent,
        StructLib.TaxReceiver[] memory _taxReceivers,
        uint256 _signatureExpTime
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(
                    id,
                    _orderId,
                    _token,
                    _paymentToken,
                    _isPercent,
                    _promoCodeNft,
                    _promoCodeServiceFee,
                    _taxForBuyerPercent,
                    _taxForSellerPercent,
                    _taxReceivers,
                    _signatureExpTime
                )
            );
    }

    function verifyBidMessage(
        bytes memory signature,
        address _sender,
        address _paymentToken,
        uint256 _orderId,
        uint256 _price,
        uint256 _taxPercent,
        uint256 _signatureExpTime,
        address _nFTAddress,
        address _verifier
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        if (_signatureExpTime < block.timestamp) return false;
        bytes32 dataHash = encodeBidData(
            _sender,
            _nFTAddress,
            _paymentToken,
            _orderId,
            _price,
            _taxPercent,
            _signatureExpTime
        );
        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == _verifier;
    }

    function encodeBidData(
        address _sender,
        address _token,
        address _paymentToken,
        uint256 _orderId,
        uint256 _price,
        uint256 _taxPercent,
        uint256 _signatureExpTime
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(
                    id,
                    _sender,
                    _token,
                    _paymentToken,
                    _orderId,
                    _price,
                    _taxPercent,
                    _signatureExpTime
                )
            );
    }

    function verifyOrderMessage(
        bytes memory signature,
        address _sender,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _buyerGetVAT,
        uint256 _signatureExpTime,
        address _nFTAddress,
        address _verifier
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        if (_signatureExpTime < block.timestamp) return false;
        bytes32 dataHash = encodeOrderData(
            _sender,
            _nFTAddress,
            _paymentToken,
            _tokenId,
            _price,
            _expTime,
            _assetName,
            _premiumPercent,
            _isFloatingPrice,
            _VATPercent,
            _buyerGetVAT,
            _signatureExpTime
        );

        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == _verifier;
    }

    function encodeOrderData(
        address _sender,
        address _token,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _buyerGetVAT,
        uint256 _signatureExpTime
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }

        return
            keccak256(
                abi.encode(
                    id,
                    _sender,
                    _token,
                    _paymentToken,
                    _tokenId,
                    _price,
                    _expTime,
                    _assetName,
                    _premiumPercent,
                    _isFloatingPrice,
                    _VATPercent,
                    _buyerGetVAT,
                    _signatureExpTime
                )
            );
    }

    function verifyUpdateOrderMessage(
        bytes memory signature,
        address _sender,
        address _paymentToken,
        uint256 _orderId,
        uint256 _price,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _buyerGetVAT,
        uint256 _signatureExpTime,
        address _nFTAddress,
        address _verifier
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        if (_signatureExpTime < block.timestamp) return false;
        bytes32 dataHash = encodeUpdateOrderData(
            _sender,
            _paymentToken,
            _orderId,
            _nFTAddress,
            _price,
            _expTime,
            _assetName,
            _premiumPercent,
            _isFloatingPrice,
            _VATPercent,
            _buyerGetVAT,
            _signatureExpTime
        );
        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == _verifier;
    }

    function encodeUpdateOrderData(
        address _sender,
        address _paymentToken,
        uint256 _orderId,
        address _token,
        uint256 _price,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _buyerGetVAT,
        uint256 _signatureExpTime
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(
                    id,
                    _sender,
                    _paymentToken,
                    _orderId,
                    _token,
                    _price,
                    _expTime,
                    _assetName,
                    _premiumPercent,
                    _isFloatingPrice,
                    _VATPercent,
                    _buyerGetVAT,
                    _signatureExpTime
                )
            );
    }

    function verifyAcceptBidMessage(
        bytes memory signature,
        uint256 _bidId,
        uint256 _taxForBuyerPercent,
        uint256 _taxForSellerPercent,
        StructLib.TaxReceiver[] memory _taxReceivers,
        uint256 _signatureExpTime,
        address _nFTAddress,
        address _verifier
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        if (_signatureExpTime < block.timestamp) return false;
        bytes32 dataHash = encodeAcceptBidData(
            _bidId,
            _nFTAddress,
            _taxForBuyerPercent,
            _taxForSellerPercent,
            _taxReceivers,
            _signatureExpTime
        );
        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == _verifier;
    }

    function encodeAcceptBidData(
        uint256 _bidId,
        address _token,
        uint256 _taxForBuyerPercent,
        uint256 _taxForSellerPercent,
        StructLib.TaxReceiver[] memory _taxReceivers,
        uint256 _signatureExpTime
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(
                    id,
                    _bidId,
                    _token,
                    _taxForBuyerPercent,
                    _taxForSellerPercent,
                    _taxReceivers,
                    _signatureExpTime
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StructLib {
    struct Order {
        address owner;
        address paymentToken;
        uint256 tokenId;
        uint256 price; // price of 1 NFT in paymentToken
        uint256 commissionFromBuyer;
        uint256 commissionToSeller;
        uint256 expTime;
        bool isFloatingPrice;
        string assetName;
        PricePath[] pricePathConfirmed;
        uint256 premiumPercent;
        uint256 VATPercent;
        bool sellerGetVAT;
        TaxReceived[] taxReceived;
        bool isOnsale; // true: on sale, false: cancel
    }

    struct Bid {
        address bidder;
        address paymentToken;
        uint256 orderId;
        uint256 bidPrice;
        uint256 commissionFromBuyer;
        uint256 serviceTaxAmount;
        uint256 VATAmount;
        uint256 expTime;
        bool status; // 1: available | 2: done | 3: reject
    }

    struct BuyerCommissionInput {
        address paymentToken;
        uint256 tokenId;
        uint256 amount;
        address minter;
        uint256 VATPercent;
    }

    struct PromoCodeInfo {
        bool isPercent;
        uint256 promoCodeNft;
        uint256 promoCodeServiceFee;
    }

    struct TaxInfo {
        uint256 serviceTaxPercentForSeller;
        uint256 serviceTaxPercentForBuyer;
    }

    struct TaxReceiver {
        address receiver;
        uint256 taxPercent;
        bool isGST;
    }

    struct TaxReceived {
        address receiver;
        uint256 receivedAmount;
    }

    struct BuyerCommissionOutput {
        uint256 amountToBuyer;
        uint256 commissionFromBuyer;
        uint256 promocodeAmount;
        uint256 serviceTaxAmount;
        uint256 VATAmount;
    }

    struct AggregatorV3Path {
        address aggregatorV3;
        bool isReverse;
    }

    struct PricePath {
        address aggregatorV3;
        bool isReverse;
        uint80 roundId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/Payment.sol";
import "./libraries/Commission.sol";
import "./libraries/StructLib.sol";

contract Manager is Initializable, OwnableUpgradeable, PausableUpgradeable {
    // FEE
    uint256 public xUser;
    uint256 public xBuyer;
    uint256 public acceptableFloatingPercent;

    mapping(address => bool) public paymentMethod;
    mapping(address => bool) public isOperator;

    mapping(bytes32 => uint256) internal commissionSellers;
    mapping(bytes32 => bool) internal isCommissionSellerSets;

    mapping(bytes32 => uint256) internal commissionBuyers;
    mapping(bytes32 => bool) internal isCommissionBuyerSets;
    mapping(string => mapping(address => StructLib.AggregatorV3Path[]))
        internal aggregatorV3Paths;

    event SetCommissions(
        uint256[] _categoryIds,
        uint256[] _branchIds,
        uint256[] _collectionIds,
        address[] _minters,
        uint256[] _sellerCommissions,
        uint256[] _buyerCommissions
    );

    event SetSystemFee(uint256 xUser, uint256 xBuyer);
    event FloatingPaymentMethodSet(
        string assetName,
        address paymentToken,
        StructLib.AggregatorV3Path[] aggregatorV3Paths
    );

    function __Manager_init() public onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        xUser = 250; // 2.5%
        xBuyer = 250; // 2.5%
    }

    function whiteListOperator(
        address _operator,
        bool _whitelist
    ) external onlyOwner {
        isOperator[_operator] = _whitelist;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function setSystemFee(uint256 _xUser, uint256 _xBuyer) external onlyOwner {
        xUser = _xUser;
        xBuyer = _xBuyer;
        emit SetSystemFee(_xUser, _xBuyer);
    }

    function setPaymentMethod(address _token, bool _status) external onlyOwner {
        require(_token != address(0), "Invalid-payment-address");
        paymentMethod[_token] = _status;
    }

    /**
     * @dev Function to add floating payment method
     * @param _assetName name of asset to check price
     * @param _paymentToken address of payment token
     * @param _aggregatorV3Paths array of aggregatorV3 to convert asset price to payment token price
     */
    function setFloatingPaymentMethod(
        string calldata _assetName,
        address _paymentToken,
        StructLib.AggregatorV3Path[] calldata _aggregatorV3Paths
    ) external onlyOwner {
        Payment.setFloatingPaymentMethod(
            aggregatorV3Paths,
            paymentMethod,
            _assetName,
            _paymentToken,
            _aggregatorV3Paths
        );

        emit FloatingPaymentMethodSet(
            _assetName,
            _paymentToken,
            aggregatorV3Paths[_assetName][_paymentToken]
        );
    }

    /**
     * @dev function to set acceptable floating percent
     * @param _acceptableFloatingPercent acceptable floating percent
     */
    function setAcceptableFloatingPercent(
        uint256 _acceptableFloatingPercent
    ) external onlyOwner {
        acceptableFloatingPercent = _acceptableFloatingPercent;
    }

    function setCommissions(
        uint256[] memory _categoryIds,
        uint256[] memory _branchIds,
        uint256[] memory _collectionIds,
        address[] memory _minters,
        uint256[] memory _sellerCommissions,
        uint256[] memory _buyerCommissions
    ) external onlyOwner {
        Commission.setCommission(
            commissionSellers,
            isCommissionSellerSets,
            commissionBuyers,
            isCommissionBuyerSets,
            _categoryIds,
            _branchIds,
            _collectionIds,
            _minters,
            _sellerCommissions,
            _buyerCommissions
        );

        emit SetCommissions(
            _categoryIds,
            _branchIds,
            _collectionIds,
            _minters,
            _sellerCommissions,
            _buyerCommissions
        );
    }

    function getCommissionSeller(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        return
            Commission.getCommissionSeller(
                commissionSellers,
                isCommissionSellerSets,
                xUser,
                _categoryId,
                _branchId,
                _collecttionId,
                _minter
            );
    }

    function getCommissionBuyer(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        return
            Commission.getCommissionBuyer(
                commissionBuyers,
                isCommissionBuyerSets,
                xBuyer,
                _categoryId,
                _branchId,
                _collecttionId,
                _minter
            );
    }

    function getAggregatorV3Paths(
        string memory _assetName,
        address _paymentToken
    ) public view returns (StructLib.AggregatorV3Path[] memory) {
        return aggregatorV3Paths[_assetName][_paymentToken];
    }
    
    /**
     * @notice withdrawFunds
     */
    function withdrawFunds(
        address payable _beneficiary,
        address _tokenAddress
    ) external onlyOwner whenPaused {
        if (_tokenAddress == address(0)) {
            _beneficiary.transfer(address(this).balance);
        } else {
            IERC20Upgradeable(_tokenAddress).transfer(
                _beneficiary,
                IERC20Upgradeable(_tokenAddress).balanceOf(address(this))
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Manager.sol";
import "./libraries/Signature.sol";

contract VerdantMarket is Manager, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public nFTAddress;

    address public verifier;
    address public feeTo;
    uint256 private constant ZOOM_FEE = 10 ** 4;
    uint256 public totalOrders;
    uint256 public totalBids;

    uint8 private constant _RATE_DECIMALS = 8;

    mapping(uint256 => StructLib.Order) public orders;
    mapping(uint256 => uint256) private tokenIdToLatestOrderID;
    mapping(uint256 => StructLib.Bid) public bids;
    mapping(bytes32 => bool) private isBid;
    mapping(bytes32 => uint256) private userBidOfToken;

    event OrderCreated(
        uint256 indexed _orderId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 _expTime,
        bool _isFloatingPrice,
        string _assetName,
        uint256 _premiumPercent,
        uint256 _VATPercent,
        bool _sellerGetVAT
    );
    event Buy(
        uint256 _itemId,
        address _paymentToken,
        uint256 _paymentAmount,
        uint256 _promocodeAmount,
        uint256 _serviceTaxAmount
    );
    event OrderCancelled(uint256 indexed _orderId);
    event OrderUpdated(uint256 indexed _orderId);
    event BidCreated(
        uint256 indexed _bidId,
        uint256 indexed _orderId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 _expTime
    );
    event AcceptBid(uint256 indexed _bidId);
    event BidUpdated(uint256 indexed _bidId);
    event BidCancelled(uint256 indexed _bidId);

    /******* GOVERNANCE FUNCTIONS *******/

    function initialize(
        address verifier_,
        address nFTAddress_,
        address feeto_,
        uint256 acceptableFloatingPercent_
    ) public initializer {
        Manager.__Manager_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        verifier = verifier_;
        nFTAddress = nFTAddress_;
        feeTo = feeto_;
        acceptableFloatingPercent = acceptableFloatingPercent_;
    }

    /**
     * @dev Function to set new verifier
     * @param _verifier new verifier address to set
     * Emit VerifierSet event
     */
    function setVerifier(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    /**
     * @dev Function to set new NFT address
     * @param _nFTAddress new verifier address to set
     * Emit NFTAddressSet event
     */
    function setNFTAddress(address _nFTAddress) external onlyOwner {
        nFTAddress = _nFTAddress;
    }

    /******* VIEW FUNCTIONS *******/

    function getOrderFloatingPrice(
        uint256 _orderId
    )
        external
        view
        returns (uint256 price, StructLib.PricePath[] memory paths)
    {
        StructLib.Order memory order = orders[_orderId];

        (price, paths) = _getOrderFloatingPrice(
            order,
            getAggregatorV3Paths(order.assetName, order.paymentToken)
        );
    }

    function _getOrderFloatingPrice(
        StructLib.Order memory order,
        StructLib.AggregatorV3Path[] memory _aggregatorV3Paths
    ) private view returns (uint256 price, StructLib.PricePath[] memory paths) {
        (price, paths) = Payment.convertFloatingPrie(
            order.paymentToken,
            order.price,
            order.premiumPercent,
            _aggregatorV3Paths,
            _RATE_DECIMALS
        );
    }

    /******* INTERNAL FUNCTIONS *******/

    function hashBidMap(
        uint256 _orderId,
        address _bidder
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_orderId, _bidder));
    }

    function getCommissionSellerByTokenId(
        uint256 _tokenId,
        address _buyer
    ) private returns (uint256 _commission) {
        return
            Commission.getCommissionSellerByTokenId(
                commissionSellers,
                isCommissionSellerSets,
                xBuyer,
                _buyer,
                nFTAddress,
                _tokenId
            );
    }

    function calBuyerCommission(
        StructLib.BuyerCommissionInput memory _buyerCommission,
        uint256 _serviceTaxPercentForBuyer
    ) private returns (StructLib.BuyerCommissionOutput memory) {
        return
            Payment.calBuyerCommission(
                commissionBuyers,
                isCommissionBuyerSets,
                xBuyer,
                _buyerCommission.minter,
                nFTAddress,
                _buyerCommission.tokenId,
                _buyerCommission.amount,
                _serviceTaxPercentForBuyer,
                _buyerCommission.VATPercent
            );
    }

    function calBuyerCommissionHasSign(
        StructLib.BuyerCommissionInput memory _buyerCommission,
        StructLib.PromoCodeInfo memory _promoCodeInfo,
        uint256 _serviceTaxPercentForBuyer
    ) private returns (StructLib.BuyerCommissionOutput memory) {
        return
            Payment.calBuyerCommissionHasSign(
                commissionBuyers,
                isCommissionBuyerSets,
                xBuyer,
                _buyerCommission.minter,
                nFTAddress,
                _buyerCommission.tokenId,
                _promoCodeInfo.isPercent,
                _buyerCommission.amount,
                _promoCodeInfo.promoCodeNft,
                _promoCodeInfo.promoCodeServiceFee,
                _serviceTaxPercentForBuyer,
                _buyerCommission.VATPercent
            );
    }

    /******* MUTATIVE FUNCTIONS *******/

    /**
     * @dev Allow user create order on market
     * @param _tokenId is id of NFTs
     * @param _price is price per item in payment method (example 50 USDT)
     * @param _paymentToken is payment method (USDT, BNB, ...)
     */
    function createOrder(
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _price, // price of 1 nft
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _sellerGetVAT,
        uint256 _signatureExpTime,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant returns (uint256 _orderId) {
        require(
            Signature.verifyOrderMessage(
                _signature,
                msg.sender,
                _paymentToken,
                _tokenId,
                _price,
                _expTime,
                _assetName,
                _premiumPercent,
                _isFloatingPrice,
                _VATPercent,
                _sellerGetVAT,
                _signatureExpTime,
                nFTAddress,
                verifier
            ),
            "Invalid signature"
        );
        require(
            paymentMethod[_paymentToken] &&
                (!_isFloatingPrice ||
                    (_isFloatingPrice &&
                        aggregatorV3Paths[_assetName][_paymentToken].length >
                        0)),
            "Payment-method-not-support"
        );

        require(
            _expTime > block.timestamp || _expTime == 0,
            "Invalid-expired-time"
        );

        IERC721Upgradeable(nFTAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        StructLib.Order memory newOrder;
        newOrder.isOnsale = true;
        newOrder.owner = msg.sender;
        newOrder.price = _price;
        newOrder.tokenId = _tokenId;
        newOrder.paymentToken = _paymentToken;
        newOrder.expTime = _expTime;
        newOrder.VATPercent = _VATPercent;
        newOrder.sellerGetVAT = _sellerGetVAT;

        if (_isFloatingPrice) {
            require(_premiumPercent < ZOOM_FEE, "Invalid-premium-percent");

            newOrder.isFloatingPrice = _isFloatingPrice;
            newOrder.assetName = _assetName;
            newOrder.premiumPercent = _premiumPercent;
        }

        orders[totalOrders] = newOrder;
        _orderId = totalOrders;
        totalOrders++;

        tokenIdToLatestOrderID[_tokenId] = _orderId;

        emit OrderCreated(
            _orderId,
            _tokenId,
            _price,
            _paymentToken,
            _expTime,
            _isFloatingPrice,
            _assetName,
            _premiumPercent,
            _VATPercent,
            _sellerGetVAT
        );
        return _orderId;
    }

    function buy(
        uint256 _orderId,
        address _paymentToken,
        uint256 _priceDesired,
        StructLib.PromoCodeInfo memory _promoCodeInfo,
        StructLib.TaxInfo memory _taxInfo,
        StructLib.TaxReceiver[] memory _taxReceivers,
        uint256 _signatureExpTime,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        StructLib.Order memory order = orders[_orderId];
        require(order.owner != address(0), "Invalid-order-id");
        require(
            _paymentToken == order.paymentToken,
            "Payment-method-not-support"
        );
        require(order.isOnsale, "Not-on-sale");
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        uint256 orderTokenPrice = order.price;

        if (order.isFloatingPrice) {
            (
                orderTokenPrice,
                orders[_orderId].pricePathConfirmed
            ) = _getOrderFloatingPrice(
                order,
                aggregatorV3Paths[order.assetName][_paymentToken]
            );
        }

        require(
            Signature.verifyBuyMessage(
                _signature,
                _orderId,
                _paymentToken,
                _promoCodeInfo.isPercent,
                _promoCodeInfo.promoCodeNft,
                _promoCodeInfo.promoCodeServiceFee,
                _taxInfo.serviceTaxPercentForBuyer,
                _taxInfo.serviceTaxPercentForSeller,
                _taxReceivers,
                _signatureExpTime,
                nFTAddress,
                verifier
            ),
            "Invalid signature"
        );

        StructLib.BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommissionHasSign(
                StructLib.BuyerCommissionInput(
                    _paymentToken,
                    order.tokenId,
                    orderTokenPrice,
                    msg.sender,
                    order.VATPercent
                ),
                _promoCodeInfo,
                _taxInfo.serviceTaxPercentForBuyer
            );

        require(
            _buyerCommissionOutput.amountToBuyer <=
                (_priceDesired * (ZOOM_FEE + acceptableFloatingPercent)) /
                    ZOOM_FEE,
            "Price desired exceeds"
        );

        bytes32 _id = hashBidMap(_orderId, msg.sender);

        bool isUserBid = isBid[_id];

        if (isUserBid) {
            uint256 bidId = userBidOfToken[_id];
            StructLib.Bid memory bid = bids[bidId];
            if (bid.paymentToken == _paymentToken) {
                uint256 buyerPaidAmount = bid.bidPrice +
                    bid.serviceTaxAmount +
                    bid.commissionFromBuyer;
                if (buyerPaidAmount > _buyerCommissionOutput.amountToBuyer) {
                    Payment.paid(
                        _paymentToken,
                        msg.sender,
                        buyerPaidAmount - _buyerCommissionOutput.amountToBuyer
                    );
                } else {
                    IERC20Upgradeable(_paymentToken).safeTransferFrom(
                        msg.sender,
                        address(this),
                        _buyerCommissionOutput.amountToBuyer - buyerPaidAmount
                    );
                }
                bid.status = false;
                bids[bidId] = bid;
                isBid[_id] = false;
                emit BidCancelled(bidId);
            } else {
                isUserBid = false;
            }
        }

        if (!isUserBid) {
            IERC20Upgradeable(_paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _buyerCommissionOutput.amountToBuyer
            );
        }

        uint256 _amountToSeller = _buyerCommissionOutput.amountToBuyer <
            orderTokenPrice
            ? _buyerCommissionOutput.amountToBuyer
            : orderTokenPrice;

        Payment.matchOrder(
            msg.sender,
            _paymentToken,
            orders[_orderId],
            _amountToSeller,
            getCommissionSellerByTokenId(order.tokenId, msg.sender),
            _taxInfo.serviceTaxPercentForSeller,
            _buyerCommissionOutput.commissionFromBuyer,
            _buyerCommissionOutput.serviceTaxAmount,
            _buyerCommissionOutput.amountToBuyer,
            _buyerCommissionOutput.VATAmount,
            _taxReceivers,
            order.sellerGetVAT,
            feeTo,
            nFTAddress
        );

        emit Buy(
            _orderId,
            _paymentToken,
            _buyerCommissionOutput.amountToBuyer,
            _buyerCommissionOutput.promocodeAmount,
            _buyerCommissionOutput.serviceTaxAmount
        );
    }

    function createBid(
        address _paymentToken, // payment method
        uint256 _orderId,
        uint256 _price, // price of 1 nft
        uint256 _serviceTaxPercentForBuyer,
        uint256 _expTime,
        uint256 _signatureExpTime,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant returns (uint256 _bidId) {
        bytes32 _id = hashBidMap(_orderId, msg.sender);
        require(!isBid[_id], "User-has-bid");
        require(paymentMethod[_paymentToken], "Payment-method-not-support");
        require(
            _expTime > block.timestamp || _expTime == 0,
            "Invalid-expired-time"
        );

        StructLib.Order memory order = orders[_orderId];
        require(order.isOnsale, "Not-on-sale");

        require(
            Signature.verifyBidMessage(
                _signature,
                msg.sender,
                _paymentToken,
                _orderId,
                _price,
                _serviceTaxPercentForBuyer,
                _signatureExpTime,
                nFTAddress,
                verifier
            ),
            "Invalid signature"
        );

        StructLib.Bid memory newBid;
        newBid.bidder = msg.sender;
        newBid.bidPrice = _price;
        newBid.orderId = _orderId;

        StructLib.BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommission(
                StructLib.BuyerCommissionInput(
                    _paymentToken,
                    order.tokenId,
                    _price,
                    msg.sender,
                    order.VATPercent
                ),
                _serviceTaxPercentForBuyer
            );

        newBid.paymentToken = _paymentToken;
        IERC20Upgradeable(newBid.paymentToken).safeTransferFrom(
            msg.sender,
            address(this),
            _buyerCommissionOutput.amountToBuyer
        );

        newBid.serviceTaxAmount = _buyerCommissionOutput.serviceTaxAmount;
        newBid.VATAmount = _buyerCommissionOutput.VATAmount;
        newBid.commissionFromBuyer = _buyerCommissionOutput.commissionFromBuyer;
        newBid.status = true;
        newBid.expTime = _expTime;
        bids[totalBids] = newBid;
        _bidId = totalBids;
        totalBids++;

        isBid[_id] = true;
        userBidOfToken[_id] = _bidId;
        emit BidCreated(
            _bidId,
            _orderId,
            order.tokenId,
            _buyerCommissionOutput.amountToBuyer,
            newBid.paymentToken,
            _expTime
        );
        return _bidId;
    }

    function acceptBid(
        uint256 _bidId,
        StructLib.TaxInfo memory _taxInfo,
        StructLib.TaxReceiver[] memory _taxReceivers,
        uint256 _signatureExpTime,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        StructLib.Bid memory bid = bids[_bidId];
        require(bid.status, "Bid-cancelled");
        require(
            bid.expTime > block.timestamp || bid.expTime == 0,
            "Bid-expired"
        );

        require(
            Signature.verifyAcceptBidMessage(
                _signature,
                _bidId,
                _taxInfo.serviceTaxPercentForBuyer,
                _taxInfo.serviceTaxPercentForSeller,
                _taxReceivers,
                _signatureExpTime,
                nFTAddress,
                verifier
            ),
            "Invalid signature"
        );

        StructLib.Order memory order = orders[bid.orderId];
        require(
            (order.owner == msg.sender ||
                (order.isFloatingPrice && isOperator[msg.sender])) &&
                order.isOnsale,
            "Not-owner/operator-or-cancelled"
        );
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        if (order.isFloatingPrice && isOperator[msg.sender]) {
            require(
                order.paymentToken == bid.paymentToken,
                "Invalid-payment-method"
            );
            (uint256 orderTokenPrice, ) = _getOrderFloatingPrice(
                order,
                aggregatorV3Paths[order.assetName][bid.paymentToken]
            );

            require(
                bid.bidPrice >=
                    (orderTokenPrice * (ZOOM_FEE - acceptableFloatingPercent)) /
                        ZOOM_FEE,
                "Invalid-bid-price"
            );
        }

        uint256 buyerPaidAmount = bid.bidPrice +
            bid.commissionFromBuyer +
            bid.serviceTaxAmount;
        StructLib.BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommission(
                StructLib.BuyerCommissionInput(
                    bid.paymentToken,
                    order.tokenId,
                    bid.bidPrice,
                    msg.sender,
                    order.VATPercent
                ),
                _taxInfo.serviceTaxPercentForBuyer
            );

        bid.status = false;
        bid.commissionFromBuyer = _buyerCommissionOutput.commissionFromBuyer;
        bid.serviceTaxAmount = _buyerCommissionOutput.serviceTaxAmount;

        bids[_bidId] = bid;

        isBid[hashBidMap(bid.orderId, bid.bidder)] = false;

        Payment.matchOrder(
            bid.bidder,
            bid.paymentToken,
            orders[bid.orderId],
            bid.bidPrice,
            getCommissionSellerByTokenId(order.tokenId, bid.bidder),
            _taxInfo.serviceTaxPercentForSeller,
            bid.commissionFromBuyer,
            bid.serviceTaxAmount,
            buyerPaidAmount,
            bid.VATAmount,
            _taxReceivers,
            order.sellerGetVAT,
            feeTo,
            nFTAddress
        );

        emit AcceptBid(_bidId);
    }

    function cancelOrder(uint256 _orderId) external whenNotPaused nonReentrant {
        StructLib.Order memory order = orders[_orderId];
        require(
            (order.owner == msg.sender || isOperator[msg.sender]) &&
                order.isOnsale,
            "Not-owner/operator-or-cancelled"
        );
        IERC721Upgradeable(nFTAddress).transferFrom(
            address(this),
            order.owner,
            order.tokenId
        );

        order.isOnsale = false;
        orders[_orderId] = order;
        emit OrderCancelled(_orderId);
    }

    function cancelBid(uint256 _bidId) external whenNotPaused nonReentrant {
        StructLib.Bid memory bid = bids[_bidId];
        require(
            bid.bidder == msg.sender || isOperator[msg.sender],
            "Only-bidder-operator"
        );
        require(bid.status, "Bid-cancelled");

        IERC20Upgradeable(bid.paymentToken).safeTransfer(
            bid.bidder,
            bid.bidPrice +
                bid.commissionFromBuyer +
                bid.serviceTaxAmount +
                bid.VATAmount
        );

        bid.status = false;
        bids[_bidId] = bid;

        isBid[hashBidMap(bid.orderId, bid.bidder)] = false;

        emit BidCancelled(_bidId);
    }

    function updateOrder(
        uint256 _orderId,
        address _paymentToken,
        uint256 _price,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _sellerGetVAT,
        uint256 _signatureExpTime,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        StructLib.Order memory order = orders[_orderId];
        require(
            Signature.verifyUpdateOrderMessage(
                _signature,
                msg.sender,
                _paymentToken,
                _orderId,
                _price,
                _expTime,
                _assetName,
                _premiumPercent,
                _isFloatingPrice,
                _VATPercent,
                _sellerGetVAT,
                _signatureExpTime,
                nFTAddress,
                verifier
            ),
            "Invalid signature"
        );

        require(
            order.owner == msg.sender && order.isOnsale,
            "Not-owner-or-cancelled"
        );
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );
        require(
            paymentMethod[_paymentToken] &&
                (!_isFloatingPrice ||
                    (_isFloatingPrice &&
                        aggregatorV3Paths[_assetName][_paymentToken].length >
                        0)),
            "Payment-method-not-support"
        );

        require(
            _expTime > block.timestamp || _expTime == 0,
            "Invalid-expired-time"
        );

        order.paymentToken = _paymentToken;
        order.expTime = _expTime;
        order.price = _price;
        order.VATPercent = _VATPercent;
        order.sellerGetVAT = _sellerGetVAT;
        if (_isFloatingPrice) {
            require(_premiumPercent < ZOOM_FEE, "Invalid-premium-percent");

            order.assetName = _assetName;
            order.premiumPercent = _premiumPercent;
            order.isFloatingPrice = _isFloatingPrice;
        }

        orders[_orderId] = order;
        emit OrderUpdated(_orderId);
    }

    function updateBid(
        uint256 _bidId,
        uint256 _bidPrice,
        uint256 _serviceTaxPercentForBuyer,
        uint256 _expTime,
        uint256 _signatureExpTime,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        StructLib.Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid-bidder");
        require(bid.status, "Bid-cancelled");
        require(
            bid.expTime > block.timestamp || bid.expTime == 0,
            "Bid-expired"
        );
        require(
            _expTime > block.timestamp || _expTime == 0,
            "Invalid-expired-time"
        );
        bid.expTime = _expTime;
        StructLib.Order memory order = orders[bid.orderId];
        if (bid.bidPrice != _bidPrice) {
            require(
                Signature.verifyBidMessage(
                    _signature,
                    msg.sender,
                    bid.paymentToken,
                    bid.orderId,
                    _bidPrice,
                    _serviceTaxPercentForBuyer,
                    _signatureExpTime,
                    nFTAddress,
                    verifier
                ),
                "Invalid signature"
            );

            StructLib.BuyerCommissionOutput
                memory _buyerCommissionOutput = calBuyerCommission(
                    StructLib.BuyerCommissionInput(
                        bid.paymentToken,
                        order.tokenId,
                        _bidPrice,
                        msg.sender,
                        order.VATPercent
                    ),
                    _serviceTaxPercentForBuyer
                );
            uint256 _amountToBuyerOld = bid.bidPrice +
                bid.commissionFromBuyer +
                bid.serviceTaxAmount;

            bool isExcess = _amountToBuyerOld >
                _buyerCommissionOutput.amountToBuyer;
            uint256 amount = isExcess
                ? _amountToBuyerOld - _buyerCommissionOutput.amountToBuyer
                : _buyerCommissionOutput.amountToBuyer - _amountToBuyerOld;

            if (isExcess) {
                IERC20Upgradeable(bid.paymentToken).safeTransfer(
                    bid.bidder,
                    amount
                );
            } else {
                IERC20Upgradeable(bid.paymentToken).safeTransferFrom(
                    bid.bidder,
                    address(this),
                    amount
                );
            }

            bid.bidPrice = _bidPrice;
            bid.commissionFromBuyer = _buyerCommissionOutput
                .commissionFromBuyer;
            bid.serviceTaxAmount = _buyerCommissionOutput.serviceTaxAmount;
            bid.VATAmount = _buyerCommissionOutput.VATAmount;
        }

        bids[_bidId] = bid;
        emit BidUpdated(_bidId);
    }
}