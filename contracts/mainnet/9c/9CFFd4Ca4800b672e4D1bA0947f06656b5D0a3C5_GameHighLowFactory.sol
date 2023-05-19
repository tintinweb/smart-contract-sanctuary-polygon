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

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

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
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
pragma solidity ^0.8.18;

import "./GameEngine.sol";

abstract contract GameBase {
    // GAME STATS
    // Address of system admin wallet
    address public systemAddress;
    // Amount needed to place a bet in the game
    uint256 public enterAmount;
    // Amount of money which will be lost from user
    uint256 public loseAmount;
    // Max amount of participants
    uint256 public maxParticipants;
    // Min amount of participants to play
    uint256 public minParticipants;
    // Jackpot multiplier factor if should be set to higher depend on enterAmount
    uint256 public jackpotFactor;
    // Game Engine contract
    GameEngine gameEngine;
    // Ingame pot amount
    uint256 public gamePot = 0;

    address[] public _participantsAddressArray;

    event OnParticipation(address indexed sender);
    event OnLeave(address indexed sender);
    event OnPlay(uint256 nextNumber, uint256 potPerParticipant);

    bool public isPaused = false;
    bool public isReadyToPlay = false;
    bool isGameVRFInit;

    address public gameVRFAddress;
    address public gameCroneJobAddress;

    address public gameFactoryAddress;


    modifier onlyNotPaused {
        require(!isPaused, "Game is paused, you cant call this method");
        _;
    }

    modifier onlyReadyToPlay {
        require(isReadyToPlay, "Game is not ready, you cant call this method");
        _;
    }

    modifier onlyNotReadyToPlay {
        require(!isReadyToPlay, "Game is ready, you cant call this method");
        _;
    }

    modifier onlyIfGameVRFInit {
         require(isGameVRFInit, "Can be called only if Game VRF is init");
        _;
    }

    modifier onlyGameVRFContract {
         require(msg.sender == gameVRFAddress, "Can be called only from gameVRFAddress");
        _;
    }

    modifier onlyFactroyContract {
        require(msg.sender == gameFactoryAddress, "Can be called only from gameFactoryAddress");
        _;
    }

    constructor(
        uint256 _enterAmount, 
        uint256 _loseAmount, 
        uint256 _maxParticipants, 
        address _systemAddress,
        uint256 _jackpotFactor,
        address _gameEngine,
        uint256 _minParticipants
        ) {
        enterAmount = _enterAmount;
        loseAmount = _loseAmount;
        maxParticipants = _maxParticipants;
        systemAddress = _systemAddress;
        minParticipants = _minParticipants;

        // Jackpot
        jackpotFactor = _jackpotFactor;
        gameEngine = GameEngine(_gameEngine);
        gameFactoryAddress = msg.sender;
    }

    function setReadyToPlay() public onlyIfGameVRFInit onlyGameVRFContract returns(bool) {
        isReadyToPlay = true;
        return isReadyToPlay;
    }

    function resetReadyToPlay() public onlyIfGameVRFInit onlyGameVRFContract returns(bool) {
        isReadyToPlay = false;
        return isReadyToPlay;
    }

    function unpauseTheGame() external onlyFactroyContract {
        isPaused = false;
    }


    function initGameVRF(address _vrfContractAddress, address _gameCroneJobAddress) public onlyFactroyContract returns(bool) {
        require(!isGameVRFInit, "Game VRF should not be init");
        gameVRFAddress = _vrfContractAddress;
        gameCroneJobAddress = _gameCroneJobAddress;
        isGameVRFInit = true;
        return isGameVRFInit;
    }

    function calculatePlatformFees(uint256 _playersAmount) public view returns(uint256) {
        uint256 gasPrice = _getGasPrice();
        uint256 gasPerExtraPlayer = getGasPerExtraPlayer();
        uint256 vrfCallbackMinimumExecutionCost = getVrfCallbackMinimumExecutionCost();
        uint256 croneJobGasUsage = getCronJobGasUsage();

        // Game can not ba launched with less then min participants
        uint256 vrfGasFees = _getVRFCost(gasPrice, gasPerExtraPlayer * (_playersAmount - minParticipants) + vrfCallbackMinimumExecutionCost);
        // Crone job contract avarage gas usage in gwei
        uint256 croneJobGasFees = _getCroneJobCost(gasPrice, croneJobGasUsage);
        uint256 fees = (vrfGasFees +  croneJobGasFees);
        return fees;
    }

    function _getVRFCost(uint256 _gweiGasPrice, uint256 _callBackGasUsed) internal pure returns(uint256) {
        return _gweiGasPrice * (_callBackGasUsed + getVrfExecutionGasUsed());
    }

    function _getCroneJobCost(uint256 _gweiGasPrice, uint256 _gasUsed) internal pure returns(uint256) {
        return  ((_gasUsed * _gweiGasPrice * 170 ) / 100 + (80000 * _gweiGasPrice));
    }


    function _calculateJackpotWinnerIdx(uint256 _randomnes) internal view returns(uint256) {
        return _randomnes % (gameEngine.jackpotChance() / jackpotFactor);
    }

    function _getGasPrice() internal view returns (uint256) {
        uint256 gasPrice;
        assembly {
            gasPrice := gasprice()
        }
        return gasPrice;
    }

    // Methods which trigers game logic can be called only from GameVRF contracts
    function playGame(uint256 _randomnes) external onlyGameVRFContract onlyIfGameVRFInit onlyReadyToPlay {
        uint256 systemFees = calculatePlatformFees(getParticipantsAmount());
        /// Deduct system fees

        gamePot = gameEngine.deductPlatformFees(gamePot, systemFees);

        uint256 jackpotWinnerIdx = _calculateJackpotWinnerIdx(_randomnes);

        // Check if somebody won the jackpot 
        if(jackpotWinnerIdx < getParticipantsAmount()) {
            gameEngine.distributeJackpot(_participantsAddressArray[jackpotWinnerIdx]);
        }
        
        playHandler(_randomnes);

        // Reset readyState when the game is sucessfully finished
        isReadyToPlay = false;
    }

    // Here you should implement exact functionality of the game
    function playHandler(uint256 _randomnes) internal virtual;

    function pauseTheGame() external virtual;

    

    // Chainlink variables should be redefined in specific game contract according to
    // VRF, Chainlink Upkeep and playGame gas usage

    // Gas usage of chainlink upkeep cron job
    function getCronJobGasUsage() public view virtual returns(uint256);

    // Execution cost of playGame method for minParticipants
    function getVrfCallbackMinimumExecutionCost() public view virtual returns(uint256);

    // Gas which should be included to fees calculations according to method consumption increase per one
    // player. Start from more then minParticipants
    function getGasPerExtraPlayer() public view virtual returns(uint256);

    // Value calculated according to chainlink docs
    function getVrfExecutionGasUsed() public pure returns(uint256) {
        return 200000;
    }
    
    function getParticipantsAmount() public view virtual returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./GameVRF.sol";

abstract contract GameCronJob is AutomationCompatibleInterface {
    // Interval in blocks each game of the engine should be based on block mining instead of time
    uint public immutable interval;
    uint public lastTimeStamp;

    bool isInit;

    address internal systemAddress;
    address internal factoryAddress;
    GameVRF gameVRF;

    modifier onlySystemAddress {
        require(msg.sender == systemAddress, "Only system address");
        _;
    }

    modifier onlyFactroyContract {
        require(msg.sender == factoryAddress, "Can be called only from Room Factory");
        _;
    }

    constructor(uint _updateInterval, address _systemAddress, address _factoryAddress) {
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
        systemAddress = _systemAddress;
        factoryAddress = _factoryAddress;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        virtual
        view
        returns (bool upkeepNeeded, bytes memory);

    function performUpkeep(bytes calldata b) external override {
        (bool upkeepNeeded, ) = checkUpkeep(b);
        if(upkeepNeeded) {
            gameVRF.requestRandomness();
        }
    }

    function getUpkeepData(bytes calldata b) view external returns(uint256, bool) {
        uint256 blocksBeforeUpkeep = 0;
        uint256 upkeepPlanedBlock = getNextUpkeepPlanedBlock();
        if(upkeepPlanedBlock > block.number) {
            blocksBeforeUpkeep = upkeepPlanedBlock - block.number;
        }
        (bool upkeepNeeded, ) = checkUpkeep(b);
        return (blocksBeforeUpkeep, upkeepNeeded);
    }

    function getNextUpkeepPlanedBlock() public view returns(uint256)  {
        return gameVRF.getLastMinedBlockNumber() + interval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GameEngine is ReentrancyGuard {
    event OnParticipation(address indexed sender,  uint256 amount);
    event OnWithdraw(address indexed sender, uint256 amount);
    event OnJackpotDistribiton(address winner, uint256 amount);
    event OnTopUp(address sender, uint256 amount);
    event OnAddBalance(address indexed addr);
    event OnDeductBalance(address indexed addr);
    event OnGameEngineFundsTransfer(address indexed sender, address indexed receiver, uint256 amount);


    struct ParticipantAccount {
        address id;
        uint256 balance;
        bool init;
        address inTheGame;
        address referredBy;
    }

    address public systemAddress;
    address owner1;
    address owner2;
    // Should be adjusted before launch
    uint8 owner1PercentageFees = 1;
    uint8 owner2PercentageFees = 1;
    // Should be adjusted before launch
    uint8 jackpotPercentageFees = 1;
    uint256 public owner1Fees;
    uint256 public owner2Fees;
    uint256 public systemAddressFees;
    uint256 public jackpotFees;
    // Should be adjusted before launch 1:100
    uint256 public jackpotChance = 100;
    // Should be adjusted before launch
    uint256 public referealFees = 1;

    mapping(address => ParticipantAccount) public addressToParticipantAccounts;
    // ParticipantAddress -> GameAddress
    mapping(address => mapping( address => bool)) public approvedParticipantsGames;

    // List of the games approved by system to perform any operations with user balances
    mapping(address => bool) public systemAvailableGames;
    // Name mapping for quick access to the address
    mapping(string => address) public participantNameToAddress;
    // Name mapping for quick access to the name
    mapping(address => string) public adddressToParticipantName;

    modifier onlyFirstOwner {
        require(msg.sender == owner1, "Only owners can call this methods");
        _;
    }

     modifier onlySecondOwner {
        require(msg.sender == owner2, "Only owners can call this methods");
        _;
    }

    modifier onlySystemAddress {
        require(msg.sender == systemAddress, "G1");
        _;
    }

    modifier onlyApprovedSystemGame {
        require(isSystemAvailableGame(msg.sender), "Only approved game can call this method");
        _;
    }
    constructor(address _systemAddress, address _owner1, address _owner2) {
        systemAddress = _systemAddress;
        owner1 = _owner1;
        owner2 = _owner2;
    }


    ///////////////////////////////////////////////////////////
    //
    // PARTICIPANT/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    // When user call this method he creates in game account
    // this account will be used as a deposit vault to easier interact with all GAMEv1 smart contracts in the system
    // user need to set participant name which will be displayed to other users during game process
    function createParticipantAccount(string memory _name) payable public nonReentrant returns(address) {
        require(bytes(_name).length <= 7, "Name should be max 7 symbols");
        require(getParticipantAddressByName(_name) == address(0), "Name is already exist");
        require(!getParticipantAccount(msg.sender).init, "Account is Already exists");

        ParticipantAccount memory createdAccount = ParticipantAccount({
            id: msg.sender,
            balance: msg.value,
            init: true,
            inTheGame: address(0),
            referredBy: address(0)
        });

        addressToParticipantAccounts[msg.sender] = createdAccount;
        participantNameToAddress[_name] = msg.sender;
        adddressToParticipantName[msg.sender] = _name;
        
        

        emit OnParticipation(msg.sender, msg.value);

        return msg.sender;
    }


    // When user call this method he creates in game account
    // this account will be used as a deposit vault to easier interact with all GAMEv1 smart contracts in the system
    // user need to set participant name which will be displayed to other users during game process
    // referalAddress - will be set as lifetime referal address which will get fees from all participantAccount wins in GAMEv1 contracts
    function createParticipantAccountWithRef(string memory _name, address _referalAddress) payable public nonReentrant returns(address) {
        require(bytes(_name).length <= 7, "Name should be max 7 symbols");
        require(getParticipantAddressByName(_name) == address(0), "Name is already exist");
        require(_referalAddress != msg.sender, "You cannot refer yourself");
        require(getParticipantAccount(_referalAddress).init, "Ref Address is not a participant");

        ParticipantAccount memory createdAccount = ParticipantAccount({
            id: msg.sender,
            balance: msg.value,
            init: true,
            inTheGame: address(0),
            referredBy: _referalAddress
        });

        addressToParticipantAccounts[msg.sender] = createdAccount;
        participantNameToAddress[_name] = msg.sender;
        adddressToParticipantName[msg.sender] = _name;

        emit OnParticipation(msg.sender, msg.value);

        return msg.sender;
    }


    // Participants should call this method when they want to add funds to thair game account
    // nonReentrant
    function topUpParticipantAccount() payable nonReentrant public  {
        require(getParticipantAccount(msg.sender).init, "Participant Account is not init yet");
        addressToParticipantAccounts[msg.sender].balance += msg.value;
        emit OnTopUp(msg.sender, msg.value);
    }

    
    // Participants are able to call this function to withdraw all funds from thair in-game accounts;
    function withdraw(uint256 _amount) public nonReentrant {
        require(addressToParticipantAccounts[msg.sender].init, "G2");
        require(addressToParticipantAccounts[msg.sender].inTheGame == address(0), "G9");
        require(addressToParticipantAccounts[msg.sender].balance >= _amount, "Balance should be more then amount");
        payable(msg.sender).transfer(_amount);
        addressToParticipantAccounts[msg.sender].balance -= _amount;

        emit OnWithdraw(msg.sender, _amount);
    }

    // Transfer funds from your ingame account to any others ingame account
    function transferGameEngineFunds(address _to, uint256 _amount) public nonReentrant {
        require(addressToParticipantAccounts[msg.sender].init, "G2");
        require(addressToParticipantAccounts[_to].init, "Receiver account does not exist");
        require(addressToParticipantAccounts[msg.sender].balance >= _amount, "Balance should be more then amount");
        addressToParticipantAccounts[msg.sender].balance -= _amount;
        addressToParticipantAccounts[_to].balance += _amount;
        emit OnGameEngineFundsTransfer(msg.sender, _to, _amount);
    }

    // Participants need to approve GEMEv1 contract before thay can participate in GEMEv1 contract
    function approveGame(address _gameAddress) public {
        require(isSystemAvailableGame(_gameAddress), "G4");
        require(addressToParticipantAccounts[msg.sender].init, "G5");
        require(!approvedParticipantsGames[msg.sender][_gameAddress], "G6");
        approvedParticipantsGames[msg.sender][_gameAddress] = true;
    }

    // Participants are able to remove game from thair approved GAMEv1 list
    // only if participant is not in the game
    function rejectGame(address _gameAddress) public {
        require(isSystemAvailableGame(_gameAddress), "G4");
        require(approvedParticipantsGames[msg.sender][_gameAddress], "G7");
        require(addressToParticipantAccounts[msg.sender].init, "G5");
        require(addressToParticipantAccounts[msg.sender].inTheGame == address(0), "G9");
        approvedParticipantsGames[msg.sender][_gameAddress] = false;
    }

    ///////////////////////////////////////////////////////////
    //
    // PARTICIPANT/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////



    ///////////////////////////////////////////////////////////
    //
    // SYSTEM ADDRESS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////


    function addSystemGame(address _gameAddress) public onlySystemAddress {
        systemAvailableGames[_gameAddress] = true;
    }

    function removeSystemGame(address _gameAddress) public onlySystemAddress {
        delete systemAvailableGames[_gameAddress];
    }

    ///////////////////////////////////////////////////////////
    //
    // SYSTEM ADDRESS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    //
    // APPROVED GAMEv1 CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    // Approved GAMEv1 are avaliable to change statuses of Participants Accounts 
    function changeInGameStatus(address _value, address _addr) external onlyApprovedSystemGame {
        require(approvedParticipantsGames[_addr][msg.sender], "G8");
        addressToParticipantAccounts[_addr].inTheGame = _value;
    }

    // Approved GAMEv1 are avaliable to change balances of Participants Accounts 
    function deductBalance(uint256 _value, address _addr) external onlyApprovedSystemGame {
        require(approvedParticipantsGames[_addr][msg.sender], "G8");
        addressToParticipantAccounts[_addr].balance -= _value;
        emit OnDeductBalance(_addr);
    }


    // Approved GAMEv1 are avaliable to deduct _jackpot, owner1, owner2 and system fees and return new gamePot with deducted fees
    // System fees is dynamic value which should be calcualted separately for each game type
    // As a developer you should always be sure that your game is addBalances for deductedAmount
    function deductPlatformFees(uint256 _gamePotValue, uint256 _systemFees) external onlyApprovedSystemGame returns (uint256){
        uint256 _jackpotFees = _getJackpotFee(_gamePotValue);
        uint256 _owner1Fees = _getFirstOwnerFeeFromAmount(_gamePotValue);
        uint256 _owner2Fees = _getSecondOwnerFeeFromAmount(_gamePotValue);
        uint256 totalFees = _owner1Fees + _owner2Fees + _jackpotFees + _systemFees;
        if(totalFees >= _gamePotValue) {
            return _gamePotValue;
        }

        owner1Fees += _owner1Fees;
        owner2Fees += _owner2Fees;
        systemAddressFees += _systemFees;
        jackpotFees += _jackpotFees;

        return _gamePotValue - totalFees;
    }

    // Approved GAMEv1 are avaliable to add balances of Participants Accounts.
    // As a developer you should always be sure that your game is addBalances for deductedAmount
    function addBalance(uint256 _value, address _addr) external onlyApprovedSystemGame {
        require(approvedParticipantsGames[_addr][msg.sender], "G8");

        // Distribute referal fees with 4 level depth
        address prevRefAddress = _addr;
        uint256 levelFees = _getReferalFees(_value);
        uint8 j = 0;

        while(addressToParticipantAccounts[_addr].referredBy != address(0) && j <= 4) {
            prevRefAddress = addressToParticipantAccounts[prevRefAddress].referredBy;
            addressToParticipantAccounts[prevRefAddress].balance += levelFees;
            levelFees = _getReferalFees(levelFees);
            j++;
        }

        if(addressToParticipantAccounts[_addr].referredBy != address(0)) {
            addressToParticipantAccounts[_addr].balance += _value - _getReferalFees(_value);
        } else {
            addressToParticipantAccounts[_addr].balance += _value;
        }
        emit OnAddBalance(_addr);
    }

    // Approved GAMEv1 are avaliable to add jackpot of Participants Accounts.
    function distributeJackpot(address _to) external onlyApprovedSystemGame {
       require(approvedParticipantsGames[_to][msg.sender], "G8");

       address prevRefAddress = _to;
       uint256 levelFees = _getReferalFees(jackpotFees);
       uint8 j = 0;

       while(addressToParticipantAccounts[_to].referredBy != address(0) && j <= 4) {
            prevRefAddress = addressToParticipantAccounts[prevRefAddress].referredBy;
            addressToParticipantAccounts[prevRefAddress].balance += levelFees;
            levelFees = _getReferalFees(levelFees);
            j++;
        }
    
        if(addressToParticipantAccounts[_to].referredBy == address(0)) {
            addressToParticipantAccounts[_to].balance += jackpotFees;  
        } else {
            addressToParticipantAccounts[_to].balance += jackpotFees - _getReferalFees(jackpotFees);  
        }
         

       // Increase chance to win jackpot

       jackpotChance += 1;

       emit OnJackpotDistribiton(_to, jackpotFees);

       jackpotFees = 0;
    }

    ///////////////////////////////////////////////////////////
    //
    // APPROVED GAMEv1 CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////
    //
    // OWNER ADDRESS CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////

    // Method to withdraw fees of owners
    // 
    function withdrawFirstOwnerFees() external onlyFirstOwner nonReentrant {
        require(owner1Fees > 0, "Balance should be more then 0");


        payable(owner1).transfer(owner1Fees);

        owner1Fees = 0;
    }

    // Method to withdraw fees of owners
    // 
    function withdrawSecondOwnerFees() external onlySecondOwner nonReentrant {
        require(owner2Fees > 0, "Balance should be more then 0");

        payable(owner2).transfer(owner2Fees);

        owner2Fees = 0;
    }

    // Method to withdraw fees of system Address to pay for Chainlink services

    function withdrawSystemAddressFees() external onlySystemAddress nonReentrant {
        require(systemAddressFees > 0, "Balance should be more then 0");

        payable(systemAddress).transfer(systemAddressFees);

        systemAddressFees = 0;
    }


    ///////////////////////////////////////////////////////////
    //
    // OWNER ADDRESS CONTRACTS/CONTRACT INTERACTIONS
    //
    ///////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////
    //
    // PULBIC
    //
    ///////////////////////////////////////////////////////////

    function getOwners() public view returns(address, address) {
        return (address(owner1), address(owner2));
    } 

    function getParticipantAddressByName(string memory _name) public view returns(address) {
        return participantNameToAddress[_name];
    }

    function getParticipantNameByAddress(address _addr) public view returns(string memory) {
        return adddressToParticipantName[_addr];
    }
    
    function isApprovedParticipantGame(address _participantAddress, address _gameAddress) public view returns(bool) {
        return approvedParticipantsGames[_participantAddress][_gameAddress];
    }

    function getParticipantAccount(address _addr) public view returns(ParticipantAccount memory) {
        return addressToParticipantAccounts[_addr];
    }

    function isSystemAvailableGame(address _addr) public view returns(bool) {
        return systemAvailableGames[_addr];
    }

    ///////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ///////////////////////////////////////////////////////////
    function _getFirstOwnerFeeFromAmount(uint256 amount) internal view returns(uint256) {
        return amount * owner1PercentageFees / 100;
    }

    function _getSecondOwnerFeeFromAmount(uint256 amount) internal view returns(uint256) {
        return amount * owner2PercentageFees / 100;
    }
    function _getJackpotFee(uint256 amount) internal view returns(uint256) {
        return amount * jackpotPercentageFees / 100;
    }
    function _getReferalFees(uint256 amount) internal view returns(uint256) {
        return amount * referealFees / 100;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./GameEngine.sol";
import "./GameBase.sol";

abstract contract GameFactory {
    event OnRoomCreation(address roomId, uint256 enterAmount, uint256 loseAmount, uint256 maxParticipants, address roomVRF);

    address private owner1;
    address private owner2;
    address public systemAddress;
    address[] public roomAddresses;
    //VRF
    address coordintatorAddress;
    uint64 public subscriptionId;
    bytes32 keyHash;

    VRFCoordinatorV2Interface COORDINATOR;

    struct RoomInfo {
        address id;
        uint256 enterAmount;
        uint256 loseAmount;
        uint256 currentParticipants;
        uint256 maxParticipants;
    }

    GameEngine gameEngine;


    modifier onlySystemAddress {
        require(msg.sender == systemAddress, "Only system wallet can call this method");
        _;
    }


    constructor(
        address _coordintatorAddress,
        bytes32 _keyHash,
        address _gameEngine
        ) {
        
        coordintatorAddress = _coordintatorAddress;
        keyHash = _keyHash;
        gameEngine = GameEngine(_gameEngine);
        systemAddress = gameEngine.systemAddress();

        (address _o1, address _o2) = GameEngine(gameEngine).getOwners();
        owner1 = _o1;
        owner2 = _o2;

        COORDINATOR = VRFCoordinatorV2Interface(
            _coordintatorAddress
        );
        subscriptionId = COORDINATOR.createSubscription();
    }

    function cancelSubscription(address receivingWallet) external onlySystemAddress {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(subscriptionId, receivingWallet);
        subscriptionId = 0;
    }

    function pauseTheGame(address _gameAddress) external onlySystemAddress {
        GameBase(_gameAddress).pauseTheGame();
    }
    
    function unpauseTheGame(address _gameAddress) external onlySystemAddress {
        GameBase(_gameAddress).unpauseTheGame();
    }

    function getAllGames() public view returns(RoomInfo[] memory) {
        RoomInfo[] memory rooms = new RoomInfo[](roomAddresses.length);
        for (uint i = 0; i < roomAddresses.length; i++) {
            GameBase currentGame = GameBase(roomAddresses[i]);
            RoomInfo memory roomInfo = RoomInfo({
             id: roomAddresses[i],
             enterAmount: currentGame.enterAmount(),
             loseAmount: currentGame.loseAmount(),
             currentParticipants: currentGame.getParticipantsAmount(), 
             maxParticipants: currentGame.maxParticipants()
            });
            rooms[i] = roomInfo;
            
        }

        return rooms;
    }

    function getGameById(address _roomAddress) public view returns (RoomInfo memory) {
        GameBase currentGame = GameBase(_roomAddress);
        RoomInfo memory roomInfo = RoomInfo({
             id: _roomAddress,
             enterAmount: currentGame.enterAmount(),
             loseAmount: currentGame.loseAmount(),
             currentParticipants: currentGame.getParticipantsAmount(), 
             maxParticipants: currentGame.maxParticipants()
        });
        return roomInfo;
    } 


     function createRoom(uint256 _enterAmount, uint256 _loseAmount, uint256 _maxParticipants, uint256 _jackpotFactor) virtual public returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./GameEngine.sol";
import "./GameBase.sol";


abstract contract GameVRF is VRFConsumerBaseV2, ConfirmedOwner {
    event OnRequestRandomness(uint256 requestId);
    event OnFullfillRandomness(uint256 requestId, uint256 randomness);
    event OnFullFillFailed(uint256 requestId);

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256 public lastRequestId;
    uint256 lastMinedBlockNumber = block.number;
    bytes32 keyHash;

    uint32 numWords = 1;

    GameBase room;

    modifier onlyCroneJob {
        require(room.gameCroneJobAddress() == msg.sender, "Only callable by crone job");
        _;
    }

    constructor(
        address _coordintatorAddress,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _systemAddress,
        address _roomAddress
    )
        VRFConsumerBaseV2(_coordintatorAddress)
        ConfirmedOwner(_systemAddress)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            _coordintatorAddress
        );
        s_subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        room = GameBase(_roomAddress);
    }

    function requestRandomness()
        external
        onlyCroneJob
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            getRequestConfirmations(),
            getCallbackGasLimit(),
            numWords
        );

        lastRequestId = requestId;
        emit OnRequestRandomness(requestId);
        room.setReadyToPlay();
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomness = _randomWords[0];

        try room.playGame(randomness) {
            emit OnFullfillRandomness(_requestId, randomness);
        } catch {
            room.resetReadyToPlay();
            emit OnFullFillFailed(_requestId);
        }

        lastMinedBlockNumber = block.number;
    }

    function getLastMinedBlockNumber() external view returns(uint256) {
        return lastMinedBlockNumber;
    }

    function getRequestConfirmations() virtual internal returns(uint16);

    function getCallbackGasLimit() virtual internal returns(uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../GameBase.sol";

contract GameHighLow is GameBase {
    event OnMakePrediction(Prediction nextNumber, address sender);

    uint256 public lastRandomness = _calculatePredictionNumber(block.timestamp);

    address[] public lowerPredictionsAddresses;
    address[] public higherPredictionAddresses;


    enum Prediction {
        Empty,
        High,
        Low
    }

    struct Participant {
        address id;
        uint256 wins;
        uint256 loses;
        Prediction prediction; // 0 - empty, 1 - high, 2 - low
    }
    
    mapping (address => Participant) public addressToParticipants;

    constructor(
        uint256 _enterAmount, 
        uint256 _loseAmount, 
        uint256 _maxParticipants, 
        address _systemAddress,
        uint256 _jackpotFactor,
        address _gameEngine,
        uint256 _minParticipants
        ) GameBase(_enterAmount, _loseAmount, _maxParticipants, _systemAddress, _jackpotFactor, _gameEngine, _minParticipants) {}
        
    function pauseTheGame() override external onlyFactroyContract onlyNotPaused {
        // Change statuses 
        while(_participantsAddressArray.length != 0) {
            address _participantAddress = _participantsAddressArray[_participantsAddressArray.length - 1];
            gameEngine.changeInGameStatus(address(0), _participantAddress);
            if(addressToParticipants[_participantAddress].prediction != Prediction.Empty) {
                gameEngine.addBalance(enterAmount, _participantAddress);
                gamePot = gamePot - enterAmount;
            }
            _removeParticipant(_participantAddress);
        }
        isPaused = true;
        isReadyToPlay = false;
        higherPredictionAddresses = new address[](0);
        lowerPredictionsAddresses = new address[](0);
        gamePot = 0;
    }

    function participate(Prediction _prediction) public onlyNotReadyToPlay onlyIfGameVRFInit onlyNotPaused {
        require(gameEngine.getParticipantAccount(msg.sender).inTheGame == address(0), "Participant should not be in the game");
        require(_participantsAddressArray.length < maxParticipants, "Max amount of players in the game");
        require(gameEngine.getParticipantAccount(msg.sender).balance >= enterAmount, "Not enough funds to participate");
        require(addressToParticipants[msg.sender].id != msg.sender, "Participant is already initialized");
        
        Participant memory newParticipant = Participant({
            id: msg.sender,
            wins: 0,
            loses: 0,
            prediction: Prediction.Empty
        });

        gameEngine.changeInGameStatus(address(this), msg.sender);

        addressToParticipants[address(msg.sender)] = newParticipant;
        _participantsAddressArray.push(address(msg.sender));

        emit OnParticipation(msg.sender);

        makePrediction(_prediction);
    }

    function leave() public onlyNotReadyToPlay onlyIfGameVRFInit {
        require(_participantsAddressArray.length != 0, "Zero participants in the game");

        require(addressToParticipants[msg.sender].id == msg.sender, "Only participant can close his position");
        gameEngine.changeInGameStatus(address(0), msg.sender);

        if(addressToParticipants[msg.sender].prediction != Prediction.Empty) {
            gameEngine.addBalance(enterAmount, msg.sender);
            gamePot = gamePot - enterAmount;
        }

        if(addressToParticipants[msg.sender].prediction == Prediction.High) {
            for(uint8 i = 0; i <= higherPredictionAddresses.length; i++) {
                address _participantAddress = higherPredictionAddresses[i];
                if(_participantAddress == msg.sender) {
                    higherPredictionAddresses[i] = higherPredictionAddresses[higherPredictionAddresses.length - 1];
                    higherPredictionAddresses.pop();
                    break;
                }
            }
        }

        if(addressToParticipants[msg.sender].prediction == Prediction.Low) {
            for(uint8 i = 0; i <= lowerPredictionsAddresses.length; i++) {
                address _participantAddress = lowerPredictionsAddresses[i];
                if(_participantAddress == msg.sender) {
                    lowerPredictionsAddresses[i] = lowerPredictionsAddresses[lowerPredictionsAddresses.length - 1];
                    lowerPredictionsAddresses.pop();
                    break;
                }
            }
        }
        // Remove participants info form ingame data 
        _removeParticipant(msg.sender);

        emit OnLeave(msg.sender);
    }   

    function makePrediction(Prediction _prediction) public onlyNotReadyToPlay onlyNotPaused returns(Prediction) {
        require(_prediction != Prediction.Empty, "Prediction cant be empty");
        require(addressToParticipants[address(msg.sender)].id != address(0), "Participant should exist");
        require(gameEngine.getParticipantAccount(msg.sender).balance >= enterAmount, "Not enough balance");
        require(addressToParticipants[address(msg.sender)].prediction == Prediction.Empty, "Prediction is already done");

        addressToParticipants[address(msg.sender)].prediction = _prediction;

        gameEngine.deductBalance(enterAmount, msg.sender);

        gamePot += enterAmount;
        
        if(_prediction == Prediction.High) {
            higherPredictionAddresses.push(msg.sender);
        } else {
            lowerPredictionsAddresses.push(msg.sender);
        }

        emit OnMakePrediction(_prediction, msg.sender);
        return _prediction;
    }

    function playHandler(uint256 _randomnes) override internal {

        uint256 nextNumber = _calculatePredictionNumber(_randomnes);
        address[] memory winners;


        // If there is no people voted lower - distribute funds back to the user
        if(lowerPredictionsAddresses.length == 0) {
            winners = higherPredictionAddresses;
        // If there is no people voted higher - distribute funds back to the user
        } else if(higherPredictionAddresses.length == 0) {
            winners = lowerPredictionsAddresses;
        } else if(nextNumber > lastRandomness) {
            // If win prediction is High
            winners = higherPredictionAddresses;
        } else {
            // If win prediction is Low
            winners = lowerPredictionsAddresses;
        }


        // Calculate partof the pot distributed to each winner
        uint256 potPerParticipant = gamePot / winners.length;

        uint256 len = winners.length - 1;


        // Distribute pot part winnings to the winners
        for(uint256 i = 0; i <= len; i++) {
            address currentParticipantAddress = winners[i];
            Participant storage currentParticipant = addressToParticipants[currentParticipantAddress];
            gameEngine.addBalance(potPerParticipant, currentParticipantAddress);
            currentParticipant.wins += 1;
        }

        // Auto kick AFK participants with empty predictions
        uint8 afkCount = 0;
        uint256 pLen = _participantsAddressArray.length - 1;
        while (pLen >= 0) {
            address currentParticipantAddress = _participantsAddressArray[pLen];
            Participant storage currentParticipant = addressToParticipants[currentParticipantAddress];

            if(currentParticipant.prediction == Prediction.Empty) {
                _afkKick(pLen, currentParticipantAddress);
                afkCount += 1;
            } else {
                currentParticipant.prediction = Prediction.Empty;
            }

            if(pLen == 0) {
                break;
            }
            pLen--;
        }

        // console.log("Afk count: ", afkCount);
        while(afkCount != 0) {
            _participantsAddressArray.pop();
            afkCount -= 1;
        }

        // Auto kick AFK participants with empty predictions

        higherPredictionAddresses = new address[](0);
        lowerPredictionsAddresses = new address[](0);
        gamePot = 0;

        // Save Randomness
        lastRandomness = nextNumber;

        emit OnPlay(nextNumber, potPerParticipant);
    }

    // Do not forget to remove from participants array _participantsAddressArray.pop()
    function _afkKick(uint256 _idx, address _participatAddress) internal {
        gameEngine.changeInGameStatus(address(0), _participatAddress);
        // Remove participants info form ingame data 
        delete addressToParticipants[_participatAddress];
        _participantsAddressArray[_idx] = _participantsAddressArray[_participantsAddressArray.length - 1];
    }
    
    function _removeParticipant(address _address) internal {
        delete addressToParticipants[_address];
        for(uint8 i = 0; i <=_participantsAddressArray.length; i++) {
            address _participantAddress = _participantsAddressArray[i];
            if(_participantAddress == _address) {
                _participantsAddressArray[i] = _participantsAddressArray[_participantsAddressArray.length - 1];
                _participantsAddressArray.pop();
                break;
            }
        }
    }

    function _calculatePredictionNumber(uint256 _randomness) internal view returns(uint256) {
        uint256 newRandomness = _randomness % 99 + 1;
        if(newRandomness == lastRandomness) {
            if(_randomness % 2 == 0) {
                return newRandomness + 1;
            }
            return newRandomness - 1;
        }

        return newRandomness;
    }


    // API Get requests
    function getParticipantInfo(address _participantAddress) public view returns(Participant memory)  {
        return addressToParticipants[_participantAddress];
    }

    function getAllParticipantsInfo() public view returns(Participant[] memory, string[10] memory) {
        Participant[] memory participants = new Participant[](_participantsAddressArray.length);
        string[10] memory participantNames;

        for (uint i = 0; i < _participantsAddressArray.length; i++) {
            Participant storage participant = addressToParticipants[_participantsAddressArray[i]];
            participants[i] = participant;
            participantNames[i] = gameEngine.getParticipantNameByAddress(participant.id);
        }
        
        return (participants, participantNames);
    }

    function getPredictionsAmount() external view returns(uint256) {
        return higherPredictionAddresses.length + lowerPredictionsAddresses.length;
    }

    function getParticipantsAmount() override public view returns(uint256) {
        return _participantsAddressArray.length;
    }

    function getCronJobGasUsage() override public pure returns(uint256) {
        return 200000;
    }

    function getVrfCallbackMinimumExecutionCost() override public pure returns(uint256) {
        return 189561;
    }
    function getGasPerExtraPlayer() override public pure returns(uint256) {
        return 42842;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./GameHighLowVRF.sol";
import "./GameHighLow.sol";
import "../GameCronJob.sol";

contract GameHighLowCronJob is GameCronJob {

    GameHighLow room;
    constructor(uint _updateInterval, address _systemAddress, address _factoryAddress) GameCronJob(_updateInterval, _systemAddress, _factoryAddress) {}

    function initialize(address _vrfAddress, address _room) external onlyFactroyContract returns(bool) {
        require(!isInit, "Already Initialized");
        isInit = true;
        gameVRF = GameHighLowVRF(_vrfAddress);
        room = GameHighLow(_room);
        return isInit;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        uint256 currentParticipants = room.getParticipantsAmount();
        bool isHaveEnoughPlayers =  currentParticipants <= room.maxParticipants() && currentParticipants >= room.minParticipants();
        bool isReadyToPlay = room.isReadyToPlay();

        uint256 amountOfPredictions = room.getPredictionsAmount();
        bool isEnoughPredictions = amountOfPredictions >= room.minParticipants();
        bool isIntervalPassed = block.number > getNextUpkeepPlanedBlock();

        upkeepNeeded = isIntervalPassed && isHaveEnoughPlayers && !isReadyToPlay && isEnoughPredictions;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./GameHighLow.sol";
import "./GameHighLowVRF.sol";
import "./GameHighLowCronJob.sol";
import "../GameFactory.sol";

contract GameHighLowFactory is GameFactory {

    constructor(
        address _coordintatorAddress,
        bytes32 _keyHash,
        address _gameEngine
        ) GameFactory(_coordintatorAddress, _keyHash, _gameEngine) {}

    function createRoom(uint256 _enterAmount, uint256 _loseAmount, uint256 _maxParticipants, uint256 _jackpotFactor) override public onlySystemAddress returns (address) {

        address room = address(new GameHighLow(_enterAmount, _loseAmount, _maxParticipants, systemAddress, _jackpotFactor, address(gameEngine), 3));
        address roomVrf = address(new GameHighLowVRF(coordintatorAddress, subscriptionId, keyHash, systemAddress, room));
        // Game will be trigered each 4 mined block
        address gameCroneJob = address(new GameHighLowCronJob(5, systemAddress, address(this)));


        GameHighLow(room).initGameVRF(roomVrf, gameCroneJob);
        GameHighLowCronJob(gameCroneJob).initialize(roomVrf, room);
        COORDINATOR.addConsumer(subscriptionId, roomVrf);

        emit OnRoomCreation(room, _enterAmount, _loseAmount, _maxParticipants, roomVrf);
        roomAddresses.push(room);

        return room;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../GameEngine.sol";
import "../GameVRF.sol";


contract GameHighLowVRF is GameVRF {
    constructor(
        address _coordintatorAddress,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _systemAddress,
        address _roomAddress
    ) GameVRF(_coordintatorAddress, _subscriptionId, _keyHash, _systemAddress, _roomAddress) {}

    function getRequestConfirmations() override pure internal returns(uint16) {
        return 3;
    }
    function getCallbackGasLimit() override pure internal returns(uint32) {
        return 1000000;
    }
}