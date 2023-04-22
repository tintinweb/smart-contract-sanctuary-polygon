// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Constants.sol";
import "./utils/BreakdownUint256.sol";

contract Blackjack is VRFConsumerBaseV2, Ownable, BreakdownUint256 {
    // VRF parameters
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 public subscriptionId;
    uint256 public requestId;
    uint256[] public randomWords;

    event GameStarted(address player, uint256 bet);
    event PlayerWin();
    event DealerWin();
    event Tie();

    enum State {
        INACTIVE,
        WAITING_FOR_INIT_VRF,
        PLAYER_TURN,
        WAITING_FOR_PLAYER_VRF,
        RESOLVING_PLAYER_HAND,
        WAITING_FOR_DEALER_VRF,
        RESOLVING_DEALER_HAND,
        TIE,
        PLAYER_WINS,
        DEALER_WINS,
        FAILED_VRF
    }

    enum Card {
        ACE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT,
        NINE,
        TEN,
        JACK,
        QUEEN,
        KING
    }

    struct GameState {
        Card[] playerCards;
        Card[] dealerCards;
        uint256 bet;
        State blackjackstate;
        address playerAddress;
        bool isPlaying;
    }

    function dealerCards(address player) public view returns (Card[] memory) {
        return gamesStates[player].dealerCards;
    }

    function playerCards(address player) public view returns (Card[] memory) {
        return gamesStates[player].playerCards;
    }

    function VRFCards(address player) public view returns (uint8[] memory) {
        return vrfRequests[addressToVRF[player]].cards;
    }

    mapping(address => GameState) public gamesStates;
    mapping(address => uint256) public addressToVRF;
    // key value is requestIndex given by VRF Coordinator
    mapping(uint256 => VRFRequest) public vrfRequests;
    mapping(uint8 => uint8) public cardValues;

    enum VRFRequestType {
        INIT,
        PLAYER,
        DEALER
    }

    struct VRFRequest {
        VRFRequestType vrfRequestType;
        address playerAddress;
        bool isFulfilled;
        uint timestamp;
        uint8[] cards;
    }

    constructor(
        address vrfCoordinator,
        address link
    ) payable VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
        LINKTOKEN = LinkTokenInterface(link);
    }

    function fund(uint256 amount) public {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(subscriptionId)
        );
    }

    function randomnessIsRequestedHere() public {
        uint256 requestId_ = COORDINATOR.requestRandomWords(
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            subscriptionId,
            3,
            2_500_000,
            1
        );
        requestId = requestId_;
        addressToVRF[msg.sender] = requestId_;
    }

    function requestRandomWords() public returns (uint256) {
        uint256 requestId_ = COORDINATOR.requestRandomWords(
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            subscriptionId,
            3,
            2_500_000,
            1
        );
        addressToVRF[msg.sender] = requestId_;
        return requestId_;
    }

    function calculateHandValue(
        Card[] memory cards
    ) public pure returns (uint8) {
        uint8 handValue = 0;
        uint8 aces = 0;

        for (uint8 i = 0; i < cards.length; i++) {
            uint8 card = uint8(cards[i]);

            if (card == 0) {
                handValue += 11;
                aces++;
            } else if (card > 0 && card < 10) {
                handValue += card + 1;
            } else {
                handValue += 10;
            }
        }

        while (handValue > 21 && aces > 0) {
            handValue -= 10;
            aces--;
        }

        return handValue;
    }

    function viewPlayerTotal(address player) public view returns (uint8) {
        return calculateHandValue(gamesStates[player].playerCards);
    }

    function viewDealerTotal(address player) public view returns (uint8) {
        return calculateHandValue(gamesStates[player].dealerCards);
    }

    function uint8ToCard(uint8 randomUint8) public pure returns (Card) {
        // If uint8 is above 247, it will be rehashed
        // to a number between 0 and 247
        while (randomUint8 > 247) {
            bytes32 hashedInput = keccak256(abi.encodePacked(randomUint8));
            randomUint8 = uint8(uint256(hashedInput) % 256);
        }

        uint8 card = randomUint8 % 13;
        require(card <= uint8(Card.KING), "Invalid card value");
        return Card(card);
    }

    function showGameState() external view returns (GameState memory) {
        return gamesStates[msg.sender];
    }

    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords_
    ) internal override {
        randomWords = randomWords_;

        VRFRequest storage vrfRequest = vrfRequests[requestId_];
        vrfRequest.isFulfilled = true;

        // require(!vrfRequest.isFulfilled, "Request is already fulfilled");

        uint256 randomWord = randomWords[0];

        uint8[] memory randomUint8s = getUint256BrokenIntoUint8(randomWord);

        vrfRequest.cards = [
            randomUint8s[0],
            randomUint8s[1],
            randomUint8s[2],
            randomUint8s[3],
            randomUint8s[4],
            randomUint8s[5]
        ];

        if (vrfRequest.vrfRequestType == VRFRequestType.INIT) {
            fulfillInit(requestId_);
        } else if (vrfRequest.vrfRequestType == VRFRequestType.PLAYER) {
            fulfillPlayerTurn(requestId_);
        } else if (vrfRequest.vrfRequestType == VRFRequestType.DEALER) {
            fulfillDealerTurn(requestId_);
        }
    }

    function fulfillInit(uint256 requestId_) private {
        VRFRequest storage vrfRequest = vrfRequests[requestId_];

        address player = vrfRequest.playerAddress;

        GameState storage gameState = gamesStates[player];

        require(
            gameState.blackjackstate == State.WAITING_FOR_INIT_VRF,
            "Game is not waiting for init VRF"
        );

        Card playerCard1 = uint8ToCard(vrfRequest.cards[0]);
        Card playerCard2 = uint8ToCard(vrfRequest.cards[1]);
        Card dealerCard1 = uint8ToCard(vrfRequest.cards[2]);

        gameState.playerCards.push(playerCard1);
        gameState.playerCards.push(playerCard2);
        gameState.dealerCards.push(dealerCard1);

        gameState.blackjackstate = State.PLAYER_TURN;
    }

    function fulfillPlayerTurn(uint256 requestId_) private {
        VRFRequest storage vrfRequest = vrfRequests[requestId_];

        address player = vrfRequest.playerAddress;

        GameState storage gameState = gamesStates[player];

        require(
            gameState.blackjackstate == State.WAITING_FOR_PLAYER_VRF,
            "Game is not waiting for player VRF"
        );

        uint8[] memory randomUint8s = vrfRequest.cards;

        Card playerCard = uint8ToCard(randomUint8s[0]);

        addPlayerCard(gameState, playerCard);
    }

    function fulfillDealerTurn(uint256 requestId_) private {
        VRFRequest storage vrfRequest = vrfRequests[requestId_];

        address player = vrfRequest.playerAddress;

        GameState storage gameState = gamesStates[player];

        require(
            gameState.blackjackstate == State.WAITING_FOR_DEALER_VRF,
            "Game is not waiting for dealer VRF"
        );

        uint8[] memory randomUint8s = vrfRequest.cards;

        for (uint256 i = 0; i < 5; i++) {
            Card dealerCard = uint8ToCard(randomUint8s[i]);
            if (addDealerCard(gameState, dealerCard)) {
                // Dealer has 17 or more
                break;
            }
        }

        // find winner
        uint8 playerValue = calculateHandValue(gameState.playerCards);
        uint8 dealerValue = calculateHandValue(gameState.dealerCards);

        if (dealerValue > 21) {
            // player won
            payable(player).transfer(gameState.bet * 2);
            gameState.blackjackstate = State.INACTIVE;
            emit PlayerWin();
        } else if (playerValue > dealerValue) {
            // player won
            payable(player).transfer(gameState.bet * 2);
            gameState.blackjackstate = State.INACTIVE;
            emit PlayerWin();
        } else if (playerValue == dealerValue) {
            // tie
            payable(player).transfer(gameState.bet);
            gameState.blackjackstate = State.INACTIVE;
            emit Tie();
        } else if (playerValue < dealerValue) {
            // player lost
            gameState.blackjackstate = State.INACTIVE;
            emit DealerWin();
        }
    }

    function addPlayerCard(
        GameState storage gameState,
        Card card
    ) private returns (bool) {
        gameState.playerCards.push(card);
        uint8 value = calculateHandValue(gameState.playerCards);
        if (value > 21) {
            gameState.blackjackstate = State.INACTIVE;
            gameState.isPlaying = false;
            emit DealerWin();
        } else {
            gameState.blackjackstate = State.PLAYER_TURN;
        }
    }

    function addDealerCard(
        GameState storage gameState,
        Card card
    ) private returns (bool) {
        gameState.dealerCards.push(card);
        uint8 value = calculateHandValue(gameState.dealerCards);
        if (value > 16) {
            gameState.blackjackstate = State.INACTIVE;
            gameState.isPlaying = false;
            return true;
        } else {
            gameState.blackjackstate = State.INACTIVE;
            return false;
        }
    }

    function deal() public payable {
        address player = msg.sender;
        GameState storage gameState = gamesStates[player];

        require(
            gameState.blackjackstate == State.INACTIVE,
            "Game is already in progress"
        );

        // Bet amount must be less than 1 ether
        require(msg.value < 1 ether, "Bet amount must be less than 1 ether");

        // Bet amount must be greater than 0.01 ether
        require(
            msg.value > 0.0001 ether,
            "Bet amount must be greater than 0.01 ether"
        );

        // Memory error, doing it manually for now
        // gameState = GameState({
        //     bet: msg.value,
        //     blackjackstate: State.WAITING_FOR_INIT_VRF,
        //     isPlaying: true,
        //     playerCards: new Card[](0),
        //     dealerCards: new Card[](0),
        //     playerAddress: player
        // });

        gameState.bet = msg.value;
        gameState.blackjackstate = State.WAITING_FOR_INIT_VRF;
        gameState.isPlaying = true;
        gameState.playerCards = new Card[](0);
        gameState.dealerCards = new Card[](0);
        gameState.playerAddress = player;

        requestInitVRF();
    }

    function hit() public {
        address player = msg.sender;
        GameState storage gameState = gamesStates[player];

        require(
            gameState.blackjackstate == State.PLAYER_TURN,
            "Game is not in player turn"
        );

        gameState.blackjackstate = State.WAITING_FOR_PLAYER_VRF;
        requestPlayerVRF(player);
    }

    function stand() public {
        address player = msg.sender;
        GameState storage gameState = gamesStates[player];

        require(
            gameState.blackjackstate == State.PLAYER_TURN,
            "Game is not in player turn"
        );

        gameState.blackjackstate = State.WAITING_FOR_DEALER_VRF;
        requestDealerVRF(player);
    }

    function requestInitVRF() private {
        VRFRequest memory vrfRequest = VRFRequest(
            VRFRequestType.INIT,
            msg.sender,
            false,
            block.timestamp,
            new uint8[](0)
        );

        uint256 requestId_ = requestRandomWords();

        vrfRequests[requestId_] = vrfRequest;
    }

    function requestPlayerVRF(address player) private {
        VRFRequest memory vrfRequest = VRFRequest(
            VRFRequestType.PLAYER,
            player,
            false,
            block.timestamp,
            new uint8[](0)
        );

        uint256 requestId_ = requestRandomWords();

        vrfRequests[requestId_] = vrfRequest;
    }

    function requestDealerVRF(address player) private {
        VRFRequest memory vrfRequest = VRFRequest(
            VRFRequestType.DEALER,
            player,
            false,
            block.timestamp,
            new uint8[](0)
        );

        uint256 requestId = requestRandomWords();

        vrfRequests[requestId] = vrfRequest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract Constants {
    mapping(string => Config) internal configMap;
    struct Config {
        VRFCoordinatorV2Interface vrfCoordinator;
        LinkTokenInterface linkToken;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    constructor() {
        Config memory mumbai = Config(
            VRFCoordinatorV2Interface(
                0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
            ),
            LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB),
            0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            2500000,
            3,
            1
        );

        Config memory sepolia = Config(
            VRFCoordinatorV2Interface(
                0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
            ),
            LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789),
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            100000,
            3,
            2
        );

        configMap["mumbai"] = mumbai;
        configMap["sepolia"] = sepolia;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract BreakdownUint256 {
    function getUint256BrokenIntoUint8(
        uint256 n
    ) public pure returns (uint8[] memory) {
        uint8[] memory _8BitNumbers = new uint8[](32);

        // Mask to copy 8 bits at a time
        // 0xff is 8 bits, so we are copying 8 bits at a time.
        // After copying 8 bits, then we need to move the ff 8 bits to the left, to be able to copy the next 8 bits
        uint256 mask = 0x00000000000000000000000000000000000000000000000000000000000000ff;
        uint256 shiftBy = 0;

        // a 256-bit number has 32 bytes
        for (int256 i = 31; i >= 0; i--) {
            // Copying from right to left, end of the array to the start

            // Copying 8 bits of n doing an AND bitwise operation
            uint256 v = n & mask;

            // After every iteration, move the mask byte 8 bits to the left
            mask <<= 8;

            // The bits we just copied are to the left, if we try to cast v to uint8 then the bits will be lost and the result will be 0,
            // because the casting takes the lower bits (the right-most bits).
            // To prevent this, we need to shift the bits to the right-most part and then do the casting.
            // With shiftBy, we keep track of how many bits to th left we have copied and this way we can take these
            // bits to the left-most by shifting them shiftBy times.
            v >>= shiftBy;

            // Casting the bits to uint8 then to bytes1 and adding them to the b bytes array.
            _8BitNumbers[uint256(i)] = uint8(v);

            // For the next interation, we need to skip the current 8 bits and copy the next 8 bits.
            shiftBy += 8;
        }

        return _8BitNumbers;
    }
}