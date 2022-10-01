// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ECCArithmetic} from "./ECCArithmetic.sol";
import {LinkTokenInterface} from "./vendor/ocr2-contracts/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorConsumer} from "./IVRFCoordinatorConsumer.sol";
import {IVRFCoordinatorExternalAPI} from "./IVRFCoordinatorExternalAPI.sol";
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";

contract BeaconVRFConsumer is IVRFCoordinatorConsumer {
    uint256[] public s_randomWords;
    mapping(uint256 => mapping(ConfirmationDelay => VRFBeaconTypes.RequestID)) /* block height */
        public s_requestsIDs;
    mapping(VRFBeaconTypes.RequestID => VRFBeaconTypes.BeaconRequest)
        public s_myBeaconRequests;
    mapping(VRFBeaconTypes.RequestID => uint256[]) /* randomness */
        public s_ReceivedRandomnessByRequestID;

    IVRFCoordinatorExternalAPI COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 public s_subId;
    uint256 public s_gasAvailable;
    bool public fail;
    uint256 public i_beaconPeriodBlocks;

    constructor(
        address coordinator,
        bool shouldFail,
        uint256 beaconPeriodBlocks /*, address link*/
    ) IVRFCoordinatorConsumer(coordinator) {
        COORDINATOR = IVRFCoordinatorExternalAPI(coordinator);
        fail = shouldFail;
        i_beaconPeriodBlocks = beaconPeriodBlocks;
    }

    function setFail(bool shouldFail) public {
        fail = shouldFail;
    }

    function fulfillRandomWords(
        VRFBeaconTypes.RequestID requestID,
        uint256[] memory response,
        bytes memory /* arguments */
    ) internal override {
        if (fail) {
            require(false, " failed in fulfillRandomWords");
        }
        s_ReceivedRandomnessByRequestID[requestID] = response;
    }

    function testRequestRandomnessFulfillment(
        uint64 subID,
        uint16 numWords,
        VRFBeaconTypes.ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) external returns (VRFBeaconTypes.RequestID) {
        uint256 periodOffset = block.number % i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = block.number +
            i_beaconPeriodBlocks -
            periodOffset;
        VRFBeaconTypes.RequestID reqId = COORDINATOR
            .requestRandomnessFulfillment(
                subID,
                numWords,
                confirmationDelayArg,
                callbackGasLimit,
                arguments
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
        uint64 subID,
        ConfirmationDelay confirmationDelayArg
    ) external returns (RequestID) {
        // Have to compute them nextBeaconOutputHeight becuase requestRandomness does not return it
        // XXX : should maybe return it in requestRandomness?

        uint256 periodOffset = block.number % i_beaconPeriodBlocks;
        uint256 nextBeaconOutputHeight = block.number +
            i_beaconPeriodBlocks -
            periodOffset;
        VRFBeaconTypes.RequestID reqId = COORDINATOR.requestRandomness(
            numWords,
            subID,
            confirmationDelayArg
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

    function testRedeemRandomness(RequestID requestID) public {
        uint256[] memory response = COORDINATOR.redeemRandomness(requestID);
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
import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";
import {IVRFCoordinatorExternalAPI} from "./IVRFCoordinatorExternalAPI.sol";

abstract contract IVRFCoordinatorConsumer is VRFBeaconTypes {
    IVRFCoordinatorExternalAPI immutable coordinator;

    constructor(address _coordinator) {
        coordinator = IVRFCoordinatorExternalAPI(_coordinator);
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
        require(
            address(coordinator) == msg.sender,
            "only coordinator can fulfill"
        );
        fulfillRandomWords(requestID, randomWords, arguments);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VRFBeaconTypes} from "./VRFBeaconTypes.sol";

abstract contract IVRFCoordinatorExternalAPI is VRFBeaconTypes {
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
    /// @param numWords number of uint256's of randomness to provide in response
    /// @return ID of created request
    function requestRandomness(
        uint16 numWords,
        uint64 subID,
        ConfirmationDelay confirmationDelayArg
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice fulfillRandomness(RequestID,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param arguments data which should be passed to the callback method
    ///
    /// @return ID of created request
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    function requestRandomnessFulfillment(
        uint64 subID,
        uint16 numWords,
        ConfirmationDelay confirmationDelayArg,
        uint32 callbackGasLimit,
        bytes memory arguments
    ) external virtual returns (RequestID);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(RequestID requestID)
        public
        virtual
        returns (uint256[] memory randomness);
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
        uint64 subID;
        uint96 gasAllowance; // gas offered to callback method when called
    }

    struct CostedCallback {
        Callback callback;
        uint96 price; // nominal price charged for the callback
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
    }
}