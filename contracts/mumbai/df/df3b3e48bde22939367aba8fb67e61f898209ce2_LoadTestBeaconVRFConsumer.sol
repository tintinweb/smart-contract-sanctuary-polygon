// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./TestBeaconVRFConsumer.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";

contract LoadTestBeaconVRFConsumer is BeaconVRFConsumer {
    uint256 public s_averageFulfillmentInMillions = 0; // in millions for better precision
    uint256 public s_slowestFulfillment = 0;
    uint256 public s_fastestFulfillment = 999;
    uint256 public s_totalRequests = 0;
    uint256 public s_totalFulfilled = 0;
    // tracks number of times reset() is called
    // used as key in s_requestOutputHeights and s_fulfillmentDurationInBlocks to enable reset() functionality
    uint256 public s_resetCounter = 0;
    VRFBeaconTypes.RequestID public s_slowestRequestID;
    mapping(uint256 => VRFBeaconTypes.RequestID[]) public s_requestIDs;
    mapping(uint256 => mapping(VRFBeaconTypes.RequestID => uint256))
        public s_requestOutputHeights;
    mapping(uint256 => mapping(VRFBeaconTypes.RequestID => uint256))
        public s_fulfillmentDurationInBlocks;

    constructor(
        address router,
        bool shouldFail,
        uint256 beaconPeriodBlocks /*, address link*/
    ) BeaconVRFConsumer(router, shouldFail, beaconPeriodBlocks) {}

    // Est. 200_000 gas for the first fulfillment.
    function fulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory response,
        bytes memory /* arguments */
    ) internal override {
        if (fail) {
            require(false, " failed in fulfillRandomWords");
        }

        // Mark randomness as fulfilled.
        // Update fastest, slowest, and average fulfillment time in blocks.
        s_ReceivedRandomnessByRequestID[requestID] = response;
        uint256 requestDelay = ChainSpecificUtil.getBlockNumber() -
            s_requestOutputHeights[s_resetCounter][requestID];
        uint256 requestDelayInMillions = requestDelay * 1_000_000;
        if (requestDelay > s_slowestFulfillment) {
            s_slowestFulfillment = requestDelay;
            s_slowestRequestID = requestID;
        }
        s_fastestFulfillment = requestDelay < s_fastestFulfillment
            ? requestDelay
            : s_fastestFulfillment;
        s_averageFulfillmentInMillions = s_totalFulfilled > 0
            ? (s_averageFulfillmentInMillions *
                s_totalFulfilled +
                requestDelayInMillions) / (s_totalFulfilled + 1)
            : requestDelayInMillions;
        s_totalFulfilled++;
        s_fulfillmentDurationInBlocks[s_resetCounter][requestID] = requestDelay;
    }

    function testRequestRandomnessFulfillmentBatch(
        uint256 subID,
        uint16 numWords,
        VRFBeaconTypes.ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments,
        uint256 batchSize
    ) external {
        uint256 periodOffset = ChainSpecificUtil.getBlockNumber() %
            i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = ChainSpecificUtil.getBlockNumber() +
            i_beaconPeriodBlocks -
            periodOffset;

        for (uint256 i = 0; i < batchSize; i++) {
            VRFBeaconTypes.RequestID reqId = testRequestRandomnessFulfillment(
                subID,
                numWords,
                confirmationDelayArg,
                callbackGasLimit,
                arguments
            );
            s_totalRequests++;
            s_requestOutputHeights[s_resetCounter][
                reqId
            ] = nextBeaconOutputHeight;
            s_requestIDs[s_resetCounter].push(reqId);
        }
    }

    function pendingRequests()
        external
        view
        returns (VRFBeaconTypes.RequestID[] memory)
    {
        VRFBeaconTypes.RequestID[]
            memory pendingReqs = new VRFBeaconTypes.RequestID[](
                s_requestIDs[s_resetCounter].length
            );
        uint256 numPendingRequests;
        for (uint256 i = 0; i < s_requestIDs[s_resetCounter].length; i++) {
            VRFBeaconTypes.RequestID reqID = s_requestIDs[s_resetCounter][i];
            if (s_fulfillmentDurationInBlocks[s_resetCounter][reqID] == 0) {
                pendingReqs[numPendingRequests] = reqID;
                numPendingRequests++;
            }
        }
        assembly {
            mstore(pendingReqs, numPendingRequests)
        }
        return pendingReqs;
    }

    function getFulfillmentDurationByRequestID(VRFBeaconTypes.RequestID reqID)
        external
        view
        returns (uint256)
    {
        return s_fulfillmentDurationInBlocks[s_resetCounter][reqID];
    }

    function reset() external {
        s_averageFulfillmentInMillions = 0; // in millions for better precision
        s_slowestFulfillment = 0;
        s_fastestFulfillment = 999;
        s_totalRequests = 0;
        s_totalFulfilled = 0;
        s_slowestRequestID = VRFBeaconTypes.RequestID.wrap(0);
        s_resetCounter++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {ChainSpecificUtil} from "./ChainSpecificUtil.sol";
import {VRFRouter} from "./VRFRouter.sol";
import {IVRFRouterConsumer} from "./IVRFRouterConsumer.sol";

contract BeaconVRFConsumer is IVRFRouterConsumer {
    bytes internal constant EMPTY_ARGS = "";

    uint256[] public s_randomWords;
    mapping(uint256 => mapping(ConfirmationDelay => VRFBeaconTypes.RequestID)) /* block height */
        public s_requestsIDs;
    mapping(VRFBeaconTypes.RequestID => VRFBeaconTypes.BeaconRequest)
        public s_myBeaconRequests;
    mapping(VRFBeaconTypes.RequestID => uint256[]) /* randomness */
        public s_ReceivedRandomnessByRequestID;
    bytes public s_arguments;

    VRFRouter ROUTER;
    LinkTokenInterface LINKTOKEN;
    uint64 public s_subId;
    uint256 public s_gasAvailable;
    bool public fail;
    uint256 public i_beaconPeriodBlocks;

    constructor(
        address router,
        bool shouldFail,
        uint256 beaconPeriodBlocks /*, address link*/
    ) IVRFRouterConsumer(router) {
        ROUTER = VRFRouter(router);
        fail = shouldFail;
        i_beaconPeriodBlocks = beaconPeriodBlocks;
    }

    function setFail(bool shouldFail) public {
        fail = shouldFail;
    }

    function fulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual override {
        if (fail) {
            require(false, " failed in fulfillRandomWords");
        }
        s_ReceivedRandomnessByRequestID[requestID] = response;
        s_arguments = arguments;
    }

    function testRequestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        VRFBeaconTypes.ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) public returns (VRFBeaconTypes.RequestID) {
        uint256 periodOffset = ChainSpecificUtil.getBlockNumber() %
            i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = ChainSpecificUtil.getBlockNumber() +
            i_beaconPeriodBlocks -
            periodOffset;
        VRFBeaconTypes.RequestID reqId = ROUTER.requestRandomnessFulfillment(
            subID,
            numWords,
            confirmationDelayArg,
            callbackGasLimit,
            arguments,
            EMPTY_ARGS
        );
        storeBeaconRequest(
            reqId,
            nextBeaconOutputHeight,
            confirmationDelayArg,
            numWords
        );
        return reqId;
    }

    function testRequestRandomness(
        uint16 numWords,
        uint256 subID,
        ConfirmationDelay confirmationDelayArg
    ) external returns (RequestID) {
        // Have to compute them nextBeaconOutputHeight becuase requestRandomness does not return it
        // XXX : should maybe return it in requestRandomness?

        uint256 periodOffset = ChainSpecificUtil.getBlockNumber() %
            i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = ChainSpecificUtil.getBlockNumber() +
            i_beaconPeriodBlocks -
            periodOffset;
        VRFBeaconTypes.RequestID reqId = ROUTER.requestRandomness(
            subID,
            numWords,
            confirmationDelayArg,
            EMPTY_ARGS
        );

        // Need the beaconRequest for computing the expected VRF in the test
        // requestRandomness does not emit or return the beaconRequest, so could not follow after
        // beaconRequests off-chain without accessing it directly from the contract.

        storeBeaconRequest(
            reqId,
            nextBeaconOutputHeight,
            confirmationDelayArg,
            numWords
        );
        return reqId;
    }

    function testRedeemRandomness(uint256 subID, RequestID requestID) public {
        uint256[] memory response = ROUTER.redeemRandomness(
            subID,
            requestID,
            EMPTY_ARGS
        );
        s_ReceivedRandomnessByRequestID[requestID] = response;
    }

    function storeBeaconRequest(
        VRFBeaconTypes.RequestID reqId,
        uint256 height,
        VRFBeaconTypes.ConfirmationDelay delay,
        uint16 numWords
    ) public {
        s_requestsIDs[height][delay] = reqId;
        uint256 slotNumberBig = height / i_beaconPeriodBlocks;
        SlotNumber slotNumber = SlotNumber.wrap(uint32(slotNumberBig));
        BeaconRequest memory r = BeaconRequest({
            slotNumber: slotNumber,
            confirmationDelay: delay,
            numWords: numWords,
            requester: address(this)
        });
        s_myBeaconRequests[reqId] = r;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ArbSys} from "./vendor/nitro/207827de97/contracts/src/precompiles/ArbSys.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
    address private constant ARBSYS_ADDR =
        address(0x0000000000000000000000000000000000000064);
    ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
    uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

    function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            if ((getBlockNumber() - blockNumber) > 256) {
                return "";
            }
            return ARBSYS.arbBlockHash(blockNumber);
        }
        return blockhash(blockNumber);
    }

    function getBlockNumber() internal view returns (uint256) {
        uint256 chainid = block.chainid;
        if (
            chainid == ARB_MAINNET_CHAIN_ID ||
            chainid == ARB_GOERLI_TESTNET_CHAIN_ID
        ) {
            return ARBSYS.arbBlockNumber();
        }
        return block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

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
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";

// If these types are changed, the types in beaconObservation.proto and
// AbstractCostedCallbackRequest etc. probably need to change, too.
contract VRFBeaconTypes {
    type RequestID is uint48;
    RequestID constant MAX_REQUEST_ID = RequestID.wrap(type(uint48).max);
    uint8 public constant NUM_CONF_DELAYS = 8;
    uint256 internal constant MAX_NUM_ORACLES = 31;

    /// @dev With a beacon period of 15, using a uint32 here allows for roughly
    /// @dev 60B blocks, which would take roughly 2000 years on a chain with a 1s
    /// @dev block time.
    type SlotNumber is uint32;
    SlotNumber internal constant MAX_SLOT_NUMBER =
        SlotNumber.wrap(type(uint32).max);

    type ConfirmationDelay is uint24;
    ConfirmationDelay internal constant MAX_CONFIRMATION_DELAY =
        ConfirmationDelay.wrap(type(uint24).max);
    uint8 internal constant CONFIRMATION_DELAY_BYTE_WIDTH = 3;

    /// @dev Request metadata. Designed to fit in a single 32-byte word, to save
    /// @dev on storage/retrieval gas costs.
    struct BeaconRequest {
        SlotNumber slotNumber;
        ConfirmationDelay confirmationDelay;
        uint16 numWords;
        address requester; // Address which will eventually retrieve randomness
    }

    struct Callback {
        RequestID requestID;
        uint16 numWords;
        address requester;
        bytes arguments;
        uint96 gasAllowance; // gas offered to callback method when called
        uint256 subID;
        uint256 gasPrice;
        uint256 weiPerUnitLink;
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
    }

    /// @dev configuration parameters for billing
    struct BillingConfig {
        // flag to enable/disable the use of reasonableGasPrice.
        bool useReasonableGasPrice;
        // Penalty in percent (max 100) for unused gas in an allowance.
        uint8 unusedGasPenaltyPercent;
        // stalenessSeconds is how long before we consider the feed price to be
        // stale and fallback to fallbackWeiPerUnitLink.
        uint32 stalenessSeconds;
        // Estimated gas cost for a beacon fulfillment.
        uint32 redeemableRequestGasOverhead;
        // Estimated gas cost for a callback fulfillment (excludes gas allowance).
        uint32 callbackRequestGasOverhead;
        // Premium percentage charged.
        uint32 premiumPercentage;
        // reasonableGasPriceStalenessBlocks is how long before we consider
        // the last reported average gas price to be valid before falling back to
        // tx.gasprice.
        uint32 reasonableGasPriceStalenessBlocks;
        // Fallback LINK/ETH ratio.
        int256 fallbackWeiPerUnitLink;
    }

    // TODO(coventry): There is scope for optimization of the calldata gas cost,
    // here. The solidity lists can be replaced by something lower-level, where
    // the lengths are represented by something shorter, and there could be a
    // specialized part of the report which deals with fulfillments for blocks
    // which have already had their seeds reported.
    struct VRFOutput {
        uint64 blockHeight; // Beacon height this output corresponds to
        ConfirmationDelay confirmationDelay; // #blocks til offchain system response
        // VRF output for blockhash at blockHeight. If this is (0,0), indicates that
        // this is a request for callbacks for a pre-existing height, and the seed
        // should be sought from contract storage
        ECCArithmetic.G1Point vrfOutput;
        CostedCallback[] callbacks; // Contracts to callback with random outputs
    }

    struct OutputServed {
        uint64 height;
        ConfirmationDelay confirmationDelay;
        uint256 proofG1X;
        uint256 proofG1Y;
    }

    /// @dev Emitted when randomness is requested without a callback, for the
    /// @dev given beacon height. This signals to the offchain system that it
    /// @dev should provide the VRF output for that height
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param subID subscription ID that consumer contract belongs to
    /// @param numWords number of randomness words requested
    event RandomnessRequested(
        RequestID indexed requestID,
        address indexed requester,
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint256 subID,
        uint16 numWords
    );

    /// @dev Emitted when randomness is requested with a callback, for the given
    /// @dev height, to the given address, which should contain a contract with a
    /// @dev fulfillRandomness(RequestID,uint256,bytes) method. This will be
    /// @dev called with the given RequestID, the uint256 output, and the given
    /// @dev bytes arguments.
    ///
    /// @param requestID request identifier
    /// @param requester consumer contract
    /// @param nextBeaconOutputHeight height where VRF output should be provided
    /// @param confDelay num blocks offchain system should wait before responding
    /// @param subID subscription ID that consumer contract belongs to
    /// @param numWords number of randomness words requested
    /// @param gasAllowance max gas offered to callback method during fulfillment
    /// @param gasPrice tx.gasprice during request
    /// @param weiPerUnitLink ETH/LINK ratio during request
    /// @param arguments callback arguments passed in from consumer contract
    event RandomnessFulfillmentRequested(
        RequestID indexed requestID,
        address indexed requester,
        uint64 nextBeaconOutputHeight,
        ConfirmationDelay confDelay,
        uint256 subID,
        uint16 numWords,
        uint32 gasAllowance,
        uint256 gasPrice,
        uint256 weiPerUnitLink,
        bytes arguments
    );

    /// @notice emitted when the requestIDs have been fulfilled
    ///
    /// @dev There is one entry in truncatedErrorData for each false entry in
    /// @dev successfulFulfillment
    ///
    /// @param requestIDs the IDs of the requests which have been fulfilled
    /// @param successfulFulfillment ith entry true if ith fulfillment succeeded
    /// @param truncatedErrorData ith entry is error message for ith failure
    event RandomWordsFulfilled(
        RequestID[] requestIDs,
        bytes successfulFulfillment,
        bytes[] truncatedErrorData
    );

    event NewTransmission(
        uint32 indexed aggregatorRoundId,
        uint40 indexed epochAndRound,
        address transmitter,
        uint192 juelsPerFeeCoin,
        uint64 reasonableGasPrice,
        bytes32 configDigest
    );

    event OutputsServed(
        uint64 recentBlockHeight,
        address transmitter,
        uint192 juelsPerFeeCoin,
        uint64 reasonableGasPrice,
        OutputServed[] outputsServed
    );
    /**
     * @notice triggers a new run of the offchain reporting protocol
     * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
     * @param configDigest configDigest of this configuration
     * @param configCount ordinal number of this config setting among all config settings over the life of this contract
     * @param signers ith element is address ith oracle uses to sign a report
     * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
     * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    event ConfigSet(
        uint32 previousConfigBlockNumber,
        bytes32 configDigest,
        uint64 configCount,
        address[] signers,
        address[] transmitters,
        uint8 f,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC677ReceiverInterface} from "./ERC677ReceiverInterface.sol";
import {TypeAndVersionInterface} from "./vendor/ocr2-contracts/interfaces/TypeAndVersionInterface.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {VRFMigratableCoordinatorInterface} from "./VRFMigratableCoordinatorInterface.sol";
import {VRFMigrationInterface} from "./VRFMigrationInterface.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

////////////////////////////////////////////////////////////////////////////////
/// @title routes consumer requests to coordinators
///
/// @dev This router enables migrations from existing versions of the VRF coordinator to new ones.
/// @dev A VRF Consumer interacts directly with the router for requests and responses (fulfillment and redemption)
/// @dev RequestRandomness/RequestRandomnessFulfillment/RedeemRandomness are backwards-compatible
/// @dev functions across coordinators
/// @dev Consumer should allow calls from the router for fulfillment
contract VRFRouter is TypeAndVersionInterface, OwnerIsCreator, VRFBeaconTypes {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => address) private s_routes; /* sub id */ /* vrf coordinator address*/
    EnumerableSet.AddressSet private s_coordinators;

    /// @dev Emitted when given subID doesn't have any route defined
    error RouteNotFound();
    /// @dev coordinator is already registered as a valid coordinator in the router
    error CoordinatorAlreadyRegistered();
    /// @dev Emitted when given address is not registered in the router
    error CoordinatorNotRegistered();
    /// @dev Emitted when given address returns unexpected migration version
    error UnexpectedMigrationVersion();

    /// @dev Emitted when new coordinator is registered
    event CoordinatorRegistered(address coordinatorAddress);
    /// @dev Emitted when new coordinator is deregistered
    event CoordinatorDeregistered(address coordinatorAddress);
    /// @dev Emitted when a route is set for given subID
    event RouteSet(uint256 indexed subID, address coordinatorAddress);

    function getRoute(uint256 subID) public view returns (address coordinator) {
        address route = s_routes[subID];
        if (route == address(0)) {
            revert RouteNotFound();
        }

        if (!s_coordinators.contains(route)) {
            // This case happens when a coordinator is deprecated,
            // causing dangling subIDs to become invalid
            revert RouteNotFound();
        }

        return route;
    }

    /// @dev whenever a subscription is created in coordinator, it must call
    /// @dev this function to register the route
    function setRoute(uint256 subID) external validateCoordinators(msg.sender) {
        s_routes[subID] = msg.sender;
        emit RouteSet(subID, msg.sender);
    }

    /// @dev whenever a subscription is cancelled/deleted in coordinator, it must call
    /// @dev this function to reset the route
    function resetRoute(uint256 subID)
        external
        validateCoordinators(msg.sender)
    {
        s_routes[subID] = address(0);
        emit RouteSet(subID, address(0));
    }

    function registerCoordinator(address coordinatorAddress)
        external
        onlyOwner
    {
        if (s_coordinators.contains(coordinatorAddress)) {
            revert CoordinatorAlreadyRegistered();
        }
        VRFMigrationInterface coordinator = VRFMigrationInterface(
            coordinatorAddress
        );
        // validate coordinator implements VRFMigrationInterface and
        // returns valid migration version
        if (coordinator.migrationVersion() == 0) {
            revert UnexpectedMigrationVersion();
        }

        s_coordinators.add(coordinatorAddress);
        emit CoordinatorRegistered(coordinatorAddress);
    }

    function deregisterCoordinator(address coordinatorAddress)
        external
        onlyOwner
        validateCoordinators(coordinatorAddress)
    {
        s_coordinators.remove(coordinatorAddress);
        emit CoordinatorDeregistered(coordinatorAddress);
    }

    function getCoordinators() external view returns (address[] memory) {
        return s_coordinators.values();
    }

    function isCoordinatorRegistered(address coordinatorAddress)
        external
        view
        returns (bool)
    {
        if (s_coordinators.contains(coordinatorAddress)) {
            return true;
        }
        return false;
    }

    function requestRandomness(
        uint256 subID,
        uint16 numWords,
        ConfirmationDelay confDelay,
        bytes memory extraArgs
    ) external returns (RequestID) {
        VRFMigratableCoordinatorInterface coordinator = VRFMigratableCoordinatorInterface(
                getRoute(subID)
            );
        return
            coordinator.requestRandomness(
                msg.sender,
                subID,
                numWords,
                confDelay,
                extraArgs
            );
    }

    function requestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        ConfirmationDelay confDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external returns (RequestID) {
        VRFMigratableCoordinatorInterface coordinator = VRFMigratableCoordinatorInterface(
                getRoute(subID)
            );
        return
            coordinator.requestRandomnessFulfillment(
                msg.sender,
                subID,
                numWords,
                confDelay,
                callbackGasLimit,
                arguments,
                extraArgs
            );
    }

    function redeemRandomness(
        uint256 subID,
        RequestID requestID,
        bytes memory extraArgs
    ) external returns (uint256[] memory randomness) {
        VRFMigratableCoordinatorInterface coordinator = VRFMigratableCoordinatorInterface(
                getRoute(subID)
            );
        return
            coordinator.redeemRandomness(
                msg.sender,
                subID,
                requestID,
                extraArgs
            );
    }

    uint256 private constant CALL_WITH_EXACT_GAS_CUSHION = 5_000;

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function callWithExactGasEvenIfTargetIsNoContract(
        uint256 gasAmount,
        address target,
        bytes memory data
    )
        external
        validateCoordinators(msg.sender)
        returns (bool success, bool sufficientGas)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let g := gas()
            // Compute g -= CALL_WITH_EXACT_GAS_CUSHION and check for underflow. We
            // need the cushion since the logic following the above call to gas also
            // costs gas which we cannot account for exactly. So cushion is a
            // conservative upper bound for the cost of this logic.
            if iszero(lt(g, CALL_WITH_EXACT_GAS_CUSHION)) {
                // i.e., g >= CALL_WITH_EXACT_GAS_CUSHION
                g := sub(g, CALL_WITH_EXACT_GAS_CUSHION)
                // If g - g//64 <= _gasAmount, we don't have enough gas. (We subtract g//64
                // because of EIP-150.)
                if gt(sub(g, div(g, 64)), gasAmount) {
                    // Call and receive the result of call. Note that we did not check
                    // whether a contract actually exists at the _target address.
                    success := call(
                        gasAmount, // gas
                        target, // address of target contract
                        0, // value
                        add(data, 0x20), // inputs
                        mload(data), // inputs size
                        0, // outputs
                        0 // outputs size
                    )
                    sufficientGas := true
                }
            }
        }
    }

    modifier validateCoordinators(address addr) {
        if (!s_coordinators.contains(addr)) {
            revert CoordinatorNotRegistered();
        }
        _;
    }

    function typeAndVersion() external pure virtual returns (string memory) {
        return "VRFRouter 1.0.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {VRFRouter} from "./VRFRouter.sol";

abstract contract IVRFRouterConsumer is VRFBeaconTypes {
    VRFRouter immutable router;

    constructor(address _router) {
        router = VRFRouter(_router);
    }

    function fulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory response,
        bytes memory arguments
    ) internal virtual;

    function rawFulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory randomWords,
        bytes memory arguments
    ) external {
        require(address(router) == msg.sender, "only router can fulfill");
        fulfillRandomWords(requestID, randomWords, arguments);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ECCArithmetic {
    // constant term in affine curve equation: y²=x³+b
    uint256 constant B = 3;

    // Base field for G1 is 𝔽ₚ
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
    uint256 constant P =
        // solium-disable-next-line indentation
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // #E(𝔽ₚ), number of points on  G1/G2Add
    // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
    uint256 constant Q =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    struct G1Point {
        uint256[2] p;
    }

    struct G2Point {
        uint256[4] p;
    }

    function checkPointOnCurve(G1Point memory p) internal pure {
        require(p.p[0] < P, "x not in F_P");
        require(p.p[1] < P, "y not in F_P");
        uint256 rhs = addmod(
            mulmod(mulmod(p.p[0], p.p[0], P), p.p[0], P),
            B,
            P
        );
        require(mulmod(p.p[1], p.p[1], P) == rhs, "point not on curve");
    }

    function _addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory sum)
    {
        checkPointOnCurve(p1);
        checkPointOnCurve(p2);

        uint256[4] memory summands;
        summands[0] = p1.p[0];
        summands[1] = p1.p[1];
        summands[2] = p2.p[0];
        summands[3] = p2.p[1];
        uint256[2] memory result;
        uint256 callresult;
        assembly {
            // solhint-disable-line no-inline-assembly
            callresult := staticcall(
                // gas cost. https://eips.ethereum.org/EIPS/eip-1108 ,
                // https://github.com/ethereum/go-ethereum/blob/9d10856/params/protocol_params.go#L124
                150,
                // g1add https://github.com/ethereum/go-ethereum/blob/9d10856/core/vm/contracts.go#L89
                0x6,
                summands, // input
                0x80, // input length: 4 words
                result, // output
                0x40 // output length: 2 words
            )
        }
        require(callresult != 0, "addg1 call failed");
        sum.p[0] = result[0];
        sum.p[1] = result[1];
        return sum;
    }

    function addG1(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory)
    {
        G1Point memory sum = _addG1(p1, p2);
        // This failure is mathematically possible from a legitimate return
        // value, but vanishingly unlikely, and almost certainly instead
        // reflects a failure in the precompile.
        require(sum.p[0] != 0 && sum.p[1] != 0, "addg1 failed: zero ordinate");
        return sum;
    }

    // Coordinates for generator of G2.
    uint256 constant g2GenXA =
        0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 constant g2GenXB =
        0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 constant g2GenYA =
        0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
    uint256 constant g2GenYB =
        0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 constant pairingGasCost = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
    uint256 constant pairingPrecompileAddress = 0x8;
    uint256 constant pairingInputLength = 12 * 0x20;
    uint256 constant pairingOutputLength = 0x20;

    // discreteLogsMatch returns true iff signature = sk*base, where sk is the
    // secret key associated with pubkey, i.e. pubkey = sk*<G2 generator>
    //
    // This is used for signature/VRF verification. In actual use, g1Base is the
    // hash-to-curve to be signed/exponentiated, and pubkey is the public key
    // the signature pertains to.
    function discreteLogsMatch(
        G1Point memory g1Base,
        G1Point memory signature,
        G2Point memory pubkey
    ) internal view returns (bool) {
        // It is not necessary to check that the points are in their respective
        // groups; the pairing check fails if that's not the case.

        // Let g1, g2 be the canonical generators of G1, G2, respectively..
        // Let l be the (unknown) discrete log of g1Base w.r.t. the G1 generator.
        //
        // In the happy path, the result of the first pairing in the following
        // will be -l*log_{g2}(pubkey) * e(g1,g2) = -l * sk * e(g1,g2), of the
        // second will be sk * l * e(g1,g2) = l * sk * e(g1,g2). Thus the two
        // terms will cancel, and the pairing function will return one. See
        // EIP-197.
        G1Point[] memory g1s = new G1Point[](2);
        G2Point[] memory g2s = new G2Point[](2);
        g1s[0] = G1Point([g1Base.p[0], P - g1Base.p[1]]);
        g1s[1] = signature;
        g2s[0] = pubkey;
        g2s[1] = G2Point([g2GenXA, g2GenXB, g2GenYA, g2GenYB]);
        return pairing(g1s, g2s);
    }

    function negateG1(G1Point memory p)
        internal
        pure
        returns (G1Point memory neg)
    {
        neg.p[0] = p.p[0];
        neg.p[1] = P - p.p[1];
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    //
    // Cribbed from https://gist.github.com/BjornvdLaan/ca6dd4e3993e1ef392f363ec27fe74c4
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].p[0];
            input[i * 6 + 1] = p1[i].p[1];
            input[i * 6 + 2] = p2[i].p[0];
            input[i * 6 + 3] = p2[i].p[1];
            input[i * 6 + 4] = p2[i].p[2];
            input[i * 6 + 5] = p2[i].p[3];
        }

        uint256[1] memory out;
        bool success;

        assembly {
            success := staticcall(
                pairingGasCost,
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        require(success);
        return out[0] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ERC677ReceiverInterface {
    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TypeAndVersionInterface {
    function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";

abstract contract VRFMigratableCoordinatorInterface is VRFBeaconTypes {
    //////////////////////////////////////////////////////////////////////////////
    /// @notice Register a future request for randomness,and return the requestID.
    ///
    /// @notice The requestID resulting from given requestRandomness call MAY
    /// @notice CHANGE if a set of transactions calling requestRandomness are
    /// @notice re-ordered during a block re-organization. Thus, it is necessary
    /// @notice for the calling context to store the requestID onchain, unless
    /// @notice there is a an offchain system which keeps track of changes to the
    /// @notice requestID.
    ///
    /// @param requester consumer address. msg.sender in router
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomness(
        address requester,
        uint256 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelay,
        bytes memory extraArgs
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice fulfillRandomness(RequestID,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    ///
    /// @param requester consumer address. msg.sender in router
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomnessFulfillment(
        address requester,
        uint256 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requester consumer address. msg.sender in router
    /// @param subID subscription ID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @param extraArgs extra arguments
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(
        address requester,
        uint256 subID,
        RequestID requestID,
        bytes memory extraArgs
    ) external virtual returns (uint256[] memory randomness);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFMigratableCoordinatorInterface} from "./VRFMigratableCoordinatorInterface.sol";

interface VRFMigrationInterface {
    /**
     * @notice Migrates user data (e.g. balance, consumers) from one coordinator to another.
     * @notice only callable by the owner of user data
     * @param newCoordinator new coordinator instance
     * @param encodedRequest abi-encoded data that identifies that migrate() request (e.g. version to migrate to, user data ID)
     */
    function migrate(
        VRFMigrationInterface newCoordinator,
        bytes calldata encodedRequest
    ) external;

    /**
     * @notice called by older versions of coordinator for migration.
     * @notice only callable by older versions of coordinator
     * @param encodedData - user data from older version of coordinator
     */
    function onMigration(bytes calldata encodedData) external;

    /**
     * @return version - current migration version
     */
    function migrationVersion() external pure returns (uint8 version);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
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

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}