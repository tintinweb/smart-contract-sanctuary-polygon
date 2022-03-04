/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IPentSpliter_V1_3 {

    enum DISTRIBUTION_METHOD {
        CREATE,
        RENT,
        FUSION,
        CASHOUT
    }

    enum DISTRIBUTION {
        REWARD_POOL,
        TREASURY,
        VAULT,
        LIQUIDITY,
        BURN_ADDRESS
    }


    // for admin
    function updateProtocolAddresses(DISTRIBUTION _target, address _newAddress) external;

    function updateProtocolFees(DISTRIBUTION_METHOD _method, DISTRIBUTION _feeIndex, uint256 _newValue) external;

    function updateSwapAmount(uint256 _newValue) external;

    function updateTokenAddress(address _newToken) external;

    function updateUniswapV2Router(address newAddress) external;


    // for user
    function addBalance(DISTRIBUTION_METHOD _method, uint256 _value) external;
}

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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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

contract PentSpliter_V1_3 is IPentSpliter_V1_3 {
    using SafeMath for uint256;

    address public admin;
    mapping(address => bool) managers;

    address public token;

    bool public swapping = false;
    uint256 public swapAvailableAmount = 1 * 10 ** 18;
    mapping(DISTRIBUTION_METHOD => uint256) public balanceOfContract;
    mapping(DISTRIBUTION => address) public protocolAddresses;
    mapping(DISTRIBUTION_METHOD => mapping(DISTRIBUTION => uint256)) public protocolFees;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier onlyAdmin() {
        require(msg.sender == admin, "MANAGEMENT: NOT ADMIN");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender] == true, "MANAGEMENT: NOT MANAGER");
        _;
    }

    constructor (address _token, address _uniswapV2Router) {
        admin = msg.sender;
        managers[msg.sender] = true;

        require(_token != address(0) && _uniswapV2Router != address(0), "SPLITER: CONST ADDRESS ERROR");

        token = _token;

        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            uniswapV2Router.WETH(),
            token
        );

        if (pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(uniswapV2Router.WETH(), token);
        } else {
            uniswapV2Pair = pair;
        }
    }

    receive() external payable {}

    function addManager(address _newManager) external onlyAdmin {
        require(_newManager != address(0), "MANAGEMENT: ADD MANAGER ERROR");

        managers[_newManager] = true;
    }

    function removeManager(address _manager) external onlyAdmin {
        require(_manager != address(0), "MANAGEMENT: REMOVE MANAGER ERROR");

        managers[_manager] = false;
    }

    function manualTransfer(address _target, uint256 _amount) public onlyAdmin {
        IERC20(token).transfer(_target, _amount);
    }

	function manualswap(uint amount) public onlyAdmin {
		if (amount > IERC20(token).balanceOf(address(this))) amount = IERC20(token).balanceOf(address(this));
		swapTokensForEth(amount);
	}

	function manualsend(uint amount) public onlyAdmin {
		if (amount > address(this).balance) amount = address(this).balance;
		payable(admin).transfer(amount);
	}



    // Admin Helpere
    function updateProtocolAddresses(DISTRIBUTION _target, address _newAddress) external override onlyManager {
        protocolAddresses[_target] = _newAddress;
    }

    function updateProtocolFees(DISTRIBUTION_METHOD _method, DISTRIBUTION _feeIndex, uint256 _newValue) external override onlyManager {
        protocolFees[_method][_feeIndex] = _newValue;
    }

    function updateSwapAmount(uint256 _newValue) external override onlyManager {
        swapAvailableAmount = _newValue;
    }

    function updateTokenAddress(address _newToken) external override onlyManager {
        require(_newToken != address(0), "PENT ZERO ADDRESS");
        token = _newToken;

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            uniswapV2Router.WETH(),
            token
        );

        if (pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(uniswapV2Router.WETH(), token);
        } else {
            uniswapV2Pair = pair;
        }
    }

    function updateUniswapV2Router(address newAddress) external override onlyManager {
        require(newAddress != address(uniswapV2Router), "ALEADY SET");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(token, uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }



    // User Helper
    function addBalance(DISTRIBUTION_METHOD _method, uint256 _value) external override onlyManager {
        balanceOfContract[_method] += _value;
        distribution(_method);
    }



    // Internal Function
    function distribution(DISTRIBUTION_METHOD _method) internal {
        if (balanceOfContract[_method] >= swapAvailableAmount && swapping) {
            swapping = true;

            uint256 swapAmount = balanceOfContract[_method];

            uint256 amountForRewardsPool = swapAmount * (protocolFees[_method][DISTRIBUTION.REWARD_POOL]) / 100;
            uint256 amountForTreasury = swapAmount * (protocolFees[_method][DISTRIBUTION.TREASURY]) / 100;
            uint256 amountForVault = swapAmount * (protocolFees[_method][DISTRIBUTION.VAULT]) / 100;
            uint256 amountForLiquidity = swapAmount * (protocolFees[_method][DISTRIBUTION.LIQUIDITY]) / 100;
            uint256 amountForBurn = swapAmount * (protocolFees[_method][DISTRIBUTION.BURN_ADDRESS]) / 100;

            if (protocolFees[_method][DISTRIBUTION.REWARD_POOL] != 0) {
                IERC20(token).transfer(protocolAddresses[DISTRIBUTION.REWARD_POOL], amountForRewardsPool);
            }

            if (protocolFees[_method][DISTRIBUTION.TREASURY] != 0) {
                swapAndSendToFee(protocolAddresses[DISTRIBUTION.TREASURY], amountForTreasury);
            }

            if (protocolFees[_method][DISTRIBUTION.VAULT] != 0) {
                swapAndSendToFee(protocolAddresses[DISTRIBUTION.VAULT], amountForVault);
            }

            if (protocolFees[_method][DISTRIBUTION.LIQUIDITY] != 0) {
                swapAndLiquify(amountForLiquidity);
            }

            if (protocolFees[_method][DISTRIBUTION.BURN_ADDRESS] != 0) {
                burn(amountForBurn);
            }

            balanceOfContract[_method] -= swapAmount;

            swapping = false;
        }
    }

    function burn(uint256 _tokenAmount) internal {
        IERC20(token).transfer(protocolAddresses[DISTRIBUTION.BURN_ADDRESS], _tokenAmount);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        (bool success, ) = destination.call{value: newBalance}("");
        require(success, "PAYMENT FAIL");
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

	function swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();

        IERC20(token).approve(address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
	}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        IERC20(token).approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            token,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }
}