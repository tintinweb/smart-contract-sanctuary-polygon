// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollateralManager {
    function depositeCollateral(
        address _from,
        address _collateralCurrency,
        uint256 _collateralAmount
    ) external payable;

    function withdrawCollateral(
        address _to,
        address _collateralCurrency,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint256[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 value,
            uint256 systemValue,
            uint256 systemSourceRate,
            uint256 systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint256);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view returns (uint256);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId) external view returns (uint256 rate, uint256 time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint256 rate, uint256 time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint256 rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint256);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint256);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds,
        uint256 roundId
    ) external view returns (uint256[] memory rates, uint256[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint256[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint256 amount;
        bytes32 dest;
        uint256 reclaim;
        uint256 rebate;
        uint256 srcRoundIdAtPeriodEnd;
        uint256 destRoundIdAtPeriodEnd;
        uint256 timestamp;
    }

    struct ExchangeEntry {
        uint256 sourceRate;
        uint256 destinationRate;
        uint256 destinationAmount;
        uint256 exchangeFeeRate;
        uint256 exchangeDynamicFeeRate;
        uint256 roundIdForSrc;
        uint256 roundIdForDest;
    }

    struct ExchangeArgs {
        address fromAccount;
        address destAccount;
        bytes32 sourceCurrencyKey;
        bytes32 destCurrencyKey;
        uint256 sourceAmount;
        uint256 destAmount;
        uint256 fee;
        uint256 reclaimed;
        uint256 refunded;
        uint16 destChainId;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint256 amount,
        uint256 refunded
    ) external view returns (uint256 amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 numEntries
        );

    // function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint256);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint256 feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate
        );

    // function priceDeviationThresholdFactor() external view returns (uint256);

    // function waitingPeriodSecs() external view returns (uint256);

    // function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(ExchangeArgs calldata args) external payable returns (uint256 amountReceived);

    function exchangeAtomically(uint256 minAmount, ExchangeArgs calldata args) external payable returns (uint256 amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntries
        );

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;

    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint256 destinationAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISynth.sol";

interface IIssuer {
    // Views

    function allNetworksDebtInfo() external view returns (uint256 debt, uint256 sharesSupply);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer) external view returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(
        address _issuer
    ) external view returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(
        address issuer
    ) external view returns (uint256 maxIssuable, uint256 alreadyIssued, uint256 totalSystemDebt);

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256);

    function checkFreeCollateral(
        address _issuer,
        bytes32 _collateralKey,
        uint16 _chainId
    ) external view returns (uint256 withdrawableSynthr);

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynths(address from, uint256 destChainId) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount
    ) external returns (uint256 synthAmount, uint256 debtShare, uint256 reclaimed, uint256 refunded);

    function burnSynthsToTarget(
        address from,
        bytes32 synthKey
    ) external returns (uint256 synthAmount, uint256 debtShare, uint256 reclaimed, uint256 refunded);

    function burnForRedemption(address deprecatedSynthProxy, address account, uint256 balance) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        uint16 chainId,
        bool isSelfLiquidation
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate, uint256 sharesToRemove);

    function destIssue(address _account, bytes32 _synthKey, uint256 _synthAmount) external;

    function destBurn(address _account, bytes32 _synthKey, uint256 _synthAmount) external returns (uint256);

    function transferMargin(address account, uint256 marginDelta) external returns (uint256);

    function setCurrentPeriodId(uint128 periodId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISynth {
    // Views
    function balanceOf(address _account) external view returns (uint256);

    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external payable returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external payable returns (bool);

    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExchanger.sol";

interface ISynthrBridge {
    /* ========== MUTATIVE FUNCTIONS ========== */
    function sendDepositCollateral(
        address account,
        bytes32 collateralKey,
        uint256 amount
    ) external payable;

    function sendBurn(
        address account,
        bytes32 synthKey,
        uint256 amount
    ) external payable;

    function sendExchange(
        address account,
        bytes32 srcSynthKey,
        bytes32 dstSynthKey,
        uint256 srcAmount,
        uint256 dstAmount,
        uint256 reclaimed,
        uint256 refunded,
        uint256 fee,
        uint16 dstChainId
    ) external payable;

    function sendBridgeSyToken(
        address account,
        bytes32 synthKey,
        uint256 amount,
        uint16 dstChainId
    ) external payable;

    function sendTransferMargin(address account, uint256 amount) external payable;

    // function sendExchange(IExchanger.ExchangeArgs calldata args) external payable;

    function calcLZFee(
        bytes memory lzPayload,
        uint16 packetType,
        uint16 dstChainId
    ) external view returns (uint256 lzFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function synthSuspended(bytes32 currencyKey) external view returns (bool);

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "../interfaces/IAddressResolver.sol";

// Internal references
import "../interfaces/IIssuer.sol";
import "./MixinResolver.sol";

contract AddressResolverLightChain is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Inheritance
import "../interfaces/IERC20.sol";
import "./ExternWrappedStateTokenLightChain.sol";
import "./MixinResolver.sol";
import "./Owned.sol";
// Internal references
import "../interfaces/ISynth.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IIssuer.sol";
import "../interfaces/ICollateralManager.sol";
import "../interfaces/ISynthrBridgeLightChain.sol";
import "../libraries/TransferHelper.sol";
import "./SafeDecimalMath.sol";

contract BaseWrappedSynthr is MixinResolver, Owned {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    // ========== STATE VARIABLES ==========

    // Available Synths which can be used with the system
    bytes32 public constant sUSD = "sUSD";

    ExternWrappedStateTokenLightChain extTokenState;

    address internal constant NULL_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYNTHRBRIDGE = "SynthrBridge";
    bytes32 private constant CONTRACT_COLLATERAL_MANAGER = "CollateralManager";

    // ========== CONSTRUCTOR ==========
    constructor(
        ExternWrappedStateTokenLightChain _extTokenState,
        address _owner,
        address _resolver
    ) MixinResolver(_resolver) Owned(_owner) {
        extTokenState = _extTokenState;
    }

    // ========== VIEWS ==========

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public pure override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](6);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXCHANGER;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_EXRATES;
        addresses[4] = CONTRACT_SYNTHRBRIDGE;
        addresses[5] = CONTRACT_COLLATERAL_MANAGER;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function collateralManager() internal view returns (ICollateralManager) {
        return ICollateralManager(requireAndGetAddress(CONTRACT_COLLATERAL_MANAGER));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function synthrBridge() internal view returns (ISynthrBridge) {
        return ISynthrBridge(requireAndGetAddress(CONTRACT_SYNTHRBRIDGE));
    }

    function getAvailableCollaterals() external view returns (bytes32[] memory) {
        return extTokenState.getAvailableCollaterals();
    }

    function name() external view returns (string memory) {
        return extTokenState.name();
    }

    function symbol() external view returns (string memory) {
        return extTokenState.symbol();
    }

    function decimals() external view returns (uint256) {
        return extTokenState.decimals();
    }

    function collateralCurrency(bytes32 _collateralKey) external view returns (address) {
        return extTokenState.collateralCurrency(_collateralKey);
    }

    // ========== MUTATIVE FUNCTIONS ==========

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint16 destChainId
    ) external payable exchangeActive(sourceCurrencyKey, destinationCurrencyKey) systemActive returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: msg.sender,
            destAccount: msg.sender,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destAmount: 0,
            fee: 0,
            reclaimed: 0,
            refunded: 0,
            destChainId: destChainId
        });
        (amountReceived) = exchanger().exchange{value: msg.value}(args);
    }

    function collateralTransfer(
        address _from,
        bytes32 _collateralKey,
        uint256 _collateralAmount
    ) public systemActive onlySynthrBridge returns (bool) {
        require(extTokenState.collateralCurrency(_collateralKey) != address(0), "");
        extTokenState.withdrawCollateral(address(this), _collateralKey, _collateralAmount);
        _burn(_from, _collateralAmount, _collateralKey);
        if (extTokenState.collateralCurrency(_collateralKey) == NULL_ADDRESS) {
            collateralManager().depositeCollateral{value: _collateralAmount}(_from, NULL_ADDRESS, _collateralAmount);
        } else {
            if (
                IERC20(extTokenState.collateralCurrency(_collateralKey)).allowance(address(this), address(collateralManager())) ==
                0
            ) {
                TransferHelper.safeApprove(
                    extTokenState.collateralCurrency(_collateralKey),
                    address(collateralManager()),
                    type(uint256).max
                );
            }
            collateralManager().depositeCollateral{value: 0}(
                _from,
                extTokenState.collateralCurrency(_collateralKey),
                _collateralAmount
            );
        }
        emit CollateralTransfer(_from, _collateralKey, _collateralAmount);
        return true;
    }

    function _mint(
        address _to,
        uint256 _collateralAmount,
        bytes32 _collateralKey
    ) internal returns (bool) {
        // Increase total supply by minted amount
        extTokenState.increaseCollateral(_to, _collateralKey, _collateralAmount);
        // emit Transfer(address(0), _to, _collateralAmount);
        return true;
    }

    function _burn(
        address _to,
        uint256 _collateralAmount,
        bytes32 _collateralKey
    ) internal returns (bool) {
        extTokenState.decreaseCollateral(_to, _collateralKey, _collateralAmount);
        // emit Transfer(_to, address(0), _collateralAmount);
        return true;
    }

    // ========== MODIFIERS ==========

    modifier systemActive() {
        _systemActive();
        _;
    }

    function _systemActive() private view {
        systemStatus().requireSystemActive();
    }

    modifier issuanceActive() {
        _issuanceActive();
        _;
    }

    function _issuanceActive() private view {
        systemStatus().requireIssuanceActive();
    }

    modifier exchangeActive(bytes32 src, bytes32 dest) {
        _exchangeActive(src, dest);
        _;
    }

    function _exchangeActive(bytes32 src, bytes32 dest) private view {
        systemStatus().requireExchangeBetweenSynthsAllowed(src, dest);
    }

    modifier onlyExchanger() {
        _onlyExchanger();
        _;
    }

    function _onlyExchanger() private view {
        require(msg.sender == address(exchanger()), "Only Exchanger can invoke this");
    }

    modifier onlySynthrBridge() {
        require(msg.sender == address(synthrBridge()), "Only SynthrBridge can invoke this");
        _;
    }

    // ========== EVENTS ==========

    event AccountLiquidated(address indexed account, uint256 synthRedeemed, uint256 amountLiquidated, address liquidator);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event CollateralTransfer(address indexed from, bytes32 collateralKey, uint256 collateralAmount);

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./State.sol";
import "../interfaces/IERC20.sol";
// Libraries
import "./SafeDecimalMath.sol";
import "../libraries/TransferHelper.sol";

contract ExternWrappedStateTokenLightChain is State {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    /* ========== STATE VARIABLES ========== */
    /* Other ERC20 fields. */
    string public name;
    string public symbol;
    // uint256 public totalSupply;
    uint8 public decimals;
    mapping(bytes32 => uint256) public totalSupplyPerKey;

    mapping(bytes32 => address) public collateralCurrency;
    bytes32[] public availableCollateralCurrencies;
    mapping(bytes32 => mapping(address => uint256)) public collateralByIssuer;

    address internal constant NULL_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner,
        address _associatedContract
    ) State(_owner, _associatedContract) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function getAvailableCollaterals() external view returns (bytes32[] memory) {
        return availableCollateralCurrencies;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function addCollateralCurrency(address _collateralAddress, bytes32 _currencyKey) external onlyOwner {
        require(collateralCurrency[_currencyKey] == address(0), "Collateral Currency Key exists already");
        collateralCurrency[_currencyKey] = _collateralAddress;
        availableCollateralCurrencies.push(_currencyKey);
        emit CollateralCurrencyAdded(_currencyKey, _collateralAddress);
    }

    function removeCollateralCurrency(bytes32 _currencyKey) external onlyOwner {
        require(collateralCurrency[_currencyKey] != address(0), "Collateral Currency Key no exists");
        address collateralAddress = collateralCurrency[_currencyKey];
        delete collateralCurrency[_currencyKey];
        uint256 availableLength = availableCollateralCurrencies.length;
        for (uint256 ii = 0; ii < availableLength; ii++) {
            if (availableCollateralCurrencies[ii] == _currencyKey) {
                availableCollateralCurrencies[ii] = availableCollateralCurrencies[availableLength - 1];
                availableCollateralCurrencies.pop();
            }
        }
        emit CollateralCurrencyRemoved(_currencyKey, collateralAddress);
    }

    function increaseCollateral(
        address _to,
        bytes32 _currencyKey,
        uint256 _collateralAmount
    ) external onlyAssociatedContract {
        totalSupplyPerKey[_currencyKey] = totalSupplyPerKey[_currencyKey] + _collateralAmount;
        collateralByIssuer[_currencyKey][_to] = collateralByIssuer[_currencyKey][_to] + _collateralAmount;
    }

    function decreaseCollateral(
        address _to,
        bytes32 _currencyKey,
        uint256 _collateralAmount
    ) external onlyAssociatedContract {
        totalSupplyPerKey[_currencyKey] = totalSupplyPerKey[_currencyKey] - _collateralAmount;
        collateralByIssuer[_currencyKey][_to] = collateralByIssuer[_currencyKey][_to] - _collateralAmount;
    }

    function withdrawCollateral(
        address _to,
        bytes32 _currencyKey,
        uint256 _collateralAmount
    ) external onlyAssociatedContract {
        if (collateralCurrency[_currencyKey] == NULL_ADDRESS) {
            require(address(this).balance >= _collateralAmount, "Insufficient ETH balance to withdraw.");
            TransferHelper.safeTransferETH(_to, _collateralAmount);
        } else {
            require(
                IERC20(collateralCurrency[_currencyKey]).balanceOf(address(this)) >= _collateralAmount,
                "Insufficient Collateral Balance to withdraw on Contract."
            );
            TransferHelper.safeTransfer(collateralCurrency[_currencyKey], _to, _collateralAmount);
        }
    }

    // admin functions for dev version
    function withdrawFundsByAdmin(
        address _to,
        bytes32 _currencyKey,
        uint256 _collateralAmount
    ) external onlyOwner {
        if (collateralCurrency[_currencyKey] == NULL_ADDRESS) {
            require(address(this).balance >= _collateralAmount, "Insufficient ETH balance to withdraw.");
            TransferHelper.safeTransferETH(_to, _collateralAmount);
        } else {
            require(
                IERC20(collateralCurrency[_currencyKey]).balanceOf(address(this)) >= _collateralAmount,
                "Insufficient Collateral Balance to withdraw on Contract."
            );
            TransferHelper.safeTransfer(collateralCurrency[_currencyKey], _to, _collateralAmount);
        }
    }

    // For dev
    function setCollateralBalance(
        address _account,
        bytes32 _currencyKey,
        uint256 _amount
    ) external onlyOwner {
        collateralByIssuer[_currencyKey][_account] = _amount;
        totalSupplyPerKey[_currencyKey] += _amount;

        emit SetCollateralBalance(_account, _currencyKey, _amount);
    }

    receive() external payable {}

    // ========== EVENTS ==========
    event CollateralCurrencyAdded(bytes32 currencyKey, address collateralCurrency);
    event CollateralCurrencyRemoved(bytes32 currencyKey, address collateralCurrency);
    event SetCollateralBalance(address indexed _account, bytes32 _currencyKey, uint256 _amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal references
import "./AddressResolverLightChain.sol";

contract MixinResolver {
    AddressResolverLightChain public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) {
        resolver = AddressResolverLightChain(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
// import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "../externals/openzeppelin/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(signedAbs(x));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _owner, address _associatedContract) Owned(_owner) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract() {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./BaseWrappedSynthr.sol";
import "./ExternWrappedStateTokenLightChain.sol";
import "./SafeDecimalMath.sol";
import "../interfaces/IExchanger.sol";

// Internal references
import "../libraries/TransferHelper.sol";

contract WrappedSynthrLightChain is BaseWrappedSynthr {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 public constant CONTRACT_NAME = "Wrapped Synthr";
    uint16 private constant PT_DEPOSIT_COLLATERAL = 1; // staking collateral
    uint16 internal constant PT_BURN_SYNTH = 4;
    uint16 internal constant PT_TRANSFER_MARGIN_SYNTH = 9;

    // ========== CONSTRUCTOR ==========
    constructor(
        ExternWrappedStateTokenLightChain _extTokenState,
        address _owner,
        address _resolver
    ) BaseWrappedSynthr(_extTokenState, _owner, _resolver) {}

    // ========== VIEWS ==========

    function balanceOf(address account) external view returns (uint256) {
        uint256 synthrBalance;
        bytes32[] memory availableCollateralCurrencies = extTokenState.getAvailableCollaterals();
        for (uint256 ii = 0; ii < availableCollateralCurrencies.length; ii++) {
            bytes32 _collateralCurrencyKey = availableCollateralCurrencies[ii];
            if (extTokenState.collateralByIssuer(_collateralCurrencyKey, account) > 0) {
                (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralCurrencyKey);
                synthrBalance = synthrBalance.add(
                    extTokenState.collateralByIssuer(_collateralCurrencyKey, account).multiplyDecimal(collateralRate)
                );
            }
        }
        return synthrBalance;
    }

    function balanceOfPerKey(address _account, bytes32 _collateralKey) external view returns (uint256) {
        (uint256 collateralRate, ) = exchangeRates().rateAndInvalid(_collateralKey);
        return extTokenState.collateralByIssuer(_collateralKey, _account).multiplyDecimal(collateralRate);
    }

    function getSendStakingGasFee(
        address _account,
        bytes32 _collateralKey,
        uint256 _collateralAmount,
        uint16 _destChainId
    ) external view returns (uint256) {
        bytes memory lzPayload = abi.encode(PT_DEPOSIT_COLLATERAL, abi.encodePacked(_account), _collateralKey, _collateralAmount);
        return synthrBridge().calcLZFee(lzPayload, PT_DEPOSIT_COLLATERAL, _destChainId);
    }

    function getSendBurnGasFee(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount,
        uint16 _destChainId
    ) external view returns (uint256) {
        bytes memory lzPayload = abi.encode(PT_BURN_SYNTH, abi.encodePacked(_account), _synthKey, _synthAmount);
        return synthrBridge().calcLZFee(lzPayload, PT_BURN_SYNTH, _destChainId);
    }

    function getSendTransferMargin(address _account, uint256 _marginDelta, uint16 _destChainId) external view returns (uint256) {
        bytes memory lzPayload = abi.encode(PT_TRANSFER_MARGIN_SYNTH, abi.encodePacked(_account), _marginDelta);
        return synthrBridge().calcLZFee(lzPayload, PT_TRANSFER_MARGIN_SYNTH, _destChainId);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 minAmount,
        uint16 destChainId
    ) external payable exchangeActive(sourceCurrencyKey, destinationCurrencyKey) systemActive returns (uint256 amountReceived) {
        IExchanger.ExchangeArgs memory args = IExchanger.ExchangeArgs({
            fromAccount: msg.sender,
            destAccount: msg.sender,
            sourceCurrencyKey: sourceCurrencyKey,
            destCurrencyKey: destinationCurrencyKey,
            sourceAmount: sourceAmount,
            destAmount: 0,
            fee: 0,
            reclaimed: 0,
            refunded: 0,
            destChainId: destChainId
        });
        return exchanger().exchangeAtomically{value: msg.value}(minAmount, args);
    }

    function settle(bytes32 currencyKey) external returns (uint256 reclaimed, uint256 refunded, uint256 numEntriesSettled) {
        return exchanger().settle(msg.sender, currencyKey);
    }

    function transferMargin(uint256 marginDelta) external payable issuanceActive systemActive {
        uint256 transferAmount = issuer().transferMargin(msg.sender, marginDelta);
        synthrBridge().sendTransferMargin{value: msg.value}(msg.sender, transferAmount);
        emit TransferMargin(msg.sender, transferAmount);
    }

    function burnSynths(uint256 _amount, bytes32 _synthKey) external payable issuanceActive systemActive {
        (uint256 synthAmount, , , ) = issuer().burnSynths(msg.sender, _synthKey, _amount);
        synthrBridge().sendBurn{value: msg.value}(msg.sender, _synthKey, synthAmount);
        emit BurnSynth(msg.sender, _synthKey, synthAmount);
    }

    function stakeCollateral(bytes32 _collateralKey, uint256 _collateralAmount) external payable issuanceActive systemActive {
        require(_collateralAmount > 0, "Collateral amount must be larger than zero.");
        uint256 msgValueForGas = msg.value;
        _stakingCollateral(msg.sender, msg.sender, _collateralKey, _collateralAmount);
        if (extTokenState.collateralCurrency(_collateralKey) == NULL_ADDRESS) {
            require(msg.value > _collateralAmount, "Insufficient ETH amount.");
            msgValueForGas = msg.value - _collateralAmount;
        }

        synthrBridge().sendDepositCollateral{value: msgValueForGas}(msg.sender, _collateralKey, _collateralAmount);
        return;
    }

    function _stakingCollateral(address from, address to, bytes32 _collateralKey, uint256 _collateralAmount) internal {
        require(extTokenState.collateralCurrency(_collateralKey) != address(0), "No Collateral Currency exists.");
        if (extTokenState.collateralCurrency(_collateralKey) != NULL_ADDRESS) {
            TransferHelper.safeTransferFrom(
                extTokenState.collateralCurrency(_collateralKey),
                from,
                address(extTokenState),
                _collateralAmount
            );
        } else {
            TransferHelper.safeTransferETH(address(extTokenState), _collateralAmount);
        }

        bool isSucceed = _mint(to, _collateralAmount, _collateralKey);
        require(isSucceed, "Mint Synthr failed.");
        emit StakeCollateral(from, to, _collateralKey, _collateralAmount);
    }

    function withdrawCollateral(
        address _from,
        address _to,
        bytes32 _collateralKey,
        uint256 _collateralAmount
    ) external issuanceActive systemActive onlySynthrBridge {
        require(_collateralAmount > 0, "Collateral amount must not be zero");
        require(extTokenState.collateralCurrency(_collateralKey) != address(0), "No Collateral Currency exists.");
        require(
            extTokenState.collateralByIssuer(_collateralKey, _from) >= _collateralAmount,
            "Insufficient Collateral Balance to withdraw."
        );
        extTokenState.withdrawCollateral(_to, _collateralKey, _collateralAmount);

        bool isSucceed = _burn(_from, _collateralAmount, _collateralKey);
        require(isSucceed, "Burn Synthr failed.");

        emit WithdrawCollateral(msg.sender, _collateralKey, extTokenState.collateralCurrency(_collateralKey), _collateralAmount);
    }

    // ========== EVENTS ==========
    event StakeCollateral(address indexed from, address indexed to, bytes32 collateralKey, uint256 collateralAmount);
    event WithdrawCollateral(
        address indexed from,
        bytes32 indexed collateralKey,
        address collateralCurrency,
        uint256 collateralAmount
    );
    event BurnSynth(address indexed from, bytes32 synthKey, uint256 synthAmount);
    event TransferMargin(address indexed account, uint256 transferAmount);
}