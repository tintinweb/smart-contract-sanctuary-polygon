/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: github/BasedFinance/based-finance-contracts/contracts/lib/TransferHelper.sol



pragma solidity ^0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: github/BasedFinance/based-finance-contracts/contracts/interfaces/IVault.sol



pragma solidity ^0.8.0;


interface IVault is IERC20 {
    function deposit(uint256 amount) external;
    function withdraw(uint256 shares) external;
    function want() external pure returns (address);
}
// File: github/BasedFinance/based-finance-contracts/contracts/interfaces/IUniswapV2Router.sol



pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: github/BasedFinance/based-finance-contracts/contracts/interfaces/IUniswapV2Pair.sol



pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: github/BasedFinance/based-finance-contracts/contracts/interfaces/IHyperswapRouter.sol



pragma solidity ^0.8.0;

interface IHyperswapRouter {
    function factory() external pure returns (address);

    function WFTM() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityFTM(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountFTM, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityFTM(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFTM);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityFTMWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFTM);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactFTM(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: github/BasedFinance/based-finance-contracts/contracts/Zapper.sol



pragma solidity ^0.8.0;












contract Zapper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // @NATIVE - native token that is not a part of our zap-in LP
    address private NATIVE;

    struct LiquidityPair {
        address _token0;
        address _token1;
        uint256 _amountToken0;
        uint256 _amountToken1;
        uint256 _liqTokenAmt;
    }

    struct FunctionArgs {
        address _LP;
        address _in;
        address _out;
        address _recipient;
        address _routerAddr;
        address _token;
        uint256 _amount;
        
        uint256 _otherAmt;
        uint256 _swapAmt;
    }

    mapping(address => mapping(address => address)) private tokenBridgeForRouter;

    mapping (address => bool) public useNativeRouter;

    modifier whitelist(address route) {
        require(useNativeRouter[route], "route not allowed");
        _;
    }

    // Based address here
    constructor(address _NATIVE) Ownable() {
        NATIVE = _NATIVE;
    }

    /* ========== External Functions ========== */

    receive() external payable {}

    function NativeToken() public view returns (address) {
        return NATIVE;
    }

    // @_in - Token we want to throw in
    // @amount - amount of our _in
    // @out - address of LP we are going to get
    // @minAmountOfLp - will be calculated on UI including slippage set by user

    function zapInToken(address _in, uint256 amount, address out, address routerAddr, address recipient, uint256 minAmountOfLp) external whitelist(routerAddr) {
        // From an ERC20 to an LP token, through specified router, going through base asset if necessary
        IERC20(_in).safeTransferFrom(msg.sender, address(this), amount);
        // we'll need this approval to add liquidity
        _approveTokenIfNeeded(_in, routerAddr);
       uint256 amountOfLp =  _swapTokenToLP(_in, amount, out, recipient, routerAddr);
        // add require after actual actioin of all functions - will revert lp creation if doesnt meet requirement
        require(amountOfLp >= minAmountOfLp, "lp amount too small");
    }
    // @_in - Token we want to throw in
    // @amount - amount of our _in
    // @out - address of LP we are going to get

    function estimateZapInToken(address _in, address out, address router, uint256 amount) public view whitelist(router) returns (uint256, uint256) {
        // get pairs for desired lp
        // check if we already have one of the assets
        if (_in == IUniswapV2Pair(out).token0() || _in == IUniswapV2Pair(out).token1()) {
            // if so, we're going to sell half of in for the other token we need
            // figure out which token we need, and approve
            address other = _in == IUniswapV2Pair(out).token0() ? IUniswapV2Pair(out).token1() : IUniswapV2Pair(out).token0();
            // calculate amount of in to sell
            uint256 sellAmount = amount.div(2);
            // calculate amount of other token for potential lp
            uint256 otherAmount = _estimateSwap(_in, sellAmount, other, router);
            if (_in == IUniswapV2Pair(out).token0()) {
                return (sellAmount, otherAmount);
            } else {
                return (otherAmount, sellAmount);
            }
        } else {
            // go through native token, that's not in our LP, for highest liquidity
            uint256 nativeAmount = _in == NATIVE ? amount : _estimateSwap(_in, amount, NATIVE, router);
            return estimateZapIn(out, router, nativeAmount);
        }
    }

    function estimateZapIn(address LP, address router, uint256 amount) public view whitelist(router) returns (uint256, uint256) {
        uint256 zapAmount = amount.div(2);

        IUniswapV2Pair pair = IUniswapV2Pair(LP);
        address token0 = pair.token0();
        address token1 = pair.token1();

        if (token0 == NATIVE || token1 == NATIVE) {
            address token = token0 == NATIVE ? token1 : token0;
            uint256 tokenAmount = _estimateSwap(NATIVE, zapAmount, token, router);
            if (token0 == NATIVE) {
                return (zapAmount, tokenAmount);
            } else {
                return (tokenAmount, zapAmount);
            }
        } else {
            uint256 amountToken0 = _estimateSwap(NATIVE, zapAmount, token0, router);
            uint256 amountToken1 = _estimateSwap(NATIVE, zapAmount, token1, router);

            return (amountToken0, amountToken1);
        }
    }

    // from Native to an LP token through the specified router
    // @ out - LP we want to get out of this
    // @ minAmountOfLp will be calculated on UI using estimate function and passed into this function
    function nativeZapIn(uint256 amount, address out, address routerAddr, address recipient, uint256 minAmountOfLp) external whitelist (routerAddr) {
         IERC20(NATIVE).safeTransferFrom(msg.sender, address(this), amount);
         _approveTokenIfNeeded(NATIVE, routerAddr);
        uint256 amountOfLp = _swapNativeToLP(out, amount, recipient, routerAddr);
        require(amountOfLp >= minAmountOfLp);
    }

     // @ _fromLP - LP we want to throw in
    // @ _to - token we want to get out of our LP
    // @ minAmountToken0, minAmountToken1 - coming from UI (min amount of tokens coming from breaking our LP)
    function estimateZapOutToken(address _fromLp, address _to, address _router, uint256 minAmountToken0, uint256 minAmountToken1 ) public view whitelist(_router) returns (uint256) {
        address token0 = IUniswapV2Pair(_fromLp).token0();
        address token1 = IUniswapV2Pair(_fromLp).token1();
        if(_to == NATIVE) {
            if(token0 == NATIVE) {
                return _estimateSwap(token1, minAmountToken1, _to, _router).add(minAmountToken0);
            } else {
                return _estimateSwap(token0, minAmountToken0, _to, _router).add(minAmountToken1);
            }
        }

        if(token0 == NATIVE) {

            if(_to == token1) {
               
                return _estimateSwap(token0, minAmountToken0, _to, _router).add(minAmountToken1);

            } else {
               
                uint256 halfAmountof_to = _estimateSwap(token0, minAmountToken0, _to, _router);
                uint256 otherhalfAmountof_to = _estimateSwap(token1, minAmountToken1, _to, _router);
                return (halfAmountof_to.add(otherhalfAmountof_to));
            }
        } else {
            if (_to == token0) {
              
                return _estimateSwap(token1, minAmountToken1, _to, _router).add(minAmountToken0);

            } else {
              
                uint256 halfAmountof_to = _estimateSwap(token0, minAmountToken0, _to, _router);
                uint256 otherhalfAmountof_to = _estimateSwap(token1, minAmountToken1, _to, _router);
                return halfAmountof_to.add(otherhalfAmountof_to);
            }
        }
    }

    // from an LP token to Native through specified router
    // @in - LP we want to throw in
    // @amount - amount of our LP
    function zapOutToNative(address _in, uint256 amount, address routerAddr, address recipient, uint256 minAmountNative) external whitelist(routerAddr) {
        // take the LP token
        IERC20(_in).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_in, routerAddr);

        LiquidityPair memory pair;

        // get pairs for LP
        pair._token0 = IUniswapV2Pair(_in).token0();
        pair._token1 = IUniswapV2Pair(_in).token1();
        _approveTokenIfNeeded(pair._token0, routerAddr);
        _approveTokenIfNeeded(pair._token1, routerAddr);


        (pair._amountToken0, pair._amountToken1) = IUniswapV2Router(routerAddr).removeLiquidity(pair._token0, pair._token1, amount, 0, 0, address(this), block.timestamp);
        if (pair._token0 != NATIVE) {
            pair._amountToken0 = _swapTokenForNative(pair._token0, pair._amountToken0, address(this), routerAddr);
        }
        if (pair._token1 != NATIVE) {
            pair._amountToken1 = _swapTokenForNative(pair._token1, pair._amountToken1, address(this), routerAddr);
        }
        require (pair._amountToken0.add(pair._amountToken1) >= minAmountNative, "token amt < minAmountNative");
        IERC20(NATIVE).safeTransfer(recipient, pair._amountToken0.add(pair._amountToken1));

    }
    // from an LP token to an ERC20 through specified router

    // from an LP token to Native through specified router
    // @in - LP we want to throw in
    // @amount - amount of our LP
    // @out - token we want to get
    function zapOutToToken(address _in, uint256 amount, address out, address routerAddr, address recipient, uint256 minAmountToken) whitelist(routerAddr) external {

        FunctionArgs memory args;
        LiquidityPair memory pair;

        args._amount = amount;
        args._out = out;
        args._recipient = recipient;
        args._routerAddr = routerAddr;
        
        args._in = _in;

        IERC20(args._in).safeTransferFrom(msg.sender, address(this), args._amount);
        _approveTokenIfNeeded(args._in, args._routerAddr);

        pair._token0 = IUniswapV2Pair(args._in).token0();
        pair._token1 = IUniswapV2Pair(args._in).token1();

        _approveTokenIfNeeded(pair._token0, args._routerAddr);
        _approveTokenIfNeeded(pair._token1, args._routerAddr);

        (pair._amountToken0, pair._amountToken1) = IUniswapV2Router(args._routerAddr).removeLiquidity(pair._token0, pair._token1, args._amount, 0, 0, address(this), block.timestamp);
        if (pair._token0 != args._out) {
            pair._amountToken0 = _swap(pair._token0, pair._amountToken0, args._out, address(this), args._routerAddr);
        }
        if (pair._token1 != args._out) {
            pair._amountToken1 = _swap(pair._token1, pair._amountToken1, args._out, address(this), args._routerAddr);
        }
        require (pair._amountToken0.add(pair._amountToken1) >= minAmountToken, "amt < minAmountToken");
        IERC20(args._out).safeTransfer(args._recipient, pair._amountToken0.add(pair._amountToken1));
    }
   
    
    // @_in - token we want to throw in
    // @amount - amount of our _in
    // @out - token we want to get out
    function _swap(address _in, uint256 amount, address out, address recipient, address routerAddr) public whitelist(routerAddr) returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        address fromBridge = tokenBridgeForRouter[_in][routerAddr];
        address toBridge = tokenBridgeForRouter[out][routerAddr];

        address[] memory path;

        if (fromBridge != address(0) && toBridge != address(0)) {
            if (fromBridge != toBridge) {
                path = new address[](5);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = toBridge;
                path[4] = out;
            } else {
                path = new address[](3);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = out;
            }
        } else if (fromBridge != address(0)) {
            if (out == NATIVE) {
                path = new address[](3);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = NATIVE;
            } else {
                path = new address[](4);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = out;
            }
        } else if (toBridge != address(0)) {
            path = new address[](4);
            path[0] = _in;
            path[1] = NATIVE;
            path[2] = toBridge;
            path[3] = out;
        } else if (_in == NATIVE || out == NATIVE) {
            path = new address[](2);
            path[0] = _in;
            path[1] = out;
        } else {
            // Go through Native
            path = new address[](3);
            path[0] = _in;
            path[1] = NATIVE;
            path[2] = out;
        }
        uint256 tokenAmountEst = _estimateSwap(_in, amount, out, routerAddr);

        uint256[] memory amounts = router.swapExactTokensForTokens(amount, tokenAmountEst, path, recipient, block.timestamp);
        require(amounts[amounts.length-1] >= tokenAmountEst, "amount smaller than estimate");
        return amounts[amounts.length - 1];
    }
    // @_in - token we want to throw in
    // @amount - amount of our _in
    // @out - token we want to get out
    function _estimateSwap(address _in, uint256 amount, address out, address routerAddr) public view whitelist(routerAddr) returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        address fromBridge = tokenBridgeForRouter[_in][routerAddr];
        address toBridge = tokenBridgeForRouter[out][routerAddr];

        address[] memory path;

        if (fromBridge != address(0) && toBridge != address(0)) {
            if (fromBridge != toBridge) {
                path = new address[](5);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = toBridge;
                path[4] = out;
            } else {
                path = new address[](3);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = out;
            }
        } else if (fromBridge != address(0)) {
            if (out == NATIVE) {
                path = new address[](3);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = NATIVE;
            } else {
                path = new address[](4);
                path[0] = _in;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = out;
            }
        } else if (toBridge != address(0)) {
            path = new address[](4);
            path[0] = _in;
            path[1] = NATIVE;
            path[2] = toBridge;
            path[3] = out;
        } else if (_in == NATIVE || out == NATIVE) {
            path = new address[](2);
            path[0] = _in;
            path[1] = out;
        } else {
            // Go through Native
            path = new address[](3);
            path[0] = _in;
            path[1] = NATIVE;
            path[2] = out;
        }

        uint256[] memory amounts = router.getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }
    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token, address router) private {
        if (IERC20(token).allowance(address(this), router) == 0) {
            IERC20(token).safeApprove(router, type(uint256).max);
        }
    }
    
    function _swapTokenToLP(address _in, uint256 amount, address out, address recipient, address routerAddr) private returns (uint256) {
       
        FunctionArgs memory args;
            args._in = _in;
            args._amount = amount;
            args._out = out;
            args._recipient = recipient;
            args._routerAddr = routerAddr;
            
        LiquidityPair memory pair;

        if (args._in == IUniswapV2Pair(args._out).token0() || args._in == IUniswapV2Pair(args._out).token1()) { 

            args._token = args._in == IUniswapV2Pair(args._out).token0() ? IUniswapV2Pair(args._out).token1() : IUniswapV2Pair(args._out).token0();
            // calculate args._amount of _in to sell
            args._swapAmt = args._amount.div(2);
            args._otherAmt = _swap(args._in, args._swapAmt, args._token, address(this), args._routerAddr);
            _approveTokenIfNeeded(args._token, args._routerAddr);
            // execute swap
           
            (pair._amountToken0 , pair._amountToken1 , pair._liqTokenAmt) = 
            IUniswapV2Router(args._routerAddr).addLiquidity(
                args._in, 
                args._token, 
                args._amount.sub(args._swapAmt), 
                args._otherAmt, 
                args._swapAmt , 
                args._otherAmt, 
                args._recipient, 
                block.timestamp);
            
            if (args._in == IUniswapV2Pair(args._out).token0()) {
                _dustDistribution(  args._swapAmt, 
                                    args._otherAmt, 
                                    pair._amountToken0, 
                                    pair._amountToken1, 
                                    args._in, 
                                    args._token, 
                                    args._recipient);

            } else {
                 _dustDistribution( args._otherAmt, 
                                    args._swapAmt, 
                                    pair._amountToken1, 
                                    pair._amountToken0, 
                                    args._in, 
                                    args._token, 
                                    args._recipient);
            }
            return pair._liqTokenAmt;
        } else {
            // go through native token for highest liquidity
            uint256 nativeAmount = _swapTokenForNative(args._in, args._amount, address(this), args._routerAddr);
            return _swapNativeToLP(args._out, nativeAmount, args._recipient, args._routerAddr);
        }
    }
    
    // @amount - amount of our native token
    // @out - LP we want to get
    function _swapNativeToLP(address out, uint256 amount, address recipient, address routerAddress) private returns (uint256) {
        
        IUniswapV2Pair pair = IUniswapV2Pair(out);
        address token0 = pair.token0();  
        address token1 = pair.token1();  
        uint256 liquidity;

        liquidity = _swapNativeToEqualTokensAndProvide(token0, token1, amount, routerAddress, recipient);
        return liquidity;
    }

    function _dustDistribution(uint256 token0, uint256 token1, uint256 amountToken0, uint256 amountToken1, address native, address token, address recipient) private {
        uint256 nativeDust = token0.sub(amountToken0);
        uint256 tokenDust = token1.sub(amountToken1);
        if (nativeDust > 0) {
            IERC20(native).safeTransfer(recipient, nativeDust);
        }
        if (tokenDust > 0) {
            IERC20(token).safeTransfer(recipient, tokenDust);
        }

    }
    // @token0 - swap Native to this , and provide this to create LP
    // @token1 - swap Native to this , and provide this to create LP
    // @amount - amount of native token
    function _swapNativeToEqualTokensAndProvide(address token0, address token1, uint256 amount, address routerAddress, address recipient) private returns (uint256) {
        FunctionArgs memory args;
        args._amount = amount;
        args._recipient = recipient;
        args._routerAddr = routerAddress;
       
        args._swapAmt = args._amount.div(2);

        LiquidityPair memory pair;
        pair._token0 = token0;
        pair._token1 = token1;

        IUniswapV2Router router = IUniswapV2Router(args._routerAddr);

        if (pair._token0 == NATIVE) {
            args._otherAmt= _swapNativeForToken(pair._token1, args._swapAmt, address(this), args._routerAddr);
            _approveTokenIfNeeded(pair._token0, args._routerAddr);
            _approveTokenIfNeeded(pair._token1, args._routerAddr);

            (pair._amountToken0, pair._amountToken1, pair._liqTokenAmt) = 
            router.addLiquidity(    pair._token0, 
                                    pair._token1, 
                                    args._swapAmt, 
                                    args._otherAmt, 
                                    args._swapAmt, 
                                    args._otherAmt, 
                                    args._recipient, 
                                    block.timestamp);
            _dustDistribution(  args._swapAmt, 
                                args._otherAmt, 
                                pair._amountToken0, 
                                pair._amountToken1, 
                                pair._token0, 
                                pair._token1, 
                                args._recipient);
            return pair._liqTokenAmt;
        } else {
            args._otherAmt = _swapNativeForToken(pair._token0,  args._swapAmt, address(this), args._routerAddr);
            _approveTokenIfNeeded( pair._token0, args._routerAddr);
            _approveTokenIfNeeded( pair._token1, args._routerAddr);

            (pair._amountToken0, pair._amountToken1, pair._liqTokenAmt) = 
            router.addLiquidity(pair._token0, 
                                pair._token1, 
                                args._otherAmt, 
                                args._swapAmt, 
                                args._otherAmt, 
                                args._swapAmt, 
                                args._recipient, 
                                block.timestamp);
            _dustDistribution(  args._otherAmt, 
                                args._swapAmt, 
                                pair._amountToken1, 
                                pair._amountToken0,  
                                pair._token1, 
                                pair._token0, 
                                args._recipient);
            return pair._liqTokenAmt;
        }
    }
    // @token - swap Native to this token
    // @amount - amount of native token
    function _swapNativeForToken(address token, uint256 amount, address recipient, address routerAddr) private returns (uint256) {
        address[] memory path;
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        if (tokenBridgeForRouter[token][routerAddr] != address(0)) {
            path = new address[](3);
            path[0] = NATIVE;
            path[1] = tokenBridgeForRouter[token][routerAddr];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = NATIVE;
            path[1] = token;
        }
        uint256 tokenAmt = _estimateSwap(NATIVE, amount, token, routerAddr);
        uint256[] memory amounts = router.swapExactTokensForTokens(amount, tokenAmt, path, recipient, block.timestamp);
        return amounts[amounts.length - 1];
    }
     // @token - swap this token to Native
    // @amount - amount of native token
    function _swapTokenForNative(address token, uint256 amount, address recipient, address routerAddr) private returns (uint256) {
        address[] memory path;
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        if (tokenBridgeForRouter[token][routerAddr] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = tokenBridgeForRouter[token][routerAddr];
            path[2] = NATIVE;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = NATIVE;
        }

        uint256 tokenAmt = _estimateSwap(token, amount, NATIVE, routerAddr);
        uint256[] memory amounts = router.swapExactTokensForTokens(amount, tokenAmt, path, recipient, block.timestamp);
        return amounts[amounts.length - 1];
    }

      // @in - token we want to throw in
    // @amount - amount of our token
    // @out - token we want to get
    function swapToken(address _in, uint256 amount, address out, address routerAddr, address _recipient, uint256 minAmountOut) private {
        IERC20(_in).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_in, routerAddr);
       uint256 tokensOut =  _swap(_in, amount, out, _recipient, routerAddr);
       require (tokensOut >= minAmountOut);
    }
    
     // @in - token we want to throw in
    // @amount - amount of our token
    
    function swapToNative(address _in, uint256 amount, address routerAddr, address _recipient, uint256 minAmountOut) private {
        IERC20(_in).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_in, routerAddr);
        uint256 amountNative = _swapTokenForNative(_in, amount, _recipient, routerAddr);
        require (amountNative >= minAmountOut);
    }
    
   


    /* ========== RESTRICTED FUNCTIONS ========== */

    function setNativeToken(address _NATIVE) external onlyOwner {
        NATIVE = _NATIVE;
    }

    function setTokenBridgeForRouter(address token, address router, address bridgeToken) external onlyOwner {
        tokenBridgeForRouter[token][router] = bridgeToken;
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function setUseNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = true;
    }

    function removeNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = false;
    }
}