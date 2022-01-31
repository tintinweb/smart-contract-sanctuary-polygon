// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= DEUSZapper =========================
// ==============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Mohammad Mst
// Kazem GH

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface IUniswapV2Router02 {
	function factory() external pure returns (address);
	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
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

	function getAmountsOut(
		uint256 amountIn, 
		address[] calldata path
	) external view returns (uint256[] memory amounts);
}

interface IUniwapV2Pair {
	function token0() external pure returns (address);
	function token1() external pure returns (address);
	function totalSupply() external view returns (uint);
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IStaking {
	function depositFor(address _user, uint256 amount) external;
}

struct ProxyInput {
	uint amountIn;
	uint minAmountOut;
	uint deusPriceUSD;
	uint colPriceUSD;
	uint usdcForMintAmount;
	uint deusNeededAmount;
	uint expireBlock;
	bytes[] sigs;
}

interface IDEIProxy {
	function getUSDC2DEIInputs(
		uint amountIn, 
		uint deusPriceUSD, 
		uint colPriceUSD
	) external view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount);
	function USDC2DEI(ProxyInput memory proxyInput) external returns (uint deiAmount);
}

struct ZapperInput {
	uint amountIn;
	uint deusPriceUSD;
	uint collateralPrice;
	uint iterations;
	address[] toUsdcPath;
	address[] toMaticPath;
}

contract DEI_USDC_ZAPPER is Ownable {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */

	bool public stopped;
	address public uniswapRouter;
	address public pairAddress;
	address public usdcAddress;
	address public deiAddress;
	address public stakingAddress;
	address public deiProxyAddress;
	uint private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor (
		address _pairAddress,
		address _usdcAddress,
		address _deiAddress,
		address _uniswapRouter,
		address _stakingAddress,
		address _deiProxyAddress
	) {
		uniswapRouter = _uniswapRouter;
		pairAddress = _pairAddress;
		usdcAddress = _usdcAddress;
		deiAddress = _deiAddress;
		stakingAddress = _stakingAddress;
		deiProxyAddress = _deiProxyAddress;
		init();
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function approve(address token, address to) public onlyOwner {
		IERC20(token).safeApprove(to, type(uint256).max);
	}

	function emergencyWithdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).safeTransfer(to, amount);
	}

	function emergencyWithdrawETH(address recv, uint amount) external onlyOwner {
		payable(recv).transfer(amount);
	}

	function setStaking(address _stakingAddress) external onlyOwner {
		stakingAddress = _stakingAddress;
		emit StakingSet(stakingAddress);
	}

	function setVariables(
		address _pairAddress,
		address _usdcAddress,
		address _deiAddress,
		address _uniswapRouter,
		address _stakingAddress,
		address _deiProxyAddress
	) external onlyOwner {
		uniswapRouter = _uniswapRouter;
		pairAddress = _pairAddress;
		usdcAddress = _usdcAddress;
		deiAddress = _deiAddress;
		stakingAddress = _stakingAddress;
		deiProxyAddress = _deiProxyAddress;
	}

	// circuit breaker modifiers
	modifier stopInEmergency() {
		require(!stopped, "ZAPPER: temporarily paused");
		_;
	}

	/* ========== PUBLIC FUNCTIONS ========== */
	function usdcToDei (ProxyInput memory proxyInput, uint totalUsdcAmount) internal returns(uint token0Bought, uint token1Bought){
		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		if (usdcAddress == pair.token0()) {
			token1Bought = IDEIProxy(deiProxyAddress).USDC2DEI(proxyInput);
			token0Bought = totalUsdcAmount - proxyInput.amountIn;
		} else {
			token0Bought = IDEIProxy(deiProxyAddress).USDC2DEI(proxyInput);
			token1Bought = totalUsdcAmount - proxyInput.amountIn;
		}
	}

	function zapInNativecoin(
		uint256 minLPAmount,
		bool transferResidual,  // Set false to save gas by donating the residual remaining after a Zap
		ProxyInput memory proxyInput,
		address[] calldata path,
		uint usdcAmountToSwap
	) external payable {
		uint totalUsdcAmount = IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: msg.value}(1, path, address(this), deadline)[path.length-1];
		proxyInput.amountIn = usdcAmountToSwap;
		
		(uint256 token0Bought, uint256 token1Bought) = usdcToDei(proxyInput, totalUsdcAmount);

		uint256 LPBought = _uniDeposit(IUniwapV2Pair(pairAddress).token0(),
										IUniwapV2Pair(pairAddress).token1(),
										token0Bought,
										token1Bought,
										transferResidual);

		require(LPBought >= minLPAmount, "ZAPPER: Insufficient output amount");

		IStaking(stakingAddress).depositFor(msg.sender, LPBought);

		emit ZappedIn(address(0), pairAddress, msg.value, LPBought, transferResidual);
	}

	function zapInERC20(
		uint256 amountIn,
		uint256 minLPAmount,
		bool transferResidual,  // Set false to save gas by donating the residual remaining after a Zap
		ProxyInput memory proxyInput,
		address[] calldata path,
		uint usdcAmountToSwap
	) external {
		IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
		
		uint totalUsdcAmount = amountIn;
		if (path[0] != usdcAddress) {
			// approve token if doesn't have allowance
			if (IERC20(path[0]).allowance(address(this), uniswapRouter) == 0) IERC20(path[0]).safeApprove(uniswapRouter, type(uint).max);
			totalUsdcAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amountIn, 1, path, address(this), deadline)[path.length-1];
		}

		proxyInput.amountIn = usdcAmountToSwap;

		(uint256 token0Bought, uint256 token1Bought) = usdcToDei(proxyInput, totalUsdcAmount);

		uint256 LPBought = _uniDeposit(IUniwapV2Pair(pairAddress).token0(),
										IUniwapV2Pair(pairAddress).token1(),
										token0Bought,
										token1Bought,
										transferResidual);

		require(LPBought >= minLPAmount, "ZAPPER: Insufficient output amount");

		IStaking(stakingAddress).depositFor(msg.sender, LPBought);

		emit ZappedIn(path[0], pairAddress, amountIn, LPBought, transferResidual);
	}


	function _uniDeposit(
		address _toUnipoolToken0,
		address _toUnipoolToken1,
		uint256 token0Bought,
		uint256 token1Bought,
		bool transferResidual
	) internal returns(uint256) {
		(uint256 amountA, uint256 amountB, uint256 LP) = IUniswapV2Router02(uniswapRouter).addLiquidity(_toUnipoolToken0,
																										_toUnipoolToken1,
																										token0Bought,
																										token1Bought,
																										1,
																										1,
																										address(this),
																										deadline);

		if (transferResidual) {
			//Returning Residue in token0, if any.
			if (token0Bought - amountA > 0) {
				IERC20(_toUnipoolToken0).safeTransfer(
					msg.sender,
					token0Bought - amountA
				);
			}

			//Returning Residue in token1, if any
			if (token1Bought - amountB > 0) {
				IERC20(_toUnipoolToken1).safeTransfer(
					msg.sender,
					token1Bought - amountB
				);
			}
		}

		return LP;
	}

	/* ========== VIEWS ========== */

	function getAmountOut(ZapperInput memory input) public view returns (uint percentage, uint lp ,uint usdcForMintAmount, uint deusNeededAmount, uint swapAmountUsdc) {
		uint totalUsdcAmount = input.amountIn;
		if(input.toUsdcPath[0] != usdcAddress) {
			totalUsdcAmount = IUniswapV2Router02(uniswapRouter).getAmountsOut(input.amountIn, input.toUsdcPath)[input.toUsdcPath.length - 1];
		}

		input.amountIn = totalUsdcAmount;
		uint remain;
		(swapAmountUsdc, remain) = getSwapAmountUsdc(input);
		(, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxyAddress).getUSDC2DEIInputs(swapAmountUsdc, input.deusPriceUSD, input.collateralPrice);
		uint usdcAmount = totalUsdcAmount - swapAmountUsdc - remain;

		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		(uint res0, uint res1, ) = pair.getReserves();
		
		if(pair.token0() == usdcAddress) {
			percentage = usdcAmount * 1e6 / (res0 + usdcAmount);
			lp = usdcAmount * pair.totalSupply() / res0;
		} else {
			percentage = usdcAmount * 1e6 / (res1 + usdcAmount);
			lp = usdcAmount * pair.totalSupply() / res1;
		}
	}

	function getSwapAmountUsdc(ZapperInput memory input) public view returns(uint, uint) {

		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		uint reservedUsdc;
		uint reservedDei;
		if (usdcAddress == pair.token0()) {
			(reservedUsdc, reservedDei, ) = pair.getReserves();
		} else {
			(reservedDei, reservedUsdc, ) = pair.getReserves();
		}

		uint remain = input.amountIn * 1e12;
		uint x;
		uint y;
		uint amountToSwap;
		for (uint256 i = 0; i < input.iterations; i++) {
			x = remain / 2;

			(y, ,) = IDEIProxy(deiProxyAddress).getUSDC2DEIInputs(x / 1e12, input.deusPriceUSD, input.collateralPrice);

			if(x < 2e16) {
				break;
			}
			
			while(y * reservedUsdc * 1e12 / reservedDei + x > remain) {
				x = remain - y * reservedUsdc * 1e12 / reservedDei;
				(y, ,) = IDEIProxy(deiProxyAddress).getUSDC2DEIInputs(x / 1e12, input.deusPriceUSD, input.collateralPrice);
			}

			remain = remain - y * reservedUsdc * 1e12 / reservedDei - x;
			amountToSwap += x;
		}
		return (amountToSwap / 1e12, remain / 1e12);
		
	}

	function getSwapAmountByPath(ZapperInput memory input) public view returns(uint, uint) {
		uint totalUsdcAmount = IUniswapV2Router02(uniswapRouter).getAmountsOut(input.amountIn, input.toUsdcPath)[input.toUsdcPath.length-1];
		input.amountIn = totalUsdcAmount;
		return getSwapAmountUsdc(input);
	}

	function init() public onlyOwner {
		approve(IUniwapV2Pair(pairAddress).token0(), uniswapRouter);
		approve(IUniwapV2Pair(pairAddress).token1(), uniswapRouter);
		approve(usdcAddress, deiProxyAddress);
		approve(pairAddress, stakingAddress);
	}

	// to Pause the contract
	function toggleContractActive() external onlyOwner {
		stopped = !stopped;
	}

	/* ========== EVENTS ========== */

	event StakingSet(address staking);
	event ZappedIn(address input_token, address output_token, uint input_amount, uint output_amount, bool transfer_residual);
}

// Dar panahe Khoda

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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