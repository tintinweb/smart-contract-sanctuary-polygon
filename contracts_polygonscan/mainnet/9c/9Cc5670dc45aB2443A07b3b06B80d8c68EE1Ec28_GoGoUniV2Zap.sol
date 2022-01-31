/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

// File: contracts/libraries/Babylonian.sol


pragma solidity ^0.8.4;

library Babylonian {
	// credit for this implementation goes to
	// https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
	function sqrt(uint256 x) internal pure returns (uint256) {
		if (x == 0) return 0;
		// this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
		// however that code costs significantly more gas
		uint256 xx = x;
		uint256 r = 1;
		if (xx >= 0x100000000000000000000000000000000) {
			xx >>= 128;
			r <<= 64;
		}
		if (xx >= 0x10000000000000000) {
			xx >>= 64;
			r <<= 32;
		}
		if (xx >= 0x100000000) {
			xx >>= 32;
			r <<= 16;
		}
		if (xx >= 0x10000) {
			xx >>= 16;
			r <<= 8;
		}
		if (xx >= 0x100) {
			xx >>= 8;
			r <<= 4;
		}
		if (xx >= 0x10) {
			xx >>= 4;
			r <<= 2;
		}
		if (xx >= 0x8) {
			r <<= 1;
		}
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1; // Seven iterations should be enough
		uint256 r1 = x / r;
		return (r < r1 ? r : r1);
	}
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/zap.sol


pragma solidity ^0.8.4;






library LowGasSafeMath {
	/// @notice Returns x + y, reverts if sum overflows uint256
	/// @param x The augend
	/// @param y The addend
	/// @return z The sum of x and y
	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require((z = x + y) >= x);
	}

	/// @notice Returns x - y, reverts if underflows
	/// @param x The minuend
	/// @param y The subtrahend
	/// @return z The difference of x and y
	function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require((z = x - y) <= x);
	}

	/// @notice Returns x * y, reverts if overflows
	/// @param x The multiplicand
	/// @param y The multiplier
	/// @return z The product of x and y
	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require(x == 0 || (z = x * y) / x == y);
	}

	/// @notice Returns x + y, reverts if overflows or underflows
	/// @param x The augend
	/// @param y The addend
	/// @return z The sum of x and y
	function add(int256 x, int256 y) internal pure returns (int256 z) {
		require((z = x + y) >= x == (y >= 0));
	}

	/// @notice Returns x - y, reverts if overflows or underflows
	/// @param x The minuend
	/// @param y The subtrahend
	/// @return z The difference of x and y
	function sub(int256 x, int256 y) internal pure returns (int256 z) {
		require((z = x - y) <= x == (y >= 0));
	}
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

interface IWETH is IERC20 {
	function deposit() external payable;

	function withdraw(uint256 wad) external;
}

interface IGoGoVault is IERC20 {
	function deposit(uint256 amount) external;

	function withdraw(uint256 shares) external;

	function want() external pure returns (address);
}

contract GoGoUniV2Zap {
	using LowGasSafeMath for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for IGoGoVault;

	IUniswapV2Router02 public immutable router;
	address public immutable WETH;
	uint256 public constant minimumAmount = 1000;

	constructor(address _router, address _WETH) {
		router = IUniswapV2Router02(_router);
		WETH = _WETH;
	}

	receive() external payable {
		assert(msg.sender == WETH);
	}

	function gogoInETH(address GoGoVault, uint256 tokenAmountOutMin)
		external
		payable
	{
		require(msg.value >= minimumAmount, "GoGo: Insignificant input amount");

		IWETH(WETH).deposit{ value: msg.value }();

		_swapAndStake(GoGoVault, tokenAmountOutMin, WETH);
	}

	function gogoIn(
		address GoGoVault,
		uint256 tokenAmountOutMin,
		address tokenIn,
		uint256 tokenInAmount
	) external {
		require(
			tokenInAmount >= minimumAmount,
			"GoGo: Insignificant input amount"
		);
		require(
			IERC20(tokenIn).allowance(msg.sender, address(this)) >=
				tokenInAmount,
			"GoGo: Input token is not approved"
		);

		IERC20(tokenIn).safeTransferFrom(
			msg.sender,
			address(this),
			tokenInAmount
		);

		_swapAndStake(GoGoVault, tokenAmountOutMin, tokenIn);
	}

	function gogoOut(address GoGoVault, uint256 withdrawAmount) external {
		IUniswapV2Pair pair = IUniswapV2Pair(GoGoVault);

		IERC20(GoGoVault).safeTransferFrom(
			msg.sender,
			address(this),
			withdrawAmount
		);

		if (pair.token0() != WETH && pair.token1() != WETH) {
			return _removeLiqudity(address(pair), msg.sender);
		}

		_removeLiqudity(address(pair), address(this));

		address[] memory tokens = new address[](2);
		tokens[0] = pair.token0();
		tokens[1] = pair.token1();

		_returnAssets(tokens);
	}

	function gogoOutAndSwap(
		address GoGoVault,
		uint256 withdrawAmount,
		address desiredToken,
		uint256 desiredTokenOutMin
	) external {
		IUniswapV2Pair pair = IUniswapV2Pair(GoGoVault);
		address token0 = pair.token0();
		address token1 = pair.token1();
		require(
			token0 == desiredToken || token1 == desiredToken,
			"GoGo: desired token not present in liqudity pair"
		);

		IERC20(GoGoVault).safeTransferFrom(
			msg.sender,
			address(this),
			withdrawAmount
		);
		_removeLiqudity(address(pair), address(this));

		address swapToken = token1 == desiredToken ? token0 : token1;
		address[] memory path = new address[](2);
		path[0] = swapToken;
		path[1] = desiredToken;

		_approveTokenIfNeeded(path[0], address(router));
		router.swapExactTokensForTokens(
			IERC20(swapToken).balanceOf(address(this)),
			desiredTokenOutMin,
			path,
			address(this),
			block.timestamp
		);

		_returnAssets(path);
	}

	function _removeLiqudity(address pair, address to) private {
		IERC20(pair).safeTransfer(pair, IERC20(pair).balanceOf(address(this)));
		(uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);

		require(
			amount0 >= minimumAmount,
			"UniswapV2Router: INSUFFICIENT_A_AMOUNT"
		);
		require(
			amount1 >= minimumAmount,
			"UniswapV2Router: INSUFFICIENT_B_AMOUNT"
		);
	}

	function _getVaultPair(address GoGoVault)
		private
		view
		returns (IGoGoVault vault, IUniswapV2Pair pair)
	{
		vault = IGoGoVault(GoGoVault);
		pair = IUniswapV2Pair(GoGoVault);
		require(
			pair.factory() == router.factory(),
			"GoGo: Incompatible liquidity pair factory"
		);
	}

	function _swapAndStake(
		address GoGoVault,
		uint256 tokenAmountOutMin,
		address tokenIn
	) private {
		IUniswapV2Pair pair = IUniswapV2Pair(GoGoVault);

		(uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
		require(
			reserveA > minimumAmount && reserveB > minimumAmount,
			"GoGo: Liquidity pair reserves too low"
		);

		bool isInputA = pair.token0() == tokenIn;
		require(
			isInputA || pair.token1() == tokenIn,
			"GoGo: Input token not present in liqudity pair"
		);

		address[] memory path = new address[](2);
		path[0] = tokenIn;
		path[1] = isInputA ? pair.token1() : pair.token0();

		uint256 fullInvestment = IERC20(tokenIn).balanceOf(address(this));
		uint256 swapAmountIn;
		if (isInputA) {
			swapAmountIn = _getSwapAmount(fullInvestment, reserveA, reserveB);
		} else {
			swapAmountIn = _getSwapAmount(fullInvestment, reserveB, reserveA);
		}

		_approveTokenIfNeeded(path[0], address(router));
		uint256[] memory swapedAmounts = router.swapExactTokensForTokens(
			swapAmountIn,
			tokenAmountOutMin,
			path,
			address(this),
			block.timestamp
		);

		_approveTokenIfNeeded(path[1], address(router));
		(, , uint256 amountLiquidity) = router.addLiquidity(
			path[0],
			path[1],
			fullInvestment.sub(swapedAmounts[0]),
			swapedAmounts[1],
			1,
			1,
			address(this),
			block.timestamp
		);
		IERC20(GoGoVault).safeTransfer(msg.sender, amountLiquidity);
		_returnAssets(path);
	}

	function _returnAssets(address[] memory tokens) private {
		uint256 balance;
		for (uint256 i; i < tokens.length; i++) {
			balance = IERC20(tokens[i]).balanceOf(address(this));
			if (balance > 0) {
				if (tokens[i] == WETH) {
					IWETH(WETH).withdraw(balance);
					(bool success, ) = msg.sender.call{ value: balance }(
						new bytes(0)
					);
					require(success, "GoGo: ETH transfer failed");
				} else {
					IERC20(tokens[i]).safeTransfer(msg.sender, balance);
				}
			}
		}
	}

	function _getSwapAmount(
		uint256 investmentA,
		uint256 reserveA,
		uint256 reserveB
	) private view returns (uint256 swapAmount) {
		uint256 halfInvestment = investmentA / 2;
		uint256 nominator = router.getAmountOut(
			halfInvestment,
			reserveA,
			reserveB
		);
		uint256 denominator = router.quote(
			halfInvestment,
			reserveA.add(halfInvestment),
			reserveB.sub(nominator)
		);
		swapAmount = investmentA.sub(
			Babylonian.sqrt(
				(halfInvestment * halfInvestment * nominator) / denominator
			)
		);
	}

	function estimateSwap(
		address GoGoVault,
		address tokenIn,
		uint256 fullInvestmentIn
	)
		public
		view
		returns (
			uint256 swapAmountIn,
			uint256 swapAmountOut,
			address swapTokenOut
		)
	{
		checkWETH();
		IUniswapV2Pair pair = IUniswapV2Pair(GoGoVault);

		bool isInputA = pair.token0() == tokenIn;
		require(
			isInputA || pair.token1() == tokenIn,
			"GoGo: Input token not present in liqudity pair"
		);

		(uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
		(reserveA, reserveB) = isInputA
			? (reserveA, reserveB)
			: (reserveB, reserveA);

		swapAmountIn = _getSwapAmount(fullInvestmentIn, reserveA, reserveB);
		swapAmountOut = router.getAmountOut(swapAmountIn, reserveA, reserveB);
		swapTokenOut = isInputA ? pair.token1() : pair.token0();
	}

	function checkWETH() public view returns (bool isValid) {
		isValid = WETH == router.WETH();
		require(isValid, "GoGo: WETH address not matching Router.WETH()");
	}

	function _approveTokenIfNeeded(address token, address spender) private {
		if (IERC20(token).allowance(address(this), spender) == 0) {
			IERC20(token).safeApprove(spender, 2**256 - 1);
		}
	}
}