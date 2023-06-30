/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: BUSL-1.1
//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IStaking.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStaking {
    /* ========== STATE VARIABLES ========== */
    function stakingToken() external returns (IERC20);

    function totalSupply() external returns (uint256);

    function balances(address _account) external returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function recoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) external;

    /* ========== EVENTS ========== */

    // Emitted on staking
    event Staked(address indexed account, uint256 amount);

    // Emitted on withdrawal (including exit)
    event Withdrawn(address indexed account, uint256 amount);

    // Emitted on token recovery
    event Recovered(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
}

// File: contracts/interfaces/IStakingFee.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStakingFee is IStaking {
    /* ========== STATE VARIABLES ========== */
    function feesUnit() external returns (uint256);

    function maxFee() external returns (uint256);

    function withdrawalFeeSchedule(uint256) external returns (uint256);

    function withdrawalFeesBps(uint256) external returns (uint256);

    function depositFeeBps() external returns (uint256);

    function collectedFees() external returns (uint256);

    function userLastStakedTime(address _user) external view returns (uint32);

    /* ========== VIEWS ========== */

    function depositFee(uint256 _depositAmount) external view returns (uint256);

    function withdrawalFee(
        address _account,
        uint256 _withdrawalAmount
    ) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverFees(address _recipient) external;
    
    /* ========== EVENTS ========== */

    // Emitted when fees are (re)configured
    event FeesSet(
        uint16 _depositFeeBps,
        uint16[] _withdrawalFeesBps,
        uint32[] _feeSchedule
    );

    // Emitted when a deposit fee is collected
    event DepositFeesCollected(address indexed _user, uint256 _amount);

    // Emitted when a withdrawal fee is collected
    event WithdrawalFeesCollected(address indexed _user, uint256 _amount);

    // Emitted when fees are recovered by governance
    event FeesRecovered(uint256 _amount);
}

// File: contracts/interfaces/IStakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;


interface IStakingRewards is IStakingFee {
    /* ========== STATE VARIABLES ========== */

    function rewardTokens(uint256) external view returns (IERC20);

    function rewardTokenAddresses(
        address _rewardAddress
    ) external view returns (bool);

    function periodFinish() external view returns (uint256);

    function rewardsDuration() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRates(
        address _rewardAddress
    ) external view returns (uint256);

    function rewardPerTokenStored(
        address _rewardAddress
    ) external view returns (uint256);

    // wallet address => token address => amount
    function userRewardPerTokenPaid(
        address _walletAddress,
        address _tokenAddress
    ) external view returns (uint256);

    function rewards(
        address _walletAddress,
        address _tokenAddress
    ) external view returns (uint256);

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken(
        address _tokenAddress
    ) external view returns (uint256);

    function earned(
        address _tokenAddress,
        address _account
    ) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getReward(address _tokenAddress, address _recipient) external;

    function getRewards(address _recipient) external;

    // Must send reward before calling this!
    function startEmission(
        uint256[] memory _rewards,
        uint256 _duration
    ) external;

    function stopEmission(address _refundAddress) external;

    function recoverLeftoverReward(
        address _tokenAddress,
        address _recipient
    ) external;

    function addRewardToken(address _tokenAddress) external;

    function rewardTokenIndex(
        address _tokenAddress
    ) external view returns (int8);

    /* ========== EVENTS ========== */

    // Emitted when a reward is paid to an account
    event RewardPaid(
        address indexed _token,
        address indexed _account,
        uint256 _reward
    );

    // Emitted when a leftover reward is recovered
    event LeftoverRewardRecovered(address indexed _recipient, uint256 _amount);

    // Emitted when rewards emission is started
    event RewardsEmissionStarted(uint256[] _rewards, uint256 _duration);

    // Emitted when rewards emission ends
    event RewardsEmissionEnded();
}

// File: @openzeppelin/[email protected]/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/[email protected]/security/ReentrancyGuard.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/ERC20.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Staking.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;






/**
 * Base contract implementing simple ERC20 token staking functionality (no staking rewards).
 */
contract Staking is ReentrancyGuard, Ownable, IStaking {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Staking token interface
    IERC20 public immutable stakingToken;

    /// @notice Total supply of the staking token
    uint256 public totalSupply;

    /// @notice Account balances
    mapping(address => uint256) public balances;

    // Scaling factor: supply is always stored as wei (10**18) regardless of the token's decimals
    uint256 private supplyScalingFactor;

    /* ========== CONSTRUCTOR ========== */

    /// @param _stakingTokenAddress address of the token used for staking (must be ERC20)
    constructor(address _stakingTokenAddress) {
        require(_stakingTokenAddress != address(0), "E1");
        stakingToken = IERC20(_stakingTokenAddress);
        supplyScalingFactor = 1e18 / 10**ERC20(_stakingTokenAddress).decimals();
    }

    /**
     * @dev Stake tokens.
     * Note: the contract must have sufficient allowance for the staking token.
     * @param _amount amount to stake
     */
    function stake(uint256 _amount) public nonReentrant {
        uint256 originalAmount = _amount;
        _amount = _beforeStake(msg.sender, _amount);
        require(_amount > 0 && originalAmount > 0, "E2"); // Check after the hook
        totalSupply += _amount * supplyScalingFactor;
        balances[msg.sender] += _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), originalAmount);
        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraw previously staked tokens.
     * @param _amount amount to withdraw
     */
    function withdraw(uint256 _amount) public nonReentrant {
        uint256 originalAmount = _amount;
        _amount = _beforeWithdraw(msg.sender, _amount);
        require(
            _amount > 0 && _amount <= balances[msg.sender] && originalAmount <= balances[msg.sender],
            "E3"
        ); // Check after the hook
        totalSupply -= originalAmount * supplyScalingFactor;
        balances[msg.sender] -= originalAmount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Exit the farm, i.e., withdraw the entire token balance of the calling account
     */
    function exit() external {
        _beforeExit(msg.sender);
        withdraw(balances[msg.sender]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Recover ERC20 tokens held in the contract.
     * Note: privileged governance function to recover tokens mistakenly sent to this contract address.
     * This function cannot be used to withdraw staking tokens.
     * @param _tokenAddress address of the token to recover
     * @param _recipient recovery address
     * @param _amount amount to withdraw
     * @ return withdrawn amount (may differ from input amount due to e.g., fees)
     */
    function recoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) external nonReentrant onlyOwner {
        require(
            _tokenAddress != address(stakingToken),
            "E4"
        );
        _beforeRecoverERC20(_tokenAddress, _recipient, _amount);
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(_recipient, _amount);
        emit Recovered(_tokenAddress, _recipient, _amount);
    }

    /* ========== HOOKS ========== */

    /**
     * @dev Internal hook called before staking (in the stake() function).
     * @ param _account staker address
     * @param _amount amount being staken
     * @return amount to stake (may be changed by the hook)
     */
    function _beforeStake(
        address /*_account*/,
        uint256 _amount
    ) internal virtual returns (uint256) {
        return _amount;
    }

    /**
     * @dev Internal hook called before withdrawing (in the withdraw() function).
     * @ param _account withdrawer address
     * @param _amount amount being withdrawn
     * @return amount to withdraw (may be changed by the hook)
     */
    function _beforeWithdraw(
        address /*_account*/,
        uint256 _amount
    ) internal virtual returns (uint256) {
        return _amount;
    }

    /**
     * @dev Internal hook called before exiting (in the exit() function).
     * Note: since exit() calls withdraw() internally, the _beforeWithdraw() hook fill fire too.
     * @param _account address exiting
     */
    function _beforeExit(address _account) internal virtual {}

    /**
     * @dev Internal hook called before recovering tokens (in the recoverERC20() function).
     * @param _tokenAddress address of the token being recovered
     * @param _recipient recovery address
     * @param _amount amount being withdrawn
     */
    function _beforeRecoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) internal virtual {}
}

// File: contracts/StakingFee.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;



/**
 * Contract implementing simple ERC20 token staking functionality and supporting deposit/withdrawal fees (no staking rewards).
 */
contract StakingFee is Staking, IStakingFee {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Constant Fee Unit (1e4)
    uint256 public constant feesUnit = 10000;

    /// @notice Maximum fee (20%)
    uint256 public constant maxFee = 2000;

    /// @notice Schedule of withdrawal fees represented as a sorted array of durations
    /// @dev example: 10% after 1 hour, 1% after a day, 0% after a week => [3600, 86400]
    uint256[] public withdrawalFeeSchedule;

    /// @notice Withdrawal fees described in basis points (fee unit) represented as an array of the same length as withdrawalFeeSchedule
    /// @dev example: 10% after 1 hour, 1% after a day, 0% after a week => [1000, 100]
    uint256[] public withdrawalFeesBps;

    /// @notice Deposit (staking) fee in basis points (fee unit)
    uint256 public depositFeeBps;

    /// @notice Counter of collected fees
    uint256 public collectedFees;

    /// @notice Last staking time for each user
    mapping(address => uint32) public userLastStakedTime;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _stakingTokenAddress address of the token used for staking (must be ERC20)
     * @param _depositFeeBps deposit fee in basis points
     * @param _withdrawalFeesBps aligned to fee schedule
     * @param _withdrawalFeeSchedule assumes a sorted array
     */
    constructor(
        address _stakingTokenAddress,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) Staking(_stakingTokenAddress) {
        _setFees(_depositFeeBps, _withdrawalFeesBps, _withdrawalFeeSchedule);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Calculate the deposit fee for a given amount.
     * @param _depositAmount amount to stake
     * @return fee paid upon deposit
     */
    function depositFee(uint256 _depositAmount) public view returns (uint256) {
        return depositFeeBps > 0 ? (_depositAmount * depositFeeBps) / feesUnit : 0;
    }

    /**
     * @dev Calculate the withdrawal fee for a given amount.
     * @param _account user wallet address
     * @param _withdrawalAmount amount to withdraw
     * @return fee paid upon withdrawal
     */
    function withdrawalFee(
        address _account,
        uint256 _withdrawalAmount
    ) public view returns (uint256) {
        uint256 userLastStakedTimestampDiff = block.timestamp - userLastStakedTime[_account];
        uint256 withdrawalFeeAmount;
        for (uint i = 0; i < withdrawalFeeSchedule.length; ++i) {
            if (userLastStakedTimestampDiff < withdrawalFeeSchedule[i]) {
                withdrawalFeeAmount = (_withdrawalAmount * withdrawalFeesBps[i]) / feesUnit;
                break;
            }
        }
        return withdrawalFeeAmount;
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Recover collected fees held in the contract.
     * Note: privileged function for governance
     * @param _recipient fee recovery address
     */
    function recoverFees(address _recipient) external onlyOwner nonReentrant {
        _beforeRecoverFees(_recipient);
        uint256 previousFees = collectedFees;
        collectedFees = 0;
        emit FeesRecovered(previousFees);
        stakingToken.safeTransfer(_recipient, previousFees);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Configure the fees for this contract.
     * @param _depositFeeBps deposit fee in basis points
     * @param _withdrawalFeesBps withdrawal fees in basis points
     * @param _withdrawalFeeSchedule withdrawal fees schedule
     */
    function _setFees(
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    ) private {
        require(_withdrawalFeeSchedule.length == _withdrawalFeesBps.length && _withdrawalFeeSchedule.length <= 10 && _depositFeeBps <= maxFee, "E5");

        uint32 lastFeeSchedule = 0;
        uint256 lastWithdrawalFee = maxFee + 1;

        for (uint i = 0; i < _withdrawalFeeSchedule.length; ++i) {
            require(_withdrawalFeeSchedule[i] > lastFeeSchedule, "E7");
            require(_withdrawalFeesBps[i] < lastWithdrawalFee, "E8");
            lastFeeSchedule = _withdrawalFeeSchedule[i];
            lastWithdrawalFee = _withdrawalFeesBps[i];
        }

        withdrawalFeeSchedule = _withdrawalFeeSchedule;
        withdrawalFeesBps = _withdrawalFeesBps;
        depositFeeBps = _depositFeeBps;

        emit FeesSet(
            _depositFeeBps,
            _withdrawalFeesBps,
            _withdrawalFeeSchedule
        );
    }

    /* ========== HOOKS ========== */

    /**
     * @dev Override _beforeStake() hook to collect the deposit fee and update associated state
     */
    function _beforeStake(
        address _account,
        uint256 _amount
    ) internal virtual override returns (uint256) {
        uint256 fee = depositFee(_amount);
        userLastStakedTime[_account] = uint32(block.timestamp);
        if (fee > 0) {
            collectedFees += fee;
            emit DepositFeesCollected(_account, fee);
        }
        return super._beforeStake(_account, _amount - fee);
    }

    /**
     * @dev Override _beforeWithdrawl() hook to collect the withdrawal fee and update associated state
     */
    function _beforeWithdraw(
        address _account,
        uint256 _amount
    ) internal virtual override returns (uint256) {
        uint256 fee = withdrawalFee(_account, _amount);
        if (fee > 0) {
            collectedFees += fee;
            emit WithdrawalFeesCollected(_account, fee);
        }
        return super._beforeWithdraw(_account, _amount - fee);
    }

    /**
     * @dev Internal hook called before recovering fees (in the recoverFees() function).
     * @param _recipient recovery address
     */
    function _beforeRecoverFees(address _recipient) internal virtual {}
}

// File: contracts/StakingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;



/**
 * Contract implementing simple ERC20 token staking functionality with staking rewards and deposit/withdrawal fees.
 */
contract StakingRewards is StakingFee, IStakingRewards {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice List of reward token interfaces
    IERC20[] public rewardTokens;

    /// @notice Reward token addresses (maps every reward token address to true, others to false)
    mapping(address => bool) public rewardTokenAddresses;

    /// @notice Timestamp when rewards stop emitting
    uint256 public periodFinish;

    /// @notice Duration for reward emission
    uint256 public rewardsDuration;

    /// @notice Last time the rewards were updated
    uint256 public lastUpdateTime;

    /// @notice Reward token rates (maps every reward token to an emission rate, i.e., how many tokens emitted per second)
    mapping(address => uint256) public rewardRates;

    /// @notice How many tokens are emitted per staked token
    mapping(address => uint256) public rewardPerTokenStored;

    /// @notice How many reward tokens were paid per user (token address => wallet address => amount)
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;

    /// @notice Accumulator of reward tokens per user (token address => wallet address => amount)
    mapping(address => mapping(address => uint256)) public rewards;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _stakingTokenAddress address of the token used for staking (must be ERC20)
     * @param _rewardTokenAddresses addresses the reward tokens (must be ERC20)
     * @param _rewardsDuration reward emission duration
     * @param _depositFeeBps deposit fee in basis points
     * @param _withdrawalFeesBps aligned to fee schedule
     * @param _withdrawalFeeSchedule assumes a sorted array
     */
    constructor(
        address _stakingTokenAddress,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    )
        StakingFee(
            _stakingTokenAddress,
            _depositFeeBps,
            _withdrawalFeesBps,
            _withdrawalFeeSchedule
        )
    {
        require(_rewardTokenAddresses.length > 0, "E9");
        // update reward data structures
        for (uint i = 0; i < _rewardTokenAddresses.length; ++i) {
            address tokenAddress = _rewardTokenAddresses[i];
            _addRewardToken(tokenAddress);
        }
        rewardsDuration = _rewardsDuration;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Return the last time rewards are applicable (the lowest of the current timestamp and the rewards expiry timestamp).
     * @return timestamp
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @notice Return the reward per staked token for a given reward token address.
     * @param _tokenAddress reward token address
     * @return amount of reward per staked token
     */
    function rewardPerToken(
        address _tokenAddress
    ) public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored[_tokenAddress];
        }
        return
            rewardPerTokenStored[_tokenAddress] +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRates[_tokenAddress] *
                10**ERC20(_tokenAddress).decimals()) /
            totalSupply;
    }

    /**
     * @notice Return the total reward earned by a user for a given reward token address.
     * @param _tokenAddress reward token address
     * @param _account user wallet address
     * @return amount earned
     */
    function earned(
        address _tokenAddress,
        address _account
    ) public view returns (uint256) {
        return
            (balances[_account] *
                (rewardPerToken(_tokenAddress) -
                    userRewardPerTokenPaid[_tokenAddress][_account])) /
            10**ERC20(_tokenAddress).decimals() +
            rewards[_tokenAddress][_account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev claim the specified token reward for a staker
     * @param _tokenAddress the address of the reward token
     * @param _recipient the address of the staker that should receive the reward
     * @ return amount of reward received
     */
    function getReward(
        address _tokenAddress,
        address _recipient
    ) public nonReentrant updateRewards(_recipient) {
        return _getReward(_tokenAddress, _recipient);
    }

    /**
     * @dev claim rewards for all the reward tokens for the staker
     * @param _recipient address of the recipient to receive the rewards
     */
    function getRewards(
        address _recipient
    ) public nonReentrant updateRewards(_recipient) {
        for (uint i = 0; i < rewardTokens.length; ++i) {
            _getReward(address(rewardTokens[i]), _recipient);
        }
    }

    /**
     * @dev Start the emission of rewards to stakers. The owner must send reward tokens to the contract before calling this function.
     * Note: Can only be called by owner when the contract is not emitting rewards.
     * @param _rewards array of rewards amounts for each reward token
     * @param _duration duration in seconds for which rewards will be emitted
     */
    function startEmission(
        uint256[] memory _rewards,
        uint256 _duration
    )
        public
        virtual
        nonReentrant
        onlyOwner
        whenNotEmitting
        updateRewards(address(0))
    {
        require(_duration > 0, "E10");
        require(_rewards.length == rewardTokens.length, "E11");

        _beforeStartEmission(_rewards, _duration);

        rewardsDuration = _duration;

        for (uint i = 0; i < rewardTokens.length; ++i) {
            IERC20 token = rewardTokens[i];
            address tokenAddress = address(token);
            rewardRates[tokenAddress] = _rewards[i] / rewardsDuration;

            // Ensure the provided reward amount is not more than the balance in the contract.
            // This keeps the reward rate in the right range, preventing overflows due to
            // very high values of rewardRate in the earned and rewardsPerToken functions;
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            uint256 balance = rewardTokens[i].balanceOf(address(this));
            if (tokenAddress != address(stakingToken)) {
                require(
                    rewardRates[tokenAddress] <= balance / rewardsDuration,
                    "E3"
                );
            } else {
                // Handle carefully where rewardsToken is the same as stakingToken (need to subtract total supply)
                require(
                    rewardRates[tokenAddress] <=
                        (balance - totalSupply) / rewardsDuration,
                    "E3"
                );
            }
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardsEmissionStarted(_rewards, _duration);
    }

    /**
     * @dev stop the reward emission process and transfer the remaining reward tokens to a specified address
     * Note: can only be called by owner when the contract is currently emitting rewards
     * @param _refundAddress the address to receive the remaining reward tokens
     */
    function stopEmission(
        address _refundAddress
    ) external nonReentrant onlyOwner whenEmitting {
        _beforeStopEmission(_refundAddress);
        uint256 remaining = 0;
        if (periodFinish > block.timestamp) {
            remaining = periodFinish - block.timestamp;
        }

        periodFinish = block.timestamp;

        for (uint i = 0; i < rewardTokens.length; ++i) {
            IERC20 token = rewardTokens[i];
            address tokenAddress = address(token);
            uint256 refund = rewardRates[tokenAddress] * remaining;
            if (refund > 0) {
                token.safeTransfer(_refundAddress, refund);
            }
        }

        emit RewardsEmissionEnded();
    }

    /**
     * @dev recover leftover reward tokens and transfer them to a specified recipient
     * Note: can only be called by owner when the contract is not emitting rewards
     * @param _tokenAddress address of the reward token to be recovered
     * @param _recipient address to receive the recovered reward tokens
     */
    function recoverLeftoverReward(
        address _tokenAddress,
        address _recipient
    ) external onlyOwner whenNotEmitting {
        require(totalSupply == 0, "E12");
        if (rewardTokenAddresses[_tokenAddress]) {
            _beforeRecoverLeftoverReward(_tokenAddress, _recipient);
            IERC20 token = IERC20(_tokenAddress);
            uint256 amount = token.balanceOf(address(this));
            if (amount > 0) {
                token.safeTransfer(_recipient, amount);
            }
            emit LeftoverRewardRecovered(_recipient, amount);
        }
    }

    /**
     * @dev add a reward token to the contract
     * Note: can only be called by owner when the contract is not emitting rewards
     * @param _tokenAddress address of the new reward token
     */
    function addRewardToken(
        address _tokenAddress
    ) external onlyOwner whenNotEmitting {
        _addRewardToken(_tokenAddress);
    }

    /**
     * @dev Return the array index of the provided token address (if applicable)
     * @param _tokenAddress address of the LP token
     * @return the array index for _tokenAddress or -1 if it is not a reward token
     */
    function rewardTokenIndex(
        address _tokenAddress
    ) public view returns (int8) {
        if (rewardTokenAddresses[_tokenAddress]) {
            for (uint i = 0; i < rewardTokens.length; ++i) {
                if (address(rewardTokens[i]) == _tokenAddress) {
                    return int8(int256(i));
                }
            }
        }
        return -1;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Get the reward amount of a token for a specific recipient
     * @param _tokenAddress address of the token
     * @param _recipient address of the recipient
     */
    function _getReward(address _tokenAddress, address _recipient) private {
        require(msg.sender == owner() || msg.sender == _recipient, "E14");
        require(rewardTokenAddresses[_tokenAddress], "E13");
        uint256 reward = rewards[_tokenAddress][_recipient];
        if (reward > 0) {
            rewards[_tokenAddress][_recipient] = 0;
            IERC20(_tokenAddress).safeTransfer(_recipient, reward);
            emit RewardPaid(_tokenAddress, _recipient, reward);
        }
    }

    /**
     * @dev Add a token as a reward token
     * @param _tokenAddress address of the token to be added as a reward token
     */
    function _addRewardToken(address _tokenAddress) private {
        require(rewardTokens.length <= 15, "E15");
        require(_tokenAddress != address(0), "E1");
        if (!rewardTokenAddresses[_tokenAddress]) {
            rewardTokens.push(IERC20(_tokenAddress));
            rewardTokenAddresses[_tokenAddress] = true;
        }
    }

    /* ========== HOOKS ========== */

    /**
     * @dev Override _beforeStake() hook to ensure staking is only possible when rewards are emitting and update the rewards
     */
    function _beforeStake(
        address _account,
        uint256 _amount
    ) internal virtual override whenEmitting updateRewards(_account) returns (uint256) {
        return super._beforeStake(_account, _amount);
    }

    /**
     * @dev Override _beforeExit() hook to claim all rewards for the account exiting
     */
    function _beforeExit(address _account) internal virtual override {
        getRewards(_account); // getRewards calls updateRewards so we don't need to call it explicitly again here
        super._beforeExit(_account);
    }

    /**
     * @dev Override _beforeRecoverERC20() hook to prevent recovery of a reward token
     */
    function _beforeRecoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) internal virtual override {
        require(!rewardTokenAddresses[_tokenAddress], "E16");
        super._beforeRecoverERC20(_tokenAddress, _recipient, _amount);
    }

    /**
     * @dev Internal hook called before starting the emission process (in the startEmission() function).
     * @param _rewards array of rewards per token.
     * @param _duration emission duration.
     */
    function _beforeStartEmission(
        uint256[] memory _rewards,
        uint256 _duration
    ) internal virtual {}

    /**
     * @dev Internal hook called before stopping the emission process (in the stopEmission() function).
     * @param _refundAddress address to refund the remaining reward to
     */
    function _beforeStopEmission(address _refundAddress) internal virtual {}

    /**
     * @dev Internal hook called before recovering leftover rewards (in the recoverLeftoverRewards() function).
     * @param _tokenAddress address of the token to recover
     * @param _recipient address to recover the leftover rewards to
     */
    function _beforeRecoverLeftoverReward(
        address _tokenAddress,
        address _recipient
    ) internal virtual {}

    /* ========== MODIFIERS ========== */

    /**
     * @dev Modifier to update rewards of a given account.
     * @param _account account to update rewards for
     */
    modifier updateRewards(address _account) {
        for (uint i = 0; i < rewardTokens.length; ++i) {
            address tokenAddress = address(rewardTokens[i]);
            rewardPerTokenStored[tokenAddress] = rewardPerToken(tokenAddress);
        }
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            for (uint i = 0; i < rewardTokens.length; ++i) {
                address tokenAddress = address(rewardTokens[i]);
                rewards[tokenAddress][_account] = earned(tokenAddress, _account);
                userRewardPerTokenPaid[tokenAddress][_account] = rewardPerTokenStored[tokenAddress];
            }
        }
        _;
    }

    /**
     * @dev Modifier to check if rewards are emitting.
     */
    modifier whenEmitting() {
        require(block.timestamp <= periodFinish, "E18");
        _;
    }

    /**
     * @dev Modifier to check if rewards are not emitting.
     */
    modifier whenNotEmitting() {
        require(block.timestamp > periodFinish, "E17");
        _;
    }
}

// File: contracts/interfaces/IElkPair.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.5.0;

interface IElkPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address _owner) external view returns (uint);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint);

    function approve(address _spender, uint _value) external returns (bool);

    function transfer(address _to, uint _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address _owner) external view returns (uint);

    function permit(
        address _owner,
        address _spender,
        uint _value,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address _to) external returns (uint liquidity);

    function burn(address _to) external returns (uint amount0, uint amount1);

    function swap(
        uint _amount0Out,
        uint _amount1Out,
        address _to,
        bytes calldata _data
    ) external;

    function skim(address _to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IElkDexOracle.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;

interface IElkDexOracle {
    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    function weth() external view returns (address);

    function factory() external view returns (address);

    function windowSize() external view returns (uint);

    function granularity() external view returns (uint8);

    function periodSize() external view returns (uint);

    function pairObservations(
        address _pair
    ) external view returns (Observation[] memory);

    function observationIndexOf(uint _timestamp) external view returns (uint);

    function update(address _tokenA, address _tokenB) external;

    function updateWeth(address _token) external;

    function consult(
        address _tokenIn,
        uint _amountIn,
        address _tokenOut
    ) external view returns (uint);

    function consultWeth(
        address _tokenIn,
        uint _amountIn
    ) external view returns (uint);
}

// File: contracts/interfaces/IElkV2FarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>

pragma solidity >=0.8.0;




interface IElkV2FarmingRewards is IStakingRewards {
    /// @notice Represents a snapshot of an LP position at a given timestamp
    struct Position {
        uint112 amount0;
        uint112 amount1;
        uint32 blockTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

    function oracle() external returns (IElkDexOracle);

    function lpToken() external returns (IElkPair);

    function coverageTokenAddress() external returns (address);

    function coverageAmount() external returns (uint256);

    function coverageVestingDuration() external returns (uint256);

    function coverageRate() external returns (uint256);

    function coveragePerTokenStored() external returns (uint256);

    function userCoveragePerTokenPaid(
        address _tokenPaid
    ) external returns (uint256);

    function coverage(address _token) external returns (uint256);

    function lastStakedPosition(
        address _user
    )
        external
        returns (uint112 amount0, uint112 amount1, uint32 blockTimeStamp);

    /* ========== VIEWS ========== */

    function coveragePerToken() external view returns (uint256);

    function coverageEarned(address _account) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getCoverage(address _recipient) external;

    function startEmission(
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) external;

    function recoverLeftoverCoverage(address _recipient) external;

    /* ========== EVENTS ========== */

    // Emitted when the coverage is paid to an account
    event CoveragePaid(address indexed account, uint256 coverage);

    // Emitted when the leftover coverage is recovered
    event LeftoverCoverageRecovered(address indexed recipient, uint256 amount);
}

// File: contracts/ElkV2FarmingRewards.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;





/**
 * Contract implementing simple ERC20 token staking functionality with staking rewards, impermanent loss coverage, and deposit/withdrawal fees.
 */
contract ElkV2FarmingRewards is StakingRewards, IElkV2FarmingRewards {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Interface to the ElkDex pricing oracle on this blockchain
    IElkDexOracle public immutable oracle;

    /// @notice Interface to the LP token that is staked in this farm
    IElkPair public immutable lpToken;

    /// @notice Address of the coverage token
    address public coverageTokenAddress;

    /// @notice Total amount of coverage available (worst case max amount)
    uint256 public coverageAmount;

    /// @notice Time until a farmed position is fully covered against impermanent loss (100%)
    uint256 public coverageVestingDuration;

    /// @notice Rate of coverage vesting
    uint256 public coverageRate;

    /// @notice Coverage amount per token staked in the farm
    uint256 public coveragePerTokenStored;

    /// @notice How much coverage was paid per user (wallet address => amount)
    mapping(address => uint256) public userCoveragePerTokenPaid;

    /// @notice Accumulator of coverage tokens per user (wallet address => amount)
    mapping(address => uint256) public coverage;

    /// @notice Last farming position for a given user (wallet address => position)
    mapping(address => Position) public lastStakedPosition;


    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _oracleAddress address of the price oracle
     * @param _lpTokenAddress address of the staking LP token (must be an ElkDex LP)
     * @param _coverageTokenAddress address of the token that the coverage is paid in
     * @param _coverageAmount total amount of coverage
     * @param _coverageVestingDuration time it takes to vest 100% of the coverage (min. 1 day)
     * @param _rewardTokenAddresses addresses the reward tokens (must be ERC20)
     * @param _rewardsDuration reward emission duration
     * @param _depositFeeBps deposit fee in basis points
     * @param _withdrawalFeesBps aligned to fee schedule
     * @param _withdrawalFeeSchedule assumes a sorted array
     */
    constructor(
        address _oracleAddress,
        address _lpTokenAddress,
        address _coverageTokenAddress,
        uint256 _coverageAmount,
        uint32 _coverageVestingDuration,
        address[] memory _rewardTokenAddresses,
        uint256 _rewardsDuration,
        uint16 _depositFeeBps,
        uint16[] memory _withdrawalFeesBps,
        uint32[] memory _withdrawalFeeSchedule
    )
        StakingRewards(
            _lpTokenAddress,
            _rewardTokenAddresses,
            _rewardsDuration,
            _depositFeeBps,
            _withdrawalFeesBps,
            _withdrawalFeeSchedule
        )
    {
        oracle = IElkDexOracle(_oracleAddress);
        lpToken = IElkPair(_lpTokenAddress);

        if (_coverageTokenAddress != address(0)) {
            require(
                lpToken.token0() == _coverageTokenAddress ||
                    lpToken.token1() == _coverageTokenAddress,
                "E19"
            );
            require(
                _coverageVestingDuration >= 24 * 3600 && _coverageVestingDuration <= rewardsDuration,
                "E21"
            );
        }

        require(
            lpToken.factory() == oracle.factory(),
            "E20"
        );

        coverageTokenAddress = _coverageTokenAddress;
        coverageAmount = _coverageAmount;
        coverageVestingDuration = _coverageVestingDuration;
    }

    // Optimized version below
    /*function coveragePerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return coveragePerTokenStored;
        }
        return
            // does this work for non 18 dec tokens?  rate = _coverage / rewardsDuration, here rate is converted back to 18 dec
            coveragePerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                coverageRate *
                10**ERC20(coverageTokenAddress).decimals()) /
            totalSupply;
    }*/

    /**
     * @dev Return the coverage per staked token (in coverage token amounts)
     * @return amount of coverage per staked token
     */
    function coveragePerToken() public view returns (uint256) {
        return totalSupply == 0 ? coveragePerTokenStored : coveragePerTokenStored + (((lastTimeRewardApplicable() - lastUpdateTime) * coverageRate * 10**ERC20(coverageTokenAddress).decimals()) / totalSupply);
    }

    // Code below optimizes this version of the function
    /*function coverageEarned(address _account) public view returns(uint256) {
        if (coverageTokenAddress == address(0)) {
            return 0;
        }
        uint256 hodlValue = lpValueWeth(lastStakedPosition[_account]);
        if (hodlValue == 0) {
            // prevent division by zero below // equivalent check would be lastStakedPosition[_account].blockTimestamp > 0
            return coverage[_account];
        }
        uint256 outValue = lpValueWeth(position(balances[_account]));
        uint256 cappedCoverage = (balances[_account] *
            (coveragePerToken() - userCoveragePerTokenPaid[_account])) / 1e18;
        uint256 vested = vestedCoverage(
            hodlValue,
            outValue,
            lastStakedPosition[_account].blockTimestamp
        );
        if (vested > cappedCoverage) {
            vested = cappedCoverage;
        }
        // amount * (hodl value - out value) / hodl value = amount * (1 - (out value / hodl value))
        return (vested - (vested * outValue) / hodlValue) + coverage[_account];
    }*/

   /**
     * @dev Return the total coverage earned by a user.
     * @param _account user wallet address
     * @return coverage amount earned
     */
    function coverageEarned(address _account) public view returns(uint256) {
        if (coverageTokenAddress == address(0)) {
            return 0;
        }
        Position memory lastStake = lastStakedPosition[_account];
        uint256 hodlValue = lpValueWeth(lastStake);
        if (hodlValue == 0) {
            return coverage[_account];
        }
        uint256 outValue = lpValueWeth(position(balances[_account]));
        uint256 balance = balances[_account];
        uint256 cappedCoverage = (balance * (coveragePerToken() - userCoveragePerTokenPaid[_account])) / 1e18;
        uint256 vested = vestedCoverage(hodlValue, outValue, lastStake.blockTimestamp);
        return (vested > cappedCoverage ? cappedCoverage : vested) - (vested * outValue) / hodlValue + coverage[_account];
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    // Optimized version of this below
    /*
    function getCoverage(
        address _recipient
    ) public nonReentrant updateCoverage(_recipient) {
        require(
            msg.sender == owner() || msg.sender == _recipient,
            "E14"
        );
        require(coverageTokenAddress != address(0), "E23");
        uint256 cov = coverage[_recipient];
        if (cov > 0) {
            coverage[_recipient] = 0;
            IERC20(coverageTokenAddress).safeTransfer(_recipient, cov);
            emit CoveragePaid(_recipient, cov);
        }
    }
    */

    /**
     * @dev claim the coverage for a staker
     * @param _recipient the address of the staker that should receive the coverage
     * @ return the amount of reward received
     */
     function getCoverage(address _recipient) 
        public 
        nonReentrant 
        updateCoverage(_recipient) 
    {
        require(msg.sender == owner() || msg.sender == _recipient, "E14");
        require(coverageTokenAddress != address(0), "E23");

        uint256 cov = coverage[_recipient];
        if (cov == 0) return;

        coverage[_recipient] = 0;
        IERC20(coverageTokenAddress).safeTransfer(_recipient, cov);
        emit CoveragePaid(_recipient, cov);
    }

    /**
     * @dev Set the coverage parameters if none were set in the constructor. Gives the option for farm owners to change coverage tokens.
     * Note: Can't change coverage token if coverage is already accumulated
     * @param _tokenAddress address of token to be used for coverage emissions
     * @param _coverageAmount total amount of coverage token to emit
     * @param _coverageVestingDuration vesting period in seconds that users need to have staked to claim coverage
     */
    function setCoverage(address _tokenAddress, uint256 _coverageAmount, uint32 _coverageVestingDuration) external onlyOwner whenNotEmitting {
        require(coveragePerTokenStored == 0, "E24");
        require(
            (lpToken.token0() == _tokenAddress || lpToken.token1() == _tokenAddress) &&
            (_coverageVestingDuration >= 24 * 3600) &&
            (_coverageVestingDuration <= rewardsDuration),
            "E19"
        );
        coverageTokenAddress = _tokenAddress;
        coverageAmount = _coverageAmount;
        coverageVestingDuration = _coverageVestingDuration;
    }

    // Override startEmission() so it calls the expanded function that includes the coverage amount
    /**
     * @dev Start the emission of rewards to stakers with no coverage. The owner must send reward tokens to the contract before calling this function.
     * Note: Can only be called by owner when the contract is not emitting rewards.
     * @param _rewards array of rewards amounts for each reward token
     * @param _duration duration in seconds for which rewards will be emitted
     */
    function startEmission(
        uint256[] memory _rewards,
        uint256 _duration
    ) public override(StakingRewards, IStakingRewards) onlyOwner {
        return startEmission(_rewards, 0, _duration);
    }

    /**
     * @dev Start the emission of rewards to stakers. The owner must send reward and coverage tokens to the contract before calling this function.
     * Note: Can only be called by owner when the contract is not emitting rewards.
     * @param _rewards array of rewards amounts for each reward token
     * @param _coverage total amount of coverage provided to users (worst case max)
     * @param _duration duration in seconds for which rewards will be emitted (and coverage will be active)
     */
    function startEmission(
        uint256[] memory _rewards,
        uint256 _coverage,
        uint256 _duration
    ) public onlyOwner updateCoverage(address(0)) {
        super.startEmission(_rewards, _duration);
        require(
            coverageVestingDuration <= rewardsDuration,
            "E22"
        ); // must check again

        coverageRate = _coverage / rewardsDuration; // rewardsDuration, not coverageVestingDuration which can be shorter!

        if (coverageTokenAddress != address(0) && _coverage > 0) {
            // Ensure the provided coverage amount is not more than the balance in the contract
            uint256 balance = IERC20(coverageTokenAddress).balanceOf(
                address(this)
            );
            int8 tokenIndex = rewardTokenIndex(coverageTokenAddress);
            if (tokenIndex >= 0) {
                balance -= _rewards[uint256(int256(tokenIndex))];
            }
            require(
                coverageRate <= balance / rewardsDuration,
                "E3"
            );
        }
    }

    /**
     * @dev recover leftover coverage tokens and transfer them to a specified recipient
     * Note: can only be called by owner when the contract is not emitting rewards
     * @param _recipient address to receive the recovered coverage tokens
     */
     function recoverLeftoverCoverage(address _recipient) public onlyOwner whenNotEmitting {
        require(totalSupply == 0 && coverageTokenAddress != address(0), "E12/E23");
        _beforeRecoverLeftoverCoverage(_recipient);
        IERC20 token = IERC20(coverageTokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            token.safeTransfer(_recipient, amount);
            emit LeftoverCoverageRecovered(_recipient, amount);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Return the LP position for a given amount of LP token.
     * @param _amount the amount of LP token
     * @return the corresponding LP position (amount0, amount1, timestamp)
     */
    function position(uint256 _amount) private view returns (Position memory) {
        (uint112 reserve0, uint112 reserve1, uint32 timestamp) = lpToken.getReserves();
        uint256 totalAmount = lpToken.totalSupply();
        return Position(uint112((_amount * reserve0) / totalAmount), uint112((_amount * reserve1) / totalAmount), timestamp);
    }

    /**
     * @dev Return the value in WETH of the given LP position.
     * @param _position LP position
     * @return the value in WETH
     */
    function lpValueWeth(
        Position memory _position
    ) private view returns (uint256) {
        return
            oracle.consultWeth(lpToken.token0(), _position.amount0) +
            oracle.consultWeth(lpToken.token1(), _position.amount1);
    }
    
    /**
     * @dev Return the vested coverage in coverage token amount for the given HODL and OUT values since the provided timestamp.
     * @param _hodlValue the value (in WETH) if the tokens making up the LP were kept unpaired
     * @param _outValue the value (in WETH) of the LP token position
     * @param _lastTimestamp the start timestamp (when the LP token position was created)
     * @return vested coverage in coverage token amount
     */
    function vestedCoverage(
        uint256 _hodlValue,
        uint256 _outValue,
        uint32 _lastTimestamp
    ) private view returns (uint256) {
        uint256 timeElapsed = block.timestamp - _lastTimestamp;
        uint256 wethCov = _hodlValue > _outValue ? _hodlValue - _outValue : 0;
        uint256 tokenCoverage = wethCov == 0 ? 0 : oracle.consult(oracle.weth(), wethCov, coverageTokenAddress);
        if (timeElapsed >= coverageVestingDuration) {
            return tokenCoverage;
        }
        return (tokenCoverage * timeElapsed) / coverageVestingDuration;
    }

    /* ========== HOOKS ========== */

    /**
     * @dev Override _beforeStake() hook to ensure staking updates the coverage
     */
    function _beforeStake(
        address _account,
        uint256 _amount
    ) internal virtual override updateCoverage(_account) returns (uint256) {
        return super._beforeStake(_account, _amount);
    }

    /**
     * @dev Override _beforeWithdraw() hook to ensure withdrawing updates the coverage
     */
    function _beforeWithdraw(
        address _account,
        uint256 _amount
    ) internal virtual override updateCoverage(_account) returns (uint256) {
        return super._beforeWithdraw(_account, _amount);
    }

    /**
     * @dev Override _beforeExit() hook to claim all coverage for the account exiting
     */
    function _beforeExit(address _account) internal virtual override {
        if (coverageTokenAddress != address(0)) {
            getCoverage(_account);
        }
        super._beforeExit(_account);
    }

    /**
     * @dev Override _beforeRecoverERC20() hook to prevent recovery of a coverage token
     */
    function _beforeRecoverERC20(
        address _tokenAddress,
        address _recipient,
        uint256 _amount
    ) internal virtual override {
        require(
            _tokenAddress != coverageTokenAddress,
            "E16"
        );
        super._beforeRecoverERC20(_tokenAddress, _recipient, _amount);
    }

    // New hooks

    /**
     * @dev Internal hook called before recovering leftover coverage (in the recoverLeftoverCoverage() function).
     * @param _recipient address to recover the leftover coverage to
     */
    function _beforeRecoverLeftoverCoverage(
        address _recipient
    ) internal virtual {}

    /* ========== MODIFIERS ========== */

    /**
     * @dev Modifier to update the coverage of a given account.
     * @param _account account to update coverage for
     */
    modifier updateCoverage(address _account) {
        if (coverageTokenAddress != address(0)) {
            coveragePerTokenStored = coveragePerToken();
            lastUpdateTime = lastTimeRewardApplicable(); // it seems fine to redo this here
            oracle.update(lpToken.token0(), oracle.weth()); // update oracle for first token
            oracle.update(lpToken.token1(), oracle.weth()); // ditto for the second token
            if (_account != address(0)) {
                coverage[_account] = coverageEarned(_account);
                userCoveragePerTokenPaid[_account] = coveragePerTokenStored;
                lastStakedPosition[_account] = position(balances[_account]); // don't forget to reset the last position info
            }
        }
        _;
    }
}

// File: contracts/ElkV2FactoryHelper.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity >=0.8.0;


/**
 * @title contains a helper function that creates new FarmingRewards contracts in the ElkFarmFactory
 * @notice this is a separate contract so that the FarmFactory contract is not too large
 */
library ElkV2FactoryHelper {
    /**
     * @notice creates a new FarmingRewards contract and transfers ownership to the provided farm manager
     * @param _abi the abi of the FarmingRewards contract
     * @param _salt the salt used to create the contract
     * @param _farmManager the address of the farm manager
     */
    function createFarmContract(
        bytes memory _abi,
        bytes32 _salt,
        address _farmManager
    ) external returns (address addr) {
        bytes memory bytecode = abi.encodePacked(
            type(ElkV2FarmingRewards).creationCode,
            _abi
        );

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        ElkV2FarmingRewards(addr).transferOwnership(_farmManager);
    }
}