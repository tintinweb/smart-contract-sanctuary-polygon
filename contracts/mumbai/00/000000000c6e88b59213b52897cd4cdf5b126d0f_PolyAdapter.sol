// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FinderInterface} from "./interfaces/FinderInterface.sol";
import {OptimisticOracleInterface} from "./interfaces/OptimisticOracleInterface.sol";
import {QuestionData, IUmaCtfAdapter} from "./interfaces/IUmaCtfAdapter.sol";
import {QuestionData as BinaryQuestionData, IUmaCtfAdapterBinary} from "./interfaces/IUmaCtfAdapterBinary.sol";
import {IPolyAdapter} from "./interfaces/IPolyAdapter.sol";

contract PolyAdapter is IPolyAdapter {
    // addresses
    IUmaCtfAdapter public umaAdapter;
    IUmaCtfAdapterBinary public umaBinaryAdapter;

    constructor(address _umaAdapter, address _umaBinaryAdapter) {
        umaAdapter = IUmaCtfAdapter(_umaAdapter);
        umaBinaryAdapter = IUmaCtfAdapterBinary(_umaBinaryAdapter);
    }

    /// @notice Get initialized & resolved variables of respective UMA adapter.
    /// @param _questionID QuestionID.
    /// @param _adapter Adapter to use.
    /// @return _initialized QuestionID exists in adapter's context.
    /// @return _resolved QuestionID is resolved.
    function getInitializedAndResolved(
        bytes32 _questionID,
        Adapter _adapter
    ) external returns (bool _initialized, bool _resolved) {
        if (_adapter == Adapter.DEFAULT) {
            QuestionData memory data = umaAdapter.getQuestion(_questionID);
            _initialized = data.ancillaryData.length > 0;
            _resolved = data.resolved;
        } else if (_adapter == Adapter.BINARY) {
            (uint256 resolutionTime, , , , , , , bool resolved, , , ) = umaBinaryAdapter.questions(_questionID);
            _initialized = resolutionTime > 0;
            _resolved = resolved;
        } else {
            revert InvalidAdapter();
        }
    }

    /// @notice Get expected payout array for respective UMA adapter.
    /// @param _questionID QuestionID.
    /// @param _adapter Adapter to use.
    /// @return _payout Array representing payout.
    function getPayout(bytes32 _questionID, Adapter _adapter) external view returns (uint256[] memory _payout) {
        if (_adapter == Adapter.DEFAULT) {
            _payout = umaAdapter.getExpectedPayouts(_questionID);
        } else if (_adapter == Adapter.BINARY) {
            _payout = getResolvedPrice(_questionID);
        } else {
            revert InvalidAdapter();
        }
    }

    /// @notice Get payout array directly from UMA Optimistic Oracle.
    /// @dev only used for BinaryAdapter because Binary's getPayout is internal.
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
        ) = umaBinaryAdapter.questions(_questionID);
        if (resolutionTime == 0) revert NotInitialized();
        if (!resolved) revert PriceNotAvailable();

        int256 resolutionData = OptimisticOracleInterface(
            FinderInterface(umaBinaryAdapter.umaFinder()).getImplementationAddress("OptimisticOracle")
        ).getRequest(address(umaBinaryAdapter), "YES_OR_NO_QUERY", requestTimestamp, ancillaryData).resolvedPrice;

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

struct QuestionData {
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

interface IUmaCtfAdapter {
    function getQuestion(bytes32 questionID) external returns (QuestionData memory);

    function isInitialized(bytes32 questionID) external view returns (bool);

    function getExpectedPayouts(bytes32 questionID) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct QuestionData {
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

interface IUmaCtfAdapterBinary {
    function getExpectedPayouts(bytes32 questionID) external view returns (uint256[] memory);

    function isQuestionInitialized(bytes32 questionID) external view returns (bool);

    function questions(
        bytes32 questionID
    )
        external
        view
        returns (
            uint256 resolutionTime,
            uint256 reward,
            uint256 proposalBond,
            uint256 settled,
            uint256 requestTimestamp,
            uint256 adminResolutionTimestamp,
            bool earlyResolutionEnabled,
            bool resolved,
            bool paused,
            address rewardToken,
            bytes calldata ancillaryData
        );

    function umaFinder() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface IPolyAdapter {
    error PriceNotAvailable();
    error NotInitialized();
    error InvalidPrice();
    error InvalidAdapter();

    enum Adapter {
        DEFAULT, // polymarket UmaCtfAdapter
        BINARY, // polymarket UmaCtfAdapterBinary
        INTERNAL // memz oracle resolver (not in use)
    }

    function getInitializedAndResolved(
        bytes32 _questionID,
        Adapter _adapter
    ) external returns (bool _initialized, bool _resolved);

    function getPayout(bytes32 _questionID, Adapter _adapter) external view returns (uint256[] memory _payout);
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