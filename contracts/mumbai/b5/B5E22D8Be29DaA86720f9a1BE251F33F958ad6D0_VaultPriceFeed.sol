// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./settings/VaultPriceFeedSettings.sol";
contract VaultPriceFeed is VaultPriceFeedSettings {
    constructor() public {
        gov = msg.sender;
    }
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool) public override view returns (uint256) {
        uint256 price = useV2Pricing ? getPriceV2(_token, _maximise, _includeAmmPrice) : getPriceV1(_token, _maximise, _includeAmmPrice);
        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(Constants.BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(Constants.BASIS_POINTS_DIVISOR);
            } else {
                price = price.mul(Constants.BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(Constants.BASIS_POINTS_DIVISOR);
            }
        }
        return price;
    }
    function getPriceV1(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);
        if (_includeAmmPrice && isAmmEnabled) {
            uint256 ammPrice = getAmmPrice(_token);
            if (ammPrice > 0) {
                if (_maximise && ammPrice > price) {
                    price = ammPrice;
                }
                if (!_maximise && ammPrice < price) {
                    price = ammPrice;
                }
            }
        }
        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }
        if (strictStableTokens[_token]) {
            uint256 delta = price > Constants.ONE_USD ? price.sub(Constants.ONE_USD) : Constants.ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return Constants.ONE_USD;
            }
            if (_maximise && price > Constants.ONE_USD) {
                return price;
            }
            if (!_maximise && price < Constants.ONE_USD) {
                return price;
            }
            return Constants.ONE_USD;
        }
        uint256 _spreadBasisPoints = spreadBasisPoints[_token];
        if (_maximise) {
            return price.mul(Constants.BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(Constants.BASIS_POINTS_DIVISOR);
        }
        return price.mul(Constants.BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(Constants.BASIS_POINTS_DIVISOR);
    }
    function getPriceV2(address _token, bool _maximise, bool _includeAmmPrice) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);
        if (_includeAmmPrice && isAmmEnabled) {
            price = getAmmPriceV2(_token, _maximise, price);
        }
        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }
        if (strictStableTokens[_token]) {
            uint256 delta = price > Constants.ONE_USD ? price.sub(Constants.ONE_USD) : Constants.ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return Constants.ONE_USD;
            }
            if (_maximise && price > Constants.ONE_USD) {
                return price;
            }
            if (!_maximise && price < Constants.ONE_USD) {
                return price;
            }
            return Constants.ONE_USD;
        }
        uint256 _spreadBasisPoints = spreadBasisPoints[_token];
        if (_maximise) {
            return price.mul(Constants.BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(Constants.BASIS_POINTS_DIVISOR);
        }
        return price.mul(Constants.BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(Constants.BASIS_POINTS_DIVISOR);
    }
    function getAmmPriceV2(address _token, bool _maximise, uint256 _primaryPrice) public view returns (uint256) {
        uint256 ammPrice = getAmmPrice(_token);
        if (ammPrice == 0) {
            return _primaryPrice;
        }
        uint256 diff = ammPrice > _primaryPrice ? ammPrice.sub(_primaryPrice) : _primaryPrice.sub(ammPrice);
        if (diff.mul(Constants.BASIS_POINTS_DIVISOR) < _primaryPrice.mul(spreadThresholdBasisPoints)) {
            if (favorPrimaryPrice) {
                return _primaryPrice;
            }
            return ammPrice;
        }
        if (_maximise && ammPrice > _primaryPrice) {
            return ammPrice;
        }
        if (!_maximise && ammPrice < _primaryPrice) {
            return ammPrice;
        }
        return _primaryPrice;
    }
    function getLatestPrimaryPrice(address _token) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), Errors.VAULTPRICEFEED_INVALID_PRICE_FEED);
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        int256 price = priceFeed.latestAnswer();
        require(price > 0, Errors.VAULTPRICEFEED_INVALID_PRICE);
        return uint256(price);
    }
    function getPrimaryPrice(address _token, bool _maximise) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), Errors.VAULTPRICEFEED_INVALID_PRICE_FEED);
        if (chainlinkFlags != address(0)) {
            bool isRaised = IChainlinkFlags(chainlinkFlags).getFlag(Constants.FLAG_ARBITRUM_SEQ_OFFLINE);
            if (isRaised) {
                revert(Errors.CHAINLINK_FEEDS_ARE_NOT_BEING_UPDATED);
            }
        }
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        uint256 price = 0;
        uint80 roundId = priceFeed.latestRound();
        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) { break; }
            uint256 p;
            if (i == 0) {
                int256 _p = priceFeed.latestAnswer();
                require(_p > 0, Errors.VAULTPRICEFEED_INVALID_PRICE);
                p = uint256(_p);
            } else {
                (, int256 _p, , ,) = priceFeed.getRoundData(roundId - i);
                require(_p > 0, Errors.VAULTPRICEFEED_INVALID_PRICE);
                p = uint256(_p);
            }
            if (price == 0) {
                price = p;
                continue;
            }
            if (_maximise && p > price) {
                price = p;
                continue;
            }
            if (!_maximise && p < price) {
                price = p;
            }
        }
        require(price > 0, Errors.VAULTPRICEFEED_COULD_NOT_FETCH_PRICE);
        uint256 _priceDecimals = priceDecimals[_token];
        return price.mul(Constants.PRICE_PRECISION).div(10 ** _priceDecimals);
    }
    function getSecondaryPrice(address _token, uint256 _referencePrice, bool _maximise) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) { return _referencePrice; }
        return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
    }
    function getAmmPrice(address _token) public override view returns (uint256) {
        if (_token == bnb) {
            return getPairPrice(bnbBusd, true);
        }
        if (_token == eth) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            uint256 price1 = getPairPrice(ethBnb, true);
            return price0.mul(price1).div(Constants.PRICE_PRECISION);
        }
        if (_token == btc) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            uint256 price1 = getPairPrice(btcBnb, true);
            return price0.mul(price1).div(Constants.PRICE_PRECISION);
        }
        return 0;
    }
    function getPairPrice(address _pair, bool _divByReserve0) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pair).getReserves();
        if (_divByReserve0) {
            if (reserve0 == 0) { return 0; }
            return reserve1.mul(Constants.PRICE_PRECISION).div(reserve0);
        }
        if (reserve1 == 0) { return 0; }
        return reserve0.mul(Constants.PRICE_PRECISION).div(reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(address _token, address _priceFeed, uint256 _priceDecimals, bool _isStrictStable) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "../storage/VaultPriceFeedStorage.sol";
abstract contract VaultPriceFeedSettings is VaultPriceFeedStorage {
    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
    function setChainlinkFlags(address _chainlinkFlags) external onlyGov {
        chainlinkFlags = _chainlinkFlags;
    }
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyGov {
        require(
            lastAdjustmentTimings[_token].add(Constants.MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
            Errors.VAULTPRICEFEED_ADJUSTMENT_FREQUENCY_EXCEEDED
        );
        require(_adjustmentBps <= Constants.MAX_ADJUSTMENT_BASIS_POINTS, Errors.VAULTPRICEFEED_INVALID_ADJUSTMENTBPS);
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }
    function setUseV2Pricing(bool _useV2Pricing) external override onlyGov {
        useV2Pricing = _useV2Pricing;
    }
    function setIsAmmEnabled(bool _isEnabled) external override onlyGov {
        isAmmEnabled = _isEnabled;
    }
    function setIsSecondaryPriceEnabled(bool _isEnabled) external override onlyGov {
        isSecondaryPriceEnabled = _isEnabled;
    }
    function setSecondaryPriceFeed(address _secondaryPriceFeed) external onlyGov {
        secondaryPriceFeed = _secondaryPriceFeed;
    }
    function setTokens(address _btc, address _eth, address _bnb) external onlyGov {
        btc = _btc;
        eth = _eth;
        bnb = _bnb;
    }
    function setPairs(address _bnbBusd, address _ethBnb, address _btcBnb) external onlyGov {
        bnbBusd = _bnbBusd;
        ethBnb = _ethBnb;
        btcBnb = _btcBnb;
    }
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyGov {
        require(_spreadBasisPoints <= Constants.MAX_SPREAD_BASIS_POINTS, Errors.VAULTPRICEFEED_INVALID_SPREADBASISPOINTS);
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyGov {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external override onlyGov {
        favorPrimaryPrice = _favorPrimaryPrice;
    }
    function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyGov {
        require(_priceSampleSpace > 0, Errors.VAULTPRICEFEED_INVALID_PRICESAMPLESPACE);
        priceSampleSpace = _priceSampleSpace;
    }
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyGov {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }
    function setTokenConfig(address _token, address _priceFeed, uint256 _priceDecimals, bool _isStrictStable) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "../../oracle/interfaces/IPriceFeed.sol";
import "../../oracle/interfaces/ISecondaryPriceFeed.sol";
import "../../oracle/interfaces/IChainlinkFlags.sol";
import "../../amm/interfaces/IPancakePair.sol";
import "../interfaces/IVaultPriceFeed.sol";
import "../../libraries/math/SafeMath.sol";
import "../../libraries/Errors.sol";
import "../../libraries/Constants.sol";
abstract contract VaultPriceFeedStorage is IVaultPriceFeed  {
    uint256 public spreadThresholdBasisPoints = 30;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    bool public isAmmEnabled = true;
    bool public isSecondaryPriceEnabled = true;
    bool public useV2Pricing = false;
    bool public favorPrimaryPrice = false;
    address public gov;
    address public chainlinkFlags;
    address public secondaryPriceFeed;
    address public btc;
    address public eth;
    address public bnb;
    address public bnbBusd;
    address public ethBnb;
    address public btcBnb;
    mapping (address => address) public priceFeeds;
    mapping (address => uint256) public priceDecimals;
    mapping (address => uint256) public spreadBasisPoints;
    mapping (address => bool) public strictStableTokens;
    mapping (address => uint256) public override adjustmentBasisPoints;
    mapping (address => bool) public override isAdjustmentAdditive;
    mapping (address => uint256) public lastAdjustmentTimings;
    using SafeMath for uint256;
    modifier onlyGov() {
        require(msg.sender == gov, Errors.VAULTPRICEFEED_FORBIDDEN);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
library Constants {
    string public constant USDM_TOKEN_NAME = "USD Mold";
    string public constant USDM_TOKEN_SYMBOL = "USDM";
    /* VaultPriceFeed.sol */
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;
    address constant internal FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));
    /* VaultUtils.sol */
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;

    /* Vault.sol*/
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant USDM_DECIMALS = 18;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%

    /* OrderBook.sol */
    uint256 public constant USDM_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
library Errors {
    /* Timelock Error Message*/
    string public constant Timelock_Invalid_Target = "Timelock: invalid _target";
    string public constant Timelock_Invalid_Buffer = "Timelock: invalid _buffer";
    string public constant Timelock_Buffer_Cannot_Be_Decreased = "Timelock: buffer cannot be decreased";
    string public constant Timelock_invalid_maxLeverage = "Timelock: invalid _maxLeverage";
    string public constant Timelock_invalid_fundingRateFactor = "Timelock: invalid _fundingRateFactor";
    string public constant Timelock_invalid_stableFundingRateFactor = "Timelock: invalid _stableFundingRateFactor";
    string public constant Timelock_invalid_minProfitBps = "Timelock: invalid _minProfitBps";
    string public constant Timelock_token_not_yet_whitelisted = "Timelock: token not yet whitelisted";
    string public constant TIMELOCK_INVALID_MAXGASPRICE = "Invalid _maxGasPrice";
    string public constant TIMELOCK_INVALID_LENGTHS = "Timelock: invalid lengths";
    string public constant TIMELOCK_MAXTOKENSUPPLY_EXCEEDED = "Timelock: maxTokenSupply exceeded";
    string public constant TIMELOCK_ACTION_ALREADY_SIGNALLED = "Timelock: action already signalled";
    string public constant TIMELOCK_ACTION_NOT_SIGNALLED = "Timelock: action not signalled";
    string public constant TIMELOCK_ACTION_TIME_NOT_YET_PASSED = "Timelock: action time not yet passed";
    string public constant TIMELOCK_INVALID_ACTION = "Timelock: invalid _action";
    string public constant TIMELOCK_INVALID_BUFFER = "Timelock: invalid _buffer";

    /* PriceFeed Error Message*/
    string public constant PriceFeed_forbidden = "PriceFeed: forbidden";

    /* USDM.sol*/
    string public constant USDM_FORBIDDEN = "USDM: forbidden";

    /* BasePositionManagers.sol */
    string public constant BASEPOSITIONMANAGER_MARK_PRICE_LOWER_THAN_LIMIT      = "BasePositionManager: mark price lower than limit";
    string public constant BASEPOSITIONMANAGER_MARK_PRICE_HIGHER_THAN_LIMIT     = "BasePositionManager: mark price higher than limit";
    string public constant BASEPOSITIONMANAGER_INVALID_PATH_LENGTH              = "BasePositionManager: invalid _path.length";
    string public constant BASEPOSITIONMANAGER_INSUFFICIENT_AMOUNTOUT           = "BasePositionManager: insufficient amountOut";
    string public constant BASEPOSITIONMANAGER_MAX_GLOBAL_LONGS_EXCEEDED        = "BasePositionManager: max global longs exceeded";
    string public constant BASEPOSITIONMANAGER_MAX_GLOBAL_SHORTS_EXCEEDED       = "BasePositionManager: max global shorts exceeded";
    string public constant BASEPOSITIONMANAGER_INVALID_SENDER                   = "BasePositionManager: invalid sender";

    /* PositionManager.sol */
    string public constant POSITIONMANAGER_INVALID_PATH_LENGTH                  = "PositionManager: invalid _path.length";
    string public constant POSITIONMANAGER_INVALID_PATH                         = "PositionManager: invalid _path";
    string public constant POSITIONMANAGER_LONG_DEPOSIT                         = "PositionManager: long deposit";
    string public constant POSITIONMANAGER_LONG_LEVERAGE_DECREASE               = "PositionManager: long leverage decrease";
    string public constant POSITIONMANAGER_FORBIDDEN                            = "PositionManager: forbidden";

    /* Router.sol*/
    string public constant ROUTER_FORBIDDEN                                     = "Router: forbidden";

    /* MlpManager.sol */
    string public constant MLPMANAGER_ACTION_NOT_ENABLED                        = "MlpManager: action not enabled";
    string public constant MLPMANAGER_INVALID_WEIGHT                            = "MlpManager: invalid weight";
    string public constant MLPMANAGER_INVALID_COOLDOWNDURATION                  = "MlpManager: invalid _cooldownDuration";
    string public constant MLPMANAGER_INVALID_AMOUNT                            = "MlpManager: invalid _amount";
    string public constant MLPMANAGER_INSUFFICIENT_USDM_OUTPUT                  = "MlpManager: insufficient USDM output";
    string public constant MLPMANAGER_INSUFFICIENT_MLP_OUTPUT                   = "MlpManager: insufficient MLP output";
    string public constant MLPMANAGER_INVALID_MLPAMOUNT                         = "MlpManager: invalid _mlpAmount";
    string public constant MLPMANAGER_COOLDOWN_DURATION_NOT_YET_PASSED          = "MlpManager: cooldown duration not yet passed";
    string public constant MLPMANAGER_INSUFFICIENT_OUTPUT                       = "MlpManager: insufficient output";
    string public constant MLPMANAGER_FORBIDDEN                                 = "MlpManager: forbidden";

    /* ShortsTrack.sol*/
    string public constant SHORTSTRACKER_FORBIDDEN                              = "ShortsTracker: forbidden";
    string public constant SHORTSTRACKER_INVALID_HANDLER                        = "ShortsTracker: invalid _handler";
    string public constant SHORTSTRACKER_ALREADY_MIGRATED                       = "ShortsTracker: already migrated";
    string public constant SHORTSTRACKER_OVERFLOW                               = "ShortsTracker: overflow";

    /* VaultUtils.sol*/
    string public constant VAULT_LOSSES_EXCEED_COLLATERAL                       = "Vault: losses exceed collateral";
    string public constant VAULT_FEES_EXCEED_COLLATERAL                         = "Vault: fees exceed collateral";
    string public constant VAULT_LIQUIDATION_FEES_EXCEED_COLLATERAL             = "Vault: liquidation fees exceed collateral";
    string public constant VAULT_MAXLEVERAGE_EXCEEDED                           = "Vault: maxLeverage exceeded";

    /* VaultPriceFeed.sol*/
    string public constant VAULTPRICEFEED_FORBIDDEN                             = "VaultPriceFeed: forbidden";
    string public constant VAULTPRICEFEED_ADJUSTMENT_FREQUENCY_EXCEEDED         = "VaultPriceFeed: adjustment frequency exceeded";
    string public constant VAULTPRICEFEED_INVALID_ADJUSTMENTBPS                 = "Vaultpricefeed: invalid _adjustmentBps";
    string public constant VAULTPRICEFEED_INVALID_SPREADBASISPOINTS             = "VaultPriceFeed: invalid _spreadBasisPoints";
    string public constant VAULTPRICEFEED_INVALID_PRICESAMPLESPACE              = "VaultPriceFeed: invalid _priceSampleSpace";
    string internal constant VAULTPRICEFEED_INVALID_PRICE_FEED                  = "VaultPriceFeed: invalid price feed";
    string internal constant VAULTPRICEFEED_INVALID_PRICE                       = "VaultPriceFeed: invalid price";
    string internal constant CHAINLINK_FEEDS_ARE_NOT_BEING_UPDATED              = "Chainlink feeds are not being updated";
    string internal constant VAULTPRICEFEED_COULD_NOT_FETCH_PRICE               = "VaultPriceFeed: could not fetch price";

    /* VaultInternal.sol*/
    string internal constant VAULT_POOLAMOUNT_EXCEEDED                          = "Vault: poolAmount exceeded";
    string internal constant VAULT_INSUFFICIENT_RESERVE                         = "Vault: insufficient reserve";
    string internal constant VAULT_MAX_SHORTS_EXCEEDED                          = "Vault: max shorts exceeded";
    string internal constant VAULT_POOLAMOUNT_BUFFER                            = "Vault: poolAmount < buffer";
    string internal constant VAULT_INVALID_ERRORCONTROLLER                      = "Vault: invalid errorController";

    /* Router.sol */
    string internal constant ROUTER_INVALID_SENDER                              = "Router: invalid sender";
    string internal constant ROUTER_INVALID_PATH                                = "Router: invalid _path";
    string internal constant ROUTER_MARK_PRICE_HIGHER_THAN_LIMIT                = "Router: mark price higher than limit";
    string internal constant ROUTER_MARK_PRICE_LOWER_THAN_LIMIT                 = "Router: mark price lower than limit";
    string internal constant ROUTER_INVALID_PATH_LENGTH                         = "Router: invalid _path.length";
    string internal constant ROUTER_INSUFFICIENT_AMOUNTOUT                      = "Router: insufficient amountOut";
    string internal constant ROUTER_INVALID_PLUGIN                              = "Router: invalid plugin";
    string internal constant ROUTER_PLUGIN_NOT_APPROVED                         = "Router: plugin not approved";

    /* OrderBook.sol*/
    string internal constant ORDERBOOK_FORBIDDEN                                = "OrderBook: forbidden";
    string internal constant ORDERBOOK_ALREADY_INITIALIZED                      = "OrderBook: already initialized";
    string internal constant ORDERBOOK_INVALID_SENDER                           = "OrderBook: invalid sender";
    string internal constant ORDERBOOK_INVALID_PATH_LENGTH                      = "OrderBook: invalid _path.length";
    string internal constant ORDERBOOK_INVALID_PATH                             = "OrderBook: invalid _path";
    string internal constant ORDERBOOK_INVALID_AMOUNTIN                         = "OrderBook: invalid _amountIn";
    string internal constant ORDERBOOK_INSUFFICIENT_EXECUTION_FEE               = "OrderBook: insufficient execution fee";
    string internal constant ORDERBOOK_ONLY_WETH_COULD_BE_WRAPPED               = "OrderBook: only weth could be wrapped";
    string internal constant ORDERBOOK_INCORRECT_VALUE_TRANSFERRED              = "OrderBook: incorrect value transferred";
    string internal constant ORDERBOOK_INCORRECT_EXECUTION_FEE_TRANSFERRED      = "OrderBook: incorrect execution fee transferred";
    string internal constant ORDERBOOK_NON_EXISTENT_ORDER                       = "OrderBook: non-existent order";
    string internal constant ORDERBOOK_INVALID_PRICE_FOR_EXECUTION              = "OrderBook: invalid price for execution";
    string internal constant ORDERBOOK_INSUFFICIENT_COLLATERAL                  = "OrderBook: insufficient collateral";
    string internal constant ORDERBOOK_INSUFFICIENT_AMOUNTOUT                   = "OrderBook: insufficient amountOut";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
interface IChainlinkFlags {
  function getFlag(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
interface ISecondaryPriceFeed {
    function getPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
}