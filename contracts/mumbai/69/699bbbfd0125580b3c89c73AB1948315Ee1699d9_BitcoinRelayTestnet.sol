// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./TypedMemView.sol";
import "../types/ScriptTypesEnum.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library BitcoinHelper {

    using SafeCast for uint96;
    using SafeCast for uint256;

    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 internal constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 internal constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 internal constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    enum BTCTypes {
        Unknown,            // 0x0
        CompactInt,         // 0x1
        ScriptSig,          // 0x2 - with length prefix
        Outpoint,           // 0x3
        TxIn,               // 0x4
        IntermediateTxIns,  // 0x5 - used in vin parsing
        Vin,                // 0x6
        ScriptPubkey,       // 0x7 - with length prefix
        PKH,                // 0x8 - the 20-byte payload digest
        WPKH,               // 0x9 - the 20-byte payload digest
        WSH,                // 0xa - the 32-byte payload digest
        SH,                 // 0xb - the 20-byte payload digest
        OpReturnPayload,    // 0xc
        TxOut,              // 0xd
        IntermediateTxOuts, // 0xe - used in vout parsing
        Vout,               // 0xf
        Header,             // 0x10
        HeaderArray,        // 0x11
        MerkleNode,         // 0x12
        MerkleStep,         // 0x13
        MerkleArray         // 0x14
    }

    /// @notice             requires `memView` to be of a specified type
    /// @dev                passes if it is the correct type, errors if not
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    modifier typeAssert(bytes29 memView, BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    // Revert with an error message re: non-minimal VarInts
    function revertNonMinimal(bytes29 ref) private pure returns (string memory) {
        (, uint256 g) = TypedMemView.encodeHex(ref.indexUint(0, ref.len().toUint8()));
        string memory err = string(
            abi.encodePacked(
                "Non-minimal var int. Got 0x",
                uint144(g)
            )
        );
        revert(err);
    }

    /// @notice             reads a compact int from the view at the specified index
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param _index       the index
    /// @return number      returns the compact int at the specified index
    function indexCompactInt(bytes29 memView, uint256 _index) internal pure returns (uint64 number) {
        uint256 flag = memView.indexUint(_index, 1);
        if (flag <= 0xfc) {
            return flag.toUint64();
        } else if (flag == 0xfd) {
            number = memView.indexLEUint(_index + 1, 2).toUint64();
            if (compactIntLength(number) != 3) {revertNonMinimal(memView.slice(_index, 3, 0));}
        } else if (flag == 0xfe) {
            number = memView.indexLEUint(_index + 1, 4).toUint64();
            if (compactIntLength(number) != 5) {revertNonMinimal(memView.slice(_index, 5, 0));}
        } else if (flag == 0xff) {
            number = memView.indexLEUint(_index + 1, 8).toUint64();
            if (compactIntLength(number) != 9) {revertNonMinimal(memView.slice(_index, 9, 0));}
        }
    }

    /// @notice         gives the total length (in bytes) of a CompactInt-encoded number
    /// @param number   the number as uint64
    /// @return         the compact integer length as uint8
    function compactIntLength(uint64 number) private pure returns (uint8) {
        if (number <= 0xfc) {
            return 1;
        } else if (number <= 0xffff) {
            return 3;
        } else if (number <= 0xffffffff) {
            return 5;
        } else {
            return 9;
        }
    }

    /// @notice             extracts the LE txid from an outpoint
    /// @param _outpoint    the outpoint
    /// @return             the LE txid
    function txidLE(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (bytes32) {
        return _outpoint.index(0, 32);
    }

    /// @notice                      Calculates the required transaction Id from the transaction details
    /// @dev                         Calculates the hash of transaction details two consecutive times
    /// @param _version              Version of the transaction
    /// @param _vin                  Inputs of the transaction
    /// @param _vout                 Outputs of the transaction
    /// @param _locktime             Lock time of the transaction
    /// @return                      Transaction Id of the transaction (in LE form)
    function calculateTxId(
        bytes4 _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes4 _locktime
    ) internal pure returns (bytes32) {
        bytes32 inputHash1 = sha256(abi.encodePacked(_version, _vin, _vout, _locktime));
        bytes32 inputHash2 = sha256(abi.encodePacked(inputHash1));
        return inputHash2;
    }

    /// @notice                      Reverts a Bytes32 input
    /// @param _input                Bytes32 input that we want to revert
    /// @return                      Reverted bytes32
    function reverseBytes32(bytes32 _input) private pure returns (bytes32) {
        bytes memory temp;
        bytes32 result;
        for (uint i = 0; i < 32; i++) {
            temp = abi.encodePacked(temp, _input[31-i]);
        }
        assembly {
            result := mload(add(temp, 32))
        }
        return result;
    }

    /// @notice                           Parses outpoint info from an input
    /// @dev                              Reverts if vin is null
    /// @param _vin                       The vin of a Bitcoin transaction
    /// @param _index                     Index of the input that we are looking at
    /// @return _txId                     Output tx id
    /// @return _outputIndex              Output tx index
    function extractOutpoint(
        bytes memory _vin, 
        uint _index
    ) internal pure returns (bytes32 _txId, uint _outputIndex) {
        bytes29 vin = tryAsVin(_vin.ref(uint40(BTCTypes.Unknown)));
        require(!vin.isNull(), "BitcoinHelper: vin is null");
        bytes29 input = indexVin(vin, _index);
        bytes29 _outpoint = outpoint(input);
        _txId = txidLE(_outpoint);
        _outputIndex = outpointIdx(_outpoint);
    }

    /// @notice             extracts the index as an integer from the outpoint
    /// @param _outpoint    the outpoint
    /// @return             the index
    function outpointIdx(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (uint32) {
        return _outpoint.indexLEUint(32, 4).toUint32();
    }

    /// @notice          extracts the outpoint from an input
    /// @param _input    the input
    /// @return          the outpoint as a typed memory
    function outpoint(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        return _input.slice(0, 36, uint40(BTCTypes.Outpoint));
    }

    /// @notice           extracts the script sig from an input
    /// @param _input     the input
    /// @return           the script sig as a typed memory
    function scriptSig(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_input, 36);
        return _input.slice(36, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptSig));
    }

    /// @notice         determines the length of the first input in an array of inputs
    /// @param _inputs  the vin without its length prefix
    /// @return         the input length
    function inputLength(bytes29 _inputs) private pure typeAssert(_inputs, BTCTypes.IntermediateTxIns) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_inputs, 36);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 36 + 4;
    }

    /// @notice         extracts the input at a specified index
    /// @param _vin     the vin
    /// @param _index   the index of the desired input
    /// @return         the desired input
    function indexVin(bytes29 _vin, uint256 _index) internal pure typeAssert(_vin, BTCTypes.Vin) returns (bytes29) {
        uint256 _nIns = uint256(indexCompactInt(_vin, 0));
        uint256 _viewLen = _vin.len();
        require(_index < _nIns, "Vin read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nIns)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }

        _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
        uint256 _len = inputLength(_remaining);
        return _vin.slice(_offset, _len, uint40(BTCTypes.TxIn));
    }

    /// @notice         extracts the value from an output
    /// @param _output  the output
    /// @return         the value
    function value(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (uint64) {
        return _output.indexLEUint(0, 8).toUint64();
    }

    /// @notice                   Finds the value of a specific output
    /// @dev                      Reverts if vout is null
    /// @param _vout              The vout of a Bitcoin transaction
    /// @param _index             Index of output
    /// @return _value            Value of the specified output
    function parseOutputValue(bytes memory _vout, uint _index) internal pure returns (uint64 _value) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output;
        output = indexVout(voutView, _index);
        _value = value(output);
    }

    /// @notice                   Finds total outputs value
    /// @dev                      Reverts if vout is null
    /// @param _vout              The vout of a Bitcoin transaction
    /// @return _totalValue       Total vout value
    function parseOutputsTotalValue(bytes memory _vout) internal pure returns (uint64 _totalValue) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _totalValue = _totalValue + value(output);
        }
    }

    /// @notice                           Parses the BTC amount that has been sent to 
    ///                                   a specific script in a specific output
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _voutIndex                 Index of the output that we are looking at
    /// @param _script                    Desired recipient script
    /// @param _scriptType                Type of the script (e.g. P2PK)
    /// @return bitcoinAmount             Amount of BTC have been sent to the _script
    function parseValueFromSpecificOutputHavingScript(
        bytes memory _vout,
        uint _voutIndex,
        bytes memory _script,
        ScriptTypes _scriptType
    ) internal pure returns (uint64 bitcoinAmount) {

        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");
        bytes29 output = indexVout(voutView, _voutIndex);
        bytes29 _scriptPubkey = scriptPubkey(output);
        
        if (_scriptType == ScriptTypes.P2TR) {
            // note: first two bytes are OP_1 and Pushdata Bytelength. 
            // note: script hash length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(2, 32))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2PK) {
            // note: first byte is Pushdata Bytelength. 
            // note: public key length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(1, 32))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2PKH) { 
            // note: first three bytes are OP_DUP, OP_HASH160, Pushdata Bytelength. 
            // note: public key hash length is 20.         
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(3))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2SH) {
            // note: first two bytes are OP_HASH160, Pushdata Bytelength
            // note: script hash length is 20.                      
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(2))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2WPKH) {               
            // note: first two bytes are OP_0, Pushdata Bytelength
            // note: segwit public key hash length is 20. 
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.indexAddress(2))) ? value(output) : 0;
        } else if (_scriptType == ScriptTypes.P2WSH) {
            // note: first two bytes are OP_0, Pushdata Bytelength 
            // note: segwit script hash length is 32.           
            bitcoinAmount = keccak256(_script) == keccak256(abi.encodePacked(_scriptPubkey.index(2, 32))) ? value(output) : 0;
        }
        
    }

    /// @notice                           Parses the BTC amount of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Returns zero if no matching locking scrip is found
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    function parseValueHavingLockingScript(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        
        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);

            if (
                keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
            ) {
                bitcoinAmount = value(output);
                // Stops searching after finding the desired locking script
                break;
            }
        }
    }

    /// @notice                           Parses the BTC amount and the op_return of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Assumes that payload size is less than 76 bytes
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    /// @return arbitraryData             Opreturn  data of the transaction
    function parseValueAndDataHavingLockingScriptSmallPayload(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount, bytes memory arbitraryData) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        bytes29 _scriptPubkeyWithLength;
        bytes29 _arbitraryData;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);
            _scriptPubkeyWithLength = scriptPubkeyWithLength(output);
            _arbitraryData = opReturnPayloadSmall(_scriptPubkeyWithLength);

            // Checks whether the output is an arbitarary data or not
            if(_arbitraryData == TypedMemView.NULL) {
                // Output is not an arbitrary data
                if (
                    keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
                ) {
                    bitcoinAmount = value(output);
                }
            } else {
                // Returns the whole bytes array
                arbitraryData = _arbitraryData.clone();
            }
        }
    }

    /// @notice                           Parses the BTC amount and the op_return of a transaction
    /// @dev                              Finds the BTC amount that has been sent to the locking script
    ///                                   Assumes that payload size is greater than 75 bytes
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _lockingScript             Desired locking script
    /// @return bitcoinAmount             Amount of BTC have been sent to the _lockingScript
    /// @return arbitraryData             Opreturn  data of the transaction
    function parseValueAndDataHavingLockingScriptBigPayload(
        bytes memory _vout,
        bytes memory _lockingScript
    ) internal view returns (uint64 bitcoinAmount, bytes memory arbitraryData) {
        // Checks that vout is not null
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!voutView.isNull(), "BitcoinHelper: vout is null");

        bytes29 output;
        bytes29 _scriptPubkey;
        bytes29 _scriptPubkeyWithLength;
        bytes29 _arbitraryData;

        // Finds total number of outputs
        uint _numberOfOutputs = uint256(indexCompactInt(voutView, 0));

        for (uint index = 0; index < _numberOfOutputs; index++) {
            output = indexVout(voutView, index);
            _scriptPubkey = scriptPubkey(output);
            _scriptPubkeyWithLength = scriptPubkeyWithLength(output);
            _arbitraryData = opReturnPayloadBig(_scriptPubkeyWithLength);

            // Checks whether the output is an arbitarary data or not
            if(_arbitraryData == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                // Output is not an arbitrary data
                if (
                    keccak256(abi.encodePacked(_scriptPubkey.clone())) == keccak256(abi.encodePacked(_lockingScript))
                ) {
                    bitcoinAmount = value(output);
                }
            } else {
                // Returns the whole bytes array
                arbitraryData = _arbitraryData.clone();
            }
        }
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkey(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8 + compactIntLength(scriptLength), scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkeyWithLength(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice                           Parses locking script from an output
    /// @dev                              Reverts if vout is null
    /// @param _vout                      The vout of a Bitcoin transaction
    /// @param _index                     Index of the output that we are looking at
    /// @return _lockingScript            Parsed locking script
    function getLockingScript(
        bytes memory _vout, 
        uint _index
    ) internal view returns (bytes memory _lockingScript) {
        bytes29 vout = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        require(!vout.isNull(), "BitcoinHelper: vout is null");
        bytes29 output = indexVout(vout, _index);
        bytes29 _lockingScriptBytes29 = scriptPubkey(output);
        _lockingScript = _lockingScriptBytes29.clone();
    }

    /// @notice                   Returns number of outputs in a vout
    /// @param _vout              The vout of a Bitcoin transaction           
    function numberOfOutputs(bytes memory _vout) internal pure returns (uint _numberOfOutputs) {
        bytes29 voutView = tryAsVout(_vout.ref(uint40(BTCTypes.Unknown)));
        _numberOfOutputs = uint256(indexCompactInt(voutView, 0));
    }

    /// @notice             determines the length of the first output in an array of outputs
    /// @param _outputs     the vout without its length prefix
    /// @return             the output length
    function outputLength(bytes29 _outputs) private pure typeAssert(_outputs, BTCTypes.IntermediateTxOuts) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_outputs, 8);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 8;
    }

    /// @notice         extracts the output at a specified index
    /// @param _vout    the vout
    /// @param _index   the index of the desired output
    /// @return         the desired output
    function indexVout(bytes29 _vout, uint256 _index) internal pure typeAssert(_vout, BTCTypes.Vout) returns (bytes29) {
        uint256 _nOuts = uint256(indexCompactInt(_vout, 0));
        uint256 _viewLen = _vout.len();
        require(_index < _nOuts, "Vout read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nOuts)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }

        _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
        uint256 _len = outputLength(_remaining);
        return _vout.slice(_offset, _len, uint40(BTCTypes.TxOut));
    }

    /// @notice         extracts the Op Return Payload
    /// @dev            structure of the input is: 1 byte op return + 2 bytes indicating the length of payload + max length for op return payload is 80 bytes
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayloadBig(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = _spk.indexUint(3, 1).toUint64();
        if (_bodyLength > 83 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(3, 1) != _bodyLength - 3) {
            return TypedMemView.nullView();
        }
        return _spk.slice(4, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice         extracts the Op Return Payload
    /// @dev            structure of the input is: 1 byte op return + 1 bytes indicating the length of payload + max length for op return payload is 75 bytes
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayloadSmall(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = _spk.indexUint(2, 1).toUint64();
        if (_bodyLength > 77 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(2, 1) != _bodyLength - 2) {
            return TypedMemView.nullView();
        }
        return _spk.slice(3, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice     verifies the vin and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _vin the vin
    /// @return     the typed vin (or null if error)
    function tryAsVin(bytes29 _vin) internal pure typeAssert(_vin, BTCTypes.Unknown) returns (bytes29) {
        if (_vin.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nIns = indexCompactInt(_vin, 0);
        uint256 _viewLen = _vin.len();
        if (_nIns == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nIns));
        for (uint256 i = 0; i < _nIns; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vin.castTo(uint40(BTCTypes.Vin));
    }

    /// @notice         verifies the vout and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _vout    the vout
    /// @return         the typed vout (or null if error)
    function tryAsVout(bytes29 _vout) internal pure typeAssert(_vout, BTCTypes.Unknown) returns (bytes29) {
        if (_vout.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nOuts = indexCompactInt(_vout, 0);

        uint256 _viewLen = _vout.len();
        if (_nOuts == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nOuts));
        for (uint256 i = 0; i < _nOuts; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vout.castTo(uint40(BTCTypes.Vout));
    }

    /// @notice         verifies the header and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _header  the header
    /// @return         the typed header (or null if error)
    function tryAsHeader(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Unknown) returns (bytes29) {
        if (_header.len() != 80) {
            return TypedMemView.nullView();
        }
        return _header.castTo(uint40(BTCTypes.Header));
    }


    /// @notice         Index a header array.
    /// @dev            Errors on overruns
    /// @param _arr     The header array
    /// @param index    The 0-indexed location of the header to get
    /// @return         the typed header at `index`
    function indexHeaderArray(bytes29 _arr, uint256 index) internal pure typeAssert(_arr, BTCTypes.HeaderArray) returns (bytes29) {
        uint256 _start = index * 80;
        return _arr.slice(_start, 80, uint40(BTCTypes.Header));
    }


    /// @notice     verifies the header array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the header array
    /// @return     the typed header array (or null if error)
    function tryAsHeaderArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 80 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.HeaderArray));
    }

    /// @notice     verifies the merkle array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the merkle array
    /// @return     the typed merkle array (or null if error)
    function tryAsMerkleArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 32 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.MerkleArray));
    }

    /// @notice         extracts the merkle root from the header
    /// @param _header  the header
    /// @return         the merkle root
    function merkleRoot(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(36, 32);
    }

    /// @notice         extracts the target from the header
    /// @param _header  the header
    /// @return         the target
    function target(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        uint256 _mantissa = _header.indexLEUint(72, 3);
        require(_header.indexUint(75, 1) > 2, "ViewBTC: invalid target difficulty");
        uint256 _exponent = _header.indexUint(75, 1) - 3;
        return _mantissa * (256 ** _exponent);
    }

    /// @notice         calculates the difficulty from a target
    /// @param _target  the target
    /// @return         the difficulty
    function toDiff(uint256  _target) private pure returns (uint256) {
        return DIFF1_TARGET / (_target);
    }

    /// @notice         extracts the difficulty from the header
    /// @param _header  the header
    /// @return         the difficulty
    function diff(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        return toDiff(target(_header));
    }

    /// @notice         extracts the timestamp from the header
    /// @param _header  the header
    /// @return         the timestamp
    function time(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint32) {
        return uint32(_header.indexLEUint(68, 4));
    }

    /// @notice         extracts the parent hash from the header
    /// @param _header  the header
    /// @return         the parent hash
    function parent(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(4, 32);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header parent to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function checkParent(bytes29 _header, bytes32 _prevHeaderDigest) internal pure typeAssert(_header, BTCTypes.Header) returns (bool) {
        return parent(_header) == _prevHeaderDigest;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove( 
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes29 _intermediateNodes,
        uint _index
    ) internal view typeAssert(_intermediateNodes, BTCTypes.MerkleArray) returns (bool) {
        // Shortcut the empty-block case
        if (
            _txid == _merkleRoot &&
                _index == 0 &&
                    _intermediateNodes.len() == 0
        ) {
            return true;
        }

        return checkMerkle(_txid, _intermediateNodes, _merkleRoot, _index);
    }

    /// @notice         verifies a merkle proof
    /// @dev            leaf, proof, and root are in LE format
    /// @param _leaf    the leaf
    /// @param _proof   the proof nodes
    /// @param _root    the merkle root
    /// @param _index   the index
    /// @return         true if valid, false if otherwise
    function checkMerkle(
        bytes32 _leaf,
        bytes29 _proof,
        bytes32 _root,
        uint256 _index
    ) private view typeAssert(_proof, BTCTypes.MerkleArray) returns (bool) {
        uint256 nodes = _proof.len() / 32;
        if (nodes == 0) {
            return _leaf == _root;
        }

        uint256 _idx = _index;
        bytes32 _current = _leaf;

        for (uint i = 0; i < nodes; i++) {
            bytes32 _next = _proof.index(i * 32, 32);
            if (_idx % 2 == 1) {
                _current = merkleStep(_next, _current);
            } else {
                _current = merkleStep(_current, _next);
            }
            _idx >>= 1;
        }

        return _current == _root;
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @dev             Not recommended to call directly.
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return digest   The double-sha256 of the concatenated hashes
    function merkleStep(bytes32 _a, bytes32 _b) private view returns (bytes32 digest) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            pop(staticcall(gas(), 2, ptr, 0x40, ptr, 0x20)) // sha256 #1
            pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha256 #2
            digest := mload(ptr)
        }
    }

    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp - _firstTimestamp;

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD / 4) {
            _elapsedTime = RETARGET_PERIOD / 4;
        }
        if (_elapsedTime > RETARGET_PERIOD * 4) {
            _elapsedTime = RETARGET_PERIOD * 4;
        }

        /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
        uint256 _adjusted = _previousTarget / 65536 * _elapsedTime;
        return _adjusted / RETARGET_PERIOD * 65536;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

/** @author Summa (https://summa.one) */

/*
    Original version: https://github.com/summa-tx/memview-sol/blob/main/contracts/TypedMemView.sol
    We made few changes to the original version:
    1. Use solidity version 8 compiler
    2. Remove SafeMath library
    3. Add unchecked in line 522
*/

library TypedMemView {

    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.


    // The null view
    bytes29 internal constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
    uint8 constant TWELVE_BYTES = 96;

    /**
     * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _b    The byte
     * @return      char - The encoded hex character
     */
    function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
        // This can probably be done more efficiently, but it's only in error
        // paths, so we don't really care :)
        uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
        if (_nibble == 0xf0) {return 0x30;} // 0
        if (_nibble == 0xf1) {return 0x31;} // 1
        if (_nibble == 0xf2) {return 0x32;} // 2
        if (_nibble == 0xf3) {return 0x33;} // 3
        if (_nibble == 0xf4) {return 0x34;} // 4
        if (_nibble == 0xf5) {return 0x35;} // 5
        if (_nibble == 0xf6) {return 0x36;} // 6
        if (_nibble == 0xf7) {return 0x37;} // 7
        if (_nibble == 0xf8) {return 0x38;} // 8
        if (_nibble == 0xf9) {return 0x39;} // 9
        if (_nibble == 0xfa) {return 0x61;} // a
        if (_nibble == 0xfb) {return 0x62;} // b
        if (_nibble == 0xfc) {return 0x63;} // c
        if (_nibble == 0xfd) {return 0x64;} // d
        if (_nibble == 0xfe) {return 0x65;} // e
        if (_nibble == 0xff) {return 0x66;} // f
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     *              `the first 8 bits of encoded is the nibbleHex of top 4 bits of _b`
     *              `the second 8 bits of encoded is the nibbleHex of lower 4 bits of _b`
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
        for (uint8 i = 31; i > 15; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
        }

        unchecked {
            // abusing underflow here =_=
            for (uint8 i = 15; i < 255 ; i -= 1) {
                uint8 _byte = uint8(_b >> (i * 8));
                second |= byteHex(_byte);
                if (i != 0) {
                    second <<= 16;
                }
            }
        }
        
    }

    /**
     * @notice          Changes the endianness of a uint256.
     * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
     * @param _b        The unsigned integer to reverse
     * @return          v - The reversed value
     */
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
        ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
        ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
        ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
        ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            mask := sar(
            sub(_len, 1),
            0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice      Return the null view.
     * @return      bytes29 - The null view
     */
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /**
     * @notice      Check if the view is null.
     * @return      bool - True if the view is null
     */
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /**
     * @notice      Check if the view is not null.
     * @return      bool - True if the view is not null
     */
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /**
     * @notice          Check if the view is of a valid type and points to a valid location
     *                  in memory.
     * @dev             We perform this check by examining solidity's unallocated memory
     *                  pointer and ensuring that the view's upper bound is less than that.
     * @param memView   The view
     * @return          ret - True if the view is valid
     */
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) {return false;}
        uint256 _end = end(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ret := not(gt(_end, mload(0x40)))
        }
    }

    /**
     * @notice          Require that a typed memory view be valid.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @return          bytes29 - The validated view
     */
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /**
     * @notice          Return true if the memview is of the expected type. Otherwise false.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bool - True if the memview is of the expected type
     */
    function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
        return typeOf(memView) == _expected;
    }

    /**
     * @notice          Require that a typed memory view has a specific type.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bytes29 - The view with validated type
     */
    function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /**
     * @notice          Return an identical view with a different type.
     * @param memView   The view
     * @param _newType  The new type
     * @return          newView - The new view with the specified type
     */
    function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
        // then | in the new type
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // shift off the top 5 bytes
            newView := or(newView, shr(40, shl(40, memView)))
            newView := or(newView, shl(216, _newType))
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(uint256 _type, uint256 _loc, uint256 _len) private pure returns (bytes29 newView) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            newView := shl(96, or(newView, _type)) // insert type
            newView := shl(96, or(newView, _loc))  // insert loc
            newView := shl(24, or(newView, _len))  // empty bottom 3 bytes
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(uint256 _type, uint256 _loc, uint256 _len) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
        uint256 _len = arr.length;

        uint256 _loc;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            _loc := add(arr, 0x20)  // our view is of the data, not the struct
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the associated type information.
     * @param memView   The memory view
     * @return          _type - The type associated with the view
     */
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // 216 == 256 - 40
            _type := shr(216, memView) // shift out lower (12 + 12 + 3) bytes
        }
    }

    /**
     * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the 5-byte type flag is equal
     */
    function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
        // XOR the inputs to check their difference
        return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
            _loc := and(shr(120, memView), _mask)
        }
    }

    /**
     * @notice          The number of memory words this memory view occupies, rounded up.
     * @param memView   The view
     * @return          uint256 - The number of memory words
     */
    function words(bytes29 memView) internal pure returns (uint256) {
        return (uint256(len(memView)) + 32) / 32;
    }

    /**
     * @notice          The in-memory footprint of a fresh copy of the view.
     * @param memView   The view
     * @return          uint256 - The in-memory footprint of a fresh copy of the view.
     */
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            _len := and(shr(24, memView), _mask)
        }
    }

    /**
     * @notice          Returns the endpoint of `memView`.
     * @param memView   The view
     * @return          uint256 - The endpoint of `memView`
     */
    function end(bytes29 memView) internal pure returns (uint256) {
        return loc(memView) + len(memView);
    }

    /**
     * @notice          Safe slicing without memory modification.
     * @param memView   The view
     * @param _index    The start index
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function slice(bytes29 memView, uint256 _index, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc + _index + _len > end(memView)) {
            return NULL;
        }

        _loc = _loc + _index;
        return build(newType, _loc, _len);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function prefix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the last `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function postfix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)) - _len, _len, newType);
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The 32 byte result
     */
    function index(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (bytes32 result) {
        if (_bytes == 0) {return bytes32(0);}
        if (_index + _bytes > len(memView)) {
            revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
        }
        require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

        unchecked {
            uint8 bitLength = _bytes * 8;
            uint256 _loc = loc(memView);
            uint256 _mask = leftMask(bitLength);
            assembly {
                // solium-disable-previous-line security/no-inline-assembly
                result := and(mload(add(_loc, _index)), _mask)
            }   
        }

    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view has >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The unsigned integer
     */
    function indexUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /**
     * @notice          Parse an unsigned integer from LE bytes.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes length
     * @return          result - The unsigned integer
     */
    function indexLEUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /**
     * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
     *                  following that index.
     * @param memView   The view
     * @param _index    The index
     * @return          address - The address
     */
    function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
        return address(uint160(indexUint(memView, _index, 20)));
    }

    /**
     * @notice          Return the keccak256 hash of the underlying memory
     * @param memView   The view
     * @return          digest - The keccak256 hash of the underlying memory
     */
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /**
     * @notice          Return the sha2 digest of the underlying memory.
     * @dev             We explicitly deallocate memory afterwards.
     * @param memView   The view
     * @return          digest - The sha2 hash of the underlying memory
     */
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
            digest := mload(ptr)
        }
    }

    /**
     * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
     * @param memView   The pre-image
     * @return          digest - the Digest
     */
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
            pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
    }

    /**
     * @notice          Implements bitcoin's hash256 (double sha2)
     * @param memView   A view of the preimage
     * @return          digest - the Digest
     */
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
            pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
    }

    /**
     * @notice          Return true if the underlying memory is equal. Else false.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the underlying memory is equal
     */
    function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
    }

    /**
     * @notice          Return false if the underlying memory is equal. Else true.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - False if the underlying memory is equal
     */
    function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !untypedEqual(left, right);
    }

    /**
     * @notice          Compares type equality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are the same
     */
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /**
     * @notice          Compares type inequality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are not the same
     */
    function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !equal(left, right);
    }

    /**
     * @notice          Copy the view to a location, return an unsafe memory reference
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memView   The view
     * @param _newLoc   The new location
     * @return          written - the unsafe memory reference
     */
    function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
        require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
        require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40)
        // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20) // empty revert message
            }

        // use the identity precompile to copy
        // guaranteed not to fail, so pop the success
            pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
        }

        written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /**
     * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
     *                  the new memory
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param memView   The view
     * @return          ret - The view pointing to the new memory
     */
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        unsafeCopyTo(memView, ptr + 0x20);
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /**
     * @notice          Join the views in memory, return an unsafe reference to the memory.
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memViews  The views
     * @return          unsafeView - The conjoined view pointing to the new memory
     */
    function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
        // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20) // empty revert message
            }
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i ++) {
            bytes29 memView = memViews[i];
            unsafeCopyTo(memView, _location + _offset);
            _offset += len(memView);
        }
        unsafeView = unsafeBuildUnchecked(0, _location, _offset);
    }

    /**
     * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The keccak256 digest
     */
    function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The sha256 digest
     */
    function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          copies all views, joins them into a new bytearray.
     * @param memViews  The views
     * @return          ret - The new byte array
     */
    function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
        uint256 ptr;
        assembly {
        // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView = unsafeJoin(memViews, ptr + 0x20);
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
        // solium-disable-previous-line security/no-inline-assembly
        // store the legnth
            mstore(ptr, _written)
        // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "../libraries/TypedMemView.sol";
import "../libraries/BitcoinHelper.sol";
import "./interfaces/IBitcoinRelay.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BitcoinRelay is IBitcoinRelay, Ownable, ReentrancyGuard, Pausable {

    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using BitcoinHelper for bytes29;
    using SafeERC20 for IERC20;

    // Public variables
    uint constant ONE_HUNDRED_PERCENT = 10000;
    uint constant MAX_FINALIZATION_PARAMETER = 432; // roughly 3 days
    uint constant MAX_ALLOWED_GAP = 90 minutes;
    // ^ This is to prevent the submission of a Bitcoin block header with a timestamp 
    // that is more than 90 minutes ahead of the network's timestamp. Without this check,
    // the attacker could manipulate the difficulty target of a new epoch

    uint public override initialHeight;
    uint public override lastSubmittedHeight;
    uint public override finalizationParameter;
    uint public override rewardAmountInTDT;
    uint public override relayerPercentageFee; // A number between [0, 10000)
    uint public override submissionGasUsed; // Gas used for submitting a block header
    uint public override epochLength;
    uint public override baseQueries;
    uint public override currentEpochQueries;
    uint public override lastEpochQueries;
    address public override TeleportDAOToken;
    bytes32 public override relayGenesisHash; // Initial block header of relay

    // Private and internal variables
    mapping(uint => blockHeader[]) private chain; // height => list of block headers
    mapping(bytes32 => bytes32) internal previousBlock; // block header hash => parent header hash
    mapping(bytes32 => uint256) internal blockHeight; // block header hash => block height

    /// @notice Gives a starting point for the relay
    /// @param  _genesisHeader The starting header
    /// @param  _height The starting height
    /// @param  _periodStart The hash of the first header in the genesis epoch
    /// @param  _TeleportDAOToken The address of the TeleportDAO ERC20 token contract
    constructor(
        bytes memory _genesisHeader,
        uint256 _height,
        bytes32 _periodStart,
        address _TeleportDAOToken
    ) {
        // Adds the initial block header to the chain
        bytes29 _genesisView = _genesisHeader.ref(0).tryAsHeader();
        require(_genesisView.notNull(), "BitcoinRelay: null block");
        // Genesis header and period start can be same
        bytes32 _genesisHash = _genesisView.hash256();
        relayGenesisHash = _genesisHash;
        blockHeader memory newBlockHeader;
        newBlockHeader.selfHash = _genesisHash;
        newBlockHeader.parentHash = _genesisView.parent();
        newBlockHeader.merkleRoot = _genesisView.merkleRoot();
        newBlockHeader.relayer = _msgSender();
        newBlockHeader.gasPrice = 0;
        chain[_height].push(newBlockHeader);
        blockHeight[_genesisHash] = _height;
        blockHeight[_periodStart] = _height - (_height % BitcoinHelper.RETARGET_PERIOD_BLOCKS);

        // Relay parameters
        _setFinalizationParameter(3);
        initialHeight = _height;
        lastSubmittedHeight = _height;
        
        _setTeleportDAOToken(_TeleportDAOToken);
        _setRelayerPercentageFee(500);
        _setEpochLength(BitcoinHelper.RETARGET_PERIOD_BLOCKS);
        _setBaseQueries(epochLength);
        lastEpochQueries = baseQueries;
        currentEpochQueries = 0;
        _setSubmissionGasUsed(300000); // in wei
    }

    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice Pauses the Relay
    /// @dev Only functions with whenPaused modifier can be called
    function pauseRelay() external override onlyOwner {
        _pause();
    }

    /// @notice Unpauses the relay
    /// @dev Only functions with whenNotPaused modifier can be called
    function unpauseRelay() external override onlyOwner {
        _unpause();
    }

    /// @notice Getter for a specific block header's hash in the stored chain
    /// @dev It cannot be called by other contracts
    /// @param  _height of the desired block header
    /// @param  _index of the desired block header in that height
    /// @return Block header's hash
    function getBlockHeaderHash(uint _height, uint _index) external view override returns (bytes32) {
        require(
            !Address.isContract(msg.sender), 
            "BitcoinRelay: addr is contract"
        );
        return chain[_height][_index].selfHash;
    }

    /// @notice Getter for a specific block header submission gas price
    /// @param  _height of the desired block header
    /// @param  _index of the desired block header in that height
    /// @return Block header submission gas price
    function getBlockHeaderFee(uint _height, uint _index) external view override returns (uint) {
        return _calculateFee(chain[_height][_index].gasPrice);
    }

    /// @notice Getter for the number of submitted block headers in a height
    /// @dev This shows the number of temporary forks in that specific height
    /// @param  _height The desired height of the blockchain
    /// @return Number of block headers stored in a height
    function getNumberOfSubmittedHeaders(uint _height) external view override returns (uint) {
        return chain[_height].length;
    }

    /// @notice Getter for available TDT in Relay treasury
    function availableTDT() external view override returns (uint) {
        return IERC20(TeleportDAOToken).balanceOf(address(this));
    }

    /// @notice Getter for available target native token (TNT) in Relay treasury
    function availableTNT() external view override returns (uint) {
        return address(this).balance;
    }

    /// @notice Finds the height of a header by its hash
    /// @dev Fails if the header is unknown
    /// @param _hash The header hash to search for
    /// @return The height of the header
    function findHeight(bytes32 _hash) external view override returns (uint256) {
        return _findHeight(_hash);
    }

    /// @notice External setter for rewardAmountInTDT
    /// @dev This award is for the Relayer who submitted a finalized block header
    /// @param _rewardAmountInTDT The amount of reward in TDT
    function setRewardAmountInTDT(uint _rewardAmountInTDT) external override onlyOwner {
        _setRewardAmountInTDT(_rewardAmountInTDT);
    }

    /// @notice External setter for finalizationParameter
    /// @dev Bigger finalization parameter increases security but also increases the delay
    /// @param _finalizationParameter The finalization parameter of Bitcoin
    function setFinalizationParameter(uint _finalizationParameter) external override onlyOwner {
        _setFinalizationParameter(_finalizationParameter);
    }

    /// @notice External setter for relayerPercentageFee
    /// @dev A percentage of the submission gas used goes to Relayers as reward
    /// @param _relayerPercentageFee New percentage fee
    function setRelayerPercentageFee(uint _relayerPercentageFee) external override onlyOwner {
        _setRelayerPercentageFee(_relayerPercentageFee);
    }

    /// @notice External setter for TeleportDAO token
    /// @param _TeleportDAOToken The TeleportDAO token (TDT) address
    function setTeleportDAOToken(address _TeleportDAOToken) external override onlyOwner {
        _setTeleportDAOToken(_TeleportDAOToken);
    }

    /// @notice External setter for epochLength
    /// @param _epochLength The length of epochs used for estimating the query fee
    function setEpochLength(uint _epochLength) external override onlyOwner {
        _setEpochLength(_epochLength);
    }

    /// @notice External setter for baseQueries
    /// @param _baseQueries The base number of queries we assume in each epoch
    ///                     This prevents query fee to grow significantly
    function setBaseQueries(uint _baseQueries) external override onlyOwner {
        _setBaseQueries(_baseQueries);
    }

    /// @notice External setter for submissionGasUsed
    /// @param _submissionGasUsed The gas used by Relayers for submitting a block header
    function setSubmissionGasUsed(uint _submissionGasUsed) external override onlyOwner {
        _setSubmissionGasUsed(_submissionGasUsed);
    }

    /// @notice Checks if a tx is included and finalized on Bitcoin
    /// @dev Checks if the block is finalized, and Merkle proof is valid
    /// @param _txid Desired tx Id in LE form
    /// @param _blockHeight of the desired tx
    /// @param _intermediateNodes Part of the Merkle tree from the tx to the root in LE form (called Merkle proof)
    /// @param _index of the tx in Merkle tree
    /// @return True if the provided tx is confirmed on Bitcoin
    function checkTxProof (
        bytes32 _txid, // In LE form
        uint _blockHeight,
        bytes calldata _intermediateNodes, // In LE form
        uint _index
    ) external payable nonReentrant whenNotPaused override returns (bool) {
        require(_txid != bytes32(0), "BitcoinRelay: txid should be non-zero");
        // Revert if the block is not finalized
        require(
            _blockHeight + finalizationParameter < lastSubmittedHeight + 1,
            "BitcoinRelay: block is not finalized on the relay"
        );
        // Block header exists on the relay
        require(
            _blockHeight >= initialHeight,
            "BitcoinRelay: the requested height is not submitted on the relay (too old)"
        );

        // Get the Relay fee from the user
        uint paidFee = _getFee(chain[_blockHeight][0].gasPrice);
        
        // Check the inclusion of the transaction
        bytes32 _merkleRoot = chain[_blockHeight][0].merkleRoot;
        bytes29 intermediateNodes = _intermediateNodes.ref(0).tryAsMerkleArray(); // Check for errors if any
        
        emit NewQuery(_txid, _blockHeight, paidFee); 
        return BitcoinHelper.prove(_txid, _merkleRoot, intermediateNodes, _index);   
    }

    /// @notice Same as getBlockHeaderHash, but can be called by other contracts
    /// @dev Caller should pay the query fee
    function getBlockHeaderHashContract(uint _height, uint _index) external payable override returns (bytes32) {
        uint paidFee = _getFee(chain[_height][_index].gasPrice);
        emit NewQuery(chain[_height][_index].selfHash, _height, paidFee); 
        return chain[_height][_index].selfHash;
    }

    /// @notice Adds headers to storage after validating
    /// @dev Checks integrity and consistency of the header chain
    /// @param _anchor The header immediately preceeding the new chain
    /// @param _headers A tightly-packed list of 80-byte Bitcoin headers
    /// @return True if successfully written, error otherwise
    function addHeaders(
        bytes calldata _anchor, 
        bytes calldata _headers
    ) external nonReentrant whenNotPaused override returns (bool) {
        bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
        bytes29 _anchorView = _anchor.ref(0).tryAsHeader();

        _checkInputSizeAddHeaders(_headersView, _anchorView);

        return _addHeaders(_anchorView, _headersView, false);
    }

    /// @notice Adds headers to storage, performs additional validation of retarget
    /// @dev Checks the retarget, the heights, and the linkage
    /// @param _oldPeriodStartHeader The first header in the difficulty period being closed
    /// @param _oldPeriodEndHeader The last header in the difficulty period being closed (anchor of new headers)
    /// @param _headers A tightly-packed list of 80-byte Bitcoin headers
    /// @return True if successfully written, error otherwise
    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external nonReentrant whenNotPaused override returns (bool) {
        bytes29 _oldStart = _oldPeriodStartHeader.ref(0).tryAsHeader();
        bytes29 _oldEnd = _oldPeriodEndHeader.ref(0).tryAsHeader();
        bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();

        _checkInputSizeAddHeadersWithRetarget(_oldStart, _oldEnd, _headersView);

        return _addHeadersWithRetarget(_oldStart, _oldEnd, _headersView);
    }

    /// @notice Same as addHeaders, but can only be called by owner even if contract is paused
    ///         It will be used if a fork happend
    function ownerAddHeaders(
        bytes calldata _anchor, 
        bytes calldata _headers
    ) external nonReentrant onlyOwner override returns (bool) {
        bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
        bytes29 _anchorView = _anchor.ref(0).tryAsHeader();

        _checkInputSizeAddHeaders(_headersView, _anchorView);

        return _addHeaders(_anchorView, _headersView, false);
    }

    /// @notice Same as addHeadersWithRetarget, but can only be called by owner even if contract is paused
    ///         It will be used if a fork happend
    function ownerAddHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external nonReentrant onlyOwner override returns (bool) {
        bytes29 _oldStart = _oldPeriodStartHeader.ref(0).tryAsHeader();
        bytes29 _oldEnd = _oldPeriodEndHeader.ref(0).tryAsHeader();
        bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();

        _checkInputSizeAddHeadersWithRetarget(_oldStart, _oldEnd, _headersView);

        return _addHeadersWithRetarget(_oldStart, _oldEnd, _headersView);
    }

    /// @notice  Checks the size of addHeaders inputs 
    function _checkInputSizeAddHeaders(bytes29 _headersView, bytes29 _anchorView) internal pure {
        require(
            _headersView.notNull() && _headersView.len() % 80 == 0
                && _anchorView.notNull() && _anchorView.len() == 80,
            "BitcoinRelay: wrong len"
        );
    }

    /// @notice Checks the size of addHeadersWithRetarget inputs 
    function _checkInputSizeAddHeadersWithRetarget(
        bytes29 _oldStart,
        bytes29 _oldEnd,
        bytes29 _headersView
    ) internal pure {
        require(
            _oldStart.notNull() && _oldStart.len() == 80 
                && _oldEnd.notNull() && _oldEnd.len() == 80 
                    && _headersView.notNull() && _headersView.len() % 80 == 0,
            "BitcoinRelay: wrong len"
        );
    }

    /// @notice Finds the height of a header by its hash
    /// @dev Reverts if the header is unknown
    /// @param _hash of the desired header
    /// @return The height of the header
    function _findHeight(bytes32 _hash) internal view returns (uint256) {
        if (blockHeight[_hash] == 0) {
            revert("BitcoinRelay: unknown block");
        }
        else {
            return blockHeight[_hash];
        }
    }

    /// @notice Gets fee from the user who queries the Relay
    /// @dev Fee is paid in target blockchain native token (called TNT)
    /// @param _gasPrice has been used for submitting the block header
    /// @return _feeAmount Needed fee
    function _getFee(uint _gasPrice) internal returns (uint _feeAmount) {
        // Count the query for next epoch fee calculation
        currentEpochQueries += 1;
        _feeAmount = _calculateFee(_gasPrice);
        require(msg.value >= _feeAmount, "BitcoinRelay: fee is not enough");
        Address.sendValue(payable(_msgSender()), msg.value - _feeAmount);
    }

    /// @notice Calculates the fee of querying a block header
    /// @param _gasPrice has been used for submitting the block header
    /// @return The fee amount 
    function _calculateFee(uint _gasPrice) private view returns (uint) {
        return (submissionGasUsed * _gasPrice * (ONE_HUNDRED_PERCENT + relayerPercentageFee) * epochLength) 
            / lastEpochQueries / ONE_HUNDRED_PERCENT;
    }

    /// @notice Adds headers to storage after validating
    function _addHeaders(bytes29 _anchor, bytes29 _headers, bool _internal) internal virtual returns (bool) {
        // Extract basic info
        bytes32 _previousHash = _anchor.hash256();
        uint256 _anchorHeight = _findHeight(_previousHash); // revert if the block is unknown
        uint256 _target = _headers.indexHeaderArray(0).target();

        // When calling addHeaders, no retargetting should happen
        require(
            _internal || _anchor.target() == _target,
            "BitcoinRelay: unexpected retarget on external call"
        );
        // check the height on top of the anchor is not finalized
        require(
            _anchorHeight + 1 + finalizationParameter > lastSubmittedHeight, 
            "BitcoinRelay: block headers are too old"
        );

        /*
            1. check that the blockheader is not a replica
            2. check blocks are in the same epoch regarding difficulty
            3. check that headers are in a coherent chain (no retargets, hash links good)
            4. check that the header has sufficient work
            5. Store the block connection
            6. Store the height
            7. store the block in the chain
        */
        uint256 _height;
        bytes32 _currentHash;
        for (uint256 i = 0; i < _headers.len() / 80; i++) {
            bytes29 _header = _headers.indexHeaderArray(i);
            _height = _anchorHeight + i + 1;
            _currentHash = _header.hash256();

            // The below check prevents adding a replicated block header
            require(
                previousBlock[_currentHash] == bytes32(0),
                "BitcoinRelay: the block header exists on the relay"
            );

            // Blocks that are multiplies of 2016 should be submitted using addHeadersWithRetarget
            require(
                _internal || _height % BitcoinHelper.RETARGET_PERIOD_BLOCKS != 0,
                "BitcoinRelay: headers should be submitted by calling addHeadersWithRetarget"
            );

            require(_header.time() < block.timestamp + MAX_ALLOWED_GAP, "BitcoinRelay: block is ahead in time");
            require(_header.target() == _target, "BitcoinRelay: target changed unexpectedly");
            require(_header.checkParent(_previousHash), "BitcoinRelay: headers do not form a consistent chain");
            
            require(
                TypedMemView.reverseUint256(uint256(_currentHash)) <= _target,
                "BitcoinRelay: header work is insufficient"
            );

            previousBlock[_currentHash] = _previousHash;
            blockHeight[_currentHash] = _height;
            emit BlockAdded(_height, _currentHash, _previousHash, _msgSender());
            _addToChain(_header, _height);
            _previousHash = _currentHash;
        }
        return true;
    }

    /// @notice Adds headers to storage, performs additional validation of retarget
    function _addHeadersWithRetarget(
        bytes29 _oldStart,
        bytes29 _oldEnd,
        bytes29 _headers
    ) internal virtual returns (bool) {
        // requires that both blocks are known
        uint256 _startHeight = _findHeight(_oldStart.hash256());
        uint256 _endHeight = _findHeight(_oldEnd.hash256());

        // retargets should happen at 2016 block intervals
        require(
            _endHeight % BitcoinHelper.RETARGET_PERIOD_BLOCKS == 2015,
            "BitcoinRelay: must provide the last header of the closing difficulty period");
        require(
            _endHeight == _startHeight + 2015,
            "BitcoinRelay: must provide exactly 1 difficulty period");
        require(
            _oldStart.diff() == _oldEnd.diff(),
            "BitcoinRelay: period header difficulties do not match");

        /* NB: This comparison looks weird because header nBits encoding truncates targets */
        bytes29 _newStart = _headers.indexHeaderArray(0);
        uint256 _actualTarget = _newStart.target();
        uint256 _expectedTarget = BitcoinHelper.retargetAlgorithm(
            _oldStart.target(),
            _oldStart.time(),
            _oldEnd.time()
        );
        require(
            (_actualTarget & _expectedTarget) == _actualTarget, 
            "BitcoinRelay: invalid retarget provided"
        );

        // Pass all but the first through to be added
        return _addHeaders(_oldEnd, _headers, true);
    }

    /// @notice Sends reward to the Relayer
    /// @dev We compensate the Relayer for the block submission cost + give extra reward in TDT
    /// @param _relayer The Relayer address
    /// @param _height The height of the submitted block header
    /// @return Reward in TNT
    /// @return Reward in TDT
    function _sendReward(address _relayer, uint _height) internal returns (uint, uint) {

        // Reward in TNT
        uint rewardAmountInTNT = submissionGasUsed * chain[_height][0].gasPrice 
            * (ONE_HUNDRED_PERCENT + relayerPercentageFee) / ONE_HUNDRED_PERCENT;

        // Reward in TDT
        uint contractTDTBalance = 0;
        if (TeleportDAOToken != address(0)) {
            contractTDTBalance = IERC20(TeleportDAOToken).balanceOf(address(this));
        }

        // Send reward in TDT
        bool sentTDT;
        if (rewardAmountInTDT <= contractTDTBalance && rewardAmountInTDT > 0) {
            // Call ERC20 token contract to transfer reward tokens to the relayer
            IERC20(TeleportDAOToken).safeTransfer(_relayer, rewardAmountInTDT);
            sentTDT = true;
        }

        // Send reward in TNT
        bool sentTNT;
        if (address(this).balance > rewardAmountInTNT && rewardAmountInTNT > 0) {
            // note: no need to revert if failed
            (sentTNT,) = payable(_relayer).call{value: rewardAmountInTNT}("");
        }

        if (sentTNT) {
            return sentTDT ? (rewardAmountInTNT, rewardAmountInTDT) : (rewardAmountInTNT, 0);
        } else {
            return sentTDT ? (0, rewardAmountInTDT) : (0, 0);
        }
    }

    /// @notice Adds a header to the chain
    /// @dev We prune the chain if the new header finalizes any header
    /// @param  _header The new block header
    /// @param  _height The height of the new block header
    function _addToChain(bytes29 _header, uint _height) internal {
        // Prevent relayers to submit too old block headers
        require(_height + finalizationParameter > lastSubmittedHeight, "BitcoinRelay: block header is too old");
        blockHeader memory newBlockHeader;
        newBlockHeader.selfHash = _header.hash256();
        newBlockHeader.parentHash = _header.parent();
        newBlockHeader.merkleRoot = _header.merkleRoot();
        newBlockHeader.relayer = _msgSender();
        newBlockHeader.gasPrice = tx.gasprice;
        chain[_height].push(newBlockHeader);
        if(_height > lastSubmittedHeight){
            lastSubmittedHeight += 1;
            _updateFee();
            _pruneChain();
        }
    }

    /// @notice Reset the number of epoch users when a new epoch starts
    /// @dev This parameter is used to calculate the fee that Relay gets from users in the next epoch
    function _updateFee() internal {
        if (lastSubmittedHeight % epochLength == 0) {
            lastEpochQueries = (currentEpochQueries < baseQueries) ? baseQueries : currentEpochQueries;
            currentEpochQueries = 0;
        }
    }

    /// @notice Finalizes a block header and removes all the other headers in that height
    /// @dev When chain gets pruned, we only delete blocks in the same 
    ///      height as the finalized header. Other blocks on top of the non finalized blocks 
    ///      will exist until their height gets finalized.
    function _pruneChain() internal {
        // Make sure that we have at least finalizationParameter blocks on relay
        if ((lastSubmittedHeight - initialHeight) >= finalizationParameter){
            uint idx = finalizationParameter;
            uint currentHeight = lastSubmittedHeight;
            uint stableIdx = 0;
            while (idx > 0) {
                // bytes29 header = chain[currentHeight][stableIdx];
                bytes32 parentHeaderHash = chain[currentHeight][stableIdx].parentHash;
                stableIdx = _findIndex(parentHeaderHash, currentHeight-1);
                idx--;
                currentHeight--;
            }
            // Keep the finalized block header and delete rest of headers
            chain[currentHeight][0] = chain[currentHeight][stableIdx];
            if(chain[currentHeight].length > 1){
                _pruneHeight(currentHeight);
            }
            // A new block has been finalized, we send its relayer's reward
            uint rewardAmountTNT;
            uint rewardAmountTDT;
            (rewardAmountTNT, rewardAmountTDT) = _sendReward(chain[currentHeight][0].relayer, currentHeight);

            emit BlockFinalized(
                currentHeight,
                chain[currentHeight][0].selfHash,
                chain[currentHeight][0].parentHash,
                chain[currentHeight][0].relayer,
                rewardAmountTNT,
                rewardAmountTDT
            );
        }
    }

    /// @notice Finds the index of a block header in a specific height
    /// @param _headerHash The block header hash
    /// @param _height The height that we are searching
    /// @return _index Index of the block header
    function _findIndex(bytes32 _headerHash, uint _height) internal view returns(uint _index) {
        for(uint256 i = 0; i < chain[_height].length; i++) {
            if(_headerHash == chain[_height][i].selfHash) {
                _index = i;
            }
        }
    }

    /// @notice Deletes all the block header in a height except the first header
    /// @dev The first header is the one that gets finalized
    /// @param _height The height that we are pruning
    function _pruneHeight(uint _height) internal {
        uint idx = chain[_height].length - 1;
        while(idx > 0){
            chain[_height].pop();
            idx -= 1;
        }
    }

    /// @notice nternal setter for rewardAmountInTDT
    function _setRewardAmountInTDT(uint _rewardAmountInTDT) private {
        emit NewRewardAmountInTDT(rewardAmountInTDT, _rewardAmountInTDT);
        // this reward can be zero as well
        rewardAmountInTDT = _rewardAmountInTDT;
    }

    /// @notice Internal setter for finalizationParameter
    function _setFinalizationParameter(uint _finalizationParameter) private {
        emit NewFinalizationParameter(finalizationParameter, _finalizationParameter);
        require(
            _finalizationParameter > 0 && _finalizationParameter <= MAX_FINALIZATION_PARAMETER,
            "BitcoinRelay: invalid finalization param"
        );

        finalizationParameter = _finalizationParameter;
    }

    /// @notice Internal setter for relayerPercentageFee
    function _setRelayerPercentageFee(uint _relayerPercentageFee) private {
        emit NewRelayerPercentageFee(relayerPercentageFee, _relayerPercentageFee);
        require(
            _relayerPercentageFee <= ONE_HUNDRED_PERCENT,
            "BitcoinRelay: relay fee is above max"
        );
        relayerPercentageFee = _relayerPercentageFee;
    }

    /// @notice Internal setter for teleportDAO token
    function _setTeleportDAOToken(address _TeleportDAOToken) private {
        emit NewTeleportDAOToken(TeleportDAOToken, _TeleportDAOToken);
        TeleportDAOToken = _TeleportDAOToken;
    }

    /// @notice Internal setter for epochLength
    function _setEpochLength(uint _epochLength) private {
        emit NewEpochLength(epochLength, _epochLength);
        require(
            _epochLength > 0,
            "BitcoinRelay: zero epoch length"
        );
        epochLength = _epochLength;
    }

    /// @notice Internal setter for baseQueries
    function _setBaseQueries(uint _baseQueries) private {
        emit NewBaseQueries(baseQueries, _baseQueries);
        require(
            _baseQueries > 0,
            "BitcoinRelay: zero base query"
        );
        baseQueries = _baseQueries;
    }

    /// @notice Internal setter for submissionGasUsed
    function _setSubmissionGasUsed(uint _submissionGasUsed) private {
        emit NewSubmissionGasUsed(submissionGasUsed, _submissionGasUsed);
        submissionGasUsed = _submissionGasUsed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./BitcoinRelay.sol";
import "../libraries/TypedMemView.sol";
import "../libraries/BitcoinHelper.sol";

contract BitcoinRelayTestnet is BitcoinRelay {

    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using BitcoinHelper for bytes29;

    /// @notice Gives a starting point for the relay
    /// @dev Same as BitcoinRelay contract, but some retargeting checks has been removed
    constructor(
        bytes memory _genesisHeader,
        uint256 _height,
        bytes32 _periodStart,
        address _TeleportDAOToken
    ) BitcoinRelay(_genesisHeader, _height, _periodStart, _TeleportDAOToken) {}

    /// @notice Adds headers to storage after validating
    /// @dev Checks for retargeting have been removed since the Bitcoin testnet has unexpected retargeting
    function _addHeaders(bytes29 _anchor, bytes29 _headers, bool _internal) internal override returns (bool) {
        // Extract basic info
        bytes32 _previousHash = _anchor.hash256();
        uint256 _anchorHeight = _findHeight(_previousHash); // revert if the block is unknown
        uint256 _target = _headers.indexHeaderArray(0).target();

        /*
        1. check that the blockheader is not a replica
        2. check blocks are in the same epoch regarding difficulty
        3. check that headers are in a coherent chain (no retargets, hash links good)
        4. check that the header has sufficient work
        5. Store the block connection
        6. Store the height
        7. store the block in the chain
        */
        uint256 _height;
        bytes32 _currentHash;
        for (uint256 i = 0; i < _headers.len() / 80; i++) {
            bytes29 _header = _headers.indexHeaderArray(i);
            _height = _anchorHeight + i + 1;
            _currentHash = _header.hash256();

            // The below check prevents adding a replicated block header
            require(
                previousBlock[_currentHash] == bytes32(0),
                "BitcoinRelay: the block header exists on the relay"
            );

            require(_header.target() == _target, "BitcoinRelay: target changed unexpectedly");
            require(_header.checkParent(_previousHash), "BitcoinRelay: headers do not form a consistent chain");
            
            require(
                TypedMemView.reverseUint256(uint256(_currentHash)) <= _target,
                "BitcoinRelay: header work is insufficient"
            );

            previousBlock[_currentHash] = _previousHash;
            blockHeight[_currentHash] = _height;
            emit BlockAdded(_height, _currentHash, _previousHash, _msgSender());
            _addToChain(_header, _height);
            _previousHash = _currentHash;
        }
        return true;
    }

    /// @notice Adds headers to storage, performs additional validation of retarget
    /// @dev Checks for retargeting have been removed since the Bitcoin testnet has unexpected retargeting
    function _addHeadersWithRetarget(
        bytes29 _oldStart,
        bytes29 _oldEnd,
        bytes29 _headers
    ) internal override returns (bool) {
        return _addHeaders(_oldEnd, _headers, true);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IBitcoinRelay {
    // Structures

    /// @notice Structure for recording block header
    /// @param selfHash Hash of block header
    /// @param parentHash Hash of parent header
    /// @param merkleRoot Merkle root of transactions in the header
    /// @param relayer Address of Relayer who submitted the block header
    /// @param gasPrice Gas price of block header submission transaction
    struct blockHeader {
        bytes32 selfHash;
        bytes32 parentHash;
        bytes32 merkleRoot;
        address relayer;
        uint gasPrice;
    }

    // Events

    /// @notice Emits when a block header is added
    /// @param height of submitted header
    /// @param selfHash Hash of submitted header
    /// @param parentHash of submitted header
    /// @param relayer Address of Relayer who submitted the block header
    event BlockAdded(
        uint indexed height,
        bytes32 selfHash,
        bytes32 indexed parentHash,
        address indexed relayer
    );

    /// @notice Emits when a block header gets finalized
    /// @param height of the header
    /// @param selfHash Hash of the header
    /// @param parentHash of the header
    /// @param relayer Address of Relayer who submitted the block header
    /// @param rewardAmountTNT Amount of reward that the Relayer receives in target blockchain native token
    /// @param rewardAmountTDT Amount of reward that the Relayer receives in TeleportDAO token
    event BlockFinalized(
        uint indexed height,
        bytes32 selfHash,
        bytes32 parentHash,
        address indexed relayer,
        uint rewardAmountTNT,
        uint rewardAmountTDT
    );

    /// @notice Emits when inclusion of a tx is queried
    /// @param txId of queried transaction
    /// @param blockHeight of the block that includes the tx
    /// @param paidFee Amount of fee that user paid to Relay
    event NewQuery(
        bytes32 txId,
        uint blockHeight,
        uint paidFee
    );
         
    event NewRewardAmountInTDT (
        uint oldRewardAmountInTDT, 
        uint newRewardAmountInTDT
    );

    event NewFinalizationParameter (
        uint oldFinalizationParameter, 
        uint newFinalizationParameter
    );

    event NewRelayerPercentageFee (
        uint oldRelayerPercentageFee, 
        uint newRelayerPercentageFee
    );

    event NewTeleportDAOToken(
        address oldTeleportDAOToken, 
        address newTeleportDAOToken
    );

    event NewEpochLength(
        uint oldEpochLength, 
        uint newEpochLength
    );

    event NewBaseQueries(
        uint oldBaseQueries, 
        uint newBaseQueries
    );

    event NewSubmissionGasUsed(
        uint oldSubmissionGasUsed, 
        uint newSubmissionGasUsed
    );

    // Read-only functions

    function relayGenesisHash() external view returns (bytes32);

    function initialHeight() external view returns(uint);

    function lastSubmittedHeight() external view returns(uint);

    function finalizationParameter() external view returns(uint);

    function TeleportDAOToken() external view returns(address);

    function relayerPercentageFee() external view returns(uint);

    function epochLength() external view returns(uint);

    function lastEpochQueries() external view returns(uint);

    function currentEpochQueries() external view returns(uint);

    function baseQueries() external view returns(uint);

    function submissionGasUsed() external view returns(uint);

    function getBlockHeaderHash(uint height, uint index) external view returns(bytes32);

    function getBlockHeaderFee(uint _height, uint _index) external view returns(uint);

    function getNumberOfSubmittedHeaders(uint height) external view returns (uint);

    function availableTDT() external view returns(uint);

    function availableTNT() external view returns(uint);

    function findHeight(bytes32 _hash) external view returns (uint256);

    function rewardAmountInTDT() external view returns (uint);

    // State-changing functions

    function pauseRelay() external;

    function unpauseRelay() external;

    function setRewardAmountInTDT(uint _rewardAmountInTDT) external;

    function setFinalizationParameter(uint _finalizationParameter) external;

    function setRelayerPercentageFee(uint _relayerPercentageFee) external;

    function setTeleportDAOToken(address _TeleportDAOToken) external;

    function setEpochLength(uint _epochLength) external;

    function setBaseQueries(uint _baseQueries) external;

    function setSubmissionGasUsed(uint _submissionGasUsed) external;

    function checkTxProof(
        bytes32 txid,
        uint blockHeight,
        bytes calldata intermediateNodes,
        uint index
    ) external payable returns (bool);

    function getBlockHeaderHashContract(uint _height, uint _index) external payable returns (bytes32);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);

    function ownerAddHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function ownerAddHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

    enum ScriptTypes {
        P2PK, // 32 bytes
        P2PKH, // 20 bytes        
        P2SH, // 20 bytes          
        P2WPKH, // 20 bytes          
        P2WSH, // 32 bytes
        P2TR // 32 bytes               
    }