/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// File: contracts/Const.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

library Const {
    uint256 public constant ONE                       = 10**18;

    uint256 public constant MIN_BOUND_TOKENS           = 2;
    uint256 public constant MAX_BOUND_TOKENS           = 8;

    uint256 public constant MIN_FEE                    = ONE / 10**6;
    uint256 public constant BASE_FEE                   = 25 * ONE / 10**5;
    uint256 public constant MAX_FEE                    = ONE / 10;
    uint256 public constant EXIT_FEE                   = 0;

    uint80 public constant MIN_WEIGHT                  = uint80(ONE);
    uint80 public constant MAX_WEIGHT                  = uint80(ONE * 50);
    uint80 public constant MAX_TOTAL_WEIGHT            = uint80(ONE * 50);
    uint256 public constant MIN_BALANCE                = ONE / 10**12;

    uint256 public constant INIT_POOL_SUPPLY           = ONE * 100;

    uint256 public constant MIN_POW_BASE              = 1 wei;
    uint256 public constant MAX_POW_BASE              = (2 * ONE) - 1 wei;
    uint256 public constant POW_PRECISION             = ONE / 10**10;

    uint public constant MAX_IN_RATIO                  = ONE / 2;
    uint public constant MAX_OUT_RATIO                 = (ONE / 3) + 1 wei;

    uint64 public constant BASE_Z                      = uint64(6 * ONE);

    uint256 public constant MIN_HORIZON                = 1 * ONE;
    uint256 public constant BASE_HORIZON               = 5 * ONE;

    uint8 public constant MIN_LOOKBACK_IN_ROUND        = 1;
    uint8 public constant BASE_LOOKBACK_IN_ROUND       = 5;
    uint8 public constant MAX_LOOKBACK_IN_ROUND        = 100;

    uint256 public constant MIN_LOOKBACK_IN_SEC        = 1;
    uint256 public constant BASE_LOOKBACK_IN_SEC       = 3600;

    uint256 public constant MIN_MAX_PRICE_UNPEG_RATIO  = ONE + ONE / 800;
    uint256 public constant BASE_MAX_PRICE_UNPEG_RATIO = ONE + ONE / 40;
    uint256 public constant MAX_MAX_PRICE_UNPEG_RATIO  = ONE + ONE / 10;

    uint64 public constant PAUSE_WINDOW                = 86400 * 60;

    uint256 public constant FALLBACK_SPREAD            = 3 * ONE / 1000;

    uint256 public constant ORACLE_TIMEOUT             = 2 * 60;

    uint8 public constant MIN_LOOKBACK_STEP_IN_ROUND   = 1;
    uint8 public constant LOOKBACK_STEP_IN_ROUND       = 4;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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

// File: contracts/interfaces/IPoolHelpers/IPoolToken.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title Contains the external methods implemented by PoolToken
*/
interface IPoolToken is IERC20 {
    
    /**
    * @notice Returns token's name
    */
    function name() external pure returns (string memory name);

    /**
    * @notice Returns token's symbol
    */
    function symbol() external pure returns (string memory symbol);
    
    /**
    * @notice Returns token's decimals
    */
    function decimals() external pure returns(uint8 decimals);

    /**
    * @notice Increases an address approval by the input amount
    */
    function increaseApproval(address dst, uint256 amt) external returns (bool);

    /**
    * @notice Decreases an address approval by the input amount
    */
    function decreaseApproval(address dst, uint256 amt) external returns (bool);

}

// File: contracts/Errors.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
 * @author Forked from contracts developed by Balancer Labs and adapted by Swaap Labs
 */
library Err {

    uint256 internal constant REENTRY = 0;
    uint256 internal constant NOT_FINALIZED = 1;
    uint256 internal constant NOT_BOUND = 2;
    uint256 internal constant NOT_CONTROLLER = 3;
    uint256 internal constant IS_FINALIZED = 4;
    uint256 internal constant MATH_APPROX = 5;
    uint256 internal constant NOT_FACTORY = 6;
    uint256 internal constant FACTORY_CONTROL_REVOKED = 7;
    uint256 internal constant LIMIT_IN = 8;
    uint256 internal constant LIMIT_OUT = 9;
    uint256 internal constant SWAP_NOT_PUBLIC = 10;
    uint256 internal constant BAD_LIMIT_PRICE = 11;
    uint256 internal constant NOT_ADMIN = 12;
    uint256 internal constant NULL_CONTROLLER = 13;
    uint256 internal constant MIN_FEE = 14;
    uint256 internal constant MAX_FEE = 15;
    uint256 internal constant NON_POSITIVE_PRICE = 16;
    uint256 internal constant NOT_POOL = 17;
    uint256 internal constant MIN_TOKENS = 18;
    uint256 internal constant INSUFFICIENT_BALANCE = 19;
    uint256 internal constant NOT_PENDING_SWAAPLABS = 20;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 21;
    uint256 internal constant MIN_HORIZON = 22;
    uint256 internal constant MAX_HORIZON = 23;
    uint256 internal constant MIN_LB_PERIODS = 24;
    uint256 internal constant MAX_LB_PERIODS = 25;
    uint256 internal constant MIN_LB_SECS = 26;
    // uint256 internal constant MAX_LB_SECS = 27;
    uint256 internal constant IS_BOUND = 28;
    uint256 internal constant MAX_TOKENS = 29;
    uint256 internal constant MIN_WEIGHT = 30;
    uint256 internal constant MAX_WEIGHT = 31;
    uint256 internal constant MIN_BALANCE = 32;
    uint256 internal constant MAX_TOTAL_WEIGHT = 33;
    uint256 internal constant NOT_SWAAPLABS = 34;
    uint256 internal constant NULL_ADDRESS = 35;
    uint256 internal constant PAUSED_FACTORY = 36;
    uint256 internal constant X_OUT_OF_BOUNDS = 37;
    uint256 internal constant Y_OUT_OF_BOUNDS = 38;
    uint256 internal constant POW_BASE_TOO_LOW = 39;
    uint256 internal constant POW_BASE_TOO_HIGH = 40;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 41;
    uint256 internal constant INVALID_EXPONENT = 42;
    uint256 internal constant OUT_OF_BOUNDS = 43;
    uint256 internal constant MAX_PRICE_UNPEG_RATIO = 44;
    uint256 internal constant PAUSE_WINDOW_EXCEEDED = 45;
    // uint256 internal constant MAX_PRICE_DELAY_SEC = 46;
    uint256 internal constant NOT_PENDING_CONTROLLER = 47;
    uint256 internal constant EXCEEDED_ORACLE_TIMEOUT = 48;
    uint256 internal constant NEGATIVE_PRICE = 49;
    uint256 internal constant BINDED_TOKENS = 50;
    uint256 internal constant PENDING_NEW_CONTROLLER = 51;
    uint256 internal constant UNEXPECTED_BALANCE = 52;
    uint256 internal constant MIN_LB_STEP_PERIODS = 53;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 54;
    uint256 internal constant MIN_MAX_PRICE_UNPEG_RATIO = 55;
    uint256 internal constant MAX_MAX_PRICE_UNPEG_RATIO = 56;
    uint256 internal constant MAX_IN_RATIO = 57;
    uint256 internal constant MAX_OUT_RATIO = 58;
}

/**
* @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 99 are
* supported.
*/
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}


/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 99 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert uint256 based on the error code, with the following format:
    // 'SWAAP#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 00 to 99).
    //
    // We don't have revert uint256s embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual uint256 characters.
    //
    // The dynamic uint256 creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-99
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full uint256. The SWAAP# part is a known constant
        // (0x535741415023): we simply shift this by 16 (to provide space for the 2 bytes of the error code), and add
        // the characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 192 bits (256 minus the length of the uint256, 8 characters * 8
        // bits per character = 64) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(192, add(0x5357414150230000, add(units, shl(8, tenths))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ uint256 location offset ] [ uint256 length ] [ uint256 contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(uint256) function. We
        // also write zeroes to the next 29 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the uint256, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The uint256 length is fixed: 8 characters.
        mstore(0x24, 8)
        // Finally, the uint256 itself is stored.
        mstore(0x44, revertReason)

        // Even if the uint256 is only 8 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

// File: contracts/PoolToken.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.




// Highly opinionated token implementation

contract PoolToken is IPoolToken {

    mapping(address => uint256)                   internal _balance;
    mapping(address => mapping(address=>uint256)) internal _allowance;
    uint256 internal _totalSupply;

    function _mint(uint256 amt) internal {
        _balance[address(this)] = _balance[address(this)] + amt;
        _totalSupply = _totalSupply + amt;
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        _balance[address(this)] = _balance[address(this)] - amt;
        _totalSupply = _totalSupply - amt;
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint256 amt) internal {
        _require(dst != address(0), Err.NULL_ADDRESS);
        
        uint256 fromBalance = _balance[src];
        _require(fromBalance >= amt, Err.INSUFFICIENT_BALANCE);
        unchecked {
            _balance[src] = fromBalance - amt;
        }
        _balance[dst] += amt;

        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }

    string constant private _name     = "Swaap Pool Token";
    string constant private _symbol   = "SPT";
    uint8  constant private _decimals = 18;

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns(uint8) {
        return _decimals;
    }


    function allowance(address src, address dst) external view returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = _allowance[msg.sender][dst] + amt;
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = oldValue - amt;
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amt) external returns (bool) {
        if (msg.sender != src && _allowance[src][msg.sender] != type(uint256).max) {
            uint256 currentAllowance = _allowance[src][msg.sender];
            _require(currentAllowance >= amt, Err.INSUFFICIENT_ALLOWANCE);
            unchecked {
                _allowance[src][msg.sender] = currentAllowance - amt;
            }
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        _move(src, dst, amt);
        return true;
    }
}

// File: contracts/Num.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.




library Num {

    function toi(uint256 a)
        internal pure
        returns (uint256)
    {
        return a / Const.ONE;
    }

    function floor(uint256 a)
        internal pure
        returns (uint256)
    {
        return toi(a) * Const.ONE;
    }

    function subSign(uint256 a, uint256 b)
        internal pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c0 = a * b;
        uint256 c1 = c0 + (Const.ONE / 2);
        uint256 c2 = c1 / Const.ONE;
        return c2;
    }

    function mulTruncated(uint256 a, uint256 b)
    internal pure
    returns (uint256)
    {
        uint256 c0 = a * b;
        return c0 / Const.ONE;
    }

    function div(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c0 = a * Const.ONE;
        uint256 c1 = c0 + (b / 2);
        uint256 c2 = c1 / b;
        return c2;
    }

    function divTruncated(uint256 a, uint256 b)
    internal pure
    returns (uint256)
    {
        uint256 c0 = a * Const.ONE;
        return c0 / b;
    }

    // DSMath.wpow
    function powi(uint256 a, uint256 n)
        internal pure
        returns (uint256)
    {
        uint256 z = n % 2 != 0 ? a : Const.ONE;

        for (n /= 2; n != 0; n /= 2) {
            a = mul(a, a);

            if (n % 2 != 0) {
                z = mul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `powi` for `b^e` and `powK` for k iterations
    // of approximation of b^0.w
    function pow(uint256 base, uint256 exp)
        internal pure
        returns (uint256)
    {
        _require(base >= Const.MIN_POW_BASE, Err.POW_BASE_TOO_LOW);
        _require(base <= Const.MAX_POW_BASE, Err.POW_BASE_TOO_HIGH);

        uint256 whole  = floor(exp);
        uint256 remain = exp - whole;

        uint256 wholePow = powi(base, toi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = powApprox(base, remain, Const.POW_PRECISION);
        return mul(wholePow, partialResult);
    }

    function powApprox(uint256 base, uint256 exp, uint256 precision)
        internal pure
        returns (uint256)
    {
        // term 0:
        uint256 a     = exp;
        (uint256 x, bool xneg)  = subSign(base, Const.ONE);
        uint256 term = Const.ONE;
        uint256 sum   = term;
        bool negative = false;


        // term(k) = numer / denom 
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * Const.ONE;
            (uint256 c, bool cneg) = subSign(a, bigK - Const.ONE);
            term = mul(term, mul(c, x));
            term = div(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum -= term;
            } else {
                sum += term;
            }
        }

        return sum;
    }

    /**
    * @notice Computes the division of 2 int256 with ONE precision
    * @dev Converts inputs to uint256 if needed, and then uses div(uint256, uint256)
    * @param a The int256 representation of a floating point number with ONE precision
    * @param b The int256 representation of a floating point number with ONE precision
    * @return b The division of 2 int256 with ONE precision
    */
    function divInt256(int256 a, int256 b) internal pure returns (int256) {
        if (a < 0) {
            if (b < 0) {
                return int256(div(uint256(-a), uint256(-b))); // both negative
            } else {
                return -int256(div(uint256(-a), uint256(b))); // a < 0, b >= 0
            }
        } else {
            if (b < 0) {
                return -int256(div(uint256(a), uint256(-b))); // a >= 0, b < 0
            } else {
                return int256(div(uint256(a), uint256(b))); // both positive
            }
        }
    }

    function positivePart(int256 value) internal pure returns (uint256) {
        if (value <= 0) {
            return uint256(0);
        }
        return uint256(value);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

}

// File: contracts/LogExpMath.sol

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x < 2**255, Err.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Err.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Err.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Err.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Err.OUT_OF_BOUNDS);
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// File: contracts/structs/Struct.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



contract Struct {

    struct TokenGlobal {
        TokenRecord info;
        LatestRound latestRound;
    }

    struct LatestRound {
        address oracle;
        uint80  roundId;
        uint256 price;
        uint256 timestamp;
    }

    struct OracleState {
        address oracle;
        uint256 price;
    }

    struct HistoricalPricesParameters {
        uint8   lookbackInRound;
        uint256 lookbackInSec;
        uint256 timestamp;
        uint8   lookbackStepInRound;
    }
    
    struct HistoricalPricesData {
        uint256   startIndex;
        uint256[] timestamps;
        uint256[] prices;
    }
    
    struct SwapResult {
        uint256 amount;
        uint256 spread;
        uint256 taxBaseIn;
    }

    struct PriceResult {
        uint256 spotPriceBefore;
        uint256 spotPriceAfter;
        uint256 priceIn;
        uint256 priceOut;
    }

    struct GBMEstimation {
        int256  mean;
        uint256 variance;
        bool    success;
    }

    struct TokenRecord {
        uint8 decimals; // token decimals + oracle decimals
        uint256 balance;
        uint256 weight;
    }

    struct SwapParameters {
        uint256 amount;
        uint256 fee;
        uint256 fallbackSpread;
    }

    struct JoinExitSwapParameters {
        uint256 amount;
        uint256 fee;
        uint256 fallbackSpread;
        uint256 poolSupply;
    }

    struct GBMParameters {
        uint256 z;
        uint256 horizon;
    }

}

// File: contracts/ChainlinkUtils.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.







library ChainlinkUtils {

    /**
    * @notice Retrieves the oracle latest price, its decimals and description
    * @dev We consider the token price to be > 0
    * @param oracle The price feed oracle's address
    * @return The latest price's value
    * @return The latest price's number of decimals
    * @return The oracle description
    */
    function getTokenLatestPrice(address oracle) internal view returns (uint256, uint8, string memory) {
        AggregatorV3Interface feed = AggregatorV3Interface(oracle);
        (, int256 latestPrice, , uint256 latestTimestamp,) = feed.latestRoundData();
        // we assume that block.timestamp >= latestTimestamp, else => revert
        _require(block.timestamp - latestTimestamp <= Const.ORACLE_TIMEOUT, Err.EXCEEDED_ORACLE_TIMEOUT);
        _require(latestPrice > 0, Err.NON_POSITIVE_PRICE);
        return (uint256(latestPrice), feed.decimals(), feed.description()); // we consider the token price to be > 0
    }

    function getLatestRound(address oracle) internal view returns (Struct.LatestRound memory) {
        (
            uint80 latestRoundId, int256 latestPrice, , uint256 latestTimestamp,
        ) = AggregatorV3Interface(oracle).latestRoundData();
        // we assume that block.timestamp >= latestTimestamp, else => revert
        _require(block.timestamp - latestTimestamp <= Const.ORACLE_TIMEOUT, Err.EXCEEDED_ORACLE_TIMEOUT);
        _require(latestPrice > 0, Err.NON_POSITIVE_PRICE);
        return Struct.LatestRound(
            oracle,
            latestRoundId,
            uint256(latestPrice),
            latestTimestamp
        );
    }

    /**
    * @notice Retrieves historical data from round id.
    * @dev Special cases:
    * - if retrieved price is negative --> fails
    * - if no data can be found --> returns (0,0)
    * @param oracle The price feed oracle
    * @param _roundId The the round of interest ID
    * @return The round price
    * @return The round timestamp
    */
    function getRoundData(address oracle, uint80 _roundId) internal view returns (uint256, uint256) {
        try AggregatorV3Interface(oracle).getRoundData(_roundId) returns (
            uint80 ,
            int256 _price,
            uint256 ,
            uint256 _timestamp,
            uint80
        ) {
            _require(_price >= 0, Err.NEGATIVE_PRICE);
            return (uint256(_price), _timestamp);
        } catch {}
        return (0, 0);
    }


    /**
    * @notice Computes the price of token 2 in terms of token 1
    * @param price_1 The latest price data for token 1
    * @param decimals_1 The sum of the decimals of token 1 its oracle
    * @param price_2 The latest price data for token 2
    * @param decimals_2 The sum of the decimals of token 2 its oracle
    * @return The last price of token 2 divded by the last price of token 1
    */
    function getTokenRelativePrice(
        uint256 price_1, uint8 decimals_1,
        uint256 price_2, uint8 decimals_2
    )
    internal
    pure
    returns (uint256) {
        // we consider tokens price to be > 0
        if (decimals_1 > decimals_2) {
            return Num.div(
                Num.mul(price_2, (10**(decimals_1 - decimals_2))*Const.ONE),
                price_1
            );
        } else if (decimals_1 < decimals_2) {
            return Num.div(
                Num.div(price_2, price_1),
                (10**(decimals_2 - decimals_1))*Const.ONE
            );
        } else { // decimals_1 == decimals_2
            return Num.div(price_2, price_1);
         }
    }

    /**
    * @notice Computes the previous price of tokenIn in terms of tokenOut 's upper bound
    * @param latestRound_1 The token_1's latest round
    * @param decimals_1 The sum of the decimals of token 1 its oracle 
    * @param latestRound_2 The token_2's latest round
    * @param decimals_2 The sum of the decimals of token 2 its oracle
    * @return The ratio of token 2 and token 1 values if well defined, else 0
    */
    function getMaxRelativePriceInLastBlock(
        Struct.LatestRound memory latestRound_1,
        uint8 decimals_1,
        Struct.LatestRound memory latestRound_2,
        uint8 decimals_2
    ) internal view returns (uint256) {
        
        uint256 minPrice_1 = latestRound_1.price;
        {
            uint256 timestamp_1  = latestRound_1.timestamp;
            uint256 temp_price_1;
            uint80  roundId_1    = latestRound_1.roundId;
            address oracle_1     = latestRound_1.oracle;

            while (timestamp_1 == block.timestamp) {
                --roundId_1;
                (temp_price_1, timestamp_1) = ChainlinkUtils.getRoundData(
                    oracle_1, roundId_1
                );
                if (temp_price_1 == 0) {
                    return 0;
                }
                if (temp_price_1 < minPrice_1) {
                    minPrice_1 = temp_price_1;
                }
            }
        }

        uint maxPrice_2 = latestRound_2.price;
        {
            uint256 timestamp_2  = latestRound_2.timestamp;
            uint256 temp_price_2;
            uint80  roundId_2    = latestRound_2.roundId;
            address oracle_2     = latestRound_2.oracle;

            while (timestamp_2 == block.timestamp) {
                --roundId_2;
                (temp_price_2, timestamp_2) = ChainlinkUtils.getRoundData(
                    oracle_2, roundId_2
                );
                if (temp_price_2 == 0) {
                    return 0;
                }
                if (temp_price_2 > maxPrice_2) {
                    maxPrice_2 = temp_price_2;
                }
            }
        }

        return getTokenRelativePrice(
            minPrice_1, decimals_1,
            maxPrice_2, decimals_2
        );
    }

}

// File: contracts/GeometricBrownianMotionOracle.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.







/**
* @title Library in charge of historical prices statistics computations
* @author borelien
* @notice This library implements a method to retrieve the mean/variance of a given pair of assets, from Chainlink data
* @dev Because Chainlink data feeds' samplings are usually sparse and with varying time spacings, the estimation
* of mean / variance objects are only approximations.
*/
library GeometricBrownianMotionOracle {

    /**
    * @notice Gets asset-pair approximate historical return's mean and variance
    * @param oracleIn The address of tokenIn's oracle
    * @param oracleOut The address of tokenOut's oracle
    * @param hpParameters The parameters for historical prices retrieval
    * @return gbmEstimation The asset-pair historical return's mean and variance
    */
    function getParametersEstimation(
        address oracleIn,
        address oracleOut,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    external view returns (Struct.GBMEstimation memory gbmEstimation) {
        Struct.LatestRound memory latestRoundIn = ChainlinkUtils.getLatestRound(oracleIn);
        Struct.LatestRound memory latestRoundOut = ChainlinkUtils.getLatestRound(oracleOut);
        return (
            getParametersEstimation(
                latestRoundIn,
                latestRoundOut,
                hpParameters
            )
        );
    }

    /**
    * @notice Gets asset-pair approximate historical return's mean and variance
    * @param latestRoundIn The round-to-start-from's data including its ID of tokenIn
    * @param latestRoundOut The round-to-start-from's data including its ID of tokenOut
    * @param hpParameters The parameters for historical prices retrieval
    * @return gbmEstimation The asset-pair historical return's mean and variance
    */
    function getParametersEstimation(
        Struct.LatestRound memory latestRoundIn,
        Struct.LatestRound memory latestRoundOut,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    internal view returns (Struct.GBMEstimation memory gbmEstimation) {

        // retrieve historical prices of tokenIn
        (
            uint256[] memory pricesIn, uint256[] memory timestampsIn, uint256 startIndexIn, bool noMoreDataPointIn
        ) = getHistoricalPrices(
            latestRoundIn, hpParameters
        );
        if (!noMoreDataPointIn && (startIndexIn < hpParameters.lookbackInRound - 1)) {
            return Struct.GBMEstimation(0, 0, false);
        }

        uint256 reducedLookbackInSecCandidate = hpParameters.timestamp - timestampsIn[startIndexIn];
        if (reducedLookbackInSecCandidate < hpParameters.lookbackInSec) {
            hpParameters.lookbackInSec = reducedLookbackInSecCandidate;
        }

        // retrieve historical prices of tokenOut
        (
            uint256[] memory pricesOut, uint256[] memory timestampsOut, uint256 startIndexOut, bool noMoreDataPointOut
        ) = getHistoricalPrices(
            latestRoundOut, hpParameters
        );
        if (!noMoreDataPointOut && (startIndexOut < hpParameters.lookbackInRound - 1)) {
            return Struct.GBMEstimation(0, 0, false);
        }

        return _getParametersEstimation(
            noMoreDataPointIn && noMoreDataPointOut,
            Struct.HistoricalPricesData(startIndexIn, timestampsIn, pricesIn),
            Struct.HistoricalPricesData(startIndexOut, timestampsOut, pricesOut),
            hpParameters
        );
    }

    /**
    * @notice Gets asset-pair historical data return's mean and variance
    * @param noMoreDataPoints True if and only if the retrieved data span over the whole time window of interest
    * @param hpDataIn Historical prices data of tokenIn
    * @param hpDataOut Historical prices data of tokenOut
    * @param hpParameters The parameters for historical prices retrieval
    * @return gbmEstimation The asset-pair historical return's mean and variance
    */
    function _getParametersEstimation(
        bool noMoreDataPoints,
        Struct.HistoricalPricesData memory hpDataIn,
        Struct.HistoricalPricesData memory hpDataOut,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    internal pure returns (Struct.GBMEstimation memory gbmEstimation) {

        // no price return can be calculated with only 1 data point
        if (hpDataIn.startIndex == 0 && hpDataOut.startIndex == 0) {
            return gbmEstimation = Struct.GBMEstimation(0, 0, true);
        }

        if (noMoreDataPoints) {
            uint256 ts = hpParameters.timestamp - hpParameters.lookbackInSec;
            hpDataIn.timestamps[hpDataIn.startIndex] = ts;
            hpDataOut.timestamps[hpDataOut.startIndex] = ts;
        } else {
            consolidateStartIndices(
                hpDataIn,
                hpDataOut
            );
            // no price return can be calculated with only 1 data point
            if (hpDataIn.startIndex == 0 && hpDataOut.startIndex == 0) {
                return gbmEstimation = Struct.GBMEstimation(0, 0, true);
            }
        }
        (int256[] memory values, uint256[] memory timestamps) = getSeries(
            hpDataIn.prices, hpDataIn.timestamps, hpDataIn.startIndex,
            hpDataOut.prices, hpDataOut.timestamps, hpDataOut.startIndex
        );
        (int256 mean, uint256 variance) = getStatistics(values, timestamps);

        return gbmEstimation = Struct.GBMEstimation(mean, variance, true);

    }

    /**
    * @notice Gets asset-pair historical prices with timestamps
    * @param pricesIn The historical prices of tokenIn
    * @param timestampsIn The timestamps corresponding to the tokenIn's historical prices
    * @param startIndexIn The tokenIn historical data's last valid index
    * @param pricesOut The tokenIn historical data's last valid index
    * @param timestampsOut The timestamps corresponding to the tokenOut's historical prices
    * @param startIndexOut The tokenOut historical data's last valid index
    * @return values The asset-pair historical prices array
    * @return timestamps The asset-pair historical timestamps array
    */
    function getSeries(
        uint256[] memory pricesIn, uint256[] memory timestampsIn, uint256 startIndexIn,
        uint256[] memory pricesOut, uint256[] memory timestampsOut, uint256 startIndexOut
    ) internal pure returns (int256[] memory values, uint256[] memory timestamps) {

        // compute the number of returns
        uint256 count = 1;
        {
            uint256 _startIndexIn = startIndexIn;
            uint256 _startIndexOut = startIndexOut;
            bool skip = true;
            while (_startIndexIn > 0 || _startIndexOut > 0) {
                (skip, _startIndexIn, _startIndexOut) = getNextSample(
                    _startIndexIn, _startIndexOut, timestampsIn, timestampsOut
                );
                if (!skip) {
                    count += 1;
                }
            }
            values = new int256[](count);
            timestamps = new uint256[](count);
            values[0] = int256(Num.div(pricesOut[startIndexOut], pricesIn[startIndexIn]));
            timestamps[0] = Num.max(timestampsOut[startIndexOut], timestampsIn[startIndexIn]) * Const.ONE;
        }

        // compute actual returns
        {
            count = 1;
            bool skip = true;
            while (startIndexIn > 0 || startIndexOut > 0) {
                (skip, startIndexIn, startIndexOut) = getNextSample(
                    startIndexIn, startIndexOut, timestampsIn, timestampsOut
                );
                if (!skip) {
                    values[count] = int256(Num.div(pricesOut[startIndexOut], pricesIn[startIndexIn]));
                    timestamps[count] = Num.max(timestampsOut[startIndexOut], timestampsIn[startIndexIn]) * Const.ONE;
                    count += 1;
                }
            }
        }

        return (values, timestamps);

    }

    /**
    * @notice Gets asset-pair historical mean/variance from timestamped data
    * @param values The historical values
    * @param timestamps The corresponding time deltas, in seconds
    * @return mean The asset-pair historical return's mean
    * @return variance asset-pair historical return's variance
    */
    function getStatistics(int256[] memory values, uint256[] memory timestamps)
    internal pure returns (int256, uint256) {

        uint256 n = values.length;
        if (n < 2) {
            return (0, 0);
        }
        n -= 1;

        uint256 tWithPrecision = timestamps[n] - timestamps[0];

        // mean
        int256 mean = Num.divInt256(LogExpMath.ln(Num.divInt256(values[n], values[0])), int256(tWithPrecision));
        uint256 meanSquare;
        if (mean < 0) {
            meanSquare = Num.mul(uint256(-mean), uint256(-mean));
        } else {
            meanSquare = Num.mul(uint256(mean), uint256(mean));
        }
        // variance
        int256 variance = -int256(Num.mul(meanSquare, tWithPrecision));
        for (uint256 i = 1; i <= n; i++) {
            int256 d = LogExpMath.ln(Num.divInt256(values[i], values[i - 1]));
            if (d < 0) {
                d = -d;
            }
            uint256 dAbs = uint256(d);
            variance += int256(Num.div(Num.mul(dAbs, dAbs), timestamps[i] - timestamps[i - 1]));
        }
        variance = Num.divInt256(variance, int256(n * Const.ONE));

        return (mean, Num.positivePart(variance));
    }

    /**
    * @notice Finds the next data point in chronological order
    * @dev Few considerations:
    * - data point with same timestamp as previous point are tagged with a 'skip=true'
    * - when we reach the last point of a token, we consider it's value constant going forward with the other token
    * As a result the variance of those returns will be underestimated.
    * @param startIndexIn  The tokenIn historical data's last valid index
    * @param startIndexOut The tokenOut historical data's last valid index
    * @param timestampsIn  The timestamps corresponding to the tokenIn's historical prices
    * @param timestampsOut The timestamps corresponding to the tokenOut's historical prices
    * @return skip The 'skip' tag
    * @return startIndexIn The updated startIndexIn
    * @return startIndexOut The updated startIndexOut
    */
    function getNextSample(
        uint256 startIndexIn, uint256 startIndexOut,
        uint256[] memory timestampsIn, uint256[] memory timestampsOut
    ) internal pure returns (bool, uint256, uint256) {
        bool skip = true;
        uint256 nextStartIndexIn = startIndexIn > 0 ? startIndexIn - 1 : startIndexIn;
        uint256 nextStartIndexOut = startIndexOut > 0 ? startIndexOut - 1 : startIndexOut;
        if (timestampsIn[nextStartIndexIn] == timestampsOut[nextStartIndexOut]) {
            if (
                (timestampsIn[nextStartIndexIn] != timestampsIn[startIndexIn])
                && (timestampsOut[nextStartIndexOut] != timestampsOut[startIndexOut])
            ) {
                skip = false;
            }
            if (startIndexIn > 0) {
                startIndexIn--;
            }
            if (startIndexOut > 0) {
                startIndexOut--;
            }
        } else {
            if (startIndexOut == 0) {
                if (timestampsIn[nextStartIndexIn] != timestampsIn[startIndexIn]) {
                    skip = false;
                }
                if (startIndexIn > 0) {
                    startIndexIn--;
                }
            } else if (startIndexIn == 0) {
                if (timestampsOut[nextStartIndexOut] != timestampsOut[startIndexOut]) {
                    skip = false;
                }
                if (startIndexOut > 0) {
                    startIndexOut--;
                }
            } else {
                if (timestampsIn[nextStartIndexIn] < timestampsOut[nextStartIndexOut]) {
                    if (timestampsIn[nextStartIndexIn] != timestampsIn[startIndexIn]) {
                        skip = false;
                    }
                    if (startIndexIn > 0) {
                        startIndexIn--;
                    }
                } else {
                    if (timestampsOut[nextStartIndexOut] != timestampsOut[startIndexOut]) {
                        skip = false;
                    }
                    if (startIndexOut > 0) {
                        startIndexOut--;
                    }
                }
            }
        }
        return  (skip, startIndexIn, startIndexOut);
    }

    /**
    * @notice Gets historical prices from a Chainlink data feed
    * @dev Few specificities:
    * - it filters out round data with null price or timestamp
    * - it stops filling the prices/timestamps when:
    * a) hpParameters.lookbackInRound rounds have already been found
    * b) time window induced by hpParameters.lookbackInSec is no more satisfied
    * @param latestRound The round-to-start-from's data including its ID
    * @param hpParameters The parameters for historical prices retrieval
    * @return historicalPrices The historical prices of a token
    * @return historicalTimestamps The timestamps of the reported prices
    * @return index The last valid index of the returned arrays
    * @return noMoreDataPoints True if the reported historical prices reaches the lookback time limit
    */
    function getHistoricalPrices(
        Struct.LatestRound memory latestRound,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    internal view returns (uint256[] memory, uint256[] memory, uint256, bool)
    {
        uint256 latestTimestamp = latestRound.timestamp;

        // historical price endtimestamp >= lookback window or it reverts
        uint256 timeLimit = hpParameters.timestamp - hpParameters.lookbackInSec;

        // result variables
        uint256[] memory prices = new uint256[](hpParameters.lookbackInRound);
        uint256[] memory timestamps = new uint256[](hpParameters.lookbackInRound);
        uint256 idx = 1;

        {

            prices[0] = latestRound.price; // is supposed to be well valid
            timestamps[0] = latestTimestamp; // is supposed to be well valid

            if (latestTimestamp < timeLimit) {
                return (prices, timestamps, 0, true);
            }

            uint80 count = 1;

            // buffer variables
            uint80 _roundId = latestRound.roundId;

            while ((_roundId >= hpParameters.lookbackStepInRound) && (count < hpParameters.lookbackInRound)) {

                _roundId -= hpParameters.lookbackStepInRound;
                (uint256 _price, uint256 _timestamp) = ChainlinkUtils.getRoundData(latestRound.oracle, _roundId);

                if (_price > 0 && _timestamp > 0) {

                    prices[idx] = _price;
                    timestamps[idx] = _timestamp;
                    idx += 1;

                    if (_timestamp < timeLimit) {
                        return (prices, timestamps, idx - 1, true);
                    }

                }

                count += 1;

            }

        }

        return (prices, timestamps, idx - 1, false);
    }

    /**
    * @notice Consolidate the last valid indexes of tokenIn and tokenOut
    * @param hpDataIn Historical prices data of tokenIn
    * @param hpDataOut Historical prices data of tokenOut
    */
    function consolidateStartIndices(
        Struct.HistoricalPricesData memory hpDataIn,
        Struct.HistoricalPricesData memory hpDataOut
    )
    internal pure
    {

        // trim prices/timestamps by adjusting startIndexes
        if (hpDataIn.timestamps[hpDataIn.startIndex] > hpDataOut.timestamps[hpDataOut.startIndex]) {
            while (
                (hpDataOut.startIndex > 0)
                && (hpDataOut.timestamps[hpDataOut.startIndex - 1] <= hpDataIn.timestamps[hpDataIn.startIndex])
            ) {
                --hpDataOut.startIndex;
            }
        } else if (hpDataIn.timestamps[hpDataIn.startIndex] < hpDataOut.timestamps[hpDataOut.startIndex]) {
            while (
                (hpDataIn.startIndex > 0)
                && (hpDataIn.timestamps[hpDataIn.startIndex - 1] <= hpDataOut.timestamps[hpDataOut.startIndex])
            ) {
                --hpDataIn.startIndex;
            }
        }

    }

}

// File: contracts/Math.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.








/**
* @title Library in charge of the Swaap pricing computations
* @dev few definitions
* shortage of tokenOut is when (balanceIn * weightOut) / (balanceOut * weightIn) > oraclePriceOut / oraclePriceIn
* abundance of tokenOut is when (balanceIn * weightOut) / (balanceOut * weightIn) < oraclePriceOut / oraclePriceIn
* equilibrium is when (balanceIn * weightOut) / (balanceOut * weightIn) = oraclePriceOut / oraclePriceIn
*/
library Math {

    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                      ( bI * w0 )                                      //
    // bO = tokenBalanceOut         sP =  ------------------------                               //
    // wI = tokenWeightIn                 ( bO * wI ) * ( 1 - sF )                               //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    )
    external pure
    returns (uint256 spotPrice)
    {
        uint256 numer = Num.mul(tokenBalanceIn, tokenWeightOut);
        uint256 denom = Num.mul(Num.mul(tokenBalanceOut, tokenWeightIn), Const.ONE - swapFee);
        return (spotPrice = Num.div(numer, denom));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    )
    internal pure
    returns (uint256 tokenAmountOut)
    {
        uint256 weightRatio = Num.div(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = Const.ONE - swapFee;
        adjustedIn = Num.mul(tokenAmountIn, adjustedIn);
        uint256 y = Num.div(tokenBalanceIn, tokenBalanceIn + adjustedIn);
        uint256 foo = Num.pow(y, weightRatio);
        uint256 bar = Const.ONE - foo;
        tokenAmountOut = Num.mul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    )
        internal pure
        returns (uint256 tokenAmountIn)
    {
        uint256 weightRatio = Num.div(tokenWeightOut, tokenWeightIn);
        uint256 diff = tokenBalanceOut - tokenAmountOut;
        uint256 y = Num.div(tokenBalanceOut, diff);
        uint256 foo = Num.pow(y, weightRatio);
        foo = foo - Const.ONE;
        tokenAmountIn = Const.ONE - swapFee;
        tokenAmountIn = Num.div(Num.mul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut                                                                       //
    // tAi = tokenAmountIn        //                                      \    wI   \            //
    // wI = tokenWeightIn        //                                        \  ----   \           //
    // tW = totalWeight          ||   tAi * ( tW - ( tW - wI ) * sF )      | ^ tW    |           //
    // tBi = tokenBalanceIn pAo= ||  --------------------------------- + 1 |         | * pS - pS //
    // pS = poolSupply            \\             tBi * tW                  /         /           //
    // sF = swapFee                \\                                     /         /            //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    )
        internal pure
        returns (uint256 poolAmountOut)
    {
        // Charge the trading fee for the proportion of tokenAi
        //  which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);

        uint256 innerNumer = Num.mul(
            tokenAmountIn,
            totalWeight -  Num.mul(
                totalWeight - tokenWeightIn,
                swapFee
            )
        );
        uint256 innerDenom = Num.mul(tokenBalanceIn, totalWeight);

        uint256 inner = Num.pow(Num.div(innerNumer, innerDenom) + Const.ONE, Num.div(tokenWeightIn, totalWeight));

        return (poolAmountOut = Num.mul(inner, poolSupply) - poolSupply);
    }

    /**
    * @notice Computes the pool token out when joining with a single asset
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param remainingTokens The pool global information on the remaining tokens
    * @param joinswapParameters The joinswap's parameters (amount in, fee, fallback-spread and pool supply)
    * @param gbmParameters The GBM forecast parameters (Z, horizon)
    * @param hpParameters The parameters for historical prices retrieval
    * @return poolAmountOut The amount of pool tokens to be received
    */
    function calcPoolOutGivenSingleInMMM(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal[] memory remainingTokens,
        Struct.JoinExitSwapParameters memory joinswapParameters,
        Struct.GBMParameters memory gbmParameters,
        Struct.HistoricalPricesParameters memory hpParameters
    )
        external view
        returns (uint256 poolAmountOut)
    {

        // to get the total adjusted weight, we assume all the tokens Out are in shortage
        uint256 totalAdjustedWeight = getTotalWeightMMM(
            true,
            joinswapParameters.fallbackSpread,
            tokenGlobalIn,
            remainingTokens,
            gbmParameters,
            hpParameters
        );

        uint256 fee = joinswapParameters.fee;

        bool blockHasPriceUpdate = block.timestamp == tokenGlobalIn.latestRound.timestamp;
        {
            uint8 i;
            while ((!blockHasPriceUpdate) && (i < remainingTokens.length)) {
                if (block.timestamp == remainingTokens[i].latestRound.timestamp) {
                    blockHasPriceUpdate = true;
                }
                unchecked { ++i; }
            }
        }
        if (blockHasPriceUpdate) {
            uint256 poolValueInTokenIn = getPoolTotalValue(tokenGlobalIn, remainingTokens);
            fee = Num.min(
                Const.ONE,
                fee + calcPoolOutGivenSingleInAdaptiveFees(
                    poolValueInTokenIn,
                    tokenGlobalIn.info.balance,
                    Num.div(tokenGlobalIn.info.weight, totalAdjustedWeight),
                    joinswapParameters.amount
                )
            );
        }

        poolAmountOut = calcPoolOutGivenSingleIn(
            tokenGlobalIn.info.balance,
            tokenGlobalIn.info.weight,
            joinswapParameters.poolSupply,
            totalAdjustedWeight,
            joinswapParameters.amount,
            fee
        );

        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                          \\      //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /  tW  \      \\     //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | ------ | * b0 ||    //
    // ps = poolSupply                \      \\          pS           /     \  wO  /      //     //
    // wI = tokenWeightIn      tAo =   \      \                                          //      //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    )
    internal pure
    returns (uint256 tokenAmountOut)
    {
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee = Num.mul(poolAmountIn, Const.ONE - Const.EXIT_FEE);
        uint256 newPoolSupply = poolSupply - poolAmountInAfterExitFee;
        uint256 poolRatio = Num.div(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = Num.pow(poolRatio, Num.div(totalWeight, tokenWeightOut));
        uint256 newTokenBalanceOut = Num.mul(tokenOutRatio, tokenBalanceOut);

        uint256 tokenAmountOutBeforeSwapFee = tokenBalanceOut - newTokenBalanceOut;

        // charge swap fee on the output token side
        //uint256 tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint256 zaz = Num.mul(Const.ONE - Num.div(tokenWeightOut, totalWeight), swapFee);
        tokenAmountOut = Num.mul(tokenAmountOutBeforeSwapFee, Const.ONE - zaz);
        return tokenAmountOut;
    }

    /**
    * @notice Computes the token amount out to be received when exiting the pool with a single asset
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param remainingTokens The pool global information on the remaining tokens
    * @param exitswapParameters The exitswap's parameters (amount in, fee, fallback-spread and pool supply)
    * @param gbmParameters The GBM forecast parameters (Z, horizon)
    * @param hpParameters The parameters for historical prices retrieval
    * @return tokenAmountOut The amount of tokenOut to be received
    */
    function calcSingleOutGivenPoolInMMM(
        Struct.TokenGlobal memory tokenGlobalOut,
        Struct.TokenGlobal[] memory remainingTokens,
        Struct.JoinExitSwapParameters memory exitswapParameters,
        Struct.GBMParameters memory gbmParameters,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    external view
    returns (uint256 tokenAmountOut)
    {
        // to get the total adjusted weight, we assume all the remaining tokens are in shortage
        uint256 totalAdjustedWeight = getTotalWeightMMM(
            false,
            exitswapParameters.fallbackSpread,
            tokenGlobalOut,
            remainingTokens,
            gbmParameters,
            hpParameters
        );

        uint256 fee = exitswapParameters.fee;

        bool blockHasPriceUpdate = block.timestamp == tokenGlobalOut.latestRound.timestamp;
        {
            uint8 i;
            while ((!blockHasPriceUpdate) && (i < remainingTokens.length)) {
                if (block.timestamp == remainingTokens[i].latestRound.timestamp) {
                    blockHasPriceUpdate = true;
                }
                unchecked { ++i; }
            }
        }
        if (blockHasPriceUpdate) {
            uint256 poolValueInTokenOut = getPoolTotalValue(tokenGlobalOut, remainingTokens);
            fee = Num.min(
                Const.ONE,
                fee + calcSingleOutGivenPoolInAdaptiveFees(
                    poolValueInTokenOut,
                    tokenGlobalOut.info.balance,
                    Num.div(tokenGlobalOut.info.weight, totalAdjustedWeight),
                    Num.div(exitswapParameters.amount, exitswapParameters.poolSupply)
                )
            );
        }

        tokenAmountOut = calcSingleOutGivenPoolIn(
            tokenGlobalOut.info.balance,
            tokenGlobalOut.info.weight,
            exitswapParameters.poolSupply,
            totalAdjustedWeight,
            exitswapParameters.amount,
            fee
        );

        return tokenAmountOut;
    }

    /**
    * @notice Computes the log spread factor
    * @dev We define it as the log of the p-quantile of a GBM process (log-normal distribution),
    * which is given by the following:
    * mean * horizon + z * sqrt(2 * variance * horizon)
    * where z = ierf(2p - 1), with ierf being the inverse error function.
    * GBM: https://en.wikipedia.org/wiki/Geometric_Brownian_motion
    * Log-normal distribution: https://en.wikipedia.org/wiki/Log-normal_distribution
    * erf: https://en.wikipedia.org/wiki/Error_function
    * @param mean The percentage drift
    * @param variance The percentage volatility
    * @param horizon The GBM forecast horizon parameter
    * @param z The GBM forecast z parameter
    * @return x The log spread factor
    */
    function getLogSpreadFactor(
        int256 mean, uint256 variance,
        uint256 horizon, uint256 z
    )
    internal pure
    returns (int256 x)
    {
        if (mean == 0 && variance == 0) {
            return 0;
        }
        if (mean < 0) {
            mean = -int256(Num.mul(uint256(-mean), horizon));
        } else {
            mean = int256(Num.mul(uint256(mean), horizon));
        }
        uint256 diffusion;
        if (variance > 0) {
            diffusion = Num.mul(
                z,
                LogExpMath.pow(
                    Num.mul(variance, 2 * horizon),
                    Const.ONE / 2
                )
            );
        }
        return (x = int256(diffusion) + mean);
    }

    /**
    * @notice Apply to the tokenWeight a 'spread' factor
    * @dev The spread factor is defined as the maximum between:
    a) the expected relative tokenOut increase in tokenIn terms
    b) 1
    * The function multiplies the tokenWeight by the spread factor if
    * the token is in shortage, or divides it by the spread factor if it is in abundance
    * @param shortage true when the token is in shortage, false if in abundance
    * @param fallbackSpread The default spread in case the it couldn't be calculated using oracle prices
    * @param tokenWeight The token's weight
    * @param gbmEstimation The GBM's 2 first moments estimation
    * @param gbmParameters The GBM forecast parameters (Z, horizon)
    * @return adjustedWeight The adjusted weight based on spread
    * @return spread The spread
    */
    function getMMMWeight(
        bool shortage,
        uint256 fallbackSpread,
        uint256 tokenWeight,
        Struct.GBMEstimation memory gbmEstimation,
        Struct.GBMParameters memory gbmParameters
    )
    internal pure
    returns (uint256 adjustedWeight, uint256 spread)
    {

        if (!gbmEstimation.success) {
            if (shortage) {
                return (Num.mul(tokenWeight, Const.ONE + fallbackSpread), fallbackSpread);
            } else {
                return (Num.div(tokenWeight, Const.ONE + fallbackSpread), fallbackSpread);
            }
        }

        if (gbmParameters.horizon == 0) {
            return (tokenWeight, 0);
        }

        int256 logSpreadFactor = getLogSpreadFactor(
            gbmEstimation.mean, gbmEstimation.variance,
            gbmParameters.horizon, gbmParameters.z
        );
        if (logSpreadFactor <= 0) {
            return (tokenWeight, 0);
        }
        uint256 spreadFactor = uint256(LogExpMath.exp(logSpreadFactor));
        // if spread < 1 --> rounding error --> set to 1
        if (spreadFactor <= Const.ONE) {
            return (tokenWeight, 0);
        }

        spread = spreadFactor - Const.ONE;

        if (shortage) {
            return (Num.mul(tokenWeight, spreadFactor), spread);
        } else {
            return (Num.div(tokenWeight, spreadFactor), spread);
        }
    }

    /**
    * @notice Adjusts every token's weight (except from the pivotToken) with a spread factor and computes the sum
    * @dev The initial weights of the tokens are the ones adjusted by their price performance only
    * @param pivotTokenIsInput True if and only if pivotToken should be considered as an input token
    * @param fallbackSpread The default spread in case the it couldn't be calculated using oracle prices
    * @param pivotToken The pivot token's global information (token records + latest round info)
    * @param otherTokens Other pool's tokens' global information (token records + latest rounds info)
    * @param gbmParameters The GBM forecast parameters (Z, horizon)
    * @param hpParameters The parameters for historical prices retrieval
    * @return totalAdjustedWeight The total adjusted weight
    */
    function getTotalWeightMMM(
        bool pivotTokenIsInput,
        uint256 fallbackSpread,
        Struct.TokenGlobal memory pivotToken,
        Struct.TokenGlobal[] memory otherTokens,
        Struct.GBMParameters memory gbmParameters,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    internal view
    returns (uint256 totalAdjustedWeight)
    {

        bool noMoreDataPointPivot;
        Struct.HistoricalPricesData memory hpDataPivot;

        {
            uint256[] memory pricesPivot;
            uint256[] memory timestampsPivot;
            uint256 startIndexPivot;
            // retrieve historical prices of tokenIn
            (pricesPivot,
            timestampsPivot,
            startIndexPivot,
            noMoreDataPointPivot) = GeometricBrownianMotionOracle.getHistoricalPrices(
                pivotToken.latestRound,
                hpParameters
            );

            hpDataPivot = Struct.HistoricalPricesData(startIndexPivot, timestampsPivot, pricesPivot);

            // reducing lookback time window
            uint256 reducedLookbackInSecCandidate = hpParameters.timestamp - timestampsPivot[startIndexPivot];
            if (reducedLookbackInSecCandidate < hpParameters.lookbackInSec) {
                hpParameters.lookbackInSec = reducedLookbackInSecCandidate;
            }
        }

        // to get the total adjusted weight, we apply a spread factor on every weight except from the pivotToken's one.
        totalAdjustedWeight = pivotToken.info.weight;
        for (uint256 i; i < otherTokens.length;) {

            (uint256[] memory pricesOthers,
            uint256[] memory timestampsOthers,
            uint256 startIndexOthers,
            bool noMoreDataPointOthers) = GeometricBrownianMotionOracle.getHistoricalPrices(
                otherTokens[i].latestRound,
                hpParameters
            );

            Struct.GBMEstimation memory gbmEstimation;
            if (pivotTokenIsInput) {
                // weight is increased
                gbmEstimation = GeometricBrownianMotionOracle._getParametersEstimation(
                    noMoreDataPointPivot && noMoreDataPointOthers,
                    hpDataPivot,
                    Struct.HistoricalPricesData(startIndexOthers, timestampsOthers, pricesOthers),
                    hpParameters
                );
            } else {
                // weight is reduced
                gbmEstimation = GeometricBrownianMotionOracle._getParametersEstimation(
                    noMoreDataPointPivot && noMoreDataPointOthers,
                    Struct.HistoricalPricesData(startIndexOthers, timestampsOthers, pricesOthers),
                    hpDataPivot,
                    hpParameters
                );
            }

            (otherTokens[i].info.weight, ) = getMMMWeight(
                pivotTokenIsInput,
                fallbackSpread,
                otherTokens[i].info.weight,
                gbmEstimation,
                gbmParameters
            );

            totalAdjustedWeight += otherTokens[i].info.weight;
            unchecked {++i;}
        }

        return totalAdjustedWeight;
    }

    /**
    * @notice Computes the net value of a given tokenIn amount in tokenOut terms
    * @dev A spread is applied as soon as entering a "shortage of tokenOut" phase
    * cf whitepaper: https://www.swaap.finance/whitepaper.pdf
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param swapParameters Amount of token in and swap fee
    * @param gbmParameters The GBM forecast parameters (Z, horizon)
    * @param hpParameters The parameters for historical prices retrieval
    * @return swapResult The swap result (amount out, spread and tax base in)
    */
    function calcOutGivenInMMM(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 relativePrice,
        Struct.SwapParameters memory swapParameters,
        Struct.GBMParameters memory gbmParameters,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    external view
    returns (Struct.SwapResult memory swapResult)
    {

        // determines the balance of tokenIn at equilibrium (cf definitions)
        uint256 balanceInAtEquilibrium = getTokenBalanceAtEquilibrium(
            tokenGlobalIn.info.balance,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance,
            tokenGlobalOut.info.weight,
            relativePrice
        );

        // from abundance of tokenOut to abundance of tokenOut --> no spread
        {
            if (
                (tokenGlobalIn.info.balance < balanceInAtEquilibrium)
                && (swapParameters.amount < balanceInAtEquilibrium - tokenGlobalIn.info.balance)
            ) {
                return Struct.SwapResult(
                    _calcOutGivenInMMMAbundance(
                        tokenGlobalIn, tokenGlobalOut,
                        relativePrice,
                        swapParameters.amount,
                        swapParameters.fee,
                        swapParameters.fallbackSpread
                    ),
                    0,
                    0
                );
            }
        }

        {
            Struct.GBMEstimation memory gbmEstimation = GeometricBrownianMotionOracle.getParametersEstimation(
                tokenGlobalIn.latestRound, tokenGlobalOut.latestRound,
                hpParameters
            );

            (uint256 adjustedTokenOutWeight, uint256 spread) = getMMMWeight(
                true,
                swapParameters.fallbackSpread,
                tokenGlobalOut.info.weight,
                gbmEstimation, gbmParameters
            );

            if (tokenGlobalIn.info.balance >= balanceInAtEquilibrium) {
                // shortage to shortage
                return (
                    Struct.SwapResult(
                        calcOutGivenIn(
                            tokenGlobalIn.info.balance,
                            tokenGlobalIn.info.weight,
                            tokenGlobalOut.info.balance,
                            adjustedTokenOutWeight,
                            swapParameters.amount,
                            swapParameters.fee
                        ),
                        spread,
                        swapParameters.amount
                    )
                );
            }
            else {
                // abundance to shortage
                (uint256 amount, uint256 taxBaseIn) = _calcOutGivenInMMMMixed(
                    tokenGlobalIn,
                    tokenGlobalOut,
                    swapParameters,
                    relativePrice,
                    adjustedTokenOutWeight,
                    balanceInAtEquilibrium
                );
                return (
                    Struct.SwapResult(
                        amount,
                        spread,
                        taxBaseIn
                    )
                );
            }
        }

    }

    /**
    * @notice Implements calcOutGivenInMMM in the case of abundance of tokenOut
    * @dev A spread is applied as soon as entering a "shortage of tokenOut" phase
    * cf whitepaper: https://www.swaap.finance/whitepaper.pdf
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param tokenAmountIn The amount of tokenIn that will be swaped
    * @param baseFee The base fee
    * @param fallbackSpread The default spread in case the it couldn't be calculated using oracle prices
    * @return tokenAmountOut The tokenAmountOut when the tokenOut is in abundance
    */
    function _calcOutGivenInMMMAbundance(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 relativePrice,
        uint256 tokenAmountIn,
        uint256 baseFee,
        uint256 fallbackSpread
    ) internal view returns (uint256) {
        uint256 adaptiveFees = getAdaptiveFees(
            tokenGlobalIn,
            tokenAmountIn,
            tokenGlobalOut,
            Num.div(tokenAmountIn, relativePrice),
            relativePrice,
            baseFee,
            fallbackSpread
        );
        return (
            calcOutGivenIn(
                tokenGlobalIn.info.balance,
                tokenGlobalIn.info.weight,
                tokenGlobalOut.info.balance,
                tokenGlobalOut.info.weight,
                tokenAmountIn,
                adaptiveFees
            )
        );
    }

    /**
    * @notice Implements 'calcOutGivenInMMM' in the case of mixed regime of tokenOut (abundance then shortage)
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param swapParameters The parameters of the swap
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param adjustedTokenWeightOut The spread-augmented tokenOut's weight
    * @param balanceInAtEquilibrium TokenIn balance at equilibrium
    * @return tokenAmountOut The total amount of token out
    * @return taxBaseIn The amount of tokenIn swapped when in shortage of tokenOut
    */
    function _calcOutGivenInMMMMixed(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        Struct.SwapParameters memory swapParameters,
        uint256 relativePrice,
        uint256 adjustedTokenWeightOut,
        uint256 balanceInAtEquilibrium
    )
    internal view
    returns (uint256, uint256)
    {

        uint256 tokenInSellAmountForEquilibrium = balanceInAtEquilibrium - tokenGlobalIn.info.balance;
        uint256 taxBaseIn = swapParameters.amount - tokenInSellAmountForEquilibrium;

        // 'abundance of tokenOut' phase --> no spread
        uint256 tokenAmountOutPart1 = _calcOutGivenInMMMAbundance(
            tokenGlobalIn,
            tokenGlobalOut,
            relativePrice,
            tokenInSellAmountForEquilibrium,
            swapParameters.fee,
            swapParameters.fallbackSpread
        );

        // 'shortage of tokenOut phase' --> apply spread
        uint256 tokenAmountOutPart2 = calcOutGivenIn(
            tokenGlobalIn.info.balance + tokenInSellAmountForEquilibrium,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance - tokenAmountOutPart1,
            adjustedTokenWeightOut,
            taxBaseIn, // tokenAmountIn > tokenInSellAmountForEquilibrium
            swapParameters.fee
        );

        return (tokenAmountOutPart1 + tokenAmountOutPart2, taxBaseIn);

    }

    /**
    * @notice Computes the amount of tokenIn needed in order to receive a given amount of tokenOut
    * @dev A spread is applied as soon as entering a "shortage of tokenOut" phase
    * cf whitepaper: https://www.swaap.finance/whitepaper.pdf
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param swapParameters Amount of token out and swap fee
    * @param gbmParameters The GBM forecast parameters (Z, horizon)
    * @param hpParameters The parameters for historical prices retrieval
    * @return swapResult The swap result (amount in, spread and tax base in)
    */
    function calcInGivenOutMMM(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 relativePrice,
        Struct.SwapParameters memory swapParameters,
        Struct.GBMParameters memory gbmParameters,
        Struct.HistoricalPricesParameters memory hpParameters
    )
    external view
    returns (Struct.SwapResult memory)
    {

        // determines the balance of tokenOut at equilibrium (cf definitions)
        uint256 balanceOutAtEquilibrium = getTokenBalanceAtEquilibrium(
            tokenGlobalOut.info.balance,
            tokenGlobalOut.info.weight,
            tokenGlobalIn.info.balance,
            tokenGlobalIn.info.weight,
            Num.div(Const.ONE, relativePrice)
        );

        // from abundance of tokenOut to abundance of tokenOut --> no spread
        if (
            (tokenGlobalOut.info.balance > balanceOutAtEquilibrium)
            && (swapParameters.amount < tokenGlobalOut.info.balance - balanceOutAtEquilibrium)
        ) {
            return (
                Struct.SwapResult(
                    _calcInGivenOutMMMAbundance(
                        tokenGlobalIn, tokenGlobalOut,
                        relativePrice,
                        swapParameters.amount,
                        swapParameters.fee,
                        swapParameters.fallbackSpread
                    ),
                    0,
                    0
                )
            );
        }

        {
            Struct.GBMEstimation memory gbmEstimation = GeometricBrownianMotionOracle.getParametersEstimation(
                tokenGlobalIn.latestRound, tokenGlobalOut.latestRound,
                hpParameters
            );

            (uint256 adjustedTokenOutWeight, uint256 spread) = getMMMWeight(
                true,
                swapParameters.fallbackSpread,
                tokenGlobalOut.info.weight,
                gbmEstimation, gbmParameters
            );

            if (tokenGlobalOut.info.balance <= balanceOutAtEquilibrium) {
                // shortage to shortage
                return (
                    Struct.SwapResult(
                        calcInGivenOut(
                            tokenGlobalIn.info.balance,
                            tokenGlobalIn.info.weight,
                            tokenGlobalOut.info.balance,
                            adjustedTokenOutWeight,
                            swapParameters.amount,
                            swapParameters.fee
                        ),
                        spread,
                        swapParameters.amount
                    )
                );
            }
            else {
                // abundance to shortage
                (uint256 amount, uint256 taxBaseIn) = _calcInGivenOutMMMMixed(
                    tokenGlobalIn,
                    tokenGlobalOut,
                    swapParameters,
                    relativePrice,
                    adjustedTokenOutWeight,
                    balanceOutAtEquilibrium
                );
                return (
                    Struct.SwapResult(
                        amount,
                        spread,
                        taxBaseIn
                    )
                );
            }

        }

    }

    /**
    * @notice Implements calcOutGivenInMMM in the case of abundance of tokenOut
    * @dev A spread is applied as soon as entering a "shortage of tokenOut" phase
    * cf whitepaper: https://www.swaap.finance/whitepaper.pdf
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param tokenAmountOut The amount of tokenOut that will be received
    * @param baseFee The base fee
    * @param fallbackSpread The default spread in case the it couldn't be calculated using oracle prices
    * @return tokenAmountIn The amount of tokenIn needed for the swap
    */
    function _calcInGivenOutMMMAbundance(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 relativePrice,
        uint256 tokenAmountOut,
        uint256 baseFee,
        uint256 fallbackSpread
    ) internal view returns (uint256) {
        uint256 adaptiveFees = getAdaptiveFees(
            tokenGlobalIn,
            Num.mul(tokenAmountOut, relativePrice),
            tokenGlobalOut,
            tokenAmountOut,
            relativePrice,
            baseFee,
            fallbackSpread
        );
        return (
            calcInGivenOut(
                tokenGlobalIn.info.balance,
                tokenGlobalIn.info.weight,
                tokenGlobalOut.info.balance,
                tokenGlobalOut.info.weight,
                tokenAmountOut,
                adaptiveFees
            )
        );
    }

    /**
    * @notice Implements 'calcInGivenOutMMM' in the case of abundance of tokenOut
    * @dev Two cases to consider:
    * 1) amount of tokenIn won't drive the pool from abundance of tokenOut to shortage ==> 1 pricing (no spread)
    * 2) amount of tokenIn will drive the pool from abundance of tokenOut to shortage ==> 2 pricing, one for each phase
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param swapParameters The parameters of the swap
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param adjustedTokenWeightOut The spread-augmented tokenOut's weight
    * @return tokenAmountIn The total amount of tokenIn needed for the swap
    * @return taxBaseIn The amount of tokenIn swapped when in shortage of tokenOut
    */
    function _calcInGivenOutMMMMixed(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        Struct.SwapParameters memory swapParameters,
        uint256 relativePrice,
        uint256 adjustedTokenWeightOut,
        uint256 balanceOutAtEquilibrium
    )
    internal view
    returns (uint256, uint256)
    {
        
        uint256 tokenOutBuyAmountForEquilibrium =  tokenGlobalOut.info.balance - balanceOutAtEquilibrium;

        // 'abundance of tokenOut' phase --> no spread
        uint256 tokenAmountInPart1 = _calcInGivenOutMMMAbundance(
            tokenGlobalIn,
            tokenGlobalOut,
            relativePrice,
            tokenOutBuyAmountForEquilibrium,
            swapParameters.fee,
            swapParameters.fallbackSpread
        );

        // 'shortage of tokenOut phase' --> apply spread
        uint256 tokenAmountInPart2 = calcInGivenOut(
            tokenGlobalIn.info.balance + tokenAmountInPart1,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance - tokenOutBuyAmountForEquilibrium,
            adjustedTokenWeightOut,
            swapParameters.amount - tokenOutBuyAmountForEquilibrium, // tokenAmountOut > tokenOutBuyAmountForEquilibrium
            swapParameters.fee
        );

        return (tokenAmountInPart1 + tokenAmountInPart2, tokenAmountInPart2);
    }

    /**
    * @notice Computes the balance of token1 the pool must have in order to have token1/token2 at equilibrium
    * while satisfying the pricing curve prod^k balance_k^w_k = K
    * @dev We only rely on the following equations:
    * a) priceTokenOutOutInTokenIn = balance_in / balance_out * w_out / w_in
    * b) tokenBalanceOut = (K / prod_k!=in balance_k^w_k)^(1/w_out) = (localInvariant / balance_in^w_in)^(1/w_out)
    * with localInvariant = balance_in^w_in * balance_out^w_out which can be computed with only In/Out
    * @param tokenBalance1 The balance of token1 initially
    * @param tokenWeight1 The weight of token1
    * @param tokenBalance2 The balance of token2 initially
    * @param tokenWeight2 The weight of token2
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @return balance1AtEquilibrium The balance of token1 in order to have a token1/token2 at equilibrium
    */
    function getTokenBalanceAtEquilibrium( 
        uint256 tokenBalance1,
        uint256 tokenWeight1,
        uint256 tokenBalance2,
        uint256 tokenWeight2,
        uint256 relativePrice
    )
    internal pure
    returns (uint256 balance1AtEquilibrium)
    {
        {
            uint256 weightSum = tokenWeight1 + tokenWeight2;
            // relativePrice * weight1/weight2
            uint256 foo = Num.mul(relativePrice, Num.div(tokenWeight1, tokenWeight2));
            // relativePrice * balance2 * (weight1/weight2)
            foo = Num.mul(foo, tokenBalance2);
            
            balance1AtEquilibrium = Num.mul(
                LogExpMath.pow(
                    foo,
                    Num.div(tokenWeight2, weightSum)
                ),
                LogExpMath.pow(
                    tokenBalance1,
                    Num.div(tokenWeight1, weightSum)
                )
            );
        }
        return balance1AtEquilibrium;

    }

    /**
    * @notice Computes the fee needed to maintain the pool's value constant
    * @dev We use oracle to evaluate pool's value
    * @param tokenBalanceIn The balance of tokenIn initially
    * @param tokenAmountIn The amount of tokenIn to be added
    * @param tokenWeightIn The weight of tokenIn
    * @param tokenBalanceOut The balance of tokenOut initially
    * @param tokenAmountOut The amount of tokenOut to be removed from the pool
    * @param tokenWeightOut The weight of tokenOut
    * @return adaptiveFee The computed adaptive fee to be added to the base fees
    */
    function calcAdaptiveFeeGivenInAndOut(
        uint256 tokenBalanceIn,
        uint256 tokenAmountIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenAmountOut,
        uint256 tokenWeightOut
    )
    internal pure
    returns (uint256)
    {
        uint256 weightRatio = Num.div(tokenWeightOut, tokenWeightIn);
        uint256 y = Num.div(tokenBalanceOut, tokenBalanceOut - tokenAmountOut);
        uint256 foo = Num.mul(tokenBalanceIn, Num.pow(y, weightRatio));

        uint256 afterSwapTokenInBalance = tokenBalanceIn + tokenAmountIn;

        if (foo > afterSwapTokenInBalance) {
            return 0;
        }
        return (
            Num.div(
                afterSwapTokenInBalance - foo,
                tokenAmountIn
            )
        );
    }

    /**
    * @notice Computes the fee amount that will ensure we maintain the pool's value, according to oracle prices.
    * @dev We apply this fee regime only if Out-In price increased in the same block as now.
    * @param tokenGlobalIn The pool global information on tokenIn
    * @param tokenAmountIn The swap desired amount for tokenIn
    * @param tokenGlobalOut The pool global information on tokenOut
    * @param tokenAmountOut The swap desired amount for tokenOut
    * @param relativePrice The price of tokenOut in tokenIn terms
    * @param baseFee The base fee amount
    * @param fallbackSpread The default spread in case the it couldn't be calculated using oracle prices
    * @return alpha The potentially augmented fee amount
    */
    function getAdaptiveFees(
        Struct.TokenGlobal memory tokenGlobalIn,
        uint256 tokenAmountIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 tokenAmountOut,
        uint256 relativePrice,
        uint256 baseFee,
        uint256 fallbackSpread
    ) internal view returns (uint256 alpha) {

        // we only consider same block as last price update
        if (
            (block.timestamp != tokenGlobalIn.latestRound.timestamp)
            && (block.timestamp != tokenGlobalOut.latestRound.timestamp)
        ) {
            // no additional fees
            return alpha = baseFee;
        }
        uint256 recentPriceUpperBound = ChainlinkUtils.getMaxRelativePriceInLastBlock(
            tokenGlobalIn.latestRound,
            tokenGlobalIn.info.decimals,
            tokenGlobalOut.latestRound,
            tokenGlobalOut.info.decimals
        );
        if (recentPriceUpperBound == 0) {
            // we were not able to retrieve the previous price
            return alpha = fallbackSpread;
        } else if (recentPriceUpperBound <= relativePrice) {
            // no additional fees
            return alpha = baseFee;
        }

        return (
            // additional fees indexed on price increase and imbalance
            alpha = Num.min(
                Const.ONE,
                baseFee + calcAdaptiveFeeGivenInAndOut(
                    tokenGlobalIn.info.balance,
                    tokenAmountIn,
                    tokenGlobalIn.info.weight,
                    tokenGlobalOut.info.balance,
                    tokenAmountOut,
                    tokenGlobalOut.info.weight
                )
            )
        );

    }

    /**
    * @notice Computes the adaptive fees when joining a pool
    * @dev Adaptive fees are the fees related to the price increase of tokenIn with respect to tokenOut
    * reported by the oracles in the same block as the transaction
    * @param poolValueInTokenIn The pool value in terms of tokenIn
    * @param tokenBalanceIn The pool's balance of tokenIn
    * @param normalizedTokenWeightIn The normalized weight of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be swapped
    * @return adaptiveFees The adaptive fees (should be added to the pool's swap fees)
    */
    function calcPoolOutGivenSingleInAdaptiveFees(
        uint256 poolValueInTokenIn,
        uint256 tokenBalanceIn,
        uint256 normalizedTokenWeightIn,
        uint256 tokenAmountIn
    ) internal pure returns (uint256) {
        uint256 foo = Num.mul(
            Num.div(tokenBalanceIn, tokenAmountIn),
            Num.pow(
                Num.div(
                    poolValueInTokenIn + tokenAmountIn,
                    poolValueInTokenIn
                ),
                Num.div(Const.ONE, normalizedTokenWeightIn)
            ) - Const.ONE
        );
        if (foo >= Const.ONE) {
            return 0;
        }
        return (
            Num.div(
                Const.ONE - foo,
                Const.ONE - normalizedTokenWeightIn
            )
        );
    }

    /**
    * @notice Computes the adaptive fees when exiting a pool
    * @dev Adaptive fees are the fees related to the price increase of tokenIn with respect to tokenOut
    * reported by the oracles in the same block as the transaction
    * @param poolValueInTokenOut The pool value in terms of tokenOut
    * @param tokenBalanceOut The pool's balance of tokenOut
    * @param normalizedTokenWeightOut The normalized weight of tokenOut
    * @param normalizedPoolAmountOut The normalized amount of pool token's to be burned
    * @return adaptiveFees The adaptive fees (should be added to the pool's swap fees)
    */
    function calcSingleOutGivenPoolInAdaptiveFees(
        uint256 poolValueInTokenOut,
        uint256 tokenBalanceOut,
        uint256 normalizedTokenWeightOut,
        uint256 normalizedPoolAmountOut
    ) internal pure returns (uint256) {
        uint256 foo = Num.div(
            Num.mul(poolValueInTokenOut, normalizedPoolAmountOut),
            Num.mul(
                tokenBalanceOut,
                    Const.ONE -
                    Num.pow(
                        Const.ONE - normalizedPoolAmountOut,
                        Num.div(Const.ONE, normalizedTokenWeightOut)
                    )
            )
        );
        if (foo >= Const.ONE) {
            return 0;
        }
        return (
        Num.div(
            Const.ONE - foo,
            Const.ONE - normalizedTokenWeightOut
        )
        );
    }

    /**
    * @notice Computes the total value of the pool in terms of the quote token
    */
    function getPoolTotalValue(Struct.TokenGlobal memory quoteToken, Struct.TokenGlobal[] memory baseTokens)
    internal pure returns (uint256 basesTotalValue){
        basesTotalValue = quoteToken.info.balance;
        for (uint256 i; i < baseTokens.length;) {
            basesTotalValue += Num.mul(
                baseTokens[i].info.balance,
                ChainlinkUtils.getTokenRelativePrice(
                    quoteToken.latestRound.price,
                    quoteToken.info.decimals,
                    baseTokens[i].latestRound.price,
                    baseTokens[i].info.decimals
                )
            );
            unchecked { ++i; }
        }
        return basesTotalValue;
    }

}

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/IFactory.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title The interface for a Swaap V1 Pool Factory
*/
interface IFactory {
    
    /**
    * @notice Emitted when a controller creates a pool
    * @param caller The pool's creator
    * @param pool The created pool's address
    */
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    /**
    * @notice Emitted when a Swaap labs transfer is requested
    * @param from The current Swaap labs address
    * @param to The pending new Swaap labs address
    */
    event LOG_TRANSFER_REQUESTED(
        address indexed from,
        address indexed to
    );

    /**
    * @notice Emitted when a new address accepts the Swaap labs role
    * @param from The old Swaap labs address
    * @param to The new Swaap labs address
    */
    event LOG_NEW_SWAAPLABS(
        address indexed from,
        address indexed to
    );

    /*
    * @notice Create new pool with default parameters
    */
    function newPool() external returns (address);
    
    /**
    * @notice Returns if an address corresponds to a pool created by the factory
    */
    function isPool(address b) external view returns (bool);
    
    /**
    * @notice Returns swaap labs' address
    */
    function getSwaapLabs() external view returns (address);

    /**
    * @notice Allows an owner to begin transferring ownership to a new address,
    * pending.
    */
    function transferOwnership(address _to) external;

    /**
    * @notice Allows an ownership transfer to be completed by the recipient.
    */
    function acceptOwnership() external;
   
    /**
    * @notice Sends the exit fees accumulated to swaap labs
    */
    function collect(address erc20) external;

    /**
    * @notice Pause the factory's pools
    * @dev Pause disables most of the pools functionalities (swap, joinPool & joinswap)
    * and only allows LPs to withdraw their funds
    */
    function pauseProtocol() external;
    
    /**
    * @notice Resume the factory's pools
    * @dev Unpausing re-enables all the pools functionalities
    */
    function resumeProtocol() external;
    
    /**
    * @notice Reverts pools if the factory is paused
    * @dev This function is called by the pools whenever a swap or a joinPool is being made
    */
    function whenNotPaused() external view;

    /**
    * @notice Revoke factory control over a pool's parameters
    */
    function revokePoolFactoryControl(address pool) external;
    
    /**
    * @notice Sets a pool's swap fee
    */
    function setPoolSwapFee(address pool, uint256 swapFee) external;
    
    /**
    * @notice Sets a pool's dynamic coverage fees Z
    */
    function setPoolDynamicCoverageFeesZ(address pool, uint64 dynamicCoverageFeesZ) external;

    /**
    * @notice Sets a pool's dynamic coverage fees horizon
    */
    function setPoolDynamicCoverageFeesHorizon(address pool, uint256 dynamicCoverageFeesHorizon) external;

    /**
    * @notice Sets a pool's price statistics lookback in round
    */    
    function setPoolPriceStatisticsLookbackInRound(address pool, uint8 priceStatisticsLookbackInRound) external;

    /**
    * @notice Sets a pool's price statistics lookback in seconds
    */    
    function setPoolPriceStatisticsLookbackInSec(address pool, uint64 priceStatisticsLookbackInSec) external;

    /**
    * @notice Sets a pool's statistics lookback step in round
    */
    function setPoolPriceStatisticsLookbackStepInRound(address pool, uint8 priceStatisticsLookbackStepInRound) external;

    /**
    * @notice Sets a pool's maximum price unpeg ratio
    */
    function setPoolMaxPriceUnpegRatio(address pool, uint256 maxPriceUnpegRatio) external;

}

// File: contracts/interfaces/IPoolHelpers/IPoolLP.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title Contains the useful methods to a liquidity provider
*/
interface IPoolLP {
    
    /**
    * @notice Add liquidity to a pool and credit msg.sender
    * @dev The order of maxAmount of each token must be the same as the _tokens' addresses stored in the pool
    * @param poolAmountOut Amount of pool shares a LP wishes to receive
    * @param maxAmountsIn Maximum accepted token amount in
    */
    function joinPool(
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    )
    external;

    /**
    * @notice Get the token amounts in required and pool shares received when joining
    * the pool given an amount of tokenIn
    * @dev The amountIn of the specified token as input may differ at the exit due to
    * rounding discrepancies
    * @param  tokenIn The address of tokenIn
    * @param  tokenAmountIn The approximate amount of tokenIn to be swapped
    * @return poolAmountOut The pool amount out received
    * @return tokenAmountsIn The exact amounts of tokenIn needed
    */
    function getJoinPool(
        address tokenIn,
        uint256 tokenAmountIn
    )
    external
    view
    returns (uint256 poolAmountOut, uint256[] memory tokenAmountsIn);

    /**
    * @notice Remove liquidity from a pool
    * @dev The order of minAmount of each token must be the same as the _tokens' addresses stored in the pool
    * @param poolAmountIn Amount of pool shares a LP wishes to liquidate for tokens
    * @param minAmountsOut Minimum accepted token amount out
    */
    function exitPool(
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
    external;
    
    /**
    * @notice Get the token amounts received for a given pool shares in
    * @param poolAmountIn The amount of pool shares a LP wishes to liquidate for tokens
    * @return tokenAmountsOut The token amounts received
    */
    function getExitPool(uint256 poolAmountIn)
    external
    view
    returns (uint256[] memory tokenAmountsOut);

    /**
    * @notice Join a pool with a single asset with a fixed amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the joinswap
    * @param tokenIn The address of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be added to the pool
    * @param minPoolAmountOut The minimum amount of pool tokens that can be received
    * @return poolAmountOut The received pool amount out
    */
    function joinswapExternAmountInMMM(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
    external
    returns (uint poolAmountOut);

    /**
    * @notice Computes the amount of pool tokens received when joining a pool with a single asset of fixed amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the joinswap
    * @param tokenIn The address of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be added to the pool
    * @return poolAmountOut The received pool token amount out
    */
    function getJoinswapExternAmountInMMM(
        address tokenIn,
        uint256 tokenAmountIn
    )
    external
    view
    returns (uint256 poolAmountOut);

    /**
    * @notice Exit a pool with a single asset given the pool token amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the exitswap
    * @param tokenOut The address of tokenOut
    * @param poolAmountIn The fixed amount of pool tokens in
    * @param minAmountOut The minimum amount of token out that can be receied
    * @return tokenAmountOut The received token amount out
    */
    function exitswapPoolAmountInMMM(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
    external
    returns (uint tokenAmountOut);

}

// File: contracts/interfaces/IPoolHelpers/IPoolSwap.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title Contains the useful methods to a trader
*/
interface IPoolSwap{

    /**
    * @notice Swap two tokens given the exact amount of token in
    * @param tokenIn The address of the input token
    * @param tokenAmountIn The exact amount of tokenIn to be swapped
    * @param tokenOut The address of the received token
    * @param minAmountOut The minimum accepted amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return tokenAmountOut The token amount out received
    * @return spotPriceAfter The spot price of tokenOut in terms of tokenIn after the swap
    */
    function swapExactAmountInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
    external
    returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    /**
    * @notice Computes the amount of tokenOut received when swapping a fixed amount of tokenIn
    * @param tokenIn The address of the input token
    * @param tokenAmountIn The fixed amount of tokenIn to be swapped
    * @param tokenOut The address of the received token
    * @param minAmountOut The minimum amount of tokenOut that can be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return swapResult The swap result (amount out, spread and tax base in)
    * @return priceResult The price result (spot price before & after the swap, latest oracle price in & out)
    */
    function getAmountOutGivenInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
    external view
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult);

    /**
    * @notice Swap two tokens given the exact amount of token out
    * @param tokenIn The address of the input token
    * @param maxAmountIn The maximum amount of tokenIn that can be swapped
    * @param tokenOut The address of the received token
    * @param tokenAmountOut The exact amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return tokenAmountIn The amount of tokenIn added to the pool
    * @return spotPriceAfter The spot price of token out in terms of token in after the swap
    */
    function swapExactAmountOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
    external
    returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    /**
    * @notice Computes the amount of tokenIn needed to receive a fixed amount of tokenOut
    * @param tokenIn The address of the input token
    * @param maxAmountIn The maximum amount of tokenIn that can be swapped
    * @param tokenOut The address of the received token
    * @param tokenAmountOut The fixed accepted amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return swapResult The swap result (amount in, spread and tax base in)
    * @return priceResult The price result (spot price before & after the swap, latest oracle price in & out)
    */
    function getAmountInGivenOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
    external view
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult);
}

// File: contracts/interfaces/IPoolHelpers/IPoolState.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title Contains the useful methods to get the Pool's parameters and state
*/
interface IPoolState{
    
    /**
    * @dev Returns true if a trader can swap on the pool
    */
    function isPublicSwap() external view returns (bool);

    /**
    * @dev Returns true if a liquidity provider can join the pool
    * A trader can swap on the pool if the pool is either finalized or isPublicSwap
    */
    function isFinalized() external view returns (bool);

    /**
    * @dev Returns true if the token is binded to the pool
    */
    function isBound(address t) external view returns (bool);

    /**
    * @dev Returns the binded tokens
    */
    function getTokens() external view returns (address[] memory tokens);
    
    /**
    * @dev Returns the initial weight of a binded token
    * The initial weight is the un-adjusted weight set by the controller at bind
    * The adjusted weight is the corrected weight based on the token's price performance:
    * adjusted_weight = initial_weight * current_price / initial_price
    */
    function getDenormalizedWeight(address token) external view returns (uint256);
    
    /**
    * @dev Returns the balance of a binded token
    */
    function getBalance(address token) external view returns (uint256);
    
    /**
    * @dev Returns the swap fee of the pool
    */
    function getSwapFee() external view returns (uint256);
    
    /**
    * @dev Returns the current controller of the pool
    */
    function getController() external view returns (address);
    
    /**
    * @dev Returns the coverage parameters of the pool
    */
    function getCoverageParameters() external view returns (
        uint8   priceStatisticsLBInRound,
        uint8   priceStatisticsLBStepInRound,
        uint64  dynamicCoverageFeesZ,
        uint256 dynamicCoverageFeesHorizon,
        uint256 priceStatisticsLBInSec,
        uint256 maxPriceUnpegRatio
    );

    /**
    * @dev Returns the token's price when it was binded to the pool
    */
    function getTokenOracleInitialPrice(address token) external view returns (uint256);

    /**
    * @dev Returns the oracle's address of a token
    */
    function getTokenPriceOracle(address token) external view returns (address);

    /**
    * @dev Absorb any tokens that have been sent to this contract into the pool
    * @param token The token's address
    */
    function gulp(address token) external;

    /**
    * @notice Returns the spot price without fees of a token pair
    * @return spotPrice The spot price of tokenOut in terms of tokenIn
    */
    function getSpotPriceSansFee(address tokenIn, address tokenOut) 
    external view
    returns (uint256 spotPrice);
}

// File: contracts/interfaces/IPoolHelpers/IPoolEvents.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title Contains the pool's events
*/
interface IPoolEvents {
    
    /**
    * @notice Emitted after each swap
    * @param caller The trader's address
    * @param tokenIn The tokenIn's address
    * @param tokenOut The tokenOut's address
    * @param tokenAmountIn The amount of the swapped tokenIn
    * @param tokenAmountOut The amount of the swapped tokenOut
    * @param spread The spread
    * @param taxBaseIn The amount of tokenIn swapped when in shortage of tokenOut
    * @param priceIn The latest price of tokenIn given by the oracle
    * @param priceOut The latest price of tokenOut given by the oracle
    */
    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut,
        uint256         spread,
        uint256         taxBaseIn,
        uint256         priceIn,
        uint256         priceOut
    );

    /**
    * @notice Emitted when an LP joins the pool with 1 or multiple assets
    * @param caller The LP's address
    * @param tokenIn The dposited token's address
    * @param tokenAmountIn The deposited amount of tokenIn
    */
    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    /**
    * @notice Emitted when an LP withdraws one or multiple assets from the pool
    * @param caller The LP's address
    * @param tokenOut The withdrawn token's address
    * @param tokenAmountOut The withdrawn amount of tokenOut
    */
    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    /**
    * @param sig The function's signature
    * @param caller The caller's address
    * @param data The input data of the call
    */
    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    /**
    * @notice Emitted when a new controller is assigned to the pool
    * @param from The previous controller's address
    * @param to The new controller's address
    */
    event LOG_NEW_CONTROLLER(
        address indexed from,
        address indexed to
    );

    /**
    * @notice Emitted when a token is binded/rebinded
    * @param token The binded token's address
    * @param oracle The assigned oracle's address
    * @param price The latest token's price reported by the oracle
    * @param description The oracle's description
    */
    event LOG_NEW_ORACLE_STATE(
        address indexed token,
        address oracle,
        uint256 price,
        uint8   decimals,
        string  description
    );

}

// File: contracts/interfaces/IPoolHelpers/IPoolControl.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



/**
* @title Contains the useful methods to a pool controller
*/
interface IPoolControl {

    /**
    * @notice Revokes factory control over pool parameters
    * @dev Factory control can only be revoked by the factory and not the pool controller
    */
    function revokeFactoryControl() external;

    /**
    * @notice Gives back factory control over the pool parameters
    */
    function giveFactoryControl() external;
    
    /**
    * @notice Allows a controller to transfer ownership to a new address
    * @dev It is recommended to use transferOwnership/acceptOwnership logic for safer transfers
    * to avoid any faulty input
    * This function is useful when creating pools using a proxy contract and transfer pool assets
    * WARNING: Binded assets are also transferred to the new controller if the pool is not finalized
    */  
    function setControllerAndTransfer(address controller) external;
    
    /**
    * @notice Allows a controller to begin transferring ownership to a new address
    * @dev The function will revert if there are binded tokens in an un-finalized pool
    * This prevents any accidental loss of funds for the current controller
    */
    function transferOwnership(address pendingController) external;
    
    /**
    * @notice Allows a controller transfer to be completed by the recipient
    */
    function acceptOwnership() external;
    
    /**
    * @notice Bind a new token to the pool
    * @param token The token's address
    * @param balance The token's balance
    * @param denorm The token's weight
    * @param priceFeedAddress The token's Chainlink price feed
    */
    function bindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress) external;
    
    /**
    * @notice Replace a binded token's balance, weight and price feed's address
    * @param token The token's address
    * @param balance The token's balance
    * @param denorm The token's weight
    * @param priceFeedAddress The token's Chainlink price feed
    */
    function rebindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress) external;
    
    /**
    * @notice Unbind a token from the pool
    * @dev The function will return the token's balance back to the controller
    * @param token The token's address
    */
    function unbindMMM(address token) external;
    
    /**
    * @notice Enables public swaps on the pool but does not finalize the parameters
    * @dev Unfinalized pool enables exclusively the controller to add liquidity into the pool
    */
    function setPublicSwap(bool publicSwap) external;

    /**
    * @notice Enables publicswap and finalizes the pool's tokens, price feeds, initial shares, balances and weights
    */
    function finalize() external;
    
    /** 
    * @notice Sets swap fee
    */
    function setSwapFee(uint256 swapFee) external;
    
    /**
    * @notice Sets dynamic coverage fees Z
    */
    function setDynamicCoverageFeesZ(uint64 dynamicCoverageFeesZ) external;
    
    /**
    * @notice Sets dynamic coverage fees horizon
    */
    function setDynamicCoverageFeesHorizon(uint256 dynamicCoverageFeesHorizon) external;
    
    /**
    * @notice Sets price statistics maximum lookback in round
    */
    function setPriceStatisticsLookbackInRound(uint8 priceStatisticsLookbackInRound) external;
    
    /** 
    * @notice Sets price statistics maximum lookback in seconds
    */
    function setPriceStatisticsLookbackStepInRound(uint8 priceStatisticsLookbackStepInRound) external;
    
    /**
    * @notice Sets price statistics lookback step in round
    * @dev This corresponds to the roundId lookback step when looking for historical prices
    */
    function setPriceStatisticsLookbackInSec(uint256 priceStatisticsLookbackInSec) external;

    /**
    * @notice Sets price statistics maximum unpeg ratio
    */
    function setMaxPriceUnpegRatio(uint256 maxPriceUnpegRatio) external;
}

// File: contracts/interfaces/IPool.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.








/**
* @title The interface for a Swaap V1 Pool
*/
interface IPool is 
    IPoolLP,
    IPoolSwap,
    IPoolState,
    IPoolToken,
    IPoolEvents,
    IPoolControl
{

}

// File: contracts/interfaces/IDecimals.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.



interface IDecimals {
    function decimals() external view returns(uint8);
}

// File: contracts/Pool.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.








contract Pool is PoolToken, IPool {

    using SafeERC20 for IERC20; 

    struct Record {
        bool bound;   // is token bound to pool
        uint8 index;   // private
        uint8 decimals; // token decimals + oracle decimals
        uint80 denorm;  // denormalized weight
        uint256 balance;
    }

    // putting modifier logic in functions enables contract size optimization
    function _emitLog() private {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
    }

    modifier _logs_() {
        _emitLog();
        _;
    }

    function _lock() private {
        _require(!_mutex, Err.REENTRY);
        _mutex = true;
    }

    function _unlock() private {
        _mutex = false;
    }

    modifier _lock_() {
        _lock();
        _;
        _unlock();
    }

    modifier _viewlock_() {
        _require(!_mutex, Err.REENTRY);
        _;
    }

    function _whenNotPaused() private view {
        IFactory(_factory).whenNotPaused();
    }

    modifier _whenNotPaused_() {
        _whenNotPaused();
        _;
    }

    function _onlyAdmins() private view {
        if (msg.sender == _controller) {
            _require(!_finalized, Err.IS_FINALIZED);
        }
        else if (msg.sender == _factory) {
            _require(!_revokedFactoryControl, Err.FACTORY_CONTROL_REVOKED);
        }
        else {
            _revert(Err.NOT_ADMIN);
        }
    }

    modifier _onlyAdmins_() {
        _onlyAdmins();
        _;
    }

    // prevents token transfers with fees
    modifier _checkBalanceAfterTransfer_(address erc20, uint amount) {
        uint expectedBalance = IERC20(erc20).balanceOf(address(this)) + amount;
        _;
        uint currentBalance = IERC20(erc20).balanceOf(address(this));
        _require(expectedBalance == currentBalance, Err.UNEXPECTED_BALANCE);
    }

    address[] private _tokens;
    mapping(address=>Record) private _records;

    bool    private _mutex;
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool    private _publicSwap; // true if PUBLIC can call SWAP functions
    
    bool    private _finalized;
    bool    private _revokedFactoryControl; // if true factory cannot change pool parameters
    address immutable private _factory; // Factory address to push token exitFee to

    // Coverage parameters
    uint8   private _priceStatisticsLookbackInRound;
    uint8   private _priceStatisticsLookbackStepInRound;
    uint64  private _dynamicCoverageFeesZ;
    uint256 private _dynamicCoverageFeesHorizon;
    uint256 private _priceStatisticsLookbackInSec;
    uint256 private _maxPriceUnpegRatio;

    // Pool's swap fee
    uint256 private _swapFee;

    uint80  private _totalWeight;
    address private _controller; // has CONTROL role
    address private _pendingController;
        
    mapping(address=>Struct.OracleState) private _oraclesInitialState;


    constructor() {
        _controller = msg.sender;
        _factory = msg.sender;
        // Pool swap fee
        _swapFee = Const.MIN_FEE;
        // Coverage parameters
        _priceStatisticsLookbackInRound = Const.BASE_LOOKBACK_IN_ROUND;
        _priceStatisticsLookbackStepInRound = Const.LOOKBACK_STEP_IN_ROUND;
        _dynamicCoverageFeesZ = Const.BASE_Z;
        _dynamicCoverageFeesHorizon = Const.BASE_HORIZON;
        _priceStatisticsLookbackInSec = Const.BASE_LOOKBACK_IN_SEC;
        _maxPriceUnpegRatio = Const.BASE_MAX_PRICE_UNPEG_RATIO;
    }

    /**
    * @dev Returns true if a trader can swap on the pool
    */
    function isPublicSwap()
    external view
    _viewlock_
    returns (bool)
    {
        return _publicSwap;
    }

    /**
    * @dev Returns true if a liquidity provider can join the pool
    * A trader can swap on the pool if the pool is either finalized or isPublicSwap
    */
    function isFinalized()
    external view
    _viewlock_
    returns (bool)
    {
        return _finalized;
    }

    /**
    * @dev Returns true if the token is binded to the pool
    */
    function isBound(address t)
    external view
    _viewlock_
    returns (bool)
    {
        return _records[t].bound;
    }

    /**
    * @dev Returns the binded tokens
    */
    function getTokens()
    external view
    _viewlock_
    returns (address[] memory tokens)
    {
        return _tokens;
    }

    /**
    * @dev Returns the initial weight of a binded token
    * The initial weight is the un-adjusted weight set by the controller at bind
    * The adjusted weight is the corrected weight based on the token's price performance:
    * adjusted_weight = initial_weight * current_price / initial_price
    */
    function getDenormalizedWeight(address token)
    external view
    _viewlock_
    returns (uint256)
    {
        _require(_records[token].bound, Err.NOT_BOUND);
        return _records[token].denorm;
    }

    /**
    * @dev Returns the balance of a binded token
    */
    function getBalance(address token)
    external view
    _viewlock_
    returns (uint256)
    {
        _require(_records[token].bound, Err.NOT_BOUND);
        return _records[token].balance;
    }

    /**
    * @dev Returns the swap fee of the pool
    */
    function getSwapFee()
    external view
    _viewlock_
    returns (uint256)
    {
        return _swapFee;
    }

    /**
    * @dev Returns the current controller of the pool
    */
    function getController()
    external view
    _viewlock_
    returns (address)
    {
        return _controller;
    }

    /**
    * @notice Sets swap fee
    */
    function setSwapFee(uint256 swapFee)
    external
    _logs_
    _lock_
    _onlyAdmins_
    {
        _require(swapFee >= Const.MIN_FEE, Err.MIN_FEE);
        _require(swapFee <= Const.MAX_FEE, Err.MAX_FEE);
        _swapFee = swapFee;
    }

    /**
    * @notice Allows a controller to transfer ownership to a new address
    * @dev It is recommended to use transferOwnership/acceptOwnership logic for safer transfers
    * to avoid any faulty input
    * This function is useful when creating pools using a proxy contract and transfer pool assets
    * WARNING: Binded assets are also transferred to the new controller if the pool is not finalized
    */  
    function setControllerAndTransfer(address controller)
    external
    _lock_
    {
        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        _require(controller != address(0), Err.NULL_CONTROLLER);
        _controller = controller;
        _pendingController = address(0);
        emit LOG_NEW_CONTROLLER(msg.sender, controller);
    }
    
    /**
    * @notice Allows a controller to begin transferring ownership to a new address
    * @dev The function will revert if there are binded tokens in an un-finalized pool
    * This prevents any accidental loss of funds for the current controller
    */
    function transferOwnership(address pendingController)
    external
    _logs_
    {
        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        if(!_finalized){
            // This condition prevents any accidental transfer of funds between the old and new controller
            // when the pool is not finalized
            _require(_tokens.length == 0 ,Err.BINDED_TOKENS);
        }
        _pendingController = pendingController;
    }

    /**
    * @notice Allows a controller transfer to be completed by the recipient
    */
    function acceptOwnership()
    external
    {
        _require(msg.sender == _pendingController, Err.NOT_PENDING_CONTROLLER);

        address oldController = _controller;
        _controller = msg.sender;
        _pendingController = address(0);

        emit LOG_NEW_CONTROLLER(oldController, msg.sender);
    }

    /**
    * @notice Revokes factory control over pool parameters
    * @dev Factory control can only be revoked by the factory and not the pool controller
    */
    function revokeFactoryControl()
    external
    _logs_
    {
        _require(msg.sender == _factory, Err.NOT_FACTORY);
        _revokedFactoryControl = true;
    }

    /**
    * @notice Gives back factory control over the pool parameters
    */
    function giveFactoryControl()
    external
    _logs_
    {
        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        _revokedFactoryControl = false;
    }

    /**
    * @notice Enables public swaps on the pool but does not finalize the parameters
    * @dev Unfinalized pool enables exclusively the controller to add liquidity into the pool
    */
    function setPublicSwap(bool publicSwap)
    external
    _logs_
    _lock_
    {
        _require(!_finalized, Err.IS_FINALIZED);
        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        _publicSwap = publicSwap;
    }

    /**
    * @notice Enables publicswap and finalizes the pool's tokens, price feeds, initial shares, balances and weights
    */
    function finalize()
    external
    _logs_
    _lock_
    {
        _require(!_finalized, Err.IS_FINALIZED);
        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        _require(_tokens.length >= Const.MIN_BOUND_TOKENS, Err.MIN_TOKENS);

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(Const.INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, Const.INIT_POOL_SUPPLY);
    }

    /**
    * @dev Absorb any tokens that have been sent to this contract into the pool
    * @param token The token's address
    */
    function gulp(address token)
    external
    _logs_
    _lock_
    {
        _require(_records[token].bound, Err.NOT_BOUND);
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    /**
    * @notice Get the token amounts in required and pool shares received when joining
    * the pool given an amount of tokenIn
    * @dev The amountIn of the specified token as input may differ at the exit due to
    * rounding discrepancies
    * @param  tokenIn The address of tokenIn
    * @param  tokenAmountIn The approximate amount of tokenIn to be swapped
    * @return poolAmountOut The pool amount out received
    * @return tokenAmountsIn The exact amounts of tokenIn needed
    */
    function getJoinPool(address tokenIn, uint256 tokenAmountIn)
    external
    view
    _viewlock_
    _whenNotPaused_
    returns (uint256 poolAmountOut, uint256[] memory tokenAmountsIn)
    {
        _require(_finalized, Err.NOT_FINALIZED);
        _require(_records[tokenIn].bound, Err.NOT_BOUND);

        uint256 ratio = Num.divTruncated(tokenAmountIn, _records[tokenIn].balance);
        
        uint256 poolTotal = _totalSupply;
        poolAmountOut = Num.mul(ratio, poolTotal);
        // ratio is re-evaluated to avoid any calculation discrepancies with joinPool
        ratio = Num.div(poolAmountOut, poolTotal);
        _require(ratio != 0, Err.MATH_APPROX);

        uint256 tokensLength = _tokens.length;
        tokenAmountsIn = new uint256[](tokensLength);

        for (uint256 i; i < tokensLength;) {
            address t     = _tokens[i];
            uint256 bal   = _records[t].balance;
            tokenAmountIn = Num.mul(ratio, bal);
            _require(tokenAmountIn != 0, Err.MATH_APPROX);
            tokenAmountsIn[i] = tokenAmountIn;
            unchecked{++i;}
        }
        
        return (poolAmountOut, tokenAmountsIn);

    }


    /**
    * @notice Add liquidity to a pool and credit msg.sender
    * @dev The order of maxAmount of each token must be the same as the _tokens' addresses stored in the pool
    * @param poolAmountOut Amount of pool shares a LP wishes to receive
    * @param maxAmountsIn Maximum accepted token amount in
    */
    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
    _logs_
    _lock_
    _whenNotPaused_
    external
    {
        _require(_finalized, Err.NOT_FINALIZED);
        _require(maxAmountsIn.length == _tokens.length, Err.INPUT_LENGTH_MISMATCH);

        uint256 ratio = Num.div(poolAmountOut, _totalSupply);
        _require(ratio != 0, Err.MATH_APPROX);

        for (uint256 i; i < maxAmountsIn.length;) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountIn = Num.mul(ratio, bal);
            _require(tokenAmountIn != 0, Err.MATH_APPROX);
            _require(tokenAmountIn <= maxAmountsIn[i], Err.LIMIT_IN);
            _records[t].balance = bal + tokenAmountIn;
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
            unchecked{++i;}
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    /**
    * @notice Get the token amounts received for a given pool shares in
    * @param poolAmountIn The amount of pool shares a LP wishes to liquidate for tokens
    * @return tokenAmountsOut The token amounts received
    */
    function getExitPool(uint256 poolAmountIn)
    external
    view
    _viewlock_
    returns (uint256[] memory tokenAmountsOut)
    {

        _require(_finalized, Err.NOT_FINALIZED);

        uint256 exitFee = Num.mul(poolAmountIn, Const.EXIT_FEE);
        uint256 pAiAfterExitFee = poolAmountIn - exitFee;
        uint256 ratio = Num.divTruncated(pAiAfterExitFee, _totalSupply);

        uint256 tokensLength = _tokens.length;
        tokenAmountsOut = new uint256[](tokensLength);

        for (uint256 i; i < tokensLength;) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = Num.mulTruncated(ratio, bal);
            _require(tokenAmountOut != 0, Err.MATH_APPROX);
            tokenAmountsOut[i] = tokenAmountOut;
            unchecked{++i;}
        }

        return tokenAmountsOut;
    }

    /**
    * @notice Remove liquidity from a pool
    * @dev The order of minAmount of each token must be the same as the _tokens' addresses stored in the pool
    * @param poolAmountIn Amount of pool shares a LP wishes to liquidate for tokens
    * @param minAmountsOut Minimum accepted token amount out
    */
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external
    _logs_
    _lock_
    {
        _require(_finalized, Err.NOT_FINALIZED);
        _require(minAmountsOut.length == _tokens.length, Err.INPUT_LENGTH_MISMATCH);

        uint256 exitFee = Num.mul(poolAmountIn, Const.EXIT_FEE);
        uint256 pAiAfterExitFee = poolAmountIn - exitFee;
        uint256 ratio = Num.divTruncated(pAiAfterExitFee, _totalSupply);
        _require(ratio != 0, Err.MATH_APPROX);

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_factory, exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint256 i; i < minAmountsOut.length;) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = Num.mulTruncated(ratio, bal);
            _require(tokenAmountOut != 0, Err.MATH_APPROX);
            _require(tokenAmountOut >= minAmountsOut[i], Err.LIMIT_OUT);

            _records[t].balance = _records[t].balance - tokenAmountOut;
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
            unchecked{++i;}
        }

    }

    /**
    * @notice Computes the amount of pool tokens received when joining a pool with a single asset of fixed amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the joinswap
    * @param tokenIn The address of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be added to the pool
    * @return poolAmountOut The received pool token amount out
    */
    function getJoinswapExternAmountInMMM(address tokenIn, uint256 tokenAmountIn)
    external
    view
    _viewlock_
    _whenNotPaused_
    returns (uint256 poolAmountOut)
    {
        return (poolAmountOut = _getJoinswapExternAmountInMMM(tokenIn, tokenAmountIn));
    }

    function _getJoinswapExternAmountInMMM(address tokenIn, uint256 tokenAmountIn)
    internal
    view
    returns (uint256 poolAmountOut)
    {
        _require(_finalized, Err.NOT_FINALIZED);
        _require(_records[tokenIn].bound, Err.NOT_BOUND);
        _require(tokenAmountIn <= Num.mul(_records[tokenIn].balance, Const.MAX_IN_RATIO), Err.MAX_IN_RATIO);

        Struct.TokenGlobal memory tokenInInfo;
        Struct.TokenGlobal[] memory remainingTokensInfo;
        (tokenInInfo, remainingTokensInfo) = _getAllTokensInfo(tokenIn);

        {
            Struct.JoinExitSwapParameters memory joinswapParameters = Struct.JoinExitSwapParameters(
                tokenAmountIn,
                _swapFee,
                Const.FALLBACK_SPREAD,
                _totalSupply
            );
            Struct.GBMParameters memory gbmParameters = Struct.GBMParameters(
                _dynamicCoverageFeesZ,
                _dynamicCoverageFeesHorizon
            );
            Struct.HistoricalPricesParameters memory hpParameters = Struct.HistoricalPricesParameters(
                _priceStatisticsLookbackInRound,
                _priceStatisticsLookbackInSec,
                block.timestamp,
                _priceStatisticsLookbackStepInRound
            );

            poolAmountOut = Math.calcPoolOutGivenSingleInMMM(
                tokenInInfo,
                remainingTokensInfo,
                joinswapParameters,
                gbmParameters,
                hpParameters
            );

            tokenInInfo.info.balance += tokenAmountIn;
            _checkJoinSwapPrices(tokenInInfo, remainingTokensInfo);

            return poolAmountOut;
        }
    }

    /**
    * @notice Join a pool with a single asset with a fixed amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the joinswap
    * @param tokenIn The address of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be added to the pool
    * @param minPoolAmountOut The minimum amount of pool tokens that can be received
    * @return poolAmountOut The received pool amount out
    */
    function joinswapExternAmountInMMM(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
    external
    _logs_
    _lock_
    _whenNotPaused_
    returns (uint poolAmountOut)
    {        
        poolAmountOut = _getJoinswapExternAmountInMMM(
            tokenIn, tokenAmountIn
        );

        _require(poolAmountOut >= minPoolAmountOut, Err.LIMIT_OUT);

        _records[tokenIn].balance = _records[tokenIn].balance + tokenAmountIn;

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);

        return poolAmountOut;
    }

    /**
    * @notice Exit a pool with a single asset given the pool token amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the exitswap
    * @param tokenOut The address of tokenOut
    * @param poolAmountIn The fixed amount of pool tokens in
    * @param minAmountOut The minimum amount of token out that can be receied
    * @return tokenAmountOut The received token amount out
    */
    function exitswapPoolAmountInMMM(address tokenOut, uint poolAmountIn, uint minAmountOut)
    external
    _logs_
    _lock_
    _whenNotPaused_
    returns (uint tokenAmountOut)
    {
        _require(_finalized, Err.NOT_FINALIZED);
        _require(_records[tokenOut].bound, Err.NOT_BOUND);

        Struct.TokenGlobal memory tokenOutInfo;
        Struct.TokenGlobal[] memory remainingTokensInfo;

        (tokenOutInfo, remainingTokensInfo) = _getAllTokensInfo(tokenOut);

        {
            Struct.JoinExitSwapParameters memory exitswapParameters = Struct.JoinExitSwapParameters(
                poolAmountIn,
                _swapFee,
                Const.FALLBACK_SPREAD,
                _totalSupply
            );
            Struct.GBMParameters memory gbmParameters = Struct.GBMParameters(
                _dynamicCoverageFeesZ,
                _dynamicCoverageFeesHorizon
            );
            Struct.HistoricalPricesParameters memory hpParameters = Struct.HistoricalPricesParameters(
                _priceStatisticsLookbackInRound,
                _priceStatisticsLookbackInSec,
                block.timestamp,
                _priceStatisticsLookbackStepInRound
            );

            tokenAmountOut = Math.calcSingleOutGivenPoolInMMM(
                tokenOutInfo,
                remainingTokensInfo,
                exitswapParameters,
                gbmParameters,
                hpParameters
            );
            _require(tokenAmountOut <= Num.mul(_records[tokenOut].balance, Const.MAX_OUT_RATIO), Err.MAX_OUT_RATIO);
        }

        _require(tokenAmountOut >= minAmountOut, Err.LIMIT_OUT);

        tokenOutInfo.info.balance -= tokenAmountOut;
        _checkExitSwapPrices(tokenOutInfo, remainingTokensInfo);
        _records[tokenOut].balance = tokenOutInfo.info.balance;

        uint exitFee =  Num.mul(poolAmountIn, Const.EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn - exitFee);
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    /**
    * @dev 'Underlying' token-manipulation functions make external calls but are NOT locked
    * You must `_lock_` or otherwise ensure reentry-safety
    */
    function _pullUnderlying(address erc20, address from, uint256 amount)
    internal
    _checkBalanceAfterTransfer_(erc20, amount)
    {
        IERC20(erc20).safeTransferFrom(from, address(this), amount);
    }

    /**
    * @dev 'Underlying' token-manipulation functions make external calls but are NOT locked
    * You must `_lock_` or otherwise ensure reentry-safety
    */
    function _pushUnderlying(address erc20, address to, uint256 amount)
    internal
    {
        IERC20(erc20).safeTransfer(to, amount);
    }

    function _pullPoolShare(address from, uint256 amount)
    internal
    {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount)
    internal
    {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount)
    internal
    {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount)
    internal
    {
        _burn(amount);
    }

    /**
    * @notice Sets dynamic coverage fees Z
    */
    function setDynamicCoverageFeesZ(uint64 dynamicCoverageFeesZ)
    external
    _logs_
    _lock_
    _onlyAdmins_
    {
        _dynamicCoverageFeesZ = dynamicCoverageFeesZ;
    }

    /**
    * @notice Sets dynamic coverage fees horizon
    */
    function setDynamicCoverageFeesHorizon(uint256 dynamicCoverageFeesHorizon)
    external
    _logs_
    _lock_
    _onlyAdmins_
    {
        _require(dynamicCoverageFeesHorizon >= Const.MIN_HORIZON, Err.MIN_HORIZON);
        _dynamicCoverageFeesHorizon = dynamicCoverageFeesHorizon;
    }

    /**
    * @notice Sets price statistics maximum lookback in round
    */
    function setPriceStatisticsLookbackInRound(uint8 priceStatisticsLookbackInRound)
    external
    _logs_
    _lock_
    _onlyAdmins_
    {
        _require(priceStatisticsLookbackInRound >= Const.MIN_LOOKBACK_IN_ROUND, Err.MIN_LB_PERIODS);
        _require(priceStatisticsLookbackInRound <= Const.MAX_LOOKBACK_IN_ROUND, Err.MAX_LB_PERIODS);
        _priceStatisticsLookbackInRound = priceStatisticsLookbackInRound;
    }

    /** 
    * @notice Sets price statistics maximum lookback in seconds
    */
    function setPriceStatisticsLookbackInSec(uint256 priceStatisticsLookbackInSec)
    external
    _logs_
    _lock_
    _onlyAdmins_
    {
        _require(priceStatisticsLookbackInSec >= Const.MIN_LOOKBACK_IN_SEC, Err.MIN_LB_SECS);
        _priceStatisticsLookbackInSec = priceStatisticsLookbackInSec;
    }

    /**
    * @notice Sets price statistics lookback step in round
    * @dev This corresponds to the roundId lookback step when looking for historical prices
    */
    function setPriceStatisticsLookbackStepInRound(uint8 priceStatisticsLookbackStepInRound)
    external
    _logs_
    _lock_
    _onlyAdmins_
    {
        _require(priceStatisticsLookbackStepInRound >= Const.MIN_LOOKBACK_STEP_IN_ROUND, Err.MIN_LB_STEP_PERIODS);
        _priceStatisticsLookbackStepInRound = priceStatisticsLookbackStepInRound;
    }

    /**
    * @notice Sets price statistics maximum unpeg ratio
    */
    function setMaxPriceUnpegRatio(uint256 maxPriceUnpegRatio)
    external
    _logs_
    _lock_
    {
        _require(msg.sender == _factory, Err.NOT_FACTORY);
        _require(!_revokedFactoryControl, Err.FACTORY_CONTROL_REVOKED);
        _require(maxPriceUnpegRatio >= Const.MIN_MAX_PRICE_UNPEG_RATIO, Err.MIN_MAX_PRICE_UNPEG_RATIO);
        _require(maxPriceUnpegRatio <= Const.MAX_MAX_PRICE_UNPEG_RATIO, Err.MAX_MAX_PRICE_UNPEG_RATIO);
        _maxPriceUnpegRatio = maxPriceUnpegRatio;
    }

    /**
    * @dev Returns the coverage parameters of the pool
    */
    function getCoverageParameters()
    external view
    _viewlock_
    returns (
            uint8   priceStatisticsLBInRound,
            uint8   priceStatisticsLBStepInRound,
            uint64  dynamicCoverageFeesZ,
            uint256 dynamicCoverageFeesHorizon,
            uint256 priceStatisticsLBInSec,
            uint256 maxPriceUnpegRatio
        )
    {
        return (
            priceStatisticsLBInRound     = _priceStatisticsLookbackInRound,
            priceStatisticsLBStepInRound = _priceStatisticsLookbackStepInRound,
            dynamicCoverageFeesZ         = _dynamicCoverageFeesZ,
            dynamicCoverageFeesHorizon   = _dynamicCoverageFeesHorizon,
            priceStatisticsLBInSec       = _priceStatisticsLookbackInSec,
            maxPriceUnpegRatio           = _maxPriceUnpegRatio
        );
    }

    /**
    * @dev Returns the token's price when it was binded to the pool
    */
    function getTokenOracleInitialPrice(address token)
    external view
    _viewlock_
    returns (uint256)
    {
        _require(_records[token].bound, Err.NOT_BOUND);
        return _oraclesInitialState[token].price;
    }

    /**
    * @dev Returns the oracle's address of a token
    */
    function getTokenPriceOracle(address token)
    external view
    _viewlock_
    returns (address)
    {
        _require(_records[token].bound, Err.NOT_BOUND);
        return _oraclesInitialState[token].oracle;
    }

    /**
    * @notice Bind a new token to the pool
    * @param token The token's address
    * @param balance The token's balance
    * @param denorm The token's weight
    * @param priceFeedAddress The token's Chainlink price feed
    */
    function bindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress)
    external
    {
        _require(!_records[token].bound, Err.IS_BOUND);

        _require(_tokens.length < Const.MAX_BOUND_TOKENS, Err.MAX_TOKENS);

        _records[token] = Record(
            {
                bound: true,
                index: uint8(_tokens.length),
                decimals: 0,
                denorm: 0,    // balance and denorm will be validated
                balance: 0   // and set by `rebind`
            }
        );
        _tokens.push(token);
        _rebindMMM(token, balance, denorm, priceFeedAddress);
    }

    /**
    * @notice Replace a binded token's balance, weight and price feed's address
    * @param token The token's address
    * @param balance The token's balance
    * @param denorm The token's weight
    * @param priceFeedAddress The token's Chainlink price feed
    */
    function rebindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress)
    external
    {
        _require(_records[token].bound, Err.NOT_BOUND);

        _rebindMMM(token, balance, denorm, priceFeedAddress);
    }

    function _rebindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress)
    internal 
    _logs_
    _lock_
    _whenNotPaused_
    {
        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        _require(!_finalized, Err.IS_FINALIZED);
        _require(_pendingController == address(0), Err.PENDING_NEW_CONTROLLER);

        _require(denorm >= Const.MIN_WEIGHT, Err.MIN_WEIGHT);
        _require(denorm <= Const.MAX_WEIGHT, Err.MAX_WEIGHT);
        _require(balance >= Const.MIN_BALANCE, Err.MIN_BALANCE);

        // Adjust the denorm and totalWeight
        uint80 oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = _totalWeight + (denorm - oldWeight);
            _require(_totalWeight <= Const.MAX_TOTAL_WEIGHT, Err.MAX_TOTAL_WEIGHT);
        } else if (denorm < oldWeight) {
            _totalWeight = (_totalWeight - oldWeight) + denorm;
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint256 oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, balance - oldBalance);
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint256 tokenBalanceWithdrawn = oldBalance - balance;
            uint256 tokenExitFee = Num.mul(tokenBalanceWithdrawn, Const.EXIT_FEE);
            _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn - tokenExitFee);
            _pushUnderlying(token, _factory, tokenExitFee);
        }

        (
            uint256 price,
            uint8 decimals,
            string memory description
        ) = ChainlinkUtils.getTokenLatestPrice(priceFeedAddress);

        _records[token].decimals = decimals + _tryGetTokenDecimals(token);

        // Updating oracle state
        _oraclesInitialState[token] = Struct.OracleState(
            {
                oracle: priceFeedAddress,
                price: price // set right below
            }
        );

        emit LOG_NEW_ORACLE_STATE(
            token,
            priceFeedAddress,
            price,
            decimals,
            description
        );
    }

    /**
    * @notice Unbind a token from the pool
    * @dev The function will return the token's balance back to the controller
    * @param token The token's address
    */
    function unbindMMM(address token)
    external
    _logs_
    _lock_
    {

        _require(msg.sender == _controller, Err.NOT_CONTROLLER);
        _require(_records[token].bound, Err.NOT_BOUND);
        _require(!_finalized, Err.IS_FINALIZED);

        uint256 tokenBalance = _records[token].balance;
        uint256 tokenExitFee = Num.mul(tokenBalance, Const.EXIT_FEE);

        _totalWeight = _totalWeight - _records[token].denorm;

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint8 index = _records[token].index;
        uint256 last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        delete _records[token];
        delete _oraclesInitialState[token];

        _pushUnderlying(token, msg.sender, tokenBalance - tokenExitFee);
        _pushUnderlying(token, _factory, tokenExitFee);

    }

    /**
    * @notice Returns the spot price without fees of a token pair
    * @return spotPrice The spot price of tokenOut in terms of tokenIn
    */
    function getSpotPriceSansFee(address tokenIn, address tokenOut)
    external view
    _viewlock_
    returns (uint256 spotPrice)
    {
        _require(_records[tokenIn].bound && _records[tokenOut].bound, Err.NOT_BOUND);
        // The weights are corrected by the price change of each token
        Struct.TokenGlobal memory tokenGlobalIn = getTokenLatestInfo(tokenIn);
        Struct.TokenGlobal memory tokenGlobalOut = getTokenLatestInfo(tokenOut);
        return spotPrice = Math.calcSpotPrice(
            tokenGlobalIn.info.balance,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance,
            tokenGlobalOut.info.weight,
            0
        );
    }

    /**
    * @notice Swap two tokens given the exact amount of token in
    * @param tokenIn The address of the input token
    * @param tokenAmountIn The exact amount of tokenIn to be swapped
    * @param tokenOut The address of the received token
    * @param minAmountOut The minimum accepted amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return tokenAmountOut The token amount out received
    * @return spotPriceAfter The spot price of tokenOut in terms of tokenIn after the swap
    */
    function swapExactAmountInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
    external
    _logs_
    _lock_
    _whenNotPaused_
    returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult) = _getAmountOutGivenInMMM(
            tokenIn,
            tokenAmountIn,
            tokenOut,
            minAmountOut,
            maxPrice
        );

        _records[tokenIn].balance += tokenAmountIn;
        _records[tokenOut].balance -= swapResult.amount;

        emit LOG_SWAP(
            msg.sender, tokenIn, tokenOut, tokenAmountIn,
            swapResult.amount, swapResult.spread, swapResult.taxBaseIn,
            priceResult.priceIn, priceResult.priceOut
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, swapResult.amount);

        return (tokenAmountOut = swapResult.amount, spotPriceAfter = priceResult.spotPriceAfter);
    }

    /**
    * @notice Computes the amount of tokenOut received when swapping a fixed amount of tokenIn
    * @param tokenIn The address of the input token
    * @param tokenAmountIn The fixed amount of tokenIn to be swapped
    * @param tokenOut The address of the received token
    * @param minAmountOut The minimum amount of tokenOut that can be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return swapResult The swap result (amount out, spread and tax base in)
    * @return priceResult The price result (spot price before & after the swap, latest oracle price in & out)
    */
    function getAmountOutGivenInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
    external view
    _viewlock_
    _whenNotPaused_
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult)
    {
        return _getAmountOutGivenInMMM(
            tokenIn,
            tokenAmountIn,
            tokenOut,
            minAmountOut,
            maxPrice
        );
    }

    function _getAmountOutGivenInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
    internal view
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult)
    {

        _require(_records[tokenIn].bound && _records[tokenOut].bound, Err.NOT_BOUND);
        _require(_publicSwap, Err.SWAP_NOT_PUBLIC);

        _require(tokenAmountIn <= Num.mul(_records[tokenIn].balance, Const.MAX_IN_RATIO), Err.MAX_IN_RATIO);

        Struct.TokenGlobal memory tokenGlobalIn = getTokenLatestInfo(tokenIn);
        Struct.TokenGlobal memory tokenGlobalOut = getTokenLatestInfo(tokenOut);

        priceResult.spotPriceBefore = Math.calcSpotPrice(
            tokenGlobalIn.info.balance,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance,
            tokenGlobalOut.info.weight,
            _swapFee
        );

        _require(priceResult.spotPriceBefore <= maxPrice, Err.BAD_LIMIT_PRICE);

        swapResult = _getAmountOutGivenInMMMWithTimestamp(
            tokenGlobalIn,
            tokenGlobalOut,
            tokenAmountIn,
            block.timestamp
        );
        _require(swapResult.amount >= minAmountOut, Err.LIMIT_OUT);

        priceResult.spotPriceAfter = Math.calcSpotPrice(
            tokenGlobalIn.info.balance + tokenAmountIn,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance - swapResult.amount,
            tokenGlobalOut.info.weight,
            _swapFee
        );

        _require(priceResult.spotPriceAfter >= priceResult.spotPriceBefore, Err.MATH_APPROX);
        uint256 maxAmount = Num.divTruncated(tokenAmountIn, priceResult.spotPriceBefore);
        if (swapResult.amount > maxAmount) {
            swapResult.amount = maxAmount;
        }
        _require(
            Num.div(
                Num.mul(priceResult.spotPriceAfter, Const.ONE - _swapFee),
                ChainlinkUtils.getTokenRelativePrice(
                    tokenGlobalIn.latestRound.price,
                    tokenGlobalIn.info.decimals,
                    tokenGlobalOut.latestRound.price,
                    tokenGlobalOut.info.decimals
                )
            ) <= _maxPriceUnpegRatio,
            Err.MAX_PRICE_UNPEG_RATIO
        );

        priceResult.priceIn = tokenGlobalIn.latestRound.price;
        priceResult.priceOut = tokenGlobalOut.latestRound.price;

        return (swapResult, priceResult);
    }

    function _getAmountOutGivenInMMMWithTimestamp(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 tokenAmountIn,
        uint256 timestamp
    )
    internal view
    returns (Struct.SwapResult memory)
    {

        Struct.SwapParameters memory swapParameters = Struct.SwapParameters(
            tokenAmountIn,
            _swapFee,
            Const.FALLBACK_SPREAD
        );
        Struct.GBMParameters memory gbmParameters = Struct.GBMParameters(
            _dynamicCoverageFeesZ,
            _dynamicCoverageFeesHorizon
        );
        Struct.HistoricalPricesParameters memory hpParameters = Struct.HistoricalPricesParameters(
            _priceStatisticsLookbackInRound,
            _priceStatisticsLookbackInSec,
            timestamp,
            _priceStatisticsLookbackStepInRound
        );

        return Math.calcOutGivenInMMM(
            tokenGlobalIn,
            tokenGlobalOut,
            ChainlinkUtils.getTokenRelativePrice(
                tokenGlobalIn.latestRound.price,
                tokenGlobalIn.info.decimals,
                tokenGlobalOut.latestRound.price,
                tokenGlobalOut.info.decimals
            ),
            swapParameters,
            gbmParameters,
            hpParameters
        );

    }

    /**
    * @notice Swap two tokens given the exact amount of token out
    * @param tokenIn The address of the input token
    * @param maxAmountIn The maximum amount of tokenIn that can be swapped
    * @param tokenOut The address of the received token
    * @param tokenAmountOut The exact amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return tokenAmountIn The amount of tokenIn added to the pool
    * @return spotPriceAfter The spot price of token out in terms of token in after the swap
    */
    function swapExactAmountOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
    external
    _logs_
    _lock_
    _whenNotPaused_
    returns (uint256 tokenAmountIn, uint256 spotPriceAfter)
    {

        (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult) = _getAmountInGivenOutMMM(
            tokenIn,
            maxAmountIn,
            tokenOut,
            tokenAmountOut,
            maxPrice
        );

        _records[tokenIn].balance += swapResult.amount;
        _records[tokenOut].balance -= tokenAmountOut;

        emit LOG_SWAP(
            msg.sender, tokenIn, tokenOut, swapResult.amount,
            tokenAmountOut, swapResult.spread, swapResult.taxBaseIn,
            priceResult.priceIn, priceResult.priceOut
        );

        _pullUnderlying(tokenIn, msg.sender, swapResult.amount);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountIn = swapResult.amount, spotPriceAfter = priceResult.spotPriceAfter);
    }

    /**
    * @notice Computes the amount of tokenIn needed to receive a fixed amount of tokenOut
    * @param tokenIn The address of the input token
    * @param maxAmountIn The maximum amount of tokenIn that can be swapped
    * @param tokenOut The address of the received token
    * @param tokenAmountOut The fixed accepted amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return swapResult The swap result (amount in, spread and tax base in)
    * @return priceResult The price result (spot price before & after the swap, latest oracle price in & out)
    */
    function getAmountInGivenOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
    external view
    _viewlock_
    _whenNotPaused_
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult)
    {
        return _getAmountInGivenOutMMM(
            tokenIn,
            maxAmountIn,
            tokenOut,
            tokenAmountOut,
            maxPrice
        );
    }

    function _getAmountInGivenOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
    internal view
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult)
    {

        _require(_records[tokenIn].bound && _records[tokenOut].bound, Err.NOT_BOUND);
        _require(_publicSwap, Err.SWAP_NOT_PUBLIC);

        _require(tokenAmountOut <= Num.mul(_records[tokenOut].balance, Const.MAX_OUT_RATIO), Err.MAX_OUT_RATIO);

        Struct.TokenGlobal memory tokenGlobalIn = getTokenLatestInfo(tokenIn);
        Struct.TokenGlobal memory tokenGlobalOut = getTokenLatestInfo(tokenOut);

        priceResult.spotPriceBefore = Math.calcSpotPrice(
            tokenGlobalIn.info.balance,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance,
            tokenGlobalOut.info.weight,
            _swapFee
        );

        _require(priceResult.spotPriceBefore <= maxPrice, Err.BAD_LIMIT_PRICE);

        swapResult = _getAmountInGivenOutMMMWithTimestamp(
            tokenGlobalIn,
            tokenGlobalOut,
            tokenAmountOut,
            block.timestamp
        );

        _require(swapResult.amount <= maxAmountIn, Err.LIMIT_IN);

        priceResult.spotPriceAfter = Math.calcSpotPrice(
            tokenGlobalIn.info.balance + swapResult.amount,
            tokenGlobalIn.info.weight,
            tokenGlobalOut.info.balance - tokenAmountOut,
            tokenGlobalOut.info.weight,
            _swapFee
        );

        _require(priceResult.spotPriceAfter >= priceResult.spotPriceBefore, Err.MATH_APPROX);
        uint256 minAmount = Num.mul(priceResult.spotPriceBefore, tokenAmountOut) + 1;
        if (swapResult.amount < minAmount) {
            swapResult.amount = minAmount;
        }
        _require(
            Num.div(
                Num.mul(priceResult.spotPriceAfter, Const.ONE - _swapFee),
                ChainlinkUtils.getTokenRelativePrice(
                    tokenGlobalIn.latestRound.price,
                    tokenGlobalIn.info.decimals,
                    tokenGlobalOut.latestRound.price,
                    tokenGlobalOut.info.decimals
                )
            ) <= _maxPriceUnpegRatio,
            Err.MAX_PRICE_UNPEG_RATIO
        );

        priceResult.priceIn = tokenGlobalIn.latestRound.price;
        priceResult.priceOut = tokenGlobalOut.latestRound.price;

        return (swapResult, priceResult);
    }

    function _getAmountInGivenOutMMMWithTimestamp(
        Struct.TokenGlobal memory tokenGlobalIn,
        Struct.TokenGlobal memory tokenGlobalOut,
        uint256 tokenAmountOut,
        uint256 timestamp
    )
    internal view
    returns (Struct.SwapResult memory)
    {
        
        Struct.SwapParameters memory swapParameters = Struct.SwapParameters(
            tokenAmountOut,
            _swapFee,
            Const.FALLBACK_SPREAD
        );
        Struct.GBMParameters memory gbmParameters = Struct.GBMParameters(
            _dynamicCoverageFeesZ,
            _dynamicCoverageFeesHorizon
        );
        Struct.HistoricalPricesParameters memory hpParameters = Struct.HistoricalPricesParameters(
            _priceStatisticsLookbackInRound,
            _priceStatisticsLookbackInSec,
            timestamp,
            _priceStatisticsLookbackStepInRound
        );

        return Math.calcInGivenOutMMM(
            tokenGlobalIn,
            tokenGlobalOut,
            ChainlinkUtils.getTokenRelativePrice(
                        tokenGlobalIn.latestRound.price,
                        tokenGlobalIn.info.decimals,
                        tokenGlobalOut.latestRound.price,
                        tokenGlobalOut.info.decimals
            ),
            swapParameters,
            gbmParameters,
            hpParameters
        );

    }

    /**
    * @notice Compute the token historical performance since pool's inception
    * @param initialPrice The token's initial price
    * @param latestPrice The token's latest price
    * @return tokenGlobal The token historical performance since pool's inception
    */
    function _getTokenPerformance(uint256 initialPrice, uint256 latestPrice)
    internal pure returns (uint256) {
        return Num.div(
            latestPrice,
            initialPrice
        );
    }

    /**
    * @notice Retrieves the given token's latest oracle data.
    * @dev We get:
    * - latest round Id
    * - latest price
    * - latest round timestamp
    * - token historical performance since pool's inception
    * @param token The token's address
    * @return tokenGlobal The latest tokenIn oracle data
    */
    function getTokenLatestInfo(address token)
    internal view returns (Struct.TokenGlobal memory tokenGlobal) {
        Record memory record = _records[token];
        Struct.OracleState memory initialOracleState = _oraclesInitialState[token];
        Struct.LatestRound memory latestRound = ChainlinkUtils.getLatestRound(initialOracleState.oracle);
        Struct.TokenRecord memory info = Struct.TokenRecord(
            record.decimals,
            record.balance,
            // we adjust the token's target weight (in value) based on its appreciation since the inception of the pool.
            Num.mul(
                record.denorm,
                _getTokenPerformance(
                    initialOracleState.price,
                    latestRound.price
                )
            )
        );
        return (
            tokenGlobal = Struct.TokenGlobal(
                info,
                latestRound
            )
        );
    }

    /**
    * @notice Returns all the binded token's global information (token record + latest round info)  
    * @param swappedToken the address of the swapped token 
    * @return swappedTokenInfo swapped token's global information
    * @return remainingTokensInfo remaining tokens' global information
    */
    function _getAllTokensInfo(address swappedToken)
    private view returns (
        Struct.TokenGlobal memory swappedTokenInfo,
        Struct.TokenGlobal[] memory remainingTokensInfo
    ) {

        swappedTokenInfo = getTokenLatestInfo(swappedToken);

        uint nRemainingTokens = _tokens.length - 1;
        remainingTokensInfo = new Struct.TokenGlobal[](nRemainingTokens);
        
        // Extracting the remaining un-traded tokens' info
        uint count;
        for (uint i; count < nRemainingTokens;) {
            if (_tokens[i] != swappedToken) {
                remainingTokensInfo[count] = getTokenLatestInfo(_tokens[i]);
                unchecked{++count;}
            }
            unchecked{++i;}
        }

    }

    /**
    * @notice Check if the spot prices falls within the limits of the oracle price
    * - spot prices of the remaining tokens must be < oraclePrice * _maxPriceUnpegRatio
    * @dev tokenInInfo.info.balance should contain the balance after the trade
    * - spot prices of the remaining tokens are computed in terms of tokenIn
    * @param tokenInInfo swapped token's info
    * @param remainingTokensInfo remaining tokens' info
    */
    function _checkJoinSwapPrices (
        Struct.TokenGlobal memory tokenInInfo,
        Struct.TokenGlobal[] memory remainingTokensInfo
    ) internal view {
        
        uint256 spotPriceAfter;

        for (uint256 i; i < remainingTokensInfo.length;)
        {
            spotPriceAfter = Math.calcSpotPrice(
                tokenInInfo.info.balance,
                tokenInInfo.info.weight,
                remainingTokensInfo[i].info.balance,
                remainingTokensInfo[i].info.weight,
                0
            );

            _require(
                Num.div(
                    spotPriceAfter,
                    ChainlinkUtils.getTokenRelativePrice(
                        tokenInInfo.latestRound.price,
                        tokenInInfo.info.decimals,
                        remainingTokensInfo[i].latestRound.price,
                        remainingTokensInfo[i].info.decimals
                    )
                ) <= _maxPriceUnpegRatio,
                Err.MAX_PRICE_UNPEG_RATIO
            );
            unchecked{++i;}
        }
    }

    /**
    * @notice Check if the spot prices falls within the limits of the oracle price
    * - spot price of tokenOut must be < oraclePrice * _maxPriceUnpegRatio
    * @dev tokenOutInfo.info.balance should contain the balance after the trade
    * - spot price of tokenOut is computed in terms of the remaining tokens independently
    * @param tokenOutInfo swapped token's info
    * @param remainingTokensInfo remaining tokens' info
    */
    function _checkExitSwapPrices (
        Struct.TokenGlobal memory tokenOutInfo,
        Struct.TokenGlobal[] memory remainingTokensInfo
    ) internal view {
        
        uint256 spotPriceAfter;

        for (uint256 i; i < remainingTokensInfo.length;)
        {
            spotPriceAfter = Math.calcSpotPrice(
                remainingTokensInfo[i].info.balance,
                remainingTokensInfo[i].info.weight,
                tokenOutInfo.info.balance,
                tokenOutInfo.info.weight,
                0
            );

            _require(
                Num.div(
                    spotPriceAfter,
                    ChainlinkUtils.getTokenRelativePrice(
                        remainingTokensInfo[i].latestRound.price,
                        remainingTokensInfo[i].info.decimals,
                        tokenOutInfo.latestRound.price,
                        tokenOutInfo.info.decimals
                    )    
                ) <= _maxPriceUnpegRatio,
                Err.MAX_PRICE_UNPEG_RATIO
            );
            unchecked{++i;}
        }
    }

    function _tryGetTokenDecimals(address token) internal view returns (uint8) {
        try IDecimals(token).decimals() returns (uint8 d) {
            return d;
        } catch {}
        return 0;
    }

}