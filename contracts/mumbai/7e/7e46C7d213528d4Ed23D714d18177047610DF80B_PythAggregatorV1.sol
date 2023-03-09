pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/external/pyth/IPyth.sol";
import "../utils/MoreMath.sol";


contract PythAggregatorV1 is AggregatorV3Interface {

    mapping(uint => uint) rounds;

    uint latestRound;
    int[] answers;
    uint[] updatedAts;

    bool private lockedRound = true;
    bool private lockedAnswers = true;
    bool private lockedUpdatedAts = true;

    address _pythOracleAddr;
    bytes32 _feedId;


    constructor(address pythOracleAddr, bytes32 feedId) public {

        /*
            oracle addrs: https://docs.pyth.network/pythnet-price-feeds/evm
            
            Goerli (Ethereum testnet) 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C
            Fuji (Avalanche testnet) 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C
            Fantom testnet 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C
            Mumbai (Polygon testnet) 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C

            feed ids: https://pyth.network/developers/price-feed-ids

            MAINET

            btc/usd: 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43
            eth/usd: 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace
            matic/usd: 0x5de33a9112c2b700b8d30b8a3402c103578ccfa2765696471cc672bd5cf6ac52
            avax/usd: 0x93da3352f9f1d105fdfe4971cfa80e9dd777bfc5d0f683ebb6e1294b92137bb7

            TESTNET

            btc/usd: 0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b
            eth/usd: 0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6
            matic/usd: 0xd2c2c1f2bba8e0964f9589e060c2ee97f5e19057267ac3284caef3bd50bd2cb5
            avax/usd: 0xd7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9

        */
        _pythOracleAddr = pythOracleAddr;
        _feedId = feedId;
    }

    function decimals() override external view returns (uint8) {
        IPyth.Price memory p = IPyth(_pythOracleAddr).getPriceUnsafe(_feedId);
        return uint8(MoreMath.abs(p.expo));
    }

    function description() override external view returns (string memory) {

    }

    function version() override external view returns (uint256) {

    }

    /* SEEDING FOR INITIALIZATION BELOW */

    function setRoundIds(uint[] calldata rids) external {
        require(lockedRound == false && latestRound == 0, "already init round");
        for (uint i = 0; i < rids.length; i++) {
            rounds[rids[i]] = i;
        }

        latestRound = rids[ rids.length - 1];
        lockedRound = true;
    }

    function setAnswers(int[] calldata ans) external {
        require(lockedAnswers == false && answers.length == 0, "already init answers");
        answers = ans;
        lockedAnswers = true;
    }

    function setUpdatedAts(uint[] calldata uts) external {
        require(lockedUpdatedAts == false && updatedAts.length == 0, "already init answers");
        updatedAts = uts;
        lockedUpdatedAts = true;
    }

    /* SEEDING FOR INITIALIZATION ABOVE */

    function oracle() external view returns (address) {
        return _pythOracleAddr;
    }

    function incrementRound() external {
        appendUpdatedAt();
        appendAnswer();
        appendRoundId();
    }

    function appendRoundId() private {
        if (answers.length > 1) {
            rounds[latestRound++] = answers.length;
        } else {
            rounds[latestRound] = answers.length;
        }
    }

    function appendAnswer() private {
        IPyth.Price memory p = IPyth(_pythOracleAddr).getPriceUnsafe(_feedId);
        answers.push(p.price);
    }

    function appendUpdatedAt() private {
        IPyth.Price memory p = IPyth(_pythOracleAddr).getPriceUnsafe(_feedId);
        updatedAts.push(uint(p.publishTime));
    }

    function getRoundData(uint80 _roundId)
        override
        external
        view
        returns
    (
        uint80 roundId,
        int256 answer,
        uint256,
        uint256 updatedAt,
        uint80
    )
    {
        roundId = _roundId;
        answer = answers[rounds[_roundId]];
        updatedAt = updatedAts[rounds[_roundId]];
    }

    function latestRoundId() public view returns (uint) {
        return latestRound;
    }

    function latestRoundData()
        override
        external
        view
        returns
    (
        uint80 roundId,
        int256 answer,
        uint256,
        uint256 updatedAt,
        uint80
    )
    {
        IPyth.Price memory p = IPyth(_pythOracleAddr).getPriceUnsafe(_feedId);

        roundId = uint80(latestRound);
        answer = p.price;
        updatedAt = uint(p.publishTime);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
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
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
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
     * opsymbol (which leaves remaining gas untouched) while Solidity uses an
     * invalid opsymbol to revert (consuming all remaining gas).
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
     * opsymbol (which leaves remaining gas untouched) while Solidity uses an
     * invalid opsymbol to revert (consuming all remaining gas).
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

pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./FixedPointMathLib.sol";

library MoreMath {

    using SafeMath for uint;
    using SignedSafeMath for int;

    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant PI = 3_141592653589793238;
    int256 internal constant SQRT_2PI = 2_506628274631000502;
    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant NEGATIVE_TWO = -2e18;
    int256 internal constant SQRT2 = 1_414213562373095048; // √2 with 18 decimals of precision.
    int256 internal constant ERFC_A = 1_265512230000000000;
    int256 internal constant ERFC_B = 1_000023680000000000;
    int256 internal constant ERFC_C = 374091960000000000; // 1e-1
    int256 internal constant ERFC_D = 96784180000000000; // 1e-2
    int256 internal constant ERFC_E = -186288060000000000; // 1e-1
    int256 internal constant ERFC_F = 278868070000000000; // 1e-1
    int256 internal constant ERFC_G = -1_135203980000000000;
    int256 internal constant ERFC_H = 1_488515870000000000;
    int256 internal constant ERFC_I = -822152230000000000; // 1e-1
    int256 internal constant ERFC_J = 170872770000000000; // 1e-1
    int256 internal constant IERFC_A = -707110000000000000; // 1e-1
    int256 internal constant IERFC_B = 2_307530000000000000;
    int256 internal constant IERFC_C = 270610000000000000; // 1e-1
    int256 internal constant IERFC_D = 992290000000000000; // 1e-1
    int256 internal constant IERFC_E = 44810000000000000; // 1e-2
    int256 internal constant IERFC_F = 1_128379167095512570;

    //see: https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity

    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    int256 internal constant SCALE = 1e18;

    int256 internal constant OLD_PI = 3_141592653589793238;

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function old_log2(int256 x) internal pure returns (int256 result) {
        require(x > 0);
        // This works because log2(x) = -log2(1/x).
        int256 sign;
        if (x >= SCALE) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            assembly {
                x := div(1000000000000000000000000000000000000, x)
            }
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = mostSignificantBit(uint256(x / SCALE));

        // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
        // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
        result = int256(n) * SCALE;

        // This is y = x * 2^(-n).
        int256 y = x >> n;

        // If y = 1, the fractional part is zero.
        if (y == SCALE) {
            return result * sign;
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
            y = (y * y) / SCALE;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= 2 * SCALE) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result *= sign;
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        result = (old_log2(x) * SCALE) / LOG2_E;
    }

    /*
     * notice Approximation of the Complimentary Error Function.
     * Related to the Error Function: `erfc(x) = 1 - erf(x)`.
     * Both cumulative distribution and error functions are integrals
     * which cannot be expressed in elementary terms. They are called special functions.
     * The error and complimentary error functions have numerical approximations
     * which is what is used in this library to compute the cumulative distribution function.
     *
     *  dev This is a special function with its own identities.
     * Identity: `erfc(-x) = 2 - erfc(x)`.
     * Special Values:
     * erfc(-infinity)  =   2
     * erfc(0)          =   1
     * erfc(infinity)   =   0
     *
     * custom:epsilon Fractional error less than 1.2e-7.
     * custom:source Numerical Recipes in C 2e p221.
     * custom:source https://mathworld.wolfram.com/Erfc.html.
     */
    function erfc(int256 input) internal pure returns (int256 output) {
        uint256 z = abs(input);
        int256 t;
        int256 step;
        int256 k;
        assembly {
            let quo := sdiv(mul(z, ONE), TWO) // 1 / (1 + z / 2).
            let den := add(ONE, quo)
            t := sdiv(SCALAR_SQRD, den)

            function muli(pxn, pxd) -> res {
                res := sdiv(mul(pxn, pxd), ONE)
            }

            {
                step := add(
                    ERFC_F,
                    muli(
                        t,
                        add(
                            ERFC_G,
                            muli(
                                t,
                                add(
                                    ERFC_H,
                                    muli(t, add(ERFC_I, muli(t, ERFC_J)))
                                )
                            )
                        )
                    )
                )
            }
            {
                step := muli(
                    t,
                    add(
                        ERFC_B,
                        muli(
                            t,
                            add(
                                ERFC_C,
                                muli(
                                    t,
                                    add(
                                        ERFC_D,
                                        muli(t, add(ERFC_E, muli(t, step)))
                                    )
                                )
                            )
                        )
                    )
                )
            }

            k := add(sub(mul(SIGN, muli(z, z)), ERFC_A), step)
        }

        int256 expWad = FixedPointMathLib.expWad(k);
        int256 r;
        assembly {
            r := sdiv(mul(t, expWad), ONE)
            switch iszero(slt(input, 0))
            case 0 {
                output := sub(TWO, r)
            }
            case 1 {
                output := r
            }
        }
    }

    /**
     * notice Approximation of the Cumulative Distribution Function.
     *
     * dev Equal to `D(x) = 0.5[ 1 + erf((x - µ) / σ√2)]`.
     * Only computes cdf of a distribution with µ = 0 and σ = 1.
     *
     * custom:error Maximum error of 1.2e-7.
     * custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     */
    function cdf(int256 x) internal pure returns (int256 z) {
        int256 negated;
        assembly {
            let res := sdiv(mul(x, ONE), SQRT2)
            negated := add(not(res), 1)
        }

        int256 _erfc = erfc(negated);
        assembly {
            z := sdiv(mul(ONE, _erfc), TWO)
        }
    }

    /*
     * notice Approximation of the Probability Density Function.
     *
     * dev Equal to `Z(x) = (1 / σ√2π)e^( (-(x - µ)^2) / 2σ^2 )`.
     * Only computes pdf of a distribution with µ = 0 and σ = 1.
     *
     * custom:error Maximum error of 1.2e-7.
     * custom:source https://mathworld.wolfram.com/ProbabilityDensityFunction.html.
     */
    function pdf(int256 x) internal pure returns (int256 z) {
        int256 e;
        assembly {
            e := sdiv(mul(add(not(x), 1), x), TWO) // (-x * x) / 2.
        }
        e = FixedPointMathLib.expWad(e);

        assembly {
            z := sdiv(mul(e, ONE), SQRT_2PI)
        }
    }


    // rounds "v" considering a base "b"
    function round(uint v, uint b) internal pure returns (uint) {

        return v.div(b).add((v % b) >= b.div(2) ? 1 : 0);
    }

    // calculates {[(n/d)^e]*f}
    function powAndMultiply(uint n, uint d, uint e, uint f) internal pure returns (uint) {
        
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return f.mul(n).div(d);
        } else {
            uint p = powAndMultiply(n, d, e.div(2), f);
            p = p.mul(p).div(f);
            if (e.mod(2) == 1) {
                p = p.mul(n).div(d);
            }
            return p;
        }
    }

    // calculates (n^e)
    function pow(uint n, uint e) internal pure returns (uint) {
        
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return n;
        } else {
            uint p = pow(n, e.div(2));
            p = p.mul(p);
            if (e.mod(2) == 1) {
                p = p.mul(n);
            }
            return p;
        }
    }

    // calculates {n^(e/b)}
    function powDecimal(uint n, uint e, uint b) internal pure returns (uint v) {
        
        if (e == 0) {
            return b;
        }

        if (e > b) {
            return n.mul(powDecimal(n, e.sub(b), b)).div(b);
        }

        v = b;
        uint f = b;
        uint aux = 0;
        uint rootN = n;
        uint rootB = sqrt(b);
        while (f > 1) {
            f = f.div(2);
            rootN = sqrt(rootN).mul(rootB);
            if (aux.add(f) < e) {
                aux = aux.add(f);
                v = v.mul(rootN).div(b);
            }
        }
    }
    
    // calculates ceil(n/d)
    function divCeil(uint n, uint d) internal pure returns (uint v) {
        
        v = n.div(d);
        if (n.mod(d) > 0) {
            v = v.add(1);
        }
    }
    
    // calculates the square root of "x" and multiplies it by "f"
    function sqrtAndMultiply(uint x, uint f) internal pure returns (uint y) {
    
        y = sqrt(x.mul(1e18)).mul(f).div(1e9);
    }
    
    // calculates the square root of "x"
    function sqrt(uint x) internal pure returns (uint y) {
    
        uint z = (x.div(2)).add(1);
        y = x;
        while (z < y) {
            y = z;
            z = (x.div(z).add(z)).div(2);
        }
    }

    // calculates the standard deviation
    function std(int[] memory array) internal pure returns (uint _std) {

        int avg = sum(array).div(int(array.length));
        uint x2 = 0;
        for (uint i = 0; i < array.length; i++) {
            int p = array[i].sub(avg);
            x2 = x2.add(uint(p.mul(p)));
        }
        _std = sqrt(x2 / array.length);
    }

    function sum(int[] memory array) internal pure returns (int _sum) {

        for (uint i = 0; i < array.length; i++) {
            _sum = _sum.add(array[i]);
        }
    }

    function abs(int a) internal pure returns (uint) {

        return uint(a < 0 ? -a : a);
    }
    
    function max(int a, int b) internal pure returns (int) {
        
        return a > b ? a : b;
    }
    
    function max(uint a, uint b) internal pure returns (uint) {
        
        return a > b ? a : b;
    }
    
    function min(int a, int b) internal pure returns (int) {
        
        return a < b ? a : b;
    }
    
    function min(uint a, uint b) internal pure returns (uint) {
        
        return a < b ? a : b;
    }

    function toString(uint v) internal pure returns (string memory str) {

        str = toString(v, true);
    }
    
    function toString(uint v, bool scientific) internal pure returns (string memory str) {

        if (v == 0) {
            return "0";
        }

        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }

        uint zeros = 0;
        if (scientific) {
            for (uint k = 0; k < i; k++) {
                if (reversed[k] == '0') {
                    zeros++;
                } else {
                    break;
                }
            }
        }

        uint len = i - (zeros > 2 ? zeros : 0);
        bytes memory s = new bytes(len);
        for (uint j = 0; j < len; j++) {
            s[j] = reversed[i - j - 1];
        }

        str = string(s);

        if (scientific && zeros > 2) {
            str = string(abi.encodePacked(s, "e", toString(zeros, false)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }

    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
        returns
    (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
        external
        view
        returns
    (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}