/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.17;

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

pragma solidity ^0.8.17;

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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.17;




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

// File: contracts/Tranzacto.sol


pragma solidity ^0.8.17;





uint constant MAX_UINT = 2**256 - 1;


interface IDODOV2 {
    function querySellBase(
        address trader, 
        uint256 payBaseAmount
    ) external view  returns (uint256 receiveQuoteAmount,uint256 mtFee);

    function querySellQuote(
        address trader, 
        uint256 payQuoteAmount
    ) external view  returns (uint256 receiveBaseAmount,uint256 mtFee);
}

interface IDODOProxy {

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}

contract DODOProxyIntegrate{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address dodoV2Pool = 0x0Baa76f0aD48b50E4880623B4E6E4578A03F5Cc0; //ERR pool on DODO
    address fromToken = 0xFB32513135e3267995268E3099d2B6114d20B6eD; //Polygon ERR
    address toToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; //Polygon USDT
    address dodoApprove = 0x6D310348d5c12009854DFCf72e0DF9027e8cb4f4; //Dodo Approve Address
    address dodoProxy = 0xa222e6a71D1A1Dd5F279805fbe38d5329C1d0e70; //Dodo proxy address

    function useDodoSwapV2(address _buyer, address _receiver, uint256 _amount) public {
        
        uint256 fromTokenAmount = _amount; //sellBaseAmount
        uint256 slippage = 1;


        IERC20(fromToken).transferFrom(_buyer, address(this), fromTokenAmount);
        //(uint256 receivedQuoteAmount,) = IDODOV2(dodoV2Pool).querySellBase(msg.sender, fromTokenAmount);
        (uint256 receivedBaseAmount,) = IDODOV2(dodoV2Pool).querySellQuote(_buyer, fromTokenAmount);
        uint256 minReturnAmount = receivedBaseAmount.mul(100 - slippage).div(100);
        
        address[] memory dodoPairs = new address[](1); //one-hop
        dodoPairs[0] = dodoV2Pool;
  
        uint256 directions = 1; 
        uint256 deadline = block.timestamp + 60 * 10;

        _generalApproveMax(fromToken, dodoApprove, fromTokenAmount);

        uint256 returnAmount = IDODOProxy(dodoProxy).dodoSwapV2TokenToToken(
            fromToken,
            toToken,
            fromTokenAmount,
            minReturnAmount,
            dodoPairs,
            directions,
            false,
            deadline
        );

        IERC20(toToken).safeTransfer(_receiver, returnAmount);
        //IERC20(toToken).safeTransferFrom(msg.sender, _seller, returnAmount);
        

    }

    function _generalApproveMax(
        address token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                IERC20(token).safeApprove(to, 0);
            }
            IERC20(token).safeApprove(to, MAX_UINT);
        }
    }
}

contract tranzacto is DODOProxyIntegrate {
using SafeMath for uint256;

    address public owner;
    //address public dexRouter;

    IERC20 public ERR = IERC20(0xFB32513135e3267995268E3099d2B6114d20B6eD);
    IERC20 public USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 public feeAddress = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); //USDT
    address public feeReceiver;

    uint256 constant months = 30 days;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    uint256 private invoice;
    uint256 public amountERR;
    uint256 public maticDrop = 5*10**16;
    uint256 public requiredERR = 100000*10**9;
    uint256 public fees = 1000000;
    uint256 public feesInERR = 10000*10**9;

    struct sellerERRVault{
        string sellerName;
        uint256 falseAmount;
        uint256 remainAmount;
        uint256 monthlyAllowed;
        uint256 nextMonth;
    }
    struct sellerTranzacto{
        string sellerName;
        uint256 salesMade;
    }
    struct approvedPayment{
        address seller;
        string What;
        IERC20 currency;
        uint256 amount;
        string status;
        bool isPending;
    }
    
    struct acceptedCurrencies{
        string currencyName;
        uint8 decimals;
    }

    mapping(address => bool) public blackList;
    mapping(address => sellerERRVault) public acceptERR;
    mapping(address => bool) public receiveERR;
    mapping(address => sellerTranzacto) public approvedSeller;
    mapping(address => bool) public isSeller;
    mapping(IERC20 => acceptedCurrencies) public currenciesAccepted;
    mapping(IERC20 => bool) public checkCurrency;
    mapping(address => mapping(uint256 => approvedPayment)) public paying;
    mapping(address => bool) public maticReceived;
    mapping(address => uint256) public balanceERR;

/* Events */
   event changeOwner(address OldOwner, address NewOwner);
   event returnMatic(address To, uint256 Amount, uint8 Decimals);
   event paymentApproved(address Buyer, uint256 Invoice);
   event paidFor(uint256 Invoice, string Item, IERC20 Currency, uint256 Amount);

/*  @dev: Check if contract owner */
    modifier onlyOwner (){
        require(msg.sender == owner, "Not Owner!");
        _;
    }   
/*  @dev: prevent reentrancy when function is executing */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
/*  @dev: Black Listed wallets */
    modifier isNotBlacklisted(address _wallet){
        require(blackList[_wallet] != true, "Wallet is Blacklisted!");
        _;
    }
/*  @dev: Check if Currency */
    modifier isCurrency(IERC20 _currency){
        require(checkCurrency[_currency] == true, "Currency not accpeted!");
        _;
    }
    constructor() {
        owner = msg.sender;
        feeReceiver = msg.sender;
        // Add ERR
        currenciesAccepted[ERR].currencyName = "ERR";
        currenciesAccepted[ERR].decimals = 9;
        checkCurrency[ERR] = true;
        // Add USDT
        currenciesAccepted[USDT].currencyName = "USDT";
        currenciesAccepted[USDT].decimals = 6;
        checkCurrency[USDT] = true;
        _status = _NOT_ENTERED;
    }
    function returnDoDO() public view 
    returns(
        address pool, 
        address from, 
        address to, 
        address approve, 
        address proxy){
            return(dodoV2Pool, fromToken, toToken, dodoApprove, dodoProxy);
    }
    function changeDodoV2Pool(address _newPool) external onlyOwner{
        require(_newPool != address(0), "address zero not allowed");
        dodoV2Pool = _newPool; 
    }
    function changeDodoProxy(address _newProxy) external onlyOwner{
        require(_newProxy != address(0), "address zero not allowed");
        dodoProxy = _newProxy;
    }
    function changeDodoApprove(address _newApprove) external onlyOwner{
        require(_newApprove != address(0), "address zero not allowed");
        dodoApprove = _newApprove;
    }
    function changeToToken(address _newToToken) external onlyOwner{
        require(_newToToken != address(0), "address zero not allowed");
        toToken = _newToToken;
    }
    function changeFromToken(address _newFromToken) external onlyOwner{
        require(_newFromToken != address(0), "address zero not allowed");
        fromToken = _newFromToken;
    }

/*. @dev: Change the contract owner */
    function transferOwnership(address _newOwner)external onlyOwner{
        require(_newOwner != address(0x0),"Zero Address");
        emit changeOwner(owner, _newOwner);
        owner = _newOwner;
    }
    function changeFeeReceiver(address _newReceiver) external onlyOwner{
        require(_newReceiver != address(0x0), "Address Zero");
        feeReceiver = _newReceiver;
    }
    function setMaticDrop(uint256 _amount, uint8 _decimals) external onlyOwner{
        maticDrop = _amount*10**_decimals;
    }
    function setRequiredERR(uint256 _required) external onlyOwner{
        require(_required > 1, "at least 1 ERR");
        requiredERR = _required*10**9;
    }
    function kyc(address _user) external onlyOwner{
        //require(balanceERR[_user] >= requiredERR, "User should deposit ERR first");
        require(maticReceived[_user] != true, "Matic received!");
        if(address(this).balance >= maticDrop){
            payable(_user).transfer(maticDrop);
            maticReceived[_user] = true;
        }
    }
    function setFee(IERC20 feeAdd, uint256 _newFee) external onlyOwner{
        require(feeAdd != IERC20(address(0x0)), "Address zero");
        feeAddress = feeAdd;
        fees = _newFee;
    }
    function setFeeERR(uint256 _newFeeERR) external onlyOwner{
        feesInERR = _newFeeERR;
    }
    function addSeller(string memory _name, address _seller, uint256 pA, bool _receiveERR) external onlyOwner{
        if(_receiveERR == true){
            acceptERR[_seller].sellerName = _name;
            acceptERR[_seller].monthlyAllowed = pA;
            receiveERR[_seller] = true;
            isSeller[_seller] = true;
        }
        else{
            approvedSeller[_seller].sellerName = _name;
            isSeller[_seller] = true;
        }
        
    }
    function addCurrency(string memory _name, IERC20 _currency, uint8 _dcml) external onlyOwner{
        require(_currency != IERC20(address(0x0)), "Zero address");
        currenciesAccepted[_currency].currencyName = _name;
        currenciesAccepted[_currency].decimals = _dcml;
        checkCurrency[_currency] = true;
    }
    // First the seller creates order for the buyer
    function approvePay(address _buyer, string memory _what, IERC20 _currency, uint256 _amount) isCurrency(_currency) external nonReentrant{
        require(isSeller[msg.sender] == true, "Seller not Approved");
        invoice ++;
        paying[_buyer][invoice].seller = msg.sender;
        paying[_buyer][invoice].What = _what;
        paying[_buyer][invoice].currency = _currency;
        paying[_buyer][invoice].amount = _amount;
        paying[_buyer][invoice].status = "Pending";
        paying[_buyer][invoice].isPending = true;
        emit paymentApproved(_buyer, invoice);
    }
    function approveBuy() external{
        ERR.approve(dodoApprove, MAX_UINT);
        USDT.approve(dodoApprove, MAX_UINT);
    }
    function approveBuyProxy() external{
        ERR.approve(dodoProxy, MAX_UINT);
    }
    function approveBuyV2() external{
        ERR.approve(dodoV2Pool, MAX_UINT);
    }
    // The buyer get the invoice number from the seller then pays for the seller
    function payFor(uint256 _invoice, uint256 _fee) external nonReentrant{
        require(paying[msg.sender][_invoice].isPending == true, "no invoice ");
        address _seller = paying[msg.sender][_invoice].seller;
        string memory item = paying[msg.sender][_invoice].What;
        IERC20 _currency =  paying[msg.sender][_invoice].currency;
        uint256 _amount = paying[msg.sender][_invoice].amount;
        //require approve from fee currency address
        //the contract is deployed with USDT for fees
        if(feeAddress.balanceOf(msg.sender) < fees){
            if(_fee < feesInERR){
                ERR.transferFrom(msg.sender, feeReceiver, feesInERR);
            }
            else{
                ERR.transferFrom(msg.sender, feeReceiver, _fee);
            }
        }
        else{
            feeAddress.transferFrom(msg.sender, feeReceiver, fees);
        }
        //check payment currency
        if(_currency == ERR && receiveERR[_seller] != true){
            useDodoSwapV2(msg.sender, _seller, _amount);
        }
        else if(_currency == ERR && receiveERR[_seller] == true){
            //need to approve from ERR contract first
            ERR.transferFrom(msg.sender, address(this), _amount);
            acceptERR[_seller].falseAmount += _amount;
            acceptERR[_seller].remainAmount += _amount;
            amountERR += _amount;
        }
        else{
            //need approve from currency contract to this contract as spender
            _currency.transferFrom(msg.sender, _seller, _amount);
        }
        paying[msg.sender][_invoice].isPending == false;
        paying[msg.sender][_invoice].status = "Paid";
        emit paidFor(_invoice, item, _currency, _amount);
    }
    function sellerWithdraw(uint256 _amount) external{
        require(acceptERR[msg.sender].nextMonth <= block.timestamp, "till next month!");
        require(isSeller[msg.sender] == true, "You are not a seller!");
        require(acceptERR[msg.sender].remainAmount >= _amount, "amount is bigger than balance");
        uint256 amount = acceptERR[msg.sender].falseAmount.mul(acceptERR[msg.sender].monthlyAllowed).div(100);
        if(amount > acceptERR[msg.sender].remainAmount){
            ERR.transfer(msg.sender, acceptERR[msg.sender].remainAmount);
        }
        else{
            ERR.transfer(msg.sender, amount);
        }
        acceptERR[msg.sender].nextMonth = block.timestamp.add(months);
        acceptERR[msg.sender].remainAmount -= amount;
        amountERR -= amount;
    }

/*  @dev: Withdrwa Matic token!*/
    function withdrawalMatic(uint256 _amount, uint8 decimal, address to) external onlyOwner() {
        require(address(this).balance >= _amount,"Balanace"); //No matic balance available
        require(to != address(0), "Zero Address");
        uint256 dcml = 10 ** decimal;
        emit returnMatic(to, _amount, decimal);
        payable(to).transfer(_amount*dcml);      
    }
/* @dev: contract is payable (can receive Matic) */
    receive() external payable {}
}



               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
               **********************************************************/