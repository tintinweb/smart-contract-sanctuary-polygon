/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

//SPDX-License-Identifier: Unlicense

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: stakingNudara.sol

pragma solidity ^0.8.0;

contract NudaraStaking is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address feeWallet;
    uint unclaimedTax;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint24 lockTime;
        uint256 apr;
        uint256 claimedRewards;
        bool unstaked;
    }

    uint24[] public lockTimes = [180, 45];


    IERC20 public stakingToken;

    uint256 public contractRewardFunds;

    uint256 tokensBlocked;

    uint256[] tokensBlockedLevels = [2001, 201, 0];

    uint256 amountForReferrals = 300; // 30%
    address referralProgramWallet;

    

    mapping(uint256 => mapping(uint24 => uint256)) public aprForTvlAndLocktime;
    mapping(address => Stake[]) public stakesByAccount;
    mapping(address => uint256) tokensStakedPerWallet;

    mapping(address => address) referralByWallet;
    mapping(address => ReferralDeposit[]) referralDepositsPerWallet;
    mapping(address => uint256) pendingBalancePerWallet;
    mapping(address => uint256) claimedBalancePerWallet;
    
    struct ReferralDeposit {
        address from;
        uint256 amount;
    }

    //EVENTS
    event Staked(address indexed staker, uint256 amount, uint24 indexed lockTime, uint256 indexed apr);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardsDeposited(uint256 amount);
    event RewardsClaimed(address indexed staker, uint256 amount);
    event feeWalletChanged(address indexed wallet);
    event unclaimedTaxChanged(uint indexed tax);

    constructor() {

        stakingToken = IERC20(0xe364C692d905C5009257dc8f6dd28E388ca2bbB1);//CHANGE TO PROD
        
        //RANGE 0 - 200
        aprForTvlAndLocktime[0][45] = 10;
        aprForTvlAndLocktime[0][180] = 90;

        //RANGE 201 - 2000
        aprForTvlAndLocktime[201][45] = 20;
        aprForTvlAndLocktime[201][180] = 130;
        
        //RANGE 2001 - INFINITE
        aprForTvlAndLocktime[2001][45] = 32;
        aprForTvlAndLocktime[2001][180] = 180;
        
        referralProgramWallet = owner();

        feeWallet = owner();
    }

    function stake(uint256 _amount, uint24 _lockTime, address _referral) external whenNotPaused nonReentrant {

        require(stakingToken.allowance(msg.sender, address(this)) >= _amount, "NOT_ENOUGH_ALLOWANCE"); //CHECK ALLOWANCE
        require(_isValidLockTime(_lockTime), "NO_VALID_LOCK_TIME"); //CHECK VALID LOCK TIME
        
        
        uint256 currentBlockedLevel = 0;
        bool hasReferral =  referralByWallet[msg.sender] != address(0) ? true: _referral != address(0) ? true: false;

        uint256 amountToDistribute = getTotalToEarn(_amount, _lockTime).mul(amountForReferrals).div(1000);
        uint256 amountReferrals = amountToDistribute.mul(90).div(100);
        uint256 amountReferralProgram = amountToDistribute.mul(10).div(100);

        uint256 referralAmount = amountReferrals.mul(60).div(100);
        uint256 referralAmountTwo = amountReferrals.mul(25).div(100);
        uint256 referralAmountThree = amountReferrals.mul(15).div(100);
        
        for(uint256 i = 0; i < tokensBlockedLevels.length; i++) {
            if(_amount  >= tokensBlockedLevels[i] * 10 ** 18) {
                currentBlockedLevel = i;
                break;
            }
        }

        
        if(hasReferral) {
            referralByWallet[msg.sender] = referralByWallet[msg.sender] != address(0) ? referralByWallet[msg.sender]:  _referral;


             //TERCER NIVEL HACIA ARRIBA
            if(referralByWallet[referralByWallet[referralByWallet[msg.sender]]] != address(0)) {
                
                pendingBalancePerWallet[referralByWallet[msg.sender]] += referralAmount;
                pendingBalancePerWallet[referralByWallet[referralByWallet[msg.sender]]] += referralAmountTwo;
                pendingBalancePerWallet[referralByWallet[referralByWallet[referralByWallet[msg.sender]]]] += referralAmountThree;
                pendingBalancePerWallet[referralProgramWallet] += amountReferralProgram;

            }

            //SEGUNDO NIVEL HACIA ARRIBA
            else if(referralByWallet[referralByWallet[msg.sender]] != address(0)) {

                pendingBalancePerWallet[referralByWallet[msg.sender]] += referralAmount;
                pendingBalancePerWallet[referralByWallet[referralByWallet[msg.sender]]] += referralAmountTwo;
                pendingBalancePerWallet[referralProgramWallet] += amountReferralProgram;

            }
            //PRIMER NIVEL HACIA ARRIBA
            else {
                pendingBalancePerWallet[referralByWallet[msg.sender]] += referralAmount;
                pendingBalancePerWallet[referralProgramWallet] += amountReferralProgram;
            }
           
        }

        tokensStakedPerWallet[msg.sender] += _amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount); //TRANSFER TOKENS TO THE CONTRACT
        
        tokensBlocked += _amount; //WE ADD THE BLOCKED TOKENS

        uint256 apr =  aprForTvlAndLocktime[currentBlockedLevel][_lockTime]; //CALCULATE CURRENT APR

        stakesByAccount[msg.sender].push(
            Stake(
                _amount,
                block.timestamp,
                _lockTime,
                apr,
                0,
                false
            )
        );

        emit Staked(msg.sender, _amount, _lockTime, apr);

    }

    function unstake(uint256 _stake) external nonReentrant {

        require(stakesByAccount[msg.sender][_stake].amount > 0, "Amount needs to be > 0");
        require(!stakesByAccount[msg.sender][_stake].unstaked, "Stake unstaked");


        uint daysDiff = (block.timestamp - stakesByAccount[msg.sender][_stake].timestamp) / 60 / 60 / 24; // days
        uint256 fee = 0;

        if(daysDiff <  stakesByAccount[msg.sender][_stake].lockTime) {
            fee =  stakesByAccount[msg.sender][_stake].amount.div(100).mul(unclaimedTax); //CHARGE TAX IF THE STAKING IS LOWER TO LOCKED DAY
            stakingToken.safeTransfer(feeWallet, fee);  //SEND FEE TO FEE WALLET
        }

        stakesByAccount[msg.sender][_stake].unstaked = true; //SET UNSTAKED TO TRUE TO AVOID UNSTAKE AGAIN
        tokensBlocked -= stakesByAccount[msg.sender][_stake].amount; //REDUCE AMOUNT FROM BLOCKED TOKENS
        
        stakingToken.safeTransfer(msg.sender, stakesByAccount[msg.sender][_stake].amount - fee); //TRANSFER TOKENS TO MSG.SENDER

        emit Unstaked(msg.sender, stakesByAccount[msg.sender][_stake].amount - fee); //EMIT UNSTAKED EVENT
    }  

    function claimRewards(uint256 _stake) external nonReentrant{

        uint256 rewards = getRewardsByStake(_stake);

        require(rewards > 0, "Rewards needs to be > 0");
        require(contractRewardFunds >= rewards, "Not enough funds in the contract");
        require(stakesByAccount[msg.sender][_stake].amount > 0, "Amount needs to be > 0");
        require(!stakesByAccount[msg.sender][_stake].unstaked, "Stake unstaked");

        bool hasReferral =  referralByWallet[msg.sender] != address(0) ? true: false;

        uint256 _amount = stakesByAccount[msg.sender][_stake].amount;
        uint24 _lockTime = stakesByAccount[msg.sender][_stake].lockTime;

        uint256 amountToDistribute = getTotalToEarn(_amount, _lockTime).mul(amountForReferrals).div(1000);
        uint256 amountReferrals = amountToDistribute.mul(90).div(100);
       
        uint256 amountReferralProgram = 0;
        uint256 referralAmount = 0;
        uint256 referralAmountTwo = 0;
        uint256 referralAmountThree = 0;

         if(hasReferral) {
             //TERCER NIVEL HACIA ARRIBA
            if(referralByWallet[referralByWallet[referralByWallet[msg.sender]]] != address(0)) {

                amountReferralProgram = amountToDistribute.mul(10).div(100);
                referralAmount = amountReferrals.mul(60).div(100);
                referralAmountTwo = amountReferrals.mul(25).div(100);
                referralAmountThree = amountReferrals.mul(15).div(100);
        
                pendingBalancePerWallet[referralByWallet[msg.sender]] -= referralAmount;
                pendingBalancePerWallet[referralByWallet[referralByWallet[msg.sender]]] -= referralAmountTwo;
                pendingBalancePerWallet[referralByWallet[referralByWallet[referralByWallet[msg.sender]]]] -= referralAmountThree;
                pendingBalancePerWallet[referralProgramWallet] -= amountReferralProgram;

                claimedBalancePerWallet[referralByWallet[msg.sender]] += referralAmount;
                claimedBalancePerWallet[referralByWallet[referralByWallet[msg.sender]]] += referralAmountTwo;
                claimedBalancePerWallet[referralByWallet[referralByWallet[referralByWallet[msg.sender]]]] += referralAmountThree;
                claimedBalancePerWallet[referralProgramWallet] += amountReferralProgram;

                IERC20(stakingToken).transferFrom(msg.sender, referralByWallet[msg.sender], referralAmount);
                IERC20(stakingToken).transferFrom(msg.sender, referralByWallet[referralByWallet[msg.sender]], referralAmountTwo);
                IERC20(stakingToken).transferFrom(msg.sender, referralByWallet[referralByWallet[referralByWallet[msg.sender]]], referralAmountThree);
                IERC20(stakingToken).transferFrom(msg.sender, referralProgramWallet, amountReferralProgram);

                referralDepositsPerWallet[referralByWallet[msg.sender]].push(
                    ReferralDeposit(
                        msg.sender,
                        referralAmount
                    )
                );

                referralDepositsPerWallet[referralByWallet[referralByWallet[msg.sender]]].push(
                    ReferralDeposit(
                        msg.sender,
                        referralAmountTwo
                    )
                );

                referralDepositsPerWallet[referralByWallet[referralByWallet[referralByWallet[msg.sender]]]].push(
                    ReferralDeposit(
                        msg.sender,
                        referralAmountThree
                    )
                );

                referralDepositsPerWallet[referralProgramWallet].push(
                    ReferralDeposit(
                        msg.sender,
                        amountReferralProgram
                    )
                );

            }

            //SEGUNDO NIVEL HACIA ARRIBA
            else if(referralByWallet[referralByWallet[msg.sender]] != address(0)) {

                amountReferralProgram = amountToDistribute.mul(10).div(100);
                referralAmount = amountReferrals.mul(60).div(100);
                referralAmountTwo = amountReferrals.mul(25).div(100);

                pendingBalancePerWallet[referralByWallet[msg.sender]] -= referralAmount;
                pendingBalancePerWallet[referralByWallet[referralByWallet[msg.sender]]] -= referralAmountTwo;
                pendingBalancePerWallet[referralProgramWallet] -= amountReferralProgram;

                claimedBalancePerWallet[referralByWallet[msg.sender]] += referralAmount;
                claimedBalancePerWallet[referralByWallet[referralByWallet[msg.sender]]] += referralAmountTwo;
                claimedBalancePerWallet[referralProgramWallet] += amountReferralProgram;

                IERC20(stakingToken).transferFrom(msg.sender, referralByWallet[msg.sender], referralAmount);
                IERC20(stakingToken).transferFrom(msg.sender, referralByWallet[referralByWallet[msg.sender]], referralAmountTwo);
                IERC20(stakingToken).transferFrom(msg.sender, referralProgramWallet, amountReferralProgram);


                referralDepositsPerWallet[referralByWallet[msg.sender]].push(
                    ReferralDeposit(
                        msg.sender,
                        referralAmount
                    )
                );

                referralDepositsPerWallet[referralByWallet[referralByWallet[msg.sender]]].push(
                    ReferralDeposit(
                        msg.sender,
                        referralAmountTwo
                    )
                );

                referralDepositsPerWallet[referralProgramWallet].push(
                    ReferralDeposit(
                        msg.sender,
                        amountReferralProgram
                    )
                );


            }
            //PRIMER NIVEL HACIA ARRIBA
            else {

                amountReferralProgram = amountToDistribute.mul(10).div(100);
                referralAmount = amountReferrals.mul(60).div(100);

                pendingBalancePerWallet[referralByWallet[msg.sender]] -= referralAmount;
                pendingBalancePerWallet[referralProgramWallet] -= amountReferralProgram;

                claimedBalancePerWallet[referralByWallet[msg.sender]] += referralAmount;
                claimedBalancePerWallet[referralProgramWallet] += amountReferralProgram;



                IERC20(stakingToken).transferFrom(msg.sender, referralByWallet[msg.sender], referralAmount);
                IERC20(stakingToken).transferFrom(msg.sender, referralProgramWallet, amountReferralProgram);

                 referralDepositsPerWallet[referralByWallet[msg.sender]].push(
                    ReferralDeposit(
                        msg.sender,
                        referralAmount
                    )
                );

                referralDepositsPerWallet[referralProgramWallet].push(
                    ReferralDeposit(
                        msg.sender,
                        amountReferralProgram
                    )
                );
            }
           
        }

        contractRewardFunds -= rewards - amountReferralProgram - referralAmount - referralAmountTwo - referralAmountThree;

        stakesByAccount[msg.sender][_stake].claimedRewards += rewards; //ADD CLAIMED REWARDS TO STAKE

        stakingToken.safeTransfer(msg.sender, rewards); //TRANSFER TOKENS TO MSG.SENDER
       
        emit RewardsClaimed(msg.sender, rewards); //EMIT REWARDS CLAIMED EVENT

    }

    function getRewardsByStake(uint256 _stake) public view returns(uint256) {
       
        uint256 minutesSinceStake =  (block.timestamp - stakesByAccount[msg.sender][_stake].timestamp) / 60; // minutes
        uint256 daysToClaim = minutesSinceStake < stakesByAccount[msg.sender][_stake].lockTime * 24 * 60 ? minutesSinceStake : stakesByAccount[msg.sender][_stake].lockTime * 24 * 60;
        uint256 rewards = (stakesByAccount[msg.sender][_stake].amount * daysToClaim * stakesByAccount[msg.sender][_stake].apr) / (1000 * 365 * 24 * 60);
        uint256 total = rewards - stakesByAccount[msg.sender][_stake].claimedRewards;
        return total;
    }
    
    function depositRewards(uint256 _amount) external {
        require(
            stakingToken.allowance(msg.sender, address(this)) >= _amount,
            "NOT_ENOUGH_ALLOWANCE"
        );

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        contractRewardFunds += _amount ;

        emit RewardsDeposited(_amount);
    }

    function _isValidLockTime(uint24 _lockTime)
        private
        view
        returns (bool isValid)
    {
        uint256 i = 0;
        for (; i < lockTimes.length; i++) {
            if (lockTimes[i] == _lockTime) return true;
        }
    }

    //ONLY OWNER FUNCTIONS

    function setFeeWallet(address wallet) external onlyOwner {
        feeWallet = wallet;
        emit feeWalletChanged(wallet);
    }

    function setUnstakeTax(uint tax) external onlyOwner {
        unclaimedTax = tax;
        emit unclaimedTaxChanged(tax);
    }

    function pause() public onlyOwner {
        _pause();
    }
    //VIEW FUNCTIONS

    function checkUnclaimedTax() external view returns(uint) {
        return unclaimedTax;
    }

    function getStakesByWallet() external view returns(Stake[] memory) {
        return stakesByAccount[msg.sender];
    }

    function getLockTimes() external view returns(uint24[] memory) {
        return lockTimes;
    }

    function getAPR(uint256 _tokens, uint24 _lockTime) external view returns(uint256) {
        return aprForTvlAndLocktime[_tokens][_lockTime];
    }

    function getTotalToEarn(uint256 _tokens, uint24 _lockTime) public view returns(uint256) {

        uint256 apr = aprForTvlAndLocktime[_tokens][_lockTime];
        uint256 totalTokensPerDay = _tokens.mul(apr).div(1000).div(365);
        uint256 totalToEarn = totalTokensPerDay * _lockTime;
        return totalToEarn;
        
    }

    function getReferralDepositsPerWalletPaginate(address wallet, uint256 page) external view returns(ReferralDeposit[] memory) {
       
        uint256 length = referralDepositsPerWallet[wallet].length;
        ReferralDeposit[] memory deposits = new ReferralDeposit[](length);

        uint totalItemCount = length <= 10 ? length: 10;

        for(uint i = ((page * 10) - 10); i < totalItemCount; i++) {
            deposits[i] = ReferralDeposit(
                    referralDepositsPerWallet[wallet][i].from,
                    referralDepositsPerWallet[wallet][i].amount
                );
        }
    
        return deposits;
   
    }

    function getReferralDepositsPerWallet(address wallet) external view returns(ReferralDeposit[] memory) {
       
        return  referralDepositsPerWallet[wallet];
   
    }


    function changeReferralPrograWallet(address _wallet) external onlyOwner {
        referralProgramWallet = _wallet;
    }

    function changeAmountPerReferrals(uint256 _amount) external onlyOwner {
        amountForReferrals = _amount;
    }

    function getTokensStakedPerWallet(address _wallet) external view returns(uint256){
        return tokensStakedPerWallet[_wallet];
    }

    function getPendingBalance(address _wallet) external view returns(uint256) {
        return pendingBalancePerWallet[_wallet];
    }

    function getClaimedBalance(address _wallet) external view returns(uint256) {
        return claimedBalancePerWallet[_wallet];
    }
}