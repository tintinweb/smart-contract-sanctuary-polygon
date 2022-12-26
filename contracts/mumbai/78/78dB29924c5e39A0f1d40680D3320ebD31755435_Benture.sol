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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBenture.sol";
import "./interfaces/IBentureProducedToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Dividends distributing contract
contract Benture is IBenture, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /// @dev The contract must be able to receive ether to pay dividends with it
    receive() external payable {}

    /// @dev Stores information about a specific dividends distribution
    struct Distribution {
        uint256 id;
        address origToken;
        address distToken;
        uint256 amount;
        uint256 dueDate;
        bool isEqual;
        DistStatus status;
    }

    /// @dev Incrementing IDs of distributions
    Counters.Counter internal distributionIds;
    /// @dev Mapping from distribution ID to the address of the admin
    ///      who announced the distribution
    mapping(uint256 => address) internal distributionsToAdmins;
    /// @dev Mapping from admin address to the list of IDs of active distributions he announced
    mapping(address => uint256[]) internal adminsToDistributions;
    /// @dev An array of all distributions
    /// @dev NOTE: Each of them can have any status of 3 available
    Distribution[] internal distributions;
    /// @dev Mapping from distribution ID to its index inside the `distributions` array
    mapping(uint256 => uint256) internal idsToIndexes;

    /// @notice Allows admin to annouce the next distribution of dividends
    /// @param origToken The tokens to the holders of which the dividends will be paid
    /// @param distToken The token that will be paid
    /// @param amount The amount of tokens that will be paid
    /// @param dueDate The number of seconds in which the dividends will be paid
    ///        *after the announcement*
    ///         Use `0` to announce an immediate distribution
    /// @param isEqual Indicates whether distribution will be equal
    /// @dev Announcement does not guarantee that dividends will be distributed. It just shows
    ///      that the admin is willing to do that
    function announceDividends(
        address origToken,
        address distToken,
        uint256 amount,
        uint256 dueDate,
        bool isEqual
    ) external {
        require(
            origToken != address(0),
            "Benture: original token can not have a zero address!"
        );
        // Check that amount is not zero
        require(amount > 0, "Benture: dividends amount can not be zero!");
        // Check that caller is an admin of `origToken`
        IBentureProducedToken(origToken).checkAdmin(msg.sender);
        distributionIds.increment();
        // NOTE The lowest distribution ID is 1
        uint256 distributionId = distributionIds.current();
        // Mark that this admin announced a distribution with the new ID
        distributionsToAdmins[distributionId] = msg.sender;
        // Add this distribution's ID to the list of all distributions he announced
        adminsToDistributions[msg.sender].push(distributionId);
        // Create a new distribution
        Distribution memory distribution = Distribution({
            id: distributionId,
            origToken: origToken,
            distToken: distToken,
            amount: amount,
            dueDate: dueDate,
            isEqual: isEqual,
            // Set a `pending` status for each new distribution
            status: DistStatus.pending
        });
        // Add this distribution to the list of all distributions of all admins
        distributions.push(distribution);
        // Get the index of the added distribution
        uint256 lastIndex = distributions.length - 1;
        // Mark that a new distribution has this index in the global array
        idsToIndexes[distributionId] = lastIndex;

        emit DividendsAnnounced(origToken, distToken, amount, dueDate, isEqual);
    }

    /// @notice Cancels previously announced distribution
    /// @param id The ID of the distribution to cancel
    function cancelDividends(uint256 id) external {
        // Check that distribution with the provided ID was announced previously
        require(
            distributionsToAdmins[id] != address(0),
            "Benture: distribution with the given ID has not been annouced yet!"
        );
        // Get the distribution with the provided id
        Distribution storage distribution = distributions[idsToIndexes[id]];
        // Check that caller is an admin of the origToken project
        IBentureProducedToken(distribution.origToken).checkAdmin(msg.sender);
        // All we need is to change distribution's status to `cancelled`
        distribution.status = DistStatus.cancelled;

        emit DividendsCancelled(id);
    }

    /// @notice Returns the list of IDs of all distributions the admin has ever announced
    /// @param admin The address of the admin
    /// @return The list of IDs of all distributions the admin has ever announced
    function getDistributions(
        address admin
    ) public view returns (uint256[] memory) {
        // Do not check wheter the given address is actually an admin
        require(
            admin != address(0),
            "Benture: admin can not have a zero address!"
        );
        return adminsToDistributions[admin];
    }

    /// @notice Returns the distribution with the given ID
    /// @param id The ID of the distribution to search for
    /// @return All information about the distribution
    function getDistribution(
        uint256 id
    )
        public
        view
        returns (uint256, address, address, uint256, uint256, bool, DistStatus)
    {
        require(id >= 1, "Benture: ID of distribution must be greater than 1!");
        require(
            distributionsToAdmins[id] != address(0),
            "Benture: distribution with the given ID has not been annouced yet!"
        );
        Distribution storage distribution = distributions[idsToIndexes[id]];
        return (
            distribution.id,
            distribution.origToken,
            distribution.distToken,
            distribution.amount,
            distribution.dueDate,
            distribution.isEqual,
            distribution.status
        );
    }

    /// @notice Checks if the distribution with the given ID was announced by the given admin
    /// @param id The ID of the distribution to check
    /// @param admin The address of the admin to check
    /// @return True if admin has announced the distribution with the given ID. Otherwise - false.
    function checkAnnounced(
        uint256 id,
        address admin
    ) public view returns (bool) {
        require(id >= 1, "Benture: ID of distribution must be greater than 1!");
        require(
            distributionsToAdmins[id] != address(0),
            "Benture: distribution with the given ID has not been annouced yet!"
        );
        require(
            admin != address(0),
            "Benture: admin can not have a zero address!"
        );
        if (distributionsToAdmins[id] == admin) {
            return true;
        }
        return false;
    }

    /// @notice Checks if distribution can be fulfilled
    /// @param id The ID of the distribution that is going to be fulfilled
    /// @param origToken The address of the token that is held by receivers;
    /// @param distToken The address of the token that is to be distributed as dividends
    /// @param amount The amount of distTokens to be distributed in total
    /// @param isEqual Indicates whether the distribution is equal or weighted
    function canFulfill(
        uint256 id,
        address origToken,
        address distToken,
        uint256 amount,
        bool isEqual
    ) internal view {
        Distribution storage distribution = distributions[idsToIndexes[id]];
        require(
            distribution.status == DistStatus.pending,
            "Benture: distribution is not pending!"
        );
        require(
            block.timestamp >= distribution.dueDate,
            "Benture: too early for distribution!"
        );
        require(
            distribution.origToken == origToken,
            "Benture: origToken is different!"
        );
        require(
            distribution.distToken == distToken,
            "Benture: distToken is different!"
        );
        require(distribution.amount == amount, "Benture: amount is different!");
        require(
            distribution.isEqual == isEqual,
            "Benture: another type of distribution!"
        );
    }

    /// @dev Makes sanitary checks before token distribution
    /// @param origToken The address of the token that is held by receivers;
    ///        Can not be a zero address!
    ///        MUST be an address of a contract - not an address of EOA!
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param id The ID of the distribution that is being fulfilled
    /// @param amount The amount of distTokens to be distributed in total
    /// @param isEqual Indicates whether the distribution is equal or not
    function preDistChecks(
        address origToken,
        address distToken,
        uint256 id,
        uint256 amount,
        bool isEqual
    ) internal view {
        require(
            origToken != address(0),
            "Benture: original token can not have a zero address!"
        );
        // Check that caller is an admin of `origToken`
        IBentureProducedToken(origToken).checkAdmin(msg.sender);
        // Check that distribution can be fulfilled
        canFulfill(id, origToken, distToken, amount, isEqual);
    }

    /// @dev Checks that `Benture` has enough tokens to distribute
    ///      the required amount
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param amount The amount of distTokens to be distributed in total
    function preDistTransfer(address distToken, uint256 amount) internal {
        if (distToken == address(0)) {
            // Check that enough native tokens were sent with the transaction
            require(
                msg.value >= amount,
                "Benture: not enough native dividend tokens were provided!"
            );
        } else {
            // Transfer the `amount` of tokens to the contract
            // NOTE This transfer should be approved by the owner of tokens before calling this function
            IERC20(distToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
    }

    /// @dev Returns tokens that were not distributed back to the admin
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param amount The amount of distTokens to be distributed in total
    /// @param startBalance The balance of the the `distToken` before distribution
    /// @param endBalance The balance of the the `distToken` after distribution
    function returnLeft(
        address distToken,
        uint256 amount,
        uint256 startBalance,
        uint256 endBalance
    ) internal {
        uint256 reallyDistributed = startBalance - endBalance;
        if (reallyDistributed != amount) {
            if (distToken != address(0)) {
                IERC20(distToken).safeTransfer(
                    msg.sender,
                    amount - reallyDistributed
                );
            } else {
                msg.sender.call{value: amount - reallyDistributed};
            }
        }
    }

    /// @dev Returns the current `distToken` address of this contract
    /// @param distToken The address of the token to get the balance in
    /// @return The `distToken` balance of this contract
    function getCurrentBalance(
        address distToken
    ) internal view returns (uint256) {
        uint256 balance;
        if (distToken != address(0)) {
            balance = IERC20(distToken).balanceOf(address(this));
        } else {
            balance = address(this).balance;
        }

        return balance;
    }

    /// @notice Distributes one token as dividends for holders of another token _equally _
    /// @param id The ID of the distribution that is being fulfilled
    /// @param origToken The address of the token that is held by receivers;
    ///        Can not be a zero address!
    ///        MUST be an address of a contract - not an address of EOA!
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param amount The amount of distTokens to be distributed in total
    ///        NOTE: This amount takes `decimals` into account. For example 4 USDT = 4 000 000 units
    function distributeDividendsEqual(
        uint256 id,
        address origToken,
        address distToken,
        uint256 amount
    ) external payable nonReentrant {
        // Do all necessary checks before distributing dividends
        preDistChecks(origToken, distToken, id, amount, true);
        // Transfer tokens to the `Benture` contract before distributing dividends
        preDistTransfer(distToken, amount);

        // The initial balance before distribution
        uint256 startBalance = getCurrentBalance(distToken);

        // Get all holders of the origToken
        address[] memory receivers = IBentureProducedToken(origToken).holders();
        uint256 length = receivers.length;
        uint256 parts = length;
        require(length > 0, "Benture: no dividends receivers were found!");
        // It is impossible to distribute dividends if the amount is less then the number of receivers
        // (mostly used for ERC20 tokens)
        require(
            amount >= length,
            "Benture: too many receivers for the provided amount!"
        );
        // If one of the receivers is the `Benture` contract itself - do not distribute dividends to it
        // Reduce the number of receivers as well to calculate dividends correctly
        if (IBentureProducedToken(origToken).isHolder(address(this))) {
            parts -= 1;
        }
        // Distribute dividends to each of the holders
        for (uint256 i = 0; i < length; i++) {
            // No dividends should be distributed to a zero address
            require(
                receivers[i] != address(0),
                "Benture: no dividends for a zero address allowed!"
            );
            // If `Benture` contract is a receiver, just ignore it and move to the next one
            if (receivers[i] != address(this)) {
                if (distToken == address(0)) {
                    // Native tokens (wei)
                    (bool transferred, ) = receivers[i].call{
                        value: amount / parts
                    }("");
                    require(transferred, "Benture: dividends transfer failed!");
                } else {
                    // ERC20 tokens
                    IERC20(distToken).safeTransfer(
                        receivers[i],
                        amount / parts
                    );
                }
            }
        }

        // The balance after the distribution
        uint256 endBalance = getCurrentBalance(distToken);

        // Change distribution status to `fulfilled`
        Distribution storage distribution = distributions[idsToIndexes[id]];
        distribution.status = DistStatus.fulfilled;

        emit DividendsFulfilled(id);
        emit DividendsDistributed(distToken, startBalance - endBalance);

        // All distTokens that were for some reason not distributed are returned
        // to the admin
        returnLeft(distToken, amount, startBalance, endBalance);
    }

    /// @notice Distributes one token as dividends for holders of another token _according to each user's balance_
    /// @param id The ID of the distribution that is being fulfilled
    /// @param origToken The address of the token that is held by receivers
    ///        Can not be a zero address!
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param amount The amount of distTokens to be distributed in total
    ///        NOTE: This amount takes `decimals` into account. For example 4 USDT = 4 000 000 units
    function distributeDividendsWeighted(
        uint256 id,
        address origToken,
        address distToken,
        uint256 amount
    ) external payable nonReentrant {
        // Do all necessary checks before distributing dividends
        preDistChecks(origToken, distToken, id, amount, false);
        // Transfer tokens to the `Benture` contract before distributing dividends
        preDistTransfer(distToken, amount);

        // The initial balance before distribution
        uint256 startBalance = getCurrentBalance(distToken);

        // Get all holders of the origToken
        address[] memory receivers = IBentureProducedToken(origToken).holders();
        uint256 length = receivers.length;
        require(length > 0, "Benture: no dividends receivers were found!");

        // NOTE formula [A] of amount of distTokens each user receives:
        // `tokensToReceive = userBalance * amount / totalBalance`
        // Where `amount / totalBalance = weight` but it's *not* calculated in a separate operation
        // in order to avoid zero result, e.g:
        // 1) `weight = 5 / 100 = 0`
        // 2) `tokensToReceive = 240 * 0 = 0`
        // But `tokensToReceive = 240 * 5 / 100 = 1200 / 100 = 12` <- different result

        // NOTE this inequation [B] should meet for *each* user in order for them to get minimum
        // possible dividends (1 wei+):
        // userBalance * amount * 10 ^ (distToken decimals) / totalBalance >= 1
        // Otherwise, the user will get 0 dividends

        // If `amount` is less than `length` then none of the users will receive any dividends
        // NOTE Only users with balance >= `totalBalance / amount` will receive their dividends
        require(
            amount >= length,
            "Benture: amount should be greater than the number of dividends receivers!"
        );
        // Get total holders` balance of origTokens
        uint256 totalBalance = _getTotalBalance(receivers, origToken);
        // Distribute dividends to each of the holders
        for (uint256 i = 0; i < length; i++) {
            // No dividends should be distributed to a zero address
            require(
                receivers[i] != address(0),
                "Benture: no dividends for a zero address allowed!"
            );
            // If `Benture` contract is a receiver, just ignore it and move to the next one
            if (receivers[i] != address(this)) {
                uint256 userBalance = IERC20(origToken).balanceOf(receivers[i]);
                // Native tokens
                if (distToken == address(0)) {
                    (bool success, ) = receivers[i].call{ // Some of the holders might receive no dividends // Formulas [A] and [B] can be used here
                        value: (userBalance * amount) / totalBalance
                    }("");
                    require(success, "Benture: dividends transfer failed!");
                    // Other ERC20 tokens
                } else {
                    IERC20(distToken).safeTransfer(
                        receivers[i],
                        // Formulas [A] and [B] can be used here
                        // Some of the holders might receive no dividends
                        (userBalance * amount) / totalBalance
                    );
                }
            }
        }

        // The balance after the distribution
        uint256 endBalance = getCurrentBalance(distToken);

        // Change distribution status to `fulfilled`
        Distribution storage distribution = distributions[idsToIndexes[id]];
        distribution.status = DistStatus.fulfilled;

        emit DividendsFulfilled(id);
        emit DividendsDistributed(distToken, startBalance - endBalance);

        // All distTokens that were for some reason not distributed are returned
        // to the admin
        returnLeft(distToken, amount, startBalance, endBalance);
    }

    /// @notice Returns the total users` balance of the given token
    /// @param users The list of users to calculate the total balance of
    /// @param token The token which balance must be calculated
    /// @return The total users' balance of the given token
    function _getTotalBalance(
        address[] memory users,
        address token
    ) internal view returns (uint256) {
        uint256 totalBalance;
        for (uint256 i = 0; i < users.length; i++) {
            // If this contract is holder - ignore its balance
            // It should not affect amount of tokens distributed to real holders
            if (users[i] != address(this)) {
                uint256 singleBalance = IERC20(token).balanceOf(users[i]);
                totalBalance += singleBalance;
            }
        }
        return totalBalance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Dividend-Paying Token Interface

/// @dev An interface for dividends distributing contract
interface IBenture {
    /// @dev Status of a distribution
    enum DistStatus {
        pending,
        cancelled,
        fulfilled
    }

    /// @notice Allows admin to annouce the next distribution of dividends
    /// @param origToken The tokens to the holders of which the dividends will be paid
    /// @param distToken The token that will be paid
    /// @param amount The amount of tokens that will be paid
    /// @param dueDate The number of seconds in which the dividends will be paid
    ///        *after the announcement*
    /// @param isEqual Indicates whether distribution will be equal
    /// @dev Announcement does not guarantee that dividends will be distributed. It just shows
    ///      that the admin is willing to do that
    function announceDividends(
        address origToken,
        address distToken,
        uint256 amount,
        uint256 dueDate,
        bool isEqual
    ) external;

    /// @notice Cancels previously announced distribution
    /// @param id The ID of the distribution to cancel
    function cancelDividends(uint256 id) external;

    /// @notice Returns the list of IDs of all active distributions the admin has announced
    /// @param admin The address of the admin
    /// @return The list of IDs of all active distributions the admin has announced
    function getDistributions(
        address admin
    ) external view returns (uint256[] memory);

    /// @notice Returns the distribution with the given ID
    /// @param id The ID of the distribution to search for
    /// @return All information about the distribution
    function getDistribution(
        uint256 id
    )
        external
        view
        returns (uint256, address, address, uint256, uint256, bool, DistStatus);

    /// @notice Checks if the distribution with the given ID was announced by the given admin
    /// @param id The ID of the distribution to check
    /// @param admin The address of the admin to check
    /// @return True if admin has announced the distribution with the given ID. Otherwise - false.
    function checkAnnounced(
        uint256 id,
        address admin
    ) external view returns (bool);

    /// @notice Distributes one token as dividends for holders of another token _equally _
    /// @param id The ID of the distribution that is being fulfilled
    /// @param origToken The address of the token that is held by receivers
    ///        Can not be a zero address!
    ///        MUST be an address of a contract - not an address of EOA!
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param amount The amount of distTokens to be distributed in total
    ///        NOTE: If dividends are to payed in ether then `amount` is the amount of wei (NOT ether!)
    function distributeDividendsEqual(
        uint256 id,
        address origToken,
        address distToken,
        uint256 amount
    ) external payable;

    /// @notice Distributes one token as dividends for holders of another token _according to each user's balance_
    /// @param id The ID of the distribution that is being fulfilled
    /// @param origToken The address of the token that is held by receivers
    ///        Can not be a zero address!
    /// @param distToken The address of the token that is to be distributed as dividends
    ///        Zero address for native token (ether, wei)
    /// @param weight The amount of origTokens required to get a single distToken
    ///        NOTE: If dividends are payed in ether then `weight` is the amount of origTokens required to get a single ether (NOT a single wei!)
    function distributeDividendsWeighted(
        uint256 id,
        address origToken,
        address distToken,
        uint256 weight
    ) external payable;

    /// @dev Indicates that dividends were distributed
    /// @param distToken The address of dividend token that gets distributed
    /// @param amount The amount of distTokens to be distributed in total
    event DividendsDistributed(
        address indexed distToken,
        uint256 indexed amount
    );

    /// @dev Indicates that new dividends distribution was announced
    /// @param origToken The tokens to the holders of which the dividends will be paid
    /// @param distToken The token that will be paid
    /// @param amount The amount of tokens that will be paid
    /// @param dueDate The number of seconds in which the dividends will be paid
    ///        *after the announcement*
    /// @param isEqual Indicates whether distribution will be equal
    event DividendsAnnounced(
        address indexed origToken,
        address indexed distToken,
        uint256 indexed amount,
        uint256 dueDate,
        bool isEqual
    );

    /// @dev Indicates that dividends distribution was fulfilled
    /// @param id The ID of the fulfilled distribution
    event DividendsFulfilled(uint256 indexed id);

    /// @dev Indicates that dividends distribution was cancelled
    /// @param id The ID of the cancelled distribution
    event DividendsCancelled(uint256 indexed id);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title An interface for a custom ERC20 contract used in the bridge
interface IBentureProducedToken is IERC20 {
    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() external view returns (string memory);

    /// @notice Returns number of decimals of the token
    /// @return The number of decimals of the token
    function decimals() external view returns (uint8);

    /// @notice Indicates whether the token is mintable or not
    /// @return True if the token is mintable. False - if it is not
    function mintable() external view returns (bool);

    /// @notice Returns the array of addresses of all token holders
    /// @return The array of addresses of all token holders
    function holders() external view returns (address[] memory);

    /// @notice Returns the max total supply of the token
    /// @return The max total supply of the token
    function maxTotalSupply() external view returns (uint256);

    /// @notice Checks if the address is a holder
    /// @param account The address to check
    /// @return True if address is a holder. False if it is not
    function isHolder(address account) external view returns (bool);

    /// @notice Checks if user is an admin of this token
    /// @param account The address to check
    function checkAdmin(address account) external view;

    /// @notice Creates tokens and assigns them to account, increasing the total supply.
    /// @param to The receiver of tokens
    /// @param amount The amount of tokens to mint
    /// @dev Can only be called by the owner of the admin NFT
    /// @dev Can only be called when token is mintable
    function mint(address to, uint256 amount) external;

    /// @notice Burns user's tokens
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) external;

    /// @notice Indicates that a new ERC20 was created
    event ControlledTokenCreated(address indexed account, uint256 amount);

    /// @notice Indicates that a new ERC20 was burnt
    event ControlledTokenBurnt(address indexed account, uint256 amount);

    /// @notice Indicates that a new ERC20 was transferred
    event ControlledTokenTransferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );
}