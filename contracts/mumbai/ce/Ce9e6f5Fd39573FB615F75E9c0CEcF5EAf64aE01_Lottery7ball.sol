// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery7ball is VRFConsumerBaseV2, Ownable, AutomationCompatible {


  uint8[] rangeArray;
  uint8[] public drawnNumbersArray;

  uint8[7][] public ticketsArray;
  address[] public ticketOwnersArray;

  address[] winners7ball;
  address[] winners6ball;
  address[] winners5ball;
  address[] winners4ball;
  address[] winners3ball;

  uint256 prize7matched;
  uint256 prize6matched;
  uint256 prize5matched;
  uint256 prize4matched;
  uint256 prize3matched;

  uint256 ticketPrice;

  uint256 public prizePool;
  uint256 public protocolPool;
  uint256 public adminPool;

  uint256 public lastTimeStamp;
  uint256 public interval;
  bool public gameIsOn;

  mapping(address => uint256) public addressToRewardBalance;

  event UpdatedNumbersDrawn();
  event UpdatedInterval(uint256 indexed interval);
  event UpdatedPrizePool();
  event UpdatedBalances();
  event GameIsOn(bool isGameOn);

  // ===================================================
  //                  CHAINLINK CONFIGURATION
  // ===================================================

  VRFCoordinatorV2Interface COORDINATOR;

  address constant vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 constant keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  uint64 immutable subscriptionId;
  uint32 constant callbackGasLimit = 2000000;
  uint16 constant requestConfirmations = 3;
  uint16 constant randomNumbersAmount =  7;
  uint256 public requestId;

  

  constructor(
    uint64 _subscriptionId
  ) VRFConsumerBaseV2(vrfCoordinator) {

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    subscriptionId = _subscriptionId;

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42];

    prize6matched = 1000000000000000000; // 1.00 ether
    prize5matched = 100000000000000000; // 0.10 ether
    prize4matched = 50000000000000000; // 0.05 ether
    prize3matched = 12000000000000000; // 0.012 ether

    ticketPrice = 1 ether;

    lastTimeStamp = block.timestamp;
    interval = 1 hours;
    gameIsOn = true;
  }




  // ===================================================
  //                  AUTOMATION INTERFACE
  // ===================================================

  function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
  }

  function performUpkeep(bytes calldata /* performData */) external override {

    if ((block.timestamp - lastTimeStamp) > interval ) {

      if(gameIsOn) {
        lastTimeStamp = block.timestamp;
        startLottery();

        interval = 20 minutes;
        gameIsOn = false;

        emit GameIsOn(gameIsOn);
        emit UpdatedInterval(interval);

      } else {
        lastTimeStamp = block.timestamp;
        resetGame();

        interval = 1 hours;
        gameIsOn = true;

        emit GameIsOn(gameIsOn);
        emit UpdatedInterval(interval);
      }
    }
  }

  function startLottery() internal {

    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      randomNumbersAmount
    );
  }

  function resetGame() internal {

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42];

    delete ticketsArray;
    delete ticketOwnersArray;
    delete drawnNumbersArray;

    delete winners7ball;
    delete winners6ball;
    delete winners5ball;
    delete winners4ball;
    delete winners3ball;

    emit UpdatedNumbersDrawn();
  }


  // ===================================================
  //               CHAINLINK FALLBACK
  // ===================================================

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomNumbers) internal override {

    addNumberToDrawnNumbersArray(_randomNumbers[0] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[1] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[2] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[3] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[4] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[5] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[6] % rangeArray.length);

    pushWinnersToArrays();
    assignPrizesToWinnersBalances();

    emit UpdatedNumbersDrawn();
  }




  // ===================================================
  //               PUBLIC INTERFACE
  // ===================================================

  function claimReward() public {
    require(address(this).balance >= addressToRewardBalance[msg.sender], "Insufficient funds in contract");

    uint256 rewardBalance = addressToRewardBalance[msg.sender];
    addressToRewardBalance[msg.sender] = 0;
    payable(msg.sender).transfer(rewardBalance);
  }

  
  function buyTicket(
    uint8 first,
    uint8 second,
    uint8 third,
    uint8 fourth,
    uint8 fifth,
    uint8 sixth,
    uint8 seventh) public payable payThePrice lotteryIsOn {

    prizePool = prizePool + (msg.value / 100) * 90;
    protocolPool = protocolPool + (msg.value / 100) * 10;

    ticketsArray.push([first, second, third, fourth, fifth, sixth, seventh]);
    ticketOwnersArray.push(msg.sender);

    emit UpdatedPrizePool();
  }




  // ===================================================
  //               ADMIN INTERFACE
  // ===================================================

  function adminWithdrawProtocolPool(address payable withdrawTo, uint256 amount) public onlyOwner {
    require(amount <= protocolPool, "Cannot withdraw more than protocolPool");

    protocolPool = protocolPool - amount;
    withdrawTo.transfer(amount);
  }

  function adminWithdrawAdminPool(address payable withdrawTo, uint256 amount) public onlyOwner {
    require(amount <= adminPool, "Cannot withdraw more than adminPool");

    adminPool = adminPool - amount;
    prizePool = prizePool - amount;
    withdrawTo.transfer(amount);

    emit UpdatedPrizePool();
  }

  function adminFundContract() public payable onlyOwner {
    prizePool += msg.value;
    adminPool += msg.value;

    emit UpdatedPrizePool();
  }



  // ===================================================
  //               UTILS / HELPERS
  // ===================================================

  function addNumberToDrawnNumbersArray(uint256 number) internal {
    drawnNumbersArray.push(rangeArray[number]);

    delete rangeArray[number];

    for(uint256 i = number; i < rangeArray.length - 1; i++) {
      rangeArray[i] = rangeArray[i + 1];
    }
  }


  function pushWinnersToArrays() internal {

    for(uint32 i = 0; i < ticketsArray.length; i++) {
      uint8 matching = 0;

      for(uint8 j = 0; j < ticketsArray[i].length; j++) {

        for(uint8 k = 0; k < drawnNumbersArray.length; k++) {
          if(drawnNumbersArray[k] == ticketsArray[i][j]) {
            matching = matching + 1;
          }
        }
      }

      if(matching == 7) {
        winners7ball.push(ticketOwnersArray[i]);

      } else if(matching == 6) {
        winners6ball.push(ticketOwnersArray[i]);

      } else if(matching == 5) {
        winners5ball.push(ticketOwnersArray[i]);

      } else if(matching == 4) {
        winners4ball.push(ticketOwnersArray[i]);
        
      } else if(matching == 3) { 
        winners3ball.push(ticketOwnersArray[i]);
      }
    }
  }


  function assignPrizesToWinnersBalances() internal {

    /*
      This function is called to assign prize to each winner.
      Prizes for up to 6 matched numbers are fixed that is why they are determined first.
      Main prize for 7 matched numbers is always prizePool, so to make sure that all winners
      will get their prize, it is calculated at the end, and has to be split between all
      who matched 7 numbers evenly.
    */

    if(winners3ball.length != 0) {
      for(uint32 i = 0; i < winners3ball.length; i++) {
        addressToRewardBalance[winners3ball[i]] += prize3matched;
      }
      prizePool = prizePool - (winners3ball.length * prize3matched);
    }


    if(winners4ball.length != 0) {
      for(uint32 i = 0; i < winners4ball.length; i++) {
        addressToRewardBalance[winners4ball[i]] += prize4matched;
      }
      prizePool = prizePool - (winners4ball.length * prize4matched);
    }


    if(winners5ball.length != 0) {
      for(uint32 i = 0; i < winners5ball.length; i++) {
        addressToRewardBalance[winners5ball[i]] += prize5matched;
      }
      prizePool = prizePool - (winners5ball.length * prize5matched);
    }


    if(winners6ball.length != 0) {
      for(uint32 i = 0; i < winners6ball.length; i++) {
        addressToRewardBalance[winners6ball[i]] += prize6matched;
      }
      prizePool = prizePool - (winners6ball.length * prize6matched);
    }


    if(winners7ball.length != 0) {
      prize7matched = prizePool / winners7ball.length;

      for(uint32 i = 0; i < winners7ball.length; i++) {
        addressToRewardBalance[winners7ball[i]] += prize7matched;
      }
      prizePool = prizePool - (winners7ball.length * prize7matched);
    }

    emit UpdatedBalances();
  }




  // ===================================================
  //                  MODIFIERS
  // ===================================================

  modifier payThePrice() {
    require(msg.value >= ticketPrice, "Insufficient transfer");
    _;
  }

  modifier lotteryIsOn() {
    require(gameIsOn == true, "Lottery has not started yet");
    _;
  }




  // ===================================================
  //               TESTING INTERFACE
  //               only for testnet
  // ===================================================

  function test_withdrawAll() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function test_fundContract() public payable onlyOwner {
    prizePool += msg.value;
    
    emit UpdatedPrizePool();
  }

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
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}