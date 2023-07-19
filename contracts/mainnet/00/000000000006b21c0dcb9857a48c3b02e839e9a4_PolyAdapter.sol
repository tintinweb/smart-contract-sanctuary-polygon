// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FinderInterface} from "./interfaces/FinderInterface.sol";
import {OptimisticOracleInterface} from "./interfaces/OptimisticOracleInterface.sol";
import {V1Data, IPolyV1} from "./interfaces/IPolyV1.sol";
import {V2Data, IPolyV2} from "./interfaces/IPolyV2.sol";
import {V3Data, IPolyV3} from "./interfaces/IPolyV3.sol";
import {IPolyAdapter} from "./interfaces/IPolyAdapter.sol";

/// @title PolyAdapter
/// Memz Polymarket UMA oracle adapter.
/// @author smarsx @_smarsx
contract PolyAdapter is IPolyAdapter {
    // adapter addresses
    IPolyV1 public v1Adapter;
    IPolyV2 public v2Adapter;
    IPolyV3 public v3Adapter;

    constructor(address _v1, address _v2, address _v3) {
        v1Adapter = IPolyV1(_v1);
        v2Adapter = IPolyV2(_v2);
        v3Adapter = IPolyV3(_v3);
    }

    /// @notice Get initialized & resolved variables of respective adapter.
    /// @param _questionID QuestionID.
    /// @param _adapter Adapter to use.
    /// @return _initialized is QuestionID initialized in adapter's ctx.
    /// @return _resolved is QuestionID resolved in adapter's ctx.
    function getInitializedAndResolved(
        bytes32 _questionID,
        Adapter _adapter
    ) external view returns (bool _initialized, bool _resolved) {
        if (_adapter == Adapter.PolyV1) {
            (uint256 resolutionTime, , , , , , , bool resolved, , , ) = v1Adapter.questions(_questionID);
            _initialized = resolutionTime > 0;
            _resolved = resolved;
        } else if (_adapter == Adapter.PolyV2) {
            V2Data memory data = v2Adapter.getQuestion(_questionID);
            _initialized = data.ancillaryData.length > 0;
            _resolved = data.resolved;
        } else if (_adapter == Adapter.PolyV3) {
            V3Data memory data = v3Adapter.getQuestion(_questionID);
            _initialized = data.ancillaryData.length > 0;
            _resolved = data.resolved;
        } else {
            revert InvalidAdapter();
        }
    }

    /// @notice Check correct outcome.
    /// @dev Reverts on not resolved.
    /// @param _questionID questionID.
    /// @param _adapter Adapter to use.
    /// @param _outcome Outcome to assert correctness.
    function isOutcome(bytes32 _questionID, Adapter _adapter, Outcome _outcome) external view returns (bool) {
        uint256[] memory payouts = new uint256[](2);
        if (_adapter == Adapter.PolyV1) {
            payouts = getResolvedPrice(_questionID);
        } else if (_adapter == Adapter.PolyV2) {
            payouts = v2Adapter.getExpectedPayouts(_questionID);
        } else if (_adapter == Adapter.PolyV3) {
            payouts = v3Adapter.getExpectedPayouts(_questionID);
        } else {
            revert InvalidAdapter();
        }

        if (_outcome == Outcome.YES) {
            return payouts[0] == 1 && payouts[1] == 0;
        } else if (_outcome == Outcome.NO) {
            return payouts[0] == 0 && payouts[1] == 1;
        } else if (_outcome == Outcome.TIE) {
            return payouts[0] == 1 && payouts[1] == 1;
        }
        return false;
    }

    /// @notice Get payout array directly from UMA Optimistic Oracle.
    /// @dev only used for V1 because V1's getPayout is internal.
    /// @param _questionID QuestionID.
    /// @return payouts Array representing payout.
    function getResolvedPrice(bytes32 _questionID) internal view returns (uint256[] memory) {
        (
            uint256 resolutionTime,
            ,
            ,
            ,
            uint256 requestTimestamp,
            ,
            ,
            bool resolved,
            ,
            ,
            bytes memory ancillaryData
        ) = v1Adapter.questions(_questionID);
        if (resolutionTime == 0) revert NotInitialized();
        if (!resolved) revert PriceNotAvailable();

        int256 resolutionData = OptimisticOracleInterface(
            FinderInterface(v1Adapter.umaFinder()).getImplementationAddress("OptimisticOracle")
        ).getRequest(address(v1Adapter), "YES_OR_NO_QUERY", requestTimestamp, ancillaryData).resolvedPrice;

        // Valid prices are 0, 0.5 and 1
        if (resolutionData != 0 && resolutionData != 0.5 ether && resolutionData != 1 ether) revert InvalidPrice();

        // Payouts: [YES, NO]
        uint256[] memory payouts = new uint256[](2);

        if (resolutionData == 0) {
            // NO: Report [Yes, No] as [0, 1]
            payouts[0] = 0;
            payouts[1] = 1;
        } else if (resolutionData == 0.5 ether) {
            // UNKNOWN: Report [Yes, No] as [1, 1], 50/50
            payouts[0] = 1;
            payouts[1] = 1;
        } else {
            // YES: Report [Yes, No] as [1, 0]
            payouts[0] = 1;
            payouts[1] = 0;
        }
        return payouts;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface OptimisticOracleInterface {
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (Request memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct V1Data {
    // Unix timestamp(in seconds) at which a market can be resolved
    uint256 resolutionTime;
    // Reward offered to a successful proposer
    uint256 reward;
    // Additional bond required by Optimistic oracle proposers and disputers
    uint256 proposalBond;
    // Flag marking the block number when a question was settled
    uint256 settled;
    // Request timestmap, set when a request is made to the Optimistic Oracle
    uint256 requestTimestamp;
    // Admin Resolution timestamp, set when a market is flagged for admin resolution
    uint256 adminResolutionTimestamp;
    // Flag marking whether a question can be resolved early
    bool earlyResolutionEnabled;
    // Flag marking whether a question is resolved
    bool resolved;
    // Flag marking whether a question is paused
    bool paused;
    // ERC20 token address used for payment of rewards, proposal bonds and fees
    address rewardToken;
    // Data used to resolve a condition
    bytes ancillaryData;
}

interface IPolyV1 {
    function getExpectedPayouts(bytes32 questionID) external view returns (uint256[] memory);

    function isQuestionInitialized(bytes32 questionID) external view returns (bool);

    function questions(
        bytes32
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, bool, bool, address, bytes calldata);

    function umaFinder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct V2Data {
    /// @notice Request timestamp, set when a request is made to the Optimistic Oracle
    /// @dev Used to identify the request and NOT used by the DVM to determine validity
    uint256 requestTimestamp;
    /// @notice Reward offered to a successful proposer
    uint256 reward;
    /// @notice Additional bond required by Optimistic oracle proposers/disputers
    uint256 proposalBond;
    /// @notice Emergency resolution timestamp, set when a market is flagged for emergency resolution
    uint256 emergencyResolutionTimestamp;
    /// @notice Flag marking whether a question is resolved
    bool resolved;
    /// @notice Flag marking whether a question is paused
    bool paused;
    /// @notice Flag marking whether a question has been reset. A question can only be reset once
    bool reset;
    /// @notice ERC20 token address used for payment of rewards, proposal bonds and fees
    address rewardToken;
    /// @notice The address of the question creator
    address creator;
    /// @notice Data used to resolve a condition
    bytes ancillaryData;
}

interface IPolyV2 {
    function getQuestion(bytes32 questionID) external view returns (V2Data memory);

    function isInitialized(bytes32 questionID) external view returns (bool);

    function getExpectedPayouts(bytes32 questionID) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct V3Data {
    /// @notice Request timestamp, set when a request is made to the Optimistic Oracle
    /// @dev Used to identify the request and NOT used by the DVM to determine validity
    uint256 requestTimestamp;
    /// @notice Reward offered to a successful proposer
    uint256 reward;
    /// @notice Additional bond required by Optimistic oracle proposers/disputers
    uint256 proposalBond;
    /// @notice Custom liveness period
    uint256 liveness;
    /// @notice Emergency resolution timestamp, set when a market is flagged for emergency resolution
    uint256 emergencyResolutionTimestamp;
    /// @notice Flag marking whether a question is resolved
    bool resolved;
    /// @notice Flag marking whether a question is paused
    bool paused;
    /// @notice Flag marking whether a question has been reset. A question can only be reset once
    bool reset;
    /// @notice ERC20 token address used for payment of rewards, proposal bonds and fees
    address rewardToken;
    /// @notice The address of the question creator
    address creator;
    /// @notice Data used to resolve a condition
    bytes ancillaryData;
}

interface IPolyV3 {
    function getQuestion(bytes32 questionID) external view returns (V3Data memory);

    function isInitialized(bytes32 questionID) external view returns (bool);

    function getExpectedPayouts(bytes32 questionID) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface IPolyAdapter {
    error PriceNotAvailable();
    error NotInitialized();
    error InvalidPrice();
    error InvalidAdapter();

    enum Adapter {
        PolyV1, // polymarket UmaCtfAdapterBinary (V1)
        PolyV2, // polymarket UmaCtfAdapter (V2)
        PolyV3, // polymarket UmaCtfAdapter (V3)
        PolyV4, // future-proofing
        PolyV5,
        PolyV6,
        PolyV7,
        Memz // custom oracle resolver (not in use)
    }

    /// @notice Outcomes for an event.
    enum Outcome {
        UNRESOLVED,
        YES,
        NO,
        TIE
    }

    function getInitializedAndResolved(bytes32, Adapter) external returns (bool, bool);

    function isOutcome(bytes32, Adapter, Outcome) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}