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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./IKPIPaymentActions.sol";
import "./IKPIPaymentEvents.sol";
import "./IKPIPaymentImmutables.sol";
import "./IKPIPaymentStates.sol";

/// @title KPI Payment interface
/// @notice Contain payment method for project and task contracts
/// @author BARA
interface IKPIPayment is IKPIPaymentStates, IKPIPaymentActions, IKPIPaymentEvents, IKPIPaymentImmutables 
{

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title KPI Payment interface
/// @notice Contain payment actions
/// @author BARA
interface IKPIPaymentActions { 
    /// @notice Deposit task reward
    /// @dev owner or admin can deposit a task many times
    /// @param taskID ID of the task
    /// @param depositor Address of the depositor
    /// @param amount Amount of the deposit
    /// @param whichToken select token to deposit to task, start with 0 is the default token
    function depositTask(
        uint256 taskID,
        address depositor,
        uint256 amount,
        uint8 whichToken
    ) external;

    /// @notice Withdraw task reward
    /// @dev only assignee can receive task reward
    /// @param taskID ID of the task
    /// @param status Task's status
    /// @param receiver Address of the receiver
    /// @param amount the amount of the withdraw
    /// @param whichToken select token to deposit to task, start with 0 is the default token
    /// @return withdrawAmount amount of token withdrawed
    function withdrawTask(
        uint256 taskID,
        uint256 status,
        address receiver,
        uint256 amount,
        uint8 whichToken
    ) external returns (uint256 withdrawAmount);

    /// @notice Owner withdraw penalty amount
    /// @dev only owner can call this function
    /// @return amount1 amount of penalty of token1, amount2 amount of penalty of token2
    function withdrawPenalty() external returns (uint256 amount1, uint256 amount2);

    /// @notice Deposit guarantee amount
    /// @dev call this function for a user deposit guarantee amount
    /// @param depositor Address of the depositor
    /// @param amount Guarantee amount of the project or the missing amount of the project
    function depositGuaranteeAmount(address depositor, uint256 amount) external;

    /// @notice Withdraw guarantee amount
    /// @dev call this function for a user withdraw guarantee amount
    /// @param receiver Address of the receiver
    /// @param amount the amount of the withdraw
    function withdrawGuaranteeAmount(address receiver, uint256 amount)
        external;

    /// @notice Assignee drop a task to call this function, get penalized
    /// @dev call this function for a user drop a task
    /// @param depositor Address of the depositor
    /// @param guaranteeAmount Guarantee amount of assignee
    function dropTask(address depositor, uint256 guaranteeAmount) external;

    /// @notice Penalize a task
    /// @dev call this function when an admin penalize a task
    /// @param taskID taskID ID of the task
    /// @param assignee Assignee of this task
    /// @param taskRemaining1 amount of the task reward of token1
    /// @param taskRemaining2 amount of the task reward of token2
    /// @param assigneeGuarantee amount of the assignee guarantee
    /// @return totalPenalized1 total penalized amount of token1, totalPenalized2 total penalized amount of token2
    function penalized(
        uint256 taskID,
        address assignee,
        uint256 taskRemaining1,
        uint256 taskRemaining2,
        uint256 assigneeGuarantee
    ) external returns (uint256 totalPenalized1, uint256 totalPenalized2);

    /// @notice Cancel a task
    /// @dev call this function to cancel a task and transfer the amount of the task for admin
    /// @param taskID ID of the task
    /// @param taskRemaining1 amount of the task reward left of token1
    /// @param taskRemaining2 amount of the task reward left of token2
    function canceled(uint256 taskID, uint256 taskRemaining1, uint256 taskRemaining2) external;

    /// @notice Reset a task
    /// @dev call this function to reset and deposit new amount for a task
    /// @param taskID ID of the task
    /// @param depositor Address of the depositor
    /// @param newAmount New amount of the task
    function resetTask(
        uint256 taskID,
        address depositor,
        uint256 newAmount,
        uint8 whichToken
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title KPI Payment Events interface
/// @notice Contain payment events
/// @author BARA
interface IKPIPaymentEvents {
    /// @notice Emitted when a user withdraw
    /// @param user User address
    /// @param amount Withdraw amount
    event Withdraw(address indexed user, uint256 indexed amount, address indexed token);

    /// @notice Emitted when a user deposit
    /// @param user User address
    /// @param amount Deposit amount
    event Deposit(address indexed user, uint256 indexed amount, address indexed token);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title KPI Payment immutables interface
/// @notice Contain immutables of payment contract
/// @author BARA
interface IKPIPaymentImmutables {
    /// @notice Project owner address
    function owner() external view returns (address);

    /// @notice Project contract address
    function projectContract() external view returns (address);

    /// @notice Task contract address
    function taskContract() external view returns (address);

    /// @notice Default token address used in project
    function token1() external view returns (address);

    /// @notice Another token address
    function token2() external view returns (address);

    /// @notice Factory address
    function factory() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title KPI Payment states interface
/// @notice Contain states of payment contract
/// @author BARA
interface IKPIPaymentStates {
    /// @notice call this function to get penalty amount that currently have on this project
    function penalty(address token) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./IKPIProjectActions.sol";
import "./IKPIProjectImmutables.sol";
import "./IKPIProjectStates.sol";
import "./IKPIProjectEvents.sol";

/// @title The interface for the KPI Project
/// @notice This contract is used to control tasks, members, and payments in a project
/// @author BARA
interface IKPIProject is
    IKPIProjectActions,
    IKPIProjectImmutables,
    IKPIProjectStates,
    IKPIProjectEvents
{

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Permissionless KPI project actions
/// @notice Contains project methods that can be called by owner and admins
/// @author BARA
interface IKPIProjectActions {
    /// @notice Add a new member to the project
    /// @param user The address of the new member
    /// @dev This function is called by owner and admins to add new member to the project
    function addMember(address user, bytes32 name) external;

    /// @notice Remove a member from the project
    /// @param user The address of the member
    /// @dev This function is called by owner and admins to remove (actually set isMember to false)
    /// a member from the project, if this member is admin, remove admin role too
    function removeMember(address user) external;

    /// @notice Add a new admin to the project
    /// @param user The address of the new admin
    /// @dev If admin is already a member, this function will not add a new member and set role to admin
    /// else it will add a new member and set that member to admin role
    function addAdmin(address user, bytes32 name) external;

    /// @notice Remove an admin from the project
    /// @param user The address of the admin
    /// @dev Remove admin role from a member, that admin is still a member
    function removeAdmin(address user) external;

    /// @notice Change a member name
    /// @param user The address of the member
    /// @param name The new name of the member
    /// @dev This function is called by admins to change member name
    function changeMemberName(address user, bytes32 name) external;

    /// @notice Change the alternate address of a member
    /// @param user The address of the member
    /// @param alternateAddress The new alternate address of the member
    /// @dev This alternate address is can be set only by that user
    function changeAlternate(address user, address alternateAddress) external;

    /// @notice Set project name
    /// @param name The new project name
    /// @dev This function is called only by owner
    function setName(bytes32 name) external;

    /// @notice Set guarantee amount
    /// @param amount The new guarantee amount
    /// @dev This function is called only by owner
    function setGuaranteeAmount(uint256 amount) external;

    /// @notice Set repository link
    /// @param repository The new repository link
    /// @dev This function is called only by owner
    function setRepository(bytes32 repository) external;

    /// @notice Set project owner
    /// @param newOwner The new project owner
    /// @dev This function is called only by owner
    function setOwner(address newOwner) external;

    /// @notice Get this project states
    /// @dev This function is called by anyone to get project states
    /// @return factory The project factory address, token The project token address, createdAt The project created time, name The project name, guaranteeAmount The project guarantee amount for a user to be able to receive task,
    /// repository The project repository link, members The number of members in this project, taskContract The task contract address, owner The project owner address, penaltyPercentage The project penalty rate
    function getProject()
        external
        view
        returns (
            address factory,
            address token,
            address token2,
            uint256 createdAt,
            bytes32 name,
            uint256 guaranteeAmount,
            bytes32 repository,
            uint256 members,
            address taskContract,
            address owner,
            bool depositChecking,
            uint256 penaltyPercentage
        );

    /// @notice Check a user is an admin of the project
    /// @param user The address of user
    function isAdmin(address user) external view returns (bool);

    /// @notice Check a user is a member of the project
    /// @param user The address of user
    function isMember(address user) external view returns (bool);

    /// @notice Factory set task contract
    /// @param task The task contract address
    function setTaskContract(address task) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title The interface for the KPI Project Events
/// @author BARA
interface IKPIProjectEvents {
    /// @notice Emitted when a new member is added to the project'
    /// @param project The project address
    /// @param member New member address
    /// @param name New member name
    event MemberAdded(
        address indexed project,
        address indexed member,
        bytes32 indexed name
    );

    /// @notice Emitted when a member is removed from the project
    /// @param project The project address
    /// @param member Removed member address
    event MemberRemoved(address indexed project, address indexed member);

    /// @notice Emitted when an admin is added
    /// @param project The project address
    /// @param admin New admin address
    /// @param name New admin name
    event AdminAdded(
        address indexed project,
        address indexed admin,
        bytes32 indexed name
    );

    /// @notice Emitted when an admin is removed
    /// @param project The project address
    /// @param admin Removed admin address
    event AdminRemoved(address indexed project, address indexed admin);

    /// @notice Emitted when guarantee amount of a project is changed by owner
    /// @param project The project address
    /// @param newAmount New guarantee amount
    event ProjectGuaranteeAmountChanged(
        address indexed project,
        uint256 indexed newAmount
    );

    /// @notice Emitted when project owner is changed
    /// @param project The project address
    /// @param oldOwner The old owner address
    /// @param newOwner The new owner address
    event OwnerChanged(
        address indexed project,
        address indexed oldOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Project state that never change
/// @notice These parameters are fixed for a project forever, i.e., the methods will always return the same values
/// @author BARA
interface IKPIProjectImmutables {
    /// @notice The contract that deployed the project
    function factory() external view returns (address);

    /// @notice The token address used to pay for tasks in the project
    function token1() external view returns (address);

    /// @notice Another token address, can be used like first token
    function token2() external view returns (address);

    /// @notice The project created time
    /// @dev Save this value with uint256 to minimize gas cost
    function createdAt() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Project states that can change
/// @author BARA
interface IKPIProjectStates {
    /// @notice Member struct
    /// @param user The address of member
    /// @dev get member by members index
    /// @return name Member name, isMember is active member, alternate The alternate address that user want to receive reward instead of the current user address
    function getMember(address user)
        external
        view
        returns (
            bytes32 name,
            bool isMember,
            address alternate
        );

    /// @notice Get task contract address
    function taskContract() external view returns (address);

    /// @notice get project info
    /// @param projectName The project name
    /// @param repository repository link to the project's repository
    /// @param guaranteeAmount Current guarantee amount for a user to be able to receive task in this project
    /// @param members Project's members count, always start with 1
    /// @param penaltyPercentage Project's penalty rate
    /// @param depositChecking Check if this project have to deposit or not
    /// @param owner Project's owner
    function projectInfo()
        external
        view
        returns (
            bytes32 projectName,
            bytes32 repository,
            uint256 guaranteeAmount,
            uint256 members,
            uint256 penaltyPercentage,
            bool depositChecking,
            address owner
        );
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./IKPITaskActions.sol";
import "./IKPITaskEvents.sol";
import "./IKPITaskStates.sol";

/// @title The interface for the KPI Task
/// @notice This contract is used to control tasks of a project
/// @author BARA
interface IKPITask is IKPITaskActions, IKPITaskEvents, IKPITaskStates {

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Permissionless KPI task actions
/// @notice Contains task methods that can be called by members, admins and owner
/// @author BARA
interface IKPITaskActions {
    /// @notice Create new task for the project
    /// @dev only project owner and admins can call this function
    /// @param name The name of the task
    /// @param description The description of the task
    /// @param reward1 The amount that member can claim when complete this task according to token default
    /// @param reward2 The amount that member can claim when complete this task according to token2
    /// @param deadline The deadline of the task
    /// @return newTaskID The ID of the new task
    function createTask(
        bytes32 name,
        bytes32 description,
        uint256 reward1,
        uint256 reward2,
        uint256 deadline
    ) external returns (uint256 newTaskID);

    /// @notice Receive a task to work on
    /// @dev only members can call this function
    /// @param taskID The ID of the task
    function receiveTask(uint256 taskID) external;

    /// @notice Finish a task
    /// @dev only assignee can call this function
    /// @param taskID The ID of the task
    function finishTask(uint256 taskID) external;

    /// @notice Penalize a delay task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    function penalizeTask(uint256 taskID) external;

    /// @notice Cancel a task and claim back the reward
    /// @dev only project owner can call this function
    /// @param taskID The ID of the task
    function cancelTask(uint256 taskID) external;

    /// @notice Approve a task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    function approveTask(uint256 taskID) external;

    /// @notice Reset/Reopen a task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param newAmount1 The new amount that member can claim when complete this task
    /// @param newAmount2 The new amount according to token2
    /// @param deadline The new deadline of the task
    function resetTask(
        uint256 taskID,
        uint256 newAmount1,
        uint256 newAmount2,
        uint256 deadline
    ) external;

    /// @notice Force finish a task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    function forceDone(uint256 taskID) external;

    /// @notice Claim reward for a task
    /// @dev only assignee can call this function
    /// @param taskID The ID of the task
    function claimTask(uint256 taskID) external;

    /// @notice Withdraw guarantee amount of a user from the project
    function withdrawGuarantee() external;

    /// @notice Deposit more for a task
    /// @dev only depositor of this task can re deposit
    /// @param taskID The ID of the task
    /// @param reward The reward amount
    /// @param whichToken choose token to be transfer, 0 is default token
    function depositTask(uint256 taskID, uint256 reward, uint8 whichToken) external;

    /// @notice Assign a task to a member
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param assignee The address of the member
    function assignTask(uint256 taskID, address assignee) external;

    /// @notice Change the total reward of the project
    /// @dev only payment contract can call this function
    /// @param taskID The ID of the task
    /// @param totalReward The new total reward of the project
    /// @param whichToken choose token to be transfer, 0 is default token
    function setTotalReward(uint256 taskID, uint256 totalReward, uint8 whichToken) external;

    /// @notice Change the remaining reward of the project
    /// @dev only payment contract and project contract can call this function
    /// @param taskID The ID of the task
    /// @param remaining The new remaining reward of the task
    /// @param whichToken choose token to be transfer, 0 is default token
    function setRemaining(uint256 taskID, uint256 remaining, uint8 whichToken) external;

    /// @notice Change task description
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param description The new description of the task
    function changeDescription(uint256 taskID, bytes32 description) external;

    /// @notice Change task deadline
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param deadline The new deadline of the task
    function changeDeadline(uint256 taskID, uint256 deadline) external;

    // /// @notice Change task auto claim status
    // /// @dev only assignee of the task can call this function
    // /// @param taskID The ID of the task
    // function changeAutoClaim(uint256 taskID, bool isAutoClaim) external;

    /// @notice Transfer money from task to another address
    /// @param to The address to transfer to
    /// @param amount The amount to transfer
    /// @param whichToken choose token to be transfer, 0 is default token
    function transfer(address to, uint256 amount, uint8 whichToken) external;

    // /// @notice remove all completed tasks of a member
    // /// @dev only this contract and payment can call, return remaning reward of all completed tasks
    // /// @param member The address of the member
    // function withdrawAllCompletedTasks(address member)
    //     external
    //     returns (uint256);

    /// @notice drop a task and get penalty for a task
    /// @dev only assignee of the task can call this function
    /// @param taskID The ID of the task
    function dropTask(uint256 taskID) external;

    /// @notice factory set payment contract address
    /// @dev only call when created
    /// @param payment payment contract
    function setPaymentContract(address payment) external;

    /// @notice factory set task control contract address
    /// @dev only call when created
    /// @param taskControl task control contract
    function setTaskControlContract(address taskControl) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Task Control contract
/// @author BARA
interface IKPITaskControl {
    /// @notice Get the task contract of this task control contract
    function taskContract() external view returns (address);

    /// @notice Get the owner of this task control contract
    function owner() external view returns (address);

    /// @notice Get the factory contract address
    function factory() external view returns (address);

    /// @notice get number of tasks in project
    function taskCount() external view returns (uint256);

    /// @notice get number of tasks by a user, start with 1
    function tasksByUser(address user) external view returns (uint256);

    /// @notice map index to task with tasksByUser mapping
    function mapIndexToTask(address user, uint256 index)
        external
        view
        returns (uint256);

    /// @notice get in progress task by a user
    /// @param user The address of user
    function inProgress(address user) external view returns (uint256);

    /// @notice get number of late tasks
    /// @param user address of the member
    function late(address user) external view returns (uint256);

    /// @notice get number of completed tasks
    /// @param user address of the member
    function completed(address user) external view returns (uint256);

    /// @notice get number of penalized tasks
    /// @param user address of the member
    function penalized(address user) external view returns (uint256);

    /// @notice get completed task by a user
    /// @dev index is always start with 1, user mapping to get the task id
    /// @param user The address of user
    /// @param index The index of completed task in user struct
    /// @return taskID The id of task
    function getCompleted(address user, uint256 index)
        external
        view
        returns (uint256 taskID);

    /// @notice get penalized task by a user
    /// @dev index is always start with 1, user mapping to get the task id
    /// @param user The address of user
    /// @param index The index of penalized task in user struct
    /// @return taskID The id of task
    function getPenalized(address user, uint256 index)
        external
        view
        returns (uint256 taskID);

    /// @notice get late task by a user
    /// @dev index is always start with 1, user mapping to get the task id
    /// @param user The address of user
    /// @param index The index of late task in user struct
    /// @return taskID The id of task
    function getLate(address user, uint256 index)
        external
        view
        returns (uint256 taskID);

    /// @notice The amount of reward that user has earned with this project
    /// @param user user of this project
    /// @return amount The earned amount
    function earned(address user, uint8 whichToken) external view returns (uint256 amount);

    /// @notice The amount of guarantee that user has deposited
    /// @param user user of this project
    function guarantee(address user) external view returns (uint256);

    /// @notice Map a completed task with index for a user
    /// @param user The address of the member
    /// @param taskID The ID of the task
    /// @dev only Contract can call this function
    function mapIndexToCompletedTask(address user, uint256 taskID) external;

    /// @notice Map a penalized task with index for a user
    /// @param user The address of the member
    /// @param taskID The ID of the task
    /// @dev only Contract can call this function
    function mapIndexToPenalizedTask(address user, uint256 taskID) external;

    /// @notice Map a late task with index for a user
    /// @param user The address of the member
    /// @param taskID The ID of the task
    /// @dev only Contract can call this function
    function mapIndexToLateTask(address user, uint256 taskID) external;

    /// @notice Change a user guarantee amount
    /// @dev only Contract can call this function
    /// @param user The address of user
    /// @param amount The new guarantee amount
    function changeMemberGuarantee(address user, uint256 amount) external;

    /// @notice create task called by task contract
    /// @param newTaskID new task id
    function createTask(uint256 newTaskID) external;

    /// @notice Get task by user
    /// @param user The address of the member
    /// @return isOwned The task is owned by the user, isInProgress The task is in progress, isDone The task is done, isPenalized The task is penalized,
    /// isCanceled The task is canceled, isWaitingForApproval The task is waiting for approval, isDropped The task is dropped
    function assignTask(address user, uint256 taskID)
        external
        view
        returns (
            bool isOwned,
            bool isInProgress,
            bool isDone,
            bool isPenalized,
            bool isCanceled,
            bool isWaitingForApproval,
            bool isDropped
        );

    /// @notice Change the task status when a user receive a task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function receiveTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a user finish a task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function finishTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a user is penalized for a task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function penalizeTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a task is canceled
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function cancelTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a task is approved
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function approveTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a task is reset
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function resetTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a task is force done
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function forceDone(address user, uint256 taskID) external;

    /// @notice User drop task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function dropTask(address user, uint256 taskID) external;

    /// @notice Increase the completed tasks of a user
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increaseCompleted(address user) external returns (uint256);

    /// @notice Increase the penalized tasks of a user
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increasePenalized(address user) external returns (uint256);

    /// @notice Increase the late tasks of a user
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increaseLate(address user) external returns (uint256);

    /// @notice Increase the tasks that a user is working on
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increaseInProgress(address user) external;

    /// @notice Decrease the tasks that a user is working on
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function decreaseInProgress(address user) external;

    /// @notice Get tasks by user address
    /// @param user The address of the member
    /// @param cursor The cursor position to get tasks
    /// @param quantity The quantity of the task
    function getTasksByUser(
        address user,
        uint256 cursor,
        uint256 quantity
    ) external view returns (uint256[] memory taskIDs, uint256 nextCursor);

    /// @notice Get task ids
    /// @param cursor The index to start getting task ids
    /// @param quantity The number of task ids to get
    /// @return taskIDs The array of task ids, nextCursor The index to start getting next task ids
    function getTasks(uint256 cursor, uint256 quantity)
        external
        view
        returns (uint256[] memory taskIDs, uint256 nextCursor);

    // /// @notice Add completed task to mapping completedTasks
    // /// @param taskID Completed task id
    // /// @param user Address of a user
    // function addCompletedTask(
    //     uint256 taskID,
    //     address user
    // ) external;

    /// @notice get list of completed tasks
    /// @param user address of a user
    function getCompletedTasks(address user)
        external
        view
        returns (uint256[] memory);

    /// @notice Increase the earned amount of a user
    /// @param user The address of the member
    /// @param amount1 The amount to increase of token1
    /// @param amount2 The amount to increase of token2
    /// @dev only Contract can call this function
    function increaseEarned(address user, uint256 amount1, uint256 amount2) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title An interface for a contract that is capable of deploying KPI Task Contract
/// @notice A contract that constructs tasks for a project must implement this to pass arguments to the KPI Task Contract
/// @author BARA
interface IKPITaskDeployer {
    /// @notice Get the parameters to be used in constructing a new task contract.
    /// @dev Called by the project contract constructor to fetch the parameters of the new task contract
    /// @return factory The factory contract, token default token address to be used in the project, token2 token address 2
    /// projectContract Project contract address, owner The owner address
    function parameters()
        external
        view
        returns (
            address factory,
            address token1,
            address token2,
            address projectContract,
            address owner
        );

    /// @notice Function to deploys a new task contract
    /// @dev This function is used from KPIProjectFactory to deploy a new task contract
    /// @param factory The factory contract
    /// @param token1 The default token address to be used in this project
    /// @param token2 The token number 2
    /// @param projectContract The address of the project contract
    /// @return task task address
    function deployTask(
        address factory,
        address token1,
        address token2,
        address projectContract,
        address owner
    ) external returns (address task);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title The interface for the KPI Task Events
/// @author BARA
interface IKPITaskEvents {
    /// @notice Emitted when the project owner create task
    /// @param projectContract address of the project contract
    /// @param taskID ID of the new created task
    /// @param reward Task reward
    event TaskCreated(
        address indexed projectContract,
        uint256 indexed taskID,
        uint256 indexed reward,
        uint256 reward2
    );

    /// @notice Emitted when task is assigned to someone
    /// @param taskID ID of the task
    /// @param assignee Address of assignee
    event TaskAssigned(uint256 indexed taskID, address indexed assignee);

    /// @notice Emitted when a task is waiting for approval
    /// @param projectContract Address of the project contract
    /// @param taskID ID of the task
    /// @param status Task status
    event WaitingForApproval(
        address indexed projectContract,
        uint256 indexed taskID,
        uint256 indexed status
    );

    /// @notice Emitted when a task is penalized
    /// @param taskID ID of the task
    /// @param amount1 Penalize amount with token1
    /// @param amount2 Penalize amount with token2
    /// @param assignee Task assignee
    event Penalized(
        uint256 indexed taskID,
        uint256 indexed amount1,
        uint256 indexed amount2,
        address assignee
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Task states that can change
interface IKPITaskStates {
    /// @notice get task by task id
    /// @param taskID The id of task
    /// @return name Task name, description Task description, status Task status, createdAt Task created time, updatedAt update time, submitAt Task submit time, deadline Task deadline,
    /// assignee Task assignee, totalReward Task total reward, remaining Task remaining reward, isExist Task is exist
    function getTask(uint256 taskID)
        external
        view
        returns (
            bytes32 name,
            bytes32 description,
            uint256 status,
            uint256 createdAt,
            uint256 startAt,
            uint256 updatedAt,
            uint256 submitAt,
            uint256 deadline,
            address assignee,
            bool isExist
        );

    /// @notice get task reward detail by id
    /// @param taskID The id of task
    /// @return totalReward1 total reward of default token, remaining remaining of default token, totalReward2 total reward of token2,
    /// remaining2 remaining of token2
    function getTaskReward(uint256 taskID) external view returns (
        uint256 totalReward1,
        uint256 remaining1,
        uint256 totalReward2,
        uint256 remaining2
    );

    /// @notice get task depositor address
    /// @dev get address of the task depositor to transfer remaining reward
    /// or penalty to this address
    /// @param taskID The id of task
    function getDepositor(uint256 taskID) external view returns (address);

    /// @notice get this task contract information
    function taskContractInfo()
        external
        view
        returns (
            address factory,
            address token1,
            address token2,
            address projectContract,
            address paymentContract,
            address controlContract,
            address owner,
            uint256 taskCount
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title TaskStatus
/// @notice A library for KPI Task status
/// @dev Used in KPITask.sol
library TaskStatus {
    uint256 internal constant TODO = 0;
    uint256 internal constant IN_PROGRESS = 1;
    uint256 internal constant WAITING_FOR_APPROVAL = 2;
    uint256 internal constant DONE = 3;
    uint256 internal constant LATE = 4;
    /// @dev This nearly done status is that the task is almost done or the task is late
    /// due to some problems and the task owner still want to give all the rewards to the task assignee
    uint256 internal constant NEARLY_DONE = 5;
    uint256 internal constant CANCELED = 6;
    uint256 internal constant PENALIZED = 7;
    uint256 internal constant REJECTED = 8;

    /// @notice check if the task can be claim reward by a user
    /// @dev call this function to check when a member claim reward from a task
    /// @param status The task status
    function canClaimTask(uint256 status) external pure returns (bool) {
        if (status == DONE || status == LATE || status == NEARLY_DONE) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be received by a user
    /// @dev call this function to check when a member receive a task
    /// @param status The task status
    /// @param assignee The current task assignee
    /// @param user The user address
    function checkFreeTask(
        uint256 status,
        address assignee,
        address user
    ) external pure returns (bool) {
        if (
            checkAvailableTask(status) &&
            (assignee == address(0) || assignee == user)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task is available to be received
    /// @dev call this function to check if status is TODO
    /// @param status The task status
    function checkAvailableTask(uint256 status) public pure returns (bool) {
        if (status == TODO) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be finished
    /// @dev call this function to check if a task can be finish by its status
    /// @param status The task status
    function canFinishTask(uint256 status) external pure returns (bool) {
        if (status == TODO || status == IN_PROGRESS) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be penalized
    /// @dev call this function to check if a task can be penalized by its status
    /// @param status The task status
    function canPenalizeTask(uint256 status) external pure returns (bool) {
        if (status == IN_PROGRESS || status == WAITING_FOR_APPROVAL) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be canceled
    /// @dev call this function to check if a task can be canceled by its status
    /// @param status The task status
    function canCancelTask(uint256 status) external pure returns (bool) {
        if (
            status == TODO ||
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be approved
    /// @dev call this function to check if a task can be approved by its status
    /// @param status The task status
    function canApproveTask(uint256 status) external pure returns (bool) {
        if (status == WAITING_FOR_APPROVAL || status == IN_PROGRESS) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be reset
    /// @dev call this function to check if a task can be reset by its status
    /// @param status The task status
    function canResetTask(uint256 status) external pure returns (bool) {
        if (status == CANCELED || status == PENALIZED || status == REJECTED) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be forced finish
    /// @dev call this function to check if a task can be forced finish by its status
    /// @param status The task status
    function canForceDone(uint256 status) external pure returns (bool) {
        if (
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL ||
            status == LATE
        ) {
            return true;
        } else {
            return false;
        }
    }

    function canDepositTask(uint256 status) external pure returns (bool) {
        if (
            status == TODO ||
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be assigned
    /// @dev call this function to check if a task can be assigned by its status
    /// @param status The task status
    function canSetAssignee(uint256 status) external pure returns (bool) {
        if (status == TODO) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if admin can change deadline of a task
    /// @param status The task status
    function canSetDeadline(uint256 status) external pure returns (bool) {
        if (status == TODO || status == IN_PROGRESS) {
            return true;
        } else {
            return false;
        }
    }

    function canDropTask(uint256 status) external pure returns (bool) {
        if (status == TODO || status == IN_PROGRESS || status == WAITING_FOR_APPROVAL) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if user can change isAutoClaim property of a task
    /// @param status The task status
    function canSetAutoClaim(uint256 status) external pure returns (bool) {
        if (
            status == TODO ||
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL
        ) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "../interface/task/IKPITask.sol";
import "../interface/task/IKPITaskDeployer.sol";
import "../interface/task/IKPITaskControl.sol";
import "../interface/project/IKPIProject.sol";
import "../interface/payment/IKPIPayment.sol";
import "../libraries/TaskStatus.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract KPITask is IKPITask {
    using SafeERC20 for IERC20;
    struct TaskContractInfo {
        address factory;
        address token1;
        address token2;
        address projectContract;
        address paymentContract;
        address controlContract;
        address owner;
        uint256 taskCount;
    }
    struct Task {
        bytes32 name;
        bytes32 description;
        uint256 status;
        uint256 createdAt;
        uint256 startAt;
        uint256 updatedAt;
        uint256 submitAt;
        uint256 deadline;
        address assignee;
        bool isExist;
    }
    struct TaskReward {
        uint256 totalReward1;
        uint256 remaining1;
        uint256 totalReward2;
        uint256 remaining2;
    }
    /// @inheritdoc IKPITaskStates
    TaskContractInfo public override taskContractInfo;
    /// @inheritdoc IKPITaskStates
    mapping(uint256 => Task) public override getTask;
    /// @inheritdoc IKPITaskStates
    mapping(uint256 => TaskReward) public override getTaskReward;
    /// @inheritdoc IKPITaskStates
    mapping(uint256 => address) public override getDepositor;

    constructor() {
        (
            address factory,
            address token1,
            address token2,
            address projectContract,
            address owner
        ) = IKPITaskDeployer(msg.sender).parameters();
        taskContractInfo.factory = factory;
        taskContractInfo.token1 = token1;
        taskContractInfo.token2 = token2;
        taskContractInfo.projectContract = projectContract;
        taskContractInfo.owner = owner;
    }

    /// @inheritdoc IKPITaskActions
    function createTask(
        bytes32 name,
        bytes32 description,
        uint256 reward1,
        uint256 reward2,
        uint256 deadline
    ) external override returns (uint256 newTaskID) {
        require(reward1 > 0);
        require(deadline > block.timestamp);
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        taskContractInfo.taskCount += 1;
        newTaskID = taskContractInfo.taskCount;
        getTask[newTaskID] = Task({
            name: name,
            description: description,
            status: TaskStatus.TODO,
            createdAt: block.timestamp,
            startAt: 0,
            updatedAt: block.timestamp,
            deadline: deadline,
            submitAt: 0,
            assignee: address(0),
            isExist: true
        });
        getTaskReward[newTaskID] = TaskReward({
            totalReward1: 0,
            remaining1: 0,
            totalReward2: 0,
            remaining2: 0
        });
        getDepositor[newTaskID] = msg.sender;
        IKPIPayment(taskContractInfo.paymentContract).depositTask(
            newTaskID,
            msg.sender,
            reward1,
            0
        );
        if (reward2 > 0) {
            IKPIPayment(taskContractInfo.paymentContract).depositTask(
                newTaskID,
                msg.sender,
                reward2,
                1
            );
        }
        IKPITaskControl(taskContractInfo.controlContract).createTask(newTaskID);
        emit TaskCreated(taskContractInfo.projectContract, newTaskID, reward1, reward2);
        return newTaskID;
    }

    /// @inheritdoc IKPITaskActions
    function receiveTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        require(IKPIProject(taskContractInfo.projectContract).isMember(msg.sender));
        require(
            TaskStatus.checkFreeTask(
                getTask[taskID].status,
                getTask[taskID].assignee,
                msg.sender
            )
        );
        uint256 guarantee = IKPITaskControl(taskContractInfo.controlContract).guarantee(
            msg.sender
        );
        ( , , uint256 guaranteeAmount, , , bool depositChecking, ) = IKPIProject(
            taskContractInfo.projectContract
        ).projectInfo();
        if (guarantee < guaranteeAmount && depositChecking) {
            uint256 missing = guaranteeAmount - guarantee;
            IKPIPayment(taskContractInfo.paymentContract).depositGuaranteeAmount(
                msg.sender,
                missing
            );
            IKPITaskControl(taskContractInfo.controlContract).changeMemberGuarantee(
                msg.sender,
                guaranteeAmount
            );
        }
        getTask[taskID].status = TaskStatus.IN_PROGRESS;
        IKPITaskControl(taskContractInfo.controlContract).receiveTask(
            msg.sender,
            taskID
        );
        getTask[taskID].assignee = msg.sender;
        getTask[taskID].startAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function finishTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(TaskStatus.canFinishTask(task.status));
        require(task.assignee == msg.sender);
        task.status = TaskStatus.WAITING_FOR_APPROVAL;
        IKPITaskControl(taskContractInfo.controlContract).finishTask(
            msg.sender,
            taskID
        );
        task.updatedAt = block.timestamp;
        task.submitAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function penalizeTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(TaskStatus.canPenalizeTask(task.status));
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        require(task.assignee != address(0));
        require(task.deadline < block.timestamp);
        uint256 guarantee = IKPITaskControl(taskContractInfo.controlContract).guarantee(
            task.assignee
        );
        (uint256 totalPenalized1, uint256 totalPenalized2) = IKPIPayment(taskContractInfo.paymentContract)
            .penalized(taskID, task.assignee, getTaskReward[taskID].remaining1, getTaskReward[taskID].remaining2, guarantee);
        IKPITaskControl(taskContractInfo.controlContract).mapIndexToPenalizedTask(
            task.assignee,
            taskID
        );
        task.status = TaskStatus.PENALIZED;
        task.updatedAt = block.timestamp;

        emit Penalized(taskID, totalPenalized1, totalPenalized2, task.assignee);
    }

    /// @inheritdoc IKPITaskActions
    function cancelTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(TaskStatus.canCancelTask(task.status));
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        IKPIPayment(taskContractInfo.paymentContract).canceled(taskID, getTaskReward[taskID].remaining1, getTaskReward[taskID].remaining2);
        if (task.assignee != address(0)) {
            if (task.status != TaskStatus.TODO) {
                IKPITaskControl(taskContractInfo.controlContract).cancelTask(
                    task.assignee,
                    taskID
                );
            }
            task.assignee = address(0);
        }
        task.status = TaskStatus.CANCELED;
        task.updatedAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function approveTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(TaskStatus.canApproveTask(task.status));
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        if (task.submitAt > task.deadline) {
            task.status = TaskStatus.LATE;
            IKPITaskControl(taskContractInfo.controlContract).mapIndexToLateTask(
                task.assignee,
                taskID
            );
        } else {
            task.status = TaskStatus.DONE;
            IKPITaskControl(taskContractInfo.controlContract).mapIndexToCompletedTask(
                task.assignee,
                taskID
            );
        }
        uint256 taskReward1 = IKPIPayment(taskContractInfo.paymentContract).withdrawTask(
            taskID,
            task.status,
            task.assignee,
            getTaskReward[taskID].remaining1,
            0
        );
        uint256 taskReward2 = 0;
        if (getTaskReward[taskID].remaining2 > 0) {
            taskReward2 = IKPIPayment(taskContractInfo.paymentContract).withdrawTask(
                taskID,
                task.status,
                task.assignee,
                getTaskReward[taskID].remaining2,
                1
            );
        }
        IKPITaskControl(taskContractInfo.paymentContract).increaseEarned(
            task.assignee,
            taskReward1,
            taskReward2
        );
        IKPITaskControl(taskContractInfo.controlContract).approveTask(
            task.assignee,
            taskID
        );
        task.updatedAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function resetTask(
        uint256 taskID,
        uint256 newAmount1,
        uint256 newAmount2,
        uint256 newDeadline
    ) external override {
        require(getTask[taskID].isExist);
        require(newDeadline > block.timestamp);
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        Task storage task = getTask[taskID];
        require(TaskStatus.canResetTask(task.status));
        getDepositor[taskID] = msg.sender;
        task.assignee = address(0);
        task.deadline = newDeadline;
        task.status = TaskStatus.TODO;
        IKPIPayment(taskContractInfo.paymentContract).resetTask(
            taskID,
            msg.sender,
            newAmount1,
            0
        );
        if (newAmount2 > 0) {
            IKPIPayment(taskContractInfo.paymentContract).resetTask(
                taskID,
                msg.sender,
                newAmount2,
                1
            );
        }
        IKPITaskControl(taskContractInfo.controlContract).resetTask(
            task.assignee,
            taskID
        );
        task.updatedAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function forceDone(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        require(getTaskReward[taskID].remaining1 != 0);
        Task storage task = getTask[taskID];
        require(TaskStatus.canForceDone(task.status));
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        if (task.status != TaskStatus.LATE) {
            IKPITaskControl(taskContractInfo.controlContract).mapIndexToCompletedTask(
                task.assignee,
                taskID
            );
        }
        uint256 amount1 = IKPIPayment(taskContractInfo.paymentContract).withdrawTask(
            taskID,
            task.status,
            task.assignee,
            getTaskReward[taskID].remaining1,
            0
        );
        uint256 amount2 = 0;
        if (getTaskReward[taskID].remaining2 > 0) {
            amount2 = IKPIPayment(taskContractInfo.paymentContract).withdrawTask(
                taskID,
                task.status,
                task.assignee,
                getTaskReward[taskID].remaining2,
                1
            );
        }
        IKPITaskControl(taskContractInfo.controlContract).increaseEarned(
            task.assignee,
            amount1,
            amount2
        );
        IKPITaskControl(taskContractInfo.controlContract).forceDone(
            task.assignee,
            taskID
        );
        task.status = TaskStatus.NEARLY_DONE;
        task.updatedAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function claimTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(TaskStatus.canClaimTask(task.status));
        require(task.assignee == msg.sender);
        TaskReward storage taskReward = getTaskReward[taskID];
        require(taskReward.remaining1 > 0 || taskReward.remaining2 > 0);
        uint256 amount1 = 0;
        if (taskReward.remaining1 > 0) {
            amount1 = IKPIPayment(taskContractInfo.paymentContract).withdrawTask(
                taskID,
                task.status,
                msg.sender,
                taskReward.remaining1,
                0
            );
        }
        uint256 amount2 = 0;
        if (taskReward.remaining2 > 0) {
            amount2 = IKPIPayment(taskContractInfo.paymentContract).withdrawTask(
                taskID,
                task.status,
                msg.sender,
                taskReward.remaining2,
                1
            );
        } 
        IKPITaskControl(taskContractInfo.controlContract).increaseEarned(
            task.assignee,
            amount1,
            amount2
        );
    }

    /// @inheritdoc IKPITaskActions
    function withdrawGuarantee() external override {
        uint256 guarantee = IKPITaskControl(taskContractInfo.controlContract).guarantee(
            msg.sender
        );
        uint256 inProgress = IKPITaskControl(taskContractInfo.controlContract)
            .inProgress(msg.sender);
        require(inProgress == 0);
        require(guarantee > 0);
        IKPITaskControl(taskContractInfo.controlContract).changeMemberGuarantee(
            msg.sender,
            0
        );
        IKPIPayment(taskContractInfo.paymentContract).withdrawGuaranteeAmount(
            msg.sender,
            guarantee
        );
    }

    /// @inheritdoc IKPITaskActions
    function depositTask(uint256 taskID, uint256 reward, uint8 whichToken) external override {
        require(getTask[taskID].isExist);
        require(getDepositor[taskID] == msg.sender);
        Task storage task = getTask[taskID];
        require(TaskStatus.canDepositTask(task.status));

        IKPIPayment(taskContractInfo.paymentContract).depositTask(
            taskID,
            msg.sender,
            reward,
            whichToken
        );
    }

    /// @inheritdoc IKPITaskActions
    function assignTask(uint256 taskID, address member) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(TaskStatus.canSetAssignee(task.status));
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        task.assignee = member;

        emit TaskAssigned(taskID, member);
    }

    /// @inheritdoc IKPITaskActions
    function changeDescription(uint256 taskID, bytes32 description)
        external
        override
    {
        require(getTask[taskID].isExist);
        require(getTaskReward[taskID].remaining1 > 0);
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        getTask[taskID].description = description;
    }

    /// @inheritdoc IKPITaskActions
    function changeDeadline(uint256 taskID, uint256 deadline)
        external
        override
    {
        require(getTask[taskID].isExist);
        require(getTaskReward[taskID].remaining1 > 0);
        require(TaskStatus.canSetDeadline(getTask[taskID].status));
        require(IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        require(deadline > block.timestamp);
        getTask[taskID].deadline = deadline;
    }

    /// @inheritdoc IKPITaskActions
    function transfer(address to, uint256 amount, uint8 whichToken)
        external
        override
        onlyPaymentContract
    {
        IERC20 tokenERC20 = IERC20(taskContractInfo.token1);
        if (whichToken == 1) {
            tokenERC20 = IERC20(taskContractInfo.token2);
        }
        tokenERC20.safeTransfer(to, amount);
    }

    /// @inheritdoc IKPITaskActions
    function dropTask(uint256 taskID) external override {
        require(getTask[taskID].isExist);
        Task storage task = getTask[taskID];
        require(msg.sender == task.assignee || IKPIProject(taskContractInfo.projectContract).isAdmin(msg.sender));
        require(TaskStatus.canDropTask(task.status));
        require(getTaskReward[taskID].remaining1 > 0 || getTaskReward[taskID].remaining2 > 0);
        if (task.status != TaskStatus.TODO) {
            if (msg.sender == task.assignee) {
                uint256 guarantee = IKPITaskControl(taskContractInfo.controlContract)
                    .guarantee(msg.sender);
                IKPITaskControl(taskContractInfo.controlContract).changeMemberGuarantee(
                    task.assignee,
                    0
                );
                IKPIPayment(taskContractInfo.paymentContract).dropTask(
                    getDepositor[taskID],
                    guarantee
                );
            }
            task.status = TaskStatus.TODO;
        }
        IKPITaskControl(taskContractInfo.controlContract).dropTask(
            task.assignee,
            taskID
        );
        task.assignee = address(0);
        task.updatedAt = block.timestamp;
    }

    /// @inheritdoc IKPITaskActions
    function setTotalReward(uint256 taskID, uint256 totalReward, uint8 whichToken)
        external
        override
        onlyPaymentContract
    {
        if (whichToken == 0) {
            getTaskReward[taskID].totalReward1 = totalReward;
            getTaskReward[taskID].remaining1 = getTaskReward[taskID].remaining1 + totalReward;
        } else if (whichToken == 1) {
            getTaskReward[taskID].totalReward2 = totalReward;
            getTaskReward[taskID].remaining2 = getTaskReward[taskID].remaining2 + totalReward;
        }
    }

    /// @inheritdoc IKPITaskActions
    function setRemaining(uint256 taskID, uint256 remaining, uint8 whichToken)
        external
        override
        onlyPaymentContract
    {
        if (whichToken == 0) {
            getTaskReward[taskID].remaining1 = remaining;
        } else if (whichToken == 2) {
            getTaskReward[taskID].remaining2 = remaining;
        }
    }

    ///@inheritdoc IKPITaskActions
    function setPaymentContract(address payment) external override onlyFactory {
        taskContractInfo.paymentContract = payment;
    }

    ///@inheritdoc IKPITaskActions
    function setTaskControlContract(address taskControl)
        external
        override
        onlyFactory
    {
        taskContractInfo.controlContract = taskControl;
    }

    modifier onlyPaymentContract() {
        require(
            msg.sender == taskContractInfo.paymentContract ||
                msg.sender == address(this)
        );
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == taskContractInfo.factory);
        _;
    }
}