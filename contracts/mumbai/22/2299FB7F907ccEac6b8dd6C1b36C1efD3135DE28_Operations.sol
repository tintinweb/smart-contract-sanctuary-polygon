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

pragma solidity ^0.8.0;

interface ICore {
    function getBaseProvider(address token) external view returns (address);

    function getRandomProvider(address token, uint256 randomWord) external returns (address);

    function getUserBalance(address account, address token) external view returns (uint256);

    function getTotalFunds(address token) external view returns (uint256);

    function getUserStaked(address account, address token) external view returns (uint256);

    function getTotalStakes(address token) external view returns (uint256);

    function getDepositerHLBalance(address depositer, address token)
        external
        view
        returns (uint256);

    function getTotalHL(address token) external view returns (uint256);

    function getProviderPayout(address account, address token) external view returns (uint256);

    function getTotalPayout(address token) external view returns (uint256);

    function getBalancedStatus(address token) external view returns (bool);

    function transferCoreOwnership(address newOwner) external;

    function setTrustedForwarder(address trustedForwarder) external;

    function addTokens(address token) external;

    function disableToken(address token) external;

    function setBaseProvider(address account, address token) external;

    function handleBalance(
        address bettor,
        address token,
        uint256 amount,
        uint256 operator
    ) external;

    function handleStakes(
        address bettor,
        address token,
        uint256 amount,
        uint256 operator
    ) external;

    function handleHL(
        address bettor,
        address token,
        uint256 amount,
        uint256 operator
    ) external;

    function handlePayout(
        address bettor,
        address token,
        uint256 amount,
        uint256 operator
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./ICore.sol";

error Operations__OnlyOwnerMethod();
error Operations__OnlySignerMethod();
error Operations__InsuffucentBalance();
error Operations__SettlementFailed();
error Operations__ContractIsNotBalanced();
error Operations__InvalidBetId();
error Operations__StakeMorethanbal();
error Operations__InsuffuceintHL();
error Operations__InsufficentStakes();
error Operations__InsufficentPayouts();
error Operations__AlreadySettled();

contract Operations is VRFConsumerBaseV2 {
    /* Type Declarations */
    enum BetStatus {
        Active, //0
        Loss, //1
        Win, //2
        Suspended //3
    }

    struct Bet {
        uint256 betId;
        address bettor;
        address token;
        uint256 odds;
        uint256 stake;
        uint256 payout;
        bytes32 betValue;
        bytes32 eventId;
        BetStatus betStatus;
        address provider;
        bytes32 meta;
    }

    /* State Variables */

    /* Chainlink VRF Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /* Ops Contract Variables */
    uint256 private s_betId = 0;
    address private s_opsOwner;

    uint256 private constant ODDS_DECIMAL_ADJUSTER = 100;
    ICore private immutable i_core;
    uint256 private s_randomWord;

    mapping(address => bool) private s_betSigner;
    mapping(address => bool) private s_settleSigner;

    mapping(uint256 => Bet) private s_betIdToBet;

    event TransferOpsOwnership(address indexed oldOwner, address indexed newOwner);
    event BetInfo(
        uint256 indexed betId,
        address indexed bettor,
        address indexed token,
        uint256 odds,
        uint256 stake,
        uint256 payout,
        bytes32 betValue,
        bytes32 eventId,
        BetStatus betStatus,
        address provider,
        bytes32 meta
    );

    // mapping(uint256 => address) private betIdToProvider;

    constructor(
        address owner,
        address payable core,
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        s_opsOwner = owner;
        i_core = ICore(core); //Creating Instance of fundmanager
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    modifier onlyOpsOwner() {
        if (msg.sender != s_opsOwner) {
            revert Operations__OnlyOwnerMethod();
        }
        _;
    }

    modifier onlyBetSigner() {
        if (!s_betSigner[msg.sender]) {
            revert Operations__OnlySignerMethod();
        }
        _;
    }

    modifier onlySettleSigner() {
        if (!s_settleSigner[msg.sender]) {
            revert Operations__OnlySignerMethod();
        }
        _;
    }

    modifier settlementReq(Bet memory bet) {
        if (bet.stake > i_core.getUserStaked(bet.bettor, bet.token)) {
            revert Operations__InsufficentStakes();
        }
        if (bet.stake > i_core.getTotalStakes(bet.token)) {
            revert Operations__InsufficentStakes();
        }
        if (bet.payout > i_core.getProviderPayout(bet.provider, bet.token)) {
            revert Operations__InsufficentPayouts();
        }
        if (bet.payout > i_core.getTotalPayout(bet.token)) {
            revert Operations__InsufficentPayouts();
        }
        _;
    }

    /* State Changing Methods */
    function transferOpsOwnership(address _newOwner) public onlyOpsOwner {
        _transferOpsOwnership(_newOwner);
    }

    function _transferOpsOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Incorect address");
        address oldOwner = s_opsOwner;
        s_opsOwner = _newOwner;
        emit TransferOpsOwnership(oldOwner, _newOwner);
    }

    function transferCoreOnwershipInOps(address newOwner) public onlyOpsOwner {
        i_core.transferCoreOwnership(newOwner);
    }

    function setCoreTrustedForwarder(address trustedForwarder) public onlyOpsOwner {
        i_core.setTrustedForwarder(trustedForwarder);
    }

    function addTokensToCore(address token) public onlyOpsOwner {
        i_core.addTokens(token);
    }

    function disableCoreToken(address token) public onlyOpsOwner {
        i_core.disableToken(token);
    }

    function setBaseProviderInCore(address account, address token) public onlyOpsOwner {
        i_core.setBaseProvider(account, token);
    }

    function setBetSigner(address account, bool status) public onlyOpsOwner {
        s_betSigner[account] = status;
    }

    function setSettleSigner(address account, bool status) public onlyOpsOwner {
        s_settleSigner[account] = status;
    }

    function callOrcale() internal {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        s_randomWord = randomWords[0];
    }

    function placeBet(
        address bettor,
        address token,
        uint256 odds,
        uint256 stake,
        uint256 payout,
        bytes32 betValue,
        bytes32 eventId, //league-home-away-bettype //nba-dettoits-charloote-overundrof
        bool callOracle,
        bytes32 meta
    ) public onlyBetSigner returns (uint256) {
        // require(stake <= i_core.getUserBalance(bettor, token), "Stake Greater than balance");
        // require(stake <= i_core.getTotalFunds(token), "Insuffuceint Funds");
        // require(payout <= i_core.getTotalHL(token), "Insuffuceint House Liquidity");
        if (stake > i_core.getUserBalance(bettor, token)) {
            revert Operations__StakeMorethanbal();
        }
        if (payout > i_core.getTotalHL(token)) {
            revert Operations__InsuffuceintHL();
        }
        address provider;
        if (callOracle) {
            callOrcale();
            provider = i_core.getRandomProvider(token, s_randomWord);
            if (payout > i_core.getDepositerHLBalance(provider, token)) {
                provider = i_core.getBaseProvider(token);
                require(
                    payout <= i_core.getDepositerHLBalance(provider, token),
                    "Insuffcient Liquidity"
                );
            }
        } else {
            provider = i_core.getBaseProvider(token);
            require(
                payout <= i_core.getDepositerHLBalance(provider, token),
                "Insuffcient House Liquidity"
            );
        }
        s_betId++;
        i_core.handleBalance(bettor, token, stake, 0);
        i_core.handleHL(provider, token, payout, 0);
        i_core.handleStakes(bettor, token, stake, 1);
        i_core.handlePayout(provider, token, payout, 1);
        if (!i_core.getBalancedStatus(token)) {
            revert Operations__ContractIsNotBalanced();
        }
        s_betIdToBet[s_betId] = Bet(
            s_betId,
            bettor,
            token,
            odds,
            stake,
            payout,
            betValue, // Home ,(Over 177) , Under 171.5
            eventId, // 4-190338 ,1-190338
            BetStatus.Active,
            provider,
            meta
        );
        emit BetInfo(
            s_betId,
            bettor,
            token,
            odds,
            stake,
            payout,
            betValue,
            eventId,
            BetStatus.Active,
            provider,
            meta
        );
        return s_betId;
    }

    //check if already settled
    function settleBet(uint256 betId, uint256 status) public onlySettleSigner {
        Bet storage bet = s_betIdToBet[betId];
        if (bet.betStatus != BetStatus.Active) revert Operations__AlreadySettled();
        if (betId != bet.betId || betId == 0) revert Operations__InvalidBetId();
        if (status == 1) {
            bet.betStatus = BetStatus.Loss;
            handleLoss(bet);
        } else if (status == 2) {
            bet.betStatus = BetStatus.Win;
            handleWin(bet);
        } else if (status == 3) {
            bet.betStatus = BetStatus.Suspended;
            handleSuspension(bet);
        } else {
            revert Operations__SettlementFailed();
        }
    }

    function handleLoss(Bet memory bet) internal settlementReq(bet) {
        i_core.handleStakes(bet.bettor, bet.token, bet.stake, 0);
        i_core.handleHL(bet.provider, bet.token, bet.stake + bet.payout, 1);
        i_core.handlePayout(bet.provider, bet.token, bet.payout, 0);
        //    i_core.handleHL(bet.provider, bet.token, bet.payout, 1);
        if (!i_core.getBalancedStatus(bet.token)) {
            revert Operations__ContractIsNotBalanced();
        }
        emit BetInfo(
            bet.betId,
            bet.bettor,
            bet.token,
            bet.odds,
            bet.stake,
            bet.payout,
            bet.betValue,
            bet.eventId,
            bet.betStatus,
            bet.provider,
            bet.meta
        );
    }

    function handleWin(Bet memory bet) internal settlementReq(bet) {
        i_core.handleBalance(bet.bettor, bet.token, bet.stake + bet.payout, 1);
        i_core.handleStakes(bet.bettor, bet.token, bet.stake, 0);
        i_core.handlePayout(bet.provider, bet.token, bet.payout, 0);
        //i_core.handleBalance(bet.bettor, bet.token, bet.stake, 1);
        if (!i_core.getBalancedStatus(bet.token)) {
            revert Operations__ContractIsNotBalanced();
        }
        emit BetInfo(
            bet.betId,
            bet.bettor,
            bet.token,
            bet.odds,
            bet.stake,
            bet.payout,
            bet.betValue,
            bet.eventId,
            bet.betStatus,
            bet.provider,
            bet.meta
        );
    }

    function handleSuspension(Bet memory bet) internal settlementReq(bet) {
        i_core.handleBalance(bet.bettor, bet.token, bet.stake, 1);
        i_core.handleStakes(bet.bettor, bet.token, bet.stake, 0);
        i_core.handleHL(bet.provider, bet.token, bet.payout, 1);
        i_core.handlePayout(bet.provider, bet.token, bet.payout, 0);
        if (!i_core.getBalancedStatus(bet.token)) {
            revert Operations__ContractIsNotBalanced();
        }
        emit BetInfo(
            bet.betId,
            bet.bettor,
            bet.token,
            bet.odds,
            bet.stake,
            bet.payout,
            bet.betValue,
            bet.eventId,
            bet.betStatus,
            bet.provider,
            bet.meta
        );
    }

    /*Gettor Functions */
    function getOpsOwner() public view returns (address) {
        return s_opsOwner;
    }

    function getBetSigner(address betSigner) public view returns (bool) {
        return (s_betSigner[betSigner]);
    }

    function getSettleSigner(address setlleSigner) public view returns (bool) {
        return (s_settleSigner[setlleSigner]);
    }

    function getAdjustedOdds() public pure returns (uint256) {
        return ODDS_DECIMAL_ADJUSTER;
    }

    function getCurrentBetId() public view returns (uint256) {
        return s_betId;
    }

    function getBet(uint256 betId) public view returns (Bet memory) {
        return s_betIdToBet[betId];
    }
}
//