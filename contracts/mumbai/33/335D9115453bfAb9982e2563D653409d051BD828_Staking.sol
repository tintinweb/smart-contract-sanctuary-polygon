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
import "../libs/types.sol";

interface IDevelopmentDao {
    function evaluateVoteAmount(address staker, uint256 proposalId) external;
    function evaluateEscrowVoteAmount(address staker, uint256 proposalId) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/types.sol";
import "./interfaces/IShareHolderDao.sol";
import "./interfaces/IProductDao.sol";
import "./interfaces/IDevelopmentDao.sol";

contract Staking is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // staking index
    Counters.Counter public stakingIndex;

    // share holder dao address
    address public SHARE_HOLDER_ADDRESS;
    // product dao address
    address public PRODUCT_ADDRESS;
    // development dao address
    address public DEVELOPMENT_ADDRESS;

    uint256 private _PROPOSAL_EXPIRED_DATE;

    // max shareholder voting count
    uint256 private _MAX_SHARE_HOLDER_VOTING_COUNT;
    // max prodcut voting count
    uint256 private _MAX_PRODUCT_VOTING_COUNT;
    // max development voting count
    uint256 private _MAX_DEVELOPMENT_VOTING_COUNT;

    // ERC20 _LOP address
    address private _LOP;
    // ERC20 _vLOP address
    address private _vLOP;

    // minimum vote percent
    uint256 private _minVotePercent;

    //staker => stake info
    mapping(address => Types.StakeInfo) public _stakingList;
    /**
     * @param staker address of staker
     * @param amount staking amount
     **/
    event StakeLop(address indexed staker, uint256 amount);
    /**
     * @param staker address of staker
     * @param amount staking amount
     **/
    event StakeVLop(address indexed staker, uint256 amount);
    /**
     * @param withdrawer address of withdrawer
     * @param amount withdraw amount of LOP
     **/
    event WithdrawLop(address indexed withdrawer, uint256 amount);
    /**
     * @param withdrawer address of withdrawer
     * @param amount withdraw amount of LOP
     **/
    event WithdrawVLop(address indexed withdrawer, uint256 amount);
    /**
     * @param staker address of staker
     * @param shareHolderProposalId share holder proposal id
     **/
    event AddShareHolderVotingId(
        address indexed staker,
        uint256 shareHolderProposalId
    );
    /**
     * @param staker address of staker
     * @param shareHolderProposalId share holder proposal id
     **/
    event RemoveShareHolderVotingId(
        address indexed staker,
        uint256 shareHolderProposalId
    );
    /**
     * @param staker address of staker
     * @param productProposalId product proposal id
     **/
    event AddProductVotingId(address indexed staker, uint256 productProposalId);
    /**
     * @param staker address of staker
     * @param productProposalId product proposal id
     **/
    event RemoveProductVotingId(
        address indexed staker,
        uint256 productProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentProposalId development proposal id
     **/
    event AddDevelopmentVotingId(
        address indexed staker,
        uint256 developmentProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentProposalId development proposal id
     **/
    event RemoveDevelopmentVotingId(
        address indexed staker,
        uint256 developmentProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentEscrowProposalId development escrow proposal id
     **/
    event AddDevelopmentEscrowVotingId(
        address indexed staker,
        uint256 developmentEscrowProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentEscrowProposalId development escrow proposal id
     **/
    event RemoveDevelopmentEscrowVotingId(
        address indexed staker,
        uint256 developmentEscrowProposalId
    );
    /**
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    event AdminWithdrawNative(address indexed toAddress, uint256 amount);
    /**
     * @param token token address
     * @param toAddress destination address
     * @param amount withdraw amount
     **/
    event AdminWithdraw(
        address indexed token,
        address indexed toAddress,
        uint256 amount
    );
    /**
     * @param _LOP ERC20 _LOP address
     **/
    event SetLOP(address indexed _LOP);
    /**
     * @param _vLOP ERC20 _vLOP address
     **/
    event SetVLOP(address indexed _vLOP);

    /**
     * @param minVotePercent min vote percent
     **/
    event MinVoteUpdated(uint256 minVotePercent);

    /**
     * @param _proposalExpiredDate proposal expired date
     **/
    event SetProposalExpiredDate(uint256 _proposalExpiredDate);

    /**
     * @param _MAX_SHARE_HOLDER_VOTING_COUNT max share holder voting count
     **/
    event SetMaxShareHolderVotingCount(uint256 _MAX_SHARE_HOLDER_VOTING_COUNT);

    /**
     * @param _MAX_PRODUCT_VOTING_COUNT max product voting count
     **/
    event SetMaxProductVotingCount(uint256 _MAX_PRODUCT_VOTING_COUNT);

    /**
     * @param _MAX_DEVELOPMENT_VOTING_COUNT max development voting count
     **/
    event SetMaxDevelopmentVotingCount(uint256 _MAX_DEVELOPMENT_VOTING_COUNT);

    /**
     * @param SHARE_HOLDER_ADDRESS share holder address
     **/
    event SetShareHolderAddress(address SHARE_HOLDER_ADDRESS);

    /**
     * @param PRODUCT_ADDRESS product address
     **/
    event SetProductAddress(address PRODUCT_ADDRESS);

    /**
     * @param DEVELOPMMENT_ADDRESS development address
     **/
    event SetDevelopmentAddress(address DEVELOPMMENT_ADDRESS);

    modifier onlyShareHolderContract() {
        require(
            msg.sender == SHARE_HOLDER_ADDRESS,
            "Staking: Only share holder contract can access this function"
        );
        _;
    }

    modifier onlyProductContract() {
        require(
            msg.sender == PRODUCT_ADDRESS,
            "Staking: Only product contract can access this function"
        );
        _;
    }

    modifier onlyDevelopmentContract() {
        require(
            msg.sender == DEVELOPMENT_ADDRESS,
            "Staking: Only development contract can access this function"
        );
        _;
    }

    constructor(address LOP_, address vLOP_, uint256 minVotePercent_) {
        require(
            LOP_ != address(0),
            "Staking: LOP address hould not be the zero address"
        );
        require(
            vLOP_ != address(0),
            "Staking: vLOP address hould not be the zero address"
        );

        require(
            minVotePercent_ > 0,
            "Staking: min vote percent should be greater than the zero"
        );

        _LOP = LOP_;
        _vLOP = vLOP_;

        _minVotePercent = minVotePercent_;

        _MAX_SHARE_HOLDER_VOTING_COUNT = 5;
        _MAX_PRODUCT_VOTING_COUNT = 5;
        _MAX_DEVELOPMENT_VOTING_COUNT = 5;

        // 14 days
        _PROPOSAL_EXPIRED_DATE = 14 * 24 * 60 * 60;

        emit SetLOP(_LOP);
        emit SetVLOP(_vLOP);
        emit SetMaxShareHolderVotingCount(_MAX_SHARE_HOLDER_VOTING_COUNT);
        emit SetMaxDevelopmentVotingCount(_MAX_DEVELOPMENT_VOTING_COUNT);
        emit SetMaxProductVotingCount(_MAX_PRODUCT_VOTING_COUNT);
        emit SetProposalExpiredDate(_PROPOSAL_EXPIRED_DATE);
    }

    /**
     * @param amount staking amount of LOP
     **/
    function stakeLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.lopAmount += amount;
        IERC20(_LOP).safeTransferFrom(msg.sender, address(this), amount);

        _evaluateShareHolderDao(msg.sender);

        emit StakeLop(msg.sender, amount);
    }

    /**
     * @param amount staking amount of vLOP
     **/
    function stakeVLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.vLopAmount += amount;
        IERC20(_vLOP).safeTransferFrom(msg.sender, address(this), amount);

        _evaluateShareHolderDao(msg.sender);

        emit StakeVLop(msg.sender, amount);
    }

    /**
     * @dev withdraw LOP token
     **/
    function withdrawLop() external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(
            _stakeInfo.lopAmount > 0,
            "Staking: amount should not be the zero amount"
        );

        uint256 _amount = _stakeInfo.lopAmount;
        _stakeInfo.lopAmount = 0;
        IERC20(_LOP).safeTransfer(msg.sender, _amount);

        _evaluateShareHolderDao(msg.sender);

        emit WithdrawLop(msg.sender, _amount);
    }

    /**
     * @dev withdraw vLOP token
     **/
    function withdrawVLop() external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(
            _stakeInfo.vLopAmount > 0,
            "Staking: amount should not be the zero amount"
        );

        uint256 _amount = _stakeInfo.vLopAmount;
        _stakeInfo.vLopAmount = 0;
        IERC20(_vLOP).safeTransfer(msg.sender, _amount);

        _evaluateShareHolderDao(msg.sender);

        emit WithdrawVLop(msg.sender, _amount);
    }

    /**
     * @param _staker address of staker
     * @param _shareHolderProposalId share holder proposal id
     ** */
    function addShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external onlyShareHolderContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.shareHolderVotingIds.push(_shareHolderProposalId);

        emit AddShareHolderVotingId(_staker, _shareHolderProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _shareHolderProposalId share holder proposal id
     ** */
    function removeShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external onlyShareHolderContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.shareHolderVotingIds.push(_shareHolderProposalId);
        uint256 _votingIdsLen = _stakeInfo.shareHolderVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (_stakeInfo.shareHolderVotingIds[i] == _shareHolderProposalId) {
                _stakeInfo.shareHolderVotingIds[i] = _stakeInfo
                    .shareHolderVotingIds[_votingIdsLen];
                _stakeInfo.shareHolderVotingIds.pop();
                break;
            }
        }

        emit RemoveShareHolderVotingId(_staker, _shareHolderProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _productProposalId product proposal id
     ** */
    function addProductVotingId(
        address _staker,
        uint256 _productProposalId
    ) external onlyProductContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.productVotingIds.push(_productProposalId);

        emit AddProductVotingId(_staker, _productProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _productProposalId product proposal id
     ** */
    function removeProductVotingId(
        address _staker,
        uint256 _productProposalId
    ) external onlyProductContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.productVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (_stakeInfo.productVotingIds[i] == _productProposalId) {
                _stakeInfo.productVotingIds[i] = _stakeInfo.productVotingIds[
                    _votingIdsLen - 1
                ];
                _stakeInfo.productVotingIds.pop();
                break;
            }
        }

        emit RemoveProductVotingId(_staker, _productProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _developmentProposalId development proposal id
     ** */
    function addDevelopmentVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.developmentVotingIds.push(_developmentProposalId);

        emit AddDevelopmentVotingId(_staker, _developmentProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _developmentProposalId development proposal id
     ** */
    function removeDevelopmentVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.developmentVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (_stakeInfo.developmentVotingIds[i] == _developmentProposalId) {
                _stakeInfo.developmentVotingIds[i] = _stakeInfo
                    .developmentVotingIds[_votingIdsLen - 1];
                _stakeInfo.developmentVotingIds.pop();
                break;
            }
        }

        emit RemoveDevelopmentVotingId(_staker, _developmentProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _developmentEscrowProposalId development proposal id
     ** */
    function addDevelopmentEscrowVotingId(
        address _staker,
        uint256 _developmentEscrowProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.developmentEscrowVotingIds.push(
            _developmentEscrowProposalId
        );

        emit AddDevelopmentEscrowVotingId(
            _staker,
            _developmentEscrowProposalId
        );
    }

    /**
     * @param _staker address of staker
     * @param _developmentEscrowProposalId development proposal id
     ** */
    function removeDevelopmentEscrowVotingId(
        address _staker,
        uint256 _developmentEscrowProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.developmentEscrowVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (
                _stakeInfo.developmentEscrowVotingIds[i] ==
                _developmentEscrowProposalId
            ) {
                _stakeInfo.developmentEscrowVotingIds[i] = _stakeInfo
                    .developmentEscrowVotingIds[_votingIdsLen - 1];
                _stakeInfo.developmentEscrowVotingIds.pop();
                break;
            }
        }

        emit RemoveDevelopmentVotingId(_staker, _developmentEscrowProposalId);
    }

    /**
     * @param  toAddress address to receive fee
     * @param amount withdraw native token amount
     **/
    function adminWithdrawNative(
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            toAddress != address(0),
            "Staking: The zero address should not be the fee address"
        );

        require(amount > 0, "Staking: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "Staking: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "Staking: Withdraw failed");

        emit AdminWithdrawNative(toAddress, balance);
    }

    /**
     * @param token token address
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    function adminWithdraw(
        address token,
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(0),
            "Staking: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "Staking: to address should not be the zero address"
        );
        require(amount > 0, "Staking: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "Staking: No balance to withdraw");

        IERC20(token).safeTransfer(toAddress, amount);

        emit AdminWithdraw(token, toAddress, amount);
    }

    /**
     * @param _shareHolderAddress share holder address
     * @dev only owner can set share holder address
     **/
    function setShareHolderAddress(
        address _shareHolderAddress
    ) external onlyOwner {
        require(
            _shareHolderAddress != address(0),
            "Staking: share holder address should not be the zero"
        );

        SHARE_HOLDER_ADDRESS = _shareHolderAddress;

        emit SetShareHolderAddress(SHARE_HOLDER_ADDRESS);
    }

    /**
     * @param _productAddress product address
     * @dev only owner can set product address
     **/
    function setProductAddress(address _productAddress) external onlyOwner {
        require(
            _productAddress != address(0),
            "Staking: product address should not be the zero"
        );

        PRODUCT_ADDRESS = _productAddress;

        emit SetProductAddress(PRODUCT_ADDRESS);
    }

    /**
     * @param _developmentAddress development address
     * @dev only owner can set develometn address
     **/
    function setDevelopmentAddress(
        address _developmentAddress
    ) external onlyOwner {
        require(
            _developmentAddress != address(0),
            "Staking: development should not be the zero"
        );

        DEVELOPMENT_ADDRESS = _developmentAddress;

        emit SetDevelopmentAddress(DEVELOPMENT_ADDRESS);
    }

    /**
     * @param LOP_ ERC20 _LOP address
     * @dev only owner can set _LOP address
     **/
    function setLOP(address LOP_) external onlyOwner {
        require(
            LOP_ != address(0),
            "Staking: LOP address hould not be the zero address"
        );

        _LOP = LOP_;

        emit SetLOP(_LOP);
    }

    /**
     * @param vLOP_ ERC20 _vLOP address
     * @dev only owner can set _vLOP address
     **/
    function setVLOP(address vLOP_) external onlyOwner {
        require(
            vLOP_ != address(0),
            "Staking: vLOP address hould not be the zero address"
        );

        _vLOP = vLOP_;

        emit SetLOP(_vLOP);
    }

    /**
     * @param minVotePercent_ min vote percent
     * @dev only owner can set minVotePercent
     **/
    function setMinVotePercent(uint256 minVotePercent_) external onlyOwner {
        require(
            minVotePercent_ > 0,
            "Staking: min vote should be greater than the zero"
        );

        _minVotePercent = minVotePercent_;

        emit MinVoteUpdated(_minVotePercent);
    }

    /**
     * @param _propsalExpiredDate max shareholder voting count
     **/
    function setProposalExpriedDate(
        uint256 _propsalExpiredDate
    ) external onlyOwner {
        require(
            _propsalExpiredDate > 0,
            "Staking: proposal expired should be greater than the zero"
        );

        _PROPOSAL_EXPIRED_DATE = _propsalExpiredDate;

        emit SetProposalExpiredDate(_propsalExpiredDate);
    }

    /**
     * @param _maxShareHolderVotingCount max shareholder voting count
     * @dev only owner can set max share holder voting count
     **/
    function setMaxShareHolderVotingCount(
        uint256 _maxShareHolderVotingCount
    ) external onlyOwner {
        require(
            _maxShareHolderVotingCount > 0,
            "Staking: max share holder voting count should be greater than the zero"
        );

        _MAX_SHARE_HOLDER_VOTING_COUNT = _maxShareHolderVotingCount;

        emit SetMaxShareHolderVotingCount(_MAX_SHARE_HOLDER_VOTING_COUNT);
    }

    /**
     * @param _maxProductVotingCount max product voting count
     * @dev only owner can set max product voting count
     **/
    function setMaxProductVotingCount(
        uint256 _maxProductVotingCount
    ) external onlyOwner {
        require(
            _maxProductVotingCount > 0,
            "Staking: max product voting count should be greater than the zero"
        );

        _MAX_PRODUCT_VOTING_COUNT = _maxProductVotingCount;

        emit SetMaxProductVotingCount(_MAX_PRODUCT_VOTING_COUNT);
    }

    /**
     * @param _maxDevelopmentVotingCount max development voting count
     * @dev only owner can set max development voting count
     **/
    function setMaxDevelopmentVotingCount(
        uint256 _maxDevelopmentVotingCount
    ) external onlyOwner {
        require(
            _maxDevelopmentVotingCount > 0,
            "Staking: max development voting count should be greater than the zero"
        );

        _MAX_DEVELOPMENT_VOTING_COUNT = _maxDevelopmentVotingCount;

        emit SetMaxDevelopmentVotingCount(_MAX_DEVELOPMENT_VOTING_COUNT);
    }

    /**
     * @param staker staker address
     * @dev get stake amount for LOP and vLOP
     **/
    function getStakeAmount(address staker) external view returns (uint256) {
        return _stakingList[staker].lopAmount + _stakingList[staker].vLopAmount;
    }

    function getLOP() external view returns (address) {
        return _LOP;
    }

    function getVLOP() external view returns (address) {
        return _vLOP;
    }

    function getMinVotePercent() external view returns (uint256) {
        return _minVotePercent;
    }

    function getStakingInfo(
        address staker
    ) external view returns (Types.StakeInfo memory) {
        return _stakingList[staker];
    }

    function MAX_SHARE_HOLDER_VOTING_COUNT() external view returns (uint256) {
        return _MAX_SHARE_HOLDER_VOTING_COUNT;
    }

    function MAX_PRODUCT_VOTING_COUNT() external view returns (uint256) {
        return _MAX_PRODUCT_VOTING_COUNT;
    }

    function MAX_DEVELOPMENT_VOTING_COUNT() external view returns (uint256) {
        return _MAX_DEVELOPMENT_VOTING_COUNT;
    }

    function getProposalExpiredDate() external view returns (uint256) {
        return _PROPOSAL_EXPIRED_DATE;
    }

    function _evaluateShareHolderDao(address _staker) internal {
        Types.StakeInfo memory _stakingInfo = _stakingList[_staker];

        for (uint256 i = 0; i < _stakingInfo.shareHolderVotingIds.length; i++) {
            IShareHolderDao(SHARE_HOLDER_ADDRESS).evaluateVoteAmount(
                _staker,
                _stakingInfo.shareHolderVotingIds[i]
            );
        }

        for (uint256 i = 0; i < _stakingInfo.productVotingIds.length; i++) {
            IProductDao(PRODUCT_ADDRESS).evaluateVoteAmount(
                _staker,
                _stakingInfo.productVotingIds[i]
            );
        }

        for (uint256 i = 0; i < _stakingInfo.developmentVotingIds.length; i++) {
            IDevelopmentDao(DEVELOPMENT_ADDRESS).evaluateVoteAmount(
                _staker,
                _stakingInfo.developmentVotingIds[i]
            );
        }

        for (
            uint256 i = 0;
            i < _stakingInfo.developmentEscrowVotingIds.length;
            i++
        ) {
            IDevelopmentDao(DEVELOPMENT_ADDRESS).evaluateEscrowVoteAmount(
                _staker,
                _stakingInfo.developmentEscrowVotingIds[i]
            );
        }
    }
}