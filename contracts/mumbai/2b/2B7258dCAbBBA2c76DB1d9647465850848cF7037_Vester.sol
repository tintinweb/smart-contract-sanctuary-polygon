// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vester {
    using SafeERC20 for IERC20;
    struct ReceiverData {
        uint256 amount;
        uint256 released;
        bool revoked;
    }
    struct VestingSchedule {
        address owner; // address of vesting creater
        address token; //address of vesting tokens
        uint256 totalAmount; // total amount of tokens to be released at the end of the vesting
        uint256 start; // start time of the vesting period
        uint256 cliff; // cliff duration in seconds
        uint256 duration; // duration of the vesting period in seconds
        uint256 slicePeriodSeconds; // duration of a slice period for the vesting in seconds
        bool revocable; // whether or not the vesting is revocable
    }
    uint256 public vestingIds;
    mapping(uint256 => mapping(address => ReceiverData)) private receivers; //mapping for receivers data
    mapping(uint256 => VestingSchedule) vestingSchedules;
    mapping(address => uint256[]) depositorsVesting;
    mapping(address => uint256[]) receiversVesting;

    event VestingCreated(
        uint256 vestingId,
        address owner,
        address token,
        uint256 totalAmount,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 slicePeriodSeconds,
        bool revocable
    );
    event ReceiversData(
        uint256 vestingId,
        address receiver,
        uint256 amount,
        uint256 released,
        bool revoked
    );
    event VestingRevoked(
        uint256 vestingId,
        address receiver,
        uint256 returnAmount,
        uint256 withdrawAmount,
        bool revoked
    );
    event WithdrawAmount(uint256 vestingId, address receiver, uint256 amount);

    /**
     *@dev function createVesing in contract
     *@param _receivers {address[]} array of receiver's addresses
     *@param _token {address} address of token
     *@param _amounts {address[]} array amounts for respective receivers
     *@param _start {uint256} start time for vesting Schedule
     *@param _cliff {uint256} cliff time for vesting Schedule
     *@param _duration {uint256} total time period of vesting
     *@param _slicePeriodSeconds {uint256} time duration for each slice
     *@param _revocable {bool} whether vesting revocable or not
     */
    function createVesting(
        address[] calldata _receivers,
        address _token,
        uint256[] calldata _amounts,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable
    ) public {
        require(_duration > 0, "Duration must be > 0");
        require(_slicePeriodSeconds > 0, "SlicePeriodSeconds must be > 0");
        require(
            _slicePeriodSeconds <= _duration,
            "SlicePeriod should not exceed to duration"
        );
        require(
            _cliff <= _duration,
            "Cliff time should not exceed to duration"
        );
        require(_start >= block.timestamp, "Invalid Start Time");

        uint256 totalAmount;
        require(
            _receivers.length == _amounts.length,
            "Not valid input for Receiver or Token Amount"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0), "Invalid Reciever Address");
            require(_amounts[i] > 0, "Amount must be > 0");
            totalAmount += _amounts[i];
        }

        bool result = IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        require(result, "Transaction inturrupted");

        VestingSchedule storage v = vestingSchedules[++vestingIds];
        v.owner = msg.sender;
        v.token = _token;
        v.totalAmount = totalAmount;
        v.start = _start;
        v.cliff = _cliff;
        v.duration = _duration;
        v.slicePeriodSeconds = _slicePeriodSeconds;
        v.revocable = _revocable;

        emit VestingCreated(
            vestingIds,
            msg.sender,
            _token,
            totalAmount,
            _start,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            _revocable
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            address rec = _receivers[i];
            receivers[vestingIds][rec] = ReceiverData(_amounts[i], 0, false);
            receiversVesting[rec].push(vestingIds);
            emit ReceiversData(vestingIds, rec, _amounts[i], 0, false);
        }
        depositorsVesting[msg.sender].push(vestingIds);
    }

    /**
     *@dev revoke vestingSchedule for given receiver
     *@param _vestingId {uint256} vesting id for perticular vesingSchedule
     *@param _receiver {address} address of receiver
     */
    function revoke(uint256 _vestingId, address _receiver) public {
        require(_vestingId <= vestingIds, "Invalid vestingIds");
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingId];
        require(
            vestingSchedule.owner == msg.sender,
            "Not Authorized to revoke"
        );
        ReceiverData storage receiverData = receivers[vestingIds][_receiver];
        require(receiverData.amount != 0, "Receiver not found");
        require(vestingSchedule.revocable, "vesting is not revocable");
        require(!receiverData.revoked, "vesting is already revoked");
        uint256 releasableAmount = _getReleasableAmount(
            vestingSchedule,
            _receiver
        );
        receiverData.released = receiverData.released + releasableAmount;
        uint256 returnAmount = vestingSchedule.totalAmount -
            receiverData.released;
        receiverData.revoked = true;
        emit VestingRevoked(
            _vestingId,
            _receiver,
            returnAmount,
            releasableAmount,
            true
        );
        _release(vestingSchedule, _receiver, releasableAmount, returnAmount);
    }

    /**
     *@dev withdraw given amount of token to receiver
     *@param _vestingId {uint256} vesting id for perticular vesingSchedule
     *@param _amount {uint256} amount of token to withdraw
     */
    function withdraw(uint256 _vestingId, uint256 _amount) public {
        require(_vestingId <= vestingIds, "Invalid vestingIds");
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingId];
        require(
            receivers[_vestingId][msg.sender].amount != 0,
            "Receiver not found"
        );
        uint256 releasableAmount = _getReleasableAmount(
            vestingSchedule,
            msg.sender
        );
        require(releasableAmount > _amount, "Not enough tokens to withdraw");
        receivers[vestingIds][msg.sender].released =
            receivers[vestingIds][msg.sender].released +
            _amount;
        emit WithdrawAmount(_vestingId, msg.sender, _amount);
        _release(vestingSchedule, msg.sender, _amount, 0);
    }

    /**
     *@dev getReceiversVesting get vestingIds of receiver
     *@param _account {address} address of receiver
     *@return {uint256[]} array of vesting ids
     */
    function getReceiversVesting(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return receiversVesting[_account];
    }

    /**
     *@dev getDepositorsVesting get vestingIds of depositor
     *@param _account {address} address of depositor
     *@return {uint256[]} array of vesting ids
     */
    function getDepositorsVesting(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return depositorsVesting[_account];
    }

    function getVestingSchedules(uint256 _vestingId, address _receiver)
        public
        view
        returns (VestingSchedule memory, ReceiverData memory)
    {
        return (vestingSchedules[_vestingId], receivers[vestingIds][_receiver]);
    }

    /**
     * @dev _getReleasableAmount calculate releasable amount
     * @param vestingSchedule {VestingSchedule} vestingSchedule data
     * @param _receiver {address} address of receiver
     * @return {uint256} amount of releaseable token
     */
    function _getReleasableAmount(
        VestingSchedule memory vestingSchedule,
        address _receiver
    ) internal view returns (uint256) {
        ReceiverData memory receiverData = receivers[vestingIds][_receiver];
        uint256 currentTime = block.timestamp;
        if (
            (currentTime < (vestingSchedule.start + vestingSchedule.cliff)) ||
            receiverData.revoked
        ) {
            return 0;
        } else if (
            currentTime >= vestingSchedule.start + vestingSchedule.duration
        ) {
            return receiverData.amount - receiverData.released;
        } else {
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            uint256 releasableAmount = (vestingSchedule.totalAmount *
                vestedSeconds) / (vestingSchedule.duration);
            releasableAmount = releasableAmount - receiverData.released;
            return releasableAmount;
        }
    }

    /**
     *@dev _release transfers tokens to receiver and owner
     *@param _vestingSchedule {VestingSchedule} address of receiver
     *@param _receiver {address} address of receiver
     *@param _releasableAmount {uint256} amount of token for receiver to get
     *@param _returnAmount {uint256} amount of token for owner to get
     */
    function _release(
        VestingSchedule memory _vestingSchedule,
        address _receiver,
        uint256 _releasableAmount,
        uint256 _returnAmount
    ) internal {
        IERC20(_vestingSchedule.token).safeTransfer(
            _receiver,
            _releasableAmount
        );
        if (_returnAmount > 0) {
            IERC20(_vestingSchedule.token).safeTransfer(
                _vestingSchedule.owner,
                _returnAmount
            );
        }
    }
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