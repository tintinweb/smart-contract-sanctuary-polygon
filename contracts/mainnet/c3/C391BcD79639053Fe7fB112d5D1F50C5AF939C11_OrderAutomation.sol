// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Handle batches of vrf requests for prospecting.
interface IOrderAutomation {

    function addRequestToBatch(uint _orderId) external;

    function getRandomNumberForOrder(uint _orderId) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IOrderAutomation.sol";

interface IVRFBatchHandler {
    function handleBatch(uint orderId, uint randomNumber) external;
}

interface IVRFConsumerBaseV2 {
    function getRandomNumber(uint32 _num_words) external returns (uint256 requestID);
}

contract OrderAutomation is AutomationCompatibleInterface, OwnableUpgradeable, IOrderAutomation {

    address prospecting;
    IVRFConsumerBaseV2 private s_randNumOracle;

    struct BatchOrder {
        uint timestamp;
        bool pending;
        uint[] orderIds;
    }

    mapping(uint => uint) reqIdToBatchId;
    mapping(uint256 => BatchOrder) public queue;
    uint public batchMaxSize;
    uint public interval;
    uint256 public first;
    uint256 public last;

    mapping(uint => uint) orderIdToBatchIndex;
    mapping(uint => uint) batchIndexToRandomNumber;


    // queue functions
    function enqueue(BatchOrder memory data) internal {
        last += 1;
        queue[last] = data;
    }

    function dequeue() internal returns (BatchOrder memory data) {
        require(last >= first);  // non-empty queue

        data = queue[first];
        delete queue[first];
        first += 1;
    }

    function queueLength() public view returns (uint) {
        return 1 + last - first;
    }

    function getFirstBatch() public view returns (BatchOrder memory){
        if (queueLength() < 1) revert("No batch in queue");
        return queue[first];
    }


    function initialize(uint _updateInterval, uint _batchMaxSize, address _prospecting) public initializer {
        __Ownable_init();
        interval = _updateInterval;
        prospecting = _prospecting;
        batchMaxSize = _batchMaxSize;
        first = 1;
        last = 0;
    }

    // Modifiers
    modifier onlyProspecting() {
        if (msg.sender != prospecting) revert("not prospecting");
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != address(s_randNumOracle)) revert("Not oracle");
        _;
    }


    /** @notice Add new order id to correct position in the batch queue.
     *  @param _orderId order id to be added in a vrf batch request.
     */
    function addRequestToBatch(uint _orderId) override external onlyProspecting {
        if (!queue[last].pending && last >= first && queue[last].orderIds.length < batchMaxSize) {
            queue[last].orderIds.push(_orderId);
        }
        else {
            BatchOrder memory batch;
            batch.timestamp = block.timestamp;
            batch.pending = false;
            enqueue(batch);
            queue[last].orderIds.push(_orderId);
        }
        //orderIdToBatchIndex[_orderId] = last;
    }

    /** @notice Will be called on by every block to see if performUpkeep tx should be executed.
     *  @param upkeepNeeded return true if tx should be performed.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = shouldPerformUpkeep();
    }

    /** @notice Check if batch should be processed.
    */
    function shouldPerformUpkeep() public view returns (bool){
        if (!queue[first].pending && last >= first && (block.timestamp - queue[first].timestamp > interval || queue[first].orderIds.length >= batchMaxSize)) {
            return true;
        }
        return false;
    }

    function performUpkeep(bytes calldata) external override {

        if (!shouldPerformUpkeep()) {
            revert("reveal criteria not met");
        }
        if (address(s_randNumOracle) == address(0)) {
            revert("Oracle not set");
        }
        queue[first].pending = true;

        uint256 reqId = s_randNumOracle.getRandomNumber(uint32(queue[first].orderIds.length));
        //uint256 reqId = s_randNumOracle.getRandomNumber(1);
        reqIdToBatchId[reqId] = first;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    external
    onlyOracle
    {
        uint batchIndex = reqIdToBatchId[requestId];
        if(batchIndex == 0) revert("invalid requestId");
        for (uint i; i < randomWords.length; i++){
            IVRFBatchHandler(prospecting).handleBatch(queue[batchIndex].orderIds[i], randomWords[i]);
        }
        dequeue();
        delete reqIdToBatchId[requestId];
    }

    function getRandomNumberForOrder(uint _orderId) override external view returns(uint){
        uint randNum = batchIndexToRandomNumber[orderIdToBatchIndex[_orderId]];
        if (randNum == 0) revert("Random Number not fulfilled");
        return uint256(keccak256(abi.encode(randNum, _orderId)));
    }

    // Admin setters
    function setTimeInterval(uint _interval) external onlyOwner {
        interval = _interval;
    }

    function setProspecting(address _prospecting) external onlyOwner {
        prospecting = _prospecting;
    }

    function setOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert("Can't be zero address");
        s_randNumOracle = IVRFConsumerBaseV2(_oracle);
    }

    function setBatchMaxSize(uint _batchMaxSize) external onlyOwner {
        batchMaxSize = _batchMaxSize;
    }
}