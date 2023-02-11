/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {AbstractRouteAdapter} from '../abstracts/AbstractRouteAdapter.sol';
import {Router} from '@abacus-network/app/contracts/Router.sol';
import {IRoute} from '../interfaces/IRoute.sol';
import {IRouteReceiver} from '../interfaces/IRouteReceiver.sol';

/**
 * @author Flowcarbon LLC
 * @title Hyperlane Route Adapter Contract
 */
contract HyperlaneRouteAdapter is
        IRoute,
        AbstractRouteAdapter,
        Router {

    // ================
    // Public Constants
    // ================

    /** @notice Adapter name and version. */
    bytes32 constant public IDENTIFIER = keccak256('HYPERLANE_v1.0.0');

    // =================
    // Public Properties
    // =================

    /** @notice Maps chain IDs to hyperlane domain identifiers. */
    mapping(uint32 => uint32) public chainToDomain;

    /** @notice Maps hyperlane domain identifiers to chain IDs. */
    mapping(uint32 => uint32) public domainToChain;

    // ========================
    // Initialization Functions
    // ========================

    /**
     * @param connectionManager_ - Address of hyperlane's connection manager.
     * @param interchainGasPaymaster_ - Address of hyperlane's interchain gas paymaster.
     * @param receiver_ - Route receiver.
     * @param operator_ - Account that is given operative privileges.
     */
    constructor(
        address connectionManager_,
        address interchainGasPaymaster_,
        IRouteReceiver receiver_,
        address operator_
    ) initializer {
        require(address(receiver_) != address(0),
            'HyperlaneRouteAdapter: receiver is required');
        require(operator_ != address(0),
            'HyperlaneRouteAdapter: operator is required');
        __Router_initialize(
            connectionManager_,
            interchainGasPaymaster_
        );
        transferOwnership(operator_);
        receiver = receiver_;
        _initDomains();
    }

    // ===================
    // Discovery Functions
    // ===================

    /** @dev See IRoute. */
    function getIdentifier() external pure returns (bytes32) {
        return IDENTIFIER;
    }

    // ========================
    // Administrative Functions
    // ========================

    /** @dev Set the domain identifier associated with the a chain. */
    function setDomain(uint32 chainId_, uint32 domain_) public onlyOwner {
        require(chainId_ != 0,
            'HyperlaneRouteAdapter: chain id is required');
        require(domain_ != 0,
            'HyperlaneRouteAdapter: domain is required');
        _setDomain(chainId_, domain_);
    }

    /** @dev Clear the domain identifier associated with a chain. */
    function unsetDomain(uint32 chainId_) public onlyOwner {
        uint32 domain = chainToDomain[uint32(chainId_)];
        if (domain != 0) {
            chainToDomain[chainId_] = 0;
            domainToChain[domain] = 0;
        }
    }

    /** @dev See IRoute. */
    function registerRemoteRoute(uint256 destination_, address contract_) external onlyReceiver {
        uint32 domain = chainToDomain[uint32(destination_)];
        require(domain != 0, 'HyperlaneRouteAdapter: unknown destination chain');
        _enrollRemoteRouter(uint32(domain), bytes32(uint256(uint160(contract_))));
    }

    // ==================
    // Internal Functions
    // ==================

    /** @dev Initialize domain identifiers. */
    function _initDomains() internal virtual {
        _setDomain(1, 0x657468);         // Ethereum
        _setDomain(5, 5);                // Ethereum Goerli
        _setDomain(42, 3000);            // Ethereum Kovan
        _setDomain(42161, 0x617262);     // Arbitrum
        _setDomain(421611, 0x61722d72);  // Arbitrum Rinkeby
        _setDomain(43114, 0x61766178);   // Avalanche
        _setDomain(43113, 43113);        // Avalanche Fuji
        _setDomain(56, 0x627363);        // BSC
        _setDomain(97, 0x62732d74);      // BSC Testnet
        _setDomain(42220, 0x63656c6f);   // Celo
        _setDomain(44787, 1000);         // Celo Alfajores
        _setDomain(10, 0x6f70);          // Optimism
        _setDomain(69, 0x6f702d6b);      // Optimism Kovan
        _setDomain(137, 0x706f6c79);     // Polygon
        _setDomain(80001, 80001);        // Polygon Mumbai
    }

    /** @dev Set the domain identifier associated with the a chain. */
    function _setDomain(uint32 chainId_, uint32 domain_) internal {
        chainToDomain[chainId_] = domain_;
        domainToChain[domain_] = chainId_;
    }

    /** @dev Hyperlane interface hook. */
    function _handle(uint32 source_, bytes32, bytes memory message_) internal virtual override {
        uint32 chainId = domainToChain[source_];
        require(chainId != 0, 'HyperlaneRouteAdapter: unknown source domain');
        receiver.handleSendMessage(uint256(chainId), message_);
    }

    /** @dev See IRoute. */
    function sendMessage(uint256 destination_, bytes memory payload_) external onlyReceiver payable {
        uint32 domain = chainToDomain[uint32(destination_)];
        require(domain != 0, 'HyperlaneRouteAdapter: unknown destination chain');
        _dispatchWithGas(uint32(domain), payload_, msg.value);
    }
}

/** SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import {IRouteReceiver} from '../interfaces/IRouteReceiver.sol';

/**
 * @author Flowcarbon LLC
 * @title Route Adapter Base-Contract
 */
abstract contract AbstractRouteAdapter {

    // =================
    // Public Properties
    // =================

    /** @notice Address of the local station that connects us to the cross-chain network. */
    IRouteReceiver public receiver;

    // =========
    // Modifiers
    // =========

    /** @dev Allows only the bridge receiver to access to a method. */
    modifier onlyReceiver() {
        require(msg.sender == address(receiver),
            'AbstractRouteAdapter: caller is not the route receiver');
        _;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {AbacusConnectionClient} from "./AbacusConnectionClient.sol";
import {IAbacusConnectionManager} from "@abacus-network/core/interfaces/IAbacusConnectionManager.sol";
import {IInterchainGasPaymaster} from "@abacus-network/core/interfaces/IInterchainGasPaymaster.sol";
import {IMessageRecipient} from "@abacus-network/core/interfaces/IMessageRecipient.sol";
import {IOutbox} from "@abacus-network/core/interfaces/IOutbox.sol";

abstract contract Router is AbacusConnectionClient, IMessageRecipient {
    // ============ Mutable Storage ============

    mapping(uint32 => bytes32) public routers;
    uint256[49] private __GAP; // gap for upgrade safety

    // ============ Events ============

    /**
     * @notice Emitted when a router is set.
     * @param domain The domain of the new router
     * @param router The address of the new router
     */
    event RemoteRouterEnrolled(uint32 indexed domain, bytes32 indexed router);

    // ============ Modifiers ============
    /**
     * @notice Only accept messages from a remote Router contract
     * @param _origin The domain the message is coming from
     * @param _router The address the message is coming from
     */
    modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
        require(_isRemoteRouter(_origin, _router), "!router");
        _;
    }

    // ======== Initializer =========
    function __Router_initialize(address _abacusConnectionManager)
        internal
        onlyInitializing
    {
        __AbacusConnectionClient_initialize(_abacusConnectionManager);
    }

    function __Router_initialize(
        address _abacusConnectionManager,
        address _interchainGasPaymaster
    ) internal onlyInitializing {
        __AbacusConnectionClient_initialize(
            _abacusConnectionManager,
            _interchainGasPaymaster
        );
    }

    // ============ External functions ============

    /**
     * @notice Register the address of a Router contract for the same Application on a remote chain
     * @param _domain The domain of the remote Application Router
     * @param _router The address of the remote Application Router
     */
    function enrollRemoteRouter(uint32 _domain, bytes32 _router)
        external
        virtual
        onlyOwner
    {
        _enrollRemoteRouter(_domain, _router);
    }

    /**
     * @notice Handles an incoming message
     * @param _origin The origin domain
     * @param _sender The sender address
     * @param _message The message
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) external virtual override onlyInbox onlyRemoteRouter(_origin, _sender) {
        // TODO: callbacks on success/failure
        _handle(_origin, _sender, _message);
    }

    // ============ Virtual functions ============
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) internal virtual;

    // ============ Internal functions ============

    /**
     * @notice Set the router for a given domain
     * @param _domain The domain
     * @param _router The new router
     */
    function _enrollRemoteRouter(uint32 _domain, bytes32 _router) internal {
        routers[_domain] = _router;
        emit RemoteRouterEnrolled(_domain, _router);
    }

    /**
     * @notice Return true if the given domain / router is the address of a remote Application Router
     * @param _domain The domain of the potential remote Application Router
     * @param _router The address of the potential remote Application Router
     */
    function _isRemoteRouter(uint32 _domain, bytes32 _router)
        internal
        view
        returns (bool)
    {
        return routers[_domain] == _router;
    }

    /**
     * @notice Assert that the given domain has a Application Router registered and return its address
     * @param _domain The domain of the chain for which to get the Application Router
     * @return _router The address of the remote Application Router on _domain
     */
    function _mustHaveRemoteRouter(uint32 _domain)
        internal
        view
        returns (bytes32 _router)
    {
        _router = routers[_domain];
        require(_router != bytes32(0), "!router");
    }

    /**
     * @notice Dispatches a message to an enrolled router via the local router's Outbox.
     * @notice Does not pay interchain gas.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _msg The message to dispatch.
     */
    function _dispatch(uint32 _destinationDomain, bytes memory _msg)
        internal
        returns (uint256)
    {
        return _dispatch(_outbox(), _destinationDomain, _msg);
    }

    /**
     * @notice Dispatches a message to an enrolled router via the local router's Outbox
     * and pays for it to be relayed to the destination.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _msg The message to dispatch.
     * @param _gasPayment The amount of native tokens to pay for the message to be relayed.
     */
    function _dispatchWithGas(
        uint32 _destinationDomain,
        bytes memory _msg,
        uint256 _gasPayment
    ) internal {
        IOutbox _outbox = _outbox();
        uint256 _leafIndex = _dispatch(_outbox, _destinationDomain, _msg);
        if (_gasPayment > 0) {
            interchainGasPaymaster.payGasFor{value: _gasPayment}(
                address(_outbox),
                _leafIndex,
                _destinationDomain
            );
        }
    }

    // ============ Private functions ============

    /**
     * @notice Dispatches a message to an enrolled router via the provided Outbox.
     * @dev Does not pay interchain gas.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _outbox The outbox contract to dispatch the message through.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _msg The message to dispatch.
     */
    function _dispatch(
        IOutbox _outbox,
        uint32 _destinationDomain,
        bytes memory _msg
    ) private returns (uint256) {
        // Ensure that destination chain has an enrolled router.
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return _outbox.dispatch(_destinationDomain, _router, _msg);
    }
}

/** SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

/**
 * @author Flowcarbon LLC
 * @title Route Interface
 */
interface IRoute {

    // ===================
    // Discovery Functions
    // ===================

    /**
     * @dev The identifier format is ROUTE_NAME_v1.0.0.
     * @return Keccak256 encoded identifier.
     */
    function getIdentifier() external pure returns (bytes32);

    // ========================
    // Administrative Functions
    // ========================

    /**
     * @notice Send a message to the remote chain.
     * @param destination_ - The chain id to which we want to send the message.
     * @param payload_ - The raw payload to send.
     */
    function sendMessage(uint256 destination_, bytes memory payload_) payable external;

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @notice Connect a contract on the terminal chain to this chain.
     * @dev The target contract needs to be an IRouteReceiver.
     * @param destination_ - The chain id with the respective route endpoint contract.
     * @param contract_ - The address on the terminal chain.
     */
    function registerRemoteRoute(uint256 destination_, address contract_) external;
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

/**
 * @author Flowcarbon LLC
 * @title Route Receiver Interface
 */
interface IRouteReceiver {

    // ==================
    // Protocol Functions
    // ==================

    /**
     * @notice Interface hook for inbound messages.
     * @param source_ - The chain ID from which this message was sent.
     * @param payload_ - The raw payload.
     */
    function handleSendMessage(uint256 source_, bytes memory payload_) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IInterchainGasPaymaster} from "@abacus-network/core/interfaces/IInterchainGasPaymaster.sol";
import {IOutbox} from "@abacus-network/core/interfaces/IOutbox.sol";
import {IAbacusConnectionManager} from "@abacus-network/core/interfaces/IAbacusConnectionManager.sol";

// ============ External Imports ============
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract AbacusConnectionClient is OwnableUpgradeable {
    // ============ Mutable Storage ============

    IAbacusConnectionManager public abacusConnectionManager;
    // Interchain Gas Paymaster contract. The relayer associated with this contract
    // must be willing to relay messages dispatched from the current Outbox contract,
    // otherwise payments made to the paymaster will not result in relayed messages.
    IInterchainGasPaymaster public interchainGasPaymaster;

    uint256[48] private __GAP; // gap for upgrade safety

    // ============ Events ============

    /**
     * @notice Emitted when a new abacusConnectionManager is set.
     * @param abacusConnectionManager The address of the abacusConnectionManager contract
     */
    event AbacusConnectionManagerSet(address indexed abacusConnectionManager);

    /**
     * @notice Emitted when a new Interchain Gas Paymaster is set.
     * @param interchainGasPaymaster The address of the Interchain Gas Paymaster.
     */
    event InterchainGasPaymasterSet(address indexed interchainGasPaymaster);

    // ============ Modifiers ============

    /**
     * @notice Only accept messages from an Abacus Inbox contract
     */
    modifier onlyInbox() {
        require(_isInbox(msg.sender), "!inbox");
        _;
    }

    // ======== Initializer =========

    function __AbacusConnectionClient_initialize(
        address _abacusConnectionManager
    ) internal onlyInitializing {
        _setAbacusConnectionManager(_abacusConnectionManager);
        __Ownable_init();
    }

    function __AbacusConnectionClient_initialize(
        address _abacusConnectionManager,
        address _interchainGasPaymaster
    ) internal onlyInitializing {
        _setInterchainGasPaymaster(_interchainGasPaymaster);
        __AbacusConnectionClient_initialize(_abacusConnectionManager);
    }

    // ============ External functions ============

    /**
     * @notice Sets the address of the application's AbacusConnectionManager.
     * @param _abacusConnectionManager The address of the AbacusConnectionManager contract.
     */
    function setAbacusConnectionManager(address _abacusConnectionManager)
        external
        virtual
        onlyOwner
    {
        _setAbacusConnectionManager(_abacusConnectionManager);
    }

    /**
     * @notice Sets the address of the application's InterchainGasPaymaster.
     * @param _interchainGasPaymaster The address of the InterchainGasPaymaster contract.
     */
    function setInterchainGasPaymaster(address _interchainGasPaymaster)
        external
        virtual
        onlyOwner
    {
        _setInterchainGasPaymaster(_interchainGasPaymaster);
    }

    // ============ Internal functions ============

    /**
     * @notice Sets the address of the application's InterchainGasPaymaster.
     * @param _interchainGasPaymaster The address of the InterchainGasPaymaster contract.
     */
    function _setInterchainGasPaymaster(address _interchainGasPaymaster)
        internal
    {
        interchainGasPaymaster = IInterchainGasPaymaster(
            _interchainGasPaymaster
        );
        emit InterchainGasPaymasterSet(_interchainGasPaymaster);
    }

    /**
     * @notice Modify the contract the Application uses to validate Inbox contracts
     * @param _abacusConnectionManager The address of the abacusConnectionManager contract
     */
    function _setAbacusConnectionManager(address _abacusConnectionManager)
        internal
    {
        abacusConnectionManager = IAbacusConnectionManager(
            _abacusConnectionManager
        );
        emit AbacusConnectionManagerSet(_abacusConnectionManager);
    }

    /**
     * @notice Get the local Outbox contract from the abacusConnectionManager
     * @return The local Outbox contract
     */
    function _outbox() internal view returns (IOutbox) {
        return abacusConnectionManager.outbox();
    }

    /**
     * @notice Determine whether _potentialInbox is an enrolled Inbox from the abacusConnectionManager
     * @return True if _potentialInbox is an enrolled Inbox
     */
    function _isInbox(address _potentialInbox) internal view returns (bool) {
        return abacusConnectionManager.isInbox(_potentialInbox);
    }

    /**
     * @notice Get the local domain from the abacusConnectionManager
     * @return The local domain
     */
    function _localDomain() internal view virtual returns (uint32) {
        return abacusConnectionManager.localDomain();
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IOutbox} from "./IOutbox.sol";

interface IAbacusConnectionManager {
    function outbox() external view returns (IOutbox);

    function isInbox(address _inbox) external view returns (bool);

    function localDomain() external view returns (uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payGasFor(
        address _outbox,
        uint256 _leafIndex,
        uint32 _destinationDomain
    ) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IMailbox} from "./IMailbox.sol";

interface IOutbox is IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (uint256);

    function cacheCheckpoint() external;

    function latestCheckpoint() external view returns (bytes32, uint256);

    function count() external returns (uint256);

    function fail() external;

    function cachedCheckpoints(bytes32) external view returns (uint256);

    function latestCachedCheckpoint()
        external
        view
        returns (bytes32 root, uint256 index);
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMailbox {
    function localDomain() external view returns (uint32);
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