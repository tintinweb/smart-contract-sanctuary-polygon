// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

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
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts/utils/Context.sol';

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
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x095ea7b3, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper: APPROVE_FAILED'
    );
  }

  function safeTransfer(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0xa9059cbb, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper: TRANSFER_FAILED'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(0x23b872dd, from, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper: TRANSFER_FROM_FAILED'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }
}

// SPDX-License-Identifier: MIT

// File contracts/StakingPool.sol
pragma solidity 0.8.9;

import './library/TransferHelper.sol';
import './library/Ownable.sol';
import './IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract StakingPoolUpdatableFixedAPR is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeMath for uint16;
  using Address for address;

  /// @notice information stuct on each user than stakes LP tokens.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 nextHarvestUntil; // When can the user harvest again.
    mapping(IERC20 => uint256) rewardDebt; // Reward debt.
    mapping(IERC20 => uint256) rewardLockedUp; // Reward locked up.
    mapping(address => bool) whiteListedHandlers;
  }

  // Info of each pool.
  struct RewardInfo {
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 accRewardPerShare;
    uint256 lastRewardBlockTimestamp; // Last block timestamp that rewards distribution occurs.
    uint256 blockRewardPerSec;
    IERC20 rewardToken; // Address of reward token contract.
    uint256 expectedAPR; // if target APR is 20%, then expectedAPR =  ( 20 / 100 ) * 1e18. Percentage APR is scaled up by e18.
  }

  /// @notice all the settings for this farm in one struct
  struct FarmInfo {
    uint256 numFarmers;
    uint256 harvestInterval; // Harvest interval in seconds
    IERC20 inputToken;
    uint16 withdrawalFeeBP; // Withdrawal fee in basis points
    uint256 endTimestamp;
  }

  // Withdrawal Fee address
  address public feeAddress;
  // Max harvest interval: 14 days.
  uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
  uint256 public constant SECONDS_IN_YEAR = 365 * 86400;

  // Max withdrawal fee: 10%. This number is later divided by 10000 for calculations.
  uint16 public constant MAXIMUM_WITHDRAWAL_FEE_BP = 1000;

  uint256 public totalInputTokensStaked;
  uint public exponent = 1e18;

  // Total locked up rewards
  mapping(IERC20 => uint256) public totalLockedUpRewards;

  FarmInfo public farmInfo;

  mapping(address => bool) public activeRewardTokens;

  /// @notice information on each user than stakes LP tokens
  mapping(address => UserInfo) public userInfo;

  RewardInfo[] public rewardPool;

  bool public initialized;

  uint256 public maxAllowedDeposit;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 amount);
  event RewardLockedUp(address indexed user, uint256 amountLockedUp);
  event RewardTokenAdded(IERC20 _rewardToken);
  event FeeAddressChanged(address _feeAddress);
  event RewardPoolUpdated(uint256 _rewardInfoIndex);
  event UserWhitelisted(address _primaryUser, address _whitelistedUser);
  event UserBlacklisted(address _primaryUser, address _blacklistedUser);
  event ExpectedAprUpdated(uint256 _expectedApr, uint256 _rewardPoolIndex);
  event WithdrawalFeeChanged(uint16 _withdrawalFee);
  event HarvestIntervalChanged(uint256 _harvestInterval);
  event MaxAllowedDepositUpdated(uint256 _maxAllowedDeposit);

  struct LocalVars {
    uint256 _amount;
    uint256 _startTimestamp;
    uint256 _endTimestamp;
    IERC20 _rewardToken;
  }

  LocalVars private _localVars;

  constructor(bytes memory poolData) {
    _initPool(poolData);
  }

  /**
   * @notice initialize the staking pool contract.
   * This is called only once and state is initialized.
   */
  function _initPool(bytes memory poolData) internal {
    require(initialized == false, 'Contract already initialized');

    // Decoding is done in two parts due to stack too deep issue.
    (
      _localVars._rewardToken,
      _localVars._amount,
      farmInfo.inputToken,
      _localVars._startTimestamp,
      _localVars._endTimestamp
    ) = abi.decode(poolData, (IERC20, uint256, IERC20, uint256, uint256));

    uint256 expectedAPR;

    (
      ,
      ,
      ,
      ,
      ,
      expectedAPR,
      farmInfo.harvestInterval,
      feeAddress,
      farmInfo.withdrawalFeeBP,
      owner
    ) = abi.decode(
      poolData,
      (
        IERC20,
        uint256,
        IERC20,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint16,
        address
      )
    );

    (, , , , , , , , , , farmInfo.endTimestamp, maxAllowedDeposit) = abi.decode(
      poolData,
      (
        IERC20,
        uint256,
        IERC20,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint16,
        address,
        uint256,
        uint256
      )
    );

    require(
      farmInfo.withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE_BP,
      'add: invalid withdrawal fee basis points'
    );
    require(
      farmInfo.harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
      'add: invalid harvest interval'
    );

    TransferHelper.safeTransferFrom(
      address(_localVars._rewardToken),
      msg.sender,
      address(this),
      _localVars._amount
    );

    require(
      farmInfo.endTimestamp >= block.timestamp,
      'End block timestamp must be greater than current timestamp'
    );
    require(
      farmInfo.endTimestamp > _localVars._startTimestamp,
      'Invalid start timestamp'
    );
    require(
      farmInfo.endTimestamp >= _localVars._endTimestamp,
      'Invalid end timestamp'
    );
    require(
      _localVars._endTimestamp > _localVars._startTimestamp,
      'Invalid start and end timestamp'
    );

    rewardPool.push(
      RewardInfo({
        startTimestamp: _localVars._startTimestamp,
        endTimestamp: _localVars._endTimestamp,
        rewardToken: _localVars._rewardToken,
        lastRewardBlockTimestamp: block.timestamp > _localVars._startTimestamp
          ? block.timestamp
          : _localVars._startTimestamp,
        blockRewardPerSec: 0,
        accRewardPerShare: 0,
        expectedAPR: expectedAPR
      })
    );

    activeRewardTokens[address(_localVars._rewardToken)] = true;
    initialized = true;
  }

  function updateMaxAllowedDeposit(
    uint256 _maxAllowedDeposit
  ) external onlyOwner {
    maxAllowedDeposit = _maxAllowedDeposit;
    emit MaxAllowedDepositUpdated(_maxAllowedDeposit);
  }

  function updateExponent(uint _newExponent) public onlyOwner {
    massUpdatePools();
    exponent = _newExponent;
  }

  function updateWithdrawalFee(
    uint16 _withdrawalFee,
    bool _massUpdate
  ) external onlyOwner {
    require(
      _withdrawalFee <= MAXIMUM_WITHDRAWAL_FEE_BP,
      'invalid withdrawal fee basis points'
    );

    if (_massUpdate) {
      massUpdatePools();
    }

    farmInfo.withdrawalFeeBP = _withdrawalFee;
    emit WithdrawalFeeChanged(_withdrawalFee);
  }

  function updateHarvestInterval(
    uint256 _harvestInterval,
    bool _massUpdate
  ) external onlyOwner {
    require(
      _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
      'invalid harvest intervals'
    );

    if (_massUpdate) {
      massUpdatePools();
    }

    farmInfo.harvestInterval = _harvestInterval;
    emit HarvestIntervalChanged(_harvestInterval);
  }

  function rescueFunds(IERC20 _token, address _recipient) external onlyOwner {
    TransferHelper.safeTransfer(
      address(_token),
      _recipient,
      _token.balanceOf(address(this))
    );
  }

  function addRewardToken(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    IERC20 _rewardToken, // Address of reward token contract.
    uint256 _lastRewardTimestamp,
    uint256 _amount,
    bool _massUpdate,
    uint256 _expectedAPR
  ) external onlyOwner nonReentrant {
    require(
      farmInfo.endTimestamp > _startTimestamp,
      'Invalid start end timestamp'
    );
    require(farmInfo.endTimestamp >= _endTimestamp, 'Invalid end timestamp');
    require(_endTimestamp > _startTimestamp, 'Invalid end timestamp');
    require(address(_rewardToken) != address(0), 'Invalid reward token');
    require(
      activeRewardTokens[address(_rewardToken)] == false,
      'Reward Token already added'
    );

    require(
      _lastRewardTimestamp >= block.timestamp,
      'Last RewardBlock must be greater than currentBlock'
    );

    if (_massUpdate) {
      massUpdatePools();
    }

    rewardPool.push(
      RewardInfo({
        startTimestamp: _startTimestamp,
        endTimestamp: _endTimestamp,
        rewardToken: _rewardToken,
        lastRewardBlockTimestamp: _lastRewardTimestamp,
        blockRewardPerSec: 0,
        accRewardPerShare: 0,
        expectedAPR: _expectedAPR
      })
    );

    activeRewardTokens[address(_rewardToken)] = true;

    TransferHelper.safeTransferFrom(
      address(_rewardToken),
      msg.sender,
      address(this),
      _amount
    );

    _updateRewardPerSecond();
    emit RewardTokenAdded(_rewardToken);
  }

  function deposit(uint256 _amount) external nonReentrant {
    _deposit(_amount, msg.sender);
  }

  function depositFor(uint256 _amount, address _user) external nonReentrant {
    _deposit(_amount, _user);
  }

  /**
   * @notice withdraw LP token function for msg.sender
   * @param _amount the total withdrawable amount
   */
  function withdraw(uint256 _amount) external nonReentrant {
    _withdraw(_amount, msg.sender, msg.sender);
  }

  function withdrawFor(uint256 _amount, address _user) external nonReentrant {
    UserInfo storage user = userInfo[_user];
    require(
      user.whiteListedHandlers[msg.sender],
      'Handler not whitelisted to withdraw'
    );
    _withdraw(_amount, _user, msg.sender);
  }

  /**
   * @notice emergency function to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
   */
  function emergencyWithdraw() external nonReentrant {
    UserInfo storage user = userInfo[msg.sender];

    if (user.amount > 0) {
      farmInfo.numFarmers--;
    }
    totalInputTokensStaked = totalInputTokensStaked.sub(user.amount);
    uint256 amount = user.amount;
    user.amount = 0;

    uint256 totalRewardPools = rewardPool.length;
    for (uint256 i = 0; i < totalRewardPools; i++) {
      user.rewardDebt[rewardPool[i].rewardToken] = 0;
      totalLockedUpRewards[rewardPool[i].rewardToken] = totalLockedUpRewards[
        rewardPool[i].rewardToken
      ].sub(user.rewardLockedUp[rewardPool[i].rewardToken]);
      user.rewardLockedUp[rewardPool[i].rewardToken] = 0;
    }
    _updateRewardPerSecond();
    TransferHelper.safeTransfer(
      address(farmInfo.inputToken),
      address(msg.sender),
      amount
    );
    emit EmergencyWithdraw(msg.sender, amount);
  }

  function whitelistHandler(address _handler) external {
    UserInfo storage user = userInfo[msg.sender];
    user.whiteListedHandlers[_handler] = true;
    emit UserWhitelisted(msg.sender, _handler);
  }

  function removeWhitelistedHandler(address _handler) external {
    UserInfo storage user = userInfo[msg.sender];
    user.whiteListedHandlers[_handler] = false;
    emit UserBlacklisted(msg.sender, _handler);
  }

  // Update fee address by the previous fee address.
  function setFeeAddress(address _feeAddress) external onlyOwner {
    require(_feeAddress != address(0), 'setFeeAddress: invalid address');
    feeAddress = _feeAddress;
    emit FeeAddressChanged(feeAddress);
  }

  function updateExpectedAPR(
    uint256 _expectedAPR,
    uint256 _rewardTokenIndex
  ) external onlyOwner {
    massUpdatePools();
    RewardInfo storage reward = rewardPool[_rewardTokenIndex];
    reward.expectedAPR = _expectedAPR;
    _updateRewardPerSecond();
    emit ExpectedAprUpdated(_expectedAPR, _rewardTokenIndex);
  }

  function transferRewardToken(
    uint256 _rewardTokenIndex,
    uint256 _amount
  ) external onlyOwner {
    RewardInfo storage rewardInfo = rewardPool[_rewardTokenIndex];
    require(
      rewardInfo.rewardToken.balanceOf(address(this)) >= _amount,
      'Insufficient reward token balance'
    );

    TransferHelper.safeTransfer(
      address(rewardInfo.rewardToken),
      msg.sender,
      _amount
    );
  }

  /**
   * @notice function to see accumulated balance of reward token for specified user
   * @param _user the user for whom unclaimed tokens will be shown
   * @param _rewardInfoIndex reward token's index.
   * @return total amount of withdrawable reward tokens
   */
  function pendingReward(
    address _user,
    uint256 _rewardInfoIndex
  ) external view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    RewardInfo memory rewardInfo = rewardPool[_rewardInfoIndex];
    uint256 accRewardPerShare = rewardInfo.accRewardPerShare;
    uint256 lpSupply = totalInputTokensStaked;

    if (
      block.timestamp > rewardInfo.lastRewardBlockTimestamp && lpSupply != 0
    ) {
      uint256 multiplier = getMultiplier(
        rewardInfo.lastRewardBlockTimestamp,
        _rewardInfoIndex,
        block.timestamp
      );
      uint256 tokenReward = multiplier.mul(rewardInfo.blockRewardPerSec);
      accRewardPerShare = accRewardPerShare.add(tokenReward.div(lpSupply));
    }

    uint256 pending = user.amount.mul(accRewardPerShare).div(exponent).sub(
      user.rewardDebt[rewardInfo.rewardToken]
    );
    return pending.add(user.rewardLockedUp[rewardInfo.rewardToken]);
  }

  function isUserWhiteListed(
    address _owner,
    address _user
  ) external view returns (bool) {
    UserInfo storage user = userInfo[_owner];
    return user.whiteListedHandlers[_user];
  }

  // View function to see if user harvest until time.
  function getHarvestUntil(address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    return user.nextHarvestUntil;
  }

  /**
   * @notice updates pool information to be up to date to the current block timestamp
   */
  function updatePool(uint256 _rewardInfoIndex) public {
    RewardInfo storage rewardInfo = rewardPool[_rewardInfoIndex];
    if (block.timestamp <= rewardInfo.lastRewardBlockTimestamp) {
      return;
    }
    uint256 lpSupply = totalInputTokensStaked;

    if (lpSupply == 0) {
      rewardInfo.lastRewardBlockTimestamp = block.timestamp;
      return;
    }
    uint256 multiplier = getMultiplier(
      rewardInfo.lastRewardBlockTimestamp,
      _rewardInfoIndex,
      block.timestamp
    );
    uint256 tokenReward = multiplier.mul(rewardInfo.blockRewardPerSec);
    rewardInfo.accRewardPerShare = rewardInfo.accRewardPerShare.add(
      tokenReward.div(lpSupply)
    );
    rewardInfo.lastRewardBlockTimestamp = block.timestamp <
      rewardInfo.endTimestamp
      ? block.timestamp
      : rewardInfo.endTimestamp;

    emit RewardPoolUpdated(_rewardInfoIndex);
  }

  function massUpdatePools() public {
    uint256 totalRewardPool = rewardPool.length;
    for (uint256 i = 0; i < totalRewardPool; i++) {
      updatePool(i);
    }
  }

  /**
   * @notice Gets the reward multiplier over the given _fromTimestamp until _toTimestamp
   * @param _fromTimestamp the start of the period to measure rewards for
   * @param _rewardInfoIndex RewardPool Id number
   * @param _toTimestamp the end of the period to measure rewards for
   * @return The weighted multiplier for the given period
   */
  function getMultiplier(
    uint256 _fromTimestamp,
    uint256 _rewardInfoIndex,
    uint256 _toTimestamp
  ) public view returns (uint256) {
    RewardInfo memory rewardInfo = rewardPool[_rewardInfoIndex];
    uint256 _from = _fromTimestamp >= rewardInfo.startTimestamp
      ? _fromTimestamp
      : rewardInfo.startTimestamp;
    uint256 to = rewardInfo.endTimestamp > _toTimestamp
      ? _toTimestamp
      : rewardInfo.endTimestamp;
    if (_from > to) {
      return 0;
    }

    return to.sub(_from, 'from getMultiplier');
  }

  // View function to see if user can harvest tokens.
  function canHarvest(address _user) public view returns (bool) {
    UserInfo storage user = userInfo[_user];
    return ((block.timestamp >= user.nextHarvestUntil));
  }

  function _updateRewardPerSecond() internal {
    /* 
            APR = ( SECONDS_IN_YEAR * RewardPerSecond * 100 ) / Total deposited
            RewardPerSecond = ( APR * Total deposited ) / ( SECONDS_IN_YEAR )
        */
    uint256 totalRewardPools = rewardPool.length;
    uint256 inputTokenDecimals = farmInfo.inputToken.decimals();

    for (uint256 i = 0; i < totalRewardPools; i++) {
      RewardInfo storage rewardInfo = rewardPool[i];
      uint256 rewardTokenDecimals = rewardInfo.rewardToken.decimals();
      uint256 expectedAPR = rewardInfo.expectedAPR;
      uint256 effectiveRewardPerSecond = (
        expectedAPR
          .mul(totalInputTokensStaked)
          .mul(10 ** rewardTokenDecimals)
          .mul(exponent)
      ).div((10 ** inputTokenDecimals).mul(SECONDS_IN_YEAR * 1e18));
      rewardInfo.blockRewardPerSec = effectiveRewardPerSecond;
    }
  }

  function _deposit(uint256 _amount, address _user) internal {
    require(
      totalInputTokensStaked.add(_amount) <= maxAllowedDeposit,
      'Max allowed deposit exceeded'
    );
    UserInfo storage user = userInfo[_user];
    payOrLockupPendingReward(_user, _user);
    if (user.amount == 0 && _amount > 0) {
      farmInfo.numFarmers++;
    }
    if (_amount > 0) {
      TransferHelper.safeTransferFrom(
        address(farmInfo.inputToken),
        address(msg.sender),
        address(this),
        _amount
      );
      user.amount = user.amount.add(_amount);
    }
    totalInputTokensStaked = totalInputTokensStaked.add(_amount);
    updateRewardDebt(_user);
    _updateRewardPerSecond();
    emit Deposit(_user, _amount);
  }

  function _withdraw(
    uint256 _amount,
    address _user,
    address _withdrawer
  ) internal {
    UserInfo storage user = userInfo[_user];
    require(user.amount >= _amount, 'INSUFFICIENT');
    payOrLockupPendingReward(_user, _withdrawer);
    if (_amount > 0) {
      if (user.amount == _amount) {
        farmInfo.numFarmers--;
      }
      user.amount = user.amount.sub(_amount);
      if (farmInfo.withdrawalFeeBP > 0) {
        uint256 withdrawalFee = _amount.mul(farmInfo.withdrawalFeeBP).div(
          10000
        );
        TransferHelper.safeTransfer(
          address(farmInfo.inputToken),
          feeAddress,
          withdrawalFee
        );
        TransferHelper.safeTransfer(
          address(farmInfo.inputToken),
          address(_withdrawer),
          _amount.sub(withdrawalFee)
        );
      } else {
        TransferHelper.safeTransfer(
          address(farmInfo.inputToken),
          address(_withdrawer),
          _amount
        );
      }
    }
    totalInputTokensStaked = totalInputTokensStaked.sub(_amount);
    updateRewardDebt(_user);
    _updateRewardPerSecond();
    emit Withdraw(_user, _amount);
  }

  function payOrLockupPendingReward(
    address _user,
    address _withdrawer
  ) internal {
    UserInfo storage user = userInfo[_user];
    if (user.nextHarvestUntil == 0) {
      user.nextHarvestUntil = block.timestamp.add(farmInfo.harvestInterval);
    }

    bool canUserHarvest = canHarvest(_user);

    uint256 totalRewardPools = rewardPool.length;
    for (uint256 i = 0; i < totalRewardPools; i++) {
      RewardInfo storage rewardInfo = rewardPool[i];

      updatePool(i);

      uint256 userRewardDebt = user.rewardDebt[rewardInfo.rewardToken];
      uint256 userRewardLockedUp = user.rewardLockedUp[rewardInfo.rewardToken];
      uint256 pending = user
        .amount
        .mul(rewardInfo.accRewardPerShare)
        .div(exponent)
        .sub(userRewardDebt);

      if (canUserHarvest) {
        if (pending > 0 || userRewardLockedUp > 0) {
          uint256 totalRewards = pending.add(userRewardLockedUp);
          // reset lockup
          totalLockedUpRewards[rewardInfo.rewardToken] = totalLockedUpRewards[
            rewardInfo.rewardToken
          ].sub(userRewardLockedUp);
          user.rewardLockedUp[rewardInfo.rewardToken] = 0;
          user.nextHarvestUntil = block.timestamp.add(farmInfo.harvestInterval);
          // send rewards
          _safeRewardTransfer(
            _withdrawer,
            totalRewards,
            rewardInfo.rewardToken
          );
        }
      } else if (pending > 0) {
        user.rewardLockedUp[rewardInfo.rewardToken] = user
          .rewardLockedUp[rewardInfo.rewardToken]
          .add(pending);
        totalLockedUpRewards[rewardInfo.rewardToken] = totalLockedUpRewards[
          rewardInfo.rewardToken
        ].add(pending);
        emit RewardLockedUp(_user, pending);
      }
    }
  }

  function updateRewardDebt(address _user) internal {
    UserInfo storage user = userInfo[_user];
    uint256 totalRewardPools = rewardPool.length;
    for (uint256 i = 0; i < totalRewardPools; i++) {
      RewardInfo storage rewardInfo = rewardPool[i];

      user.rewardDebt[rewardInfo.rewardToken] = user
        .amount
        .mul(rewardInfo.accRewardPerShare)
        .div(exponent);
    }
  }

  /**
   * @notice Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
   * @param _amount the total amount of tokens to transfer
   * @param _rewardToken token address for transferring tokens
   */
  function _safeRewardTransfer(
    address _to,
    uint256 _amount,
    IERC20 _rewardToken
  ) private {
    require(
      _rewardToken.balanceOf(address(this)) >= _amount,
      'Insufficient reward token balance'
    );
    TransferHelper.safeTransfer(address(_rewardToken), _to, _amount);
  }
}