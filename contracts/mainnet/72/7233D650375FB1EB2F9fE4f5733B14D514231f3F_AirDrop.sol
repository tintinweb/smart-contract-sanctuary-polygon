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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAirdrop.sol";
import "./interfaces/IVotingEscrow.sol";
import "./utils/Adminable.sol";

contract AirDrop is Adminable, IAirdrop, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token; // MVDAO token contract address
    IVotingEscrow public immutable veContract; // Voting Escrow contract address

    address public treasury; // treasury wallet address
    uint256 public globalLockupDuration; // airdropped tokens must be locked up for this amount of time
    uint256 public airdropExpiryTime; // the expiry timestamp of airdrop
    uint256 public totalAmountToAirdrop; // Total amount of tokens to be airdropped
    uint256 public totalNumOfWalletsClaimed; // Total number of wallets that have claimed tokens
    uint256 public totalNumOfWallets; // Total number of wallets that have been allocated tokens

    mapping(address => LockupSummary) private _lockupInfo; // lockup info by wallets

    bool public airdropStarted; // Has the airdrop started

    constructor(
        address _token,
        address _treasury,
        address _veContract
    ) {
        require(_token != address(0), "Airdrop: invalid address");
        require(_treasury != address(0), "Airdrop: invalid address");
        require(_veContract != address(0), "Airdrop: invalid address");

        token = IERC20(_token);
        treasury = _treasury;
        veContract = IVotingEscrow(_veContract);
    }

    function startAirdrop(
        uint256 _globalLockupDuration,
        uint256 _airdropExpiryTime
    ) external override onlyAdmin {
        uint256 unclaimedAmount = totalUnclaimed();
        require(unclaimedAmount > 0, "Airdrop: no tokens deposited");
        require(
            unclaimedAmount >= totalAmountToAirdrop,
            "Airdrop: insufficient tokens"
        );
        require(!airdropStarted, "Airdrop: airdrop has started");
        require(_globalLockupDuration > 0, "Airdrop: invalid lockup duration");
        require(
            _airdropExpiryTime > block.timestamp,
            "Airdrop: invalid airdrop expiry time"
        );

        globalLockupDuration = _globalLockupDuration;
        airdropExpiryTime = _airdropExpiryTime;
        airdropStarted = true;

        emit AirdropStarted(
            globalLockupDuration,
            airdropExpiryTime,
            totalAmountToAirdrop
        );
    }

    function lock() external override nonReentrant {
        require(airdropStarted, "Airdrop: airdrop has not started");
        require(!_isEnded(), "Airdrop: airdrop has ended");
        address caller = _msgSender();
        require(isEligibleToClaim(caller), "Airdrop: not eligible");
        LockupSummary storage lockupInfo = _lockupInfo[caller];
        uint256 balance = lockupInfo.amount;
        uint256 lockEndTime = block.timestamp + globalLockupDuration;
        lockupInfo.claimed = true;
        totalNumOfWalletsClaimed++;
        token.approve(address(veContract), balance);
        veContract.createLockFor(caller, address(this), balance, lockEndTime);

        emit Locked(caller);
    }

    function setAmount(address _account, uint256 _amount)
        external
        override
        onlyAdmin
    {
        require(!airdropStarted, "Airdrop: airdrop has already started");
        _setAmount(_account, _amount);
    }

    function setAmounts(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external override onlyAdmin {
        require(!airdropStarted, "Airdrop: airdrop has already started");
        require(
            _accounts.length == _amounts.length,
            "Airdrop: unequal lengths"
        );
        uint256 n = _accounts.length;
        for (uint256 i = 0; i < n; i++) {
            _setAmount(_accounts[i], _amounts[i]);
        }
    }

    function setTreasury(address _treasury) external override onlyAdmin {
        require(_treasury != address(0), "Airdrop: invalid address");
        treasury = _treasury;

        emit TreasurySet(treasury);
    }

    function recoverUnclaimedTokens() external override onlyAdmin {
        require(airdropStarted, "Airdrop: airdrop has not started");
        require(_isEnded(), "Airdrop: airdrop has not ended");
        uint256 remainingAmount = totalUnclaimed();
        token.safeTransfer(treasury, remainingAmount);

        emit UnclaimedTokenRecovered(remainingAmount);
    }

    function totalUnclaimed() public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function isEligibleToClaim(address account)
        public
        view
        override
        returns (bool)
    {
        bool cond1 = _lockupInfo[account].amount > 0;
        bool cond2 = !_lockupInfo[account].claimed;
        return cond1 && cond2;
    }

    function getLockupInfo(address account)
        external
        view
        override
        returns (LockupSummary memory)
    {
        return _lockupInfo[account];
    }

    function isAirdropEnded() external view override returns (bool) {
        return _isEnded();
    }

    function _setAmount(address account, uint256 amount) private {
        require(amount > 0, "Airdrop: invalid amount");
        LockupSummary storage lockupInfo = _lockupInfo[account];
        require(lockupInfo.amount == 0, "Airdrop: already set");
        lockupInfo.amount = amount;
        totalAmountToAirdrop += amount;
        totalNumOfWallets++;

        emit AmountSet(account, amount);
    }

    function _isEnded() private view returns (bool) {
        return airdropExpiryTime > 0 && block.timestamp > airdropExpiryTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IAirdrop {
    struct LockupSummary {
        uint256 amount; // Amount airdropped to an account
        bool claimed; // If the airdropped tokens have been claimed
    }

    /**
     * @dev Emitted when `amount` of tokens are set to `account` for
     * airdropping.
     */
    event AmountSet(address account, uint256 amount);

    /**
     * @dev Emitted when this airdrop is started with
     * `globalLockupDuration` and `airdropExpiryTime` with the total amount
     * in this airdrop being `totalAmountToAirdrop`.
     */
    event AirdropStarted(
        uint256 globalLockupDuration,
        uint256 airdropExpiryTime,
        uint256 totalAmountToAirdrop
    );

    /**
     * @dev Emitted when `account` locked their tokens for gaining voting
     * power.
     */
    event Locked(address account);

    /**
     * @dev Emitted when `amount` of unclaimed tokens are recovered.
     */
    event UnclaimedTokenRecovered(uint256 amount);

    /**
     * @dev Emitted when a new `treasury` address is set.
     */
    event TreasurySet(address treasury);

    /**
     * @dev Starts the airdrop officially.
     * @param globalLockupDuration the duration sets the end timestamp after
     * which airdropped tokens are eligible to be withdrawn directly to
     * users' accounts.
     * @param airdropExpiryTime the timestamp after which unclaimed airdrop
     * tokens are eligible to be reclaimed back to the treasury
     */
    function startAirdrop(
        uint256 globalLockupDuration,
        uint256 airdropExpiryTime
    ) external;

    /**
     * @dev Sets `amount` of tokens for `account` in airdropping.
     */
    function setAmount(address account, uint256 amount) external;

    /**
     * @dev Sets `amounts` of tokens for a list of `accounts` in airdropping.
     */
    function setAmounts(address[] calldata accounts, uint256[] calldata amounts)
        external;

    /**
     * @dev Locks airdropped tokens directly to Voting Escrow to gain voting
     * power.
     */
    function lock() external;

    /**
     * @dev Withdraws to the treasury any unclaimed/unlocked tokens after the
     * airdrop has expired.
     */
    function recoverUnclaimedTokens() external;

    /**
     * @dev Sets a new `treasury` address.
     */
    function setTreasury(address treasury) external;

    /**
     * @dev Returns the total amount of unclaimed/unlocked airdropped tokens.
     */
    function totalUnclaimed() external view returns (uint256);

    /**
     * @dev Returns if `account` is eligible for claiming airdropped tokens.
     */
    function isEligibleToClaim(address account) external view returns (bool);

    /**
     * @dev Returns if the airdrop is ended.
     */
    function isAirdropEnded() external view returns (bool);

    /**
     * @dev Returns the LockupSummary info for a given `account`.
     */
    function getLockupInfo(address account)
        external
        view
        returns (LockupSummary memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVotingEscrow {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        RELOCK
    }

    struct Point {
        int128 bias;
        int128 slope; // dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    /**
     * @dev Emitted `provider` withdraws previously deposited `value`
     * amount of tokens at timestamp `ts`.
     */
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    /**
     * @dev Emitted when tokens of `value` amount are deposited by
     * `provider` at `locktime` of `_type` at the transaction time `ts`.
     */
    event Deposit(
        address indexed provider,
        address indexed payer,
        uint256 value,
        uint256 indexed locktime,
        DepositType _type,
        uint256 ts
    );

    /**
     * @dev Emitted `amount` of `token` is recovered from this contract to
     * the owner.
     */
    event Recovered(address token, uint256 amount);

    /**
     * @dev Emitted when the total supply is updated from `prevSupply`
     * to `supply`.
     */
    event Supply(uint256 prevSupply, uint256 supply);

    /**
     * @dev Emitted when a new `listener` is added.
     */
    event ListenerAdded(address listner);

    /**
     * @dev Emitted when an existing `listener` is removed.
     */
    event ListenerRemoved(address listner);

    /**
     * @dev Emitted when the smart wallet check status is toggled.
     */
    event SmartWalletCheckerStatusToggled(bool isSmartWalletCheckerOn);

    /**
     * @dev Emitted when the smart wallet check address is set.
     */
    event SmartWalletCheckerSet(address checker);

    /**
     * @dev Emitted when a create lock helper is set.
     */
    event CreateLockHelperSet(address helper);

    /**
     * @dev Deposits and locks `_value` amount of tokens for a user `_addr`.
     */
    function deposit_for(address _addr, uint256 _value) external;

    /**
     * @dev Creates a lock of `_value` amount of tokens ended at
     * `_unlock_time`.
     */
    function create_lock(uint256 _value, uint256 _unlock_time) external;

    /**
     * @dev Creates a lock of `_value` amount of tokens for `_beneficiary`
     * with lock ending time at `_unlock_time`. The tokens are paid by
     * `_payer`, which may or may not be the same with `_beneficiary`.
     */
    function createLockFor(
        address _beneficiary,
        address _payer,
        uint256 _value,
        uint256 _unlock_time
    ) external;

    /**
     * @dev Increases the locked amount by `_value` amount of tokens the
     * caller.
     */
    function increase_amount(uint256 _value) external;

    /**
     * @dev Increases the locked amount to a new unlock time at
     * `_unlock_time` by the caller.
     */
    function increase_unlock_time(uint256 _unlock_time) external;

    /**
     * @dev Increases the locked amount by `_value` amount and to a
     * new unlock time at `_unlock_time` by the caller.
     */
    function increaseAmountAndUnlockTime(uint256 _value, uint256 _unlock_time)
        external;

    /**
     * @dev Withdraws unlocked tokens to the caller's wallet.
     */
    function withdraw() external;

    /**
     * @dev Relocks caller's expired tokens for `_unlock_time`
     * amount of time.
     */
    function relock(uint256 _unlock_time) external;

    /**
     * @dev Toggles the smart contract checker status.
     */
    function toggleSmartWalletCheckerStatus() external;

    /**
     * @dev Adds a `listener` contract that needs to be notified when
     * voting power is updated for any token holder.
     */
    function addListener(address listener) external;

    /**
     * @dev Removes a listener at `listenerIdx` that is no longer in use.
     */
    function removeListenerAt(uint256 listenerIdx) external;

    /**
     * @dev Returns the listerner at the `listenerIdx`-th location.
     */
    function getListenerAt(uint256 listenerIdx) external view returns (address);

    /**
     * @dev Returns the number of listeners available.
     */
    function getNumOfListeners() external view returns (uint256);

    /**
     * @dev Returns the last user slope for the account `addr`.
     */
    function get_last_user_slope(address addr) external view returns (int128);

    /**
     * @dev Returns the last user bias for the account `addr`.
     */
    function get_last_user_bias(address addr) external view returns (int128);

    /**
     * @dev Returns the vesting time in seconds since last check point
     * for a given `addr`.
     */
    function get_last_user_vestingTime(address addr)
        external
        view
        returns (int128);

    /**
     * @dev Returns the timestamp for checkpoint `_idx` for `_addr`
     */
    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the timestamp when `_addr`'s lock finishes.
     */
    function locked__end(address _addr) external view returns (uint256);

    /**
     * @dev Returns the current voting power for `_msgSender()` at the
     * specified timestamp `_t`.
     */
    function balanceOf(address addr, uint256 _t)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the current voting power for `_msgSender()` at the
     * moment when this function is called.
     */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * @dev Returns the voting power of `addr` at block height `_block`.
     */
    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total voting power of the caller at the specified
     * timestamp `t`.
     */
    function totalSupply(uint256 t) external view returns (uint256);

    /**
     * @dev Returns the total voting power of the caller at the
     * current timestamp.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the total voting power of the caller at `_block` usually
     * in the past.
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256);

    /**
     * @dev Recovers `tokenAmount` of ERC20 tokens at `tokenAddress` in this
     * contract to be distributed to the contract admin.
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This is a direct copy of OpenZeppelin's Ownable at:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */

abstract contract Adminable is Context {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _transferAdminship(_msgSender());
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // solhint-disable-next-line reason-string
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without admin. It will not be possible to call
     * `onlyAdmin` functions anymore. Can only be called by the current admin.
     *
     * NOTE: Renouncing adminship will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function renounceAdminship() public virtual onlyAdmin {
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdminship(address newAdmin) public virtual onlyAdmin {
        // solhint-disable-next-line reason-string
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        _transferAdminship(newAdmin);
    }

    /**
     * @dev Transfers adminship of the contract to a new account (`newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminshipTransferred(oldAdmin, newAdmin);
    }
}