// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/v0.8/vrf/VRFConsumerBaseV2.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IAccessController} from "../interfaces/IAccessController.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {IClooverRaffle} from "../interfaces/IClooverRaffle.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";

import {RandomProviderTypes} from "../libraries/Types.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title RandomProvider
/// @author Cloover
/// @notice Contract that manage the link with the ChainLink VRF
contract RandomProvider is VRFConsumerBaseV2, IRandomProvider {
    //----------------------------------------
    // Storage
    //----------------------------------------

    VRFCoordinatorV2Interface public COORDINATOR;

    address private _implementationManager;

    RandomProviderTypes.ChainlinkVRFData private _chainlinkVRFData;

    mapping(uint256 => address) private _requestIdToCaller;

    //----------------------------------------
    // Initialization
    //----------------------------------------

    constructor(address implementationManager_, RandomProviderTypes.ChainlinkVRFData memory data)
        VRFConsumerBaseV2(data.vrfCoordinator)
    {
        _implementationManager = implementationManager_;
        COORDINATOR = VRFCoordinatorV2Interface(data.vrfCoordinator);
        _chainlinkVRFData = data;
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IRandomProvider
    function requestRandomNumbers(uint32 numWords) external override returns (uint256 requestId) {
        IClooverRaffleFactory raffleFactory = IClooverRaffleFactory(
            IImplementationManager(_implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.ClooverRaffleFactory
            )
        );
        if (!raffleFactory.isRegistered(msg.sender)) revert Errors.NOT_REGISTERED_RAFFLE();
        requestId = COORDINATOR.requestRandomWords(
            _chainlinkVRFData.keyHash,
            _chainlinkVRFData.subscriptionId,
            _chainlinkVRFData.requestConfirmations,
            _chainlinkVRFData.callbackGasLimit,
            numWords
        );
        _requestIdToCaller[requestId] = msg.sender;
    }

    /// @inheritdoc IRandomProvider
    function clooverRaffleFactory() external view override returns (address) {
        return IImplementationManager(_implementationManager).getImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory
        );
    }

    /// @inheritdoc IRandomProvider
    function implementationManager() external view override returns (address) {
        return _implementationManager;
    }

    /// @inheritdoc IRandomProvider
    function requestorAddressFromRequestId(uint256 requestId) external view override returns (address) {
        return _requestIdToCaller[requestId];
    }

    /// @inheritdoc IRandomProvider
    function chainlinkVRFData() external view override returns (RandomProviderTypes.ChainlinkVRFData memory) {
        return _chainlinkVRFData;
    }

    //----------------------------------------
    // Internal functions
    //----------------------------------------

    /// @notice internal function call by the ChainLink VRFConsumerBaseV2 fallback
    /// @dev only callable by the vrfCoordinator (cf.VRFConsumerBaseV2 and ChainLinkVRFv2 docs)
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address requestorAddress = _requestIdToCaller[requestId];
        IClooverRaffle(requestorAddress).draw(randomWords);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IImplementationManager {
    /// @notice Updates the address of the contract that implements `interfaceName`
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /// @notice Return the address of the contract that implements the given `interfaceName`
    function getImplementationAddress(bytes32 interfaceName) external view returns (address implementationAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessController is IAccessControl {
    function MAINTAINER_ROLE() external view returns (bytes32);
    function MANAGER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {RandomProviderTypes} from "../libraries/Types.sol";

interface IRandomProvider {
    /// @notice Request a random numbers using ChainLinkVRFv2
    function requestRandomNumbers(uint32 numWords) external returns (uint256 requestId);

    /// @notice Return the raffle factory contract addres
    function clooverRaffleFactory() external view returns (address);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);

    /// @notice Return the address of the contract that requested the random number from the requestId
    function requestorAddressFromRequestId(uint256 requestId) external view returns (address);

    /// @notice Return the ChainlinkVRFData struct
    function chainlinkVRFData() external view returns (RandomProviderTypes.ChainlinkVRFData memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "../libraries/Types.sol";

interface IClooverRaffleGetters {
    /// @notice Return the total amount of tickets sold
    function currentTicketSupply() external view returns (uint16);

    /// @notice Return the max amount of tickets that can be sold
    function maxTicketSupply() external view returns (uint16);

    /// @notice Return the max amount of tickets that can be sold per participant
    /// @dev 0 means no limit
    function maxTicketPerWallet() external view returns (uint16);

    /// @notice Return the address of the wallet that initiated the raffle
    function creator() external view returns (address);

    /// @notice Return the address of the token used to buy tickets
    /// @dev If the raffle is in Eth mode, this value will be address(0)
    function purchaseCurrency() external view returns (address);

    /// @notice Return if the raffle accept only ETH
    function isEthRaffle() external view returns (bool);

    /// @notice Return the price of one ticket
    function ticketPrice() external view returns (uint256);

    /// @notice Return the end time where ticket sales closing
    function endTicketSales() external view returns (uint64);

    /// @notice Return the winning ticket number
    function winningTicketNumber() external view returns (uint16);

    /// @notice get the winner address
    function winnerAddress() external view returns (address);

    /// @notice Return info regarding the nft to win
    function nftInfo() external view returns (address nftContractAddress, uint256 nftId);

    /// @notice Return the current status of the raffle
    function raffleStatus() external view returns (ClooverRaffleTypes.Status);

    /// @notice Return all tickets number own by the address
    /// @dev This function should not be call by any contract as it can be very expensive in term of gas usage due to the nested loop
    /// should be use only by front end to display the tickets number own by an address
    function getParticipantTicketsNumber(address user) external view returns (uint16[] memory);

    /// @notice Return the address that own a specific ticket number
    function ownerOf(uint16 id) external view returns (address);

    /// @notice Return the randomProvider contract address
    function randomProvider() external view returns (address);

    /// @notice Return the amount of REFUNDABLE paid by the creator
    function insurancePaid() external view returns (uint256);

    /// @notice Return the amount of ticket that is covered by the REFUNDABLE
    /// @dev If the raffle is not in REFUNDABLE mode, this value will be 0
    function minTicketThreshold() external view returns (uint16);

    /// @notice Return the royalties rate to apply on ticket sales amount to pay to the nft collection creator
    function royaltiesRate() external view returns (uint16);

    /// @notice Return the version of the contract
    function version() external pure returns (string memory);
}

interface IClooverRaffle is IClooverRaffleGetters {
    /// @notice Function to initialize contract
    function initialize(ClooverRaffleTypes.InitializeRaffleParams memory params) external payable;

    /// @notice Allows users to purchase tickets with ERC20 tokens
    function purchaseTickets(uint16 nbOfTickets) external;

    /// @notice Allows users to purchase tickets with ERC20Permit tokens
    function purchaseTicketsWithPermit(uint16 nbOfTickets, ClooverRaffleTypes.PermitDataParams calldata permitData)
        external;

    /// @notice Allows users to purchase tickets with ETH
    function purchaseTicketsInEth(uint16 nbOfTickets) external payable;

    /// @notice Request a random numbers to the RandomProvider contract
    function draw() external;

    /// @notice Select the winning ticket number using the random number from Chainlink's VRFConsumerBaseV2
    /// @dev must be only called by the RandomProvider contract
    /// function must not revert to avoid multi drawn to revert and block contract in case of wrong value received
    function draw(uint256[] memory randomNumbers) external;

    /// @notice Allows the creator to exerce the REFUNDABLE he paid in ERC20 token for and claim back his nft
    function claimCreatorRefund() external;

    /// @notice Allows the creator to exerce the REFUNDABLE he paid in Eth for and claim back his nft
    function claimCreatorRefundInEth() external;

    /// @notice Allows the creator to claim the amount link to the ticket sales in ERC20 token
    function claimTicketSales() external;

    /// @notice Allows the creator to claim the amount link to the ticket sales in Eth
    function claimTicketSalesInEth() external;

    /// @notice Allows the winner to claim his price
    function claimPrize() external;

    /// @notice Allow tickets owner to claim refund if raffle is in REFUNDABLE mode in ERC20 token
    function claimParticipantRefund() external;

    /// @notice Allow tickets owner to claim refund if raffle is in REFUNDABLE mode in Eth
    function claimParticipantRefundInEth() external;

    /// @notice Allow the creator to cancel the raffle if no ticket has been sold
    function cancel() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "../libraries/Types.sol";

interface IClooverRaffleFactoryGetters {
    /// @notice Return the implementation manager contract
    function implementationManager() external view returns (address);

    /// @notice Return the fees rate to apply on ticket sales amount
    function protocolFeeRate() external view returns (uint256);

    /// @notice Return the rate that creator will have to pay on the min sales defined
    function insuranceRate() external view returns (uint256);

    /// @notice Return the max ticket supply allowed in a raffle
    function maxTicketSupplyAllowed() external view returns (uint256);

    /// @notice Return the min duration for the ticket sales
    function minTicketSalesDuration() external view returns (uint256);

    /// @notice Return the max duration for the ticket sales
    function maxTicketSalesDuration() external view returns (uint256);

    /// @notice Return the limit of duration for the ticket sales
    function ticketSalesDurationLimits() external view returns (uint256 minDuration, uint256 maxDuration);

    /// @notice Return Ture if raffle is registered
    function isRegistered(address raffle) external view returns (bool);

    /// @notice Return all raffle address that are currently included in the whitelist
    function getRegisteredRaffle() external view returns (address[] memory);

    /// @notice Return the version of the contract
    function version() external pure returns (string memory);
}

interface IClooverRaffleFactorySetters {
    /// @notice Set the protocol fees rate to apply on new raffle deployed
    function setProtocolFeeRate(uint16 newFeeRate) external;

    /// @notice Set the insurance rate to apply on new raffle deployed
    function setInsuranceRate(uint16 newinsuranceRate) external;

    /// @notice Set the min duration for the ticket sales
    function setMinTicketSalesDuration(uint64 newMinTicketSalesDuration) external;

    /// @notice Set the max duration for the ticket sales
    function setMaxTicketSalesDuration(uint64 newMaxTicketSalesDuration) external;

    /// @notice Set the max ticket supply allowed in a raffle
    function setMaxTicketSupplyAllowed(uint16 newMaxTotalSupplyAllowed) external;

    /// @notice Pause the contract preventing new raffle to be deployed
    /// @dev can only be called by the maintainer
    function pause() external;

    /// @notice Unpause the contract allowing new raffle to be deployed
    /// @dev can only be called by the maintainer
    function unpause() external;
}

interface IClooverRaffleFactory is IClooverRaffleFactoryGetters, IClooverRaffleFactorySetters {
    /// @notice Deploy a new raffle contract
    /// @dev must transfer the nft to the contract before initialize()
    function createRaffle(
        ClooverRaffleTypes.CreateRaffleParams memory params,
        ClooverRaffleTypes.PermitDataParams calldata permitData
    ) external payable returns (address newRaffle);

    /// @notice remove msg.sender from the list of registered raffles
    /// @dev can only be called by the raffle contract itself
    function removeRaffleFromRegister() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ClooverRaffleTypes
/// @author Cloover
/// @notice Library exposing all Types used in ClooverRaffle & ClooverRaffleFactory.
library ClooverRaffleTypes {
    /* ENUMS */
    /// @notice Enumeration of the different status of the raffle
    enum Status {
        OPEN,
        DRAWING,
        DRAWN,
        REFUNDABLE,
        CANCELLED
    }

    /* STORAGE STRUCTS */

    /// @notice Contains the immutable config of a raffle
    struct ConfigData {
        // SLOT 0
        address creator; // 160 bits
        uint64 endTicketSales; // 64 bits
        // SLOT 1
        address implementationManager; // 160 bits
        uint16 maxTicketSupply; // 16 bits
        // SLOT 2
        address purchaseCurrency; // 160 bits
        uint16 maxTicketPerWallet; // 16 bits
        // SLOT 3
        address nftContract; // 160 bits
        uint16 minTicketThreshold; // 24 bits
        uint16 protocolFeeRate; // 16 bits
        uint16 insuranceRate; // 16 bits
        uint16 royaltiesRate; // 16 bits
        bool isEthRaffle; // 8 bits
        // SLOT 4
        uint256 nftId; // 256 bits
        // SLOT 5
        uint256 ticketPrice; // 256 bits
    }

    /// @notice Contains the current state of the raffle
    struct LifeCycleData {
        Status status; // 8 bits
        uint16 currentTicketSupply; // 16 bits
        uint16 winningTicketNumber; // 16 bits
    }

    /// @notice Contains the info of a purchased entry
    struct PurchasedEntries {
        address owner; // 160 bits
        uint16 currentTicketsSold; // 16 bits
        uint16 nbOfTickets; // 16 bits
    }

    ///@notice Contains the info of a participant
    struct ParticipantInfo {
        uint16 nbOfTicketsPurchased; // 16 bits
        uint16[] purchasedEntriesIndexes; // 16 bits
        bool hasClaimedRefund; // 8 bits
    }

    /// @notice Contains the base info and limit for raffles
    struct FactoryConfig {
        uint16 maxTicketSupplyAllowed; // 16 bits
        uint16 protocolFeeRate; // 16 bits
        uint16 insuranceRate; // 16 bits
        uint64 minTicketSalesDuration; // 64 bits
        uint64 maxTicketSalesDuration; // 64 bits
    }

    /* STACK AND RETURN STRUCTS */

    /// @notice The parameters used by the raffle factory to create a new raffle
    struct CreateRaffleParams {
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTicketSupply;
        uint16 maxTicketPerWallet;
        uint16 minTicketThreshold;
        uint16 royaltiesRate;
    }

    /// @notice The parameters used for ERC20 permit function
    struct PermitDataParams {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The parameters used to initialize the raffle
    struct InitializeRaffleParams {
        address creator;
        address implementationManager;
        address purchaseCurrency;
        address nftContract;
        uint256 nftId;
        uint256 ticketPrice;
        uint64 endTicketSales;
        uint16 maxTicketSupply;
        uint16 maxTicketPerWallet;
        uint16 minTicketThreshold;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint16 royaltiesRate;
        bool isEthRaffle;
    }

    /// @notice The parameters used to initialize the raffle factory
    struct FactoryConfigParams {
        uint16 maxTicketSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }
}

/// @title RandomProviderTypes
/// @author Cloover
/// @notice Library exposing all Types used in RandomProvider.
library RandomProviderTypes {
    struct ChainlinkVRFData {
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        address vrfCoordinator;
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash; // 256 bits
        // A reasonable default is 100000, but this value could be different
        // on other networks.
        uint32 callbackGasLimit;
        // The default is 3, but you can set this higher.
        uint16 requestConfirmations;
        uint64 subscriptionId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ImplementationInterfaceNames
/// @author Cloover
/// @notice Library exposing interfaces names used in Cloover
library ImplementationInterfaceNames {
    bytes32 public constant AccessController = "AccessController";
    bytes32 public constant RandomProvider = "RandomProvider";
    bytes32 public constant NFTWhitelist = "NFTWhitelist";
    bytes32 public constant TokenWhitelist = "TokenWhitelist";
    bytes32 public constant ClooverRaffleFactory = "ClooverRaffleFactory";
    bytes32 public constant Treasury = "Treasury";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Errors library
/// @author Cloover
/// @notice Library exposing errors used in Cloover's contracts
library Errors {
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error NOT_MAINTAINER(); // 'Caller is not the maintainer'
    error IMPLEMENTATION_NOT_FOUND(); // 'Implementation interfaces is not registered'
    error ALREADY_WHITELISTED(); //'address already whitelisted'
    error NOT_WHITELISTED(); //'address not whitelisted'
    error EXCEED_MAX_PERCENTAGE(); //'Percentage value must be lower than max allowed'
    error EXCEED_MAX_VALUE_ALLOWED(); //'Value must be lower than max allowed'
    error BELOW_MIN_VALUE_ALLOWED(); //'Value must be higher than min allowed'
    error WRONG_DURATION_LIMITS(); //'The min duration must be lower than the max one'
    error OUT_OF_RANGE(); //'The value is not in the allowed range'
    error SALES_ALREADY_STARTED(); // 'At least one ticket has already been sold'
    error RAFFLE_CLOSE(); // 'Current timestamps greater or equal than the close time'
    error RAFFLE_STILL_OPEN(); // 'Current timestamps lesser or equal than the close time'
    error DRAW_NOT_POSSIBLE(); // 'Raffle is status forwards than DRAWING'
    error TICKET_SUPPLY_OVERFLOW(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error WRONG_MSG_VALUE(); // 'msg.value not valid'
    error WRONG_AMOUNT(); // 'msg.value not valid'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
    error NOT_CREATOR(); // 'msg.sender is not the creator of the raffle'
    error TICKET_NOT_DRAWN(); // 'ticket must be drawn'
    error TICKET_ALREADY_DRAWN(); // 'ticket has already be drawn'
    error NOT_REGISTERED_RAFFLE(); // 'Caller is not a raffle contract registered'
    error NOT_RANDOM_PROVIDER_CONTRACT(); // 'Caller is not the random provider contract'
    error COLLECTION_NOT_WHITELISTED(); //'NFT collection not whitelisted'
    error ROYALTIES_NOT_POSSIBLE(); //'NFT collection creator '
    error TOKEN_NOT_WHITELISTED(); //'Token not whitelisted'
    error IS_ETH_RAFFLE(); //'Ticket can only be purchase with native token (ETH)'
    error NOT_ETH_RAFFLE(); //'Ticket can only be purchase with ERC20 token'
    error NO_INSURANCE_TAKEN(); //'ClooverRaffle's creator didn't took insurance to claim prize refund'
    error INSURANCE_AMOUNT(); //'insurance cost paid'
    error SALES_EXCEED_MIN_THRESHOLD_LIMIT(); //'Ticket sales exceed min ticket sales covered by the insurance paid'
    error ALREADY_CLAIMED(); //'User already claimed his part'
    error NOTHING_TO_CLAIM(); //'User has nothing to claim'
    error EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE(); //'User exceed allowed ticket to purchase limit'
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}