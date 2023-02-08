/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



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


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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




interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool    approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IWETH2 is IWETH {
    function balanceOf(address _account) external view returns (uint256);
}

// Libraries
library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"5fe75051b33b0e6362588ca710b69338237fd3aba4a35229168ea1bd47d88e0f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract DexOrderBook is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ================================= State Variables =================================

    uint256 public orderFee;
    uint256 public totalBuyOrders;
    uint256 public totalSellOrders;
    address public uniswapRouterAddress;
    address public uniswapFactoryAddress;

    enum OrderStatus {
        PENDING,
        FILLED,
        CANCELLED
    }

    struct Order {
        address maker; // address of the order maker
        address[2] path; // token pair of the order
        uint256 price; // price of the order
        uint256 stopPrice; // stop price of the order
        uint256 amountIn; // amount of the first token in the order\
        uint256 minAmountOut; // minimum amount user will get in the order
        uint256 timestamp; // timestamp of the order
        uint256 expireAt; // timestamp of the order expiration
        uint256 maxGasFee; // maximum gas fee of the order
        bool isLimitOrder; // is the order a limit order?
        bool isBuyOrder; // is the order a buy order?
        OrderStatus status; // status of the order
    }

    struct OrderBook {
        uint256 orderCount;
        uint128 totalBuyOrders;
        uint256 totalSellOrders;
        mapping(uint256 => Order) orders;
    }

    mapping(address => OrderBook) public orders; // user =>  OrderBook
    mapping(address => uint256) public ethBalance; // user =>  ethBalance
    uint256[5] public expiryDurations;
    address private _relayerPubKey;

    // ******************************** //
    // *** CONSTANTS AND IMMUTABLES *** //
    // ******************************** //

    // Can they be private?
    // Private to save gas, to verify it's correct, check the constructor arguments
    address private wethToken;
    address private constant USE_ETHEREUM = address(0);
    uint32 public constant PERCENT_DENOMINATOR = 100000;

    event MARKET_ORDER_PLACED(uint256 amount, address user, address lpAddress);
    event ORDER_PLACED(
        address[2] _addr, // user, lpPair
        bool[2] _orderActions, // isLimitOrder, isBuyOrder
        uint256[6] _orderOpts // tpPrice, slPrice, amount, orderNum, expireAt, maxGasFee
    );
    event ORDER_FILLED(
        bool isBuyOrder,
        uint256 amount,
        address user,
        uint256 orderNum
    );
    event ORDER_CANCELLED(bool isBuyOrder, address _user, uint256 orderNum);

    modifier isAuthorized() {
        require(msg.sender == _relayerPubKey, "Unauthorized Access!");
        _;
    }

    // Contract should be able to receive ETH deposits to support deposit
    receive() external payable {
        depositETH(msg.sender);
    }

    // ================================= Constructor =================================
    constructor(
        address _pubKey,
        uint256 _fee,
        address _uniswapRouterAddress,
        address _uniswapFactoryAddress,
        address wethToken_
    )  {
       
        orderFee = _fee;
        _relayerPubKey = _pubKey;
        uniswapRouterAddress = _uniswapRouterAddress;
        uniswapFactoryAddress = _uniswapFactoryAddress;
        wethToken = wethToken_;

        expiryDurations[0] = 0; // never
        expiryDurations[1] = 1 hours; // 1 hour
        expiryDurations[2] = 1 days; // 1 day
        expiryDurations[3] = 7 days; // 7 days
        expiryDurations[4] = 30 days; // 30 days
    }

    // ================================= Public Functions =================================
    /**
     * @notice Function to place a market order.
     * @dev Function to place a market order.
     * @param _path Path to the pair of tokens to trade.
     * @param _amount The amount of the first token in the order.
     */
    function placeMarketOrder(
        address[2] memory _path, // base token, quote token
        uint256 _amount
    ) external payable nonReentrant {
        // store base token
        address baseToken = _path[0];
        // Converting ETH to WETH
        if (_path[0] == USE_ETHEREUM) {
            require(msg.value >= _amount, "Insufficient ETH");
            IWETH(wethToken).deposit{value: _amount}();

            baseToken = wethToken;
        }
        _path[1] = _path[1] == USE_ETHEREUM ? wethToken : _path[1];

        address lpAddress = IUniswapV2Factory(uniswapFactoryAddress).getPair(
            baseToken,
            _path[1]
        );

        require(lpAddress != address(0), "Invalid Pair!");
        require(_amount > 0, "Amount = 0");

        if (_path[0] != USE_ETHEREUM) {
            IERC20(_path[0]).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        require(
            IERC20(baseToken).approve(uniswapRouterAddress, _amount),
            "approve failed."
        );

        _processOrder(_path[0], _path[1], _amount, msg.sender);
        emit MARKET_ORDER_PLACED(_amount, msg.sender, lpAddress);
    }

    /**
     * @notice Function to place an order according to params.
     * @dev Function to place an order according to params.
     * @param _path Path to the pair of tokens to trade.
     * @param  _orderActions booleans to indicate if the order is a limit or stop order.
     * @param _takeProfitRate The take profit rate of the order.
     * @param _stopLossRate The stop loss rate of the order.
     * @param _amountIn The amount of the first token in the order.
     * @param _amountOut The amount of the first token in the order.
     * @param _expiryIndex The index of the expiry duration of the order.
     * @param _maxGasFee The maximum gas fee of the order.
     */
    function placeOrder(
        address[2] memory _path, // base token, quote token
        bool[2] memory _orderActions, // isLimitOrder, isBuyOrder
        uint256 _takeProfitRate,
        uint256 _stopLossRate,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _expiryIndex,
        uint256 _maxGasFee
    ) external payable nonReentrant {
        require(
            _expiryIndex < expiryDurations.length,
            "Invalid expiry duration."
        );

        // store base token
        address baseToken = _path[0];
        // Converting ETH to WETH
        if (_path[0] == USE_ETHEREUM) {
            require(msg.value >= _amountIn, "Insufficient ETH");
            IWETH(wethToken).deposit{value: _amountIn}();

            baseToken = wethToken;
        }
        _path[1] = _path[1] == USE_ETHEREUM ? wethToken : _path[1];

        address lpAddress = IUniswapV2Factory(uniswapFactoryAddress).getPair(
            baseToken,
            _path[1]
        );

        require(lpAddress != address(0), "Invalid Pair!");
        require(_amountIn > 0, "Amount = 0");
        require(_takeProfitRate > 0, "Price = 0");
        require(
            _takeProfitRate > _stopLossRate,
            "Take profit must be greater than stop loss."
        );

        if (_path[0] != USE_ETHEREUM) {
            IERC20(_path[0]).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
        }

        uint256 _orderNum = ++orders[msg.sender].orderCount;
        uint256 _expireAt = _expiryIndex == 0
            ? 0
            : block.timestamp + expiryDurations[_expiryIndex];

        Order memory _orderDetail = Order({
            maker: msg.sender,
            path: _path,
            price: _takeProfitRate,
            stopPrice: _stopLossRate,
            amountIn: _amountIn,
            minAmountOut: _amountOut,
            timestamp: block.timestamp,
            expireAt: _expireAt,
            maxGasFee: _maxGasFee,
            isLimitOrder: _orderActions[0],
            isBuyOrder: _orderActions[1],
            status: OrderStatus.PENDING
        });
        orders[msg.sender].orders[_orderNum] = _orderDetail;

        if (_orderActions[1]) {
            orders[msg.sender].totalBuyOrders++;
            totalBuyOrders++;
        } else {
            orders[msg.sender].totalSellOrders++;
            totalSellOrders++;
        }

        emit ORDER_PLACED(
            [msg.sender, lpAddress],
            _orderActions,
            [
                _takeProfitRate,
                _stopLossRate,
                _amountIn,
                _orderNum,
                _expireAt,
                _maxGasFee
            ]
        );
    }

    /**
     * @notice Cancel a placed order before it is filled
     * @dev Cancel a placed order before it is filled
     * @param _orderId Order Id of the order to be cancelled
     */
    function cancelOrder(uint256 _orderId) external nonReentrant {
        require(_orderId != 0, "Invalid Order#");

        Order storage _currentOrder = orders[msg.sender].orders[_orderId];
        require(_currentOrder.maker == msg.sender, "Unauthorized Access!");
        require(
            _currentOrder.status == OrderStatus.PENDING,
            "Now Order Cant be cancelled"
        );

        _currentOrder.status = OrderStatus.CANCELLED;

        if (_currentOrder.path[0] == wethToken) {
            if (IWETH2(wethToken).balanceOf(msg.sender) > 0) {
                IWETH(wethToken).withdraw(_currentOrder.amountIn);
            }
            payable(msg.sender).transfer(_currentOrder.amountIn);
        } else {
            IERC20(_currentOrder.path[0]).transfer(
                msg.sender,
                _currentOrder.amountIn
            );
        }

        emit ORDER_CANCELLED(_currentOrder.isBuyOrder, msg.sender, _orderId);
    }

    /**
     * @notice Proceed to fill the limit order if price matched
     * @dev Proceed to fill the limit order if price matched and the amount of tokens to be transferred to the user
     * @param _usr User address who placed the order
     * @param _orderId Order Id of the order to be filled
     */
    function proceedOrder(
        address _usr,
        uint256 _orderId,
        uint256 _estimatedOrderFee
    ) external isAuthorized {
        Order storage _currentOrder = orders[_usr].orders[_orderId];

        require(
            _currentOrder.maxGasFee == 0 ||
                _currentOrder.maxGasFee >= _estimatedOrderFee,
            "Insufficient Gas Fee"
        );
        require(ethBalance[_usr] >= _estimatedOrderFee, "Insufficient ETH");
        require(
            _currentOrder.status == OrderStatus.PENDING,
            "Order Can not be filled"
        );
        require(
            _currentOrder.expireAt == 0 ||
                block.timestamp <= _currentOrder.expireAt,
            "Order Expired"
        );
        require(
            IERC20(_currentOrder.path[0]).approve(
                uniswapRouterAddress,
                _currentOrder.amountIn
            ),
            "approve failed."
        );

        uint256 fee = _currentOrder.amountIn.mul(orderFee).div(
            PERCENT_DENOMINATOR
        );
        IERC20(_currentOrder.path[0]).transfer(address(this), fee);
        uint256 swappingAmount = _currentOrder.amountIn.sub(fee);

        _processOrder(
            _currentOrder.path[0],
            _currentOrder.path[1],
            swappingAmount,
            _currentOrder.maker
        );

        _currentOrder.status = OrderStatus.FILLED;

        (bool _isFeePaid, ) = payable(_relayerPubKey).call{
            value: _estimatedOrderFee
        }("");
        require(_isFeePaid, "Fee Transfer Failed!");
        ethBalance[_usr] = ethBalance[_usr].sub(_estimatedOrderFee);

        emit ORDER_FILLED(
            _currentOrder.isBuyOrder,
            _currentOrder.amountIn,
            _currentOrder.maker,
            _orderId
        );
    }

    /**
     * @notice deposit ETH to the contract to pay gas fee
     * @dev deposit ETH to the contract to pay gas fee
     * @param _usr User address who placed the order
     */
    function depositETH(address _usr) public payable {
        require(msg.value > 0, "Insufficient ETH");
        ethBalance[_usr] = ethBalance[_usr].add(msg.value);
    }

    /**
     * @notice deposit ETH to the contract to pay gas fee
     * @dev deposit ETH to the contract to pay gas fee
     * @param _amount Amount of ETH to be withdrawn
     */
    function withdrawETH(uint256 _amount) external {
        require(ethBalance[msg.sender] >= _amount, "Insufficient ETH");
        payable(msg.sender).transfer(_amount);
        ethBalance[msg.sender] = ethBalance[msg.sender].sub(_amount);
    }

    // =========================== Internal Functions ===========================
    /**
     * @notice Process the order and transfer the tokens
     * @dev Process the order and transfer the tokens
     * @param _base Token address of the base token
     * @param _quote Token address of the quote token
     * @param _amountIn Amount of tokens to be swapped
     * @param _receiver User address who will receive the tokens
     */
    function _processOrder(
        address _base,
        address _quote,
        uint256 _amountIn,
        address _receiver
    ) private {
        address[] memory path = new address[](2);
        path[0] = _base;
        path[1] = _quote;
        IUniswapV2Router02(uniswapRouterAddress).swapExactTokensForTokens(
            _amountIn,
            0,
            path,
            _receiver,
            block.timestamp + 10
        );
    }

    // ================================= View Functions =================================

    /**
     * @notice Get Order detail of a specific order
     * @dev Get Order detail of a specific order
     * @param _user User address who placed the order
     * @param _orderNum Order Id of the order
     * @return amount of tokens to be swapped for the user
     * @return baseToken address of the base token
     * @return quoteToken address of the quote token
     * @return status of the order
     */
    function getOrderDetail(address _user, uint256 _orderNum)
        public
        view
        returns (
            uint256 amount,
            address baseToken,
            address quoteToken,
            string memory status
        )
    {
        Order storage _currentOrder = orders[_user].orders[_orderNum];
        return (
            _currentOrder.amountIn,
            _currentOrder.path[0],
            _currentOrder.path[1],
            getStatus(_currentOrder.status)
        );
    }

    function getStatus(OrderStatus _statusInd)
        public
        pure
        returns (string memory _status)
    {
        if (_statusInd == OrderStatus.PENDING) {
            _status = "PENDING";
        } else if (_statusInd == OrderStatus.FILLED) {
            _status = "FILLED";
        } else if (_statusInd == OrderStatus.CANCELLED) {
            _status = "CANCELLED";
        }
    }

    // function getAmountOutMin(
    //     uint256 _amountIn,
    //     address _baseToken,
    //     address _quoteToken,
    //     bool _isBuyOrder
    // ) public view returns (uint256) {
    //     (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
    //         uniswapFactoryAddress,
    //         _baseToken,
    //         _quoteToken
    //     );

    //     if (_isBuyOrder) {
    //         return
    //             UniswapV2Library.getAmountOut(_amountIn, reserveIn, reserveOut);
    //     } else {
    //         return
    //             UniswapV2Library.getAmountIn(_amountIn, reserveIn, reserveOut);
    //     }
    // }

    // **** LIBRARY FUNCTIONS ****
    // function quote(
    //     uint256 amountA,
    //     uint256 reserveA,
    //     uint256 reserveB
    // ) public pure returns (uint256 amountB) {
    //     return UniswapV2Library.quote(amountA, reserveA, reserveB);
    // }

    // ================================= Owner Functions =================================
    function updateOrderFee(uint256 _fee) external onlyOwner {
        orderFee = _fee;
    }

    function sweepFeeTokens(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_recipient, _amount);
    }

    function sweepFeeETH(address _recipient, uint256 _amount)
        external
        onlyOwner
    {
        payable(_recipient).transfer(_amount);
    }

    function updateServerKey(address _pubKey) external onlyOwner {
        _relayerPubKey = _pubKey;
    }

    function updateWETHAddress(address _wethAddress) external onlyOwner {
        wethToken = _wethAddress;
    }

    function updateRouter(address _router) external onlyOwner {
        uniswapRouterAddress = _router;
    }
}