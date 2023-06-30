// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Optimistic Oracle V3 Interface that callers must use to assert truths about the world.
 */
interface OptimisticOracleV3Interface {
    // Struct grouping together the settings related to the escalation manager stored in the assertion.
    struct EscalationManagerSettings {
        bool arbitrateViaEscalationManager; // False if the DVM is used as an oracle (EscalationManager on True).
        bool discardOracle; // False if Oracle result is used for resolving assertion after dispute.
        bool validateDisputers; // True if the EM isDisputeAllowed should be checked on disputes.
        address assertingCaller; // Stores msg.sender when assertion was made.
        address escalationManager; // Address of the escalation manager (zero address if not configured).
    }

    // Struct for storing properties and lifecycle of an assertion.
    struct Assertion {
        EscalationManagerSettings escalationManagerSettings; // Settings related to the escalation manager.
        address asserter; // Address of the asserter.
        uint64 assertionTime; // Time of the assertion.
        bool settled; // True if the request is settled.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        uint64 expirationTime; // Unix timestamp marking threshold when the assertion can no longer be disputed.
        bool settlementResolution; // Resolution of the assertion (false till resolved).
        bytes32 domainId; // Optional domain that can be used to relate the assertion to others in the escalationManager.
        bytes32 identifier; // UMA DVM identifier to use for price requests in the event of a dispute.
        uint256 bond; // Amount of currency that the asserter has bonded.
        address callbackRecipient; // Address that receives the callback.
        address disputer; // Address of the disputer.
    }

    // Struct for storing cached currency whitelist.
    struct WhitelistedCurrency {
        bool isWhitelisted; // True if the currency is whitelisted.
        uint256 finalFee; // Final fee of the currency.
    }

    /**
     * @notice Returns the default identifier used by the Optimistic Oracle V3.
     * @return The default identifier.
     */
    function defaultIdentifier() external view returns (bytes32);

    /**
     * @notice Fetches information about a specific assertion and returns it.
     * @param assertionId unique identifier for the assertion to fetch information for.
     * @return assertion information about the assertion.
     */
    function getAssertion(bytes32 assertionId) external view returns (Assertion memory);

    /**
     * @notice Asserts a truth about the world, using the default currency and liveness. No callback recipient or
     * escalation manager is enabled. The caller is expected to provide a bond of finalFee/burnedBondPercentage
     * (with burnedBondPercentage set to 50%, the bond is 2x final fee) of the default currency.
     * @dev The caller must approve this contract to spend at least the result of getMinimumBond(defaultCurrency).
     * @param claim the truth claim being asserted. This is an assertion about the world, and is verified by disputers.
     * @param asserter receives bonds back at settlement. This could be msg.sender or
     * any other account that the caller wants to receive the bond at settlement time.
     * @return assertionId unique identifier for this assertion.
     */
    function assertTruthWithDefaults(bytes memory claim, address asserter) external returns (bytes32);

    /**
     * @notice Asserts a truth about the world, using a fully custom configuration.
     * @dev The caller must approve this contract to spend at least bond amount of currency.
     * @param claim the truth claim being asserted. This is an assertion about the world, and is verified by disputers.
     * @param asserter receives bonds back at settlement. This could be msg.sender or
     * any other account that the caller wants to receive the bond at settlement time.
     * @param callbackRecipient if configured, this address will receive a function call assertionResolvedCallback and
     * assertionDisputedCallback at resolution or dispute respectively. Enables dynamic responses to these events. The
     * recipient _must_ implement these callbacks and not revert or the assertion resolution will be blocked.
     * @param escalationManager if configured, this address will control escalation properties of the assertion. This
     * means a) choosing to arbitrate via the UMA DVM, b) choosing to discard assertions on dispute, or choosing to
     * validate disputes. Combining these, the asserter can define their own security properties for the assertion.
     * escalationManager also _must_ implement the same callbacks as callbackRecipient.
     * @param liveness time to wait before the assertion can be resolved. Assertion can be disputed in this time.
     * @param currency bond currency pulled from the caller and held in escrow until the assertion is resolved.
     * @param bond amount of currency to pull from the caller and hold in escrow until the assertion is resolved. This
     * must be >= getMinimumBond(address(currency)).
     * @param identifier UMA DVM identifier to use for price requests in the event of a dispute. Must be pre-approved.
     * @param domainId optional domain that can be used to relate this assertion to others in the escalationManager and
     * can be used by the configured escalationManager to define custom behavior for groups of assertions. This is
     * typically used for "escalation games" by changing bonds or other assertion properties based on the other
     * assertions that have come before. If not needed this value should be 0 to save gas.
     * @return assertionId unique identifier for this assertion.
     */
    function assertTruth(
        bytes memory claim,
        address asserter,
        address callbackRecipient,
        address escalationManager,
        uint64 liveness,
        IERC20 currency,
        uint256 bond,
        bytes32 identifier,
        bytes32 domainId
    ) external returns (bytes32);

    /**
     * @notice Fetches information about a specific identifier & currency from the UMA contracts and stores a local copy
     * of the information within this contract. This is used to save gas when making assertions as we can avoid an
     * external call to the UMA contracts to fetch this.
     * @param identifier identifier to fetch information for and store locally.
     * @param currency currency to fetch information for and store locally.
     */
    function syncUmaParams(bytes32 identifier, address currency) external;

    /**
     * @notice Resolves an assertion. If the assertion has not been disputed, the assertion is resolved as true and the
     * asserter receives the bond. If the assertion has been disputed, the assertion is resolved depending on the oracle
     * result. Based on the result, the asserter or disputer receives the bond. If the assertion was disputed then an
     * amount of the bond is sent to the UMA Store as an oracle fee based on the burnedBondPercentage. The remainder of
     * the bond is returned to the asserter or disputer.
     * @param assertionId unique identifier for the assertion to resolve.
     */
    function settleAssertion(bytes32 assertionId) external;

    /**
     * @notice Settles an assertion and returns the resolution.
     * @param assertionId unique identifier for the assertion to resolve and return the resolution for.
     * @return resolution of the assertion.
     */
    function settleAndGetAssertionResult(bytes32 assertionId) external returns (bool);

    /**
     * @notice Fetches the resolution of a specific assertion and returns it. If the assertion has not been settled then
     * this will revert. If the assertion was disputed and configured to discard the oracle resolution return false.
     * @param assertionId unique identifier for the assertion to fetch the resolution for.
     * @return resolution of the assertion.
     */
    function getAssertionResult(bytes32 assertionId) external view returns (bool);

    /**
     * @notice Returns the minimum bond amount required to make an assertion. This is calculated as the final fee of the
     * currency divided by the burnedBondPercentage. If burn percentage is 50% then the min bond is 2x the final fee.
     * @param currency currency to calculate the minimum bond for.
     * @return minimum bond amount.
     */
    function getMinimumBond(address currency) external view returns (uint256);

    event AssertionMade(
        bytes32 indexed assertionId,
        bytes32 domainId,
        bytes claim,
        address indexed asserter,
        address callbackRecipient,
        address escalationManager,
        address caller,
        uint64 expirationTime,
        IERC20 currency,
        uint256 bond,
        bytes32 indexed identifier
    );

    event AssertionDisputed(bytes32 indexed assertionId, address indexed caller, address indexed disputer);

    event AssertionSettled(
        bytes32 indexed assertionId,
        address indexed bondRecipient,
        bool disputed,
        bool settlementResolution,
        address settleCaller
    );

    event AdminPropertiesSet(IERC20 defaultCurrency, uint64 defaultLiveness, uint256 burnedBondPercentage);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.16;

import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";

// ***************************************
// *    Minimum Viable OOV3 Integration  *
// ***************************************

// This contract shows how to get up and running as quickly as possible with UMA's Optimistic Oracle V3.
// We make a simple data assertion about the real world and let the OOV3 arbitrate the outcome.

contract InsuranceDataCheck {
    // Create an Optimistic Oracle V3 instance at the deployed address on Görli.
    // Optimism mainnet 0x072819Bb43B50E7A251c64411e7aA362ce82803B
    OptimisticOracleV3Interface oov3 =
        OptimisticOracleV3Interface(0x263351499f82C107e540B01F0Ca959843e22464a);

    // Asserted claim. This is some truth statement about the world and can be verified by the network of disputers.
    //bytes public assertedClaim =
    //   bytes("Flight number 90901 was cancelled"); // AC306

    // Each assertion has an associated assertionID that uniquly identifies the assertion. We will store this here.
    bytes32 public assertionId;

    event SentMessage(address recipient, string message);

    // Assert the truth against the Optimistic Asserter. This uses the assertion with defaults method which defaults
    // all values, such as a) challenge window to 120 seconds (2 mins), b) identifier to ASSERT_TRUTH, c) bond currency
    //  to USDC and c) and default bond size to 0 (which means we dont need to worry about approvals in this example).
    function assertTruth(string memory flightId) public {
        string memory assertedClaim = "Was cancelled fligth number ";
        assertionId = oov3.assertTruthWithDefaults(
            bytes(string.concat(assertedClaim, flightId)),
            address(this)
        );
    }

    // Settle the assertion, if it has not been disputed and it has passed the challenge window, and return the result.
    // result
    function settleAndGetAssertionResult() public returns (bool) {
        return oov3.settleAndGetAssertionResult(assertionId);
    }

    // Just return the assertion result. Can only be called once the assertion has been settled.
    function getAssertionResult() external returns (bool) {
        bool result = oov3.getAssertionResult(assertionId);
        string memory message;
        if (result) {
            message = "Flight Was cancelled";
        } else {
            message = "Flight was not cancelled";
        }

        emit SentMessage(msg.sender, message);
        return result;
    }

    // Return the full assertion object contain all information associated with the assertion. Can be called any time.
    function getAssertion()
        public
        view
        returns (OptimisticOracleV3Interface.Assertion memory)
    {
        return oov3.getAssertion(assertionId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./InsuraceDataCheck.sol";

// import "@hyperlane-xyz/core/interfaces/IMailbox.sol";

contract InsuranceArbitrator {
    using SafeERC20 for IERC20;
    // IMailbox inbox; // mumbai 0xCC737a94FecaeC165AbCf12dED095BB13F037685
    // gnosis 0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70
    // bytes32 public lastSender;
    // string public lastMessage;

    InsuranceDataCheck public _insuranceDataCheck;
    // Stores state and parameters of insurance policy.
    struct InsurancePolicy {
        bool claimInitiated; // Claim state preventing simultaneous claim attempts.
        string insuredEvent; // Short description of insured event.
        address insuredAddress; // Beneficiary address eligible for insurance compensation.
        uint256 insuredAmount; // Amount of insurance coverage.
        string fligthId; // Fligth to insure
    }

    // References all active insurance policies by policyId.
    mapping(bytes32 => InsurancePolicy) public insurancePolicies;

    // Maps hash of initiated claims to their policyId.
    // This is used in callback function to potentially pay out the beneficiary.
    mapping(bytes32 => bytes32) public insuranceClaims;

    IERC20 public immutable currency; // Denomination token for insurance coverage and bonding.

    uint256 public constant MAX_EVENT_DESCRIPTION_SIZE = 6; // Insured event description should be concise.

    // Template for constructing ancillary data. The claim would insert insuredEvent in between when requesting
    // through Optimistic Oracle.
    string constant ancillaryDataHead =
        'q:"Had the following insured event occurred as of request timestamp: ';
    string constant ancillaryDataTail = '?"';

    /****************************************
     *                EVENTS                *
     ****************************************/

    event PolicyIssued(
        bytes32 indexed policyId,
        address indexed insurer,
        string insuredEvent,
        address indexed insuredAddress,
        uint256 insuredAmount,
        string fligthInsured
    );
    event ClaimSubmitted(
        uint256 claimTimestamp,
        bytes32 indexed claimId,
        bytes32 indexed policyId
    );
    event ClaimAccepted(bytes32 indexed claimId, bytes32 indexed policyId);
    event ClaimRejected(bytes32 indexed claimId, bytes32 indexed policyId);

    // event ReceivedMessage(uint32 origin, bytes32 sender, bytes message);

    constructor(address _currency) {
        // address _inbox
        currency = IERC20(_currency);
        // inbox = IMailbox(_inbox);
    }

    /**
     * @notice Deposits insuredAmount from the insurer and issues insurance policy to the insured beneficiary.
     * @dev This contract must be approved to spend at least insuredAmount of currency token.
     * @param insuredEvent short description of insured event. Potential verifiers should be able to evaluate whether
     * this event had occurred as of claim time with binary yes/no answer.
     * @param insuredAddress Beneficiary address eligible for insurance compensation.
     * @param insuredAmount Amount of insurance coverage.
     * @param fligthId Fligth to insure.
     * @return policyId Unique identifier of issued insurance policy.
     */
    function issueInsurance(
        string calldata insuredEvent,
        address insuredAddress,
        uint256 insuredAmount,
        string memory fligthId
    ) external returns (bytes32 policyId) {
        require(
            bytes(insuredEvent).length <= MAX_EVENT_DESCRIPTION_SIZE,
            "Event description too long"
        );
        require(insuredAddress != address(0), "Invalid insured address");
        require(insuredAmount > 0, "Amount should be above 0");
        policyId = _getPolicyId(
            block.number,
            insuredEvent,
            insuredAddress,
            insuredAmount
        );
        require(
            insurancePolicies[policyId].insuredAddress == address(0),
            "Policy already issued"
        );

        InsurancePolicy storage newPolicy = insurancePolicies[policyId];
        newPolicy.insuredEvent = insuredEvent;
        newPolicy.insuredAddress = insuredAddress;
        newPolicy.insuredAmount = insuredAmount;
        newPolicy.fligthId = fligthId;

        currency.safeTransferFrom(msg.sender, address(this), insuredAmount);

        emit PolicyIssued(
            policyId,
            msg.sender,
            insuredEvent,
            insuredAddress,
            insuredAmount,
            fligthId
        );
    }

    /**
     * @notice Anyone can submit insurance claim posting oracle bonding. Only one simultaneous claim per insurance
     * policy is allowed.
     * @dev This contract must be approved to spend at least (insuredAmount * oracleBondPercentage + finalFee) of
     * currency token. This call requests and proposes that insuredEvent had ocured through Optimistic Oracle.
     * @param policyId Identifier of claimed insurance policy.
     */
    function submitClaim(bytes32 policyId) external {
        bool result = _insuranceDataCheck.getAssertionResult();
        require(result == true, "Invalid Claim");
        InsurancePolicy storage claimedPolicy = insurancePolicies[policyId];
        require(
            claimedPolicy.insuredAddress != address(0),
            "Insurance not issued"
        );
        require(!claimedPolicy.claimInitiated, "Claim already initiated");
        claimedPolicy.claimInitiated = true;

        bytes memory ancillaryData = abi.encodePacked(
            ancillaryDataHead,
            claimedPolicy.insuredEvent,
            ancillaryDataTail
        );
        bytes32 claimId = _getClaimId(block.timestamp, ancillaryData);
        insuranceClaims[claimId] = policyId;

        uint256 proposerBond = (claimedPolicy.insuredAmount * 0.001e18) / 1e18; // 0.01%
        currency.safeTransferFrom(msg.sender, address(this), proposerBond); // deposita una comision al contrato

        emit ClaimSubmitted(block.timestamp, claimId, policyId);
    }

    // function handle(
    //     uint32 _origin, // 420 Opt mainnet
    //     bytes32 _sender, // OracleDataCheck address
    //     bytes calldata _message // "Flight Was cancelled"
    // ) external {
    //     lastSender = _sender;
    //     lastMessage = string(_message);

    //     emit ReceivedMessage(_origin, _sender, _message);
    // }

    /******************************************
     *           INTERNAL FUNCTIONS           *
     ******************************************/

    function _getPolicyId(
        uint256 blockNumber,
        string memory insuredEvent,
        address insuredAddress,
        uint256 insuredAmount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    blockNumber,
                    insuredEvent,
                    insuredAddress,
                    insuredAmount
                )
            );
    }

    function _getClaimId(
        uint256 timestamp,
        bytes memory ancillaryData
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(timestamp, ancillaryData));
    }
}