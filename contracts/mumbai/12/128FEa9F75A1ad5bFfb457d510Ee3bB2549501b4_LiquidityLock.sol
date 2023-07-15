// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity 0.8.19;

interface IRektLock {

    function balanceOf(address owner) external view returns (uint256);

    function getVotingPower (uint256 _tokenID) 
        external
        view
        returns (uint256 votingPower);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
interface IWentokens {

    /**
     *
     * @param _token ERC20 token to airdrop
     * @param _recipients list of recipients
     * @param _amounts list of amounts to send each recipient
     * @param _total total amount to transfer from caller
     */
    function airdropERC20(
        IERC20 _token,
        address[] calldata _recipients,
        uint256[] calldata _amounts,
        uint256 _total
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IRektLock.sol";
import "./Interfaces/IWentokens.sol";

contract LiquidityLock is Ownable {

    // errors
    error InvalidAmount ();
    error InvalidDuration();
    error InvalidShares();
    error InsufficientFunds (uint256 _amount, uint256 _balance);
    error TransferFailed();
    error NotLocked();
    error NotOwner();
    error NotDeadline();
    error Deadline();
    error Claimed();
    error NotVeNFTHolder();
    error NoVotingPower();
    error NotExecuted();
    error AlreadyExecuted();
    error LTPaused();

    // events
    event Locked (
        uint256 lockLTID, address indexed tokenAddress, address indexed locker, 
        uint256 indexed tokenAmount, uint256 startTime, uint256 unlockTime
    );
    event Unlocked (uint256 lockLTID, uint256 unlockAmount, address caller);
    event ProposalSuggested (uint256 lockLTID, bytes32 reason, address user);
    event ProposalCreated (uint256 proposalID, uint256 lockLTID);
    event ProposalVoted (uint256 proposalID, address voter, Vote vote);
    event ProposalExecuted (uint256 proposalID);


    struct LockLT {
        address tokenAddress; // Address of ERC20 token locked
        // State of the claimed status
        // 0 == Not claimed; 1 == Claimed;
        uint96 claimed;
        address locker; // Address that locked the tokens
        uint96 ltPaused; // 0 == Not Paused; 1 == Paused;
        uint256 tokenAmount; // Amount of tokens locked
        uint256 startTime;
        uint256 unlockTime; // When tokens would be available to be transferred.
    }

    struct Proposals {
        uint256 lockLTID; // ID of the locked liquidity token
        uint256 created; // proposal creation date
        uint256 deadline; // proposal deadline
        uint256 executed; // Execution status of proposal 0 == Not Executed; 1 == Executed;
        bytes32 proposalReason;
        uint256 yayVotes;
        uint256 nayVotes;
        uint256 totalVotingPower;
        // mapping of NFT token IDs that voted
        mapping (uint256 tokenID => bool voted) voters;
        mapping (uint256 tokenID => bool) claimed;
        mapping (uint256 tokenID => uint256 votingPower) tokenIDVotingPower;
    }

    uint256 private numLLT; // number of locked liquidity token
    uint256 private numProposals;

    address private treasury;
    uint32 private holdersShare = 8000; // 80% = 8000;
    uint32 private treasuryShare = 1000; //10% = 1000
    uint32 private votersShare = 1000; // 10% = 1500;

    uint64 private MINLOCKDURATION = 7_776_000; //3 Months = 7_776_000;
    uint64 private MAXLOCKDURATION = 31_104_000; //12 Months = 31_104_000;
    uint64 private VOTINGPERIOD = 604_800; //7 Days = 604_800;
    // No proposal can be created after "21 days" to the unlock time.
    uint64 private PROPOSALPERIOD = 1_814_400; // 21 Days = 1_814_400


    mapping (uint256 lockLTID => LockLT) public detailsLockID;
    mapping (uint256 proposalID => Proposals) public detailsProposalID;

    IRektLock veNFT;
    IWentokens airdrop;

    constructor (address _veNFT, address _treasury, address _wenTokenAddr) payable {
        veNFT = IRektLock(_veNFT);
        airdrop = IWentokens(_wenTokenAddr);
        treasury = _treasury;
    }

    modifier validateDuration (uint256 _duration) {
        if (_duration < MINLOCKDURATION || _duration > MAXLOCKDURATION) {
            revert InvalidDuration();
        }
        _;
    }

    modifier veNftHolderOnly() {
        if (veNFT.balanceOf(msg.sender) == 0) revert NotVeNFTHolder();
        _;
    }

    modifier activeProposalOnly(uint256 proposalID) {
        if (block.timestamp > detailsProposalID[proposalID].deadline) {
            revert NotDeadline();
        }
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalID) {
        Proposals storage proposal = detailsProposalID[proposalID];
        if (proposal.deadline >= block.timestamp) revert NotDeadline();
        if (proposal.executed == 1) revert AlreadyExecuted();
        _;
    }

    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    /// @notice Lock up the Liquidity tokens
    /// @dev After locking up the Liquidity tokens, proposals can be made by $REKT NFT holders 
    /// @dev to decide if the tokens would go back to the community or not.
    /// @param _amount - The amount of tokens to lock up
    /// @param _duration - The duration to lock up tokens
    function ltLock(uint _amount, uint256 _duration, address _lt) external 
        validateDuration(_duration) {

        if (_amount == 0) revert InvalidAmount();
        IERC20 lt = IERC20(_lt);
        address locker = msg.sender;
        uint256 balance = lt.balanceOf(locker);
        if (_amount > balance) revert InsufficientFunds(balance, _amount);
        uint256 _numLLT = numLLT;
        detailsLockID[_numLLT].startTime = block.timestamp;
        detailsLockID[_numLLT].unlockTime = block.timestamp + _duration;
        detailsLockID[_numLLT].tokenAmount = _amount;
        detailsLockID[_numLLT].tokenAddress = _lt;
        detailsLockID[_numLLT].locker = locker;
        // Approve contract to transfer tokens
        // lt.approve(address(this), type(uint256).max);
        bool success = lt.transferFrom(locker, address(this), _amount);
        if (!success) revert TransferFailed();
        numLLT = numLLT + 1;
        
        emit Locked(_numLLT, _lt, locker, _amount, block.timestamp, block.timestamp + _duration);
    }

    /// @notice Unlocks the locked liquidity token
    /// @dev Can only be unlocked by the address that locked it
    /// @dev Cannot be unlocked before the deadline OR if there's an active proposal OR if a proposal passes
    /// @param lockLTID - The ID of the Locked Liquidity token
    function ltUnlock(uint256 lockLTID) external {
        address caller = msg.sender;
        LockLT memory lockLTdetails = detailsLockID[lockLTID];
        if (lockLTdetails.locker != caller) revert NotOwner();
        if (lockLTdetails.unlockTime > block.timestamp) revert NotDeadline();
        if (lockLTdetails.claimed == 1) revert Claimed();
        if (lockLTdetails.ltPaused == 1) revert LTPaused();
        detailsLockID[lockLTID].claimed = 1;

        _ltUnlock(lockLTID, caller, lockLTdetails.tokenAmount);

    }

    /// @notice veNFT holders can suggest a proposal, as only the admins can create proposals.
    /// @notice A link pointing to a detailed explanation of the reason for the suggestion can be hashed and used as `_proposalReason` 
    function suggestProposal(uint256 lockLTID, bytes32 _proposalReason)
        external
        veNftHolderOnly
    {
        emit ProposalSuggested(lockLTID, _proposalReason, msg.sender);
    }

    /// @notice Creates a proposal with the locked liquidity token ID and the reason
    /// @notice The reason can be a link, hashed and converted to bytes32
    /// @dev Only the admin is allowed to create a proposal
    /// @dev Proposals cannot be created `PROPOSALPERIOD` to the unlock time
    function createProposal(uint256 lockLTID, bytes32 _proposalReason)
        external
        onlyOwner
        returns (uint256)
    {
        LockLT memory lockLTdetails = detailsLockID[lockLTID];
        if (lockLTdetails.tokenAddress == address(0)) revert NotLocked();
        if (lockLTdetails.ltPaused == 1) revert LTPaused();
        if (block.timestamp > (lockLTdetails.unlockTime - PROPOSALPERIOD)) {
            revert Deadline();
        }
        Proposals storage proposal = detailsProposalID[numProposals];
        proposal.lockLTID = lockLTID;
        uint256 startTime = block.timestamp;
        proposal.created = startTime;
        proposal.deadline = startTime + VOTINGPERIOD;
        proposal.proposalReason = _proposalReason;
        detailsLockID[proposal.lockLTID].ltPaused = 1;

        emit ProposalCreated (numProposals, lockLTID);
        numProposals = numProposals + 1;
        return numProposals - 1;
    }

    /// @notice veNFT holders only are allowed to vote on active proposals
    /// @param proposalID - The proposal ID to vote on
    /// @param vote - 0 - Yay; 1 - Nay.
    function voteOnProposal(uint256 proposalID, Vote vote)
        external
        veNftHolderOnly
        activeProposalOnly(proposalID) {
        Proposals storage proposal = detailsProposalID[proposalID];

        address caller = msg.sender;
        uint256 voterNFTBalance = veNFT.balanceOf(caller);
        uint256 votingPower;

        // Calculate how many NFTs are owned by the voter and their voting power
        for (uint256 i; i < voterNFTBalance;) {
            uint256 tokenId = veNFT.tokenOfOwnerByIndex(caller, i);
            if (proposal.voters[tokenId] == false) {
                uint256 tokenIdVotingPower = veNFT.getVotingPower(tokenId);
                votingPower += tokenIdVotingPower;
                proposal.voters[tokenId] = true;
                proposal.tokenIDVotingPower[tokenId] += votingPower;
            }
            unchecked {
                ++i;
            }
        }
        if (votingPower == 0) revert NoVotingPower();
        proposal.totalVotingPower += votingPower;

        if (vote == Vote.YAY) {
            proposal.yayVotes += votingPower;
        } else {
            proposal.nayVotes += votingPower;
        }
        emit ProposalVoted(proposalID, caller, vote);
    }

    /// Only ADMIN can execute the proposal after the deadline
    /// @param proposalID - Proposal ID to execute
    function executeProposal(uint256 proposalID, address[] calldata tokenHolders, uint256[] calldata amounts)
        external
        onlyOwner
        inactiveProposalOnly(proposalID) {

        Proposals storage proposal = detailsProposalID[proposalID];
        proposal.executed = 1;
        bool proposalPassed = checkProposalResult(proposalID);
        // If the proposal passes, transfer the locked Liquidity Token.
        if (proposalPassed) {
            uint256 tokenAmount = detailsLockID[proposal.lockLTID].tokenAmount;
            (uint256 _holdersAmount, ,uint256 _treasuryAmount) = calcShares(tokenAmount);

            _ltUnlock(proposal.lockLTID, treasury, _treasuryAmount);
            LockLT memory lockLTdetails = detailsLockID[proposal.lockLTID];
            IERC20 lt = IERC20(lockLTdetails.tokenAddress);
            airdrop.airdropERC20(lt, tokenHolders, amounts, _holdersAmount);

        } else {
            detailsLockID[proposal.lockLTID].ltPaused = 0;
        }
        
        emit ProposalExecuted(proposalID);
    }

    /// @notice If a proposal passes, veNFT token IDs that voted are allowed to get a share from the VOTERSSHARE allocation
    /// @notice The total allocation is shared according to the voting power at the time of the voting
    /// @dev Only veNFTHolders that voted are allowed to claim the reward
    /// @param proposalID - Proposal ID to claim
    function claim(uint256 proposalID) external veNftHolderOnly {

        Proposals storage proposal = detailsProposalID[proposalID];
        if (proposal.executed == 0) revert NotExecuted();
        bool proposalPassed = checkProposalResult(proposalID);
        address caller = msg.sender;
        if (proposalPassed) {
            uint256 voterNFTBalance = veNFT.balanceOf(caller);
            uint256 votingPower;
            // Calculate how many NFTs are owned by the voter and their voting power
            for (uint256 i; i < voterNFTBalance;) {
                uint256 tokenId = veNFT.tokenOfOwnerByIndex(caller, i);
                if (proposal.claimed[tokenId] == false) {
                uint256 tokenIDVotingPower = proposal.tokenIDVotingPower[tokenId];
                votingPower += tokenIDVotingPower;
                proposal.claimed[tokenId] = true;
                }
                unchecked {
                    ++i;
                }
            }

            if (votingPower == 0) revert NoVotingPower();
            uint256 tokenAmount = detailsLockID[proposal.lockLTID].tokenAmount;
            (, uint256 votersAmount,) = calcShares(tokenAmount);

            uint256 amount = votersAmount * votingPower / proposal.totalVotingPower;

            _ltUnlock(proposal.lockLTID, caller, amount);
        } else revert();

    }

    function checkProposalResult (uint256 proposalID) public view returns (bool passed) {
        Proposals storage proposal = detailsProposalID[proposalID];
        passed = proposal.yayVotes > proposal.nayVotes ? true : false;
    }

    /// @notice Calculate the different allocations from a given amount
    /// @param amount - Total amount to be split
    /// @return _holdersAmount for the holders
    /// @return _votersAmount for the voters
    /// @return _treasuryAmount for the treasury
    function calcShares (uint256 amount) internal view returns 
        (uint256 _holdersAmount, uint256 _votersAmount,
        uint256 _treasuryAmount) {
            _holdersAmount = amount * holdersShare / 10000;
            _votersAmount = amount * votersShare / 10000;
            _treasuryAmount = amount * treasuryShare / 10000;
    }


    /// @notice Unlock the liquidity token and distribute to the given address
    /// @param lockLTID - Locked liquidity token ID
    /// @param caller - Address to send the unlocked token
    /// @param amount - Amount to be unlocked
    function _ltUnlock (uint256 lockLTID, address caller, uint256 amount) internal {
        LockLT memory lockLTdetails = detailsLockID[lockLTID];
        IERC20 lt = IERC20(lockLTdetails.tokenAddress);
        uint256 balance = lt.balanceOf(address(this));

        if (balance < amount) revert InsufficientFunds(amount, balance);

        bool success = lt.transfer(caller, amount);
        if (!success) revert TransferFailed();

        emit Unlocked (lockLTID, amount, caller);
    }

    function distributeToken (address tokenAddr, address[] calldata _receipients,
    uint256[] calldata _amounts, uint256 total ) public onlyOwner {
        IERC20 token = IERC20(tokenAddr);
        airdrop.airdropERC20(token, _receipients, _amounts, total);
    }

    /// ----------------ADMIN SETTER FUNCTIONS ------------------------///

    function setDuration(uint64 _minDuration, uint64 _maxDuration) external payable onlyOwner {
        MINLOCKDURATION = _minDuration;
        MAXLOCKDURATION = _maxDuration;
    }

    function setPeriods(uint64 _votingPeriod, uint64 _proposalPeriod) external payable onlyOwner {
        VOTINGPERIOD = _votingPeriod;
        PROPOSALPERIOD = _proposalPeriod;
    }

    function setShares (uint32 _holdersShare, uint32 _votersShare, uint32 _treasuryShare) external payable onlyOwner{
        if (_holdersShare + _votersShare + _treasuryShare != 10_000) revert InvalidShares();
        holdersShare = _holdersShare;
        votersShare = _votersShare;
        treasuryShare = _treasuryShare;
    }

    function setAddresses(address _treasury) external payable onlyOwner {
        treasury = _treasury;
    }

    /// ----------------GETTER FUNCTIONS ------------------------///
    function getNumLockedLiquidityTokens() external view returns (uint256 _numLLT) {
        _numLLT = numLLT;
    }

    function getNumProposals() external view returns (uint256 _numProposals) {
        _numProposals = numProposals;
    }

    function getTreasuryAddress() external view returns (address _treasury) {
        _treasury = treasury;
    }

    function getShares() external view returns (uint32 _holdersShare, uint32 _votersShare, uint32 _treasuryShare) {
        _holdersShare = holdersShare;
        _votersShare = votersShare;
        _treasuryShare = treasuryShare;
    }

    function getLockDurations() external view returns (uint64 _minDuration, uint64 _maxDuration) {
        _minDuration = MINLOCKDURATION;
        _maxDuration = MAXLOCKDURATION;
    }

    function getPeriods() external view returns (uint64 _votingPeriod, uint64 _proposalPeriod) {
        _votingPeriod = VOTINGPERIOD;
        _proposalPeriod = PROPOSALPERIOD;
    }

    function getLLTById(uint256 lockLTID) external view returns (LockLT memory _lockLt) {
        _lockLt = detailsLockID[lockLTID];
    }

}