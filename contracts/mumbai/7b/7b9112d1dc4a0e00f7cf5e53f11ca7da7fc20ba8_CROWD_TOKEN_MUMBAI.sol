/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
//All rights reserved by RIOMA.eth

pragma solidity ^0.8.7;
library SignedSafeMath {
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
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
        return a - b;
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
        return a + b;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {        
        return a >= b ? a : b; 
    }
}

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/*
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
/* PancakeSwap Interface */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance:");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */


library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


/// @title Reward-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as rewards and allows token holders to withdraw their rewards.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract RewardPayingToken  {
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  //  using IterableMapping for IterableMapping.Map;

  // With `magnitude`, we can properly distribute rewards even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 public magnifiedDividendPerShare;

  // About rewardCorrection:
  // If the token balance of a `_user` is never changed, the reward of `_user` can be computed with:
  //   `rewardOf(_user) = rewardPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `rewardOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `rewardOf(_user)` unchanged, we add a correction term:
  //   `rewardOf(_user) = rewardPerShare * balanceOf(_user) + rewardCorrectionOf(_user)`,
  //   where `rewardCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `rewardCorrectionOf(_user) = rewardPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `rewardOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) public magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnRewards;
  mapping(address => uint256) internal withdrawnNum;

  uint256 public totalRewardsDistributed;

  uint256 public totalRewardsCorrection;

  uint256 public totalRewardsCreated;

  mapping(address => uint256) public paidRewards;

  mapping(address => uint256) internal withdrawnDividends; 
  

  uint256 public totalDividendsDistributed;

  uint256 public totalDvidendsCreated;

    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromRewards;

    mapping (address => uint256) public lastClaimTimes;
    mapping (address => uint256) public numClaimsAccount;

    uint256 public rewardInterval = 1 days; //52 weeks;
    uint256 public minimumTokenBalanceForRewards =  1 * (10**18);//10 ;
    uint256 public rewardRate = 1000000000;// with 12 decimals divider : 1000000000 -> 0,1%

    IERC20 public MYTOKEN = IERC20(address(this));
    IERC20 public USDT = IERC20(0xe11A86849d99F524cAC3E7A0Ec1241828e332C62);//usdt 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 main 0x55d398326f99059fF775485246999027B3197955

    bool public dividendIsOpen = false;


    
  /// @notice Distributes ether to token holders as rewards.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `RewardsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed USDT in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  

    function _distributeDividends(uint256 _dividends) internal {// FROM VALUE TO TOKENS
        dividendIsOpen = true;
        USDT.transferFrom(msg.sender, address(this), _dividends);
        uint256 supply = MYTOKEN.totalSupply().sub(totalRewardsCorrection);

        magnifiedDividendPerShare = magnifiedDividendPerShare.add( //BOH
            (_dividends).mul(magnitude) / supply //ERC20(address(this)).balanceOf(address(this))
        );
        totalDvidendsCreated = totalDvidendsCreated.add(_dividends);
    }
    
    
    
    function _setDevidendStatus(bool _isOn) internal returns (bool )  {
        dividendIsOpen = _isOn;
        return _isOn;
    }


  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `RewardWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawRewardOfUser(address  user) internal returns (uint256) {//RIO EX payable
    uint256 _withdrawableReward = withdrawableRewardOf(user);
    if (_withdrawableReward > 0) {
      withdrawnRewards[user] = withdrawnRewards[user].add(_withdrawableReward);
    
         withdrawnNum[user]++;

        MYTOKEN.transfer(user, _withdrawableReward);    

        totalRewardsDistributed = totalRewardsDistributed.add(_withdrawableReward);
        
      return _withdrawableReward;
    }

    return 0;
  }
  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `RewardWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendsOfUser(address  user) internal returns (uint256) {//RIO EX payable
    uint256 _withdrawableDividend = dividendsOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
    
      withdrawnNum[user]++;

        USDT.transfer(user, _withdrawableDividend);    

        totalDividendsDistributed = totalDividendsDistributed.add(_withdrawableDividend);
       
      return _withdrawableDividend;
    }

    return 0;
  }
  /// @notice View the amount of dividends in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividends in wei that `_owner` can withdraw.
function accumulativeDividendOf(address _owner) public view returns(uint256) {
      
    uint256 balance = MYTOKEN.balanceOf(_owner).sub(withdrawnRewards[_owner]).add(paidRewards[_owner]);

    return magnifiedDividendPerShare.mul(balance).toInt256()
      .add(magnifiedDividendCorrections[_owner]).toUint256() / magnitude;
  }

/// @notice View the amount of dividends in wei that an address can withdraw.
function dividendsOf(address _owner) public view  returns(uint256) {
    if(excludedFromRewards[_owner]) {
        return 0;
    }

    (bool check, uint256 rew) = SafeMath.trySub(accumulativeDividendOf(_owner),withdrawnDividends[_owner]);
    if(check){return rew;}else{return 0;}

}

  /// @return The amount of reward in wei that `_owner` can withdraw from the beginning or last time claiming
  function rewardOfTime(address _owner) public view  returns(uint256) {
    uint256 balance = MYTOKEN.balanceOf(_owner);

   uint256 rewards;
        
        (bool check, uint256 period) = SafeMath.trySub(block.timestamp,lastClaimTimes[_owner]);

        if(check && period.div(rewardInterval) > 0){ //
        
            (bool check1, uint256 rew) = SafeMath.tryDiv((balance * rewardRate),(10 ** 12));
                if(check1){
                uint256 dias = period.div(rewardInterval);
                rewards = rew.mul(dias);

             }
        }
        return rewards;
  }

    /* calculate reward for time left from purchases or last claim */
    function withdrawableRewardOf(address _owner) public view  returns(uint256) {
        return rewardOfTime(_owner); 
    }

  /// @return The amount of rewards in wei that `_owner` withdrawn from the beginning
    function withdrawnRewardOf(address _owner) public view  returns(uint256) {
        return withdrawnRewards[_owner];
    }
  /// @return The amount of dividends in wei that `_owner` withdrawn from the beginning
    function withdrawnDividendsOf(address _owner) public view  returns(uint256) {
        return withdrawnDividends[_owner];
    }
//last claim date by the holder
    function getLastClaimRewardTime(address _holder) public view returns (uint256) {
       return lastClaimTimes[_holder];
    }
//how many times interval reward is occorred
//for an intervalPeriod setted on 1 day, on the year end the amount will be 365
    function getNumClaimDays(address _holder) public view returns (uint256) {
       return numClaimsAccount[_holder];
    }
    function canClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= rewardInterval;
    }

// PROCESS REWARD DISTRIBUTION
    function processAccount(address account, uint256 lastDistributionDay) internal  returns (bool) {
        
        uint256 iniTime = lastClaimTimes[account];
        if(canClaim(iniTime)) { 
        uint256 amount = _withdrawRewardOfUser(account);

    	if(amount > 0) {
            uint256 dias = (block.timestamp.sub(iniTime)).div(rewardInterval);
            numClaimsAccount[account] = numClaimsAccount[account].add(dias);

    		lastClaimTimes[account] = lastDistributionDay;

    		return true;
    	    }
      }

   return false;
    }
   
    function withdrawDividendsOfUser(address account) public {
           if(dividendIsOpen)
            _withdrawDividendsOfUser(account);
    }
     
}


contract CROWD_TOKEN_MUMBAI is ERC20, RewardPayingToken{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
        
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    IUniswapV2Router02 public uniswapV2Router; 
    address public  uniswapV2Pair;//immutable

    bool public claimIsOpen = true;
    
    bool public inRewardsPaused = true;

    bool public sendAndLiquifyEnabled = false;

    bool public mintingIsLive = true;

    uint256 public maxSellTransactionAmount = 1_000_000 * (10**18);

    bool public isOpenToMarket = false;//Trading with PancakeSwap & Co. is disabled

    address payable public  projectWallet;

    address public deadWallet = address(0x000000000000000000000000000000000000dEaD);

    uint256 public lastSentToContract;
    
    // use by default 350,000 gas to auto-process reward distribution
    uint256 public gasForProcessing = 350000;
    
    mapping(address => bool) private _isExcludedFromMaxTx;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to specific rules
    mapping (address => bool) public automatedMarketMakerPairs;

    //FEES
    uint256 public projectFeeRate =  0;//50 -> 5%
    uint256 divider = 1000; //divider for projectFeeRate
    uint256 public withdrawns;
    uint256 public deposits;

    address public WBNB = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;//test 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd main 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c

    address public admin;
    address public owner;

    /* lock Token*/
    bool public tradeIsOpen = true;
    mapping(address => bool) internal _whiteList;
    
    // Normally during the private sale the token is locked. Here you can act with this
    modifier isOpenTrade(address from, address to) {
        require(tradeIsOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    //permit transfership for public sale
    function openTrade(bool _isOpen) external onlyOwner {
        tradeIsOpen = _isOpen;
    }

    //include expecptions to openTrade
    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    //Trade is closed on PancakeSwap and decentralized excange by default. In the future admin can open to DeFi
    function openTradeToMarket(bool _isOpen) public onlyOwner {
        isOpenToMarket = _isOpen;
    } 


    // only this Contract can CREATE A CROWD TOKEN by accepting the FEE AMOUNT
    IgetSuperAdmin public superAdmin = IgetSuperAdmin(msg.sender); 

    constructor(address __owner, string memory _name,string memory _symbol) ERC20(_name,_symbol) {
        admin = msg.sender;
      //  require(superAdmin.getSuperAdmin(msg.sender),"NOT ALLOWED");
        projectWallet = payable(__owner);
        owner = __owner;

        _whiteList[__owner] = true;
        _whiteList[admin] = true;
        _whiteList[address(this)] = true;
   /*     
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD);//0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 uniswap V3 0x1F98431c8aD98523631AE4a59f267346ea31F984
         //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Create a PancakeSwap pair for this new token ->mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E
        //https://github.com/Uniswap/universal-router/blob/main/deploy-addresses/polygon-mumbai.json

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        */
        excludeFromRewards(address(this),true);
        excludeFromRewards(projectWallet,true);
      //  excludeFromRewards(address(_uniswapV2Router),true);
        excludeFromRewards(0x000000000000000000000000000000000000dEaD,true);

 
        // exclude from max tx
        _isExcludedFromMaxTx[owner] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        setSendAndLiquifyEnabled(true);

        lastSentToContract =  block.timestamp; 
    }

    modifier onlyOwner() {
        require(owner == msg.sender || admin == msg.sender , "No Mint: caller is not the admin owner");
        _;
    }

    function setMintingIsLive(bool _isOn) public onlyOwner returns (bool )  {
        mintingIsLive = _isOn;
        return _isOn;
    }

    function setinRewardsPaused(bool _bool) public onlyOwner {
        inRewardsPaused = _bool;
    }
    
    function setClaimIsOpen(bool _bool) public onlyOwner {
        claimIsOpen = _bool;
    }

    function excludeFromRewardsUser(address account, bool value) public onlyOwner {
    excludeFromRewards( account,value);
    }

    function ABC_RIO() public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD);//0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 uniswap V3 0x1F98431c8aD98523631AE4a59f267346ea31F984
         //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Create a PancakeSwap pair for this new token ->mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E
        //https://github.com/Uniswap/universal-router/blob/main/deploy-addresses/polygon-mumbai.json

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
    }
    
    function setLastSentToContract(uint256 _date) public onlyOwner {
        lastSentToContract = _date;
        
    }
    
    /*exclude from anti whale */
    function excludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = value;
    }

    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    //set the decentralized exchange address to manage openTradeMarket
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "CROWD TOKEN:The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    // NOT USEFULL
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    //set a new decentralized exchange address to manage openTradeMarket
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    //gas precessing value
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "CROWD TOKEN:gasForProcessing must be between 200,000 and 500,000");
        gasForProcessing = newValue;
    }


  
// external call to claim token rewards
    function claimRewards() external {
        if(
            !inRewardsPaused 
        ) {
        sendAndLiquify();
		processAccount(msg.sender, lastSentToContract);
        }
    }
   
 // external call to withdraw USDT dividends
    function claimDividends() external {
		withdrawDividendsOfUser(msg.sender);     
    }

//launch massive rewards distribution until gas is out
//for many holders will be necessary repeat the operation a few times
   function claimAllHolderRewards() external onlyOwner{
        if(!inRewardsPaused) {
        sendAndLiquify();
	//	process(gasForProcessing, lastSentToContract);
        }
    }

//Enable/disable rewards distribution
    function setSendAndLiquifyEnabled(bool _enabled) public onlyOwner {
        sendAndLiquifyEnabled = _enabled;
    }

//Change the wallet for fees 
    function setProjectWallet(address newAccount) public {
        require(msg.sender == owner, "Only Owner can act here");
        projectWallet = payable(newAccount);
        excludeFromRewards(newAccount,true);
    }

//possible Anti-wales  option
    function setMaxSellTransactionAmount(uint256 newAmount) public onlyOwner 
    {
        maxSellTransactionAmount = newAmount;
    }    
    
/* DEFAULT FUNCTIONS */
    function _transfer(address from, address to, uint256 amount) 
    isOpenTrade(from, to) //openTrade lock managing
     internal override 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if((!_isExcludedFromMaxTx[from]) && (!_isExcludedFromMaxTx[to]))
        {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        if(!isOpenToMarket){
            if(automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from])
            {
                revert("Trade is actually closed on PancakeSwap or decentralized excange");
            }
        }
       
        setBuyTime(to);  //call before transfer
        
        if(from != address(this)){

       subCorrection(from,amount);
       addCorrection(to,amount);
            if(!inRewardsPaused ) {
                sendAndLiquify();
                processAccount(from, lastSentToContract);           
            }
         }
         
        super._transfer(from, to, amount);
        
    }
    
/* 
    Correction works only for TOKEN MINTED FOR rewards: ONLY PAID TOKENS ARE CALCULATED TO RECEIVE DIVIDENDS   
    Rewards can be swapped with USDT by the 
    function claimTokenReward (uint256 _claim).
    Then the Rewards Tokens will be burned 
*/

    function addCorrection(address account,uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256() );
    }

    function subCorrection(address account,uint256 value) public {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256() );
    }

//mint token for the exact amount of holders
    function sendAndLiquify() public {
        if(!sendAndLiquifyEnabled)return;
        uint256 rewards;
       // uint256 rewardInterval = rewardInterval();
        
        (bool check, uint256 period) = SafeMath.trySub(block.timestamp,lastSentToContract);

        if(check && period.div(rewardInterval) > 0){ //
        
            (bool check1, uint256 rew) = SafeMath.tryDiv((totalSupply() * rewardRate),(10 ** 12));
                if(check1){
                uint256 dias = period.div(rewardInterval);
                rewards = rew.mul(dias);
               
                if(rewards>0){
                
                totalRewardsCorrection = totalRewardsCorrection.add(rewards);

                _mint(address(this), rewards);

                lastSentToContract += dias.mul(rewardInterval);
                
                }
             }
        }

    }
function distributeDividends(uint256 _dividends) public  onlyOwner{
    _distributeDividends(_dividends);
}
function setDevidendStatus(bool _isOn) public onlyOwner  { 
   _setDevidendStatus(_isOn);
}
//SET FOR FIRST PURCHASE ONLY : to avoid misalignment we set buyTime = last distribution time but with a max of token reward interval
    function setBuyTime(address _holder) internal {
        if(balanceOf(_holder)==0){
            uint256 _time;
            //nel caso non si minti dopo il deploy
            if(totalSupply()==0)lastSentToContract = block.timestamp;

            if(block.timestamp.sub(lastSentToContract) < rewardInterval){
                _time = lastSentToContract;
            }else{
                _time = block.timestamp;
            }
            
            setBuyTime2(_holder,_time);
        }

    }

    function setBuyTime2(address _holder, uint256 _time) internal {

        lastClaimTimes[_holder] = _time;
    }
    
    function updateRewardInterval(uint256 newRewardInterval) external onlyOwner {
        require(newRewardInterval != rewardInterval, "ABC_Reward_Tracker: Cannot update RewardInterval to same value");
        rewardInterval = newRewardInterval;
    }

    function setMinimumTokenBalanceForRewards(uint256 _minimumTokenBalanceWei) public onlyOwner {
        minimumTokenBalanceForRewards = _minimumTokenBalanceWei;
    }



    /* CROWD TOKEN MINTING*/
     /* PAY WITH BNB */
    function buyToken () public payable returns (bool){//uint256 tokens
        require(mintingIsLive , "Minting is OFF LINE");
        uint amount = msg.value;
        require(amount > 0, "Not enough Tokens to buy");
        uint256 fee = amount.mul(projectFeeRate).div(divider);       
        
        address _holder = msg.sender;
        if(!inRewardsPaused ) 
        { 
            sendAndLiquify();
            processAccount(_holder, lastSentToContract);
        }
    
        setBuyTime(_holder);  //call before minting

        uint256 tokens = swapBnbToUsdt(amount.sub(fee));
        
        _mint(_holder,tokens);

        if(fee>0)swapBnbToUsdtAndSendTo(fee,projectWallet);
        
        addCorrection(_holder,tokens);
        return true;
    }

    /* PAY WITH USDT : 1 CROWD TOKEN => 1 USDT  */
    function buyTokenUSDT (uint256 amount) public payable returns (bool){//uint256 tokens
        require(mintingIsLive , "Minting is OFF LINE");
        require(amount > 0, "Not enough Tokens to buy");
        uint256 fee = amount.mul(projectFeeRate).div(divider);       
        
        address _holder = msg.sender;
        if(!inRewardsPaused ) { 
            sendAndLiquify();
            processAccount(_holder, lastSentToContract);
        }

        setBuyTime(_holder);  //call before minting

        uint256 tokens = amount.sub(fee);

        USDT.transferFrom(_holder, address(this), tokens);//in Polygon USDT has only 6 decimals

        _mint(_holder,tokens);
        
       if(fee>0)USDT.transfer(projectWallet, fee);        

       addCorrection(_holder,tokens);
        
        return true;
    }

    function buyTokenAdmin (address _holder, uint256 tokens) public payable {//uint256 tokens
        require(tokens > 0, "Not enough Tokens to buy");

        setBuyTime(_holder);  //call before minting

        _mint(_holder,tokens);
        
        addCorrection(_holder,tokens);
    }
    
    
// THREE DIFFERENTS FUNCTION FOR CLAIMING BECAUSE THE REWARDS CORRECTION:ONLY PUCHASED TOKEN WILL GET REWARDS
//1 : FOR THE THE ORIGINAL TOKEN
//2 : FOR THE REWARDS
//3 : TO EXIT COMPLETELY AND WITHDRAW ALL AVOING FUTURE REWARDS AND DIVIDENDS


/* claim Token Reward amount:
    totalRewardsCorrection works only for rewards: ONLY PAID TOKENS ARE CALCULATED TO RECEIVE DIVIDENDS    */

    function claimTokenReward (uint256 _claim) public returns (bool ){
        address _holder = msg.sender;
        require(claimIsOpen,"Token swap with USDT is not allowed at this moment, try later");

        if(!inRewardsPaused) {
        sendAndLiquify();
		processAccount(_holder, lastSentToContract);
        }  
        // to limit only to rewards
        require(_claim <= (withdrawnRewards[_holder].sub(paidRewards[_holder])),"Only rewards allowed");
       
        uint256 fee = _claim.mul(projectFeeRate).div(divider);   
         
        USDT.transfer(msg.sender, _claim.sub(fee));
        if(fee>0)USDT.transfer(projectWallet, fee);
               
        super._burn(_holder,_claim); 

        paidRewards[_holder] += _claim;

        subCorrection(_holder,_claim);
        totalRewardsCorrection = totalRewardsCorrection.sub(_claim);

        return true;
    }


     /* 
     Claim ONLY purchased TOKENS :
     */
    function claimToken (uint256 _claim) public returns (bool ){
    address _holder = msg.sender;
    uint256 balance = balanceOf(_holder);
    require(claimIsOpen,"Token swap with USDT is not allowed at this moment, try later");

    require(_claim <= balance.sub(withdrawnRewards[_holder].add(paidRewards[_holder])),"Only bought token allowed");

        withdrawDividendsOfUser(_holder);
        
        if(
            !inRewardsPaused
        ) {
            sendAndLiquify();
            processAccount(_holder, lastSentToContract);
        }  

        uint256 fee = _claim.mul(projectFeeRate).div(divider);
  
        USDT.transfer(_holder, _claim.sub(fee));
        if(fee>0)USDT.transfer(projectWallet, fee);

        super._burn(_holder,_claim);
         
        subCorrection(_holder,_claim);

        return true;
    }


    /* WITHDRAW USDT, BURN TOKENS AND EXIT FROM PROJECT . FUTURE TOKEN PURCHASED ARE ALLOWED*/
    function claimAllToken () public returns (bool ){
        address _holder = msg.sender;
        require(claimIsOpen,"Token swap with USDT is not allowed at this moment, try later");
        withdrawDividendsOfUser(_holder);
        
        if(!inRewardsPaused) {
            sendAndLiquify();
            processAccount(_holder, lastSentToContract);
        }  
        
        uint256 balance = balanceOf(_holder);
        uint256 fee = balance.mul(projectFeeRate).div(divider);
  
        USDT.transfer(_holder, balance.sub(fee));
        if(fee>0)USDT.transfer(projectWallet, fee);
        super._burn(_holder,balance);
 
        subCorrection(_holder,balance);
        totalRewardsCorrection = totalRewardsCorrection.sub(withdrawnRewards[_holder].add(paidRewards[_holder]));

        withdrawnDividends[_holder] = 0;
        withdrawnRewards[_holder] = 0;
        paidRewards[_holder] = 0;

        return true;
    }

    /* ADMIN FUNCTIONS TO MANAGE CROWD TOKEN CONTRACT BALANCE*/
    /* USDT CAN ONLY BE SENT ONLY TO PROJECT WALLET*/
    function withdrawUsdtFromContract(uint256 _amount) external  onlyOwner{
        require(USDT.balanceOf(address(this)) >= _amount, "Request exceed Balance");
        USDT.transfer(projectWallet, _amount);
        withdrawns = withdrawns.add(_amount);
    }

    function withdrawUsdtFromContractAll() external  onlyOwner{
        USDT.transfer(projectWallet, USDT.balanceOf(address(this)));
    }

    function depositUsdtToContract(uint256 _amount) external  {//onlyOwner
        // You need to approve this action from USDT contract before or transfer directly USDT to contract address
        USDT.transferFrom(msg.sender,address(this), _amount);
        deposits = deposits.add(_amount);
    }

    function withdrawTokenContract(address _token, uint256 _amount) external onlyOwner{
        IERC20(_token).transferFrom(address(this),projectWallet, _amount);
    }

    function setAdminFee (uint256 _fee) public onlyOwner  returns (bool ){
        require(_fee <= divider.div(5) , "Max fee 20%");
        projectFeeRate = _fee;
        return true;
    }

    function setRewardRate (uint256 _rate) public onlyOwner  returns (bool ){
        rewardRate = _rate;
        return true;
    }
    
    function setDivider (uint256 _divider) public onlyOwner  returns (bool ){
        divider = _divider;
        return true;
    }
   
    /*  USED FOR ESTIMATE THE AMOUNT IN THE DAPP */
    function  getAmountOfTokenForEth(uint tokenIn) public virtual view returns (uint256){
      address[] memory path = new address[](2);
        path[1] = WBNB;
        path[0] = address(USDT);
      uint[] memory amounts = uniswapV2Router.getAmountsIn(tokenIn,path);
        return amounts[0];
    }
    
    /*  SWAPPING USDT */
    function swapBnbToUsdt(uint256 amount) internal returns(uint256){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(USDT);

        // make the swap
        uint[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: amount}(
            0, // accept any amount of USDT
            path,
            address(this),
            block.timestamp + 30
        );
    return amounts[1];
       
    }

    function swapBnbToUsdtAndSendTo(uint256 amount, address _receiver) internal  {
        if(amount<1)return ;
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(USDT);

        // make the swap
        uniswapV2Router.swapExactETHForTokens{value: amount}(
            0, // accept any amount of USDT
            path,
            _receiver,
            block.timestamp + 30
        );
       
    }
    
    /* in any case could be changed the WBNB-USDT-BUSD contract address */
    function setTokenAddressUSDT(address _contract) public onlyOwner{
        USDT = IERC20(_contract);
    }

    function setTokenAddressWBNB(address _contract) public onlyOwner{
        WBNB = _contract;
    }

/* return contract infos */
    function contractInfo()
        public view returns (
            address _owner,
            string memory _name,
            string memory _symbol,
            uint256 _totalSupply,
            uint256 _totalRewardsDistributed,
            uint256 _rewardInterval,
            uint256 _rewardRate,
            uint256 _lastSentToContract,
            uint256 _totalDividendsDistributed
            ) {
_owner = owner;_name=name();_symbol=symbol();_totalSupply=totalSupply();
_totalRewardsDistributed=totalRewardsDistributed;
_totalDividendsDistributed=totalDividendsDistributed;
_rewardInterval=rewardInterval;_rewardRate=rewardRate;_lastSentToContract=lastSentToContract;
            }

    
    function excludeFromRewards(address account, bool value) internal  {
    	excludedFromRewards[account] = value;
    }

    
    function isExcludedFromRewards(address account) public view returns(bool) {
        return excludedFromRewards[account];
    }

//return account infos
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            uint256 balance,
            uint256 _totalRewards,
            uint256 _withdrawableRewards,
            uint256 _lastClaimTime,
            uint256 _nextClaimTime,
            uint256 _numClaims,
            uint256 _withdrawnDividends,
            uint256 _withdrableDividends,
            int256 iterationsUntilProcessed) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        balance = balanceOf(account);

        _withdrawableRewards = withdrawableRewardOf(account);
        
        _totalRewards = withdrawnRewards[account].add(rewardOfTime(account));// accumulativeDividendOf(account);

        _lastClaimTime = lastClaimTimes[account];

        _nextClaimTime = _lastClaimTime > 0 ?
                                    _lastClaimTime.add(rewardInterval) :
                                    0;

        _numClaims = numClaimsAccount[account];
        
        _withdrawnDividends = withdrawnDividends[account];

        _withdrableDividends = dividendsOf(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            
        }

    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256 ,
            uint256 ,
            uint256 ,            uint256 ,            uint256 ,            uint256 ,            uint256 ,            uint256 ,            uint256 ,            int256 ) {


        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }
    

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
/*
//massive rewards distribution onlyOwner
    function process(uint256 gas, uint256 lastDistributionDay) internal returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    			if(processAccount(account, lastDistributionDay)) {
    				claims++;
    			}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }  
*/
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
}


interface IgetSuperAdmin {
        function getSuperAdmin(address _user) external view returns (bool);

}

contract Crowd_Token_Creator {
    address payable public  rioWallet;
    address public  superAdmin;
    uint256 public feeRio = 0.0;
    address[] contractCreated;
    event newCrowdContract(
       address contractAddress
    );
        constructor()
    {
        rioWallet = payable(msg.sender);
        superAdmin = address(this);
    }
    
    function createNewToken( string memory _name,string memory _symbol) public payable {

        uint256 amount = msg.value;
        require(amount >= feeRio , "Fee required");

        rioWallet.transfer(amount);
        
        address newContract = address(new CROWD_TOKEN_MUMBAI(msg.sender,_name,_symbol));
        contractCreated.push(newContract);
        emit newCrowdContract(newContract);
    }
    
    // ETH-BNB wei FEE SERVICE AMOUNT
    function setFee (uint256 _fee) public {
        require(msg.sender == rioWallet);
        feeRio = _fee;
    }

    function getContracts() public  view returns (address[] memory){
        return contractCreated;
    }

    function getSuperAdmin(address _user) external view returns (bool){
        return _user == superAdmin;
    }

}