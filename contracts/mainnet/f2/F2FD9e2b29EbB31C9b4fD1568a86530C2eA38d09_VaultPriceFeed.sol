// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _confScalingFactors
    ) external;
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "../oracle/interfaces/ISecondaryPriceFeed.sol";
import "../oracle/interfaces/IChainlinkFlags.sol";
import "../amm/interfaces/IPancakePair.sol";

pragma solidity ^0.8.0;

contract VaultPriceFeed is IVaultPriceFeed {
    using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

    // Identifier of the Sequencer offline flag on the Flags contract
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));

    address public gov;
    address public chainlinkFlags;

    bool public isAmmEnabled = true;
    bool public isSecondaryPriceEnabled = false;
    bool public useV2Pricing = false;
    bool public favorPrimaryPrice = false;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    address public secondaryPriceFeed;
    uint256 public spreadThresholdBasisPoints = 30;

    address public btc;
    address public eth;
    address public bnb;
    address public bnbBusd;
    address public ethBnb;
    address public btcBnb;

    mapping (address => address) public priceFeeds;
    mapping (address => uint256) public priceDecimals;
    mapping (address => uint256) public spreadBasisPoints;
    mapping (address => uint256) public confScalingFactors;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping (address => bool) public strictStableTokens;

    mapping (address => uint256) public override adjustmentBasisPoints;
    mapping (address => bool) public override isAdjustmentAdditive;
    mapping (address => uint256) public lastAdjustmentTimings;

    modifier onlyGov() {
        require(msg.sender == gov, "VaultPriceFeed: forbidden");
        _;
    }

    constructor() {
        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setChainlinkFlags(address _chainlinkFlags) external onlyGov {
        chainlinkFlags = _chainlinkFlags;
    }

    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyGov {
        require(
            lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
            "VaultPriceFeed: adjustment frequency exceeded"
        );
        require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
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
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyGov {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external override onlyGov {
        favorPrimaryPrice = _favorPrimaryPrice;
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyGov {
        require(_priceSampleSpace > 0, "VaultPriceFeed: invalid _priceSampleSpace");
        priceSampleSpace = _priceSampleSpace;
    }

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyGov {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }

    function setTokenConfig (
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _confScalingFactor
    ) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
        confScalingFactors[_token] = _confScalingFactor;
    }

    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool /* _useSwapPricing */) public override view returns (uint256) {
        uint256 price = useV2Pricing ? getPriceV2(_token, _maximise, _includeAmmPrice) : getPriceV1(_token, _maximise, _includeAmmPrice);

        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            } else {
                price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
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
            uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
        }

        return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
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
            uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
        }

        return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
    }

    function getAmmPriceV2(address _token, bool _maximise, uint256 _primaryPrice) public view returns (uint256) {
        uint256 ammPrice = getAmmPrice(_token);
        if (ammPrice == 0) {
            return _primaryPrice;
        }

        uint256 diff = ammPrice > _primaryPrice ? ammPrice.sub(_primaryPrice) : _primaryPrice.sub(ammPrice);
        if (diff.mul(BASIS_POINTS_DIVISOR) < _primaryPrice.mul(spreadThresholdBasisPoints)) {
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
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        IPriceFeed.PriceInfo memory priceInfo = priceFeed.latestAnswer();

        require(priceInfo.price > 0, "VaultPriceFeed: invalid price");
        return priceInfo.price;
    }

    function getPrimaryPrice(address _token, bool _maximise) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        if (chainlinkFlags != address(0)) {
            bool isRaised = IChainlinkFlags(chainlinkFlags).getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
            if (isRaised) {
                // If flag is raised we shouldn't perform any critical operations
                revert("Chainlink feeds are not being updated");
            }
        }
        
        uint256 price;
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        IPriceFeed.PriceInfo memory priceInfo = priceFeed.latestAnswer();
        uint256 scaledConf = priceInfo.conf * confScalingFactors[_token] / 1e8;
        price = _maximise ? (priceInfo.price.add(scaledConf)) : (priceInfo.price.sub(scaledConf));

        require(price > 0, "VaultPriceFeed: could not fetch price");
        uint256 _priceDecimals = priceDecimals[_token];
        return price.mul(PRICE_PRECISION).div(10 ** _priceDecimals);
    }

    function getSecondaryPrice(address _token, uint256 _referencePrice, bool _maximise) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) { return _referencePrice; }
        return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
    }

    function getAmmPrice(address _token) public override view returns (uint256) {
        if (_token == bnb) {
            // for bnbBusd, reserve0: BNB, reserve1: BUSD
            return getPairPrice(bnbBusd, true);
        }

        if (_token == eth) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for ethBnb, reserve0: ETH, reserve1: BNB
            uint256 price1 = getPairPrice(ethBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return price0.mul(price1).div(PRICE_PRECISION);
        }

        if (_token == btc) {
            uint256 price0 = getPairPrice(bnbBusd, true);
            // for btcBnb, reserve0: BTC, reserve1: BNB
            uint256 price1 = getPairPrice(btcBnb, true);
            // this calculation could overflow if (price0 / 10**30) * (price1 / 10**30) is more than 10**17
            return price0.mul(price1).div(PRICE_PRECISION);
        }

        return 0;
    }

    // if divByReserve0: calculate price as reserve1 / reserve0
    // if !divByReserve1: calculate price as reserve0 / reserve1
    function getPairPrice(address _pair, bool _divByReserve0) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pair).getReserves();
        if (_divByReserve0) {
            if (reserve0 == 0) { return 0; }
            return reserve1.mul(PRICE_PRECISION).div(reserve0);
        }
        if (reserve1 == 0) { return 0; }
        return reserve0.mul(PRICE_PRECISION).div(reserve1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainlinkFlags {
  function getFlag(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    struct PriceInfo {
        // Price
        uint256 price;
        // Confidence interval around the price
        uint256 conf;
    }

    function latestAnswer() external view returns (PriceInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISecondaryPriceFeed {
    function getPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
}