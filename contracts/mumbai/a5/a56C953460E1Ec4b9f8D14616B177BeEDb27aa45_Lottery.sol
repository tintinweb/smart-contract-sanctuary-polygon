// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {

  address owner; 
  uint8[] public rangeArray;
  uint8[] public winningArray;
  uint128 public ticketId;

  uint8[6][] public ticketsArray;
  address[] public ticketOwnersArray;

  address payable[] public sixWinners;
  address payable[] public fiveWinners;
  address payable[] public fourWinners;
  address payable[] public threeWinners;

  uint256 public ticketPrice;
  uint256 public prizePool;
  uint256 public protocolFee;

  uint256 threePrize;
  uint256 fourPrize;
  uint256 fivePrize;
  uint256 sixPrize;


  // CHAINLINK CONFIGURATION
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  VRFCoordinatorV2Interface COORDINATOR;

  // polygon mumbai
  address constant vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 constant keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  uint64 immutable subscriptionId;
  uint32 constant callbackGasLimit = 2000000;
  uint16 constant requestConfirmations = 3;
  uint16 constant randomNumbersAmount =  6;
  uint256 public requestId;
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


  constructor(
    uint64 _subscriptionId
  ) VRFConsumerBaseV2(vrfCoordinator) {

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    subscriptionId = _subscriptionId;

    owner = msg.sender;

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
    ticketId = 0;

    // later set it to 1 ether
    ticketPrice = 10000000000000000; // 0.01 ether

    // set prizes:
    // later set: 1.2 ether
    threePrize = 12000000000000000; // 0.012 ether

    // later set: 5 ether
    fourPrize = 50000000000000000; // 0.05 ether

    // later set: 10 ether
    fivePrize = 100000000000000000; // 0.10 ether

  }



  // ===================================================
  //                  INTERNAL INTERFACE
  // ===================================================


  // get number from rangeArray and push to winningArray
  // after the is pushed to winningArray, delete it from the rangeArray 
  // so all the numbers are uniqe
  // *** INTERNAL ***
  function getNumber(uint256 number) public {
    winningArray.push(rangeArray[number]);

    delete rangeArray[number];

    for(uint256 i = number; i < rangeArray.length - 1; i++) {
      rangeArray[i] = rangeArray[i + 1];
    }
  }

  // pass here array of random numbers from chainlink to receive 
  // winningArray of 6 random numbers
  // *** INTERNAL ***
  // *** WARNING ***
  // this may be gas consuming, check if Chainlink will be able
  // to execute this function in fallback
  function setWinningArray(uint256[] memory randomNumbers) public {

    getNumber(randomNumbers[0] % rangeArray.length);
    getNumber(randomNumbers[1] % rangeArray.length);
    getNumber(randomNumbers[2] % rangeArray.length);
    getNumber(randomNumbers[3] % rangeArray.length);
    getNumber(randomNumbers[4] % rangeArray.length);
    getNumber(randomNumbers[5] % rangeArray.length);
  }

  // call to pay rewards to winners
  // *** INTERNAL ***
  function payRewards(address payable withdrawTo, uint256 amount) internal {
    withdrawTo.transfer(amount);
  }


  // ===================================================
  //                  PUBLIC INTERFACE
  // ===================================================

  // *** PAY TICKET PRICE ***
  function buyTicket(
    uint8 first,
    uint8 second,
    uint8 third,
    uint8 fourth,
    uint8 fifth,
    uint8 sixth
  ) public payable {

    // 80% from the ticket price go to prizePool
    prizePool = prizePool + (msg.value / 100) * 80;
    // 20% from the ticket price go to protocolFee and is claimable by admin.
    protocolFee = protocolFee + (msg.value / 100) * 20;

    ticketsArray.push([first, second, third, fourth, fifth, sixth]);
    ticketOwnersArray.push(msg.sender);

    ticketId++; 
  }



  // ===================================================
  //                  ADMIN INTERFACE
  // ===================================================


  // admin check for winners and push them to arrays eligible for rewards
  // *** ONLY OWNER ***
  function checkWinners() public {

    for(uint32 i = 0; i < ticketsArray.length; i++) {
      uint8 matching = 0;

      for(uint8 j = 0; j < ticketsArray[i].length; j++) {

        for(uint8 k = 0; k < winningArray.length; k++) {
          if(winningArray[k] == ticketsArray[i][j]) {
            matching = matching + 1;
          }
        }
      }

      if(matching == 6) {
        sixWinners.push(payable(ticketOwnersArray[i]));
      } else if(matching == 5) {
        fiveWinners.push(payable(ticketOwnersArray[i]));
      } else if(matching == 4) {
        fourWinners.push(payable(ticketOwnersArray[i]));
      } else if(matching == 3) { 
        threeWinners.push(payable(ticketOwnersArray[i]));
      }
    }
  }


  // admin can restart the game
  // *** ONLY OWNER ***
  function resetGame() public {

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36];
    ticketId = 0;

    delete ticketsArray;
    delete ticketOwnersArray;
    delete winningArray;

    delete sixWinners;
    delete fiveWinners;
    delete fourWinners;
    delete threeWinners;
  }


  // admin distribute rewards
  // *** ONLY OWNER ***
  function distributeRewardToWinners() public {

    for(uint32 i = 0; i < threeWinners.length; i++) {
      payRewards(threeWinners[i], threePrize);
    }
    // update prize pool - subtract rewards for three
    prizePool = prizePool - (threeWinners.length * threePrize);


    for(uint32 i = 0; i < fourWinners.length; i++) {
      payRewards(fourWinners[i], fourPrize);
      prizePool = prizePool - fourPrize;
    }
    // update prize pool - subtract rewards for four
    prizePool = prizePool - (fourWinners.length * fourPrize);


    for(uint32 i = 0; i < fiveWinners.length; i++) {
      payRewards(fiveWinners[i], fivePrize);
    }
    // update prize pool - subtract rewards for five
    prizePool = prizePool - (fiveWinners.length * fivePrize);

    if(sixWinners.length != 0) {
      sixPrize = prizePool / sixWinners.length;
    }
    for(uint32 i = 0; i < sixWinners.length; i++) {
      payRewards(sixWinners[i], sixPrize);
    }
    // update prize pool - subtract rewards for four
    prizePool = prizePool - (sixWinners.length * sixPrize);

  }


  // admin fund prize pool
  // *** ONLY OWNER ***
  function adminFundProtocol() public payable {
    prizePool = prizePool + msg.value;
  }


  // adming withdraw fees
  // *** ONLY OWNER ***
  function adminWithdrawFees(address payable withdrawTo, uint256 amount) public {
    require(amount <= protocolFee, "Cannot withdraw more than protocol fee");

    protocolFee = protocolFee - amount;
    withdrawTo.transfer(amount);
  }


  // admin withdrawn all - helper - will be deleted
  // *** ONLY OWNER ***
  function adminWithdrawAll(address payable withdrawTo) public {
    withdrawTo.transfer(address(this).balance);
  }


  // admin complete the game, check winners, distribute reward
  // *** ONLY OWNER ***
  function adminCompleteGame() public {
    checkWinners();
    distributeRewardToWinners();
  }


  // START LOTTERY
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  // *** ONLY OWNER ***
  function startLottery() public {

    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      randomNumbersAmount
    );

    // assing requestId to gameId 
  }
  // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx



  // ===================================================
  //               CHAINLINK FALLBACK
  // ===================================================

  // chainlink retrives random numbers here
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomNumbers) internal override {

    setWinningArray(_randomNumbers);

    checkWinners();
    distributeRewardToWinners();
  }



  // ===================================================
  //               MODIFIERS - REQUIREMENTS
  // ===================================================


  // Only owner is allowed to call function
  modifier onlyOwner() {
    require(msg.sender == owner, "You are not an owner");
    _;
  }


  // User must pay lottery ticket price
  modifier payTicketPrice() {
    require(msg.value == ticketPrice, "Incorrect value");
    _;
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