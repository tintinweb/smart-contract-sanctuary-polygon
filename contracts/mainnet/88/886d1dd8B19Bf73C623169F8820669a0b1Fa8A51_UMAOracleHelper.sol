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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IAddressWhitelist {
    function addToWhitelist(address newElement) external;

    function removeFromWhitelist(address newElement) external;

    function isOnWhitelist(address newElement) external view returns (bool);

    function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUMAFinder} from "./IUMAFinder.sol";

/**
 * @title Simplified interface for UMA Optimistic V2 oracle interface.
 */
interface IOptimisticOracleV2 {
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    struct RequestSettings {
        bool eventBased; // True if the request is set to be event-based.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        bool callbackOnPriceProposed; // True if callbackOnPriceProposed callback is required.
        bool callbackOnPriceDisputed; // True if callbackOnPriceDisputed callback is required.
        bool callbackOnPriceSettled; // True if callbackOnPriceSettled callback is required.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        RequestSettings requestSettings; // Custom settings associated with a request.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    }

    function defaultLiveness() external view returns (uint256);

    function finder() external view returns (IUMAFinder);

    function getCurrentTime() external view returns (uint256);

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external;

    /**
     * @notice Sets the request to be an "event-based" request.
     * @dev Calling this method has a few impacts on the request:
     *
     * 1. The timestamp at which the request is evaluated is the time of the proposal, not the timestamp associated
     *    with the request.
     *
     * 2. The proposer cannot propose the "too early" value (TOO_EARLY_RESPONSE). This is to ensure that a proposer who
     *    prematurely proposes a response loses their bond.
     *
     * 3. RefundoOnDispute is automatically set, meaning disputes trigger the reward to be automatically refunded to
     *    the requesting contract.
     *
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setEventBased(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external;

    /**
     * @notice Sets which callbacks should be enabled for the request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param callbackOnPriceProposed whether to enable the callback onPriceProposed.
     * @param callbackOnPriceDisputed whether to enable the callback onPriceDisputed.
     * @param callbackOnPriceSettled whether to enable the callback onPriceSettled.
     */
    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external returns (uint256 payout);

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

    /**
     * @notice Returns the state of a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State enum value.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external view returns (bool);

    function stampAncillaryData(bytes memory ancillaryData, address requester)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface IUMAFinder {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(
        bytes32 interfaceName,
        address implementationAddress
    ) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IOptimisticOracleV2} from "../../interfaces/uma/IOptimisticOracleV2.sol";
import {IdentifierWhitelistInterface} from "../../interfaces/uma/IdentifierWhitelistInterface.sol";
import {IUMAFinder} from "../../interfaces/uma/IUMAFinder.sol";
import {IAddressWhitelist} from "../../interfaces/uma/IAddressWhitelist.sol";
import {UMAOracleInterfaces} from "./UMAOracleInterfaces.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAggregatorV3} from "../../interfaces/chainlink/IAggregatorV3.sol";

contract UMAOracleHelper {
    /**
     * @dev emitted after the {acceptableUMAPriceObsolence} changes
     * @param newTime of acceptable UMA price obsolence
     **/
    event AcceptableUMAPriceTimeChange(uint256 newTime);

    struct LastRequest {
        uint256 timestamp;
        IOptimisticOracleV2.State state;
        uint256 resolvedPrice;
        address proposer;
    }

    // Finder for UMA contracts.
    IUMAFinder public finder;

    // Unique identifier for price feed ticker.
    bytes32 private priceIdentifier;

    // The collateral currency used to back the positions in this contract.
    IERC20 public stakeCollateralCurrency;

    uint256 public acceptableUMAPriceObselence;

    LastRequest internal _lastRequest;

    constructor(
        address _stakeCollateralCurrency,
        address _finderAddress,
        bytes32 _priceIdentifier,
        uint256 _acceptableUMAPriceObselence
    ) {
        finder = IUMAFinder(_finderAddress);
        require(
            _getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier),
            "Unsupported price identifier"
        );
        require(
            _getAddressWhitelist().isOnWhitelist(_stakeCollateralCurrency),
            "Unsupported collateral type"
        );
        stakeCollateralCurrency = IERC20(_stakeCollateralCurrency);
        priceIdentifier = _priceIdentifier;
        setAcceptableUMAPriceObsolence(_acceptableUMAPriceObselence);
    }

    /**
     * Returns computed price in 8 decimal places.
     * @dev Requires chainlink price feed address for reserve asset.
     * Requires:
     * - price settled time is not greater than acceptableUMAPriceObselence.
     * - last request proposed price is settled according to UMA process:
     *   https://docs.umaproject.org/protocol-overview/how-does-umas-oracle-work
     */
    function getLastRequest(address addrChainlinkReserveAsset_)
        external
        view
        returns (uint256 computedPrice)
    {
        uint256 priceObsolence = block.timestamp > _lastRequest.timestamp
            ? block.timestamp - _lastRequest.timestamp
            : type(uint256).max;
        require(
            _lastRequest.state == IOptimisticOracleV2.State.Settled,
            "Not settled!"
        );
        require(priceObsolence < acceptableUMAPriceObselence, "Price too old!");
        (, int256 usdreserve, , , ) = IAggregatorV3(addrChainlinkReserveAsset_)
            .latestRoundData();
        computedPrice =
            (uint256(usdreserve) * 1e18) /
            _lastRequest.resolvedPrice;
    }

    // Requests a price for `priceIdentifier` at `requestedTime` from the Optimistic Oracle.
    function requestPrice() external {
        _checkLastRequest();

        uint256 requestedTime = block.timestamp;
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        oracle.requestPrice(
            priceIdentifier,
            requestedTime,
            "",
            IERC20(stakeCollateralCurrency),
            0
        );
        _resetLastRequest(requestedTime, IOptimisticOracleV2.State.Requested);
    }

    function requestPriceWithReward(uint256 rewardAmount) external {
        _checkLastRequest();
        require(
            stakeCollateralCurrency.allowance(msg.sender, address(this)) >=
                rewardAmount,
            "No erc20-approval"
        );
        IOptimisticOracleV2 oracle = _getOptimisticOracle();

        stakeCollateralCurrency.approve(address(oracle), rewardAmount);

        uint256 requestedTime = block.timestamp;

        oracle.requestPrice(
            priceIdentifier,
            requestedTime,
            "",
            IERC20(stakeCollateralCurrency),
            rewardAmount
        );

        _resetLastRequest(requestedTime, IOptimisticOracleV2.State.Requested);
    }

    function setCustomLivenessLastRequest(uint256 time) external {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        oracle.setCustomLiveness(
            priceIdentifier,
            _lastRequest.timestamp,
            "",
            time
        );
    }

    function changeBondLastPriceRequest(uint256 bond) external {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        oracle.setBond(priceIdentifier, _lastRequest.timestamp, "", bond);
    }

    function computeTotalBondLastRequest()
        public
        view
        returns (uint256 totalBond)
    {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        IOptimisticOracleV2.Request memory request = oracle.getRequest(
            address(this),
            priceIdentifier,
            _lastRequest.timestamp,
            ""
        );
        totalBond = request.requestSettings.bond + request.finalFee;
    }

    /**
     * @dev Proposed price should be in 18 decimals per specification:
     * https://github.com/UMAprotocol/UMIPs/blob/master/UMIPs/umip-139.md
     */
    function proposePriceLastRequest(uint256 proposedPrice) external {
        uint256 totalBond = computeTotalBondLastRequest();
        require(
            stakeCollateralCurrency.allowance(msg.sender, address(this)) >=
                totalBond,
            "No allowance for propose bond"
        );
        stakeCollateralCurrency.transferFrom(
            msg.sender,
            address(this),
            totalBond
        );
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        stakeCollateralCurrency.approve(address(oracle), totalBond);
        oracle.proposePrice(
            address(this),
            priceIdentifier,
            _lastRequest.timestamp,
            "",
            int256(proposedPrice)
        );
        _lastRequest.proposer = msg.sender;
        _lastRequest.state = IOptimisticOracleV2.State.Proposed;
    }

    function settleLastRequestAndGetPrice() external returns (uint256 price) {
        IOptimisticOracleV2 oracle = _getOptimisticOracle();
        int256 settledPrice = oracle.settleAndGetPrice(
            priceIdentifier,
            _lastRequest.timestamp,
            ""
        );
        require(settledPrice > 0, "Settle Price Error!");
        _lastRequest.resolvedPrice = uint256(settledPrice);
        _lastRequest.state = IOptimisticOracleV2.State.Settled;
        stakeCollateralCurrency.transfer(
            _lastRequest.proposer,
            computeTotalBondLastRequest()
        );
        price = uint256(settledPrice);
    }

    /**
     * @notice Sets a new acceptable UMA price feed obsolence time.
     * @dev Restricted to admin only.
     * @param _newTime for acceptable UMA price feed obsolence.
     * Emits a {AcceptableUMAPriceTimeChange} event.
     */
    function setAcceptableUMAPriceObsolence(uint256 _newTime) public {
        if (_newTime < 10 minutes) {
            // NewTime is too small
            revert("Invalid input");
        }
        acceptableUMAPriceObselence = _newTime;
        emit AcceptableUMAPriceTimeChange(_newTime);
    }

    function _checkLastRequest() internal view {
        if (_lastRequest.timestamp != 0) {
            require(
                _lastRequest.state == IOptimisticOracleV2.State.Settled,
                "Last request not settled!"
            );
        }
    }

    function _resetLastRequest(
        uint256 requestedTime,
        IOptimisticOracleV2.State state
    ) internal {
        _lastRequest.timestamp = requestedTime;
        _lastRequest.state = state;
        _lastRequest.resolvedPrice = 0;
        _lastRequest.proposer = address(0);
    }

    function _getIdentifierWhitelist()
        internal
        view
        returns (IdentifierWhitelistInterface)
    {
        return
            IdentifierWhitelistInterface(
                finder.getImplementationAddress(
                    UMAOracleInterfaces.IdentifierWhitelist
                )
            );
    }

    function _getAddressWhitelist() internal view returns (IAddressWhitelist) {
        return
            IAddressWhitelist(
                finder.getImplementationAddress(
                    UMAOracleInterfaces.CollateralWhitelist
                )
            );
    }

    function _getOptimisticOracle()
        internal
        view
        returns (IOptimisticOracleV2)
    {
        return
            IOptimisticOracleV2(
                finder.getImplementationAddress("OptimisticOracleV2")
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library UMAOracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant OracleHub = "OracleHub";
    bytes32 public constant OracleSpoke = "OracleSpoke";
}