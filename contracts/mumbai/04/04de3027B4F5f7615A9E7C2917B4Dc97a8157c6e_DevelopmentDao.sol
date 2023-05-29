// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IStaking.sol";
import "../libs/types.sol";

contract GroupDao is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // join request index
    Counters.Counter public joinRequestIndex;
    // member index
    Counters.Counter public memberIndex;

    // staking address
    address public stakingAddress;

    // user address => group member status
    mapping(address => Types.Member) public members;
    // join request id => join request
    mapping(uint256 => Types.JoinRequest) public joinRequests;

    /**
     * @param requestId join request id
     * @param creator the creator of join request
     **/
    event JoinRequest(uint256 requestId, address indexed creator);

    /**
     * @param _joinRequestIndex join request index
     * @param acceptor acceptor
     **/
    event AeeptedJoinRequest(
        uint256 _joinRequestIndex,
        address indexed acceptor
    );

    /**
     * @param _user user address
     * @param _status member status
     * @dev emitted when update member status by only owner
     **/
    event MemberStatusUpdated(
        address indexed _user,
        Types.MemberStatus _status
    );

    /**
     * @param prev previous staking address
     * @param next next staking address
     * @dev emitted when dupdate staking address by only owner
     **/
    event SetStakingAddress(address indexed prev, address indexed next);

    /**
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    event WithdrawNative(address indexed toAddress, uint256 amount);

    /**
     * @param token token address
     * @param toAddress destination address
     * @param amount withdraw amount
     **/
    event Withdraw(
        address indexed token,
        address indexed toAddress,
        uint256 amount
    );

    /**
     * @param _user user address
     **/
    modifier checkMember(address _user) {
        require(isMember(_user), "GroupDao: Not member of group");
        _;
    }

    modifier onlyTokenHolder() {
        require(
            IERC20(getLOP()).balanceOf(msg.sender) > 0 ||
                IERC20(getVLOP()).balanceOf(msg.sender) > 0,
            "GroupDao: You have not enough LOP or vLOP token"
        );
        _;
    }

    modifier onlyStaker() {
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);
        require(
            (_stakeInfo.lopAmount + _stakeInfo.vLopAmount) > 0,
            "GroupDao: You have to stake LOP or vLOP token to access this contract"
        );
        _;
    }

    modifier onlyStakingContract() {
        require(
            stakingAddress == msg.sender,
            "GroupDao: Only staking contract can access this function"
        );
        _;
    }

    /**
     * @param _stakingAddress share holder dao address
     **/
    constructor(address _stakingAddress) {
        require(
            _stakingAddress != address(0),
            "GroupDao: staking address should not be the zero address"
        );

        stakingAddress = _stakingAddress;

        memberIndex.increment();

        emit SetStakingAddress(address(0), stakingAddress);
    }

    /**
     * @dev create a new request to join group
     **/
    function requestToJoin() external {
        require(
            members[msg.sender].status == Types.MemberStatus.NONE,
            "GroupDao: You already sent join request or a member of group"
        );

        Types.JoinRequest memory _joinRequest = Types.JoinRequest({
            status: Types.JoinRequestStatus.CREATED,
            owner: msg.sender
        });

        uint256 _joinRequestIndex = joinRequestIndex.current();
        joinRequests[_joinRequestIndex] = _joinRequest;

        Types.Member memory _member = Types.Member({
            owner: msg.sender,
            status: Types.MemberStatus.JOINNING,
            requestId: _joinRequestIndex
        });

        members[msg.sender] = _member;

        joinRequestIndex.increment();

        emit JoinRequest(_joinRequestIndex, msg.sender);
    }

    /**
     * @param _joinRequestIndex join request index
     * @dev accept join request
     **/
    function acceptJoinRequest(
        uint256 _joinRequestIndex
    ) external checkMember(msg.sender) {
        Types.JoinRequest storage _joinRequest = joinRequests[
            _joinRequestIndex
        ];

        Types.Member storage _member = members[_joinRequest.owner];

        require(
            _joinRequest.status == Types.JoinRequestStatus.CREATED,
            "GroupDao: the request is not created"
        );
        require(
            _member.status == Types.MemberStatus.JOINNING,
            "GroupDao: member status is not joinning"
        );

        _joinRequest.status = Types.JoinRequestStatus.PASSED;
        _member.status = Types.MemberStatus.JOINED;

        memberIndex.increment();

        emit AeeptedJoinRequest(_joinRequestIndex, msg.sender);
    }

    /**
     * @param _stakingAddress new staking address
     **/
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        require(
            _stakingAddress != address(0),
            "GroupDao: staking address should not be the zero address"
        );

        address _prevStakingAddress = stakingAddress;

        stakingAddress = _stakingAddress;

        emit SetStakingAddress(_prevStakingAddress, stakingAddress);
    }

    /**
     * @param _user user address
     * @param _status member status
     * @dev set member status by only owner
     * @dev contract owner can disable, enable, block user for group
     **/
    function setMemberStatus(
        address _user,
        Types.MemberStatus _status
    ) external onlyOwner {
        require(
            _user != address(0),
            "GroupDao: user should not be the zero address"
        );
        require(
            members[_user].status != _status,
            "GroupDao: same status error"
        );

        if (members[_user].status == Types.MemberStatus.JOINED) {
            memberIndex.decrement();
        }

        if (_status == Types.MemberStatus.JOINED) {
            memberIndex.increment();
        }

        members[_user].status = _status;

        emit MemberStatusUpdated(_user, _status);
    }

    /**
     * @param  toAddress address to receive fee
     * @param amount withdraw native token amount
     **/
    function withdrawNative(
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            toAddress != address(0),
            "GroupDao: The zero address should not be the fee address"
        );

        require(amount > 0, "GroupDao: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "GroupDao: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "GroupDao: Withdraw failed");

        emit WithdrawNative(toAddress, balance);
    }

    /**
     * @param token token address
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    function withdraw(
        address token,
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(0),
            "GroupDao: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "GroupDao: to address should not be the zero address"
        );
        require(amount > 0, "GroupDao: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "GroupDao: No balance to withdraw");

        IERC20(token).safeTransfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }

    /**
     * @dev get LOP address from ShareHolderDao
     **/
    function getLOP() public view returns (address) {
        return IStaking(stakingAddress).getLOP();
    }

    /**
     * @dev get vLOP address from ShareHolderDao
     **/
    function getVLOP() public view returns (address) {
        return IStaking(stakingAddress).getVLOP();
    }

    function getMinVotePercent() public view returns (uint256) {
        return IStaking(stakingAddress).getMinVotePercent();
    }

    /**
     * @param _user user address
     * @dev check is the member of gruop
     **/
    function isMember(address _user) public view returns (bool) {
        return
            members[_user].status == Types.MemberStatus.JOINED ||
            owner() == _user;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Basics/GroupDao.sol";
import "./interfaces/IProductDao.sol";
import "./interfaces/IERC20LOP.sol";
import "./interfaces/IShareHolderDao.sol";

contract DevelopmentDao is GroupDao {
    using Counters for Counters.Counter;
    // proposal index
    Counters.Counter public proposalIndex;
    // escrow proposal index
    Counters.Counter public escrowProposalIndex;

    // product dao address
    address public productDao;
    // share holder dao address
    address public shareHolderDao;

    // proposal id => DevelopmentProposal
    mapping(uint256 => Types.DevelopmentProposal) public proposals;
    // user address => proposal id => voting info
    mapping(address => mapping(uint256 => Types.VotingInfo)) public votingList;
    // proposal id => escrow amount
    mapping(uint256 => uint256) public escrowBudgets;
    // escrow proposal id => escrow proposal
    mapping(uint256 => Types.EscrowProposal) public escrowProposals;
    // user address => escrow proposal id => status
    mapping(address => mapping(uint256 => Types.VotingInfo))
        public escrowVotingList;

    /**
     * @param creator proposal creator
     * @param proposalIndex proposal index
     * @param metadata metadata URL
     * @param productId product id
     * @param budget budget
     **/
    event ProposalCreated(
        address indexed creator,
        uint256 proposalIndex,
        string metadata,
        uint256 productId,
        uint256 budget
    );

    /**
     * @param voter voter
     * @param proposalId proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event VoteYes(
        address indexed voter,
        uint256 proposalId,
        uint256 tokenAmount
    );

    /**
     * @param voter voter
     * @param proposalId proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event VoteNo(
        address indexed voter,
        uint256 proposalId,
        uint256 tokenAmount
    );

    /**
     * @param proposalId propoal id
     * @param activator activator
     **/
    event Activated(uint256 proposalId, address indexed activator);

    /**
     * @param proposalId proposal id
     * @param canceller canceller
     **/
    event Cancelled(uint256 proposalId, address indexed canceller);

    /**
     * @param proposalId propoal id
     * @param activator activator
     **/
    event EscrowActivated(uint256 proposalId, address indexed activator);

    /**
     * @param proposalId proposal id
     * @param canceller canceller
     **/
    event EscrowCancelled(uint256 proposalId, address indexed canceller);

    /**
     * @param prev previous product address
     * @param next next product address
     * @dev emitted when dupdate product dao address by only owner
     **/
    event ShareHolderDaoUpdated(address indexed prev, address indexed next);

    /**
     * @param prev previous product address
     * @param next next product address
     * @dev emitted when dupdate product dao address by only owner
     **/
    event ProductDaoUpdated(address indexed prev, address indexed next);

    /**
     * @param proposalId proposal id
     * @param amount escrow amount
     * @param escrowProposalIndex escrow proposal index
     **/
    event EscrowProposalCreated(
        uint256 proposalId,
        uint256 amount,
        uint256 escrowProposalIndex
    );

    /**
     * @param voter voter address
     * @param escrowId escrow proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event EscrowVoteYes(
        address indexed voter,
        uint256 escrowId,
        uint256 tokenAmount
    );

    /**
     * @param voter voter address
     * @param escrowId escrow proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event EscrowVoteNo(
        address indexed voter,
        uint256 escrowId,
        uint256 tokenAmount
    );

    /**
     * @param staker address staker
     * @param proposalId proposal id
     * @param oldAmount old amount
     * @param newAmount new amount
     **/
    event EvaluateVoteAmount(
        address indexed staker,
        uint256 proposalId,
        uint256 oldAmount,
        uint256 newAmount
    );

    /**
     * @param staker address staker
     * @param escrowProposalId proposal id
     * @param oldAmount old amount
     * @param newAmount new amount
     **/
    event EvaluateEscrowVoteAmount(
        address indexed staker,
        uint256 escrowProposalId,
        uint256 oldAmount,
        uint256 newAmount
    );

    /**
     * @param _shareHolderDao share holder dao address
     * @param _productDao product dao address
     **/
    constructor(
        address _shareHolderDao,
        address _productDao,
        address _stakingAddress
    ) GroupDao(_stakingAddress) {
        require(
            _shareHolderDao != address(0),
            "DevelopmentDao: share holder dao address should not be the zero address"
        );
        require(
            _productDao != address(0),
            "DevelopmentDao: product dao address should not be the zero address"
        );

        shareHolderDao = _shareHolderDao;

        productDao = _productDao;

        memberIndex.increment();

        emit ShareHolderDaoUpdated(address(0), shareHolderDao);
        emit ProductDaoUpdated(address(0), productDao);
    }

    /**
     * @param _metadata metadata URL
     * @param _productId proposal id
     * @param _budget proposal budget
     **/
    function createProposal(
        string calldata _metadata,
        uint256 _productId,
        uint256 _budget
    ) external onlyTokenHolder {
        Types.ProductProposal memory _prposal = IProductDao(productDao)
            .getProposalById(_productId);

        require(
            bytes(_metadata).length > 0,
            "DevelopmentDao: metadata should not be empty string"
        );
        require(
            _prposal.status == Types.ProposalStatus.ACTIVE,
            "DevelopmentDao: proposal is not active now"
        );
        require(
            _budget > 0,
            "DevelopmentDao: budget should be greater than the zero"
        );

        uint256 _proposalIndex = proposalIndex.current();

        Types.DevelopmentProposal memory _proposal = Types.DevelopmentProposal({
            metadata: _metadata,
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            voteYes: 0,
            voteYesAmount: 0,
            voteNo: 0,
            voteNoAmount: 0,
            productId: _productId,
            budget: _budget,
            createdAt: block.timestamp
        });

        proposals[_proposalIndex] = _proposal;

        proposalIndex.increment();

        emit ProposalCreated(
            msg.sender,
            _proposalIndex,
            _metadata,
            _productId,
            _budget
        );
    }

    /**
     * @param _proposalId proposal id
     **/
    function voteYes(uint256 _proposalId) external onlyStaker checkMember(msg.sender) {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            _proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal is not created"
        );
        require(
            !_votingInfo.isVoted,
            "DevelopmentDao: proposal is already voted"
        );
        require(
            _stakeInfo.developmentVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteYes++;
        _proposal.voteYesAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = true;

        IStaking(stakingAddress).addDevelopmentVotingId(
            msg.sender,
            _proposalId
        );

        emit VoteYes(msg.sender, _proposalId, _tokenAmount);
    }

    /**
     * @param _proposalId proposal id
     **/
    function voteNo(uint256 _proposalId) external onlyStaker checkMember(msg.sender) {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            _proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal is not created"
        );
        require(
            !_votingInfo.isVoted,
            "DevelopmentDao: proposal is already voted"
        );
        require(
            _stakeInfo.developmentVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteNo++;
        _proposal.voteNoAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = false;

        IStaking(stakingAddress).addDevelopmentVotingId(
            msg.sender,
            _proposalId
        );

        emit VoteNo(msg.sender, _proposalId, _tokenAmount);
    }

    /**
     * @param _proposalId proposal id
     * @dev only proposal creator can execute one's proposal
     **/
    function execute(uint256 _proposalId) external onlyTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "DevelopmentDao: You are not the owner of this proposal"
        );

        uint256 _shareHolderTotalBudget = IShareHolderDao(shareHolderDao)
            .totalBudget();

        require(
            _proposal.budget <= _shareHolderTotalBudget,
            "DevelopmentDao: proposal budget should be less than shareholder budget"
        );

        uint256 _voteYesPercent = (_proposal.voteYesAmount * 100) /
            (_proposal.voteYesAmount + _proposal.voteNoAmount);

        uint256 _totalYesPercent = (_proposal.voteYesAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        uint256 _totalNoPercent = (_proposal.voteNoAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        if (!(_totalYesPercent > 50 || _totalNoPercent > 50)) {
            require(
                (IStaking(stakingAddress).getProposalExpiredDate() +
                    _proposal.createdAt) < block.timestamp,
                "DevelopmentDao: You can execute proposal after expired"
            );
        }

        if (_voteYesPercent >= IStaking(stakingAddress).getMinVotePercent()) {
            _proposal.status = Types.ProposalStatus.ACTIVE;

            IShareHolderDao(shareHolderDao).decreaseBudget(_proposal.budget);

            IERC20LOP(getLOP()).mint(address(this), _proposal.budget);

            escrowBudgets[_proposalId] = _proposal.budget;

            IStaking(stakingAddress).removeDevelopmentVotingId(
                msg.sender,
                _proposalId
            );

            emit Activated(_proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;

            IStaking(stakingAddress).removeDevelopmentVotingId(
                msg.sender,
                _proposalId
            );

            emit Cancelled(_proposalId, msg.sender);
        }
    }

    /**
     * @param _proposalId proposal id
     * @param _amount proposal amount
     **/
    function escrowCreateProposal(
        uint256 _proposalId,
        uint256 _amount
    ) external onlyTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];

        require(
            _proposal.status == Types.ProposalStatus.ACTIVE,
            "DevelopmentDao: Proposal status is not active"
        );
        require(
            _proposal.owner == msg.sender,
            "DevelopmentDao: You are not the owner of proposal"
        );
        require(
            _amount > 0,
            "DevelopmentDao: amount should be greater than the zero"
        );
        require(
            escrowBudgets[_proposalId] >= _amount,
            "DevelopmentDao: amount should be less than the escrow budget"
        );

        Types.EscrowProposal memory _escrowProposal = Types.EscrowProposal({
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            budget: _amount,
            voteYes: 0,
            voteYesAmount: 0,
            voteNo: 0,
            voteNoAmount: 0,
            createdAt: block.timestamp
        });

        uint256 _escrowProposalIndex = escrowProposalIndex.current();
        escrowProposals[_escrowProposalIndex] = _escrowProposal;

        escrowProposalIndex.increment();

        emit EscrowProposalCreated(_proposalId, _amount, _escrowProposalIndex);
    }

    /**
     * @param escrowId escrow proposal id
     **/
    function escrowVoteYes(uint256 escrowId) external onlyTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            !escrowVotingList[msg.sender][escrowId].isVoted,
            "DevelopmentDao: You already voted this proposal"
        );
        require(
            _stakeInfo.developmentEscrowVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        escrowVotingList[msg.sender][escrowId].isVoted = true;
        escrowVotingList[msg.sender][escrowId].voteAmount = _tokenAmount;
        escrowVotingList[msg.sender][escrowId].voteType = true;

        _escrowProposal.voteYes += 1;
        _escrowProposal.voteYesAmount += _tokenAmount;

        IStaking(stakingAddress).addDevelopmentEscrowVotingId(
            msg.sender,
            escrowId
        );

        emit EscrowVoteYes(msg.sender, escrowId, _tokenAmount);
    }

    /**
     * @param escrowId escrow proposal id
     **/
    function escrowVoteNo(uint256 escrowId) external onlyTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            !escrowVotingList[msg.sender][escrowId].isVoted,
            "DevelopmentDao: You already voted this proposal"
        );
        require(
            _stakeInfo.developmentEscrowVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        escrowVotingList[msg.sender][escrowId].isVoted = true;
        escrowVotingList[msg.sender][escrowId].voteAmount = _tokenAmount;
        escrowVotingList[msg.sender][escrowId].voteType = false;

        _escrowProposal.voteNo += 1;
        _escrowProposal.voteNoAmount += _tokenAmount;

        IStaking(stakingAddress).addDevelopmentEscrowVotingId(
            msg.sender,
            escrowId
        );

        emit EscrowVoteNo(msg.sender, escrowId, _tokenAmount);
    }

    function escrowVoteExecute(uint256 escrowId) external onlyTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            _escrowProposal.owner == msg.sender,
            "DevelopmentDao: only proposal owner can execute"
        );

        uint256 _voteYesPercent = (_escrowProposal.voteYesAmount * 100) /
            (_escrowProposal.voteYesAmount + _escrowProposal.voteNoAmount);

        uint256 _totalYesPercent = (_escrowProposal.voteYesAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        uint256 _totalNoPercent = (_escrowProposal.voteNoAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        if (!(_totalYesPercent > 50 || _totalNoPercent > 50)) {
            require(
                (IStaking(stakingAddress).getProposalExpiredDate() +
                    _escrowProposal.createdAt) >= block.timestamp,
                "DevelopmentDao: You can execute proposal after expired"
            );
        }

        if (_voteYesPercent >= IStaking(stakingAddress).getMinVotePercent()) {
            _escrowProposal.status = Types.ProposalStatus.ACTIVE;

            escrowBudgets[escrowId] -= _escrowProposal.budget;

            require(
                IERC20LOP(IStaking(stakingAddress).getLOP()).transfer(
                    msg.sender,
                    _escrowProposal.budget
                ),
                "DevelopmentDao: tansfer LOP token fail"
            );

            emit EscrowActivated(escrowId, msg.sender);
        } else {
            _escrowProposal.status = Types.ProposalStatus.CANCELLED;

            emit EscrowCancelled(escrowId, msg.sender);
        }
    }

    function evaluateVoteAmount(
        address staker,
        uint256 proposalId
    ) external onlyStakingContract {
        require(
            staker != address(0),
            "DevelopmentDao: staker should not be the zero address"
        );

        Types.VotingInfo storage _votingInfo = votingList[staker][proposalId];
        Types.DevelopmentProposal storage _developmentProposal = proposals[
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(staker);

        uint256 _newStakeAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;
        uint256 _oldStakeAmount = _votingInfo.voteAmount;

        if (_votingInfo.isVoted) {
            if (_votingInfo.voteType) {
                // vote yes
                _developmentProposal.voteYesAmount =
                    _developmentProposal.voteYesAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            } else {
                // vote no
                _developmentProposal.voteNoAmount =
                    _developmentProposal.voteNoAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            }

            _votingInfo.voteAmount = _newStakeAmount;
        }

        emit EvaluateVoteAmount(
            staker,
            proposalId,
            _oldStakeAmount,
            _newStakeAmount
        );
    }

    function evaluateEscrowVoteAmount(
        address staker,
        uint256 escrowProposalId
    ) external onlyStakingContract {
        require(
            staker != address(0),
            "DevelopmentDao: staker should not be the zero address"
        );

        Types.VotingInfo storage _escrowVotingInfo = escrowVotingList[staker][
            escrowProposalId
        ];
        Types.EscrowProposal
            storage _developmentEscrowProposal = escrowProposals[
                escrowProposalId
            ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(staker);

        uint256 _newStakeAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;
        uint256 _oldStakeAmount = _escrowVotingInfo.voteAmount;

        if (_escrowVotingInfo.isVoted) {
            if (_escrowVotingInfo.voteType) {
                // vote yes
                _developmentEscrowProposal.voteYesAmount =
                    _developmentEscrowProposal.voteYesAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            } else {
                // vote no
                _developmentEscrowProposal.voteNoAmount =
                    _developmentEscrowProposal.voteNoAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            }

            _escrowVotingInfo.voteAmount = _newStakeAmount;
        }

        emit EvaluateEscrowVoteAmount(
            staker,
            escrowProposalId,
            _oldStakeAmount,
            _newStakeAmount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20LOP {
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IProductDao {
    function evaluateVoteAmount(address staker, uint256 proposalId) external;

    function getProposalById(
        uint256 _proposalId
    ) external view returns (Types.ProductProposal memory _proposal);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IShareHolderDao {
    function decreaseBudget(uint256 _amount) external;

    function getMyVoteType(
        address _user,
        uint256 _proposalId
    ) external view returns (bool);

    function totalBudget() external view returns (uint256);

    function evaluateVoteAmount(address staker, uint256 proposalId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IStaking {
    function getStakeAmount(address staker) external view returns (uint256);

    function getLOP() external view returns (address);

    function getVLOP() external view returns (address);

    function getMinVotePercent() external view returns (uint256);

    function getStakingInfo(
        address staker
    ) external view returns (Types.StakeInfo memory);

    function MAX_SHARE_HOLDER_VOTING_COUNT() external view returns (uint256);

    function MAX_PRODUCT_VOTING_COUNT() external view returns (uint256);

    function MAX_DEVELOPMENT_VOTING_COUNT() external view returns (uint256);

    function getProposalExpiredDate() external view returns (uint256);

    function addShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external;

    function removeShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external;

    function addProductVotingId(
        address _staker,
        uint256 _productProposalId
    ) external;

    function removeProductVotingId(
        address _staker,
        uint256 _productProposalId
    ) external;

    function addDevelopmentVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external;

    function removeDevelopmentVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external;

    function addDevelopmentEscrowVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external;

    function removeDevelopmentEscrowVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Types {
    enum ProposalStatus {
        NONE,
        CREATED,
        CANCELLED,
        ACTIVE
    }

    enum JoinRequestStatus {
        NONE,
        CREATED,
        PASSED,
        CANCELLED
    }

    enum MemberStatus {
        NONE,
        JOINNING,
        JOINED
    }

    struct ShareHolderProposal {
        uint256 budget;
        address owner;
        ProposalStatus status;
        uint256 voteYes;
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 createdAt;
    }

    struct JoinRequest {
        JoinRequestStatus status;
        address owner;
    }

    struct Member {
        address owner;
        uint256 requestId;
        MemberStatus status;
    }

    struct ProductProposal {
        string metadata;
        ProposalStatus status;
        address owner;
        uint256 voteYes;
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 createdAt;
    }

    struct DevelopmentProposal {
        string metadata;
        ProposalStatus status;
        address owner;
        uint256 voteYes;
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 productId;
        uint256 budget;
        uint256 createdAt;
    }

    struct EscrowProposal {
        ProposalStatus status;
        address owner;
        uint256 budget;
        uint256 voteYes;
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 createdAt;
    }

    struct StakeInfo {
        uint256 lopAmount;
        uint256 vLopAmount;
        uint256[] shareHolderVotingIds;
        uint256[] productVotingIds;
        uint256[] developmentVotingIds;
        uint256[] developmentEscrowVotingIds;
    }

    struct VotingInfo {
        bool isVoted;
        bool voteType; // true => VOTE Yes, false => VOTE No
        uint256 voteAmount;
    }
}