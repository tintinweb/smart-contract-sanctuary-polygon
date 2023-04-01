// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

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
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IForwarder {

  function tokenPerDestinationLength(address destination) external view returns (uint);

  function tokenPerDestinationAt(address destination, uint i) external view returns (address);

  function registerIncome(
    address[] memory tokens,
    uint[] memory amounts,
    address vault,
    bool isDistribute
  ) external;

  function distributeAll(address destination) external;

  function distribute(address token) external;

  function setInvestFundRatio(uint value) external;

  function setGaugesRatio(uint value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITetuLiquidator {

  struct PoolData {
    address pool;
    address swapper;
    address tokenIn;
    address tokenOut;
  }

  function addLargestPools(PoolData[] memory _pools, bool rewrite) external;

  function addBlueChipsPools(PoolData[] memory _pools, bool rewrite) external;

  function getPrice(address tokenIn, address tokenOut, uint amount) external view returns (uint);

  function getPriceForRoute(PoolData[] memory route, uint amount) external view returns (uint);

  function isRouteExist(address tokenIn, address tokenOut) external view returns (bool);

  function buildRoute(
    address tokenIn,
    address tokenOut
  ) external view returns (PoolData[] memory route, string memory errorMessage);

  function liquidate(
    address tokenIn,
    address tokenOut,
    uint amount,
    uint slippage
  ) external;

  function liquidateWithRoute(
    PoolData[] memory route,
    uint amount,
    uint slippage
  ) external;


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IVaultInsurance.sol";
import "./IERC20.sol";

interface ITetuVaultV2 {

  function depositFee() external view returns (uint);

  function withdrawFee() external view returns (uint);

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity 0.8.17;

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
    return a > b ? a : b;
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
    require(denominator > prod1, "Math: mulDiv overflow");

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
   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1 << (log2(a) >> 1);

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
  unchecked {
    uint256 result = sqrt(a);
    return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 128;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 64;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 32;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 16;
    }
    if (value >> 8 > 0) {
      value >>= 8;
      result += 8;
    }
    if (value >> 4 > 0) {
      value >>= 4;
      result += 4;
    }
    if (value >> 2 > 0) {
      value >>= 2;
      result += 2;
    }
    if (value >> 1 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log2(value);
    return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >= 10**64) {
      value /= 10**64;
      result += 64;
    }
    if (value >= 10**32) {
      value /= 10**32;
      result += 32;
    }
    if (value >= 10**16) {
      value /= 10**16;
      result += 16;
    }
    if (value >= 10**8) {
      value /= 10**8;
      result += 8;
    }
    if (value >= 10**4) {
      value /= 10**4;
      result += 4;
    }
    if (value >= 10**2) {
      value /= 10**2;
      result += 2;
    }
    if (value >= 10**1) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log10(value);
    return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
  }
  }

  /**
   * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
  function log256(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
  unchecked {
    if (value >> 128 > 0) {
      value >>= 128;
      result += 16;
    }
    if (value >> 64 > 0) {
      value >>= 64;
      result += 8;
    }
    if (value >> 32 > 0) {
      value >>= 32;
      result += 4;
    }
    if (value >> 16 > 0) {
      value >>= 16;
      result += 2;
    }
    if (value >> 8 > 0) {
      result += 1;
    }
  }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
  unchecked {
    uint256 result = log256(value);
    return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
  }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

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
    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/SafeERC20.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/ISplitter.sol";

library StrategyLib {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Denominator for fee calculation.
  uint internal constant FEE_DENOMINATOR = 100_000;

  // *************************************************************
  //                        ERRORS
  // *************************************************************

  string internal constant DENIED = "SB: Denied";
  string internal constant TOO_HIGH = "SB: Too high";
  string internal constant WRONG_VALUE = "SB: Wrong value";

  // *************************************************************
  //                     RESTRICTIONS
  // *************************************************************

  /// @dev Restrict access only for operators
  function onlyOperators(address controller) external view {
    require(IController(controller).isOperator(msg.sender), DENIED);
  }

  /// @dev Restrict access only for governance
  function onlyGovernance(address controller) external view {
    require(IController(controller).governance() == msg.sender, DENIED);
  }

  /// @dev Restrict access only for platform voter
  function onlyPlatformVoter(address controller) external view {
    require(IController(controller).platformVoter() == msg.sender, DENIED);
  }

  /// @dev Restrict access only for splitter
  function onlySplitter(address splitter) external view {
    require(splitter == msg.sender, DENIED);
  }

  // *************************************************************
  //                       HELPERS
  // *************************************************************

  /// @notice Calculate withdrawn amount in USD using the {assetPrice}.
  ///         Revert if the amount is different from expected too much (high price impact)
  /// @param balanceBefore Asset balance of the strategy before withdrawing
  /// @param investedAssetsUSD Expected amount in USD, decimals are same to {_asset}
  /// @param assetPrice Price of the asset, decimals 18
  /// @return balance Current asset balance of the strategy
  function checkWithdrawImpact(
    address _asset,
    uint balanceBefore,
    uint investedAssetsUSD,
    uint assetPrice,
    address _splitter
  ) external view returns (uint balance) {
    balance = IERC20(_asset).balanceOf(address(this));
    if (assetPrice != 0 && investedAssetsUSD != 0) {

      uint withdrew = balance > balanceBefore ? balance - balanceBefore : 0;
      uint withdrewUSD = withdrew * assetPrice / 1e18;
      uint priceChangeTolerance = ITetuVaultV2(ISplitter(_splitter).vault()).withdrawFee();
      uint difference = investedAssetsUSD > withdrewUSD ? investedAssetsUSD - withdrewUSD : 0;

      require(difference * FEE_DENOMINATOR / investedAssetsUSD <= priceChangeTolerance, TOO_HIGH);
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Keep and provide addresses of all application contracts
interface IConverterController {
  function governance() external view returns (address);

  /// ********************* Health factor explanation  ****************
  /// For example, a landing platform has: liquidity threshold = 0.85, LTV=0.8, LTV / LT = 1.0625
  /// For collateral $100 we can borrow $80. A liquidation happens if the cost of collateral will reduce below $85.
  /// We set min-health-factor = 1.1, target-health-factor = 1.3
  /// For collateral 100 we will borrow 100/1.3 = 76.92
  ///
  /// Collateral value   100        77            assume that collateral value is decreased at 100/77=1.3 times
  /// Collateral * LT    85         65.45
  /// Borrow value       65.38      65.38         but borrow value is the same as before
  /// Health factor      1.3        1.001         liquidation almost happens here (!)
  ///
  /// So, if we have target factor 1.3, it means, that if collateral amount will decreases at 1.3 times
  /// and the borrow value won't change at the same time, the liquidation happens at that point.
  /// Min health factor marks the point at which a rebalancing must be made asap.
  /// *****************************************************************

  /// @notice min allowed health factor with decimals 2, must be >= 1e2
  function minHealthFactor2() external view returns (uint16);
  function setMinHealthFactor2(uint16 value_) external;

  /// @notice target health factor with decimals 2
  /// @dev If the health factor is below/above min/max threshold, we need to make repay
  ///      or additional borrow and restore the health factor to the given target value
  function targetHealthFactor2() external view returns (uint16);
  function setTargetHealthFactor2(uint16 value_) external;

  /// @notice max allowed health factor with decimals 2
  /// @dev For future versions, currently max health factor is not used
  function maxHealthFactor2() external view returns (uint16);
  /// @dev For future versions, currently max health factor is not used
  function setMaxHealthFactor2(uint16 value_) external;

  /// @notice get current value of blocks per day. The value is set manually at first and can be auto-updated later
  function blocksPerDay() external view returns (uint);
  /// @notice set value of blocks per day manually and enable/disable auto update of this value
  function setBlocksPerDay(uint blocksPerDay_, bool enableAutoUpdate_) external;
  /// @notice Check if it's time to call updateBlocksPerDay()
  /// @param periodInSeconds_ Period of auto-update in seconds
  function isBlocksPerDayAutoUpdateRequired(uint periodInSeconds_) external view returns (bool);
  /// @notice Recalculate blocksPerDay value
  /// @param periodInSeconds_ Period of auto-update in seconds
  function updateBlocksPerDay(uint periodInSeconds_) external;

  /// @notice 0 - new borrows are allowed, 1 - any new borrows are forbidden
  function paused() external view returns (bool);

  /// @notice the given user is whitelisted and is allowed to make borrow/swap using TetuConverter
  function isWhitelisted(address user_) external view returns (bool);

  ///////////////////////////////////////////////////////
  ///        Core application contracts
  ///////////////////////////////////////////////////////

  function tetuConverter() external view returns (address);
  function borrowManager() external view returns (address);
  function debtMonitor() external view returns (address);
  function tetuLiquidator() external view returns (address);
  function swapManager() external view returns (address);
  function priceOracle() external view returns (address);

  ///////////////////////////////////////////////////////
  ///        External contracts
  ///////////////////////////////////////////////////////
  /// @notice A keeper to control health and efficiency of the borrows
  function keeper() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceOracle {
  /// @notice Return asset price in USD, decimals 18
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IConverterController.sol";

/// @notice Main contract of the TetuConverter application
/// @dev Borrower (strategy) makes all operations via this contract only.
interface ITetuConverter {

  function controller() external view returns (IConverterController);

  /// @notice Find possible borrow strategies and provide "cost of money" as interest for the period for each strategy
  ///         Result arrays of the strategy are ordered in ascending order of APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converters Array of available converters ordered in ascending order of APR.
  ///                    Each item contains a result contract that should be used for conversion; it supports IConverter
  ///                    This address should be passed to borrow-function during conversion.
  ///                    The length of array is always equal to the count of available lending platforms.
  ///                    Last items in array can contain zero addresses (it means they are not used)
  /// @return collateralAmountsOut Amounts that should be provided as a collateral
  /// @return amountToBorrowsOut Amounts that should be borrowed
  ///                            This amount is not zero if corresponded converter is not zero.
  /// @return aprs18 Interests on the use of {amountIn_} during the given period, decimals 18
  function findBorrowStrategies(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external view returns (
    address[] memory converters,
    uint[] memory collateralAmountsOut,
    uint[] memory amountToBorrowsOut,
    int[] memory aprs18
  );

  /// @notice Find best swap strategy and provide "cost of money" as interest for the period
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @return converter Result contract that should be used for conversion to be passed to borrow()
  /// @return sourceAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                         It can be different from the {sourceAmount_} for some entry kinds.
  /// @return targetAmountOut Result amount of {targetToken_} after swap
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findSwapStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_
  ) external returns (
    address converter,
    uint sourceAmountOut,
    uint targetAmountOut,
    int apr18
  );

  /// @notice Find best conversion strategy (swap or borrow) and provide "cost of money" as interest for the period.
  ///         It calls both findBorrowStrategy and findSwapStrategy and selects a best strategy.
  /// @dev This is writable function with read-only behavior.
  ///      It should be writable to be able to simulate real swap and get a real APR for swapping.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 is used by default
  /// @param amountIn_  The meaning depends on entryData
  ///                   For entryKind=0 it's max available amount of collateral
  ///                   This amount must be approved to TetuConverter before the call.
  ///                   For entryKind=2 we don't know amount of collateral before the call,
  ///                   so it's necessary to approve large enough amount (or make infinity approve)
  /// @param periodInBlocks_ Estimated period to keep target amount. It's required to compute APR
  /// @return converter Result contract that should be used for conversion to be passed to borrow().
  /// @return collateralAmountOut Amount of {sourceToken_} that should be swapped to get {targetToken_}
  ///                             It can be different from the {sourceAmount_} for some entry kinds.
  /// @return amountToBorrowOut Result amount of {targetToken_} after conversion
  /// @return apr18 Interest on the use of {outMaxTargetAmount} during the given period, decimals 18
  function findConversionStrategy(
    bytes memory entryData_,
    address sourceToken_,
    uint amountIn_,
    address targetToken_,
    uint periodInBlocks_
  ) external returns (
    address converter,
    uint collateralAmountOut,
    uint amountToBorrowOut,
    int apr18
  );

  /// @notice Convert {collateralAmount_} to {amountToBorrow_} using {converter_}
  ///         Target amount will be transferred to {receiver_}. No re-balancing here.
  /// @dev Transferring of {collateralAmount_} by TetuConverter-contract must be approved by the caller before the call
  ///      Only whitelisted users are allowed to make borrows
  /// @param converter_ A converter received from findBestConversionStrategy.
  /// @param collateralAmount_ Amount of {collateralAsset_} to be converted.
  ///                          This amount must be approved to TetuConverter before the call.
  /// @param amountToBorrow_ Amount of {borrowAsset_} to be borrowed and sent to {receiver_}
  /// @param receiver_ A receiver of borrowed amount
  /// @return borrowedAmountOut Exact borrowed amount transferred to {receiver_}
  function borrow(
    address converter_,
    address collateralAsset_,
    uint collateralAmount_,
    address borrowAsset_,
    uint amountToBorrow_,
    address receiver_
  ) external returns (
    uint borrowedAmountOut
  );

  /// @notice Full or partial repay of the borrow
  /// @dev A user should transfer {amountToRepay_} to TetuConverter before calling repay()
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  ///                       You can know exact total amount of debt using {getStatusCurrent}.
  ///                       if the amount exceed total amount of the debt:
  ///                       - the debt will be fully repaid
  ///                       - remain amount will be swapped from {borrowAsset_} to {collateralAsset_}
  /// @param receiver_ A receiver of the collateral that will be withdrawn after the repay
  ///                  The remained amount of borrow asset will be returned to the {receiver_} too
  /// @return collateralAmountOut Exact collateral amount transferred to {collateralReceiver_}
  ///         If TetuConverter is not able to make the swap, it reverts
  /// @return returnedBorrowAmountOut A part of amount-to-repay that wasn't converted to collateral asset
  ///                                 because of any reasons (i.e. there is no available conversion strategy)
  ///                                 This amount is returned back to the collateralReceiver_
  /// @return swappedLeftoverCollateralOut A part of collateral received through the swapping
  /// @return swappedLeftoverBorrowOut A part of amountToRepay_ that was swapped
  function repay(
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_,
    address receiver_
  ) external returns (
    uint collateralAmountOut,
    uint returnedBorrowAmountOut,
    uint swappedLeftoverCollateralOut,
    uint swappedLeftoverBorrowOut
  );

  /// @notice Estimate result amount after making full or partial repay
  /// @dev It works in exactly same way as repay() but don't make actual repay
  ///      Anyway, the function is write, not read-only, because it makes updateStatus()
  /// @param user_ user whose amount-to-repay will be calculated
  /// @param amountToRepay_ Amount of borrowed asset to repay.
  /// @return collateralAmountOut Total collateral amount to be returned after repay in exchange of {amountToRepay_}
  function quoteRepay(
    address user_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountToRepay_
  ) external returns (
    uint collateralAmountOut
  );

  /// @notice Update status in all opened positions
  ///         and calculate exact total amount of borrowed and collateral assets
  /// @param user_ user whose debts will be updated and returned
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountCurrent(
    address user_,
    address collateralAsset_,
    address borrowAsset_
  ) external returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice Total amount of borrow tokens that should be repaid to close the borrow completely.
  /// @dev Actual debt amount can be a little LESS then the amount returned by this function.
  ///      I.e. AAVE's pool adapter returns (amount of debt + tiny addon ~ 1 cent)
  ///      The addon is required to workaround dust-tokens problem.
  ///      After repaying the remaining amount is transferred back on the balance of the caller strategy.
  /// @param user_ user whose debts will be returned
  /// @return totalDebtAmountOut Borrowed amount that should be repaid to pay off the loan in full
  /// @return totalCollateralAmountOut Amount of collateral that should be received after paying off the loan
  function getDebtAmountStored(
    address user_,
    address collateralAsset_,
    address borrowAsset_
  ) external view returns (
    uint totalDebtAmountOut,
    uint totalCollateralAmountOut
  );

  /// @notice User needs to redeem some collateral amount. Calculate an amount of borrow token that should be repaid
  /// @param user_ user whose debts will be returned
  /// @param collateralAmountRequired_ Amount of collateral required by the user
  /// @return borrowAssetAmount Borrowed amount that should be repaid to receive back following amount of collateral:
  ///                           amountToReceive = collateralAmountRequired_ - unobtainableCollateralAssetAmount
  /// @return unobtainableCollateralAssetAmount A part of collateral that cannot be obtained in any case
  ///                                           even if all borrowed amount will be returned.
  ///                                           If this amount is not 0, you ask to get too much collateral.
  function estimateRepay(
    address user_,
    address collateralAsset_,
    uint collateralAmountRequired_,
    address borrowAsset_
  ) external view returns (
    uint borrowAssetAmount,
    uint unobtainableCollateralAssetAmount
  );

  /// @notice Transfer all reward tokens to {receiver_}
  /// @return rewardTokensOut What tokens were transferred. Same reward token can appear in the array several times
  /// @return amountsOut Amounts of transferred rewards, the array is synced with {rewardTokens}
  function claimRewards(address receiver_) external returns (
    address[] memory rewardTokensOut,
    uint[] memory amountsOut
  );

  /// @notice Swap {amountIn_} of {assetIn_} to {assetOut_} and send result amount to {receiver_}
  ///         The swapping is made using TetuLiquidator with checking price impact using embedded price oracle.
  /// @param amountIn_ Amount of {assetIn_} to be swapped.
  ///                      It should be transferred on balance of the TetuConverter before the function call
  /// @param receiver_ Result amount will be sent to this address
  /// @param priceImpactToleranceSource_ Price impact tolerance for liquidate-call, decimals = 100_000
  /// @param priceImpactToleranceTarget_ Price impact tolerance for price-oracle-check, decimals = 100_000
  /// @return amountOut The amount of {assetOut_} that has been sent to the receiver
  function safeLiquidate(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    address receiver_,
    uint priceImpactToleranceSource_,
    uint priceImpactToleranceTarget_
  ) external returns (
    uint amountOut
  );

  /// @notice Check if {amountOut_} is too different from the value calculated directly using price oracle prices
  /// @return Price difference is ok for the given {priceImpactTolerance_}
  function isConversionValid(
    address assetIn_,
    uint amountIn_,
    address assetOut_,
    uint amountOut_,
    uint priceImpactTolerance_
  ) external view returns (bool);

  /// @notice Close given borrow and return collateral back to the user, governance only
  /// @dev The pool adapter asks required amount-to-repay from the user internally
  /// @param poolAdapter_ The pool adapter that represents the borrow
  /// @param closePosition Close position after repay
  ///        Usually it should be true, because the function always tries to repay all debt
  ///        false can be used if user doesn't have enough amount to pay full debt
  ///              and we are trying to pay "as much as possible"
  /// @return collateralAmountOut Amount of collateral returned to the user
  /// @return repaidAmountOut Amount of borrow asset repaid to the lending platform
  function repayTheBorrow(address poolAdapter_, bool closePosition) external returns (
    uint collateralAmountOut,
    uint repaidAmountOut
  );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import './IUniswapV3PoolImmutables.sol';
import './IUniswapV3PoolState.sol';
import './IUniswapV3PoolDerivedState.sol';
import './IUniswapV3PoolActions.sol';
import './IUniswapV3PoolOwnerActions.sol';
import './IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
IUniswapV3PoolImmutables,
IUniswapV3PoolState,
IUniswapV3PoolDerivedState,
IUniswapV3PoolActions,
IUniswapV3PoolOwnerActions,
IUniswapV3PoolEvents
{}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
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
  returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
  /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
  /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  event Initialize(uint160 sqrtPriceX96, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @param sender The address that minted the liquidity
  /// @param owner The owner of the position and recipient of any minted liquidity
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount The amount of liquidity minted to the position range
  /// @param amount0 How much token0 was required for the minted liquidity
  /// @param amount1 How much token1 was required for the minted liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when fees are collected by the owner of a position
  /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
  /// @param owner The owner of the position for which fees are collected
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount0 The amount of token0 fees collected
  /// @param amount1 The amount of token1 fees collected
  event Collect(
    address indexed owner,
    address recipient,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount0,
    uint128 amount1
  );

  /// @notice Emitted when a position's liquidity is removed
  /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
  /// @param owner The owner of the position for which liquidity is removed
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount The amount of liquidity to remove
  /// @param amount0 The amount of token0 withdrawn
  /// @param amount1 The amount of token1 withdrawn
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 amount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted by the pool for any swaps between token0 and token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the output of the swap
  /// @param amount0 The delta of the token0 balance of the pool
  /// @param amount1 The delta of the token1 balance of the pool
  /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param liquidity The liquidity of the pool after the swap
  /// @param tick The log base 1.0001 of price of the pool after the swap
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 amount0,
    int256 amount1,
    uint160 sqrtPriceX96,
    uint128 liquidity,
    int24 tick
  );

  /// @notice Emitted by the pool for any flashes of token0/token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the tokens from flash
  /// @param amount0 The amount of token0 that was flashed
  /// @param amount1 The amount of token1 that was flashed
  /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
  /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 amount0,
    uint256 amount1,
    uint256 paid0,
    uint256 paid1
  );

  /// @notice Emitted by the pool for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(
    uint16 observationCardinalityNextOld,
    uint16 observationCardinalityNextNew
  );

  /// @notice Emitted when the protocol fee is changed by the pool
  /// @param feeProtocol0Old The previous value of the token0 protocol fee
  /// @param feeProtocol1Old The previous value of the token1 protocol fee
  /// @param feeProtocol0New The updated value of the token0 protocol fee
  /// @param feeProtocol1New The updated value of the token1 protocol fee
  event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

  /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
  /// @param sender The address that collects the protocol fees
  /// @param recipient The address that receives the collected protocol fees
  /// @param amount0 The amount of token0 protocol fees that is withdrawn
  /// @param amount0 The amount of token1 protocol fees that is withdrawn
  event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
  /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
  /// @return The contract address
  function factory() external view returns (address);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
  /// @return The fee
  function fee() external view returns (uint24);

  /// @notice The pool tick spacing
  /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
  /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The tick spacing
  function tickSpacing() external view returns (int24);

  /// @notice The maximum amount of position liquidity that can use any tick in the range
  /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
  /// @notice Set the denominator of the protocol's % share of the fees
  /// @param feeProtocol0 new protocol fee for token0 of the pool
  /// @param feeProtocol1 new protocol fee for token1 of the pool
  function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

  /// @notice Collect the protocol fee accrued to the pool
  /// @param recipient The address to which collected protocol fees should be sent
  /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
  /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
  /// @return amount0 The protocol fee collected in token0
  /// @return amount1 The protocol fee collected in token1
  function collectProtocol(
    address recipient,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice List of all errors generated by the application
///         Each error should have unique code TS-XXX and descriptive comment
library AppErrors {
  /// @notice Provided address should be not zero
  string public constant ZERO_ADDRESS = "TS-1 zero address";

  /// @notice A pair of the tokens cannot be found in the factory of uniswap pairs
  string public constant UNISWAP_PAIR_NOT_FOUND = "TS-2 pair not found";

  /// @notice Lengths not matched
  string public constant WRONG_LENGTHS = "TS-4 wrong lengths";

  /// @notice Unexpected zero balance
  string public constant ZERO_BALANCE = "TS-5 zero balance";

  string public constant ITEM_NOT_FOUND = "TS-6 not found";

  string public constant NOT_ENOUGH_BALANCE = "TS-7 not enough balance";

  /// @notice Price oracle returns zero price
  string public constant ZERO_PRICE = "TS-8 zero price";

  string public constant WRONG_VALUE = "TS-9 wrong value";

  /// @notice TetuConvertor wasn't able to make borrow, i.e. borrow-strategy wasn't found
  string public constant ZERO_AMOUNT_BORROWED = "TS-10 zero borrowed amount";

  string public constant WITHDRAW_TOO_MUCH = "TS-11 try to withdraw too much";

  string public constant UNKNOWN_ENTRY_KIND = "TS-12 unknown entry kind";

  string public constant ONLY_TETU_CONVERTER = "TS-13 only TetuConverter";

  string public constant WRONG_ASSET = "TS-14 wrong asset";

  string public constant NO_LIQUIDATION_ROUTE = "TS-15 No liquidation route";

  string public constant PRICE_IMPACT = "TS-16 price impact";

  /// @notice tetuConverter_.repay makes swap internally. It's not efficient and not allowed
  string public constant REPAY_MAKES_SWAP = "TS-17 can not convert back";

  string public constant NO_INVESTMENTS = "TS-18 no investments";

  string public constant INCORRECT_LENGTHS = "TS-19 lengths";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

/// @notice Common internal utils
library AppLib {
  using SafeERC20 for IERC20;

  /// @notice Unchecked increment for for-cycles
  function uncheckedInc(uint i) internal pure returns (uint) {
  unchecked {
    return i + 1;
  }
  }

  /// @notice Make infinite approve of {token} to {spender} if the approved amount is less than {amount}
  /// @dev Should NOT be used for third-party pools
  function approveIfNeeded(address token, uint amount, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      // infinite approve, 2*255 is more gas efficient then type(uint).max
      IERC20(token).safeApprove(spender, 2 ** 255);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Utils and constants related to entryKind param of ITetuConverter.findBorrowStrategy
library ConverterEntryKinds {
  /// @notice Amount of collateral is fixed. Amount of borrow should be max possible.
  uint constant public ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0 = 0;

  /// @notice Split provided source amount S on two parts: C1 and C2 (C1 + C2 = S)
  ///         C2 should be used as collateral to make a borrow B.
  ///         Results amounts of C1 and B (both in terms of USD) must be in the given proportion
  uint constant public ENTRY_KIND_EXACT_PROPORTION_1 = 1;

  /// @notice Borrow given amount using min possible collateral
  uint constant public ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2 = 2;

  /// @notice Decode entryData, extract first uint - entry kind
  ///         Valid values of entry kinds are given by ENTRY_KIND_XXX constants above
  function getEntryKind(bytes memory entryData_) internal pure returns (uint) {
    if (entryData_.length == 0) {
      return ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0;
    }
    return abi.decode(entryData_, (uint));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppErrors.sol";

/// @title Library for clearing / joining token addresses & amounts arrays
/// @author bogdoslav
library TokenAmountsLib {

  function uncheckedInc(uint i) internal pure returns (uint) {
  unchecked {
    return i + 1;
  }
  }

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string internal constant TOKEN_AMOUNTS_LIB_VERSION = "1.0.0";

  function filterZeroAmounts(
    address[] memory tokens,
    uint[] memory amounts
  ) internal pure returns (
    address[] memory t,
    uint[] memory a
  ) {
    require(tokens.length == amounts.length, 'TAL: Arrays mismatch');
    uint len2 = 0;
    uint len = tokens.length;
    for (uint i = 0; i < len; i++) {
      if (amounts[i] != 0) len2++;
    }

    t = new address[](len2);
    a = new uint[](len2);

    uint j = 0;
    for (uint i = 0; i < len; i++) {
      uint amount = amounts[i];
      if (amount != 0) {
        t[j] = tokens[i];
        a[j] = amount;
        j++;
      }
    }
  }

  /// @notice unites three arrays to single array without duplicates, amounts are sum, zero amounts are allowed
  function combineArrays(
    address[] memory tokens0,
    uint[] memory amounts0,
    address[] memory tokens1,
    uint[] memory amounts1,
    address[] memory tokens2,
    uint[] memory amounts2
  ) internal pure returns (
    address[] memory allTokens,
    uint[] memory allAmounts
  ) {
    uint[] memory lens = new uint[](3);
    lens[0] = tokens0.length;
    lens[1] = tokens1.length;
    lens[2] = tokens2.length;

    require(
      lens[0] == amounts0.length && lens[1] == amounts1.length && lens[2] == amounts2.length,
      AppErrors.INCORRECT_LENGTHS
    );

    uint maxLength = lens[0] + lens[1] + lens[2];
    address[] memory tokensOut = new address[](maxLength);
    uint[] memory amountsOut = new uint[](maxLength);
    uint unitedLength;

    for (uint step; step < 3; ++step) {
      uint[] memory amounts = step == 0
        ? amounts0
        : (step == 1
          ? amounts1
          : amounts2);
      address[] memory tokens = step == 0
        ? tokens0
        : (step == 1
          ? tokens1
          : tokens2);
      for (uint i1 = 0; i1 < lens[step]; i1++) {
        uint amount1 = amounts[i1];
        address token1 = tokens[i1];
        bool united = false;

        for (uint i = 0; i < unitedLength; i++) {
          if (token1 == tokensOut[i]) {
            amountsOut[i] += amount1;
            united = true;
            break;
          }
        }

        if (!united) {
          tokensOut[unitedLength] = token1;
          amountsOut[unitedLength] = amount1;
          unitedLength++;
        }
      }
    }

    // copy united tokens to result array
    allTokens = new address[](unitedLength);
    allAmounts = new uint[](unitedLength);
    for (uint i; i < unitedLength; i++) {
      allTokens[i] = tokensOut[i];
      allAmounts[i] = amountsOut[i];
    }

  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ITetuLiquidator.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IForwarder.sol";
import "@tetu_io/tetu-contracts-v2/contracts/strategy/StrategyLib.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/Math.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/IPriceOracle.sol";
import "@tetu_io/tetu-converter/contracts/interfaces/ITetuConverter.sol";
import "../libs/AppErrors.sol";
import "../libs/AppLib.sol";
import "../libs/TokenAmountsLib.sol";
import "../libs/ConverterEntryKinds.sol";

library ConverterStrategyBaseLib {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///                        DATA TYPES
  /////////////////////////////////////////////////////////////////////
  /// @notice Local vars for {_recycle}, workaround for stack too deep
  struct RecycleLocalParams {
    uint amountToCompound;
    uint amountToForward;
    address rewardToken;
    uint liquidationThresholdAsset;
    uint len;
    uint baseAmountIn;
    uint totalRewardAmounts;
    uint spentAmountIn;
    uint receivedAmountOut;
  }

  struct OpenPositionLocal {
    uint entryKind;
    address[] converters;
    uint[] collateralsRequired;
    uint[] amountsToBorrow;
    uint collateral;
    uint amountToBorrow;
  }

  struct OpenPositionEntryKind1Local {
    address[] converters;
    uint[] collateralsRequired;
    uint[] amountsToBorrow;
    uint collateral;
    uint amountToBorrow;
    uint c1;
    uint c3;
    uint ratio;
    uint alpha;
  }

  struct CalcInvestedAssetsLocal {
    uint len;
    uint[] prices;
    uint[] decs;
    uint[] debts;
  }

  struct ConvertAfterWithdrawLocalParams {
    address asset;
    uint collateral;
    uint spentAmountIn;
    uint receivedAmountOut;
  }

  struct SwapToGivenAmountInputParams {
    uint targetAmount;
    address[] tokens;
    uint indexTargetAsset;
    address underlying;
    uint[] amounts;
    ITetuConverter converter;
    ITetuLiquidator liquidator;
    uint liquidationThresholdForTargetAsset;
    /// @notice Allow to swap more then required (i.e. 1_000 => +1%)
    ///         to avoid additional swap if the swap return amount a bit less than we expected
    uint overswap;
  }

  struct SwapToGivenAmountLocal {
    uint len;
    uint[] availableAmounts;
    uint[] receivedAmounts;
    uint i;
  }

  /////////////////////////////////////////////////////////////////////
  ///                        Constants
  /////////////////////////////////////////////////////////////////////

  /// @notice approx one month for average block time 2 sec
  uint internal constant _LOAN_PERIOD_IN_BLOCKS = 30 days / 2;
  uint internal constant _REWARD_LIQUIDATION_SLIPPAGE = 5_000; // 5%
  uint internal constant COMPOUND_DENOMINATOR = 100_000;
  uint internal constant DENOMINATOR = 100_000;
  uint internal constant _ASSET_LIQUIDATION_SLIPPAGE = 300;
  uint internal constant PRICE_IMPACT_TOLERANCE = 300;
  /// @notice borrow/collateral amount cannot be less than given number of tokens
  uint internal constant DEFAULT_OPEN_POSITION_AMOUNT_IN_THRESHOLD = 10;
  /// @notice Allow to swap more then required (i.e. 1_000 => +1%) inside {swapToGivenAmount}
  ///         to avoid additional swap if the swap will return amount a bit less than we expected
  uint internal constant OVERSWAP = PRICE_IMPACT_TOLERANCE + _ASSET_LIQUIDATION_SLIPPAGE;

  /////////////////////////////////////////////////////////////////////
  ///                         Events
  /////////////////////////////////////////////////////////////////////
  /// @notice A borrow was made
  event OpenPosition(
    address converter,
    address collateralAsset,
    uint collateralAmount,
    address borrowAsset,
    uint borrowedAmount,
    address recepient
  );

  /// @notice Some borrow(s) was/were repaid
  event ClosePosition(
    address collateralAsset,
    address borrowAsset,
    uint amountRepay,
    address recepient,
    uint returnedAssetAmountOut,
    uint returnedBorrowAmountOut
  );

  /// @notice A liquidation was made
  event Liquidation(
    address tokenIn,
    address tokenOut,
    uint amountIn,
    uint spentAmountIn,
    uint receivedAmountOut
  );

  /////////////////////////////////////////////////////////////////////
  ///                      View functions
  /////////////////////////////////////////////////////////////////////

  /// @notice Get amount of assets that we expect to receive after withdrawing
  ///         ratio = amount-LP-tokens-to-withdraw / total-amount-LP-tokens-in-pool
  /// @param reserves_ Reserves of the {poolAssets_}, same order, same length (we don't check it)
  ///                  The order of tokens should be same as in {_depositorPoolAssets()},
  ///                  one of assets must be {asset_}
  /// @param liquidityAmount_ Amount of LP tokens that we are going to withdraw
  /// @param totalSupply_ Total amount of LP tokens in the depositor
  /// @return withdrawnAmountsOut Expected withdrawn amounts (decimals == decimals of the tokens)
  function getExpectedWithdrawnAmounts(
    uint[] memory reserves_,
    uint liquidityAmount_,
    uint totalSupply_
  ) internal pure returns (
    uint[] memory withdrawnAmountsOut
  ) {
    uint ratio = totalSupply_ == 0
      ? 0
      : (liquidityAmount_ >= totalSupply_
        ? 1e18
        : 1e18 * liquidityAmount_ / totalSupply_
    );
    // we need brackets here for npm.run.coverage

    uint len = reserves_.length;
    withdrawnAmountsOut = new uint[](len);

    if (ratio != 0) {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        withdrawnAmountsOut[i] = reserves_[i] * ratio / 1e18;
      }
    }
  }

  /// @notice For each {token_} calculate a part of {amount_} to be used as collateral according to the weights.
  ///         I.e. we have 300 USDC, we need to split it on 100 USDC, 100 USDT, 100 DAI
  ///         USDC is main asset, USDT and DAI should be borrowed. We check amounts of USDT and DAI on the balance
  ///         and return collaterals reduced on that amounts. For main asset, we return full amount always (100 USDC).
  function getCollaterals(
    uint amount_,
    address[] memory tokens_,
    uint[] memory weights_,
    uint totalWeight_,
    uint indexAsset_,
    IPriceOracle priceOracle,
    mapping(address => uint) storage baseAmounts_
  ) external view returns (
    uint[] memory tokenAmountsOut
  ) {
    uint len = tokens_.length;
    tokenAmountsOut = new uint[](len);

    // get token prices and decimals
    (uint[] memory prices, uint[] memory decs) = _getPricesAndDecs(priceOracle, tokens_, len);

    // split the amount on tokens proportionally to the weights
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      uint amountAssetForToken = amount_ * weights_[i] / totalWeight_;

      if (i == indexAsset_) {
        tokenAmountsOut[i] = amountAssetForToken;
      } else {
        // if we have some tokens on balance then we need to use only a part of the collateral
        uint tokenAmountToBeBorrowed = amountAssetForToken
        * prices[indexAsset_]
        * decs[i]
        / prices[i]
        / decs[indexAsset_];

        uint tokenBalance = baseAmounts_[tokens_[i]];
        if (tokenBalance < tokenAmountToBeBorrowed) {
          tokenAmountsOut[i] = amountAssetForToken * (tokenAmountToBeBorrowed - tokenBalance) / tokenAmountToBeBorrowed;
        }
      }
    }
  }

  /// @return prices Prices with decimals 18
  /// @return decs 10**decimals
  function _getPricesAndDecs(IPriceOracle priceOracle, address[] memory tokens_, uint len) internal view returns (
    uint[] memory prices,
    uint[] memory decs
  ) {
    prices = new uint[](len);
    decs = new uint[](len);
    {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        decs[i] = 10 ** IERC20Metadata(tokens_[i]).decimals();
        prices[i] = priceOracle.getAssetPrice(tokens_[i]);
      }
    }
  }

  /// @notice Find index of the given {asset_} in array {tokens_}, return type(uint).max if not found
  function getAssetIndex(address[] memory tokens_, address asset_) internal pure returns (uint) {
    uint len = tokens_.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (tokens_[i] == asset_) {
        return i;
      }
    }
    return type(uint).max;
  }

  /// @notice Get a ratio to calculate amount of liquidity that should be withdrawn from the pool to get {targetAmount_}
  ///               liquidityAmount = _depositorLiquidity() * {liquidityRatioOut} / 1e18
  ///         User needs to withdraw {targetAmount_} in main asset.
  ///         There are two kinds of available liquidity:
  ///         1) liquidity in the pool - {depositorLiquidity_}
  ///         2) Converted amounts on balance of the strategy - {baseAmounts_}
  ///         To withdraw {targetAmount_} we need
  ///         1) Reconvert converted amounts back to main asset
  ///         2) IF result amount is not necessary - withdraw some liquidity from the pool
  ///            and also convert it to the main asset.
  /// @dev This is a writable function with read-only behavior (because of the quote-call)
  /// @param targetAmount_ Required amount of main asset to be withdrawn from the strategy
  ///                      0 - withdraw all
  /// @param baseAmounts_ Available balances of the converted assets
  /// @param strategy_ Address of the strategy
  function getLiquidityAmountRatio(
    uint targetAmount_,
    mapping(address => uint) storage baseAmounts_,
    address strategy_,
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint investedAssets,
    uint depositorLiquidity
  ) external returns (
    uint liquidityRatioOut,
    uint[] memory amountsToConvertOut
  ) {
    bool all = targetAmount_ == 0;

    uint len = tokens.length;
    amountsToConvertOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;

      uint baseAmount = baseAmounts_[tokens[i]];
      if (baseAmount != 0) {
        // let's estimate collateral that we received back after repaying baseAmount
        uint expectedCollateral = converter.quoteRepay(
          strategy_,
          tokens[indexAsset],
          tokens[i],
          baseAmount
        );

        if (all || targetAmount_ != 0) {
          // We always repay WHOLE available baseAmount even if it gives us much more amount then we need.
          // We cannot repay a part of it because converter doesn't allow to know
          // what amount should be repaid to get given amount of collateral.
          // And it's too dangerous to assume that we can calculate this amount
          // by reducing baseAmount proportionally to expectedCollateral/targetAmount_
          amountsToConvertOut[i] = baseAmount;
        }

        if (targetAmount_ > expectedCollateral) {
          targetAmount_ -= expectedCollateral;
        } else {
          targetAmount_ = 0;
        }

        if (investedAssets > expectedCollateral) {
          investedAssets -= expectedCollateral;
        } else {
          investedAssets = 0;
        }
      }
    }

    require(all || investedAssets > 0, AppErrors.WITHDRAW_TOO_MUCH);

    liquidityRatioOut = all
      ? 1e18
      : ((targetAmount_ == 0)
        ? 0
        : 1e18
          * 101 // add 1% on top...
          * targetAmount_ / investedAssets // a part of amount that we are going to withdraw
          / 100 // .. add 1% on top
    );

    if (liquidityRatioOut != 0) {
      // liquidityAmount temporary contains ratio...
      liquidityRatioOut = liquidityRatioOut * depositorLiquidity / 1e18;
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///                   Borrow and close positions
  /////////////////////////////////////////////////////////////////////
  /// @notice Make one or several borrow necessary to supply/borrow required {amountIn_} according to {entryData_}
  ///         Max possible collateral should be approved before calling of this function.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See TetuConverter\EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 or empty: Amount of collateral {amountIn_} is fixed, amount of borrow should be max possible.
  /// @param amountIn_ Meaning depends on {entryData_}.
  function openPosition(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint thresholdAmountIn_
  ) external returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    return _openPosition(tetuConverter_, entryData_, collateralAsset_, borrowAsset_, amountIn_, thresholdAmountIn_);
  }

  /// @notice Make one or several borrow necessary to supply/borrow required {amountIn_} according to {entryData_}
  ///         Max possible collateral should be approved before calling of this function.
  /// @param entryData_ Encoded entry kind and additional params if necessary (set of params depends on the kind)
  ///                   See TetuConverter\EntryKinds.sol\ENTRY_KIND_XXX constants for possible entry kinds
  ///                   0 or empty: Amount of collateral {amountIn_} is fixed, amount of borrow should be max possible.
  /// @param amountIn_ Meaning depends on {entryData_}.
  /// @param thresholdAmountIn_ Min value of amountIn allowed for the second and subsequent conversions.
  ///        0 - use default min value
  ///        If amountIn becomes too low, no additional borrows are possible, so
  ///        the rest amountIn is just added to collateral/borrow amount of previous conversion.
  function _openPosition(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint thresholdAmountIn_
  ) internal returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    if (thresholdAmountIn_ == 0) {
      // zero threshold is not allowed because round-issues are possible, see openPosition.dust test
      // we assume here, that it's useless to borrow amount using collateral/borrow amount
      // less than given number of tokens (event for BTC)
      thresholdAmountIn_ = DEFAULT_OPEN_POSITION_AMOUNT_IN_THRESHOLD;
    }
    require(amountIn_ > thresholdAmountIn_, AppErrors.WRONG_VALUE);

    OpenPositionLocal memory vars;
    // we assume here, that max possible collateral amount is already approved (as it's required by TetuConverter)
    vars.entryKind = ConverterEntryKinds.getEntryKind(entryData_);
    if (vars.entryKind == ConverterEntryKinds.ENTRY_KIND_EXACT_PROPORTION_1) {
      return openPositionEntryKind1(
        tetuConverter_,
        entryData_,
        collateralAsset_,
        borrowAsset_,
        amountIn_,
        thresholdAmountIn_
      );
    } else {
      (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter_.findBorrowStrategies(
        entryData_,
        collateralAsset_,
        amountIn_,
        borrowAsset_,
        _LOAN_PERIOD_IN_BLOCKS
      );

      uint len = vars.converters.length;
      if (len > 0) {
        for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
          // we need to approve collateralAmount before the borrow-call but it's already approved, see above comments
          vars.collateral;
          vars.amountToBorrow;
          if (vars.entryKind == ConverterEntryKinds.ENTRY_KIND_EXACT_COLLATERAL_IN_FOR_MAX_BORROW_OUT_0) {
            // we have exact amount of total collateral amount
            // Case ENTRY_KIND_EXACT_PROPORTION_1 is here too because we consider first platform only
            vars.collateral = amountIn_ < vars.collateralsRequired[i]
            ? amountIn_
            : vars.collateralsRequired[i];
            vars.amountToBorrow = amountIn_ < vars.collateralsRequired[i]
            ? vars.amountsToBorrow[i] * amountIn_ / vars.collateralsRequired[i]
            : vars.amountsToBorrow[i];
            amountIn_ -= vars.collateral;
          } else {
            // assume here that entryKind == EntryKinds.ENTRY_KIND_EXACT_BORROW_OUT_FOR_MIN_COLLATERAL_IN_2
            // we have exact amount of total amount-to-borrow
            vars.amountToBorrow = amountIn_ < vars.amountsToBorrow[i]
            ? amountIn_
            : vars.amountsToBorrow[i];
            vars.collateral = amountIn_ < vars.amountsToBorrow[i]
            ? vars.collateralsRequired[i] * amountIn_ / vars.amountsToBorrow[i]
            : vars.collateralsRequired[i];
            amountIn_ -= vars.amountToBorrow;
          }

          if (amountIn_ < thresholdAmountIn_ && amountIn_ != 0) {
            // dust amount is left, just leave it unused
            // we cannot add it to collateral/borrow amounts - there is a risk to exceed max allowed amounts
            amountIn_ = 0;
          }

          if (vars.amountToBorrow != 0) {
            borrowedAmountOut += tetuConverter_.borrow(
              vars.converters[i],
              collateralAsset_,
              vars.collateral,
              borrowAsset_,
              vars.amountToBorrow,
              address(this)
            );
            collateralAmountOut += vars.collateral;
            emit OpenPosition(
              vars.converters[i],
              collateralAsset_,
              vars.collateral,
              borrowAsset_,
              vars.amountToBorrow,
              address(this)
            );
          }

          if (amountIn_ == 0) break;
        }
      }

      return (collateralAmountOut, borrowedAmountOut);
    }
  }

  function openPositionEntryKind1(
    ITetuConverter tetuConverter_,
    bytes memory entryData_,
    address collateralAsset_,
    address borrowAsset_,
    uint amountIn_,
    uint collateralThreshold_
  ) internal returns (
    uint collateralAmountOut,
    uint borrowedAmountOut
  ) {
    OpenPositionEntryKind1Local memory vars;
    (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter_.findBorrowStrategies(
      entryData_,
      collateralAsset_,
      amountIn_,
      borrowAsset_,
      _LOAN_PERIOD_IN_BLOCKS
    );

    collateralAmountOut = 0;
    borrowedAmountOut = 0;

    uint len = vars.converters.length;
    if (len > 0) {
      // we should split amountIn on two amounts with proportions x:y
      (, uint x, uint y) = abi.decode(entryData_, (uint, uint, uint));
      // calculate prices conversion ratio using price oracle, decimals 18
      // i.e. alpha = 1e18 * 75e6 usdc / 25e18 matic = 3e6 usdc/matic
      vars.alpha = _getCollateralToBorrowRatio(tetuConverter_, collateralAsset_, borrowAsset_);

      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        // the lending platform allows to convert {collateralsRequired[i]} to {amountsToBorrow[i]}
        // and give us required proportions in result
        // C = C1 + C2, C2 => B2, B2 * alpha = C3, C1/C3 must be equal to x/y
        // C2 is collateral amount, that is converted to B2
        // but if lending platform doesn't have enough liquidity
        // it reduces {collateralsRequired[i]} and {amountsToBorrow[i]} proportionally to fit the limits
        // as result, remaining C1 will be too big after conversion and we need to make another borrow
        vars.c3 = vars.alpha * vars.amountsToBorrow[i] / 1e18;
        vars.c1 = x * vars.c3 / y;
        vars.ratio = vars.collateralsRequired[i] + vars.c1 > amountIn_
        ? 1e18 * amountIn_ / (vars.collateralsRequired[i] + vars.c1)
        : 1e18;
        // c2
        vars.collateral = vars.collateralsRequired[i] * vars.ratio / 1e18;
        vars.amountToBorrow = vars.amountsToBorrow[i] * vars.ratio / 1e18;

        vars.c3 = vars.alpha * vars.amountToBorrow / 1e18;
        vars.c1 = x * vars.c3 / y;

        if (amountIn_ > vars.c1 + vars.collateral) {
          // we have some amount for next converter
          amountIn_ -= (vars.c1 + vars.collateral);

          // protection against dust amounts, see "openPosition.dust", just leave dust amount unused
          // we CAN NOT add it to collateral/borrow amounts - there is a risk to exceed max allowed amounts
          if (amountIn_ < collateralThreshold_) {
            amountIn_ = 0;
          }
        } else {
          amountIn_ = 0;
        }

        require(
          tetuConverter_.borrow(
            vars.converters[i],
            collateralAsset_,
            vars.collateral,
            borrowAsset_,
            vars.amountToBorrow,
            address(this)
          ) == vars.amountToBorrow,
          StrategyLib.WRONG_VALUE
        );
        emit OpenPosition(
          vars.converters[i],
          collateralAsset_,
          vars.collateral,
          borrowAsset_,
          vars.amountToBorrow,
          address(this)
        );

        borrowedAmountOut += vars.amountToBorrow;
        collateralAmountOut += vars.collateral;

        if (amountIn_ == 0) {
          break;
        }
      }
    }

    return (collateralAmountOut, borrowedAmountOut);
  }

  /// @notice Get ratio18 = collateral / borrow
  function _getCollateralToBorrowRatio(
    ITetuConverter tetuConverter_,
    address collateralAsset_,
    address borrowAsset_
  ) internal view returns (uint){
    IPriceOracle priceOracle = IPriceOracle(IConverterController(tetuConverter_.controller()).priceOracle());
    uint priceCollateral = priceOracle.getAssetPrice(collateralAsset_);
    uint priceBorrow = priceOracle.getAssetPrice(borrowAsset_);
    return 1e18 * priceBorrow * 10 ** IERC20Metadata(collateralAsset_).decimals()
    / priceCollateral / 10 ** IERC20Metadata(borrowAsset_).decimals();
  }

  /// @notice Close the given position, pay {amountToRepay}, return collateral amount in result
  /// @param amountToRepay Amount to repay in terms of {borrowAsset}
  /// @return returnedAssetAmountOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function _closePosition(
    ITetuConverter tetuConverter_,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) internal returns (
    uint returnedAssetAmountOut,
    uint repaidAmountOut
  ) {

    // We shouldn't try to pay more than we actually need to repay
    // The leftover will be swapped inside TetuConverter, it's inefficient.
    // Let's limit amountToRepay by needToRepay-amount
    (uint needToRepay,) = tetuConverter_.getDebtAmountCurrent(address(this), collateralAsset, borrowAsset);

    uint amountRepay = amountToRepay < needToRepay
    ? amountToRepay
    : needToRepay;

    // Make full/partial repayment
    uint balanceBefore = IERC20(borrowAsset).balanceOf(address(this));
    IERC20(borrowAsset).safeTransfer(address(tetuConverter_), amountRepay);
    uint returnedBorrowAmountOut;

    (returnedAssetAmountOut, returnedBorrowAmountOut,,) = tetuConverter_.repay(
      collateralAsset,
      borrowAsset,
      amountRepay,
      address(this)
    );
    emit ClosePosition(
      collateralAsset,
      borrowAsset,
      amountRepay,
      address(this),
      returnedAssetAmountOut,
      returnedBorrowAmountOut
    );
    uint balanceAfter = IERC20(borrowAsset).balanceOf(address(this));

    // we cannot use amountRepay here because AAVE pool adapter is able to send tiny amount back (dust tokens)
    repaidAmountOut = balanceBefore > balanceAfter
    ? balanceBefore - balanceAfter
    : 0;

    require(returnedBorrowAmountOut == 0, StrategyLib.WRONG_VALUE);
  }

  /// @notice Close the given position, pay {amountToRepay}, return collateral amount in result
  /// @param amountToRepay Amount to repay in terms of {borrowAsset}
  /// @return returnedAssetAmountOut Amount of collateral received back after repaying
  /// @return repaidAmountOut Amount that was actually repaid
  function closePosition(
    ITetuConverter tetuConverter_,
    address collateralAsset,
    address borrowAsset,
    uint amountToRepay
  ) external returns (
    uint returnedAssetAmountOut,
    uint repaidAmountOut
  ) {
    return _closePosition(tetuConverter_, collateralAsset, borrowAsset, amountToRepay);
  }

  /////////////////////////////////////////////////////////////////////
  ///                         Liquidation
  /////////////////////////////////////////////////////////////////////

  /// @notice Make liquidation if estimated amountOut exceeds the given threshold
  /// @param spentAmountIn Amount of {tokenIn} has been consumed by the liquidator
  /// @param receivedAmountOut Amount of {tokenOut_} has been returned by the liquidator
  function liquidate(
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    uint liquidationThresholdForTokenOut_
  ) external returns (
    uint spentAmountIn,
    uint receivedAmountOut
  ) {
    return _liquidate(liquidator_, tokenIn_, tokenOut_, amountIn_, slippage_, liquidationThresholdForTokenOut_);
  }

  /// @notice Make liquidation if estimated amountOut exceeds the given threshold
  /// @param spentAmountIn Amount of {tokenIn} has been consumed by the liquidator
  /// @param receivedAmountOut Amount of {tokenOut_} has been returned by the liquidator
  function _liquidate(
    ITetuLiquidator liquidator_,
    address tokenIn_,
    address tokenOut_,
    uint amountIn_,
    uint slippage_,
    uint liquidationThresholdForTokenOut_
  ) internal returns (
    uint spentAmountIn,
    uint receivedAmountOut
  ) {
    (ITetuLiquidator.PoolData[] memory route,) = liquidator_.buildRoute(tokenIn_, tokenOut_);

    require(route.length != 0, AppErrors.NO_LIQUIDATION_ROUTE);

    // calculate balance in out value for check threshold
    uint amountOut = liquidator_.getPriceForRoute(route, amountIn_);

    // if the expected value is higher than threshold distribute to destinations
    if (amountOut > liquidationThresholdForTokenOut_) {
      // we need to approve each time, liquidator address can be changed in controller
      AppLib.approveIfNeeded(tokenIn_, amountIn_, address(liquidator_));

      uint balanceBefore = IERC20(tokenOut_).balanceOf(address(this));

      liquidator_.liquidateWithRoute(route, amountIn_, slippage_);

      // temporary save balance of token out after  liquidation to spentAmountIn
      uint balanceAfter = IERC20(tokenOut_).balanceOf(address(this));

      // assign correct values to
      receivedAmountOut = balanceAfter > balanceBefore
      ? balanceAfter - balanceBefore
      : 0;
      spentAmountIn = amountIn_;

      emit Liquidation(
        tokenIn_,
        tokenOut_,
        amountIn_,
        spentAmountIn,
        receivedAmountOut
      );
    }

    return (spentAmountIn, receivedAmountOut);
  }

  /////////////////////////////////////////////////////////////////////
  ///                 requirePayAmountBack
  /////////////////////////////////////////////////////////////////////

  /// @notice Swap available {amounts_} of {tokens_} to receive {targetAmount_} of {tokens[indexTheAsset_]}
  /// @param targetAmount_ Required amount of tokens[indexTheAsset_] that should be received by swap(s)
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param indexTargetAsset_ Index of target asset in tokens_ array
  /// @param underlying_ Index of underlying
  /// @param withdrawnAmounts_ Amounts withdrawn from the pool
  /// @param liquidationThresholdForTargetAsset_ Liquidation thresholds for the target asset
  /// @param overswap_ Allow to swap more then required (i.e. 1_000 => +1%)
  ///                  to avoid additional swap if the swap return amount a bit less than we expected
  /// @return spentAmounts Any amounts spent during the swaps
  /// @return withdrawnAmountsOut withdrawnAmounts + any amounts received during the swaps
  function swapToGivenAmount(
    uint targetAmount_,
    address[] memory tokens_,
    uint indexTargetAsset_,
    address underlying_,
    uint[] memory withdrawnAmounts_,
    ITetuConverter converter_,
    ITetuLiquidator liquidator_,
    uint liquidationThresholdForTargetAsset_,
    uint overswap_,
    mapping(address => uint) storage baseAmounts_
  ) external returns (
    uint[] memory spentAmounts,
    uint[] memory withdrawnAmountsOut
  ) {
    SwapToGivenAmountLocal memory v;
    v.len = tokens_.length;

    spentAmounts = new uint[](v.len);
    withdrawnAmountsOut = new uint[](v.len);

    v.availableAmounts = new uint[](v.len);
    for (; v.i < v.len; v.i = AppLib.uncheckedInc(v.i)) {
      v.availableAmounts[v.i] = withdrawnAmounts_[v.i] + baseAmounts_[tokens_[v.i]];
    }
    (spentAmounts, v.receivedAmounts) = _swapToGivenAmount(
      SwapToGivenAmountInputParams({
        targetAmount: targetAmount_,
        tokens: tokens_,
        indexTargetAsset: indexTargetAsset_,
        underlying: underlying_,
        amounts: v.availableAmounts,
        converter: converter_,
        liquidator: liquidator_,
        liquidationThresholdForTargetAsset: liquidationThresholdForTargetAsset_,
        overswap: overswap_
      })
    );
    for (v.i = 0; v.i < v.len; v.i = AppLib.uncheckedInc(v.i)) {
      withdrawnAmountsOut[v.i] = withdrawnAmounts_[v.i] + v.receivedAmounts[v.i];
    }
  }

  /// @notice Swap available {amounts_} of {tokens_} to receive {targetAmount_} of {tokens[indexTheAsset_]}
  /// @return spentAmounts Any amounts spent during the swaps
  /// @return receivedAmounts Any amounts received during the swaps
  function _swapToGivenAmount(SwapToGivenAmountInputParams memory p) internal returns (
    uint[] memory spentAmounts,
    uint[] memory receivedAmounts
  ) {
    CalcInvestedAssetsLocal memory v;
    v.len = p.tokens.length;
    receivedAmounts = new uint[](v.len);
    spentAmounts = new uint[](v.len);

    // calculate prices, decimals
    (v.prices, v.decs) = _getPricesAndDecs(
      IPriceOracle(IConverterController(p.converter.controller()).priceOracle()),
      p.tokens,
      v.len
    );

    // we need to swap other assets to the asset
    // at first we should swap NOT underlying.
    // if it would be not enough, we can swap underlying too.

    // swap NOT underlying, initialize {indexUnderlying}
    uint indexUnderlying;
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (p.underlying == p.tokens[i]) {
        indexUnderlying = i;
        continue;
      }
      if (p.indexTargetAsset == i) continue;

      (uint spent, uint received) = _swapToGetAmount(receivedAmounts[p.indexTargetAsset], p, v, i);
      spentAmounts[i] += spent;
      receivedAmounts[p.indexTargetAsset] += received;

      if (receivedAmounts[p.indexTargetAsset] >= p.targetAmount) break;
    }

    // swap underlying
    if (receivedAmounts[p.indexTargetAsset] < p.targetAmount && p.indexTargetAsset != indexUnderlying) {
      (uint spent, uint received) = _swapToGetAmount(receivedAmounts[p.indexTargetAsset], p, v, indexUnderlying);
      spentAmounts[indexUnderlying] += spent;
      receivedAmounts[p.indexTargetAsset] += received;
    }
  }

  /// @notice Swap a part of amount of asset {tokens[indexTokenIn]} to {targetAsset} to get {targetAmount} in result
  /// @param receivedTargetAmount Already received amount of {targetAsset} in previous swaps
  /// @param indexTokenIn Index of the tokenIn in p.tokens
  function _swapToGetAmount(
    uint receivedTargetAmount,
    SwapToGivenAmountInputParams memory p,
    CalcInvestedAssetsLocal memory v,
    uint indexTokenIn
  ) internal returns (
    uint amountSpent,
    uint amountReceived
  ) {
    if (p.amounts[indexTokenIn] != 0) {
      // we assume here, that p.targetAmount > receivedTargetAmount, see _swapToGivenAmount implementation

      // calculate amount that should be swapped
      // {overswap} allows to swap a bit more
      // to avoid additional swaps if the swap will give us a bit less amount than expected
      uint amountIn = (
        (p.targetAmount - receivedTargetAmount)
        * v.prices[p.indexTargetAsset] * v.decs[indexTokenIn]
        / v.prices[indexTokenIn] / v.decs[p.indexTargetAsset]
      ) * (p.overswap + DENOMINATOR) / DENOMINATOR;

      (amountSpent, amountReceived) = _liquidate(
        p.liquidator,
        p.tokens[indexTokenIn],
        p.tokens[p.indexTargetAsset],
        Math.min(amountIn, p.amounts[indexTokenIn]),
        _ASSET_LIQUIDATION_SLIPPAGE,
        p.liquidationThresholdForTargetAsset
      );
    }

    return (amountSpent, amountReceived);
  }

  /////////////////////////////////////////////////////////////////////
  ///                      Recycle rewards
  /////////////////////////////////////////////////////////////////////

  /// @notice Recycle the amounts: liquidate a part of each amount, send the other part to the forwarder.
  /// We have two kinds of rewards:
  /// 1) rewards in depositor's assets (the assets returned by _depositorPoolAssets)
  /// 2) any other rewards
  /// All received rewards are immediately "recycled".
  /// It means, they are divided on two parts: to forwarder, to compound
  ///   Compound-part of Rewards-2 can be liquidated
  ///   Compound part of Rewards-1 should be just added to baseAmounts
  /// All forwarder-parts are returned in amountsToForward and should be transferred to the forwarder.
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param rewardTokens_ Full list of reward tokens received from tetuConverter and depositor
  /// @param rewardAmounts_ Amounts of {rewardTokens_}; we assume, there are no zero amounts here
  /// @param liquidationThresholds_ Liquidation thresholds for rewards tokens
  /// @param baseAmounts_ Base amounts for rewards tokens
  ///                     The base amounts allow to separate just received and previously received rewards.
  /// @return receivedAmounts Received amounts of the tokens
  ///         This array has +1 item at the end: received amount of the main asset
  ///                                            there was no possibility to use separate var for it, stack too deep
  /// @return spentAmounts Spent amounts of the tokens
  /// @return amountsToForward Amounts to be sent to forwarder
  function recycle(
    address asset_,
    uint compoundRatio_,
    address[] memory tokens_,
    ITetuLiquidator liquidator_,
    mapping(address => uint) storage liquidationThresholds_,
    mapping(address => uint) storage baseAmounts_,
    address[] memory rewardTokens_,
    uint[] memory rewardAmounts_
  ) external returns (
    uint[] memory receivedAmounts,
    uint[] memory spentAmounts,
    uint[] memory amountsToForward
  ) {
    (receivedAmounts, spentAmounts, amountsToForward) = _recycle(
      asset_,
      compoundRatio_,
      tokens_,
      liquidator_,
      rewardTokens_,
      rewardAmounts_,
      liquidationThresholds_,
      baseAmounts_
    );
  }

  /// @dev Implementation of {recycle}
  function _recycle(
    address asset,
    uint compoundRatio,
    address[] memory tokens,
    ITetuLiquidator liquidator,
    address[] memory rewardTokens,
    uint[] memory rewardAmounts,
    mapping(address => uint) storage liquidationThresholds,
    mapping(address => uint) storage baseAmounts
  ) internal returns (
    uint[] memory receivedAmounts,
    uint[] memory spentAmounts,
    uint[] memory amountsToForward
  ) {
    RecycleLocalParams memory p;

    p.len = rewardTokens.length;
    require(p.len == rewardAmounts.length, AppErrors.WRONG_LENGTHS);

    p.liquidationThresholdAsset = liquidationThresholds[asset];

    amountsToForward = new uint[](p.len);
    receivedAmounts = new uint[](p.len + 1);
    spentAmounts = new uint[](p.len);

    // split each amount on two parts: a part-to-compound and a part-to-transfer-to-the-forwarder
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      p.rewardToken = rewardTokens[i];
      p.amountToCompound = rewardAmounts[i] * compoundRatio / COMPOUND_DENOMINATOR;

      if (p.amountToCompound > 0) {
        if (ConverterStrategyBaseLib.getAssetIndex(tokens, p.rewardToken) != type(uint).max) {
          // The asset is in the list of depositor's assets, liquidation is not allowed
          receivedAmounts[i] += p.amountToCompound;
        } else {
          p.baseAmountIn = baseAmounts[p.rewardToken];
          // total amount that can be liquidated
          p.totalRewardAmounts = p.amountToCompound + p.baseAmountIn;

          if (p.totalRewardAmounts < liquidationThresholds[p.rewardToken]) {
            // amount is too small, liquidation is not allowed
            receivedAmounts[i] += p.amountToCompound;
          } else {
            // The asset is not in the list of depositor's assets, its amount is big enough and should be liquidated
            // We assume here, that {token} cannot be equal to {_asset}
            // because the {_asset} is always included to the list of depositor's assets
            (p.spentAmountIn, p.receivedAmountOut) = _liquidate(
              liquidator,
              p.rewardToken,
              asset,
              p.totalRewardAmounts,
              _REWARD_LIQUIDATION_SLIPPAGE,
              p.liquidationThresholdAsset
            );

            // Adjust amounts after liquidation
            if (p.receivedAmountOut > 0) {
              receivedAmounts[p.len] += p.receivedAmountOut;
            }
            if (p.spentAmountIn == 0) {
              receivedAmounts[i] += p.amountToCompound;
            } else {
              require(p.spentAmountIn == p.amountToCompound + p.baseAmountIn, StrategyLib.WRONG_VALUE);
              spentAmounts[i] += p.baseAmountIn;
            }
          }
        }
      }

      p.amountToForward = rewardAmounts[i] - p.amountToCompound;
      amountsToForward[i] = p.amountToForward;
    }

    return (receivedAmounts, spentAmounts, amountsToForward);
  }

  /////////////////////////////////////////////////////////////////////
  ///                      calcInvestedAssets
  /////////////////////////////////////////////////////////////////////
  /// @notice Calculate amount we will receive when we withdraw all from pool
  /// @dev This is writable function because we need to update current balances in the internal protocols.
  /// @return amountOut Invested asset amount under control (in terms of {asset})
  function calcInvestedAssets(
    address[] memory tokens,
    uint[] memory amountsOut,
    uint indexAsset,
    ITetuConverter converter_,
    mapping(address => uint) storage baseAmounts
  ) external returns (
    uint amountOut
  ) {
    CalcInvestedAssetsLocal memory v;
    v.len = tokens.length;

    // calculate prices, decimals
    (v.prices, v.decs) = _getPricesAndDecs(
      IPriceOracle(IConverterController(converter_.controller()).priceOracle()),
      tokens,
      v.len
    );

    // A debt is registered below if we have X amount of asset, need to pay Y amount of the asset and X < Y
    // In this case: debt = Y - X, the order of tokens is the same as in {tokens} array
    for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) {
        // Current strategy balance of main asset is not taken into account here because it's add by splitter
        amountOut += amountsOut[i];
      } else {
        // available amount to repay
        uint toRepay = baseAmounts[tokens[i]] + amountsOut[i];

        (uint toPay, uint collateral) = converter_.getDebtAmountCurrent(address(this), tokens[indexAsset], tokens[i]);
        amountOut += collateral;
        if (toRepay >= toPay) {
          amountOut += (toRepay - toPay) * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
        } else {
          // there is not enough amount to pay the debt
          // let's register a debt and try to resolve it later below
          if (v.debts.length == 0) {
            // lazy initialization
            v.debts = new uint[](v.len);
          }
          // to pay the following amount we need to swap some other asset at first
          v.debts[i] = toPay - toRepay;
        }
      }
    }

    if (v.debts.length == v.len) {
      // we assume here, that it would be always profitable to save collateral
      // f.e. if there is not enough amount of USDT on our balance and we have a debt in USDT,
      // it's profitable to change any available asset to USDT, pay the debt and return the collateral back
      for (uint i; i < v.len; i = AppLib.uncheckedInc(i)) {
        if (v.debts[i] == 0) continue;

        // estimatedAssets should be reduced on the debt-value
        uint debtInAsset = v.debts[i] * v.prices[i] * v.decs[indexAsset] / v.prices[indexAsset] / v.decs[i];
        if (debtInAsset > amountOut) {
          // The debt is greater than we can pay. We shouldn't try to pay the debt in this case
          amountOut = 0;
        } else {
          amountOut -= debtInAsset;
        }
      }
    }

    return amountOut;
  }

  /////////////////////////////////////////////////////////////////////
  ///                      getExpectedAmountMainAsset
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate expected amount of the main asset after withdrawing
  /// @param withdrawnAmounts_ Expected amounts to be withdrawn from the pool
  /// @param amountsToConvert_ Amounts on balance initially available for the conversion
  /// @return amountOut Expected amount of the main asset
  function getExpectedAmountMainAsset(
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint[] memory withdrawnAmounts_,
    uint[] memory amountsToConvert_
  ) internal returns (
    uint amountOut
  ) {
    uint len = tokens.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) {
        amountOut += withdrawnAmounts_[i];
      } else {
        uint amount = withdrawnAmounts_[i] + amountsToConvert_[i];
        if (amount != 0) {
          amountOut += converter.quoteRepay(address(this), tokens[indexAsset], tokens[i], amount);
        }
      }
    }

    return amountOut;
  }

  /////////////////////////////////////////////////////////////////////
  ///              Reduce size of ConverterStrategyBase
  /////////////////////////////////////////////////////////////////////
  /// @notice Make borrow and save amounts of tokens available for deposit to tokenAmounts
  /// @param thresholdMainAsset_ Min allowed value of collateral in terms of main asset, 0 - use default min value
  /// @return tokenAmountsOut Amounts available for deposit
  /// @return borrowedAmounts Amounts borrowed for {spendCollateral}
  /// @return spentCollateral Total collateral amount spent for borrowing
  function getTokenAmounts(
    ITetuConverter tetuConverter_,
    address[] memory tokens_,
    uint indexAsset_,
    uint[] memory collaterals_,
    uint thresholdMainAsset_,
    mapping(address => uint) storage baseAmounts_
  ) external returns (
    uint[] memory tokenAmountsOut,
    uint[] memory borrowedAmounts,
    uint spentCollateral
  ) {
    // content of tokenAmounts will be modified in place
    uint len = tokens_.length;
    borrowedAmounts = new uint[](len);
    tokenAmountsOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset_) {
        tokenAmountsOut[i] = collaterals_[i];
      } else {
        if (collaterals_[i] > 0) {
          uint collateral;
          AppLib.approveIfNeeded(tokens_[indexAsset_], collaterals_[i], address(tetuConverter_));
          (collateral, borrowedAmounts[i]) = _openPosition(
            tetuConverter_,
            "", // entry kind = 0: fixed collateral amount, max possible borrow amount
            tokens_[indexAsset_],
            tokens_[i],
            collaterals_[i],
            thresholdMainAsset_
          );
          // collateral should be equal to tokenAmounts[i] here because we use default entry kind
          spentCollateral += collateral;

          // zero amount are possible (conversion is not available) but it's not suitable for depositor
          require(borrowedAmounts[i] != 0, AppErrors.ZERO_AMOUNT_BORROWED);
        }
        tokenAmountsOut[i] = baseAmounts_[tokens_[i]] + borrowedAmounts[i];
      }
    }

    return (tokenAmountsOut, borrowedAmounts, spentCollateral);
  }

  /// @notice Claim rewards from tetuConverter, generate result list of all available rewards and airdrops
  /// @dev The post-processing is rewards conversion to the main asset
  /// @param tokens_ tokens received from {_depositorPoolAssets}
  /// @param rewardTokens_ List of rewards claimed from the internal pool
  /// @param rewardTokens_ Amounts of rewards claimed from the internal pool
  /// @param tokensOut List of available rewards - not zero amounts, reward tokens don't repeat
  /// @param amountsOut Amounts of available rewards
  function prepareRewardsList(
    ITetuConverter tetuConverter_,
    address[] memory tokens_,
    address[] memory rewardTokens_,
    uint[] memory rewardAmounts_,
    mapping(address => uint) storage baseAmounts_
  ) external returns (
    address[] memory tokensOut,
    uint[] memory amountsOut
  ) {
    // Rewards from TetuConverter
    (address[] memory tokensTC, uint[] memory amountsTC) = tetuConverter_.claimRewards(address(this));

    // Join arrays and recycle tokens
    (tokensOut, amountsOut) = TokenAmountsLib.combineArrays(
      rewardTokens_, rewardAmounts_,
      tokensTC, amountsTC,
      // by default, depositor assets have zero amounts here .. but probably they have airdrops (see below)
      tokens_, new uint[](tokens_.length)
    );

    // Add airdrops
    uint len = tokensOut.length;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      amountsOut[i] = IERC20(tokensOut[i]).balanceOf(address(this)) - baseAmounts_[tokensOut[i]];
    }

    // filter zero amounts out
    (tokensOut, amountsOut) = TokenAmountsLib.filterZeroAmounts(tokensOut, amountsOut);
  }

  /////////////////////////////////////////////////////////////////////
  ///                       WITHDRAW HELPERS
  /////////////////////////////////////////////////////////////////////

  function postWithdrawActions(
    uint[] memory reserves,
    uint depositorLiquidity,
    uint liquidityAmount,
    uint totalSupply,
    uint[] memory amountsToConvert,

    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,

    uint _depositorLiquidityNew,
    uint[] memory withdrawnAmounts
  ) external returns (uint _expectedAmountMainAsset, uint[] memory _amountsToConvert){

    // estimate, how many assets should be withdrawn
    // the depositor is able to use less liquidity than it was asked
    // (i.e. Balancer-depositor leaves some BPT unused)
    // so, we need to fix liquidityAmount on this amount

    // we assume here, that liquidity cannot increase in _depositorExit
    uint depositorLiquidityDelta = depositorLiquidity - _depositorLiquidityNew;
    if (liquidityAmount > depositorLiquidityDelta) {
      liquidityAmount = depositorLiquidityDelta;
    }

    // now we can estimate expected amount of assets to be withdrawn
    uint[] memory expectedWithdrawAmounts = getExpectedWithdrawnAmounts(
      reserves,
      liquidityAmount,
      totalSupply
    );

    uint expectedAmountMainAsset = getExpectedAmountMainAsset(
      tokens,
      indexAsset,
      converter,
      expectedWithdrawAmounts,
      amountsToConvert
    );
    for (uint i; i < tokens.length; i = AppLib.uncheckedInc(i)) {
      amountsToConvert[i] += withdrawnAmounts[i];
    }

    return (expectedAmountMainAsset, amountsToConvert);
  }

  function postWithdrawActionsEmpty(
    address[] memory tokens,
    uint indexAsset,
    ITetuConverter converter,
    uint[] memory withdrawnAmounts_,
    uint[] memory amountsToConvert_
  ) external returns (uint[] memory withdrawnAmounts, uint expectedAmountMainAsset){
    withdrawnAmounts = withdrawnAmounts_;
    expectedAmountMainAsset = getExpectedAmountMainAsset(
      tokens,
      indexAsset,
      converter,
      withdrawnAmounts_,
      amountsToConvert_
    );
  }

  /////////////////////////////////////////////////////////////////////
  ///                      convertAfterWithdraw
  /////////////////////////////////////////////////////////////////////
  /// @notice Convert {p.amountsToConvert_} to the main asset
  /// @return collateralOut Total amount of collateral returned after closing positions
  /// @return repaidAmountsOut What amounts were spent in exchange of the {collateralOut}
  function convertAfterWithdraw(
    ITetuConverter tetuConverter,
    ITetuLiquidator liquidator,
    uint liquidationThreshold,
    address[] memory tokens,
    uint indexAsset,
    uint[] memory amountsToConvert
  ) external returns (
    uint collateralOut,
    uint[] memory repaidAmountsOut
  ) {
    ConvertAfterWithdrawLocalParams memory vars;
    vars.asset = tokens[indexAsset];

    uint len = tokens.length;
    repaidAmountsOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;
      (vars.collateral, repaidAmountsOut[i]) = _closePosition(
        tetuConverter,
        vars.asset,
        tokens[i],
        amountsToConvert[i]
      );
      collateralOut += vars.collateral;
    }

    // Manually swap remain leftovers
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == indexAsset) continue;
      if (amountsToConvert[i] > repaidAmountsOut[i]) {
        (vars.spentAmountIn, vars.receivedAmountOut) = _liquidate(
          liquidator,
          tokens[i],
          vars.asset,
          amountsToConvert[i] - repaidAmountsOut[i],
          _ASSET_LIQUIDATION_SLIPPAGE,
          liquidationThreshold
        );
        if (vars.receivedAmountOut != 0) {
          collateralOut += vars.receivedAmountOut;
        }
        if (vars.spentAmountIn != 0) {
          repaidAmountsOut[i] += vars.spentAmountIn;
          require(
            tetuConverter.isConversionValid(
              tokens[i],
              vars.spentAmountIn,
              vars.asset,
              vars.receivedAmountOut,
              PRICE_IMPACT_TOLERANCE
            ),
            AppErrors.PRICE_IMPACT
          );
        }
      }
    }

    return (collateralOut, repaidAmountsOut);
  }

  /////////////////////////////////////////////////////////////////////
  ///                       OTHER HELPERS
  /////////////////////////////////////////////////////////////////////

  function getAssetPriceFromConverter(ITetuConverter converter, address token) external view returns (uint) {
    return IPriceOracle(IConverterController(converter.controller()).priceOracle()).getAssetPrice(token);
  }

  function registerIncome(
    uint assetBefore,
    uint assetAfter,
    uint earned,
    uint lost
  ) internal pure returns (uint _earned, uint _lost) {
    if (assetAfter > assetBefore) {
      earned += assetAfter - assetBefore;
    } else {
      lost += assetBefore - assetAfter;
    }
    return (earned, lost);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./UniswapV3Lib.sol";
import "./UniswapV3DebtLib.sol";

library UniswapV3ConverterStrategyLogicLib {

  //////////////////////////////////////////
  //            CONSTANTS
  //////////////////////////////////////////

  uint internal constant LIQUIDATOR_SWAP_SLIPPAGE_STABLE = 100;
  uint internal constant LIQUIDATOR_SWAP_SLIPPAGE_VOLATILE = 500;
  uint internal constant HARD_WORK_USD_FEE_THRESHOLD = 100;
  uint public constant DEFAULT_FUSE_THRESHOLD = 5e15;

  //////////////////////////////////////////
  //            EVENTS
  //////////////////////////////////////////

  event FuseTriggered();
  event Rebalanced();
  event DisableFuse();
  event NewFuseThreshold(uint newFuseThreshold);

  //////////////////////////////////////////
  //            STRUCTURES
  //////////////////////////////////////////

  struct State {
    address tokenA;
    address tokenB;
    IUniswapV3Pool pool;
    int24 tickSpacing;
    bool fillUp;
    bool isStablePool;
    int24 lowerTick;
    int24 upperTick;
    int24 lowerTickFillup;
    int24 upperTickFillup;
    int24 rebalanceTickRange;
    bool depositorSwapTokens;
    uint128 totalLiquidity;
    uint128 totalLiquidityFillup;
    uint rebalanceEarned0;
    uint rebalanceEarned1;
    uint rebalanceLost;
    bool isFuseTriggered;
    uint fuseThreshold;
    uint lastPrice;
  }

  struct TryCoverLossParams {
    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;
    bool depositorSwapTokens;
    uint fee0;
    uint fee1;
    uint oldInvestedAssets;
  }

  struct RebalanceLocalVariables {
    int24 upperTick;
    int24 lowerTick;
    int24 tickSpacing;
    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;
    uint lastPrice;
    uint fuseThreshold;
    bool depositorSwapTokens;
    uint rebalanceEarned0;
    uint rebalanceEarned1;

    uint newRebalanceEarned0;
    uint newRebalanceEarned1;
    uint notCoveredLoss;
    int24 newLowerTick;
    int24 newUpperTick;

    bool fillUp;
    bool isStablePool;
    uint newPrice;
  }

  //////////////////////////////////////////
  //            HELPERS
  //////////////////////////////////////////

  function emitDisableFuse() external {
    emit DisableFuse();
  }

  function emitNewFuseThreshold(uint value) external {
    emit NewFuseThreshold(value);
  }

  /// @dev Gets the liquidator swap slippage based on the pool type (stable or volatile).
  /// @param pool The IUniswapV3Pool instance.
  /// @return The liquidator swap slippage percentage.
  function _getLiquidatorSwapSlippage(IUniswapV3Pool pool) internal view returns (uint) {
    return isStablePool(pool) ? LIQUIDATOR_SWAP_SLIPPAGE_STABLE : LIQUIDATOR_SWAP_SLIPPAGE_VOLATILE;
  }

  /// @notice Get the balance of the given token held by the contract.
  /// @param token The token address.
  /// @return The balance of the token.
  function _balance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }

  /// @notice Check if the given pool is a stable pool.
  /// @param pool The Uniswap V3 pool.
  /// @return A boolean indicating if the pool is stable.
  function isStablePool(IUniswapV3Pool pool) public view returns (bool) {
    return pool.fee() == 100;
  }

  /// @notice Get the token amounts held by the contract excluding earned parts.
  /// @param state The state of the pool.
  /// @return amountA The balance of tokenA.
  /// @return amountB The balance of tokenB.
  function getTokenAmounts(State storage state) external view returns (uint amountA, uint amountB) {
    bool depositorSwapTokens = state.depositorSwapTokens;
    amountA = _balance(state.tokenA);
    amountB = _balance(state.tokenB);

    uint earned0 = (depositorSwapTokens ? state.rebalanceEarned1 : state.rebalanceEarned0);
    uint earned1 = (depositorSwapTokens ? state.rebalanceEarned0 : state.rebalanceEarned1);

    require(amountA >= earned0 && amountB >= earned1, "Wrong balance");
    amountA -= earned0;
    amountB -= earned1;
  }

  /// @notice Get the price ratio of the two given tokens from the oracle.
  /// @param converter The Tetu converter.
  /// @param tokenA The first token address.
  /// @param tokenB The second token address.
  /// @return The price ratio of the two tokens.
  function getOracleAssetsPrice(ITetuConverter converter, address tokenA, address tokenB) public view returns (uint) {
    IPriceOracle oracle = IPriceOracle(IConverterController(converter.controller()).priceOracle());
    uint priceA = oracle.getAssetPrice(tokenA);
    uint priceB = oracle.getAssetPrice(tokenB);
    return priceB * 1e18 / priceA;
  }

  /// @notice Check if the fuse is enabled based on the price difference and fuse threshold.
  /// @param oldPrice The old price.
  /// @param newPrice The new price.
  /// @param fuseThreshold The fuse threshold.
  /// @return A boolean indicating if the fuse is enabled.
  function isEnableFuse(uint oldPrice, uint newPrice, uint fuseThreshold) internal pure returns (bool) {
    return oldPrice > newPrice ? (oldPrice - newPrice) > fuseThreshold : (newPrice - oldPrice) > fuseThreshold;
  }

  /// @dev Gets the update information for the strategy, including token amounts received and spent.
  /// @param state The State storage object.
  /// @param baseAmounts Mapping of token addresses to their base amounts on the strategy balance (not rewards).
  /// @return receivedA The amount of tokenA received.
  /// @return spentA The amount of tokenA spent.
  /// @return receivedB The amount of tokenB received.
  /// @return spentB The amount of tokenB spent.
  function getUpdateInfo(State storage state, mapping(address => uint) storage baseAmounts) external view returns (
    uint receivedA,
    uint spentA,
    uint receivedB,
    uint spentB
  ){
    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    bool depositorSwapTokens = state.depositorSwapTokens;
    //updating baseAmounts (token amounts on strategy balance which are not rewards)
    uint balanceOfTokenABefore = baseAmounts[tokenA];
    uint balanceOfTokenBBefore = baseAmounts[tokenB];
    uint balanceOfTokenAAfter = _balance(tokenA) - (depositorSwapTokens ? state.rebalanceEarned1 : state.rebalanceEarned0);
    uint balanceOfTokenBAfter = _balance(tokenB) - (depositorSwapTokens ? state.rebalanceEarned0 : state.rebalanceEarned1);

    receivedA = balanceOfTokenABefore > balanceOfTokenAAfter ? 0 : balanceOfTokenAAfter - balanceOfTokenABefore;
    spentA = balanceOfTokenABefore > balanceOfTokenAAfter ? balanceOfTokenABefore - balanceOfTokenAAfter : 0;
    receivedB = balanceOfTokenBBefore > balanceOfTokenBAfter ? 0 : balanceOfTokenBAfter - balanceOfTokenBBefore;
    spentB = balanceOfTokenBBefore > balanceOfTokenBAfter ? balanceOfTokenBBefore - balanceOfTokenBAfter : 0;
  }

  function initStrategyState(State storage state, address controller_, address converter) external {
    address liquidator = IController(controller_).liquidator();
    IERC20(state.tokenA).approve(liquidator, type(uint).max);
    IERC20(state.tokenB).approve(liquidator, type(uint).max);

    /// for ultra-wide ranges we use Swap rebalancing strategy and Fill-up for other
    /// upperTick always greater then lowerTick
    state.fillUp = state.upperTick - state.lowerTick >= 4 * state.tickSpacing;

    if (isStablePool(state.pool)) {
      /// for stable pools fuse can be enabled
      state.isStablePool = true;
      // 0.5% price change
      state.fuseThreshold = DEFAULT_FUSE_THRESHOLD;
      emit NewFuseThreshold(DEFAULT_FUSE_THRESHOLD);
      state.lastPrice = getOracleAssetsPrice(ITetuConverter(converter), state.tokenA, state.tokenB);
    }
  }

  //////////////////////////////////////////
  //            CALCULATIONS
  //////////////////////////////////////////

  /// @notice Calculate the initial values for a Uniswap V3 pool Depositor.
  /// @param pool The Uniswap V3 pool to get the initial values from.
  /// @param tickRange_ The tick range for the pool.
  /// @param rebalanceTickRange_ The rebalance tick range for the pool.
  /// @param asset_ Underlying asset of the depositor.
  /// @return tickSpacing The tick spacing for the pool.
  /// @return lowerTick The lower tick value for the pool.
  /// @return upperTick The upper tick value for the pool.
  /// @return tokenA The address of the first token in the pool.
  /// @return tokenB The address of the second token in the pool.
  /// @return _depositorSwapTokens A boolean representing whether to use reverse tokens for pool.
  function calcInitialDepositorValues(
    IUniswapV3Pool pool,
    int24 tickRange_,
    int24 rebalanceTickRange_,
    address asset_
  ) external view returns (
    int24 tickSpacing,
    int24 lowerTick,
    int24 upperTick,
    address tokenA,
    address tokenB,
    bool _depositorSwapTokens
  ) {
    tickSpacing = UniswapV3Lib.getTickSpacing(pool.fee());
    (, int24 tick, , , , ,) = pool.slot0();
    if (tickRange_ == 0) {
      lowerTick = tick / tickSpacing * tickSpacing;
      upperTick = lowerTick + tickSpacing;
    } else {
      require(tickRange_ == tickRange_ / tickSpacing * tickSpacing, 'Incorrect tickRange');
      require(rebalanceTickRange_ == rebalanceTickRange_ / tickSpacing * tickSpacing, 'Incorrect rebalanceTickRange');
      lowerTick = (tick - tickRange_) / tickSpacing * tickSpacing;
      upperTick = (tick + tickRange_) / tickSpacing * tickSpacing;
    }
    require(asset_ == pool.token0() || asset_ == pool.token1(), 'Incorrect asset');
    if (asset_ == pool.token0()) {
      tokenA = pool.token0();
      tokenB = pool.token1();
      _depositorSwapTokens = false;
    } else {
      tokenA = pool.token1();
      tokenB = pool.token0();
      _depositorSwapTokens = true;
    }
  }

  /// @notice Calculate the new tick range for a Uniswap V3 pool.
  /// @param pool The Uniswap V3 pool to calculate the new tick range for.
  /// @param lowerTick The current lower tick value for the pool.
  /// @param upperTick The current upper tick value for the pool.
  /// @param tickSpacing The tick spacing for the pool.
  /// @return lowerTickNew The new lower tick value for the pool.
  /// @return upperTickNew The new upper tick value for the pool.
  function _calcNewTickRange(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 tickSpacing
  ) internal view returns (int24 lowerTickNew, int24 upperTickNew) {
    (, int24 tick, , , , ,) = pool.slot0();
    if (upperTick - lowerTick == tickSpacing) {
      lowerTickNew = tick / tickSpacing * tickSpacing;
      upperTickNew = lowerTickNew + tickSpacing;
    } else {
      int24 halfRange = (upperTick - lowerTick) / 2;
      lowerTickNew = (tick - halfRange) / tickSpacing * tickSpacing;
      upperTickNew = (tick + halfRange) / tickSpacing * tickSpacing;
    }
  }

  /// @dev Calculates the new fee amounts and the not covered loss, if any, after attempting to cover losses.
  /// @param p The TryCoverLossParams instance containing required parameters.
  /// @param collateralAmount The current collateral amount.
  /// @return newFee0 The new fee amount for tokenA.
  /// @return newFee1 The new fee amount for tokenB.
  /// @return notCoveredLoss The amount of loss that could not be covered by fees.
  function _calculateCoverLoss(
    TryCoverLossParams memory p,
    uint collateralAmount
  ) internal view returns (uint newFee0, uint newFee1, uint notCoveredLoss) {
    notCoveredLoss = 0;

    newFee0 = p.fee0;
    newFee1 = p.fee1;
    uint feeA = p.depositorSwapTokens ? newFee1 : newFee0;
    uint feeB = p.depositorSwapTokens ? newFee0 : newFee1;

    uint newInvestedAssets = collateralAmount + _balance(p.tokenA) - feeA;
    if (newInvestedAssets < p.oldInvestedAssets) {
      // we have lost
      uint lost = p.oldInvestedAssets - newInvestedAssets;

      if (lost <= feeA) {
        // feeA is enough to cover lost
        if (p.depositorSwapTokens) {
          newFee1 -= lost;
        } else {
          newFee0 -= lost;
        }
      } else {
        // feeA is not enough to cover lost

        if (p.depositorSwapTokens) {
          newFee1 = 0;
        } else {
          newFee0 = 0;
        }

        uint feeBinTermOfA;
        if (feeB > 0) {

          feeBinTermOfA = UniswapV3Lib.getPrice(address(p.pool), p.tokenB) * feeB / 10 ** IERC20Metadata(p.tokenB).decimals();

          if (feeA + feeBinTermOfA > lost) {
            if (p.depositorSwapTokens) {
              newFee0 = (feeA + feeBinTermOfA - lost) * UniswapV3Lib.getPrice(address(p.pool), p.tokenA) / 10 ** IERC20Metadata(p.tokenA).decimals();
            } else {
              newFee1 = (feeA + feeBinTermOfA - lost) * UniswapV3Lib.getPrice(address(p.pool), p.tokenA) / 10 ** IERC20Metadata(p.tokenA).decimals();
            }
          } else {
            notCoveredLoss = lost - feeA - feeBinTermOfA;
            if (p.depositorSwapTokens) {
              newFee0 = 0;
            } else {
              newFee1 = 0;
            }
          }
        } else {
          notCoveredLoss = lost - feeA;
        }
      }
    }
  }

  //////////////////////////////////////////
  //            Pool info
  //////////////////////////////////////////

  /// @notice Retrieve the reserves of a Uniswap V3 pool managed by this contract.
  /// @param state The State storage containing the pool's information.
  /// @return reserves An array containing the reserve amounts of the contract owned liquidity.
  function getPoolReserves(State storage state) external view returns (uint[] memory reserves) {
    reserves = new uint[](2);
    (uint160 sqrtRatioX96, , , , , ,) = state.pool.slot0();

    (reserves[0], reserves[1]) = UniswapV3Lib.getAmountsForLiquidity(
      sqrtRatioX96,
      state.lowerTick,
      state.upperTick,
      state.totalLiquidity
    );

    (uint amount0CurrentFillup, uint amount1CurrentFillup) = UniswapV3Lib.getAmountsForLiquidity(
      sqrtRatioX96,
      state.lowerTickFillup,
      state.upperTickFillup,
      state.totalLiquidityFillup
    );

    (uint fee0, uint fee1) = getFees(state);

    reserves[0] += amount0CurrentFillup + fee0 + _balance(state.pool.token0());
    reserves[1] += amount1CurrentFillup + fee1 + _balance(state.pool.token1());

    if (state.depositorSwapTokens) {
      (reserves[0], reserves[1]) = (reserves[1], reserves[0]);
    }
  }

  /// @notice Retrieve the fees generated by a Uniswap V3 pool managed by this contract.
  /// @param state The State storage containing the pool's information.
  /// @return fee0 The fees generated for the first token in the pool.
  /// @return fee1 The fees generated for the second token in the pool.
  function getFees(State storage state) public view returns (uint fee0, uint fee1) {
    UniswapV3Lib.PoolPosition memory position = UniswapV3Lib.PoolPosition(address(state.pool), state.lowerTick, state.upperTick, state.totalLiquidity, address(this));
    (fee0, fee1) = UniswapV3Lib.getFees(position);
    UniswapV3Lib.PoolPosition memory positionFillup = UniswapV3Lib.PoolPosition(address(state.pool), state.lowerTickFillup, state.upperTickFillup, state.totalLiquidityFillup, address(this));
    (uint fee0Fillup, uint fee1Fillup) = UniswapV3Lib.getFees(positionFillup);
    fee0 += fee0Fillup;
    fee1 += fee1Fillup;
  }

  /// @notice Estimate the exit amounts for a given liquidity amount in a Uniswap V3 pool.
  /// @param pool The Uniswap V3 pool to quote the exit amounts for.
  /// @param lowerTick The lower tick value for the pool.
  /// @param upperTick The upper tick value for the pool.
  /// @param lowerTickFillup The lower tick value for the fillup range in the pool.
  /// @param upperTickFillup The upper tick value for the fillup range in the pool.
  /// @param liquidity The current liquidity in the pool.
  /// @param liquidityFillup The current liquidity in the fillup range.
  /// @param liquidityAmountToExit The amount of liquidity to exit.
  /// @param _depositorSwapTokens A boolean indicating if need to use token B instead of token A.
  /// @return amountsOut An array containing the estimated exit amounts for each token in the pool.
  function quoteExit(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 lowerTickFillup,
    int24 upperTickFillup,
    uint128 liquidity,
    uint128 liquidityFillup,
    uint128 liquidityAmountToExit,
    bool _depositorSwapTokens
  ) external view returns (uint[] memory amountsOut) {
    amountsOut = new uint[](2);
    (uint160 sqrtRatioX96, , , , , ,) = pool.slot0();

    (amountsOut[0], amountsOut[1]) = UniswapV3Lib.getAmountsForLiquidity(
      sqrtRatioX96,
      lowerTick,
      upperTick,
      liquidityAmountToExit
    );

    if (liquidity > 0 && liquidityFillup > 0) {
      (uint amountOut0Fillup, uint amountOut1Fillup) = UniswapV3Lib.getAmountsForLiquidity(
        sqrtRatioX96,
        lowerTickFillup,
        upperTickFillup,
        liquidityFillup * liquidityAmountToExit / liquidity
      );

      amountsOut[0] += amountOut0Fillup;
      amountsOut[1] += amountOut1Fillup;
    }

    if (_depositorSwapTokens) {
      (amountsOut[0], amountsOut[1]) = (amountsOut[1], amountsOut[0]);
    }
  }

  /// @notice Determine if the pool needs to be rebalanced.
  /// @return A boolean indicating if the pool needs to be rebalanced.
  function needRebalance(
    bool isFuseTriggered,
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 tickSpacing,
    int24 rebalanceTickRange
  ) public view returns (bool) {
    if (isFuseTriggered) {
      return false;
    }
    (, int24 tick, , , , ,) = pool.slot0();
    if (upperTick - lowerTick == tickSpacing) {
      return tick < lowerTick || tick >= upperTick;
    } else {
      int24 halfRange = (upperTick - lowerTick) / 2;
      int24 oldMedianTick = lowerTick + halfRange;
      if (tick > oldMedianTick) {
        return tick - oldMedianTick >= rebalanceTickRange;
      }
      return oldMedianTick - tick > rebalanceTickRange;
    }
  }

  /// @notice Get entry data for a Uniswap V3 pool.
  /// @param pool The Uniswap V3 pool instance.
  /// @param lowerTick The lower tick of the pool's main range.
  /// @param upperTick The upper tick of the pool's main range.
  /// @param tickSpacing The tick spacing of the pool.
  /// @param depositorSwapTokens A boolean indicating if need to use token B instead of token A.
  /// @return entryData A byte array containing the entry data for the pool.
  function getEntryData(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 tickSpacing,
    bool depositorSwapTokens
  ) public view returns (bytes memory entryData) {
    address token1 = pool.token1();
    uint token1Price = UniswapV3Lib.getPrice(address(pool), token1);
    (lowerTick, upperTick) = _calcNewTickRange(pool, lowerTick, upperTick, tickSpacing);

    uint token1Decimals = IERC20Metadata(token1).decimals();

    uint token0Desired = token1Price;
    uint token1Desired = 10 ** token1Decimals;

    // calculate proportions
    (uint consumed0, uint consumed1,) = UniswapV3Lib.addLiquidityPreview(address(pool), lowerTick, upperTick, token0Desired, token1Desired);

    if (depositorSwapTokens) {
      entryData = abi.encode(1, consumed1 * token1Price / token1Desired, consumed0);
    } else {
      entryData = abi.encode(1, consumed0, consumed1 * token1Price / token1Desired);
    }
  }

  //////////////////////////////////////////
  //            Joins to the pool
  //////////////////////////////////////////

  /// @notice Enter the pool and provide liquidity with desired token amounts.
  /// @param pool The Uniswap V3 pool to provide liquidity to.
  /// @param lowerTick The lower tick value for the pool.
  /// @param upperTick The upper tick value for the pool.
  /// @param amountsDesired_ An array containing the desired amounts of tokens to provide liquidity.
  /// @param totalLiquidity The current total liquidity in the pool.
  /// @param _depositorSwapTokens A boolean indicating if need to use token B instead of token A.
  /// @return amountsConsumed An array containing the consumed amounts for each token in the pool.
  /// @return liquidityOut The amount of liquidity added to the pool.
  /// @return totalLiquidityNew The updated total liquidity after providing liquidity.
  function enter(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    uint[] memory amountsDesired_,
    uint128 totalLiquidity,
    bool _depositorSwapTokens
  ) external returns (uint[] memory amountsConsumed, uint liquidityOut, uint128 totalLiquidityNew) {

    amountsConsumed = new uint[](2);
    if (_depositorSwapTokens) {
      (amountsDesired_[0], amountsDesired_[1]) = (amountsDesired_[1], amountsDesired_[0]);
    }
    uint128 newLiquidity;
    (amountsConsumed[0], amountsConsumed[1], newLiquidity) = UniswapV3Lib.addLiquidityPreview(address(pool), lowerTick, upperTick, amountsDesired_[0], amountsDesired_[1]);
    pool.mint(address(this), lowerTick, upperTick, newLiquidity, "");
    liquidityOut = uint(newLiquidity);
    totalLiquidityNew = totalLiquidity + newLiquidity;
    if (_depositorSwapTokens) {
      (amountsConsumed[0], amountsConsumed[1]) = (amountsConsumed[1], amountsConsumed[0]);
    }
  }

  /// @notice Add liquidity to a Uniswap V3 pool in a specified tick range according fill up rules.
  /// @param pool The Uniswap V3 pool to add liquidity to.
  /// @param lowerTick The current lower tick value for the pool.
  /// @param upperTick The current upper tick value for the pool.
  /// @param tickSpacing The tick spacing for the pool.
  /// @param fee0 The fee amount for the first token in the pool.
  /// @param fee1 The fee amount for the second token in the pool.
  /// @return lowerTickFillup The lower tick value for the new liquidity range.
  /// @return upperTickFillup The upper tick value for the new liquidity range.
  /// @return liquidityOutFillup The liquidity amount added to the new range.
  function addFillup(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 tickSpacing,
    uint fee0,
    uint fee1
  ) external returns (int24 lowerTickFillup, int24 upperTickFillup, uint128 liquidityOutFillup) {
    uint balance0 = _balance(pool.token0());
    uint balance1 = _balance(pool.token1());

    require(balance0 >= fee0 && balance1 >= fee1, "Wrong fee");
    balance0 -= fee0;
    balance1 -= fee1;

    (, int24 tick, , , , ,) = pool.slot0();
    if (balance0 > balance1 * UniswapV3Lib.getPrice(address(pool), pool.token1()) / 10 ** IERC20Metadata(pool.token1()).decimals()) {
      // add token0 to half range
      lowerTickFillup = tick / tickSpacing * tickSpacing + tickSpacing;
      upperTickFillup = upperTick;
      (,, liquidityOutFillup) = UniswapV3Lib.addLiquidityPreview(address(pool), lowerTickFillup, upperTickFillup, balance0, 0);
      pool.mint(address(this), lowerTickFillup, upperTickFillup, liquidityOutFillup, "");
    } else {
      lowerTickFillup = lowerTick;
      upperTickFillup = tick / tickSpacing * tickSpacing - tickSpacing;
      (,, liquidityOutFillup) = UniswapV3Lib.addLiquidityPreview(address(pool), lowerTickFillup, upperTickFillup, 0, balance1);
      pool.mint(address(this), lowerTickFillup, upperTickFillup, liquidityOutFillup, "");
    }
  }

  //////////////////////////////////////////
  //            Exit from the pool
  //////////////////////////////////////////


  /// @notice Exit the pool and collect tokens proportional to the liquidity amount to exit.
  /// @param pool The Uniswap V3 pool to exit from.
  /// @param lowerTick The lower tick value for the pool.
  /// @param upperTick The upper tick value for the pool.
  /// @param lowerTickFillup The lower tick value for the fillup range in the pool.
  /// @param upperTickFillup The upper tick value for the fillup range in the pool.
  /// @param liquidity The current liquidity in the pool.
  /// @param liquidityFillup The current liquidity in the fillup range.
  /// @param liquidityAmountToExit The amount of liquidity to exit.
  /// @param _depositorSwapTokens A boolean indicating if need to use token B instead of token A.
  /// @return amountsOut An array containing the collected amounts for each token in the pool.
  /// @return totalLiquidity The updated total liquidity after the exit.
  /// @return totalLiquidityFillup The updated total liquidity in the fillup range after the exit.
  function exit(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 lowerTickFillup,
    int24 upperTickFillup,
    uint128 liquidity,
    uint128 liquidityFillup,
    uint128 liquidityAmountToExit,
    bool _depositorSwapTokens
  ) external returns (uint[] memory amountsOut, uint128 totalLiquidity, uint128 totalLiquidityFillup) {
    totalLiquidityFillup = 0;

    amountsOut = new uint[](2);
    (amountsOut[0], amountsOut[1]) = pool.burn(lowerTick, upperTick, liquidityAmountToExit);
    // all fees will be collected but not returned in amountsOut
    pool.collect(
      address(this),
      lowerTick,
      upperTick,
      type(uint128).max,
      type(uint128).max
    );

    // remove proportional part of fillup liquidity
    if (liquidityFillup != 0) {
      uint128 toRemoveFillUpAmount = liquidityFillup * liquidityAmountToExit / liquidity;
      (uint amountsOutFillup0, uint amountsOutFillup1) = pool.burn(lowerTickFillup, upperTickFillup, toRemoveFillUpAmount);
      pool.collect(
        address(this),
        lowerTickFillup,
        upperTickFillup,
        type(uint128).max,
        type(uint128).max
      );
      amountsOut[0] += amountsOutFillup0;
      amountsOut[1] += amountsOutFillup1;

      require(liquidityFillup >= toRemoveFillUpAmount, "Wrong fillup");
      totalLiquidityFillup = liquidityFillup - toRemoveFillUpAmount;
    }

    require(liquidity >= liquidityAmountToExit, "Wrong liquidity");
    totalLiquidity = liquidity - liquidityAmountToExit;

    if (_depositorSwapTokens) {
      (amountsOut[0], amountsOut[1]) = (amountsOut[1], amountsOut[0]);
    }
  }

  //////////////////////////////////////////
  //            Claim
  //////////////////////////////////////////

  /// @notice Claim rewards from the Uniswap V3 pool.
  /// @param pool The Uniswap V3 pool instance.
  /// @param lowerTick The lower tick of the pool's main range.
  /// @param upperTick The upper tick of the pool's main range.
  /// @param lowerTickFillup The lower tick of the pool's fill-up range.
  /// @param upperTickFillup The upper tick of the pool's fill-up range.
  /// @param rebalanceEarned0 The amount of token0 earned from rebalancing.
  /// @param rebalanceEarned1 The amount of token1 earned from rebalancing.
  /// @param _depositorSwapTokens A boolean indicating if need to use token B instead of token A.
  /// @return amountsOut An array containing the amounts of token0 and token1 claimed as rewards.
  function claimRewards(
    IUniswapV3Pool pool,
    int24 lowerTick,
    int24 upperTick,
    int24 lowerTickFillup,
    int24 upperTickFillup,
    uint rebalanceEarned0,
    uint rebalanceEarned1,
    bool _depositorSwapTokens
  ) external returns (uint[] memory amountsOut) {
    amountsOut = new uint[](2);
    pool.burn(lowerTick, upperTick, 0);
    (amountsOut[0], amountsOut[1]) = pool.collect(
      address(this),
      lowerTick,
      upperTick,
      type(uint128).max,
      type(uint128).max
    );
    if (lowerTickFillup != upperTickFillup) {
      pool.burn(lowerTickFillup, upperTickFillup, 0);
      (uint fillup0, uint fillup1) = pool.collect(
        address(this),
        lowerTickFillup,
        upperTickFillup,
        type(uint128).max,
        type(uint128).max
      );
      amountsOut[0] += fillup0;
      amountsOut[1] += fillup1;
    }
    amountsOut[0] += rebalanceEarned0;
    amountsOut[1] += rebalanceEarned1;
    if (_depositorSwapTokens) {
      (amountsOut[0], amountsOut[1]) = (amountsOut[1], amountsOut[0]);
    }
  }

  function isReadyToHardWork(State storage state, ITetuConverter converter) external view returns (bool isReady) {
    // check claimable amounts and compare with thresholds
    (uint fee0, uint fee1) = getFees(state);
    fee0 += state.rebalanceEarned0;
    fee1 += state.rebalanceEarned1;

    if (state.depositorSwapTokens) {
      (fee0, fee1) = (fee1, fee0);
    }

    address tokenA = state.tokenA;
    address tokenB = state.tokenB;
    IPriceOracle oracle = IPriceOracle(IConverterController(converter.controller()).priceOracle());
    uint priceA = oracle.getAssetPrice(tokenA);
    uint priceB = oracle.getAssetPrice(tokenB);

    uint fee0USD = fee0 * priceA / 1e18;
    uint fee1USD = fee1 * priceB / 1e18;

    return fee0USD > HARD_WORK_USD_FEE_THRESHOLD || fee1USD > HARD_WORK_USD_FEE_THRESHOLD;
  }

  //////////////////////////////////////////
  //            Rebalance
  //////////////////////////////////////////

  /// @dev Rebalances the current position, adjusts the tick range, and attempts to cover loss with pool rewards.
  /// @param state The State storage object.
  /// @param converter The TetuConverter contract.
  /// @param controller The Tetu controller address.
  /// @param oldInvestedAssets The amount of invested assets before rebalancing.
  /// @return tokenAmounts The token amounts for deposit (if length != 2 then do nothing).
  /// @return isNeedFillup Indicates if fill-up is required after rebalancing.
  function rebalance(
    State storage state,
    ITetuConverter converter,
    address controller,
    uint oldInvestedAssets
  ) external returns (
    uint[] memory tokenAmounts, // _depositorEnter(tokenAmounts) if length == 2
    bool isNeedFillup
  ) {
    tokenAmounts = new uint[](0);
    isNeedFillup = false;

    RebalanceLocalVariables memory vars = RebalanceLocalVariables({
    upperTick : state.upperTick,
    lowerTick : state.lowerTick,
    tickSpacing : state.tickSpacing,
    pool : state.pool,
    tokenA : state.tokenA,
    tokenB : state.tokenB,
    lastPrice : state.lastPrice,
    fuseThreshold : state.fuseThreshold,
    depositorSwapTokens : state.depositorSwapTokens,
    rebalanceEarned0 : state.rebalanceEarned0,
    rebalanceEarned1 : state.rebalanceEarned1,
    // setup initial values
    newRebalanceEarned0 : 0,
    newRebalanceEarned1 : 0,
    notCoveredLoss : 0,
    newLowerTick : 0,
    newUpperTick : 0,
    fillUp : state.fillUp,
    isStablePool : state.isStablePool,
    newPrice : 0
    });

    require(needRebalance(
        state.isFuseTriggered,
        vars.pool,
        vars.lowerTick,
        vars.upperTick,
        vars.tickSpacing,
        state.rebalanceTickRange
      ), "No rebalancing needed");

    vars.newPrice = getOracleAssetsPrice(converter, vars.tokenA, vars.tokenB);

    if (vars.isStablePool && isEnableFuse(vars.lastPrice, vars.newPrice, vars.fuseThreshold)) {
      /// enabling fuse: close debt and stop providing liquidity
      state.isFuseTriggered = true;
      emit FuseTriggered();

      UniswapV3DebtLib.closeDebt(
        converter,
        controller,
        vars.pool,
        vars.tokenA,
        vars.tokenB,
        vars.depositorSwapTokens,
        vars.rebalanceEarned0,
        vars.rebalanceEarned1,
        _getLiquidatorSwapSlippage(vars.pool)
      );

      vars.newRebalanceEarned0 = vars.rebalanceEarned0;
      vars.newRebalanceEarned1 = vars.rebalanceEarned1;
      vars.newLowerTick = vars.lowerTick;
      vars.newUpperTick = vars.upperTick;
    } else {
      if (vars.isStablePool) {
        state.lastPrice = vars.newPrice;
      }

      /// rebalancing debt with passing rebalanceEarned0, rebalanceEarned1 that will remain untouched
      UniswapV3DebtLib.rebalanceDebt(
        converter,
        controller,
        vars.pool,
        vars.tokenA,
        vars.tokenB,
        vars.fillUp,
        (vars.depositorSwapTokens ? vars.rebalanceEarned1 : vars.rebalanceEarned0),
        (vars.depositorSwapTokens ? vars.rebalanceEarned0 : vars.rebalanceEarned1),
        getEntryData(vars.pool, vars.lowerTick, vars.upperTick, vars.tickSpacing, vars.depositorSwapTokens),
        _getLiquidatorSwapSlippage(vars.pool)
      );

      /// trying to cover rebalance loss (IL + not hedged part of tokenB + swap cost) by pool rewards
      (vars.newRebalanceEarned0, vars.newRebalanceEarned1, vars.notCoveredLoss) = _calculateCoverLoss(
        TryCoverLossParams(
          vars.pool,
          vars.tokenA,
          vars.tokenB,
          vars.depositorSwapTokens,
          vars.rebalanceEarned0,
          vars.rebalanceEarned1,
          oldInvestedAssets
        ),
        UniswapV3DebtLib.getDeptTotalCollateralAmountOut(converter, vars.tokenA, vars.tokenB)
      );
      state.rebalanceEarned0 = vars.newRebalanceEarned0;
      state.rebalanceEarned1 = vars.newRebalanceEarned1;
      if (vars.notCoveredLoss != 0) {
        state.rebalanceLost += vars.notCoveredLoss;
      }

      // calculate and set new tick range
      (vars.newLowerTick, vars.newUpperTick) = _calcNewTickRange(vars.pool, vars.lowerTick, vars.upperTick, vars.tickSpacing);
      state.lowerTick = vars.newLowerTick;
      state.upperTick = vars.newUpperTick;


      tokenAmounts = new uint[](2);
      tokenAmounts[0] = _balance(vars.tokenA) - (vars.depositorSwapTokens ? vars.newRebalanceEarned1 : vars.newRebalanceEarned0);
      tokenAmounts[1] = _balance(vars.tokenB) - (vars.depositorSwapTokens ? vars.newRebalanceEarned0 : vars.newRebalanceEarned1);

      if (vars.fillUp) {
        isNeedFillup = true;
      }
    }
    emit Rebalanced();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ConverterStrategyBaseLib.sol";
import "./UniswapV3Lib.sol";

library UniswapV3DebtLib {

  //////////////////////////////////////////
  //            CONSTANTS
  //////////////////////////////////////////

  uint internal constant SELL_GAP = 100;
  /// @dev should be placed local, probably will be adjusted later
  uint internal constant BORROW_PERIOD_ESTIMATION = 30 days / 2;

  //////////////////////////////////////////
  //            STRUCTURES
  //////////////////////////////////////////

  struct RebalanceDebtFillUpLocalVariables {
    uint debtAmount;
    uint availableBalanceTokenA;
    uint availableBalanceTokenB;
    uint needToBorrowOrFreeFromBorrow;
  }

  //////////////////////////////////////////
  //            MAIN LOGIC
  //////////////////////////////////////////

  /// @dev Returns the total collateral amount out for the given token pair.
  /// @param tetuConverter The ITetuConverter instance.
  /// @param tokenA The address of tokenA.
  /// @param tokenB The address of tokenB.
  /// @return totalCollateralAmountOut The total collateral amount out for the token pair.
  function getDeptTotalCollateralAmountOut(ITetuConverter tetuConverter, address tokenA, address tokenB) internal returns (uint totalCollateralAmountOut) {
    (, totalCollateralAmountOut) = tetuConverter.getDebtAmountCurrent(address(this), tokenA, tokenB);
  }

  /// @dev Returns the total debt amount out for the given token pair.
  /// @param tetuConverter The ITetuConverter instance.
  /// @param tokenA The address of tokenA.
  /// @param tokenB The address of tokenB.
  /// @return totalDebtAmountOut The total debt amount out for the token pair.
  function getDeptTotalDebtAmountOut(ITetuConverter tetuConverter, address tokenA, address tokenB) internal returns (uint totalDebtAmountOut) {
    (totalDebtAmountOut,) = tetuConverter.getDebtAmountCurrent(address(this), tokenA, tokenB);
  }

  /// @dev Closes the debt positions for the given token pair.
  /// @param tetuConverter The ITetuConverter instance.
  /// @param controller The controller address.
  /// @param pool The IUniswapV3Pool instance.
  /// @param tokenA The address of tokenA.
  /// @param tokenB The address of tokenB.
  /// @param depositorSwapTokens A boolean indicating if need to use token B instead of token A.
  /// @param fee0 The fee amount for tokenA.
  /// @param fee1 The fee amount for tokenB.
  function closeDebt(
    ITetuConverter tetuConverter,
    address controller,
    IUniswapV3Pool pool,
    address tokenA,
    address tokenB,
    bool depositorSwapTokens,
    uint fee0,
    uint fee1,
    uint liquidatorSwapSlippage
  ) internal {
    uint tokenAFee = depositorSwapTokens ? fee1 : fee0;
    uint tokenBFee = depositorSwapTokens ? fee0 : fee1;
    _closeDebt(tetuConverter, controller, pool, tokenA, tokenB, tokenAFee, tokenBFee, liquidatorSwapSlippage);
  }

  /// @dev Rebalances the debt by either filling up or closing and reopening debt positions.
  function rebalanceDebt(
    ITetuConverter tetuConverter,
    address controller,
    IUniswapV3Pool pool,
    address tokenA,
    address tokenB,
    bool fillUp,
    uint tokenAFee,
    uint tokenBFee,
    bytes memory entryData,
    uint liquidatorSwapSlippage
  ) external {
    if (fillUp) {
      _rebalanceDebtFillup(tetuConverter, controller, pool, tokenA, tokenB, tokenAFee, tokenBFee, liquidatorSwapSlippage);
    } else {
      _closeDebt(tetuConverter, controller, pool, tokenA, tokenB, tokenAFee, tokenBFee, liquidatorSwapSlippage);
      _openDebt(tetuConverter, tokenA, tokenB, entryData, tokenAFee);
    }
  }

  /// @notice Closes debt by liquidating tokens as necessary.
  ///         This function helps ensure that the converter strategy maintains the appropriate balances
  ///         and debt positions for token A and token B, while accounting for fees and potential price impacts.
  function _closeDebt(
    ITetuConverter tetuConverter,
    address controller,
    IUniswapV3Pool pool,
    address tokenA,
    address tokenB,
    uint feeA,
    uint feeB,
    uint liquidatorSwapSlippage
  ) internal {
    uint debtAmount = getDeptTotalDebtAmountOut(tetuConverter, tokenA, tokenB);

    uint availableBalanceTokenA = _balance(tokenA);
    uint availableBalanceTokenB = _balance(tokenB);

    require(availableBalanceTokenA >= feeA && availableBalanceTokenB >= feeB, "Wrong balance");
    availableBalanceTokenA -= feeA;
    availableBalanceTokenB -= feeB;

    if (availableBalanceTokenB < debtAmount) {

      uint tokenBprice = UniswapV3Lib.getPrice(address(pool), tokenB);
      uint needToSellTokenA = tokenBprice * (debtAmount - availableBalanceTokenB) / 10 ** IERC20Metadata(tokenB).decimals();
      // add 1% gap for price impact
      needToSellTokenA += needToSellTokenA / SELL_GAP;

      if (needToSellTokenA < availableBalanceTokenA) {
        ConverterStrategyBaseLib.liquidate(ITetuLiquidator(IController(controller).liquidator()), tokenA, tokenB, needToSellTokenA, liquidatorSwapSlippage, 0);
      } else {
        // very rare case, but happens on long run backtests
        ConverterStrategyBaseLib.liquidate(ITetuLiquidator(IController(controller).liquidator()), tokenA, tokenB, availableBalanceTokenA, liquidatorSwapSlippage, 0);
        ConverterStrategyBaseLib.closePosition(
          tetuConverter,
          tokenA,
          tokenB,
          _balance(tokenB) - feeB
        );
        // refresh dept amount
        debtAmount = getDeptTotalDebtAmountOut(tetuConverter, tokenA, tokenB);
        if (debtAmount > 0) {
          tokenBprice = UniswapV3Lib.getPrice(address(pool), tokenB);
          needToSellTokenA = tokenBprice * debtAmount / 10 ** IERC20Metadata(tokenB).decimals();
          needToSellTokenA += needToSellTokenA / SELL_GAP;
          ConverterStrategyBaseLib.liquidate(ITetuLiquidator(IController(controller).liquidator()), tokenA, tokenB, needToSellTokenA, liquidatorSwapSlippage, 0);
        }
      }
    }

    if (debtAmount > 0) {
      ConverterStrategyBaseLib.closePosition(
        tetuConverter,
        tokenA,
        tokenB,
        debtAmount
      );
    }

    ConverterStrategyBaseLib.liquidate(ITetuLiquidator(IController(controller).liquidator()), tokenB, tokenA, _balance(tokenB) - feeB, liquidatorSwapSlippage, 0);
  }

  /// @dev Opens a new debt position using entry data.
  /// @param tetuConverter The TetuConverter contract.
  /// @param tokenA The address of token A.
  /// @param tokenB The address of token B.
  /// @param entryData The data required to open a position.
  /// @param feeA The fee associated with token A.
  function _openDebt(
    ITetuConverter tetuConverter,
    address tokenA,
    address tokenB,
    bytes memory entryData,
    uint feeA
  ) internal {
    ConverterStrategyBaseLib.openPosition(
      tetuConverter,
      entryData,
      tokenA,
      tokenB,
      _balance(tokenA) - feeA,
      0
    );
  }

  /// @dev Rebalances the debt to reach the optimal ratio between token A and token B.
  function _rebalanceDebtFillup(
    ITetuConverter tetuConverter,
    address controller,
    IUniswapV3Pool pool,
    address tokenA,
    address tokenB,
    uint tokenAFee,
    uint tokenBFee,
    uint liquidatorSwapSlippage
  ) internal {
    RebalanceDebtFillUpLocalVariables memory vars;
    vars.debtAmount = getDeptTotalDebtAmountOut(tetuConverter, tokenA, tokenB);

    vars.availableBalanceTokenA = getBalanceWithoutFees(tokenA, tokenAFee);
    vars.availableBalanceTokenB = getBalanceWithoutFees(tokenB, tokenBFee);

    if (vars.availableBalanceTokenB > vars.debtAmount) {
      vars.needToBorrowOrFreeFromBorrow = vars.availableBalanceTokenB - vars.debtAmount;

      if (_getCollateralAmountForBorrow(tetuConverter, tokenA, tokenB, vars.needToBorrowOrFreeFromBorrow) < vars.availableBalanceTokenA) {
        ConverterStrategyBaseLib.openPosition(
          tetuConverter,
          abi.encode(2),
          tokenA,
          tokenB,
          vars.needToBorrowOrFreeFromBorrow,
          0
        );
      } else {
        ConverterStrategyBaseLib.closePosition(
          tetuConverter,
          tokenA,
          tokenB,
          vars.debtAmount
        );

        vars.availableBalanceTokenB = getBalanceWithoutFees(tokenB, tokenBFee);

        ConverterStrategyBaseLib.liquidate(ITetuLiquidator(IController(controller).liquidator()), tokenB, tokenA, vars.availableBalanceTokenB, liquidatorSwapSlippage, 0);

        vars.availableBalanceTokenA = getBalanceWithoutFees(tokenA, tokenAFee);

        ConverterStrategyBaseLib.openPosition(
          tetuConverter,
          abi.encode(1, 1, 1),
          tokenA,
          tokenB,
          vars.availableBalanceTokenA,
          0
        );
      }
    } else {
      vars.needToBorrowOrFreeFromBorrow = vars.debtAmount - vars.availableBalanceTokenB;
      if (vars.availableBalanceTokenB > vars.needToBorrowOrFreeFromBorrow) {
        ConverterStrategyBaseLib.closePosition(
          tetuConverter,
          tokenA,
          tokenB,
          vars.needToBorrowOrFreeFromBorrow
        );
      } else {
        uint needToSellTokenA = UniswapV3Lib.getPrice(address(pool), tokenB) * vars.needToBorrowOrFreeFromBorrow / 10 ** IERC20Metadata(tokenB).decimals();
        // add % gap for price impact
        needToSellTokenA += needToSellTokenA / SELL_GAP;
        ConverterStrategyBaseLib.liquidate(ITetuLiquidator(IController(controller).liquidator()), tokenA, tokenB, needToSellTokenA, liquidatorSwapSlippage, 0);

        vars.availableBalanceTokenB = getBalanceWithoutFees(tokenB, tokenBFee);

        ConverterStrategyBaseLib.closePosition(
          tetuConverter,
          tokenA,
          tokenB,
          vars.debtAmount < vars.availableBalanceTokenB ? vars.debtAmount : vars.availableBalanceTokenB
        );

        vars.availableBalanceTokenA = getBalanceWithoutFees(tokenA, tokenAFee);

        ConverterStrategyBaseLib.openPosition(
          tetuConverter,
          abi.encode(1, 1, 1),
          tokenA,
          tokenB,
          vars.availableBalanceTokenA,
          0
        );
      }
    }
  }

  /// @dev Calculates the collateral amount required for borrowing a specified amount.
  /// @param tetuConverter The TetuConverter contract.
  /// @param tokenA The address of token A.
  /// @param tokenB The address of token B.
  /// @param needToBorrow The amount that needs to be borrowed.
  /// @return collateralAmount The amount of collateral required for borrowing the specified amount.
  function _getCollateralAmountForBorrow(
    ITetuConverter tetuConverter,
    address tokenA,
    address tokenB,
    uint needToBorrow
  ) internal view returns (uint collateralAmount) {
    ConverterStrategyBaseLib.OpenPositionLocal memory vars;
    (vars.converters, vars.collateralsRequired, vars.amountsToBorrow,) = tetuConverter.findBorrowStrategies(
      abi.encode(2),
      tokenA,
      needToBorrow,
      tokenB,
      BORROW_PERIOD_ESTIMATION
    );

    uint len = vars.converters.length;
    if (len > 0) {
      for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
        vars.amountToBorrow = needToBorrow < vars.amountsToBorrow[i]
        ? needToBorrow
        : vars.amountsToBorrow[i];
        vars.collateral = needToBorrow < vars.amountsToBorrow[i]
        ? vars.collateralsRequired[i] * needToBorrow / vars.amountsToBorrow[i]
        : vars.collateralsRequired[i];
        needToBorrow -= vars.amountToBorrow;
        if (needToBorrow == 0) break;
      }
    }
    return vars.collateral;
  }

  /// @notice Get the balance of the given token held by the contract.
  /// @param token The token address.
  /// @return The balance of the token.
  function _balance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }

  /// @dev Gets the token balance without fees.
  /// @param token The token address.
  /// @param fee The fee amount to be subtracted from the balance.
  /// @return balanceWithoutFees The token balance without the specified fee amount.
  function getBalanceWithoutFees(address token, uint fee) internal view returns (uint balanceWithoutFees) {
    balanceWithoutFees = _balance(token);
    require(balanceWithoutFees >= fee, "Balance lower than fee");
    balanceWithoutFees -= fee;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../integrations/uniswap/IUniswapV3Pool.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";

/// @title Uniswap V3 liquidity management helper
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library UniswapV3Lib {
  uint8 internal constant RESOLUTION = 96;
  uint internal constant Q96 = 0x1000000000000000000000000;
  uint private constant TWO_96 = 2 ** 96;
  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 private constant MIN_SQRT_RATIO = 4295128739 + 1;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 private constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = - 887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = - MIN_TICK;

  struct PoolPosition {
    address pool;
    int24 lowerTick;
    int24 upperTick;
    uint128 liquidity;
    address owner;
  }

  function getTickSpacing(uint24 fee) external pure returns (int24) {
    if (fee == 10000) {
      return 200;
    }
    if (fee == 3000) {
      return 60;
    }
    if (fee == 500) {
      return 10;
    }
    return 1;
  }

  function getFees(PoolPosition memory position) public view returns (uint fee0, uint fee1) {
    bytes32 positionId = _getPositionId(position);
    IUniswapV3Pool pool = IUniswapV3Pool(position.pool);
    (, int24 tick, , , , ,) = pool.slot0();
    (, uint feeGrowthInside0Last, uint feeGrowthInside1Last, uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(positionId);
    fee0 = _computeFeesEarned(position, true, feeGrowthInside0Last, tick) + uint(tokensOwed0);
    fee1 = _computeFeesEarned(position, false, feeGrowthInside1Last, tick) + uint(tokensOwed1);
  }

  function addLiquidityPreview(address pool_, int24 lowerTick_, int24 upperTick_, uint amount0Desired_, uint amount1Desired_) external view returns (uint amount0Consumed, uint amount1Consumed, uint128 liquidityOut) {
    IUniswapV3Pool pool = IUniswapV3Pool(pool_);
    (uint160 sqrtRatioX96, , , , , ,) = pool.slot0();
    liquidityOut = getLiquidityForAmounts(sqrtRatioX96, lowerTick_, upperTick_, amount0Desired_, amount1Desired_);
    (amount0Consumed, amount1Consumed) = getAmountsForLiquidity(sqrtRatioX96, lowerTick_, upperTick_, liquidityOut);
  }

  /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
  /// pool prices and the prices at the tick boundaries
  function getLiquidityForAmounts(
    uint160 sqrtRatioX96,
    int24 lowerTick,
    int24 upperTick,
    uint amount0,
    uint amount1
  ) public pure returns (uint128 liquidity) {
    uint160 sqrtRatioAX96 = _getSqrtRatioAtTick(lowerTick);
    uint160 sqrtRatioBX96 = _getSqrtRatioAtTick(upperTick);
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      liquidity = _getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      uint128 liquidity0 = _getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
      uint128 liquidity1 = _getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);
      liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    } else {
      liquidity = _getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
    }
  }

  /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
  /// pool prices and the prices at the tick boundaries
  function getAmountsForLiquidity(
    uint160 sqrtRatioX96,
    int24 lowerTick,
    int24 upperTick,
    uint128 liquidity
  ) public pure returns (uint amount0, uint amount1) {
    uint160 sqrtRatioAX96 = _getSqrtRatioAtTick(lowerTick);
    uint160 sqrtRatioBX96 = _getSqrtRatioAtTick(upperTick);

    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }

    if (sqrtRatioX96 <= sqrtRatioAX96) {
      amount0 = _getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    } else if (sqrtRatioX96 < sqrtRatioBX96) {
      amount0 = _getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
      amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
    } else {
      amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }
  }

  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint a,
    uint b,
    uint denominator
  ) public pure returns (uint result) {
  unchecked {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint prod0;
    // Least significant 256 bits of the product
    uint prod1;
    // Most significant 256 bits of the product
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
    uint remainder;
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
    // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint
    uint twos = denominator & (~denominator + 1);

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
    uint inv = (3 * denominator) ^ 2;
    // Now use Newton-Raphson iteration to improve the precision.
    // Thanks to Hensel's lifting lemma, this also works in modular
    // arithmetic, doubling the correct bits in each step.
    inv *= 2 - denominator * inv;
    // inverse mod 2**8
    inv *= 2 - denominator * inv;
    // inverse mod 2**16
    inv *= 2 - denominator * inv;
    // inverse mod 2**32
    inv *= 2 - denominator * inv;
    // inverse mod 2**64
    inv *= 2 - denominator * inv;
    // inverse mod 2**128
    inv *= 2 - denominator * inv;
    // inverse mod 2**256

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

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint a,
    uint b,
    uint denominator
  ) internal pure returns (uint result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < type(uint).max);
      result++;
    }
  }

  /// @notice Calculates price in pool
  function getPrice(address pool_, address tokenIn) public view returns (uint) {
    IUniswapV3Pool pool = IUniswapV3Pool(pool_);
    address token0 = pool.token0();
    address token1 = pool.token1();

    uint tokenInDecimals = tokenIn == token0 ? IERC20Metadata(token0).decimals() : IERC20Metadata(token1).decimals();
    uint tokenOutDecimals = tokenIn == token1 ? IERC20Metadata(token0).decimals() : IERC20Metadata(token1).decimals();
    (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

    uint divider = tokenOutDecimals < 18 ? _max(10 ** tokenOutDecimals / 10 ** tokenInDecimals, 1) : 1;

    uint priceDigits = _countDigits(uint(sqrtPriceX96));
    uint purePrice;
    uint precision;
    if (tokenIn == token0) {
      precision = 10 ** ((priceDigits < 29 ? 29 - priceDigits : 0) + tokenInDecimals);
      uint part = uint(sqrtPriceX96) * precision / TWO_96;
      purePrice = part * part;
    } else {
      precision = 10 ** ((priceDigits > 29 ? priceDigits - 29 : 0) + tokenInDecimals);
      uint part = TWO_96 * precision / uint(sqrtPriceX96);
      purePrice = part * part;
    }
    return purePrice / divider / precision / (precision > 1e18 ? (precision / 1e18) : 1);
  }

  /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
  /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param amount0 The amount0 being sent in
  /// @return liquidity The amount of returned liquidity
  function _getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint amount0) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    uint intermediate = mulDiv(sqrtRatioAX96, sqrtRatioBX96, Q96);
    return _toUint128(mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
  /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param amount1 The amount1 being sent in
  /// @return liquidity The amount of returned liquidity
  function _getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint amount1) internal pure returns (uint128 liquidity) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    return _toUint128(mulDiv(amount1, Q96, sqrtRatioBX96 - sqrtRatioAX96));
  }

  /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The liquidity being valued
  /// @return amount0 The amount0
  function _getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint amount0) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    return mulDivRoundingUp(1, mulDivRoundingUp(uint(liquidity) << RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96), sqrtRatioAX96);
  }

  /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
  /// @param sqrtRatioAX96 A sqrt price
  /// @param sqrtRatioBX96 Another sqrt price
  /// @param liquidity The liquidity being valued
  /// @return amount1 The amount1
  function _getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) internal pure returns (uint amount1) {
    if (sqrtRatioAX96 > sqrtRatioBX96) {
      (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
    }
    return mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Q96);
  }

  function _computeFeesEarned(
    PoolPosition memory position,
    bool isZero,
    uint feeGrowthInsideLast,
    int24 tick
  ) internal view returns (uint fee) {
    IUniswapV3Pool pool = IUniswapV3Pool(position.pool);
    uint feeGrowthOutsideLower;
    uint feeGrowthOutsideUpper;
    uint feeGrowthGlobal;
    if (isZero) {
      feeGrowthGlobal = pool.feeGrowthGlobal0X128();
      (,, feeGrowthOutsideLower,,,,,) = pool.ticks(position.lowerTick);
      (,, feeGrowthOutsideUpper,,,,,) = pool.ticks(position.upperTick);
    } else {
      feeGrowthGlobal = pool.feeGrowthGlobal1X128();
      (,,, feeGrowthOutsideLower,,,,) = pool.ticks(position.lowerTick);
      (,,, feeGrowthOutsideUpper,,,,) = pool.ticks(position.upperTick);
    }

  unchecked {
    // calculate fee growth below
    uint feeGrowthBelow;
    if (tick >= position.lowerTick) {
      feeGrowthBelow = feeGrowthOutsideLower;
    } else {
      feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
    }

    // calculate fee growth above
    uint feeGrowthAbove;
    if (tick < position.upperTick) {
      feeGrowthAbove = feeGrowthOutsideUpper;
    } else {
      feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
    }

    uint feeGrowthInside =
    feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;
    fee = mulDiv(
      position.liquidity,
      feeGrowthInside - feeGrowthInsideLast,
      0x100000000000000000000000000000000
    );
  }
  }

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function _getSqrtRatioAtTick(int24 tick)
  internal
  pure
  returns (uint160 sqrtPriceX96)
  {
    uint256 absTick =
    tick < 0 ? uint256(- int256(tick)) : uint256(int256(tick));

    // EDIT: 0.8 compatibility
    require(absTick <= uint256(int256(MAX_TICK)), "T");

    uint256 ratio =
    absTick & 0x1 != 0
    ? 0xfffcb933bd6fad37aa2d162d1a594001
    : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0)
      ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    if (absTick & 0x4 != 0)
      ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
    if (absTick & 0x8 != 0)
      ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
    if (absTick & 0x10 != 0)
      ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
    if (absTick & 0x20 != 0)
      ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
    if (absTick & 0x40 != 0)
      ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
    if (absTick & 0x80 != 0)
      ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
    if (absTick & 0x100 != 0)
      ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
    if (absTick & 0x200 != 0)
      ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
    if (absTick & 0x400 != 0)
      ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
    if (absTick & 0x800 != 0)
      ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
    if (absTick & 0x1000 != 0)
      ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
    if (absTick & 0x2000 != 0)
      ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
    if (absTick & 0x4000 != 0)
      ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
    if (absTick & 0x8000 != 0)
      ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
    if (absTick & 0x10000 != 0)
      ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
    if (absTick & 0x20000 != 0)
      ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
    if (absTick & 0x40000 != 0)
      ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
    if (absTick & 0x80000 != 0)
      ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    if (tick > 0) ratio = type(uint256).max / ratio;

    // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
    // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
    // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
    sqrtPriceX96 = uint160(
      (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
    );
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(
      sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
      "R"
    );
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

    tick = _getFinalTick(log_2, sqrtPriceX96);
  }

  function _getFinalTick(int256 log_2, uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    // 128.128 number
    int256 log_sqrt10001 = log_2 * 255738958999603826347141;

    int24 tickLow =
    int24(
      (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
    );
    int24 tickHi =
    int24(
      (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
    );

    tick = (tickLow == tickHi)
    ? tickLow
    : (_getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
    ? tickHi
    : tickLow);
  }

  function _getPositionId(PoolPosition memory position) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(position.owner, position.lowerTick, position.upperTick));
  }

  function _countDigits(uint n) internal pure returns (uint) {
    if (n == 0) {
      return 0;
    }
    uint count = 0;
    while (n != 0) {
      n = n / 10;
      ++count;
    }
    return count;
  }

  function _min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function _max(uint a, uint b) internal pure returns (uint) {
    return a > b ? a : b;
  }

  function _toUint128(uint x) private pure returns (uint128 y) {
    require((y = uint128(x)) == x);
  }
}