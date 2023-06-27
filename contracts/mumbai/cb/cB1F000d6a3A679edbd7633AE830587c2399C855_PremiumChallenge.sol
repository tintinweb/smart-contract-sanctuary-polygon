// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
* @title Premium Challenge
* @dev Premium Challenge for challengeproject
* @custom:dev-run-script scripts/deploy_with_ethers.ts
*/
contract PremiumChallenge is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum ChallengeState{ DRAFT, CANCELLED, RUNNING, COMPLETED }

    struct MetaData {
        string challengeName;
        string gameName;
        // url to the challenge instance on Challenger Project Platform
        string url;
        // challenge target
        string target;
        // start time of challenge in epochUnixTime
        uint256 startTime;
        // end time of challenge in epochUnixTime
        uint256 endTime;
        // entry fee to challenge
        uint256 entryFee;
    }

    struct Winner {
        uint256 place;
        address wallet;
        bool claimed;
        uint256 reward;
        //mapping(address => uint256) rewards;
    }

    // CHLL token
    IERC20 public immutable platformToken;
    // meta data
    MetaData private metaData;
    // owner of this contract
    address private owner;
    // organiser of challenge
    address private organiser;
    // sakeing address
    address private stakeAddress;
    // treasury
    address private treasury;
    // is winner set
    bool private isWinnersSet = false;
    // cashed token balance after winners set
    uint256 private balance;

    // store participant addresses 
    address[] private participantWallets;
    // store participant 
    mapping(address => address) private participants;
    // store winners
    mapping(address => Winner) private winners;
    // store prize pool
    mapping(address => uint256) private prizePool;
    // store supported reward tokens
    mapping(address => address) private supportedRewardTokens;

    // events
    event ParticipantJoined(address _wallet);
    event ChallengeFinished();
    event PrizeRewardChanged(uint _amount);
    //event PrizeRewardChanged(address _tokenSCAddress, uint _amount);

    // constructor is called during contract deployment 
    constructor(
        IERC20 _platformToken,
        string memory _challengeName,
        string memory _gameName,
        string memory _baseUrl,
        string memory _target,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _entryFee,
        address _organiser,
        address _stakeAddress,
        address _treasury
    ) {
        // assign the address that created contract
        owner = payable(msg.sender);
        organiser = _organiser;
        stakeAddress = _stakeAddress;
        treasury = _treasury;
        // assing platform token
        platformToken = _platformToken;
        metaData = MetaData(
            _challengeName,
            _gameName,
            _baseUrl,
            _target,
            _startTime,
            _endTime,
            _entryFee
        );
    }

    // MODIFIERS

    //create a modifier that the msg.sender must be the owner modifier 
    modifier onlyOwner {
        require(msg.sender == owner, 'Only the owner can call this function.');
        _;
    }

    // create a modifier that checks if participant not joined to challenge
    modifier participantNotJoined {
        require(participants[msg.sender] == address(0), 'Participant already joined');
        _;
    }

    // create a modifier that checks if participant already joined to challenge
    modifier participantJoined {
        require(participants[msg.sender] != address(0), 'Participant not joined');
        _;
    }

    // create a modifier that checks if the challenge winners is set
    modifier challengeWinnersIsSet {
        require(isWinnersSet == true, "Challenge winners is not set.");
        _;
    }

    // create a modifier that checks if the challenge winners is not set
    modifier challengeWinnersIsNotSet {
        require(isWinnersSet == false, "Challenge winners is set.");
        _;
    }

    // create a modifier that checks if sender is valid
    modifier senderIsAddress {
        require(msg.sender != address(0), 'Invalid wallet address');
        _;
    }

    // create a modifier that checks if challenge state is valid for joining the challenge
    modifier challengeStateIsValidForJoin {
        ChallengeState _challengeState = forecastChallengeState();
        require(_challengeState == ChallengeState.DRAFT || _challengeState == ChallengeState.RUNNING, 'Invalid challenge state for joining');
        _;
    }

    modifier challengeStateIsValidForRewardClaim {
        ChallengeState _challengeState = forecastChallengeState();
        require(_challengeState == ChallengeState.COMPLETED, 'Invalid challenge state for claim reward');
        _;
    }

    modifier challengeStateIsValidForSettingWinners {
        ChallengeState _challengeState = forecastChallengeState();
        require(_challengeState == ChallengeState.COMPLETED, 'Invalid challenge state for setting winners');
        _;
    }

    // FUNCTIONS

    function forecastChallengeState() private view returns (ChallengeState){
        if (block.timestamp < metaData.startTime)
            return ChallengeState.DRAFT;
        if (block.timestamp >= metaData.startTime && block.timestamp < metaData.endTime)
            return ChallengeState.RUNNING;
        return ChallengeState.COMPLETED;
    }

    // join to challenge
    function join() external nonReentrant senderIsAddress challengeStateIsValidForJoin participantNotJoined {
        uint256 _balance = platformToken.balanceOf(msg.sender);
        require(_balance >= metaData.entryFee, "Balance to small");
        uint256 _allowance = platformToken.allowance(msg.sender, address(this));
        require(_allowance >= metaData.entryFee, "Check the token allowance");
        bool _success = platformToken.transferFrom(msg.sender, address(this), metaData.entryFee);
        require(_success, "Token transfer failure");
        participants[msg.sender] = msg.sender;
        participantWallets.push(msg.sender);
        //address _platformTokenAddress = address(platformToken);
        //prizePool[_platformTokenAddress] += metaData.entryFee;
        emit ParticipantJoined(msg.sender);
        emit PrizeRewardChanged(this.getPrizePool());
    }

    function claimReward() public senderIsAddress challengeWinnersIsSet challengeStateIsValidForRewardClaim participantJoined {
        require(winners[msg.sender].wallet != address(0), "Not Winner");
        require(!winners[msg.sender].claimed, "Reward already claimed");
        bool _success = platformToken.transfer(msg.sender, winners[msg.sender].reward);
        require(_success, "Reward claim failure");
        winners[msg.sender].claimed = true;
    }
    
    function setWinners(address[] memory _winnersWallets, uint256 _qualifiedParticipants) public onlyOwner challengeWinnersIsNotSet challengeStateIsValidForSettingWinners {
        // validate wallets
        for (uint256 i = 0; i < _winnersWallets.length; i++) {
            require(_winnersWallets[i] != address(0), "Invalid address");
            require(participants[_winnersWallets[i]] != address(0), 'Participant not joined');
        }
        uint256[] memory _rewards = this.getRewardsDistibution(_qualifiedParticipants);
        require(_rewards.length == _winnersWallets.length, "Invalid winners array length");

        for (uint256 i = 0; i < _winnersWallets.length; i++) {
            winners[_winnersWallets[i]] = Winner(
                i + 1,
                _winnersWallets[i],
                false,
                _rewards[i]
            );
        }

        uint256 _balance = this.getPrizePool();

        // protocol fees
        uint256 _fees = getProtocolFees();
        uint256 _partReward = _fees/3;
        // organiser
        bool _successTransferOrganiser = platformToken.transfer(organiser, _partReward);
        require(_successTransferOrganiser, "Organiser protocol fees transfer failure");
        // stakeing
        bool _successTransferStake = platformToken.transfer(stakeAddress, _partReward);
        require(_successTransferStake, "Stakeing protocol fees transfer failure");
        // treasury
        bool _successTransferTreasury = platformToken.transfer(treasury, _fees - _partReward * 2);
        require(_successTransferTreasury, "Treasury protocol fees transfer failure");

        balance = _balance;

        isWinnersSet = true;
    }

    // protocol fees
    function getProtocolFees() private view returns (uint256) {
        return platformToken.balanceOf(address(this)) - ((platformToken.balanceOf(address(this)) * 7) / 10);
    }

    function getRewardsDistibution(uint256 _qualifiedParticipants) public view returns (uint256[] memory) {
        uint256 _minReward = 1;
        uint256 _balance = this.getPrizePool();
        if (_balance == 0 || _qualifiedParticipants <= 0)
            return new uint256[](0);
        bool _condition = true;
        uint256 _remaningPrizePool = _balance;
        uint256 _size = 0;
        while (_condition) {
            bool _isLast = _remaningPrizePool < metaData.entryFee || _remaningPrizePool < _minReward || _size + 1 >= _qualifiedParticipants;
            if (_isLast) {
                _condition = false;
            } else {
                uint256 _currentRewardLevel = _remaningPrizePool / 2;
                _remaningPrizePool = _remaningPrizePool - _currentRewardLevel;
            }
            _size++;
        }
        _condition = true;
        _remaningPrizePool = _balance;
        uint256[] memory _distiribution = new uint256[](_size);
        uint256 _iterator = 0;
        while (_condition) {
            bool _isLast = _remaningPrizePool < metaData.entryFee || _remaningPrizePool < _minReward || _iterator + 1 >= _qualifiedParticipants;
            if (_isLast) {
                _distiribution[_iterator] = _remaningPrizePool;
                _condition = false;
            } else {
                uint256 _currentRewardLevel = _remaningPrizePool / 2;
                _distiribution[_iterator] = _currentRewardLevel;
                _remaningPrizePool = _remaningPrizePool - _currentRewardLevel;
            }
            _iterator++;
        }
        return _distiribution;
    }

    // am I participated
    function amIParticipated() public senderIsAddress view returns (bool) {
        return this.isParticipated(msg.sender);
    }

    // is participated
    function isParticipated(address _wallet) public view returns (bool) {
        require(_wallet != address(0), 'Invalid wallet address');
        return participants[_wallet] != address(0);
    }

    // get winner data
    function getWinnerData(address _wallet) public senderIsAddress challengeWinnersIsSet view returns (Winner memory) {
        require(_wallet != address(0), 'Invalid wallet address');
        require(winners[_wallet].wallet != address(0), 'Winner not found');
        return winners[_wallet];
    }

    // check is winner
    function isWinner(address _wallet) public senderIsAddress challengeWinnersIsSet view returns (bool) {
        require(_wallet != address(0), 'Invalid wallet address');
        return winners[_wallet].wallet != address(0);
    }

    // check is reward to claim
    function isRewardClaimed(address _wallet) public senderIsAddress challengeWinnersIsSet view returns (bool) {
        require(_wallet != address(0), 'Invalid wallet address');
        require(winners[_wallet].wallet != address(0), 'Winner not found');
        return winners[_wallet].claimed;
    }

    // get challenge state
    function getChallengeState() public view returns (string memory) {
        ChallengeState _challengeState = forecastChallengeState();
        if (_challengeState == ChallengeState.DRAFT) return "Draft";
        if (_challengeState == ChallengeState.RUNNING) return "Open";
        if (_challengeState == ChallengeState.COMPLETED) return "Completed";
        if (_challengeState == ChallengeState.CANCELLED) return "Cancelled";
        return "Unknown";
    }

    // get metaData
    function getMetaData() public view returns (MetaData memory) {
        return metaData;
    }

    // get wallets
    function getParticipantWallets() public onlyOwner view returns (address[] memory) {
        return participantWallets;
    }

    // get owner
    function getOwner() public senderIsAddress view returns (address) {
        return owner;
    }

    // get organiser
    function getOrganiser() public view returns (address) {
        return organiser;
    }

    // am i owner
    function amIOwner() public senderIsAddress view returns (bool) {
        return msg.sender == owner;
    }

    // get is winners set
    function getIsWinnersSet() public view returns (bool) {
        return isWinnersSet;
    }

    // get prize Pool
    function getPrizePool() public view returns (uint256) {
        if (isWinnersSet)
            return balance;
        return (platformToken.balanceOf(address(this)) * 7) / 10;
    }

}