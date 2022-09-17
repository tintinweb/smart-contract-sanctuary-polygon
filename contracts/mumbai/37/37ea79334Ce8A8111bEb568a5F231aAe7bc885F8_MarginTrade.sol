/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-27
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the decimal poimt of the token.
     */
    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.7.6;

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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

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
        bool approveMax,
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

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.7.6;

contract MarginTrade is Ownable {
    using SafeMath for uint256;

    struct Position {
        address userAddress;
        address asset;
        uint256 assetAmount;
        uint256 reverseAmount;
        address targetAsset;
        uint256 targetAmount;
        uint256 timestamp;
        uint256 tradedPrice;
        uint256 closedPrice;
        uint256 liquidationPrice;
        uint8 status; // 0 for create, 1 for close, 2 for liquidate
    }

    struct Deposit {
        uint256 assetAmount;
        uint256 leverage;
        uint256 loanAmount;
        uint256 interestAccumulated;
        uint256 timestamp;
        uint256 usedMargin;
        uint256 usedLoan;
        uint256 lossValue;
        uint256 gainValue;
        uint256 exitAmount;
    }

    // Starting position
    uint256 public positionID = 1;
    // Interest per block
    uint256 interestPerBlock = 2E18;

    uint256 public tradeDeadline = 5 minutes;

    uint256 public reserveMargin;
    // handles trade position
    mapping(uint256 => Position) public positionIDs;
    // Handles users deposits
    mapping(address => mapping(address => Deposit)) public deposits;
    // Handles array of position id
    mapping(address => uint256[]) public usersPosition;
    // users positions based on deposit token
    mapping(address => mapping(address => uint256[]))
        public userPositionByAsset;
    // User balance
    mapping(address => mapping(address => uint256)) public userbalances;

    mapping(address => uint256) public availableLiquidity;
    // Event for deposit
    event DepositEvent(
        address User,
        address Token,
        uint256 Amount,
        uint256 Timestamp
    );
    // Event to close position
    event closeTrade(uint256 positionID);

    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x8954AfA98594b838bda56FE4C12a09D7739D179b
        );
        uniswapV2Router = _uniswapV2Router;
        reserveMargin = 2;
    }

    receive() external payable {}

    function deposit(
        address tokenAddress,
        uint256 amount,
        uint256 leverage
    ) external payable {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        require(amount > 0 || msg.value > 0, "Deposit call : Null Amount");
        if (tokenAddress == address(0)) amount = msg.value;
        else
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );

        // If deposit data exist, calculate interest so far
        if (depositInfo.assetAmount > 0) {
            accureInterest(tokenAddress, depositInfo.loanAmount);
        }
        // Record entry data
        depositInfo.assetAmount = depositInfo.assetAmount.add(amount); //100
        depositInfo.leverage = depositInfo.leverage.add(leverage);
        depositInfo.loanAmount = depositInfo.loanAmount.add(
            (amount.mul(leverage)).sub(amount)
        );
        depositInfo.timestamp = block.number;
        // Loan should be there in contract
        availableLiquidity[tokenAddress] = availableLiquidity[tokenAddress].sub(
            depositInfo.loanAmount
        );
        // Additonal amount storage
        userbalances[msg.sender][tokenAddress] = userbalances[msg.sender][
            tokenAddress
        ].add(amount);
        emit DepositEvent(msg.sender, tokenAddress, amount, block.timestamp);
    }

    function createPositionandTrade(
        address tokenAddress,
        address targetToken,
        uint256 amount
    ) external {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        // Allowed should be sub of used loan and used margin
        uint256 allowedDeposit = depositInfo
            .assetAmount
            .add(depositInfo.loanAmount)
            .sub(depositInfo.usedMargin.add(depositInfo.usedLoan));
        allowedDeposit = allowedDeposit.sub(
            allowedDeposit.mul(reserveMargin).div(100)
        );
        require(
            allowedDeposit >= amount,
            "Create Position call : Insufficient Deposit"
        );
        //  Path for quickswap swap
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = targetToken;
        if (tokenAddress == address(0)) path[0] = uniswapV2Router.WETH();

        // pair should exist in quickswap
        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            path[0],
            path[1]
        );
        require(pair != address(0), "Create Position call :Invalid Pair");
        // Additonal condition to check balance -- can be removed
        if (tokenAddress == address(0))
            require(
                address(this).balance >= amount,
                "Create position call : Insufficient payable Balance"
            );
        else
            require(
                IERC20(tokenAddress).balanceOf(address(this)) >= amount,
                "Create position call : Insufficient Token Balance"
            );

        // Store trade result and traded price
        (uint256 _result, uint256 tradePrice) = trade(amount, path);

        // Store position created details
        positionIDs[positionID] = Position({
            userAddress: msg.sender,
            asset: tokenAddress,
            assetAmount: amount,
            reverseAmount: 0,
            targetAsset: targetToken,
            targetAmount: _result,
            timestamp: block.number,
            tradedPrice: tradePrice,
            closedPrice: 0,
            liquidationPrice: (tradePrice* 80) / 100,
            status: 0
        });
        // Used Loan is 80% of given amount
        depositInfo.usedLoan = depositInfo.usedLoan.add(
            amount.mul(80).div(100)
        );
        // Used margin is 20% of given amount
        depositInfo.usedMargin = depositInfo.usedMargin.add(
            amount.mul(20).div(100)
        );
        // Pushing position id of individual user
        usersPosition[msg.sender].push(positionID);
        userPositionByAsset[msg.sender][tokenAddress].push(positionID);
        positionID++;
    }

    function trade(uint256 tradeAmount, address[] memory path)
        internal
        returns (uint256, uint256)
    {
        uint256[] memory result = new uint256[](2);
        uint256 deadline = block.timestamp + tradeDeadline;
        uint256 decimals = IERC20(path[0]).decimals();
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            1 * 10**decimals,
            path
        );
        if (path[0] == uniswapV2Router.WETH()) {
            // Trade and get asset out
            result = uniswapV2Router.swapExactETHForTokens{value: tradeAmount}(
                0,
                path,
                address(this),
                deadline
            );
        } else if (path[1] == uniswapV2Router.WETH()) {
            // Approve token in
            IERC20(path[0]).approve(address(uniswapV2Router), tradeAmount);
            // Trade and get asset out
            result = uniswapV2Router.swapExactTokensForETH(
                tradeAmount,
                0,
                path,
                address(this),
                deadline
            );
        } else {
            // Approve token in
            IERC20(path[0]).approve(address(uniswapV2Router), tradeAmount);
            // Trade and get asset out
            result = uniswapV2Router.swapExactTokensForTokens(
                tradeAmount,
                0,
                path,
                address(this),
                deadline
            );
        }
        return (result[1], price[1]);
    }

    function closePosition(uint256 _positionID) public payable {
        Position storage positionInfo = positionIDs[_positionID];
        // Only close one's one position
        require(
            positionInfo.userAddress == msg.sender,
            "Close Position : Not the user"
        );
        // Should be open position
        require(positionInfo.status == 0, "Close Position : Invalid Position");
        Deposit storage depositInfo = deposits[msg.sender][positionInfo.asset];
        // Path for trade back
        address[] memory path = new address[](2);
        path[1] = positionInfo.asset;
        path[0] = positionInfo.targetAsset;
        if (path[1] == address(0)) path[1] = uniswapV2Router.WETH();
        // Store trade result
        (uint256 _result, ) = trade(positionInfo.targetAmount, path);
        // Since price should be in same asset
        // Calculate path again and get price
        uint256 decimals = IERC20(path[1]).decimals();
        address[] memory path_ = new address[](2);
        path_[0] = path[1];
        path_[1] = path[0];
        // Get Price
        uint256[] memory price = uniswapV2Router.getAmountsOut(
            1 * 10**decimals,
            path_
        );
        // Store Traded values
        positionInfo.reverseAmount = _result;
        positionInfo.closedPrice = price[1];
        positionInfo.status = 1;

        // Since position is closed asset goes to available margin
        // asset amount wont be the same -- check for errors
        depositInfo.usedMargin = depositInfo.usedMargin.sub(
            positionInfo.assetAmount.mul(20).div(100)
        );

        // Sub / add Profit and loss to asset amount
        uint256 temp;
        if (positionInfo.assetAmount >= _result) {
            temp = positionInfo.assetAmount.sub(_result);
            if (depositInfo.assetAmount >= temp)
                depositInfo.assetAmount = depositInfo.assetAmount.sub(temp);
            else depositInfo.assetAmount = depositInfo.assetAmount.add(_result);
            depositInfo.lossValue = depositInfo.lossValue.add(temp);
        } else {
            temp = _result.sub(positionInfo.assetAmount);
            depositInfo.assetAmount = depositInfo.assetAmount.add(temp);
            depositInfo.gainValue = depositInfo.gainValue.add(temp);
        }
        // allocated loan for position asset
        uint256 allocatedLoan = (positionInfo.assetAmount.mul(80).div(100));
        // Add loan back to available liquidity for that user -- not to global
        // Reduce from here
        depositInfo.usedLoan = depositInfo.usedLoan.sub(allocatedLoan);
        // ****** Below has to be in withdraw  *******//
        // // Add here
        // availableLiquidity[positionInfo.asset] = availableLiquidity[positionInfo.asset].add(allocatedLoan);
        emit closeTrade(_positionID);
    }

    function withdraw(address tokenAddress, uint256 amount) external payable {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        require(
            depositInfo.assetAmount.sub(depositInfo.usedMargin) > 0,
            "Withdraw call : Insufficient Deposit"
        );
        uint256 withdrawAmount;
        accureInterest(tokenAddress, depositInfo.loanAmount);
        uint256 _interest = depositInfo.interestAccumulated;
        uint256 actualAsset = depositInfo.assetAmount +
            depositInfo.lossValue -
            depositInfo.gainValue;
        uint256 leverage = depositInfo.loanAmount.div(actualAsset);
        // require(userbalances[msg.sender][tokenAddress].sub(amount) > _interest, "Withdraw call : Cannot withdraw more than allowed");
        if (amount + _interest >= depositInfo.assetAmount) {
            depositInfo.interestAccumulated = 0;
            if (depositInfo.assetAmount < _interest) {
                uint256 amountTopay = _interest.sub(depositInfo.assetAmount);
                if (tokenAddress == address(0))
                    require(
                        msg.value >= amountTopay,
                        "Withdraw call : Insufficient Payable Interest pay"
                    );
                else
                    IERC20(tokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        amountTopay
                    );
            }
            withdrawAmount = depositInfo.assetAmount.sub(_interest);
            userbalances[address(this)][tokenAddress] = userbalances[
                address(this)
            ][tokenAddress].add(_interest);
            depositInfo.assetAmount = depositInfo.assetAmount.sub(_interest);
            depositInfo.loanAmount = 0;
            depositInfo.leverage = 0;
            // for getting back liquidity
            amount = actualAsset;
        } else {
            withdrawAmount = amount;
        }
        if (tokenAddress == address(0)) msg.sender.transfer(withdrawAmount);
        else IERC20(tokenAddress).transfer(msg.sender, withdrawAmount);

        userbalances[msg.sender][tokenAddress] = userbalances[msg.sender][
            tokenAddress
        ].sub(withdrawAmount);
        depositInfo.assetAmount = depositInfo.assetAmount.sub(withdrawAmount);
        depositInfo.timestamp = block.number;
        availableLiquidity[tokenAddress] = availableLiquidity[tokenAddress].add(
            amount * leverage
        );
    }

    function withdrawTest(address tokenAddress, uint256 amount)
        external
        payable
    {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        require(
            depositInfo.assetAmount.sub(depositInfo.usedMargin) > 0,
            "Withdraw call : Insufficient Deposit"
        );

        uint256 actualAsset = depositInfo.assetAmount +
            depositInfo.lossValue -
            depositInfo.gainValue +
            depositInfo.exitAmount;
        // given 350(actualAsset)
        // Loan 550(loanAmount)
        // for x amount => (loanAmount*x)/actualAsset
        uint256 temp;
        if (depositInfo.assetAmount.add(depositInfo.usedMargin) == 0)
            temp = depositInfo.loanAmount.mul(
                amount + depositInfo.lossValue - depositInfo.gainValue
            );
        else temp = depositInfo.loanAmount.mul(amount);
        // Loan given for input amount
        uint256 allocatedLoan = temp / actualAsset;
        // Interest for given amount
        accureInterest(tokenAddress, allocatedLoan);
        uint256 _interest = depositInfo.interestAccumulated;
        // Interest has to be settled for further withdraw
        require(
            amount > _interest,
            "Withdraw call : Amount too less for paying interest"
        );
        // Withdraw with interest
        uint256 amountToWithdraw = amount.sub(_interest);
        // Add interest to contract
        userbalances[address(this)][tokenAddress] = userbalances[address(this)][
            tokenAddress
        ].add(_interest);
        // Reduce amount from depsosit
        depositInfo.assetAmount = depositInfo.assetAmount.sub(amount);
        // Reset deposit after full withdraw
        if (depositInfo.assetAmount.add(depositInfo.usedMargin) == 0) {
            depositInfo.loanAmount = 0;
            depositInfo.leverage = 0;
            depositInfo.exitAmount = 0;
            depositInfo.lossValue = 0;
            depositInfo.gainValue = 0;
            // allocatedLoan = amount+depositInfo.lossValue-depositInfo.gainValue;
        }
        // have exit amount for calculate actual deposit
        else depositInfo.exitAmount = depositInfo.exitAmount.add(amount);
        // Reduce loan amount from deposit, make it available for others
        // If it reduced here, leverge calculation at top will break
        // So make it zero when asset == 0
        // But add in availableLiquidity for others to use
        // **** depositInfo.loanAmount =  depositInfo.loanAmount.sub(allocatedLoan); **** //
        // add the allocated loan for user back to global availablity
        availableLiquidity[tokenAddress] = availableLiquidity[tokenAddress].add(
            allocatedLoan
        );
        // Reduce paid interest
        depositInfo.interestAccumulated = depositInfo.interestAccumulated.sub(
            _interest
        );
        // Send amount after withdraw
        if (tokenAddress == address(0)) msg.sender.transfer(amountToWithdraw);
        else IERC20(tokenAddress).transfer(msg.sender, amountToWithdraw);
    }

    function accureInterest(address tokenAddress, uint256 loanAmount) internal {
        Deposit storage depositInfo = deposits[msg.sender][tokenAddress];
        depositInfo.interestAccumulated = depositInfo.interestAccumulated.add(
            checkInterestAccumulated1(msg.sender, tokenAddress, loanAmount)
        );
    }

    function checkInterestAccumulated(address userAddress, address tokenAddress)
        public
        view
        returns (uint256)
    {
        Deposit memory depositInfo = deposits[userAddress][tokenAddress];
        uint256 loanAmount = depositInfo.loanAmount;
        uint256 interval = (block.number.sub(depositInfo.timestamp)).div(20);
        uint256 interest = depositInfo.interestAccumulated.add(
            loanAmount.mul(interval.mul(interestPerBlock).div(1000)).div(1E18)
        );
        return interest;
    }

    function checkInterestAccumulated1(
        address userAddress,
        address tokenAddress,
        uint256 loanAmount
    ) public view returns (uint256) {
        Deposit memory depositInfo = deposits[userAddress][tokenAddress];
        // uint256 loanAmount = depositInfo.loanAmount;
        uint256 interval = (block.number.sub(depositInfo.timestamp)).div(20);
        uint256 interest = depositInfo.interestAccumulated.add(
            loanAmount.mul(interval.mul(interestPerBlock).div(1000)).div(1E18)
        );
        return interest;
    }

    function liquidateOpenPosition(uint256 _positionID, address user)
        external
        onlyOwner
    {
        Position storage positionInfo = positionIDs[_positionID];
        // Should be open position
        require(positionInfo.status == 0, "Close Position : Invalid Position");
        if (positionInfo.tradedPrice < positionInfo.liquidationPrice) {
            Deposit storage depositInfo = deposits[user][positionInfo.asset];
            // Path for trade back
            address[] memory path = new address[](2);
            path[1] = positionInfo.asset;
            path[0] = positionInfo.targetAsset;
            if (path[1] == address(0)) path[1] = uniswapV2Router.WETH();
            // Store trade result
            (uint256 _result, ) = trade(positionInfo.targetAmount, path);
            // Since price should be in same asset
            // Calculate path again and get price
            uint256 decimals = IERC20(path[1]).decimals();
            address[] memory path_ = new address[](2);
            path_[0] = path[1];
            path_[1] = path[0];
            // Get Price
            uint256[] memory price = uniswapV2Router.getAmountsOut(
                1 * 10**decimals,
                path_
            );
            // Store Traded values
            positionInfo.reverseAmount = _result;
            positionInfo.closedPrice = price[1];
            positionInfo.status = 2;

            // Since position is closed asset goes to available margin
            // asset amount wont be the same -- check for errors
            depositInfo.usedMargin = depositInfo.usedMargin.sub(
                positionInfo.assetAmount.mul(20).div(100)
            );

            // Sub / add Profit and loss to asset amount
            uint256 temp;
            if (positionInfo.assetAmount >= _result) {
                temp = positionInfo.assetAmount.sub(_result);
                if (depositInfo.assetAmount >= temp)
                    depositInfo.assetAmount = depositInfo.assetAmount.sub(temp);
                else
                    depositInfo.assetAmount = depositInfo.assetAmount.add(
                        _result
                    );
                depositInfo.lossValue = depositInfo.lossValue.add(temp);
            } else {
                temp = _result.sub(positionInfo.assetAmount);
                depositInfo.assetAmount = depositInfo.assetAmount.add(temp);
                depositInfo.gainValue = depositInfo.gainValue.add(temp);
            }
            // allocated loan for position asset
            uint256 allocatedLoan = (positionInfo.assetAmount.mul(80).div(100));
            // Add loan back to available liquidity for that user -- not to global
            // Reduce from here
            depositInfo.usedLoan = depositInfo.usedLoan.sub(allocatedLoan);
            // ****** Below has to be in withdraw  *******//
            // // Add here
            // availableLiquidity[positionInfo.asset] = availableLiquidity[positionInfo.asset].add(allocatedLoan);
            emit closeTrade(_positionID);
        }
    }

    function withdrawInterestAccumulated(address tokenAddress)
        external
        onlyOwner
    {
        if (tokenAddress == address(0)) {
            uint256 maticBalance = userbalances[address(this)][tokenAddress];
            payable(owner()).transfer(maticBalance);
        } else {
            uint256 tokenBalance = userbalances[address(this)][tokenAddress];
            IERC20(tokenAddress).transfer(owner(), tokenBalance);
        }
    }

    function setTradeDeadline(uint256 _newDeadline) external onlyOwner {
        tradeDeadline = _newDeadline;
    }

    function addAsset(address tokenAddress, uint256 amount) external payable {
        if (tokenAddress == address(0)) {
            amount = msg.value;
        } else {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        availableLiquidity[tokenAddress] = availableLiquidity[tokenAddress].add(
            amount
        );
    }

    function removeAsset(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            payable(owner()).transfer(availableLiquidity[tokenAddress]);
        } else {
            IERC20(tokenAddress).transfer(
                msg.sender,
                availableLiquidity[tokenAddress]
            );
        }
        availableLiquidity[tokenAddress] = 0;
    }

    function getTradedAmount(address userAddress, address tokenAddress)
        public
        view
        returns (uint256 currectTradingAmount)
    {
        for (
            uint256 i = 0;
            i < userPositionByAsset[userAddress][tokenAddress].length;
            i++
        ) {
            Position storage positionInfo = positionIDs[
                userPositionByAsset[userAddress][tokenAddress][i]
            ];
            // Only close one's one position
            // Should be open position
            if (positionInfo.status == 0) {
                currectTradingAmount = positionInfo.assetAmount;
            }
        }
    }
}