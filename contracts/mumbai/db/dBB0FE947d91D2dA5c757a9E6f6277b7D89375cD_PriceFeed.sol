// SPDX-License-Identifier: UNLICENSED
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.2;

interface AggregatorV3Interface {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

contract BaseMath {
    uint public constant DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

contract CheckContract {
    /**
     * @notice Check that the account is an already deployed non-destroyed contract.
     * @dev See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     * @param _account The address of the account to be checked
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_account)
        }
        require(size != 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.2;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./SafeMath.sol";

library LiquityMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;
    uint internal constant HALF_DECIMAL_PRECISION = 5e17;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(HALF_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
        if (_minutes > 5256e5) {
            _minutes = 5256e5;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    //  _coll should be the amount of VC and _debt is debt of STAR\
    // new collateral ratio is 10**18 times the collateral ratio. (150% => 1.5e18)
    function _computeCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt != 0) {
            uint newCollRatio = _coll.mul(1e18).div(_debt);
            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./Context.sol";

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div by 0");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface IPriceFeed {
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // function fetchPrice() external returns (uint);

    function fetchPrice_v() external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

interface ITellorCaller {
    function getTellorCurrentValue(uint256 _requestId)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./Interfaces/IPriceFeed.sol";
import "./Interfaces/ITellorCaller.sol";
import "./Dependencies/AggregatorV3Interface.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/BaseMath.sol";
import "./Dependencies/LiquityMath.sol";

/*
 * PriceFeed for mainnet deployment, to be connected to Chainlink's live Collateral:USD aggregator reference
 * contract
 *
 * PriceFeed will just return the Chainlink feed price unless _chainlinkIsBroken() returns true
 * in which case it will just return lastGoodPrice
 */
contract PriceFeed is IPriceFeed {
    using SafeMath for uint256;

    string public name;

    AggregatorV3Interface public priceAggregator; // Mainnet Chainlink aggregator

    uint256 public constant DECIMAL_PRECISION = 1e18;

    // Use to convert a price answer to an 18-digit precision uint
    uint256 public constant TARGET_DIGITS = 18;

    // The last good price seen from an oracle by Preon
    uint256 public lastGoodPrice;

    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    // --- Dependency setters ---
    bool private addressSet;

    function setAddresses(address _priceAggregatorAddress, string memory _name)
        external
    {
        require(addressSet == false, "Addresses already set");
        addressSet = true;

        name = _name;

        priceAggregator = AggregatorV3Interface(_priceAggregatorAddress);

        ChainlinkResponse
            memory chainlinkResponse = _getCurrentChainlinkResponse();

        require(
            !_chainlinkIsBroken(chainlinkResponse),
            "PriceFeed: Chainlink must be working"
        );

        uint256 scaledChainlinkPrice = _scaleChainlinkPriceByDigits(
            uint256(chainlinkResponse.answer),
            chainlinkResponse.decimals
        );

        // Store an initial price from Chainlink to serve as first reference for lastGoodPrice
        _storePrice(scaledChainlinkPrice);
    }

    // --- Functions ---

    /**
     * @notice Returns the latest price obtained from the Oracle.
     * @dev Callable by anyone externally.
     *
     * Non-view function - it stores the last good price seen by Preon.
     *
     * Uses a Chainlink Oracle and checks it isn't broken.
     * If the Chainlink Oracle is broken, then returns the last good price seen
     * If Chainlink is working, it updates lastGoodPrice to the last Chainlink Response
     * and returns it.
     */
    function fetchPrice() external returns (uint256) {
        // Get current and previous price data from Chainlink
        ChainlinkResponse
            memory chainlinkResponse = _getCurrentChainlinkResponse();
        if (_chainlinkIsBroken(chainlinkResponse)) {
            // Chainlink has some issue so just return lastGoodPrice
            return lastGoodPrice;
        } else {
            uint256 newPrice = _scaleChainlinkPriceByDigits(
                uint256(chainlinkResponse.answer),
                chainlinkResponse.decimals
            );
            _storePrice(newPrice);
            return newPrice;
        }
    }

    /**
     * @notice Returns the latest price obtained from the Oracle.
     * @dev Called by Preon contracts that require a current price.
     * Also callable by anyone externally.
     *
     * View function
     *
     * Uses a Chainlink Oracle and checks it isn't broken.
     * If the Chainlink Oracle is broken, then returns the last good price seen
     * If Chainlink is working, just returns the latest Chainlink response
     */
    function fetchPrice_v() external view override returns (uint256) {
        // Get current and previous price data from Chainlink
        ChainlinkResponse
            memory chainlinkResponse = _getCurrentChainlinkResponse();
        if (_chainlinkIsBroken(chainlinkResponse)) {
            // Chainlink has some issue so just return lastGoodPrice
            return lastGoodPrice;
        } else {
            return
                _scaleChainlinkPriceByDigits(
                    uint256(chainlinkResponse.answer),
                    chainlinkResponse.decimals
                );
        }
    }

    // --- Helper functions ---

    /**
     *Chainlink is considered broken if its current round data is in any way bad
     */
    function _chainlinkIsBroken(ChainlinkResponse memory _response)
        internal
        view
        returns (bool)
    {
        // Check for response call reverted
        if (!_response.success) {
            return true;
        }
        // Check for an invalid roundId that is 0
        if (_response.roundId == 0) {
            return true;
        }
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {
            return true;
        }
        // Check for non-positive price
        if (_response.answer <= 0) {
            return true;
        }

        return false;
    }

    function _scaleChainlinkPriceByDigits(uint256 _price, uint256 _answerDigits)
        internal
        pure
        returns (uint256)
    {
        /*
         * Convert the price returned by the Chainlink oracle to an 18-digit decimal for use by Preon.
         * At date of Preon launch, Chainlink uses an 8-digit price, but we also handle the possibility of
         * future changes.
         *
         */
        uint256 price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Preon's target precision
            price = _price.div(10**(_answerDigits - TARGET_DIGITS));
        } else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Preon's target precision
            price = _price.mul(10**(TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    function _storePrice(uint256 _currentPrice) internal {
        lastGoodPrice = _currentPrice;
        emit LastGoodPriceUpdated(_currentPrice);
    }

    // --- Oracle response wrapper functions ---

    function _getCurrentChainlinkResponse()
        internal
        view
        returns (ChainlinkResponse memory chainlinkResponse)
    {
        // First, try to get current decimal precision:
        try priceAggregator.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponse.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try priceAggregator.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256, /* startedAt */
            uint256 timestamp,
            uint80 /* answeredInRound */
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
    }
}