// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from './@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IFlashLiquidityBastion} from './interfaces/IFlashLiquidityBastion.sol';
import {IFlashLiquidityFactory} from './interfaces/IFlashLiquidityFactory.sol';
import {IFlashLiquidityRouter} from './interfaces/IFlashLiquidityRouter.sol';
import {IFlashLiquidityPair} from './interfaces/IFlashLiquidityPair.sol';
import {IFlashBotFactory} from './interfaces/IFlashBotFactory.sol';
import {IUpkeepsStationFactory} from './interfaces/IUpkeepsStationFactory.sol';
import {IStakingRewards} from './interfaces/IStakingRewards.sol';
import {IPegSwap} from './interfaces/IPegSwap.sol';
import {Recoverable, IERC20, SafeERC20} from './types/Recoverable.sol';

contract FlashLiquidityBastion is IFlashLiquidityBastion, Recoverable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable router;
    address public immutable stakingFactory;
    address public immutable flashBotFactory;
    address public immutable upkeepsStationFactory;
    address private immutable linkTokenERC20;
    address private immutable linkTokenERC667;
    address private immutable pegSwap;
    uint256 public nextExecAllocationId = 0;
    uint256 private nextAllocationId = 0;
    uint256 public immutable allocExecDelay;

    mapping(uint256 => Allocation) public allocations;
    mapping(address => uint256) private tokensAllocated;

    constructor(
        address _governor,
        address _guardian,
        address _router,
        address _stakingFactory,
        address _flashBotFactory,
        address _upkeepsStationFactory,
        address _linkTokenERC20,
        address _linkTokenERC667,
        address _pegSwap,
        uint256 _allocExecDelay,
        uint256 _transferGovernanceDelay,
        uint256 _withdrawalDelay
    ) Recoverable(_governor, _guardian, _transferGovernanceDelay, _withdrawalDelay) {
        router = _router;
        stakingFactory = _stakingFactory;
        flashBotFactory = _flashBotFactory;
        upkeepsStationFactory = _upkeepsStationFactory;
        linkTokenERC20 = _linkTokenERC20;
        linkTokenERC667 = _linkTokenERC667;
        pegSwap = _pegSwap;
        allocExecDelay = _allocExecDelay;
    }

    function getUnallocatedAmount(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) - tokensAllocated[_token];
    }

    function isNextAllocationExecutable() public view returns (bool) {
        Allocation storage _allocation = allocations[nextExecAllocationId];
        if(_allocation.state == AllocationState.PENDING) {
            return block.timestamp - allocations[nextExecAllocationId].requestTimestamp > allocExecDelay;
        }
        return false;
    }

    function setFlashbot(address _pair, address _flashbot) public onlyGovernor {
        IFlashLiquidityFactory factory = IFlashLiquidityFactory(
            IFlashLiquidityRouter(router).factory()
        ); 
        factory.setFlashbot(_pair, _flashbot);
    }

    function setFlashbotSetter(address _flashbotSetter) external onlyGovernor {
        IFlashLiquidityFactory factory = IFlashLiquidityFactory(
            IFlashLiquidityRouter(router).factory()
        );
        factory.setFlashbotSetter(_flashbotSetter);
    }

    function enableAutomatedArbitrage(
        string calldata name,
        address _rewardToken,
        address _flashSwapFarm,
        address _flashPool,
        address[] calldata _extPools,
        address _fastGasFeed,
        address _wethPriceFeed,
        address _rewardTokenPriceFeed,
        uint256 _reserveProfitRatio,
        uint96 _toUpkeepAmount,
        uint32 _gasLimit,
        bytes calldata checkData
    ) external onlyGovernor whenNotPaused {
        address _flashbot = IFlashBotFactory(flashBotFactory).deployFlashbot(
            _rewardToken,
            _flashSwapFarm,
            _flashPool,
            _extPools,
            _fastGasFeed,
            _wethPriceFeed,
            _rewardTokenPriceFeed,
            _reserveProfitRatio,
            50,
            _gasLimit
        );
        setFlashbot(_flashPool, _flashbot);
        IUpkeepsStationFactory(upkeepsStationFactory).automateFlashBot(
            name, 
            _flashbot,
            _gasLimit,
            checkData,
            _toUpkeepAmount
        );
        emit AutomatedArbitrageEnabled(_flashPool);
    }

    function requestAllocation(
        address _recipient,
        address[] calldata _tokens, 
        uint256[] calldata _amounts
    ) external onlyGovernor whenNotPaused {
        uint256 _nextAllocationId = nextAllocationId;
        Allocation storage _allocation = allocations[_nextAllocationId];
        require(_allocation.state == AllocationState.EMPTY, "Wrong Allocation State");
        _allocation.state = AllocationState.PENDING;
        _allocation.requestTimestamp = block.timestamp;
        _allocation.recipient = _recipient;
        nextAllocationId += 1;
        for(uint256 i = 0; i < _tokens.length; i++) {
            require(getUnallocatedAmount(_tokens[i]) >= _amounts[i], "Amount Exceeds Balance");
            tokensAllocated[_tokens[i]] += _amounts[i];
        }
        allocations[_nextAllocationId].tokens = _tokens;
        allocations[_nextAllocationId].amounts = _amounts;
        emit AllocationRequested(_nextAllocationId, _allocation.recipient);
    }

    function abortAllocation(uint256 _allocationId) external onlyGuardian {
        Allocation storage _allocation = allocations[_allocationId];
        require(_allocationId < nextAllocationId, "Not Exists");
        require(_allocationId <= nextExecAllocationId, "Already Executed");
        require(_allocation.state == AllocationState.PENDING, "Not Pending");
        _allocation.state = AllocationState.ABORTED;
        for(uint256 i = 0; i < _allocation.tokens.length; i++) {
            tokensAllocated[_allocation.tokens[i]] -= _allocation.amounts[i];
        }
        emit AllocationAborted(_allocationId);
    }

    function executeAllocation() external onlyGuardian whenNotPaused {
        skipAbortedAllocations();
        uint256 _nextExecAllocationId = nextExecAllocationId;
        Allocation storage _allocation = allocations[_nextExecAllocationId];
        require(_nextExecAllocationId < nextAllocationId, "No Pending Allocation");
        require(_allocation.state == AllocationState.PENDING, "Already Executed");
        require(block.timestamp - _allocation.requestTimestamp > allocExecDelay, "Too Early");
        _allocation.state = AllocationState.EXECUTED;
        nextExecAllocationId += 1;
        for(uint256 i = 0; i < _allocation.tokens.length; i++) {
            IERC20(_allocation.tokens[i]).safeTransfer(_allocation.recipient, _allocation.amounts[i]);
        }
        emit AllocationCompleted(_nextExecAllocationId, _allocation.tokens, _allocation.amounts);

    }

    function skipAbortedAllocation() external onlyGuardian whenNotPaused {
        Allocation storage _allocation = allocations[nextExecAllocationId];
        require(_allocation.state == AllocationState.ABORTED, "Not Aborted");
        nextExecAllocationId += 1;   
    }

    function skipAbortedAllocations() internal {
        uint256 _nextExecAllocationId = nextExecAllocationId;
        Allocation storage _nextAllocation = allocations[_nextExecAllocationId];
        uint256 _count = 0;
        while(_nextAllocation.state == AllocationState.ABORTED) {
            _count += 1;
            _nextAllocation = allocations[_nextExecAllocationId + _count];
        }
        nextExecAllocationId += _count;
    }

    function swapExactTokensForTokens(
        uint256 amountIn, 
        uint256 amountOut, 
        address[] calldata _path
    ) external onlyGovernor whenNotPaused {
        require(amountIn <= getUnallocatedAmount(_path[0]), "AmountIn exceeds unallocated balance");
        IERC20 _token1 = IERC20(_path[0]);
        _token1.safeIncreaseAllowance(router, amountIn);
        uint[] memory amounts = IFlashLiquidityRouter(router).swapExactTokensForTokens(
            amountIn, 
            amountOut, 
            _path, 
            address(this), 
            block.timestamp
        );
        _token1.approve(router, 0);
        emit Swapped(_path[0], _path[_path.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapOnLockedPair(
        uint256 amountIn, 
        uint256 amountOut,
        address fromToken, 
        address toToken
    ) external onlyGovernor whenNotPaused balanceCheck(fromToken, amountIn) {
        IFlashLiquidityFactory factory = IFlashLiquidityFactory(
            IFlashLiquidityRouter(router).factory()
        );
        IFlashLiquidityPair pair = IFlashLiquidityPair(factory.getPair(fromToken, toToken));
        address _flashbot = pair.flashbot();
        require(address(pair) != address(0), "Cannot convert");
        require(_flashbot != address(0), "Cannot use swapLockedPair with open pairs");
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        factory.setFlashbot(address(pair), address(this));      
        if (fromToken == pair.token0()) {
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, address(this), new bytes(0));
        } else {
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, address(this), new bytes(0));
        }

        factory.setFlashbot(address(pair), _flashbot);
        emit Swapped(fromToken, toToken, amountIn, amountOut);         
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external onlyGovernor whenNotPaused balanceCheck(tokenA, amountAMin) balanceCheck(tokenB, amountBMin) {
        IERC20(tokenA).safeIncreaseAllowance(router, amountADesired);
        IERC20(tokenB).safeIncreaseAllowance(router, amountBDesired);
        (uint256 amountA, uint256 amountB,) = IFlashLiquidityRouter(router).addLiquidity(
            tokenA, 
            tokenB, 
            amountADesired, 
            amountBDesired, 
            amountAMin, 
            amountBMin, 
            address(this), 
            block.timestamp
        );
        IERC20(tokenA).approve(router, 0);
        IERC20(tokenB).approve(router, 0);
        emit AddedLiquidity(tokenA, tokenB, amountA, amountB);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin
    ) external onlyGovernor whenNotPaused {
        IFlashLiquidityFactory factory = IFlashLiquidityFactory(
            IFlashLiquidityRouter(router).factory()
        );       
        IERC20 pair = IERC20(factory.getPair(tokenA, tokenB));
        require(liquidity <= getUnallocatedAmount(address(pair)), "Removed liquidity exceeds unallocated balance");
        pair.safeIncreaseAllowance(router, liquidity);
        (uint256 amountA, uint256 amountB) = IFlashLiquidityRouter(router).removeLiquidity(
            tokenA, 
            tokenB, 
            liquidity, 
            amountAMin, 
            amountBMin, 
            address(this),
            block.timestamp
        );
        pair.approve(router, 0);
        emit RemovedLiquidity(tokenA, tokenB, amountA, amountB);
    }

    function stakeLpTokens(
        address farm, 
        uint256 amount
    ) external onlyGovernor whenNotPaused {
        IStakingRewards _farm = IStakingRewards(farm);
        require(_farm.rewardsFactory() == stakingFactory, "Not Authorized");
        IERC20 _stakingToken = IERC20(_farm.stakingToken());
        require(amount <= getUnallocatedAmount(address(_stakingToken)), "Amount exceeds unallocated balance");
        _stakingToken.safeIncreaseAllowance(farm, amount);
        _farm.stake(amount);
        _stakingToken.approve(farm, 0);
        emit Staked(address(_stakingToken), amount);
    }

    function unstakeLpTokens(
        address farm, 
        uint256 amount
    ) external onlyGovernor whenNotPaused {
        IStakingRewards _farm = IStakingRewards(farm);
        require(_farm.rewardsFactory() == stakingFactory, "Not Authorized");
        address _stakingToken = _farm.stakingToken();
        IStakingRewards(farm).withdraw(amount);
        emit Unstaked(_stakingToken, amount);
    }

    function claimStakingRewards(address farm) external onlyGovernor whenNotPaused {
        IStakingRewards _farm = IStakingRewards(farm);
        require(_farm.rewardsFactory() == stakingFactory, "Not Authorized");
        address _stakingToken = _farm.stakingToken();
        IStakingRewards(farm).getReward();
        emit ClaimedRewards(_stakingToken);
    }

    function swapLinkToken(
        bool toERC667,
        uint256 amount
    ) external onlyGovernor whenNotPaused{
        address source;
        address dest;
        if (toERC667) {            
            source = linkTokenERC20;
            dest = linkTokenERC667;
        } else {
            source = linkTokenERC667;
            dest = linkTokenERC20;
        }
        require(amount <= getUnallocatedAmount(source) , "Amount exceeds unallocated balance");
        IERC20(source).safeIncreaseAllowance(pegSwap, amount);
        IPegSwap(pegSwap).swap(amount, source, dest);
        IERC20(source).approve(pegSwap, 0);
    }

    function sendLinkToUpkeepsStationFactory(uint256 amount) external onlyGovernor whenNotPaused balanceCheck(linkTokenERC667, amount) {
        IERC20(linkTokenERC667).safeTransfer(upkeepsStationFactory, amount);
        emit TransferredToStationFactory(amount);
    }

    modifier balanceCheck(address _token, uint256 _amount) {
        require(_amount <= getUnallocatedAmount(_token) , "Amount exceeds unallocated balance");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IFlashBorrower {
    function onFlashLoan(address sender, address token, uint256 amount, uint256 fee, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashBotFactory {

    event FlashBotDeployed(address indexed _flashPool, address indexed _bot);

    function poolflashBot(address) external view returns(address);

    function deployFlashbot(
        address _rewardToken,
        address _flashSwapFarm,
        address _flashPool,
        address[] calldata _extPools,
        address _fastGasFeed,
        address _wethPriceFeed,
        address _rewardTokenPriceFeed,
        uint256 _reserveProfitRatio,
        uint256 _gasProfitMultiplier,
        uint32 _gasLimit
    ) external returns (address _flashbot);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityBastion {

    enum AllocationState {
        EMPTY,
        PENDING,
        EXECUTED,
        ABORTED
    }

    struct Allocation {
        uint256 requestTimestamp;
        AllocationState state;
        address recipient;
        address[] tokens;
        uint256[] amounts;
    }

    event AutomatedArbitrageEnabled(address indexed _pair);
    event AllocationRequested(uint256 indexed _id, address indexed _recipient);
    event AllocationCompleted(uint256 indexed _id, address[] indexed _tokens, uint256[] indexed _amounts);
    event AllocationAborted(uint256 indexed _id);
    event AddedLiquidity(
        address indexed tokenA, 
        address indexed tokenB, 
        uint256 amountA, 
        uint256 amountB
    );
    event RemovedLiquidity(
        address indexed tokenA, 
        address indexed tokenB, 
        uint256 amountA, 
        uint256 amountB
    );
    event Swapped(
        address indexed tokenA, 
        address indexed tokenB, 
        uint256 amountA, 
        uint256 amountB
    );
    event Staked(address indexed stakingToken, uint256 indexed amount);
    event Unstaked(address indexed stakingToken, uint256 indexed amount);
    event ClaimedRewards(address indexed stakingToken);
    event TransferredToStationFactory(uint256 indexed amount);
    
    function router() external view returns (address);
    function stakingFactory() external view returns (address);
    function flashBotFactory() external view returns (address);
    function upkeepsStationFactory() external view returns (address);
    function nextExecAllocationId() external view returns (uint256);
    function allocExecDelay() external view returns (uint256);
    function getUnallocatedAmount(address _token) external view returns (uint256);
    function isNextAllocationExecutable() external view returns (bool);

    function setFlashbot(address _pair, address _flashbot) external;
    function setFlashbotSetter(address _flashbotSetter) external;
    function enableAutomatedArbitrage(
        string calldata name,
        address _rewardToken,
        address _flashSwapFarm,
        address _flashPool,
        address[] calldata _extPools,
        address _fastGasFeed,
        address _wethPriceFeed,
        address _rewardTokenPriceFeed,
        uint256 _reserveProfitRatio,
        uint96 _toUpkeepAmount,
        uint32 _gasLimit,
        bytes calldata checkData
    ) external;

    function requestAllocation(
        address _recipient,
        address[] calldata _tokens, 
        uint256[] calldata _amounts
    ) external;

    function executeAllocation() external;

    function skipAbortedAllocation() external;

    function swapExactTokensForTokens(
        uint256 amountIn, 
        uint256 amountOut, 
        address[] calldata _path
    ) external;

    function swapOnLockedPair(
        uint256 amountIn, 
        uint256 amountOut,
        address fromToken, 
        address toToken
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin
    ) external;

    function stakeLpTokens(
        address farm, 
        uint256 amount
    ) external;

    function unstakeLpTokens(
        address farm, 
        uint256 amount
    ) external;

    function claimStakingRewards(address farm) external;

    function swapLinkToken(
        bool toERC667,
        uint256 amount
    ) external;

    function sendLinkToUpkeepsStationFactory(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IFlashLiquidityFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function flashbotSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function setFlashbot(address pair, address _flashBot) external;
    function setFlashbotSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IFlashLiquidityPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function flashbot() external view returns (address);
    
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
    function setFlashbot(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IFlashLiquidityRouter01.sol';

interface IFlashLiquidityRouter is IFlashLiquidityRouter01 {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IFlashLiquidityRouter01 {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPegSwap {
  function swap(uint256 amount, address source, address target) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './IFlashBorrower.sol';

interface IStakingRewards {

    function rewardsFactory() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    function flashLoan(IFlashBorrower borrower, address receiver, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUpkeepsStationFactory {

    event StationCreated(address indexed station);
    event StationDisabled(address indexed station);
    event UpkeepCreated(uint256 indexed id);
    event UpkeepCanceled(uint256 indexed id);
    event FactoryUpkeepRefueled(uint256 indexed id, uint96 indexed amount);
    event StationUpkeepRefueled(uint256 indexed id, uint96 indexed amount);
    event TransferredToStation(address indexed station, uint96 indexed amount);
    event RevokedFromStation(
        address indexed station, 
        address[] indexed tokens,
        uint256[] indexed amount
    );

    function stations(uint256) external view returns (address);
    function factoryUpkeepId() external view returns (uint256);
    function minWaitNext() external view returns (uint256);
    function minStationBalance() external view returns (uint96);
    function minUpkeepBalance() external view returns (uint96);
    function toStationAmount() external view returns (uint96);
    function toUpkeepAmount() external view returns (uint96);
    function maxStationUpkeeps() external view returns (uint8);
    function getLessBusyStation() external view returns (address station);
    function getFlashBotUpkeepId(address _flashbot) external view returns (uint256);

    function setMinWaitNext(uint256 _interval) external;
    function setMinStationBalance(uint96 _minStationBalance) external;
    function setMinUpkeepBalance(uint96 _minUpkeepBalance) external;
    function setToStationAmount(uint96 _toStationAmount) external;
    function setToUpkeepAmount(uint96 _toUpkeepAmount) external;
    function selfDismantle() external;
    function withdrawStationFactoryUpkeep() external;

    function deployUpkeepsStation(
        string memory name,
        uint32 gasLimit,
        bytes calldata checkData,
        uint96 amount
    ) external;

    function disableUpkeepsStation(address _station) external;
    function withdrawUpkeepsStation(address _station) external;

    function automateFlashBot(
        string memory name,
        address flashbot,
        uint32 gasLimit,
        bytes calldata checkData,
        uint96 amount
    ) external;

    function disableFlashBot(address _flashbot) external;

    function withdrawCanceledFlashBotUpkeeps(address _station, uint256 _upkeepsNumber) external;
    function withdrawAllCanceledFlashBotUpkeeps() external; 
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Governable {

    address public governor;
    address public pendingGovernor;
    uint256 public requestTimestamp;
    uint256 public immutable transferGovernanceDelay;

    event GovernanceTrasferred(address indexed _oldGovernor, address indexed _newGovernor);
    event PendingGovernorChanged(address indexed _pendingGovernor);

    constructor(address _governor, uint256 _transferGovernanceDelay) {
        governor = _governor;
        transferGovernanceDelay = _transferGovernanceDelay;
        emit GovernanceTrasferred(address(0), _governor);
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Only Governor");
        _;
    }

    function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
        require(_pendingGovernor != address(0), "Zero Address");
        pendingGovernor = _pendingGovernor;
        requestTimestamp = block.timestamp;
        emit PendingGovernorChanged(_pendingGovernor);
    }

    function transferGovernance() external {
        address _newGovernor = pendingGovernor;
        address _oldGovernor = governor;
        require(_newGovernor != address(0), "Zero Address");
        require(msg.sender == _oldGovernor || msg.sender == _newGovernor, "Forbidden");
        require(block.timestamp - requestTimestamp > transferGovernanceDelay, "Too Early");
        pendingGovernor = address(0);
        governor = _newGovernor;
        emit GovernanceTrasferred(_oldGovernor, _newGovernor);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Governable.sol';

abstract contract Guardable is Governable {

    address public guardian;

    event GuardianChanged(address indexed _oldGuardian, address indexed _newGuardian);

    constructor(
        address _governor, 
        address _guardian,
        uint256 _transferGovernanceDelay
    ) Governable(_governor, _transferGovernanceDelay) {
        guardian = _guardian;
        emit GuardianChanged(address(0), _guardian);
    }

    function setGuardian(address _guardian) external onlyGovernor {
        address _oldGuardian = guardian;
        guardian = _guardian;
        emit GuardianChanged(_oldGuardian, _guardian);
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only Guardian");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Guardable.sol';
import '../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract Recoverable is Guardable {
    using SafeERC20 for IERC20;
    bool public paused;
    uint256 public withdrawalRequestTimestamp;
    uint256 public immutable withdrawalDelay;
    address public withdrawalRecipient;

    event Paused(address indexed _guardian);
    event Unpaused(address indexed _guardian);
    event EmergencyWithdrawalRequested(address indexed _recipient);
    event EmergencyWithdrawalCompleted(address indexed _recipient);
    event EmergencyWithdrawalAborted(address indexed _recipient);
    event WithdrawalRecipientChanged(address indexed _recipient);

    constructor(
        address _governor, 
        address _guardian, 
        uint256 _transferGovernanceDelay,
        uint256 _withdrawalDelay
    ) Guardable(_governor, _guardian, _transferGovernanceDelay) {
        withdrawalDelay = _withdrawalDelay;
    }

    function pause() external onlyGuardian whenNotPaused {
        paused = true;
        emit Paused(guardian);
    }

    function unpause() external onlyGuardian whenPaused {
        paused = false;
        withdrawalRequestTimestamp = 0;
        emit Unpaused(guardian);
    }

    function requestEmergencyWithdrawal(
        address _withdrawalRecipient
    ) external onlyGovernor whenPaused whenNotEmergency {
        require(_withdrawalRecipient != address(0), "Zero Address");
        withdrawalRecipient = _withdrawalRecipient;
        withdrawalRequestTimestamp = block.timestamp;
        emit EmergencyWithdrawalRequested(_withdrawalRecipient);
    }

    function abortEmergencyWithdrawal() external onlyGovernor whenPaused whenEmergency {
        withdrawalRequestTimestamp = 0;
        emit EmergencyWithdrawalAborted(withdrawalRecipient);
    }

    function emergencyWithdrawal(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyGovernor whenPaused whenEmergency {
        require(block.timestamp - withdrawalRequestTimestamp > withdrawalDelay, "Too Early");
        address _recipient = withdrawalRecipient;
        withdrawalRequestTimestamp = 0;
        for(uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(_recipient, _amounts[i]);
        }
        emit EmergencyWithdrawalCompleted(_recipient);
    }

    modifier whenPaused() {
        require(paused, "Not Paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    modifier whenEmergency() {
        require(withdrawalRequestTimestamp != 0, "Withdrawal Not Requested");
        _;
    }

    modifier whenNotEmergency() {
        require(withdrawalRequestTimestamp == 0, "Withdrawal Already Requested");
        _;
    }
}