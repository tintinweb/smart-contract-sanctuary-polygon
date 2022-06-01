// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../openzeppelin/IERC20.sol";
import "../openzeppelin/IERC20Metadata.sol";
import "../openzeppelin/Address.sol";
import "../third_party/uniswap/IUniswapV2Factory.sol";
import "../third_party/uniswap/IUniswapV2Pair.sol";
import "../third_party/IERC20Name.sol";
import "../swap/libraries/Math.sol";
import "../swap/interfaces/ITetuSwapPair.sol";


/// @title Utility contract for using on website UI and other integrations (like MultiSwap2)
/// @author belbix, bogdoslav
contract ContractUtils {
  using Address for address;

  struct LpData {
    address lp;
    address token0;
    address token1;
  }

  struct ReservesData {
    uint reserve0;
    uint reserve1;
  }

  // ********************* ERC20 UTILS ************************************

  function erc20Names(address[] memory tokens) external view returns (string[] memory) {
    string[] memory result = new string[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      result[i] = IERC20Name(tokens[i]).name();
    }
    return result;
  }

  function erc20Symbols(address[] memory tokens) external view returns (string[] memory) {
    string[] memory result = new string[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      result[i] = IERC20Name(tokens[i]).symbol();
    }
    return result;
  }

  // @note Some token contract addresses was destructed or wrong. This function does not revert on such addresses
  function erc20SymbolsSafe(address[] memory tokens) external view returns (string[] memory result) {
   result = new string[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      if (token.isContract()) {
        try IERC20Name(token).symbol() returns (string memory symbol) {
          result[i] = symbol;
        } catch Error(string memory /*reason*/) {
        } catch Panic(uint /*errorCode*/) {
        } catch (bytes memory /*lowLevelData*/) {
        }
      }
    }
  }

  function erc20Decimals(address[] memory tokens) external view returns (uint8[] memory) {
    uint8[] memory result = new uint8[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      result[i] = IERC20Metadata(tokens[i]).decimals();
    }
    return result;
  }

  function erc20Balances(address[] memory tokens, address adr) external view returns (uint[] memory) {
    uint[] memory result = new uint[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      result[i] = IERC20(tokens[i]).balanceOf(adr);
    }
    return result;
  }

  function erc20BalancesForAddresses(address token, address[] memory _addresses) external view returns (uint[] memory) {
    uint[] memory result = new uint[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = IERC20(token).balanceOf(_addresses[i]);
    }
    return result;
  }

  function erc20TotalSupply(address[] memory tokens) external view returns (uint[] memory) {
    uint[] memory result = new uint[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      result[i] = IERC20(tokens[i]).totalSupply();
    }
    return result;
  }

  // ********************* UNISWAP V2 UTILS ************************************

  /// @dev Used for MultiSwap2
  function loadPairsUniswapV2(address factoryAddress, uint skip, uint count )
  external view returns (LpData[] memory pairs) {
    IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);
    uint allPairsLength = factory.allPairsLength();
    uint maxPair = Math.min(allPairsLength, skip + count);
    pairs = new LpData[](maxPair - skip);

    uint b = 0;
    for (uint p = skip; p < maxPair; p++) {
      address pairAddress = factory.allPairs(p);
      IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
      address token0 = pair.token0();
      address token1 = pair.token1();

      pairs[b++] = LpData({lp:pairAddress, token0:token0, token1: token1});
    }
  }

  /// @dev Used for MultiSwap2
  function loadPairsReserves(address[] memory pairs)
  external view returns (ReservesData[] memory data) {
    uint len = pairs.length;
    data = new ReservesData[](len);

    for (uint i = 0; i < len; i++) {
      address pairAddress = pairs[i];
      IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
      try pair.getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
        data[i] = ReservesData({reserve0:reserve0, reserve1:reserve1});
      } catch { // any error interpret as nil reserves
        data[i] = ReservesData({reserve0:0, reserve1:0});
      }
    }
  }

  /// @dev Used for MultiSwap2
  function loadPairsFees(address[] memory pairs)
  external view returns (uint16[] memory fees) {
    uint len = pairs.length;
    fees = new uint16[](len);

    for (uint i = 0; i < len; i++) {
      fees[i] = uint16(_getTetuSwapFee(pairs[i]));
    }
  }

  /// @dev returns fee for tetuswap or default uniswap v2 fee for other swaps
  function _getTetuSwapFee(address pair)
  internal view returns (uint) {
    try ITetuSwapPair(pair).fee() returns (uint fee) {
      return fee;
    } catch Error(string memory /*reason*/) {
    } catch Panic(uint /*errorCode*/) {
    } catch (bytes memory /*lowLevelData*/) {
    }
    return 30;
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

import "./IERC20.sol";

/**
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC20Name {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Uniswap Math https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
///        A library for performing various math operations
library Math {

  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  /// @dev Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    z = 0;
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ITetuSwapPair {

  function balanceOfVaultUnderlying(address _token) external view returns (uint);

  function setFee(uint _fee) external;

  function setVaults(address _vault0, address _vault1) external;

  function setRewardRecipient(address _recipient) external;

  function claimAll() external;

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function rewardRecipient() external view returns (address);

  function fee() external view returns (uint);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function vault0() external view returns (address);

  function vault1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function sync() external;

  function initialize(
    address _token0,
    address _token1,
    uint _fee
  ) external;

}