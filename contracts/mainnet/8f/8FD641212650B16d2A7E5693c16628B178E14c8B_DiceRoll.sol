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

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ITest1.sol";

/// @title X's Coin Toss game
/// @notice The game is played with a two-sided coin. The game's goal is to guess whether the lucky coin face will be Heads or Tails.
/// @author Anush GS
contract DiceRoll is VRFConsumerBaseV2, ReentrancyGuard {
    /// @notice Enum to identify coin faces.
    enum DiceFace {
        One,
        Two,
        Three,
        Four,
        Five,
        Six
    }

    enum BetStatus {
        Active,
        Loss,
        Win,
        Suspend
    }

    struct ChainLinkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    struct RolledDice {
        address bettor;
        address token;
        address provider;
        uint8 multiplier;
        uint256 stake;
        uint256 payout;
        uint256 randomWord;
        uint256 timesstamp;
        DiceFace choice;
        BetStatus status;
        bool rolled;
    }

    struct StakeLimits {
        uint256 minStake;
        uint256 maxStake;
    }

    //mapping
    mapping(address => StakeLimits) private s_tokenToStakeLimits;
    mapping(address => uint256) private s_tokenToHouseEdge;
    mapping(address => uint8) private s_tokenToMultiplier;
    mapping(address => uint256) private s_tokenToBetTimelock;
    mapping(uint256 => RolledDice) private s_requestIdToDiceRoll;

    // Chainlink VRF Variables
    ChainLinkConfig private s_chainLinkConfig;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    address private s_diceRollOwner;
    ITest1 private immutable i_core;
    bool private gameAllowed = true;

    event DiceRolled(uint256 indexed requestId, address indexed bettor, address indexed token, uint256 multiplier, uint256 stake, uint256 payout, DiceFace choice, BetStatus status);
    event DiceRollSettled(uint256 indexed requestId, address indexed bettor, address indexed token, BetStatus status, uint256 randomWord);

    error DiceRoll__OnlyOwnerMethod();
    error DiceRoll__GameDisabled();
    error DiceRoll__IncorrectAddress();
    error DiceRoll__StakeToSmall();
    error DiceRoll__StakeToBig();
    error DiceRoll__StakeMoreThanBalance();
    error DiceRoll__InsuffcientUserStake();
    error DiceRoll__InsuffcientStakes();
    error DiceRoll__InsuffcientHL();
    error DiceRoll__InsuffcientProviderPayouts();
    error DiceRoll__InsuffcientPayouts();
    error DiceRoll__ContractIsNotBalanced();
    error DiceRoll__RequestIdNotFound();
    error DiceRoll__NotBettor();
    error DiceRoll__OnlyActiveSuspend();
    error DiceRoll__Timelock();

    constructor(address vrfCoordinatorV2, address owner, address payable core) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        s_diceRollOwner = owner;
        i_core = ITest1(core);
    }

    modifier onlyDiceRollOwner() {
        if (msg.sender != s_diceRollOwner) {
            revert DiceRoll__OnlyOwnerMethod();
        }
        _;
    }

    modifier isGameAllowed() {
        if (!gameAllowed) {
            revert DiceRoll__GameDisabled();
        }
        _;
    }

    function transferDiceRollOwnership(address _newOwner) public onlyDiceRollOwner {
        _transferDiceRollOwnership(_newOwner);
    }

    function _transferDiceRollOwnership(address _newOwner) internal {
        if (_newOwner == address(0)) {
            revert DiceRoll__IncorrectAddress();
        }
        s_diceRollOwner = _newOwner;
        //emit TransferOpsOwnership(oldOwner, _newOwner);
    }

    function setCoreOwnershipInDiceRoll(address newOwner) public onlyDiceRollOwner {
        i_core.setCoreOwnership(newOwner);
    }

    function disableCoreOwnershipInDiceRoll(address owner) public onlyDiceRollOwner {
        i_core.disableCoreOwnership(owner);
    }

    function modifyGameAllowed(bool status) public onlyDiceRollOwner {
        gameAllowed = status;
    }

    function setMultiplier(address token, uint8 newMultiplier) public onlyDiceRollOwner {
        s_tokenToMultiplier[token] = newMultiplier;
    }

    function setHouseEdge(address token, uint256 houseEdge) public onlyDiceRollOwner {
        s_tokenToHouseEdge[token] = houseEdge;
    }

    function setStakeLimits(address token, uint256 minStake, uint256 maxStake) public onlyDiceRollOwner {
        s_tokenToStakeLimits[token] = StakeLimits(minStake, maxStake);
    }

    function setBetTimelock(address token, uint256 duration) public onlyDiceRollOwner {
        s_tokenToBetTimelock[token] = duration;
    }

    function setChainLinkConfig(uint64 subscriptionId, bytes32 gasLane, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) public onlyDiceRollOwner {
        s_chainLinkConfig = ChainLinkConfig(subscriptionId, gasLane, callbackGasLimit, requestConfirmations, numWords);
    }

    function rollDice(address token, uint256 stake, DiceFace choice) external nonReentrant isGameAllowed {
        address provider = i_core.getBaseProvider(token);
        uint256 tips = i_core.getUserTips(msg.sender, token);
        uint256 bal = i_core.getUserBalance(msg.sender, token);
        uint256 tipsToSubtract;
        if (stake < s_tokenToStakeLimits[token].minStake) revert DiceRoll__StakeToSmall();
        if (stake > s_tokenToStakeLimits[token].maxStake) revert DiceRoll__StakeToBig();
        if (stake > tips + bal) revert DiceRoll__StakeMoreThanBalance();
        uint256 payout = calculatePayout(token, stake);
        uint256 housecut = calculateHouseCut(token, payout);
        payout = payout - housecut;
        if (payout > i_core.getTotalHL(token)) revert DiceRoll__InsuffcientHL();
        if (payout > i_core.getDepositerHLBalance(provider, token)) revert DiceRoll__InsuffcientHL();
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            s_chainLinkConfig.gasLane,
            s_chainLinkConfig.subscriptionId,
            s_chainLinkConfig.requestConfirmations,
            s_chainLinkConfig.callbackGasLimit,
            s_chainLinkConfig.numWords
        );
        s_requestIdToDiceRoll[requestId] = RolledDice(msg.sender, token, provider, s_tokenToMultiplier[token], stake, payout, 6, block.timestamp, choice, BetStatus.Active, true);
        emit DiceRolled(requestId, msg.sender, token, s_tokenToMultiplier[token], stake, payout, choice, BetStatus.Active);
        if (tips > 0) {
            tipsToSubtract = (tips >= stake) ? stake : tips;
            uint256 stakeLeft = stake - tipsToSubtract;
            i_core.handleUserTips(msg.sender, token, tipsToSubtract, 0);
            if (stakeLeft > 0) i_core.handleBalance(msg.sender, token, stakeLeft, 0);
        } else {
            i_core.handleBalance(msg.sender, token, stake, 0);
        }
        i_core.handleStakes(msg.sender, token, stake, 1);
        i_core.handleHL(provider, token, payout, 0);
        i_core.handlePayout(provider, token, payout, 1);
        if (!i_core.getBalancedStatus(token)) revert DiceRoll__ContractIsNotBalanced();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        RolledDice storage rolledDice = s_requestIdToDiceRoll[requestId];
        if (!rolledDice.rolled) revert DiceRoll__RequestIdNotFound();
        if (rolledDice.stake > i_core.getUserStaked(rolledDice.bettor, rolledDice.token)) revert DiceRoll__InsuffcientUserStake();
        if (rolledDice.stake > i_core.getTotalStakes(rolledDice.token)) revert DiceRoll__InsuffcientStakes();
        if (rolledDice.payout > i_core.getProviderPayout(rolledDice.provider, rolledDice.token)) revert DiceRoll__InsuffcientProviderPayouts();
        if (rolledDice.payout > i_core.getTotalPayout(rolledDice.token)) revert DiceRoll__InsuffcientPayouts();
        uint256 randomWord = randomWords[0] % 6;
        DiceFace result = DiceFace.Six;
        if (randomWord == 0) {
            result = DiceFace.One;
        } else if (randomWord == 1) {
            result = DiceFace.Two;
        } else if (randomWord == 2) {
            result = DiceFace.Three;
        } else if (randomWord == 3) {
            result = DiceFace.Four;
        } else if (randomWord == 4) {
            result = DiceFace.Five;
        }
        rolledDice.status = rolledDice.choice == result ? BetStatus.Win : BetStatus.Loss;
        rolledDice.randomWord = randomWord;
        emit DiceRollSettled(requestId, rolledDice.bettor, rolledDice.token, rolledDice.status, randomWord);
        if (rolledDice.choice == result) {
            i_core.handleStakes(rolledDice.bettor, rolledDice.token, rolledDice.stake, 0);
            i_core.handlePayout(rolledDice.provider, rolledDice.token, rolledDice.payout, 0);
            i_core.handleBalance(rolledDice.bettor, rolledDice.token, rolledDice.stake + rolledDice.payout, 1);
        } else {
            i_core.handleStakes(rolledDice.bettor, rolledDice.token, rolledDice.stake, 0);
            i_core.handlePayout(rolledDice.provider, rolledDice.token, rolledDice.payout, 0);
            i_core.handleHL(rolledDice.provider, rolledDice.token, rolledDice.stake + rolledDice.payout, 1);
        }
        if (!i_core.getBalancedStatus(rolledDice.token)) revert DiceRoll__ContractIsNotBalanced();
    }

    function suspendBet(uint256 requestId) external nonReentrant {
        RolledDice storage rolledDice = s_requestIdToDiceRoll[requestId];
        if (!rolledDice.rolled) revert DiceRoll__RequestIdNotFound();
        if (rolledDice.bettor != msg.sender) revert DiceRoll__NotBettor();
        if (rolledDice.status != BetStatus.Active) revert DiceRoll__OnlyActiveSuspend();
        if (!((block.timestamp - rolledDice.timesstamp) > s_tokenToBetTimelock[rolledDice.token])) revert DiceRoll__Timelock();
        if (rolledDice.stake > i_core.getUserStaked(rolledDice.bettor, rolledDice.token)) revert DiceRoll__InsuffcientUserStake();
        if (rolledDice.stake > i_core.getTotalStakes(rolledDice.token)) revert DiceRoll__InsuffcientStakes();
        if (rolledDice.payout > i_core.getProviderPayout(rolledDice.provider, rolledDice.token)) revert DiceRoll__InsuffcientProviderPayouts();
        if (rolledDice.payout > i_core.getTotalPayout(rolledDice.token)) revert DiceRoll__InsuffcientPayouts();
        rolledDice.status = BetStatus.Suspend;
        emit DiceRollSettled(requestId, rolledDice.bettor, rolledDice.token, rolledDice.status, 6);
        i_core.handleStakes(rolledDice.bettor, rolledDice.token, rolledDice.stake, 0);
        i_core.handlePayout(rolledDice.provider, rolledDice.token, rolledDice.payout, 0);
        i_core.handleBalance(rolledDice.bettor, rolledDice.token, rolledDice.stake, 1);
        i_core.handleHL(rolledDice.provider, rolledDice.token, rolledDice.payout, 1);
        if (!i_core.getBalancedStatus(rolledDice.token)) revert DiceRoll__ContractIsNotBalanced();
    }

    function calculatePayout(address token, uint256 stake) internal view returns (uint256) {
        uint256 payout = (stake * s_tokenToMultiplier[token]) - stake;
        return payout;
    }

    function calculateHouseCut(address token, uint256 payout) internal view returns (uint256) {
        uint256 housecut = (payout * s_tokenToHouseEdge[token]) / 10000;
        return housecut;
    }

    //Getter Functions
    function getDiceRollOwner() public view returns (address) {
        return s_diceRollOwner;
    }

    function getIsGameAllowed() public view returns (bool) {
        return gameAllowed;
    }

    function getDiceRollMultiplier(address token) public view returns (uint8) {
        return s_tokenToMultiplier[token];
    }

    function getHousecutEdge(address token) public view returns (uint256) {
        return s_tokenToHouseEdge[token];
    }

    function getStakeLimits(address token) public view returns (StakeLimits memory) {
        return s_tokenToStakeLimits[token];
    }

    function getBetTimelock(address token) public view returns (uint256) {
        return s_tokenToBetTimelock[token];
    }

    function getDiceRoll(uint256 requestId) public view returns (RolledDice memory) {
        return s_requestIdToDiceRoll[requestId];
    }

    function getChainLinkConfid() public view returns (ChainLinkConfig memory) {
        return s_chainLinkConfig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ITest1 {
    function getBaseProvider(address token) external view returns (address);

    function getRandomProvider(address token, uint256 randomWord) external returns (address);

    function getUserBalance(address account, address token) external view returns (uint256);

    function getTotalFunds(address token) external view returns (uint256);

    function getUserTips(address account, address token) external view returns (uint256);

    function getTotalUserTips(address token) external view returns (uint256);

    function getUserStaked(address account, address token) external view returns (uint256);

    function getTotalStakes(address token) external view returns (uint256);

    function getDepositerHLBalance(address depositer, address token) external view returns (uint256);

    function getTotalHL(address token) external view returns (uint256);

    function getProviderPayout(address account, address token) external view returns (uint256);

    function getTotalPayout(address token) external view returns (uint256);

    function getBalancedStatus(address token) external view returns (bool);

    function setCoreOwnership(address newOwner) external;

    function disableCoreOwnership(address owwner) external;

    function setTrustedForwarder(address trustedForwarder) external;

    function addTokens(address token) external;

    function disableToken(address token) external;

    function setBaseProvider(address account, address token) external;

    function handleBalance(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleUserTips(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleStakes(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleHL(address bettor, address token, uint256 amount, uint256 operator) external;

    function handlePayout(address bettor, address token, uint256 amount, uint256 operator) external;
}