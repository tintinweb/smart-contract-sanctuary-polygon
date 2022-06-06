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
pragma solidity 0.8.10;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./utils/Errors.sol";

/// @title The fund mortage vault
contract MortgageVault {
    using SafeERC20 for IERC20;

    IERC20 public mortgageToken;
    uint256 public totalAmount;
    mapping(address => uint256) public fundAmounts;

    event Mortgaged(address indexed fund, uint256 amount);
    event Claimed(address indexed receiver, address indexed fund, uint256 amount);

    constructor(IERC20 token_) {
        mortgageToken = token_;
    }

    /// @notice Mortgage tokens to this contract.
    /// @param amount_ The mortage token amount.
    function mortgage(uint256 amount_) external {
        if (amount_ == 0) return;
        address fund = msg.sender;
        Errors._require(fundAmounts[fund] == 0, Errors.Code.MORTGAGE_VAULT_FUND_MORTGAGED);
        fundAmounts[fund] += amount_;
        totalAmount += amount_;
        mortgageToken.safeTransferFrom(fund, address(this), amount_);
        emit Mortgaged(fund, amount_);
    }

    /// @notice Claim mortgage tokens of msg.sender and send the tokens to receiver
    /// @param receiver_ The receiver address.
    function claim(address receiver_) external {
        address fund = msg.sender;
        uint256 amount = fundAmounts[fund];
        if (amount == 0) return;
        fundAmounts[fund] = 0;
        totalAmount -= amount;
        mortgageToken.safeTransfer(receiver_, amount);
        emit Claimed(receiver_, fund, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error RevertCode(Code errorCode);

    enum Code {
        COMPTROLLER_HALTED, // 0: "Halted"
        COMPTROLLER_BANNED, // 1: "Banned"
        COMPTROLLER_ZERO_ADDRESS, // 2: "Zero address"
        COMPTROLLER_TOS_AND_SIGS_LENGTH_INCONSISTENT, // 3: "tos and sigs length are inconsistent"
        COMPTROLLER_BEACON_IS_INITIALIZED, // 4: "Beacon is initialized"
        COMPTROLLER_DENOMINATIONS_AND_DUSTS_LENGTH_INCONSISTENT, // 5: "denominations and dusts length are inconsistent"
        IMPLEMENTATION_ASSET_LIST_NOT_EMPTY, // 6: "assetList is not empty"
        IMPLEMENTATION_INVALID_DENOMINATION, // 7: "Invalid denomination"
        IMPLEMENTATION_INVALID_MORTGAGE_TIER, // 8: "Mortgage tier not set in comptroller"
        IMPLEMENTATION_PENDING_SHARE_NOT_RESOLVABLE, // 9: "pending share is not resolvable"
        IMPLEMENTATION_PENDING_NOT_START, // 10: "Pending does not start"
        IMPLEMENTATION_PENDING_NOT_EXPIRE, // 11: "Pending does not expire"
        IMPLEMENTATION_INVALID_ASSET, // 12: "Invalid asset"
        IMPLEMENTATION_INSUFFICIENT_TOTAL_VALUE_FOR_EXECUTION, // 13: "Insufficient total value for execution"
        FUND_PROXY_FACTORY_INVALID_CREATOR, // 14: "Invalid creator"
        FUND_PROXY_FACTORY_INVALID_DENOMINATION, // 15: "Invalid denomination"
        FUND_PROXY_FACTORY_INVALID_MORTGAGE_TIER, // 16: "Mortgage tier not set in comptroller"
        FUND_PROXY_STORAGE_UTILS_INVALID_DENOMINATION, // 17: "Invalid denomination"
        FUND_PROXY_STORAGE_UTILS_UNKNOWN_OWNER, // 18: "Unknown owner"
        FUND_PROXY_STORAGE_UTILS_WRONG_ALLOWANCE, // 19: "Wrong allowance"
        FUND_PROXY_STORAGE_UTILS_IS_NOT_ZERO, // 20: "Is not zero value or address "
        FUND_PROXY_STORAGE_UTILS_IS_ZERO, // 21: "Is zero value or address"
        MORTGAGE_VAULT_FUND_MORTGAGED, // 22: "Fund mortgaged"
        SHARE_TOKEN_INVALID_FROM, // 23: "Invalid from"
        SHARE_TOKEN_INVALID_TO, // 24: "Invalid to"
        TASK_EXECUTOR_TOS_AND_DATAS_LENGTH_INCONSISTENT, // 25: "tos and datas length inconsistent"
        TASK_EXECUTOR_TOS_AND_CONFIGS_LENGTH_INCONSISTENT, // 26: "tos and configs length inconsistent"
        TASK_EXECUTOR_INVALID_COMPTROLLER_DELEGATE_CALL, // 27: "Invalid comptroller delegate call"
        TASK_EXECUTOR_INVALID_COMPTROLLER_CONTRACT_CALL, // 28: "Invalid comptroller contract call"
        TASK_EXECUTOR_INVALID_DEALING_ASSET, // 29: "Invalid dealing asset"
        TASK_EXECUTOR_REFERENCE_TO_OUT_OF_LOCALSTACK, // 30: "Reference to out of localStack"
        TASK_EXECUTOR_RETURN_NUM_AND_PARSED_RETURN_NUM_NOT_MATCHED, // 31: "Return num and parsed return num not matched"
        TASK_EXECUTOR_ILLEGAL_LENGTH_FOR_PARSE, // 32: "Illegal length for _parse"
        TASK_EXECUTOR_STACK_OVERFLOW, // 33: "Stack overflow"
        TASK_EXECUTOR_INVALID_INITIAL_ASSET, // 34: "Invalid initial asset"
        TASK_EXECUTOR_NON_ZERO_QUOTA, // 35: "Quota is not zero"
        AFURUCOMBO_DUPLICATED_TOKENSOUT, // 36: "Duplicated tokensOut"
        AFURUCOMBO_REMAINING_TOKENS, // 37: "Furucombo has remaining tokens"
        AFURUCOMBO_TOKENS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 38: "Token length != amounts length"
        AFURUCOMBO_INVALID_COMPTROLLER_HANDLER_CALL, // 39: "Invalid comptroller handler call"
        CHAINLINK_ASSETS_AND_AGGREGATORS_INCONSISTENT, // 40: "assets.length == aggregators.length"
        CHAINLINK_ZERO_ADDRESS, // 41: "Zero address"
        CHAINLINK_EXISTING_ASSET, // 42: "Existing asset"
        CHAINLINK_NON_EXISTENT_ASSET, // 43: "Non-existent asset"
        CHAINLINK_INVALID_PRICE, // 44: "Invalid price"
        CHAINLINK_STALE_PRICE, // 45: "Stale price"
        ASSET_REGISTRY_UNREGISTERED, // 46: "Unregistered"
        ASSET_REGISTRY_BANNED_RESOLVER, // 47: "Resolver has been banned"
        ASSET_REGISTRY_ZERO_RESOLVER_ADDRESS, // 48: "Resolver zero address"
        ASSET_REGISTRY_ZERO_ASSET_ADDRESS, // 49: "Asset zero address"
        ASSET_REGISTRY_REGISTERED_RESOLVER, // 50: "Resolver is registered"
        ASSET_REGISTRY_NON_REGISTERED_RESOLVER, // 51: "Asset not registered"
        ASSET_REGISTRY_NON_BANNED_RESOLVER, // 52: "Resolver is not banned"
        ASSET_ROUTER_ASSETS_AND_AMOUNTS_LENGTH_INCONSISTENT, // 53: "assets length != amounts length"
        ASSET_ROUTER_NEGATIVE_VALUE, // 54: "Negative value"
        RESOLVER_ASSET_VALUE_NEGATIVE, // 55: "Resolver's asset value < 0"
        RESOLVER_ASSET_VALUE_POSITIVE, // 56: "Resolver's asset value > 0"
        RCURVE_STABLE_ZERO_ASSET_ADDRESS, // 57: "Zero asset address"
        RCURVE_STABLE_ZERO_POOL_ADDRESS, // 58: "Zero pool address"
        RCURVE_STABLE_ZERO_VALUED_ASSET_ADDRESS, // 59: "Zero valued asset address"
        RCURVE_STABLE_VALUED_ASSET_DECIMAL_NOT_MATCH_VALUED_ASSET, // 60: "Valued asset decimal not match valued asset"
        RCURVE_STABLE_POOL_INFO_IS_NOT_SET, // 61: "Pool info is not set"
        ASSET_MODULE_DIFFERENT_ASSET_REMAINING, // 62: "Different asset remaining"
        ASSET_MODULE_FULL_ASSET_CAPACITY, // 63: "Full Asset Capacity"
        MANAGEMENT_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_FUND_BASE, // 64: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CAN_NOT_CRYSTALLIZED_YET, // 65: "Can not crystallized yet"
        PERFORMANCE_FEE_MODULE_TIME_BEFORE_START, // 66: "Time before start"
        PERFORMANCE_FEE_MODULE_FEE_RATE_SHOULD_BE_LESS_THAN_BASE, // 67: "Fee rate should be less than 100%"
        PERFORMANCE_FEE_MODULE_CRYSTALLIZATION_PERIOD_TOO_SHORT, // 68: "Crystallization period too short"
        SHARE_MODULE_SHARE_AMOUNT_TOO_LARGE, // 69: "The requesting share amount is greater than total share amount"
        SHARE_MODULE_PURCHASE_ZERO_BALANCE, // 70: "The purchased balance is zero"
        SHARE_MODULE_PURCHASE_ZERO_SHARE, // 71: "The share purchased need to greater than zero"
        SHARE_MODULE_REDEEM_ZERO_SHARE, // 72: "The redeem share is zero"
        SHARE_MODULE_INSUFFICIENT_SHARE, // 73: "Insufficient share amount"
        SHARE_MODULE_REDEEM_IN_PENDING_WITHOUT_PERMISSION, // 74: "Redeem in pending without permission"
        SHARE_MODULE_PENDING_ROUND_INCONSISTENT, // 75: "user pending round and current pending round are inconsistent"
        SHARE_MODULE_PENDING_REDEMPTION_NOT_CLAIMABLE // 76: "Pending redemption is not claimable"
    }

    function _require(bool condition_, Code errorCode_) internal pure {
        if (!condition_) revert RevertCode(errorCode_);
    }

    function _revertMsg(string memory functionName_, string memory reason_) internal pure {
        revert(string(abi.encodePacked(functionName_, ": ", reason_)));
    }

    function _revertMsg(string memory functionName_) internal pure {
        _revertMsg(functionName_, "Unspecified");
    }
}