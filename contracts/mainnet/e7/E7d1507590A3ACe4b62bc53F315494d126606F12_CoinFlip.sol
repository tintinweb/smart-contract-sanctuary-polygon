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
/// @author X
contract CoinFlip is VRFConsumerBaseV2, ReentrancyGuard {
    /// @notice Enum to identify coin faces.
    enum CoinFace {
        Heads,
        Tails
    }

    /// @notice Enum to track coin flip status
    enum BetStatus {
        Active,
        Loss,
        Win,
        Suspend
    }

    /// @notice Chain Link configuration information struct
    /// @param subscriptionId subscription id from subscription manager dashboard
    /// @param gasLane  maximum gas price you are willing to pay for a request in wei
    /// @param callbackGasLimit  gas  for the callback request to your contract's fulfillRandomWords
    /// @param requestConfirmations confirmations the Chainlink node should wait before responding
    /// @param numWords random values to request
    struct ChainLinkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    /// @notice Full coin flip bet information struct.
    /// @param userAddress The address of the bettor.
    /// @param token The token used to place bet.
    /// @param provider The account that provides HL.
    /// @param odds The odds for outcomes
    /// @param stake The amount in wei staked by bettor
    /// @param payout The amount taken from HL after housecut
    /// @param randomWord The RNG by chainlink vrf service
    /// @param timesstamp The time stamp of coin flipped
    /// @param choice The The chosen coin face
    /// @param status The current bet status
    /// @param flipped bool to identify coin flippped
    /// @dev Used to package bet information for the front-end.
    struct FlippedCoin {
        address userAddress;
        address token;
        address provider;
        uint8 odds;
        uint256 stake;
        uint256 payout;
        uint256 randomWord;
        uint256 timestamp;
        CoinFace choice;
        BetStatus status;
        bool flipped;
    }

    /// @notice The range of amount that can be staked on bet.
    /// @param  minStake The minimum stake allowed on Coin Flip
    /// @param maxStake The maximum stake allowed on Coin Flip
    struct StakeLimits {
        uint256 minStake;
        uint256 maxStake;
    }

    //mapping

    /// @notice Maps tokens addresses to stake limits
    mapping(address => StakeLimits) private s_tokenToStakeLimits;

    /// @notice Maps tokens addresses to  house edge
    mapping(address => uint256) private s_tokenToHouseEdge;

    /// @notice Maps tokens addresses to odds
    mapping(address => uint8) private s_tokenToOdds;

    /// @notice Maps tokens addresses to time lock for bets
    mapping(address => uint256) private s_tokenToBetTimelock;

    /// @notice Maps chainlink requestId to FlippedCoin structure
    mapping(uint256 => FlippedCoin) private s_requestIdToCoinFlip;

    // Chainlink VRF Variables
    ChainLinkConfig private s_chainLinkConfig;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    /// @notice Owner of Coin Flip Game
    address private s_coinFlipOwner;

    /// @notice Interface of Core contract
    ITest1 private immutable i_core;

    /// @notice State to manage bets allowed
    bool private gameAllowed = true;

    /// @notice Emitted when coin is flipped
    /// @param requestId Used to match randomness requests with their fullfillment order
    /// @param userAddress address of the bettor of the bettor
    /// @param token address of the token
    /// @param odds The odds for outcomes
    /// @param stake The amount in wei staked by bettor
    /// @param payout The amount taken from HL after housecut
    /// @param choice The The chosen coin face
    /// @param status The current bet status
    /// @dev The event is indexed for front end
    event CoinFlipped(uint256 indexed requestId, address indexed userAddress, address indexed token, uint256 odds, uint256 stake, uint256 payout, CoinFace choice, BetStatus status);

    /// @notice Emitted when coin flip is settled
    /// @param requestId Used to match randomness requests with their fullfillment order
    /// @param userAddress address of the bettor of the bettor
    /// @param token address of the token
    /// @param status The current bet status
    /// @param randomWord RNG from chainlink vrf service
    /// @dev The events is indexed for front end updates
    event CoinFlipSettled(uint256 indexed requestId, address indexed userAddress, address indexed token, BetStatus status, uint256 randomWord);

    /// @notice Reverting error when method is not called by the owner
    error CoinFlip__OnlyOwnerMethod();

    /// @notice Reverting error when flip coin is called and betallowed is false
    error CoinFlip__GameDisabled();

    /// @notice Reverting error when address is invalid
    error CoinFlip__IncorrectAddress();

    /// @notice Reverting error when stake  is less than limit
    error CoinFlip__StakeToSmall();

    /// @notice Reverting error when stake  is more than limit
    error CoinFlip__StakeToBig();

    /// @notice Reverting error when stake is more than user balance
    error CoinFlip__StakeMoreThanBalance();

    /// @notice Reverting error when stake  is more than user staked
    error CoinFlip__InsuffcientUserStake();

    /// @notice Reverting error when stake  is more than totalStakes
    error CoinFlip__InsuffcientStakes();

    /// @notice Reverting error when payout is more than HL
    error CoinFlip__InsuffcientHL();

    /// @notice Reverting error when payout is more
    error CoinFlip__InsuffcientProviderPayouts();

    /// @notice Reverting error when payout is more
    error CoinFlip__InsuffcientPayouts();

    /// @notice Reverting error when after an state updation contract funds is not balanced
    error CoinFlip__ContractIsNotBalanced();

    /// @notice Reverting error when chain link requestId is not found
    error CoinFlip__RequestIdNotFound();

    /// @notice Reverting error when method is not called by bettor
    error CoinFlip__NotBettor();

    /// @notice Reverting error when suspending non active bet
    error CoinFlip__OnlyActiveSuspend();

    /// @notice Reverting error when enough time has not passed
    error CoinFlip__Timelock();

    /// @notice Initialize contract's state variables and VRF Consumer.
    /// @param vrfCoordinatorV2 Address of the Chainlink VRF Coordinator.
    /// @param owner Owner of the contract.
    /// @param core Address of the Core interface.
    constructor(address vrfCoordinatorV2, address owner, address payable core) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        s_coinFlipOwner = owner;
        i_core = ITest1(core);
    }

    /// @notice Modifier to restrict access to the owner of the CoinFlip contract.
    /// @dev Reverts the transaction if the message sender is not the owner.
    modifier onlyCoinFlipOwner() {
        if (msg.sender != s_coinFlipOwner) {
            revert CoinFlip__OnlyOwnerMethod();
        }
        _;
    }

    /// @notice Modifier to check if the game is allowed.
    /// @dev Reverts the transaction if the game is disabled.
    modifier isGameAllowed() {
        if (!gameAllowed) {
            revert CoinFlip__GameDisabled();
        }
        _;
    }

    /// @notice Transfers the ownership of the CoinFlip contract to a new address.
    /// @param _newOwner The address of the new owner.
    /// @dev Only the current owner of the CoinFlip contract can call this function.
    function transferCoinFlipOwnership(address _newOwner) public onlyCoinFlipOwner {
        _transferCoinFlipOwnership(_newOwner);
    }

    /// @notice Performs the actual transfer of ownership.
    /// @param _newOwner The address of the new owner.
    /// @dev Internal function to transfer ownership of the CoinFlip contract.
    function _transferCoinFlipOwnership(address _newOwner) internal {
        if (_newOwner == address(0)) {
            revert CoinFlip__IncorrectAddress();
        }
        s_coinFlipOwner = _newOwner;
    }

    /// @notice Sets the ownership of the Core contract to a new address.
    /// @param newOwner The address of the new owner of the Core contract.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function setCoreOwnershipInCoinFlip(address newOwner) public onlyCoinFlipOwner {
        i_core.setCoreOwnership(newOwner);
    }

    /// @notice Disables ownership in the Core contract for a specific address.
    /// @param owner The address for which ownership should be disabled in the Core contract.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function disableCoreOwnershipInCoinFlip(address owner) public onlyCoinFlipOwner {
        i_core.disableCoreOwnership(owner);
    }

    /// @notice Modifies the game allowed status.
    /// @param status The new game allowed status.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function modifyGameAllowed(bool status) public onlyCoinFlipOwner {
        gameAllowed = status;
    }

    /// @notice Sets the odds for a specific token.
    /// @param token The address of the token.
    /// @param odds The odds value to set.
    function setOdds(address token, uint8 odds) public onlyCoinFlipOwner {
        s_tokenToOdds[token] = odds;
    }

    /// @notice Sets the house edge for a specific token.
    /// @param token The address of the token.
    /// @param houseEdge The new house edge value.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function setHouseEdge(address token, uint256 houseEdge) public onlyCoinFlipOwner {
        s_tokenToHouseEdge[token] = houseEdge;
    }

    /// @notice Sets the stake limits for a specific token.
    /// @param token The address of the token.
    /// @param minStake The new minimum stake value.
    /// @param maxStake The new maximum stake value.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function setStakeLimits(address token, uint256 minStake, uint256 maxStake) public onlyCoinFlipOwner {
        s_tokenToStakeLimits[token] = StakeLimits(minStake, maxStake);
    }

    /// @notice Sets the bet timelock duration for a specific token.
    /// @param token The address of the token.
    /// @param duration The new bet timelock duration value.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function setBetTimelock(address token, uint256 duration) public onlyCoinFlipOwner {
        s_tokenToBetTimelock[token] = duration;
    }

    /// @notice Sets the Chainlink configuration parameters.
    /// @param subscriptionId The new subscription ID.
    /// @param gasLane The new gas lane value.
    /// @param callbackGasLimit The new callback gas limit value.
    /// @param requestConfirmations The new request confirmations value.
    /// @param numWords The new number of words value.
    /// @dev Only the owner of the CoinFlip contract can call this function.
    function setChainLinkConfig(uint64 subscriptionId, bytes32 gasLane, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) public onlyCoinFlipOwner {
        s_chainLinkConfig = ChainLinkConfig(subscriptionId, gasLane, callbackGasLimit, requestConfirmations, numWords);
    }

    /// @notice Flips a coin by placing a bet.
    /// @param token The address of the token used for the bet.
    /// @param stake The amount of the bet in wei.
    /// @param choice The chosen coin face for the bet.
    /// @dev This function is non-reentrant and can only be called when the game is allowed.
    ///      It verifies the bet parameters and transfers the necessary funds.
    ///      It also requests randomness from Chainlink VRF and stores the bet information.
    ///      Reverts if the stake is below the minimum stake limit.
    ///      Reverts if the stake is above the maximum stake limit.
    ///      Reverts if the stake is more than the combined tips and balance of the user.
    ///      Reverts if the payout exceeds the available HL balance.
    ///      Reverts if the payout exceeds the HL balance of the provider.
    ///      Emits the CoinFlipped event with the bet information.
    function flipCoin(address token, uint256 stake, CoinFace choice) external nonReentrant isGameAllowed {
        address provider = i_core.getBaseProvider(token);
        uint256 tips = i_core.getUserTips(msg.sender, token);
        uint256 bal = i_core.getUserBalance(msg.sender, token);
        uint256 tipsToSubtract;
        if (stake < s_tokenToStakeLimits[token].minStake) revert CoinFlip__StakeToSmall();
        if (stake > s_tokenToStakeLimits[token].maxStake) revert CoinFlip__StakeToBig();
        if (stake > tips + bal) revert CoinFlip__StakeMoreThanBalance();
        uint256 payout = calculatePayout(token, stake);
        uint256 housecut = calculateHouseCut(token, payout);
        payout = payout - housecut;
        if (payout > i_core.getTotalHL(token)) revert CoinFlip__InsuffcientHL();
        if (payout > i_core.getDepositerHLBalance(provider, token)) revert CoinFlip__InsuffcientHL();
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            s_chainLinkConfig.gasLane,
            s_chainLinkConfig.subscriptionId,
            s_chainLinkConfig.requestConfirmations,
            s_chainLinkConfig.callbackGasLimit,
            s_chainLinkConfig.numWords
        );
        s_requestIdToCoinFlip[requestId] = FlippedCoin(msg.sender, token, provider, s_tokenToOdds[token], stake, payout, 2, block.timestamp, choice, BetStatus.Active, true);
        emit CoinFlipped(requestId, msg.sender, token, s_tokenToOdds[token], stake, payout, choice, BetStatus.Active);
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
        if (!i_core.getBalancedStatus(token)) revert CoinFlip__ContractIsNotBalanced();
    }

    /// @notice Handles the fulfillment of random words obtained from the Chainlink VRF service.
    /// @param requestId The ID of the Chainlink VRF request.
    /// @param randomWords The array of random words obtained from the Chainlink VRF service.
    /// @dev This function is called internally to settle a flipped coin bet based on the received random words.
    ///      Reverts if the requestId is not found in the s_requestIdToCoinFlip mapping.
    ///      Reverts if the stake exceeds the user's staked amount.
    ///      Reverts if the stake exceeds the total stakes for the token.
    ///      Reverts if the payout exceeds the provider's payout amount.
    ///      Reverts if the payout exceeds the total payout for the token.
    ///      Determines the result of the coin flip based on the random word.
    ///      Updates the bet status and random word in the FlippedCoin struct.
    ///      Emits the CoinFlipSettled event with the updated bet information.
    ///      Handles the transfer of stakes, payouts, and balances based on the bet outcome.
    ///      Checks if the contract is balanced after the transfers.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        FlippedCoin storage flippedCoin = s_requestIdToCoinFlip[requestId];
        if (!flippedCoin.flipped) revert CoinFlip__RequestIdNotFound();
        if (flippedCoin.stake > i_core.getUserStaked(flippedCoin.userAddress, flippedCoin.token)) revert CoinFlip__InsuffcientUserStake();
        if (flippedCoin.stake > i_core.getTotalStakes(flippedCoin.token)) revert CoinFlip__InsuffcientStakes();
        if (flippedCoin.payout > i_core.getProviderPayout(flippedCoin.provider, flippedCoin.token)) revert CoinFlip__InsuffcientProviderPayouts();
        if (flippedCoin.payout > i_core.getTotalPayout(flippedCoin.token)) revert CoinFlip__InsuffcientPayouts();
        CoinFace result = CoinFace.Tails;
        if (randomWords[0] % 2 == 0) {
            result = CoinFace.Heads;
        }
        flippedCoin.status = flippedCoin.choice == result ? BetStatus.Win : BetStatus.Loss;
        flippedCoin.randomWord = randomWords[0] % 2;
        emit CoinFlipSettled(requestId, flippedCoin.userAddress, flippedCoin.token, flippedCoin.status, randomWords[0] % 2);
        if (flippedCoin.choice == result) {
            i_core.handleStakes(flippedCoin.userAddress, flippedCoin.token, flippedCoin.stake, 0);
            i_core.handlePayout(flippedCoin.provider, flippedCoin.token, flippedCoin.payout, 0);
            i_core.handleBalance(flippedCoin.userAddress, flippedCoin.token, flippedCoin.stake + flippedCoin.payout, 1);
        } else {
            i_core.handleStakes(flippedCoin.userAddress, flippedCoin.token, flippedCoin.stake, 0);
            i_core.handlePayout(flippedCoin.provider, flippedCoin.token, flippedCoin.payout, 0);
            i_core.handleHL(flippedCoin.provider, flippedCoin.token, flippedCoin.stake + flippedCoin.payout, 1);
        }
        if (!i_core.getBalancedStatus(flippedCoin.token)) revert CoinFlip__ContractIsNotBalanced();
    }

    /// @notice Suspends an active bet.
    /// @param requestId The ID of the Chainlink VRF request associated with the bet.
    /// @dev This function allows the bettor to suspend an active bet before the result is determined.
    ///      Reverts if the `flippedCoin.fliiped` is false, indicating an invalid `requestId`.
    ///      Reverts if the sender is not the bettor of the bet.
    ///      Reverts if the bet status is not `Active`.
    ///      Reverts if the time since the coin flip is not greater than the bet timelock duration.
    ///      Reverts if the stake exceeds the user's staked amount for the token.
    ///      Reverts if the stake exceeds the total stakes for the token.
    ///      Reverts if the payout exceeds the provider's payout amount for the token.
    ///      Reverts if the payout exceeds the total payout for the token.
    ///      Sets the bet status to `Suspend`.
    ///      Emits the `CoinFlipSettled` event with the updated bet status.
    ///      Handles the transfer of stakes, payouts, and balances based on the bet suspension.
    ///      Checks if the contract is balanced after the transfers.
    function suspendBet(uint256 requestId) external nonReentrant {
        FlippedCoin storage flippedCoin = s_requestIdToCoinFlip[requestId];
        if (!flippedCoin.flipped) revert CoinFlip__RequestIdNotFound();
        if (flippedCoin.userAddress != msg.sender) revert CoinFlip__NotBettor();
        if (flippedCoin.status != BetStatus.Active) revert CoinFlip__OnlyActiveSuspend();
        if (!((block.timestamp - flippedCoin.timestamp) > s_tokenToBetTimelock[flippedCoin.token])) revert CoinFlip__Timelock();
        if (flippedCoin.stake > i_core.getUserStaked(flippedCoin.userAddress, flippedCoin.token)) revert CoinFlip__InsuffcientUserStake();
        if (flippedCoin.stake > i_core.getTotalStakes(flippedCoin.token)) revert CoinFlip__InsuffcientStakes();
        if (flippedCoin.payout > i_core.getProviderPayout(flippedCoin.provider, flippedCoin.token)) revert CoinFlip__InsuffcientProviderPayouts();
        if (flippedCoin.payout > i_core.getTotalPayout(flippedCoin.token)) revert CoinFlip__InsuffcientPayouts();
        flippedCoin.status = BetStatus.Suspend;
        emit CoinFlipSettled(requestId, flippedCoin.userAddress, flippedCoin.token, flippedCoin.status, 2);
        i_core.handleStakes(flippedCoin.userAddress, flippedCoin.token, flippedCoin.stake, 0);
        i_core.handlePayout(flippedCoin.provider, flippedCoin.token, flippedCoin.payout, 0);
        i_core.handleBalance(flippedCoin.userAddress, flippedCoin.token, flippedCoin.stake, 1);
        i_core.handleHL(flippedCoin.provider, flippedCoin.token, flippedCoin.payout, 1);
        if (!i_core.getBalancedStatus(flippedCoin.token)) revert CoinFlip__ContractIsNotBalanced();
    }

    /// @notice Calculates the payout amount for a given token and stake.
    /// @param token The address of the token.
    /// @param stake The stake amount in wei.
    /// @return payout The calculated payout amount.
    /// @dev This function multiplies the stake by the token's odds and subtracts the original stake.
    ///      Returns the calculated payout amount.
    function calculatePayout(address token, uint256 stake) internal view returns (uint256) {
        uint256 payout = (stake * s_tokenToOdds[token]) - stake;
        return payout;
    }

    /// @notice Calculates the house cut (commission) for a given token and payout amount.
    /// @param token The address of the token.
    /// @param payout The payout amount in wei.
    /// @return housecut The calculated house cut amount.
    /// @dev This function multiplies the payout by the token's house edge (commission rate) and divides it by 10,000.
    ///      Returns the calculated house cut amount.
    function calculateHouseCut(address token, uint256 payout) internal view returns (uint256) {
        uint256 housecut = (payout * s_tokenToHouseEdge[token]) / 10000;
        return housecut;
    }

    /// @notice Retrieves the address of the Coin Flip owner.
    /// @return owner The address of the Coin Flip owner.
    function getCoinFlipOwner() public view returns (address) {
        return s_coinFlipOwner;
    }

    /// @notice Retrieves the current status of the game allowance.
    /// @return allowed The boolean value indicating whether the game is allowed or not.
    function getIsGameAllowed() public view returns (bool) {
        return gameAllowed;
    }

    function getCoinFlipOdds(address token) public view returns (uint8) {
        return s_tokenToOdds[token];
    }

    /// @notice Retrieves the house edge (commission rate) for a given token.
    /// @param token The address of the token.
    /// @return houseEdge The house edge (commission rate) for the token.
    function getHousecutEdge(address token) public view returns (uint256) {
        return s_tokenToHouseEdge[token];
    }

    /// @notice Retrieves the stake limits (minimum and maximum) for a given token.
    /// @param token The address of the token.
    /// @return limits The StakeLimits struct containing the minimum and maximum stake limits for the token.
    function getStakeLimits(address token) public view returns (StakeLimits memory) {
        return s_tokenToStakeLimits[token];
    }

    /// @notice Retrieves the bet timelock duration for a given token.
    /// @param token The address of the token.
    /// @return timelock The duration of the bet timelock for the token.
    function getBetTimelock(address token) public view returns (uint256) {
        return s_tokenToBetTimelock[token];
    }

    /// @notice Retrieves the FlippedCoin struct associated with a given requestId.
    /// @param requestId The ID of the request.
    /// @return coinFlip The FlippedCoin struct associated with the requestId.
    function getCoinFlip(uint256 requestId) public view returns (FlippedCoin memory) {
        return s_requestIdToCoinFlip[requestId];
    }

    /// @notice Retrieves the ChainLinkConfig struct containing Chainlink configuration parameters.
    /// @return config The ChainLinkConfig struct containing the configuration parameters.
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