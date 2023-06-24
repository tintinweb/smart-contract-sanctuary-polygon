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

interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint256);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint256[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int256);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int256[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint256 value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint256[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int256 value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int256[] calldata values
    ) external;

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external;

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external;

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external;

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external;

    function setBytes32Value(
        bytes32 contractName,
        bytes32 record,
        bytes32 value
    ) external;

    function setBytes32Values(
        bytes32 contractName,
        bytes32[] calldata records,
        bytes32[] calldata values
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

interface ISystemSettings {
    // Views
    function waitingPeriodSecs() external view returns (uint256);

    function priceDeviationThresholdFactor() external view returns (uint256);

    function issuanceRatio() external view returns (uint256);

    function feePeriodDuration() external view returns (uint256);

    function targetThreshold() external view returns (uint256);

    function liquidationDelay() external view returns (uint256);

    function liquidationRatio() external view returns (uint256);

    function liquidationEscrowDuration() external view returns (uint256);

    function liquidationPenalty() external view returns (uint256);

    function forceLiquidationPenalty() external view returns (uint256);

    function selfLiquidationPenalty() external view returns (uint256);

    function flagReward() external view returns (uint256);

    function liquidateReward() external view returns (uint256);

    function rateStalePeriod() external view returns (uint256);

    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint256);

    function minimumStakeTime() external view returns (uint256);

    function debtSnapshotStaleTime() external view returns (uint256);

    function aggregatorWarningFlags() external view returns (address);

    function interactionDelay(address collateral) external view returns (uint256);

    function atomicMaxVolumePerBlock() external view returns (uint256);

    function atomicTwapWindow() external view returns (uint256);

    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address);

    function atomicExchangeFeeRate(bytes32 currencyKey) external view returns (uint256);

    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint256);

    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint256);

    function pureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) external view returns (bool);
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

import "./MixinResolver.sol";

// Internal references
import "../interfaces/IFlexibleStorage.sol";

contract MixinSystemSettings is MixinResolver {
    // must match the one defined SystemSettingsLib, defined in both places due to sol v0.5 limitations
    bytes32 internal constant SETTING_CONTRACT_NAME = "SystemSettings";

    bytes32 internal constant SETTING_WAITING_PERIOD_SECS = "waitingPeriodSecs";
    bytes32 internal constant SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR = "priceDeviationThresholdFactor";
    bytes32 internal constant SETTING_RATE_STALE_PERIOD = "rateStalePeriod";
    /* ========== Exchange Fees Related ========== */
    bytes32 internal constant SETTING_EXCHANGE_FEE_RATE = "exchangeFeeRate";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD = "exchangeDynamicFeeThreshold";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY = "exchangeDynamicFeeWeightDecay";
    bytes32 internal constant SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS = "exchangeDynamicFeeRounds";
    bytes32 internal constant SETTING_EXCHANGE_MAX_DYNAMIC_FEE = "exchangeMaxDynamicFee";
    /* ========== End Exchange Fees Related ========== */
    bytes32 internal constant SETTING_AGGREGATOR_WARNING_FLAGS = "aggregatorWarningFlags";
    bytes32 internal constant SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK = "atomicMaxVolumePerBlock";
    bytes32 internal constant SETTING_ATOMIC_TWAP_WINDOW = "atomicTwapWindow";
    bytes32 internal constant SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING = "atomicEquivalentForDexPricing";
    bytes32 internal constant SETTING_ATOMIC_EXCHANGE_FEE_RATE = "atomicExchangeFeeRate";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = "atomicVolConsiderationWindow";
    bytes32 internal constant SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD = "atomicVolUpdateThreshold";
    bytes32 internal constant SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED = "pureChainlinkForAtomicsEnabled";

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    struct DynamicFeeConfig {
        uint256 threshold;
        uint256 weightDecay;
        uint256 rounds;
        uint256 maxFee;
    }

    constructor(address _resolver) MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view virtual override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function getWaitingPeriodSecs() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_WAITING_PERIOD_SECS);
    }

    function getPriceDeviationThresholdFactor() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR);
    }

    function getRateStalePeriod() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_RATE_STALE_PERIOD);
    }

    /* ========== Exchange Related Fees ========== */
    function getExchangeFeeRate(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    /// @notice Get exchange dynamic fee related keys
    /// @return threshold, weight decay, rounds, and max fee
    function getExchangeDynamicFeeConfig() internal view returns (DynamicFeeConfig memory) {
        bytes32[] memory keys = new bytes32[](4);
        keys[0] = SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD;
        keys[1] = SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY;
        keys[2] = SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS;
        keys[3] = SETTING_EXCHANGE_MAX_DYNAMIC_FEE;
        uint256[] memory values = flexibleStorage().getUIntValues(SETTING_CONTRACT_NAME, keys);
        return DynamicFeeConfig({threshold: values[0], weightDecay: values[1], rounds: values[2], maxFee: values[3]});
    }

    /* ========== End Exchange Related Fees ========== */

    function getAggregatorWarningFlags() internal view returns (address) {
        return flexibleStorage().getAddressValue(SETTING_CONTRACT_NAME, SETTING_AGGREGATOR_WARNING_FLAGS);
    }

    function getAtomicMaxVolumePerBlock() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK);
    }

    function getAtomicTwapWindow() internal view returns (uint256) {
        return flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_ATOMIC_TWAP_WINDOW);
    }

    function getAtomicEquivalentForDexPricing(bytes32 currencyKey) internal view returns (address) {
        return
            flexibleStorage().getAddressValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING, currencyKey))
            );
    }

    function getAtomicExchangeFeeRate(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_EXCHANGE_FEE_RATE, currencyKey))
            );
    }

    function getAtomicVolatilityConsiderationWindow(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW, currencyKey))
            );
    }

    function getAtomicVolatilityUpdateThreshold(bytes32 currencyKey) internal view returns (uint256) {
        return
            flexibleStorage().getUIntValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD, currencyKey))
            );
    }

    function getPureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) internal view returns (bool) {
        return
            flexibleStorage().getBoolValue(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED, currencyKey))
            );
    }
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

// Internal references
import "../interfaces/IFlexibleStorage.sol";

// Libraries
import "./SafeDecimalMath.sol";

/// This library is to reduce SystemSettings contract size only and is not really
/// a proper library - so it shares knowledge of implementation details
/// Some of the setters were refactored into this library, and some setters remain in the
/// contract itself (SystemSettings)
library SystemSettingsLibLightChain {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 public constant SETTINGS_CONTRACT_NAME = "SystemSettings";

    // No more synths may be issued than the value of Synthr backing them.
    uint256 public constant MAX_ISSUANCE_RATIO = 1e18;

    uint256 public constant MAX_TARGET_THRESHOLD = 50;

    uint256 public constant RATIO_FROM_TARGET_BUFFER = 1e18; // 149% - mininimum buffer between issuance ratio and liquidation ratio

    // Exchange fee may not exceed 10%.
    uint256 public constant MAX_EXCHANGE_FEE_RATE = 1e18 / 10;

    // Minimum Stake time may not exceed 1 weeks.
    uint256 public constant MAX_MINIMUM_STAKE_TIME = 1 weeks;

    // Atomic block volume limit is encoded as uint192.
    uint256 public constant MAX_ATOMIC_VOLUME_PER_BLOCK = type(uint192).max;

    // TWAP window must be between 1 min and 1 day.
    uint256 public constant MIN_ATOMIC_TWAP_WINDOW = 60;
    uint256 public constant MAX_ATOMIC_TWAP_WINDOW = 86400;

    // Volatility consideration window must be between 1 min and 1 day.
    uint256 public constant MIN_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = 60;
    uint256 public constant MAX_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW = 86400;

    // workaround for library not supporting public constants in sol v0.5
    function contractName() external pure returns (bytes32) {
        return SETTINGS_CONTRACT_NAME;
    }

    function setWaitingPeriodSecs(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _waitingPeriodSecs
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _waitingPeriodSecs);
    }

    function setPriceDeviationThresholdFactor(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _priceDeviationThresholdFactor
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _priceDeviationThresholdFactor);
    }

    function setRateStalePeriod(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 period
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, period);
    }

    function setExchangeFeeRateForSynths(
        IFlexibleStorage flexibleStorage,
        bytes32 settingExchangeFeeRate,
        bytes32[] calldata synthKeys,
        uint256[] calldata exchangeFeeRates
    ) external {
        require(synthKeys.length == exchangeFeeRates.length, "Array lengths dont match");
        for (uint256 i = 0; i < synthKeys.length; i++) {
            require(exchangeFeeRates[i] <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
            flexibleStorage.setUIntValue(
                SETTINGS_CONTRACT_NAME,
                keccak256(abi.encodePacked(settingExchangeFeeRate, synthKeys[i])),
                exchangeFeeRates[i]
            );
        }
    }

    function setAggregatorWarningFlags(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        address _flags
    ) external {
        require(_flags != address(0), "Valid address must be given");
        flexibleStorage.setAddressValue(SETTINGS_CONTRACT_NAME, settingName, _flags);
    }

    function setAtomicMaxVolumePerBlock(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _maxVolume
    ) external {
        require(_maxVolume <= MAX_ATOMIC_VOLUME_PER_BLOCK, "Atomic max volume exceed maximum uint192");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _maxVolume);
    }

    function setAtomicTwapWindow(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 _window
    ) external {
        require(_window >= MIN_ATOMIC_TWAP_WINDOW, "Atomic twap window under minimum 1 min");
        require(_window <= MAX_ATOMIC_TWAP_WINDOW, "Atomic twap window exceed maximum 1 day");
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, _window);
    }

    function setAtomicEquivalentForDexPricing(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        address _equivalent
    ) external {
        require(_equivalent != address(0), "Atomic equivalent is 0 address");
        flexibleStorage.setAddressValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _equivalent
        );
    }

    function setAtomicExchangeFeeRate(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _exchangeFeeRate
    ) external {
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");
        flexibleStorage.setUIntValue(
            SETTINGS_CONTRACT_NAME,
            keccak256(abi.encodePacked(settingName, _currencyKey)),
            _exchangeFeeRate
        );
    }

    function setAtomicVolatilityConsiderationWindow(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _window
    ) external {
        if (_window != 0) {
            require(
                _window >= MIN_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
                "Atomic volatility consideration window under minimum 1 min"
            );
            require(
                _window <= MAX_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
                "Atomic volatility consideration window exceed maximum 1 day"
            );
        }
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _window);
    }

    function setAtomicVolatilityUpdateThreshold(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        uint256 _threshold
    ) external {
        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _threshold);
    }

    function setPureChainlinkPriceForAtomicSwapsEnabled(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        bytes32 _currencyKey,
        bool _enabled
    ) external {
        flexibleStorage.setBoolValue(SETTINGS_CONTRACT_NAME, keccak256(abi.encodePacked(settingName, _currencyKey)), _enabled);
    }

    function setExchangeMaxDynamicFee(
        IFlexibleStorage flexibleStorage,
        bytes32 settingName,
        uint256 maxFee
    ) external {
        require(maxFee != 0, "Max dynamic fee cannot be 0");
        require(maxFee <= MAX_EXCHANGE_FEE_RATE, "MAX_EXCHANGE_FEE_RATE exceeded");

        flexibleStorage.setUIntValue(SETTINGS_CONTRACT_NAME, settingName, maxFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./MixinSystemSettings.sol";
import "../interfaces/ISystemSettings.sol";
import "./SystemSettingsLibLightChain.sol";

contract SystemSettingsLightChain is Owned, MixinSystemSettings {
    // SystemSettingsLib is a way to split out the setters to reduce contract size
    using SystemSettingsLibLightChain for IFlexibleStorage;

    constructor(address _owner, address _resolver) Owned(_owner) MixinSystemSettings(_resolver) {
        // SETTING_CONTRACT_NAME is defined for the getters in MixinSystemSettings and
        // SystemSettingsLib.contractName() is a view into SystemSettingsLib of the contract name
        // that's used by the setters. They have to be equal.
        require(SETTING_CONTRACT_NAME == SystemSettingsLibLightChain.contractName(), "read and write keys not equal");
    }

    // ========== VIEWS ==========

    // backwards compatibility to having CONTRACT_NAME public constant
    // solhint-disable-next-line func-name-mixedcase
    function CONTRACT_NAME() external pure returns (bytes32) {
        return SystemSettingsLibLightChain.contractName();
    }

    // SIP-37 Fee Reclamation
    // The number of seconds after an exchange is executed that must be waited
    // before settlement.
    function waitingPeriodSecs() external view returns (uint256) {
        return getWaitingPeriodSecs();
    }

    // SIP-65 Decentralized Circuit Breaker
    // The factor amount expressed in decimal format
    // E.g. 3e18 = factor 3, meaning movement up to 3x and above or down to 1/3x and below
    function priceDeviationThresholdFactor() external view returns (uint256) {
        return getPriceDeviationThresholdFactor();
    }

    /* ========== End SIP-148 ========== */

    // How long will the ExchangeRates contract assume the rate of any asset is correct
    function rateStalePeriod() external view returns (uint256) {
        return getRateStalePeriod();
    }

    /* ========== Exchange Related Fees ========== */
    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint256) {
        return getExchangeFeeRate(currencyKey);
    }

    // SIP-184 Dynamic Fee
    /// @notice Get the dynamic fee threshold
    /// @return The dynamic fee threshold
    function exchangeDynamicFeeThreshold() external view returns (uint256) {
        return getExchangeDynamicFeeConfig().threshold;
    }

    /// @notice Get the dynamic fee weight decay per round
    /// @return The dynamic fee weight decay per round
    function exchangeDynamicFeeWeightDecay() external view returns (uint256) {
        return getExchangeDynamicFeeConfig().weightDecay;
    }

    /// @notice Get the dynamic fee total rounds for calculation
    /// @return The dynamic fee total rounds for calculation
    function exchangeDynamicFeeRounds() external view returns (uint256) {
        return getExchangeDynamicFeeConfig().rounds;
    }

    /// @notice Get the max dynamic fee
    /// @return The max dynamic fee
    function exchangeMaxDynamicFee() external view returns (uint256) {
        return getExchangeDynamicFeeConfig().maxFee;
    }

    /* ========== End Exchange Related Fees ========== */

    function aggregatorWarningFlags() external view returns (address) {
        return getAggregatorWarningFlags();
    }

    // SIP-120 Atomic exchanges
    // max allowed volume per block for atomic exchanges
    function atomicMaxVolumePerBlock() external view returns (uint256) {
        return getAtomicMaxVolumePerBlock();
    }

    // SIP-120 Atomic exchanges
    // time window (in seconds) for TWAP prices when considered for atomic exchanges
    function atomicTwapWindow() external view returns (uint256) {
        return getAtomicTwapWindow();
    }

    // SIP-120 Atomic exchanges
    // equivalent asset to use for a synth when considering external prices for atomic exchanges
    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address) {
        return getAtomicEquivalentForDexPricing(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // fee rate override for atomic exchanges into a synth
    function atomicExchangeFeeRate(bytes32 currencyKey) external view returns (uint256) {
        return getAtomicExchangeFeeRate(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // consideration window for determining synth volatility
    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint256) {
        return getAtomicVolatilityConsiderationWindow(currencyKey);
    }

    // SIP-120 Atomic exchanges
    // update threshold for determining synth volatility
    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint256) {
        return getAtomicVolatilityUpdateThreshold(currencyKey);
    }

    // SIP-198: Atomic Exchange At Pure Chainlink Price
    // Whether to use the pure Chainlink price for a given currency key
    function pureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) external view returns (bool) {
        return getPureChainlinkPriceForAtomicSwapsEnabled(currencyKey);
    }

    function setWaitingPeriodSecs(uint256 _waitingPeriodSecs) external onlyOwner {
        flexibleStorage().setWaitingPeriodSecs(SETTING_WAITING_PERIOD_SECS, _waitingPeriodSecs);
        emit WaitingPeriodSecsUpdated(_waitingPeriodSecs);
    }

    function setPriceDeviationThresholdFactor(uint256 _priceDeviationThresholdFactor) external onlyOwner {
        flexibleStorage().setPriceDeviationThresholdFactor(
            SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR,
            _priceDeviationThresholdFactor
        );
        emit PriceDeviationThresholdUpdated(_priceDeviationThresholdFactor);
    }

    function setRateStalePeriod(uint256 period) external onlyOwner {
        flexibleStorage().setRateStalePeriod(SETTING_RATE_STALE_PERIOD, period);
        emit RateStalePeriodUpdated(period);
    }

    /* ========== Exchange Fees Related ========== */
    function setExchangeFeeRateForSynths(bytes32[] calldata synthKeys, uint256[] calldata exchangeFeeRates) external onlyOwner {
        flexibleStorage().setExchangeFeeRateForSynths(SETTING_EXCHANGE_FEE_RATE, synthKeys, exchangeFeeRates);
        for (uint256 i = 0; i < synthKeys.length; i++) {
            emit ExchangeFeeUpdated(synthKeys[i], exchangeFeeRates[i]);
        }
    }

    /// @notice Set exchange dynamic fee threshold constant in decimal ratio
    /// @param threshold The exchange dynamic fee threshold
    function setExchangeDynamicFeeThreshold(uint256 threshold) external onlyOwner {
        require(threshold != 0, "Threshold cannot be 0");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD, threshold);

        emit ExchangeDynamicFeeThresholdUpdated(threshold);
    }

    /// @notice Set exchange dynamic fee weight decay constant
    /// @param weightDecay The exchange dynamic fee weight decay
    function setExchangeDynamicFeeWeightDecay(uint256 weightDecay) external onlyOwner {
        require(weightDecay != 0, "Weight decay cannot be 0");

        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY, weightDecay);

        emit ExchangeDynamicFeeWeightDecayUpdated(weightDecay);
    }

    /// @notice Set exchange dynamic fee last N rounds with minimum 2 rounds
    /// @param rounds The exchange dynamic fee last N rounds
    function setExchangeDynamicFeeRounds(uint256 rounds) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS, rounds);

        emit ExchangeDynamicFeeRoundsUpdated(rounds);
    }

    /// @notice Set max exchange dynamic fee
    /// @param maxFee The max exchange dynamic fee
    function setExchangeMaxDynamicFee(uint256 maxFee) external onlyOwner {
        flexibleStorage().setExchangeMaxDynamicFee(SETTING_EXCHANGE_MAX_DYNAMIC_FEE, maxFee);
        emit ExchangeMaxDynamicFeeUpdated(maxFee);
    }

    function setAggregatorWarningFlags(address _flags) external onlyOwner {
        flexibleStorage().setAggregatorWarningFlags(SETTING_AGGREGATOR_WARNING_FLAGS, _flags);
        emit AggregatorWarningFlagsUpdated(_flags);
    }

    function setAtomicMaxVolumePerBlock(uint256 _maxVolume) external onlyOwner {
        flexibleStorage().setAtomicMaxVolumePerBlock(SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK, _maxVolume);
        emit AtomicMaxVolumePerBlockUpdated(_maxVolume);
    }

    function setAtomicTwapWindow(uint256 _window) external onlyOwner {
        flexibleStorage().setAtomicTwapWindow(SETTING_ATOMIC_TWAP_WINDOW, _window);
        emit AtomicTwapWindowUpdated(_window);
    }

    function setAtomicEquivalentForDexPricing(bytes32 _currencyKey, address _equivalent) external onlyOwner {
        flexibleStorage().setAtomicEquivalentForDexPricing(SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING, _currencyKey, _equivalent);
        emit AtomicEquivalentForDexPricingUpdated(_currencyKey, _equivalent);
    }

    function setAtomicExchangeFeeRate(bytes32 _currencyKey, uint256 _exchangeFeeRate) external onlyOwner {
        flexibleStorage().setAtomicExchangeFeeRate(SETTING_ATOMIC_EXCHANGE_FEE_RATE, _currencyKey, _exchangeFeeRate);
        emit AtomicExchangeFeeUpdated(_currencyKey, _exchangeFeeRate);
    }

    function setAtomicVolatilityConsiderationWindow(bytes32 _currencyKey, uint256 _window) external onlyOwner {
        flexibleStorage().setAtomicVolatilityConsiderationWindow(
            SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
            _currencyKey,
            _window
        );
        emit AtomicVolatilityConsiderationWindowUpdated(_currencyKey, _window);
    }

    function setAtomicVolatilityUpdateThreshold(bytes32 _currencyKey, uint256 _threshold) external onlyOwner {
        flexibleStorage().setAtomicVolatilityUpdateThreshold(
            SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD,
            _currencyKey,
            _threshold
        );
        emit AtomicVolatilityUpdateThresholdUpdated(_currencyKey, _threshold);
    }

    function setPureChainlinkPriceForAtomicSwapsEnabled(bytes32 _currencyKey, bool _enabled) external onlyOwner {
        flexibleStorage().setPureChainlinkPriceForAtomicSwapsEnabled(
            SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED,
            _currencyKey,
            _enabled
        );
        emit PureChainlinkPriceForAtomicSwapsEnabledUpdated(_currencyKey, _enabled);
    }

    // ========== EVENTS ==========
    event WaitingPeriodSecsUpdated(uint256 waitingPeriodSecs);
    event PriceDeviationThresholdUpdated(uint256 threshold);
    event RateStalePeriodUpdated(uint256 rateStalePeriod);
    /* ========== Exchange Fees Related ========== */
    event ExchangeFeeUpdated(bytes32 synthKey, uint256 newExchangeFeeRate);
    event ExchangeDynamicFeeThresholdUpdated(uint256 dynamicFeeThreshold);
    event ExchangeDynamicFeeWeightDecayUpdated(uint256 dynamicFeeWeightDecay);
    event ExchangeDynamicFeeRoundsUpdated(uint256 dynamicFeeRounds);
    event ExchangeMaxDynamicFeeUpdated(uint256 maxDynamicFee);
    /* ========== End Exchange Fees Related ========== */
    event AggregatorWarningFlagsUpdated(address flags);
    event AtomicMaxVolumePerBlockUpdated(uint256 newMaxVolume);
    event AtomicTwapWindowUpdated(uint256 newWindow);
    event AtomicEquivalentForDexPricingUpdated(bytes32 synthKey, address equivalent);
    event AtomicExchangeFeeUpdated(bytes32 synthKey, uint256 newExchangeFeeRate);
    event AtomicVolatilityConsiderationWindowUpdated(bytes32 synthKey, uint256 newVolatilityConsiderationWindow);
    event AtomicVolatilityUpdateThresholdUpdated(bytes32 synthKey, uint256 newVolatilityUpdateThreshold);
    event PureChainlinkPriceForAtomicSwapsEnabledUpdated(bytes32 synthKey, bool enabled);
}