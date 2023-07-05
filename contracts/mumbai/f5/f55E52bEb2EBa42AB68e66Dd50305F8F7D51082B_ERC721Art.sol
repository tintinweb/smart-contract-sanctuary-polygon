// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";
import "../@openzeppelin/proxy/utils/Initializable.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFiltererUpgradeable is
    Initializable,
    OperatorFiltererUpgradeable
{
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        __OperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import "../@openzeppelin/proxy/utils/Initializable.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function __OperatorFilterer_init(
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../upgradeable/utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../../proxy/utils/Initializable.sol";

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

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
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC2981Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is
    Initializable,
    IERC2981Upgradeable,
    ERC165Upgradeable
{
    function __ERC2981_init() internal onlyInitializing {}

    function __ERC2981_init_unchained() internal onlyInitializing {}

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo internal _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
import "../../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./MathUpgradeable.sol";

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
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title ERC721 contract for artistic workpieces from allowed artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IERC721Art} from "./interfaces/IERC721Art.sol";
import {ICrowdfund} from "./interfaces/ICrowdfund.sol";
import {IManagement} from "./interfaces/IManagement.sol";
import {IERC20} from "./@openzeppelin/token/IERC20.sol";

///@dev ERC721 token standard.
import {ERC721Upgradeable} from "./@openzeppelin/upgradeable/token/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "./@openzeppelin/upgradeable/token/ERC2981Upgradeable.sol";

///@dev security settings.
import {SecurityUpgradeable, OwnableUpgradeable} from "./SecurityUpgradeable.sol";

/**
@dev DefaultOperatorFilterer is necessary for enforcing creator's royalty on OpenSea.
To learn more:
- https://www.youtube.com/watch?v=4spapOTVpNA
- https://twitter.com/0xcygaar/status/1589787467443765248?s=46&t=iE4ffqs_8qPzPcuDUftWbg
- https://github.com/ProjectOpenSea/operator-filter-registry
*/
import {DefaultOperatorFiltererUpgradeable} from "./@opensea/DefaultOperatorFiltererUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract ERC721Art is
    IERC721Art,
    SecurityUpgradeable,
    ERC721Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable
{
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    // Specifics of ERC721 settings for CreatorsPRO project
    uint256 private s_maxSupply;
    string private s_baseURI;
    mapping(IManagement.Coin coin => uint256 price_) private s_pricePerCoin;
    mapping(uint256 tokenId => uint256 lastTransferTimestamp)
        private s_lastTransfer;

    ///@dev mapping that specifies price of token for different coins/tokens.
    mapping(uint256 tokenId => mapping(IManagement.Coin coin => uint256 price_))
        private s_tokenPrice;

    ///@dev crowdfund contract settings
    address private s_crowdfund;

    ///@dev SFTRecommendation pattern
    mapping(address coin => uint256 discount) public maxDiscount;
    address public coreSFT;

    ///@dev creator's escrow contract address
    address private s_escrow;

    //constants
    uint256 private constant MAX_UNIT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant MINT_FOR_CROWDFUND_MULTIPLIER = 5;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    /** @dev checks if it has reached the max supply 
        @param tokenId: ID of the token */
    function __checkSupply(uint256 tokenId) private view {
        if (s_maxSupply > 0 && !(tokenId < s_maxSupply)) {
            revert ERC721Art__MaxSupplyReached();
        }
    }

    ///@dev checks if caller is authorized (crowdfund)
    function __crowdFundOnlyAuthorized() private view {
        if (s_crowdfund == address(0)) {
            if (!s_management.getIsCorrupted(owner())) {
                if (
                    !(s_management.getManagers(msg.sender) ||
                        msg.sender == owner())
                ) {
                    revert ERC721Art__NotAllowed();
                }
            } else {
                if (!s_management.getManagers(msg.sender)) {
                    revert ERC721Art__NotAllowed();
                }
            }
        } else {
            if (msg.sender != s_crowdfund) {
                revert ERC721Art__NotAllowed();
            }
        }
    }

    /** @dev checks if calles is token owner 
        @param tokenId: ID of the token */
    function __onlyTokenOwner(uint256 tokenId) private view {
        if (msg.sender != ERC721Upgradeable.ownerOf(tokenId)) {
            revert ERC721Art__NotTokenOwner();
        }
    }

    /** @dev private function for onlyAllowedOperator modifier
        @param operator: operator address */
    function __onlyAllowedOperator(
        address operator
    ) private view onlyAllowedOperator(operator) {}

    /** @dev private function for onlyAllowedOperatorApproval modifier
        @param operator: operator address */
    function __onlyAllowedOperatorApproval(
        address operator
    ) private view onlyAllowedOperatorApproval(operator) {}

    /// -----------------------------------------------------------------------
    /// Receive function
    /// -----------------------------------------------------------------------

    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    /// @dev initializer modifier added
    /// @inheritdoc IERC721Art
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 maxSupply,
        uint256 price_,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) public virtual override(IERC721Art) initializer {
        _SecurityUpgradeable_init(owner_);
        __ERC721_init(name_, symbol_);
        __DefaultOperatorFilterer_init();
        __ERC2981_init();
        _setDefaultRoyalty(owner_, uint96(royalty));

        s_management = IManagement(msg.sender);
        s_maxSupply = maxSupply;
        s_pricePerCoin[IManagement.Coin.ETH_COIN] = price_;
        s_pricePerCoin[IManagement.Coin.USD_TOKEN] = priceInUSD;
        s_pricePerCoin[IManagement.Coin.CREATORS_TOKEN] = priceInCreatorsCoin;
        s_baseURI = baseURI;
        s_escrow = s_management.getCreator(owner_).escrow;
    }

    /// -----------------------------------------------------------------------
    /// Implemented functions
    /// -----------------------------------------------------------------------

    // --- ERC721 functions ---

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. _tokenId input parameter
    must be less than maxSupply (if not 0). Function won't work if creator/collection has been corrupted. */
    /// @inheritdoc IERC721Art
    function mint(
        uint256 tokenId,
        IManagement.Coin coin,
        uint256 discount
    ) public payable virtual override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        __checkSupply(tokenId);
        _notCorrupted();
        _onlyValidCoin(coin);

        if (s_crowdfund != address(0)) {
            revert ERC721Art__CollectionForFund();
        }

        if (msg.sender == coreSFT) {
            address token = address(s_management.getTokenContract(coin));

            require(
                maxDiscount[token] >= discount,
                "Mock ERC1155 mapping eth join mint discount error"
            );
            if (token == address(0))
                require(
                    msg.value ==
                        (price(address(0)) * (10000 - discount)) / 10000,
                    "Mock ERC1155 mapping eth join mint error"
                );
            else {
                require(
                    IERC20(token).allowance(msg.sender, address(this)) ==
                        (price(token) * (10000 - discount)) / 10000,
                    "Mock ERC1155 mapping eth join mint ERC20 error"
                );
                _transferERC20To(
                    coin,
                    msg.sender,
                    address(this),
                    (price(token) * (10000 - discount)) / 10000
                );
            }
        }

        bool isAmountLowerThanPrice = false;
        uint256 price_ = s_pricePerCoin[coin];
        if (coin == IManagement.Coin.ETH_COIN) {
            isAmountLowerThanPrice = msg.value < price_;
            if (msg.value > price_) {
                uint256 aboveValue = msg.value - price_;
                _transferTo(msg.sender, aboveValue);
            }
        } else {
            isAmountLowerThanPrice =
                s_management.getTokenContract(coin).allowance(
                    msg.sender,
                    address(this)
                ) <
                price_;
        }

        if (isAmountLowerThanPrice) {
            revert ERC721Art__NotEnoughValueOrAllowance();
        }

        _transferRoyalties(msg.sender, tokenId, price_, coin, true);

        _safeMint(msg.sender, tokenId);

        _approve(s_escrow, tokenId);
        _setApprovalForAll(msg.sender, s_escrow, true);

        __setPoints(msg.sender, tokenId, price_, uint8(coin), false);

        _setInitialTokenPrice(tokenId);

        // update last transfer timestamp
        s_lastTransfer[tokenId] = block.timestamp;
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. _tokenId input parameter
    must be less than maxSupply (if not 0). Function won't work if creator/collection has been corrupted. 
    Only authorized addresses (managers and creator) can call this function. */
    /// @inheritdoc IERC721Art
    function mintToAddress(
        address to,
        uint256 tokenId
    ) external override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        __checkSupply(tokenId);
        _onlyAuthorized();

        _safeMint(to, tokenId);

        _approve(s_escrow, tokenId);
        _setApprovalForAll(to, s_escrow, true);

        __setPoints(
            to,
            tokenId,
            s_pricePerCoin[IManagement.Coin.USD_TOKEN],
            uint8(IManagement.Coin.USD_TOKEN),
            false
        );

        _setInitialTokenPrice(tokenId);

        // update last transfer timestamp
        s_lastTransfer[tokenId] = block.timestamp;
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added.
    Function won't work if creator/collection has been corrupted. To work, a crowdfund address
    must have been set and the caller must be the crowdfund contract. It will revert if any token ID
    in the input array is greater than maxSupply. */
    /// @inheritdoc IERC721Art
    function mintForCrowdfund(
        uint256[] memory tokenIds,
        uint8[] memory classes,
        address to
    ) external virtual override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();

        if (s_crowdfund == address(0)) {
            revert ERC721Art__CollectionForFund();
        }

        if (s_crowdfund != msg.sender) {
            revert ERC721Art__CallerNotCrowdfund();
        }

        if (tokenIds.length != classes.length) {
            revert ERC721Art__ArraysDoNotMatch();
        }

        uint256 precision = s_management
            .getProxyReward()
            .getInteracPointsPrecision()[1];
        uint256 decimals = s_management
            .getTokenContract(IManagement.Coin.USD_TOKEN)
            .decimals();
        address escrow = s_escrow;
        _setApprovalForAll(to, escrow, true);
        for (uint256 ii; ii < tokenIds.length; ++ii) {
            if (!(tokenIds[ii] < s_maxSupply)) {
                revert ERC721Art__MaxSupplyReached();
            }

            _safeMint(to, tokenIds[ii]);
            _approve(escrow, tokenIds[ii]);
            __setPoints(
                to,
                tokenIds[ii],
                classes[ii] *
                    MINT_FOR_CROWDFUND_MULTIPLIER *
                    precision *
                    10 ** decimals,
                uint8(IManagement.Coin.USD_TOKEN),
                false
            );
        }
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. _tokenId input parameter
    must be a valid (minted) token ID. Function won't work if creator/collection has been corrupted. 
    Only authorized addresses (managers and creator) can call this function. */
    /// @inheritdoc IERC721Art
    function burn(uint256 tokenId) external override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        _onlyAuthorized();

        address owner_ = ownerOf(tokenId);

        _burn(tokenId);

        s_management.getProxyReward().removeToken(owner_, tokenId, true);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. If value sent for transfer is lower
    than token price, it reverts. Function won't work if creator/collection has been corrupted. */
    /// @inheritdoc IERC721Art
    function creatorsProSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        IManagement.Coin coin
    ) public payable override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();
        _onlyValidCoin(coin);

        bool isAmountLowerThanTokenPrice = false;
        uint256 tokenPrice = s_tokenPrice[tokenId][coin];
        if (coin == IManagement.Coin.ETH_COIN) {
            isAmountLowerThanTokenPrice = msg.value < tokenPrice;
            if (msg.value > tokenPrice) {
                uint256 aboveValue = msg.value - tokenPrice;
                _transferTo(msg.sender, aboveValue);
            }
        } else {
            isAmountLowerThanTokenPrice =
                s_management.getTokenContract(coin).allowance(
                    from,
                    address(this)
                ) <
                tokenPrice;
        }
        if (isAmountLowerThanTokenPrice) {
            revert ERC721Art__NotEnoughValueOrAllowance();
        }

        (
            uint256 CreatorsProRoyalty,
            uint256 collectionCreatorRoyalty
        ) = _transferRoyalties(to, tokenId, tokenPrice, coin, false);

        // tokenId owner payment
        uint256 ownerValue = tokenPrice -
            CreatorsProRoyalty -
            collectionCreatorRoyalty;
        _coinTransfer(to, from, ownerValue, coin);

        _setInitialTokenPrice(tokenId);

        __setPoints(from, tokenId, tokenPrice, uint8(coin), true);
        __setPoints(to, tokenId, tokenPrice, uint8(coin), false);

        ERC721Upgradeable.safeTransferFrom(from, to, tokenId);

        emit OwnerPaymentDone(tokenId, from, ownerValue);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only managers are allowed 
    to execute this function. */
    /// @inheritdoc IERC721Art
    function withdrawToAddress(
        address receiver,
        uint256 amount
    ) external override(IERC721Art) {
        _nonReentrant();
        _onlyManagers();

        _transferTo(receiver, amount);

        emit WithdrawnToAddress(msg.sender, receiver, amount);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if creator/collection 
    has been corrupted. Only creator (owner) is allowed to execute this function. */
    /// @inheritdoc IERC721Art
    function setPrice(
        uint256 price_,
        IManagement.Coin coin
    ) external override(IERC721Art) {
        _onlyOwner();
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();

        s_pricePerCoin[coin] = price_;

        emit PriceSet(price_, coin);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if creator/collection
    has been corrupted. Only token owner is allowed to execute this function. */
    /// @inheritdoc IERC721Art
    function setTokenPrice(
        uint256 tokenId,
        uint256 price_,
        IManagement.Coin coin
    ) external override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        __onlyTokenOwner(tokenId);
        _notCorrupted();

        s_tokenPrice[tokenId][coin] = price_;

        emit TokenPriceSet(tokenId, price_, coin);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if creator/collection
    has been corrupted. Only authorized addresses are allowed to execute this function. */
    /// @inheritdoc IERC721Art
    function setBaseURI(string memory uri) external override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        _onlyAuthorized();

        s_baseURI = uri;
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if creator/collection 
    has been corrupted. Only authorized addresses are allowed to execute this function. */
    /// @inheritdoc IERC721Art
    function setRoyalty(uint256 royalty) external override(IERC721Art) {
        _onlyOwner();
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();

        _setDefaultRoyalty(owner(), uint96(royalty));

        emit RoyaltySet(royalty);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. It will also
    revert if caller is not a valid crowdfund contract */
    /// @inheritdoc IERC721Art
    function setCrowdfund(address crowdfund) external override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        if (msg.sender != address(s_management)) {
            revert ERC721Art__NotAllowed();
        }
        if (s_crowdfund != address(0)) {
            revert ERC721Art__CrodFundIsSet();
        }
        uint256 amountLow = ICrowdfund(crowdfund)
            .getQuotaInfos(ICrowdfund.QuotaClass.LOW)
            .amount;
        uint256 amountReg = ICrowdfund(crowdfund)
            .getQuotaInfos(ICrowdfund.QuotaClass.REGULAR)
            .amount;
        uint256 amountHigh = ICrowdfund(crowdfund)
            .getQuotaInfos(ICrowdfund.QuotaClass.HIGH)
            .amount;
        if (
            address(SecurityUpgradeable(crowdfund).getManagement()) !=
            address(s_management) ||
            OwnableUpgradeable(crowdfund).owner() != owner() ||
            amountLow + amountReg + amountHigh != s_maxSupply ||
            address(ICrowdfund(crowdfund).getCollection()) != address(this)
        ) {
            revert ERC721Art__InvalidCrowdFund();
        }

        s_crowdfund = crowdfund;

        emit CrowdfundSet(crowdfund);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if creator/collection 
    has been corrupted. Only creator (owner) is allowed to execute this function. */
    /// @inheritdoc IERC721Art
    function setMaxDiscount(
        address token,
        uint256 maxDiscount_
    ) external override(IERC721Art) {
        _onlyOwner();
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();

        maxDiscount[token] = maxDiscount_;

        emit MaxDiscountSet(token, maxDiscount_);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if creator/collection 
    has been corrupted. Only authorized are allowed to execute this function. */
    /// @inheritdoc IERC721Art
    function setCoreSFT(address coreSFT_) external override(IERC721Art) {
        _whenNotPaused();
        _nonReentrant();
        _notCorrupted();
        _onlyAuthorized();

        coreSFT = coreSFT_;

        emit NewCoreSFTSet(msg.sender, coreSFT_);
    }

    // --- Pause and Unpause functions ---

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc SecurityUpgradeable
    function pause() public override(SecurityUpgradeable, IERC721Art) {
        __crowdFundOnlyAuthorized();

        SecurityUpgradeable.pause();
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. Uses _pause internal function from PausableUpgradeable. */
    /// @inheritdoc SecurityUpgradeable
    function unpause() public override(SecurityUpgradeable, IERC721Art) {
        __crowdFundOnlyAuthorized();

        SecurityUpgradeable.unpause();
    }

    // --- Internal functions ---

    /** @dev transfers the given amount of the given coin to the given payee (royalty).
        @param from: payer address
        @param to: receiver of payment 
        @param value: value to be transferred
        @param coin: coin of which the transfer is made */
    function _coinTransfer(
        address from,
        address to,
        uint256 value,
        IManagement.Coin coin
    ) internal {
        if (coin == IManagement.Coin.ETH_COIN) {
            _transferTo(to, value);
        } else {
            _transferERC20To(coin, from, to, value);
        }
    }

    /** @dev executes all the royalties and payment transfers when minting
        @param fromWallet: address from which the payments will be done
        @param tokenId: ID of the token to be transferred
        @param price_: price of NFT
        @param coin: which coin/token to use for transfer
        @param isMint: specifies if is a mint or transfer 
        @return uint256, uint256 values for amount of CreatorsPRO royalty and amount of creator's royalty */
    function _transferRoyalties(
        address fromWallet,
        uint256 tokenId,
        uint256 price_,
        IManagement.Coin coin,
        bool isMint
    ) internal returns (uint256, uint256) {
        // CreatorsPRO royalty
        uint256 CreatorsProRoyalty = (price_ * s_management.getFee()) /
            _feeDenominator();
        _coinTransfer(
            fromWallet,
            s_management.getMultiSig(),
            CreatorsProRoyalty,
            coin
        );

        // collection creator transfer
        uint256 collectionCreatorRoyalty;
        if (isMint) {
            _coinTransfer(
                fromWallet,
                owner(),
                price_ - CreatorsProRoyalty,
                coin
            );
        } else {
            (, collectionCreatorRoyalty) = royaltyInfo(tokenId, price_);
            _coinTransfer(fromWallet, owner(), collectionCreatorRoyalty, coin);
        }

        emit RoyaltiesTransferred(
            tokenId,
            CreatorsProRoyalty,
            isMint ? price_ - CreatorsProRoyalty : collectionCreatorRoyalty,
            fromWallet
        );

        return (CreatorsProRoyalty, collectionCreatorRoyalty);
    }

    /** @dev initially sets token price to the maximum uint256 value
        @param tokenId: ID of token */
    function _setInitialTokenPrice(uint256 tokenId) internal {
        for (uint256 ii; ii < 3; ++ii) {
            s_tokenPrice[tokenId][IManagement.Coin(ii)] = MAX_UNIT;
        }
    }

    /** @dev increases user score on Management contract
        @param user: user address
        @param tokenId: score to be added 
        @param value: value added/subtracted
        @param coin: coin of transfer
        @param isSell: bool that specifies if is selling (true) or not (false) */
    function __setPoints(
        address user,
        uint256 tokenId,
        uint256 value,
        uint8 coin,
        bool isSell
    ) private {
        s_management.getProxyReward().setPoints(
            user,
            tokenId,
            value,
            coin,
            isSell
        );
    }

    /// @inheritdoc IERC721Art
    function getRoyalty()
        external
        view
        override(IERC721Art)
        returns (address, uint256)
    {
        return (
            _defaultRoyaltyInfo.receiver,
            _defaultRoyaltyInfo.royaltyFraction
        );
    }

    /// @inheritdoc IERC721Art
    function price(
        address token
    ) public view override(IERC721Art) returns (uint256) {
        if (
            token ==
            address(s_management.getTokenContract(IManagement.Coin.USD_TOKEN))
        ) {
            return s_pricePerCoin[IManagement.Coin.USD_TOKEN];
        } else if (
            token ==
            address(
                s_management.getTokenContract(IManagement.Coin.CREATORS_TOKEN)
            )
        ) {
            return s_pricePerCoin[IManagement.Coin.CREATORS_TOKEN];
        } else if (token == address(0)) {
            return s_pricePerCoin[IManagement.Coin.ETH_COIN];
        } else {
            revert ERC721Art__InvalidAddress();
        }
    }

    /// @inheritdoc IERC721Art
    function getMaxSupply()
        external
        view
        override(IERC721Art)
        returns (uint256)
    {
        return s_maxSupply;
    }

    /// @inheritdoc IERC721Art
    function getBaseURI()
        external
        view
        override(IERC721Art)
        returns (string memory)
    {
        return s_baseURI;
    }

    /// @inheritdoc IERC721Art
    function getPricePerCoin(
        IManagement.Coin coin
    ) external view override(IERC721Art) returns (uint256) {
        return s_pricePerCoin[coin];
    }

    /// @inheritdoc IERC721Art
    function getLastTransfer(
        uint256 tokenId
    ) external view override(IERC721Art) returns (uint256) {
        return s_lastTransfer[tokenId];
    }

    /// @inheritdoc IERC721Art
    function getTokenPrice(
        uint256 tokenId,
        IManagement.Coin coin
    ) external view override(IERC721Art) returns (uint256) {
        return s_tokenPrice[tokenId][coin];
    }

    /// @inheritdoc IERC721Art
    function getCrowdfund()
        external
        view
        override(IERC721Art)
        returns (address)
    {
        return s_crowdfund;
    }

    /// -----------------------------------------------------------------------
    /// Overridden functions
    /// -----------------------------------------------------------------------

    /// @dev added onlyAllowedOperatorApproval modifier from DefaultOperatorFiltererUpgradeable (OpenSea).
    /// @inheritdoc ERC721Upgradeable
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721Upgradeable) {
        __onlyAllowedOperatorApproval(operator);
        ERC721Upgradeable.setApprovalForAll(operator, approved);
    }

    /// @dev added onlyAllowedOperatorApproval modifier from DefaultOperatorFiltererUpgradeable (OpenSea).
    /// @inheritdoc ERC721Upgradeable
    function approve(
        address operator,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) {
        __onlyAllowedOperatorApproval(operator);
        ERC721Upgradeable.approve(operator, tokenId);
    }

    /// @inheritdoc ERC721Upgradeable
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721Upgradeable) returns (string memory) {
        return
            string(
                abi.encodePacked(ERC721Upgradeable.tokenURI(_tokenId), ".json")
            );
    }

    /// @inheritdoc ERC721Upgradeable
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /// @dev added onlyAllowedOperator modifier from DefaultOperatorFiltererUpgradeable (OpenSea).
    /// @inheritdoc ERC721Upgradeable
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        _nonReentrant();
        _whenNotPaused();
        __onlyAllowedOperator(from);

        // update last transfer timestamp
        s_lastTransfer[tokenId] = block.timestamp;

        ERC721Upgradeable._transfer(from, to, tokenId);

        _approve(s_escrow, tokenId);
        _setApprovalForAll(to, s_escrow, true);
    }

    /// @inheritdoc ERC721Upgradeable
    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return s_baseURI;
    }

    /// -----------------------------------------------------------------------
    /// Storage space for upgrades
    /// -----------------------------------------------------------------------

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC721 contract for crowdfunds from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC721Art} from "./IERC721Art.sol";
import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICrowdfund {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the crowdfund has past due data
    error Crowdfund__PastDue();

    ///@dev error for when the caller is not an investor
    error Crowdfund__CallerNotInvestor();

    ///@dev error for when low class quota maximum amount has reached
    error Crowdfund__LowQuotaMaxAmountReached();

    ///@dev error for when regular class quota maximum amount has reached
    error Crowdfund__RegQuotaMaxAmountReached();

    ///@dev error for when low high quota maximum amount has reached
    error Crowdfund__HighQuotaMaxAmountReached();

    ///@dev error for when minimum fund goal is not reached
    error Crowdfund__MinGoalNotReached();

    ///@dev error for when not enough ETH value is sent
    error Crowdfund__NotEnoughValueSent();

    ///@dev error for when the resulting max supply is 0
    error Crowdfund__MaxSupplyIs0();

    ///@dev error for when the caller has no more tokens to mint
    error Crowdfund__NoMoreTokensToMint();

    ///@dev error for when the caller is not invest ID owner
    error Crowdfund__NotInvestIdOwner();

    ///@dev error for when an invalid collection address is given
    error Crowdfund__InvalidCollection();

    ///@dev error for when refund is not possible
    error Crowdfund__RefundNotPossible();

    ///@dev error for when an invalid minimum sold rate is given
    error Crowdfund__InvalidMinSoldRate();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the quota class 
        @param LOW: low class
        @param REGULAR: regular class
        @param HIGH: high class */
    enum QuotaClass {
        LOW,
        REGULAR,
        HIGH
    }

    /** @dev struct with important informations of an invest ID 
        @param index: invest ID index in investIdsPerInvestor array
        @param totalPayment: total amount paid in the investment
        @param sevenDaysPeriod: 7 seven days period end timestamp
        @param coin: coin used for the investment
        @param lowQuotaAmount: low class quota amount bought 
        @param regQuotaAmount: regular class quota amount bought 
        @param highQuotaAmount: high class quota amount bought */
    struct InvestIdInfos {
        uint256 index;
        uint256 totalPayment;
        uint256 sevenDaysPeriod;
        IManagement.Coin coin;
        address investor;
        uint256 lowQuotaAmount;
        uint256 regQuotaAmount;
        uint256 highQuotaAmount;
    }

    /** @dev struct with important information about each quota 
        @param values: array of price values for each coin. Array order: [ETH, US dollar token, CreatorsPRO token]
        @param amount: total amount
        @param bough: amount of bought quotas
        @param nextTokenId: next token ID for the current quota */
    struct QuotaInfos {
        uint256[3] values;
        uint256 amount;
        uint256 bought;
        uint256 nextTokenId;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when shares are bought 
        @param investor: investor's address
        @param investId: ID of the investment
        @param lowQuotaAmount: amount of low class quota
        @param regQuotaAmount: amount of regular class quota
        @param highQuotaAmount: amount of high class quota
        @param totalPayment: amount of shares bought 
        @param coin: coin of investment */
    event Invested(
        address indexed investor,
        uint256 indexed investId,
        uint256 lowQuotaAmount,
        uint256 regQuotaAmount,
        uint256 highQuotaAmount,
        uint256 totalPayment,
        IManagement.Coin coin
    );

    /** @dev event for when an investor withdraws investment 
        @param investor: investor's address 
        @param investId: ID of investment 
        @param amount: amount to be withdrawed
        @param coin: coin of withdrawal */
    event RefundedInvestId(
        address indexed investor,
        uint256 indexed investId,
        uint256 amount,
        IManagement.Coin coin
    );

    /** @dev event for when investor refunds his/her whole investment at once
        @param investor: investor's address 
        @param ETHAmount: amount refunded in ETH/MATIC
        @param USDAmount: amount refunded in USD 
        @param CreatorsCoinAmount: amount refunded in CreatorsCoin 
        @param investIdsRefunded: array of refunded invest IDs */
    event RefundedAll(
        address indexed investor,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount,
        uint256[] investIdsRefunded
    );

    /** @dev event for when the crowdfund creator withdraws funds 
        @param ETHAmount: amount withdrawed in ETH/MATIC
        @param USDAmount: amount withdrawed in USD
        @param CreatorsCoinAmount: amount withdrawed in CreatorsCoin */
    event CreatorWithdrawed(
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount
    );

    /** @dev event for when the donantion is sent
        @param _donationReceiver: receiver address of the donation
        @param ETHAmount: amount donated in ETH
        @param USDAmount: amount donated in USD
        @param CreatorsCoinAmount: amount donated in CreatorsCoin */
    event DonationSent(
        address indexed _donationReceiver,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount
    );

    /** @dev event for when an investor has minted his/her tokens
        @param investor: address of investor 
        @param caller: function's caller address */
    event InvestorMinted(address indexed investor, address indexed caller);

    /** @dev event for when a donation is made
        @param caller: function caller address
        @param amount: donation amount
        @param coin: coin of donation */
    event DonationTransferred(
        address indexed caller,
        uint256 amount,
        IManagement.Coin coin
    );

    /** @dev event for when a manager refunds all quotas to given investor address 
        @param manager: manager address that called the function
        @param investor: investor address
        @param ETHAmount: amount refunded in ETH/MATIC
        @param USDAmount: amount refunded in USD 
        @param CreatorsCoinAmount: amount refunded in CreatorsCoin 
        @param investIdsRefunded: array of refunded invest IDs */
    event RefundedAllToAddress(
        address indexed manager,
        address indexed investor,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount,
        uint256[] investIdsRefunded
    );

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes this contract.
        @param valuesLowQuota: array of values for low quota
        @param valuesRegQuota: array of values for regular quota
        @param valuesHighQuota: array of values for high quota 
        @param amountLowQuota: amount for low quota 
        @param amountRegQuota: amount for regular quota 
        @param amountHighQuota: amount for high quota 
        @param donationReceiver: address for donation 
        @param donationFee: fee for donation 
        @param minSoldRate: minimum rate for sold quotas 
        @param collection: ERC721Art collection address */
    function initialize(
        uint256[3] memory valuesLowQuota,
        uint256[3] memory valuesRegQuota,
        uint256[3] memory valuesHighQuota,
        uint256 amountLowQuota,
        uint256 amountRegQuota,
        uint256 amountHighQuota,
        address donationReceiver,
        uint256 donationFee,
        uint256 minSoldRate,
        address collection
    ) external;

    /** @notice buys the given amount of shares in the given coin/token. Payable function.
        @param amountOfLowQuota: amount of low quotas to be bought
        @param amountOfRegularQuota: amount of regular quotas to be bought
        @param amountOfHighQuota: amount of high quotas to be bought
        @param coin: coin of transfer */
    function invest(
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) external payable;

    /** @notice buys the given amount of shares in the given coin/token for given address. Payable function.
        @param amountOfLowQuota: amount of low quotas to be bought
        @param amountOfRegularQuota: amount of regular quotas to be bought
        @param amountOfHighQuota: amount of high quotas to be bought 
        @param coin: coin of transfer */
    function investForAddress(
        address investor,
        uint256 amountOfLowQuota,
        uint256 amountOfRegularQuota,
        uint256 amountOfHighQuota,
        IManagement.Coin coin
    ) external payable;

    /** @notice donates the given amount of the given to the crowdfund (will not get ERC721 tokens as reward) 
        @param amount: donation amount
        @param coin: coin/token for donation */
    function donate(uint256 amount, IManagement.Coin coin) external payable;

    /** @notice donates the given amount to the crowdfund (will not get ERC721 tokens as reward) for the given address
        @param donor: donor's address
        @param amount: donation amount
        @param coin: coin/token for donation */
    function donateForAddress(
        address donor,
        uint256 amount,
        IManagement.Coin coin
    ) external payable;

    /** @notice withdraws the fund invested to the calling investor address */
    function refundAll() external;

    /** @notice withdraws the fund invested for the given invest ID to the calling investor address 
        @param investId: ID of the investment */
    function refundWithInvestId(uint256 investId) external;

    /** @notice refunds all quotas to the given investor address
        @param investor: investor address */
    function refundToAddress(address investor) external;

    /** @notice withdraws fund to the calling collection's creator wallet address */
    function withdrawFund() external;

    /** @notice mints token IDs for an investor */
    function mint() external;

    /** @notice mints token IDs for an investor 
        @param investor: investor's address */
    function mint(address investor) external;

    /** @notice withdraws funds to given address
        @param receiver: fund receiver address
        @param amount: amount to withdraw */
    function withdrawToAddress(address receiver, uint256 amount) external;

    // --- From storage variables ---

    /** @notice reads minSoldRate public storage variable 
        @return uint256 value for the minimum rate of sold quotas */
    function getMinSoldRate() external view returns (uint256);

    /** @notice reads dueDate public storage variable 
        @return uint256 value for the crowdfunding due date timestamp */
    function getDueDate() external view returns (uint256);

    /** @notice reads nextInvestId public storage variable 
        @return uint256 value for the next investment ID */
    function getNextInvestId() external view returns (uint256);

    /** @notice reads investIdsPerInvestor public storage mapping
        @param investor: address of the investor
        @param index: array index
        @return uint256 value for the investment ID  */
    function getInvestIdsPerInvestor(
        address investor,
        uint256 index
    ) external view returns (uint256);

    /** @notice reads donationFee public storage variable 
        @return uint256 value for fee of donation (over 10000) */
    function getDonationFee() external view returns (uint256);

    /** @notice reads donationReceiver public storage variable 
        @return address of the donation receiver */
    function getDonationReceiver() external view returns (address);

    /** @notice reads paymentsPerCoin public storage mapping
        @param investor: address of the investor
        @param coin: coin of transfer
        @return uint256 value for amount deposited from the given investor, of the given coin  */
    function getPaymentsPerCoin(
        address investor,
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads collection public storage variable 
        @return IERC721Art instance of ERC721Art interface */
    function getCollection() external view returns (IERC721Art);

    /** @notice reads the investIdsPerInvestor public storage mapping 
        @param investor: address of the investor 
        @return uint256 array of invest IDs */
    function getAllInvestIdsPerInvestor(
        address investor
    ) external view returns (uint256[] memory);

    /** @notice reads the quotaInfos public storage mapping 
        @param class: QuotaClass class of quota 
        @return QuotaInfos struct of information about the given quota class */
    function getQuotaInfos(
        QuotaClass class
    ) external view returns (QuotaInfos memory);

    /** @notice reads the investIdInfos public storage mapping 
        @param investId: ID of the investment
        @return all information of the given invest ID */
    function getInvestIdInfos(
        uint256 investId
    ) external view returns (InvestIdInfos memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the reward contract of CreatorsPRO NFTs */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICRPReward {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error CRPReward__NotAllowed();

    ///@dev error for when the input arrays have not the same length
    error CRPReward__InputArraysNotSameLength();

    ///@dev error for when time unit is zero
    error CRPReward__TimeUnitZero();

    ///@dev error for when there are no rewards
    error CRPReward__NoRewards();

    ///@dev error for when an invalid coin is given
    error CRPReward__InvalidCoin();

    ///@dev error for when an invalid collection is calling a function
    error CRPReward__InvalidCollection();

    ///@dev error for when new interaction points precision is 0
    error CRPReward__InteracPointsPrecisionIsZero();

    ///@dev error for when new max reward claim value is 0
    error CRPReward__InvalidMaxRewardClaimValue();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev struct to store important token infos
        @param index: index of the token ID in the tokenIdsPerUser mapping
        @param hashpower: CreatorsPRO hashpower
        @param characteristId: CreatorsPRO characterist ID */
    struct TokenInfo {
        uint256 index; // 0 is for no longer listed
        uint256 hashpower;
        uint256 characteristId;
    }

    /** @dev struct to store user's info
        @param index: user index in usersArray storage array
        @param score: sum of the hashpowers from the NFTs owned by the user
        @param points: sum of interactions points done by the user
        @param timeOfLastUpdate: timestamp for the last information update
        @param unclaimedRewards: total amount of rewards still unclaimed
        @param conditionIdOflastUpdate: condition ID for the last update 
        @param collections: array of collection addresses of the user's NFTs */
    struct User {
        uint256 index; // 0 is for address no longer a user
        uint256 score;
        uint256 points;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
        address[] collections;
    }

    /** @dev struct for staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit)
        @param startTimestamp: timestamp for when the condition begins
        @param endTimestamp: timestamp for when the condition ends */
    struct RewardCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when points are added/increased
        @param user: user address
        @param tokenId: ID of the token
        @param points: amount of points increased
        @param value: value added/subtracted */
    event PointsSet(
        address indexed user,
        uint256 indexed tokenId,
        uint256 points,
        uint256 value
    );

    /** @dev event for when a token has been removed from tokenInfo mapping for
    the given user address
        @param user: user address
        @param tokenId: ID of the token */
    event TokenRemoved(address indexed user, uint256 indexed tokenId);

    /** @dev event for when rewards are claimed
        @param caller: address of the function caller (user)
        @param amount: amount of reward tokens claimed */
    event RewardsClaimed(address indexed caller, uint256 amount);

    /** @dev event for when the hash object for the tokenId is set.
        @param manager: address of the manager that has set the hash object
        @param collection: address of the collection
        @param tokenId: array of IDs of ERC721 token
        @param hashpower: array of hashpowers set by manager
        @param characteristId: array of IDs of the characterist */
    event HashObjectSet(
        address indexed manager,
        address indexed collection,
        uint256[] indexed tokenId,
        uint256[] hashpower,
        uint256[] characteristId
    );

    /** @dev event for when a new reward condition is set
        @param caller: function caller address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    event NewRewardCondition(
        address indexed caller,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    );

    /** @dev event for when new interacion points precision is set
        @param manager: manager address
        @param precision: array of precision values */
    event InteracPointsPrecisionSet(
        address indexed manager,
        uint256[3] precision
    );

    /** @dev event for when new max reward claim value is set
        @param manager: manager address
        @param maxRewardClaim: value for maximum reward claim */
    event MaxRewardClaimSet(address indexed manager, uint256 maxRewardClaim);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param management: Management contract address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time
        @param interacPoints: array of interaction points for each interaction (0: min, 1: send transfer, 2: receive transfer)
        @param maxRewardClaim:  maximum amount of claimable rewards */
    function initialize(
        address management,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime,
        uint256[3] calldata interacPoints,
        uint256 maxRewardClaim
    ) external;

    /** @notice increases the user score by the given amount
        @param user: user address
        @param tokenId: ID of the token 
        @param value: value added/subtracted
        @param coin: coin of transfer
        @param isSell: bool that specifies if is selling (true) or not (false) */
    function setPoints(
        address user,
        uint256 tokenId,
        uint256 value,
        uint8 coin,
        bool isSell
    ) external;

    /** @notice removes given token ID from given user address
        @param user: user address
        @param tokenId: token ID to be removed 
        @param emitEvent: true to emit event (external call), false otherwise (internal call)*/
    function removeToken(
        address user,
        uint256 tokenId,
        bool emitEvent
    ) external;

    /** @notice claims rewards to the caller wallet */
    function claimRewards() external;

    /** @notice sets hashpower and characterist ID for the given token ID
        @param collection: collection address
        @param tokenId: array of token IDs
        @param hashPower: array of hashpowers for the token ID
        @param characteristId: array of characterit IDs */
    function setHashObject(
        address collection,
        uint256[] memory tokenId,
        uint256[] memory hashPower,
        uint256[] memory characteristId
    ) external;

    /** @notice sets new reward condition
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    function setRewardCondition(
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    ) external;

    /** @notice sets new interaction points precision
        @param precision: array of new precision values */
    function setInteracPointsPrecision(uint256[3] calldata precision) external;

    /** @notice sets new maximum value for rewards claim
        @param maxRewardClaim: value for maximum reward claim */
    function setMaxRewardClaim(uint256 maxRewardClaim) external;

    // --- From storage variables ---

    /** @notice reads nextConditionId public storage variable 
        @return uint256 value for the next condition ID */
    function getNextConditionId() external view returns (uint256);

    // /** @notice reads totalScore public storage variable
    //     @return uint256 value for the sum of scores from all CreatorsPRO users */
    // function totalScore() external view returns (uint256);

    /** @notice reads usersArray public storage array 
        @param index: index of the array
        @return address of a user */
    function getUsersArray(uint256 index) external view returns (address);

    /** @notice reads collectionIndex public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 value for the collection index in User struct */
    function getCollectionIndex(
        address user,
        address collection
    ) external view returns (uint256);

    /** @notice reads tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @param index: index value for token IDs array
        @return uint256 value for the token ID  */
    function getTokenIdsPerUser(
        address user,
        address collection,
        uint256 index
    ) external view returns (uint256);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads hashObjects public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection
        @return uint256 values for hashpower and characterist ID */
    function getHashObject(
        address collection,
        uint256 tokenId
    ) external view returns (uint256, uint256);

    /** @notice reads tokenInfo public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection 
        @return TokenInfo struct with token infos */
    function getTokenInfo(
        address collection,
        uint256 tokenId
    ) external view returns (TokenInfo memory);

    /** @notice reads users public storage mapping 
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUser(address user) external view returns (User memory);

    /** @notice reads users public storage mapping, but the values are updated
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUserUpdated(address user) external view returns (User memory);

    /** @notice reads rewardCondition public storage mapping 
        @return RewardCondition struct with current reward condition info */
    function getCurrentRewardCondition()
        external
        view
        returns (RewardCondition memory);

    /** @notice reads rewardCondition public storage mapping 
        @param conditionId: condition ID
        @return RewardCondition struct with reward condition info */
    function getRewardCondition(
        uint256 conditionId
    ) external view returns (RewardCondition memory);

    /** @notice reads all token IDs from the array of tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 array for the token IDs  */
    function getAllTokenIdsPerUser(
        address user,
        address collection
    ) external view returns (uint256[] memory);

    /** @notice reads interacPointsPrecision storage variable
        @return uint256[3] array with interaction points precision values */
    function getInteracPointsPrecision()
        external
        view
        returns (uint256[3] memory);

    /** @notice reads maxRewardClaim storage variable
        @return uint256 value for maximum allowed rewards claim */
    function getMaxRewardClaim() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC20 burnable contract */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Metadata} from "../@openzeppelin/token/IERC20Metadata.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC20Burnable is IERC20Metadata {
    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @notice mints given amount of tokens to given address.       
        @param to: address for which tokens will be minted.
        @param amount: amount of tokens to mint .
        @return bool that specifies if mint was successful (true) or not (false). */
    function mint(address to, uint256 amount) external returns (bool);

    /** @notice burns given amount tokens from given account address.      
        @param account: account address from which tokens will be burned
        @param amount: amount of tokens to burn
        @return bool that specifies if tokens burn was successful (true) or not (false) */
    function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC721Art {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the collection max supply is reached (when maxSupply > 0)
    error ERC721Art__MaxSupplyReached();

    ///@dev error for when the value sent or the allowance is not enough to mint/buy token
    error ERC721Art__NotEnoughValueOrAllowance();

    ///@dev error for when caller is neighter manager nor collection creator
    error ERC721Art__NotAllowed();

    ///@dev error for when caller is not token owner
    error ERC721Art__NotTokenOwner();

    ///@dev error for when collection is for a crowdfund
    error ERC721Art__CollectionForFund();

    ///@dev error for when an invalid crowdfund address is set
    error ERC721Art__InvalidCrowdFund();

    ///@dev error for when the caller is not the crowdfund contract
    error ERC721Art__CallerNotCrowdfund();

    ///@dev error for when a crowfund address is already set
    error ERC721Art__CrodFundIsSet();

    ///@dev error for when input arrays don't have same length
    error ERC721Art__ArraysDoNotMatch();

    ///@dev error for when an invalid ERC20 contract address is given
    error ERC721Art__InvalidAddress();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new mint price is set.
        @param newPrice: new mint price 
        @param coin: token/coin of transfer */
    event PriceSet(uint256 indexed newPrice, IManagement.Coin indexed coin);

    /** @dev event for when owner sets new price for his/her token.
        @param tokenId: ID of ERC721 token
        @param price: new token price
        @param coin: token/coin of transfer */
    event TokenPriceSet(
        uint256 indexed tokenId,
        uint256 price,
        IManagement.Coin indexed coin
    );

    /** @dev event for when royalties transfers are done (mint).
        @param tokenId: ID of ERC721 token
        @param creatorsProRoyalty: royalty to CreatorsPRO
        @param creatorRoyalty: royalty to collection creator 
        @param fromWallet: address from which the payments was made */
    event RoyaltiesTransferred(
        uint256 indexed tokenId,
        uint256 creatorsProRoyalty,
        uint256 creatorRoyalty,
        address fromWallet
    );

    /** @dev event for when owner payments are done (creatorsProSafeTransferFrom).
        @param tokenId: ID of ERC721 token
        @param owner: owner address
        @param amount: amount transferred */
    event OwnerPaymentDone(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 amount
    );

    /** @dev event for when a new royalty fee is set
        @param _royalty: new royalty fee value */
    event RoyaltySet(uint256 _royalty);

    /** @dev event for when a new crowdfund address is set
        @param _crowdfund: address from crowdfund */
    event CrowdfundSet(address indexed _crowdfund);

    /** @dev event for when a new max discount for an ERC20 contract is set
        @param token: ERC20 contract address
        @param discount: discount value */
    event MaxDiscountSet(address indexed token, uint256 discount);

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /** @notice event for when a new coreSFT address is set
        @param caller: function's caller address
        @param _coreSFT: new address for the SFT protocol */
    event NewCoreSFTSet(address indexed caller, address _coreSFT);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param name_: name of the NFT collection
        @param symbol_: symbol of the NFT collection
        @param owner_: collection owner/creator
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price_: mint price of a single NFT
        @param priceInUSD: mint price of a single NFT
        @param priceInCreatorsCoin: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
            (final value = _royalty / 10000 (ERC2981Upgradeable._feeDenominator())) */
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 maxSupply,
        uint256 price_,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice mints given the NFT of given tokenId, using the given coin for transfer. Payable function.
        @param tokenId: tokenId to be minted 
        @param coin: token/coin of transfer 
        @param discount: discount given for NFT mint */
    function mint(
        uint256 tokenId,
        IManagement.Coin coin,
        uint256 discount
    ) external payable;

    /** @notice mints NFT of the given tokenId to the given address
        @param to: address to which the ticket is going to be minted
        @param tokenId: tokenId (batch) of the ticket to be minted */
    function mintToAddress(address to, uint256 tokenId) external;

    /** @notice mints token for crowdfunding        
        @param tokenIds: array of token IDs to mint
        @param classes: array of classes 
        @param to: address from tokens owner */
    function mintForCrowdfund(
        uint256[] memory tokenIds,
        uint8[] memory classes,
        address to
    ) external;

    /** @notice burns NFT of the given tokenId.
        @param tokenId: token ID to be burned */
    function burn(uint256 tokenId) external;

    /** @notice safeTransferFrom function especifically for CreatorPRO. It enforces (onchain) the transfer of the 
        correct token price. Payable function.
        @param coin: which coin to use (0 => ETH, 1 => USD, 2 => CreatorsCoin)
        The other parameters are the same from safeTransferFrom function. */
    function creatorsProSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        IManagement.Coin coin
    ) external payable;

    /** @notice sets NFT mint price.
        @param price: new NFT mint price 
        @param coin: coin/token to be set */
    function setPrice(uint256 price, IManagement.Coin coin) external;

    /** @notice sets the price of the ginve token ID.
        @param tokenId: ID of token
        @param price: new price to be set 
        @param coin: coin/token to be set */
    function setTokenPrice(
        uint256 tokenId,
        uint256 price,
        IManagement.Coin coin
    ) external;

    /** @notice sets new base URI for the collection.
        @param uri: new base URI to be set */
    function setBaseURI(string memory uri) external;

    /** @notice sets new royaly value for NFT transfer
        @param royalty: new value for royalty */
    function setRoyalty(uint256 royalty) external;

    /** @notice sets the crowdfund address 
        @param crowdfund: crowdfund contract address */
    function setCrowdfund(address crowdfund) external;

    /** @notice sets maxDiscount mapping for given ERC20 address
        @param token: ERC20 contract address
        @param maxDiscount_: max discount value */
    function setMaxDiscount(address token, uint256 maxDiscount_) external;

    /** @notice sets new coreSFT address
        @param coreSFT_: new address for the SFT protocol */
    function setCoreSFT(address coreSFT_) external;

    /** @notice gets the price of mint for the given address
        @param token: ERC20 token contract address 
        @return uint256 price value in the given ERC20 token */
    function price(address token) external view returns (uint256);

    /** @notice withdraws funds to given address
        @param receiver: fund receiver address
        @param amount: amount to withdraw */
    function withdrawToAddress(address receiver, uint256 amount) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- From storage variables ---

    /** @notice reads maxSupply public storage variable
        @return uint256 value of maximum supply */
    function getMaxSupply() external view returns (uint256);

    /** @notice reads baseURI public storage variable 
        @return string of the base URI */
    function getBaseURI() external view returns (string memory);

    /** @notice reads price public storage mapping
        @param coin: coin/token for price
        @return uint256 value for price */
    function getPricePerCoin(
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads lastTransfer public storage mapping 
        @param tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function getLastTransfer(uint256 tokenId) external view returns (uint256);

    /** @notice reads tokenPrice public storage mapping 
        @param tokenId: ID of the token
        @param coin: coin/token for specific token price 
        @return uint256 value for price of specific token */
    function getTokenPrice(
        uint256 tokenId,
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads crowdfund public storage variable 
        @return address of the set crowdfund contract */
    function getCrowdfund() external view returns (address);

    /** @notice reads maxDiscountPerCoin public storage mapping by address
        @param token: ERC20 contract address
        @return uint256 for the max discount of the SFTRec protocol */
    function maxDiscount(address token) external view returns (uint256);

    /** @notice gets the royalty info (address and value) from ERC2981
        @return royalty receiver address and value */
    function getRoyalty() external view returns (address, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the management contract from CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Burnable} from "./IERC20Burnable.sol";
import {ICRPReward} from "./ICRPReward.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IManagement {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error Management__NotAllowed();

    ///@dev error for when collection name is invalid
    error Management__InvalidName();

    ///@dev error for when collection symbol is invalid
    error Management__InvalidSymbol();

    ///@dev error for when the input is an invalid address
    error Management__InvalidAddress();

    ///@dev error for when the resulting max supply is 0
    error Management__FundMaxSupplyIs0();

    ///@dev error for when a token contract address is set for ETH/MATIC
    error Management__CannotSetAddressForETH();

    ///@dev error for when creator is corrupted
    error Management__CreatorCorrupted();

    ///@dev error for when an invalid collection address is given
    error Management__InvalidCollection();

    ///@dev error for when not the collection creator address calls function
    error Management__NotCollectionCreator();

    ///@dev error for when given address is not allowed creator
    error Management__AddressNotCreator();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the coin/token of transfer 
        @param ETH_COIN: ETH
        @param USD_TOKEN: a US dollar stablecoin        
        @param CREATORS_TOKEN: ERC20 token from CreatorsPRO
        @param REPUTATION_TOKEN: ERC20 token for reputation */
    enum Coin {
        ETH_COIN,
        USD_TOKEN,
        CREATORS_TOKEN,
        REPUTATION_TOKEN
    }

    /** @dev struct to be used as imput parameter that comprises with values for
    setting the crowdfunding contract   
        @param valuesLowQuota: array of values for the low class quota in ETH, USD token, and CreatorsPRO token
        @param valuesRegQuota: array of values for the regular class quota in ETH, USD token, and CreatorsPRO token 
        @param valuesHighQuota: array of values for the high class quota in ETH, USD token, and CreatorsPRO token 
        @param amountLowQuota: amount of low class quotas available 
        @param amountRegQuota: amount of low regular quotas available
        @param amountHighQuota: amount of low high quotas available 
        @param donationReceiver: address for the donation receiver 
        @param donationFee: fee value for the donation
        @param minSoldRate: minimum rate of sold quotas */
    struct CrowdFundParams {
        uint256[3] valuesLowQuota;
        uint256[3] valuesRegQuota;
        uint256[3] valuesHighQuota;
        uint256 amountLowQuota;
        uint256 amountRegQuota;
        uint256 amountHighQuota;
        address donationReceiver;
        uint256 donationFee;
        uint256 minSoldRate;
    }

    /** @dev struct used for store creators info
        @param escrow: escrow address for a creator
        @param isAllowed: defines if address is an allowed creator (true) or not (false) */
    struct Creator {
        address escrow;
        bool isAllowed;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new ERC721 art collection is instantiated
        @param collection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event ArtCollection(
        address indexed collection,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a new ERC721 crowdfund collection is instantiated
        @param fundCollection: new ERC721 crowdfund collection address
        @param artCollection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event Crowdfund(
        address indexed fundCollection,
        address indexed artCollection,
        address indexed creator,
        address caller
    );

    /** @dev event for when a new ERC721 collection from CreatorsPRO staff is instantiated
        @param collection: new ERC721 address
        @param creator: creator address of the ERC721 collection */
    event CreatorsCollection(
        address indexed collection,
        address indexed creator
    );

    /** @dev event for when a creator address is set
        @param creator: the creator address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event CreatorSet(
        address indexed creator,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new beacon admin address for ERC721 art collection contract is set
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminArt(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 crowdfund collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminFund(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 CreatorsPRO collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminCreators(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new multisig wallet address is set
        @param multisig: new multisig wallet address
        @param manager: the manager address that has done the setting */
    event NewMultiSig(address indexed multisig, address indexed manager);

    /** @dev event for when a new royalty fee is set
        @param newFee: new royalty fee
        @param manager: the manager address that has done the setting */
    event NewFee(uint256 indexed newFee, address indexed manager);

    /** @dev event for when a creator address is set
        @param setManager: the manager address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event ManagerSet(
        address indexed setManager,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new token contract address is set
        @param manager: address of the manager that has set the hash object
        @param token: address of the token contract 
        @param coin: coin/token of the contract */
    event TokenContractSet(
        address indexed manager,
        address indexed token,
        Coin coin
    );

    /** @dev event for when a new ERC721 staking contract is instantiated
        @param staking: new ERC721 staking contract address
        @param creator: contract creator address 
        @param caller: caller address of the function */
    event CRPStaking(
        address indexed staking,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a creator's address is set to corrupted (true) or not (false) 
        @param manager: maanger's address
        @param creator: creator's address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    event CorruptedAddressSet(
        address indexed manager,
        address indexed creator,
        bool corrupted
    );

    /** @dev event for when a new beacon admin address for ERC721 staking contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminStaking(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new proxy address for reward contract is set 
        @param proxy: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewProxyReward(address indexed proxy, address indexed manager);

    /** @dev event for when a CreatorsPRO collection is set
        @param collection: collection address
        @param set: true if collection is from CreatorsPRO, false otherwise */
    event CollectionSet(address indexed collection, bool set);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @dev smart contract's initializer/constructor.
        @param beaconAdminArt: address of the beacon admin for the creators ERC721 art smart contract 
        @param beaconAdminFund: address of the beacon admin for the creators ERC721 fund smart contract
        @param beaconAdminCreators: address of the beacon admin for the CreatorPRO ERC721 smart contract 
        @param erc20USD: address of a stablecoin contract (USDC/USDT/DAI)
        @param multiSig: address of the Multisig smart contract
        @param fee: royalty fee */
    function initialize(
        address beaconAdminArt,
        address beaconAdminFund,
        address beaconAdminCreators,
        address erc20USD,
        address multiSig,
        uint256 fee
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
        @param owner: owner address of the collection */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty,
        address owner
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param owner: owner address of the collection
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        address owner,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new CreatorPRO NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata */
    function newCreatorsCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSDC,
        uint256 priceInCreatorsCoin,
        string memory baseURI
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward
        @param owner: owner address of the collection */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime,
        address owner
    ) external;

    // --- Setter functions ---

    /** @notice sets creator permission.
        @param creator: creator address
        @param allowed: boolean that specifies if creator address has permission (true) or not (false) */
    function setCreator(address creator, bool allowed) external;

    /** @notice sets manager permission.
        @param manager: manager address
        @param allowed: boolean that specifies if manager address has permission (true) or not (false) */
    function setManager(address manager, bool allowed) external;

    /** @notice sets new beacon admin address for the creators ERC721 art smart contract.
        @param beacon: new address */
    function setBeaconAdminArt(address beacon) external;

    /** @notice sets new beacon admin address for the creators ERC721 fund smart contract.
        @param beacon: new address */
    function setBeaconAdminFund(address beacon) external;

    /** @notice sets new beacon admin address for the CreatorPRO ERC721 smart contract.
        @param beacon: new address */
    function setBeaconAdminCreators(address beacon) external;

    /** @notice sets new address for the Multisig smart contract.
        @param multisig: new address */
    function setMultiSig(address multisig) external;

    /** @notice sets new fee for NFT minting.
        @param fee: new fee */
    function setFee(uint256 fee) external;

    /** @notice sets new contract address for the given token 
        @param coin: coin/token for the given contract address
        @param token: new address of the token contract */
    function setTokenContract(Coin coin, address token) external;

    /** @notice sets given creator address to corrupted (true) or not (false)
        @param creator: creator address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    function setCorrupted(address creator, bool corrupted) external;

    /** @notice sets new beacon admin address for the ERC721 staking smart contract.
        @param beacon: new address */
    function setBeaconAdminStaking(address beacon) external;

    /** @notice sets new proxy address for the reward smart contract.
        @param proxy: new address */
    function setProxyReward(address proxy) external;

    /** @notice sets new collection address
        @param collection: collection address
        @param set: true (collection from CreatorsPRO) or false */
    function setCollections(address collection, bool set) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- Getter functions ---

    // --- From storage variables ---

    /** @notice reads beaconAdminArt storage variable
        @return address of the beacon admin for the art collection (ERC721) contract */
    function getBeaconAdminArt() external view returns (address);

    /** @notice reads beaconAdminFund storage variable
        @return address of the beacon admin for the crowdfund (ERC721) contract */
    function getBeaconAdminFund() external view returns (address);

    /** @notice reads beaconAdminCreators storage variable
        @return address of the beacon admin for the CreatorsPRO collection (ERC721) contract */
    function getBeaconAdminCreators() external view returns (address);

    /** @notice reads beaconAdminStaking storage variable
        @return address of the beacon admin for staking contract */
    function getBeaconAdminStaking() external view returns (address);

    /** @notice reads proxyReward storage variable
        @return address of the beacon admin for staking contract */
    function getProxyReward() external view returns (ICRPReward);

    /** @notice reads multiSig storage variable 
        @return address of the multisig wallet */
    function getMultiSig() external view returns (address);

    /** @notice reads fee storage variable 
        @return the royalty fee */
    function getFee() external view returns (uint256);

    /** @notice reads managers storage mapping
        @param caller: address to check if is manager
        @return boolean if the given address is a manager */
    function getManagers(address caller) external view returns (bool);

    /** @notice reads tokenContract storage mapping
        @param coin: coin/token for the contract address
        @return IERC20 instance for the given coin/token */
    function getTokenContract(Coin coin) external view returns (IERC20Burnable);

    /** @notice reads isCorrupted storage mapping 
        @param creator: creator address
        @return bool that sepcifies if creator is corrupted (true) or not (false) */
    function getIsCorrupted(address creator) external view returns (bool);

    /** @notice reads collections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if collection is from CreatorsPRO (true) or not (false)  */
    function getCollections(address collection) external view returns (bool);

    /** @notice reads stakingCollections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if staking collection is from CreatorsPRO (true) or not (false)  */
    function getStakingCollections(
        address collection
    ) external view returns (bool);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads creators storage mapping
        @param caller: address to check if is allowed creator
        @return Creator struct with creator info */
    function getCreator(address caller) external view returns (Creator memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Security settings for upgradeable smart contracts */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IManagement} from "./interfaces/IManagement.sol";

///@dev security settings.
import {Initializable} from "./@openzeppelin/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "./@openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "./@openzeppelin/upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "./@openzeppelin/upgradeable/security/PausableUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Errors
/// -----------------------------------------------------------------------

///@dev error for when the crowdfund has past due data
error SecurityUpgradeable__NotAllowed();

///@dev error for when the collection/creator has been corrupted
error SecurityUpgradeable__CollectionOrCreatorCorrupted();

///@dev error for when ETH/MATIC transfer fails
error SecurityUpgradeable__TransferFailed();

///@dev error for when ERC20 transfer fails
error SecurityUpgradeable__ERC20TransferFailed();

///@dev error for when ERC20 mint fails
error SecurityUpgradeable__ERC20MintFailed();

///@dev error for when an invalid coin is used
error SecurityUpgradeable__InvalidCoin();

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract SecurityUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    ///@dev Management contract
    IManagement internal s_management;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    ///@dev internal function for whenNotPaused modifier
    function _whenNotPaused() internal view whenNotPaused {}

    ///@dev internal function for nonReentrant modifier
    function _nonReentrant() internal nonReentrant {}

    ///@dev internal function for onlyOwner modifier
    function _onlyOwner() internal view onlyOwner {}

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    function _onlyManagers() internal view virtual {
        if (!s_management.getManagers(msg.sender)) {
            revert SecurityUpgradeable__NotAllowed();
        }
    }

    ///@dev checks if caller is authorized
    function _onlyAuthorized() internal view virtual {
        if (!s_management.getIsCorrupted(owner())) {
            if (
                !(s_management.getManagers(msg.sender) ||
                    msg.sender == address(s_management) ||
                    msg.sender == owner())
            ) {
                revert SecurityUpgradeable__NotAllowed();
            }
        } else {
            if (
                !(s_management.getManagers(msg.sender) ||
                    msg.sender == address(s_management))
            ) {
                revert SecurityUpgradeable__NotAllowed();
            }
        }
    }

    ///@dev checks if collection/creator is corrupted
    function _notCorrupted() internal view virtual {
        if (s_management.getIsCorrupted(owner())) {
            revert SecurityUpgradeable__CollectionOrCreatorCorrupted();
        }
    }

    ///@dev checks if used coin is valid
    function _onlyValidCoin(IManagement.Coin coin) internal pure virtual {
        if (coin == IManagement.Coin.REPUTATION_TOKEN) {
            revert SecurityUpgradeable__InvalidCoin();
        }
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @dev initiates all security dependencies. Uses onlyInitializing modifier.
        @param owner_: address of contract owner */
    function _SecurityUpgradeable_init(
        address owner_
    ) internal onlyInitializing {
        __Ownable_init();
        transferOwnership(owner_);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // --- Pause and Unpause functions ---

    /** @notice pauses the contract so that functions cannot be executed.
        Uses _pause internal function from PausableUpgradeable. */
    function pause() public virtual {
        _nonReentrant();

        _pause();
    }

    /** @notice unpauses the contract so that functions can be executed        
        Uses _pause internal function from PausableUpgradeable. */
    function unpause() public virtual {
        _nonReentrant();

        _unpause();
    }

    // --- Implemented functions ---

    /** @notice performs ETH/MATIC transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferTo(address to, uint256 amount) internal virtual {
        (bool success, ) = payable(to).call{value: amount}("");

        if (!success) {
            revert SecurityUpgradeable__TransferFailed();
        }
    }

    /** @notice performs ERC20 transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param coin: ERC20 coin to transfer
        @param from: transfer sender address
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferERC20To(
        IManagement.Coin coin,
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (coin == IManagement.Coin.ETH_COIN) {
            revert SecurityUpgradeable__InvalidCoin();
        }

        bool success;
        if (from == address(this)) {
            success = s_management.getTokenContract(coin).transfer(to, amount);
        } else {
            success = s_management.getTokenContract(coin).transferFrom(
                from,
                to,
                amount
            );
        }

        if (!success) {
            revert SecurityUpgradeable__ERC20TransferFailed();
        }
    }

    /** @notice performs ERC20 mint using the call low-level function. It reverts if
        mint fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param coin: ERC20 coin to mint
        @param to: mint receiver address
        @param amount: amount to mint */
    function _mintERC20Token(
        IManagement.Coin coin,
        address to,
        uint256 amount
    ) internal {
        if (coin == IManagement.Coin.ETH_COIN) {
            revert SecurityUpgradeable__InvalidCoin();
        }

        bool success = s_management.getTokenContract(coin).mint(to, amount);

        if (!success) {
            revert SecurityUpgradeable__ERC20MintFailed();
        }
    }

    /** @notice reads management public storage variable 
        @return IManagement instance of Management interface */
    function getManagement() external view returns (IManagement) {
        return s_management;
    }
}