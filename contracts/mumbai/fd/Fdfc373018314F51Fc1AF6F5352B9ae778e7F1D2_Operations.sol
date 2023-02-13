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
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./ICore.sol";

error Operations__OnlyOwnerMethod();
error Operations__OnlySignerMethod();
error Operations__Invalid();
error Operations__InsuffucentBalance();
error Operations__SettlementFailed();
error Operations__ContractIsNotBalanced();
error Operations__InvalidBetId();
error Operations__StakeMorethanbal();
error Operations__InsuffuceintHL();
error Operations__InsufficentStakes();
error Operations__InsufficentPayouts();

contract Operations is VRFConsumerBaseV2, ERC2771Recipient {
    /* Type Declarations */
    enum BetStatus {
        Active, //0
        Loss, //1
        Win, //2
        Suspended //3
    }

    struct BetSlip {
        bytes32 betkey;
        address bettor;
        address token;
        uint256 totalStake;
        uint256 totalPayout;
        address provider;
        bytes32 odds;
        bytes32 stake;
        bytes32 payout;
        bytes32 betValue;
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
    uint256 private s_betSlipId = 0;
    address private s_opsOwner;

    ICore private immutable i_core;
    uint256 private s_randomWord;

    mapping(bytes32 => bool) private s_placeBetKey;
    mapping(address => bool) private s_settleSigner;

    mapping(bytes32 => BetSlip) private s_keyToBetSlip;

    event TransferOpsOwnership(address indexed oldOwner, address indexed newOwner);

    event BetPlaced(
        bytes32 indexed betkey,
        address indexed bettor,
        address indexed token,
        uint256 totalStake,
        uint256 totalPayout,
        bytes32 odds,
        bytes32 stake,
        bytes32 payout,
        bytes32 betValue
    );

    event BetSettled(
        bytes32 indexed betkey,
        uint8 indexed betOrder,
        address indexed bettor,
        address token,
        BetStatus BetStatus,
        uint256 stake,
        uint256 payout,
        bytes32 odds,
        bytes32 betValue
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
        if (_msgSender() != s_opsOwner) {
            revert Operations__OnlyOwnerMethod();
        }
        _;
    }

    modifier onlySettleSigner() {
        if (!s_settleSigner[_msgSender()]) {
            revert Operations__OnlySignerMethod();
        }
        _;
    }

    modifier settlementReq(
        BetSlip memory betSlip,
        uint256 stake,
        uint256 payout
    ) {
        if (stake > i_core.getUserStaked(betSlip.bettor, betSlip.token)) {
            revert Operations__InsufficentStakes();
        }
        if (stake > i_core.getTotalStakes(betSlip.token)) {
            revert Operations__InsufficentStakes();
        }
        if (payout > i_core.getProviderPayout(betSlip.provider, betSlip.token)) {
            revert Operations__InsufficentPayouts();
        }
        if (payout > i_core.getTotalPayout(betSlip.token)) {
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

    function setOpsTrustedForwarder(address _trustedForwarder) external onlyOpsOwner {
        _setTrustedForwarder(_trustedForwarder);
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
        address token,
        uint256 totalStake,
        uint256 totalPayout,
        bytes32[5] calldata betDetails,
        bool callOracle
    ) public {
        if (s_placeBetKey[betDetails[4]] == true) {
            revert Operations__Invalid();
        }
        if (totalStake > i_core.getUserBalance(_msgSender(), token)) {
            revert Operations__StakeMorethanbal();
        }
        if (totalPayout > i_core.getTotalHL(token)) {
            revert Operations__InsuffuceintHL();
        }
        address provider;
        if (callOracle) {
            callOrcale();
            provider = i_core.getRandomProvider(token, s_randomWord);
            if (totalPayout > i_core.getDepositerHLBalance(provider, token)) {
                provider = i_core.getBaseProvider(token);
                require(
                    totalPayout <= i_core.getDepositerHLBalance(provider, token),
                    "Insuffcient Liquidity"
                );
            }
        } else {
            provider = i_core.getBaseProvider(token);
            require(
                totalPayout <= i_core.getDepositerHLBalance(provider, token),
                "Insuffcient House Liquidity"
            );
        }

        s_placeBetKey[betDetails[4]] = true;
        i_core.handleBalance(_msgSender(), token, totalStake, 0);
        i_core.handleHL(provider, token, totalPayout, 0);
        i_core.handleStakes(_msgSender(), token, totalStake, 1);
        i_core.handlePayout(provider, token, totalPayout, 1);
        if (!i_core.getBalancedStatus(token)) {
            revert Operations__ContractIsNotBalanced();
        }

        s_keyToBetSlip[betDetails[4]] = BetSlip(
            betDetails[4],
            _msgSender(),
            token,
            totalStake,
            totalPayout,
            provider,
            betDetails[0],
            betDetails[1],
            betDetails[2],
            betDetails[3]
        );
        emit BetPlaced(
            betDetails[4],
            _msgSender(),
            token,
            totalStake,
            totalPayout,
            betDetails[0],
            betDetails[1],
            betDetails[2],
            betDetails[3]
        );
    }

    //check if already settled
    function settleBet(
        bytes32 betkey,
        uint8 betOrder,
        uint256 settleStatus,
        uint256 stake,
        uint256 payout,
        bytes32[2] calldata betInfo
    ) public onlySettleSigner {
        BetSlip storage betSlip = s_keyToBetSlip[betkey];
        if (betkey != betSlip.betkey || betkey == 0) revert Operations__InvalidBetId();
        if (settleStatus == 1) {
            handleLoss(betSlip, betOrder, stake, payout, betInfo);
        } else if (settleStatus == 2) {
            handleWin(betSlip, betOrder, stake, payout, betInfo);
        } else if (settleStatus == 3) {
            handleSuspension(betSlip, betOrder, stake, payout, betInfo);
        } else {
            revert Operations__SettlementFailed();
        }
    }

    function handleLoss(
        BetSlip memory betSlip,
        uint8 betOrder,
        uint256 stake,
        uint256 payout,
        bytes32[2] calldata betInfo
    ) internal settlementReq(betSlip, stake, payout) {
        i_core.handleStakes(betSlip.bettor, betSlip.token, stake, 0);
        i_core.handleHL(betSlip.provider, betSlip.token, stake + payout, 1);
        i_core.handlePayout(betSlip.provider, betSlip.token, payout, 0);
        //    i_core.handleHL(bet.provider, bet.token, bet.payout, 1);
        if (!i_core.getBalancedStatus(betSlip.token)) {
            revert Operations__ContractIsNotBalanced();
        }

        emit BetSettled(
            betSlip.betkey,
            betOrder,
            betSlip.bettor,
            betSlip.token,
            BetStatus.Loss,
            stake,
            payout,
            betInfo[0],
            betInfo[1]
        );
    }

    function handleWin(
        BetSlip memory betSlip,
        uint8 betOrder,
        uint256 stake,
        uint256 payout,
        bytes32[2] calldata betInfo
    ) internal settlementReq(betSlip, stake, payout) {
        i_core.handleBalance(betSlip.bettor, betSlip.token, stake + payout, 1);
        i_core.handleStakes(betSlip.bettor, betSlip.token, stake, 0);
        i_core.handlePayout(betSlip.provider, betSlip.token, payout, 0);
        if (!i_core.getBalancedStatus(betSlip.token)) {
            revert Operations__ContractIsNotBalanced();
        }
        emit BetSettled(
            betSlip.betkey,
            betOrder,
            betSlip.bettor,
            betSlip.token,
            BetStatus.Win,
            stake,
            payout,
            betInfo[0],
            betInfo[1]
        );
    }

    function handleSuspension(
        BetSlip memory betSlip,
        uint8 betOrder,
        uint256 stake,
        uint256 payout,
        bytes32[2] calldata betInfo
    ) internal settlementReq(betSlip, stake, payout) {
        i_core.handleBalance(betSlip.bettor, betSlip.token, stake, 1);
        i_core.handleStakes(betSlip.bettor, betSlip.token, stake, 0);
        i_core.handleHL(betSlip.provider, betSlip.token, payout, 1);
        i_core.handlePayout(betSlip.provider, betSlip.token, payout, 0);
        if (!i_core.getBalancedStatus(betSlip.token)) {
            revert Operations__ContractIsNotBalanced();
        }
        emit BetSettled(
            betSlip.betkey,
            betOrder,
            betSlip.bettor,
            betSlip.token,
            BetStatus.Win,
            stake,
            payout,
            betInfo[0],
            betInfo[1]
        );
    }

    /*Gettor Functions */
    function getOpsOwner() public view returns (address) {
        return s_opsOwner;
    }

    function getSettleSigner(address setlleSigner) public view returns (bool) {
        return (s_settleSigner[setlleSigner]);
    }

    function getCurrentBetId() public view returns (uint256) {
        return s_betSlipId;
    }

    function getBet(bytes32 betkey) public view returns (BetSlip memory) {
        return s_keyToBetSlip[betkey];
    }
}