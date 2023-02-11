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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/ITimelock.sol';

struct CustodianTimelock {
    uint256 readyTimestamp;
    address adapter;
    address yieldProvider;
    uint256 executedAt;
}

/**
 * @title CustodianTimelockLogic
 * @author AtlendisLabs
 * @dev Contains the utilities methods associated to the manipulation of the Timelock for the custodian
 */
library CustodianTimelockLogic {
    /**
     * @dev Initiate the timelock
     * @param timelock Timelock
     * @param delay Delay in seconds
     * @param adapter New adapter address
     * @param yieldProvider New yield provider address
     */
    function initiate(
        CustodianTimelock storage timelock,
        uint256 delay,
        address adapter,
        address yieldProvider
    ) internal {
        if (timelock.readyTimestamp != 0 && timelock.executedAt == 0) revert ITimelock.TIMELOCK_ALREADY_INITIATED();
        timelock.readyTimestamp = block.timestamp + delay;
        timelock.adapter = adapter;
        timelock.yieldProvider = yieldProvider;
        timelock.executedAt = 0;
    }

    /**
     * @dev Execute the timelock
     * @param timelock Timelock
     */
    function execute(CustodianTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        if (block.timestamp < timelock.readyTimestamp) revert ITimelock.TIMELOCK_NOT_READY();
        timelock.executedAt = block.timestamp;
    }

    /**
     * @dev Cancel the timelock
     * @param timelock Timelock
     */
    function cancel(CustodianTimelock storage timelock) internal {
        if (timelock.readyTimestamp == 0) revert ITimelock.TIMELOCK_INEXISTANT();
        if (timelock.executedAt > 0) revert ITimelock.TIMELOCK_ALREADY_EXECUTED();
        delete timelock.readyTimestamp;
        delete timelock.adapter;
        delete timelock.yieldProvider;
        delete timelock.executedAt;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';
import '../roles-manager/interfaces/IManaged.sol';
import './CustodianTimelockLogic.sol';
import '../../interfaces/ITimelock.sol';

/**
 * @notice IPoolCustodian
 * @author Atlendis Labs
 * @notice Interface of the Custodian contract
 *         A custodian contract is associated to a product contract.
 *         It receives funds by the associated product contract.
 *         A yield strategy is chosen in order to generate rewards based on the deposited funds.
 */
interface IPoolCustodian is IERC165, ITimelock, IManaged {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when an internal delegate call fails
     */
    error DELEGATE_CALL_FAIL();

    /**
     * @notice Thrown when given yield provider does not support the token
     */
    error TOKEN_NOT_SUPPORTED();

    /**
     * @notice Thrown when the given address does not support the adapter interface
     */
    error ADAPTER_NOT_SUPPORTED();

    /**
     * @notice Thrown when sender is not the setup pool address
     * @param sender Sender address
     * @param pool Pool address
     */
    error ONLY_POOL(address sender, address pool);

    /**
     * @notice Thrown when sender is not the setup pool address
     * @param sender Sender address
     * @param rewardsOperator Rewards operator address
     */
    error ONLY_REWARDS_OPERATOR(address sender, address rewardsOperator);

    /**
     * @notice Thrown when trying to initialize an already initialized pool
     * @param pool Address of the already initialized pool
     */
    error POOL_ALREADY_INITIALIZED(address pool);

    /**
     * @notice Thrown when trying to withdraw an amount of deposits higher than what is available
     */
    error NOT_ENOUGH_DEPOSITS();

    /**
     * @notice Thrown when trying to withdraw an amount of rewards higher than what is available
     */
    error NOT_ENOUGH_REWARDS();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when tokens have been deposited to the custodian using current adapter and yield provider
     * @param amount Deposited amount of tokens
     * @param adapter Address of the adapter
     * @param yieldProvider Address of the yield provider
     **/
    event Deposited(uint256 amount, address from, address adapter, address yieldProvider);

    /**
     * @notice Emitted when tokens have been withdrawn from the custodian using current adapter and yield provider
     * @param amount Withdrawn amount of tokens
     * @param to Recipient address
     * @param adapter Address of the adapter
     * @param yieldProvider Address of the yield provider
     **/
    event Withdrawn(uint256 amount, address to, address adapter, address yieldProvider);

    /**
     * @notice Emitted when the yield provider has been switched
     * @param adapter Address of the new adapter
     * @param yieldProvider Address of the new yield provider
     * @param delay Delay for the timelock to be executed
     **/
    event YieldProviderSwitchProcedureStarted(address adapter, address yieldProvider, uint256 delay);

    /**
     * @notice Emitted when the rewards have been collected
     * @param amount Amount of collected rewards
     **/
    event RewardsCollected(uint256 amount);

    /**
     * @notice Emitted when rewards have been withdrawn
     * @param amount Amount of withdrawn rewards
     **/
    event RewardsWithdrawn(uint256 amount);

    /**
     * @notice Emitted when pool has been initialized
     * @param pool Address of the pool
     */
    event PoolInitialized(address pool);

    /**
     * @notice Emitted when rewards operator has been updated
     * @param rewardsOperator Address of the rewards operator
     */
    event RewardsOperatorUpdated(address rewardsOperator);

    /*//////////////////////////////////////////////////////////////
                             VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieve the current stored amount of rewards generated by the custodian
     * @return rewards Amount of rewards
     */
    function getRewards() external view returns (uint256 rewards);

    /**
     * @notice Retrieve the all time amount of generated rewards by the custodian
     * @return generatedRewards All time amount of rewards
     */
    function getGeneratedRewards() external view returns (uint256 generatedRewards);

    /**
     * @notice Retrieve the decimals of the underlying asset
     * @return decimals Decimals of the underlying asset
     */
    function getAssetDecimals() external view returns (uint256 decimals);

    /**
     * @notice Returns the token address of the custodian and the decimals number
     * @return token Token address
     * @return decimals Decimals number
     */
    function getTokenConfiguration() external view returns (address token, uint256 decimals);

    /**
     * @notice Retrieve the current timelock
     * @return timelock The current timelock, may be empty
     */
    function getTimelock() external view returns (CustodianTimelock memory);

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit tokens to the yield provider
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     *
     * Emits a {Deposited} event
     **/
    function deposit(uint256 amount, address from) external;

    /**
     * @notice Exceptional deposit from the governance directly, bypassing the underlying pool
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     *
     * Emits a {Deposited} event
     **/
    function exceptionalDeposit(uint256 amount) external;

    /**
     * @notice Withdraw tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param amount Amount to withdraw
     * @param to Recipient address
     *
     * Emits a {Withdrawn} event
     **/
    function withdraw(uint256 amount, address to) external;

    /**
     * @notice Withdraw all the deposited tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param to Recipient address
     * @return withdrawnAmount The withdrawn amount
     *
     * Emits a {Withdrawn} event
     **/
    function withdrawAllDeposits(address to) external returns (uint256 withdrawnAmount);

    /*//////////////////////////////////////////////////////////////
                          REWARDS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraw an amount of rewards
     * @param amount The amount of rewards to be withdrawn
     * @param to Address that will receive the rewards
     *
     * Emits a {RewardsWithdrawn} event
     **/
    function withdrawRewards(uint256 amount, address to) external;

    /**
     * @notice Updates the pending rewards accrued by the deposits
     * @return generatedRewards The all time amount of generated rewards by the custodian
     *
     * Emits a {RewardsCollected} event
     **/
    function collectRewards() external returns (uint256);

    /*//////////////////////////////////////////////////////////////
                      YIELD PROVIDER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start a procedure for changing the yield provider used by the custodian
     * @param newAdapter New adapter used to manage yield provider interaction
     * @param newYieldProvider New yield provider address
     * @param delay Delay for the timlelock
     *
     * Emits a {YieldProviderSwitchProcedureStarted} event
     **/
    function startSwitchYieldProviderProcedure(
        address newAdapter,
        address newYieldProvider,
        uint256 delay
    ) external;

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize and block the address of the pool for the custodian
     * @param pool Address of the pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address pool) external;

    /**
     * @notice Update the rewards operator address
     * @param rewardsOperator Address of the rewards operator
     *
     * Emits a {RewardsOperatorUpdated} event
     */
    function updateRewardsOperator(address rewardsOperator) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @notice IFeesController
 * @author Atlendis Labs
 * Contract responsible for gathering protocol fees from users
 * actions and making it available for governance to withdraw
 * Is called from the pools contracts directly
 */
interface IFeesController {
    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when management fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event ManagementFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when exit fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param rate Exit fees rate
     **/
    event ExitFeesRegistered(address token, uint256 amount, uint256 rate);

    /**
     * @notice Emitted when borrowing fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event BorrowingFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when repayment fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event RepaymentFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when fees are withdrawn from the fee collector
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param to Recipient address of the fees
     **/
    event FeesWithdrawn(address token, uint256 amount, address to);

    /**
     * @notice Emitted when the due fees are pulled from the pool
     * @param token Token address of the fees
     * @param amount Amount of due fees
     */
    event DuesFeesPulled(address token, uint256 amount);

    /**
     * @notice Emitted when pool is initialized
     * @param managedPool Address of the managed pool
     */
    event PoolInitialized(address managedPool);

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the repayment fee rate
     * @dev Necessary for RCL pool new epochs amounts accounting
     * @return repaymentFeesRate Amount of fees taken at repayment
     **/
    function getRepaymentFeesRate() external view returns (uint256 repaymentFeesRate);

    /**
     * @notice Get the total amount of fees currently held by the contract for the target token
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the contract
     **/
    function getTotalFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the amount of fees currently held by the pool contract for the target token ready to be withdrawn to the Fees Controller
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the pool contract
     **/
    function getDueFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the managed pool contract address
     * @return managedPool The managed pool contract address
     */
    function getManagedPool() external view returns (address managedPool);

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register fees on lender position withdrawal
     * @param amount Withdrawn amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ManagementFeesRegistered} event
     **/
    function registerManagementFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on exit
     * @param amount Exited amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ExitFeesRegistered} event
     **/
    function registerExitFees(uint256 amount, uint256 timeUntilMaturity) external returns (uint256 fees);

    /**
     * @notice Register fees on borrow
     * @param amount Borrowed amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {BorrowingFeesRegistered} event
     **/
    function registerBorrowingFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on repayment
     * @param amount Repaid interests subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {RepaymentFeesRegistered} event
     **/
    function registerRepaymentFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Pull dues fees from the pool
     * @param token Address of the token for which the fees are pulled
     *
     * Emits a {DuesFeesPulled} event
     */
    function pullDueFees(address token) external;

    /**
     * @notice Allows the contract owner to withdraw accumulated fees
     * @param token Address of the token for which fees are withdrawn
     * @param amount Amount of fees to withdraw
     * @param to Recipient address of the witdrawn fees
     *
     * Emits a {FeesWithdrawn} event
     **/
    function withdrawFees(
        address token,
        uint256 amount,
        address to
    ) external;

    /**
     * @notice Initialize the managed pool
     * @param managedPool Address of the managed pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address managedPool) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRolesManager.sol';

/**
 * @title IManaged
 * @author Atlendis Labs
 * @notice Interface in order to integrate roles and permissions managed by a RolesManager
 */
interface IManaged {
    /**
     * @notice Thrown when sender is not a governance address
     */
    error ONLY_GOVERNANCE();

    /**
     * @notice Emitted when the Roles Manager contract has been updated
     * @param rolesManager New Roles Manager contract address
     */
    event RolesManagerUpdated(address indexed rolesManager);

    /**
     * @notice Update the Roles Manager contract
     * @param rolesManager The new Roles Manager contract
     *
     * Emits a {RolesManagerUpdated} event
     */
    function updateRolesManager(address rolesManager) external;

    /**
     * @notice Retrieve the Roles Manager contract
     * @return rolesManager The Roles Manager contract
     */
    function getRolesManager() external view returns (IRolesManager rolesManager);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/**
 * @notice IRolesManager
 * @author Atlendis Labs
 * @notice Roles Manager interface
 *         The Roles Manager is in charge of managing the various roles in the set of smart contracts of a product.
 *         The identified roles are
 *          - GOVERNANCE: allowed to manage the parameters of the contracts and various governance only actions,
 *          - BORROWER: allowed to perform borrow and repay actions,
 *          - OPERATOR: allowed to perform Position NFT or staked Position NFT transfer,
 *          - LENDER: allowed to deposit, update rate, withdraw etc...
 */
interface IRolesManager is IERC165 {
    /**
     * @notice Check if an address has a governance role
     * @param account Address to check
     * @return _ True if the address has a governance role, false otherwise
     */
    function isGovernance(address account) external view returns (bool);

    /**
     * @notice Check if an address has a borrower role
     * @param account Address to check
     * @return _ True if the address has a borrower role, false otherwise
     */
    function isBorrower(address account) external view returns (bool);

    /**
     * @notice Check if an address has an operator role
     * @param account Address to check
     * @return _ True if the address has a operator role, false otherwise
     */
    function isOperator(address account) external view returns (bool);

    /**
     * @notice Check if an address has a lender role
     * @param account Address to check
     * @return _ True if the address has a lender role, false otherwise
     */
    function isLender(address account) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ITimelock
 * @author Atlendis Labs
 * @notice Interface of a basic Timelock
 *         Timelocks are considered for non standard repay, rescue procedures and switching yield provider
 *         Initiation of such procedures are not specified here
 */
interface ITimelock {
    /**
     * @notice Thrown when trying to interact with inexistant timelock
     */
    error TIMELOCK_INEXISTANT();

    /**
     * @notice Thrown when trying to interact with an already executed timelock
     */
    error TIMELOCK_ALREADY_EXECUTED();

    /**
     * @notice Thrown when trying to interact with an already executed timelock
     */
    error TIMELOCK_NOT_READY();

    /**
     * @notice Thrown when trying to interact with an already initiated timelock
     */
    error TIMELOCK_ALREADY_INITIATED();

    /**
     * @notice Thrown when the input delay for a timelock is too small
     */
    error TIMELOCK_DELAY_TOO_SMALL();

    /**
     * @notice Emitted when a timelock has been cancelled
     */
    event TimelockCancelled();

    /**
     * @notice Emitted when a timelock has been executed
     * @param transferredAmount Amount of transferred tokens
     */
    event TimelockExecuted(uint256 transferredAmount);

    /**
     * @notice Execute a ready timelock
     *
     * Emits a {TimelockExecuted} event
     */
    function executeTimelock() external;

    /**
     * @notice Cancel a timelock
     *
     * Emits a {TimelockCancelled} event
     */
    function cancelTimelock() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {IERC20} from 'lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import '../common/custodian/IPoolCustodian.sol';
import '../common/fees/IFeesController.sol';

/**
 * @title FundsTransfer library
 * @author Atlendis Labs
 * @dev Contains the utilities methods associated to transfers of funds between pool contract, pool custodian and fees controller contracts
 */
library FundsTransfer {
    using SafeERC20 for IERC20;

    /**
     * @dev Withdraw funds from the custodian, apply a fee and transfer the computed amount to a recipient address
     * @param token Address of the ERC20 token of the pool
     * @param custodian Pool custodian contract
     * @param recipient Recipient address
     * @param amount Amount of tokens to send to the sender
     * @param fees Amount of tokens to keep as fees
     */
    function chargedWithdraw(
        address token,
        IPoolCustodian custodian,
        address recipient,
        uint256 amount,
        uint256 fees
    ) external {
        custodian.withdraw(amount + fees, address(this));
        IERC20(token).safeTransfer(recipient, amount);
    }

    /**
     * @dev Deposit funds to the custodian from the sender, apply a fee
     * @param token Address of the ERC20 token of the pool
     * @param custodian Pool custodian contract
     * @param amount Amount of tokens to send to the custodian
     * @param fees Amount of tokens to keep as fees
     */
    function chargedDepositToCustodian(
        address token,
        IPoolCustodian custodian,
        uint256 amount,
        uint256 fees
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount + fees);
        IERC20(token).safeApprove(address(custodian), amount);
        custodian.deposit(amount, address(this));
    }

    /**
     * @dev Approve fees to be pulled by the fees controller
     * @param token Address of the ERC20 token of the pool
     * @param feesController Fees controller contract
     * @param fees Amount of tokens to allow the fees controller to pull
     */
    function approveFees(
        address token,
        IFeesController feesController,
        uint256 fees
    ) external {
        IERC20(token).safeApprove(address(feesController), fees);
    }
}