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
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {DSMath} from "./library/DSMath.sol";

/**
 * @title Lepricon Staking Contract
 * @author @Pedrojok01
 */
contract LepriconStaking is DSMath, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /* Storage:
     ***********/

    IERC20 public token;
    address private admin; // = back-end address (yield payment + API)

    struct Vault {
        uint8 apr;
        uint256 timelock;
        uint256 totalAmountLock;
    }

    Vault[4] public vaults;

    /**
     * @notice Define the token that will be used for staking, and push once to stakeholders for index to work properly
     * @param _token the token that will be used for staking
     */
    constructor(IERC20 _token) {
        _initializeVaults();
        token = _token;
        admin = _msgSender();
        stakeholders.push();
    }

    /**
     * @notice Struct used to represent the way we store each stake;
     * A Stake contain the users address, the amount staked, the timeLock duration, and the unlock time;
     * @param since allow us to calculate the reward (reset to block.timestamp with each withdraw)
     * @param claimable is used to display the actual reward earned to user (see hasStake() function)
     */
    struct Stake {
        address user;
        uint8 timeLock;
        uint256 amount;
        uint256 since;
        uint256 unlockTime;
        uint256 claimable;
    }

    /// @notice Track the NFT status per stakeholders that has at least 1 active stake
    struct Boost {
        bool isBoost;
        uint8 boostValue;
        address NftContractAddress;
        uint256 tokenId;
        uint256 since;
    }

    /// @notice A Stakeholder is a staker that has at least 1 active stake
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    /// @notice Struct used to contain all stakes per address (user)
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    /// @notice Store all Stakes performed on the Contract per index, the index can be found using the stakes mapping
    Stakeholder[] private stakeholders;

    /// @notice Map all NFTboost status per stakehoder address
    mapping(address => Boost) public boost;

    /// @notice keep track of the INDEX for the stakers in the stakes array
    mapping(address => uint256) private stakes;

    /***********************************************************************************
                                    STAKE FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow a user to stake his tokens
     * @param _amount Amount of tokens that the user wish to stake
     * @param _timeLock Duration of staking (in months) chosen by user: 0 | 3 | 6 | 12 (will determines the APR)
     */
    function stake(uint256 _amount, uint8 _timeLock)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            _amount < token.balanceOf(_msgSender()),
            "Cannot stake more than you own"
        );
        require(
            _amount <= token.allowance(_msgSender(), address(this)),
            "Not authorized"
        );
        token.safeTransferFrom(_msgSender(), address(this), _amount); // Transfer tokens to staking contract
        _stake(_amount, _timeLock); // Handle the new stake
    }

    /**
     * @notice Create a new stake from sender. Will remove the amount to stake from sender and store it in a container
     */
    function _stake(uint256 _amount, uint8 _timeLock) private {
        require(_amount > 0, "Cannot stake nothing");

        uint256 _lock = _getLockPeriod(_timeLock);
        _addAmountToVault(_amount, _timeLock);

        uint256 index = stakes[_msgSender()];
        uint256 since = block.timestamp;
        uint256 unlockTime = since + _lock;
        // Check if the staker already has a staked index or if new user
        if (index == 0) {
            index = _addStakeholder(_msgSender());
        }

        stakeholders[index].address_stakes.push(
            Stake(_msgSender(), _timeLock, _amount, since, unlockTime, index)
        );

        emit Staked(_msgSender(), _amount, index, since, _lock, unlockTime);
    }

    /**
     * @notice Add the selected amount to the selected vault;
     * @param _amount Amount to be added;
     * @param _timelock Vault to add the amount in (0 | 1 | 3 | 6 | 12);
     */
    function _addAmountToVault(uint256 _amount, uint8 _timelock) private {
        uint8 vaultIndex = _getIndexFromTimelock(_timelock);
        vaults[vaultIndex].totalAmountLock += _amount;
    }

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 lockTime,
        uint256 unlockTime
    );

    /***********************************************************************************
                                    WITHDRAW FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow a staker to withdraw his stakes from his holder's account
     */
    function withdrawStake(uint256 amount, uint256 stake_index)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 reward = _withdrawStake(amount, stake_index);
        // Return staked tokens to user
        token.safeTransfer(_msgSender(), amount);
        // Pay earned reward to user
        token.safeTransferFrom(admin, _msgSender(), reward);
    }

    /**
     * @notice Takes in an amount and the index of the stake to withdraw from, and removes the tokens from that stake
     * The index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to transfer back to the acount (amount to withdraw + reward) and reset timer
     */
    function _withdrawStake(uint256 _amount, uint256 _index)
        private
        returns (uint256)
    {
        uint256 user_index = stakes[_msgSender()];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            _index
        ];
        require(block.timestamp > current_stake.unlockTime, "Still under lock");
        require(
            current_stake.amount >= _amount,
            "Can't withdraw more than staked"
        );

        uint8 NftBoost = boost[_msgSender()].boostValue;
        uint256 reward = calculateStakeReward(current_stake, NftBoost);
        current_stake.amount = current_stake.amount - _amount;
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[_index];
        } else {
            stakeholders[user_index]
                .address_stakes[_index]
                .amount = current_stake.amount;
            // Reset timer for reward calculation
            stakeholders[user_index].address_stakes[_index].since = block
                .timestamp;
        }
        _withdrawAmountFromVault(_amount, current_stake.timeLock);
        return reward;
    }

    /**
     * @notice Remove the selected amount from the selected vault;
     * @param _amount Amount to be removed;
     * @param _timelock Vault to remove the amount from (0 | 1 | 3 | 6 | 12);
     */
    function _withdrawAmountFromVault(uint256 _amount, uint8 _timelock)
        private
    {
        uint8 vaultIndex = _getIndexFromTimelock(_timelock);
        vaults[vaultIndex].totalAmountLock -= _amount;
    }

    /***********************************************************************************
                                    NFT BOOST FUNCTIONS
    ************************************************************************************/

    function setNftStatus(
        address _account,
        address _NftContractAddress,
        uint256 _tokenId,
        uint8 _NftBoost
    ) external {
        require(
            _msgSender() == owner() || _msgSender() == admin, // if set afterwards in case of transfer/sale
            "Not authorized"
        );
        require(_NftBoost <= 10, "Wrong boost amount"); // Prevent abuse if logic flaw
        // If never staked, initialized user first:
        if (stakes[_account] == 0) {
            _addStakeholder(_account);
        }
        _setNftStatus(_account, _NftContractAddress, _tokenId, _NftBoost);
    }

    function resetNftStatus(address _account) external {
        require(
            _account == _msgSender() || _msgSender() == admin,
            "Not authorized"
        );
        _resetNftStatus(_account);
    }

    function _setNftStatus(
        address _account,
        address _NftContractAddress,
        uint256 _tokenId,
        uint8 _NftBoost
    ) private {
        boost[_account].isBoost = true;
        boost[_account].NftContractAddress = _NftContractAddress;
        boost[_account].tokenId = _tokenId;
        boost[_account].boostValue = _NftBoost;
        boost[_account].since = block.timestamp;
    }

    function _resetNftStatus(address _account) private {
        boost[_account].isBoost = false;
        boost[_account].NftContractAddress = address(0);
        boost[_account].tokenId = 0;
        boost[_account].boostValue = 0;
        boost[_account].since = 0;
    }

    /***********************************************************************************
                                    VIEW FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow to check if a account has stakes and to return the total amount along with all the seperate stakes
     */
    function hasStake(address _staker)
        external
        view
        returns (StakingSummary memory)
    {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(
            0,
            stakeholders[stakes[_staker]].address_stakes
        );
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint8 NftBoost = boost[_staker].boostValue;
            uint256 availableReward = calculateStakeReward(
                summary.stakes[s],
                NftBoost
            );
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    /**
     * @notice Allow to to quickly fetch the total amount of tokens staked on the contract;
     */
    function getTotalStaked() external view returns (uint256) {
        uint256 totalStaked = 0;

        for (uint256 i = 0; i < vaults.length; i++) {
            totalStaked += vaults[i].totalAmountLock;
        }

        return totalStaked;
    }

    /***********************************************************************************
                                    RESTRICTED FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Allow to pause staking/withawal in case of emergency;
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allow to unpause staking/withawal if paused;
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Staking: zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit NewAdminSet(oldAdmin, _newAdmin);
    }

    event NewAdminSet(address indexed oldAdmin, address indexed newAdmin);

    function setToken(IERC20 _newToken) external onlyOwner {
        IERC20 oldToken = token;
        token = _newToken;
        emit NewTokenSet(oldToken, _newToken);
    }

    event NewTokenSet(IERC20 indexed oldToken, IERC20 indexed newToken);

    /**
     * @notice The following functions allow to change the APR per lock duration;
     * @param _newApr Percent interest per year. MUST BE AN INTEGER. Will be divided by 10,000,000 to get the %/day;
     * @param _timelock Indicate the lock duration: 0 | 3 | 6 | 12 (months);
     */
    function setAPR(uint8 _newApr, uint8 _timelock) external onlyOwner {
        vaults[_getIndexFromTimelock(_timelock)].apr = _newApr;
        emit NewAprSet(_newApr, _timelock);
    }

    event NewAprSet(uint8 _newApr, uint8 _timelock);

    /***********************************************************************************
                                    PRIVATE FUNCTIONS
    ************************************************************************************/

    function _initializeVaults() private {
        vaults[0] = Vault({timelock: 0, apr: 2, totalAmountLock: 0});
        vaults[1] = Vault({timelock: 91 days, apr: 4, totalAmountLock: 0});
        vaults[2] = Vault({timelock: 182 days, apr: 6, totalAmountLock: 0});
        vaults[3] = Vault({timelock: 364 days, apr: 8, totalAmountLock: 0});
    }

    /**
     * @notice Add a stakeholder to the "stakeholders" array
     */
    function _addStakeholder(address staker) private returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;

        _resetNftStatus(staker);

        return userIndex;
    }

    /**
     * @notice Calculate how much a user should be rewarded for his stakes
     * @return reward Amount won based on: vault APR, NFT boost (if any), number of days, amount staked;
     */
    function calculateStakeReward(Stake memory _current_stake, uint8 _NftBoost)
        private
        view
        returns (uint256)
    {
        uint256 reward = 0;
        uint8 vaultIndex = _getIndexFromTimelock(_current_stake.timeLock);
        uint256 apr = _getAprFromPercent(vaults[vaultIndex].apr);

        if (_current_stake.timeLock == 0) {
            if (_NftBoost != 0) {
                uint256 extraBoost = _getAprFromPercent(_NftBoost);
                if (boost[_current_stake.user].since > _current_stake.since) {
                    reward = apr + extraBoost;
                    uint256 boostReward = wmul(
                        (((block.timestamp - boost[_current_stake.user].since) /
                            1 days) * _current_stake.amount),
                        reward
                    );
                    uint256 noBoostReward = wmul(
                        (((boost[_current_stake.user].since -
                            _current_stake.since) / 1 days) *
                            _current_stake.amount),
                        apr
                    );
                    return boostReward + noBoostReward;
                } else {
                    reward = apr + extraBoost;
                }
            } else {
                reward = apr;
            }
        } else {
            reward = apr;
        }
        // Calculation: numbers of days * amount staked * APR
        return
            wmul(
                (((block.timestamp - _current_stake.since) / 1 days) *
                    _current_stake.amount),
                reward
            );
    }

    /***********************************************************************************
                                    UTILS FUNCTIONS
    ************************************************************************************/

    /**
     * @notice Return the vault index to get the stake corresponding the the selected vault (_timelock);
     */
    function _getIndexFromTimelock(uint8 _timelock)
        private
        pure
        returns (uint8)
    {
        if (_timelock == 0) return _timelock;
        else if (_timelock == 3) return 1;
        else if (_timelock == 6) return 2;
        else if (_timelock == 12) return 3;
        else revert("Staking: invalid lock");
    }

    function _getLockPeriod(uint8 _timelock) private view returns (uint256) {
        return vaults[_getIndexFromTimelock(_timelock)].timelock;
    }

    function _getAprFromPercent(uint16 _percent)
        private
        pure
        returns (uint256)
    {
        return wdiv(_percent * 274, 1e7); // eg: 5% APR == 0.0001370/day
    }
}

// SPDX-License-Identifier: MIT

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.16;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 private constant WAD = 10 ** 18;
    uint256 private constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}