// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract TestMB is Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _NAME = "Crazy Test";
    string private constant _SYMBOL = "CTST";
    uint256 private constant _DECIMALS = 18;
    uint256 private _totalSupply;

    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;
    address payable public developmentWallet;
    uint256 public swapableRefection;
    uint256 public swapableDevTax;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public sellTax;
    uint256 public buyTax;
    uint256 public taxDivisionPercentage;
    uint256 public totalBurned;
    uint256 public totalReflected;
    uint256 public totalLP;

    IUniswapV2Router02 public dexRouter;
    address public immutable lpPair;
    bool public tradingActive;
    uint256 public ethReflectionBasis;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _reflectionExcluded;
    mapping(address => uint256) public lastReflectionBasis;
    mapping(address => uint256) public totalClaimedReflection;
    mapping(address => bool) public lpPairs;
    mapping(address => bool) private _isExcludedFromTax;
    mapping(address => bool) private _bots;

    event functionType(uint Type, address sender, uint256 amount);

    constructor(
        uint256 totalSupply_,
        address payable devWallet_,
        uint256 taxDivisionPercentage_,
        uint256 maxTxLimit_,
        uint256 maxWalletLimit_
    ) {
        _totalSupply = totalSupply_.mul(10 ** _DECIMALS);
        _balances[owner()] = _balances[owner()].add(_totalSupply);

        developmentWallet = payable(devWallet_);
        sellTax = 60;
        buyTax = 15;
        maxTxLimit = maxTxLimit_;
        maxWalletLimit = maxWalletLimit_;
        taxDivisionPercentage = taxDivisionPercentage_;

        dexRouter = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(
            address(this),
            dexRouter.WETH()
        );
        lpPairs[lpPair] = true;

        _approve(owner(), address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[lpPair] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint256) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address sender,
        address spender
    ) public view override returns (uint256) {
        return _allowances[sender][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(
            _balances[msg.sender] >= amount,
            "ERC20: Amount exceeds account balance"
        );

        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Cannot be zero address");
        require(recipient != address(0), "ERC20: Cannot be zero address");
        require(recipient != DEAD, "ERC20: Cannot be zero the dead address");
        require(
            _allowances[sender][msg.sender] >= amount,
            "ERC20: Insufficient allowance."
        );
        require(
            _balances[sender] >= amount,
            "ERC20: Amount exceeds sender's account balance"
        );

        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount);
        }
        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            _bots[sender] == false && _bots[recipient] == false,
            "Go away Jared and MEV bots"
        );

        if (sender == owner() && lpPairs[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else if (lpPairs[sender] || lpPairs[recipient]) {
            require(tradingActive == true, "Trading is inactive");

            if (_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient]) {
                if (
                    _checkWalletLimit(recipient, amount) &&
                    _checkTxLimit(amount)
                ) {
                    _transferFromExcluded(sender, recipient, amount); //buy
                }
            } else if (
                !_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]
            ) {
                if (_checkTxLimit(amount)) {
                    _transferToExcluded(sender, recipient, amount); //sell
                }
            } else if (
                _isExcludedFromTax[sender] && _isExcludedFromTax[recipient]
            ) {
                if (
                    sender == owner() ||
                    recipient == owner() ||
                    sender == address(this) ||
                    recipient == address(this)
                ) {
                    _transferBothExcluded(sender, recipient, amount);
                } else if (lpPairs[recipient]) {
                    if (_checkTxLimit(amount)) {
                        _transferBothExcluded(sender, recipient, amount);
                    }
                } else if (
                    _checkWalletLimit(recipient, amount) &&
                    _checkTxLimit(amount)
                ) {
                    _transferBothExcluded(sender, recipient, amount);
                }
            }
        } else {
            if (
                sender == owner() ||
                recipient == owner() ||
                sender == address(this) ||
                recipient == address(this)
            ) {
                _transferBothExcluded(sender, recipient, amount);
            } else if (
                _checkWalletLimit(recipient, amount) && _checkTxLimit(amount)
            ) {
                _transferBothExcluded(sender, recipient, amount);
            }
        }
    }

    // Buy
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 randomNumber = _generateRandomNumber();
        uint256 taxAmount = amount.mul(buyTax).div(100);
        uint256 receiveAmount = amount.sub(taxAmount);
        (
            uint256 devAmount,
            uint256 burnAmount,
            uint256 lpAmount,
            uint256 reflectionAmount
        ) = _getTaxAmount(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(receiveAmount);
        _balances[address(this)] = _balances[address(this)].add(devAmount);
        swapableDevTax = swapableDevTax.add(devAmount);

        if (randomNumber == 1) {
            _burn(sender, burnAmount);
            emit functionType(randomNumber, sender, burnAmount);
        } else if (randomNumber == 2) {
            _takeLP(sender, lpAmount);
            emit functionType(randomNumber, sender, lpAmount);
        } else if (randomNumber == 3) {
            _balances[address(this)] = _balances[address(this)].add(
                reflectionAmount
            );
            swapableRefection = swapableRefection.add(reflectionAmount);
            totalReflected = totalReflected.add(reflectionAmount);
            emit functionType(randomNumber, sender, reflectionAmount);
        }
        emit Transfer(sender, recipient, amount);
    }

    // Sell
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 randomNumber = _generateRandomNumber();
        uint256 taxAmount = amount.mul(sellTax).div(100);
        uint256 sentAmount = amount.sub(taxAmount);
        (
            uint256 devAmount,
            uint256 burnAmount,
            uint256 lpAmount,
            uint256 reflectionAmount
        ) = _getTaxAmount(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(sentAmount);
        _balances[address(this)] = _balances[address(this)].add(devAmount);
        swapableDevTax = swapableDevTax.add(devAmount);

        if (randomNumber == 1) {
            _burn(sender, burnAmount);
            emit functionType(randomNumber, sender, burnAmount);
        } else if (randomNumber == 2) {
            _takeLP(sender, lpAmount);
            emit functionType(randomNumber, sender, lpAmount);
        } else if (randomNumber == 3) {
            _balances[address(this)] = _balances[address(this)].add(
                reflectionAmount
            );
            swapableRefection = swapableRefection.add(reflectionAmount);
            totalReflected = totalReflected.add(reflectionAmount);
            emit functionType(randomNumber, sender, reflectionAmount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function burn(uint256 amountTokens) public {
        address sender = msg.sender;
        require(
            _balances[sender] >= amountTokens,
            "You dont have enough to burn that much"
        );
        require(amountTokens > 0, "Cannot burn 0 token");

        if (amountTokens > 0) {
            _balances[sender] = _balances[sender].sub(amountTokens);
            _burn(sender, amountTokens);
        }
    }

    function _burn(address from, uint256 amount) private {
        _totalSupply = _totalSupply.sub(amount);
        totalBurned = totalBurned.add(amount);

        emit Transfer(from, address(0), amount);
    }

    function _takeLP(address from, uint256 tax) private {
        if (tax > 0) {
            (, , uint256 lp, ) = _getTaxAmount(tax);
            _balances[lpPair] = _balances[lpPair].add(lp);
            totalLP = totalLP.add(lp);

            emit Transfer(from, lpPair, lp);
        }
    }

    function addReflection() external payable {
        ethReflectionBasis = ethReflectionBasis.add(msg.value);
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function removeReflectionExcluded(address account) external onlyOwner {
        require(isReflectionExcluded(account), "Address is not excluded");

        _reflectionExcluded[account] = false;
    }

    function addReflectionExcluded(address account) external onlyOwner {
        _addReflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "Address already excluded");
        _reflectionExcluded[account] = true;
    }

    function unclaimedReflection(address addr) public view returns (uint256) {
        if (addr == lpPair || addr == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis -
            lastReflectionBasis[addr];
        return (basisDifference * balanceOf(addr)) / _totalSupply;
    }

    function _claimReflection(address payable addr) internal {
        uint256 unclaimed = unclaimedReflection(addr);
        require(unclaimed > 0, "You have 0 unclaimed reflective tokens");
        require(
            isReflectionExcluded(addr) == false,
            "This address is excluded from claim reflection"
        );

        lastReflectionBasis[addr] = ethReflectionBasis;
        if (unclaimed > 0) {
            addr.transfer(unclaimed);
        }
        totalClaimedReflection[addr] = totalClaimedReflection[addr].add(
            unclaimed
        );
    }

    function claimReflection() external {
        _claimReflection(payable(msg.sender));
    }

    function swapReflection() external {
        require(swapableRefection > 0, "Insufficient token balance to swap");

        uint256 currentBalance = address(this).balance;
        _swap(address(this), swapableRefection);
        swapableRefection = 0;

        uint256 ethTransfer = (address(this).balance).sub(currentBalance);
        ethReflectionBasis = ethReflectionBasis.add(ethTransfer);
    }

    function swapDevTax() external {
        require(swapableDevTax > 0, "Insufficient token balance to swap");
        _swap(developmentWallet, swapableDevTax);
        swapableDevTax = 0;
    }

    function setmaxTxLimit(uint256 amount) public onlyOwner {
        maxTxLimit = amount;
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner {
        maxWalletLimit = amount;
    }

    function setDevWallet(address payable newDevWallet) public onlyOwner {
        require(newDevWallet != address(0), "Dev wallet cannot be 0 address");
        developmentWallet = newDevWallet;
    }

    function setsellTax(uint256 tax) public onlyOwner {
        require(tax <= 15, "Buy tax percentage cannot be more than 15");
        sellTax = tax;
    }

    function setbuyTax(uint256 tax) public onlyOwner {
        require(tax <= 15, "Buy tax percentage cannot be more than 15");
        buyTax = tax;
    }

    function setTaxDivPercentage(uint256 percentage) public onlyOwner {
        require(
            percentage <= 100,
            "Tax division percentage cannot be more then 100"
        );
        taxDivisionPercentage = percentage;
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function addBot(address[] memory _bot) public onlyOwner {
        for (uint i = 0; i < _bot.length; i++) {
            _bots[_bot[i]] = true;
        }
    }

    function removeBot(address _bot) public onlyOwner {
        require(_bots[_bot] == true, "ERC20: Bot is not in the list");
        _bots[_bot] = false;
    }

    function addLpPair(address pair, bool status) public onlyOwner {
        lpPairs[pair] = status;
        _isExcludedFromTax[pair] = status;
    }

    function removeAllTax() public onlyOwner {
        sellTax = 0;
        buyTax = 0;
        taxDivisionPercentage = 0;
    }

    function excludeFromTax(address account) public onlyOwner {
        require(
            !_isExcludedFromTax[account],
            "ERC20: Account is already excluded."
        );
        _isExcludedFromTax[account] = true;
    }

    function includeInTax(address _account) public onlyOwner {
        require(
            _isExcludedFromTax[_account],
            "ERC20: Account is already included."
        );
        _isExcludedFromTax[_account] = false;
    }

    function recoverAllEth() public onlyOwner { // CHANGE FROM owner() to developmentWallet
        payable(developmentWallet).transfer(address(this).balance);
    }

    function recoverErc20token(address token, uint256 amount) public onlyOwner { // CHANGE FROM owner() to developmentWallet
        IERC20(token).transfer(developmentWallet, amount);
    }

    function checkExludedFromTax(address _account) public view returns (bool) {
        return _isExcludedFromTax[_account];
    }

    function isBot(address _account) public view returns (bool) {
        return _bots[_account];
    }

    function _generateRandomNumber() private view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        block.gaslimit,
                        tx.origin,
                        block.number,
                        tx.gasprice
                    )
                )
            ) % 3) + 1;
    }

    function _getTaxAmount(
        uint256 _tax
    )
        private
        view
        returns (
            uint256 _devAmount,
            uint256 Burn,
            uint256 LP,
            uint256 Reflection
        )
    {
        uint256 devAmount;
        uint256 burnAmount;
        uint256 lpAmount;
        uint256 reflectionAmount;

        if (_tax > 0) {
            devAmount = _tax.mul((100 - taxDivisionPercentage)).div(100);
            burnAmount = _tax.mul(taxDivisionPercentage).div(100);
            lpAmount = _tax.mul(taxDivisionPercentage).div(100);
            reflectionAmount = _tax.mul(taxDivisionPercentage).div(100);
        }
        return (devAmount, burnAmount, lpAmount, reflectionAmount);
    }

    function _checkWalletLimit(
        address recipient,
        uint256 amount
    ) private view returns (bool) {
        require(
            maxWalletLimit >= balanceOf(recipient).add(amount),
            "ERC20: Wallet limit exceeds"
        );
        return true;
    }

    function _checkTxLimit(uint256 amount) private view returns (bool) {
        require(amount <= maxTxLimit, "ERC20: Transaction limit exceeds");
        return true;
    }

    function _swap(address recipient, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }
}