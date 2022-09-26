/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// File: @hyperlane-xyz/core/interfaces/IMessageRecipient.sol


pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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

// File: @hyperlane-xyz/core/interfaces/IMailbox.sol


pragma solidity >=0.6.11;

interface IMailbox {
    function localDomain() external view returns (uint32);

    function validatorManager() external view returns (address);
}

// File: @hyperlane-xyz/core/interfaces/IOutbox.sol


pragma solidity >=0.6.11;


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

// File: @hyperlane-xyz/core/interfaces/IAbacusConnectionManager.sol


pragma solidity >=0.6.11;


interface IAbacusConnectionManager {
    function outbox() external view returns (IOutbox);

    function isInbox(address _inbox) external view returns (bool);

    function localDomain() external view returns (uint32);
}

// File: @hyperlane-xyz/core/interfaces/IInterchainGasPaymaster.sol


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

// File: @hyperlane-xyz/app/contracts/AbacusConnectionClient.sol


pragma solidity >=0.6.11;

// ============ Internal Imports ============




// ============ External Imports ============


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

// File: @hyperlane-xyz/app/contracts/Router.sol


pragma solidity >=0.6.11;

// ============ Internal Imports ============






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

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @uniswap/v2-periphery/contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/headenfinanceparent.sol


pragma solidity ^0.8.4;
pragma abicoder v2;








interface ChainLinkAggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IMultiChain {
    function anySwapOut(address token, address to, uint amount, uint toChainID) external;
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
    function anySwapOut(address[] calldata tokens, address[] calldata to, uint[] calldata amounts, uint[] calldata toChainIDs) external;

}

interface IHyperLane {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _messageBody
    ) external;

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (uint256);
}

interface IDeBridge {
    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external payable;
}

contract chainLinkFeedUSDC {
    ChainLinkAggregatorInterface chainLink = ChainLinkAggregatorInterface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0);
}

// Mumbai testnet
contract HeadenFinanceParent is chainLinkFeedUSDC, ReentrancyGuard, KeeperCompatibleInterface, Router{
    address swapRouter;
    string  hashSalt;
    uint public tax = 350; //3.5%
    uint public immutable interval;
    uint public lastTimeStamp = block.timestamp;
    uint32 public chainId;
    uint32 public immutable defaultId = 0;
    uint public SECONDS_PER_YEAR = 3600 * 24 * 365;
    address public multichainRouter;
    address public usdc;
    address public dai;
    address public matic;
    uint multiplier = 10**18;

    uint public  supplyKink;
    uint public  supplyPerSecondInterestRateSlopeLow;
    uint public  supplyPerSecondInterestRateSlopeHigh;
    uint public  supplyPerSecondInterestRateBase;
    uint public  borrowKink;
    uint public  borrowPerSecondInterestRateSlopeLow;
    uint public  borrowPerSecondInterestRateSlopeHigh;
    uint public  borrowPerSecondInterestRateBase;

    struct Configuration {
        uint64 supplyKink;
        uint64 supplyPerYearInterestRateSlopeLow;
        uint64 supplyPerYearInterestRateSlopeHigh;
        uint64 supplyPerYearInterestRateBase;
        uint64 borrowKink;
        uint64 borrowPerYearInterestRateSlopeLow;
        uint64 borrowPerYearInterestRateSlopeHigh;
        uint64 borrowPerYearInterestRateBase;
    }

    //user specific
    struct User {
        address userAddress;
        bool available;
        uint totalAmountBorrowed; //in usd up to 8 decimal places
        uint totalAmountStaked; //in usd
        uint creditScore; //max is 10000
        uint ltv;
        bool lock;
    }

    //stake specific
    struct UserStake {
        address userAddress;
        address tokenAddress;
        bool available;
        uint amountStaked; 
        uint timeLastStaked;
    }

    //borrow/collateral specific
    struct UserBorrow {
        address userAddress;
        address tokenAddress;
        bool available;
        uint amountBorrowed; //amount of token address borrowed
        address collateralAddress;
        uint collateralAmount;
        address borrowRouter;
        uint timeLastBorrowed;
    }

    struct Market {
        address tokenAddress;
        bool available;
        uint amountStaked;
        uint amountBorrowed;
        uint timeLastBorrowed;
        uint timeLastStaked;
        uint borrowRate;
        uint supplyRate;
    }

    struct FullUpdateData {
        address user;
        uint totalStakes;
        uint totalBorrows;
    }
    struct MarketToken{
        bool available;
        uint128 _id;
    }

    //mapping (address=>User) public users;
    mapping (uint32=>mapping(address=>User)) public users;
    mapping (bytes32=>UserBorrow) public usersborrows;
    mapping (bytes32=>UserStake) public userstakes;
    mapping (uint128 => Market) public markets;
    mapping (address => MarketToken) public marketTokens;
    mapping (address => bool) public relayers;
    uint128 market_pools = 0;
    //string[] availableTokens;
    address[] userAddresses;
    uint32[] chains;

    event ParentChainSynced(address user, uint totalStakes, uint totalBorrows);
    event FullParentChainSynced(FullUpdateData[] usersdata);

    constructor(uint _interval, uint32 _chainId, address _multichainRouter, string memory _hashSalt, address _swapRouter, address _usdc, address _dai, address _matic, Configuration memory config){
        interval = _interval;
        lastTimeStamp = block.timestamp;
        chainId = _chainId;
        multichainRouter=_multichainRouter;
        relayers[msg.sender] = true;
        hashSalt =_hashSalt;
        swapRouter=_swapRouter;
        dai = _dai;
        usdc = _usdc;
        matic = _matic;
        chains.push(_chainId);
        _setAbacusConnectionManager(0xb636B2c65A75d41F0dBe98fB33eb563d245a241a);
        // Set IGP contract address
        _setInterchainGasPaymaster(0x9A27744C249A11f68B3B56f09D280599585DFBb8);

        // Set interest rate model configs
        unchecked {
            supplyKink = config.supplyKink;
            supplyPerSecondInterestRateSlopeLow = config.supplyPerYearInterestRateSlopeLow / SECONDS_PER_YEAR;
            supplyPerSecondInterestRateSlopeHigh = config.supplyPerYearInterestRateSlopeHigh / SECONDS_PER_YEAR;
            supplyPerSecondInterestRateBase = config.supplyPerYearInterestRateBase / SECONDS_PER_YEAR;
            borrowKink = config.borrowKink;
            borrowPerSecondInterestRateSlopeLow = config.borrowPerYearInterestRateSlopeLow / SECONDS_PER_YEAR;
            borrowPerSecondInterestRateSlopeHigh = config.borrowPerYearInterestRateSlopeHigh / SECONDS_PER_YEAR;
            borrowPerSecondInterestRateBase = config.borrowPerYearInterestRateBase / SECONDS_PER_YEAR;
        }
    }

    function updateSettings (Configuration calldata config, address _relayer) external onlyOwner{
        relayers[_relayer] = true;
        unchecked {
            supplyKink = config.supplyKink;
            supplyPerSecondInterestRateSlopeLow = config.supplyPerYearInterestRateSlopeLow / SECONDS_PER_YEAR;
            supplyPerSecondInterestRateSlopeHigh = config.supplyPerYearInterestRateSlopeHigh / SECONDS_PER_YEAR;
            supplyPerSecondInterestRateBase = config.supplyPerYearInterestRateBase / SECONDS_PER_YEAR;
            borrowKink = config.borrowKink;
            borrowPerSecondInterestRateSlopeLow = config.borrowPerYearInterestRateSlopeLow / SECONDS_PER_YEAR;
            borrowPerSecondInterestRateSlopeHigh = config.borrowPerYearInterestRateSlopeHigh / SECONDS_PER_YEAR;
            borrowPerSecondInterestRateBase = config.borrowPerYearInterestRateBase / SECONDS_PER_YEAR;
        }
    }

    function registerChildChain(uint32 _chainId) public onlyOwner{
        chains.push(_chainId);
    }

    // ---- UTILS ----

    function getAvgPriceForTokens(uint amountIn, address _router, address[] memory path) internal view returns(uint){
       uint[] memory amount = IUniswapV2Router02(_router).getAmountsOut(amountIn, path);
       return amount[amount.length-1];
    }

    function findBestPairWithStableCoin  (address token) internal view returns (address[] memory){
         address[] memory path = new address[](2);
        path[0] = token;
        path[1] = usdc;
        
        // try direct pair
        uint result = getAvgPriceForTokens(1*multiplier, swapRouter, path);
        if(result > 0){
            return path;
        }
        path = new address[](3);
        
        path[0] = token;
        path[1] = dai;
        path[2] = usdc;
        result = getAvgPriceForTokens(1*multiplier, swapRouter, path);
        if(result >0){
            return path;
        }         
        
        //try matic in between
        path[1] = matic;
        path[2] = usdc;
        result = getAvgPriceForTokens(1*multiplier, swapRouter, path);
        if(result >0){
            return path;
        }
        
        return new address[](0);
    }
    
    function per_amount(uint amount) public view returns(uint){
        return amount * 10000;
    }

    function getValueOfToken(address token, uint amount)internal returns(uint){
         //value of pool
        address[] memory path = findBestPairWithStableCoin(token);
        require(path.length > 0,"path must be definitive and greater than zero");
        uint value = getAvgPriceForTokens(1 * multiplier, swapRouter, path); 
        return uint(chainLink.latestAnswer()) * value * amount / multiplier * multiplier;
    }

    function updateUserTotalValueInUSD(address user) internal {
        for(uint128 j=0; j<=chains.length; j++){
            uint32 _chainId = chains[j];
            users[_chainId][user].totalAmountBorrowed = getBorrowedValue(user);
            users[_chainId][user].totalAmountStaked = getStakedValue(user);
            users[_chainId][user].ltv = users[_chainId][user].totalAmountBorrowed * 10000 / users[chainId][user].totalAmountStaked;
        }
    }

    function collateDataAllChains(address user) internal {
        updateUserTotalValueInUSD(user);
        uint totalstakes=0;
        uint totalborrows=0;
        for(uint128 j=0; j<=chains.length; j++){
            uint32 _chainId = chains[j];
            totalstakes += users[_chainId][user].totalAmountBorrowed;
            totalborrows += users[_chainId][user].totalAmountStaked;
            users[_chainId][user].ltv = per_amount(users[_chainId][user].totalAmountBorrowed) / users[chainId][user].totalAmountStaked;
        }

        users[defaultId][user].totalAmountBorrowed = totalborrows;
        users[defaultId][user].totalAmountStaked = totalstakes;
        users[defaultId][user].ltv = per_amount(users[defaultId][user].totalAmountBorrowed) / users[defaultId][user].totalAmountStaked;
    }

    // ---- DEPOSITS ----

    function stakeToken(address _tokenAddress, uint _amountToStake) public makeUser confirmUser nonReentrant{
        require(marketTokens[_tokenAddress].available, "market not open or available");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _tokenAddress, hashSalt));
        uint fee = (tax * _amountToStake) / 10000;
        uint valueOfTokens = getValueOfToken(_tokenAddress, _amountToStake-fee);
        require(valueOfTokens > 10, "Amount too low for staking");
        updateUserTotalValueInUSD(msg.sender);

        if(userstakes[_hash].available){
            userstakes[_hash].amountStaked += _amountToStake - fee; 
            userstakes[_hash].timeLastStaked = block.timestamp;
        }else{
            userstakes[_hash] = UserStake(msg.sender, _tokenAddress, true, _amountToStake - fee, block.timestamp);
        }  

        users[chainId][msg.sender].totalAmountStaked += valueOfTokens; 
        addToMarket(_amountToStake, false, true, marketTokens[_tokenAddress]._id);

         //transfer tokens to contract
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amountToStake), "transferFrom failed from contract.");  

        // parent
        updateChildChain(msg.sender);
    }

    function withdrawToken(address _tokenAddress, uint _amountToWithdraw, uint _chainId, address _to) public confirmUser nonReentrant{
        require(marketTokens[_tokenAddress].available, "market not open or available");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _tokenAddress, hashSalt));
        uint fee = (tax * _amountToWithdraw) / 10000;
        uint valueOfTokens = getValueOfToken(_tokenAddress, _amountToWithdraw-fee);

        require(valueOfTokens > 10, "Amount too low for withdrawal");
        require(userstakes[_hash].amountStaked > _amountToWithdraw, "Not enough liquidity to withdraw");
        updateUserTotalValueInUSD(msg.sender);
        require(((users[chainId][msg.sender].totalAmountBorrowed) * 10000)/(users[chainId][msg.sender].totalAmountStaked - valueOfTokens) < 7000 , "Amount greater than allowed amount for user to borrow");

        userstakes[_hash].amountStaked -= _amountToWithdraw; 
        users[chainId][msg.sender].totalAmountStaked -= valueOfTokens;  

        if(chainId != _chainId){
            // bridge token with multichain router
            IMultiChain(multichainRouter).anySwapOut(_tokenAddress, _to, _amountToWithdraw - fee, _chainId);
        }else{
            require(IERC20(_tokenAddress).transferFrom(address(this),msg.sender, _amountToWithdraw - fee), "transferFrom failed from contract.");
        }
        addToMarket(_amountToWithdraw, false, false, marketTokens[_tokenAddress]._id);
 
        // parent
        updateChildChain(msg.sender);
    }

    function getStakedValue(address user) internal nonReentrant returns(uint){
        uint totalStakeValue = 0;
        for(uint128 j=0; j<=market_pools; j++){
            bytes32 _hash = keccak256(abi.encodePacked(user, markets[j].tokenAddress, hashSalt));
            totalStakeValue += getValueOfToken(markets[j].tokenAddress, userstakes[_hash].amountStaked);
        }

        return totalStakeValue;
    }


    // ---- BORROWS ----

    function borrowToken(address _tokenAddress, uint _amountToBorrow)public confirmUser nonReentrant{
        require(marketTokens[_tokenAddress].available, "market not open or available");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _tokenAddress, hashSalt));
        uint fee = (tax * _amountToBorrow) / 10000;
        uint valueOfTokens = getValueOfToken(_tokenAddress, _amountToBorrow);
        require(valueOfTokens > 10, "Amount too low for borrowing");
        updateUserTotalValueInUSD(msg.sender);
        require(((users[chainId][msg.sender].totalAmountBorrowed + valueOfTokens) * 10000)/users[chainId][msg.sender].totalAmountStaked < 7000 , "Amount greater than allowed amount for user to borrow");

        if(usersborrows[_hash].available){
            usersborrows[_hash].amountBorrowed += _amountToBorrow; 
            usersborrows[_hash].timeLastBorrowed = block.timestamp;
        }else{
            usersborrows[_hash] = UserBorrow(msg.sender, _tokenAddress, true, _amountToBorrow, address(0), 0, address(0), block.timestamp);
        }  

        users[chainId][msg.sender].totalAmountBorrowed += valueOfTokens; 
        require(IERC20(_tokenAddress).transfer(msg.sender, _amountToBorrow-fee), "transferFrom failed from contract.");  
        addToMarket(_amountToBorrow, true, true, marketTokens[_tokenAddress]._id);

        // parent
        updateChildChain(msg.sender);
    }

    function borrowTokenWithCollateral(address _tokenAddress, uint _amountToBorrow, address _collateralAddress, uint _collateralAmount) public confirmUser nonReentrant{
        require(marketTokens[_tokenAddress].available, "market not open or available");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _tokenAddress, hashSalt));
        uint fee = (tax * _amountToBorrow) / 10000;
        uint valueOfTokens = getValueOfToken(_tokenAddress, _amountToBorrow);
        uint valueOfCollateral = getValueOfToken(_collateralAddress, _collateralAmount - fee);
        require(valueOfTokens > 10, "Amount too low for borrowing");
        require(valueOfCollateral > 10, "Amount too low for colalteral");
        updateUserTotalValueInUSD(msg.sender);
        require(((users[chainId][msg.sender].totalAmountBorrowed + valueOfTokens) * 10000)/(users[chainId][msg.sender].totalAmountStaked+valueOfCollateral) < 7000 , "Amount greater than allowed amount for user to borrow");

        if(usersborrows[_hash].available){
            usersborrows[_hash].amountBorrowed += _amountToBorrow; 
            usersborrows[_hash].timeLastBorrowed = block.timestamp;
        }else{
            usersborrows[_hash] = UserBorrow(msg.sender, _tokenAddress, true, _amountToBorrow, address(0), 0, address(0), block.timestamp);
        }  

        users[chainId][msg.sender].totalAmountBorrowed += valueOfTokens; 
        users[chainId][msg.sender].totalAmountStaked += valueOfCollateral;
         //transfer tokens to contract
        require(IERC20(_collateralAddress).transferFrom(msg.sender, address(this), _collateralAmount), "transferFrom failed from contract."); 
        require(IERC20(_tokenAddress).transfer(msg.sender, _amountToBorrow-fee), "transferFrom failed from contract.");  
        addToMarket(_amountToBorrow, true, true, marketTokens[_tokenAddress]._id);
        addToMarket(_collateralAmount, false, true, marketTokens[_collateralAddress]._id);

        // parent
        updateChildChain(msg.sender);
    }

    function getBorrowedValue(address user) internal nonReentrant returns(uint){
        uint totalBorrowValue = 0;
        for(uint128 j=0; j<=market_pools; j++){
            bytes32 _hash = keccak256(abi.encodePacked(user, markets[j].tokenAddress, hashSalt));
            totalBorrowValue += getValueOfToken(markets[j].tokenAddress, usersborrows[_hash].amountBorrowed);
        }

        return totalBorrowValue;
    }

    function repayLoan(address _tokenAddress, uint _amount)public confirmUser nonReentrant{
        require(marketTokens[_tokenAddress].available, "market not open or available");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _tokenAddress, hashSalt));
        uint valueOfTokens = getValueOfToken(_tokenAddress, _amount);
        require(valueOfTokens > 10, "Amount too low for repay");
        updateUserTotalValueInUSD(msg.sender);

        usersborrows[_hash].amountBorrowed -= _amount;  
        users[chainId][msg.sender].totalAmountBorrowed -= valueOfTokens;
        addToMarket(_amount, true, false, marketTokens[_tokenAddress]._id);

        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "transferFrom failed from contract."); 

        // parent
        updateChildChain(msg.sender);
    }

    // ---- RISKS AND LIQUIDATIONS ----

    function getRiskLevel() public view returns(uint){
        require(users[chainId][msg.sender].available, "User not fund");
        return users[chainId][msg.sender].ltv;
    }

    function collateAPR(address user, address token) private { //30mins
        uint timeSpent = 1800;
        bytes32 _hash = keccak256(abi.encodePacked(user, token, hashSalt));
        uint borrowRate = borrowInterestRates(marketTokens[token]._id) * timeSpent;
        uint supplyRate = supplyInterestRates(marketTokens[token]._id) * timeSpent;
        uint fee = (tax * 2 * users[chainId][user].totalAmountStaked) / 10000;

        userstakes[_hash].amountStaked += (supplyRate * userstakes[_hash].amountStaked) / 10**(chainLink.decimals()); 
        usersborrows[_hash].amountBorrowed += (borrowRate * usersborrows[_hash].amountBorrowed) / 10**(chainLink.decimals());
        users[chainId][user].totalAmountStaked += (supplyRate * users[chainId][user].totalAmountStaked) / 10**(chainLink.decimals()) - fee;
        users[chainId][user].totalAmountBorrowed += (borrowRate * users[chainId][user].totalAmountBorrowed) / 10**(chainLink.decimals());
        users[chainId][user].ltv = per_amount(users[chainId][user].totalAmountBorrowed)/ users[chainId][user].totalAmountStaked;

    }

    function liquidateUser(address user, address token) private {
        require(users[chainId][user].ltv > 7001, "Liquidation not possible for safe users");
        updateUserTotalValueInUSD(user);
        
        bytes32 _hash = keccak256(abi.encodePacked(user, token, hashSalt));
        
        uint valueOfTokens = getValueOfToken(token, userstakes[_hash].amountStaked);
        uint fee = (tax * 2 * valueOfTokens) / 10000;
        userstakes[_hash].amountStaked = 0; 
        users[chainId][user].totalAmountStaked -= valueOfTokens + fee;
        users[chainId][user].totalAmountBorrowed -= valueOfTokens;
        users[chainId][user].ltv = per_amount(users[chainId][user].totalAmountBorrowed)/ users[chainId][user].totalAmountStaked;
    }

    function validateUser(address user) private{
        updateUserTotalValueInUSD(user);
        uint limit = 7001;
        if(users[defaultId][user].creditScore >9000){
            limit = 8501;
        }else if(users[defaultId][user].creditScore >8000){
            limit = 8001;
        }else if(users[defaultId][user].creditScore >7000){
            limit = 7501;
        }

        if(users[defaultId][user].ltv > limit){
            for(uint128 j=0; j<= market_pools; j++){
                if(users[defaultId][user].ltv < limit){
                    break;
                }
                collateAPR(user, markets[j].tokenAddress);
                liquidateUser(user, markets[j].tokenAddress);
                updateUserTotalValueInUSD(user);
                collateDataAllChains(user);
            }
        }
    }

    function validateUsers() public onlyRelayers {
        for (uint i=0; i<userAddresses.length; i++){
            validateUser(userAddresses[i]);
        }
    }


    // ---- Markets ---
    
    function createMarket(address _token) public onlyRelayers {
        market_pools +=1;
        require(!marketTokens[_token].available, "market already open or available");
        markets[market_pools] = Market(_token, true, 0, 0, block.timestamp, block.timestamp, 0, 0);
        marketTokens[_token] = MarketToken(true, market_pools);
    }

    function createMarketPool(address _token, uint amount) public {
        market_pools +=1;
        require(!marketTokens[_token].available, "market already open or available");
        markets[market_pools] = Market(_token, true, 0, 0, block.timestamp, block.timestamp, 0, 0);
        marketTokens[_token] = MarketToken(true, market_pools);

        //availableTokens.push(_token);
        uint valueOfTokens = getValueOfToken(_token, amount);
        require(valueOfTokens >= 3500 * 10**(chainLink.decimals()), "Not enough amount to kickstart a new pool"); // at least 3.5kUSD needed
        stakeToken(_token, amount);
    }

    function borrowInterestRates(uint128 _id) public returns(uint){
        uint utilization = per_amount(markets[_id].amountBorrowed) / markets[_id].amountStaked;
        if (utilization <= borrowKink) {
            // interestRateBase + interestRateSlopeLow * utilization
            return borrowPerSecondInterestRateBase + borrowPerSecondInterestRateSlopeLow * utilization;
        } else {
            // interestRateBase + interestRateSlopeLow * kink + interestRateSlopeHigh * (utilization - kink)
            return borrowPerSecondInterestRateBase + (borrowPerSecondInterestRateSlopeLow * borrowKink) + (borrowPerSecondInterestRateSlopeHigh * (utilization - borrowKink));
        }
    }

    function supplyInterestRates(uint128 _id) public returns (uint){
        uint utilization = per_amount(markets[_id].amountBorrowed) / markets[_id].amountStaked;
        if (utilization <= supplyKink) {
            // interestRateBase + interestRateSlopeLow * utilization
            return supplyPerSecondInterestRateBase + (supplyPerSecondInterestRateSlopeLow * utilization);
        } else {
            // interestRateBase + interestRateSlopeLow * kink + interestRateSlopeHigh * (utilization - kink)
            return supplyPerSecondInterestRateBase + (supplyPerSecondInterestRateSlopeLow * supplyKink) + (supplyPerSecondInterestRateSlopeHigh * (utilization - supplyKink));
        }
    }

    function updateMarket(uint128 _id) private {
        if(markets[_id].available){
            markets[_id].borrowRate = borrowInterestRates(_id);
            markets[_id].supplyRate = supplyInterestRates(_id);
        }
    }

    function updateAllMarkets () private {
        for (uint128 i=0; i<=market_pools; i++){
            updateMarket(i);
        }
    }

    // for input: true is for addition and false is for subtraction. SO stake will be true and withdraw will be false
    function addToMarket(uint _tokenAmount, bool borrow, bool input, uint128 _id) private {
        if(borrow){
            if(input){
                markets[_id].amountBorrowed += _tokenAmount;
            }else{
                markets[_id].amountBorrowed -= _tokenAmount;
            }
            
            markets[_id].timeLastBorrowed = block.timestamp;
        }else{
            if(input){
                markets[_id].amountStaked += _tokenAmount;
            }else{
                markets[_id].amountStaked -= _tokenAmount;
            }
            
            markets[_id].timeLastStaked = block.timestamp;
        }
        updateMarket(_id);
    }


    // ---- Multichain Sync ----
    // parent chain
    function updateChildChain(address user) public onlyRelayers {
        collateDataAllChains(user);
        _dispatchWithGas(0x61722d72, abi.encode(user, users[defaultId][user].totalAmountStaked, users[defaultId][user].totalAmountBorrowed), 100000);
        emit ParentChainSynced(user, users[defaultId][user].totalAmountStaked, users[defaultId][user].totalAmountBorrowed);
    }

    function fullUpdateChildChain() public onlyRelayers {
        FullUpdateData[] memory updatesdata;
        for (uint i=0; i<userAddresses.length; i++){
            FullUpdateData memory user = FullUpdateData(userAddresses[i], users[defaultId][userAddresses[i]].totalAmountStaked, users[chainId][userAddresses[i]].totalAmountBorrowed);
            updatesdata[i]=user;
        }
        emit FullParentChainSynced(updatesdata);
    }

    function receiveUpdateFromChildChainPrivate(User memory user, uint32 _chainId)private{
        if(users[chainId][user.userAddress].available){
            users[_chainId][user.userAddress]= user;
            
        }else{
            userAddresses.push(user.userAddress);
            users[_chainId][user.userAddress] = User(user.userAddress, true, user.totalAmountBorrowed, user.totalAmountStaked, user.creditScore, user.ltv, user.lock);
        }
        collateDataAllChains(user.userAddress);
        emit ParentChainSynced(user.userAddress, users[defaultId][user.userAddress].totalAmountStaked, users[defaultId][user.userAddress].totalAmountBorrowed);
    }

    function receiveUpdateFromChildChain(User calldata user, uint32 _chainId) public onlyRelayers{
        if(users[chainId][user.userAddress].available){
            users[_chainId][user.userAddress]= user;
            
        }else{
            userAddresses.push(user.userAddress);
            users[_chainId][user.userAddress] = User(user.userAddress, true, user.totalAmountBorrowed, user.totalAmountStaked, user.creditScore, user.ltv, user.lock);
        }
        collateDataAllChains(user.userAddress);
        emit ParentChainSynced(user.userAddress, users[defaultId][user.userAddress].totalAmountStaked, users[defaultId][user.userAddress].totalAmountBorrowed);
    }

    
    // ---- Keepers ----
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */) external override onlyRelayers{
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            fullUpdateChildChain();
            validateUsers();
            updateAllMarkets();
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    // HyperLane
    // function _handle(
    //     uint32 _origin,
    //     bytes32,
    //     bytes memory _message
    // ) internal override {
    //     (address recipient, uint256 tokenStaked, uint256 tokenBorrowed) = abi.decode(
    //         _message,
    //         (address, uint256, uint256)
    //     );
    // }
    function _handle(
        uint32 _origin,
        bytes32,
        bytes memory _message
    ) internal override {
        (User memory user, uint32 _chainId) = abi.decode(
            _message,
            (User , uint32)
        );
        receiveUpdateFromChildChainPrivate(user, _chainId);
    }

    
    // ---- Modifiers ----

    modifier makeUser {
        if(!users[chainId][msg.sender].available){
            users[chainId][msg.sender] = User(msg.sender, true, 0, 0, 0,0, false);
            userAddresses.push(msg.sender);
        }
        _;
    }

    modifier confirmUser {
        require(users[chainId][msg.sender].available, "user does not exist yet");
        require(!users[chainId][msg.sender].lock, "Not allowed to perform a transaction right now.");
        _;
    }

    modifier onlyRelayers {
        require(relayers[msg.sender], "User not allowed for this function, Admin only.");
        _;
    }

}

// rebalance liquidity logic and executed with DeBridge