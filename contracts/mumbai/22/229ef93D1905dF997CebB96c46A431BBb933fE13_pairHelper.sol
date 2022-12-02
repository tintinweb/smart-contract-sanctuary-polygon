// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e9");
        return a % b;
    }
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//interface IAocoRouter01 {
//    function factory() external pure returns (address);
//
//    function WETH() external pure returns (address);
//
//    // function addLiquidity(
//    //     address tokenA,
//    //     address tokenB,
//    //     uint amountADesired,
//    //     uint amountBDesired,
//    //     uint amountAMin,
//    //     uint amountBMin,
//    //     address to,
//    //     uint deadline
//    // ) external returns (uint amountA, uint amountB, uint liquidity);
//
//    // function addLiquidityETH(
//    //     address token,
//    //     uint amountTokenDesired,
//    //     uint amountTokenMin,
//    //     uint amountETHMin,
//    //     address to,
//    //     uint deadline
//    // ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
//
//    // function removeLiquidity(
//    //     address tokenA,
//    //     address tokenB,
//    //     uint liquidity,
//    //     uint amountAMin,
//    //     uint amountBMin,
//    //     address to,
//    //     uint deadline
//    // ) external returns (uint amountA, uint amountB);
//
//    // function removeLiquidityETH(
//    //     address token,
//    //     uint liquidity,
//    //     uint amountTokenMin,
//    //     uint amountETHMin,
//    //     address to,
//    //     uint deadline
//    // ) external returns (uint amountToken, uint amountETH);
//
//    // function removeLiquidityWithPermit(
//    //     address tokenA,
//    //     address tokenB,
//    //     uint liquidity,
//    //     uint amountAMin,
//    //     uint amountBMin,
//    //     address to,
//    //     uint deadline,
//    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
//    // ) external returns (uint amountA, uint amountB);
//
//    // function removeLiquidityETHWithPermit(
//    //     address token,
//    //     uint liquidity,
//    //     uint amountTokenMin,
//    //     uint amountETHMin,
//    //     address to,
//    //     uint deadline,
//    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
//    // ) external returns (uint amountToken, uint amountETH);
//
//    function swapExactTokensForTokens(
//        uint amountIn,
//        uint amountOutMin,
//        address[] calldata path,
//        address to,
//        uint deadline
//    ) external returns (uint[] memory amounts);
//
//    function swapTokensForExactTokens(
//        uint amountOut,
//        uint amountInMax,
//        address[] calldata path,
//        address to,
//        uint deadline
//    ) external returns (uint[] memory amounts);
//
//    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
//    external
//    payable
//    returns (uint[] memory amounts);
//
//    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
//    external
//    returns (uint[] memory amounts);
//
//    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
//    external
//    returns (uint[] memory amounts);
//
//    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
//    external
//    payable
//    returns (uint[] memory amounts);
//
//    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
//
//    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountOut);
//
//    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountIn);
//
//    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
//
//    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
//}

interface IAocoRouter02 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);

    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    //    function swapExactETHForTokensSupportingFeeOnTransferTokens(
    //        uint amountOutMin,
    //        address[] calldata path,
    //        address to,
    //        uint deadline
    //    ) external payable;
    //
    //    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    //        uint amountIn,
    //        uint amountOutMin,
    //        address[] calldata path,
    //        address to,
    //        uint deadline
    //    ) external;
}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

interface USDTPool {
    function userInfoList(address _user) external view returns (bool _canClaim, uint256 _maxAmount);

    function claimUSDT(address _user, uint256 _amount) external;

    function USDT() external view returns (IERC20);

    function swapRate() external view returns (uint256);

    function swapAllRate() external view returns (uint256);

    function getYearMonthDay(uint256 _timestamp) external view returns (uint256);
}

contract swapHelperDiyTask2 is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;
    mapping(bytes32 => uint256) public lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) public lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => txItem)) public txHistoryList;

    struct txItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct swapTokenItem {
        uint256 startGas;
        uint256 swapAmount;
        uint256 tokenAmount;
        address swapInToken;
        address swapOutToken;
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
        uint256 spendSwapInToken;
        uint256 gasUsed;
    }

    struct taskDataItem {
        address _execAddress;
        bytes _execDataOrSelector;
        ModuleData _moduleData;
        address _feeToken;
        bool _status;
        string _taskName;
        uint256[] _start_end_Time;
        uint256[] _timeList;
        uint256[] _timeIntervalList;
        uint256[] _swapAmountList;
    }

    struct taskConfig {
        IAocoRouter02 _routerAddress;
        address _owner;
        address[] _swapRouter;
        address[] _swapRouter2;
        uint256 _interval;
        uint256 _taskExTimes;
        uint256 _index;
        uint256 _maxtxAmount;
        uint256 _maxSpendTokenAmount;
        bytes32 _md5;
        taskDataItem _taskData;
    }

    struct createTaskItem {
        bytes32 _md5;
        bytes _execData;
        bytes32 _taskID;
        ModuleData _moduleData;
        taskConfig _taskConfig;
    }

    event CounterTaskCreated(uint256 _time, address _user, uint256 _taskAmount, bytes32 _taskId);
    event swapToenEvent(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _fee, uint256 _spendSwapInToken, uint256 _timestamp, address _user);
    event swapToenTaskEvent(uint256 _index, address _user, bytes32 _md5, bytes32 _taskID);

    modifier onlyEditer(bytes32 _taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y._owner, "e003");
        _;
    }

    modifier onlyTime(bytes32 _md5) {
        taskConfig memory y = taskConfigList[md5TaskList[_md5]];
        require(block.timestamp >= (lastExecutedTimeList[_md5]).add(y._taskData._timeIntervalList[lastTimeIntervalIndexList[md5TaskList[_md5]]]), "m001");
        require(getInTimeZone(y._taskData._start_end_Time, y._taskData._timeList), "m002");
        _;
    }

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        USDTPool _USDTPoolAddress
    ) OpsTaskCreator(_ops, _fundsOwner){
        setDefaultSwapInfo(_approveAmount);
        setUSDTPoolAddress(_USDTPoolAddress);
    }

    function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
        approveAmount = _approveAmount;
    }

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress) public onlyOwner {
        USDTPoolAddress = _USDTPoolAddress;
    }

    function setSwapInfo(
        IAocoRouter02 _routerAddress,
        address[] memory _swapRouter,
        address[] memory _swapRouter2
    ) private {
        require(_swapRouter[0] == address(USDTPoolAddress.USDT()) && _swapRouter2[_swapRouter2.length - 1] == address(USDTPoolAddress.USDT()), "e001");
        require(_swapRouter2[0] != address(USDTPoolAddress.USDT()) && _swapRouter[_swapRouter2.length - 1] != address(USDTPoolAddress.USDT()), "e002");
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1], "e003");
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1], "e004");
        IERC20(_swapRouter[0]).approve(address(_routerAddress), approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), approveAmount);
    }


    function createTask(
        string memory _taskName,
        IAocoRouter02 _routerAddress,
        address[] memory _swapRouter,
        address[] memory _swapRouter2,
        uint256 _interval,
        uint256[] memory _start_end_Time,
        uint256[] memory _timeList,
        uint256[] memory _timeIntervalList,
        uint256[] memory _swapAmountList,
        uint256 _maxtxAmount,
        uint256 _maxSpendTokenAmount
    ) external payable {
        createTaskItem memory _createTaskItem = new createTaskItem[](1)[0];
        setSwapInfo(_routerAddress, _swapRouter, _swapRouter2);
        _createTaskItem._md5 = keccak256(abi.encodePacked(_taskName, block.timestamp, block.difficulty, msg.sender, _start_end_Time));
        require(!md5List[_createTaskItem._md5], "e001");
        md5List[_createTaskItem._md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        _createTaskItem._execData = abi.encodeCall(this.swapToken, (msg.sender, _createTaskItem._md5));
        if (_interval <= 20) {
            _createTaskItem._moduleData = ModuleData({
            modules : new Module[](1),
            args : new bytes[](1)
            });
            _createTaskItem._moduleData.modules[0] = Module.PROXY;
            _createTaskItem._moduleData.args[0] = _proxyModuleArg();
        } else {
            _createTaskItem._moduleData = ModuleData({
            modules : new Module[](2),
            args : new bytes[](2)
            });
            _createTaskItem._moduleData.modules[0] = Module.TIME;
            _createTaskItem._moduleData.modules[1] = Module.PROXY;
            _createTaskItem._moduleData.args[0] = _timeModuleArg(block.timestamp, _interval);
            _createTaskItem._moduleData.args[1] = _proxyModuleArg();

        }
        _createTaskItem._taskID = _createTask(address(this), _createTaskItem._execData, _createTaskItem._moduleData, ETH);
        taskList[taskAmount] = _createTaskItem._taskID;
        userTaskList[msg.sender].push(_createTaskItem._taskID);
        md5TaskList[_createTaskItem._md5] = _createTaskItem._taskID;
        _createTaskItem._taskConfig = new taskConfig[](1)[0];
        _createTaskItem._taskConfig._routerAddress = _routerAddress;
        _createTaskItem._taskConfig._owner = msg.sender;
        _createTaskItem._taskConfig._swapRouter = _swapRouter;
        _createTaskItem._taskConfig._swapRouter2 = _swapRouter2;
        _createTaskItem._taskConfig._interval = _interval;
        _createTaskItem._taskConfig._taskExTimes = 0;
        _createTaskItem._taskConfig._index = taskAmount;
        _createTaskItem._taskConfig._maxtxAmount = _maxtxAmount;
        _createTaskItem._taskConfig._maxSpendTokenAmount = _maxSpendTokenAmount;
        _createTaskItem._taskConfig._md5 = _createTaskItem._md5;
        _createTaskItem._taskConfig._taskData._execAddress = address(this);
        _createTaskItem._taskConfig._taskData._execDataOrSelector = _createTaskItem._execData;
        _createTaskItem._taskConfig._taskData._moduleData = _createTaskItem._moduleData;
        _createTaskItem._taskConfig._taskData._feeToken = ETH;
        _createTaskItem._taskConfig._taskData._status = true;
        _createTaskItem._taskConfig._taskData._taskName = _taskName;
        _createTaskItem._taskConfig._taskData._start_end_Time = _start_end_Time;
        _createTaskItem._taskConfig._taskData._timeList = _timeList;
        _createTaskItem._taskConfig._taskData._timeIntervalList = _timeIntervalList;
        _createTaskItem._taskConfig._taskData._swapAmountList = _swapAmountList;
        taskConfigList[_createTaskItem._taskID] = _createTaskItem._taskConfig;
        emit CounterTaskCreated(block.timestamp, msg.sender, taskAmount, _createTaskItem._taskID);
        taskAmount = taskAmount.add(1);
    }

    function editTaskSwapAmountList(bytes32 _taskID, uint256[] memory _swapAmountList) external onlyEditer(_taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        y._taskData._swapAmountList = _swapAmountList;
        lastSwapAmountIndexList[_taskID] = 0;
    }

    //    function editTaskInterval(bytes32 _taskID, uint256 _interval) external onlyEditer(_taskID) {
    //        taskConfig storage y = taskConfigList[_taskID];
    //        y._interval = _interval;
    //    }

    function editTaskStartEndTime(bytes32 _taskID, uint256[] memory _start_end_Time) external onlyEditer(_taskID) {
        require((_start_end_Time.length == 2) && (_start_end_Time[1] > _start_end_Time[0]), "e001");
        taskConfig storage y = taskConfigList[_taskID];
        y._taskData._start_end_Time = _start_end_Time;
    }

    function editTaskTimeList(bytes32 _taskID, uint256[] memory _timeList) external onlyEditer(_taskID) {
        require(_timeList.length % 2 == 0, "e001");
        taskConfig storage y = taskConfigList[_taskID];
        y._taskData._timeList = _timeList;
    }

    function editTaskTimeIntervalList(bytes32 _taskID, uint256[] memory _timeIntervalList) external onlyEditer(_taskID) {
        require(_timeIntervalList.length > 0, "e001");
        taskConfig storage y = taskConfigList[_taskID];
        y._taskData._timeIntervalList = _timeIntervalList;
        lastTimeIntervalIndexList[_taskID] = 0;
    }

    function editTaskLimit(bytes32 _taskID, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount) external onlyEditer(_taskID) {
        require(_maxtxAmount > 0, "e001");
        require(_maxSpendTokenAmount > 0, "e002");
        taskConfig storage y = taskConfigList[_taskID];
        y._maxtxAmount = _maxtxAmount;
        y._maxSpendTokenAmount = _maxSpendTokenAmount;
    }

    function getInTimeZone(uint256[] memory _start_end_Time, uint256[] memory _timeList) public view returns (bool _inTimeZone) {
        _inTimeZone = false;
        uint256 all = (block.timestamp + 3600 * 8) % (3600 * 24);
        uint256 TimeListLength = _timeList.length / 2;
        for (uint256 i = 0; i < TimeListLength; i++) {
            if (all >= _timeList[i * 2] && all < _timeList[i * 2 + 1] && block.timestamp >= _start_end_Time[0] && block.timestamp <= _start_end_Time[1]) {
                _inTimeZone = true;
                break;
            }
        }
    }

    function swapToken(address _user, bytes32 _md5) external onlyDedicatedMsgSender onlyTime(_md5) {
        //bytes32 taskID = md5TaskList[_md5];
        uint256 day = USDTPoolAddress.getYearMonthDay(block.timestamp);
        taskConfig storage y = taskConfigList[md5TaskList[_md5]];
        swapTokenItem memory x = new swapTokenItem[](1)[0];
        x.startGas = gasleft();
        x.swapInToken = y._swapRouter[0];
        x.swapOutToken = y._swapRouter[1];
        x.swapAmount = y._taskData._swapAmountList[lastSwapAmountIndexList[md5TaskList[_md5]]];
        x.tokenAmount = x.swapAmount;
        require(txHistoryList[md5TaskList[_md5]][day]._totalTx.add(1) <= y._maxtxAmount, "p001");
        require(txHistoryList[md5TaskList[_md5]][day]._totalSpendTokenAmount.add(x.tokenAmount * 2) <= y._maxSpendTokenAmount, "p002");
        txHistoryList[md5TaskList[_md5]][day]._totalTx = txHistoryList[md5TaskList[_md5]][day]._totalTx.add(1);
        txHistoryList[md5TaskList[_md5]][day]._totalSpendTokenAmount = txHistoryList[md5TaskList[_md5]][day]._totalSpendTokenAmount.add(x.tokenAmount * 2);
        if (x.tokenAmount == 0) {
            return;
        } else {
            if (address(USDTPoolAddress.USDT()) == x.swapInToken) {
                USDTPoolAddress.claimUSDT(_user, x.tokenAmount);
            }
            if (IERC20(x.swapInToken).allowance(address(this), address(y._routerAddress)) < x.tokenAmount) {
                IERC20(x.swapInToken).approve(address(y._routerAddress), approveAmount);
            }
            x.balanceOfIn0 = IERC20(x.swapInToken).balanceOf(address(this));
            x.balanceOfOut0 = IERC20(x.swapOutToken).balanceOf(address(this));
            y._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.tokenAmount, 0, y._swapRouter, address(this), block.timestamp);
            x.balanceOfOut1 = IERC20(x.swapOutToken).balanceOf(address(this));
            x.tokenAmount = x.balanceOfOut1.sub(x.balanceOfOut0);
            if (IERC20(x.swapOutToken).allowance(address(this), address(y._routerAddress)) < x.tokenAmount) {
                IERC20(x.swapOutToken).approve(address(y._routerAddress), approveAmount);
            }
            y._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.tokenAmount, 0, y._swapRouter2, address(this), block.timestamp);
            x.balanceOfIn1 = IERC20(x.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x.balanceOfIn0.sub(x.balanceOfIn1);
            x.gasUsed = x.startGas - gasleft();
            emit swapToenTaskEvent(y._index, _user, y._md5, md5TaskList[_md5]);
            (uint256 fee, address feeToken) = _getFeeDetails();
            _transfer(fee, feeToken);
            emit swapToenEvent(tx.origin, msg.sender, x.gasUsed, fee, x.spendSwapInToken, block.timestamp, _user);
            require(userInfoList[_user].ethAmount >= fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(fee);
            y._taskExTimes = y._taskExTimes.add(1);
            if (address(USDTPoolAddress.USDT()) == x.swapInToken) {
                uint256 poolFee = x.swapAmount.mul(USDTPoolAddress.swapRate()).div(USDTPoolAddress.swapAllRate());
                uint256 allFee = x.spendSwapInToken.add(poolFee);
                require(userInfoList[_user].usdtAmount >= allFee, "m003");
                userInfoList[_user].usdtAmount = userInfoList[_user].usdtAmount.sub(allFee);
                IERC20(x.swapInToken).transfer(address(USDTPoolAddress), x.swapAmount.add(poolFee));
            }
        }
        lastExecutedTimeList[_md5] = block.timestamp;
        lastTimeIntervalIndexList[md5TaskList[_md5]] = lastTimeIntervalIndexList[md5TaskList[_md5]].add(1);
        if (lastTimeIntervalIndexList[md5TaskList[_md5]] >= y._taskData._timeIntervalList.length) {
            lastTimeIntervalIndexList[md5TaskList[_md5]] = 0;
        }
        lastSwapAmountIndexList[md5TaskList[_md5]] = lastSwapAmountIndexList[md5TaskList[_md5]].add(1);
        if (lastSwapAmountIndexList[md5TaskList[_md5]] >= y._taskData._swapAmountList.length) {
            lastSwapAmountIndexList[md5TaskList[_md5]] = 0;
        }
    }

    function depositUSDT(uint256 _amount) external {
        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_amount);
    }

    function withdrawUSDT(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].usdtAmount, "e001");
        USDTPoolAddress.USDT().transfer(msg.sender, _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_amount);
    }

    function depositEth() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdrawETH(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].ethAmount, "e001");
        payable(msg.sender).transfer(_amount);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_amount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function cancelTask(bytes32 _taskID) external onlyEditer(_taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        require(y._taskData._status, "e002");
        _cancelTask(_taskID);
        y._taskData._status = false;
    }

    function restartTask(bytes32 _taskID) external onlyEditer(_taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        require(!y._taskData._status, "e002");
        _createTask(y._taskData._execAddress, y._taskData._execDataOrSelector, y._taskData._moduleData, y._taskData._feeToken);
        y._taskData._status = true;
    }

    function getUserTaskList(address _user) external view returns (bytes32[] memory) {
        return userTaskList[_user];
    }

    function getUserTaskListNum(address _user) external view returns (uint256) {
        return userTaskList[_user].length;
    }

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory taskIdList) {
        taskIdList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            taskIdList[i] = userTaskList[_user][_indexList[i]];
        }
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e9");
        return a % b;
    }
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAocoRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

interface USDTPool {
    function userInfoList(address _user) external view returns (bool _canClaim, uint256 _maxAmount);

    function claimUSDT(address _user, uint256 _amount) external;

    function USDT() external view returns (IERC20);

    function swapRate() external view returns (uint256);

    function swapAllRate() external view returns (uint256);

    function getYearMonthDay(uint256 _timestamp) external view returns (uint256);
}

contract swapHelperDiyTaskPlus is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;
    mapping(bytes32 => uint256) public lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) public lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => txItem)) public txHistoryList;

    struct txItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct tccItem {
        string _taskName;
        IAocoRouter02 _routerAddress;
        address[] _swapRouter;
        address[] _swapRouter2;
        uint256 _interval;
        uint256[] _start_end_Time;
        uint256[] _timeList;
        uint256[] _timeIntervalList;
        uint256[] _swapAmountList;
        uint256 _maxtxAmount;
        uint256 _maxSpendTokenAmount;
        uint256 _maxFeePerTx;
    }

    struct tcdItem {
        uint256 _index;
        address _owner;
        address _execAddress;
        bytes _execDataOrSelector;
        ModuleData _moduleData;
        address _feeToken;
        bool _status;
        uint256 _taskExTimes;
        bytes32 _md5;
        bytes32 _taskID;
    }

    struct taskConfig {
        tccItem tcc;
        tcdItem tcd;
    }

    struct gasItem {
        uint256 startGas;
        uint256 gasUsed;
    }

    struct balanceItem {
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
    }

    struct TokenItem {
        address swapInToken;
        address swapOutToken;
    }

    struct feeItem {
        uint256 poolFee;
        uint256 allFee;
    }

    struct feeItem2 {
        uint256 fee;
        address feeToken;
    }

    struct swapTokenItem {
        uint256 day;
        uint256 claimAmount;
        uint256 swapInAmount;
        uint256 spendSwapInToken;
        bytes32 taskID;
        gasItem _gasItem;
        TokenItem _TokenItem;
        balanceItem _balanceItem;
        feeItem _feeItem;
        feeItem2 _feeItem2;
    }

    event tc(uint256 _time, address _user, uint256 _taskAmount, bytes32 _taskId);
    event swap1(uint256 _index, address _user, bytes32 _md5, bytes32 _taskID);
    event swap2(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _fee, uint256 _spendSwapInToken, uint256 _timestamp, address _user);


    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        USDTPool _USDTPoolAddress
    ) OpsTaskCreator(_ops, _fundsOwner){
        setDefaultSwapInfo(_approveAmount);
        setUSDTPoolAddress(_USDTPoolAddress);
    }

    function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
        approveAmount = _approveAmount;
    }

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress) public onlyOwner {
        USDTPoolAddress = _USDTPoolAddress;
    }

    function setSwapInfo(
        IAocoRouter02 _routerAddress,
        address[] memory _swapRouter,
        address[] memory _swapRouter2
    ) private {
        require(_swapRouter[0] == address(USDTPoolAddress.USDT()) && _swapRouter2[_swapRouter2.length - 1] == address(USDTPoolAddress.USDT()), "e04");
        require(_swapRouter2[0] != address(USDTPoolAddress.USDT()) && _swapRouter[_swapRouter2.length - 1] != address(USDTPoolAddress.USDT()), "e05");
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1], "e06");
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1], "e07");
        IERC20(_swapRouter[0]).approve(address(_routerAddress), approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), approveAmount);
    }

    function createTask(
        tccItem calldata _tcc
    ) external payable {
        setSwapInfo(_tcc._routerAddress, _tcc._swapRouter, _tcc._swapRouter2);
        bytes32 md5 = keccak256(abi.encodePacked(_tcc._taskName, block.timestamp, block.difficulty, msg.sender, _tcc._start_end_Time));
        require(!md5List[md5], "e08");
        md5List[md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        bytes memory execData = abi.encodeCall(this.swapToken, (msg.sender, md5));
        ModuleData memory moduleData;
        if (_tcc._interval <= 20) {
            moduleData = ModuleData({
            modules : new Module[](1),
            args : new bytes[](1)
            });
            moduleData.modules[0] = Module.PROXY;
            moduleData.args[0] = _proxyModuleArg();
        } else {
            moduleData = ModuleData({
            modules : new Module[](2),
            args : new bytes[](2)
            });
            moduleData.modules[0] = Module.TIME;
            moduleData.modules[1] = Module.PROXY;
            moduleData.args[0] = _timeModuleArg(block.timestamp, _tcc._interval);
            moduleData.args[1] = _proxyModuleArg();
        }
        bytes32 taskID = _createTask(address(this), execData, moduleData, ETH);
        taskList[taskAmount] = taskID;
        userTaskList[msg.sender].push(taskID);
        md5TaskList[md5] = taskID;
        taskConfig memory _taskConfig = new taskConfig[](1)[0];
        _taskConfig.tcc = tccItem({
        _taskName : _tcc._taskName,
        _routerAddress : _tcc._routerAddress,
        _swapRouter : _tcc._swapRouter,
        _swapRouter2 : _tcc._swapRouter2,
        _interval : _tcc._interval,
        _start_end_Time : _tcc._start_end_Time,
        _timeList : _tcc._timeList,
        _timeIntervalList : _tcc._timeIntervalList,
        _swapAmountList : _tcc._swapAmountList,
        _maxtxAmount : _tcc._maxtxAmount,
        _maxSpendTokenAmount : _tcc._maxSpendTokenAmount,
        _maxFeePerTx : _tcc._maxFeePerTx
        });
        _taskConfig.tcd = tcdItem({
        _index : taskAmount,
        _owner : msg.sender,
        _execAddress : address(this),
        _execDataOrSelector : execData,
        _moduleData : moduleData,
        _feeToken : ETH,
        _status : true,
        _taskExTimes : 0,
        _md5 : md5,
        _taskID : taskID
        });
        taskConfigList[taskID] = _taskConfig;
        emit tc(block.timestamp, msg.sender, taskAmount, taskID);
        taskAmount = taskAmount.add(1);
    }

    function editTaskSwapAmountList(bytes32 _taskID, uint256[] memory _swapAmountList) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._swapAmountList = _swapAmountList;
        lastSwapAmountIndexList[_taskID] = 0;
    }

    function editTaskStartEndTime(bytes32 _taskID, uint256[] memory _start_end_Time) external {
        require((_start_end_Time.length == 2) && (_start_end_Time[1] > _start_end_Time[0]), "e09");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._start_end_Time = _start_end_Time;
    }

    function editTaskTimeList(bytes32 _taskID, uint256[] memory _timeList) external {
        require(_timeList.length % 2 == 0, "e10");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._timeList = _timeList;
    }

    function editTaskTimeIntervalList(bytes32 _taskID, uint256[] memory _timeIntervalList) external {
        require(_timeIntervalList.length > 0, "e11");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._timeIntervalList = _timeIntervalList;
        lastTimeIntervalIndexList[_taskID] = 0;
    }

    function editTaskLimit(bytes32 _taskID, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount, uint256 _maxFeePerTx) external {
        require(_maxtxAmount > 0, "e12");
        require(_maxSpendTokenAmount > 0, "e13");
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        y.tcc._maxtxAmount = _maxtxAmount;
        y.tcc._maxSpendTokenAmount = _maxSpendTokenAmount;
        y.tcc._maxFeePerTx = _maxFeePerTx;
    }

    function getInTimeZone(uint256[] memory _start_end_Time, uint256[] memory _timeList) public view returns (bool _inTimeZone) {
        _inTimeZone = false;
        uint256 all = (block.timestamp + 3600 * 8) % (3600 * 24);
        uint256 TimeListLength = _timeList.length / 2;
        for (uint256 i = 0; i < TimeListLength; i++) {
            if (all >= _timeList[i * 2] && all < _timeList[i * 2 + 1] && block.timestamp >= _start_end_Time[0] && block.timestamp <= _start_end_Time[1]) {
                _inTimeZone = true;
                break;
            }
        }
    }

    function swapToken(address _user, bytes32 _md5) external onlyDedicatedMsgSender {
        swapTokenItem memory x = new swapTokenItem[](1)[0];
        x.day = USDTPoolAddress.getYearMonthDay(block.timestamp);
        x.taskID = md5TaskList[_md5];
        taskConfig storage y = taskConfigList[x.taskID];
        require(block.timestamp >= (lastExecutedTimeList[_md5]).add(y.tcc._timeIntervalList[lastTimeIntervalIndexList[x.taskID]]), "e02");
        require(getInTimeZone(y.tcc._start_end_Time, y.tcc._timeList), "e03");
        x._gasItem.startGas = gasleft();
        x._TokenItem.swapInToken = y.tcc._swapRouter[0];
        x._TokenItem.swapOutToken = y.tcc._swapRouter[1];
        x.claimAmount = y.tcc._swapAmountList[lastSwapAmountIndexList[x.taskID]];
        x.swapInAmount = x.claimAmount;
        require(txHistoryList[x.taskID][x.day]._totalTx.add(1) <= y.tcc._maxtxAmount, "e14");
        require(txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount * 2) <= y.tcc._maxSpendTokenAmount, "e15");
        txHistoryList[x.taskID][x.day]._totalTx = txHistoryList[x.taskID][x.day]._totalTx.add(1);
        txHistoryList[x.taskID][x.day]._totalSpendTokenAmount = txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount * 2);
        if (x.swapInAmount == 0) {
            return;
        } else {
            //            if (address(USDTPoolAddress.USDT()) == x._TokenItem.swapInToken) {
            USDTPoolAddress.claimUSDT(_user, x.claimAmount);
            //            }
            if (IERC20(x._TokenItem.swapInToken).allowance(address(this), address(y.tcc._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapInToken).approve(address(y.tcc._routerAddress), approveAmount);
            }
            x._balanceItem.balanceOfIn0 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            x._balanceItem.balanceOfOut0 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            y.tcc._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.tcc._swapRouter, address(this), block.timestamp);
            x._balanceItem.balanceOfOut1 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            x.swapInAmount = x._balanceItem.balanceOfOut1.sub(x._balanceItem.balanceOfOut0);
            if (IERC20(x._TokenItem.swapOutToken).allowance(address(this), address(y.tcc._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapOutToken).approve(address(y.tcc._routerAddress), approveAmount);
            }
            y.tcc._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.tcc._swapRouter2, address(this), block.timestamp);
            x._balanceItem.balanceOfIn1 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x._balanceItem.balanceOfIn0.sub(x._balanceItem.balanceOfIn1);
            x._gasItem.gasUsed = x._gasItem.startGas - gasleft();
            emit swap1(y.tcd._index, _user, y.tcd._md5, x.taskID);
            (x._feeItem2.fee, x._feeItem2.feeToken) = _getFeeDetails();
            require(x._feeItem2.fee <= y.tcc._maxFeePerTx, "e16");
            txHistoryList[x.taskID][x.day]._totalFee = txHistoryList[x.taskID][x.day]._totalFee.add(x._feeItem2.fee);
            _transfer(x._feeItem2.fee, x._feeItem2.feeToken);
            emit swap2(tx.origin, msg.sender, x._gasItem.gasUsed, x._feeItem2.fee, x.spendSwapInToken, block.timestamp, _user);
            require(userInfoList[_user].ethAmount >= x._feeItem2.fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(x._feeItem2.fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(x._feeItem2.fee);
            y.tcd._taskExTimes = y.tcd._taskExTimes.add(1);
            //            if (address(USDTPoolAddress.USDT()) == x._TokenItem.swapInToken) {
            x._feeItem.poolFee = x.claimAmount.mul(USDTPoolAddress.swapRate()).div(USDTPoolAddress.swapAllRate());
            x._feeItem.allFee = x.spendSwapInToken.add(x._feeItem.poolFee);
            require(userInfoList[_user].usdtAmount >= x._feeItem.allFee, "e17");
            userInfoList[_user].usdtAmount = userInfoList[_user].usdtAmount.sub(x._feeItem.allFee);
            IERC20(x._TokenItem.swapInToken).transfer(address(USDTPoolAddress), x.claimAmount.add(x._feeItem.poolFee));
            //            }
        }
        lastExecutedTimeList[_md5] = block.timestamp;
        lastTimeIntervalIndexList[x.taskID] = lastTimeIntervalIndexList[x.taskID].add(1);
        if (lastTimeIntervalIndexList[x.taskID] >= y.tcc._timeIntervalList.length) {
            lastTimeIntervalIndexList[x.taskID] = 0;
        }
        lastSwapAmountIndexList[x.taskID] = lastSwapAmountIndexList[x.taskID].add(1);
        if (lastSwapAmountIndexList[x.taskID] >= y.tcc._swapAmountList.length) {
            lastSwapAmountIndexList[x.taskID] = 0;
        }
    }

    //    function depositUSDT(uint256 _amount) external {
    //        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _amount);
    //        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_amount);
    //    }
    //
    //    function depositEth() external payable {
    //        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
    //        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    //    }

    //    function withdrawUSDT(uint256 _amount) external {
    //        require(_amount <= userInfoList[msg.sender].usdtAmount, "e18");
    //        USDTPoolAddress.USDT().transfer(msg.sender, _amount);
    //        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_amount);
    //    }
    //
    //    function withdrawETH(uint256 _amount) external {
    //        require(_amount <= userInfoList[msg.sender].ethAmount, "e19");
    //        payable(msg.sender).transfer(_amount);
    //        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_amount);
    //    }

    function deposit(uint256 _usdtAmount) external payable {
        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _usdtAmount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_usdtAmount);
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdraw(uint256 _usdtAmount, uint256 _ethAmount) external {
        require(_usdtAmount <= userInfoList[msg.sender].usdtAmount, "e18");
        require(_ethAmount <= userInfoList[msg.sender].ethAmount, "e19");
        USDTPoolAddress.USDT().transfer(msg.sender, _usdtAmount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_usdtAmount);
        payable(msg.sender).transfer(_ethAmount);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_ethAmount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function cancelTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        require(y.tcd._status, "e20");
        _cancelTask(_taskID);
        y.tcd._status = false;
    }

    function restartTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.tcd._owner, "e01");
        require(!y.tcd._status, "e021");
        _createTask(y.tcd._execAddress, y.tcd._execDataOrSelector, y.tcd._moduleData, y.tcd._feeToken);
        y.tcd._status = true;
    }

    function getUserTaskList(address _user) external view returns (bytes32[] memory) {
        return userTaskList[_user];
    }

    function getUserTaskListNum(address _user) external view returns (uint256) {
        return userTaskList[_user].length;
    }

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory taskIdList) {
        taskIdList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            taskIdList[i] = userTaskList[_user][_indexList[i]];
        }
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}


abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAocoRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB, uint liquidity);

    // function addLiquidityETH(
    //     address token,
    //     uint amountTokenDesired,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB);

    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);

    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB);

    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountETH);

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

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IAocoRouter02 is IAocoRouter01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);

    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

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

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

contract swapHelperTask is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    IAocoRouter02 public routerAddress;
    address[] public swapRouter;
    address[] public swapRouter2;
    uint256 public approveAmount;
    uint256 public taskAmount;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => bool) public callerList;
    mapping(address => uint256) public callerAmountList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => uint256) public taskExTimes;

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct swapCotItem {
        uint256 startGas;
        uint256 _swapIn;
        address swapInToken;
        address swapOutToken;
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
        uint256 spendSwapInToken;
        uint256 gasUsed;
    }

    modifier onlyCaller() {
        require(callerList[msg.sender], "e000");
        _;
    }

    event CounterTaskCreated(uint256 taskAmount, bytes32 taskId, address execAddress, bytes execData, ModuleData moduleData, address feeToken);
    event swapCotE(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _spendSwapInToken, uint256 _timestamp, address _user, bytes32 _md5, bytes32 _taskID);

    constructor(IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2, uint256 _swapAmount, uint256 _approveAmount, address payable _ops, address _fundsOwner) OpsTaskCreator(_ops, _fundsOwner){
        setSwapInfo(_routerAddress, _swapRouter, _swapRouter2, _swapAmount, _approveAmount);
    }

    function setSwapInfo(IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2, uint256 _swapAmount, uint256 _approveAmount) public onlyOwner {
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1]);
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1]);
        routerAddress = _routerAddress;
        swapRouter = _swapRouter;
        swapRouter2 = _swapRouter2;
        approveAmount = _approveAmount;
        IERC20(_swapRouter[0]).approve(address(_routerAddress), _approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), _approveAmount);
        setCallerList(dedicatedMsgSender, _swapAmount, true);
    }

    function createTask(uint256 _INTERVAL, uint256 _salt) external payable {
        bytes32 md5 = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _salt));
        require(!md5List[md5], "e001");
        md5List[md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        bytes memory execData = abi.encodeCall(this.swapCot, (msg.sender, md5));
        ModuleData memory moduleData = ModuleData({
        modules : new Module[](2),
        args : new bytes[](2)
        });
        if (_INTERVAL > 0) {
            //周期性
            moduleData.modules[0] = Module.TIME;
            moduleData.modules[1] = Module.PROXY;
            moduleData.args[0] = _timeModuleArg(block.timestamp, _INTERVAL);
            moduleData.args[1] = _proxyModuleArg();
        } else {
            //一次性
            moduleData.modules[0] = Module.PROXY;
            moduleData.modules[1] = Module.SINGLE_EXEC;
            moduleData.args[0] = _proxyModuleArg();
            moduleData.args[1] = _singleExecModuleArg();
        }
        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        taskList[taskAmount] = id;
        userTaskList[msg.sender].push(id);
        md5TaskList[md5] = id;
        emit CounterTaskCreated(taskAmount, id, address(this), execData, moduleData, ETH);
        taskAmount = taskAmount.add(1);
    }

    function setCallerList(address _user, uint256 _amount, bool _status) public onlyOwner {
        callerList[_user] = _status;
        if (_status) {
            callerAmountList[_user] = _amount;
        } else {
            callerAmountList[_user] = 0;
        }
    }

    function swapCot(address _user, bytes32 _md5) external onlyDedicatedMsgSender {
        swapCotItem memory x = swapCotItem(gasleft(), callerAmountList[msg.sender], swapRouter[0], swapRouter[1], 0, 0, 0, 0, 0, 0);
        if (x._swapIn == 0) {
            return;
        } else {
            if (IERC20(x.swapInToken).allowance(address(this), address(routerAddress)) < x._swapIn) {
                IERC20(x.swapInToken).approve(address(routerAddress), approveAmount);
            }
            x.balanceOfIn0 = IERC20(x.swapInToken).balanceOf(address(this));
            x.balanceOfOut0 = IERC20(x.swapOutToken).balanceOf(address(this));
            routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x._swapIn, 0, swapRouter, address(this), block.timestamp);
            x.balanceOfOut1 = IERC20(x.swapOutToken).balanceOf(address(this));
            x._swapIn = x.balanceOfOut1.sub(x.balanceOfOut0);
            if (IERC20(x.swapOutToken).allowance(address(this), address(routerAddress)) < x._swapIn) {
                IERC20(x.swapOutToken).approve(address(routerAddress), approveAmount);
            }
            routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x._swapIn, 0, swapRouter2, address(this), block.timestamp);
            x.balanceOfIn1 = IERC20(x.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x.balanceOfIn0.sub(x.balanceOfIn1);
            x.gasUsed = x.startGas - gasleft();
            emit swapCotE(tx.origin, msg.sender, x.gasUsed, x.spendSwapInToken, block.timestamp, _user, _md5, md5TaskList[_md5]);
            (uint256 fee, address feeToken) = _getFeeDetails();
            _transfer(fee, feeToken);
            require(userInfoList[_user].ethAmount >= fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(fee);
            taskExTimes[md5TaskList[_md5]] = taskExTimes[md5TaskList[_md5]].add(1);
        }
    }

    function depositEth() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdrawETH() external payable {
        payable(msg.sender).transfer(userInfoList[msg.sender].ethAmount);
        userInfoList[msg.sender].ethAmount = 0;
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/IVNS.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct UserInfo {
    uint256 id;
    uint256 level;
    //index in level
    uint256 levelIndex;
    uint256 firstIdoTime;
    uint256 memberPoints;
    //=0 not initialized
    address parent;
}

interface IVNSCPD {
    function mint(address to, uint256 amount) external;
}

interface IVNSToken {
    function mint(address to, uint256 amount) external;

    function lockIdoAmount(address user, uint256 amount) external;

    function lockAirdropAmount(address user, uint256 amount) external;
}

interface IVNSNFT {
    function mintTo(address to, uint256 num) external returns (uint256);

    function blindBoxTo(address to) external returns (uint256);
}

interface IVNSMemberShip {
    function getUserInfo(address user) external view returns (UserInfo memory);

    function levelRealLength(uint256 level) external view returns (uint256);

    function addUser(address user, address parent) external;

    function addMemberPoints(address user, uint256 points) external;

    function updateLevel(address user) external;
}

interface INFTStakingPool {
    function getStakedAmount(address user) external returns (uint256);
}

interface IStakingPool {
    function stake(
        uint256 poolId,
        uint256 amount,
        address to
    ) external;
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/VNSCPD.sol


pragma solidity ^0.8.4;
contract VNSCPD2 is ERC20, AccessControl, IVNSCPD {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(address => bool) contractWhiteList;

    constructor() ERC20("VNSCPD", "CPD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        _mint(to, amount);
    }

    function setContractWhiteList(address addr, bool state)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractWhiteList[addr] = state;
    }

    function isContractWhiteList(address addr) external view returns (bool) {
        return contractWhiteList[addr];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (to.code.length > 0)
            require(contractWhiteList[to], "not whitelist contract");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
contract a {
    function ff (uint256 _x) public view returns (uint256,uint256,uint256,uint256) {
        uint256 all = (block.number+_x+1)*(block.timestamp-_x-1);
        return (block.number,block.timestamp,all,_x+all%_x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IAocoFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IAocoPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast);
}

contract pairHelper is Ownable {
    address public USDT;
    address public ETH;

    struct configItem {
        address _USDT;
        address _ETH;
    }

    struct returnItem {
        IAocoFactory _factoryAddress;
        uint256 reserve_USDT;
        uint256 reserve_ETH;
    }

    constructor (configItem memory _configItem) {
        setConfig(_configItem);
    }

    function setConfig(configItem memory _configItem) public onlyOwner {
        USDT = _configItem._USDT;
        ETH = _configItem._ETH;
    }

    function getPairInfo(IAocoFactory _factoryAddress, address _token, address _defaultToken) private view returns (uint256) {
        address pair = _factoryAddress.getPair(_token, _defaultToken);
        if (pair == address(0)) {
            return 0;
        }
        address token_ = IAocoPair(pair).token0();
        (uint256 reserve0, uint256 reserve1,) = IAocoPair(pair).getReserves();
        if (token_ == _token) {
            return reserve0;
        } else {
            return reserve1;
        }
        // try IAocoPair(pair).token0() returns(address token_) {
        //     (uint256 reserve0, uint256 reserve1,) = IAocoPair(pair).getReserves();
        //     if (token_ == _token) {
        //         return reserve0;
        //     } else {
        //         return reserve1;
        //     }
        // } catch{
        //     return 0;
        // }
    }

    function getPairInfo2(IAocoFactory _factoryAddress, address _token) private view returns (returnItem memory pairInfo_) {
        pairInfo_ = new returnItem[](1)[0];
        pairInfo_._factoryAddress = _factoryAddress;
        pairInfo_.reserve_USDT = getPairInfo(_factoryAddress, _token, USDT);
        pairInfo_.reserve_ETH = getPairInfo(_factoryAddress, _token, ETH);
    }

    function massGetPairInfo(IAocoFactory[] memory _factoryAddressList, address _token) public view returns (returnItem[] memory pairInfoList_) {
        pairInfoList_ = new returnItem[](_factoryAddressList.length);
        for (uint256 i = 0; i < _factoryAddressList.length; i++) {
            pairInfoList_[i] = getPairInfo2(_factoryAddressList[i], _token);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e9");
        return a % b;
    }
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//interface IAocoRouter01 {
//    function factory() external pure returns (address);
//
//    function WETH() external pure returns (address);
//
//    // function addLiquidity(
//    //     address tokenA,
//    //     address tokenB,
//    //     uint amountADesired,
//    //     uint amountBDesired,
//    //     uint amountAMin,
//    //     uint amountBMin,
//    //     address to,
//    //     uint deadline
//    // ) external returns (uint amountA, uint amountB, uint liquidity);
//
//    // function addLiquidityETH(
//    //     address token,
//    //     uint amountTokenDesired,
//    //     uint amountTokenMin,
//    //     uint amountETHMin,
//    //     address to,
//    //     uint deadline
//    // ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
//
//    // function removeLiquidity(
//    //     address tokenA,
//    //     address tokenB,
//    //     uint liquidity,
//    //     uint amountAMin,
//    //     uint amountBMin,
//    //     address to,
//    //     uint deadline
//    // ) external returns (uint amountA, uint amountB);
//
//    // function removeLiquidityETH(
//    //     address token,
//    //     uint liquidity,
//    //     uint amountTokenMin,
//    //     uint amountETHMin,
//    //     address to,
//    //     uint deadline
//    // ) external returns (uint amountToken, uint amountETH);
//
//    // function removeLiquidityWithPermit(
//    //     address tokenA,
//    //     address tokenB,
//    //     uint liquidity,
//    //     uint amountAMin,
//    //     uint amountBMin,
//    //     address to,
//    //     uint deadline,
//    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
//    // ) external returns (uint amountA, uint amountB);
//
//    // function removeLiquidityETHWithPermit(
//    //     address token,
//    //     uint liquidity,
//    //     uint amountTokenMin,
//    //     uint amountETHMin,
//    //     address to,
//    //     uint deadline,
//    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
//    // ) external returns (uint amountToken, uint amountETH);
//
//    function swapExactTokensForTokens(
//        uint amountIn,
//        uint amountOutMin,
//        address[] calldata path,
//        address to,
//        uint deadline
//    ) external returns (uint[] memory amounts);
//
//    function swapTokensForExactTokens(
//        uint amountOut,
//        uint amountInMax,
//        address[] calldata path,
//        address to,
//        uint deadline
//    ) external returns (uint[] memory amounts);
//
//    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
//    external
//    payable
//    returns (uint[] memory amounts);
//
//    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
//    external
//    returns (uint[] memory amounts);
//
//    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
//    external
//    returns (uint[] memory amounts);
//
//    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
//    external
//    payable
//    returns (uint[] memory amounts);
//
//    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
//
//    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountOut);
//
//    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, address token0, address token1, address factory_) external view returns (uint amountIn);
//
//    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
//
//    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
//}

interface IAocoRouter02 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);

    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    //    function swapExactETHForTokensSupportingFeeOnTransferTokens(
    //        uint amountOutMin,
    //        address[] calldata path,
    //        address to,
    //        uint deadline
    //    ) external payable;
    //
    //    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    //        uint amountIn,
    //        uint amountOutMin,
    //        address[] calldata path,
    //        address to,
    //        uint deadline
    //    ) external;
}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

interface USDTPool {
    function userInfoList(address _user) external view returns (bool _canClaim, uint256 _maxAmount);

    function claimUSDT(address _user, uint256 _amount) external;

    function USDT() external view returns (IERC20);

    function swapRate() external view returns (uint256);

    function swapAllRate() external view returns (uint256);
}

contract swapHelperDiyTask is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct swapCotItem {
        uint256 startGas;
        uint256 _swapIn;
        address swapInToken;
        address swapOutToken;
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
        uint256 spendSwapInToken;
        uint256 gasUsed;
    }

    struct taskDataItem {
        address _execAddress;
        bytes _execDataOrSelector;
        ModuleData _moduleData;
        address _feeToken;
        bool _status;
        string _taskName;
    }

    struct taskConfig {
        IAocoRouter02 _routerAddress;
        address _owner;
        address[] _swapRouter;
        address[] _swapRouter2;
        uint256 _swapAmount;
        uint256 _interval;
        uint256 _salt;
        uint256 _taskExTimes;
        uint256 _index;
        bytes32 _md5;
        taskDataItem _taskData;
    }

    event CounterTaskCreated(uint256 _time, address _user, uint256 _taskAmount, bytes32 _taskId);
    event swapToenEvent(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _spendSwapInToken, uint256 _timestamp, address _user);
    event swapToenTaskEvent(uint256 _index, address _user, bytes32 _md5, bytes32 _taskID);

    constructor(uint256 _approveAmount, address payable _ops, address _fundsOwner, USDTPool _USDTPoolAddress) OpsTaskCreator(_ops, _fundsOwner){
        setDefaultSwapInfo(_approveAmount);
        setUSDTPoolAddress(_USDTPoolAddress);
    }

    function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
        approveAmount = _approveAmount;
    }

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress) public onlyOwner {
        USDTPoolAddress = _USDTPoolAddress;
    }

    function setSwapInfo(IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2) private {
        require(_swapRouter[0] == address(USDTPoolAddress.USDT()) && _swapRouter2[_swapRouter2.length - 1] == address(USDTPoolAddress.USDT()), "e001");
        require(_swapRouter2[0] != address(USDTPoolAddress.USDT()) && _swapRouter[_swapRouter2.length - 1] != address(USDTPoolAddress.USDT()), "e002");
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1], "e003");
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1], "e004");
        IERC20(_swapRouter[0]).approve(address(_routerAddress), approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), approveAmount);
    }

    function createTask(string memory _taskName, IAocoRouter02 _routerAddress, address[] memory _swapRouter, address[] memory _swapRouter2, uint256 _swapAmount, uint256 _interval, uint256 _salt) external payable {
        setSwapInfo(_routerAddress, _swapRouter, _swapRouter2);
        bytes32 md5 = keccak256(abi.encodePacked(_taskName, block.timestamp, block.difficulty, msg.sender, _salt));
        require(!md5List[md5], "e001");
        md5List[md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        bytes memory execData = abi.encodeCall(this.swapToken, (msg.sender, md5));
        ModuleData memory moduleData;
        if (_interval > 0) {
            moduleData = ModuleData({
            modules : new Module[](2),
            args : new bytes[](2)
            });
            moduleData.modules[0] = Module.TIME;
            moduleData.modules[1] = Module.PROXY;
            moduleData.args[0] = _timeModuleArg(block.timestamp, _interval);
            moduleData.args[1] = _proxyModuleArg();
        } else {
            moduleData = ModuleData({
            modules : new Module[](1),
            args : new bytes[](1)
            });
            //            moduleData.modules[0] = Module.PROXY;
            //            moduleData.modules[1] = Module.SINGLE_EXEC;
            //            moduleData.args[0] = _proxyModuleArg();
            //            moduleData.args[1] = _singleExecModuleArg();
            //测试whenever
            moduleData.modules[0] = Module.PROXY;
            //            moduleData.modules[1] = Module.SINGLE_EXEC;
            moduleData.args[0] = _proxyModuleArg();
            //            moduleData.args[1] = _singleExecModuleArg();
        }
        bytes32 id = _createTask(address(this), execData, moduleData, ETH);
        taskList[taskAmount] = id;
        userTaskList[msg.sender].push(id);
        md5TaskList[md5] = id;
        taskConfig memory k = taskConfig(_routerAddress, msg.sender, _swapRouter, _swapRouter2, _swapAmount, _interval, _salt, 0, taskAmount, md5, taskDataItem(address(this), execData, moduleData, ETH, true, _taskName));
        taskConfigList[id] = k;
        emit CounterTaskCreated(block.timestamp, msg.sender, taskAmount, id);
        taskAmount = taskAmount.add(1);
    }

    modifier onlyTime(bytes32 _md5) {
        taskConfig storage y = taskConfigList[md5TaskList[_md5]];
        if (y._interval == 0) {
            require(block.timestamp >= (lastExecutedTimeList[_md5]).add(300), "t001");
        }
        _;
    }

    function swapToken(address _user, bytes32 _md5) external onlyDedicatedMsgSender onlyTime(_md5) {
        taskConfig storage y = taskConfigList[md5TaskList[_md5]];
        //        //测试whenever
        //        if (y._interval == 0) {
        //            require(block.timestamp >= (lastExecutedTimeList[_md5]).add(300);
        //        }
        swapCotItem memory x = swapCotItem(gasleft(), y._swapAmount, y._swapRouter[0], y._swapRouter[1], 0, 0, 0, 0, 0, 0);
        if (x._swapIn == 0) {
            return;
        } else {
            if (address(USDTPoolAddress.USDT()) == x.swapInToken) {
                USDTPoolAddress.claimUSDT(_user, y._swapAmount);
            }
            if (IERC20(x.swapInToken).allowance(address(this), address(y._routerAddress)) < x._swapIn) {
                IERC20(x.swapInToken).approve(address(y._routerAddress), approveAmount);
            }
            x.balanceOfIn0 = IERC20(x.swapInToken).balanceOf(address(this));
            x.balanceOfOut0 = IERC20(x.swapOutToken).balanceOf(address(this));
            y._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x._swapIn, 0, y._swapRouter, address(this), block.timestamp);
            x.balanceOfOut1 = IERC20(x.swapOutToken).balanceOf(address(this));
            x._swapIn = x.balanceOfOut1.sub(x.balanceOfOut0);
            if (IERC20(x.swapOutToken).allowance(address(this), address(y._routerAddress)) < x._swapIn) {
                IERC20(x.swapOutToken).approve(address(y._routerAddress), approveAmount);
            }
            y._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x._swapIn, 0, y._swapRouter2, address(this), block.timestamp);
            x.balanceOfIn1 = IERC20(x.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x.balanceOfIn0.sub(x.balanceOfIn1);
            x.gasUsed = x.startGas - gasleft();
            emit swapToenEvent(tx.origin, msg.sender, x.gasUsed, x.spendSwapInToken, block.timestamp, _user);
            emit swapToenTaskEvent(y._index, _user, y._md5, md5TaskList[_md5]);
            (uint256 fee, address feeToken) = _getFeeDetails();
            _transfer(fee, feeToken);
            require(userInfoList[_user].ethAmount >= fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(fee);
            y._taskExTimes = y._taskExTimes.add(1);
            if (address(USDTPoolAddress.USDT()) == x.swapInToken) {
                uint256 poolFee = y._swapAmount.mul(USDTPoolAddress.swapRate()).div(USDTPoolAddress.swapAllRate());
                uint256 allFee = x.spendSwapInToken.add(poolFee);
                require(userInfoList[_user].usdtAmount >= allFee, "k001");
                userInfoList[_user].usdtAmount = userInfoList[_user].usdtAmount.sub(allFee);
                IERC20(x.swapInToken).transfer(address(USDTPoolAddress), y._swapAmount.add(poolFee));
            }
        }
        lastExecutedTimeList[_md5] = block.timestamp;
    }

    function depositUSDT(uint256 _amount) external {
        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_amount);
    }

    function withdrawUSDT(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].usdtAmount, "e001");
        USDTPoolAddress.USDT().transfer(msg.sender, _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_amount);
    }

    function depositEth() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdrawETH(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].ethAmount, "e001");
        payable(msg.sender).transfer(_amount);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_amount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function cancelTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(y._owner == msg.sender, "e001");
        require(y._taskData._status, "e002");
        _cancelTask(_taskID);
        y._taskData._status = false;
    }

    function restartTask(bytes32 _taskID) external {
        taskConfig storage y = taskConfigList[_taskID];
        require(y._owner == msg.sender, "e001");
        require(!y._taskData._status, "e002");
        _createTask(y._taskData._execAddress, y._taskData._execDataOrSelector, y._taskData._moduleData, y._taskData._feeToken);
        y._taskData._status = true;
    }

    function getUserTaskList(address _user) external view returns (bytes32[] memory) {
        return userTaskList[_user];
    }

    function getUserTaskListNum(address _user) external view returns (uint256) {
        return userTaskList[_user].length;
    }

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory taskIdList) {
        taskIdList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            taskIdList[i] = userTaskList[_user][_indexList[i]];
        }
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e9");
        return a % b;
    }
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAocoRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

interface USDTPool {
    function userInfoList(address _user) external view returns (bool _canClaim, uint256 _maxAmount);

    function claimUSDT(address _user, uint256 _amount) external;

    function USDT() external view returns (IERC20);

    function swapRate() external view returns (uint256);

    function swapAllRate() external view returns (uint256);

    function getYearMonthDay(uint256 _timestamp) external view returns (uint256);
}

contract swapHelperDiyTask5 is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;
    mapping(bytes32 => uint256) public lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) public lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => txItem)) public txHistoryList;

    struct txItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 usdtAmount;
        uint256 ethUsedAmount;
    }

    struct taskConfigCreateItem {
        string _taskName;
        IAocoRouter02 _routerAddress;
        address[] _swapRouter;
        address[] _swapRouter2;
        uint256 _interval;
        uint256[] _start_end_Time;
        uint256[] _timeList;
        uint256[] _timeIntervalList;
        uint256[] _swapAmountList;
        uint256 _maxtxAmount;
        uint256 _maxSpendTokenAmount;
        uint256 _maxFeePerTx;
    }

    struct taskConfigDataItem {
        uint256 _index;
        address _owner;
        address _execAddress;
        bytes _execDataOrSelector;
        ModuleData _moduleData;
        address _feeToken;
        bool _status;
        uint256 _taskExTimes;
        bytes32 _md5;
        bytes32 _taskID;
    }

    struct taskConfig {
        taskConfigCreateItem taskConfigCreate;
        taskConfigDataItem taskConfigData;
    }

    struct gasItem {
        uint256 startGas;
        uint256 gasUsed;
    }

    struct balanceItem {
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
    }

    struct TokenItem {
        address swapInToken;
        address swapOutToken;
    }

    struct feeItem {
        uint256 poolFee;
        uint256 allFee;
    }

    struct feeItem2 {
        uint256 fee;
        address feeToken;
    }

    struct swapTokenItem {
        uint256 day;
        uint256 claimAmount;
        uint256 swapInAmount;
        uint256 spendSwapInToken;
        bytes32 taskID;
        gasItem _gasItem;
        TokenItem _TokenItem;
        balanceItem _balanceItem;
        feeItem _feeItem;
        feeItem2 _feeItem2;
    }

    event CounterTaskCreated(uint256 _time, address _user, uint256 _taskAmount, bytes32 _taskId);
    event swapToenEvent(address _tx_origin, address _msg_sender, uint256 _gasUsed, uint256 _fee, uint256 _spendSwapInToken, uint256 _timestamp, address _user);
    event swapToenTaskEvent(uint256 _index, address _user, bytes32 _md5, bytes32 _taskID);

    modifier onlyEditer(bytes32 _taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        require(msg.sender == owner() || msg.sender == y.taskConfigData._owner, "e001");
        _;
    }

    modifier onlyTime(bytes32 _md5) {
        taskConfig storage y = taskConfigList[md5TaskList[_md5]];
        require(block.timestamp >= (lastExecutedTimeList[_md5]).add(y.taskConfigCreate._timeIntervalList[lastTimeIntervalIndexList[md5TaskList[_md5]]]), "e002");
        require(getInTimeZone(y.taskConfigCreate._start_end_Time, y.taskConfigCreate._timeList), "e003");
        _;
    }

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        USDTPool _USDTPoolAddress
    ) OpsTaskCreator(_ops, _fundsOwner){
        setDefaultSwapInfo(_approveAmount);
        setUSDTPoolAddress(_USDTPoolAddress);
    }

    function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
        approveAmount = _approveAmount;
    }

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress) public onlyOwner {
        USDTPoolAddress = _USDTPoolAddress;
    }

    function setSwapInfo(
        IAocoRouter02 _routerAddress,
        address[] memory _swapRouter,
        address[] memory _swapRouter2
    ) private {
        require(_swapRouter[0] == address(USDTPoolAddress.USDT()) && _swapRouter2[_swapRouter2.length - 1] == address(USDTPoolAddress.USDT()), "e004");
        require(_swapRouter2[0] != address(USDTPoolAddress.USDT()) && _swapRouter[_swapRouter2.length - 1] != address(USDTPoolAddress.USDT()), "e005");
        require(_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1], "e006");
        require(_swapRouter2[0] == _swapRouter[_swapRouter2.length - 1], "e007");
        IERC20(_swapRouter[0]).approve(address(_routerAddress), approveAmount);
        IERC20(_swapRouter2[0]).approve(address(_routerAddress), approveAmount);
    }

    function createTask(
        taskConfigCreateItem calldata _taskConfigCreate
    ) external payable {
        setSwapInfo(_taskConfigCreate._routerAddress, _taskConfigCreate._swapRouter, _taskConfigCreate._swapRouter2);
        bytes32 md5 = keccak256(abi.encodePacked(_taskConfigCreate._taskName, block.timestamp, block.difficulty, msg.sender, _taskConfigCreate._start_end_Time));
        require(!md5List[md5], "e008");
        md5List[md5] = true;
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
        bytes memory execData = abi.encodeCall(this.swapToken, (msg.sender, md5));
        ModuleData memory moduleData;
        if (_taskConfigCreate._interval <= 20) {
            moduleData = ModuleData({
            modules : new Module[](1),
            args : new bytes[](1)
            });
            moduleData.modules[0] = Module.PROXY;
            moduleData.args[0] = _proxyModuleArg();
        } else {
            moduleData = ModuleData({
            modules : new Module[](2),
            args : new bytes[](2)
            });
            moduleData.modules[0] = Module.TIME;
            moduleData.modules[1] = Module.PROXY;
            moduleData.args[0] = _timeModuleArg(block.timestamp, _taskConfigCreate._interval);
            moduleData.args[1] = _proxyModuleArg();
        }
        bytes32 taskID = _createTask(address(this), execData, moduleData, ETH);
        taskList[taskAmount] = taskID;
        userTaskList[msg.sender].push(taskID);
        md5TaskList[md5] = taskID;
        taskConfig memory _taskConfig = new taskConfig[](1)[0];
        _taskConfig.taskConfigCreate = taskConfigCreateItem({
        _taskName : _taskConfigCreate._taskName,
        _routerAddress : _taskConfigCreate._routerAddress,
        _swapRouter : _taskConfigCreate._swapRouter,
        _swapRouter2 : _taskConfigCreate._swapRouter2,
        _interval : _taskConfigCreate._interval,
        _start_end_Time : _taskConfigCreate._start_end_Time,
        _timeList : _taskConfigCreate._timeList,
        _timeIntervalList : _taskConfigCreate._timeIntervalList,
        _swapAmountList : _taskConfigCreate._swapAmountList,
        _maxtxAmount : _taskConfigCreate._maxtxAmount,
        _maxSpendTokenAmount : _taskConfigCreate._maxSpendTokenAmount,
        _maxFeePerTx : _taskConfigCreate._maxFeePerTx
        });
        _taskConfig.taskConfigData = taskConfigDataItem({
        _index : taskAmount,
        _owner : msg.sender,
        _execAddress : address(this),
        _execDataOrSelector : execData,
        _moduleData : moduleData,
        _feeToken : ETH,
        _status : true,
        _taskExTimes : 0,
        _md5 : md5,
        _taskID : taskID
        });
        taskConfigList[taskID] = _taskConfig;
        emit CounterTaskCreated(block.timestamp, msg.sender, taskAmount, taskID);
        taskAmount = taskAmount.add(1);
    }

    function editTaskSwapAmountList(bytes32 _taskID, uint256[] memory _swapAmountList) external onlyEditer(_taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        y.taskConfigCreate._swapAmountList = _swapAmountList;
        lastSwapAmountIndexList[_taskID] = 0;
    }

    function editTaskStartEndTime(bytes32 _taskID, uint256[] memory _start_end_Time) external onlyEditer(_taskID) {
        require((_start_end_Time.length == 2) && (_start_end_Time[1] > _start_end_Time[0]), "e009");
        taskConfig storage y = taskConfigList[_taskID];
        y.taskConfigCreate._start_end_Time = _start_end_Time;
    }

    function editTaskTimeList(bytes32 _taskID, uint256[] memory _timeList) external onlyEditer(_taskID) {
        require(_timeList.length % 2 == 0, "e010");
        taskConfig storage y = taskConfigList[_taskID];
        y.taskConfigCreate._timeList = _timeList;
    }

    function editTaskTimeIntervalList(bytes32 _taskID, uint256[] memory _timeIntervalList) external onlyEditer(_taskID) {
        require(_timeIntervalList.length > 0, "e011");
        taskConfig storage y = taskConfigList[_taskID];
        y.taskConfigCreate._timeIntervalList = _timeIntervalList;
        lastTimeIntervalIndexList[_taskID] = 0;
    }

    function editTaskLimit(bytes32 _taskID, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount, uint256 _maxFeePerTx) external onlyEditer(_taskID) {
        require(_maxtxAmount > 0, "e012");
        require(_maxSpendTokenAmount > 0, "e013");
        taskConfig storage y = taskConfigList[_taskID];
        y.taskConfigCreate._maxtxAmount = _maxtxAmount;
        y.taskConfigCreate._maxSpendTokenAmount = _maxSpendTokenAmount;
        y.taskConfigCreate._maxFeePerTx = _maxFeePerTx;
    }

    function getInTimeZone(uint256[] memory _start_end_Time, uint256[] memory _timeList) public view returns (bool _inTimeZone) {
        _inTimeZone = false;
        uint256 all = (block.timestamp + 3600 * 8) % (3600 * 24);
        uint256 TimeListLength = _timeList.length / 2;
        for (uint256 i = 0; i < TimeListLength; i++) {
            if (all >= _timeList[i * 2] && all < _timeList[i * 2 + 1] && block.timestamp >= _start_end_Time[0] && block.timestamp <= _start_end_Time[1]) {
                _inTimeZone = true;
                break;
            }
        }
    }

    function swapToken(address _user, bytes32 _md5) external onlyDedicatedMsgSender onlyTime(_md5) {
        swapTokenItem memory x = new swapTokenItem[](1)[0];
        x.day = USDTPoolAddress.getYearMonthDay(block.timestamp);
        x.taskID = md5TaskList[_md5];
        taskConfig storage y = taskConfigList[x.taskID];
        x._gasItem.startGas = gasleft();
        x._TokenItem.swapInToken = y.taskConfigCreate._swapRouter[0];
        x._TokenItem.swapOutToken = y.taskConfigCreate._swapRouter[1];
        x.claimAmount = y.taskConfigCreate._swapAmountList[lastSwapAmountIndexList[x.taskID]];
        x.swapInAmount = x.claimAmount;
        require(txHistoryList[x.taskID][x.day]._totalTx.add(1) <= y.taskConfigCreate._maxtxAmount, "e014");
        require(txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount * 2) <= y.taskConfigCreate._maxSpendTokenAmount, "e015");
        txHistoryList[x.taskID][x.day]._totalTx = txHistoryList[x.taskID][x.day]._totalTx.add(1);
        txHistoryList[x.taskID][x.day]._totalSpendTokenAmount = txHistoryList[x.taskID][x.day]._totalSpendTokenAmount.add(x.claimAmount * 2);
        if (x.swapInAmount == 0) {
            return;
        } else {
            if (address(USDTPoolAddress.USDT()) == x._TokenItem.swapInToken) {
                USDTPoolAddress.claimUSDT(_user, x.claimAmount);
            }
            if (IERC20(x._TokenItem.swapInToken).allowance(address(this), address(y.taskConfigCreate._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapInToken).approve(address(y.taskConfigCreate._routerAddress), approveAmount);
            }
            x._balanceItem.balanceOfIn0 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            x._balanceItem.balanceOfOut0 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            y.taskConfigCreate._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.taskConfigCreate._swapRouter, address(this), block.timestamp);
            x._balanceItem.balanceOfOut1 = IERC20(x._TokenItem.swapOutToken).balanceOf(address(this));
            x.swapInAmount = x._balanceItem.balanceOfOut1.sub(x._balanceItem.balanceOfOut0);
            if (IERC20(x._TokenItem.swapOutToken).allowance(address(this), address(y.taskConfigCreate._routerAddress)) < x.swapInAmount) {
                IERC20(x._TokenItem.swapOutToken).approve(address(y.taskConfigCreate._routerAddress), approveAmount);
            }
            y.taskConfigCreate._routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(x.swapInAmount, 0, y.taskConfigCreate._swapRouter2, address(this), block.timestamp);
            x._balanceItem.balanceOfIn1 = IERC20(x._TokenItem.swapInToken).balanceOf(address(this));
            x.spendSwapInToken = x._balanceItem.balanceOfIn0.sub(x._balanceItem.balanceOfIn1);
            x._gasItem.gasUsed = x._gasItem.startGas - gasleft();
            emit swapToenTaskEvent(y.taskConfigData._index, _user, y.taskConfigData._md5, x.taskID);
            (x._feeItem2.fee, x._feeItem2.feeToken) = _getFeeDetails();
            require(x._feeItem2.fee <= y.taskConfigCreate._maxFeePerTx, "e016");
            txHistoryList[x.taskID][x.day]._totalFee = txHistoryList[x.taskID][x.day]._totalFee.add(x._feeItem2.fee);
            _transfer(x._feeItem2.fee, x._feeItem2.feeToken);
            emit swapToenEvent(tx.origin, msg.sender, x._gasItem.gasUsed, x._feeItem2.fee, x.spendSwapInToken, block.timestamp, _user);
            require(userInfoList[_user].ethAmount >= x._feeItem2.fee);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(x._feeItem2.fee);
            userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(x._feeItem2.fee);
            y.taskConfigData._taskExTimes = y.taskConfigData._taskExTimes.add(1);
            if (address(USDTPoolAddress.USDT()) == x._TokenItem.swapInToken) {
                x._feeItem.poolFee = x.claimAmount.mul(USDTPoolAddress.swapRate()).div(USDTPoolAddress.swapAllRate());
                x._feeItem.allFee = x.spendSwapInToken.add(x._feeItem.poolFee);
                require(userInfoList[_user].usdtAmount >= x._feeItem.allFee, "e017");
                userInfoList[_user].usdtAmount = userInfoList[_user].usdtAmount.sub(x._feeItem.allFee);
                IERC20(x._TokenItem.swapInToken).transfer(address(USDTPoolAddress), x.claimAmount.add(x._feeItem.poolFee));
            }
        }
        lastExecutedTimeList[_md5] = block.timestamp;
        lastTimeIntervalIndexList[x.taskID] = lastTimeIntervalIndexList[x.taskID].add(1);
        if (lastTimeIntervalIndexList[x.taskID] >= y.taskConfigCreate._timeIntervalList.length) {
            lastTimeIntervalIndexList[x.taskID] = 0;
        }
        lastSwapAmountIndexList[x.taskID] = lastSwapAmountIndexList[x.taskID].add(1);
        if (lastSwapAmountIndexList[x.taskID] >= y.taskConfigCreate._swapAmountList.length) {
            lastSwapAmountIndexList[x.taskID] = 0;
        }
    }

    function depositUSDT(uint256 _amount) external {
        USDTPoolAddress.USDT().transferFrom(msg.sender, address(this), _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.add(_amount);
    }

    function withdrawUSDT(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].usdtAmount, "e018");
        USDTPoolAddress.USDT().transfer(msg.sender, _amount);
        userInfoList[msg.sender].usdtAmount = userInfoList[msg.sender].usdtAmount.sub(_amount);
    }

    function depositEth() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }

    function withdrawETH(uint256 _amount) external {
        require(_amount <= userInfoList[msg.sender].ethAmount, "e019");
        payable(msg.sender).transfer(_amount);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.sub(_amount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function cancelTask(bytes32 _taskID) external onlyEditer(_taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        require(y.taskConfigData._status, "e020");
        _cancelTask(_taskID);
        y.taskConfigData._status = false;
    }

    function restartTask(bytes32 _taskID) external onlyEditer(_taskID) {
        taskConfig storage y = taskConfigList[_taskID];
        require(!y.taskConfigData._status, "e021");
        _createTask(y.taskConfigData._execAddress, y.taskConfigData._execDataOrSelector, y.taskConfigData._moduleData, y.taskConfigData._feeToken);
        y.taskConfigData._status = true;
    }

    function getUserTaskList(address _user) external view returns (bytes32[] memory) {
        return userTaskList[_user];
    }

    function getUserTaskListNum(address _user) external view returns (uint256) {
        return userTaskList[_user].length;
    }

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory taskIdList) {
        taskIdList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            taskIdList[i] = userTaskList[_user][_indexList[i]];
        }
    }

    receive() external payable {
        userInfoList[msg.sender].ethDepositAmount = userInfoList[msg.sender].ethDepositAmount.add(msg.value);
        userInfoList[msg.sender].ethAmount = userInfoList[msg.sender].ethAmount.add(msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "pool001");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "pool002");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract USDTPool3 is Ownable {

    struct _DateTime {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
        uint256 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint256 constant ORIGIN_YEAR = 1970;

    IERC20 public USDT;
    mapping(address => bool) public userBlackList;
    mapping(address => bool) public callerList;
    uint256 public defaultMaxAmount;
    uint256 public swapRate = 10;
    uint256 public swapAllRate = 1000;
    mapping(address => uint256) public userMaxAmountList;

    constructor(IERC20 _USDT, uint256 _swapRate, uint256 _swapAllRate, uint256 _defaultMaxAmount) {
        setUSDT(_USDT);
        setSwapRates(_swapRate, _swapAllRate);
        setDefaultMaxAmount(_defaultMaxAmount);
    }

    function setUSDT(IERC20 _USDT) public onlyOwner {
        USDT = _USDT;
    }

    function setSwapRates(uint256 _swapRate, uint256 _swapAllRate) public onlyOwner {
        swapRate = _swapRate;
        swapAllRate = _swapAllRate;
    }

    function setDefaultMaxAmount(uint256 _defaultMaxAmount) public onlyOwner {
        defaultMaxAmount = _defaultMaxAmount;
    }

    function setUserMaxAmountList(address _user, uint256 _amount) external onlyOwner {
        userMaxAmountList[_user] = _amount;
    }

    function setCallerList(address _user, bool _status) external onlyOwner {
        callerList[_user] = _status;
    }

    function setUserBlackList(address _user, bool _status) external onlyOwner {
        userBlackList[_user] = _status;
    }

    function claimUSDT(address _user, uint256 _amount) external {
        require(callerList[msg.sender], "pool003");
        require(!userBlackList[_user], "pool004");
        if (userMaxAmountList[_user] == 0) {
            require(_amount <= defaultMaxAmount, "pool005");
        } else {
            require(_amount <= userMaxAmountList[_user], "pool006");
        }
        USDT.transfer(msg.sender, _amount);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function isLeapYear(uint256 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint256 month, uint256 year) public pure returns (uint256) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function getYearMonthDay(uint256 _timestamp) public pure returns (uint256) {
        _DateTime memory dt = parseTimestamp(_timestamp + 3600 * 8);
        return dt.year * (10 ** 6) + dt.month * (10 ** 4) + dt.day * 10;
    }

    function parseTimestamp(uint256 timestamp) public pure returns (_DateTime memory dt) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint256 i;

        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        dt.hour = getHour(timestamp);
        dt.minute = getMinute(timestamp);
        dt.second = getSecond(timestamp);
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint256) {
        uint256 secondsAccountedFor = 0;
        uint256 year;
        uint256 numLeapYears;

        year = uint256(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint256(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint256) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint256) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint256) {
        return uint256((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint256) {
        return uint256((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    receive() external payable {
    }
}