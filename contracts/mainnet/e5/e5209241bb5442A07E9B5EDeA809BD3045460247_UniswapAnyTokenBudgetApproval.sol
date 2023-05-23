// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./base/PriceResolver.sol";
import "./base/CommonBudgetApproval.sol";
import "./lib/BytesLib.sol";
import "./lib/Constant.sol";
import "./interface/IDao.sol";
import "./interface/IAdam.sol";
import "./interface/IBudgetApprovalExecutee.sol";
import "./dex/UniswapSwapper.sol";

contract UniswapAnyTokenBudgetApproval is CommonBudgetApproval, UniswapSwapper {

    using BytesLib for bytes;

    event AllowToToken(address token);
    event ExecuteUniswapInTransaction(uint256 indexed id, address indexed executor, address indexed toAddress, address token, uint256 amount);
    event ExecuteUniswapOutTransaction(uint256 indexed id, address indexed executor, address indexed toAddress, address token, uint256 amount);
    event ExecuteWETH9Transaction(uint256 indexed id, address indexed executor, address indexed toAddress, address tokenIn, address tokenOut, uint256 amount);

    string public constant override name = "Uniswap Any Token Budget Approval";

    bool public allowAllFromTokens;
    address public fromToken;
    bool public allowAllToTokens;
    mapping(address => bool) public toTokensMapping;
    bool public allowAnyAmount;
    uint256 public totalAmount;
    uint8 public amountPercentage;

    mapping(uint256 => mapping(address => uint256)) private _tokenInAmountOfTransaction;
    mapping(uint256 => address[]) private _tokenInOfTransaction;

    function initialize(
        InitializeParams calldata params,
        bool _allowAllFromTokens,
        address _fromToken,
        bool _allowAllToTokens,
        address[] calldata _toTokens,
        bool _allowAnyAmount,
        uint256 _totalAmount,
        uint8 _amountPercentage
    ) public initializer {
        __BudgetApproval_init(params);
        
        allowAllFromTokens = _allowAllFromTokens;
        if(!_allowAllFromTokens) {
            fromToken = _fromToken;
            emit AllowToken(_fromToken);
        }

        allowAllToTokens = _allowAllToTokens;
        for(uint i = 0; i < _toTokens.length; i++) {
            _addToToken(_toTokens[i]);
        }

        allowAnyAmount = _allowAnyAmount;
        totalAmount = _totalAmount;
        amountPercentage = _amountPercentage;

    }

    function afterInitialized() external override onlyExecutee {
         if(!allowAllFromTokens) {
            approveTokenForUniswap(fromToken);
        }
    }

    function approveTokenForUniswap(address _fromToken) public {

        address _executee = executee();

        require(msg.sender == _executee ||
          msg.sender == executor() ||
          ITeam(team()).balanceOf(msg.sender, executorTeamId()) > 0, "Executor not whitelisted in budget"
        );

        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", Constant.UNISWAP_ROUTER, type(uint256).max);
        IBudgetApprovalExecutee(_executee).executeByBudgetApproval(_fromToken, data, 0);
    }

    function executeParams() external pure override returns (string[] memory) {
        string[] memory arr = new string[](3);
        arr[0] = "address to";
        arr[1] = "bytes data";
        arr[2] = "uint256 value";
        return arr;
    }

    function _execute(
        uint256 transactionId, 
        bytes memory data
    ) internal override {
        (address to, bytes memory executeData, uint256 value) = abi.decode(data,(address, bytes, uint256));
        
        if (to == Constant.UNISWAP_ROUTER) {
            _executeUniswapCall(transactionId, to, executeData, value);
        } else if (to == WETH9()) {
            _executeWETH9Call(transactionId, to, executeData, value);
        } else {
            revert("Invalid target address");
        }
    }

    function _executeUniswapCall(uint256 transactionId, address to, bytes memory executeData, uint256 value) private {
        address __executee = executee();

        bytes memory response = IBudgetApprovalExecutee(__executee).executeByBudgetApproval(to, executeData, value);
        MulticallData[] memory mDataArr = this.decodeUniswapMulticall(executeData, value, response);

        address[] storage _tokenIn = _tokenInOfTransaction[transactionId];
        mapping(address => uint256) storage _tokenInAmount = _tokenInAmountOfTransaction[transactionId];

        for (uint i = 0; i < mDataArr.length; i++) {
            MulticallData memory mData = mDataArr[i];

            require(mData.recipient == address(0) || 
                mData.recipient == RECIPIENT_EXECUTEE || 
                mData.recipient == RECIPIENT_UNISWAP_ROUTER || 
                mData.recipient == __executee, "Recipient not whitelisted");
            
            if (mData.amountIn > 0) {
                require(allowAllFromTokens || fromToken == mData.tokenIn, "Source token not whitelisted");

                if (_tokenInAmount[mData.tokenIn] == 0) {
                    _tokenIn.push(mData.tokenIn);
                }
                _tokenInAmount[mData.tokenIn] += mData.amountIn;

                emit ExecuteUniswapInTransaction(transactionId, msg.sender, Constant.UNISWAP_ROUTER, mData.tokenIn, mData.amountIn);
            }

            if (mData.amountOut > 0 && (mData.recipient == RECIPIENT_EXECUTEE || mData.recipient == __executee)) {
                require(allowAllToTokens || toTokensMapping[mData.tokenOut], "Target token not whitelisted");

                emit ExecuteUniswapOutTransaction(transactionId, msg.sender, Constant.UNISWAP_ROUTER, mData.tokenOut, mData.amountOut);
            }
        }

        if (!allowAnyAmount || amountPercentage < 100) {
            for (uint i = 0; i < _tokenIn.length; i++) {
                address tokenIn = _tokenIn[i];
                uint256 amount = _tokenInAmount[tokenIn];

                uint256 tokenInBalanceBeforeSwap;
                if(tokenIn == Constant.NATIVE_TOKEN) {
                    tokenInBalanceBeforeSwap = __executee.balance + amount;
                } else {
                    tokenInBalanceBeforeSwap = IERC20(tokenIn).balanceOf(__executee) + amount;
                }

                require(allowAnyAmount || amount <= totalAmount, "Exceeded max amount");
                require(_checkAmountPercentageValid(tokenInBalanceBeforeSwap, amount), "Exceeded percentage");     
                            
                if(!allowAnyAmount) {
                    totalAmount -= amount;
                }
            }
        }

    }

    function _executeWETH9Call(uint256 transactionId, address to, bytes memory executeData, uint256 value) private {
        address __executee = executee();

        IBudgetApprovalExecutee(__executee).executeByBudgetApproval(to, executeData, value);
        (
            address tokenIn,
            address tokenOut,
            uint256 amount
        ) = this.decodeWETH9Call(executeData, value);

        uint256 tokenInBalanceBeforeSwap;
        if(tokenIn == Constant.NATIVE_TOKEN) {
            tokenInBalanceBeforeSwap = __executee.balance + amount;
        } else {
            tokenInBalanceBeforeSwap = IERC20(tokenIn).balanceOf(__executee) + amount;
        }

        require(allowAllFromTokens || fromToken == tokenIn, "Source token not whitelisted");
        require(allowAllToTokens || toTokensMapping[tokenOut], "Target token not whitelisted");
        require(allowAnyAmount || amount <= totalAmount, "Exceeded max amount");
        require(_checkAmountPercentageValid(tokenInBalanceBeforeSwap, amount), "Exceeded percentage");
        
        if(!allowAnyAmount) {
            totalAmount -= amount;
        }

        emit ExecuteWETH9Transaction(transactionId, msg.sender, WETH9(), tokenIn, tokenOut, amount);
    }

    function _checkAmountPercentageValid(uint256 balanceOfToken, uint256 amount) private view returns (bool) {
        if (amountPercentage == 100) return true;

        if (balanceOfToken == 0) return false;

        return amount <= balanceOfToken * amountPercentage / 100;
    }

    function _addToToken(address token) private {
        require(!toTokensMapping[token], "Duplicated token in target token list");
        toTokensMapping[token] = true;
        emit AllowToToken(token);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../lib/BytesLib.sol";
import "../interface/ITeam.sol";
import "../interface/IBudgetApprovalExecutee.sol";

abstract contract CommonBudgetApproval is Initializable {

    using Counters for Counters.Counter;
    using BytesLib for bytes;

    enum Status {
        Pending,
        Approved,
        Completed,
        Cancelled
    }

    struct Transaction {
        uint256 id;
        bytes[] data;
        Status status;
        uint32 deadline;
        bool isExist;
        uint256 approvedCount;
        mapping(address => bool) approved;
    }

    event CreateTransaction(
        uint256 indexed id,
        bytes[] data,
        uint256 deadline,
        Status status,
        string comment,
        address creator
    );
    event ApproveTransaction(
        uint256 indexed id,
        address approver,
        string comment
    );
    event ExecuteTransaction(
        uint256 indexed id,
        bytes[] data,
        address _executor
    );
    event RevokeTransaction(uint256 indexed id);
    event AllowAddress(address target);
    event AllowToken(address token);
    event AllowAmount(uint256 amount);
    event SetApprover(address approver);

    Counters.Counter private _transactionIds;

    mapping(uint256 => Transaction) public transactions;

    address private _executor;
    uint256 private _executorTeamId;
    address private _executee; // Must be BudgetApprovalExecutee

    mapping(address => bool) private _approversMapping;
    uint256 private _approverTeamId;
    uint256 private _minApproval;

    string private _text;
    string private _transactionType;

    bool private _allowUnlimitedUsageCount;
    uint256 private _usageCount;

    uint256 private _startTime;
    uint256 private _endTime;


    struct InitializeParams {
        address executor;
        uint256 executorTeamId;
        address[] approvers;
        uint256 approverTeamId;
        uint256 minApproval;
        string text;
        string transactionType;
        uint256 startTime;
        uint256 endTime;
        bool allowUnlimitedUsageCount;
        uint256 usageCount;
    }

    error UnauthorizedExecutee();
    error UnauthorizedExecutor();
    error UnauthorizedApprover();
    error InvalidTransactionStatus(uint256 id, Status status);
    error TransactionExpired(uint256 id);
    error BudgetNotStarted();
    error BudgetHasEnded();
    error InvalidApproverList();
    error InvalidExecuteeTeam();
    error BudgetUsageExceeded();
    error InvalidTransactionId(uint256 id);
    error ActionDuplicated();

    modifier onlyExecutee() {
        if (msg.sender != executee()) {
            revert UnauthorizedExecutee();
        }
        _;
    }

    modifier matchStatus(uint256 id, Status status) {
        Status _status = transactions[id].status;
        if (_status != status) {
            revert InvalidTransactionStatus(id, _status);
        }
        _;
    }

    modifier checkTime(uint256 id) {
        if (block.timestamp > transactions[id].deadline) {
            revert TransactionExpired(id);
        }
        if (block.timestamp < startTime()) {
            revert BudgetNotStarted();
        }
        if (block.timestamp >= endTime()) {
            revert BudgetHasEnded();
        }
        _;
    }

    modifier onlyApprover() {
        if (!_isApprover(msg.sender)) {
            revert UnauthorizedApprover();
        }
        _;
    }

    modifier onlyExecutor() {
        if (!_isExecutor(msg.sender)) {
            revert UnauthorizedExecutor();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function executor() public view returns (address) {
        return _executor;
    }

    function _isExecutor(address eoa) internal view virtual returns (bool) {
        return eoa == executor() ||
            _inTeam(eoa, executorTeamId());
    }

    function _isApprover(address eoa) internal view virtual returns (bool) {
        return approversMapping(eoa) ||
                _inTeam(eoa, approverTeamId());
    }

    function _inTeam(address eoa, uint256 teamId) internal view returns (bool) {
        return ITeam(team()).balanceOf(eoa, teamId) > 0;
    }

    function executorTeamId() public view returns (uint256) {
        return _executorTeamId;
    }

    function executee() public view returns (address) {
        return _executee;
    }

    function approversMapping(address eoa) public view returns (bool) {
        return _approversMapping[eoa];
    }

    function approverTeamId() public view returns (uint256) {
        return _approverTeamId;
    }

    function minApproval() public view returns (uint256) {
        return _minApproval;
    }

    function text() public view returns (string memory) {
        return _text;
    }

    function transactionType() public view returns (string memory) {
        return _transactionType;
    }

    function allowUnlimitedUsageCount() public view returns (bool) {
        return _allowUnlimitedUsageCount;
    }

    function usageCount() public view returns (uint256) {
        return _usageCount;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function endTime() public view returns (uint256) {
        return _endTime;
    }

    function team() public view returns (address) {
        return IBudgetApprovalExecutee(executee()).team();
    }

    function __BudgetApproval_init(InitializeParams calldata params)
        internal
        onlyInitializing
    {
        if (params.approverTeamId == 0 && (params.minApproval > params.approvers.length)) {
            revert InvalidApproverList();
        }

        _executee = msg.sender;
        _executor = params.executor;
        _text = params.text;
        _transactionType = params.transactionType;

        _minApproval = params.minApproval;
        _startTime = params.startTime;
        _endTime = params.endTime;

        _allowUnlimitedUsageCount = params.allowUnlimitedUsageCount;
        _usageCount = params.usageCount;

        _executorTeamId = params.executorTeamId;
        _approverTeamId = params.approverTeamId;

        for (uint256 i = 0; i < params.approvers.length; i++) {
            _approversMapping[params.approvers[i]] = true;
            emit SetApprover(params.approvers[i]);
        }

        if (team() == address(0)) {
            revert InvalidExecuteeTeam();
        }
    }

    function afterInitialized() external virtual onlyExecutee {}

    function executeTransaction(uint256 id)
        public
        virtual
        matchStatus(id, Status.Approved)
        checkTime(id)
        onlyExecutor
        payable
    {
        bool unlimited = allowUnlimitedUsageCount();
        uint256 count = usageCount();
        bytes[] memory data = transactions[id].data;

        for (uint256 i = 0; i < data.length; i++) {
            if (!unlimited && count == 0) {
                revert BudgetUsageExceeded();
            }
            if (!unlimited) {
                count--;
            }
            _execute(id, data[i]);
        }

        _usageCount = count;
        transactions[id].status = Status.Completed;
        emit ExecuteTransaction(id, data, msg.sender);
    }

    function createTransaction(
        bytes[] memory _data,
        uint32 _deadline,
        bool _isExecute,
        string calldata comment
    ) external virtual onlyExecutor payable returns (uint256) {
        _transactionIds.increment();
        uint256 id = _transactionIds.current();

        // workaround when have mapping in Struct
        Transaction storage newTransaction = transactions[id];
        newTransaction.id = id;
        newTransaction.data = _data;
        newTransaction.deadline = _deadline;
        newTransaction.isExist = true;

        if (minApproval() == 0) {
            transactions[id].status = Status.Approved;
        } else {
            transactions[id].status = Status.Pending;
        }

        emit CreateTransaction(
            id,
            _data,
            _deadline,
            newTransaction.status,
            comment,
            msg.sender
        );

        if (_isExecute) {
            executeTransaction(id);
        }
        return id;
    }

    function approveTransaction(uint256 id, string calldata comment)
        external
        virtual
        onlyApprover
    {
        if (_transactionIds.current() < id) {
            revert InvalidTransactionId(id);
        }

        Status _status = transactions[id].status;
        uint256 _approvedCount = transactions[id].approvedCount + 1;

        if (_status != Status.Pending && _status != Status.Approved) {
            revert InvalidTransactionStatus(id, _status);
        }
        if (transactions[id].approved[msg.sender]) {
            revert ActionDuplicated();
        }

        transactions[id].approved[msg.sender] = true;
        transactions[id].approvedCount = _approvedCount;

        if (_approvedCount >= minApproval()) {
            transactions[id].status = Status.Approved;
        }

        emit ApproveTransaction(id, msg.sender, comment);
    }

    function revokeTransaction(uint256 id) external virtual onlyExecutor {
        if (_transactionIds.current() < id) {
            revert InvalidTransactionId(id);
        }

        Status _status = transactions[id].status;
        if (_status == Status.Completed) {
            revert InvalidTransactionStatus(id, _status);
        }

        transactions[id].status = Status.Cancelled;

        emit RevokeTransaction(id);
    }

    function _execute(uint256, bytes memory) internal virtual;

    function executeParams() external pure virtual returns (string[] memory);

    function name() external virtual returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interface/IAccountingSystem.sol";
import "../lib/Constant.sol";

abstract contract PriceResolver {
    error PairNotSupport(address asset, address base);

    function baseCurrency() public view virtual returns (address);
    function accountingSystem() public view virtual returns (address);

    /// @notice This function is imported by other contract, thus cannot be external
    function assetBaseCurrencyPrice(address asset, uint256 amount) public  view virtual returns (uint256) {
        address _baseCurrency = baseCurrency();
        address _accountingSystem = accountingSystem();

        if (!IAccountingSystem(accountingSystem()).isSupportedPair(asset, baseCurrency())) {
            revert PairNotSupport(asset, baseCurrency());
        }
        return IAccountingSystem(_accountingSystem).assetPrice(asset, _baseCurrency, amount);
    }

    function assetPrice(address asset, address base, uint256 amount) public  view virtual returns (uint256) {
        address _accountingSystem = accountingSystem();
        if (!IAccountingSystem(accountingSystem()).isSupportedPair(asset, base)) {
            revert PairNotSupport(asset, base);
        }
        return IAccountingSystem(_accountingSystem).assetPrice(asset, base, amount);
    }

    function baseCurrencyDecimals() public view virtual returns (uint8) {
        address _baseCurrency = baseCurrency();
        if (_baseCurrency == Constant.NATIVE_TOKEN) return 18;
        try IERC20Metadata(_baseCurrency).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 0;
        }
    }

    /// @notice This function is imported by other contract, thus cannot be external
    function canResolvePrice(address asset) public view virtual returns (bool) {
       return IAccountingSystem(accountingSystem()).isSupportedPair(asset, baseCurrency());
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

import "../lib/BytesLib.sol";
import "../lib/Constant.sol";

contract UniswapSwapper is Initializable {
    using BytesLib for bytes;

    address public constant RECIPIENT_EXECUTEE = address(1);
    address public constant RECIPIENT_UNISWAP_ROUTER = address(2);

    enum MulticallResultAttribute { EMPTY, AMOUNT_IN, AMOUNT_OUT }

    struct MulticallData {
        address recipient;
        address tokenIn;
        address tokenOut; 
        uint256 amountIn; 
        uint256 amountOut; 
        MulticallResultAttribute resultType;
    }

    error DecodeFailed(bytes result);
    error DecodeWETHDataFail();
    error TooMuchETH();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }
    
    function WETH9() public pure returns (address) {
        return Constant.WETH_ADDRESS;
    }

    function decodeWETH9Call(bytes memory data, uint256 value) external pure returns(address tokenIn, address tokenOut, uint256 amount) {
        bytes4 funcSig = data.toBytes4(0);
        if (funcSig == bytes4(keccak256("deposit()"))) {
            return (Denominations.ETH, WETH9(), value);
        } else if (funcSig == bytes4(keccak256("withdraw(uint256)"))) {
            return (WETH9(), Denominations.ETH, abi.decode(data.slice(4, data.length - 4), (uint256)));
        }

        revert("Failed to decode Uniswap bytecode");
    }

    function decodeUniswapMulticall(bytes memory rawData, uint256 value, bytes memory response) external view returns(MulticallData[] memory multicalData) {
        bytes[] memory executions = _decodeMulticall(rawData);
        bytes[] memory executionResults;
        uint256 remainEth = value;

        multicalData = new MulticallData[](executions.length);

        if (response.length != 0) {
            executionResults = abi.decode(response, (bytes[]));
        } 

        for (uint i = 0; i < executions.length; i++) {
            (bool success, bytes memory rawSwapData) = address(this).staticcall(executions[i]);
            if (!success) {
                revert DecodeFailed(rawSwapData);
            }

            MulticallData memory swapData = abi.decode(rawSwapData, (MulticallData));
            
            if (swapData.tokenIn == WETH9() && remainEth != 0) {
                if (swapData.amountIn > remainEth) {
                    revert DecodeWETHDataFail();
                }
                swapData.tokenIn = Denominations.ETH;
                remainEth -= swapData.amountIn;
            }
            if (executionResults.length != 0) {
                if (swapData.resultType == MulticallResultAttribute.AMOUNT_IN) {
                    swapData.amountIn = abi.decode(executionResults[i], (uint256));
                } else if (swapData.resultType == MulticallResultAttribute.AMOUNT_OUT) {
                    swapData.amountOut = abi.decode(executionResults[i], (uint256));
                }
            }
            multicalData[i] = swapData;
        }
        if (remainEth != 0) {
            revert TooMuchETH();
        }
    }

    function _decodeMulticall(bytes memory _data) internal pure returns (bytes[] memory executions) {
        bytes4 funcSig = _data.toBytes4(0);
        if (funcSig == bytes4(keccak256("multicall(uint256,bytes[])"))) {
            (, executions) = abi.decode(_data.slice(4, _data.length - 4), (uint256, bytes[]));
        } else if (funcSig == bytes4(keccak256("multicall(bytes32,bytes[])"))) {
            (, executions) = abi.decode(_data.slice(4, _data.length - 4), (bytes32, bytes[]));
        } else {
           revert("Failed to decode Uniswap multicall bytecode");
        }
    }

    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactOutputSingle(
        IV3SwapRouter.ExactOutputSingleParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountIn: params.amountInMaximum,
            amountOut: params.amountOut,
            resultType: MulticallResultAttribute.AMOUNT_IN
        });
    }
    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactInputSingle(
        IV3SwapRouter.ExactInputSingleParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountIn: params.amountIn,
            amountOut: params.amountOutMinimum,
            resultType: MulticallResultAttribute.AMOUNT_OUT
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactOutput(
        IV3SwapRouter.ExactOutputParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.path.toAddress(0),
            tokenOut: params.path.toAddress(params.path.length - 20),
            amountIn: params.amountInMaximum,
            amountOut: params.amountOut, 
            resultType: MulticallResultAttribute.AMOUNT_IN
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactInput(
        IV3SwapRouter.ExactInputParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.path.toAddress(0),
            tokenOut: params.path.toAddress(params.path.length - 20),
            amountIn: params.amountIn,
            amountOut: params.amountOutMinimum, 
            resultType: MulticallResultAttribute.AMOUNT_OUT
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V2SwapRouter.sol
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: path[0],
            tokenOut: path[path.length - 1],
            amountIn: amountInMax,
            amountOut: amountOut, 
            resultType: MulticallResultAttribute.AMOUNT_IN
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V2SwapRouter.sol
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: path[0],
            tokenOut: path[path.length - 1],
            amountIn: amountIn,
            amountOut: amountOutMin, 
            resultType: MulticallResultAttribute.AMOUNT_OUT
        });
    }

    function unwrapWETH9(
        uint256 amountMinimum,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: address(0),
            tokenOut: Denominations.ETH,
            amountIn: 0,
            amountOut: amountMinimum, 
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    function refundETH() external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: address(0),
            tokenIn: address(0),
            tokenOut: address(0),
            amountIn: 0,
            amountOut: 0,
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    function selfPermit(
        address, uint256, uint256, uint8, bytes32, bytes32
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: address(0),
            tokenIn: address(0),
            tokenOut: address(0),
            amountIn: 0,
            amountOut: 0, 
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: address(0),
            tokenOut: token,
            amountIn: 0,
            amountOut: amountMinimum, 
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    uint256[50] private __gap;

}

// SPDX-License-Identifier: GPL-3.0
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity 0.8.7;

interface IAccountingSystem {
    error InputLengthNotMatch(uint256 count1, uint256 count2);
    error OwnerNotPermit(address priceGateway);
    error PairNotSupport(address asset, address base);
    error PriceGatewayExist(address priceGateway);
    error PriceGatewayOmit(address priceGateway);
    event AddPriceGateway(address priceGateway);
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function addPriceGateway(address priceGateway) external;

    function assetPrice(
        address asset,
        address base,
        uint256 amount
    ) external view returns (uint256);

    function defaultPriceGateway() external view returns (address);

    function initialize(address[] memory _priceGateways) external;

    function isSupportedPair(address asset, address base)
        external
        view
        returns (bool);

    function owner() external view returns (address);

    function priceGateways(address) external view returns (bool);

    function renounceOwnership() external;

    function setTokenPairPriceGatewayMap(
        address[] memory _assets,
        address[] memory _bases,
        address priceGateway
    ) external;

    function tokenPairPriceGatewayMap(address, address)
        external
        view
        returns (address);

    function transferOwnership(address newOwner) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"count1","type":"uint256"},{"internalType":"uint256","name":"count2","type":"uint256"}],"name":"InputLengthNotMatch","type":"error"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"OwnerNotPermit","type":"error"},{"inputs":[{"internalType":"address","name":"asset","type":"address"},{"internalType":"address","name":"base","type":"address"}],"name":"PairNotSupport","type":"error"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"PriceGatewayExist","type":"error"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"PriceGatewayOmit","type":"error"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"priceGateway","type":"address"}],"name":"AddPriceGateway","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"addPriceGateway","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"asset","type":"address"},{"internalType":"address","name":"base","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"assetPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"defaultPriceGateway","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_priceGateways","type":"address[]"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"asset","type":"address"},{"internalType":"address","name":"base","type":"address"}],"name":"isSupportedPair","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"priceGateways","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_assets","type":"address[]"},{"internalType":"address[]","name":"_bases","type":"address[]"},{"internalType":"address","name":"priceGateway","type":"address"}],"name":"setTokenPairPriceGatewayMap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"tokenPairPriceGatewayMap","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: GPL-3.0
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity 0.8.7;

interface IAdam {
    error BudgetApprovalAlreadyInitialized(address budgetApproval);
    error BudgetApprovalNotFound(address budgetApproval);
    error DaoBeaconAlreadyInitialized(address _daoBeacon);
    error InvalidContract(address _contract);
    error PriceGatewayAlreadyInitialized(address priceGateway);
    error PriceGatewayNotFound(address priceGateway);
    event AbandonBudgetApproval(address budgetApproval);
    event AbandonPriceGateway(address priceGateway);
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event CreateDao(address indexed dao, address creator, address referer);
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SetDaoBeacon(
        address indexed _daoBeacon,
        uint256 indexed _index,
        string _name
    );
    event Upgraded(address indexed implementation);
    event WhitelistBudgetApproval(address budgetApproval);
    event WhitelistPriceGateway(address priceGateway);

    function abandonBudgetApprovals(address[] memory _budgetApprovals) external;

    function abandonPriceGateways(address[] memory _priceGateways) external;

    function budgetApprovals(address) external view returns (bool);

    function createDao(
        string memory _name,
        string memory _description,
        address _baseCurrency,
        bytes[] memory _data,
        address _referer
    ) external returns (address);

    function daoBeacon() external view returns (address);

    function daoBeaconIndex(address) external view returns (uint256);

    function daos(address) external view returns (bool);

    function initialize(
        address _daoBeacon,
        address[] memory _budgetApprovalImplementations,
        address[] memory _priceGatewayImplementations
    ) external;

    function owner() external view returns (address);

    function priceGateways(address) external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function setDaoBeacon(address _daoBeacon) external;

    function transferOwnership(address newOwner) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;

    function whitelistBudgetApprovals(address[] memory _budgetApprovals)
        external;

    function whitelistPriceGateways(address[] memory _priceGateways) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"budgetApproval","type":"address"}],"name":"BudgetApprovalAlreadyInitialized","type":"error"},{"inputs":[{"internalType":"address","name":"budgetApproval","type":"address"}],"name":"BudgetApprovalNotFound","type":"error"},{"inputs":[{"internalType":"address","name":"_daoBeacon","type":"address"}],"name":"DaoBeaconAlreadyInitialized","type":"error"},{"inputs":[{"internalType":"address","name":"_contract","type":"address"}],"name":"InvalidContract","type":"error"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"PriceGatewayAlreadyInitialized","type":"error"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"PriceGatewayNotFound","type":"error"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"budgetApproval","type":"address"}],"name":"AbandonBudgetApproval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"priceGateway","type":"address"}],"name":"AbandonPriceGateway","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"dao","type":"address"},{"indexed":false,"internalType":"address","name":"creator","type":"address"},{"indexed":false,"internalType":"address","name":"referer","type":"address"}],"name":"CreateDao","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_daoBeacon","type":"address"},{"indexed":true,"internalType":"uint256","name":"_index","type":"uint256"},{"indexed":false,"internalType":"string","name":"_name","type":"string"}],"name":"SetDaoBeacon","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"budgetApproval","type":"address"}],"name":"WhitelistBudgetApproval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"priceGateway","type":"address"}],"name":"WhitelistPriceGateway","type":"event"},{"inputs":[{"internalType":"address[]","name":"_budgetApprovals","type":"address[]"}],"name":"abandonBudgetApprovals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_priceGateways","type":"address[]"}],"name":"abandonPriceGateways","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"budgetApprovals","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_description","type":"string"},{"internalType":"address","name":"_baseCurrency","type":"address"},{"internalType":"bytes[]","name":"_data","type":"bytes[]"},{"internalType":"address","name":"_referer","type":"address"}],"name":"createDao","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"daoBeacon","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"daoBeaconIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"daos","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_daoBeacon","type":"address"},{"internalType":"address[]","name":"_budgetApprovalImplementations","type":"address[]"},{"internalType":"address[]","name":"_priceGatewayImplementations","type":"address[]"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"priceGateways","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proxiableUUID","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_daoBeacon","type":"address"}],"name":"setDaoBeacon","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_budgetApprovals","type":"address[]"}],"name":"whitelistBudgetApprovals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_priceGateways","type":"address[]"}],"name":"whitelistPriceGateways","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

interface IBudgetApprovalExecutee {
    function executeByBudgetApproval(address, bytes memory, uint256) external returns (bytes memory);
    function createBudgetApprovals(address[] calldata, bytes[] calldata) external;
    function team() external view returns (address);
    function accountingSystem() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity 0.8.7;

interface IDao {
    error BudgetApprovalTemplateNotWhitelisted(address template);
    error ContractCallFail(bytes result);
    error GovernAlreadyExists(string gName);
    error InputLengthNotMatch(uint256 count1, uint256 count2);
    error InsufficientDeposit();
    error InvalidAddress(address addr);
    error InvalidContract(address _contract);
    error PluginAlreadyExists(bytes32 contractName);
    error PluginNotAllowed(bytes32 contractName);
    error PluginRequired(bytes32 contractName);
    error Unauthorized();
    error UnsupportedDowngrade();
    event AddAdmissionToken(
        address token,
        uint256 minTokenToAdmit,
        uint256 tokenId,
        bool isMemberToken
    );
    event AllowDepositToken(address token);
    event CreateBudgetApproval(address budgetApproval, bytes data);
    event CreateGovern(string name, address govern, address voteToken);
    event CreateMember(address account, uint256 depositAmount);
    event CreateMemberToken(address token);
    event CreatePlugin(bytes32 contractName, address plugin);
    event Deposit(address account, uint256 amount);
    event ExecuteByBudgetApproval(address budgetApproval, bytes data);
    event Initialized(uint8 version);
    event RemoveAdmissionToken(address token);
    event RevokeBudgetApproval(address budgetApproval);
    event SetFirstDepositTime(address owner, uint256 time);
    event UpdateDescription(string description);
    event UpdateLocktime(uint256 locktime);
    event UpdateLogoCID(string logoCID);
    event UpdateMinDepositAmount(uint256 amount);
    event UpdateName(string newName);
    event UpgradeDaoBeacon(address daoBeacon);
    event WhitelistTeam(uint256 tokenId);

    function accountingSystem() external view returns (address);

    function adam() external view returns (address);

    function addAssets(address[] memory erc20s) external;

    function afterDeposit(address account, uint256 amount) external;

    function baseCurrency() external view returns (address);

    function budgetApprovals(address template) external view returns (bool);

    function byPassGovern(address account) external view returns (bool);

    function canAddPriceGateway(address priceGateway)
        external
        view
        returns (bool);

    function canCreateBudgetApproval(address budgetApproval)
        external
        view
        returns (bool);

    function createBudgetApprovals(
        address[] memory __budgetApprovals,
        bytes[] memory data
    ) external;

    function createGovern(
        string memory _name,
        uint256 quorum,
        uint256 passThreshold,
        uint8 voteType,
        address externalVoteToken,
        uint256 durationInBlock
    ) external;

    function createPlugin(bytes32 contractName, bytes memory data)
        external
        returns (address);

    function creator() external view returns (address);

    function description() external view returns (string memory);

    function executeByBudgetApproval(
        address _to,
        bytes memory _data,
        uint256 _value
    ) external returns (bytes memory);

    function executePlugin(
        bytes32 contractName,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory);

    function firstDepositTime(address) external view returns (uint256);

    function govern(string memory) external view returns (address);

    function initialize(
        address _creator,
        string memory _name,
        string memory _description,
        address _baseCurrency,
        bytes[] memory _data
    ) external;

    function isAssetSupported(address) external view returns (bool);

    function isPlugin(address) external view returns (bool);

    function liquidPool() external view returns (address);

    function locktime() external view returns (uint256);

    function logoCID() external view returns (string memory);

    function memberToken() external view returns (address);

    function membership() external view returns (address);

    function minDepositAmount() external view returns (uint256);

    function multicall(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) external returns (bytes[] memory);

    function name() external view returns (string memory);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function plugins(bytes32) external view returns (address);

    function revokeBudgetApprovals(address[] memory __budgetApprovals) external;

    function setDescription(string memory _description) external;

    function setFirstDepositTime(address owner, uint256 timestamp) external;

    function setLocktime(uint256 _locktime) external;

    function setLogoCID(string memory _logoCID) external;

    function setMinDepositAmount(uint256 _minDepositAmount) external;

    function setName(string memory _name) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function team() external view returns (address);

    function upgradeTo(address _daoBeacon) external;

    receive() external payable;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"template","type":"address"}],"name":"BudgetApprovalTemplateNotWhitelisted","type":"error"},{"inputs":[{"internalType":"bytes","name":"result","type":"bytes"}],"name":"ContractCallFail","type":"error"},{"inputs":[{"internalType":"string","name":"gName","type":"string"}],"name":"GovernAlreadyExists","type":"error"},{"inputs":[{"internalType":"uint256","name":"count1","type":"uint256"},{"internalType":"uint256","name":"count2","type":"uint256"}],"name":"InputLengthNotMatch","type":"error"},{"inputs":[],"name":"InsufficientDeposit","type":"error"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"InvalidAddress","type":"error"},{"inputs":[{"internalType":"address","name":"_contract","type":"address"}],"name":"InvalidContract","type":"error"},{"inputs":[{"internalType":"bytes32","name":"contractName","type":"bytes32"}],"name":"PluginAlreadyExists","type":"error"},{"inputs":[{"internalType":"bytes32","name":"contractName","type":"bytes32"}],"name":"PluginNotAllowed","type":"error"},{"inputs":[{"internalType":"bytes32","name":"contractName","type":"bytes32"}],"name":"PluginRequired","type":"error"},{"inputs":[],"name":"Unauthorized","type":"error"},{"inputs":[],"name":"UnsupportedDowngrade","type":"error"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"minTokenToAdmit","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"bool","name":"isMemberToken","type":"bool"}],"name":"AddAdmissionToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"}],"name":"AllowDepositToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"budgetApproval","type":"address"},{"indexed":false,"internalType":"bytes","name":"data","type":"bytes"}],"name":"CreateBudgetApproval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"address","name":"govern","type":"address"},{"indexed":false,"internalType":"address","name":"voteToken","type":"address"}],"name":"CreateGovern","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"depositAmount","type":"uint256"}],"name":"CreateMember","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"}],"name":"CreateMemberToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"contractName","type":"bytes32"},{"indexed":false,"internalType":"address","name":"plugin","type":"address"}],"name":"CreatePlugin","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"budgetApproval","type":"address"},{"indexed":false,"internalType":"bytes","name":"data","type":"bytes"}],"name":"ExecuteByBudgetApproval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"}],"name":"RemoveAdmissionToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"budgetApproval","type":"address"}],"name":"RevokeBudgetApproval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"}],"name":"SetFirstDepositTime","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"description","type":"string"}],"name":"UpdateDescription","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"locktime","type":"uint256"}],"name":"UpdateLocktime","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"logoCID","type":"string"}],"name":"UpdateLogoCID","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"UpdateMinDepositAmount","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"newName","type":"string"}],"name":"UpdateName","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"daoBeacon","type":"address"}],"name":"UpgradeDaoBeacon","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"WhitelistTeam","type":"event"},{"inputs":[],"name":"accountingSystem","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"adam","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"erc20s","type":"address[]"}],"name":"addAssets","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"afterDeposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"baseCurrency","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"template","type":"address"}],"name":"budgetApprovals","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"byPassGovern","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"priceGateway","type":"address"}],"name":"canAddPriceGateway","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"budgetApproval","type":"address"}],"name":"canCreateBudgetApproval","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"__budgetApprovals","type":"address[]"},{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"createBudgetApprovals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"uint256","name":"quorum","type":"uint256"},{"internalType":"uint256","name":"passThreshold","type":"uint256"},{"internalType":"enum Dao.VoteType","name":"voteType","type":"uint8"},{"internalType":"address","name":"externalVoteToken","type":"address"},{"internalType":"uint256","name":"durationInBlock","type":"uint256"}],"name":"createGovern","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"contractName","type":"bytes32"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"createPlugin","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"creator","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"description","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"},{"internalType":"uint256","name":"_value","type":"uint256"}],"name":"executeByBudgetApproval","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"contractName","type":"bytes32"},{"internalType":"bytes","name":"data","type":"bytes"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"executePlugin","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"firstDepositTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"","type":"string"}],"name":"govern","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_creator","type":"address"},{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_description","type":"string"},{"internalType":"address","name":"_baseCurrency","type":"address"},{"internalType":"bytes[]","name":"_data","type":"bytes[]"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"isAssetSupported","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"isPlugin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"liquidPool","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"locktime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"logoCID","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"memberToken","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"membership","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minDepositAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"targets","type":"address[]"},{"internalType":"uint256[]","name":"values","type":"uint256[]"},{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"","type":"bytes[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256[]","name":"","type":"uint256[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC1155BatchReceived","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC1155Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"plugins","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"__budgetApprovals","type":"address[]"}],"name":"revokeBudgetApprovals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_description","type":"string"}],"name":"setDescription","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"setFirstDepositTime","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_locktime","type":"uint256"}],"name":"setLocktime","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_logoCID","type":"string"}],"name":"setLogoCID","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minDepositAmount","type":"uint256"}],"name":"setMinDepositAmount","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_name","type":"string"}],"name":"setName","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"team","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_daoBeacon","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
*/

// SPDX-License-Identifier: GPL-3.0
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity 0.8.7;

interface ITeam {
    error InvalidAddress(address addr);
    error MemberExists(uint256 tokenId, address member);
    error MemberNotFound(uint256 tokenId, address member);
    error TransferNotAllowed();
    error Unauthorized();
    event AddMembers(uint256 tokenId, address[] members);
    event AddTeam(
        uint256 tokenId,
        address minter,
        string name,
        string description
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event EditInfo(string name, string description, uint256 tokenId);
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RemoveMembers(uint256 tokenId, address[] members);
    event SetMinter(uint256 tokenId, address minter);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event URI(string value, uint256 indexed id);

    function addMembers(address[] memory members, uint256 tokenId) external;

    function addTeam(
        string memory name,
        address minter,
        address[] memory members,
        string memory description
    ) external returns (uint256);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function descriptionOf(uint256) external view returns (string memory);

    function initialize() external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function minterOf(uint256) external view returns (address);

    function nameOf(uint256) external view returns (string memory);

    function owner() external view returns (address);

    function removeMembers(address[] memory members, uint256 tokenId) external;

    function renounceOwnership() external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setInfo(
        string memory name,
        string memory description,
        uint256 tokenId
    ) external;

    function setMinter(address minter, uint256 tokenId) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function transferOwnership(address newOwner) external;

    function uri(uint256 _id) external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"addr","type":"address"}],"name":"InvalidAddress","type":"error"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"address","name":"member","type":"address"}],"name":"MemberExists","type":"error"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"address","name":"member","type":"address"}],"name":"MemberNotFound","type":"error"},{"inputs":[],"name":"TransferNotAllowed","type":"error"},{"inputs":[],"name":"Unauthorized","type":"error"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"address[]","name":"members","type":"address[]"}],"name":"AddMembers","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"address","name":"minter","type":"address"},{"indexed":false,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"string","name":"description","type":"string"}],"name":"AddTeam","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"string","name":"description","type":"string"},{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"EditInfo","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"address[]","name":"members","type":"address[]"}],"name":"RemoveMembers","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"address","name":"minter","type":"address"}],"name":"SetMinter","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"indexed":false,"internalType":"uint256[]","name":"values","type":"uint256[]"}],"name":"TransferBatch","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"TransferSingle","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"value","type":"string"},{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"URI","type":"event"},{"inputs":[{"internalType":"address[]","name":"members","type":"address[]"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"addMembers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"name","type":"string"},{"internalType":"address","name":"minter","type":"address"},{"internalType":"address[]","name":"members","type":"address[]"},{"internalType":"string","name":"description","type":"string"}],"name":"addTeam","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"accounts","type":"address[]"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"}],"name":"balanceOfBatch","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"descriptionOf","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"minterOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"nameOf","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"members","type":"address[]"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"removeMembers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"internalType":"uint256[]","name":"amounts","type":"uint256[]"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeBatchTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"setInfo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"setMinter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"uri","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.7;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4(bytes memory _bytes, uint256 _start) internal pure returns (bytes4) {
        require(_bytes.length >= _start + 4, "toBytes4_outOfBounds");
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

library Constant {
    bytes32 public constant BEACON_NAME_DAO = bytes32(keccak256("adam.dao"));
    bytes32 public constant BEACON_NAME_MEMBERSHIP = bytes32(keccak256("adam.dao.membership"));
    bytes32 public constant BEACON_NAME_MEMBER_TOKEN = bytes32(keccak256("adam.dao.member_token"));
    bytes32 public constant BEACON_NAME_LIQUID_POOL = bytes32(keccak256("adam.dao.liquid_pool"));
    bytes32 public constant BEACON_NAME_GOVERN = bytes32(keccak256("adam.dao.govern"));
    bytes32 public constant BEACON_NAME_TEAM = bytes32(keccak256("adam.dao.team"));
    bytes32 public constant BEACON_NAME_ACCOUNTING_SYSTEM = bytes32(keccak256("adam.dao.accounting_system"));

    address public constant UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant FEED_REGISTRY = 0xB8a7e3b6Dc0e597e3eFA8e9dfeB15865679b7Cd0;
    address public constant BRIDGE_CURRENCY = 0x0000000000000000000000000000000000000348;
    address public constant NATIVE_TOKEN = 0x0000000000000000000000000000000000001010;
    address public constant WRAP_NATIVE_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    
    uint public constant STALE_PRICE_DELAY = 86400;
}