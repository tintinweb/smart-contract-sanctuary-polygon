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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity ^0.8.4;

import "./interfaces/across.sol";
import "../../errors/SocketErrors.sol";
import "../BridgeImplBase.sol";
import {ValueShouldBeZero, ValueNotEqualToAmount} from "../../errors/SocketErrors.sol";

/**
 * // @title Across  Implementation.
 * // @author Socket dot tech.
 */
contract AcrossImplV2 is BridgeImplBase {
    using SafeERC20 for IERC20;
    // ethereum

    //SpokePool public immutable spokePool = SpokePool(0x4D9079Bb4165aeb4084c526a32695dCfd2F77381);
    SpokePool public immutable spokePool;
    address public immutable WETH;

    constructor(address _spokePool, address _wethAddress, address _socketGateway) BridgeImplBase(_socketGateway) {
        spokePool = SpokePool(_spokePool);
        WETH = _wethAddress;
    }

    /**
     * // @notice Function responsible for cross chain transfer from l2 to l1 or supported
     * // l2s.
     * // Called by the registry when the selected bridge is Hop bridge.
     * // @dev Try to check for the liquidity on the other side before calling this.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiver address
     * // @param _token address of the token to bridged to the destination chain.
     * // @param _toChainId chainId of destination
     * // boderfee, amount out min and deadline.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        (uint64 _relayerFeePct, uint32 _quoteTimestamp) = abi.decode(_data, (uint64, uint32));

        // token address might not be indication thats why passed through extraData
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _toChainId, _value, _relayerFeePct, _quoteTimestamp);
            return (_token, _amount);
        }
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _relayerFeePct, _quoteTimestamp);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        (uint64 _relayerFeePct, uint32 _quoteTimestamp) = abi.decode(_data, (uint64, uint32));

        // token address might not be indication thats why passed through extraData
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _relayerFeePct, _quoteTimestamp);
        return (_token, _amount);
    }

    function _bridgeNative(
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        uint256 _value,
        uint64 _relayerFeePct,
        uint32 _quoteTimestamp
    )
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }
        spokePool.deposit{value: _amount}(_receiverAddress, WETH, _amount, _toChainId, _relayerFeePct, _quoteTimestamp);
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        uint64 _relayerFeePct,
        uint32 _quoteTimestamp
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(spokePool), _amount);
        spokePool.deposit(_receiverAddress, _token, _amount, _toChainId, _relayerFeePct, _quoteTimestamp);
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        uint64 _relayerFeePct,
        uint32 _quoteTimestamp
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeIncreaseAllowance(address(spokePool), _amount);
        spokePool.deposit(_receiverAddress, _token, _amount, _toChainId, _relayerFeePct, _quoteTimestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface SpokePool {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    )
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../BridgeImplBase.sol";
import {TokenNotSupported, ValueShouldBeZero} from "../../../errors/SocketErrors.sol";

/**
 * @title Anyswap L1 Implementation.
 * @notice This is the L1 implementation, so this is used when transferring from
 * l1 to supported l1s or L1.
 * Called by the registry if the selected bridge is Anyswap bridge.
 * @dev Follows the interface of ImplBase.
 * @author Movr Network.
 */
interface AnyswapV3Router {
    function anySwapOutUnderlying(address token, address to, uint256 amount, uint256 toChainID) external;
}

contract AnyswapImplL1 is BridgeImplBase {
    using SafeERC20 for IERC20;

    //AnyswapV3Router public constant router = AnyswapV3Router(0x6b7a87899490EcE95443e979cA9485CBE7E71522);
    AnyswapV3Router public immutable router;

    /**
     * @notice Constructor sets the router address and registry address.
     * @dev anyswap v3 address is constant. so no setter function required.
     */
    constructor(address _router, address _socketGateway) BridgeImplBase(_socketGateway) {
        router = AnyswapV3Router(_router);
    }

    /**
     * @notice function responsible for calling cross chain transfer using anyswap bridge.
     * @dev the token to be passed on to anyswap function is supposed to be the wrapper token
     * address.
     * @param _amount amount to be sent.
     * @param _receiverAddress receivers address.
     * @param _token this is the main token address on the source chain.
     * @param _toChainId destination chain Id
     * @param _data data contains the wrapper token address for the token
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes memory _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        address _wrapperTokenAddress = abi.decode(_data, (address));
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _wrapperTokenAddress);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes memory _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        address _wrapperTokenAddress = abi.decode(_data, (address));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _wrapperTokenAddress);
        return (_token, _amount);
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        address _wrapperTokenAddress
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);

        router.anySwapOutUnderlying(_wrapperTokenAddress, _receiverAddress, _amount, _toChainId);
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        address _wrapperTokenAddress
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        router.anySwapOutUnderlying(_wrapperTokenAddress, _receiverAddress, _amount, _toChainId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../BridgeImplBase.sol";
import {ValueShouldBeZero, TokenNotSupported} from "../../../errors/SocketErrors.sol";

/**
 * @title Anyswap L1 Implementation.
 * @notice This is the L1 implementation, so this is used when transferring from
 * l1 to supported l1s or L1.
 * Called by the registry if the selected bridge is Anyswap bridge.
 * @dev Follows the interface of ImplBase.
 * @author Movr Network.
 */
interface AnyswapV3Router {
    function anySwapOutUnderlying(address token, address to, uint256 amount, uint256 toChainID) external;
}

contract AnyswapL2Impl is BridgeImplBase {
    using SafeERC20 for IERC20;

    // polygon router multichain router v4
    //AnyswapV3Router public immutable router = AnyswapV3Router(0x4f3Aff3A747fCADe12598081e80c6605A8be192F);
    AnyswapV3Router public immutable router;

    constructor(address _router, address _socketGateway) BridgeImplBase(_socketGateway) {
        router = AnyswapV3Router(_router);
    }

    /**
     * @notice function responsible for calling cross chain transfer using refuel bridge.
     * @param _receiverAddress receivers address.
     * @param _toChainId destination chain Id
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        address _wrapperTokenAddress = abi.decode(_data, (address));
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _wrapperTokenAddress);

        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        address _wrapperTokenAddress = abi.decode(_data, (address));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _wrapperTokenAddress);
        return (_token, _amount);
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        address _wrapperTokenAddress
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);

        router.anySwapOutUnderlying(_wrapperTokenAddress, _receiverAddress, _amount, _toChainId);
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        address _wrapperTokenAddress
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        router.anySwapOutUnderlying(_wrapperTokenAddress, _receiverAddress, _amount, _toChainId);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.8.0;

interface L1GatewayRouter {
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    )
        external
        payable
        returns (bytes calldata);
}

interface Inbox {
    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../BridgeImplBase.sol";
import "../interfaces/arbitrum.sol";
import {ValueShouldNotBeZero, ValueShouldBeZero} from "../../../errors/SocketErrors.sol";

/**
 * // @title Native Arbitrum Bridge Implementation.
 * // @notice This is the L1 implementation,
 * //          so this is used when transferring from ethereum to arbitrum via their native bridge.
 * // Called by the registry if the selected bridge is Native Arbitrum.
 * // @dev Follows the interface of ImplBase. This is only used for depositing tokens.
 * // @author Movr Network.
 */
contract NativeArbitrumImpl is BridgeImplBase {
    using SafeERC20 for IERC20;

    //address public constant ROUTER = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
    address public immutable router;

    /// @notice registry and L1 gateway router address required.
    constructor(address _router, address _socketGateway) BridgeImplBase(_socketGateway) {
        router = _router;
    }

    struct NativeArbitrumData {
        address gatewayAddress;
        uint256 maxGas;
        uint256 gasPriceBid;
        bytes data;
    }

    /**
     * // @notice function responsible for the native arbitrum deposits from ethereum.
     * // @dev gateway address is the address where the first deposit is made.
     * //      It holds max submission price and further data.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receivers address
     * // @param _token token address on the source chain that is L1.
     * // param _toChainId not required, follows the impl base.
     * // @param _extraData extradata required for calling the l1 router function. Explain above.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256, // _toChainId
        uint256 _value,
        bytes memory _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        NativeArbitrumData memory nativeArbitrumData = abi.decode(_extraData, (NativeArbitrumData));
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _value, nativeArbitrumData);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256, // _toChainId
        uint256 _value,
        bytes memory _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        NativeArbitrumData memory nativeArbitrumData = abi.decode(_extraData, (NativeArbitrumData));

        // @notice here we dont provide a 0 value check
        // since arbitrum may need native token as well along
        // with ERC20
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _value, nativeArbitrumData);
        return (_token, _amount);
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        NativeArbitrumData memory nativeArbitrumData
    )
        internal
    {
        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(nativeArbitrumData.gatewayAddress, _amount);

        L1GatewayRouter(router).outboundTransfer{value: _value}(
            _token,
            _receiverAddress,
            _amount,
            nativeArbitrumData.maxGas,
            nativeArbitrumData.gasPriceBid,
            nativeArbitrumData.data
        );
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        NativeArbitrumData memory nativeArbitrumData
    )
        internal
    {
        IERC20(_token).safeIncreaseAllowance(nativeArbitrumData.gatewayAddress, _amount);

        L1GatewayRouter(router).outboundTransfer{value: _value}(
            _token,
            _receiverAddress,
            _amount,
            nativeArbitrumData.maxGas,
            nativeArbitrumData.gasPriceBid,
            nativeArbitrumData.data
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Pb.sol";
import {RouteAlreadyInitialised} from "../errors/SocketErrors.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Bridge Implementation will follow this interface.
 */
abstract contract BridgeImplBase {
    using SafeERC20 for IERC20;

    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public immutable socketGateway;

    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    function rescueFunds(address token, address userAddress, uint256 amount) external isSocketGatewayOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 value,
        bytes calldata _data
    )
        external
        payable
        virtual
        returns (address token, uint256 bridgedAmount);

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 value,
        bytes calldata _data
    )
        external
        payable
        virtual
        returns (address token, uint256 bridgedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../BridgeImplBase.sol";
import "./interfaces/cbridge.sol";
import "./interfaces/ICelerStorageWrapper.sol";
import {
    InvalidRouterAddress,
    InvalidWethAddress,
    ValueNotEqualToAmount,
    ValueShouldBeZero,
    TransferIdExists,
    InvalidCelerRefund,
    CelerAlreadyRefunded
} from "../../errors/SocketErrors.sol";

/**
 * @title Celer L2 Implementation.
 * @notice This is the L2 implementation, so this is used when transferring from
 * l2 to supported l2s or L1.
 * Called by the registry if the selected bridge is Celer bridge.
 * @dev Follows the interface of BridgeImplBase.
 * @author Socket.
 */

contract CelerImpl is BridgeImplBase {
    using SafeERC20 for IERC20;
    using Pb for Pb.Buffer;

    ICBridge public immutable router;
    ICelerStorageWrapper public immutable celerStorageWrapper;

    address public immutable weth;

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    }

    constructor(address _routerAddress, address _weth, address _celerStorageWrapperAddress, address _socketGateway)
        BridgeImplBase(_socketGateway)
    {
        router = ICBridge(_routerAddress);
        celerStorageWrapper = ICelerStorageWrapper(_celerStorageWrapperAddress);
        weth = _weth;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /**
     * @notice function responsible for calling cross chain transfer using celer bridge.
     * @dev the token to be passed on to the celer bridge.
     * @param _amount amount to be sent.
     * @param _receiverAddress receivers address.
     * @param _token this is the main token address on the source chain.
     * @param _toChainId destination chain Id
     * @param _value value
     * @param _extraData data contains nonce and the maxSlippage.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        (uint64 nonce, uint32 maxSlippage) = abi.decode(_extraData, (uint64, uint32));
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _toChainId, _value, nonce, maxSlippage);
            return (_token, _amount);
        } else {
            _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, nonce, maxSlippage);
            return (_token, _amount);
        }
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        (uint64 nonce, uint32 maxSlippage) = abi.decode(_extraData, (uint64, uint32));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, nonce, maxSlippage);
        return (_token, _amount);
    }

    function _bridgeNative(
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        uint256 _value,
        uint64 _nonce,
        uint32 _maxSlippage
    )
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), _receiverAddress, weth, _amount, uint64(_toChainId), _nonce, uint64(block.chainid))
        );

        address transferIdAddress = celerStorageWrapper.getAddressFromTransferId(transferId);

        if (transferIdAddress != address(0)) {
            revert TransferIdExists();
        }

        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        router.sendNative{value: _amount}(_receiverAddress, _amount, uint64(_toChainId), _nonce, _maxSlippage);
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        uint64 _nonce,
        uint32 _maxSlippage
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), _receiverAddress, _token, _amount, uint64(_toChainId), _nonce, uint64(block.chainid))
        );

        address transferIdAddress = celerStorageWrapper.getAddressFromTransferId(transferId);

        if (transferIdAddress != address(0)) {
            revert TransferIdExists();
        }

        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
        router.send(_receiverAddress, _token, _amount, uint64(_toChainId), _nonce, _maxSlippage);
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        uint64 _nonce,
        uint32 _maxSlippage
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), _receiverAddress, _token, _amount, uint64(_toChainId), _nonce, uint64(block.chainid))
        );

        address transferIdAddress = celerStorageWrapper.getAddressFromTransferId(transferId);

        if (transferIdAddress != address(0)) {
            revert TransferIdExists();
        }

        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
        router.send(_receiverAddress, _token, _amount, uint64(_toChainId), _nonce, _maxSlippage);
    }

    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    )
        external
        payable
    {
        WithdrawMsg memory request = decWithdrawMsg(_request);
        bytes32 transferId =
            keccak256(abi.encodePacked(request.chainid, request.seqnum, request.receiver, request.token, request.amount));
        uint256 _initialBalanceTokenOut = socketGateway.balance;
        if (!router.withdraws(transferId)) {
            router.withdraw(_request, _sigs, _signers, _powers);
        }

        if (request.receiver != socketGateway) {
            revert InvalidCelerRefund();
        }

        address _receiver = celerStorageWrapper.getAddressFromTransferId(request.refid);
        celerStorageWrapper.deleteTransferId(request.refid);

        if (_receiver == address(0)) {
            revert CelerAlreadyRefunded();
        }

        if (socketGateway.balance > _initialBalanceTokenOut) {
            payable(_receiver).transfer(request.amount);
        } else {
            IERC20(request.token).safeTransfer(_receiver, request.amount);
        }
    }

    function decWithdrawMsg(bytes memory raw) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {OnlySocketGateway, TransferIdDoesnotExist} from "../../errors/SocketErrors.sol";

contract CelerStorageWrapper {
    address public immutable socketGateway;
    mapping(bytes32 => address) private transferIdMapping;

    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    modifier onlySocketGateway() {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        _;
    }

    function setAddressForTransferId(bytes32 transferId, address transferIdAddress) external onlySocketGateway {
        transferIdMapping[transferId] = transferIdAddress;
    }

    function deleteTransferId(bytes32 transferId) external onlySocketGateway {
        if (transferIdMapping[transferId] == address(0)) {
            revert TransferIdDoesnotExist();
        }

        delete transferIdMapping[transferId];
    }

    function getAddressFromTransferId(bytes32 transferId) external view returns (address) {
        return transferIdMapping[transferId];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    )
        external;

    function sendNative(address _receiver, uint256 _amount, uint64 _dstChinId, uint64 _nonce, uint32 _maxSlippage)
        external
        payable;

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    )
        external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICelerStorageWrapper {
    function setAddressForTransferId(bytes32 transferId, address transferIdAddress) external;
    function deleteTransferId(bytes32 transferId) external;
    function getAddressFromTransferId(bytes32 transferId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title HopAMM
 * @notice responsible for calling the HOP L2 Impl functions.
 */
interface HopAMM {
    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) external view returns (uint256);

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline)
        external
        returns (uint256);

    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    )
        external
        payable;

    function getTokenIndex(address tokenAddress) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Not being used I think. Remove if unnecessary.
interface HopBridge {
    function send(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title L1Bridge Hop Interface
 * @notice L1 Hop Bridge, Used to transfer from L1 to L2s.
 */
interface IHopL1Bridge {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../BridgeImplBase.sol";
import {ValueNotEqualToAmount, ValueShouldBeZero} from "../../../errors/SocketErrors.sol";
import "../interfaces/IHopL1Bridge.sol";

/**
 * // @title Hop Protocol Implementation.
 * // @notice This is the L1 implementation, so this is used when transferring from l1 to supported l2s
 * //         Called by the registry if the selected bridge is HOP.
 * // @dev Follows the interface of ImplBase.
 * // @author Movr Network.
 */
contract HopImplL1 is BridgeImplBase {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line
    constructor(address _socketGateway) BridgeImplBase(_socketGateway) {}

    struct HopExtraData {
        address _l1bridgeAddr;
        address _relayer;
        uint256 _amountOutMin;
        uint256 _relayerFee;
        uint256 _deadline;
    }

    /**
     * // @notice Function responsible for cross chain transfers from L1 to L2.
     * // @dev When calling the registry the allowance should be given to this contract,
     * //      that is the implementation contract for HOP.
     * // @param _amount amount to be transferred to L2.
     * // @param _receiverAddress address that will receive the funds on the destination chain.
     * // @param _token address of the token to be used for cross chain transfer.
     * // @param _toChainId chain Id for the destination chain
     * // @param _extraData parameters required to call the hop function in bytes
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode extra data
        HopExtraData memory _hopExtraData = abi.decode(_extraData, (HopExtraData));
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _toChainId, _value, _hopExtraData);
            return (_token, _amount);
        }
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _hopExtraData);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode extra data
        HopExtraData memory _hopExtraData = abi.decode(_extraData, (HopExtraData));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _hopExtraData);
        return (_token, _amount);
    }

    function _bridgeNative(
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        uint256 _value,
        HopExtraData memory _hopExtraData
    )
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }

        IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2{value: _amount}(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._relayer,
            _hopExtraData._relayerFee
        );
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        HopExtraData memory _hopExtraData
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(_hopExtraData._l1bridgeAddr, _amount);

        // perform bridging
        IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._relayer,
            _hopExtraData._relayerFee
        );
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        HopExtraData memory _hopExtraData
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeIncreaseAllowance(_hopExtraData._l1bridgeAddr, _amount);

        // perform bridging
        IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._relayer,
            _hopExtraData._relayerFee
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/bridge.sol";
import "../interfaces/amm.sol";
import "../../../errors/SocketErrors.sol";
import "../../BridgeImplBase.sol";
import {ValueNotEqualToAmount, ValueShouldBeZero} from "../../../errors/SocketErrors.sol";

/**
 * // @title HOP L2 Implementation.
 * // @notice This is the L2 implementation, so this is used when transferring from l2
 * // to supported l2s or L1.
 * // Called by the registry if the selected bridge is Hop Bridge.
 * // @dev Follows the interface of ImplBase.
 * // @author Movr Network.
 */
contract HopImplL2 is BridgeImplBase {
    using SafeERC20 for IERC20;

    constructor(address _socketGateway) BridgeImplBase(_socketGateway) {}

    struct HopExtraData {
        address _hopAMM;
        uint256 _bonderFee; // fees passed to relayer
        uint256 _amountOutMin;
        uint256 _deadline;
        uint256 _amountOutMinDestination;
        uint256 _deadlineDestination;
    }

    /**
     * // @notice Function responsible for cross chain transfer from l2 to l1 or supported
     * // l2s.
     * // Called by the registry when the selected bridge is Hop bridge.
     * // @dev Try to check for the liquidity on the other side before calling this.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiver address
     * // @param _toChainId Destination Chain Id
     * // @param _token address of the token to bridged to the destination chain.
     * // @param _data data required to call the Hop swap and send function. hopAmm address,
     * // boderfee, amount out min and deadline.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode data
        HopExtraData memory _hopExtraData = abi.decode(_data, (HopExtraData));
        // token address might not be indication thats why passed through extraData
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _toChainId, _value, _hopExtraData);
            return (_token, _amount);
        }
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _hopExtraData);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode data
        HopExtraData memory _hopExtraData = abi.decode(_data, (HopExtraData));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value, _hopExtraData);
        return (_token, _amount);
    }

    function _bridgeNative(
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        uint256 _value,
        HopExtraData memory _hopExtraData
    )
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }

        // perform bridging
        HopAMM(_hopExtraData._hopAMM).swapAndSend{value: _amount}(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._bonderFee,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._amountOutMinDestination,
            _hopExtraData._deadlineDestination
        );
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        HopExtraData memory _hopExtraData
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(_hopExtraData._hopAMM, _amount);

        HopAMM(_hopExtraData._hopAMM).swapAndSend(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._bonderFee,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._amountOutMinDestination,
            _hopExtraData._deadlineDestination
        );
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        HopExtraData memory _hopExtraData
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeIncreaseAllowance(_hopExtraData._hopAMM, _amount);
        // perform bridging
        HopAMM(_hopExtraData._hopAMM).swapAndSend(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._bonderFee,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._amountOutMinDestination,
            _hopExtraData._deadlineDestination
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/hyphen.sol";
import "../../errors/SocketErrors.sol";
import "../BridgeImplBase.sol";
import {ValueNotEqualToAmount, ValueShouldBeZero} from "../../errors/SocketErrors.sol";

/**
 * // @title Hyphen  Implementation.
 * // @author Socket dot tech.
 */
contract HyphenImplV2 is BridgeImplBase {
    using SafeERC20 for IERC20;
    // ethereum
    // HyphenLiquidityPoolManager public immutable liquidityPoolManager =
    //     HyphenLiquidityPoolManager(0x2A5c2568b10A0E826BfA892Cf21BA7218310180b);

    HyphenLiquidityPoolManager public immutable liquidityPoolManager;

    string constant tag = "SOCKET";

    constructor(address _liquidityPoolManager, address _socketGateway) BridgeImplBase(_socketGateway) {
        liquidityPoolManager = HyphenLiquidityPoolManager(_liquidityPoolManager);
    }

    /**
     * // @notice Function responsible for cross chain transfer from l2 to l1 or supported
     * // l2s.
     * // Called by the registry when the selected bridge is Hop bridge.
     * // @dev Try to check for the liquidity on the other side before calling this.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiver address
     * // @param _token address of the token to bridged to the destination chain.
     * // @param _toChainId chainId of destination
     * // boderfee, amount out min and deadline.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // token address might not be indication thats why passed through extraData
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _toChainId, _value);
            return (_token, _amount);
        }
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _toChainId, _value);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value,
        bytes calldata
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _toChainId, _value);
        return (_token, _amount);
    }

    function _bridgeNative(uint256 _amount, address _receiverAddress, uint256 _toChainId, uint256 _value) internal {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }
        liquidityPoolManager.depositNative{value: _amount}(_receiverAddress, _toChainId, tag);
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(liquidityPoolManager), _amount);
        liquidityPoolManager.depositErc20(_toChainId, _token, _receiverAddress, _amount, tag);
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        uint256 _value
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeIncreaseAllowance(address(liquidityPoolManager), _amount);
        liquidityPoolManager.depositErc20(_toChainId, _token, _receiverAddress, _amount, tag);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface HyphenLiquidityPoolManager {
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    )
        external;

    function depositNative(address receiver, uint256 toChainId, string calldata tag) external payable;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface L1StandardBridge {
    function depositETHTo(address _to, uint32 _l2Gas, bytes calldata _data) external payable;

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external;
}

interface OldL1TokenGateway {
    function depositTo(address _to, uint256 _amount) external;

    function initiateSynthTransfer(bytes32 currencyKey, address destination, uint256 amount) external;
}

struct OptimismBridgeExtraData {
    address _l2Token;
    uint32 _l2Gas;
    bytes _data;
    address _customBridgeAddress;
    uint256 _interfaceId;
    bytes32 _currencyKey;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../BridgeImplBase.sol";
import "../interfaces/optimism.sol";
import {ValueNotEqualToAmount, ValueShouldBeZero, UnsupportedInterfaceId} from "../../../errors/SocketErrors.sol";

/**
 * // @title Native Optimism Bridge Implementation.
 * // @author Socket Technology.
 */
contract NativeOptimismImpl is BridgeImplBase {
    using SafeERC20 for IERC20;

    /**
     * // @notice We set all the required addresses in the constructor while deploying the contract.
     * // These will be constant addresses.
     * // @dev Please use the Proxy addresses and not the implementation addresses while setting these
     */
    constructor(address _socketGateway) BridgeImplBase(_socketGateway) {}

    /**
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiving address.
     * // @param _token address of the token to be bridged to optimism.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256, // _toChainId
        uint256 _value,
        bytes memory _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        OptimismBridgeExtraData memory _optimismBridgeExtraData = abi.decode(_extraData, (OptimismBridgeExtraData));
        if (_optimismBridgeExtraData._interfaceId == 0) {
            revert UnsupportedInterfaceId();
        }

        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _value, _optimismBridgeExtraData);
            return (_token, _amount);
        }
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _value, _optimismBridgeExtraData);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256, // _toChainId
        uint256 _value,
        bytes memory _extraData
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        OptimismBridgeExtraData memory _optimismBridgeExtraData = abi.decode(_extraData, (OptimismBridgeExtraData));
        if (_optimismBridgeExtraData._interfaceId == 0) {
            revert UnsupportedInterfaceId();
        }
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _value, _optimismBridgeExtraData);
        return (_token, _amount);
    }

    function _bridgeNative(
        uint256 _amount,
        address _receiverAddress,
        uint256 _value,
        OptimismBridgeExtraData memory _optimismBridgeExtraData
    )
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }

        L1StandardBridge(_optimismBridgeExtraData._customBridgeAddress).depositETHTo{value: _amount}(
            _receiverAddress, _optimismBridgeExtraData._l2Gas, _optimismBridgeExtraData._data
        );
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        OptimismBridgeExtraData memory _optimismBridgeExtraData
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(_optimismBridgeExtraData._customBridgeAddress, _amount);

        if (_optimismBridgeExtraData._interfaceId == 1) {
            // deposit into standard bridge
            _depositERC20To(
                _optimismBridgeExtraData._customBridgeAddress,
                _token,
                _optimismBridgeExtraData._l2Token,
                _optimismBridgeExtraData._l2Gas,
                _optimismBridgeExtraData._data,
                _receiverAddress,
                _amount
            );
            return;
        }

        // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
        if (_optimismBridgeExtraData._interfaceId == 2) {
            _depositTo(_optimismBridgeExtraData._customBridgeAddress, _receiverAddress, _amount);
            return;
        }

        if (_optimismBridgeExtraData._interfaceId == 3) {
            _initiateSynthTransfer(
                _optimismBridgeExtraData._customBridgeAddress,
                _optimismBridgeExtraData._currencyKey,
                _receiverAddress,
                _amount
            );
            return;
        }
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        OptimismBridgeExtraData memory _optimismBridgeExtraData
    )
        internal
    {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeIncreaseAllowance(_optimismBridgeExtraData._customBridgeAddress, _amount);

        if (_optimismBridgeExtraData._interfaceId == 1) {
            // deposit into standard bridge
            _depositERC20To(
                _optimismBridgeExtraData._customBridgeAddress,
                _token,
                _optimismBridgeExtraData._l2Token,
                _optimismBridgeExtraData._l2Gas,
                _optimismBridgeExtraData._data,
                _receiverAddress,
                _amount
            );
            return;
        }

        // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
        if (_optimismBridgeExtraData._interfaceId == 2) {
            _depositTo(_optimismBridgeExtraData._customBridgeAddress, _receiverAddress, _amount);
            return;
        }

        if (_optimismBridgeExtraData._interfaceId == 3) {
            _initiateSynthTransfer(
                _optimismBridgeExtraData._customBridgeAddress,
                _optimismBridgeExtraData._currencyKey,
                _receiverAddress,
                _amount
            );
            return;
        }
    }

    function _depositERC20To(
        address _customBridgeAddress,
        address _token,
        address _l2Token,
        uint32 _l2Gas,
        bytes memory _data,
        address _receiverAddress,
        uint256 _amount
    )
        internal
    {
        L1StandardBridge(_customBridgeAddress).depositERC20To(
            _token, _l2Token, _receiverAddress, _amount, _l2Gas, _data
        );
    }

    function _depositTo(address _customBridgeAddress, address _receiverAddress, uint256 _amount) internal {
        OldL1TokenGateway(_customBridgeAddress).depositTo(_receiverAddress, _amount);
    }

    function _initiateSynthTransfer(
        address _customBridgeAddress,
        bytes32 _currencyKey,
        address _receiverAddress,
        uint256 _amount
    )
        internal
    {
        OldL1TokenGateway(_customBridgeAddress).initiateSynthTransfer(_currencyKey, _receiverAddress, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title RootChain Manager Interface for Polygon Bridge.
 */
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(address sender, address token, bytes memory extraData) external;
}

/**
 * @title FxState Sender Interface if FxPortal Bridge is used.
 */
interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../BridgeImplBase.sol";
import {ValueNotEqualToAmount, ValueShouldBeZero, ValueShouldNotBeZero} from "../../errors/SocketErrors.sol";
import "./interfaces/polygon.sol";

/**
 * // @title Native Polygon Bridge Implementation.
 * // @notice This is the L1 implementation, so this is used when transferring
 * // from ethereum to polygon via their native bridge.
 * // Called by the registry if the selected bridge is Native Polygon.
 * // @dev Follows the interface of ImplBase. This is only used for depositing POS ERC20 tokens.
 * // @author Movr Network.
 */
contract NativePolygonImpl is BridgeImplBase {
    using SafeERC20 for IERC20;

    address public immutable rootChainManagerProxy;
    address public immutable erc20PredicateProxy;

    /**
     * // @notice We set all the required addresses in the constructor while deploying the contract.
     * // These will be constant addresses.
     * // @dev Please use the Proxy addresses and not the implementation addresses while setting these
     * // @param _rootChainManagerProxy address of the root chain manager proxy on the ethereum chain
     * // @param _erc20PredicateProxy address of the ERC20 Predicate proxy on the ethereum chain.
     * // @param _socketGateway address of the socketGateway contract that calls this contract
     */
    constructor(address _rootChainManagerProxy, address _erc20PredicateProxy, address _socketGateway)
        BridgeImplBase(_socketGateway)
    {
        rootChainManagerProxy = _rootChainManagerProxy;
        erc20PredicateProxy = _erc20PredicateProxy;
    }

    /**
     * // @notice Function responsible for depositing ERC20 tokens from ethereum to
     * // polygon chain using the POS bridge.
     * // @dev Please make sure that the token is mapped before sending it through the native bridge.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiving address.
     * // @param _token address of the token to be bridged to polygon.
     * // @param _value native value sent with the transaction
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256,
        uint256 _value,
        bytes memory
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _value);
            return (_token, _amount);
        }
        _bridgeExternalERC20(_amount, _receiverAddress, _token, _value);
        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256,
        uint256 _value,
        bytes memory
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _value);
        return (_token, _amount);
    }

    function _bridgeNative(uint256 _amount, address _receiverAddress, uint256 _value) internal {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }
        IRootChainManager(rootChainManagerProxy).depositEtherFor{value: _amount}(_receiverAddress);
    }

    function _bridgeExternalERC20(uint256 _amount, address _receiverAddress, address _token, uint256 _value) internal {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }

        IERC20 token = IERC20(_token);

        // set allowance for erc20 predicate
        token.safeTransferFrom(msg.sender, socketGateway, _amount);
        token.safeIncreaseAllowance(erc20PredicateProxy, _amount);

        // deposit into rootchain manager
        IRootChainManager(rootChainManagerProxy).depositFor(_receiverAddress, _token, abi.encodePacked(_amount));
    }

    function _bridgeInternalERC20(uint256 _amount, address _receiverAddress, address _token, uint256 _value) internal {
        if (_value != 0) {
            revert ValueShouldBeZero();
        }
        IERC20(_token).safeIncreaseAllowance(erc20PredicateProxy, _amount);

        // deposit into rootchain manager
        IRootChainManager(rootChainManagerProxy).depositFor(_receiverAddress, _token, abi.encodePacked(_amount));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IRefuel {
    function depositNativeToken(uint256 destinationChainId, address _to) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/refuel.sol";
import "../BridgeImplBase.sol";
import {ValueShouldNotBeZero, ValueNotEqualToAmount} from "../../errors/SocketErrors.sol";

contract RefuelBridgeImpl is BridgeImplBase {
    //address public constant REFUEL_BRIDGE = 0xb584D4bE1A5470CA1a8778E9B86c81e165204599;
    address public immutable refuelBridge;

    constructor(address _refuelBridge, address _socketGateway) BridgeImplBase(_socketGateway) {
        refuelBridge = _refuelBridge;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /**
     * @notice function responsible for calling cross chain transfer using refuel bridge.
     * @param _receiverAddress receivers address.
     * @param _toChainId destination chain Id
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address,
        uint256 _toChainId,
        uint256 value,
        bytes calldata
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        if (value == 0) {
            revert ValueShouldNotBeZero();
        }

        if (value != _amount) {
            revert ValueNotEqualToAmount();
        }

        IRefuel(refuelBridge).depositNativeToken{value: _amount}(_toChainId, _receiverAddress);

        return (NATIVE_TOKEN_ADDRESS, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address,
        uint256 _toChainId,
        uint256 value,
        bytes calldata
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        if (value == 0) {
            revert ValueShouldNotBeZero();
        }

        if (value != _amount) {
            revert ValueNotEqualToAmount();
        }

        IRefuel(refuelBridge).depositNativeToken{value: _amount}(_toChainId, _receiverAddress);

        return (NATIVE_TOKEN_ADDRESS, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridgeStargate {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    // only in non RouterETH
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    )
        external
        payable;

    // only in non RouterETH
    function bridge() external pure returns (address);

    // only in RouterETH
    function swapETH(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    )
        external
        payable;

    // only in RouterETH
    function stargateRouter() external pure returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/stargate.sol";
import "../../../errors/SocketErrors.sol";
import "../../BridgeImplBase.sol";
import {ValueNotEqualToAmount, ValueShouldNotBeZero, ValueShouldBeZero} from "../../../errors/SocketErrors.sol";

/**
 * // @title Stargate L1 Implementation.
 * // @author Socket dot tech.
 */
contract StargateImpl is BridgeImplBase {
    using SafeERC20 for IERC20;

    IBridgeStargate public immutable router;
    IBridgeStargate public immutable routerETH;

    constructor(address _router, address _routerEth, address _socketGateway) BridgeImplBase(_socketGateway) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    struct StargateData {
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        address senderAddress;
        uint256 destinationGasLimit;
        bytes destinationPayload;
    }

    /**
     * // @notice Function responsible for cross chain transfer from l2 to l1 or supported
     * // l2s.
     * // Called by the registry when the selected bridge is Hop bridge.
     * // @dev Try to check for the liquidity on the other side before calling this.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiver address
     * // @param _token address of the token to bridged to the destination chain.
     * // @param _data data required to call the Hop swap and send function. hopAmm address,
     * // boderfee, amount out min and deadline.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode data
        StargateData memory _stargateData = abi.decode(_data, (StargateData));

        // token address might not be indication thats why passed through extraData
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _value, _stargateData);
        } else {
            _bridgeExternalERC20(_amount, _receiverAddress, _token, _value, _stargateData);
        }

        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode data
        StargateData memory _stargateData = abi.decode(_data, (StargateData));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _value, _stargateData);

        return (_token, _amount);
    }

    function _bridgeNative(uint256 _amount, address _receiverAddress, uint256 _value, StargateData memory _stargateData)
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }

        // perform bridging
        routerETH.swapETH{value: _amount + _stargateData.optionalValue}(
            _stargateData.stargateDstChainId,
            payable(_stargateData.senderAddress),
            abi.encodePacked(_receiverAddress),
            _amount,
            _stargateData.minReceivedAmt
        );
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        StargateData memory _stargateData
    )
        internal
    {
        if (_value == 0) {
            revert ValueShouldNotBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        {
            router.swap{value: _value}(
                _stargateData.stargateDstChainId,
                _stargateData.srcPoolId,
                _stargateData.dstPoolId,
                payable(_stargateData.senderAddress), // default to refund to main contract
                _amount,
                _stargateData.minReceivedAmt,
                IBridgeStargate.lzTxObj(_stargateData.destinationGasLimit, 0, "0x"),
                abi.encodePacked(_receiverAddress),
                _stargateData.destinationPayload
            );
        }
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        StargateData memory _stargateData
    )
        internal
    {
        if (_value == 0) {
            revert ValueShouldNotBeZero();
        }

        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        {
            router.swap{value: _value}(
                _stargateData.stargateDstChainId,
                _stargateData.srcPoolId,
                _stargateData.dstPoolId,
                payable(_stargateData.senderAddress), // default to refund to main contract
                _amount,
                _stargateData.minReceivedAmt,
                IBridgeStargate.lzTxObj(_stargateData.destinationGasLimit, 0, "0x"),
                abi.encodePacked(_receiverAddress),
                _stargateData.destinationPayload
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/stargate.sol";
import "../../../errors/SocketErrors.sol";
import "../../BridgeImplBase.sol";
import {ValueNotEqualToAmount, ValueShouldNotBeZero, ValueShouldBeZero} from "../../../errors/SocketErrors.sol";

/**
 * // @title Stargate L1 Implementation.
 * // @author Socket dot tech.
 */
contract StargateImpl is BridgeImplBase {
    using SafeERC20 for IERC20;

    IBridgeStargate public immutable router;
    IBridgeStargate public immutable routerETH;

    constructor(address _router, address _routerEth, address _socketGateway) BridgeImplBase(_socketGateway) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    struct StargateData {
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        address senderAddress;
        uint256 destinationGasLimit;
        bytes destinationPayload;
    }

    /**
     * // @notice Function responsible for cross chain transfer from l2 to l1 or supported
     * // l2s.
     * // Called by the registry when the selected bridge is Hop bridge.
     * // @dev Try to check for the liquidity on the other side before calling this.
     * // @param _amount amount to be sent.
     * // @param _receiverAddress receiver address
     * // @param _token address of the token to bridged to the destination chain.
     * // @param _data data required to call the Hop swap and send function. hopAmm address,
     * // boderfee, amount out min and deadline.
     */
    function bridgeExternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode data
        StargateData memory _stargateData = abi.decode(_data, (StargateData));

        // token address might not be indication thats why passed through extraData
        if (_token == NATIVE_TOKEN_ADDRESS) {
            _bridgeNative(_amount, _receiverAddress, _value, _stargateData);
        } else {
            _bridgeExternalERC20(_amount, _receiverAddress, _token, _value, _stargateData);
        }

        return (_token, _amount);
    }

    function bridgeInternalTo(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256,
        uint256 _value,
        bytes calldata _data
    )
        external
        payable
        override
        returns (address token, uint256 bridgedAmount)
    {
        // decode data
        StargateData memory _stargateData = abi.decode(_data, (StargateData));
        _bridgeInternalERC20(_amount, _receiverAddress, _token, _value, _stargateData);

        return (_token, _amount);
    }

    function _bridgeNative(uint256 _amount, address _receiverAddress, uint256 _value, StargateData memory _stargateData)
        internal
    {
        if (_value != _amount) {
            revert ValueNotEqualToAmount();
        }

        // perform bridging
        routerETH.swapETH{value: _amount + _stargateData.optionalValue}(
            _stargateData.stargateDstChainId,
            payable(_stargateData.senderAddress),
            abi.encodePacked(_receiverAddress),
            _amount,
            _stargateData.minReceivedAmt
        );
    }

    function _bridgeExternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        StargateData memory _stargateData
    )
        internal
    {
        if (_value == 0) {
            revert ValueShouldNotBeZero();
        }

        IERC20(_token).safeTransferFrom(msg.sender, socketGateway, _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        {
            router.swap{value: _value}(
                _stargateData.stargateDstChainId,
                _stargateData.srcPoolId,
                _stargateData.dstPoolId,
                payable(_stargateData.senderAddress), // default to refund to main contract
                _amount,
                _stargateData.minReceivedAmt,
                IBridgeStargate.lzTxObj(_stargateData.destinationGasLimit, 0, "0x"),
                abi.encodePacked(_receiverAddress),
                _stargateData.destinationPayload
            );
        }
    }

    function _bridgeInternalERC20(
        uint256 _amount,
        address _receiverAddress,
        address _token,
        uint256 _value,
        StargateData memory _stargateData
    )
        internal
    {
        if (_value == 0) {
            revert ValueShouldNotBeZero();
        }

        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        {
            router.swap{value: _value}(
                _stargateData.stargateDstChainId,
                _stargateData.srcPoolId,
                _stargateData.dstPoolId,
                payable(_stargateData.senderAddress), // default to refund to main contract
                _amount,
                _stargateData.minReceivedAmt,
                IBridgeStargate.lzTxObj(_stargateData.destinationGasLimit, 0, "0x"),
                abi.encodePacked(_receiverAddress),
                _stargateData.destinationPayload
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {RouteNotFound} from "../errors/SocketErrors.sol";

/// @title BaseController Controller
/// @notice Base contract for all controller contracts
abstract contract BaseController {
    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public immutable NULL_ADDRESS = address(0);
    bytes4 public immutable SWAP_FUNCTION_SELECTOR =
        bytes4(keccak256("performAction(address,address,uint256,address,bytes)"));
    bytes4 public immutable BRIDGE_EXTERNAL_SELECTOR =
        bytes4(keccak256("bridgeExternalTo(uint256,address,address,uint256,uint256,bytes)"));
    bytes4 public immutable BRIDGE_INTERNAL_SELECTOR =
        bytes4(keccak256("bridgeInternalTo(uint256,address,address,uint256,uint256,bytes)"));

    address public immutable socketGatewayAddress;
    ISocketRoute public immutable socketRoute;
    ISocketGateway public immutable socketGateway;

    constructor(address _socketGatewayAddress) {
        socketGatewayAddress = _socketGatewayAddress;
        socketRoute = ISocketRoute(_socketGatewayAddress);
        socketGateway = ISocketGateway(_socketGatewayAddress);
    }

    function _executeRoute(uint256 routeId, bytes memory data) internal returns (bytes memory) {
        // load bridge info and validate
        ISocketRoute.RouteData memory routeInfo = socketRoute.getRoute(routeId);

        if (!routeInfo.isEnabled) {
            revert RouteNotFound();
        }

        (bool success, bytes memory result) = address(routeInfo.route).delegatecall(data);

        if (success == false) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {BaseController} from "./BaseController.sol";
import {InvalidAmount, Address0Provided, RouteNotAllowed} from "../errors/SocketErrors.sol";

/// @title RefuelSwapAndBridge Controller
/// @notice Manages bridge requests
contract RefuelSwapAndBridgeController is BaseController {
    constructor(address _socketGatewayAddress) BaseController(_socketGatewayAddress) {}

    function refuelAndSwapAndBridge(ISocketRequest.RefuelSwapBridgeRequest calldata refuelSwapBridgeRequest)
        public
        payable
        returns (bytes memory)
    {
        _executeRoute(refuelSwapBridgeRequest.refuelRouteId, refuelSwapBridgeRequest.refuelData);

        bytes memory swapResponseData =
            _executeRoute(refuelSwapBridgeRequest.swapRouteId, refuelSwapBridgeRequest.swapData);
        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        ISocketRequest.BridgeRequest memory bridgeRequest = refuelSwapBridgeRequest.bridgeRequest;

        if (bridgeRequest.token == NATIVE_TOKEN_ADDRESS) {
            //sequence of arguments for implData: amount, from, receiverAddress, token, toChainId, value, data
            bytes memory nativeImpldata = abi.encodeWithSelector(
                BRIDGE_EXTERNAL_SELECTOR,
                swapAmount,
                bridgeRequest.receiverAddress,
                bridgeRequest.token,
                bridgeRequest.toChainId,
                swapAmount,
                bridgeRequest.data
            );

            return _executeRoute(bridgeRequest.id, nativeImpldata);
        }

        //sequence of arguments for implData: amount, from, receiverAddress, token, toChainId, value, data
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_INTERNAL_SELECTOR,
            swapAmount,
            bridgeRequest.receiverAddress,
            bridgeRequest.token,
            bridgeRequest.toChainId,
            bridgeRequest.value,
            bridgeRequest.data
        );

        return _executeRoute(bridgeRequest.id, bridgeImpldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error OnlySocketGatewayOwner();
error OnlySocketGateway();
error OnlyOwner();
error OnlyNominee();
error ValueNotEqualToAmount();
error TransferIdExists();
error TransferIdDoesnotExist();
error ValueShouldBeZero();
error ValueShouldNotBeZero();
error InvalidRouteData();
error InvalidRouterAddress();
error InvalidWethAddress();
error InvalidInboxAddress();
error InvalidAmount();
error Address0Provided();
error RouteAlreadyExist();
error RouteNotAllowed();
error RouteNotFound();
error RouteUpdateDoesntExist();
error RouteInitDoesntExist();
error RouteInitialisationFailed();
error RouteAlreadyInitialised();
error DisabledRoute();
error MiddlewareActionFailed();
error SwapFailed();
error UnsupportedInterfaceId();
error InvalidRootChainManagerProxy();
error InvalidErc20PredicateProxy();
error TokenNotSupported();
error ContractContainsNoCode();
error InvalidCelerRefund();
error CelerAlreadyRefunded();
error ControllerAlreadyExist();
error ControllerDoesnotExist();
error ControllerCantBeDisabled();
error ControllerAddressIsZero();
error ControllerContainsNoCode();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISocketController {
    struct Controller {
        address controller;
        bool isEnabled;
    }

    function addController(address _controllerAddress) external returns (uint256);

    function disableController(uint256 _controllerId) external;

    function getController(uint256 _controllerId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISocketGateway {
    struct SocketControllerRequest {
        uint256 controllerId;
        bytes data;
    }

    function owner() external view returns (address);

    function bridge(uint256 routeId, bytes memory data) external payable returns (bytes memory);

    function execute(ISocketGateway.SocketControllerRequest calldata socketControllerRequest)
        external
        payable
        returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISocketRequest {
    /**
     * // @param receiverAddress Recipient address to recieve funds on destination chain
     * // @param toChainId Destination ChainId
     * // @param amount amount to be swapped if middlewareId is 0  it will be
     * // the amount to be bridged
     * // @param id routeId of the Bridge
     * // @param optionalNativeAmount optional NativeAmount
     * // @param inputToken address of inputToken
     * // @param data byte data for the bridgeImpl
     */
    struct SwapRequest {
        uint256 id;
        address receiverAddress;
        uint256 amount;
        address inputToken;
        address toToken;
        bytes data;
    }

    /**
     * // @param id routeId of the Bridge
     * // @param amount amount to be bridged
     * // @param receiverAddress Recipient address to recieve funds on destination chain
     * // @param token address of inputToken
     * // @param toChainId  Destination ChainId
     * // @param value native value
     * // @param data byte data for the bridgeImpl
     */
    struct BridgeRequest {
        uint256 id;
        uint256 amount;
        address receiverAddress;
        address token;
        uint256 toChainId;
        uint256 value;
        bytes data;
    }

    struct RefuelSwapBridgeRequest {
        uint256 refuelRouteId;
        bytes refuelData;
        uint256 swapRouteId;
        bytes swapData;
        BridgeRequest bridgeRequest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISocketRoute {
    struct RouteData {
        address route;
        bool isEnabled;
    }

    function addRoute(address _routeAddress) external;

    function disableRoute(uint256 _routeId) external;

    function getRoute(uint256 routeId) external view returns (RouteData memory);

    function getRoutes() external view returns (RouteData[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();
    error UintOutOfBounds();

    // -------------------------

    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00), and(mload(mc), mask))
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        if (_length + 31 < _length) {
            revert SliceOverflow();
        }
        if (_bytes.length < _start + _length) {
            revert SliceOutOfBounds();
        }

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        if (_bytes.length < _start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        if (_bytes.length < _start + 1) {
            revert UintOutOfBounds();
        }
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        if (_bytes.length < _start + 2) {
            revert UintOutOfBounds();
        }
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        if (_bytes.length < _start + 4) {
            revert UintOutOfBounds();
        }
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        if (_bytes.length < _start + 8) {
            revert UintOutOfBounds();
        }
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        if (_bytes.length < _start + 12) {
            revert UintOutOfBounds();
        }
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        if (_bytes.length < _start + 16) {
            revert UintOutOfBounds();
        }
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        if (_bytes.length < _start + 32) {
            revert UintOutOfBounds();
        }
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        if (_bytes.length < _start + 32) {
            revert UintOutOfBounds();
        }
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for { let cc := add(_postBytes, 0x20) }
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibBytes.sol";
import {ContractContainsNoCode} from "../errors/SocketErrors.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(bytes memory _res) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) {
            return "Transaction reverted silently";
        }
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert ContractContainsNoCode();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag) internal pure returns (uint256[] memory cnts) {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf) internal pure returns (uint256[] memory t) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../SwapImplBase.sol";
import {MiddlewareActionFailed} from "../../errors/SocketErrors.sol";

/**
 * // @title One Inch Swap Implementation
 * // @notice Called by the registry before cross chain transfers if the user requests
 * // for a swap
 * // @dev Follows the interface of Swap Impl Base
 * // @author Movr Network
 */
contract OneInchImpl is SwapImplBase {
    address public immutable ONEINCH_AGGREGATOR;

    using SafeERC20 for IERC20;

    event AmountRecieved(uint256 amount, address tokenAddress, address receiver);

    constructor(address _oneinchAggregator, address _socketGateway) SwapImplBase(_socketGateway) {
        ONEINCH_AGGREGATOR = _oneinchAggregator;
    }

    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    )
        external
        payable
        override
        returns (uint256)
    {
        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(msg.sender, socketGateway, amount);
            IERC20(fromToken).safeIncreaseAllowance(ONEINCH_AGGREGATOR, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call(data);
                IERC20(fromToken).safeApprove(ONEINCH_AGGREGATOR, 0);

                if (!success) {
                    revert MiddlewareActionFailed();
                }

                (uint256 returnAmount) = abi.decode(result, (uint256));
                emit AmountRecieved(returnAmount, toToken, receiverAddress);
                return returnAmount;
            }
        } else {
            (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call{value: amount}(data);
            if (!success) {
                revert MiddlewareActionFailed();
            }
            (uint256 returnAmount) = abi.decode(result, (uint256));
            emit AmountRecieved(returnAmount, toToken, receiverAddress);
            return returnAmount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../SwapImplBase.sol";
import {Address0Provided, MiddlewareActionFailed} from "../../errors/SocketErrors.sol";

/**
 * // @title Rainbow Swap Implementation
 * // @notice Called by the registry before cross chain transfers if the user requests
 * // for a swap
 * // @dev Follows the interface of Swap Impl Base
 */
contract RainbowSwapImpl is SwapImplBase {
    using SafeERC20 for IERC20;

    address payable public immutable rainbowSwapAggregator;

    event AmountRecieved(uint256 amount, address tokenAddress, address receiver);

    /// rainbow swap aggregator contract is payable to allow ethereum swaps
    constructor(address _rainbowSwapAggregator, address _socketGateway) SwapImplBase(_socketGateway) {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * // @notice Function responsible for swapping from one token to a different token
     * // @dev This is called only when there is a request for a swap.
     * // @param fromToken token to be swapped
     * // @param amount amount to be swapped
     * // param to not required. This is there only to follow the MiddlewareImplBase
     * // @param swapExtraData data required for rainbowSwapAggregator to get the swap done
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory swapExtraData
    )
        external
        payable
        override
        returns (uint256)
    {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        (address payable toTokenAddress, bytes memory swapCallData) = abi.decode(swapExtraData, (address, bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = IERC20(toTokenAddress).balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = socketGateway.balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(msg.sender, socketGateway, amount);
            IERC20(fromToken).safeIncreaseAllowance(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success,) = rainbowSwapAggregator.call(swapCallData);

            if (!success) {
                revert MiddlewareActionFailed();
            }

            IERC20(fromToken).safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success,) = rainbowSwapAggregator.call{value: amount}(swapCallData);
            if (!success) {
                revert MiddlewareActionFailed();
            }
        }

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = IERC20(toTokenAddress).balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = socketGateway.balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toTokenAddress == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            IERC20(toTokenAddress).transfer(receiverAddress, returnAmount);
        }
        emit AmountRecieved(returnAmount, toToken, receiverAddress);
        return returnAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import "../libraries/Pb.sol";
import {RouteAlreadyInitialised, OnlySocketGatewayOwner} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Middleware Implementation will follow this interface.
 */
abstract contract SwapImplBase {
    using SafeERC20 for IERC20;

    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public immutable socketGateway;

    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    )
        external
        payable
        virtual
        returns (uint256);

    function rescueFunds(address token, address userAddress, uint256 amount) external isSocketGatewayOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../SwapImplBase.sol";
import {Address0Provided, MiddlewareActionFailed} from "../../errors/SocketErrors.sol";

/**
 * // @title 0X Implementation
 * // @notice Called by the SocketGateway before cross chain transfers if the user requests
 * // for a swap
 * // @dev Follows the interface of Swap Impl Base
 */
contract ZeroXSwapImpl is SwapImplBase {
    using SafeERC20 for IERC20;

    address payable public immutable zeroXExchangeProxy;

    event AmountRecieved(uint256 amount, address tokenAddress, address receiver);

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(address _zeroXExchangeProxy, address _socketGateway) SwapImplBase(_socketGateway) {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * // @notice Function responsible for swapping from one token to a different token
     * // @dev This is called only when there is a request for a swap.
     * // @param fromToken token to be swapped
     * // @param toToken token to which fromToken is to be swapped
     * // @param amount amount to be swapped
     * // @param receiverAddress address of toToken recipient
     * // @param swapExtraData data required for zeroX Exchange to get the swap done
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory swapExtraData
    )
        external
        payable
        override
        returns (uint256)
    {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        (address payable toTokenAddress, bytes memory swapCallData) = abi.decode(swapExtraData, (address, bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = IERC20(toTokenAddress).balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(fromToken).safeIncreaseAllowance(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success,) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert MiddlewareActionFailed();
            }

            IERC20(fromToken).safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success,) = zeroXExchangeProxy.call{value: amount}(swapCallData);
            if (!success) {
                revert MiddlewareActionFailed();
            }
        }

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = IERC20(toTokenAddress).balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toTokenAddress == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            IERC20(toTokenAddress).transfer(receiverAddress, returnAmount);
        }

        emit AmountRecieved(returnAmount, toToken, receiverAddress);
        return returnAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "../utils/Ownable.sol";

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId, // the remote chainId sending the tokens
        bytes memory _srcAddress, // the remote Bridge address
        uint256 _nonce,
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}

contract StargateReceiver is
    Ownable,
    Pausable,
    ReentrancyGuard,
    IStargateReceiver
{
    using SafeERC20 for IERC20;
    address public stargateRouter;
    address public NATIVE_TOKEN_ADDRESS;
    uint256 public defaultGas;
    mapping(address => bool) public blockList;

    event UpdateStargateRouterAddress(address indexed stargateRouterAddress);
    event PayloadExecuted(
        address indexed toAddress,
        uint256 amount,
        address token
    );
    event AddressBlocked(address indexed blockedAddress);
    event AddressUnblocked(address indexed unblockedAddress);
    error StargateRouterOnly();
    error AddressBlockedError();
    error PayloadExectionFailed();


    constructor(
        address _stargateRouter,
        address _nativeTokenAddress,
        address _owner,
        uint256 _defaultGas
    ) Ownable(_owner) {
        stargateRouter = _stargateRouter;
        NATIVE_TOKEN_ADDRESS = _nativeTokenAddress;
        defaultGas = _defaultGas;
    }

    modifier onlyStargateRouter() {
        if(msg.sender != stargateRouter) revert StargateRouterOnly();
        _;
    }

    modifier notBlocked(address _address) {
        if(blockList[_address]) revert AddressBlockedError();
        _;
    }

    function blockAddress(address _address) external onlyOwner {
        blockList[_address] = true;
        emit AddressBlocked(_address);
    }

    function unblockAddress(address _address) external onlyOwner {
        blockList[_address] = false;
        emit AddressUnblocked(_address);
    }

    function setDefaultGas(uint256 _defaultGas) external onlyOwner {
        defaultGas = _defaultGas;
    }

    function setPause() public onlyOwner returns (bool) {
        _pause();
        return paused();
    }

    function setUnPause() public onlyOwner returns (bool) {
        _unpause();
        return paused();
    }

    function updateStargateRouterAddress(address newStargateRouter)
        external
        onlyOwner
    {
        stargateRouter = newStargateRouter;
        emit UpdateStargateRouterAddress(newStargateRouter);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }

    function sgReceive(
        uint16, // the remote chainId sending the tokens
        bytes memory, // the remote Bridge address
        uint256,
        address token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external override onlyStargateRouter nonReentrant whenNotPaused {
        (address payable toAddress, bytes memory dataPayload) = abi.decode(
            payload,
            (address, bytes)
        );
        perfomAction(token, amountLD, toAddress, dataPayload);
    }

    function perfomAction(
        address token,
        uint256 amountLD,
        address payable toAddress,
        bytes memory dataPayload
    ) private notBlocked(toAddress) {
        if (token == NATIVE_TOKEN_ADDRESS) {
            (bool success, ) = toAddress.call{
                gas: gasleft() - defaultGas,
                value: amountLD
            }(dataPayload);
            if(!success) {
               revert PayloadExectionFailed();
            }
        } else {
            IERC20(token).safeIncreaseAllowance(toAddress, amountLD);
            (bool success, ) = toAddress.call{gas: gasleft() - defaultGas}(
                dataPayload
            );
            IERC20(token).safeDecreaseAllowance(toAddress, 0);
            if(!success) {
               revert PayloadExectionFailed();
            }
        }
        emit PayloadExecuted(toAddress, amountLD, token);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {LibUtil} from "./libraries/LibUtil.sol";
import "./libraries/LibBytes.sol";
import {ISocketRoute} from "./interfaces/ISocketRoute.sol";
import {ISocketRequest} from "./interfaces/ISocketRequest.sol";
import {ISocketGateway} from "./interfaces/ISocketGateway.sol";
import {ISocketController} from "./interfaces/ISocketController.sol";
import {
    InvalidAmount,
    Address0Provided,
    RouteNotAllowed,
    SwapFailed,
    RouteNotFound,
    Address0Provided,
    InvalidRouteData,
    RouteAlreadyExist,
    RouteNotAllowed,
    RouteInitialisationFailed,
    DisabledRoute,
    OnlySocketGatewayOwner,
    ControllerDoesnotExist,
    ControllerAddressIsZero,
    ControllerAlreadyExist,
    ControllerCantBeDisabled
} from "./errors/SocketErrors.sol";

contract SocketGateway is Ownable, ReentrancyGuard {
    address public immutable NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public immutable NULL_ADDRESS = address(0);

    bytes4 public immutable SWAP_FUNCTION_SELECTOR =
        bytes4(keccak256("performAction(address,address,uint256,address,bytes)"));
    bytes4 public immutable BRIDGE_EXTERNAL_SELECTOR =
        bytes4(keccak256("bridgeExternalTo(uint256,address,address,uint256,uint256,bytes)"));
    bytes4 public immutable BRIDGE_INTERNAL_SELECTOR =
        bytes4(keccak256("bridgeInternalTo(uint256,address,address,uint256,uint256,bytes)"));

    //Events
    event NewRouteAdded(uint256 indexed routeId, address indexed route, bool isEnabled);
    event RouteDisabled(uint256 indexed routeID);
    event OwnershipTransferRequested(address indexed _from, address indexed _to);
    event ControllerAdded(address indexed controllerAddress, uint256 indexed controllerId);
    event ControllerDisabled(address indexed controllerAddress, uint256 indexed controllerId);

    using SafeERC20 for IERC20;

    //Route storage
    ISocketRoute.RouteData[] routes;

    uint256 routesCount;

    // Controller Storage
    ISocketController.Controller[] controllers;

    // number of controllers registered in socketgateway
    uint256 controllerCount;

    constructor(address _owner) Ownable(_owner) {}

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    modifier onlyExistingRoute(uint256 _routeId) {
        if (LibUtil.isZeroAddress(routes[_routeId].route) || !routes[_routeId].isEnabled) {
            revert RouteNotFound();
        }
        _;
    }

    modifier isRouteEnabled(uint256 _routeId) {
        if (!routes[_routeId].isEnabled) {
            revert RouteNotFound();
        }
        _;
    }

    function getRoute(uint256 routeId) public view returns (ISocketRoute.RouteData memory) {
        return routes[routeId];
    }

    function getRoutes() external view returns (ISocketRoute.RouteData[] memory) {
        return routes;
    }

    function getController(uint256 _controllerId)
        public
        view
        returns (ISocketController.Controller memory Controller)
    {
        return controllers[_controllerId];
    }

    function doesRouteExist(address _routeAddress) public view returns (bool) {
        for (uint256 i = 0; i < routesCount; ++i) {
            if (routes[i].route == _routeAddress) {
                return true;
            }
        }

        return false;
    }

    function doesControllerExist(address _controllerAddress) public view returns (bool) {
        for (uint256 i = 0; i < controllerCount; ++i) {
            if (controllers[i].controller == _controllerAddress) {
                return true;
            }
        }

        return (false);
    }

    /// @notice add routes to the SocketGateway.
    function addRoute(address _routeAddress) external onlyOwner returns (uint256) {
        if (LibUtil.isZeroAddress(_routeAddress)) {
            revert Address0Provided();
        }

        if (doesRouteExist(_routeAddress)) {
            revert RouteAlreadyExist();
        }

        LibUtil.enforceHasContractCode(_routeAddress);

        uint256 routeId = routesCount;

        ISocketRoute.RouteData memory _route = ISocketRoute.RouteData(_routeAddress, true);

        routes.push(_route);

        routesCount = routes.length;

        emit NewRouteAdded(routeId, _route.route, _route.isEnabled);

        return routeId;
    }

    function addController(address _controllerAddress) external onlyOwner returns (uint256) {
        if (LibUtil.isZeroAddress(_controllerAddress)) {
            revert ControllerAddressIsZero();
        }

        if (doesControllerExist(_controllerAddress)) {
            revert ControllerAlreadyExist();
        }

        LibUtil.enforceHasContractCode(_controllerAddress);

        uint256 controllerId = controllers.length;

        ISocketController.Controller memory controllerObj =
            ISocketController.Controller({controller: _controllerAddress, isEnabled: true});

        controllers.push(controllerObj);

        controllerCount = controllers.length;

        emit ControllerAdded(_controllerAddress, controllerId);

        return controllerId;
    }

    function disableController(uint256 _controllerId) public onlyOwner {
        ISocketController.Controller storage controllerObj = controllers[_controllerId];
        controllerObj.isEnabled = false;
        emit ControllerDisabled(controllerObj.controller, _controllerId);
    }

    ///@notice disables the route  if required.
    function disableRoute(uint256 _routeId) external onlyOwner onlyExistingRoute(_routeId) {
        routes[_routeId].isEnabled = false;
        emit RouteDisabled(_routeId);
    }

    function _executeRoute(uint256 routeId, bytes memory data)
        internal
        isRouteEnabled(routeId)
        returns (bytes memory)
    {
        // load bridge info and validate
        ISocketRoute.RouteData memory routeInfo = getRoute(routeId);

        (bool success, bytes memory result) = address(routeInfo.route).delegatecall(data);

        if (success == false) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    function _executeController(ISocketGateway.SocketControllerRequest calldata socketControllerRequest)
        internal
        returns (bool, bytes memory)
    {
        ISocketController.Controller memory controllerObj = getController(socketControllerRequest.controllerId);
        if (!controllerObj.isEnabled) {
            revert ControllerDoesnotExist();
        }

        (bool success, bytes memory result) = (controllerObj.controller).delegatecall(socketControllerRequest.data);

        if (success == false) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return (success, result);
    }

    function bridge(uint256 routeId, bytes memory data) external payable nonReentrant returns (bytes memory) {
        return _executeRoute(routeId, data);
    }

    function swap(uint256 routeId, bytes memory data) external payable nonReentrant returns (bytes memory) {
        return _executeRoute(routeId, data);
    }

    function swapAndBridge(
        uint256 swapRouteId,
        bytes calldata swapImplData,
        ISocketRequest.BridgeRequest calldata bridgeRequest
    )
        external
        payable
        nonReentrant
        returns (bytes memory)
    {
        bytes memory swapResponseData = _executeRoute(swapRouteId, swapImplData);

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        if (bridgeRequest.token == NATIVE_TOKEN_ADDRESS) {
            //sequence of arguments for implData: amount, from, receiverAddress, token, toChainId, value, data
            bytes memory nativeImplData = abi.encodeWithSelector(
                BRIDGE_EXTERNAL_SELECTOR,
                swapAmount,
                bridgeRequest.receiverAddress,
                bridgeRequest.token,
                bridgeRequest.toChainId,
                swapAmount,
                bridgeRequest.data
            );

            return _executeRoute(bridgeRequest.id, nativeImplData);
        }

        //sequence of arguments for implData: amount, from, receiverAddress, token, toChainId, value, data
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_INTERNAL_SELECTOR,
            swapAmount,
            bridgeRequest.receiverAddress,
            bridgeRequest.token,
            bridgeRequest.toChainId,
            bridgeRequest.value,
            bridgeRequest.data
        );

        return _executeRoute(bridgeRequest.id, bridgeImpldata);
    }

    function executeRoutes(uint256[] memory routeIds, bytes[] memory dataItems) external payable nonReentrant {
        for (uint256 index = 0; index < routeIds.length; ++index) {
            _executeRoute(routeIds[index], dataItems[index]);
        }
    }

    function executeController(ISocketGateway.SocketControllerRequest calldata socketControllerRequest)
        external
        payable
        nonReentrant
        returns (bool, bytes memory)
    {
        return _executeController(socketControllerRequest);
    }

    function executeControllers(ISocketGateway.SocketControllerRequest[] calldata controllerRequests)
        external
        payable
        nonReentrant
    {
        for (uint256 index = 0; index < controllerRequests.length; ++index) {
            _executeController(controllerRequests[index]);
        }
    }

    function rescueFunds(address token, address userAddress, uint256 amount) external nonReentrant onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount) external nonReentrant onlyOwner {
        userAddress.transfer(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {OnlyOwner, OnlyNominee} from "../errors/SocketErrors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}