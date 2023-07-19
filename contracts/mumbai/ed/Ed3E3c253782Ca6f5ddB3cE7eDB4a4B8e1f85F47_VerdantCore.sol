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
pragma solidity ^0.8.18;

import "../libraries/StructLib.sol";

interface IVerdantCore {
    event OrderCreated(
        uint256 indexed _orderId,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _sellerDiscountPercent,
        address _paymentToken,
        uint256 _expTime,
        bool _isFloatingPrice,
        string _assetName,
        uint256 _premiumPercent,
        uint256 _VATPercent,
        bool _sellerGetVAT
    );
    event Buy(
        uint256 _orderId,
        uint256 _promocodeAmount,
        StructLib.PaymentData data
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
    event AcceptBid(uint256 indexed _bidId, StructLib.PaymentData data);
    event BidUpdated(uint256 indexed _bidId);
    event BidCancelled(uint256 indexed _bidId);

    function totalOrders() external returns (uint256);

    function totalBids() external returns (uint256);

    function orders(uint256) external returns (StructLib.Order calldata);

    function bids(uint256) external returns (StructLib.Bid memory);

    function getOrderFloatingPrice(
        uint256 _orderId
    ) external returns (uint256 price, StructLib.PricePath[] memory paths);

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
        uint256 _sellerDiscountPercent,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _sellerGetVAT,
        address _sender
    ) external returns (uint256 _orderId);

    function buy(
        uint256 _orderId,
        address _paymentToken,
        uint256 _priceDesired,
        StructLib.PromoCodeInfo memory _promoCodeInfo,
        StructLib.TaxInfo memory _taxInfo,
        StructLib.TaxReceiver[] memory _taxReceivers,
        address _sender
    ) external;

    function createBid(
        address _paymentToken, // payment method
        uint256 _orderId,
        uint256 _price, // price of 1 nft
        uint256 _serviceTaxPercentBuyer,
        uint256 _expTime,
        address _sender
    ) external returns (uint256 _bidId);

    function acceptBid(
        uint256 _bidId,
        StructLib.TaxInfo memory _taxInfo,
        StructLib.TaxReceiver[] memory _taxReceivers,
        address _sender
    ) external;

    function cancelOrder(uint256 _orderId, address _sender) external;

    function cancelBid(uint256 _bidId, address _sender) external;

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
        address _sender
    ) external;

    function updateBid(
        uint256 _bidId,
        uint256 _bidPrice,
        uint256 _serviceTaxPercentBuyer,
        uint256 _expTime,
        address _sender
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../libraries/StructLib.sol";

interface IVerdantManager {
    event SetCommissions(
        uint256[],
        uint256[],
        uint256[],
        address[],
        uint256[],
        uint256[]
    );
    event SetSystemFee(uint256, uint256);
    event FloatingPaymentMethodSet(
        string,
        address,
        StructLib.AggregatorV3Path[]
    );

    function nFTAddress() external returns (address);

    function verifier() external returns (address);

    function feeTo() external returns (address);

    function xUser() external returns (uint256);

    function xBuyer() external returns (uint256);

    function acceptableFloatingPercent() external returns (uint256);

    function paymentMethod(address) external returns (bool);

    function isOperator(address) external returns (bool);

    function whiteListOperator(address, bool) external;

    function pause() external;

    function unPause() external;

    function setSystemFee(uint256, uint256) external;

    function setPaymentMethod(address, bool) external;

    function setFloatingPaymentMethod(
        string calldata _assetName,
        address _paymentToken,
        StructLib.AggregatorV3Path[] calldata _aggregatorV3Paths
    ) external;

    function setAcceptableFloatingPercent(uint256) external;

    function setCommissions(
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        address[] memory,
        uint256[] memory,
        uint256[] memory
    ) external;

    function setVerifier(address) external;

    function setFeeTo(address) external;

    function setNFTAddress(address) external;

    function mapConfigId(
        uint256,
        uint256,
        uint256,
        address
    ) external pure returns (bytes32);

    function getCommissionSeller(
        uint256,
        uint256,
        uint256,
        address
    ) external view returns (uint256);

    function getCommissionBuyer(
        uint256,
        uint256,
        uint256,
        address
    ) external view returns (uint256);

    function getCommissionSellerByTokenId(
        address _minter,
        uint256 _tokenId
    ) external returns (uint256);

    function getCommissionBuyerByTokenId(
        address _minter,
        uint256 _tokenId
    ) external returns (uint256);

    function getAggregatorV3Paths(
        string memory,
        address
    ) external view returns (StructLib.AggregatorV3Path[] memory);

    function withdrawFunds(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error EZeroAddress();

error EInvalidPremiumPercent();

error EInvalidPaymentMethod();

error EInvalidExpiredTime();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./StructLib.sol";

/**
 * @dev Library for signature verification.
 */
library Payment {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    function calBuyerCommission(
        uint256 commissionBuyerPercent,
        uint256 amount,
        uint256 serviceTaxPercentBuyer,
        uint256 VATPercent
    ) public pure returns (StructLib.BuyerCommissionOutput memory) {
        require(serviceTaxPercentBuyer <= 10 ** 4, "Invalid tax");

        uint256 commissionBuyer = (amount * commissionBuyerPercent) / (10 ** 4);
        uint256 amountToBuyer = amount + commissionBuyer;

        uint256 serviceTaxAmount = 0;
        if (serviceTaxPercentBuyer > 0) {
            serviceTaxAmount = (amount * serviceTaxPercentBuyer) / (10 ** 4);
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
                commissionBuyer,
                0,
                serviceTaxAmount,
                VATAmount
            );
    }

    function calBuyerCommissionHasSign(
        uint256 commissionBuyerPercent,
        bool isPercent,
        uint256 amount,
        uint256 promoCodeNft,
        uint256 promoCodeServiceFee,
        uint256 serviceTaxPercentBuyer,
        uint256 VATPercent
    ) public pure returns (StructLib.BuyerCommissionOutput memory) {
        require(serviceTaxPercentBuyer <= 10 ** 4, "Invalid tax");

        if (isPercent) {
            require(promoCodeNft <= 10 ** 4, "Invalid Nft code");
            require(promoCodeServiceFee <= 10 ** 4, "Invalid service code");
        }

        uint256 commissionBuyer = 0;
        uint256 amountToBuyer = 0;
        uint256 promocodeAmount = 0;

        if (isPercent) {
            uint256 _commissionAmount = (amount * commissionBuyerPercent) /
                (10 ** 4);
            uint256 _buyerAmount = (amount * ((10 ** 4) - promoCodeNft)) /
                (10 ** 4);
            commissionBuyer =
                (((_commissionAmount * ((10 ** 4) - promoCodeNft)) /
                    (10 ** 4)) * ((10 ** 4) - promoCodeServiceFee)) /
                (10 ** 4);

            amountToBuyer = _buyerAmount + commissionBuyer;
            promocodeAmount = _commissionAmount + amount - amountToBuyer;
        } else {
            uint256 _buyerAmount = amount > promoCodeNft
                ? amount - promoCodeNft
                : 0;
            uint256 _commissionAmount = (_buyerAmount *
                commissionBuyerPercent) / (10 ** 4);
            commissionBuyer = _commissionAmount > promoCodeServiceFee
                ? _commissionAmount - promoCodeServiceFee
                : 0;

            amountToBuyer = _buyerAmount + commissionBuyer;
            promocodeAmount = _commissionAmount + amount - amountToBuyer;
        }

        uint256 serviceTaxAmount = 0;
        if (serviceTaxPercentBuyer > 0) {
            serviceTaxAmount = (amount * serviceTaxPercentBuyer) / (10 ** 4);
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
                commissionBuyer,
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
        StructLib.MatchOrderFeeData memory _matchOrderFeeData,
        StructLib.TaxReceiver[] memory _taxReceivers,
        address _feeTo,
        address _nFTAddress
    ) public returns (uint256 taxToFeeTo, uint256 commissionToFeeTo) {
        require(
            _matchOrderFeeData.serviceTaxPercentSeller <= 10 ** 4,
            "Invalid tax"
        );

        _order.commissionSeller =
            (((_price * _matchOrderFeeData.commissionSellerPercent) / 10 ** 4) *
                (10 ** 4 - _matchOrderFeeData.sellerDiscountPercent)) /
            10 ** 4;

        uint256 _serviceTaxAmountSeller = (((_price *
            _matchOrderFeeData.serviceTaxPercentSeller) / 10 ** 4) *
            (10 ** 4 - _matchOrderFeeData.sellerDiscountPercent)) / 10 ** 4;

        _order.serviceTaxSeller = _serviceTaxAmountSeller;
        _order.serviceTaxBuyer = _matchOrderFeeData.serviceTaxAmountBuyer;
        uint256 totalServiceTax = _matchOrderFeeData.serviceTaxAmountBuyer +
            _serviceTaxAmountSeller;

        taxToFeeTo = totalServiceTax;
        uint256 totalCommission = _matchOrderFeeData.commissionBuyer +
            _order.commissionSeller;
        commissionToFeeTo = totalCommission;

        StructLib.TaxReceived[]
            memory _taxReceiveds = new StructLib.TaxReceived[](
                _taxReceivers.length
            );

        for (uint256 i = 0; i < _taxReceivers.length; i++) {
            _taxReceiveds[i] = StructLib.TaxReceived(
                _taxReceivers[i].receiver,
                0,
                0
            );

            _taxReceiveds[i].commissionReceivedAmount =
                (totalCommission * _taxReceivers[i].taxPercent) /
                10 ** 4;
            require(
                _taxReceiveds[i].commissionReceivedAmount <= commissionToFeeTo,
                "Invalid-total-tax-percent"
            );
            commissionToFeeTo -= _taxReceiveds[i].commissionReceivedAmount;

            if (_taxReceivers[i].isGST) {
                uint256 taxToReceiver = (totalServiceTax *
                    _taxReceivers[i].taxPercent) / 10 ** 4;
                _taxReceiveds[i].serviceTaxReceivedAmount += taxToReceiver;
                taxToFeeTo -= taxToReceiver;
            }

            paid(
                _paymentToken,
                _taxReceivers[i].receiver,
                _taxReceiveds[i].commissionReceivedAmount +
                    _taxReceiveds[i].serviceTaxReceivedAmount
            );
        }

        uint256 amountToFeeTo = taxToFeeTo + commissionToFeeTo;
        uint256 amountToSeller = _matchOrderFeeData.buyerPaidAmount -
            totalServiceTax -
            totalCommission;

        if (!_matchOrderFeeData.sellerGetVAT) {
            amountToFeeTo += _matchOrderFeeData.VATAmount;
            amountToSeller -= _matchOrderFeeData.VATAmount;
        }
        // send payment to feeTo
        paid(_paymentToken, _feeTo, amountToFeeTo);

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
        _order.commissionBuyer = _matchOrderFeeData.commissionBuyer;
    }

    function paid(address _token, address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid-address");
        IERC20MetadataUpgradeable(_token).safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library StructLib {
    struct Order {
        address owner;
        address paymentToken;
        uint256 tokenId;
        uint256 price; // price of 1 NFT in paymentToken
        uint256 sellerDiscountPercent;
        uint256 commissionBuyer;
        uint256 commissionSeller;
        uint256 serviceTaxBuyer;
        uint256 serviceTaxSeller;
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
        uint256 commissionBuyer;
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
        uint256 serviceTaxPercentSeller;
        uint256 serviceTaxPercentBuyer;
    }

    struct TaxReceiver {
        address receiver;
        uint256 taxPercent;
        bool isGST;
    }

    struct TaxReceived {
        address receiver;
        uint256 commissionReceivedAmount;
        uint256 serviceTaxReceivedAmount;
    }

    struct BuyerCommissionOutput {
        uint256 amountToBuyer;
        uint256 commissionBuyer;
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

    struct PaymentData {
        address paymentToken;
        uint256 price;
        TaxReceived[] taxReceived;
        uint256 verdantCommissionReceived;
        uint256 verdantServiceTaxReceived;
    }

    struct MatchOrderFeeData {
        uint256 commissionSellerPercent;
        uint256 serviceTaxPercentSeller;
        uint256 sellerDiscountPercent;
        uint256 commissionBuyer;
        uint256 serviceTaxAmountBuyer;
        uint256 buyerPaidAmount;
        uint256 VATAmount;
        bool sellerGetVAT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IVerdantCore.sol";
import "../interfaces/IVerdantManager.sol";
import "../libraries/Payment.sol";

import {EInvalidPremiumPercent, EZeroAddress, EInvalidPaymentMethod, EInvalidExpiredTime} from "../libraries/Error.sol";

contract VerdantCore is
    IVerdantCore,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    address public verdantRouter;
    IVerdantManager public verdantManager;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant ZOOM_FEE = 10 ** 4;
    uint256 public totalOrders;
    uint256 public totalBids;

    uint8 private constant _RATE_DECIMALS = 8;

    mapping(uint256 => StructLib.Order) private _orders;
    mapping(uint256 => uint256) private tokenIdToLatestOrderID;
    mapping(uint256 => StructLib.Bid) public _bids;
    mapping(bytes32 => bool) private isBid;
    mapping(bytes32 => uint256) private userBidOfToken;

    /******* GOVERNANCE FUNCTIONS *******/

    function initialize(
        address _verdantRouter,
        address _verdantManager
    ) public initializer {
        verdantRouter = _verdantRouter;
        verdantManager = IVerdantManager(_verdantManager);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
    }

    function setVerdantRouter(address _verdantRouter) external onlyOwner {
        if (_verdantRouter == address(0)) {
            revert EZeroAddress();
        }
        verdantRouter = _verdantRouter;
    }

    function setVerdantManager(address _verdantManager) external onlyOwner {
        if (_verdantManager == address(0)) {
            revert EZeroAddress();
        }
        verdantManager = IVerdantManager(_verdantManager);
    }

    /******* MODIFIERS *******/

    modifier onlyVerdantRouter() {
        require(msg.sender == verdantRouter, "Only VerdantRouter");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Only owner");
        _;
    }

    /******* VIEW FUNCTIONS *******/

    function orders(
        uint256 _orderId
    ) public view returns (StructLib.Order memory) {
        return _orders[_orderId];
    }

    function bids(uint256 _bidId) public view returns (StructLib.Bid memory) {
        return _bids[_bidId];
    }

    function getOrderFloatingPrice(
        uint256 _orderId
    )
        external
        view
        returns (uint256 price, StructLib.PricePath[] memory paths)
    {
        StructLib.Order memory order = _orders[_orderId];

        (price, paths) = _getOrderFloatingPrice(
            order,
            verdantManager.getAggregatorV3Paths(
                order.assetName,
                order.paymentToken
            )
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

    function owner() public view returns (address) {
        return OwnableUpgradeable(address(verdantManager)).owner();
    }

    /******* INTERNAL FUNCTIONS *******/

    function hashBidMap(
        uint256 _orderId,
        address _bidder
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_orderId, _bidder));
    }

    function calBuyerCommission(
        StructLib.BuyerCommissionInput memory _buyerCommission,
        uint256 _serviceTaxPercentBuyer
    ) private returns (StructLib.BuyerCommissionOutput memory) {
        return
            Payment.calBuyerCommission(
                verdantManager.getCommissionBuyerByTokenId(
                    _buyerCommission.minter,
                    _buyerCommission.tokenId
                ),
                _buyerCommission.amount,
                _serviceTaxPercentBuyer,
                _buyerCommission.VATPercent
            );
    }

    function calBuyerCommissionHasSign(
        StructLib.BuyerCommissionInput memory _buyerCommission,
        StructLib.PromoCodeInfo memory _promoCodeInfo,
        uint256 _serviceTaxPercentBuyer
    ) private returns (StructLib.BuyerCommissionOutput memory) {
        return
            Payment.calBuyerCommissionHasSign(
                verdantManager.getCommissionBuyerByTokenId(
                    _buyerCommission.minter,
                    _buyerCommission.tokenId
                ),
                _promoCodeInfo.isPercent,
                _buyerCommission.amount,
                _promoCodeInfo.promoCodeNft,
                _promoCodeInfo.promoCodeServiceFee,
                _serviceTaxPercentBuyer,
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
        uint256 _sellerDiscountPercent,
        uint256 _expTime,
        string memory _assetName,
        uint256 _premiumPercent,
        bool _isFloatingPrice,
        uint256 _VATPercent,
        bool _sellerGetVAT,
        address _sender
    )
        external
        onlyVerdantRouter
        whenNotPaused
        nonReentrant
        returns (uint256 _orderId)
    {
        if (
            !(verdantManager.paymentMethod(_paymentToken) &&
                (!_isFloatingPrice ||
                    (_isFloatingPrice &&
                        verdantManager
                            .getAggregatorV3Paths(_assetName, _paymentToken)
                            .length >
                        0)))
        ) {
            revert EInvalidPaymentMethod();
        }

        if (!(_expTime > block.timestamp || _expTime == 0)) {
            revert EInvalidExpiredTime();
        }

        IERC721Upgradeable(verdantManager.nFTAddress()).transferFrom(
            _sender,
            address(this),
            _tokenId
        );

        StructLib.Order memory newOrder;
        newOrder.isOnsale = true;
        newOrder.owner = _sender;
        newOrder.price = _price;
        newOrder.sellerDiscountPercent = _sellerDiscountPercent;
        newOrder.tokenId = _tokenId;
        newOrder.paymentToken = _paymentToken;
        newOrder.expTime = _expTime;
        newOrder.VATPercent = _VATPercent;
        newOrder.sellerGetVAT = _sellerGetVAT;

        if (_isFloatingPrice) {
            if (_premiumPercent > ZOOM_FEE) {
                revert EInvalidPremiumPercent();
            }

            newOrder.isFloatingPrice = _isFloatingPrice;
            newOrder.assetName = _assetName;
            newOrder.premiumPercent = _premiumPercent;
        }

        _orders[totalOrders] = newOrder;
        _orderId = totalOrders;
        totalOrders++;

        tokenIdToLatestOrderID[_tokenId] = _orderId;

        emit OrderCreated(
            _orderId,
            _tokenId,
            _price,
            _sellerDiscountPercent,
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
        address _sender
    ) external onlyVerdantRouter whenNotPaused nonReentrant {
        StructLib.Order memory order = _orders[_orderId];
        require(order.owner != address(0), "Invalid-order-id");
        if (_paymentToken != order.paymentToken) {
            revert EInvalidPaymentMethod();
        }
        require(order.isOnsale, "Not-on-sale");
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        uint256 orderTokenPrice = order.price;

        if (order.isFloatingPrice) {
            (
                orderTokenPrice,
                _orders[_orderId].pricePathConfirmed
            ) = _getOrderFloatingPrice(
                order,
                verdantManager.getAggregatorV3Paths(
                    order.assetName,
                    _paymentToken
                )
            );
        }

        StructLib.BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommissionHasSign(
                StructLib.BuyerCommissionInput(
                    _paymentToken,
                    order.tokenId,
                    orderTokenPrice,
                    _sender,
                    order.VATPercent
                ),
                _promoCodeInfo,
                _taxInfo.serviceTaxPercentBuyer
            );

        require(
            _buyerCommissionOutput.amountToBuyer <=
                (_priceDesired *
                    (ZOOM_FEE + verdantManager.acceptableFloatingPercent())) /
                    ZOOM_FEE,
            "Price desired exceeds"
        );

        bytes32 _id = hashBidMap(_orderId, _sender);

        bool isUserBid = isBid[_id];

        if (isUserBid) {
            uint256 bidId = userBidOfToken[_id];
            StructLib.Bid memory bid = _bids[bidId];
            if (bid.paymentToken == _paymentToken) {
                uint256 buyerPaidAmount = bid.bidPrice +
                    bid.serviceTaxAmount +
                    bid.commissionBuyer;
                if (buyerPaidAmount > _buyerCommissionOutput.amountToBuyer) {
                    Payment.paid(
                        _paymentToken,
                        _sender,
                        buyerPaidAmount - _buyerCommissionOutput.amountToBuyer
                    );
                } else {
                    IERC20Upgradeable(_paymentToken).safeTransferFrom(
                        _sender,
                        address(this),
                        _buyerCommissionOutput.amountToBuyer - buyerPaidAmount
                    );
                }
                bid.status = false;
                _bids[bidId] = bid;
                isBid[_id] = false;
                emit BidCancelled(bidId);
            } else {
                isUserBid = false;
            }
        }

        if (!isUserBid) {
            IERC20Upgradeable(_paymentToken).safeTransferFrom(
                _sender,
                address(this),
                _buyerCommissionOutput.amountToBuyer
            );
        }

        (
            uint256 verdantServiceTaxReceived,
            uint256 verdantCommissionReceived
        ) = Payment.matchOrder(
                _sender,
                _paymentToken,
                _orders[_orderId],
                orderTokenPrice,
                StructLib.MatchOrderFeeData(
                    verdantManager.getCommissionSellerByTokenId(
                        _sender,
                        order.tokenId
                    ),
                    _taxInfo.serviceTaxPercentSeller,
                    order.sellerDiscountPercent,
                    _buyerCommissionOutput.commissionBuyer,
                    _buyerCommissionOutput.serviceTaxAmount,
                    _buyerCommissionOutput.amountToBuyer,
                    _buyerCommissionOutput.VATAmount,
                    order.sellerGetVAT
                ),
                _taxReceivers,
                verdantManager.feeTo(),
                verdantManager.nFTAddress()
            );

        emit Buy(
            _orderId,
            _buyerCommissionOutput.promocodeAmount,
            StructLib.PaymentData(
                order.paymentToken,
                orderTokenPrice,
                _orders[_orderId].taxReceived,
                verdantCommissionReceived,
                verdantServiceTaxReceived
            )
        );
    }

    function createBid(
        address _paymentToken, // payment method
        uint256 _orderId,
        uint256 _price, // price of 1 nft
        uint256 _serviceTaxPercentBuyer,
        uint256 _expTime,
        address _sender
    )
        external
        onlyVerdantRouter
        whenNotPaused
        nonReentrant
        returns (uint256 _bidId)
    {
        bytes32 _id = hashBidMap(_orderId, _sender);
        require(!isBid[_id], "User-has-bid");
        if (!verdantManager.paymentMethod(_paymentToken)) {
            revert EInvalidPaymentMethod();
        }
        if (!(_expTime > block.timestamp || _expTime == 0)) {
            revert EInvalidExpiredTime();
        }

        StructLib.Order memory order = _orders[_orderId];
        require(order.isOnsale, "Not-on-sale");
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );
        if (order.paymentToken != _paymentToken) {
            revert EInvalidPaymentMethod();
        }

        StructLib.Bid memory newBid;
        newBid.bidder = _sender;
        newBid.bidPrice = _price;
        newBid.orderId = _orderId;

        StructLib.BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommission(
                StructLib.BuyerCommissionInput(
                    _paymentToken,
                    order.tokenId,
                    _price,
                    _sender,
                    order.VATPercent
                ),
                _serviceTaxPercentBuyer
            );

        newBid.paymentToken = _paymentToken;
        IERC20Upgradeable(newBid.paymentToken).safeTransferFrom(
            _sender,
            address(this),
            _buyerCommissionOutput.amountToBuyer
        );

        newBid.serviceTaxAmount = _buyerCommissionOutput.serviceTaxAmount;
        newBid.VATAmount = _buyerCommissionOutput.VATAmount;
        newBid.commissionBuyer = _buyerCommissionOutput.commissionBuyer;
        newBid.status = true;
        newBid.expTime = _expTime;
        _bids[totalBids] = newBid;
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
        address _sender
    ) external onlyVerdantRouter whenNotPaused nonReentrant {
        StructLib.Bid memory bid = _bids[_bidId];
        require(bid.status, "Bid-cancelled");
        require(
            bid.expTime > block.timestamp || bid.expTime == 0,
            "Bid-expired"
        );

        StructLib.Order memory order = _orders[bid.orderId];
        require(
            (order.owner == _sender ||
                (order.isFloatingPrice &&
                    verdantManager.isOperator(_sender))) && order.isOnsale,
            "Not-owner/operator-or-cancelled"
        );
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        if (order.isFloatingPrice && verdantManager.isOperator(_sender)) {
            if (order.paymentToken != bid.paymentToken) {
                revert EInvalidPaymentMethod();
            }

            (uint256 orderTokenPrice, ) = _getOrderFloatingPrice(
                order,
                verdantManager.getAggregatorV3Paths(
                    order.assetName,
                    bid.paymentToken
                )
            );

            require(
                bid.bidPrice >=
                    (orderTokenPrice *
                        (ZOOM_FEE -
                            verdantManager.acceptableFloatingPercent())) /
                        ZOOM_FEE,
                "Invalid-bid-price"
            );
        }

        uint256 buyerPaidAmount = bid.bidPrice +
            bid.commissionBuyer +
            bid.serviceTaxAmount +
            bid.VATAmount;
        StructLib.BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommission(
                StructLib.BuyerCommissionInput(
                    bid.paymentToken,
                    order.tokenId,
                    bid.bidPrice,
                    _sender,
                    order.VATPercent
                ),
                _taxInfo.serviceTaxPercentBuyer
            );

        bid.status = false;
        bid.commissionBuyer = _buyerCommissionOutput.commissionBuyer;
        bid.serviceTaxAmount = _buyerCommissionOutput.serviceTaxAmount;

        _bids[_bidId] = bid;

        isBid[hashBidMap(bid.orderId, bid.bidder)] = false;

        (
            uint256 verdantServiceTaxReceived,
            uint256 verdantCommissionReceived
        ) = Payment.matchOrder(
                bid.bidder,
                bid.paymentToken,
                _orders[bid.orderId],
                bid.bidPrice,
                StructLib.MatchOrderFeeData(
                    verdantManager.getCommissionSellerByTokenId(
                        bid.bidder,
                        order.tokenId
                    ),
                    _taxInfo.serviceTaxPercentSeller,
                    order.sellerDiscountPercent,
                    bid.commissionBuyer,
                    bid.serviceTaxAmount,
                    buyerPaidAmount,
                    bid.VATAmount,
                    order.sellerGetVAT
                ),
                _taxReceivers,
                verdantManager.feeTo(),
                verdantManager.nFTAddress()
            );

        emit AcceptBid(
            _bidId,
            StructLib.PaymentData(
                order.paymentToken,
                bid.bidPrice,
                _orders[bid.orderId].taxReceived,
                verdantCommissionReceived,
                verdantServiceTaxReceived
            )
        );
    }

    function cancelOrder(
        uint256 _orderId,
        address _sender
    ) external onlyVerdantRouter whenNotPaused nonReentrant {
        StructLib.Order memory order = _orders[_orderId];
        require(
            (order.owner == _sender || verdantManager.isOperator(_sender)) &&
                order.isOnsale,
            "Not-owner/operator-or-cancelled"
        );
        IERC721Upgradeable(verdantManager.nFTAddress()).transferFrom(
            address(this),
            order.owner,
            order.tokenId
        );

        order.isOnsale = false;
        _orders[_orderId] = order;
        emit OrderCancelled(_orderId);
    }

    function cancelBid(
        uint256 _bidId,
        address _sender
    ) external whenNotPaused nonReentrant {
        StructLib.Bid memory bid = _bids[_bidId];
        require(
            bid.bidder == _sender || verdantManager.isOperator(_sender),
            "Only-bidder-operator"
        );
        require(bid.status, "Bid-cancelled");

        IERC20Upgradeable(bid.paymentToken).safeTransfer(
            bid.bidder,
            bid.bidPrice +
                bid.commissionBuyer +
                bid.serviceTaxAmount +
                bid.VATAmount
        );

        bid.status = false;
        _bids[_bidId] = bid;

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
        address _sender
    ) external onlyVerdantRouter whenNotPaused nonReentrant {
        StructLib.Order memory order = _orders[_orderId];

        require(
            order.owner == _sender && order.isOnsale,
            "Not-owner-or-cancelled"
        );
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        if (
            !(verdantManager.paymentMethod(_paymentToken) &&
                (!_isFloatingPrice ||
                    (_isFloatingPrice &&
                        verdantManager
                            .getAggregatorV3Paths(_assetName, _paymentToken)
                            .length >
                        0)))
        ) {
            revert EInvalidPaymentMethod();
        }

        if (!(_expTime > block.timestamp || _expTime == 0)) {
            revert EInvalidExpiredTime();
        }

        order.paymentToken = _paymentToken;
        order.expTime = _expTime;
        order.price = _price;
        order.VATPercent = _VATPercent;
        order.sellerGetVAT = _sellerGetVAT;
        if (_isFloatingPrice) {
            if (_premiumPercent > ZOOM_FEE) {
                revert EInvalidPremiumPercent();
            }

            order.assetName = _assetName;
            order.premiumPercent = _premiumPercent;
            order.isFloatingPrice = _isFloatingPrice;
        }

        _orders[_orderId] = order;
        emit OrderUpdated(_orderId);
    }

    function updateBid(
        uint256 _bidId,
        uint256 _bidPrice,
        uint256 _serviceTaxPercentBuyer,
        uint256 _expTime,
        address _sender
    ) external onlyVerdantRouter whenNotPaused nonReentrant {
        StructLib.Bid memory bid = _bids[_bidId];
        require(bid.bidder == _sender, "Invalid-bidder");
        require(bid.status, "Bid-cancelled");
        require(
            bid.expTime > block.timestamp || bid.expTime == 0,
            "Bid-expired"
        );

        if (!(_expTime > block.timestamp || _expTime == 0)) {
            revert EInvalidExpiredTime();
        }

        bid.expTime = _expTime;
        StructLib.Order memory order = _orders[bid.orderId];
        if (bid.bidPrice != _bidPrice) {
            StructLib.BuyerCommissionOutput
                memory _buyerCommissionOutput = calBuyerCommission(
                    StructLib.BuyerCommissionInput(
                        bid.paymentToken,
                        order.tokenId,
                        _bidPrice,
                        _sender,
                        order.VATPercent
                    ),
                    _serviceTaxPercentBuyer
                );
            uint256 _amountToBuyerOld = bid.bidPrice +
                bid.commissionBuyer +
                bid.serviceTaxAmount +
                bid.VATAmount;

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
                    _sender,
                    address(this),
                    amount
                );
            }

            bid.bidPrice = _bidPrice;
            bid.commissionBuyer = _buyerCommissionOutput.commissionBuyer;
            bid.serviceTaxAmount = _buyerCommissionOutput.serviceTaxAmount;
            bid.VATAmount = _buyerCommissionOutput.VATAmount;
        }

        _bids[_bidId] = bid;
        emit BidUpdated(_bidId);
    }
}