/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;
interface IPineUniswapExpress {
    function sendTokenToPool(uint256 amount) external;
    function swapTokenForETH(uint amountIn, address token, address to) external returns (uint amountOut);
    function swapETHForToken(address token, address to ) external payable returns (uint256 amountOut);
}



/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {

    function safeTransferETH(address payable to, uint256 amount) internal {
        require(to != address(0), "Pinecone::TransferHelper: cannot transfer to address(0)");
        require(
            address(this).balance >= amount,
            "Pinecone::TransferHelper Address insufficient balance"
        );

        (bool success, ) = to.call{value: amount}("");//new bytes(0)
        require(
            success,
            "Pinecone::TransferHelper: Address unable to send value, recipient may have reverted"
        );
    }
}



/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../extensions/draft-IERC20Permit.sol";
////import "../../../utils/Address.sol";

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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}



/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

////import "./StorageSlot.sol";
////import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

////import "./IERC20.sol";
////import "./extensions/IERC20Metadata.sol";
////import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.10;

interface IRewards {
    function getValues(
        uint256 tAmount
    ) external view returns (uint256, uint256, uint256, uint256);

    function getStakes(
        uint256 amount
    )
        external
        view
        returns (uint256 stakePer1, uint256 stakePer2, uint256 stakePer3);

    function setContractOwner() external;
    function setInitialReferrers(address _address, address _inviterAddr) external;
    function getReferrers(
        address _address
    ) external view returns (address, address, address);

    function updateReferralActivations(address user, uint256 miningCount) external;
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.10;

interface IProMine {
    function setContractOwner() external;
    function boostMiningSpeed(address userAddress, uint256 boostLevelIndex) external;
    function addMiningPool(address userAddress, uint256 count) external;
    function currentMiningOutput(address userAddress) external view returns (uint256 miningOutput);
    function getTotalMiningOutput(address userAddress) external view returns (uint256 totalMiningOutput);
    function getMiningPerBlock(address userAddress) external view returns (uint256 miningPerBlock);

    //function getGenesisAllocationAmount() external pure returns (uint256);
    function getMiningPoolCount(address userAddress) external view returns (uint256);
    function getRemainingMiningOutput(address userAddress) external view returns (uint256 remainingMiningOutput);

    
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

////import "../lib/TransferHelper.sol";
////import "../interface/IPineUniswapExpress.sol";



abstract contract AssetManager is Ownable {
    using SafeERC20 for IERC20;

    address payable public assetAddress;
    IPineUniswapExpress public pineUniswapExpress;

    address internal usdAddress;

    //
    constructor(address _usdAddress, address _pineUniswapExpress) {
        usdAddress = _usdAddress;
        assetAddress = payable(msg.sender);

        pineUniswapExpress = IPineUniswapExpress(_pineUniswapExpress);
    }

    /// @dev token => eth
    function swapAnyTokensForETH(
        address tokenAddress,
        uint256 swapAmount
    ) external onlyOwner {
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));

        if (tokenBalance < swapAmount) {
            swapAmount = tokenBalance;
        }

        IERC20(tokenAddress).safeIncreaseAllowance(address(pineUniswapExpress), swapAmount);

        if (swapAmount > 0) {
            pineUniswapExpress.swapTokenForETH(swapAmount, tokenAddress, address(this));
        }
    }

    function setUniswapExpressAddress(
        address _pineUniswapExpress
    ) external onlyOwner {
        require(_pineUniswapExpress != address(0), "Invalid router address");
        pineUniswapExpress = IPineUniswapExpress(_pineUniswapExpress);
    }

    /// @dev EtH => token
    function swapETHForToken(
        uint256 ethAmount,
        address tokenAddress
    ) external onlyOwner {
        // Check if the ETH balance is sufficient
        uint256 currentAmount = ethAmount;
        if (address(this).balance < currentAmount) {
            currentAmount = address(this).balance;
        }

        pineUniswapExpress.swapETHForToken{value:currentAmount}(tokenAddress, address(this));
    }

    //@dev token => eth
    function _swapTokensForEth(
        uint256 tokenAmount,
        address tokenAddress,
        address acceptAddress
    ) internal {
        IERC20(address(this)).safeIncreaseAllowance(address(pineUniswapExpress), tokenAmount);
        pineUniswapExpress.swapTokenForETH(tokenAmount, tokenAddress, acceptAddress);
    }

    function _swapETHForToken(
        uint256 ethAmount,
        address tokenAddress,
        address acceptAddress
    ) internal {
        pineUniswapExpress.swapETHForToken{value:ethAmount}( tokenAddress, acceptAddress);
    }

    /// @dev 把Token增加流动池
    function _sendTokenToPool(uint256 amount) internal {
        IERC20(address(this)).safeIncreaseAllowance( address(pineUniswapExpress), amount);
        pineUniswapExpress.sendTokenToPool(amount);
    }

    function _sendETHToPool(uint256 amount) internal {
        address payable poolAddress = payable(address(pineUniswapExpress));
        TransferHelper.safeTransferETH(poolAddress, amount);
    }

    function withdrawalForTokens(address tokenAddr) external onlyOwner {
        IERC20(tokenAddr).safeTransfer(
            assetAddress,
            IERC20(tokenAddr).balanceOf(address(this))
        );
    }

    function withdrawalForETH() external onlyOwner {
        TransferHelper.safeTransferETH(
            payable(assetAddress),
            address(this).balance
        );
    }

    function updateAssetAddress(address assetAddr) external onlyOwner {
        assetAddress = payable(assetAddr);
    }

    function updateUsdAddress(address newUsdAddress) external onlyOwner {
        usdAddress = newUsdAddress;
    }
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

////import "@openzeppelin/contracts/access/Ownable.sol";

interface IAuthorization {
    function isAddressAuthorized(
        uint256 roleId,
        address addr
    ) external view returns (bool);
}

abstract contract AuthorizationManager is Ownable {
    IAuthorization public authorization;
    uint256 public defaultRoleId;

    constructor(address authorizationAddress, uint256 _defaultRoleId) {
        require(
            authorizationAddress != address(0),
            "Authorization address cannot be zero."
        );
        authorization = IAuthorization(authorizationAddress);
        defaultRoleId = _defaultRoleId;
    }

    modifier onlyAuthorizedRole() {
        require(authorization.isAddressAuthorized(defaultRoleId, msg.sender), "Caller is not authorized.");
        _;
    }

    modifier onlyAuthorizedRoleWithId(uint256 roleId) {
        require(authorization.isAddressAuthorized(roleId, msg.sender), "Caller is not authorized.");
        _;
    }


    // Set a new default role ID
    function setDefaultRoleId(uint256 newDefaultRoleId) external onlyOwner {
        defaultRoleId = newDefaultRoleId;
    }
}




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

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




/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;


////import "../interface/AggregatorV3Interface.sol";

////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";


contract PriceGetter is Ownable {
    using SafeMath for uint256;

    AggregatorV3Interface priceForToken;

    constructor(address priceAddress) {
        priceForToken = AggregatorV3Interface(priceAddress);
    }

    function setPriceForToken(address newPriceAddress) public onlyOwner {
        require(newPriceAddress != address(0), "Invalid address");
        priceForToken = AggregatorV3Interface(newPriceAddress);
    }


    function getPriceETH() public view returns (uint256) {
        (, int256 answer, , , ) = priceForToken.latestRoundData();
        return uint256(answer);
    }

    function convertToETH(uint256 price) public view returns (uint256) {
        return price.div(getPriceETH()).mul(10 ** uint256(priceForToken.decimals()));
    }
}



/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

interface IMysteryKeyNFT {
    function join(address user, uint256 tokenId, uint256 luckIndex,uint256 luckyNumber) external returns (uint256);
    
    function safeMint(address to, uint256 kindId, uint256 batchSize) external;

    function repair(uint256 tokenId,address user) external;

    function repairBatch(uint256[] calldata tokenIds,address user) external;

    function upgrade(uint256 tokenId,address user) external;
    function upgradeBatch(uint256[] calldata tokenIds,address user) external;
}



/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.10;

interface IPineconeToken {
    function checkIfAddressIsPine(address _address) external returns (bool success);
    function checkIfAddressIsDirector(address _address) external  returns (bool success);
    function checkIfAddressIsMine(address _address) external returns(bool success);

    function operateForNFT(uint256 rewardAmount, uint256 burnAmount) external;
    function boostMiningSpeedForNFT(address user,uint256 boostLevelIndex) external;

    function upgradeFeeUSDT() external view returns (uint256);
    function directorUpgradeCount() external view returns (uint256);
    function getCirculationSupply() external view returns(uint256 circulationSupply);

    function migrateOfficial(address referrer, address acount, uint256 miningCount) external;
    function upgradeToGenesisAddress(address _address, address _inviterAddr) external;
    

}



/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

////import "../ERC20.sol";
////import "../../../utils/Arrays.sol";
////import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}


/** 
 *  SourceUnit: d:\GitHub\PineconeAdminCentral\pinecone-admin\contracts\PineconeToken.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

/*
 * Deep within the network world, there is a forest of PineconeTokens in full bloom. 
 * Legend has it that this forest consists of 21,000,000 pine trees, each bearing 
 * 10,000 Pinecone Tokens (PCTs).
 *
 * These Pinecone Tokens, like the pinecones in the forest, are filled with vitality. 
 * They have deflationary and burnable attributes, and every usage can bring 
 * substantial dividends and staking rewards to the token holders.
 *
 * When you share the beauty of this forest, you will receive invitation rewards. 
 * For every new friend you invite, you will earn more Pinecone Tokens. 
 * What's more exciting is that when the number of pine trees you own reaches 10, 
 * you will receive a mysterious NFT key. This key is your pass to participate 
 * in the draw for a huge prize.
 *
 * PineconeToken is the key to the world of Web3.0. Just as each Pinecone Token 
 * embodies the vitality of a pine tree, PineconeToken also symbolizes the endless 
 * possibilities of the new network world. Together, let's explore the mysterious 
 * and beautiful world of Web3.0 through PineconeToken.
 */


pragma solidity ^0.8.10;

////import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "@openzeppelin/contracts/utils/Address.sol";

////import "./lib/TransferHelper.sol";

////import "./interface/IPineconeToken.sol";
////import "./interface/IMysteryKeyNFT.sol";

////import "./shared/PriceGetter.sol";
////import "./shared/ReentrancyGuard.sol";
////import "./shared/AuthorizationManager.sol";
////import "./shared/AssetManager.sol";

////import "./interface/IProMine.sol";
////import "./interface/IRewards.sol";

contract PineconeToken is
    ERC20Snapshot,
    AuthorizationManager,
    IPineconeToken,
    ReentrancyGuard,
    AssetManager,
    PriceGetter
{
    using SafeMath for uint256;
    using Address for address;

    //地址状态
    enum ADDRESS_STATE {
        NORMAL,
        GENESIS,
        PINE,
        DIRECTOR
    }

    // The amount of tokens allocated to the Genesis address is 100,000 tokens
    uint256 public constant GENESIS_ALLOCATION_AMOUNT = 10000 * 10 ** 18;

    // The maximum activation limit
    uint256 public constant MAX_ACTIVATION_LIMIT = 21000000;

    // Total supply of tokens
    uint256 private _totalSupply;

    // The number of addresses allocated to the Genesis address
    uint256 public genesisAddressCount;

    // The number of activated addresses
    uint256 public activatedAddressCount;

    // The maximum amount of official migrated data
    uint256 public constant GOVERNANCE_MIGRATION_AMOUNT = 66000;

    // The count of official migrated data
    uint256 public migrationCount;

    // The number of times a third-level address has to complete
    uint256 public directorUpgradeCount = 30;

    // USDT valuation
    uint256 public upgradeFeeUSDT = 15 * 10 ** 18;
    uint256 public spotFeeUSDT = 30 * 10 ** 18; 

    // Total number of referrals
    uint256 public totalReferrals;

    // Total quantity of spot donations
    uint256 public totalDonate;

    // Quantity of spot donations per donator
    mapping(address => uint256) public userDonateCount;

    // Number of referrals for each user, the count of addresses invited by the user
    mapping(address => uint256) public selfReferralCount;

    // Number of donations made by referrals
    mapping(address => uint256) public selfReferralDonateCount;

    // Number of activated referrals, this is the count of upgraded referrals after invitation
    uint256 public referralActivationsTotal;

    // 30 = 30%
    uint256 private _daoAllocationRate = 30;

    // Team allocation percentage: 8%
    uint256 private _genesisTeamAllocationPercentage = 8;

    // Board contract profit percentage: 4%
    uint256 private _boardProfitPercentage = 4;

    // Global block count starting point
    uint256 public immutable onlineBlockNumber;

    // Total amount burned
    uint256 public totalBurned;

    // Total rewards
    uint256 public totalRewards;

    // Cumulative rewards sent
    uint256 public totalRewardsSent;

    // Minimum reward exchange amount to transfer into the Stake contract, from Token to ETH, then into Stake contract
    uint256 public rewardExchangeMinAmount = 2000 * 10 ** 18;

    // Total amount pending to be added to the liquidity pool, during a transfer
    uint256 public pendingAddToLiquidityPool;

    // Total amount of referral rewards
    uint256 public totalReferralAmount;

    // Record of address types
    mapping(address => ADDRESS_STATE) public addressState;

    // Creation of genesis address, can only be created once
    mapping(address => bool) private _hasCreatedAddress;

    // Whether to exclude from fee
    mapping(address => bool) private _isExcludedFromFee;

    // Income brought by level 1 referrals
    mapping(address => uint256) private _referralIncomeLevel1;
    // Income brought by level 2 referrals
    mapping(address => uint256) private _referralIncomeLevel2;
    // Income brought by level 3 referrals
    mapping(address => uint256) private _referralIncomeLevel3;

    // Bar contract address, store income contract, transfer tax dividends, promotion reward 4%, only 3-level addresses can enjoy
    address payable public directorTokenAddress;

    // Team payment address 8%
    address payable public teamTokenAddress;

    // Dao receiving contract address 30%
    address payable public primaryDaoAddress;

    IProMine public promineContract;
    IRewards public rewardsContract;

    // Interface for Key NFT
    IMysteryKeyNFT public mysterykeyContract;

    // Default 97
    uint256 public mysteryKeyNftType = 97;

    // Determine whether to increase liquidity
    bool public swapAndLiquifyEnabled = true;

    string private errorMessage =
        "ERROR You must upgrade to Level 2 to allow transfers. Visit https://app.pineconedao.com for more info";

    mapping(address => bool) private _isExcludedFromSwap;

    // Number of gifted NFTs already received by users
    mapping(address => uint256) public nftSentCount;

    // Allow donations to receive spot rewards
    bool public allowDonation = true; 

    event GenesisAddressHistory(address indexed from, address indexed to);
    event DonateToPineconeHistory(address indexed sender, uint256 amount,uint256 count);
    event Level2UpgradeHistory(
        address indexed from,
        uint256 amount,
        uint256 tokenAmount
    );
    event Level3UpgradeHistory(
        address indexed from,
        uint256 amount,
        uint256 tokenAmount
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapAndLiquifyETH(
        uint256 tokensReceived,
        uint256 ethSwapped,
        uint256 tokensIntoLiqudity
    );

    // Only for genesis addresses
    modifier onlyGenesisAddress() {
        require(
            addressState[_msgSender()] == ADDRESS_STATE.GENESIS,
            "Only the genesis address can be upgraded"
        );
        _;
    }

    constructor(
        address payable _teamAddress,
        address payable _daoMainAddress,
        address _mysteryKeyAddr,
        address _usdAddress,
        address _pineUniswapExpress,
        address _priceAddress,
        address _rewardsContractAddress,
        address _promineContractAddress,
        address _authorizationAddress
    )
        ERC20("Pinecone Token", "PCT")
        AssetManager(_usdAddress, _pineUniswapExpress)
        PriceGetter(_priceAddress)
        AuthorizationManager(_authorizationAddress, 0)
    {
        promineContract = IProMine(_promineContractAddress);
        rewardsContract = IRewards(_rewardsContractAddress);
        mysterykeyContract = IMysteryKeyNFT(_mysteryKeyAddr);

        teamTokenAddress = payable(_teamAddress);
        primaryDaoAddress = payable(_daoMainAddress);
        onlineBlockNumber = block.number;

        _totalSupply = GENESIS_ALLOCATION_AMOUNT * MAX_ACTIVATION_LIMIT;

        //Set contract owners
        promineContract.setContractOwner();
        rewardsContract.setContractOwner();

        _mint(address(this), _totalSupply); //Mint the total supply

        setAddressDirector(owner()); //Set as a 3-level address

        genesisAddressCount = 0; //Number of genesis addresses
        activatedAddressCount = 1; //Number of activated addresses

        userDonateCount[owner()] = directorUpgradeCount * 10;
        totalDonate += directorUpgradeCount * 10;

        //Transfer from contract address to contract owner address, create initial token liquidity pool
        _transfer(
            address(this),
            owner(),
            GENESIS_ALLOCATION_AMOUNT * userDonateCount[owner()]
        ); 

        setCreateAddress(owner());
        setCreateAddress(teamTokenAddress);
        setCreateAddress(address(this));

        _isExcludedFromFee[teamTokenAddress] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

    }

    receive() external payable {}

    function snapshot() public onlyAuthorizedRole returns (uint256) {
        return _snapshot();
    }

    function setAllowDonation(bool _allowDonation) external onlyOwner {
        allowDonation = _allowDonation;
    }

    function setErrorMessage(string calldata _errorMessage) external onlyOwner {
        errorMessage = _errorMessage;
    }

    function setExcludedFromSwap(
        address _address,
        bool _status
    ) external onlyOwner {
        _isExcludedFromSwap[_address] = _status;
    }

    //Upgrade from genesis address to level 2 mining address, also known as pine tree address
    function upgradeToLevel2()
        external
        payable
        nonReentrant
        onlyGenesisAddress
    {
        //Activation quantity must be less than the upper limit
        _updateActivationLimit(1);

        // Increase the number of activated addresses
        activatedAddressCount++;

        //Decrease one genesis address
        genesisAddressCount--;

        //Upgrade
        _upgradeToLevel(1);

        //Set address to level 2
        setAddressPine(_msgSender());

        emit Level2UpgradeHistory(_msgSender(), msg.value, upgradeFeeUSDT);
    }

    function upgradeToLevel3()
        external
        payable
        nonReentrant
        onlyGenesisAddress
    {
        //Activation quantity must be less than the upper limit
        _updateActivationLimit(directorUpgradeCount);

        //Increase the number of activated addresses
        activatedAddressCount++;

        //Decrease one genesis address
        genesisAddressCount--;

        //Upgrade
        _upgradeToLevel(directorUpgradeCount);

        //Set to level 3 address
        setAddressDirector(_msgSender());

        emit Level3UpgradeHistory(
            _msgSender(),
            msg.value,
            upgradeFeeUSDT.mul(directorUpgradeCount)
        );
    }

    /// @dev  Only level 2 or above addresses can buy in again, but when the number of mining machines purchased reaches the directorUpgradeCount, it automatically upgrades to a level 3 address.
    function donate(
        address referrer,
        uint256 miningCount
    ) external payable nonReentrant {
        require(referrer != _msgSender(), "Referrer cannot be the same as sender.");
        require(
            addressState[_msgSender()] != ADDRESS_STATE.GENESIS,
            "Only the genesis address can be upgraded"
        );

        _updateActivationLimit(miningCount);

        //Add referral association
        if(referrer==address(0)) referrer = owner();

        if(addressState[_msgSender()] == ADDRESS_STATE.NORMAL){

            //Record invitation data
            rewardsContract.setInitialReferrers(_msgSender(),referrer);

            setCreateAddress(_msgSender());
        }

        selfReferralDonateCount[referrer] +=miningCount;
       
        _upgradeToLevel(miningCount);

        _updateUserAddressState(_msgSender());

        emit DonateToPineconeHistory(_msgSender(), msg.value,miningCount);
    }

    //Hidden function of the mystery box, upgrade ordinary address to genesis address
    function upgradeToGenesisAddress(
        address _address,
        address _inviterAddr
    ) external onlyAuthorizedRole {
        
        if (!_address.isContract() && !_hasCreatedAddress[_address]) {

            rewardsContract.setInitialReferrers(_address,_inviterAddr);

            _initGenesisAddress(_address);
        }
    }

    //Create an address, invitation address
    function createGenesisAddress(
        address _genesisAddress
    ) external {
        require(checkIfAddressIsMine(_msgSender()), errorMessage );
        //Create an address, invitation address
        require(
            !_genesisAddress.isContract(),
            "Contract addresses cannot be used as genesis addresses"
        );

        //Inviter's upper two-level address
        rewardsContract.setInitialReferrers(_genesisAddress,_msgSender());

        //Number of invitations
        selfReferralCount[_genesisAddress]++;

        _initGenesisAddress(_genesisAddress);

        //Invite an address, increase mining speed by 1 point
        promineContract.boostMiningSpeed(_msgSender(), 0);

        emit GenesisAddressHistory(_msgSender(), _genesisAddress);
    }


    function checkIfAddressIsPine(
        address _address
    ) external view returns (bool) {
        return addressState[_address] == ADDRESS_STATE.PINE;
    }

    function checkIfAddressIsDirector(
        address _address
    ) external view returns (bool) {
        return addressState[_address] == ADDRESS_STATE.DIRECTOR;
    }

    function setFees(uint256 _upgradeFeeUSDT, uint256 _spotFeeUSDT) external onlyOwner {
        upgradeFeeUSDT = _upgradeFeeUSDT;
        spotFeeUSDT = _spotFeeUSDT;
    }

    function getReferralIncomes(
        address _address
    ) external view returns (uint256, uint256, uint256) {
        return (
            _referralIncomeLevel1[_address],
            _referralIncomeLevel2[_address],
            _referralIncomeLevel3[_address]
        );
    }

    function setSwapAndLiquifyState(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    // Interface for migrating old customers to use with agents
    function migrateOfficial(
        address referrer,
        address account,
        uint256 miningCount
    ) external onlyAuthorizedRole {
        if(referrer==address(0)) referrer = owner();

        _updateActivationLimit(miningCount);

        require(
            addressState[account] == ADDRESS_STATE.NORMAL,
            "Address is not in NORMAL state"
        );

        require(
            migrationCount.add(miningCount) <= GOVERNANCE_MIGRATION_AMOUNT,
            "Official migration count exceeds maximum limit"
        );

        migrationCount = migrationCount.add(miningCount);

        activatedAddressCount++; 

        _transfer(
            address(this),
            account,
            GENESIS_ALLOCATION_AMOUNT * miningCount
        ); 

        rewardsContract.setInitialReferrers(account,referrer);

        promineContract.addMiningPool(account, miningCount);

        setCreateAddress(account);

        _updateUserAddressState(account);

        _sendNFTByDonation(account);

    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setDirectorTokenAddress(
        address payable directoryAddress
    ) external onlyOwner {
        require(directoryAddress != address(0), "Address should not be zero.");
        
        directorTokenAddress = directoryAddress;

        setCreateAddress(directorTokenAddress);
        _isExcludedFromFee[directorTokenAddress] = true;
        _isExcludedFromSwap[directorTokenAddress] = true;
    }

    // Setting team payout address 8% 
    function setTeamPayoutAddress(
        address payable teamAddress
    ) external onlyOwner {
        require(teamAddress != address(0), "Team address cannot be zero.");
        
        teamTokenAddress = teamAddress;
        setCreateAddress(teamTokenAddress);
    }

    function setPrimaryDaoAddress(
        address payable addressToSet
    ) external onlyOwner {
        require(addressToSet != address(0), "Address cannot be zero");

        primaryDaoAddress = addressToSet;
        setCreateAddress(primaryDaoAddress);
    }

    /// @dev Setting the limit for token=>ETH
    function setRewardExchangeMinAmount(uint256 reward) external onlyOwner {
        require(reward > 0, "Reward amount must be greater than 0");
        rewardExchangeMinAmount = reward;
    }

    /// @dev Setting the quantity for upgrading to level 3 addresses
    function setDirectorUpgradeCount(uint256 count) external onlyOwner {
        directorUpgradeCount = count;
    }

    /// @dev Authorizing NFT operations
    function operateForNFT(
        uint256 rewardAmount,
        uint256 burnAmount
    ) external onlyAuthorizedRole {
        if (burnAmount > 0) _burn(address(this), burnAmount);
        if (rewardAmount > 0) totalRewards = totalRewards.add(rewardAmount); //增加奖励
    }

    /// @dev Function to increase mining speed for the authorizer.
    function boostMiningSpeedForNFT(address user,uint256 boostLevelIndex) external onlyAuthorizedRole {
        promineContract.boostMiningSpeed(user, boostLevelIndex);
    }

    function upgradeAccount(address account, uint256 roleId) public onlyAuthorizedRoleWithId(roleId) {
        require(
            addressState[account] == ADDRESS_STATE.NORMAL,
            "Address is not in NORMAL state"
        );
        uint256 balance = balanceOf(account);

        if (balance >= directorUpgradeCount.mul(GENESIS_ALLOCATION_AMOUNT)  ) {
            if (addressState[account] != ADDRESS_STATE.DIRECTOR) {
                setAddressDirector(account);
            }
        } else if(balance >= GENESIS_ALLOCATION_AMOUNT) {
            if (addressState[account] != ADDRESS_STATE.PINE) {
                setAddressPine(account);
            }
        }

    }


    function setMysteryKeyConfig(uint256 tokenType, address nftAddr) external onlyOwner {
        mysteryKeyNftType = tokenType;
        mysterykeyContract = IMysteryKeyNFT(nftAddr);
    }

    function donateForToken(address referrer, uint256 count) public payable {
        require(referrer != _msgSender(), "Referrer cannot be the same as sender.");
        require(allowDonation, "Donation is not allowed currently");
        require(
            addressState[_msgSender()] != ADDRESS_STATE.GENESIS,
            "Only the genesis address can be upgraded"
        );

        if(addressState[_msgSender()] == ADDRESS_STATE.NORMAL){
            setCreateAddress(_msgSender());
        }

        _updateActivationLimit(count);

        uint256 usdtFeeAmount = spotFeeUSDT.mul(count);
        uint256 ethAmount = convertToETH(usdtFeeAmount);

        require(msg.value >= ethAmount, "the purchase amount does not match");

        if(referrer==address(0)) referrer = owner();
        rewardsContract.setInitialReferrers(_msgSender(),referrer);

        totalReferrals++;

        selfReferralDonateCount[referrer] +=count;

        totalDonate += count;

        userDonateCount[_msgSender()] += count;

        _allocateTokens(_msgSender(),count);

        _updateUserAddressState(_msgSender());

        _allocationToLiquidityAndAccount(ethAmount);
        
        emit DonateToPineconeHistory(_msgSender(), msg.value,count);
    }

    function _updateUserAddressState(address user) private {
        uint256 totalDonateCount = userDonateCount[user] + promineContract.getMiningPoolCount(user);

        if (totalDonateCount >= directorUpgradeCount) {
            if (addressState[user] != ADDRESS_STATE.DIRECTOR) {
                setAddressDirector(user);
            }
        } else {
            if (addressState[user] != ADDRESS_STATE.PINE) {
                setAddressPine(user);
            }
        }
    }


    function _initGenesisAddress(address to) private {

        totalReferrals++;

        setCreateAddress(to);

        setGenesisAddress(to);

        genesisAddressCount++;

        _allocateTokens(to,1);
        
    }


    function _upgradeToLevel(uint256 miningCount) private {
        uint256 usdtFeeAmount = upgradeFeeUSDT.mul(miningCount);

        uint256 ethAmount = convertToETH(usdtFeeAmount);

        require(msg.value >= ethAmount, "the purchase amount does not match");

        //Allocate to liquidity pool
        _allocationToLiquidityAndAccount(ethAmount);

        //Update referral data
        rewardsContract.updateReferralActivations(_msgSender(),miningCount);

        // Increase mining pool in Promine
        promineContract.addMiningPool(
            _msgSender(),
            miningCount
        );

        //When the number of pine trees reaches 10, send an NFT
        _sendNFTByDonation(_msgSender());

        //If it's a Genesis address, decrease the count by 1
        if (addressState[_msgSender()] == ADDRESS_STATE.GENESIS) miningCount--;

        if (miningCount > 0) {
            //Because there is an unactivated quantity, the total number may exceed the issuance limit here, 
            //but the actual activated quantity is the real issuance.
            _allocateTokens(_msgSender(),miningCount);
        }
    }

    /// @dev Token transfer after donation
    function _allocateTokens(address mintAddress,uint256 _miningCount) private {
        uint256 tokensToAllocate = GENESIS_ALLOCATION_AMOUNT.mul(_miningCount);

        if (balanceOf(address(this)) >= tokensToAllocate) {
            _transfer(address(this), mintAddress, tokensToAllocate);
        } else {
            _mint(mintAddress, tokensToAllocate);
        }
    }


    function _allocationToLiquidityAndAccount(uint256 amount) private {
        (uint256 stakePer1, uint256 stakePer2, uint256 stakePer3) = rewardsContract.getStakes(amount);

        totalReferralAmount+= stakePer1+stakePer2+stakePer3;

        (address level1Address, address level2Address, address level3Address) = 
            rewardsContract.getReferrers(_msgSender());

        TransferHelper.safeTransferETH(payable(level1Address), stakePer1);
        _referralIncomeLevel1[level1Address] += stakePer1;

        //Level2
        TransferHelper.safeTransferETH(payable(level2Address), stakePer2);
        _referralIncomeLevel2[level2Address] += stakePer2;

        //Level3
        TransferHelper.safeTransferETH(payable(level3Address), stakePer3);
        _referralIncomeLevel3[level3Address] += stakePer3;

        //30%
        TransferHelper.safeTransferETH(
            payable(primaryDaoAddress),
            amount.mul(_daoAllocationRate).div(100)
        );

        //8%
        TransferHelper.safeTransferETH(
            payable(teamTokenAddress),
            amount.mul(_genesisTeamAllocationPercentage).div(100)
        );

        //4%
        TransferHelper.safeTransferETH(
            payable(directorTokenAddress),
            amount.mul(_boardProfitPercentage).div(100)
        );

        if (
            address(this).balance > 0 && swapAndLiquifyEnabled
        ) {
            _sendETHToPool(address(this).balance);
        }
    }

    // Setting up the creation of a Genesis address
    function setCreateAddress(address _to) private {
        require(!_hasCreatedAddress[_to], "Address already created");
        _hasCreatedAddress[_to] = true;
    }

    function setGenesisAddress(address _to) private {
        addressState[_to] = ADDRESS_STATE.GENESIS;        
    }

    function setAddressPine(address _to) private {
        addressState[_to] = ADDRESS_STATE.PINE;
    }

    function setAddressDirector(address _to) private {
        addressState[_to] = ADDRESS_STATE.DIRECTOR;
    }

    //Available balance
    function availableBalanceOf(
        address _address
    ) public view returns (uint256 Balance) {
        //Addresses of level 2 or above can have available quantities.
        if (checkIfAddressIsMine(_address)) {
            return
                balanceOf(_address).sub(
                    promineContract.getRemainingMiningOutput(
                        _address
                    )
                );
        } else if (addressState[_address] == ADDRESS_STATE.NORMAL)
            return balanceOf(_address);
        else return 0;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _tokenTransfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _tokenTransfer(from, to, amount);
        return true;
    }

    function checkIfAddressIsMine(address _address) public view returns(bool success){
        return addressState[_address] == ADDRESS_STATE.PINE || addressState[_address] == ADDRESS_STATE.DIRECTOR;
    }

    function _tokenTransfer(address from, address to, uint256 amount) private {
        //Check if the amount and account type can execute
        _checkTransferAmount(from, to, amount);

        _takeFeeForTransfer(from, to, amount);

        //Account type must be pine tree or above, transfer will increase mining speed
        if(checkIfAddressIsMine(from)){
            promineContract.boostMiningSpeed(from, 1);
        }

    }

    function _checkTransferAmount(
        address from,
        address to,
        uint256 amount
    ) private view {

        if (
            addressState[from] == ADDRESS_STATE.GENESIS ||
            addressState[to] == ADDRESS_STATE.GENESIS
        ) {
            revert(errorMessage);
        }

        require(
            amount <= availableBalanceOf(from),
            "ERC20: transfer amount exceeds available"
        );
    }

    function _isExcludedSwap(
        address from,
        address to
    ) private view returns (bool) {
        return (_isExcludedFromSwap[from] ||
            _isExcludedFromSwap[to] ||
            to == address(this));
    }

    function _takeFeeForTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            to == address(this)
        ) {
            _transfer(from, to, amount);
            return;
        }

        bool takeSwap = _isExcludedSwap(from, to);

        (
            uint256 tTransferAmount,
            uint256 tLiquidity,
            uint256 tBurned,
            uint256 tReward
        ) = rewardsContract.getValues(amount);

        pendingAddToLiquidityPool = pendingAddToLiquidityPool.add(tLiquidity);

        totalBurned = totalBurned.add(tBurned);
        totalRewards = totalRewards.add(tReward);

        uint256 unspentRewards = totalRewards - totalRewardsSent;

        if (
            !takeSwap &&
            unspentRewards >= rewardExchangeMinAmount
        ) {

            totalRewardsSent = totalRewardsSent.add(rewardExchangeMinAmount);

            //After exchanging to ETH, transfer to the board of directors
            _swapTokensForEth(
                rewardExchangeMinAmount,
                address(this),                
                directorTokenAddress
            );
        }

        
        if (tBurned > 0) _burn(from, tBurned); //Burn amount
        if (tLiquidity > 0) _transfer(from, address(this), tLiquidity); //Record for pending liquidity pool
        if (tReward > 0) _transfer(from, address(this), tReward); //Reward amount is first transferred to the contract address

        if(swapAndLiquifyEnabled && !takeSwap){
            _sendTokenToPool(pendingAddToLiquidityPool);
            pendingAddToLiquidityPool=0;
        }

        _transfer(from, to, tTransferAmount); //Transfer to the recipient's address
    }

    function _sendNFTByDonation(address account) private {
        // Calculate mining count
        uint256 miningCount = promineContract.getMiningPoolCount(account);
        // Calculate the number of NFTs to be sent to the user
        uint256 nftCountToSend = miningCount / 10 - nftSentCount[account];

        // Send NFTs to users
        if (nftCountToSend > 0) {
            // Update mapping that records the number of NFTs sent
            nftSentCount[account] += nftCountToSend;

            mysterykeyContract.safeMint(
                account,
                mysteryKeyNftType,
                nftCountToSend
            );
        }
    }

    function _updateActivationLimit(uint256 count) private {
        require(
            (referralActivationsTotal.add(count)) <= MAX_ACTIVATION_LIMIT,
            "the upper limit has been reached"
        );

        referralActivationsTotal = referralActivationsTotal.add(count);
    }

    function getCirculationSupply() external view returns(uint256 circulationSupply){
        return referralActivationsTotal * GENESIS_ALLOCATION_AMOUNT;
    }


}