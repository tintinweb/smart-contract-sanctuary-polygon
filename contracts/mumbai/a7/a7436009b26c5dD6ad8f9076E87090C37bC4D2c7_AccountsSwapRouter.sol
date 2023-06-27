// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {AccountStorage} from "../storage.sol";
import {RegistrarStorage} from "../../registrar/storage.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {IRegistrar} from "../../registrar/interfaces/IRegistrar.sol";
import {ReentrancyGuardFacet} from "./ReentrancyGuardFacet.sol";
import {IAccountsEvents} from "../interfaces/IAccountsEvents.sol";
import {IAccountsSwapRouter} from "../interfaces/IAccountsSwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title AccountsSwapRouter
 * @dev This contract manages the swaps for endowments
 */
contract AccountsSwapRouter is ReentrancyGuardFacet, IAccountsEvents, IAccountsSwapRouter {
  using SafeMath for uint256;

  /**
   * @notice This function swaps tokens for an endowment
   * @dev This function swaps tokens for an endowment
   * @param id The id of the endowment
   * @param accountType The type of the account
   * @param tokenIn The address of the token to be swapped
   * @param amountIn The amount of tokens to be swapped in
   * @param tokenOut The address of the token to be received out
   * @param slippage Maximum slippage tolerance allowed for output token amount (max is 100% or 10000)
   */

  function swapToken(
    uint32 id,
    AngelCoreStruct.AccountType accountType,
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 slippage
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[id];

    RegistrarStorage.Config memory registrar_config = IRegistrar(state.config.registrarContract)
      .queryConfig();

    require(
      registrar_config.uniswapRouter != address(0),
      "Uniswap Router address is not set in Registrar"
    );
    require(
      registrar_config.uniswapFactory != address(0),
      "Uniswap Factory addresses is not set in Registrar"
    );
    require(amountIn > 0, "Invalid Swap Input: Zero Amount");
    require(tokenIn != address(0) && tokenOut != address(0), "Invalid Swap Input: Zero Address");
    require(
      slippage < AngelCoreStruct.FEE_BASIS,
      "Invalid Swap Input: Token Out slippage set too high"
    );
    // Check that the desired output token from the swap is either:
    // A. In the protocol-level accepted tokens list in the Registrar Contract OR
    // B. In the endowment-level accepted tokens list
    require(
      IRegistrar(state.config.registrarContract).isTokenAccepted(tokenOut) ||
        state.AcceptedTokens[id][tokenOut],
      "Output token not in an Accepted Tokens List"
    );

    // check if the msg sender is either the owner or their delegate address and
    // that they have the power to manage the investments for an account balance
    if (accountType == AngelCoreStruct.AccountType.Locked) {
      require(
        AngelCoreStruct.canChange(
          state.ENDOWMENTS[id].settingsController.lockedInvestmentManagement,
          msg.sender,
          state.ENDOWMENTS[id].owner,
          block.timestamp
        ),
        "Unauthorized"
      );
    } else if (accountType == AngelCoreStruct.AccountType.Locked) {
      require(
        AngelCoreStruct.canChange(
          state.ENDOWMENTS[id].settingsController.liquidInvestmentManagement,
          msg.sender,
          state.ENDOWMENTS[id].owner,
          block.timestamp
        ),
        "Unauthorized"
      );
    } else {
      revert("Invalid AccountType");
    }

    if (accountType == AngelCoreStruct.AccountType.Locked) {
      require(
        state.STATES[id].balances.locked[tokenIn] >= amountIn,
        "Requested swap amount is greater than Endowment Locked balance"
      );
      state.STATES[id].balances.locked[tokenIn] -= amountIn;
    } else {
      require(
        state.STATES[id].balances.liquid[tokenIn] >= amountIn,
        "Requested swap amount is greater than Endowment Liquid balance"
      );
      state.STATES[id].balances.liquid[tokenIn] -= amountIn;
    }

    // Check that both in & out tokens have chainlink price feed contract set for them
    // this could be either at the Registrar or the Endowment level
    address priceFeedIn = IRegistrar(state.config.registrarContract).queryTokenPriceFeed(tokenIn);
    address priceFeedOut = IRegistrar(state.config.registrarContract).queryTokenPriceFeed(tokenOut);
    if (priceFeedIn == address(0)) {
      priceFeedIn = state.PriceFeeds[id][tokenIn];
    }
    if (priceFeedOut == address(0)) {
      priceFeedOut = state.PriceFeeds[id][tokenOut];
    }
    require(
      (priceFeedIn != address(0) && priceFeedOut != address(0)),
      "Chinlink Oracle Price Feed contracts are required for all tokens swapping to/from"
    );

    require(
      IERC20(tokenIn).approve(address(registrar_config.uniswapRouter), amountIn),
      "Approval failed"
    );

    // Who ya gonna call? Swap Function!
    uint256 amountOut = swap(
      tokenIn,
      amountIn,
      priceFeedIn,
      tokenOut,
      priceFeedOut,
      slippage,
      registrar_config.uniswapRouter,
      registrar_config.uniswapFactory
    );

    // Allocate the newly swapped tokens to the correct endowment balance
    if (accountType == AngelCoreStruct.AccountType.Locked) {
      state.STATES[id].balances.locked[tokenOut] += amountOut;
    } else {
      state.STATES[id].balances.liquid[tokenOut] += amountOut;
    }

    emit TokenSwapped(id, accountType, tokenIn, amountIn, tokenOut, amountOut);
  }

  /*///////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    */ ///////////////////////////////////////////////

  /**
   * @dev This function fetches the latest token price from a Price Feed from Chainlink Oracles.
   * @param tokenFeed address
   * @return answer Returns the oracle answer of current price as an int
   */
  function getLatestPriceData(address tokenFeed) internal returns (uint256) {
    AggregatorV3Interface chainlinkFeed = AggregatorV3Interface(tokenFeed);
    (
      uint80 roundID,
      int256 answer,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = chainlinkFeed.latestRoundData();
    return uint256(answer);
  }

  // /**
  //  * @dev This function sorts two token addresses in ascending order and returns them.
  //  * @param tokenA address
  //  * @param tokenB address
  //  */
  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV3Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV3Library: ZERO_ADDRESS");
  }

  /**
   * @dev This function swaps the given amount of tokenA for tokenB and transfers it to the specified recipient address.
   * @param tokenIn address
   * @param amountIn uint256
   * @param priceFeedIn address
   * @param tokenOut address
   * @param priceFeedOut address
   * @param slippage uint256
   * @param uniswapRouter address
   * @param uniswapFactory address
   * @return amountOut Returns the amount of token received fom pool after swapping to specific address
   */
  function swap(
    address tokenIn,
    uint256 amountIn,
    address priceFeedIn,
    address tokenOut,
    address priceFeedOut,
    uint256 slippage,
    address uniswapRouter,
    address uniswapFactory
  ) internal returns (uint256 amountOut) {
    uint256 priceRatio = getLatestPriceData(priceFeedOut).mul(AngelCoreStruct.BIG_NUMBA_BASIS).div(
      getLatestPriceData(priceFeedIn)
    );
    uint256 estAmountOut = amountIn.mul(priceRatio).div(AngelCoreStruct.BIG_NUMBA_BASIS);
    uint256 minAmountOut = estAmountOut.sub(
      estAmountOut.mul(slippage).div(AngelCoreStruct.FEE_BASIS)
    );

    // find the lowest fee pool available, if any, to swap tokens
    IUniswapV3Factory factory = IUniswapV3Factory(uniswapFactory);
    uint24 poolFee;
    // UniSwap V3 Pools support fees of 0.05%(500 bps), 0.3%(3000 bps), or 1%(10000 bps)
    // 3000 is the default tier today, so we start with that to hopefully save some gas
    if (factory.getPool(tokenIn, tokenOut, 3000) != address(0)) {
      poolFee = 3000;
    } else if (factory.getPool(tokenIn, tokenOut, 500) != address(0)) {
      poolFee = 500;
    } else if (factory.getPool(tokenIn, tokenOut, 10000) != address(0)) {
      poolFee = 10000;
    }
    require(poolFee > 0, "No pool found to swap");

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      fee: poolFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut,
      sqrtPriceLimitX96: 0 // ensures that we swap our exact input amount
    });
    // execute the swap on the router
    amountOut = ISwapRouter(uniswapRouter).exactInputSingle(params);

    require(amountOut >= minAmountOut, "Output funds less than the minimum output");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (SEity/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {AccountStorage} from "../storage.sol";

/**
 * @title ReentrancyGuardFacet
 * @notice This contract facet prevents reentrancy attacks
 * @dev Uses a global mutex and prevents reentrancy.
 */
abstract contract ReentrancyGuardFacet {
  // bool private constant _NOT_ENTERED = false;
  // bool private constant _ENTERED = true;

  // Allows rentrant calls from self
  modifier nonReentrant() {
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  /**
   * @notice Prevents a contract from calling itself, directly or indirectly.
   * @dev To be called when entering a function that uses nonReentrant.
   */
  function _nonReentrantBefore() private {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    require(
      !state.config.reentrancyGuardLocked || (address(this) == msg.sender),
      "ReentrancyGuard: reentrant call"
    );

    // Any calls to nonReentrant after this point will fail
    if (address(this) != msg.sender) {
      state.config.reentrancyGuardLocked = true;
    }
  }

  /**
   * @notice Prevents a contract from calling itself, directly or indirectly.
   * @dev To be called when exiting a function that uses nonReentrant.
   */
  function _nonReentrantAfter() private {
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    AccountStorage.State storage state = LibAccounts.diamondStorage();

    if (address(this) != msg.sender) {
      state.config.reentrancyGuardLocked = false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../../struct.sol";

interface IAccountsEvents {
  event DaoContractCreated(uint32 endowId, address daoAddress);
  event DonationDeposited(uint256 endowId, address tokenAddress, uint256 amount);
  event DonationWithdrawn(uint256 endowId, address recipient, address tokenAddress, uint256 amount);
  event AllowanceRemoved(address sender, address spender, address tokenAddress);
  event AllowanceUpdated(address sender, address spender, address tokenAddress, uint256 allowance);
  event EndowmentCreated(uint256 endowId);
  event EndowmentUpdated(uint256 endowId);
  event ConfigUpdated();
  event OwnerUpdated(address owner);
  event DonationMatchCreated(uint256 endowId, address donationMatchContract);
  event TokenSwapped(
    uint256 endowId,
    AngelCoreStruct.AccountType accountType,
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOut
  );
  event EndowmentSettingUpdated(uint256 endowId, string setting);
  // event EndowmentStateUpdated(uint256 endowId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../../struct.sol";

interface IAccountsSwapRouter {
  function swapToken(
    uint32 id,
    AngelCoreStruct.AccountType accountType,
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 slippage
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountStorage} from "../storage.sol";

library LibAccounts {
  bytes32 constant AP_ACCOUNTS_DIAMOND_STORAGE_POSITION = keccak256("accounts.diamond.storage");

  function diamondStorage() internal pure returns (AccountStorage.State storage ds) {
    bytes32 position = AP_ACCOUNTS_DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";

library AccountStorage {
  struct Config {
    address owner;
    string version;
    address registrarContract;
    uint32 nextAccountId;
    uint256 maxGeneralCategoryId;
    address subDao;
    address gateway;
    address gasReceiver;
    bool reentrancyGuardLocked;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
  }

  struct Endowment {
    address owner;
    string name; // name of the Endowment
    uint256[] sdgs;
    AngelCoreStruct.Tier tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
    AngelCoreStruct.EndowmentType endowType;
    string logo;
    string image;
    uint256 maturityTime; // datetime int of endowment maturity
    LocalRegistrarLib.RebalanceParams rebalance; // parameters to guide rebalancing & harvesting of gains from locked/liquid accounts
    uint256 pendingRedemptions; // number of vault redemptions rently pending for this endowment
    uint256 proposalLink; // link back the Applications Team Multisig Proposal that created an endowment (if a Charity)
    address multisig;
    address dao;
    address daoToken;
    bool donationMatchActive;
    address donationMatchContract;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    address[] maturityAllowlist;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
    AngelCoreStruct.FeeSetting withdrawFee;
    AngelCoreStruct.FeeSetting depositFee;
    AngelCoreStruct.FeeSetting balanceFee;
    AngelCoreStruct.SettingsController settingsController;
    uint32 parent;
    bool ignoreUserSplits;
    AngelCoreStruct.SplitDetails splitToLiquid;
    uint256 referralId;
  }

  struct EndowmentState {
    AngelCoreStruct.BalanceInfo balances;
    bool closingEndowment;
    AngelCoreStruct.Beneficiary closingBeneficiary;
    mapping(bytes4 => bool) activeStrategies;
  }

  struct State {
    mapping(uint32 => uint256) DAOTOKENBALANCE;
    mapping(uint32 => EndowmentState) STATES;
    mapping(uint32 => Endowment) ENDOWMENTS;
    // endow ID -> spender Addr -> token Addr -> amount
    mapping(uint32 => mapping(address => mapping(address => uint256))) ALLOWANCES;
    // endow ID -> token Addr -> bool
    mapping(uint32 => mapping(address => bool)) AcceptedTokens;
    // endow ID -> token Addr -> Price Feed Addr
    mapping(uint32 => mapping(address => address)) PriceFeeds;
    Config config;
  }
}

contract Storage {
  AccountStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {LocalRegistrarLib} from "../lib/LocalRegistrarLib.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface ILocalRegistrar {
  /*////////////////////////////////////////////////
                        EVENTS
    */ ////////////////////////////////////////////////
  event RebalanceParamsUpdated();
  event AngelProtocolParamsUpdated();
  event AccountsContractStorageUpdated(string _chainName, string _accountsContractAddress);
  event TokenAcceptanceUpdated(address _tokenAddr, bool _isAccepted);
  event StrategyApprovalUpdated(
    bytes4 _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event StrategyParamsUpdated(
    bytes4 _strategyId,
    address _lockAddr,
    address _liqAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event GasFeeUpdated(address _tokenAddr, uint256 _gasFee);
  event FeeSettingsUpdated(
    AngelCoreStruct.FeeTypes _feeType,
    uint256 _bpsRate,
    address _payoutAddress
  );

  /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */ ////////////////////////////////////////////////

  // View methods for returning stored params
  function getRebalanceParams() external view returns (LocalRegistrarLib.RebalanceParams memory);

  function getAngelProtocolParams()
    external
    view
    returns (LocalRegistrarLib.AngelProtocolParams memory);

  function getAccountsContractAddressByChain(
    string calldata _targetChain
  ) external view returns (string memory);

  function getStrategyParamsById(
    bytes4 _strategyId
  ) external view returns (LocalRegistrarLib.StrategyParams memory);

  function isTokenAccepted(address _tokenAddr) external view returns (bool);

  function getGasByToken(address _tokenAddr) external view returns (uint256);

  function getStrategyApprovalState(
    bytes4 _strategyId
  ) external view returns (LocalRegistrarLib.StrategyApprovalState);

  function getFeeSettingsByFeeType(
    AngelCoreStruct.FeeTypes _feeType
  ) external view returns (AngelCoreStruct.FeeSetting memory);

  function getVaultOperatorApproved(address _operator) external view returns (bool);

  // Setter methods for granular changes to specific params
  function setRebalanceParams(LocalRegistrarLib.RebalanceParams calldata _rebalanceParams) external;

  function setAngelProtocolParams(
    LocalRegistrarLib.AngelProtocolParams calldata _angelProtocolParams
  ) external;

  function setAccountsContractAddressByChain(
    string memory _chainName,
    string memory _accountsContractAddress
  ) external;

  /// @notice Change whether a strategy is approved
  /// @dev Set the approval bool for a specified strategyId.
  /// @param _strategyId a uid for each strategy set by:
  /// bytes4(keccak256("StrategyName"))
  function setStrategyApprovalState(
    bytes4 _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  ) external;

  /// @notice Change which pair of vault addresses a strategy points to
  /// @dev Set the approval bool and both locked/liq vault addrs for a specified strategyId.
  /// @param _strategyId a uid for each strategy set by:
  /// bytes4(keccak256("StrategyName"))
  /// @param _liqAddr address to a comptaible Liquid type Vault
  /// @param _lockAddr address to a compatible Locked type Vault
  function setStrategyParams(
    bytes4 _strategyId,
    address _liqAddr,
    address _lockAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  ) external;

  function setTokenAccepted(address _tokenAddr, bool _isAccepted) external;

  function setGasByToken(address _tokenAddr, uint256 _gasFee) external;

  function setFeeSettingsByFeesType(
    AngelCoreStruct.FeeTypes _feeType,
    uint256 _rate,
    address _payout
  ) external;

  function setVaultOperatorApproved(address _operator, bool _isApproved) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {ILocalRegistrar} from "./ILocalRegistrar.sol";

interface IRegistrar is ILocalRegistrar {
  function updateConfig(RegistrarMessages.UpdateConfigRequest memory details) external;

  function updateOwner(address newOwner) external;

  function updateTokenPriceFeed(address token, address priceFeed) external;

  function vaultAdd(RegistrarMessages.VaultAddRequest memory details) external;

  function vaultRemove(string memory _stratagyName) external;

  function vaultUpdate(
    string memory _stratagyName,
    bool approved,
    AngelCoreStruct.EndowmentType[] memory restrictedfrom
  ) external;

  function updateNetworkConnections(
    AngelCoreStruct.NetworkInfo memory networkInfo,
    string memory action
  ) external;

  // Query functions for contract

  function queryConfig() external view returns (RegistrarStorage.Config memory);

  function queryTokenPriceFeed(address token) external view returns (address);

  function queryAllStrategies() external view returns (bytes4[] memory allStrategies);

  function queryNetworkConnection(
    uint256 chainId
  ) external view returns (AngelCoreStruct.NetworkInfo memory response);

  function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IVault} from "../../vault/interfaces/IVault.sol";
import {AngelCoreStruct} from "../../struct.sol";

library LocalRegistrarLib {
  /*////////////////////////////////////////////////
                      DEPLOYMENT DEFAULTS
  */ ////////////////////////////////////////////////
  bool constant REBALANCE_LIQUID_PROFITS = false;
  uint32 constant LOCKED_REBALANCE_TO_LIQUID = 75; // 75%
  uint32 constant INTEREST_DISTRIBUTION = 20; // 20%
  bool constant LOCKED_PRINCIPLE_TO_LIQUID = false;
  uint32 constant PRINCIPLE_DISTRIBUTION = 0;
  uint32 constant BASIS = 100;

  // DEFAULT ANGEL PROTOCOL PARAMS
  address constant ROUTER_ADDRESS = address(0);
  address constant REFUND_ADDRESS = address(0);

  /*////////////////////////////////////////////////
                      CUSTOM TYPES
  */ ////////////////////////////////////////////////
  struct RebalanceParams {
    bool rebalanceLiquidProfits;
    uint32 lockedRebalanceToLiquid;
    uint32 interestDistribution;
    bool lockedPrincipleToLiquid;
    uint32 principleDistribution;
    uint32 basis;
  }

  struct AngelProtocolParams {
    address routerAddr;
    address refundAddr;
  }

  enum StrategyApprovalState {
    NOT_APPROVED,
    APPROVED,
    WITHDRAW_ONLY,
    DEPRECATED
  }

  struct StrategyParams {
    StrategyApprovalState approvalState;
    VaultParams Locked;
    VaultParams Liquid;
  }

  struct VaultParams {
    IVault.VaultType Type;
    address vaultAddr;
  }

  struct LocalRegistrarStorage {
    address uniswapRouter;
    address uniswapFactory;
    RebalanceParams rebalanceParams;
    AngelProtocolParams angelProtocolParams;
    mapping(bytes32 => string) AccountsContractByChain;
    mapping(bytes4 => StrategyParams) VaultsByStrategyId;
    mapping(address => bool) AcceptedTokens;
    mapping(address => uint256) GasFeeByToken;
    mapping(AngelCoreStruct.FeeTypes => AngelCoreStruct.FeeSetting) FeeSettingsByFeeType;
    mapping(address => bool) ApprovedVaultOperators;
  }

  /*////////////////////////////////////////////////
                        STORAGE MGMT
    */ ////////////////////////////////////////////////
  bytes32 constant LOCAL_REGISTRAR_STORAGE_POSITION = keccak256("local.registrar.storage");

  function localRegistrarStorage() internal pure returns (LocalRegistrarStorage storage lrs) {
    bytes32 position = LOCAL_REGISTRAR_STORAGE_POSITION;
    assembly {
      lrs.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
  struct InstantiateRequest {
    address treasury;
    // uint256 taxRate;
    // AngelCoreStruct.RebalanceDetails rebalance;
    AngelCoreStruct.SplitDetails splitToLiquid;
    // AngelCoreStruct.AcceptedTokens acceptedTokens;
    address router;
    address axelarGateway;
    address axelarGasRecv;
  }

  struct UpdateConfigRequest {
    address accountsContract;
    // uint256 taxRate;
    // AngelCoreStruct.RebalanceDetails rebalance;
    string[] approved_charities;
    uint256 splitMax;
    uint256 splitMin;
    uint256 splitDefault;
    uint256 collectorShare;
    // AngelCoreStruct.AcceptedTokens acceptedTokens;

    // CONTRACT ADDRESSES
    address indexFundContract;
    address govContract;
    address treasury;
    address donationMatchCharitesContract;
    address donationMatchEmitter;
    address haloToken;
    address haloTokenLpContract;
    address charitySharesContract;
    address fundraisingContract;
    address applicationsReview;
    address uniswapRouter;
    address uniswapFactory;
    address multisigFactory;
    address multisigEmitter;
    address charityProposal;
    address lockedWithdrawal;
    address proxyAdmin;
    address usdcAddress;
    address wMaticAddress;
    address subdaoGovContract;
    address subdaoTokenContract;
    address subdaoBondingTokenContract;
    address subdaoCw900Contract;
    address subdaoDistributorContract;
    address subdaoEmitter;
    address donationMatchContract;
    address cw900lvAddress;
  }

  struct VaultAddRequest {
    // chainid of network
    uint256 network;
    string stratagyName;
    address inputDenom;
    address yieldToken;
    AngelCoreStruct.EndowmentType[] restrictedFrom;
    AngelCoreStruct.AccountType acctType;
    AngelCoreStruct.VaultType vaultType;
  }

  struct UpdateFeeRequest {
    AngelCoreStruct.FeeTypes feeType;
    address payout;
    uint256 rate;
  }

  struct ConfigResponse {
    uint256 version;
    address accountsContract;
    address treasury;
    // uint256 taxRate;
    // AngelCoreStruct.RebalanceDetails rebalance;
    address indexFund;
    // AngelCoreStruct.SplitDetails splitToLiquid;
    address haloToken;
    address govContract;
    address charitySharesContract;
    uint256 endowmentMultisigContract;
    // AngelCoreStruct.AcceptedTokens acceptedTokens;
    address applicationsReview;
    address uniswapRouter;
    address uniswapFactory;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
  struct Config {
    //Application review multisig
    address applicationsReview; // Endowment application review team's multisig (set as owner to start). Owner can set and change/revoke.
    address indexFundContract;
    address accountsContract;
    address treasury;
    address subdaoGovContract; // subdao gov wasm code
    address subdaoTokenContract; // subdao gov cw20 token wasm code
    address subdaoBondingTokenContract; // subdao gov bonding ve token wasm code
    address subdaoCw900Contract; // subdao gov ve-vE contract for locked token voting
    address subdaoDistributorContract; // subdao gov fee distributor wasm code
    address subdaoEmitter;
    address donationMatchContract; // donation matching contract wasm code
    address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
    address donationMatchEmitter;
    AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
    //TODO: pending check
    address haloToken; // TerraSwap HALO token addr
    address haloTokenLpContract;
    address govContract; // AP governance contract
    uint256 collectorShare;
    address charitySharesContract;
    // AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
    //PROTOCOL LEVEL
    address fundraisingContract;
    // AngelCoreStruct.RebalanceDetails rebalance;
    address uniswapRouter;
    address uniswapFactory;
    address multisigFactory;
    address multisigEmitter;
    address charityProposal;
    address lockedWithdrawal;
    address proxyAdmin;
    address usdcAddress;
    address wMaticAddress;
    address cw900lvAddress;
  }

  struct State {
    Config config;
    bytes4[] STRATEGIES;
    mapping(AngelCoreStruct.FeeTypes => AngelCoreStruct.FeeSetting) FeeSettingsByFeeType;
    mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
    mapping(address => address) PriceFeeds;
  }
}

contract Storage {
  RegistrarStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IVault} from "../vault/interfaces/IVault.sol";

interface IRouter is IAxelarExecutable {
  /*////////////////////////////////////////////////
                        EVENTS
    */ ////////////////////////////////////////////////

  event Transfer(IVault.VaultActionData action, uint256 amount);
  event Refund(IVault.VaultActionData action, uint256 amount);
  event Deposit(IVault.VaultActionData action);
  event Redeem(IVault.VaultActionData action, uint256 amount);
  event RewardsHarvested(IVault.VaultActionData action);
  event ErrorLogged(IVault.VaultActionData action, string message);
  event ErrorBytesLogged(IVault.VaultActionData action, bytes data);

  /*////////////////////////////////////////////////
                    CUSTOM TYPES
    */ ////////////////////////////////////////////////

  function executeLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) external returns (IVault.VaultActionData memory);

  function executeWithTokenLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) external returns (IVault.VaultActionData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
  enum AccountType {
    Locked,
    Liquid
  }

  enum Tier {
    None,
    Level1,
    Level2,
    Level3
  }

  enum EndowmentType {
    Charity,
    Normal
  }

  enum AllowanceAction {
    Add,
    Remove
  }

  struct TokenInfo {
    address addr;
    uint256 amnt;
  }

  struct BalanceInfo {
    mapping(address => uint256) locked;
    mapping(address => uint256) liquid;
  }

  struct IndexFund {
    uint256 id;
    string name;
    string description;
    uint32[] members;
    //Fund Specific: over-riding SC level setting to handle a fixed split value
    // Defines the % to split off into liquid account, and if defined overrides all other splits
    uint256 splitToLiquid;
    // Used for one-off funds that have an end date (ex. disaster recovery funds)
    uint256 expiryTime; // datetime int of index fund expiry
  }

  ///TODO: need to test this same names already declared in other libraries
  struct BeneficiaryData {
    uint32 endowId;
    uint256 fundId;
    address addr;
  }

  enum BeneficiaryEnum {
    EndowmentId,
    IndexFund,
    Wallet,
    None
  }

  struct Beneficiary {
    BeneficiaryData data;
    BeneficiaryEnum enumData;
  }

  struct SplitDetails {
    uint256 max;
    uint256 min;
    uint256 defaultSplit; // for when a user splits are not used
  }

  function checkSplits(
    SplitDetails memory splits,
    uint256 userLocked,
    uint256 userLiquid,
    bool userOverride
  ) public pure returns (uint256, uint256) {
    // check that the split provided by a user meets the endowment's
    // requirements for splits (set per Endowment)
    if (userOverride) {
      // ignore user splits and use the endowment's default split
      return (100 - splits.defaultSplit, splits.defaultSplit);
    } else if (userLiquid > splits.max) {
      // adjust upper range up within the max split threshold
      return (splits.max, 100 - splits.max);
    } else if (userLiquid < splits.min) {
      // adjust lower range up within the min split threshold
      return (100 - splits.min, splits.min);
    } else {
      // use the user entered split as is
      return (userLocked, userLiquid);
    }
  }

  struct NetworkInfo {
    string name;
    uint256 chainId;
    address router; //SHARED
    address axelarGateway;
    string ibcChannel; // Should be removed
    string transferChannel;
    address gasReceiver; // Should be removed
    uint256 gasLimit; // Should be used to set gas limit
  }

  ///TODO: need to check this and have a look at this
  enum VaultType {
    Native, // Juno native Vault contract
    Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
    Evm, // the address of the Vault contract on it's EVM chain
    None
  }

  enum veTypeEnum {
    Constant,
    Linear,
    SquarRoot
  }

  struct veTypeData {
    uint128 value;
    uint256 scale;
    uint128 slope;
    uint128 power;
  }

  struct veType {
    veTypeEnum ve_type;
    veTypeData data;
  }

  enum TokenType {
    Existing,
    New,
    VeBonding
  }

  struct DaoTokenData {
    address existingData;
    uint256 newInitialSupply;
    string newName;
    string newSymbol;
    veType veBondingType;
    string veBondingName;
    string veBondingSymbol;
    uint256 veBondingDecimals;
    address veBondingReserveDenom;
    uint256 veBondingReserveDecimals;
    uint256 veBondingPeriod;
  }

  struct DaoToken {
    TokenType token;
    DaoTokenData data;
  }

  struct DaoSetup {
    uint256 quorum; //: Decimal,
    uint256 threshold; //: Decimal,
    uint256 votingPeriod; //: u64,
    uint256 timelockPeriod; //: u64,
    uint256 expirationPeriod; //: u64,
    uint128 proposalDeposit; //: Uint128,
    uint256 snapshotPeriod; //: u64,
    DaoToken token; //: DaoToken,
  }

  struct Delegate {
    address addr;
    uint256 expires; // datetime int of delegation expiry
  }

  enum DelegateAction {
    Set,
    Revoke
  }

  function delegateIsValid(
    Delegate storage delegate,
    address sender,
    uint256 envTime
  ) public view returns (bool) {
    return (delegate.addr != address(0) &&
      sender == delegate.addr &&
      (delegate.expires == 0 || envTime <= delegate.expires));
  }

  function canChange(
    SettingsPermission storage permissions,
    address sender,
    address owner,
    uint256 envTime
  ) public view returns (bool) {
    // Can be changed if both critera are satisfied:
    // 1. permission is not locked forever (read: `locked` == true)
    // 2. sender is a valid delegate address and their powers have not expired OR
    //    sender is the endow owner (ie. owner must first revoke their delegation)
    return (!permissions.locked &&
      (delegateIsValid(permissions.delegate, sender, envTime) || sender == owner));
  }

  struct SettingsPermission {
    bool locked;
    Delegate delegate;
  }

  struct SettingsController {
    SettingsPermission acceptedTokens;
    SettingsPermission lockedInvestmentManagement;
    SettingsPermission liquidInvestmentManagement;
    SettingsPermission allowlistedBeneficiaries;
    SettingsPermission allowlistedContributors;
    SettingsPermission maturityAllowlist;
    SettingsPermission maturityTime;
    SettingsPermission earlyLockedWithdrawFee;
    SettingsPermission withdrawFee;
    SettingsPermission depositFee;
    SettingsPermission balanceFee;
    SettingsPermission name;
    SettingsPermission image;
    SettingsPermission logo;
    SettingsPermission sdgs;
    SettingsPermission splitToLiquid;
    SettingsPermission ignoreUserSplits;
  }

  enum ControllerSettingOption {
    AcceptedTokens,
    LockedInvestmentManagement,
    LiquidInvestmentManagement,
    AllowlistedBeneficiaries,
    AllowlistedContributors,
    MaturityAllowlist,
    EarlyLockedWithdrawFee,
    MaturityTime,
    WithdrawFee,
    DepositFee,
    BalanceFee,
    Name,
    Image,
    Logo,
    Sdgs,
    SplitToLiquid,
    IgnoreUserSplits
  }

  enum FeeTypes {
    Default,
    Harvest,
    WithdrawCharity,
    WithdrawNormal,
    EarlyLockedWithdrawCharity,
    EarlyLockedWithdrawNormal
  }

  struct FeeSetting {
    address payoutAddress;
    uint256 bps;
  }

  function validateFee(FeeSetting memory fee) public pure {
    if (fee.bps > 0 && fee.payoutAddress == address(0)) {
      revert("Invalid fee payout zero address given");
    } else if (fee.bps > FEE_BASIS) {
      revert("Invalid fee basis points given. Should be between 0 and 10000.");
    }
  }

  uint256 constant FEE_BASIS = 10000; // gives 0.01% precision for fees (ie. Basis Points)
  uint256 constant PERCENT_BASIS = 100; // gives 1% precision for declared percentages
  uint256 constant BIG_NUMBA_BASIS = 1e24;

  // Interface IDs
  bytes4 constant InterfaceId_Invalid = 0xffffffff;
  bytes4 constant InterfaceId_ERC165 = 0x01ffc9a7;
  bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import "../../../core/router/IRouter.sol";

abstract contract IVault {
  /*////////////////////////////////////////////////
                    CUSTOM TYPES
  */ ////////////////////////////////////////////////
  uint256 constant PRECISION = 10 ** 24;

  /// @notice Angel Protocol Vault Type
  /// @dev Vaults have different behavior depending on type. Specifically access to redemptions and
  /// principle balance
  enum VaultType {
    LOCKED,
    LIQUID
  }

  struct VaultConfig {
    VaultType vaultType;
    bytes4 strategySelector;
    address strategy;
    address registrar;
    address baseToken;
    address yieldToken;
    string apTokenName;
    string apTokenSymbol;
    address admin;
  }

  /// @notice Gerneric AP Vault action data
  /// @param destinationChain The Axelar string name of the blockchain that will receive redemptions/refunds
  /// @param strategyId The 4 byte truncated keccak256 hash of the strategy name, i.e. bytes4(keccak256("Goldfinch"))
  /// @param selector The Vault method that should be called
  /// @param accountId The endowment uid
  /// @param token The token (if any) that was forwarded along with the calldata packet by GMP
  /// @param lockAmt The amount of said token that is intended to interact with the locked vault
  /// @param liqAmt The amount of said token that is intended to interact with the liquid vault
  struct VaultActionData {
    string destinationChain;
    bytes4 strategyId;
    bytes4 selector;
    uint32[] accountIds;
    address token;
    uint256 lockAmt;
    uint256 liqAmt;
    VaultActionStatus status;
  }

  /// @notice Structure for storing account principle information necessary for yield calculations
  /// @param baseToken The qty of base tokens deposited into the vault
  /// @param costBasis_withPrecision The cost per share for entry into the vault (baseToken / share)
  struct Principle {
    uint256 baseToken;
    uint256 costBasis_withPrecision;
  }

  enum VaultActionStatus {
    UNPROCESSED, // INIT state
    SUCCESS, // Ack
    POSITION_EXITED, // Position fully exited
    FAIL_TOKENS_RETURNED, // Tokens returned to accounts contract
    FAIL_TOKENS_FALLBACK // Tokens failed to be returned to accounts contract
  }

  struct RedemptionResponse {
    uint256 amount;
    VaultActionStatus status;
  }

  /*////////////////////////////////////////////////
                        EVENTS
  */ ////////////////////////////////////////////////

  /// @notice Event emited on each Deposit call
  /// @dev Upon deposit, emit this event. Index the account and staking contract for analytics
  event Deposit(
    uint32 accountId,
    VaultType vaultType,
    address tokenDeposited,
    uint256 amtDeposited
  );

  /// @notice Event emited on each Redemption call
  /// @dev Upon redemption, emit this event. Index the account and staking contract for analytics
  event Redeem(uint32 accountId, VaultType vaultType, address tokenRedeemed, uint256 amtRedeemed);

  /// @notice Event emited on each Harvest call
  /// @dev Upon harvest, emit this event. Index the accounts harvested for.
  /// Rewards that are re-staked or otherwise reinvested will call other methods which will emit events
  /// with specific yield/value details
  /// @param accountIds a list of the Accounts harvested for
  event RewardsHarvested(uint32[] accountIds);

  /*////////////////////////////////////////////////
                        ERRORS
  */ ////////////////////////////////////////////////
  error OnlyAdmin();
  error OnlyRouter();
  error OnlyApproved();
  error OnlyBaseToken();
  error OnlyNotPaused();
  error ApproveFailed();
  error TransferFailed();

  /*////////////////////////////////////////////////
                    EXTERNAL METHODS
  */ ////////////////////////////////////////////////

  /// @notice returns the vault config
  function getVaultConfig() external view virtual returns (VaultConfig memory);

  /// @notice set the vault config
  function setVaultConfig(VaultConfig memory _newConfig) external virtual;

  /// @notice deposit tokens into vault position of specified Account
  /// @dev the deposit method allows the Vault contract to create or add to an existing
  /// position for the specified Account. In the case that multiple different tokens can be deposited,
  /// the method requires the deposit token address and amount. The transfer of tokens to the Vault
  /// contract must occur before the deposit method is called.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @param token the deposited token
  /// @param amt the amount of the deposited token
  function deposit(uint32 accountId, address token, uint256 amt) external payable virtual;

  /// @notice redeem value from the vault contract
  /// @dev allows an Account to redeem from its staked value. The behavior is different dependent on VaultType.
  /// Before returning the redemption amt, the vault must approve the Router to spend the tokens.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @param amt the amount of shares to redeem
  /// @return RedemptionResponse returns the number of base tokens redeemed by the call and the status
  function redeem(
    uint32 accountId,
    uint256 amt
  ) external payable virtual returns (RedemptionResponse memory);

  /// @notice redeem all of the value from the vault contract
  /// @dev allows an Account to redeem all of its staked value. Good for rebasing tokens wherein the value isn't
  /// known explicitly. Before returning the redemption amt, the vault must approve the Router to spend the tokens.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @return RedemptionResponse returns the number of base tokens redeemed by the call and the status
  function redeemAll(uint32 accountId) external payable virtual returns (RedemptionResponse memory);

  /// @notice restricted method for harvesting accrued rewards
  /// @dev Claim reward tokens accumulated to the staked value. The underlying behavior will vary depending
  /// on the target yield strategy and VaultType. Only callable by an Angel Protocol Keeper
  /// @param accountIds Used to specify which accounts to call harvest against. Structured so that this can
  /// be called in batches to avoid running out of gas.
  function harvest(uint32[] calldata accountIds) external virtual;

  /*////////////////////////////////////////////////
                INTERNAL HELPER METHODS
    */ ////////////////////////////////////////////////

  /// @notice internal method for validating that calls came from the approved AP router
  /// @dev The registrar will hold a record of the approved Router address. This method must implement a method of
  /// checking that the msg.sender == ApprovedRouter
  function _isApprovedRouter() internal view virtual returns (bool);

  /// @notice internal method for checking whether the caller is the paired locked/liquid vault
  /// @dev can be used for more gas efficient rebalancing between the two sibling vaults
  function _isSiblingVault() internal view virtual returns (bool);
}