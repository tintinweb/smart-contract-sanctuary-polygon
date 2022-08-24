/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// File: contracts/poolBlocks/RedemptionQueue.sol


pragma solidity ^0.8.0;

library RedemptionQueue {
  struct Request {
    address owner;
    uint256 amount;
    uint256 time;
  }

  struct Queue {
    mapping(uint256 => Request) _internal;
    uint256 _first;
    uint256 _last;
  }

  function init(Queue storage _queue) public {
    _queue._first = 1;
  }

  function empty(Queue storage _queue) public view returns (bool) {
    return (_queue._last < _queue._first);
  }

  function get(Queue storage _queue) public view returns (Request storage data) {
    return _queue._internal[_queue._first];
  }

  function getBy(Queue storage _queue, uint256 _index) public view returns (Request storage data) {
    return _queue._internal[_index];
  }

  function enqueue(Queue storage _queue, Request memory _data) public {
    _queue._last += 1;
    _queue._internal[_queue._last] = _data;
  }

  function dequeue(Queue storage _queue) public returns (Request memory data) {
    require(_queue._last >= _queue._first); // non-empty queue

    data = _queue._internal[_queue._first];

    delete _queue._internal[_queue._first];
    _queue._first += 1;
  }

  function getAll(Queue storage _queue) public view returns (Request[] memory requests) {
    if (_queue._first > _queue._last) return new Request[](0);
    uint256 length = _queue._last - _queue._first + 1;
    requests = new Request[](length);
    for (uint256 i = 0; i < length; i++) {
      requests[i] = getBy(_queue, _queue._first + i);
    }
  }
}

// File: contracts/specification/IDerivativeSpecification.sol


pragma solidity ^0.8.0;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
  /// @notice Proof of a derivative specification
  /// @dev Verifies that contract is a derivative specification
  /// @return true if contract is a derivative specification
  function isDerivativeSpecification() external pure returns (bool);

  /// @notice Set of oracles that are relied upon to measure changes in the state of the world
  /// between the start and the end of the Live period
  /// @dev Should be resolved through OracleRegistry contract
  /// @return oracle symbols
  function underlyingOracleSymbols() external view returns (bytes32[] memory);

  /// @notice Algorithm that, for the type of oracle used by the derivative,
  /// finds the value closest to a given timestamp
  /// @dev Should be resolved through OracleIteratorRegistry contract
  /// @return oracle iterator symbols
  function underlyingOracleIteratorSymbols() external view returns (bytes32[] memory);

  /// @notice Type of collateral that users submit to mint the derivative
  /// @dev Should be resolved through CollateralTokenRegistry contract
  /// @return collateral token symbol
  function collateralTokenSymbol() external view returns (bytes32);

  /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
  /// and the initial collateral split to the final collateral split
  /// @dev Should be resolved through CollateralSplitRegistry contract
  /// @return collateral split symbol
  function collateralSplitSymbol() external view returns (bytes32);

  function denomination(uint256 _settlement, uint256 _referencePrice)
    external
    view
    returns (uint256);

  function referencePrice(uint256 _price, uint256 _position) external view returns (uint256);
}

// File: contracts/collateralSplits/ICollateralSplit.sol



pragma solidity ^0.8.0;

/// @title Collateral Split interface
/// @notice Contains mathematical functions used to calculate relative claim
/// on collateral of primary and complement assets after settlement.
/// @dev Created independently from specification and published to the CollateralSplitRegistry
interface ICollateralSplit {
  /// @notice Proof of collateral split contract
  /// @dev Verifies that contract is a collateral split contract
  /// @return true if contract is a collateral split contract
  function isCollateralSplit() external pure returns (bool);

  /// @notice Symbol of the collateral split
  /// @dev Should be resolved through CollateralSplitRegistry contract
  /// @return collateral split specification symbol
  function symbol() external pure returns (string memory);

  /// @notice Calcs primary asset class' share of collateral at settlement.
  /// @dev Returns ranged value between 0 and 1 multiplied by 10 ^ 12
  /// @param _underlyingStarts underlying values in the start of Live period
  /// @param _underlyingEndRoundHints specify for each oracle round of the end of Live period
  /// @return _split primary asset class' share of collateral at settlement
  /// @return _underlyingEnds underlying values in the end of Live period
  function split(
    address[] calldata _oracles,
    address[] calldata _oracleIterators,
    int256[] calldata _underlyingStarts,
    uint256 _settleTime,
    uint256[] calldata _underlyingEndRoundHints
  ) external view returns (uint256 _split, int256[] memory _underlyingEnds);
}

// File: contracts/volatility/IVolatilitySurface.sol


pragma solidity ^0.8.0;

interface IVolatilitySurface {
  function calcSigmaATM(bytes16 _omega, bytes16 _ttm) external view returns (bytes16);

  function calcSigmaATMReverted(bytes16 _sigmaTTM, bytes16 _ttm) external view returns (bytes16);

  function calcSigma(
    bytes16 _sigmaATM,
    bytes16 _mu,
    bytes16 _ttm
  ) external view returns (bytes16);

  function calcSigmaReverted(
    bytes16 _sigma,
    bytes16 _mu,
    bytes16 _ttm
  ) external view returns (bytes16);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol


pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol


pragma solidity ^0.8.0;


interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// File: contracts/utility/ISettableFeed.sol


pragma solidity ^0.8.0;

interface ISettableFeed is AggregatorV2V3Interface {
  function setLatestRoundData(int256 _answer, uint256 _timestamp) external;
}

// File: contracts/oracleIterators/IOracleIterator.sol


pragma solidity ^0.8.0;

interface IOracleIterator {
  /// @notice Proof of oracle iterator contract
  /// @dev Verifies that contract is a oracle iterator contract
  /// @return true if contract is a oracle iterator contract
  function isOracleIterator() external pure returns (bool);

  /// @notice Symbol of the oracle iterator
  /// @dev Should be resolved through OracleIteratorRegistry contract
  /// @return oracle iterator symbol
  function symbol() external pure returns (string memory);

  /// @notice Algorithm that, for the type of oracle used by the derivative,
  //  finds the value closest to a given timestamp
  /// @param _oracle iteratable oracle through
  /// @param _timestamp a given timestamp
  /// @param _roundHint specified a round for a given timestamp
  /// @return roundId the roundId closest to a given timestamp
  /// @return value the value closest to a given timestamp
  /// @return timestamp the timestamp closest to a given timestamp
  function getRound(
    address _oracle,
    uint256 _timestamp,
    uint256 _roundHint
  )
    external
    view
    returns (
      uint80 roundId,
      int256 value,
      uint256 timestamp
    );
}

// File: contracts/volatility/IVolatilityEvolution.sol


pragma solidity ^0.8.0;



interface IVolatilityEvolution {
  struct UnderlyingParams {
    IVolatilitySurface surface;
    ISettableFeed feed;
    IOracleIterator feedIterator;
    bytes16 omegaTarget;
    bytes16 omegaMin;
    bytes16 omegaMax;
    bytes16 deltaOmegaMin;
    bytes16 deltaOmegaMax;
    bytes16 sigmaMin;
    bytes16 sigmaMax;
    bytes16 thetaConv;
  }

  struct VolatilityParams {
    bytes16 ttm;
    bytes16 mu;
    bytes16 sigma;
    bytes16 omegaCurrent;
  }

  function calculateVolatility(
    uint256 _pointInTime,
    address _underlying,
    bytes16 _ttm,
    bytes16 _mu,
    uint256 omegaRoundHint
  ) external view returns (bytes16 sigma, bytes16 omega);

  function updateVolatility(
    uint256 _pointInTime,
    VolatilityParams memory _volParams,
    address _underlying,
    bytes16 _underlyingPrice,
    bytes16 _strike,
    bytes16 _priceNorm,
    bool _buyPrimary
  ) external;
}

// File: contracts/IUnderlyingLiquidityValuer.sol


pragma solidity ^0.8.0;

interface IUnderlyingLiquidityValuer {
  function getUnderlyingLiquidityValue(address underlying) external returns (uint256 liquidityValue);
}

// File: contracts/poolBlocks/IPoolTypes.sol


pragma solidity ^0.8.0;




interface IPoolTypes {
  enum PriceType {
    mid,
    ask,
    bid
  }

  enum Side {
    Primary,
    Complement,
    Empty,
    Both
  }

  enum Mode {
    Temp,
    Reinvest
  }

  struct Sequence {
    Mode mode;
    Side side;
    uint256 settlementDelta;
    uint256 strikePosition;
  }

  struct DerivativeConfig {
    IDerivativeSpecification specification;
    address[] underlyingOracles;
    address[] underlyingOracleIterators;
    address collateralToken;
    ICollateralSplit collateralSplit;
  }

  struct Derivative {
    DerivativeConfig config;
    address terms;
    Sequence sequence;
    DerivativeParams params;
  }

  struct DerivativeParams {
    uint256 priceReference;
    uint256 settlement;
    uint256 denomination;
  }

  struct Vintage {
    Pair rollRate;
    Pair releaseRate;
    uint256 priceReference;
  }

  struct Pair {
    uint256 primary;
    uint256 complement;
  }

  struct PoolSnapshot {
    Derivative[] derivatives;
    address exposureAddress;
    uint256 collateralLocked;
    uint256 collateralFree;
    Pair[] derivativePositions;
    IVolatilityEvolution volatilityEvolution;
    IUnderlyingLiquidityValuer underlyingLiquidityValuer;
  }

  struct PricePair {
    int256 primary;
    int256 complement;
  }

  struct OtherPrices {
    int256 collateral;
    int256 underlying;
    uint256 volatilityRoundHint;
  }

  struct SettlementValues {
    Pair value;
    uint256 underlyingPrice;
  }

  struct RolloverTrade {
    Pair inward;
    Pair outward;
  }

  struct DerivativeSettlement {
    uint256 settlement;
    Pair value;
    Pair position;
  }

  struct PoolSharePriceHints {
    bool hintLess;
    uint256 collateralPrice;
    uint256[] underlyingRoundHintsIndexed;
    uint256 volatilityRoundHint;
  }

  struct PoolBalance {
    uint256 collateralLocked;
    uint256 collateralFree;
    uint256 releasedWinnings;
    uint256 releasedLiquidityTotal;
  }

  struct RolloverHints {
    uint256 derivativeIndex;
    uint256 collateralRoundHint;
    uint256[] underlyingRoundHintsIndexed;
    uint256 volatilityRoundHint;
  }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/portfolio/ITraderPortfolio.sol


pragma solidity ^0.8.0;

interface ITraderPortfolio is IERC721 {
  function getPortfolioBy(address _user) external view returns (uint256);
  function getOrCreatePortfolioBy(address _user) external returns (uint256);
}

// File: contracts/exposure/IExposure.sol


pragma solidity ^0.8.0;

interface IExposure is IPoolTypes {
  function calcExposure(
    Derivative[] memory derivatives,
    Pair[] memory positions,
    uint256 collateralAmount
  ) external view returns (uint256);

  function calcCollateralExposureLimit(
    Derivative[] memory derivatives,
    Pair[] memory positions
  ) external view returns (uint256);

  function calcInputPercent(
    uint256 derivativeIndex,
    Derivative[] memory derivatives,
    Pair[] memory positions,
    uint256 collateralFreeAmount,
    uint256 inDerivativeAmountNew,
    uint256 outDerivativeAmountNew,
    uint256 collateralAmountNew
  ) external view returns (bytes16 percent);

  function getCoefficients(
    address[] memory _underlyings
  ) external view returns(uint256[4][] memory coefficients);

  function getWeight(
    uint256 _derivativeIndex
  ) external view returns(uint256);
}

// File: contracts/share/IERC20MintedBurnable.sol


pragma solidity ^0.8.0;

interface IERC20MintedBurnable is IERC20 {
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;
}

// File: contracts/poolBlocks/IPoolConfigTypes.sol


pragma solidity ^0.8.0;







interface IPoolConfigTypes {
  struct PoolConfig {
    uint256 minExitAmount; //100USD in collateral
    uint256 protocolFee;
    address feeWallet;
    IERC20 collateralToken;
    address collateralOracle;
    IOracleIterator collateralOracleIterator;
    IVolatilityEvolution volatilityEvolution;
    IUnderlyingLiquidityValuer underlyingLiquidityValuer;
    IExposure exposure;
    IERC20MintedBurnable poolShare;
    ITraderPortfolio traderPortfolio;
    uint8 collateralDecimals;
  }
}

// File: contracts/poolBuilder/IPoolBuilderTypes.sol


pragma solidity ^0.8.0;

interface IPoolBuilderTypes {
  struct CollateralParams {
    address collateralToken;
    address collateralOracle;
    address collateralOracleIterator;
  }

  struct FeeParams {
    address feeWallet;
    uint256 protocolFee;
  }

  struct Components {
    address poolShareBuilder;
    address traderPortfolioBuilder;
    address underlyingLiquidityValuer;
    address volatilityEvolution;
  }
}

// File: contracts/math/NumLib.sol


pragma solidity ^0.8.0;

library NumLib {
  uint8 public constant STANDARD_DECIMALS = 18;
  uint8 public constant BONE_DECIMALS = 26;
  uint256 public constant BONE = 10**BONE_DECIMALS;
  int256 public constant iBONE = int256(BONE);

  function add(uint256 a, uint256 b) public pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "ADD_OVERFLOW");
  }

  function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
    bool flag;
    (c, flag) = subSign(a, b);
    require(!flag, "SUB_UNDERFLOW");
  }

  function subSign(uint256 a, uint256 b) public pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "MUL_OVERFLOW");
    c = c1 / BONE;
  }

  function div(uint256 a, uint256 b) public pure returns (uint256 c) {
    require(b != 0, "DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "DIV_public"); // mul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "DIV_public"); //  add require
    c = c1 / b;
  }

  function min(uint256 first, uint256 second) public pure returns (uint256) {
    if (first < second) {
      return first;
    }
    return second;
  }
}

// File: contracts/terms/IRepricerTypes.sol


pragma solidity ^0.8.0;

interface IRepricerTypes {
  struct PairBytes16 {
    bytes16 primary;
    bytes16 complement;
  }
}

// File: contracts/terms/ITermsTypes.sol


pragma solidity ^0.8.0;


interface ITermsTypes is IPoolTypes, IRepricerTypes {
  struct VolatilityInputs {
    bytes16 ttm;
    bytes16 mu;
  }

  struct TradePrices {
    bytes16 derivative;
    bytes16 inward;
    bytes16 outward;
    DerivativePricesBytes16 derivativePrices;
  }

  struct TradeAmounts {
    bytes16 inward;
    bytes16 outward;
  }

  struct RolloverInputs {
    PairBytes16 price;
    PairBytes16 amount;
    PairBytes16 valueAllowed;
    bytes16 collateralAmount;
    bytes16 percentLiq;
  }

  struct FeeParams {
    uint256 baseFee;
    uint256 maxFee;
    uint256 rollFee;
    uint256 feeAmpPrimary;
    uint256 feeAmpComplement;
  }

  struct DerivativePricesBytes16 {
    PairBytes16 pair;
    VolatilityInputs inputs;
    bytes16 sigma;
    bytes16 omega;
  }

  struct OtherPricesBytes16 {
    bytes16 collateral;
    bytes16 underlying;
    uint256 volatilityRoundHint;
  }

  struct DerivativeSettlementBytes16 {
    uint256 settlement;
    PairBytes16 value;
    PairBytes16 position;
  }

  struct RolloverTradeBytes16 {
    PairBytes16 inward;
    PairBytes16 outward;
    bytes16 percentExp;
  }
}

// File: contracts/terms/ITerms.sol


pragma solidity ^0.8.0;

interface ITerms is ITermsTypes {

  function version() external returns (uint256);

  function instrumentType() external returns (string memory);

  function calculatePrice(
    uint256 _pointInTime,
    Derivative memory _derivative,
    Side _side,
    PriceType _price,
    OtherPrices memory otherPrices,
    IVolatilityEvolution _volatilityEvolution
  ) external returns (PricePair memory);

  function calculateRolloverTrade(
    PoolSnapshot memory snapshot,
    uint256 derivativeIndex,
    IPoolTypes.DerivativeSettlement memory derivativeSettlement,
    OtherPrices memory otherPrices
  ) external returns (RolloverTrade memory positions);

  function calculateOutAmount(
    PoolSnapshot memory snapshot,
    uint256 inAmount,
    uint256 derivativeIndex,
    Side _side,
    bool _poolReceivesCollateral,
    OtherPrices memory otherPrices
  ) external returns (uint256 outAmount);
}

// File: contracts/poolBlocks/PoolState.sol


pragma solidity ^0.8.0;








//import "hardhat/console.sol";

library PoolState {
  using RedemptionQueue for RedemptionQueue.Queue;
  using SafeERC20 for IERC20;

  uint256 public constant POOL_SHARE_PRICE_APPROXIMATION = 10**21; // 1/10^(26-21)
  uint256 public constant P_MIN = 100000000000000000000; // 0.000001
  uint256 public constant EXCESS_ORACLES_PER_POOL = 100;
  event PausedByOracle(
    address oracle,
    uint256 roundHint,
    uint256 requestedTimestamp,
    uint80 roundId,
    int256 answer,
    uint256 timestamp
  );
  event AddedDerivative(
    uint256 indexed derivativeIndex,
    uint256 indexed timestamp,
    IPoolTypes.Derivative derivative
  );

  uint256 public constant POOL_PORTFOLIO_ID = 0;

  struct State {
    IPoolConfigTypes.PoolConfig config;
    IPoolTypes.PoolBalance balance;
    RedemptionQueue.Queue redemptionQueue;
    IPoolTypes.Derivative[] liveSet;
    mapping(uint256 => IPoolTypes.Vintage[]) _oldSet;
    // portfolio id => derivativeIndex => balance
    mapping(uint256 => mapping(uint256 => IPoolTypes.Pair)) positionBalances;
    // portfolio id => derivativeIndex => vintageIndex
    mapping(uint256 => mapping(uint256 => uint256)) _vintages;
    mapping(address => uint256) _releasedLiquidity;
    bool pausing;
  }

  function init(
    State storage _state,
    address _poolShare,
    address _traderPortfolio,
    address _volatilityEvolution,
    address _underlyingLiquidityValuer,
    address _exposure,
    IPoolBuilderTypes.FeeParams memory _feeParams,
    IPoolBuilderTypes.CollateralParams memory _collateralParams,
    uint256 _minExitAmount
  ) public {
    _state.config.poolShare = IERC20MintedBurnable(_poolShare);

    _state.config.traderPortfolio = ITraderPortfolio(_traderPortfolio);

    require(_volatilityEvolution != address(0), "VOLEVOADDR");
    _state.config.volatilityEvolution = IVolatilityEvolution(_volatilityEvolution);

    _state.config.underlyingLiquidityValuer = IUnderlyingLiquidityValuer(_underlyingLiquidityValuer);

    require(_exposure != address(0), "EXPADDR");
    _state.config.exposure = IExposure(_exposure);

    _state.config.protocolFee = _feeParams.protocolFee;
    require(_feeParams.feeWallet != address(0), "FEEWADDR");
    _state.config.feeWallet = _feeParams.feeWallet;

    require(_collateralParams.collateralToken != address(0), "COLTADDR");
    _state.config.collateralToken = IERC20(_collateralParams.collateralToken);
    _state.config.collateralDecimals = IERC20Metadata(_collateralParams.collateralToken)
      .decimals();

    require(_collateralParams.collateralOracle != address(0), "COLOADDR");
    _state.config.collateralOracle = _collateralParams.collateralOracle;

    require(_collateralParams.collateralOracleIterator != address(0), "COLOIADDR");
    _state.config.collateralOracleIterator = IOracleIterator(
      _collateralParams.collateralOracleIterator
    );

    _state.config.minExitAmount = _minExitAmount;

    _state.redemptionQueue.init();
  }

  function getUnderlyingOracleIndex(State storage _state) public view returns (address[] memory) {
    address[] memory underlyingOracleIndexExcess = new address[](EXCESS_ORACLES_PER_POOL);
    uint256 excessOracleCount = 0;
    for(uint256 i = 0; i < _state.liveSet.length; i++) {
      address[] memory underlyingOracles = _state.liveSet[i].config.underlyingOracles;
      for(uint256 j = 0; j < underlyingOracles.length; j++) {
        underlyingOracleIndexExcess[excessOracleCount] = underlyingOracles[j];
        excessOracleCount += 1;
      }
    }

    uint256 uniqueOracleCount = 0;
    for(uint256 i = 0; i < excessOracleCount; i++ ) {
      address oracle = underlyingOracleIndexExcess[i];
      if(oracle == address(0)) continue;
      uniqueOracleCount += 1;
      for(uint256 j = i + 1; j < excessOracleCount; j++ ) {
        if(oracle == underlyingOracleIndexExcess[j]) {
          delete underlyingOracleIndexExcess[j];
        }
      }
    }

    address[] memory underlyingOracleIndex = new address[](uniqueOracleCount);
    uint256 oracleCount = 0;
    for(uint256 i = 0; i < excessOracleCount; i++ ) {
      address oracle = underlyingOracleIndexExcess[i];
      if(oracle == address(0)) continue;
      underlyingOracleIndex[oracleCount] = oracle;
      oracleCount += 1;
    }
    require(uniqueOracleCount == oracleCount, "UNIQORACL");

    return underlyingOracleIndex;
  }

  function getUnderlyingOracleIndexNumber(State storage _state, address _underlyingOracle) public view returns (uint256) {
    address[] memory underlyingOracleIndex = getUnderlyingOracleIndex(_state);

    for(uint256 i = 0; i < underlyingOracleIndex.length; i++ ) {
      if(underlyingOracleIndex[i] == _underlyingOracle) return i;
    }

    revert("UNDORACLIND");
  }

  function getCollateralValue(State storage _state) public returns (uint256) {
    uint256 collateralPrice = getLatestAnswer(
      _state,
      _state.config.collateralOracleIterator,
      _state.config.collateralOracle
    );
    return
    (fromStandard(_state.balance.collateralFree + _state.balance.collateralLocked) *
    collateralPrice) / NumLib.BONE;
  }

  function getAllRedemptionRequests(State storage _state)
    external
    view
    returns (RedemptionQueue.Request[] memory)
  {
    return _state.redemptionQueue.getAll();
  }

  function addDerivative(
    State storage _state,
    IPoolTypes.DerivativeConfig memory _derivativeConfig,
    address _terms,
    IPoolTypes.Sequence memory sequence,
    uint256 pRef,
    uint256 settlement
  ) public returns (uint256 derivativeIndex) {
    require(
      _derivativeConfig.collateralToken == address(_state.config.collateralToken),
      "COLTADDR"
    );

    IPoolTypes.Derivative memory derivative = IPoolTypes.Derivative(
      _derivativeConfig,
      _terms,
      sequence,
      IPoolTypes.DerivativeParams(
        pRef,
        settlement,
        _derivativeConfig.specification.denomination(settlement, pRef)
      )
    );

    _state.liveSet.push(derivative);
    derivativeIndex = _state.liveSet.length - 1;
    emit AddedDerivative(derivativeIndex, block.timestamp, derivative);
  }

  function withdrawReleasedLiquidity(PoolState.State storage _state, uint256 _collateralAmount)
  public
  {
    if (_collateralAmount == 0) return;

    uint256 collateralAmountStandard = fromCollateralToStandard(_state, _collateralAmount);
    if(collateralAmountStandard > getReleasedLiquidity(_state, msg.sender)) {
      collateralAmountStandard = getReleasedLiquidity(_state, msg.sender);
    }
    if (collateralAmountStandard == 0) return;

    unchecked {
      decreaseReleasedLiquidity(_state, msg.sender, collateralAmountStandard);
    }
    _state.balance.releasedLiquidityTotal -= collateralAmountStandard;

    require(checkPoolCollateralBalance(_state), "COLERR");

    pushCollateral(
      address(_state.config.collateralToken),
      msg.sender,
      fromStandardToCollateral(_state, collateralAmountStandard)
    );
  }

  //D
  function calculatePoolSharePrice(
    PoolState.State storage _state,
    uint256 _pointInTime,
    IPoolTypes.PoolSharePriceHints memory _poolSharePriceHints
  ) internal returns (uint256 poolSharePrice, uint256 poolDerivativesValue) {
    if (_state.config.poolShare.totalSupply() == 0) return (_poolSharePriceHints.collateralPrice, 0);

    poolDerivativesValue = 0;
    for (uint256 i = 0; i < _state.liveSet.length; i++) {
      poolDerivativesValue += calcDerivativeValue(_state, _pointInTime, i, _poolSharePriceHints);
    }

    uint256 poolValue = calcPoolCollateralValue(_state, _poolSharePriceHints.collateralPrice) + poolDerivativesValue;

    poolSharePrice =
      max(
        PoolState.P_MIN,
        (poolValue * NumLib.BONE) / fromStandard(_state.config.poolShare.totalSupply())
      );
  }

  function getPoolSharePrice(PoolState.State storage _state)
  public
  returns (
    uint256 poolSharePrice,
    uint256 poolDerivativesValue,
    IPoolTypes.PoolSharePriceHints memory poolSharePriceHints
  )
  {
    poolSharePriceHints = createHintsWithCollateralPrice(_state);
    if (poolSharePriceHints.collateralPrice == 0) return (0, 0, poolSharePriceHints);

    if(_state.config.poolShare.totalSupply() == 0) return (poolSharePriceHints.collateralPrice, 0, poolSharePriceHints);

    (poolSharePrice, poolDerivativesValue) = calculatePoolSharePrice(_state, block.timestamp, poolSharePriceHints);
  }

  function getDerivativePrice(PoolState.State storage _state, uint256 _derivativeIndex)
  public
  returns (IPoolTypes.PricePair memory)
  {
    uint256 pintInTime = block.timestamp;

    IPoolTypes.PoolSharePriceHints memory poolSharePriceHints = createHintsWithCollateralPrice(_state);
    if (poolSharePriceHints.collateralPrice == 0) return IPoolTypes.PricePair(0, 0);

    IPoolTypes.Derivative memory derivative = _state.liveSet[_derivativeIndex];

    uint256 underlyingPrice = uint256(
      getHintedAnswer(
        _state,
        IOracleIterator(derivative.config.underlyingOracleIterators[0]),
        derivative.config.underlyingOracles[0],
        pintInTime,
        poolSharePriceHints.hintLess ? 0 : poolSharePriceHints.underlyingRoundHintsIndexed[
          getUnderlyingOracleIndexNumber(_state, derivative.config.underlyingOracles[0])
        ]
      )
    );
    if (underlyingPrice == 0) return IPoolTypes.PricePair(0, 0);

    return
    ITerms(derivative.terms).calculatePrice(
      pintInTime,
      derivative,
      IPoolTypes.Side.Empty,
      IPoolTypes.PriceType.mid,
      IPoolTypes.OtherPrices(
        int256(poolSharePriceHints.collateralPrice),
        int256(underlyingPrice),
        poolSharePriceHints.hintLess ? 0 : poolSharePriceHints.volatilityRoundHint
      ),
      _state.config.volatilityEvolution
    );
  }

  function calcPoolCollateralValue(PoolState.State storage _state, uint256 collateralPrice) public view returns(uint256) {
    return (collateralPrice * fromStandard(_state.balance.collateralFree)) / NumLib.BONE;
  }

  function calcDerivativeValue(
    PoolState.State storage _state,
    uint256 _pointInTime,
    uint256 _derivativeIndex,
    IPoolTypes.PoolSharePriceHints memory _poolSharePriceHints
  ) internal returns (uint256) {
    IPoolTypes.Pair memory poolPosition = _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][
      _derivativeIndex
    ];
    if (poolPosition.primary == 0 && poolPosition.complement == 0) return 0;

    IPoolTypes.Derivative memory derivative = _state.liveSet[_derivativeIndex];

    uint256 underlyingPrice = uint256(
      getHintedAnswer(
        _state,
        IOracleIterator(derivative.config.underlyingOracleIterators[0]),
        derivative.config.underlyingOracles[0],
        _pointInTime,
        _poolSharePriceHints.hintLess ? 0 : _poolSharePriceHints.underlyingRoundHintsIndexed[
          getUnderlyingOracleIndexNumber(_state, derivative.config.underlyingOracles[0])
        ]
      )
    );

    if (underlyingPrice == 0) return 0;

    IPoolTypes.PricePair memory derivativePrices = ITerms(derivative.terms).calculatePrice(
      _pointInTime,
      derivative,
      IPoolTypes.Side.Empty,
      IPoolTypes.PriceType.mid,
      IPoolTypes.OtherPrices(
        int256(_poolSharePriceHints.collateralPrice),
        int256(underlyingPrice),
        _poolSharePriceHints.hintLess ? 0 : _poolSharePriceHints.volatilityRoundHint
      ),
      _state.config.volatilityEvolution
    );

    uint256 derivativeValue = 0;
    if (poolPosition.primary > 0) {
      derivativeValue +=
        (fromStandard(poolPosition.primary) * uint256(derivativePrices.primary)) /
        NumLib.BONE;
    }

    if (poolPosition.complement > 0) {
      derivativeValue +=
        (fromStandard(poolPosition.complement) * uint256(derivativePrices.complement)) /
        NumLib.BONE;
    }

    return derivativeValue;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a;
    } else {
      return b;
    }
  }

  function subMod(uint256 a, uint256 b) public pure returns (uint256) {
    unchecked{
      if (a > b) {
        return a - b;
      } else {
        return b - a;
      }
    }
  }

  function getCollateralExposureLimit(PoolState.State storage _state) public view returns (uint256) {
    return
    toStandard(
      _state.config.exposure.calcCollateralExposureLimit(
        _state.liveSet,
        getDerivativePoolPositionsBonified(_state)
      )
    );
  }

  function createHintsWithCollateralPrice(PoolState.State storage _state)
    public
    returns (IPoolTypes.PoolSharePriceHints memory)
  {
    uint256 collateralPrice = uint256(
      getLatestAnswer(
        _state,
        _state.config.collateralOracleIterator,
        _state.config.collateralOracle
      )
    );

    IPoolTypes.PoolSharePriceHints memory poolSharePriceHints;
    poolSharePriceHints.hintLess = true;
    poolSharePriceHints.collateralPrice = collateralPrice;
    return poolSharePriceHints;
  }

  function checkPoolCollateralBalance(PoolState.State storage _state) public view returns (bool) {
    return
      fromCollateralToStandard(_state, _state.config.collateralToken.balanceOf(address(this))) >=
      (_state.balance.collateralLocked +
        _state.balance.collateralFree +
        _state.balance.releasedLiquidityTotal +
        _state.balance.releasedWinnings);
  }

  function getDerivativePoolPositionsBonified(State storage _state)
    public
    view
    returns (IPoolTypes.Pair[] memory _balances)
  {
    _balances = new IPoolTypes.Pair[](_state.liveSet.length);
    for (uint256 i = 0; i < _state.liveSet.length; i++) {
      _balances[i] = IPoolTypes.Pair(
        fromStandard(_state.positionBalances[POOL_PORTFOLIO_ID][i].primary),
        fromStandard(_state.positionBalances[POOL_PORTFOLIO_ID][i].complement)
      );
    }
  }

  function getReleasedLiquidity(State storage _state, address user) public view returns (uint256) {
    return _state._releasedLiquidity[user];
  }

  function increaseReleasedLiquidity(
    State storage _state,
    address user,
    uint256 amount
  ) public {
    _state._releasedLiquidity[user] += amount;
  }

  function decreaseReleasedLiquidity(
    State storage _state,
    address user,
    uint256 amount
  ) public {
    _state._releasedLiquidity[user] -= amount;
  }

  function getCurrentVintageIndexFor(State storage _state, uint256 _derivativeIndex)
    public
    view
    returns (uint256)
  {
    return _state._oldSet[_derivativeIndex].length + 1;
  }

  function setVintageFor(
    State storage _state,
    uint256 _derivativeIndex,
    uint256 _rollRatePrimary,
    uint256 _rollRateComplement,
    uint256 _releaseRatePrimary,
    uint256 _releaseRateComplement,
    uint256 _priceReference
  ) public {
    _state._oldSet[_derivativeIndex].push(
      IPoolTypes.Vintage(
        IPoolTypes.Pair(_rollRatePrimary, _rollRateComplement),
        IPoolTypes.Pair(_releaseRatePrimary, _releaseRateComplement),
        _priceReference
      )
    );
  }

  function updateVintageFor(
    State storage _state,
    uint256 _derivativeIndex,
    uint256 _vintageIndex,
    uint256 _rollRatePrimary,
    uint256 _rollRateComplement,
    uint256 _releaseRatePrimary,
    uint256 _releaseRateComplement,
    uint256 _priceReference
  ) public {
    _state._oldSet[_derivativeIndex][_vintageIndex - 1] = IPoolTypes.Vintage(
      IPoolTypes.Pair(_rollRatePrimary, _rollRateComplement),
      IPoolTypes.Pair(_releaseRatePrimary, _releaseRateComplement),
      _priceReference
    );
  }

  function getVintageBy(
    State storage _state,
    uint256 _derivativeIndex,
    uint256 _vintageIndex
  ) public view returns (IPoolTypes.Vintage memory) {
    require(_vintageIndex >= 1, "UPDBADVIN");
    return _state._oldSet[_derivativeIndex][_vintageIndex - 1];
  }

  function getUserPositionVintageIndex(
    State storage _state,
    uint256 _userPortfolio,
    uint256 _derivativeIndex
  ) public view returns (uint256) {
    return _state._vintages[_userPortfolio][_derivativeIndex];
  }

  function setUserPositionVintageIndex(
    State storage _state,
    uint256 _userPortfolio,
    uint256 _derivativeIndex,
    uint256 _vintageIndex
  ) public {
    _state._vintages[_userPortfolio][_derivativeIndex] = _vintageIndex;
  }

  function makePoolSnapshot(State storage _state)
    public
    view
    returns (IPoolTypes.PoolSnapshot memory)
  {
    return
      IPoolTypes.PoolSnapshot(
        _state.liveSet,
        address(_state.config.exposure),
        fromStandard(_state.balance.collateralLocked),
        fromStandard(_state.balance.collateralFree),
        getDerivativePoolPositionsBonified(_state),
        _state.config.volatilityEvolution,
        _state.config.underlyingLiquidityValuer
      );
  }

  function checkIfRedemptionQueueEmpty(State storage _state) public view returns (bool) {
    return _state.redemptionQueue.empty();
  }

  function moveDerivative(
    State storage _state,
    uint256 senderPortfolio,
    uint256 recipientPortfolio,
    uint256 amount,
    uint256 derivativeIndex,
    IPoolTypes.Side side
  ) public {
    uint256 senderBalance;
    if (side == IPoolTypes.Side.Primary) {
      senderBalance = _state.positionBalances[senderPortfolio][derivativeIndex].primary;
      require(senderBalance >= amount, "DERPRINSUFBAL");
      unchecked {
        _state.positionBalances[senderPortfolio][derivativeIndex].primary = senderBalance - amount;
      }
      _state.positionBalances[recipientPortfolio][derivativeIndex].primary += amount;
    } else if (side == IPoolTypes.Side.Complement) {
      senderBalance = _state.positionBalances[senderPortfolio][derivativeIndex].complement;
      require(senderBalance >= amount, "DERCOINSUFBAL");
      unchecked {
        _state.positionBalances[senderPortfolio][derivativeIndex].complement = senderBalance - amount;
      }
      _state.positionBalances[recipientPortfolio][derivativeIndex].complement += amount;
    }
  }

  function getLatestAnswerByDerivative(
    State storage _state,
    IPoolTypes.Derivative memory derivative
  ) public returns (uint256) {
    return
      getLatestAnswer(
        _state,
        IOracleIterator(derivative.config.underlyingOracleIterators[0]),
        derivative.config.underlyingOracles[0]
      );
  }

  function getLatestAnswer(
    State storage _state,
    IOracleIterator _iterator,
    address _oracle
  ) public returns (uint256) {
    return getHintedAnswer(_state, _iterator, _oracle, block.timestamp, 0);
  }

  function getHintedAnswer(
    State storage _state,
    IOracleIterator _iterator,
    address _oracle,
    uint256 _timestamp,
    uint256 _roundHint
  ) public returns (uint256) {
    (uint80 roundId, int256 value, uint256 timestamp) = _iterator.getRound(
      _oracle,
      _timestamp,
      _roundHint
    );
    if (value == type(int256).min) {
      string memory reason = string(
        abi.encodePacked(
          "Iterator missed ",
          _oracle,
          " ",
          Strings.toString(_roundHint),
          " ",
          Strings.toString(_timestamp)
        )
      );
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
    if (value <= 0) {
      _state.pausing = true;
      emit PausedByOracle(_oracle, _roundHint, _timestamp, roundId, value, timestamp);
      return 0;
    }
    if (uint256(value) < P_MIN) {
      return P_MIN;
    }

    return uint256(value);
  }

  function pullCollateral(
    address erc20,
    address from,
    uint256 amount
  ) public returns (uint256) {
    uint256 balanceBefore = IERC20(erc20).balanceOf(address(this));
    IERC20(erc20).safeTransferFrom(from, address(this), amount);
    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = IERC20(erc20).balanceOf(address(this));
    require(balanceAfter >= balanceBefore, "COLINOVER");
    return balanceAfter - balanceBefore; // underflow already checked above, just subtract
  }

  function pushCollateral(
    address erc20,
    address to,
    uint256 amount
  ) public {
    IERC20(erc20).safeTransfer(to, amount);
  }

  function convertUpDecimals(
    uint256 _value,
    uint8 _decimalsFrom,
    uint8 _decimalsTo
  ) public pure returns (uint256) {
    require(_decimalsFrom <= _decimalsTo, "BADDECIM");
    return _value * (10**(_decimalsTo - _decimalsFrom));
  }

  function convertDownDecimals(
    uint256 _value,
    uint8 _decimalsFrom,
    uint8 _decimalsTo
  ) public pure returns (uint256) {
    require(_decimalsFrom <= _decimalsTo, "BADDECIM");
    return _value / (10**(_decimalsTo - _decimalsFrom));
  }

  function fromCollateralToStandard(State storage _state, uint256 _value)
    public
    view
    returns (uint256)
  {
    return convertUpDecimals(_value, _state.config.collateralDecimals, NumLib.STANDARD_DECIMALS);
  }

  function fromStandardToCollateral(State storage _state, uint256 _value)
    public
    view
    returns (uint256)
  {
    return convertDownDecimals(_value, _state.config.collateralDecimals, NumLib.STANDARD_DECIMALS);
  }

  function fromCollateral(State storage _state, uint256 _value) public view returns (uint256) {
    return convertUpDecimals(_value, _state.config.collateralDecimals, NumLib.BONE_DECIMALS);
  }

  function toCollateral(State storage _state, uint256 _value) public view returns (uint256) {
    return convertDownDecimals(_value, _state.config.collateralDecimals, NumLib.BONE_DECIMALS);
  }

  function fromStandard(uint256 _value) public pure returns (uint256) {
    return convertUpDecimals(_value, NumLib.STANDARD_DECIMALS, NumLib.BONE_DECIMALS);
  }

  function toStandard(uint256 _value) public pure returns (uint256) {
    return convertDownDecimals(_value, NumLib.STANDARD_DECIMALS, NumLib.BONE_DECIMALS);
  }
}

// File: contracts/poolBlocks/PoolRolloverLogic.sol


pragma solidity ^0.8.0;





//import "hardhat/console.sol";

library PoolRolloverLogic {
  using PoolState for PoolState.State;
  using RedemptionQueue for RedemptionQueue.Queue;

  uint256 public constant HINTS_FREE_ROLLOVER_MAX = 3;

  event FailedRollover(uint256 chainDerivativeIndex, uint256 inDerivativeIndex);

  event RolledOverDerivative(
    uint256 indexed derivativeIndex,
    uint256 indexed timestamp,
    uint256 indexed settlement,
    IPoolTypes.Pair poolPosition,
    IPoolTypes.Pair newPoolPosition,
    uint256 newVintageIndex,
    IPoolTypes.Vintage newVintage,
    IPoolTypes.DerivativeParams newDerivativeParams,
    IPoolTypes.SettlementValues settlementValues,
    IPoolTypes.RolloverTrade rolloverTrade
  );

  event ProcessedRedemptionQueueItem(
    address indexed user,
    uint256 indexed requestTimestamp,
    uint256 timestamp,
    uint256 processedAmount,
    uint256 releasedLiquidity,
    bool fullyProcessed,
    uint256 collateralExposureLimit,
    uint256 exitRatio,
    uint256 poolSharePrice
  );

  // A
  function processRedemptionQueueAt(
    PoolState.State storage _state,
    uint256 _pointInTime,
    IPoolTypes.PoolSharePriceHints memory _poolSharePriceHints
  ) public returns (bool) {
    if (_state.redemptionQueue.empty() || _state.redemptionQueue.get().time > _pointInTime)
      return true; //empty queue

    uint256 collateralExposureLimit = PoolState.toStandard(
      _state.config.exposure.calcCollateralExposureLimit(
        _state.liveSet,
        _state.getDerivativePoolPositionsBonified()
      )
    );

    uint256 collateralAvailable = _state.balance.collateralFree <= collateralExposureLimit
      ? 0
      : _state.balance.collateralFree - collateralExposureLimit;

    if (collateralAvailable == 0) return false;

    (uint256 poolSharePrice, uint256 poolDerivativesValue) = _state.calculatePoolSharePrice(_pointInTime, _poolSharePriceHints);
    if (poolSharePrice == 0) return false;

    uint256 exitRatio = (poolSharePrice * NumLib.BONE) / _poolSharePriceHints.collateralPrice;

    return
      releaseLiquidity(_state, _pointInTime, exitRatio, collateralExposureLimit, poolSharePrice, poolDerivativesValue, _poolSharePriceHints.collateralPrice);
  }

  struct VarsRL {
    uint256 collateralAvailable;
    uint256 beingBurned;
    uint256 deltaReleasedLiquidity;
    bool fullyExecuted;
    uint256 deltaReleasedLiquidityValue;
    uint256 poolSharePriceAfter;
  }

  function releaseLiquidity(
    PoolState.State storage _state,
    uint256 _pointInTime,
    uint256 _exitRatio,
    uint256 _collateralExposureLimit,
    uint256 _poolSharePrice,
    uint256 _poolDerivativesValue,
    uint256 _collateralPrice
  ) internal returns (bool) {
    while (_state.balance.collateralFree > _collateralExposureLimit) {
      VarsRL memory vars;

      RedemptionQueue.Request storage request = _state.redemptionQueue.get();
      if (_state.redemptionQueue.empty() || request.time > _pointInTime) return true;

      vars.collateralAvailable = _state.balance.collateralFree <= _collateralExposureLimit
        ? 0
        : _state.balance.collateralFree - _collateralExposureLimit;

      if (vars.collateralAvailable == 0) return false;
      vars.beingBurned = request.amount;
      vars.deltaReleasedLiquidity = (request.amount * _exitRatio) / NumLib.BONE;
      vars.fullyExecuted = vars.deltaReleasedLiquidity <= vars.collateralAvailable;
      if (!vars.fullyExecuted) {
        vars.deltaReleasedLiquidity = vars.collateralAvailable;
        vars.beingBurned = (vars.collateralAvailable * NumLib.BONE) / _exitRatio;
        request.amount -= vars.beingBurned;
      }

      _state.balance.collateralFree -= vars.deltaReleasedLiquidity;
      _state.increaseReleasedLiquidity(request.owner, vars.deltaReleasedLiquidity);
      _state.balance.releasedLiquidityTotal += vars.deltaReleasedLiquidity;

      _state.config.poolShare.burn(vars.beingBurned);

      vars.poolSharePriceAfter = (_state.calcPoolCollateralValue(_collateralPrice) + _poolDerivativesValue) * NumLib.BONE
        / PoolState.fromStandard(_state.config.poolShare.totalSupply());

      require(PoolState.subMod(vars.poolSharePriceAfter, _poolSharePrice) <= PoolState.POOL_SHARE_PRICE_APPROXIMATION, "QUEUELPP");

      require(_state.checkPoolCollateralBalance(), "COLERR");

      emitProcessedRedemptionQueueItem(
        request,
        _pointInTime,
        vars.beingBurned,
        vars.deltaReleasedLiquidity,
        vars.fullyExecuted,
        _collateralExposureLimit,
        _exitRatio,
        _poolSharePrice
      );

      if (vars.fullyExecuted) {
        _state.redemptionQueue.dequeue();
      }
    }

    return false;
  }

  function emitProcessedRedemptionQueueItem(
    RedemptionQueue.Request storage request,
    uint256 _pointInTime,
    uint256 beingBurned,
    uint256 deltaReleasedLiquidity,
    bool fullyExecuted,
    uint256 _collateralExposureLimit,
    uint256 _exitRatio,
    uint256 _poolSharePrice
  ) internal {
    emit ProcessedRedemptionQueueItem(
      request.owner,
      request.time,
      _pointInTime,
      beingBurned,
      deltaReleasedLiquidity,
      fullyExecuted,
      _collateralExposureLimit,
      _exitRatio,
      _poolSharePrice
    );
  }

  function rolloverOldestDerivativeBatch(
    PoolState.State storage _state,
    uint256 _pointInTime,
    IPoolTypes.RolloverHints[] memory _rolloverHintsList
  ) public returns (bool) {
    for (uint256 i = 0; i < _rolloverHintsList.length; i++) {
      if (!rolloverOldestDerivative(_state, _pointInTime, _rolloverHintsList[i])) {
        return false;
      }
    }
    return true;
  }

  function rolloverOldestDerivative(
    PoolState.State storage _state,
    uint256 _pointInTime,
    IPoolTypes.RolloverHints memory _rolloverHints
  ) public returns (bool) {
    require(block.timestamp >= _pointInTime, "TIME");
    address[] memory underlyingOracleIndex = _state.getUnderlyingOracleIndex();
    require(_rolloverHints.underlyingRoundHintsIndexed.length == underlyingOracleIndex.length, "PRICEHINTS");

    uint256 derivativeIndex = getOldestDerivativeForRollover(_state, _pointInTime);

    if (
      derivativeIndex == type(uint256).max || _rolloverHints.derivativeIndex != derivativeIndex
    ) {
      emit FailedRollover(derivativeIndex, _rolloverHints.derivativeIndex);
      return false;
    }

    uint256 collateralPrice = uint256(
      _state.getHintedAnswer(
        _state.config.collateralOracleIterator,
        _state.config.collateralOracle,
        _state.liveSet[derivativeIndex].params.settlement,
        _rolloverHints.collateralRoundHint
      )
    );
    if (collateralPrice == 0) return false;

    rolloverDerivative(
      _state,
      derivativeIndex,
      IPoolTypes.PoolSharePriceHints(
        false,
        collateralPrice,
        _rolloverHints.underlyingRoundHintsIndexed,
        _rolloverHints.volatilityRoundHint
      )
    );
    if (_state.pausing == true) return false;

    return true;
  }

  function getOldestDerivativeForRollover(PoolState.State storage _state, uint256 _pointInTime)
    public
    view
    returns (uint256 derivativeIndex)
  {
    derivativeIndex = type(uint256).max;
    uint256 oldest = _pointInTime;
    for (uint256 i = 0; i < _state.liveSet.length; i++) {
      uint256 settlement = _state.liveSet[i].params.settlement;
      if (
        settlement < oldest ||
        (settlement == oldest && derivativeIndex == type(uint256).max) ||
        (settlement == oldest &&
          _state.liveSet[i].sequence.mode == IPoolTypes.Mode.Temp &&
          _state.liveSet[derivativeIndex].sequence.mode != IPoolTypes.Mode.Temp)
      ) {
        derivativeIndex = i;
        oldest = settlement;
      }
    }
  }

  function refreshPoolTo(PoolState.State storage _state, uint256 _pointInTime)
    public
    returns (bool)
  {
    IPoolTypes.PoolSharePriceHints memory poolSharePriceHints = _state
      .createHintsWithCollateralPrice();
    if (poolSharePriceHints.collateralPrice == 0) return false;

    uint256 checks;
    uint256 derivativeIndex = getOldestDerivativeForRollover(_state, _pointInTime);
    while (derivativeIndex != type(uint256).max && checks < HINTS_FREE_ROLLOVER_MAX) {
      rolloverDerivative(_state, derivativeIndex, poolSharePriceHints);
      if (_state.pausing) return false;
      derivativeIndex = getOldestDerivativeForRollover(_state, _pointInTime);
      checks++;
    }

    require(checkWhetherPoolFresh(_state, block.timestamp), "NOTFRESH");
    require(_state.checkPoolCollateralBalance(), "COLERR");

    return true;
  }

  struct VarsB {
    IPoolTypes.SettlementValues settlementValues;
    uint256 settlement;
    uint256 priceReference;
    IPoolTypes.Pair poolPosition;
    IPoolTypes.Pair poolPositionBoned;
    IPoolTypes.Pair newPool;
    bool queueNotProcessed;
    bytes16 newPrimaryPriceRaw;
    IPoolTypes.RolloverTrade rolloverTrade;
    uint256 newPoolPositionValue;
    uint256 newTotalRolloverInAmount;
  }

  // B
  function rolloverDerivative(
    PoolState.State storage _state,
    uint256 _derivativeIndex,
    IPoolTypes.PoolSharePriceHints memory poolSharePriceHints
  ) internal {
    VarsB memory vars;

    IPoolTypes.Derivative storage derivative = _state.liveSet[_derivativeIndex];

    require(block.timestamp >= derivative.params.settlement, "Incorrect time");
    vars.settlement = derivative.params.settlement;
    vars.priceReference = derivative.params.priceReference;
    //I checks later
    //II collateralPrice calculates outside method (poolSharePriceHints.collateralPrice)

    //III
    vars.settlementValues = calcUsdValueAtSettlement(
      derivative,
      poolSharePriceHints.collateralPrice,
      poolSharePriceHints.hintLess
        ? createSingleItemArray(0)
        : createSingleItemArray(poolSharePriceHints.underlyingRoundHintsIndexed[
            _state.getUnderlyingOracleIndexNumber(derivative.config.underlyingOracles[0])
          ])
    );

    //IV
    vars.poolPosition = _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex];
    vars.poolPositionBoned = IPoolTypes.Pair(
      PoolState.fromStandard(vars.poolPosition.primary),
      PoolState.fromStandard(vars.poolPosition.complement)
    );

    if (vars.poolPosition.primary != 0 || vars.poolPosition.complement != 0) {
      //I
      uint256 releasedCollateral = PoolState.toStandard(
        ((vars.poolPositionBoned.primary + vars.poolPositionBoned.complement) *
          derivative.params.denomination) / NumLib.BONE
      ) - 1; // decrement by minimal

      _state.balance.collateralLocked -= releasedCollateral;

      uint256 collateralFreeIncrement = PoolState.toStandard(
        (vars.poolPositionBoned.primary *
          vars.settlementValues.value.primary +
          vars.poolPositionBoned.complement *
          vars.settlementValues.value.complement) / poolSharePriceHints.collateralPrice
      );

      if(collateralFreeIncrement > releasedCollateral) {
        collateralFreeIncrement = releasedCollateral;
      }

      _state.balance.collateralFree += collateralFreeIncrement;
      _state.balance.releasedWinnings =
        _state.balance.releasedWinnings +
        releasedCollateral -
        collateralFreeIncrement;

      _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex] = IPoolTypes.Pair(0, 0);

      //V
      vars.queueNotProcessed = !processRedemptionQueueAt(
        _state,
        derivative.params.settlement,
        poolSharePriceHints
      );
    }

    //VI
    uint256 newReferencePrice = derivative.config.specification.referencePrice(
      vars.settlementValues.underlyingPrice,
      derivative.sequence.strikePosition
    );
    uint256 newSettlement = derivative.params.settlement + derivative.sequence.settlementDelta;
    derivative.params = IPoolTypes.DerivativeParams(
      newReferencePrice,
      newSettlement,
      derivative.config.specification.denomination(newSettlement, newReferencePrice)
    );

    //VII
    if (
      derivative.sequence.mode == IPoolTypes.Mode.Temp ||
      vars.queueNotProcessed ||
      _state.balance.collateralFree == 0 ||
      derivative.sequence.side == IPoolTypes.Side.Empty ||
      PoolState.toStandard(
        (vars.poolPositionBoned.primary *
          vars.settlementValues.value.complement +
          vars.poolPositionBoned.complement *
          vars.settlementValues.value.primary) / NumLib.BONE
      ) ==
      0 //TODO: should we convert to bone and back here?
    ) {
      //VIII
      _state.setVintageFor(
        _derivativeIndex,
        0,
        0,
        NumLib.div(vars.settlementValues.value.primary, poolSharePriceHints.collateralPrice),
        NumLib.div(vars.settlementValues.value.complement, poolSharePriceHints.collateralPrice),
        vars.priceReference
      );
    } else {
      //VII continue
      vars.rolloverTrade = calculateRolloverTrade(
        _state,
        _derivativeIndex,
        IPoolTypes.DerivativeSettlement(
          vars.settlement,
          vars.settlementValues.value,
          vars.poolPositionBoned
        ),
        int256(poolSharePriceHints.collateralPrice),
        int256(vars.settlementValues.underlyingPrice),
        poolSharePriceHints.hintLess ? 0 : poolSharePriceHints.volatilityRoundHint
      );

      vars.newPool = IPoolTypes.Pair(
        vars.rolloverTrade.outward.complement,
        vars.rolloverTrade.outward.primary
      );

      //VIII
      _state.setVintageFor(
        _derivativeIndex,
        vars.poolPosition.complement == 0
          ? 0
          : NumLib.div(vars.newPool.complement, vars.poolPosition.complement),
        vars.poolPosition.primary == 0
          ? 0
          : NumLib.div(vars.newPool.primary, vars.poolPosition.primary),
        NumLib.div(vars.settlementValues.value.primary, poolSharePriceHints.collateralPrice) -
          (
            vars.poolPosition.complement == 0
              ? 0
              : NumLib.div(vars.rolloverTrade.inward.primary, vars.poolPosition.complement)
          ),
        NumLib.div(vars.settlementValues.value.complement, poolSharePriceHints.collateralPrice) -
          (
            vars.poolPosition.primary == 0
              ? 0
              : NumLib.div(vars.rolloverTrade.inward.complement, vars.poolPosition.primary)
          ),
        vars.priceReference
      );

      //IX
      _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex] = vars.newPool;

      vars.newPoolPositionValue =
        (derivative.params.denomination * (vars.newPool.complement + vars.newPool.primary)) /
        NumLib.BONE;
      vars.newTotalRolloverInAmount =
        vars.rolloverTrade.inward.primary +
        vars.rolloverTrade.inward.complement;

      if (
        _state.balance.collateralFree + vars.newTotalRolloverInAmount <
        vars.newPoolPositionValue ||
        _state.balance.releasedWinnings < vars.newTotalRolloverInAmount ||
        !_state.checkPoolCollateralBalance()
      ) {
        _state.updateVintageFor(
          _derivativeIndex,
          _state.getCurrentVintageIndexFor(_derivativeIndex) - 1,
          0,
          0,
          NumLib.div(vars.settlementValues.value.primary, poolSharePriceHints.collateralPrice),
          NumLib.div(vars.settlementValues.value.complement, poolSharePriceHints.collateralPrice),
          vars.priceReference
        );

        _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex] = IPoolTypes.Pair(0, 0);
      } else {
        _state.balance.collateralLocked += vars.newPoolPositionValue;
        _state.balance.collateralFree =
          _state.balance.collateralFree +
          vars.newTotalRolloverInAmount -
          vars.newPoolPositionValue;
        _state.balance.releasedWinnings -= vars.newTotalRolloverInAmount;
      }
    }

    emitRolledOverDerivative(_state, vars, _derivativeIndex, derivative.params);
  }

  function emitRolledOverDerivative(
    PoolState.State storage _state,
    VarsB memory vars,
    uint256 _derivativeIndex,
    IPoolTypes.DerivativeParams memory _newDerivativeParams
  ) internal {
    uint256 newVintageIndex = _state.getCurrentVintageIndexFor(_derivativeIndex) - 1;

    emit RolledOverDerivative(
      _derivativeIndex,
      block.timestamp,
      vars.settlement,
      vars.poolPosition,
      _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex],
      newVintageIndex,
      _state.getVintageBy(_derivativeIndex, newVintageIndex),
      _newDerivativeParams,
      vars.settlementValues,
      vars.rolloverTrade
    );
  }

  function calcUsdValueAtSettlement(
    IPoolTypes.Derivative memory derivative,
    uint256 collateralPrice,
    uint256[] memory _underlyingRoundHints
  ) internal view returns (IPoolTypes.SettlementValues memory) {
    (uint256 primarySplit, int256[] memory underlyingEnds) = derivative
      .config
      .collateralSplit
      .split(
        derivative.config.underlyingOracles,
        derivative.config.underlyingOracleIterators,
        makeIntArrayFrom(int256(derivative.params.priceReference)),
        derivative.params.settlement,
        _underlyingRoundHints
      );
    primarySplit = range(primarySplit);
    uint256 complementSplit = NumLib.BONE - primarySplit;
    uint256 underlyingPrice = uint256(underlyingEnds[0]); //TODO: Process negative price

    return
      IPoolTypes.SettlementValues(
        IPoolTypes.Pair(
          (((primarySplit * collateralPrice) / NumLib.BONE) * derivative.params.denomination) /
            NumLib.BONE,
          (((complementSplit * collateralPrice) / NumLib.BONE) * derivative.params.denomination) /
            NumLib.BONE
        ),
        underlyingPrice
      );
  }

  function calculateRolloverTrade(
    PoolState.State storage _state,
    uint256 _derivativeIndex,
    IPoolTypes.DerivativeSettlement memory _derivativeSettlement,
    int256 _collateralPrice,
    int256 _underlyingPrice,
    uint256 _volatilityRoundHint
  ) internal returns (IPoolTypes.RolloverTrade memory) {
    return
      convertRolloverTradeFromBONE(
        ITerms(_state.liveSet[_derivativeIndex].terms).calculateRolloverTrade(
          _state.makePoolSnapshot(),
          _derivativeIndex,
          _derivativeSettlement,
          IPoolTypes.OtherPrices(_collateralPrice, _underlyingPrice, _volatilityRoundHint)
        )
      );
  }

  function checkWhetherPoolFresh(PoolState.State storage _state, uint256 _pointInTime)
    internal
    view
    returns (bool)
  {
    uint256 derivativeIndex = getOldestDerivativeForRollover(_state, _pointInTime);
    return derivativeIndex == type(uint256).max;
  }

  function makeIntArrayFrom(int256 _value) internal pure returns (int256[] memory array) {
    array = new int256[](1);
    array[0] = _value;
  }

  function range(uint256 _split) internal pure returns (uint256) {
    if (_split > NumLib.BONE) {
      return NumLib.BONE;
    }
    return _split;
  }

  function convertRolloverTradeFromBONE(IPoolTypes.RolloverTrade memory _rolloverTrade)
    internal
    pure
    returns (IPoolTypes.RolloverTrade memory)
  {
    return
      IPoolTypes.RolloverTrade(
        IPoolTypes.Pair(
          PoolState.toStandard(_rolloverTrade.inward.primary),
          PoolState.toStandard(_rolloverTrade.inward.complement)
        ),
        IPoolTypes.Pair(
          PoolState.toStandard(_rolloverTrade.outward.primary),
          PoolState.toStandard(_rolloverTrade.outward.complement)
        )
      );
  }

  function createSingleItemArray(uint256 item) internal pure returns (uint256[] memory array) {
    array = new uint256[](1);
    array[0] = item;
  }
}

// File: contracts/poolBlocks/PoolLogic.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;






//import "hardhat/console.sol";

library PoolLogic {
  using PoolState for PoolState.State;
  using PoolRolloverLogic for PoolState.State;
  using RedemptionQueue for RedemptionQueue.Queue;

  event JoinedPool(
    address indexed user,
    uint256 indexed timestamp,
    uint256 collateralAmount,
    uint256 poolShareAmountOut,
    uint256 poolSharePrice
  );
  event CreatedRedemptionQueueItem(
    address indexed user,
    uint256 indexed timestamp,
    uint256 poolShareAmountIn
  );

  event MintedDerivative(
    uint256 indexed portfolioId,
    uint256 indexed derivativeIndex,
    IPoolTypes.Side indexed side,
    uint256 collateralAmount,
    uint256 derivativeAmount,
    uint256 collateralFeeAmount,
    uint256 currentVintageIndex
  );
  event ProcessedDerivative(
    uint256 indexed portfolioId,
    uint256 indexed derivativeIndex,
    uint256 indexed timestamp,
    IPoolTypes.Pair poolPosition,
    IPoolTypes.Pair newPoolPosition,
    uint256 newVintage
  );
  event MovedDerivative(
    uint256 fromPortfolioId,
    uint256 indexed toPortfolioId,
    uint256 indexed derivativeIndex,
    IPoolTypes.Side indexed side,
    uint256 amount
  );
  event BurnedDerivative(
    uint256 indexed portfolioId,
    uint256 indexed derivativeIndex,
    IPoolTypes.Side indexed side,
    uint256 derivativeAmount,
    uint256 collateralAmount,
    uint256 collateralFeeAmount
  );

  function moveDerivativeSafely(
    PoolState.State storage _state,
    address _from,
    uint256 _fromPortfolio,
    address _to,
    uint256 _toPortfolio,
    uint256 _amount,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side
  ) public {
    if (!_state.refreshPoolTo(block.timestamp)) return;

    require(_to != address(0), "TOEMPTY");

    processUserPositionVintages(_state, _from, _fromPortfolio, _derivativeIndex);
    processUserPositionVintages(_state, _to, _toPortfolio, _derivativeIndex);

    _state.moveDerivative(_fromPortfolio, _toPortfolio, _amount, _derivativeIndex, _side);
    emit MovedDerivative(_fromPortfolio, _toPortfolio, _derivativeIndex, _side, _amount);
  }

  function processUserPositions(
    PoolState.State storage _state,
    address _user,
    uint256 _userPortfolio,
    uint256[] memory _derivativeIndexes
  ) public {
    for (uint256 i = 0; i < _derivativeIndexes.length; i++) {
      processUserPositionVintages(_state, _user, _userPortfolio, _derivativeIndexes[i]);
    }
  }

  function processUserPositionVintages(
    PoolState.State storage _state,
    address _user,
    uint256 _userPortfolio,
    uint256 _derivativeIndex
  ) public {
    if (!_state.refreshPoolTo(block.timestamp)) return;

    if (
      _state.positionBalances[_userPortfolio][_derivativeIndex].primary == 0 &&
      _state.positionBalances[_userPortfolio][_derivativeIndex].complement == 0
    ) return;

    uint256 currentVintageIndex = _state.getCurrentVintageIndexFor(_derivativeIndex);
    uint256 vintageIndex = _state.getUserPositionVintageIndex(_userPortfolio, _derivativeIndex);

    uint256 releasedCollateral = 0;
    while (vintageIndex < currentVintageIndex) {
      releasedCollateral += processPositionOnceFor(_state, _userPortfolio, _derivativeIndex);
      vintageIndex = _state.getUserPositionVintageIndex(_userPortfolio, _derivativeIndex);
    }

    uint256 releasedCollateralConverted = _state.fromStandardToCollateral(releasedCollateral);
    if (releasedCollateralConverted > 0) {
      _state.config.collateralToken.transfer(
        _user,
        releasedCollateralConverted
      );
    }
  }

  // C
  function processPositionOnceFor(
    PoolState.State storage _state,
    uint256 portfolioId,
    uint256 derivativeIndex
  ) internal returns (uint256 newVintageIndex) {
    uint256 userPositionVintageIndex = _state.getUserPositionVintageIndex(portfolioId, derivativeIndex);
    require(userPositionVintageIndex >= 1, "BADVINTIND");
    IPoolTypes.Vintage memory vintage = _state.getVintageBy(
      derivativeIndex,
      userPositionVintageIndex
    );

    IPoolTypes.Pair memory position = _state.positionBalances[portfolioId][derivativeIndex];

    uint256 collateralChange = (position.primary *
      vintage.releaseRate.primary +
      position.complement *
      vintage.releaseRate.complement) / NumLib.BONE;

    if (collateralChange > _state.balance.releasedWinnings) {
      collateralChange = _state.balance.releasedWinnings;
    }

    _state.balance.releasedWinnings -= collateralChange;

    _state.positionBalances[portfolioId][derivativeIndex] = IPoolTypes.Pair(
      (position.primary * vintage.rollRate.primary) / NumLib.BONE,
      (position.complement * vintage.rollRate.complement) / NumLib.BONE
    );

    _state.setUserPositionVintageIndex(portfolioId, derivativeIndex, userPositionVintageIndex + 1);

    require(_state.checkPoolCollateralBalance(), "COLERR");

    emit ProcessedDerivative(
      portfolioId,
      derivativeIndex,
      block.timestamp,
      position,
      _state.positionBalances[portfolioId][derivativeIndex],
      userPositionVintageIndex + 1
    );

    return collateralChange;
  }

  function calculateOutAmount(
    PoolState.State storage _state,
    uint256 derivativeIndex,
    IPoolTypes.Side side,
    uint256 inAmount,
    bool _poolReceivesCollateral,
    uint256 collateralPrice,
    uint256 underlyingPrice
  ) public returns (uint256) {
    uint256 outAmount = ITerms(_state.liveSet[derivativeIndex].terms).calculateOutAmount(
      _state.makePoolSnapshot(),
      _poolReceivesCollateral ? _state.fromCollateral(inAmount) : PoolState.fromStandard(inAmount),
      derivativeIndex,
      side,
      _poolReceivesCollateral,
      IPoolTypes.OtherPrices(
        int256(collateralPrice), //TODO: switch all math to uint256
        int256(underlyingPrice),
        0 // last volatility value
      )
    );

    return
      _poolReceivesCollateral ? PoolState.toStandard(outAmount) : _state.toCollateral(outAmount);
  }

  function mergePortfolios(
    PoolState.State storage _state,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _existedTokenId
  ) public {
    for (uint256 derivativeIndex = 0; derivativeIndex < _state.liveSet.length; derivativeIndex++) {
      IPoolTypes.Pair memory balance = _state.positionBalances[_tokenId][derivativeIndex];
      bool hasAnyBalances = balance.primary > 0 || balance.complement > 0;
      if (hasAnyBalances) {
        processUserPositionVintages(_state, _from, _tokenId, derivativeIndex);
        processUserPositionVintages(_state, _to, _existedTokenId, derivativeIndex);
        //reread position balance
        balance = _state.positionBalances[_tokenId][derivativeIndex];
      }
      if (balance.primary > 0) {
        _state.moveDerivative(
          _tokenId,
          _existedTokenId,
          balance.primary,
          derivativeIndex,
          IPoolTypes.Side.Primary
        );
        emit MovedDerivative(
          _tokenId,
          _existedTokenId,
          derivativeIndex,
          IPoolTypes.Side.Primary,
          balance.primary
        );
      }
      if (balance.complement > 0) {
        _state.moveDerivative(
          _tokenId,
          _existedTokenId,
          balance.complement,
          derivativeIndex,
          IPoolTypes.Side.Complement
        );
        emit MovedDerivative(
          _tokenId,
          _existedTokenId,
          derivativeIndex,
          IPoolTypes.Side.Complement,
          balance.complement
        );
      }
      if (hasAnyBalances) {
        delete _state.positionBalances[_tokenId][derivativeIndex];
      }
    }
  }

  function processRedemptionQueueSimple(PoolState.State storage _state) public returns (bool) {
    IPoolTypes.PoolSharePriceHints memory poolSharePriceHints = _state
      .createHintsWithCollateralPrice();
    if (poolSharePriceHints.collateralPrice == 0) return false;

    return _state.processRedemptionQueueAt(block.timestamp, poolSharePriceHints);
  }

  function processRedemptionQueue(
    PoolState.State storage _state,
    IPoolTypes.RolloverHints[] memory _rolloverHintsList
  ) public {
    _state.rolloverOldestDerivativeBatch(block.timestamp, _rolloverHintsList);

    if (!_state.refreshPoolTo(block.timestamp)) return;

    processRedemptionQueueSimple(_state);
  }

  // 2
  function joinSimple(
    PoolState.State storage _state,
    uint256 _collateralAmount,
    uint256 _minPoolShareAmountOut
  ) public {
    if (!_state.refreshPoolTo(block.timestamp)) return;

    (
      uint256 poolSharePrice,
      uint256 poolDerivativesValue,
      IPoolTypes.PoolSharePriceHints memory poolSharePriceHints
    ) = _state.getPoolSharePrice();

    if (poolSharePrice == 0) return;

    require(poolSharePriceHints.collateralPrice >= PoolState.P_MIN, "COLPMIN");
    require(poolSharePrice >= PoolState.P_MIN, "PTPMIN");

    uint256 poolShareAmountOut = PoolState.toStandard((poolSharePriceHints.collateralPrice * _state.fromCollateral(_collateralAmount)) / poolSharePrice);

    require(poolShareAmountOut >= _minPoolShareAmountOut, "MINLPOUT");

    PoolState.pullCollateral(
      address(_state.config.collateralToken),
      msg.sender,
      _collateralAmount
    );
    _state.balance.collateralFree += _state.fromCollateralToStandard(_collateralAmount);

    _state.config.poolShare.mint(address(this), poolShareAmountOut);
    _state.config.poolShare.transfer(msg.sender, poolShareAmountOut);

    uint256 poolSharePriceAfter = (_state.calcPoolCollateralValue(poolSharePriceHints.collateralPrice) + poolDerivativesValue) * NumLib.BONE
      / PoolState.fromStandard(_state.config.poolShare.totalSupply());

    require(PoolState.subMod(poolSharePriceAfter, poolSharePrice) <= PoolState.POOL_SHARE_PRICE_APPROXIMATION, "JOINLPP");

    require(_state.checkPoolCollateralBalance(), "COLERR");

    emit JoinedPool(
      msg.sender,
      block.timestamp,
      _collateralAmount,
      poolShareAmountOut,
      poolSharePrice
    );

    processRedemptionQueueSimple(_state);
  }

  function join(
    PoolState.State storage _state,
    uint256 _collateralAmount,
    uint256 _minPoolShareAmountOut,
    IPoolTypes.RolloverHints[] memory _rolloverHintsList
  ) public {
    _state.rolloverOldestDerivativeBatch(block.timestamp, _rolloverHintsList);
    joinSimple(_state, _collateralAmount, _minPoolShareAmountOut);
  }

  // 3
  function exitSimple(PoolState.State storage _state, uint256 _poolShareAmountIn) public {
    require(_poolShareAmountIn <= _state.config.poolShare.balanceOf(msg.sender), "WRONGAMOUNT");
    require(
      _poolShareAmountIn >= _state.config.minExitAmount ||
        _poolShareAmountIn == _state.config.poolShare.balanceOf(msg.sender),
      "MINEXIT"
    );

    _state.redemptionQueue.enqueue(
      RedemptionQueue.Request({
        owner: msg.sender,
        amount: _poolShareAmountIn,
        time: block.timestamp
      })
    );

    _state.config.poolShare.transferFrom(msg.sender, address(this), _poolShareAmountIn);

    emit CreatedRedemptionQueueItem(msg.sender, block.timestamp, _poolShareAmountIn);
  }

  function exit(
    PoolState.State storage _state,
    uint256 _poolShareAmountIn,
    IPoolTypes.RolloverHints[] memory _rolloverHintsList
  ) public {
    exitSimple(_state, _poolShareAmountIn);

    _state.rolloverOldestDerivativeBatch(block.timestamp, _rolloverHintsList);

    processRedemptionQueueSimple(_state);

    uint256 userReleasedLiquidity = _state.getReleasedLiquidity(msg.sender);

    if (userReleasedLiquidity > 0) {
      _state.withdrawReleasedLiquidity(_state.fromStandardToCollateral(userReleasedLiquidity));
    }
  }

  struct VarsTrade {
    IPoolTypes.Derivative derivative;
    uint256 currentVintage;
    uint256 userPortfolio;
    uint256 vintageIndex;
    uint256 collateralPrice;
    uint256 underlyingPrice;
    uint256 outAmount;
  }

  // 4
  function buySimple(
    PoolState.State storage _state,
    uint256 _userPortfolio,
    uint256 _collateralAmount,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    uint256 _minDerivativeAmount
  ) public {
    require(_derivativeIndex < _state.liveSet.length, "DERIND");

    if (!_state.refreshPoolTo(block.timestamp)) return;

    if (!_state.checkIfRedemptionQueueEmpty()) {
      processRedemptionQueueSimple(_state);
      if (_state.pausing) return;
    }
    require(_state.checkIfRedemptionQueueEmpty(), "NOTEMPTYQUEUE");

    VarsTrade memory vars;

    PoolState.pullCollateral(
      address(_state.config.collateralToken),
      msg.sender,
      _collateralAmount
    );
    uint256 feeAmount = (_collateralAmount * _state.config.protocolFee) / NumLib.BONE;
    if (feeAmount > 0) {
      PoolState.pushCollateral(
        address(_state.config.collateralToken),
        _state.config.feeWallet,
        feeAmount
      );
      _collateralAmount -= feeAmount;
    }

    vars.derivative = _state.liveSet[_derivativeIndex];
    require(
      vars.derivative.sequence.side == _side ||
        vars.derivative.sequence.side == IPoolTypes.Side.Both,
      "SIDE"
    );

    processUserPositionVintages(_state, msg.sender, _userPortfolio, _derivativeIndex);

    vars.collateralPrice = _state.getLatestAnswer(
      _state.config.collateralOracleIterator,
      _state.config.collateralOracle
    );
    if (vars.collateralPrice == 0) return;

    vars.underlyingPrice = _state.getLatestAnswerByDerivative(vars.derivative);
    if (vars.underlyingPrice == 0) return;

    vars.outAmount = calculateOutAmount(
      _state,
      _derivativeIndex,
      _side,
      _collateralAmount,
      true,
      vars.collateralPrice,
      vars.underlyingPrice
    );

    require(vars.outAmount >= _minDerivativeAmount, "MINDER");

    if (_side == IPoolTypes.Side.Primary) {
      _state.positionBalances[_userPortfolio][_derivativeIndex].primary += vars.outAmount;
      _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex].complement += vars.outAmount;
    } else if (_side == IPoolTypes.Side.Complement) {
      _state.positionBalances[_userPortfolio][_derivativeIndex].complement += vars.outAmount;
      _state.positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex].primary += vars.outAmount;
    }
    uint256 currentVintageIndex = _state.getCurrentVintageIndexFor(_derivativeIndex);
    // set current vintage as initial
    _state.setUserPositionVintageIndex(_userPortfolio, _derivativeIndex, currentVintageIndex);

    uint256 requiredCollateral = (vars.derivative.params.denomination * vars.outAmount) /
      NumLib.BONE + 1; //increment by minimal - round up
    _state.balance.collateralFree =
      _state.balance.collateralFree +
      _state.fromCollateralToStandard(_collateralAmount) -
      requiredCollateral;
    _state.balance.collateralLocked += requiredCollateral;

    require(_state.checkPoolCollateralBalance(), "COLERR");

    processRedemptionQueueSimple(_state);

    emit MintedDerivative(
      _userPortfolio,
      _derivativeIndex,
      _side,
      _collateralAmount,
      vars.outAmount,
      feeAmount,
      currentVintageIndex
    );
  }

  function buy(
    PoolState.State storage _state,
    address _user,
    uint256 _userPortfolio,
    uint256 _collateralAmount,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    uint256 _minDerivativeAmount,
    bool _redeemable,
    IPoolTypes.RolloverHints[] memory _rolloverHintsList
  ) public {
    _state.rolloverOldestDerivativeBatch(block.timestamp, _rolloverHintsList);
    if(_redeemable) {
      processUserPositionsAll(_state, _user, _userPortfolio);
    }
    buySimple(_state, _userPortfolio, _collateralAmount, _derivativeIndex, _side, _minDerivativeAmount);
  }

  // 5
  function sellSimple(
    PoolState.State storage _state,
    uint256 _userPortfolio,
    uint256 _derivativeAmount,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    uint256 _minCollateralAmount
  ) public {
    require(_derivativeIndex < _state.liveSet.length, "DERIND");

    if (!_state.refreshPoolTo(block.timestamp)) return;

    processUserPositionVintages(_state, msg.sender, _userPortfolio, _derivativeIndex);

    VarsTrade memory vars;

    vars.derivative = _state.liveSet[_derivativeIndex];

    uint256 userDerivativeBalance = _side == IPoolTypes.Side.Primary
      ? _state.positionBalances[_userPortfolio][_derivativeIndex].primary
      : _state.positionBalances[_userPortfolio][_derivativeIndex].complement;

    uint256 derivativeAmountBalanced = _derivativeAmount > userDerivativeBalance
      ? userDerivativeBalance
      : _derivativeAmount;

    vars.collateralPrice = _state.getLatestAnswer(
      _state.config.collateralOracleIterator,
      _state.config.collateralOracle
    );
    if (vars.collateralPrice == 0) return;

    vars.underlyingPrice = _state.getLatestAnswerByDerivative(vars.derivative);
    if (vars.underlyingPrice == 0) return;

    vars.outAmount = calculateOutAmount(
      _state,
      _derivativeIndex,
      _side,
      derivativeAmountBalanced,
      false,
      vars.collateralPrice,
      vars.underlyingPrice
    );

    require(vars.outAmount >= _minCollateralAmount, "MINCOL");

    if (_side == IPoolTypes.Side.Primary) {
      _state.positionBalances[_userPortfolio][_derivativeIndex].primary -= derivativeAmountBalanced;
      _state
      .positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex]
        .complement -= derivativeAmountBalanced;
    } else if (_side == IPoolTypes.Side.Complement) {
      _state.positionBalances[_userPortfolio][_derivativeIndex].complement -= derivativeAmountBalanced;
      _state
      .positionBalances[PoolState.POOL_PORTFOLIO_ID][_derivativeIndex].primary -= derivativeAmountBalanced;
    }

    uint256 requiredCollateral = (vars.derivative.params.denomination * derivativeAmountBalanced) /
      NumLib.BONE;
    _state.balance.collateralFree =
      _state.balance.collateralFree +
      requiredCollateral -
      _state.fromCollateralToStandard(vars.outAmount);
    _state.balance.collateralLocked -= requiredCollateral;

    require(_state.checkPoolCollateralBalance(), "COLERR");

    uint256 feeAmount = (vars.outAmount * _state.config.protocolFee) / NumLib.BONE;
    if (feeAmount > 0) {
      PoolState.pushCollateral(
        address(_state.config.collateralToken),
        _state.config.feeWallet,
        feeAmount
      );
    }

    PoolState.pushCollateral(
      address(_state.config.collateralToken),
      msg.sender,
      vars.outAmount - feeAmount
    );

    processRedemptionQueueSimple(_state);

    emit BurnedDerivative(
      _userPortfolio,
      _derivativeIndex,
      _side,
      derivativeAmountBalanced,
      vars.outAmount,
      feeAmount
    );
  }

  function sell(
    PoolState.State storage _state,
    address _user,
    uint256 _userPortfolio,
    uint256 _derivativeAmount,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    uint256 _minCollateralAmount,
    bool _redeemable,
    IPoolTypes.RolloverHints[] memory _rolloverHintsList
  ) public {
    _state.rolloverOldestDerivativeBatch(block.timestamp, _rolloverHintsList);
    if(_redeemable) {
      processUserPositionsAll(_state, _user, _userPortfolio);
    }
    sellSimple(_state, _userPortfolio, _derivativeAmount, _derivativeIndex, _side, _minCollateralAmount);
  }

  function processUserPositionsAll(
    PoolState.State storage _state,
    address _user,
    uint256 _userPortfolio
  ) public {
    for (uint256 i = 0; i < _state.liveSet.length; i++) {
      processUserPositionVintages(_state, _user, _userPortfolio, i);
    }
  }
}