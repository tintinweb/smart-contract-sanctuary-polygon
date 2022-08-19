/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        /// @solidity memory-safe-assembly
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
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(
        token,
        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
      );
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  enum Rounding {
    Down, // Toward negative infinity
    Up, // Toward infinity
    Zero // Toward zero
  }

  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a == 0 ? 0 : (a - 1) / b + 1;
  }

  /**
   * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
   * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
   * with further edits by Uniswap Labs also under MIT license.
   */
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
      // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2^256 + prod0.
      uint256 prod0; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division.
      if (prod1 == 0) {
        return prod0 / denominator;
      }

      // Make sure the result is less than 2^256. Also prevents denominator == 0.
      require(denominator > prod1);

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0].
      uint256 remainder;
      assembly {
        // Compute remainder using mulmod.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
      // See https://cs.stackexchange.com/q/138556/92363.

      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 twos = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by twos.
        denominator := div(denominator, twos)

        // Divide [prod1 prod0] by twos.
        prod0 := div(prod0, twos)

        // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
        twos := add(div(sub(0, twos), twos), 1)
      }

      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * twos;

      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;

      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256

      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }

  /**
   * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
   */
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator,
    Rounding rounding
  ) internal pure returns (uint256) {
    uint256 result = mulDiv(x, y, denominator);
    if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
      result += 1;
    }
    return result;
  }

  /**
   * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
   *
   * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
   */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`.
    // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
    // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
    // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
    // good first aproximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1;
    uint256 x = a;
    if (x >> 128 > 0) {
      x >>= 128;
      result <<= 64;
    }
    if (x >> 64 > 0) {
      x >>= 64;
      result <<= 32;
    }
    if (x >> 32 > 0) {
      x >>= 32;
      result <<= 16;
    }
    if (x >> 16 > 0) {
      x >>= 16;
      result <<= 8;
    }
    if (x >> 8 > 0) {
      x >>= 8;
      result <<= 4;
    }
    if (x >> 4 > 0) {
      x >>= 4;
      result <<= 2;
    }
    if (x >> 2 > 0) {
      result <<= 1;
    }

    // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
    // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
    // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
    // into the expected uint128 result.
    unchecked {
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      return min(result, a / result);
    }
  }

  /**
   * @notice Calculates sqrt(a), following the selected rounding direction.
   */
  function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
    uint256 result = sqrt(a);
    if (rounding == Rounding.Up && result * result < a) {
      result += 1;
    }
    return result;
  }
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
   * @dev Returns the downcasted uint248 from uint256, reverting on
   * overflow (when the input is greater than largest uint248).
   *
   * Counterpart to Solidity's `uint248` operator.
   *
   * Requirements:
   *
   * - input must fit into 248 bits
   *
   * _Available since v4.7._
   */
  function toUint248(uint256 value) internal pure returns (uint248) {
    require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
    return uint248(value);
  }

  /**
   * @dev Returns the downcasted uint240 from uint256, reverting on
   * overflow (when the input is greater than largest uint240).
   *
   * Counterpart to Solidity's `uint240` operator.
   *
   * Requirements:
   *
   * - input must fit into 240 bits
   *
   * _Available since v4.7._
   */
  function toUint240(uint256 value) internal pure returns (uint240) {
    require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
    return uint240(value);
  }

  /**
   * @dev Returns the downcasted uint232 from uint256, reverting on
   * overflow (when the input is greater than largest uint232).
   *
   * Counterpart to Solidity's `uint232` operator.
   *
   * Requirements:
   *
   * - input must fit into 232 bits
   *
   * _Available since v4.7._
   */
  function toUint232(uint256 value) internal pure returns (uint232) {
    require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
    return uint232(value);
  }

  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   *
   * _Available since v4.2._
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint216 from uint256, reverting on
   * overflow (when the input is greater than largest uint216).
   *
   * Counterpart to Solidity's `uint216` operator.
   *
   * Requirements:
   *
   * - input must fit into 216 bits
   *
   * _Available since v4.7._
   */
  function toUint216(uint256 value) internal pure returns (uint216) {
    require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
    return uint216(value);
  }

  /**
   * @dev Returns the downcasted uint208 from uint256, reverting on
   * overflow (when the input is greater than largest uint208).
   *
   * Counterpart to Solidity's `uint208` operator.
   *
   * Requirements:
   *
   * - input must fit into 208 bits
   *
   * _Available since v4.7._
   */
  function toUint208(uint256 value) internal pure returns (uint208) {
    require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
    return uint208(value);
  }

  /**
   * @dev Returns the downcasted uint200 from uint256, reverting on
   * overflow (when the input is greater than largest uint200).
   *
   * Counterpart to Solidity's `uint200` operator.
   *
   * Requirements:
   *
   * - input must fit into 200 bits
   *
   * _Available since v4.7._
   */
  function toUint200(uint256 value) internal pure returns (uint200) {
    require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
    return uint200(value);
  }

  /**
   * @dev Returns the downcasted uint192 from uint256, reverting on
   * overflow (when the input is greater than largest uint192).
   *
   * Counterpart to Solidity's `uint192` operator.
   *
   * Requirements:
   *
   * - input must fit into 192 bits
   *
   * _Available since v4.7._
   */
  function toUint192(uint256 value) internal pure returns (uint192) {
    require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
    return uint192(value);
  }

  /**
   * @dev Returns the downcasted uint184 from uint256, reverting on
   * overflow (when the input is greater than largest uint184).
   *
   * Counterpart to Solidity's `uint184` operator.
   *
   * Requirements:
   *
   * - input must fit into 184 bits
   *
   * _Available since v4.7._
   */
  function toUint184(uint256 value) internal pure returns (uint184) {
    require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
    return uint184(value);
  }

  /**
   * @dev Returns the downcasted uint176 from uint256, reverting on
   * overflow (when the input is greater than largest uint176).
   *
   * Counterpart to Solidity's `uint176` operator.
   *
   * Requirements:
   *
   * - input must fit into 176 bits
   *
   * _Available since v4.7._
   */
  function toUint176(uint256 value) internal pure returns (uint176) {
    require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
    return uint176(value);
  }

  /**
   * @dev Returns the downcasted uint168 from uint256, reverting on
   * overflow (when the input is greater than largest uint168).
   *
   * Counterpart to Solidity's `uint168` operator.
   *
   * Requirements:
   *
   * - input must fit into 168 bits
   *
   * _Available since v4.7._
   */
  function toUint168(uint256 value) internal pure returns (uint168) {
    require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
    return uint168(value);
  }

  /**
   * @dev Returns the downcasted uint160 from uint256, reverting on
   * overflow (when the input is greater than largest uint160).
   *
   * Counterpart to Solidity's `uint160` operator.
   *
   * Requirements:
   *
   * - input must fit into 160 bits
   *
   * _Available since v4.7._
   */
  function toUint160(uint256 value) internal pure returns (uint160) {
    require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
    return uint160(value);
  }

  /**
   * @dev Returns the downcasted uint152 from uint256, reverting on
   * overflow (when the input is greater than largest uint152).
   *
   * Counterpart to Solidity's `uint152` operator.
   *
   * Requirements:
   *
   * - input must fit into 152 bits
   *
   * _Available since v4.7._
   */
  function toUint152(uint256 value) internal pure returns (uint152) {
    require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
    return uint152(value);
  }

  /**
   * @dev Returns the downcasted uint144 from uint256, reverting on
   * overflow (when the input is greater than largest uint144).
   *
   * Counterpart to Solidity's `uint144` operator.
   *
   * Requirements:
   *
   * - input must fit into 144 bits
   *
   * _Available since v4.7._
   */
  function toUint144(uint256 value) internal pure returns (uint144) {
    require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
    return uint144(value);
  }

  /**
   * @dev Returns the downcasted uint136 from uint256, reverting on
   * overflow (when the input is greater than largest uint136).
   *
   * Counterpart to Solidity's `uint136` operator.
   *
   * Requirements:
   *
   * - input must fit into 136 bits
   *
   * _Available since v4.7._
   */
  function toUint136(uint256 value) internal pure returns (uint136) {
    require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
    return uint136(value);
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
   *
   * _Available since v2.5._
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint120 from uint256, reverting on
   * overflow (when the input is greater than largest uint120).
   *
   * Counterpart to Solidity's `uint120` operator.
   *
   * Requirements:
   *
   * - input must fit into 120 bits
   *
   * _Available since v4.7._
   */
  function toUint120(uint256 value) internal pure returns (uint120) {
    require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
    return uint120(value);
  }

  /**
   * @dev Returns the downcasted uint112 from uint256, reverting on
   * overflow (when the input is greater than largest uint112).
   *
   * Counterpart to Solidity's `uint112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   *
   * _Available since v4.7._
   */
  function toUint112(uint256 value) internal pure returns (uint112) {
    require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
    return uint112(value);
  }

  /**
   * @dev Returns the downcasted uint104 from uint256, reverting on
   * overflow (when the input is greater than largest uint104).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 104 bits
   *
   * _Available since v4.7._
   */
  function toUint104(uint256 value) internal pure returns (uint104) {
    require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
    return uint104(value);
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
   *
   * _Available since v4.2._
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint88 from uint256, reverting on
   * overflow (when the input is greater than largest uint88).
   *
   * Counterpart to Solidity's `uint88` operator.
   *
   * Requirements:
   *
   * - input must fit into 88 bits
   *
   * _Available since v4.7._
   */
  function toUint88(uint256 value) internal pure returns (uint88) {
    require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
    return uint88(value);
  }

  /**
   * @dev Returns the downcasted uint80 from uint256, reverting on
   * overflow (when the input is greater than largest uint80).
   *
   * Counterpart to Solidity's `uint80` operator.
   *
   * Requirements:
   *
   * - input must fit into 80 bits
   *
   * _Available since v4.7._
   */
  function toUint80(uint256 value) internal pure returns (uint80) {
    require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
    return uint80(value);
  }

  /**
   * @dev Returns the downcasted uint72 from uint256, reverting on
   * overflow (when the input is greater than largest uint72).
   *
   * Counterpart to Solidity's `uint72` operator.
   *
   * Requirements:
   *
   * - input must fit into 72 bits
   *
   * _Available since v4.7._
   */
  function toUint72(uint256 value) internal pure returns (uint72) {
    require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
    return uint72(value);
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
   *
   * _Available since v2.5._
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint56 from uint256, reverting on
   * overflow (when the input is greater than largest uint56).
   *
   * Counterpart to Solidity's `uint56` operator.
   *
   * Requirements:
   *
   * - input must fit into 56 bits
   *
   * _Available since v4.7._
   */
  function toUint56(uint256 value) internal pure returns (uint56) {
    require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
    return uint56(value);
  }

  /**
   * @dev Returns the downcasted uint48 from uint256, reverting on
   * overflow (when the input is greater than largest uint48).
   *
   * Counterpart to Solidity's `uint48` operator.
   *
   * Requirements:
   *
   * - input must fit into 48 bits
   *
   * _Available since v4.7._
   */
  function toUint48(uint256 value) internal pure returns (uint48) {
    require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
    return uint48(value);
  }

  /**
   * @dev Returns the downcasted uint40 from uint256, reverting on
   * overflow (when the input is greater than largest uint40).
   *
   * Counterpart to Solidity's `uint40` operator.
   *
   * Requirements:
   *
   * - input must fit into 40 bits
   *
   * _Available since v4.7._
   */
  function toUint40(uint256 value) internal pure returns (uint40) {
    require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
    return uint40(value);
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
   *
   * _Available since v2.5._
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint24 from uint256, reverting on
   * overflow (when the input is greater than largest uint24).
   *
   * Counterpart to Solidity's `uint24` operator.
   *
   * Requirements:
   *
   * - input must fit into 24 bits
   *
   * _Available since v4.7._
   */
  function toUint24(uint256 value) internal pure returns (uint24) {
    require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
    return uint24(value);
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
   *
   * _Available since v2.5._
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
   * - input must fit into 8 bits
   *
   * _Available since v2.5._
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
   *
   * _Available since v3.0._
   */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

  /**
   * @dev Returns the downcasted int248 from int256, reverting on
   * overflow (when the input is less than smallest int248 or
   * greater than largest int248).
   *
   * Counterpart to Solidity's `int248` operator.
   *
   * Requirements:
   *
   * - input must fit into 248 bits
   *
   * _Available since v4.7._
   */
  function toInt248(int256 value) internal pure returns (int248) {
    require(
      value >= type(int248).min && value <= type(int248).max,
      "SafeCast: value doesn't fit in 248 bits"
    );
    return int248(value);
  }

  /**
   * @dev Returns the downcasted int240 from int256, reverting on
   * overflow (when the input is less than smallest int240 or
   * greater than largest int240).
   *
   * Counterpart to Solidity's `int240` operator.
   *
   * Requirements:
   *
   * - input must fit into 240 bits
   *
   * _Available since v4.7._
   */
  function toInt240(int256 value) internal pure returns (int240) {
    require(
      value >= type(int240).min && value <= type(int240).max,
      "SafeCast: value doesn't fit in 240 bits"
    );
    return int240(value);
  }

  /**
   * @dev Returns the downcasted int232 from int256, reverting on
   * overflow (when the input is less than smallest int232 or
   * greater than largest int232).
   *
   * Counterpart to Solidity's `int232` operator.
   *
   * Requirements:
   *
   * - input must fit into 232 bits
   *
   * _Available since v4.7._
   */
  function toInt232(int256 value) internal pure returns (int232) {
    require(
      value >= type(int232).min && value <= type(int232).max,
      "SafeCast: value doesn't fit in 232 bits"
    );
    return int232(value);
  }

  /**
   * @dev Returns the downcasted int224 from int256, reverting on
   * overflow (when the input is less than smallest int224 or
   * greater than largest int224).
   *
   * Counterpart to Solidity's `int224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   *
   * _Available since v4.7._
   */
  function toInt224(int256 value) internal pure returns (int224) {
    require(
      value >= type(int224).min && value <= type(int224).max,
      "SafeCast: value doesn't fit in 224 bits"
    );
    return int224(value);
  }

  /**
   * @dev Returns the downcasted int216 from int256, reverting on
   * overflow (when the input is less than smallest int216 or
   * greater than largest int216).
   *
   * Counterpart to Solidity's `int216` operator.
   *
   * Requirements:
   *
   * - input must fit into 216 bits
   *
   * _Available since v4.7._
   */
  function toInt216(int256 value) internal pure returns (int216) {
    require(
      value >= type(int216).min && value <= type(int216).max,
      "SafeCast: value doesn't fit in 216 bits"
    );
    return int216(value);
  }

  /**
   * @dev Returns the downcasted int208 from int256, reverting on
   * overflow (when the input is less than smallest int208 or
   * greater than largest int208).
   *
   * Counterpart to Solidity's `int208` operator.
   *
   * Requirements:
   *
   * - input must fit into 208 bits
   *
   * _Available since v4.7._
   */
  function toInt208(int256 value) internal pure returns (int208) {
    require(
      value >= type(int208).min && value <= type(int208).max,
      "SafeCast: value doesn't fit in 208 bits"
    );
    return int208(value);
  }

  /**
   * @dev Returns the downcasted int200 from int256, reverting on
   * overflow (when the input is less than smallest int200 or
   * greater than largest int200).
   *
   * Counterpart to Solidity's `int200` operator.
   *
   * Requirements:
   *
   * - input must fit into 200 bits
   *
   * _Available since v4.7._
   */
  function toInt200(int256 value) internal pure returns (int200) {
    require(
      value >= type(int200).min && value <= type(int200).max,
      "SafeCast: value doesn't fit in 200 bits"
    );
    return int200(value);
  }

  /**
   * @dev Returns the downcasted int192 from int256, reverting on
   * overflow (when the input is less than smallest int192 or
   * greater than largest int192).
   *
   * Counterpart to Solidity's `int192` operator.
   *
   * Requirements:
   *
   * - input must fit into 192 bits
   *
   * _Available since v4.7._
   */
  function toInt192(int256 value) internal pure returns (int192) {
    require(
      value >= type(int192).min && value <= type(int192).max,
      "SafeCast: value doesn't fit in 192 bits"
    );
    return int192(value);
  }

  /**
   * @dev Returns the downcasted int184 from int256, reverting on
   * overflow (when the input is less than smallest int184 or
   * greater than largest int184).
   *
   * Counterpart to Solidity's `int184` operator.
   *
   * Requirements:
   *
   * - input must fit into 184 bits
   *
   * _Available since v4.7._
   */
  function toInt184(int256 value) internal pure returns (int184) {
    require(
      value >= type(int184).min && value <= type(int184).max,
      "SafeCast: value doesn't fit in 184 bits"
    );
    return int184(value);
  }

  /**
   * @dev Returns the downcasted int176 from int256, reverting on
   * overflow (when the input is less than smallest int176 or
   * greater than largest int176).
   *
   * Counterpart to Solidity's `int176` operator.
   *
   * Requirements:
   *
   * - input must fit into 176 bits
   *
   * _Available since v4.7._
   */
  function toInt176(int256 value) internal pure returns (int176) {
    require(
      value >= type(int176).min && value <= type(int176).max,
      "SafeCast: value doesn't fit in 176 bits"
    );
    return int176(value);
  }

  /**
   * @dev Returns the downcasted int168 from int256, reverting on
   * overflow (when the input is less than smallest int168 or
   * greater than largest int168).
   *
   * Counterpart to Solidity's `int168` operator.
   *
   * Requirements:
   *
   * - input must fit into 168 bits
   *
   * _Available since v4.7._
   */
  function toInt168(int256 value) internal pure returns (int168) {
    require(
      value >= type(int168).min && value <= type(int168).max,
      "SafeCast: value doesn't fit in 168 bits"
    );
    return int168(value);
  }

  /**
   * @dev Returns the downcasted int160 from int256, reverting on
   * overflow (when the input is less than smallest int160 or
   * greater than largest int160).
   *
   * Counterpart to Solidity's `int160` operator.
   *
   * Requirements:
   *
   * - input must fit into 160 bits
   *
   * _Available since v4.7._
   */
  function toInt160(int256 value) internal pure returns (int160) {
    require(
      value >= type(int160).min && value <= type(int160).max,
      "SafeCast: value doesn't fit in 160 bits"
    );
    return int160(value);
  }

  /**
   * @dev Returns the downcasted int152 from int256, reverting on
   * overflow (when the input is less than smallest int152 or
   * greater than largest int152).
   *
   * Counterpart to Solidity's `int152` operator.
   *
   * Requirements:
   *
   * - input must fit into 152 bits
   *
   * _Available since v4.7._
   */
  function toInt152(int256 value) internal pure returns (int152) {
    require(
      value >= type(int152).min && value <= type(int152).max,
      "SafeCast: value doesn't fit in 152 bits"
    );
    return int152(value);
  }

  /**
   * @dev Returns the downcasted int144 from int256, reverting on
   * overflow (when the input is less than smallest int144 or
   * greater than largest int144).
   *
   * Counterpart to Solidity's `int144` operator.
   *
   * Requirements:
   *
   * - input must fit into 144 bits
   *
   * _Available since v4.7._
   */
  function toInt144(int256 value) internal pure returns (int144) {
    require(
      value >= type(int144).min && value <= type(int144).max,
      "SafeCast: value doesn't fit in 144 bits"
    );
    return int144(value);
  }

  /**
   * @dev Returns the downcasted int136 from int256, reverting on
   * overflow (when the input is less than smallest int136 or
   * greater than largest int136).
   *
   * Counterpart to Solidity's `int136` operator.
   *
   * Requirements:
   *
   * - input must fit into 136 bits
   *
   * _Available since v4.7._
   */
  function toInt136(int256 value) internal pure returns (int136) {
    require(
      value >= type(int136).min && value <= type(int136).max,
      "SafeCast: value doesn't fit in 136 bits"
    );
    return int136(value);
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
    require(
      value >= type(int128).min && value <= type(int128).max,
      "SafeCast: value doesn't fit in 128 bits"
    );
    return int128(value);
  }

  /**
   * @dev Returns the downcasted int120 from int256, reverting on
   * overflow (when the input is less than smallest int120 or
   * greater than largest int120).
   *
   * Counterpart to Solidity's `int120` operator.
   *
   * Requirements:
   *
   * - input must fit into 120 bits
   *
   * _Available since v4.7._
   */
  function toInt120(int256 value) internal pure returns (int120) {
    require(
      value >= type(int120).min && value <= type(int120).max,
      "SafeCast: value doesn't fit in 120 bits"
    );
    return int120(value);
  }

  /**
   * @dev Returns the downcasted int112 from int256, reverting on
   * overflow (when the input is less than smallest int112 or
   * greater than largest int112).
   *
   * Counterpart to Solidity's `int112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   *
   * _Available since v4.7._
   */
  function toInt112(int256 value) internal pure returns (int112) {
    require(
      value >= type(int112).min && value <= type(int112).max,
      "SafeCast: value doesn't fit in 112 bits"
    );
    return int112(value);
  }

  /**
   * @dev Returns the downcasted int104 from int256, reverting on
   * overflow (when the input is less than smallest int104 or
   * greater than largest int104).
   *
   * Counterpart to Solidity's `int104` operator.
   *
   * Requirements:
   *
   * - input must fit into 104 bits
   *
   * _Available since v4.7._
   */
  function toInt104(int256 value) internal pure returns (int104) {
    require(
      value >= type(int104).min && value <= type(int104).max,
      "SafeCast: value doesn't fit in 104 bits"
    );
    return int104(value);
  }

  /**
   * @dev Returns the downcasted int96 from int256, reverting on
   * overflow (when the input is less than smallest int96 or
   * greater than largest int96).
   *
   * Counterpart to Solidity's `int96` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   *
   * _Available since v4.7._
   */
  function toInt96(int256 value) internal pure returns (int96) {
    require(
      value >= type(int96).min && value <= type(int96).max,
      "SafeCast: value doesn't fit in 96 bits"
    );
    return int96(value);
  }

  /**
   * @dev Returns the downcasted int88 from int256, reverting on
   * overflow (when the input is less than smallest int88 or
   * greater than largest int88).
   *
   * Counterpart to Solidity's `int88` operator.
   *
   * Requirements:
   *
   * - input must fit into 88 bits
   *
   * _Available since v4.7._
   */
  function toInt88(int256 value) internal pure returns (int88) {
    require(
      value >= type(int88).min && value <= type(int88).max,
      "SafeCast: value doesn't fit in 88 bits"
    );
    return int88(value);
  }

  /**
   * @dev Returns the downcasted int80 from int256, reverting on
   * overflow (when the input is less than smallest int80 or
   * greater than largest int80).
   *
   * Counterpart to Solidity's `int80` operator.
   *
   * Requirements:
   *
   * - input must fit into 80 bits
   *
   * _Available since v4.7._
   */
  function toInt80(int256 value) internal pure returns (int80) {
    require(
      value >= type(int80).min && value <= type(int80).max,
      "SafeCast: value doesn't fit in 80 bits"
    );
    return int80(value);
  }

  /**
   * @dev Returns the downcasted int72 from int256, reverting on
   * overflow (when the input is less than smallest int72 or
   * greater than largest int72).
   *
   * Counterpart to Solidity's `int72` operator.
   *
   * Requirements:
   *
   * - input must fit into 72 bits
   *
   * _Available since v4.7._
   */
  function toInt72(int256 value) internal pure returns (int72) {
    require(
      value >= type(int72).min && value <= type(int72).max,
      "SafeCast: value doesn't fit in 72 bits"
    );
    return int72(value);
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
    require(
      value >= type(int64).min && value <= type(int64).max,
      "SafeCast: value doesn't fit in 64 bits"
    );
    return int64(value);
  }

  /**
   * @dev Returns the downcasted int56 from int256, reverting on
   * overflow (when the input is less than smallest int56 or
   * greater than largest int56).
   *
   * Counterpart to Solidity's `int56` operator.
   *
   * Requirements:
   *
   * - input must fit into 56 bits
   *
   * _Available since v4.7._
   */
  function toInt56(int256 value) internal pure returns (int56) {
    require(
      value >= type(int56).min && value <= type(int56).max,
      "SafeCast: value doesn't fit in 56 bits"
    );
    return int56(value);
  }

  /**
   * @dev Returns the downcasted int48 from int256, reverting on
   * overflow (when the input is less than smallest int48 or
   * greater than largest int48).
   *
   * Counterpart to Solidity's `int48` operator.
   *
   * Requirements:
   *
   * - input must fit into 48 bits
   *
   * _Available since v4.7._
   */
  function toInt48(int256 value) internal pure returns (int48) {
    require(
      value >= type(int48).min && value <= type(int48).max,
      "SafeCast: value doesn't fit in 48 bits"
    );
    return int48(value);
  }

  /**
   * @dev Returns the downcasted int40 from int256, reverting on
   * overflow (when the input is less than smallest int40 or
   * greater than largest int40).
   *
   * Counterpart to Solidity's `int40` operator.
   *
   * Requirements:
   *
   * - input must fit into 40 bits
   *
   * _Available since v4.7._
   */
  function toInt40(int256 value) internal pure returns (int40) {
    require(
      value >= type(int40).min && value <= type(int40).max,
      "SafeCast: value doesn't fit in 40 bits"
    );
    return int40(value);
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
    require(
      value >= type(int32).min && value <= type(int32).max,
      "SafeCast: value doesn't fit in 32 bits"
    );
    return int32(value);
  }

  /**
   * @dev Returns the downcasted int24 from int256, reverting on
   * overflow (when the input is less than smallest int24 or
   * greater than largest int24).
   *
   * Counterpart to Solidity's `int24` operator.
   *
   * Requirements:
   *
   * - input must fit into 24 bits
   *
   * _Available since v4.7._
   */
  function toInt24(int256 value) internal pure returns (int24) {
    require(
      value >= type(int24).min && value <= type(int24).max,
      "SafeCast: value doesn't fit in 24 bits"
    );
    return int24(value);
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
    require(
      value >= type(int16).min && value <= type(int16).max,
      "SafeCast: value doesn't fit in 16 bits"
    );
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
   * - input must fit into 8 bits
   *
   * _Available since v3.1._
   */
  function toInt8(int256 value) internal pure returns (int8) {
    require(
      value >= type(int8).min && value <= type(int8).max,
      "SafeCast: value doesn't fit in 8 bits"
    );
    return int8(value);
  }

  /**
   * @dev Converts an unsigned uint256 into a signed int256.
   *
   * Requirements:
   *
   * - input must be less than or equal to maxInt256.
   *
   * _Available since v3.0._
   */
  function toInt256(uint256 value) internal pure returns (int256) {
    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
    return int256(value);
  }
}

interface ITokenFactory {
  function createSyntheticToken(
    string calldata syntheticName,
    string calldata syntheticSymbol,
    address staker,
    uint32 marketIndex,
    bool isLong
  ) external returns (address);
}

/**
@title SyntheticToken
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
*/
interface ISyntheticToken {
  // function MINTER_ROLE() external returns (bytes32);

  function mint(address, uint256) external;

  function totalSupply() external returns (uint256);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function burn(uint256 amount) external;
}

/**
@title SyntheticToken
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
*/
interface ISyntheticTokenOriginal is ISyntheticToken {
  function stake(uint256) external;
}

interface IStaker {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event Upgrade(uint256 version);

  event StakerV1(
    address admin,
    address floatTreasury,
    address floatCapital,
    address floatToken,
    uint256 floatPercentage
  );

  event MarketAddedToStaker(
    uint32 marketIndex,
    uint256 exitFee_e18,
    uint256 period,
    uint256 multiplier,
    uint256 balanceIncentiveExponent,
    int256 balanceIncentiveEquilibriumOffset,
    uint256 safeExponentBitShifting
  );

  event AccumulativeIssuancePerStakedSynthSnapshotCreated(
    uint32 marketIndex,
    uint256 accumulativeFloatIssuanceSnapshotIndex,
    uint256 accumulativeLong,
    uint256 accumulativeShort
  );

  event StakeAdded(address user, address token, uint256 amount, uint256 lastMintIndex);

  event StakeWithdrawn(address user, address token, uint256 amount);

  event StakeWithdrawnWithFees(address user, address token, uint256 amount, uint256 amountFees);

  // Note: the `amountFloatMinted` isn't strictly needed by the graph, but it is good to add it to validate calculations are accurate.
  event FloatMinted(address user, uint32 marketIndex, uint256 amountFloatMinted);

  event MarketLaunchIncentiveParametersChanges(
    uint32 marketIndex,
    uint256 period,
    uint256 multiplier
  );

  event StakeWithdrawalFeeUpdated(uint32 marketIndex, uint256 stakeWithdralFee);

  event BalanceIncentiveParamsUpdated(
    uint32 marketIndex,
    uint256 balanceIncentiveExponent,
    int256 balanceIncentiveCurve_equilibriumOffset,
    uint256 safeExponentBitShifting
  );

  event FloatPercentageUpdated(uint256 floatPercentage);

  event NextPriceStakeShift(
    address user,
    uint32 marketIndex,
    uint256 amount,
    bool isShiftFromLong,
    uint256 userShiftIndex
  );

  function userAmountStaked(address, address) external view returns (uint256);

  function addNewStakingFund(
    uint32 marketIndex,
    address longTokenAddress,
    address shortTokenAddress,
    uint256 kInitialMultiplier,
    uint256 kPeriod,
    uint256 unstakeFee_e18,
    uint256 _balanceIncentiveCurve_exponent,
    int256 _balanceIncentiveCurve_equilibriumOffset
  ) external;

  function pushUpdatedMarketPricesToUpdateFloatIssuanceCalculations(
    uint32 marketIndex,
    uint256 marketUpdateIndex,
    uint256 longTokenPrice,
    uint256 shortTokenPrice,
    uint256 longValue,
    uint256 shortValue
  ) external;

  function stakeFromUser(address from, uint256 amount) external;

  function shiftTokens(
    uint256 amountSyntheticTokensToShift,
    uint32 marketIndex,
    bool isShiftFromLong
  ) external;

  function latestRewardIndex(uint32 marketIndex) external view returns (uint256);

  // TODO: couldn't get this to work!
  function safe_getUpdateTimestamp(uint32 marketIndex, uint256 latestUpdateIndex)
    external
    view
    returns (uint256);

  function mintAndStakeNextPrice(
    uint32 marketIndex,
    uint256 amount,
    bool isLong,
    address user
  ) external;

  /* ══════ Next price action management specific ══════ */

  function userNextPrice_stakedActionIndex(uint32 marketIndex, address userAddress)
    external
    view
    returns (uint256 stakedActionIndex);

  function userNextPrice_amountStakedSyntheticToken_toShiftAwayFrom(
    uint32 marketIndex,
    bool isLong,
    address userAddress
  ) external view returns (uint256 amountUserRequestedToShiftAwayFromLongOnNextUpdate);

  function userNextPrice_paymentToken_depositAmount(
    uint32 marketIndex,
    bool isLong,
    address userAddress
  ) external view returns (uint256 depositAmount);
}

interface ILongShortOriginal {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event Upgrade(uint256 version);
  event LongShortV1(address admin, address tokenFactory, address staker);

  event SystemStateUpdated(
    uint32 marketIndex,
    uint256 updateIndex,
    int256 underlyingAssetPrice,
    uint256 longValue,
    uint256 shortValue,
    uint256 longPrice,
    uint256 shortPrice
  );

  event SyntheticMarketCreated(
    uint32 marketIndex,
    address longTokenAddress,
    address shortTokenAddress,
    address paymentToken,
    int256 initialAssetPrice,
    string name,
    string symbol,
    address oracleAddress,
    address yieldManagerAddress
  );

  event NextPriceRedeem(
    uint32 marketIndex,
    bool isLong,
    uint256 synthRedeemed,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceSyntheticPositionShift(
    uint32 marketIndex,
    bool isShiftFromLong,
    uint256 synthShifted,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceDeposit(
    uint32 marketIndex,
    bool isLong,
    uint256 depositAdded,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceDepositAndStake(
    uint32 marketIndex,
    bool isLong,
    uint256 amountToStake,
    address user,
    uint256 oracleUpdateIndex
  );

  event OracleUpdated(uint32 marketIndex, address oldOracleAddress, address newOracleAddress);

  event NewMarketLaunchedAndSeeded(uint32 marketIndex, uint256 initialSeed, uint256 marketLeverage);

  event ExecuteNextPriceSettlementsUser(address user, uint32 marketIndex);

  event MarketFundingRateMultiplerChanged(uint32 marketIndex, uint256 fundingRateMultiplier_e18);

  event SeparateMarketCreated(string name, string symbol, address market, uint32 marketIndex);

  function syntheticTokens(uint32, bool) external view returns (address);

  function assetPrice(uint32) external view returns (int256);

  function oracleManagers(uint32) external view returns (address);

  function latestMarket() external view returns (uint32);

  function marketUpdateIndex(uint32) external view returns (uint256);

  function batched_amountPaymentToken_deposit(uint32, bool) external view returns (uint256);

  function batched_amountSyntheticToken_redeem(uint32, bool) external view returns (uint256);

  function batched_amountSyntheticToken_toShiftAwayFrom_marketSide(uint32, bool)
    external
    view
    returns (uint256);

  function get_syntheticToken_priceSnapshot(uint32, uint256)
    external
    view
    returns (uint256, uint256);

  function get_syntheticToken_priceSnapshot_side(
    uint32,
    bool,
    uint256
  ) external view returns (uint256);

  function marketSideValueInPaymentToken(uint32 marketIndex)
    external
    view
    returns (uint128 marketSideValueInPaymentTokenLong, uint128 marketSideValueInPaymentTokenShort);

  function updateSystemState(uint32 marketIndex) external;

  function updateSystemStateMulti(uint32[] calldata marketIndex) external;

  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external view returns (uint256 confirmedButNotSettledBalance);

  function executeOutstandingNextPriceSettlementsUser(address user, uint32 marketIndex) external;

  function shiftPositionNextPrice(
    uint32 marketIndex,
    uint256 amountSyntheticTokensToShift,
    bool isShiftFromLong
  ) external;

  function shiftPositionFromLongNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external;

  function shiftPositionFromShortNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external;

  function getAmountSyntheticTokenToMintOnTargetSide(
    uint32 marketIndex,
    uint256 amountSyntheticTokenShiftedFromOneSide,
    bool isShiftFromLong,
    uint256 priceSnapshotIndex
  ) external view returns (uint256 amountSynthShiftedToOtherSide);

  function mintLongNextPrice(uint32 marketIndex, uint256 amount) external;

  function mintShortNextPrice(uint32 marketIndex, uint256 amount) external;

  function redeemLongNextPrice(uint32 marketIndex, uint256 amount) external;

  function redeemShortNextPrice(uint32 marketIndex, uint256 amount) external;

  /* ══════ User specific ══════ */
  function userNextPrice_currentUpdateIndex(uint32 marketIndex, address user)
    external
    view
    returns (uint256);

  function userLastInteractionTimestamp(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint32 timestamp, uint224 effectiveAmountMinted);

  function userNextPrice_paymentToken_depositAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_redeemAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_toShiftAwayFrom_marketSide(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function mintAndStakeNextPrice(
    uint32 marketIndex,
    uint256 amount,
    bool isLong
  ) external;

  function setUserTradeTimer(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;

  function checkIfUserIsEligibleToTrade(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;

  function checkIfUserIsEligibleToSendSynth(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;
}

/// @notice Manages yield accumulation for the LongShort contract. Each market is deployed with its own yield manager to simplify the bookkeeping, as different markets may share a payment token and yield pool.
interface IYieldManagerOriginal {
  event ClaimAaveRewardTokenToTreasury(uint256 amount);

  event YieldDistributed(uint256 unrealizedYield, uint256 treasuryYieldPercent_e18);

  /// @dev This is purely saving some gas, but the subgraph will know how much is due for the treasury at all times - no need to include in event.
  event WithdrawTreasuryFunds();

  /// @notice distributed yield not yet transferred to the treasury
  function totalReservedForTreasury() external returns (uint256);

  /// @notice Deposits the given amount of payment tokens into this yield manager.
  /// @param amount Amount of payment token to deposit
  function depositPaymentToken(uint256 amount) external;

  /// @notice Allows the LongShort pay out a user from tokens already withdrawn from Aave
  /// @param user User to recieve the payout
  /// @param amount Amount of payment token to pay to user
  function transferPaymentTokensToUser(address user, uint256 amount) external;

  /// @notice Withdraws the given amount of tokens from this yield manager.
  /// @param amount Amount of payment token to withdraw
  function removePaymentTokenFromMarket(uint256 amount) external;

  /**    
    @notice Calculates and updates the yield allocation to the treasury and the market
    @dev treasuryPercent = 1 - marketPercent
    @param totalValueRealizedForMarket total value of long and short side of the market
    @param treasuryYieldPercent_e18 Percentage of yield in base 1e18 that is allocated to the treasury
    @return amountForMarketIncentives The market allocation of the yield
  */
  function distributeYieldForTreasuryAndReturnMarketAllocation(
    uint256 totalValueRealizedForMarket,
    uint256 treasuryYieldPercent_e18
  ) external returns (uint256 amountForMarketIncentives);

  /// @notice Withdraw treasury allocated accrued yield from the lending pool to the treasury contract
  function withdrawTreasuryFunds() external;

  /// @notice Initializes a specific yield manager to a given market
  function initializeForMarket() external;
}

/*
 * Manages price feeds from different oracle implementations.
 */
interface IOracleManager {
  function updatePrice() external returns (int256);

  /*
   *Returns the latest price from the oracle feed.
   */
  function getLatestPrice() external view returns (int256);
}

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

    (bool success, bytes memory returndata) = target.staticcall(data);
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
        /// @solidity memory-safe-assembly
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   * @custom:oz-retyped-from bool
   */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) ||
        (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
      "Initializable: contract is already initialized"
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
   * initialization step. This is essential to configure modules that are added through upgrades and that require
   * initialization.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   */
  modifier reinitializer(uint8 version) {
    require(
      !_initializing && _initialized < version,
      "Initializable: contract is already initialized"
    );
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
// abstract contract Initializable {
//   /**
//    * @dev Indicates that the contract has been initialized.
//    * @custom:oz-retyped-from bool
//    */
//   uint8 private _initialized;

//   /**
//    * @dev Indicates that the contract is in the process of being initialized.
//    */
//   bool private _initializing;

//   /**
//    * @dev Triggered when the contract has been initialized or reinitialized.
//    */
//   event Initialized(uint8 version);

//   /**
//    * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
//    * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
//    */
//   modifier initializer() {
//     bool isTopLevelCall = !_initializing;
//     require(
//       (isTopLevelCall && _initialized < 1) ||
//         (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
//       "Initializable: contract is already initialized"
//     );
//     _initialized = 1;
//     if (isTopLevelCall) {
//       _initializing = true;
//     }
//     _;
//     if (isTopLevelCall) {
//       _initializing = false;
//       emit Initialized(1);
//     }
//   }

//   /**
//    * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
//    * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
//    * used to initialize parent contracts.
//    *
//    * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
//    * initialization step. This is essential to configure modules that are added through upgrades and that require
//    * initialization.
//    *
//    * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
//    * a contract, executing them in the right order is up to the developer or operator.
//    */
//   modifier reinitializer(uint8 version) {
//     require(
//       !_initializing && _initialized < version,
//       "Initializable: contract is already initialized"
//     );
//     _initialized = version;
//     _initializing = true;
//     _;
//     _initializing = false;
//     emit Initialized(version);
//   }

//   /**
//    * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
//    * {initializer} and {reinitializer} modifiers, directly or indirectly.
//    */
//   modifier onlyInitializing() {
//     require(_initializing, "Initializable: contract is not initializing");
//     _;
//   }

//   /**
//    * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
//    * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
//    * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
//    * through proxies.
//    */
//   function _disableInitializers() internal virtual {
//     require(!_initializing, "Initializable: contract is initializing");
//     if (_initialized < type(uint8).max) {
//       _initialized = type(uint8).max;
//       emit Initialized(type(uint8).max);
//     }
//   }
// }

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
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library StringsUpgradeable {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  /**
   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
   */
  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is
  Initializable,
  ContextUpgradeable,
  IAccessControlUpgradeable,
  ERC165Upgradeable
{
  function __AccessControl_init() internal onlyInitializing {}

  function __AccessControl_init_unchained() internal onlyInitializing {}

  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAccessControlUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `_msgSender()` is missing `role`.
   * Overriding this function changes the behavior of the {onlyRole} modifier.
   *
   * Format of the revert message is described in {_checkRole}.
   *
   * _Available since v4.6._
   */
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            "AccessControl: account ",
            StringsUpgradeable.toHexString(uint160(account), 20),
            " is missing role ",
            StringsUpgradeable.toHexString(uint256(role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleGranted} event.
   */
  function grantRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * May emit a {RoleGranted} event.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   *
   * NOTE: This function is deprecated in favor of {_grantRole}.
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleGranted} event.
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
  /**
   * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
   * address.
   *
   * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
   * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
   * function revert if invoked through a proxy.
   */
  function proxiableUUID() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
  /**
   * @dev Must return an address that can be used as a delegate call target.
   *
   * {BeaconProxy} will check that this address is a contract.
   */
  function implementation() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
  struct AddressSlot {
    address value;
  }

  struct BooleanSlot {
    bool value;
  }

  struct Bytes32Slot {
    bytes32 value;
  }

  struct Uint256Slot {
    uint256 value;
  }

  /**
   * @dev Returns an `AddressSlot` with member `value` located at `slot`.
   */
  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
   */
  function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
   */
  function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
   */
  function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }
}

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
  function __ERC1967Upgrade_init() internal onlyInitializing {}

  function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

  // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
  bytes32 private constant _ROLLBACK_SLOT =
    0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Emitted when the implementation is upgraded.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Returns the current implementation address.
   */
  function _getImplementation() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  /**
   * @dev Stores a new address in the EIP1967 implementation slot.
   */
  function _setImplementation(address newImplementation) private {
    require(
      AddressUpgradeable.isContract(newImplementation),
      "ERC1967: new implementation is not a contract"
    );
    StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
  }

  /**
   * @dev Perform implementation upgrade
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Perform implementation upgrade with additional setup call.
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeToAndCall(
    address newImplementation,
    bytes memory data,
    bool forceCall
  ) internal {
    _upgradeTo(newImplementation);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(newImplementation, data);
    }
  }

  /**
   * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeToAndCallUUPS(
    address newImplementation,
    bytes memory data,
    bool forceCall
  ) internal {
    // Upgrades from old implementations will perform a rollback test. This test requires the new
    // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
    // this special case will break upgrade paths from old UUPS implementation to new ones.
    if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
      _setImplementation(newImplementation);
    } else {
      try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
        require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
      } catch {
        revert("ERC1967Upgrade: new implementation is not UUPS");
      }
      _upgradeToAndCall(newImplementation, data, forceCall);
    }
  }

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Emitted when the admin account has changed.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Returns the current admin.
   */
  function _getAdmin() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
  }

  /**
   * @dev Stores a new address in the EIP1967 admin slot.
   */
  function _setAdmin(address newAdmin) private {
    require(newAdmin != address(0), "ERC1967: new admin is the zero address");
    StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
  }

  /**
   * @dev Changes the admin of the proxy.
   *
   * Emits an {AdminChanged} event.
   */
  function _changeAdmin(address newAdmin) internal {
    emit AdminChanged(_getAdmin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
   * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
   */
  bytes32 internal constant _BEACON_SLOT =
    0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

  /**
   * @dev Emitted when the beacon is upgraded.
   */
  event BeaconUpgraded(address indexed beacon);

  /**
   * @dev Returns the current beacon.
   */
  function _getBeacon() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
  }

  /**
   * @dev Stores a new beacon in the EIP1967 beacon slot.
   */
  function _setBeacon(address newBeacon) private {
    require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
    require(
      AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
      "ERC1967: beacon implementation is not a contract"
    );
    StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
  }

  /**
   * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
   * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
   *
   * Emits a {BeaconUpgraded} event.
   */
  function _upgradeBeaconToAndCall(
    address newBeacon,
    bytes memory data,
    bool forceCall
  ) internal {
    _setBeacon(newBeacon);
    emit BeaconUpgraded(newBeacon);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
    }
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
    require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return
      AddressUpgradeable.verifyCallResult(
        success,
        returndata,
        "Address: low-level delegate call failed"
      );
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
  Initializable,
  IERC1822ProxiableUpgradeable,
  ERC1967UpgradeUpgradeable
{
  function __UUPSUpgradeable_init() internal onlyInitializing {}

  function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
  address private immutable __self = address(this);

  /**
   * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
   * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
   * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
   * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
   * fail.
   */
  modifier onlyProxy() {
    require(address(this) != __self, "Function must be called through delegatecall");
    require(_getImplementation() == __self, "Function must be called through active proxy");
    _;
  }

  /**
   * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
   * callable on the implementing contract but not through proxies.
   */
  modifier notDelegated() {
    require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
    _;
  }

  /**
   * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
   * implementation. It is used to validate that the this implementation remains valid after an upgrade.
   *
   * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
   * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
   * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
   */
  function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
    return _IMPLEMENTATION_SLOT;
  }

  /**
   * @dev Upgrade the implementation of the proxy to `newImplementation`.
   *
   * Calls {_authorizeUpgrade}.
   *
   * Emits an {Upgraded} event.
   */
  function upgradeTo(address newImplementation) external virtual onlyProxy {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
  }

  /**
   * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
   * encoded in `data`.
   *
   * Calls {_authorizeUpgrade}.
   *
   * Emits an {Upgraded} event.
   */
  function upgradeToAndCall(address newImplementation, bytes memory data)
    external
    payable
    virtual
    onlyProxy
  {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, data, true);
  }

  /**
   * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
   * {upgradeTo} and {upgradeToAndCall}.
   *
   * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
   *
   * ```solidity
   * function _authorizeUpgrade(address) internal override onlyOwner {}
   * ```
   */
  function _authorizeUpgrade(address newImplementation) internal virtual;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// import "forge-std/console2.sol";

abstract contract AccessControlledAndUpgradeable is
  Initializable,
  AccessControlUpgradeable,
  UUPSUpgradeable
{
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @notice Initializes the contract when called by parent initializers.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init(address initialAdmin) internal onlyInitializing {
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _AccessControlledAndUpgradeable_init_unchained(initialAdmin);
  }

  /// @notice Initializes the contract for contracts that already call both __AccessControl_init
  ///         and _UUPSUpgradeable_init when initializing.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init_unchained(address initialAdmin) internal {
    require(initialAdmin != address(0));
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(UPGRADER_ROLE, initialAdmin);
  }

  /// @notice Authorizes an upgrade to a new address.
  /// @dev Can only be called by addresses wih UPGRADER_ROLE
  function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}
}

interface IGEMS {
  function initialize() external;

  function gm(address) external;

  function GEM_ROLE() external returns (bytes32);

  function balanceOf(address) external returns (uint256);
}

/** Contract giving user GEMS*/

// Inspired by https://github.com/andrecronje/rarity/blob/main/rarity.sol

/** @title GEMS */
contract GEMS is AccessControlledAndUpgradeable, IGEMS {
  bytes32 public constant GEM_ROLE = keccak256("GEM_ROLE");

  uint200 constant gems_per_day = 250e18;
  uint40 constant DAY = 1 days;

  mapping(address => uint256) public gems_deprecated;
  mapping(address => uint256) public streak_deprecated;
  mapping(address => uint256) public lastActionTimestamp_deprecated;

  // Pack all this data into a single struct.
  struct UserGemData {
    uint16 streak; // max 179 years - if someone reaches this streack, go them 🚀
    uint40 lastActionTimestamp; // will run out on February 20, 36812 (yes, the year 36812 - btw uint32 lasts untill the year 2106)
    uint200 gems; // this is big enough to last 6.4277522e+39 (=2^200/250e18) days 😆
  }
  mapping(address => UserGemData) userGemData;

  event GemsCollected(address user, uint256 gems, uint256 streak);

  function initialize() public initializer {
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(msg.sender);

    _setupRole(GEM_ROLE, msg.sender);
  }

  // Only called once per user
  function attemptUserUpgrade(address user)
    internal
    returns (UserGemData memory transferedUserGemData)
  {
    uint256 usersCurrentGems = gems_deprecated[user];
    if (usersCurrentGems > 0) {
      transferedUserGemData = UserGemData(
        uint16(streak_deprecated[user]),
        uint40(lastActionTimestamp_deprecated[user]),
        uint200(usersCurrentGems)
      );

      // resut old data (save some gas 😇)
      streak_deprecated[user] = 0;
      lastActionTimestamp_deprecated[user] = 0;
      gems_deprecated[user] = 0;
    }
  }

  // Say gm and get gems_deprecated by performing an action in LongShort or Staker
  function gm(address user) external {
    UserGemData memory userData = userGemData[user];
    uint256 userslastActionTimestamp = uint256(userData.lastActionTimestamp);
    if (userslastActionTimestamp == 0) {
      // this is either a user migrating to the more efficient struct OR a brand new user.
      //      in both cases, this branch will only ever execute once!
      userData = attemptUserUpgrade(user);
      userslastActionTimestamp = uint256(userData.lastActionTimestamp);
    }

    uint256 blocktimestamp = block.timestamp;

    unchecked {
      if (blocktimestamp - userslastActionTimestamp >= DAY) {
        if (hasRole(GEM_ROLE, msg.sender)) {
          // Award gems_deprecated
          userData.gems += gems_per_day;

          // Increment streak_deprecated
          if (blocktimestamp - userslastActionTimestamp < 2 * DAY) {
            userData.streak += 1;
          } else {
            userData.streak = 1; // reset streak_deprecated to 1
          }

          userData.lastActionTimestamp = uint40(blocktimestamp);
          userGemData[user] = userData; // update storage once all updates are complete!

          emit GemsCollected(user, uint256(userData.gems), uint256(userData.streak));
        }
      }
    }
  }

  function balanceOf(address account) public view returns (uint256 balance) {
    balance = uint256(userGemData[account].gems);
    if (balance == 0) {
      balance = gems_deprecated[account];
    }
  }

  function getGemData(address account) public view returns (UserGemData memory gemData) {
    gemData = userGemData[account];
    if (gemData.gems == 0) {
      gemData = UserGemData(
        uint16(streak_deprecated[account]),
        uint40(lastActionTimestamp_deprecated[account]),
        uint200(gems_deprecated[account])
      );
    }
  }
}

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
  address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

  function _sendLogPayload(bytes memory payload) private view {
    uint256 payloadLength = payload.length;
    address consoleAddress = CONSOLE_ADDRESS;
    assembly {
      let payloadStart := add(payload, 32)
      let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
    }
  }

  function log() internal view {
    _sendLogPayload(abi.encodeWithSignature("log()"));
  }

  function logInt(int256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
  }

  function logUint(uint256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function logString(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function logBool(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function logAddress(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function logBytes(bytes memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
  }

  function logBytes1(bytes1 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
  }

  function logBytes2(bytes2 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
  }

  function logBytes3(bytes3 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
  }

  function logBytes4(bytes4 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
  }

  function logBytes5(bytes5 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
  }

  function logBytes6(bytes6 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
  }

  function logBytes7(bytes7 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
  }

  function logBytes8(bytes8 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
  }

  function logBytes9(bytes9 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
  }

  function logBytes10(bytes10 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
  }

  function logBytes11(bytes11 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
  }

  function logBytes12(bytes12 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
  }

  function logBytes13(bytes13 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
  }

  function logBytes14(bytes14 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
  }

  function logBytes15(bytes15 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
  }

  function logBytes16(bytes16 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
  }

  function logBytes17(bytes17 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
  }

  function logBytes18(bytes18 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
  }

  function logBytes19(bytes19 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
  }

  function logBytes20(bytes20 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
  }

  function logBytes21(bytes21 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
  }

  function logBytes22(bytes22 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
  }

  function logBytes23(bytes23 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
  }

  function logBytes24(bytes24 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
  }

  function logBytes25(bytes25 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
  }

  function logBytes26(bytes26 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
  }

  function logBytes27(bytes27 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
  }

  function logBytes28(bytes28 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
  }

  function logBytes29(bytes29 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
  }

  function logBytes30(bytes30 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
  }

  function logBytes31(bytes31 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
  }

  function logBytes32(bytes32 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
  }

  function log(uint256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function log(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function log(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function log(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function log(uint256 p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
  }

  function log(uint256 p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
  }

  function log(uint256 p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
  }

  function log(uint256 p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
  }

  function log(string memory p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
  }

  function log(string memory p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
  }

  function log(string memory p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
  }

  function log(string memory p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
  }

  function log(bool p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
  }

  function log(bool p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
  }

  function log(bool p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
  }

  function log(bool p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
  }

  function log(address p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
  }

  function log(address p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
  }

  function log(address p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
  }

  function log(address p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3)
    );
  }
}

/**
 **** visit https://float.capital *****
 */

// https://polygonscan.com/address/0x16488343e508C2BFB7F180185848F924184c9C9F#code

/// @title Core logic of Float Protocal markets
/// @author float.capital
/// @notice visit https://float.capital for more info
/// @dev All functions in this file are currently `virtual`. This is NOT to encourage inheritance.
/// It is merely for convenince when unit testing.
/// @custom:auditors This contract balances long and short sides.
contract LongShortFeesAmend is ILongShortOriginal, AccessControlledAndUpgradeable {
  //Using Open Zeppelin safe transfer library for token transfers
  using SafeERC20 for IERC20;

  /*╔═════════════════════════════╗
    ║          VARIABLES          ║
    ╚═════════════════════════════╝*/

  /* ══════ Fixed-precision constants ══════ */
  /// @notice this is the address that permanently locked initial liquidity for markets is held by.
  /// These tokens will never move so market can never have zero liquidity on a side.
  /// @dev f10a7 spells float in hex - for fun - important part is that the private key for this address in not known.
  address private constant PERMANENT_INITIAL_LIQUIDITY_HOLDER =
    0xf10A7_F10A7_f10A7_F10a7_F10A7_f10a7_F10A7_f10a7;

  uint256 private constant SECONDS_IN_A_YEAR_e18 = 315576e20;

  /// @dev an empty allocation of storage for use in future upgrades - inspiration from OZ:
  ///      https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/10f0f1a95b1b0fd5520351886bae7a03490f1056/contracts/token/ERC20/ERC20Upgradeable.sol#L361
  uint256[45] private __constantsGap;

  /* ══════ Global state ══════ */
  uint32 public override latestMarket;

  address public staker;
  address public tokenFactory;
  address public gems;

  uint256[45] private __globalStateGap;

  /* ══════ Market specific ══════ */
  mapping(uint32 => bool) public marketExists;

  mapping(uint32 => int256) public override assetPrice;
  mapping(uint32 => uint256) public override marketUpdateIndex;
  mapping(uint32 => uint256) public marketTreasurySplitGradient_e18;
  mapping(uint32 => uint256) public marketLeverage_e18;

  mapping(uint32 => address) public paymentTokens;
  mapping(uint32 => address) public yieldManagers;
  mapping(uint32 => address) public override oracleManagers;

  mapping(uint32 => uint256) public fundingRateMultiplier_e18;

  uint256[44] private __marketStateGap;

  /* ══════ Market + position (long/short) specific ══════ */
  mapping(uint32 => mapping(bool => address)) public override syntheticTokens;

  mapping(uint32 => mapping(bool => uint256)) public marketSideValueInPaymentTokenLEGACY;

  /// @notice synthetic token prices of a given market of a (long/short) at every previous price update
  mapping(uint32 => mapping(bool => mapping(uint256 => uint256)))
    public syntheticToken_priceSnapshotLEGACY;

  mapping(uint32 => mapping(bool => uint256)) public override batched_amountPaymentToken_deposit;
  mapping(uint32 => mapping(bool => uint256)) public override batched_amountSyntheticToken_redeem;
  mapping(uint32 => mapping(bool => uint256))
    public
    override batched_amountSyntheticToken_toShiftAwayFrom_marketSide;

  struct MarketSideValueInPaymentToken {
    // this has a maximum size of `2^128=3.4028237e+38` units of payment token which is amply sufficient for our markets
    uint128 value_long;
    uint128 value_short;
  }
  mapping(uint32 => MarketSideValueInPaymentToken) public override marketSideValueInPaymentToken;

  struct SynthPriceInPaymentToken {
    // this has a maximum size of `2^128=3.4028237e+38` units of payment token which is amply sufficient for our markets
    uint128 price_long;
    uint128 price_short;
  }
  mapping(uint32 => mapping(uint256 => SynthPriceInPaymentToken))
    public syntheticToken_priceSnapshot;

  mapping(uint32 => uint256) public mintFee_basisPoints;
  mapping(uint32 => uint256) public feesToDistributeToMarketOnNextUpdate;

  uint256[41] private __marketPositonStateGap;

  /* ══════ User specific ══════ */
  mapping(uint32 => mapping(address => uint256)) public userNextPrice_currentUpdateIndex;

  mapping(uint32 => mapping(bool => mapping(address => uint256)))
    public userNextPrice_paymentToken_depositAmount;
  mapping(uint32 => mapping(bool => mapping(address => uint256)))
    public userNextPrice_syntheticToken_redeemAmount;
  mapping(uint32 => mapping(bool => mapping(address => uint256)))
    public userNextPrice_syntheticToken_toShiftAwayFrom_marketSide;

  /* ══════ trade time restriction logic  ══════ */
  struct UserInteractionInfo {
    uint32 timestamp;
    uint224 effectiveAmountMinted; // TODO: set this in all the functions that do anything with the timestamp.
  }
  mapping(uint32 => mapping(bool => mapping(address => UserInteractionInfo)))
    public userLastInteractionTimestamp;

  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  // This is used for testing (as opposed to onlyRole)
  function adminOnlyModifierLogic() internal virtual {
    _checkRole(ADMIN_ROLE, msg.sender);
  }

  modifier adminOnly() {
    adminOnlyModifierLogic();
    _;
  }
  modifier stakerOnly() {
    require(msg.sender == staker, "staker only");
    _;
  }

  modifier onlyValidSynthetic(uint32 marketIndex, bool isLong) {
    require(syntheticTokens[marketIndex][isLong] == msg.sender, "not valid synth");
    _;
  }

  function requireMarketExistsModifierLogic(uint32 marketIndex) internal view virtual {
    require(marketExists[marketIndex], "market doesn't exist");
  }

  modifier requireMarketExists(uint32 marketIndex) {
    requireMarketExistsModifierLogic(marketIndex);
    _;
  }

  modifier updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(
    address user,
    uint32 marketIndex
  ) {
    _updateSystemStateInternal(marketIndex);
    _executeOutstandingNextPriceSettlements(user, marketIndex);
    _;
  }

  function gemCollectingModifierLogic() internal virtual {
    if (msg.sender != staker) {
      GEMS(gems).gm(msg.sender);
    }
  }

  modifier gemCollecting() {
    gemCollectingModifierLogic();
    _;
  }

  /*╔═════════════════════════════════════════════════════╗
    ║          NETWORK SPECIFIC CONFIG FUNCTIONS          ║
    ╚═════════════════════════════════════════════════════╝*/

  /// @dev This contract uses legacy data.
  function HAS_LEGACY_DATA() internal pure virtual returns (bool) {
    return true;
  }

  /// @dev This is the amount of time users need to wait between trades.
  function CONTRACT_SLOW_TRADE_TIME() internal pure virtual returns (uint256) {
    return 0;
  }

  /*╔═════════════════════════════╗
    ║       CONTRACT SET-UP       ║
    ╚═════════════════════════════╝*/

  /// @notice Initializes the contract.
  /// @dev Calls OpenZeppelin's initializer modifier.
  /// @param _admin Address of the admin role.
  /// @param _tokenFactory Address of the contract which creates synthetic asset tokens.
  /// @param _staker Address of the contract which handles synthetic asset stakes.
  function initialize(
    address _admin,
    address _tokenFactory,
    address _staker,
    address _gems
  ) public virtual {
    require(
      _admin != address(0) &&
        _tokenFactory != address(0) &&
        _staker != address(0) &&
        _gems != address(0)
    );
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(_admin);
    tokenFactory = _tokenFactory;
    staker = _staker;
    gems = _gems;

    emit LongShortV1(_admin, _tokenFactory, _staker);
  }

  /*╔════════════════════════════════════╗
    ║       Trade Velocity Helpers       ║
    ╚════════════════════════════════════╝*/

  // sets the users timer when minting anything
  function _setUserTradeTimer(uint32 marketIndex, bool isLong) internal {
    // Could use `SafeCast.toUint32` from open Zeppelin also.
    userLastInteractionTimestamp[marketIndex][isLong][msg.sender].timestamp = uint32(
      block.timestamp
    );
  }

  function setUserTradeTimer(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external stakerOnly {
    // Could use `SafeCast.toUint32` from open Zeppelin also.
    userLastInteractionTimestamp[marketIndex][isLong][user].timestamp = uint32(block.timestamp);
  }

  // updates if 20000 seconds have passed and user is clear.
  function _checkIfUserIsEligibleToTrade(
    address user,
    uint32 marketIndex,
    bool isLong
  ) internal view {
    // when this function is upgraded to update, we can rename it to `_getAndUpdateTradeFees` and likely we'll include the trade amount as an argument.
    uint256 lastInteractionTimestamp = uint256(
      userLastInteractionTimestamp[marketIndex][isLong][user].timestamp
    );
    require(
      ((block.timestamp - lastInteractionTimestamp) >= CONTRACT_SLOW_TRADE_TIME()),
      "Rapid trading disabled, under wait period"
    );
  }

  // updates if 20000 seconds have passed and user is clear.
  function checkIfUserIsEligibleToTrade(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external view stakerOnly {
    _checkIfUserIsEligibleToTrade(user, marketIndex, isLong);
  }

  // updates if 20000 seconds have passed and user is clear.
  function checkIfUserIsEligibleToSendSynth(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external view onlyValidSynthetic(marketIndex, isLong) {
    _checkIfUserIsEligibleToTrade(user, marketIndex, isLong);
  }

  /*╔═══════════════════╗
    ║       ADMIN       ║
    ╚═══════════════════╝*/

  /// @notice Update oracle for a market
  /// @dev Can only be called by the current admin.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param _newOracleManager Address of the replacement oracle manager.
  function updateMarketOracle(uint32 marketIndex, address _newOracleManager) external adminOnly {
    // If not a oracle contract this would break things.. Test's arn't validating this
    // Ie require isOracle interface - ERC165
    address previousOracleManager = oracleManagers[marketIndex];
    oracleManagers[marketIndex] = _newOracleManager;
    emit OracleUpdated(marketIndex, previousOracleManager, _newOracleManager);
  }

  function updateMarketMintFee(uint32 marketIndex, uint256 _mintFee_basisPoints)
    external
    adminOnly
  {
    require(_mintFee_basisPoints <= 200, "mint fee > 200 basis points");
    require(marketExists[marketIndex], "market doesn't exist");
    mintFee_basisPoints[marketIndex] = _mintFee_basisPoints;
  }

  /// @notice changes the gradient of the line for determining the yield split between market and treasury.
  function changeMarketTreasurySplitGradient(
    uint32 marketIndex,
    uint256 _marketTreasurySplitGradient_e18
  ) external adminOnly {
    marketTreasurySplitGradient_e18[marketIndex] = _marketTreasurySplitGradient_e18;
  }

  function changeMarketFundingRateMultiplier(uint32 marketIndex, uint256 _fundingRateMultiplier_e18)
    external
    adminOnly
  {
    require(_fundingRateMultiplier_e18 <= 5e19, "not in range: funding rate <= 5000%");
    fundingRateMultiplier_e18[marketIndex] = _fundingRateMultiplier_e18;
    emit MarketFundingRateMultiplerChanged(marketIndex, _fundingRateMultiplier_e18);
  }

  /*╔═════════════════════════════╗
    ║       MARKET CREATION       ║
    ╚═════════════════════════════╝*/

  /// @notice Creates an entirely new long/short market tracking an underlying oracle price.
  ///  Make sure the synthetic names/symbols are unique.
  /// @dev This does not make the market active.
  /// The `initializeMarket` function was split out separately to this function to reduce costs.
  /// @param syntheticName Name of the synthetic asset
  /// @param syntheticSymbol Symbol for the synthetic asset
  /// @param _paymentToken The address of the erc20 token used to buy this synthetic asset
  /// this will likely always be DAI
  /// @param _oracleManager The address of the oracle manager that provides the price feed for this market
  /// @param _yieldManager The contract that manages depositing the paymentToken into a yield bearing protocol
  function createNewSyntheticMarket(
    string calldata syntheticName,
    string calldata syntheticSymbol,
    address _paymentToken,
    address _oracleManager,
    address _yieldManager
  ) external adminOnly {
    require(
      _paymentToken != address(0) && _oracleManager != address(0) && _yieldManager != address(0)
    );

    uint32 marketIndex = ++latestMarket;
    address _staker = staker;

    // Ensure new markets don't use the same yield manager
    IYieldManagerOriginal(_yieldManager).initializeForMarket();

    // Create new synthetic long token.
    syntheticTokens[marketIndex][true] = ITokenFactory(tokenFactory).createSyntheticToken(
      string(abi.encodePacked("Float Long ", syntheticName)),
      string(abi.encodePacked("fl", syntheticSymbol)),
      _staker,
      marketIndex,
      true
    );

    // Create new synthetic short token.
    syntheticTokens[marketIndex][false] = ITokenFactory(tokenFactory).createSyntheticToken(
      string(abi.encodePacked("Float Short ", syntheticName)),
      string(abi.encodePacked("fs", syntheticSymbol)),
      _staker,
      marketIndex,
      false
    );

    // Initial market state.
    paymentTokens[marketIndex] = _paymentToken;
    yieldManagers[marketIndex] = _yieldManager;
    oracleManagers[marketIndex] = _oracleManager;
    assetPrice[marketIndex] = IOracleManager(oracleManagers[marketIndex]).updatePrice();

    emit SyntheticMarketCreated(
      marketIndex,
      syntheticTokens[marketIndex][true],
      syntheticTokens[marketIndex][false],
      _paymentToken,
      assetPrice[marketIndex],
      syntheticName,
      syntheticSymbol,
      _oracleManager,
      _yieldManager
    );
  }

  /// @notice Creates an entirely new long/short market tracking an underlying oracle price.
  ///  Uses already created synthetic tokens.
  /// @dev This does not make the market active.
  /// The `initializeMarket` function was split out separately to this function to reduce costs.
  /// @param syntheticName Name of the synthetic asset
  /// @param syntheticSymbol Symbol for the synthetic asset
  /// @param _longToken Address for the long token.
  /// @param _shortToken Address for the short token.
  /// @param _paymentToken The address of the erc20 token used to buy this synthetic asset
  /// this will likely always be DAI
  /// @param _oracleManager The address of the oracle manager that provides the price feed for this market
  /// @param _yieldManager The contract that manages depositing the paymentToken into a yield bearing protocol
  function createNewSyntheticMarketExternalSyntheticTokens(
    string calldata syntheticName,
    string calldata syntheticSymbol,
    address _longToken,
    address _shortToken,
    address _paymentToken,
    address _oracleManager,
    address _yieldManager
  ) external adminOnly {
    uint32 marketIndex = ++latestMarket;

    // Ensure new markets don't use the same yield manager
    IYieldManagerOriginal(_yieldManager).initializeForMarket();

    // Assign new synthetic long token.
    syntheticTokens[marketIndex][true] = _longToken;

    // Assign new synthetic short token.
    syntheticTokens[marketIndex][false] = _shortToken;

    // Initial market state.
    paymentTokens[marketIndex] = _paymentToken;
    yieldManagers[marketIndex] = _yieldManager;
    oracleManagers[marketIndex] = _oracleManager;
    assetPrice[marketIndex] = IOracleManager(oracleManagers[marketIndex]).updatePrice();

    emit SyntheticMarketCreated(
      marketIndex,
      _longToken,
      _shortToken,
      _paymentToken,
      assetPrice[marketIndex],
      syntheticName,
      syntheticSymbol,
      _oracleManager,
      _yieldManager
    );
  }

  /// @notice Seeds a new market with initial capital.
  /// @dev Only called when initializing a market.
  /// @param initialMarketSeedForEachMarketSide Amount in wei for which to seed both sides of the market.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  function _seedMarketInitially(uint256 initialMarketSeedForEachMarketSide, uint32 marketIndex)
    internal
    virtual
  {
    require(
      // You require at least 1e18 (1 payment token with 18 decimal places) of the underlying payment token to seed the market.
      initialMarketSeedForEachMarketSide >= 1e18,
      "Insufficient market seed"
    );

    uint256 amountToLockInYieldManager = initialMarketSeedForEachMarketSide * 2;
    _transferPaymentTokensFromUserToYieldManager(marketIndex, amountToLockInYieldManager);
    IYieldManagerOriginal(yieldManagers[marketIndex]).depositPaymentToken(
      amountToLockInYieldManager
    );

    ISyntheticToken(syntheticTokens[marketIndex][true]).mint(
      PERMANENT_INITIAL_LIQUIDITY_HOLDER,
      initialMarketSeedForEachMarketSide
    );
    ISyntheticToken(syntheticTokens[marketIndex][false]).mint(
      PERMANENT_INITIAL_LIQUIDITY_HOLDER,
      initialMarketSeedForEachMarketSide
    );

    marketSideValueInPaymentToken[marketIndex] = MarketSideValueInPaymentToken(
      SafeCast.toUint128(initialMarketSeedForEachMarketSide),
      SafeCast.toUint128(initialMarketSeedForEachMarketSide)
    );
  }

  /// @notice Sets a market as active once it has already been setup by createNewSyntheticMarket.
  /// @dev Seperated from createNewSyntheticMarket due to gas considerations.
  /// @param marketIndex An int32 which uniquely identifies the market.
  /// @param kInitialMultiplier Linearly decreasing multiplier for Float token issuance for the market when staking synths.
  /// @param kPeriod Time which kInitialMultiplier will last
  /// @param unstakeFee_e18 Base 1e18 percentage fee levied when unstaking for the market.
  /// @param balanceIncentiveCurve_exponent Sets the degree to which Float token issuance differs
  /// for market sides in unbalanced markets. See Staker.sol
  /// @param balanceIncentiveCurve_equilibriumOffset An offset to account for naturally imbalanced markets
  /// when Float token issuance should differ for market sides. See Staker.sol
  /// @param initialMarketSeedForEachMarketSide Amount of payment token that will be deposited in each market side to seed the market.
  function initializeMarket(
    uint32 marketIndex,
    uint256 kInitialMultiplier,
    uint256 kPeriod,
    uint256 unstakeFee_e18,
    uint256 initialMarketSeedForEachMarketSide,
    uint256 balanceIncentiveCurve_exponent,
    int256 balanceIncentiveCurve_equilibriumOffset,
    uint256 _marketTreasurySplitGradient_e18,
    uint256 marketLeverage
  ) external adminOnly {
    require(
      kInitialMultiplier != 0 &&
        unstakeFee_e18 != 0 &&
        initialMarketSeedForEachMarketSide != 0 &&
        balanceIncentiveCurve_exponent != 0 &&
        _marketTreasurySplitGradient_e18 != 0
    );

    require(!marketExists[marketIndex], "already initialized");
    require(marketIndex <= latestMarket, "index too high");

    marketExists[marketIndex] = true;

    marketTreasurySplitGradient_e18[marketIndex] = _marketTreasurySplitGradient_e18;

    // Set this value to one initially - 0 is a null value and thus potentially bug prone.
    marketUpdateIndex[marketIndex] = 1;

    _seedMarketInitially(initialMarketSeedForEachMarketSide, marketIndex);

    require(marketLeverage <= 50e18 && marketLeverage >= 1e17, "Incorrect leverage");
    marketLeverage_e18[marketIndex] = marketLeverage;

    // Add new staker funds with fresh synthetic tokens.
    IStaker(staker).addNewStakingFund(
      marketIndex,
      syntheticTokens[marketIndex][true],
      syntheticTokens[marketIndex][false],
      kInitialMultiplier,
      kPeriod,
      unstakeFee_e18,
      balanceIncentiveCurve_exponent,
      balanceIncentiveCurve_equilibriumOffset
    );

    IStaker(staker).pushUpdatedMarketPricesToUpdateFloatIssuanceCalculations(
      marketIndex,
      1,
      1e18,
      1e18,
      initialMarketSeedForEachMarketSide,
      initialMarketSeedForEachMarketSide
    );

    emit NewMarketLaunchedAndSeeded(
      marketIndex,
      initialMarketSeedForEachMarketSide,
      marketLeverage
    );
  }

  /*╔══════════════════════════════╗
    ║       GETTER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  /// @notice Calculates the conversion rate from synthetic tokens to payment tokens.
  /// @dev Synth tokens have a fixed 18 decimals.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @return syntheticTokenPrice The calculated conversion rate in base 1e18.
  function _getSyntheticTokenPrice(
    uint256 amountPaymentTokenBackingSynth,
    uint256 amountSyntheticToken
  ) internal pure virtual returns (uint256 syntheticTokenPrice) {
    return (amountPaymentTokenBackingSynth * 1e18) / amountSyntheticToken;
  }

  /// @notice Converts synth token amounts to payment token amounts at a synth token price.
  /// @dev Price assumed base 1e18.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountPaymentToken The calculated amount of payment tokens in token's lowest denomination.
  function _getAmountPaymentToken(
    uint256 amountSyntheticToken,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountPaymentToken) {
    return (amountSyntheticToken * syntheticTokenPriceInPaymentTokens) / 1e18;
  }

  /// @notice Converts payment token amounts to synth token amounts at a synth token price.
  /// @dev  Price assumed base 1e18.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountSyntheticToken The calculated amount of synthetic token in wei.
  function _getAmountSyntheticToken(
    uint256 amountPaymentTokenBackingSynth,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountSyntheticToken) {
    return (amountPaymentTokenBackingSynth * 1e18) / syntheticTokenPriceInPaymentTokens;
  }

  /**
  @notice Calculate the amount of target side synthetic tokens that are worth the same
          amount of payment tokens as X many synthetic tokens on origin side.
          The resulting equation comes from simplifying this function

            _getAmountSyntheticToken(
              _getAmountPaymentToken(
                amountOriginSynth,
                priceOriginSynth
              ),
              priceTargetSynth)

            Unpacking the function we get:
            ((amountOriginSynth * priceOriginSynth) / 1e18) * 1e18 / priceTargetSynth
              And simplifying this we get:
            (amountOriginSynth * priceOriginSynth) / priceTargetSynth
  @param amountSyntheticTokens_originSide Amount of synthetic tokens on origin side
  @param syntheticTokenPrice_originSide Price of origin side's synthetic token
  @param syntheticTokenPrice_targetSide Price of target side's synthetic token
  @return equivalentAmountSyntheticTokensOnTargetSide Amount of synthetic token on target side
  */
  function _getEquivalentAmountSyntheticTokensOnTargetSide(
    uint256 amountSyntheticTokens_originSide,
    uint256 syntheticTokenPrice_originSide,
    uint256 syntheticTokenPrice_targetSide
  ) internal pure virtual returns (uint256 equivalentAmountSyntheticTokensOnTargetSide) {
    equivalentAmountSyntheticTokensOnTargetSide =
      (amountSyntheticTokens_originSide * syntheticTokenPrice_originSide) /
      syntheticTokenPrice_targetSide;
  }

  function get_syntheticToken_priceSnapshot(uint32 marketIndex, uint256 priceSnapshotIndex)
    public
    view
    override
    returns (uint256 priceLong, uint256 priceShort)
  {
    priceLong = uint256(syntheticToken_priceSnapshot[marketIndex][priceSnapshotIndex].price_long);

    priceShort = uint256(syntheticToken_priceSnapshot[marketIndex][priceSnapshotIndex].price_short);

    if (HAS_LEGACY_DATA()) {
      // In case price requested is part of legacy data-structure
      if (
        priceLong == 0 /* which means priceShort is also zero! */
      ) {
        priceLong = syntheticToken_priceSnapshotLEGACY[marketIndex][true][priceSnapshotIndex];
        priceShort = syntheticToken_priceSnapshotLEGACY[marketIndex][false][priceSnapshotIndex];
      }
    }
  }

  function get_syntheticToken_priceSnapshot_side(
    uint32 marketIndex,
    bool isLong,
    uint256 priceSnapshotIndex
  ) public view override returns (uint256 price) {
    if (isLong) {
      price = uint256(syntheticToken_priceSnapshot[marketIndex][priceSnapshotIndex].price_long);
    } else {
      price = uint256(syntheticToken_priceSnapshot[marketIndex][priceSnapshotIndex].price_short);
    }
    if (HAS_LEGACY_DATA()) {
      // In case price requested is part of legacy data-structure
      if (price == 0) {
        price = syntheticToken_priceSnapshotLEGACY[marketIndex][isLong][priceSnapshotIndex];
      }
    }
  }

  /// @notice Given an executed next price shift from tokens on one market side to the other,
  /// determines how many other side tokens the shift was worth.
  /// @dev Intended for use primarily by Staker.sol
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amountSyntheticToken_redeemOnOriginSide Amount of synth token in wei.
  /// @param isShiftFromLong Whether the token shift is from long to short (true), or short to long (false).
  /// @param priceSnapshotIndex Index which identifies which synth prices to use.
  /// @return amountSyntheticTokensToMintOnTargetSide The amount in wei of tokens for the other side that the shift was worth.
  function getAmountSyntheticTokenToMintOnTargetSide(
    uint32 marketIndex,
    uint256 amountSyntheticToken_redeemOnOriginSide,
    bool isShiftFromLong,
    uint256 priceSnapshotIndex
  ) public view virtual override returns (uint256 amountSyntheticTokensToMintOnTargetSide) {
    uint256 syntheticTokenPriceOnOriginSide;
    uint256 syntheticTokenPriceOnTargetSide;
    if (isShiftFromLong) {
      (
        syntheticTokenPriceOnOriginSide,
        syntheticTokenPriceOnTargetSide
      ) = get_syntheticToken_priceSnapshot(marketIndex, priceSnapshotIndex);
    } else {
      (
        syntheticTokenPriceOnTargetSide,
        syntheticTokenPriceOnOriginSide
      ) = get_syntheticToken_priceSnapshot(marketIndex, priceSnapshotIndex);
    }

    amountSyntheticTokensToMintOnTargetSide = _getEquivalentAmountSyntheticTokensOnTargetSide(
      amountSyntheticToken_redeemOnOriginSide,
      syntheticTokenPriceOnOriginSide,
      syntheticTokenPriceOnTargetSide
    );
  }

  /**
  @notice The amount of a synth token a user is owed following a batch execution.
    4 possible states for next price actions:
        - "Pending" - means the next price update hasn't happened or been enacted on by the updateSystemState function.
        - "Confirmed" - means the next price has been updated by the updateSystemState function. There is still
        -               outstanding (lazy) computation that needs to be executed per user in the batch.
        - "Settled" - there is no more computation left for the user.
        - "Non-existent" - user has no next price actions.
    This function returns a calculated value only in the case of 'confirmed' next price actions.
    It should return zero for all other types of next price actions.
  @dev Used in SyntheticToken.sol balanceOf to allow for automatic reflection of next price actions.
  @param user The address of the user for whom to execute the function for.
  @param marketIndex An uint32 which uniquely identifies a market.
  @param isLong Whether it is for the long synthetic asset or the short synthetic asset.
  @return confirmedButNotSettledBalance The amount in wei of tokens that the user is owed.
  */
  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    uint32 marketIndex,
    bool isLong
  )
    external
    view
    virtual
    override
    requireMarketExists(marketIndex)
    returns (uint256 confirmedButNotSettledBalance)
  {
    uint256 currentMarketUpdateIndex = marketUpdateIndex[marketIndex];
    uint256 userNextPrice_currentUpdateIndex_forMarket = userNextPrice_currentUpdateIndex[
      marketIndex
    ][user];
    if (
      userNextPrice_currentUpdateIndex_forMarket != 0 &&
      userNextPrice_currentUpdateIndex_forMarket <= currentMarketUpdateIndex
    ) {
      uint256 amountPaymentTokenDeposited = userNextPrice_paymentToken_depositAmount[marketIndex][
        isLong
      ][user];

      uint256 syntheticTokenPrice;
      uint256 syntheticTokenPriceOnOriginSideOfShift;

      if (isLong) {
        (
          syntheticTokenPrice,
          syntheticTokenPriceOnOriginSideOfShift
        ) = get_syntheticToken_priceSnapshot(
          marketIndex,
          userNextPrice_currentUpdateIndex_forMarket
        );
      } else {
        (
          syntheticTokenPriceOnOriginSideOfShift,
          syntheticTokenPrice
        ) = get_syntheticToken_priceSnapshot(
          marketIndex,
          userNextPrice_currentUpdateIndex_forMarket
        );
      }

      if (amountPaymentTokenDeposited > 0) {
        confirmedButNotSettledBalance = _getAmountSyntheticToken(
          amountPaymentTokenDeposited,
          syntheticTokenPrice
        );
      }

      uint256 amountSyntheticTokensToBeShiftedAwayFromOriginSide = userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[
          marketIndex
        ][!isLong][user];

      if (amountSyntheticTokensToBeShiftedAwayFromOriginSide > 0) {
        confirmedButNotSettledBalance += _getEquivalentAmountSyntheticTokensOnTargetSide(
          amountSyntheticTokensToBeShiftedAwayFromOriginSide,
          syntheticTokenPriceOnOriginSideOfShift,
          syntheticTokenPrice
        );
      }
    }
  }

  /**
   @notice Calculates the percentage in base 1e18 of how much of the accrued yield
   for a market should be allocated to treasury.
   @dev For gas considerations also returns whether the long side is imbalanced.
   @dev For gas considerations totalValueLockedInMarket is passed as a parameter as the function
   calling this function has pre calculated the value
   @param longValue The current total payment token value of the long side of the market.
   @param shortValue The current total payment token value of the short side of the market.
   @param totalValueLockedInMarket Total payment token value of both sides of the market.
   @return isLongSideUnderbalanced Whether the long side initially had less value than the short side.
   @return treasuryYieldPercent_e18 The percentage in base 1e18 of how much of the accrued yield
   for a market should be allocated to treasury.
   */
  function _getYieldSplit(
    uint32 marketIndex,
    uint256 longValue,
    uint256 shortValue,
    uint256 totalValueLockedInMarket
  ) internal view virtual returns (bool isLongSideUnderbalanced, uint256 treasuryYieldPercent_e18) {
    isLongSideUnderbalanced = longValue < shortValue;
    uint256 imbalance;

    unchecked {
      if (isLongSideUnderbalanced) {
        imbalance = shortValue - longValue;
      } else {
        imbalance = longValue - shortValue;
      }
    }

    // marketTreasurySplitGradient_e18 may be adjusted to ensure yield is given
    // to the market at a desired rate e.g. if a market tends to become imbalanced
    // frequently then the gradient can be increased to funnel yield to the market
    // quicker.
    // See this equation in latex: https://ipfs.io/ipfs/QmXsW4cHtxpJ5BFwRcMSUw7s5G11Qkte13NTEfPLTKEx4x
    // Interact with this equation: https://www.desmos.com/calculator/pnl43tfv5b
    uint256 marketPercentCalculated_e18 = (imbalance *
      marketTreasurySplitGradient_e18[marketIndex]) / totalValueLockedInMarket;

    uint256 marketPercent_e18 = Math.min(marketPercentCalculated_e18, 1e18);

    unchecked {
      treasuryYieldPercent_e18 = 1e18 - marketPercent_e18;
    }
  }

  /*╔══════════════════════════════╗
    ║       HELPER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  /// @notice This calculates the value transfer from the overbalanced to underbalanced side (i.e. the funding rate)
  /// This is a further incentive measure to balanced markets. This may be present on some and not other synthetic markets.
  /// @param marketIndex The market for which to execute the function for.
  /// @param _fundingRateMultiplier_e18 A scalar base e18 for the funding rate.
  /// @param overbalancedValue Side with more liquidity.
  /// @param underbalancedValue Side with less liquidity.
  /// @return fundingAmount The amount the overbalanced side needs to pay the underbalanced.
  function _calculateFundingAmount(
    uint32 marketIndex,
    uint256 _fundingRateMultiplier_e18,
    uint256 overbalancedValue,
    uint256 underbalancedValue
  ) internal virtual returns (uint256 fundingAmount) {
    uint256 lastUpdateTimestamp = IStaker(staker).safe_getUpdateTimestamp(
      marketIndex,
      marketUpdateIndex[marketIndex]
    );

    /* 
    overBalanced * (1 - underBalanced/overBalanced)
      = overBalanced * (overBalanced - underBalanced)/overBalanced)
      = overBalanced - underBalanced
      = market imbalance
    
    funding amount = market imbalance * yearlyMaxFundingRate * (now - lastUpdate) / (365.25days in seconds base e18)
    */
    fundingAmount =
      ((overbalancedValue - underbalancedValue) *
        _fundingRateMultiplier_e18 *
        (block.timestamp - lastUpdateTimestamp)) /
      SECONDS_IN_A_YEAR_e18;
  }

  /// @notice First gets yield from the yield manager and allocates it to market and treasury.
  /// It then allocates the full market yield portion to the underbalanced side of the market.
  /// NB this function also adjusts the value of the long and short side based on the latest
  /// price of the underlying asset received from the oracle. This function should ideally be
  /// called everytime there is an price update from the oracle. We have built a bot that does this.
  /// The system is still perectly safe if not called every price update, the synthetic will just
  /// less closely track the underlying asset.
  /// @dev In one function as yield should be allocated before rebalancing.
  /// This prevents an attack whereby the user imbalances a side to capture all accrued yield.
  /// @param marketIndex The market for which to execute the function for.
  /// @param newAssetPrice The new asset price.
  /// @return longValue The value of the long side after rebalancing.
  /// @return shortValue The value of the short side after rebalancing.
  function _claimAndDistributeYieldThenRebalanceMarket(uint32 marketIndex, int256 newAssetPrice)
    internal
    virtual
    returns (uint256 longValue, uint256 shortValue)
  {
    MarketSideValueInPaymentToken
      storage currentMarketSideValueInPaymentToken = marketSideValueInPaymentToken[marketIndex];
    // Claiming and distributing the yield
    longValue = currentMarketSideValueInPaymentToken.value_long;
    shortValue = currentMarketSideValueInPaymentToken.value_short;
    uint256 totalValueLockedInMarket = longValue + shortValue;

    (bool isLongSideUnderbalanced, uint256 treasuryYieldPercent_e18) = _getYieldSplit(
      marketIndex,
      longValue,
      shortValue,
      totalValueLockedInMarket
    );

    uint256 marketAmount = IYieldManagerOriginal(yieldManagers[marketIndex])
      .distributeYieldForTreasuryAndReturnMarketAllocation(
        totalValueLockedInMarket,
        treasuryYieldPercent_e18
      );

    // Take fee as simply 1% of notional over 1 year.
    // Value leaving long and short to treasury, this should be done carefully in yield manager!
    // order of where this is done is important.
    // This amount also potentially lumped together with funding rate fee + exposure fee ?
    // See what is simple and makes sense on the bottom line.

    if (marketAmount > 0) {
      if (isLongSideUnderbalanced) {
        longValue += marketAmount;
      } else {
        shortValue += marketAmount;
      }
    }

    int256 oldAssetPrice = assetPrice[marketIndex];

    // Adjusting value of long and short pool based on price movement
    // The side/position with less liquidity has 100% percent exposure to the price movement.
    // The side/position with more liquidity will have exposure < 100% to the price movement.
    // I.e. Imagine $100 in longValue and $50 shortValue
    // long side would have $50/$100 = 50% exposure to price movements based on the liquidity imbalance.
    // min(longValue, shortValue) = $50 , therefore if the price change was -10% then
    // $50 * 10% = $5 gained for short side and conversely $5 lost for long side.
    int256 underbalancedSideValue = int256(Math.min(longValue, shortValue));

    // send a piece of value change to the treasury?
    // Again this reduces the value of totalValueLockedInMarket which means yield manager needs to be alerted.
    // See this equation in latex: https://ipfs.io/ipfs/QmPeJ3SZdn1GfxqCD4GDYyWTJGPMSHkjPJaxrzk2qTTPSE
    // Interact with this equation: https://www.desmos.com/calculator/t8gr6j5vsq
    int256 valueChange = ((newAssetPrice - oldAssetPrice) *
      underbalancedSideValue *
      int256(marketLeverage_e18[marketIndex])) / (oldAssetPrice * 1e18);

    {
      uint256 fundingRateMultiplier = fundingRateMultiplier_e18[marketIndex];
      if (fundingRateMultiplier > 0) {
        //  slow drip interest funding payment here.
        //  recheck yield hasn't tipped the market.
        if (longValue < shortValue) {
          valueChange += int256(
            _calculateFundingAmount(marketIndex, fundingRateMultiplier, shortValue, longValue)
          );
        } else {
          valueChange -= int256(
            _calculateFundingAmount(marketIndex, fundingRateMultiplier, longValue, shortValue)
          );
        }
      }
    }

    if (valueChange < 0) {
      valueChange = -valueChange; // make value change positive

      // handle 'impossible' edge case where underlying price feed changes more than 100% downwards gracefully.
      if (uint256(valueChange) > longValue) {
        valueChange = (int256(longValue) * 99999) / 100000;
      }
      longValue -= uint256(valueChange);
      shortValue += uint256(valueChange);
    } else {
      // handle 'impossible' edge case where underlying price feed changes more than 100% upwards gracefully.
      if (uint256(valueChange) > shortValue) {
        valueChange = (int256(shortValue) * 99999) / 100000;
      }
      longValue += uint256(valueChange);
      shortValue -= uint256(valueChange);
    }

    // If odd, will round down. Its all in yield manager and will be recognized as yield in future.
    uint256 mintFeesForEachPool = feesToDistributeToMarketOnNextUpdate[marketIndex] >> 1; // divide by 2
    longValue += mintFeesForEachPool;
    shortValue += mintFeesForEachPool;
  }

  /*╔═══════════════════════════════╗
    ║     UPDATING SYSTEM STATE     ║
    ╚═══════════════════════════════╝*/

  /// @notice Updates the value of the long and short sides to account for latest oracle price updates
  /// and batches all next price actions.
  /// @dev To prevent front-running only executes on price change from an oracle.
  /// We assume the function will be called for each market at least once per price update.
  /// Note Even if not called on every price update, this won't affect security, it will only affect how closely
  /// the synthetic asset actually tracks the underlying asset.
  /// @param marketIndex The market index for which to update.
  function _updateSystemStateInternal(uint32 marketIndex)
    internal
    virtual
    requireMarketExists(marketIndex)
  {
    // If a negative int is return this should fail.
    int256 newAssetPrice = IOracleManager(oracleManagers[marketIndex]).updatePrice();

    uint256 currentMarketIndex = marketUpdateIndex[marketIndex];

    bool assetPriceHasChanged = assetPrice[marketIndex] != newAssetPrice;

    if (assetPriceHasChanged) {
      (
        uint256 newLongPoolValue,
        uint256 newShortPoolValue
      ) = _claimAndDistributeYieldThenRebalanceMarket(marketIndex, newAssetPrice);

      uint256 syntheticTokenPrice_inPaymentTokens_long = _getSyntheticTokenPrice(
        newLongPoolValue,
        ISyntheticToken(syntheticTokens[marketIndex][true]).totalSupply()
      );
      uint256 syntheticTokenPrice_inPaymentTokens_short = _getSyntheticTokenPrice(
        newShortPoolValue,
        ISyntheticToken(syntheticTokens[marketIndex][false]).totalSupply()
      );

      assetPrice[marketIndex] = newAssetPrice;

      currentMarketIndex++;
      marketUpdateIndex[marketIndex] = currentMarketIndex;

      syntheticToken_priceSnapshot[marketIndex][currentMarketIndex] = SynthPriceInPaymentToken(
        SafeCast.toUint128(syntheticTokenPrice_inPaymentTokens_long),
        SafeCast.toUint128(syntheticTokenPrice_inPaymentTokens_short)
      );

      (
        int256 long_changeInMarketValue_inPaymentToken,
        int256 short_changeInMarketValue_inPaymentToken
      ) = _batchConfirmOutstandingPendingActions(
          marketIndex,
          syntheticTokenPrice_inPaymentTokens_long,
          syntheticTokenPrice_inPaymentTokens_short
        );

      // This needs to be set to zero after _batchConfirmOutstandingPendingActions
      // as that function uses it to tell the yield manager the net inflow/outflow
      // of dollars to/from the yield manager
      feesToDistributeToMarketOnNextUpdate[marketIndex] = 0; // This is NB.

      newLongPoolValue = uint256(
        int256(newLongPoolValue) + long_changeInMarketValue_inPaymentToken
      );
      newShortPoolValue = uint256(
        int256(newShortPoolValue) + short_changeInMarketValue_inPaymentToken
      );
      marketSideValueInPaymentToken[marketIndex] = MarketSideValueInPaymentToken(
        SafeCast.toUint128(newLongPoolValue),
        SafeCast.toUint128(newShortPoolValue)
      );

      IStaker(staker).pushUpdatedMarketPricesToUpdateFloatIssuanceCalculations(
        marketIndex,
        currentMarketIndex,
        syntheticTokenPrice_inPaymentTokens_long,
        syntheticTokenPrice_inPaymentTokens_short,
        newLongPoolValue,
        newShortPoolValue
      );

      emit SystemStateUpdated(
        marketIndex,
        currentMarketIndex,
        newAssetPrice,
        newLongPoolValue,
        newShortPoolValue,
        syntheticTokenPrice_inPaymentTokens_long,
        syntheticTokenPrice_inPaymentTokens_short
      );
    }
  }

  /// @notice Updates the state of a market to account for the latest oracle price update.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  function updateSystemState(uint32 marketIndex) external override {
    _updateSystemStateInternal(marketIndex);
  }

  /// @notice Updates the state of multiples markets to account for their latest oracle price updates.
  /// @param marketIndexes An array of int32s which uniquely identify markets.
  function updateSystemStateMulti(uint32[] calldata marketIndexes) external override {
    uint256 length = marketIndexes.length;
    for (uint256 i = 0; i < length; i++) {
      _updateSystemStateInternal(marketIndexes[i]);
    }
  }

  /*╔═══════════════════════════╗
    ║          DEPOSIT          ║
    ╚═══════════════════════════╝*/

  /// @notice Transfers payment tokens for a market from msg.sender to this contract.
  /// @dev Tokens are transferred directly to this contract to be deposited by the yield manager in the batch to earn yield.
  ///      Since we check the return value of the transferFrom method, all payment tokens we use must conform to the ERC20 standard.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amount Amount of payment tokens in that token's lowest denominationto deposit.
  function _transferPaymentTokensFromUserToYieldManager(uint32 marketIndex, uint256 amount)
    internal
    virtual
  {
    IERC20(paymentTokens[marketIndex]).safeTransferFrom(
      msg.sender,
      yieldManagers[marketIndex],
      amount
    );
  }

  /*╔═══════════════════════════╗
    ║       MINT POSITION       ║
    ╚═══════════════════════════╝*/

  function _applyMintFees(uint32 marketIndex, uint256 amount)
    internal
    returns (uint256 amountFees)
  {
    amountFees = (amount * mintFee_basisPoints[marketIndex]) / 10000;
    feesToDistributeToMarketOnNextUpdate[marketIndex] += amountFees;
  }

  /// @notice Allows users to mint synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  /// @param isLong Whether the mint is for a long or short synth.
  function _mintNextPrice(
    uint32 marketIndex,
    uint256 amount,
    bool isLong
  )
    internal
    virtual
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(msg.sender, marketIndex)
    gemCollecting
  {
    require(amount > 0, "Mint amount == 0");

    _setUserTradeTimer(marketIndex, isLong);

    _transferPaymentTokensFromUserToYieldManager(marketIndex, amount);

    amount = amount - _applyMintFees(marketIndex, amount);

    batched_amountPaymentToken_deposit[marketIndex][isLong] += amount;
    userNextPrice_paymentToken_depositAmount[marketIndex][isLong][msg.sender] += amount;
    uint256 nextUpdateIndex = marketUpdateIndex[marketIndex] + 1;
    userNextPrice_currentUpdateIndex[marketIndex][msg.sender] = nextUpdateIndex;

    emit NextPriceDeposit(marketIndex, isLong, amount, msg.sender, nextUpdateIndex);
  }

  function mintAndStakeNextPrice(
    uint32 marketIndex,
    uint256 amount,
    bool isLong
  )
    external
    virtual
    override
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(staker, marketIndex)
    gemCollecting
  {
    require(amount > 0, "Mint amount must be greater than 0");
    _setUserTradeTimer(marketIndex, isLong);
    _transferPaymentTokensFromUserToYieldManager(marketIndex, amount);

    amount = amount - _applyMintFees(marketIndex, amount);

    batched_amountPaymentToken_deposit[marketIndex][isLong] += amount;
    userNextPrice_paymentToken_depositAmount[marketIndex][isLong][staker] += amount;
    uint256 nextUpdateIndex = marketUpdateIndex[marketIndex] + 1;
    userNextPrice_currentUpdateIndex[marketIndex][staker] = nextUpdateIndex;

    IStaker(staker).mintAndStakeNextPrice(marketIndex, amount, isLong, msg.sender);

    emit NextPriceDepositAndStake(marketIndex, isLong, amount, msg.sender, nextUpdateIndex);
  }

  /// @notice Allows users to mint long synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function mintLongNextPrice(uint32 marketIndex, uint256 amount) external override {
    _mintNextPrice(marketIndex, amount, true);
  }

  /// @notice Allows users to mint short synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function mintShortNextPrice(uint32 marketIndex, uint256 amount) external override {
    _mintNextPrice(marketIndex, amount, false);
  }

  /*╔═══════════════════════════╗
    ║      REDEEM POSITION      ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to redeem their synthetic tokens for payment tokens. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @dev Called by external functions to redeem either long or short. Payment tokens are actually transferred to the user when executeOutstandingNextPriceSettlements is called from a function call by the user.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param tokens_redeem Amount in wei of synth tokens to redeem.
  /// @param isLong Whether this redeem is for a long or short synth.
  function _redeemNextPrice(
    uint32 marketIndex,
    uint256 tokens_redeem,
    bool isLong
  )
    internal
    virtual
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(msg.sender, marketIndex)
    gemCollecting
  {
    require(tokens_redeem > 0, "Redeem amount == 0");
    _checkIfUserIsEligibleToTrade(msg.sender, marketIndex, isLong);
    ISyntheticToken(syntheticTokens[marketIndex][isLong]).transferFrom(
      msg.sender,
      address(this),
      tokens_redeem
    );

    userNextPrice_syntheticToken_redeemAmount[marketIndex][isLong][msg.sender] += tokens_redeem;
    uint256 nextUpdateIndex = marketUpdateIndex[marketIndex] + 1;
    userNextPrice_currentUpdateIndex[marketIndex][msg.sender] = nextUpdateIndex;

    batched_amountSyntheticToken_redeem[marketIndex][isLong] += tokens_redeem;

    emit NextPriceRedeem(marketIndex, isLong, tokens_redeem, msg.sender, nextUpdateIndex);
  }

  /// @notice  Allows users to redeem long synthetic assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param tokens_redeem Amount in wei of synth tokens to redeem at the next oracle price.
  function redeemLongNextPrice(uint32 marketIndex, uint256 tokens_redeem) external override {
    _redeemNextPrice(marketIndex, tokens_redeem, true);
  }

  /// @notice  Allows users to redeem short synthetic assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param tokens_redeem Amount in wei of synth tokens to redeem at the next oracle price.
  function redeemShortNextPrice(uint32 marketIndex, uint256 tokens_redeem) external override {
    _redeemNextPrice(marketIndex, tokens_redeem, false);
  }

  /*╔═══════════════════════════╗
    ║       SHIFT POSITION      ║
    ╚═══════════════════════════╝*/

  /// @notice  Allows users to shift their position from one side of the market to the other in a single transaction. To prevent front-running these shifts are executed on the next price update from the oracle.
  /// @dev Called by external functions to shift either way. Intended for primary use by Staker.sol
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amountSyntheticTokensToShift Amount in wei of synthetic tokens to shift from the one side to the other at the next oracle price update.
  /// @param isShiftFromLong Whether the token shift is from long to short (true), or short to long (false).
  function shiftPositionNextPrice(
    uint32 marketIndex,
    uint256 amountSyntheticTokensToShift,
    bool isShiftFromLong
  )
    public
    virtual
    override
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(msg.sender, marketIndex)
    gemCollecting
  {
    require(amountSyntheticTokensToShift > 0, "Shift amount == 0");

    if (msg.sender != staker) {
      _checkIfUserIsEligibleToTrade(msg.sender, marketIndex, isShiftFromLong);
      _setUserTradeTimer(marketIndex, !isShiftFromLong);
    }

    ISyntheticToken(syntheticTokens[marketIndex][isShiftFromLong]).transferFrom(
      msg.sender,
      address(this),
      amountSyntheticTokensToShift
    );

    userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[marketIndex][isShiftFromLong][
      msg.sender
    ] += amountSyntheticTokensToShift;
    uint256 nextUpdateIndex = marketUpdateIndex[marketIndex] + 1;
    userNextPrice_currentUpdateIndex[marketIndex][msg.sender] = nextUpdateIndex;

    batched_amountSyntheticToken_toShiftAwayFrom_marketSide[marketIndex][
      isShiftFromLong
    ] += amountSyntheticTokensToShift;

    emit NextPriceSyntheticPositionShift(
      marketIndex,
      isShiftFromLong,
      amountSyntheticTokensToShift,
      msg.sender,
      nextUpdateIndex
    );
  }

  /// @notice Allows users to shift their position from long to short in a single transaction. To prevent front-running these shifts are executed on the next price update from the oracle.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amountSyntheticTokensToShift Amount in wei of synthetic tokens to shift from long to short the next oracle price update.
  function shiftPositionFromLongNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external
    override
  {
    shiftPositionNextPrice(marketIndex, amountSyntheticTokensToShift, true);
  }

  /// @notice Allows users to shift their position from short to long in a single transaction. To prevent front-running these shifts are executed on the next price update from the oracle.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param amountSyntheticTokensToShift Amount in wei of synthetic tokens to shift from the short to long at the next oracle price update.
  function shiftPositionFromShortNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external
    override
  {
    shiftPositionNextPrice(marketIndex, amountSyntheticTokensToShift, false);
  }

  /*╔════════════════════════════════╗
    ║     NEXT PRICE SETTLEMENTS     ║
    ╚════════════════════════════════╝*/

  /// @notice Transfers outstanding synth tokens from a next price mint to the user.
  /// @dev The outstanding synths should already be reflected for the user due to balanceOf in SyntheticToken.sol, this just does the accounting.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param user The address of the user for whom to execute the function for.
  /// @param isLong Whether this is for the long or short synth for the market.
  function _executeOutstandingNextPriceMints(
    uint32 marketIndex,
    address user,
    bool isLong
  ) internal virtual {
    uint256 currentPaymentTokenDepositAmount = userNextPrice_paymentToken_depositAmount[
      marketIndex
    ][isLong][user];
    if (currentPaymentTokenDepositAmount > 0) {
      userNextPrice_paymentToken_depositAmount[marketIndex][isLong][user] = 0;
      uint256 amountSyntheticTokensToTransferToUser = _getAmountSyntheticToken(
        currentPaymentTokenDepositAmount,
        get_syntheticToken_priceSnapshot_side(
          marketIndex,
          isLong,
          userNextPrice_currentUpdateIndex[marketIndex][user]
        )
      );
      ISyntheticToken(syntheticTokens[marketIndex][isLong]).transfer(
        user,
        amountSyntheticTokensToTransferToUser
      );
    }
  }

  /// @notice Transfers outstanding payment tokens from a next price redemption to the user.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param user The address of the user for whom to execute the function for.
  /// @param isLong Whether this is for the long or short synth for the market.
  function _executeOutstandingNextPriceRedeems(
    uint32 marketIndex,
    address user,
    bool isLong
  ) internal virtual {
    uint256 currentSyntheticTokenRedemptions = userNextPrice_syntheticToken_redeemAmount[
      marketIndex
    ][isLong][user];
    if (currentSyntheticTokenRedemptions > 0) {
      userNextPrice_syntheticToken_redeemAmount[marketIndex][isLong][user] = 0;
      uint256 amountPaymentToken_toRedeem = _getAmountPaymentToken(
        currentSyntheticTokenRedemptions,
        get_syntheticToken_priceSnapshot_side(
          marketIndex,
          isLong,
          userNextPrice_currentUpdateIndex[marketIndex][user]
        )
      );

      IYieldManagerOriginal(yieldManagers[marketIndex]).transferPaymentTokensToUser(
        user,
        amountPaymentToken_toRedeem
      );
    }
  }

  /// @notice Transfers outstanding synth tokens from a next price position shift to the user.
  /// @dev The outstanding synths should already be reflected for the user due to balanceOf in SyntheticToken.sol, this just does the accounting.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param user The address of the user for whom to execute the function for.
  /// @param isShiftFromLong Whether the token shift was from long to short (true), or short to long (false).
  function _executeOutstandingNextPriceTokenShifts(
    uint32 marketIndex,
    address user,
    bool isShiftFromLong
  ) internal virtual {
    uint256 syntheticToken_toShiftAwayFrom_marketSide = userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[
        marketIndex
      ][isShiftFromLong][user];
    if (syntheticToken_toShiftAwayFrom_marketSide > 0) {
      uint256 syntheticToken_toShiftTowardsTargetSide = getAmountSyntheticTokenToMintOnTargetSide(
        marketIndex,
        syntheticToken_toShiftAwayFrom_marketSide,
        isShiftFromLong,
        userNextPrice_currentUpdateIndex[marketIndex][user]
      );

      userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[marketIndex][isShiftFromLong][
        user
      ] = 0;

      require(
        ISyntheticToken(syntheticTokens[marketIndex][!isShiftFromLong]).transfer(
          user,
          syntheticToken_toShiftTowardsTargetSide
        )
      );
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @dev Once the market has updated for the next price, should be guaranteed (through modifiers) to execute for a user before user initiation of new next price actions.
  /// @param user The address of the user for whom to execute the function.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  function _executeOutstandingNextPriceSettlements(address user, uint32 marketIndex)
    internal
    virtual
  {
    uint256 userCurrentUpdateIndex = userNextPrice_currentUpdateIndex[marketIndex][user];
    if (userCurrentUpdateIndex != 0 && userCurrentUpdateIndex <= marketUpdateIndex[marketIndex]) {
      _executeOutstandingNextPriceMints(marketIndex, user, true);
      _executeOutstandingNextPriceMints(marketIndex, user, false);
      _executeOutstandingNextPriceRedeems(marketIndex, user, true);
      _executeOutstandingNextPriceRedeems(marketIndex, user, false);
      _executeOutstandingNextPriceTokenShifts(marketIndex, user, true);
      _executeOutstandingNextPriceTokenShifts(marketIndex, user, false);

      userNextPrice_currentUpdateIndex[marketIndex][user] = 0;

      emit ExecuteNextPriceSettlementsUser(user, marketIndex);
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @param user The address of the user for whom to execute the function.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  function executeOutstandingNextPriceSettlementsUser(address user, uint32 marketIndex)
    external
    override
  {
    _executeOutstandingNextPriceSettlements(user, marketIndex);
  }

  /// @notice Executes outstanding next price settlements for a user for multiple markets.
  /// @param user The address of the user for whom to execute the function.
  /// @param marketIndexes An array of int32s which each uniquely identify a market.
  function executeOutstandingNextPriceSettlementsUserMulti(
    address user,
    uint32[] calldata marketIndexes
  ) external {
    uint256 length = marketIndexes.length;
    for (uint256 i = 0; i < length; i++) {
      _executeOutstandingNextPriceSettlements(user, marketIndexes[i]);
    }
  }

  /*╔═══════════════════════════════════════════╗
    ║   BATCHED NEXT PRICE SETTLEMENT ACTIONS   ║
    ╚═══════════════════════════════════════════╝*/

  /// @notice Either transfers funds from the yield manager to this contract if redeems > deposits,
  /// and vice versa. The yield manager handles depositing and withdrawing the funds from a yield market.
  /// @dev When all batched next price actions are handled the total value in the market can either increase or decrease based on the value of mints and redeems.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param totalPaymentTokenValueChangeForMarket An int256 which indicates the magnitude and direction of the change in market value.
  function _handleTotalPaymentTokenValueChangeForMarketWithYieldManager(
    uint32 marketIndex,
    int256 totalPaymentTokenValueChangeForMarket
  ) internal virtual {
    if (totalPaymentTokenValueChangeForMarket > 0) {
      IYieldManagerOriginal(yieldManagers[marketIndex]).depositPaymentToken(
        uint256(totalPaymentTokenValueChangeForMarket)
      );
    } else if (totalPaymentTokenValueChangeForMarket < 0) {
      // NB there will be issues here if not enough liquidity exists to withdraw
      // Boolean should be returned from yield manager and think how to appropriately handle this
      IYieldManagerOriginal(yieldManagers[marketIndex]).removePaymentTokenFromMarket(
        uint256(-totalPaymentTokenValueChangeForMarket)
      );
    }
  }

  /// @notice Given a desired change in synth token supply, either mints or burns tokens to achieve that desired change.
  /// @dev When all batched next price actions are executed total supply for a synth can either increase or decrease.
  /// @param marketIndex An uint32 which uniquely identifies a market.
  /// @param isLong Whether this function should execute for the long or short synth for the market.
  /// @param changeInSyntheticTokensTotalSupply The amount in wei by which synth token supply should change.
  function _handleChangeInSyntheticTokensTotalSupply(
    uint32 marketIndex,
    bool isLong,
    int256 changeInSyntheticTokensTotalSupply
  ) internal virtual {
    if (changeInSyntheticTokensTotalSupply > 0) {
      ISyntheticToken(syntheticTokens[marketIndex][isLong]).mint(
        address(this),
        uint256(changeInSyntheticTokensTotalSupply)
      );
    } else if (changeInSyntheticTokensTotalSupply < 0) {
      ISyntheticToken(syntheticTokens[marketIndex][isLong]).burn(
        uint256(-changeInSyntheticTokensTotalSupply)
      );
    }
  }

  /**
  @notice Performs all batched next price actions on an oracle price update.
  @dev Mints or burns all synthetic tokens for this contract.

    After this function is executed all user actions in that batch are confirmed and can be settled individually by
      calling _executeOutstandingNexPriceSettlements for a given user.

    The maths here is safe from rounding errors since it always over estimates on the batch with division.
      (as an example (5/3) + (5/3) = 2 but (5+5)/3 = 10/3 = 3, so the batched action would mint one more)
  @param marketIndex An uint32 which uniquely identifies a market.
  @param syntheticTokenPrice_inPaymentTokens_long The long synthetic token price for this oracle price update.
  @param syntheticTokenPrice_inPaymentTokens_short The short synthetic token price for this oracle price update.
  @return long_changeInMarketValue_inPaymentToken The total value change for the long side after all batched actions are executed.
  @return short_changeInMarketValue_inPaymentToken The total value change for the short side after all batched actions are executed.
  */
  function _batchConfirmOutstandingPendingActions(
    uint32 marketIndex,
    uint256 syntheticTokenPrice_inPaymentTokens_long,
    uint256 syntheticTokenPrice_inPaymentTokens_short
  )
    internal
    virtual
    returns (
      int256 long_changeInMarketValue_inPaymentToken,
      int256 short_changeInMarketValue_inPaymentToken
    )
  {
    int256 changeInSupply_syntheticToken_long;
    int256 changeInSupply_syntheticToken_short;

    // NOTE: the only reason we are reusing amountForCurrentAction_workingVariable for all actions (redeemLong, redeemShort, mintLong, mintShort, shiftFromLong, shiftFromShort) is to reduce stack usage
    uint256 amountForCurrentAction_workingVariable = batched_amountPaymentToken_deposit[
      marketIndex
    ][true];

    // Handle batched deposits LONG
    if (amountForCurrentAction_workingVariable > 0) {
      long_changeInMarketValue_inPaymentToken = int256(amountForCurrentAction_workingVariable);

      batched_amountPaymentToken_deposit[marketIndex][true] = 0;

      changeInSupply_syntheticToken_long = int256(
        _getAmountSyntheticToken(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_long
        )
      );
    }

    // Handle batched deposits SHORT
    amountForCurrentAction_workingVariable = batched_amountPaymentToken_deposit[marketIndex][false];
    if (amountForCurrentAction_workingVariable > 0) {
      short_changeInMarketValue_inPaymentToken = int256(amountForCurrentAction_workingVariable);

      batched_amountPaymentToken_deposit[marketIndex][false] = 0;

      changeInSupply_syntheticToken_short = int256(
        _getAmountSyntheticToken(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_short
        )
      );
    }

    // Handle shift tokens from LONG to SHORT
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_toShiftAwayFrom_marketSide[
      marketIndex
    ][true];

    if (amountForCurrentAction_workingVariable > 0) {
      int256 paymentTokenValueChangeForShiftToShort = int256(
        _getAmountPaymentToken(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_long
        )
      );

      long_changeInMarketValue_inPaymentToken -= paymentTokenValueChangeForShiftToShort;
      short_changeInMarketValue_inPaymentToken += paymentTokenValueChangeForShiftToShort;

      changeInSupply_syntheticToken_long -= int256(amountForCurrentAction_workingVariable);
      changeInSupply_syntheticToken_short += int256(
        _getEquivalentAmountSyntheticTokensOnTargetSide(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_long,
          syntheticTokenPrice_inPaymentTokens_short
        )
      );

      batched_amountSyntheticToken_toShiftAwayFrom_marketSide[marketIndex][true] = 0;
    }

    // Handle shift tokens from SHORT to LONG
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_toShiftAwayFrom_marketSide[
      marketIndex
    ][false];
    if (amountForCurrentAction_workingVariable > 0) {
      int256 paymentTokenValueChangeForShiftToLong = int256(
        _getAmountPaymentToken(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_short
        )
      );

      short_changeInMarketValue_inPaymentToken -= paymentTokenValueChangeForShiftToLong;
      long_changeInMarketValue_inPaymentToken += paymentTokenValueChangeForShiftToLong;

      changeInSupply_syntheticToken_short -= int256(amountForCurrentAction_workingVariable);
      changeInSupply_syntheticToken_long += int256(
        _getEquivalentAmountSyntheticTokensOnTargetSide(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_short,
          syntheticTokenPrice_inPaymentTokens_long
        )
      );

      batched_amountSyntheticToken_toShiftAwayFrom_marketSide[marketIndex][false] = 0;
    }

    // Handle batched redeems LONG
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_redeem[marketIndex][true];
    if (amountForCurrentAction_workingVariable > 0) {
      long_changeInMarketValue_inPaymentToken -= int256(
        _getAmountPaymentToken(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_long
        )
      );
      changeInSupply_syntheticToken_long -= int256(amountForCurrentAction_workingVariable);

      batched_amountSyntheticToken_redeem[marketIndex][true] = 0;
    }

    // Handle batched redeems SHORT
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_redeem[marketIndex][
      false
    ];
    if (amountForCurrentAction_workingVariable > 0) {
      short_changeInMarketValue_inPaymentToken -= int256(
        _getAmountPaymentToken(
          amountForCurrentAction_workingVariable,
          syntheticTokenPrice_inPaymentTokens_short
        )
      );
      changeInSupply_syntheticToken_short -= int256(amountForCurrentAction_workingVariable);

      batched_amountSyntheticToken_redeem[marketIndex][false] = 0;
    }

    // Batch settle payment tokens
    _handleTotalPaymentTokenValueChangeForMarketWithYieldManager(
      marketIndex,
      long_changeInMarketValue_inPaymentToken +
        short_changeInMarketValue_inPaymentToken +
        int256(feesToDistributeToMarketOnNextUpdate[marketIndex])
    );

    // Batch settle synthetic tokens
    _handleChangeInSyntheticTokensTotalSupply(
      marketIndex,
      true,
      changeInSupply_syntheticToken_long
    );

    _handleChangeInSyntheticTokensTotalSupply(
      marketIndex,
      false,
      changeInSupply_syntheticToken_short
    );
  }

  // Upgrade helper:
  function upgradeToUsingCompactValueAndPriceSnapshots() public {
    // If this function has alreday been called this value will not be 0!
    if (marketSideValueInPaymentToken[1].value_long == 0) {
      for (uint32 market = 1; market <= latestMarket; market++) {
        marketSideValueInPaymentToken[market] = MarketSideValueInPaymentToken(
          SafeCast.toUint128(marketSideValueInPaymentTokenLEGACY[market][true]),
          SafeCast.toUint128(marketSideValueInPaymentTokenLEGACY[market][false])
        );
      }
    }
    emit Upgrade(1);
  }
}

contract LongShortPolygon is LongShortFeesAmend {
  /// @dev This contract uses legacy data.
  function HAS_LEGACY_DATA() internal pure override returns (bool) {
    return true;
  }

  /// @dev This is the amount of time users need to wait between trades.
  function CONTRACT_SLOW_TRADE_TIME() internal pure override returns (uint256) {
    return 2 hours;
  }

  // auto initialize implementation
  constructor() initializer {}
}