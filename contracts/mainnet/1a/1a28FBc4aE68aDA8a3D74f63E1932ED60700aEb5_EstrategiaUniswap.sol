// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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
		// solhint-disable-next-line no-inline-assembly
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

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	/**
	 * @dev Performs a Solidity function call using a low level `call`. A
	 * plain`call` is an unsafe replacement for a function call: use this
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
		return
			functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(address target, bytes memory data)
		internal
		view
		returns (bytes memory)
	{
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

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
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

		// solhint-disable-next-line avoid-low-level-calls
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

				// solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import { Context } from "./Context.sol";

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
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
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
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import { SafeMath } from "./SafeMath.sol";
import { Address } from "./Address.sol";
import { IERC20 } from "../../interfaces/IERC20.sol";

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
	using SafeMath for uint256;
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
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
		);
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
		// solhint-disable-next-line max-line-length
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
		uint256 newAllowance = token.allowance(address(this), spender).add(value);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
		);
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender).sub(
			value,
			"SafeERC20: decreased allowance below zero"
		);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
		);
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

		bytes memory returndata = address(token).functionCall(
			data,
			"SafeERC20: low-level call failed"
		);
		if (returndata.length > 0) {
			// Return data is optional
			// solhint-disable-next-line max-line-length
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		uint256 c = a + b;
		if (c < a) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (b > a) return (false, 0);
		return (true, a - b);
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) return (true, 0);
		uint256 c = a * b;
		if (c / a != b) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (b == 0) return (false, 0);
		return (true, a / b);
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		if (b == 0) return (false, 0);
		return (true, a % b);
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
		require(b <= a, "SafeMath: subtraction overflow");
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
		if (a == 0) return 0;
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
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
		require(b > 0, "SafeMath: division by zero");
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
		require(b > 0, "SafeMath: modulo by zero");
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
		require(b <= a, errorMessage);
		return a - b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryDiv}.
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
		return a / b;
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
		require(b > 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
	uint8 internal constant RESOLUTION = 96;
	uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
	/// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = a * b
			// Compute the product mod 2**256 and mod 2**256 - 1
			// then use the Chinese Remainder Theorem to reconstruct
			// the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2**256 + prod0
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(a, b, not(0))
				prod0 := mul(a, b)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division
			if (prod1 == 0) {
				require(denominator > 0);
				assembly {
					result := div(prod0, denominator)
				}
				return result;
			}

			// Make sure the result is less than 2**256.
			// Also prevents denominator == 0
			require(denominator > prod1);

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0]
			// Compute remainder using mulmod
			uint256 remainder;
			assembly {
				remainder := mulmod(a, b, denominator)
			}
			// Subtract 256 bit number from 512 bit number
			assembly {
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator
			// Compute largest power of two divisor of denominator.
			// Always >= 1.
			// EDIT for 0.8 compatibility:
			// see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
			uint256 twos = denominator & (~denominator + 1);

			// Divide denominator by power of two
			assembly {
				denominator := div(denominator, twos)
			}

			// Divide [prod1 prod0] by the factors of two
			assembly {
				prod0 := div(prod0, twos)
			}
			// Shift in bits from prod1 into prod0. For this we need
			// to flip `twos` such that it is 2**256 / twos.
			// If twos is zero, then it becomes one
			assembly {
				twos := add(div(sub(0, twos), twos), 1)
			}
			prod0 |= prod1 * twos;

			// Invert denominator mod 2**256
			// Now that denominator is an odd number, it has an inverse
			// modulo 2**256 such that denominator * inv = 1 mod 2**256.
			// Compute the inverse by starting with a seed that is correct
			// correct for four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inv = (3 * denominator) ^ 2;
			// Now use Newton-Raphson iteration to improve the precision.
			// Thanks to Hensel's lifting lemma, this also works in modular
			// arithmetic, doubling the correct bits in each step.
			inv *= 2 - denominator * inv; // inverse mod 2**8
			inv *= 2 - denominator * inv; // inverse mod 2**16
			inv *= 2 - denominator * inv; // inverse mod 2**32
			inv *= 2 - denominator * inv; // inverse mod 2**64
			inv *= 2 - denominator * inv; // inverse mod 2**128
			inv *= 2 - denominator * inv; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying
			// with the modular inverse of denominator. This will give us the
			// correct result modulo 2**256. Since the precoditions guarantee
			// that the outcome is less than 2**256, this is the final result.
			// We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inv;
			return result;
		}
	}

	/// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	function mulDivRoundingUp(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		result = mulDiv(a, b, denominator);
		if (mulmod(a, b, denominator) > 0) {
			require(result < type(uint256).max);
			result++;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
	/// @notice Downcasts uint256 to uint128
	/// @param x The uint258 to be downcasted
	/// @return y The passed value, downcasted to uint128
	function toUint128(uint256 x) private pure returns (uint128 y) {
		require((y = uint128(x)) == x);
	}

	/// @notice Computes the amount of liquidity received for a given amount of token0 and price range
	/// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
	/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
	/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
	/// @param amount0 The amount0 being sent in
	/// @return liquidity The amount of returned liquidity
	function getLiquidityForAmount0(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount0
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
		uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
		return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
	}

	/// @notice Computes the amount of liquidity received for a given amount of token1 and price range
	/// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
	/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
	/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
	/// @param amount1 The amount1 being sent in
	/// @return liquidity The amount of returned liquidity
	function getLiquidityForAmount1(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount1
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
		return
			toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
	}

	/// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
	/// pool prices and the prices at the tick boundaries
	/// @param sqrtRatioX96 A sqrt price representing the current pool prices
	/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
	/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
	/// @param amount0 The amount of token0 being sent in
	/// @param amount1 The amount of token1 being sent in
	/// @return liquidity The maximum amount of liquidity received
	function getLiquidityForAmounts(
		uint160 sqrtRatioX96,
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount0,
		uint256 amount1
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		if (sqrtRatioX96 <= sqrtRatioAX96) {
			liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
		} else if (sqrtRatioX96 < sqrtRatioBX96) {
			uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
			uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

			liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
		} else {
			liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
		}
	}

	/// @notice Computes the amount of token0 for a given amount of liquidity and a price range
	/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
	/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
	/// @param liquidity The liquidity being valued
	/// @return amount0 The amount of token0
	function getAmount0ForLiquidity(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount0) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		return
			FullMath.mulDiv(
				uint256(liquidity) << FixedPoint96.RESOLUTION,
				sqrtRatioBX96 - sqrtRatioAX96,
				sqrtRatioBX96
			) / sqrtRatioAX96;
	}

	/// @notice Computes the amount of token1 for a given amount of liquidity and a price range
	/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
	/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
	/// @param liquidity The liquidity being valued
	/// @return amount1 The amount of token1
	function getAmount1ForLiquidity(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
	}

	/// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
	/// pool prices and the prices at the tick boundaries
	/// @param sqrtRatioX96 A sqrt price representing the current pool prices
	/// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
	/// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
	/// @param liquidity The liquidity being valued
	/// @return amount0 The amount of token0
	/// @return amount1 The amount of token1
	function getAmountsForLiquidity(
		uint160 sqrtRatioX96,
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount0, uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		if (sqrtRatioX96 <= sqrtRatioAX96) {
			amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
		} else if (sqrtRatioX96 < sqrtRatioBX96) {
			amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
			amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
		} else {
			amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
	/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
	int24 internal constant MIN_TICK = -887272;
	/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
	int24 internal constant MAX_TICK = -MIN_TICK;

	/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	/// @notice Calculates sqrt(1.0001^tick) * 2^96
	/// @dev Throws if |tick| > max tick
	/// @param tick The input tick for the above formula
	/// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
	/// at the given tick
	function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

		// EDIT: 0.8 compatibility
		require(absTick <= uint256(int256(MAX_TICK)), "T");

		uint256 ratio = absTick & 0x1 != 0
			? 0xfffcb933bd6fad37aa2d162d1a594001
			: 0x100000000000000000000000000000000;
		if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
		if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
		if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
		if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
		if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
		if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
		if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
		if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
		if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
		if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
		if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
		if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
		if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
		if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
		if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
		if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
		if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
		if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
		if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

		if (tick > 0) ratio = type(uint256).max / ratio;

		// this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
		// we then downcast because we know the result always fits within 160 bits due to our tick input constraint
		// we round up in the division so getTickAtSqrtRatio of the output price is always consistent
		sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
	}

	/// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
	/// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
	/// ever return.
	/// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
	/// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
	function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
		// second inequality must be < because the price can never reach the price at the max tick
		require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
		uint256 ratio = uint256(sqrtPriceX96) << 32;

		uint256 r = ratio;
		uint256 msb = 0;

		assembly {
			let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(5, gt(r, 0xFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(4, gt(r, 0xFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(3, gt(r, 0xFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(2, gt(r, 0xF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(1, gt(r, 0x3))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := gt(r, 0x1)
			msb := or(msb, f)
		}

		if (msb >= 128) r = ratio >> (msb - 127);
		else r = ratio << (127 - msb);

		int256 log_2 = (int256(msb) - 128) << 64;

		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(63, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(62, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(61, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(60, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(59, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(58, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(57, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(56, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(55, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(54, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(53, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(52, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(51, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(50, f))
		}

		int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

		int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
		int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

		tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
			? tickHi
			: tickLow;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "./librerias/SafeERC20.sol";
import { Ownable } from "./librerias/Ownable.sol";
import { FullMath } from "./librerias/uniswap/FullMath.sol";
import { TickMath } from "./librerias/uniswap/TickMath.sol";
import { LiquidityAmounts } from "./librerias/uniswap/LiquidityAmounts.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { IUniNFT } from "../interfaces/IUniNFT.sol";
import { IUniV3Router } from "../interfaces/IUniV3Router.sol";
import { IUniV3Pool } from "../interfaces/IUniV3Pool.sol";

/**
 * @title  TFM Estrategia UniswapV3
 * @author Elias (UNED)
 * @notice El Smart Contract hereda la funcionalidad de Ownable.
 *
 * @dev    Este es el contrato encargado de invertir los tokens.
 *         La estrategia interacciona con la Pool de Liquidez USDC-USDT en Uniswap.
 *         Los tokens recibidos como incentivo son reinvertidos en la estrategia.
 */
contract EstrategiaUniswap is Ownable {
	using SafeERC20 for IERC20; // Librería SafeERC20 cuando trabajamos con ERC20
	using TickMath for int24; // Librería TickMath para operar con Ticks

	// Contratos de Uniswap en Polygon
	IUniNFT public nftManager = IUniNFT(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
	IUniV3Router public router = IUniV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	IUniV3Pool public pool = IUniV3Pool(0xDaC8A8E6DBf8c690ec6815e0fF03491B2770255D);

	// Tokens utilizados
	address public token = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // USDC
	address public par = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); // USDT

	// Variable de ayuda
	uint256 internal constant MAX = type(uint256).max;

	// Address de la vault
	address public vault;

	// Id del token ERC721
	uint256 public tokenId;

	// Pool USDC-USDT 0.01%
	uint24 public constant poolFee = 100;

	// Liquidez de la posición
	uint128 public liquidez;

	// Estructura ticks
	struct Ticks {
		int24 tickInferior;
		int24 tickSuperior;
	}

	// Variable para guardar los ticks
	Ticks public ticks;

	// Eventos para visualizar depositos y retiradas
	event Deposito(uint256 tvl);
	event Retirada(uint256 tvl);

	/**
	 * @dev El constructor inicializa los valores de las distintas variables.
	 *
	 * @param _vault la address de la vault vinculada a la estrategia.
	 */
	constructor(
		address _vault,
		int24 _tickInferior,
		int24 _tickSuperior
	) {
		vault = _vault;

		ticks = Ticks({ tickInferior: _tickInferior, tickSuperior: _tickSuperior });

		_darPermisos();
	}

	/**
	 * @dev Deposita los tokens en Uniswap y los pone en Staking.
	 */
	function depositar() public {
		_cambiarMitad();

		if (tokenId != 0) {
			_darLiquidez();
		} else {
			// TokenId inexistente -> Necesitamos crear un NFT.
			(tokenId, liquidez, , ) = nftManager.mint(
				IUniNFT.NftStruct({
					token0: token,
					token1: par,
					fee: poolFee,
					tickLower: ticks.tickInferior,
					tickUpper: ticks.tickSuperior,
					amount0Desired: balanceDeToken(),
					amount1Desired: IERC20(par).balanceOf(address(this)),
					amount0Min: 0,
					amount1Min: 0,
					recipient: address(this),
					deadline: block.timestamp
				})
			);
		}

		emit Deposito(balanceEstrategia());
	}

	/**
	 * @dev Retira una cantidad de tokens y los envía de vuelta a la Vault.
	 */
	function retirar(uint256 _cantidad) external {
		require(msg.sender == vault, "no es la vault");
		// Balance en el contrato
		uint256 tokenBal = balanceDeToken();

		if (tokenBal < _cantidad) {
			// Necesitamos retirar del staking
			_retirarAlgo(_cantidad - tokenBal);
			tokenBal = balanceDeToken();
		}

		if (tokenBal > _cantidad) {
			// Reasignamos tokenBal para no transferir de más
			tokenBal = _cantidad;
		}

		IERC20(token).safeTransfer(vault, tokenBal);

		emit Retirada(balanceEstrategia());
	}

	/**
	 * @dev Reinvierte los beneficios.
	 */
	function reinvertir() external {
		_recogerFees();
		_darLiquidez();
	}

	/**
	 * @dev Retorna la estimación de beneficio de la estrategia.
	 */
	function gananciaEstimada() public view returns (uint256 token0Fee, uint256 token1Fee) {
		(
			,
			,
			,
			,
			,
			,
			,
			uint128 liquidity,
			uint256 feeGrowthInside0Last,
			uint256 feeGrowthInside1Last,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		) = nftManager.positions(tokenId);

		(, int24 tick, , , , , ) = pool.slot0();

		token0Fee =
			_calcularFeesGeneradas(true, feeGrowthInside0Last, tick, liquidity) +
			uint256(tokensOwed0);
		token1Fee =
			_calcularFeesGeneradas(false, feeGrowthInside1Last, tick, liquidity) +
			uint256(tokensOwed1);
	}

	/**
	 * @dev Calcula el balance total de token en la estrategia.
	 */
	function balanceEstrategia() public view returns (uint256) {
		return balanceDeToken() + balanceDePar() + balanceDesplegado();
	}

	/**
	 * @dev Devuelve el balance de token disponible en este contrato.
	 */
	function balanceDeToken() public view returns (uint256) {
		return IERC20(token).balanceOf(address(this)); // USDC
	}

	/**
	 * @dev Devuelve el balance del par disponible en este contrato.
	 */
	function balanceDePar() public view returns (uint256) {
		return IERC20(par).balanceOf(address(this)); // USDT
	}

	/**
	 * @dev Devuelve la liquidez de la posición de la estrategia.
	 */
	function liquidezTotal() public view returns (uint128 _liquidez) {
		(, , , , , , , _liquidez, , , , ) = nftManager.positions(tokenId);
	}

	/**
	 * @dev Calcula el balance desplegado en Uniswap.
	 */
	function balanceDesplegado() public view returns (uint256 balance) {
		if (tokenId == 0) return 0;

		(
			,
			,
			,
			,
			,
			,
			,
			uint128 liquidity,
			uint256 feeGrowthInside0Last,
			uint256 feeGrowthInside1Last,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		) = nftManager.positions(tokenId);

		(uint160 sqrtRatioX96, int24 tick, , , , , ) = pool.slot0();

		// Compute current holdings from liquidity
		(uint256 cantidad0, uint256 cantidad1) = LiquidityAmounts.getAmountsForLiquidity(
			sqrtRatioX96,
			ticks.tickInferior.getSqrtRatioAtTick(),
			ticks.tickSuperior.getSqrtRatioAtTick(),
			liquidity
		);

		// Compute current fees earned
		uint256 token0Fee = _calcularFeesGeneradas(true, feeGrowthInside0Last, tick, liquidity) +
			uint256(tokensOwed0);
		uint256 token1Fee = _calcularFeesGeneradas(false, feeGrowthInside1Last, tick, liquidity) +
			uint256(tokensOwed1);

		balance = cantidad0 + cantidad1 + token0Fee + token1Fee;
	}

	/**
	 * @dev Calcula las fees generadas en la posición.
	 */
	function _calcularFeesGeneradas(
		bool isZero,
		uint256 feeGrowthInsideLast,
		int24 tick,
		uint128 liquidity
	) internal view returns (uint256 fee) {
		uint256 feeGrowthGlobal;
		uint256 feeGrowthOutsideLower;
		uint256 feeGrowthOutsideUpper;

		if (isZero) {
			feeGrowthGlobal = pool.feeGrowthGlobal0X128();
			(, , feeGrowthOutsideLower, , , , , ) = pool.ticks(ticks.tickInferior);
			(, , feeGrowthOutsideUpper, , , , , ) = pool.ticks(ticks.tickSuperior);
		} else {
			feeGrowthGlobal = pool.feeGrowthGlobal1X128();
			(, , , feeGrowthOutsideLower, , , , ) = pool.ticks(ticks.tickInferior);
			(, , , feeGrowthOutsideUpper, , , , ) = pool.ticks(ticks.tickSuperior);
		}

		unchecked {
			// Calculate fee growth below
			uint256 feeGrowthBelow;
			if (tick >= ticks.tickInferior) {
				feeGrowthBelow = feeGrowthOutsideLower;
			} else {
				feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
			}

			// Calculate fee growth above
			uint256 feeGrowthAbove;
			if (tick < ticks.tickSuperior) {
				feeGrowthAbove = feeGrowthOutsideUpper;
			} else {
				feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
			}

			uint256 feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;
			fee = FullMath.mulDiv(
				liquidity,
				feeGrowthInside - feeGrowthInsideLast,
				0x100000000000000000000000000000000
			);
		}
	}

	/**
	 * @dev Retira la estrategia y envía los fondos de vuelta a la vault.
	 */
	function retirarEstrategia() external {
		require(msg.sender == vault, "no es la vault");

		_recogerFees();

		_removerLiquidez(liquidezTotal());

		_venderPar();

		IERC20(token).transfer(vault, balanceDeToken());
	}

	/**
	 * @dev Añade liquidez en la Pool USDC-USDT.
	 */
	function _darLiquidez() internal {
		(uint128 incrementoLiquidez, , ) = nftManager.increaseLiquidity(
			IUniNFT.IncreaseStruct({
				token_id: tokenId,
				amount0Desired: balanceDeToken(),
				amount1Desired: IERC20(par).balanceOf(address(this)),
				amount0Min: 0,
				amount1Min: 0,
				deadline: block.timestamp
			})
		);

		liquidez += incrementoLiquidez;
	}

	/**
	 * @dev Recoge las fees generadas.
	 */
	function _recogerFees() internal {
		nftManager.collect(
			IUniNFT.CollectStruct({
				token_id: tokenId,
				recipient: address(this),
				amount0Max: type(uint128).max,
				amount1Max: type(uint128).max
			})
		);
	}

	/**
	 * @dev Remueve una cantidad de lpTokens de la pool.
	 */
	function _removerLiquidez(uint128 _liquidez) internal {
		nftManager.decreaseLiquidity(
			IUniNFT.DecreaseStruct({
				token_id: tokenId,
				liquidity: _liquidez,
				amount0Min: 0,
				amount1Min: 0,
				deadline: block.timestamp
			})
		);
	}

	/**
	 * @dev Cambia el USDT por USDC.
	 */
	function _venderPar() internal {
		uint256 parBal = balanceDePar();
		if (parBal > 0) {
			router.exactInput(
				IUniV3Router.ExactInputParams({
					path: abi.encodePacked(par, poolFee, token),
					recipient: address(this),
					deadline: block.timestamp,
					amountIn: parBal,
					amountOutMinimum: 0
				})
			);
		}
	}

	/**
	 * @dev Cambia la mitad de USDC por USDT.
	 */
	function _cambiarMitad() internal {
		uint256 tokenBal = IERC20(token).balanceOf(address(this));
		if (tokenBal > 0) {
			router.exactInput(
				IUniV3Router.ExactInputParams({
					path: abi.encodePacked(token, poolFee, par),
					recipient: address(this),
					deadline: block.timestamp,
					amountIn: tokenBal / 2,
					amountOutMinimum: 0
				})
			);
		}
	}

	/**
	 * @dev Cambia una determinada cantidad de uno de los dos tokens por el otro.
	 */
	function venderToken(address tokenDeseado, uint256 cantidad) external onlyOwner {
		address token0 = tokenDeseado == token ? token : par;
		address token1 = token0 == token ? par : token;

		if (cantidad > 0) {
			router.exactInput(
				IUniV3Router.ExactInputParams({
					path: abi.encodePacked(token0, poolFee, token1),
					recipient: address(this),
					deadline: block.timestamp,
					amountIn: cantidad,
					amountOutMinimum: 0
				})
			);
		}
	}

	/**
	 * @dev Retira una determinada cantidad de la estrategia.
	 */
	function _retirarAlgo(uint256 cantidad) internal {
		uint256 _liquidez = (cantidad * liquidezTotal()) / balanceDesplegado();

		_removerLiquidez(uint128(_liquidez));

		_venderPar();
	}

	/**
	 * @dev Da permisos a contratos para transferir tokens.
	 */
	function _darPermisos() internal {
		IERC20(token).safeApprove(address(router), MAX);
		IERC20(par).safeApprove(address(router), MAX);

		IERC20(token).safeApprove(address(nftManager), MAX);
		IERC20(par).safeApprove(address(nftManager), MAX);
	}

	/**
	 * @dev Remueve permisos a contratos para transferir tokens.
	 */
	function removerPermisos() external onlyOwner {
		IERC20(token).safeApprove(address(router), 0);
		IERC20(par).safeApprove(address(router), 0);

		IERC20(token).safeApprove(address(nftManager), 0);
		IERC20(par).safeApprove(address(nftManager), 0);
	}

	/**
	 * @dev Establece la vault asociada a la estrategia.
	 */
	function setVault(address _vault) external onlyOwner {
		require(_vault != address(0), "Address no permitida");
		vault = _vault;
	}

	/**
	 * @dev Hook necesario para recibir ERC721 tokens
	 */
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) public pure virtual returns (bytes4) {
		return this.onERC721Received.selector;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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
pragma solidity 0.8.0;

interface IUniNFT {
	struct NftStruct {
		address token0;
		address token1;
		uint24 fee;
		int24 tickLower;
		int24 tickUpper;
		uint256 amount0Desired;
		uint256 amount1Desired;
		uint256 amount0Min;
		uint256 amount1Min;
		address recipient;
		uint256 deadline;
	}

	function mint(NftStruct calldata params)
		external
		payable
		returns (
			uint256 token_id,
			uint128 liquidity,
			uint256 amount0,
			uint256 amount1
		);

	function positions(uint256 tokenId)
		external
		view
		returns (
			uint96 nonce,
			address operator,
			address token0,
			address token1,
			uint24 fee,
			int24 tickLower,
			int24 tickUpper,
			uint128 liquidity,
			uint256 feeGrowthInside0LastX128,
			uint256 feeGrowthInside1LastX128,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		);

	struct DecreaseStruct {
		uint256 token_id;
		uint128 liquidity;
		uint256 amount0Min;
		uint256 amount1Min;
		uint256 deadline;
	}

	function balanceOf(address owner) external view returns (uint256 balance);

	function decreaseLiquidity(DecreaseStruct calldata params)
		external
		payable
		returns (uint256 amount0, uint256 amount1);

	struct CollectStruct {
		uint256 token_id;
		address recipient;
		uint128 amount0Max;
		uint128 amount1Max;
	}

	function collect(CollectStruct calldata params)
		external
		payable
		returns (uint256 amount0, uint256 amount1);

	struct IncreaseStruct {
		uint256 token_id;
		uint256 amount0Desired;
		uint256 amount1Desired;
		uint256 amount0Min;
		uint256 amount1Min;
		uint256 deadline;
	}

	function increaseLiquidity(IncreaseStruct calldata params)
		external
		payable
		returns (
			uint128 liquidity,
			uint256 amount0,
			uint256 amount1
		);

	function ownerOf(uint256 tokenID) external view returns (address);

	function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniV3Pool {
	/// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
	/// when accessed externally.
	/// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
	/// tick The current tick of the pool, i.e. according to the last tick transition that was run.
	/// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
	/// boundary.
	/// observationIndex The index of the last oracle observation that was written,
	/// observationCardinality The current maximum number of observations stored in the pool,
	/// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
	/// feeProtocol The protocol fee for both tokens of the pool.
	/// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
	/// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
	/// unlocked Whether the pool is currently locked to reentrancy
	function slot0()
		external
		view
		returns (
			uint160 sqrtPriceX96,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			uint16 observationCardinalityNext,
			uint8 feeProtocol,
			bool unlocked
		);

	/// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
	/// @dev This value can overflow the uint256
	function feeGrowthGlobal0X128() external view returns (uint256);

	/// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
	/// @dev This value can overflow the uint256
	function feeGrowthGlobal1X128() external view returns (uint256);

	/// @notice The amounts of token0 and token1 that are owed to the protocol
	/// @dev Protocol fees will never exceed uint128 max in either token
	function protocolFees() external view returns (uint128 token0, uint128 token1);

	/// @notice The currently in range liquidity available to the pool
	/// @dev This value has no relationship to the total liquidity across all ticks
	function liquidity() external view returns (uint128);

	/// @notice Look up information about a specific tick in the pool
	/// @param tick The tick to look up
	/// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
	/// tick upper,
	/// liquidityNet how much liquidity changes when the pool price crosses the tick,
	/// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
	/// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
	/// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
	/// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
	/// secondsOutside the seconds spent on the other side of the tick from the current tick,
	/// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
	/// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
	/// In addition, these values are only relative and must be used only in comparison to previous snapshots for
	/// a specific position.
	function ticks(int24 tick)
		external
		view
		returns (
			uint128 liquidityGross,
			int128 liquidityNet,
			uint256 feeGrowthOutside0X128,
			uint256 feeGrowthOutside1X128,
			int56 tickCumulativeOutside,
			uint160 secondsPerLiquidityOutsideX128,
			uint32 secondsOutside,
			bool initialized
		);

	/// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
	function tickBitmap(int16 wordPosition) external view returns (uint256);

	/// @notice Returns the information about a position by the position's key
	/// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
	/// @return _liquidity The amount of liquidity in the position,
	/// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
	/// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
	/// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
	/// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
	function positions(bytes32 key)
		external
		view
		returns (
			uint128 _liquidity,
			uint256 feeGrowthInside0LastX128,
			uint256 feeGrowthInside1LastX128,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		);

	/// @notice Returns data about a specific observation index
	/// @param index The element of the observations array to fetch
	/// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
	/// ago, rather than at a specific index in the array.
	/// @return blockTimestamp The timestamp of the observation,
	/// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
	/// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
	/// Returns initialized whether the observation has been initialized and the values are safe to use
	function observations(uint256 index)
		external
		view
		returns (
			uint32 blockTimestamp,
			int56 tickCumulative,
			uint160 secondsPerLiquidityCumulativeX128,
			bool initialized
		);

	/// @notice Sets the initial price for the pool
	/// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
	/// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
	function initialize(uint160 sqrtPriceX96) external;

	/// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
	/// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
	/// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
	/// on tickLower, tickUpper, the amount of liquidity, and the current price.
	/// @param recipient The address for which the liquidity will be created
	/// @param tickLower The lower tick of the position in which to add liquidity
	/// @param tickUpper The upper tick of the position in which to add liquidity
	/// @param amount The amount of liquidity to mint
	/// @param data Any data that should be passed through to the callback
	/// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
	/// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
	function mint(
		address recipient,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount,
		bytes calldata data
	) external returns (uint256 amount0, uint256 amount1);

	/// @notice Collects tokens owed to a position
	/// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
	/// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
	/// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
	/// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
	/// @param recipient The address which should receive the fees collected
	/// @param tickLower The lower tick of the position for which to collect fees
	/// @param tickUpper The upper tick of the position for which to collect fees
	/// @param amount0Requested How much token0 should be withdrawn from the fees owed
	/// @param amount1Requested How much token1 should be withdrawn from the fees owed
	/// @return amount0 The amount of fees collected in token0
	/// @return amount1 The amount of fees collected in token1
	function collect(
		address recipient,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount0Requested,
		uint128 amount1Requested
	) external returns (uint128 amount0, uint128 amount1);

	/// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
	/// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
	/// @dev Fees must be collected separately via a call to #collect
	/// @param tickLower The lower tick of the position for which to burn liquidity
	/// @param tickUpper The upper tick of the position for which to burn liquidity
	/// @param amount How much liquidity to burn
	/// @return amount0 The amount of token0 sent to the recipient
	/// @return amount1 The amount of token1 sent to the recipient
	function burn(
		int24 tickLower,
		int24 tickUpper,
		uint128 amount
	) external returns (uint256 amount0, uint256 amount1);

	/// @notice Swap token0 for token1, or token1 for token0
	/// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
	/// @param recipient The address to receive the output of the swap
	/// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
	/// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
	/// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
	/// value after the swap. If one for zero, the price cannot be greater than this value after the swap
	/// @param data Any data to be passed through to the callback
	/// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
	/// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
	function swap(
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) external returns (int256 amount0, int256 amount1);

	/// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
	/// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
	/// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
	/// with 0 amount{0,1} and sending the donation amount(s) from the callback
	/// @param recipient The address which will receive the token0 and token1 amounts
	/// @param amount0 The amount of token0 to send
	/// @param amount1 The amount of token1 to send
	/// @param data Any data to be passed through to the callback
	function flash(
		address recipient,
		uint256 amount0,
		uint256 amount1,
		bytes calldata data
	) external;

	/// @notice Increase the maximum number of price and liquidity observations that this pool will store
	/// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
	/// the input observationCardinalityNext.
	/// @param observationCardinalityNext The desired minimum number of observations for the pool to store
	function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

	/// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
	/// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
	/// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
	/// you must call it with secondsAgos = [3600, 0].
	/// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
	/// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
	/// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
	/// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
	/// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
	/// timestamp
	function observe(uint32[] calldata secondsAgos)
		external
		view
		returns (
			int56[] memory tickCumulatives,
			uint160[] memory secondsPerLiquidityCumulativeX128s
		);

	/// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
	/// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
	/// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
	/// snapshot is taken and the second snapshot is taken.
	/// @param tickLower The lower tick of the range
	/// @param tickUpper The upper tick of the range
	/// @return tickCumulativeInside The snapshot of the tick accumulator for the range
	/// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
	/// @return secondsInside The snapshot of seconds per liquidity for the range
	function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
		external
		view
		returns (
			int56 tickCumulativeInside,
			uint160 secondsPerLiquidityInsideX128,
			uint32 secondsInside
		);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniV3Router {
	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 deadline;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	function exactInput(ExactInputParams calldata params)
		external
		payable
		returns (uint256 amountOut);
}