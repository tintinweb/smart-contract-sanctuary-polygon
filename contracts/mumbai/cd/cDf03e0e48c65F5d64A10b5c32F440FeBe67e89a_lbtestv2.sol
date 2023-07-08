// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/* <Luckblocks - Decentralized Raffle Lotteries on Blockchain.>
    Copyright (C) 2023  t.me/WaLsh_P (kristim.org)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    see <https://www.gnu.org/licenses/>. */
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import './utils/Address.sol';

// 
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

    function decimals() external view returns (uint8);
    
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
    using SafeMath for int;

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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IluckblocksNodes {
    function updateNodeInfo(address caller, uint256 reward, uint weekly,uint lottery) external returns (bool);
    function getUserActivation(address _caller, uint weekly) external returns (bool);
    function activateNodes(address caller, uint8[] calldata _nodes , uint lottery,uint weekly) external;
    function resetQueue(uint lottery, uint weekly) external;
}

interface IluckblocksWeekly {
    function requestCounter() external view returns (uint256);
    function getUserTicketsByDraw(uint256 drawId, address user) external view returns (uint16[] memory);
    function registerTickets(uint256 quantity,address player) external;
    function ForfeitTicket(address user) external;
}

contract lbtestv2 is VRFV2WrapperConsumerBase,ConfirmedOwner,ReentrancyGuard {
	using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public contractBalance;
    uint256 public nftnodeBalance;

    AggregatorV3Interface internal priceFeed;
     
    IluckblocksNodes internal lbNodes;
    IluckblocksWeekly internal lottoWeekly;

	// WBTC 	// USDC 
    IUniswapV2Router02 public uniswapRouter;
    
    uint8 stableDecimals = 6;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    // toggle to reset queue
    bool reset;

    // VRF configs
    uint32 callbackGasLimit = 2400000;
    uint16 requestConfirmations = 20;
    uint32 numWords = 1;
    uint256 fee = 0.0005 * 10**18;

    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address wrapperAddress = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;
    address vrfcoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

	IERC20 usd = IERC20(0xc7A852A78dbaD037EaEa62C04b3216a2f1491cD5); // USDC
	IERC20 btc = IERC20(0xdA10cE16a1B8ee92508555C8cF4F3936dc7776C2); // BTC
    IERC20 krstm = IERC20(0x210e3410db1EDfD7025e95b244357C5849e30844); // KRSTM

    address usdTrading = 0xc7A852A78dbaD037EaEa62C04b3216a2f1491cD5;
    address btcTrading = 0xdA10cE16a1B8ee92508555C8cF4F3936dc7776C2;

    address platformAddress = 0x580a13BDdF2F29963C8E544D894569E4cA8f8FEe;
    address stakingContract = 0x20Bf53C6292F2D44B94FF7D052737ba354bD4dEc;

    address weeklyContract;

    uint256 minimumPot = 20 * 10**18;

    uint256 minimumPrize;
    uint16 incrementTicketIds = 0;
    uint16 ticketLimit = 100;

    mapping(uint256 => uint256) public requestNumberIndexToRequestId;
    mapping(uint256 => uint256) public requestIdToRequestNumberIndex;
    mapping(uint256 => uint256) public requestNumberIndexToRandomNumber;
    uint256 public requestCounter;

    mapping (uint => Ticket) public jackpotWinHistory;
    mapping (uint => uint) public numberOfPlayers;

    uint256 internal TICKET_VAL = 1 * 10**stableDecimals; //minimum amount (in wei) for getting registered on list
    uint256 internal KrstmPremium = 5 * 10**18; // Amount in KRSTM for discount

    uint256 prizeValueJackpot = 0; // 47.5% of ticket bought - added every new buy - filled by prizeValue
   

    uint256 lastAutoSpin = block.timestamp;
    uint8 public houseTickets = 20;


	uint16 internal raffle; //number which picks the winner from registered List

    address internal lastWinner;

    struct Ticket {
        uint drawId;
        uint16 id;
        address owner;
        bool winner;
    }


    // Tickets mapping draw ID -> ticket ID -> ticket info 
    mapping (uint256 => mapping(uint256 => Ticket)) public ticketsHistory;

    // User Tickets mapping by draw - draw ID -> user address -> tickets IDs 
    mapping (uint256 => mapping(address => uint16[])) public userTickets;

    uint16[] public registeredsAccts;
   
    mapping(address => bool) internal gelatoWhitelist; //for gelato auto bets
    mapping(address => address) internal gelatoSender; //for gelato auto bets - user gelato sender
    mapping(address => uint256) internal gelatoInterval; //for gelato auto bets - interval config
    mapping(address => uint256) internal gelatoLastBet; //for gelato auto bets - last bet mapping
    mapping(address => uint256) internal gelatoMaxQT; //for gelato auto bets - max quantity tickets

	event LotteryLog(uint256 timestamp,address adrs, string message, uint256 amount);


    constructor() 
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) 
    {
	
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // (0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        
        uniswapRouter = _uniswapRouter;
        
        priceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b); // (0xc907E116054Ad103354f2D350FD2514433D57F6f); // BTC/USD Price feed
        
        lottoWeekly = IluckblocksWeekly(0x4c6b3a2a93DD713edCD4e26da4279c75846c97a8);
        weeklyContract = 0x4c6b3a2a93DD713edCD4e26da4279c75846c97a8;

        lbNodes = IluckblocksNodes(0x41AE25AaF8E1b30fc5076D82d87F1a56e48AA0Ff);

    }

    /**
     * Returns the latest price from chainlink oracle
     */
    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        return uint256(price) * 1e10;
    } 

    function getJackpotinUSD() public view returns (uint256) {
       uint256 tprice = getLatestPrice();

       uint256 result = ((prizeValueJackpot * 10**10) * tprice) / 10**18; 

       return result;

    } 


    function getJackpot() public view returns (uint256) {
 
       return prizeValueJackpot;

    } 

    function setStableAddress(address _usdAddress, uint8 _stableDecimals) public onlyOwner() {
        usd = IERC20(_usdAddress);
        usdTrading = _usdAddress;
        stableDecimals = _stableDecimals;
    }

    function setMinimumPot(uint256 _minimumPot) public onlyOwner() {
        minimumPot = _minimumPot;
    }

    function setGasLimit(uint32 _callbackGasLimit) public onlyOwner() {
        callbackGasLimit = _callbackGasLimit;
    }

    function setPlatform(address _platform) external onlyOwner() {
        platformAddress = _platform;
    }
    
    function setStaking(address _staking) external onlyOwner() {
        stakingContract = _staking;
    }
   
    function setNFTNode(address _contract) public onlyOwner() {
        lbNodes = IluckblocksNodes(_contract);
    }

    function setParentContract(address _weeklyContract) public onlyOwner() {
        lottoWeekly = IluckblocksWeekly(_weeklyContract);
        weeklyContract = _weeklyContract;
    }

    //TEST FUNCTIONs - DELETE on MAINNET
    function deleteParticipations() public onlyOwner() {
        delete registeredsAccts;
    }
    function changeTicketLimit(uint16 _ticketLimit) public onlyOwner() {
        ticketLimit = _ticketLimit;
    }
    //

    function withdrawExcessBalance () public onlyOwner() {

        btc.safeTransfer(msg.sender,contractBalance);

        contractBalance -= contractBalance;

    }

    /**
     * @notice Change the fee
     * @param _fee: new fee (in LINK)
     */
    function setFee(uint256 _fee) external onlyOwner() {
        fee = _fee;
    }

    /**
     * @notice Change coordinator
     * @param _coordinator: new coordinator     */
    function setCoordinator(address _coordinator) external onlyOwner() {
        vrfcoordinator = _coordinator;
    }

    //In case of new router version
    function changeRouter(address _routerAddress) public onlyOwner() {
        
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(_routerAddress);
        
        uniswapRouter = _uniswapRouter;

    }

    /**
     * @notice Change the priceFeed
     * @param _priceFeed: new priceFeed
     */
    function setPriceFeed(address _priceFeed) external onlyOwner() {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // Decided by KRSTM DAO
    function setKRSTMPremium(uint256 _amountNeeded) public onlyOwner() {
        KrstmPremium = _amountNeeded;
    }

    // External && Internal Minimum Prize Raise
    function fillJackpot(uint256 amount) external {
        
        uint256 tprice = getLatestPrice();

        uint256 amountInToken = (20 * 10**18 * 10**18) / tprice;  // 20 usd in token

        minimumPrize = amountInToken / 10**10;

        require(amount >= minimumPrize,"not enough amount - below 20 usd");
        require(btc.balanceOf(msg.sender) >= amount,"not enough balance");
        
        btc.safeTransferFrom(msg.sender,address(this),amount);
        contractBalance += amount;

        prizeValueJackpot += minimumPrize;
        contractBalance -= minimumPrize;

        if(registeredsAccts.length < 1){
            // Add 20 contract tickets
            for(uint index = 0; index < 20; index++){
            
                uint16 indexCheck = incrementTicketIds;

                Ticket memory ticket = Ticket(requestCounter,indexCheck,address(this),false);
                
                ticketsHistory[requestCounter][indexCheck] = ticket;

                if (userTickets[requestCounter][address(this)].length == 0) {
                    userTickets[requestCounter][address(this)] = new uint16[](0);
                }

                registeredsAccts.push(indexCheck);
                userTickets[requestCounter][address(this)].push(indexCheck);
                incrementTicketIds++;

            }
        }
               
    }

    function accumulateJackpot(uint256 amount) internal {
        
        if(amount > minimumPrize){
         
         contractBalance += amount.mul(25).div(100);
         
         prizeValueJackpot = amount.mul(60).div(100);
    
         btc.safeTransfer(weeklyContract,amount.mul(15).div(100));
         
   
        } else{
            if(contractBalance >= minimumPrize){
                prizeValueJackpot += minimumPrize;
                contractBalance -= minimumPrize;
            }
        }
               
    }

    // function to update gelato msg.sender
    function setGelatoSender(address _msgSender) public {
        gelatoSender[msg.sender] = _msgSender;
    }

    //toggle if bets from gelato can be made
    function toggleGelato() public {
        if(gelatoWhitelist[msg.sender] == false){
          gelatoWhitelist[msg.sender] = true;
        }else{
          gelatoWhitelist[msg.sender] = false;
        }
    }
    
    function setGelatoInterval(uint256 _interval) public {
     // interval manual - 1 for daily 2 for weekly 3 for monthly
     if(_interval == 1){
        
        gelatoInterval[msg.sender] = 86400;

     }else if (_interval == 2){

        gelatoInterval[msg.sender] = 604800;

     } else if (_interval == 3){

        gelatoInterval[msg.sender] = 2592000;

     } else {
        
        gelatoInterval[msg.sender] = 86400;

     }


    }

    function setGelatoMaxQT(uint256 _quantityOfTickets) public {
        // max quantity allowed to set on gelato auto bets
        gelatoMaxQT[msg.sender] = _quantityOfTickets;
        
    }


    function swapTokens(uint256 tokenAmount) private {
        // generate the swap pair path of tokens
        address[] memory path = new address[](2);
        path[0] = usdTrading;
        path[1] = btcTrading;

        usd.approve(address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of Tokens out
            path,
            address(this), // The contract
            block.timestamp + 300
        );
    }

    function swapTokensToJackpot(uint256 tokenAmount) private {
        // generate the swap pair path of tokens
        address[] memory path = new address[](2);
        path[0] = usdTrading;
        path[1] = btcTrading;


        usd.approve(address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of Tokens out
            path,
            weeklyContract, // The contract
            block.timestamp + 300
        );
    }

    function swapTokensToUSD(uint256 tokenAmount, address user, uint typeSwap) private {
        // generate the swap pair path of tokens
        address[] memory path = new address[](2);
        path[0] = btcTrading;
        path[1] = usdTrading;

        // Convert to 18 Decimals
        uint256 amountToMath;
        if(stableDecimals < 18){
            amountToMath = (tokenAmount * 10**(18 - stableDecimals));
        }else{
            amountToMath = tokenAmount;   
        }
        // approve token
        uint256 tprice = getLatestPrice();
        
        uint256 amountInToken = (amountToMath * 10**18) / tprice;  // refund value in token
        amountInToken = amountInToken / 10**10;
        uint256 amountMath = amountInToken.mul(50).div(1000); // 5% slippage safe - difference goes to pot on next ticket buy
        amountInToken = amountInToken + amountMath;
        btc.approve(address(uniswapRouter), (amountInToken+10000000));


        // make the swap
        uniswapRouter.swapTokensForExactTokens(
            tokenAmount,
            amountInToken+10000000, // to garantee the trade
            path,
            user, // receiving user
            block.timestamp + 300
        );

        if(typeSwap == 1){
         
         prizeValueJackpot -= amountInToken+10000000; // testnet config with +

        } else if (typeSwap == 0){

         contractBalance -= amountInToken;

        }
    }

    // Move the last element to the deleted spot.
    // Remove the last element.
    function clearRegisteredElement(uint index) internal {
        require(index < registeredsAccts.length);
        registeredsAccts[index] = registeredsAccts[registeredsAccts.length-1];
        registeredsAccts.pop();
    }

    function clearUserTicket(address user,uint256 drawId,uint16 ticketId) internal returns (bool) {
        for (uint256 i = 0; i < userTickets[drawId][user].length; i++) {
            if (userTickets[drawId][user][i] == ticketId) {
                // Found the value to delete, shift the rest of the array down
                for (uint256 j = i; j < userTickets[drawId][user].length - 1; j++) {
                    userTickets[drawId][user][j] = userTickets[drawId][user][j+1];
                }
                // Delete the last element, which is now a duplicate of the second-to-last element
                delete userTickets[drawId][user][userTickets[drawId][user].length - 1];
                // Reduce the length of the array by 1
                userTickets[drawId][user].pop();
                // delete from ticket history
                delete ticketsHistory[requestCounter][ticketId];

                // Return true to indicate success
                return true;
            }
        }
        // Value not found, return false to indicate failure
        return false;
    }

    // Auto Spin
    function autoSpin(address _caller, uint8[] calldata _nodes) public nonReentrant {

        if(lbNodes.getUserActivation(_caller,0) == false){
            lbNodes.activateNodes(_caller,_nodes,1,0);
        }else{

            require(block.timestamp > lastAutoSpin + 600,"draw timestamp still not reached."); // 86400 mainnet

            uint256 botReward = nftnodeBalance;

            if(getJackpotinUSD() >= minimumPot && registeredsAccts.length >= 25){ 


                    if(block.timestamp > lastAutoSpin + 900 && reset == false){    // if no node activates in 5 minutes period queue resets
                        lbNodes.resetQueue(1,0);
                        reset = true;
                    } else if(lbNodes.updateNodeInfo(_caller,botReward,0,1) == true){

                        // Reward user that activates the function using NFTNode with rewards in usd
                
                        usd.safeTransfer(_caller,botReward);
                        reset = false;
                        nftnodeBalance = 0;

                        // Fires a new Draw
                        getRandomNumber();  

                        lastAutoSpin = block.timestamp;

                    } else{
                        require(0 > 1, "updateNodeInfo functions returned false. Review your _nodes parameter and configuration");    
                    }
                
            } else{
                lastAutoSpin = block.timestamp;
                emit LotteryLog(block.timestamp,deadAddress, "Minimum Pot or minimum registers not reached, tickets and prize carry over for next draw",prizeValueJackpot);
            }
        }
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (uint256 requestId) {
        require(LINK.balanceOf(address(this)) >= VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit), "Not enough LINK - fill contract");
		requestId = requestRandomness(callbackGasLimit,requestConfirmations,numWords);
        requestNumberIndexToRequestId[requestCounter] = requestId;
        requestIdToRequestNumberIndex[requestId] = requestCounter;

        uint256 tprice = getLatestPrice();
        
        uint256 amountInToken = (20 * 10**18 * 10**18) / tprice;  // 20 usd in token
        minimumPrize = amountInToken / 10**10;
        
        // minimum 5 usd to nftnodes if sufficient balance

        if(contractBalance >= minimumPrize*3){

            swapTokensToUSD((5 * 10**stableDecimals),address(this),0);
            nftnodeBalance = usd.balanceOf(address(this));

         }

        //
    }


	 /** 
     * @notice Modifier to only allow updates by the VRFCoordinator contract
     */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfcoordinator, 'Fulfillment only allowed by VRFCoordinator');
        _;
    }


    // For multiple randomness
    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomWords(uint256 requestId, uint256[] memory _randomWords) internal override {

        uint256 requestNumber = requestIdToRequestNumberIndex[requestId];
        
        // Store the random number
        requestNumberIndexToRandomNumber[requestNumber] = _randomWords[0];

        // Calculate the number of players for provably fair
        numberOfPlayers[requestNumber] = registeredsAccts.length;

        // Determine the raffle winner
        raffle = uint16(_randomWords[0] % uint256(registeredsAccts.length));
	
        // Getting Raffle Winner Infos
        uint16 idInPosition = registeredsAccts[raffle];

        Ticket memory winnerTicket = ticketsHistory[requestNumber][idInPosition];

        address userWallet = winnerTicket.owner;

        // Send Raffle Prize and reset tickets
        if (idInPosition < 20) {
            // Contract wins - accumulate prize
            accumulateJackpot(prizeValueJackpot);
            emit LotteryLog(block.timestamp, userWallet, "Contract Wins Prize Accumulate", prizeValueJackpot);
        } else {
            btc.safeTransfer(userWallet, prizeValueJackpot);
            prizeValueJackpot = 0;
            emit LotteryLog(block.timestamp, userWallet, "We have a new raffle Winner", prizeValueJackpot);

            // Minimum prize value fill
            if (contractBalance >= minimumPrize) {
                prizeValueJackpot += minimumPrize;
                contractBalance -= minimumPrize;
            }
        }

        // Update ticket info
        winnerTicket.winner = true;
        jackpotWinHistory[requestNumber] = winnerTicket;

        delete registeredsAccts;
        incrementTicketIds = 0;
        requestCounter += 1;

    }


    // Play Function
    function BuyTicket(address player,uint quantity) public nonReentrant {
        
        require(player == msg.sender || msg.sender == gelatoSender[player],"You can't buy ticket for other players");
        require((registeredsAccts.length + quantity) <= ticketLimit, "Already reached tickets limit, Try again next draw.");   
        
        if(msg.sender == gelatoSender[player]){

            require(gelatoWhitelist[player] == true,"You have to whitelist gelato bets in the smart contract");
            require(block.timestamp >= gelatoLastBet[player] + gelatoInterval[player], "Gelato Interval timestamp not reached,bet again on a later time.");
            require(quantity <= gelatoMaxQT[player],"quantity setted is higher than allowed max quantity.");
            gelatoLastBet[player] = block.timestamp;

        }

        if(registeredsAccts.length < 1){
            if (userTickets[requestCounter][address(this)].length == 0) {
                userTickets[requestCounter][address(this)] = new uint16[](0);
            }

            // Add 20 contract tickets
            for(uint index = 0; index < 20; index++){
            
                uint16 indexCheck = incrementTicketIds;

                Ticket memory ticket = Ticket(requestCounter,indexCheck,address(this),false);
                
                ticketsHistory[requestCounter][indexCheck] = ticket;

                registeredsAccts.push(indexCheck);
                userTickets[requestCounter][address(this)].push(indexCheck);
                incrementTicketIds++;
            }
        }

        // > total allocation is 47.50% to dailly raffle () 5.00% to fee () 47.50% to jackpot weekly raffle 
        uint256 totalCost;
        uint256 dailyFeed; //47.5% of ticket value to pay raffle prize
        uint256 weeklyFeed;
        // 5% of sustaining fee + ecosystem rewards + node rewards
        uint256 nftnodeFee; // 2% of sustainingFee - added every new buy, accumulated amount paid for the NFT owner on the draw
        uint256 platformFee; // 1% of sustainingFee - platform fee
        uint256 lpstakingFee; // 2% of sustainingFee - amount that goes for KRSTM-MATIC LP stakers

        if(krstm.balanceOf(player) >= KrstmPremium){
            if(quantity >= 10){
             totalCost = (TICKET_VAL.mul(75).div(100)).mul(quantity);
            } else{
             totalCost = (TICKET_VAL.mul(80).div(100)).mul(quantity);    
            }
        } else{
            if(quantity >= 10){
             totalCost = (TICKET_VAL.mul(95).div(100)).mul(quantity);

            } else{
             totalCost = TICKET_VAL.mul(quantity);
            }
        }

        weeklyFeed = totalCost.mul(475).div(1000); // 47.5%
        dailyFeed = totalCost.mul(475).div(1000); // 47.5%

        nftnodeFee = totalCost.mul(2).div(100); // 2% of sustainingFee - added every new buy, accumulated amount paid for the NFT owner on the draw
        platformFee = totalCost.mul(1).div(100); // 1% of sustainingFee - platform fee
        lpstakingFee = totalCost.mul(2).div(100); // 2% of sustainingFee - amount that goes for KRSTM-MATIC LP stakers

        require(usd.balanceOf(player) >= totalCost,"You don't have enough USD in the wallet!");   
                    

        usd.transferFrom(payable(player),address(this),(dailyFeed + nftnodeFee + weeklyFeed));
        usd.transferFrom(payable(player),stakingContract,lpstakingFee);
        usd.transferFrom(payable(player),platformAddress,platformFee);

        // update balances
         swapTokens(dailyFeed);
         swapTokensToJackpot(weeklyFeed);   

         nftnodeBalance += nftnodeFee; 
         prizeValueJackpot = (btc.balanceOf(address(this)) - contractBalance); // ((dailyFeed * 10**12) / tprice) / 10**10;

        for(uint i = 0; i < quantity; i++){
       
            // Create Id based on position entry Daily
            uint16 indexCheck = incrementTicketIds;

            Ticket memory ticket = Ticket(requestCounter,indexCheck,player,false);
            ticketsHistory[requestCounter][indexCheck] = ticket; 
            
            if (userTickets[requestCounter][player].length == 0) {
                userTickets[requestCounter][player] = new uint16[](0);
            }

            registeredsAccts.push(indexCheck);
            userTickets[requestCounter][player].push(indexCheck);
            incrementTicketIds++;
        }
        
        // register the weekly tickets
        lottoWeekly.registerTickets(quantity,player);

        emit LotteryLog(block.timestamp,player, "Ticket's Bought, Good luck!",totalCost);
    }
	
    // Data Fetch Functions
	function amountOfRegisters() public view returns(uint) {
		return registeredsAccts.length;
	}
	

    function getTicketPositions() external view returns(uint16[] memory) {
		
        return registeredsAccts;

	}

    function getUserTicketsByDraw(uint256 drawId,address userWallet) external view returns(uint16[] memory) {
		
        return userTickets[drawId][userWallet];

	}

	function autoSpinTimestamp() public view returns(uint256) {
		return lastAutoSpin;
	}


    // it will show winner address in that lottery id if the user has hit jackpot.
    function getJackpotWinnerByLotteryId(uint256 _requestCounter) public view returns (Ticket memory) {
        return jackpotWinHistory[_requestCounter];
    }
    
    function ourLastWinner() public view returns(address) {
        return lastWinner;
    }
	   
    // Users Forfeit Withdraw function get Back a % of ticket value
    function ForfeitTicket(uint256 index) public nonReentrant {
    
        Ticket memory trackedTicket = ticketsHistory[requestCounter][index];
        address owner = trackedTicket.owner;
        require(owner == msg.sender,"You are not the owner of that ticket!");
        require(getJackpotinUSD() >= 1 * 10**18, "Contract need to have atleast 1 USD in value.");

        uint16 ticketPosition;

        uint256 weeklyDraw = lottoWeekly.requestCounter();

        uint16[] memory getTicketsWeekly = lottoWeekly.getUserTicketsByDraw(weeklyDraw,owner);
    

        for(uint16 i = 0; i < registeredsAccts.length; i++){
          
          uint16 idInPosition = registeredsAccts[i];
           
           if(idInPosition == index){
            ticketPosition = i;

            uint256 drawId = requestCounter;

            // Getting Registered user Info and Value
            uint256 refundValue;
                            
            refundValue = TICKET_VAL.mul(75).div(100);

            // Delete ticket from list   
            if(clearUserTicket(owner,drawId,trackedTicket.id)){       
            
                clearRegisteredElement(ticketPosition);
                if(getTicketsWeekly.length > 0){
                 lottoWeekly.ForfeitTicket(owner);
                }
                // Refund user
                swapTokensToUSD(refundValue,msg.sender,1);   
                
            }


          }  
        }            
    }
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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