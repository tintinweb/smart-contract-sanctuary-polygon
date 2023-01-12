/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.17;

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

pragma solidity ^0.8.17;

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

// File: contracts/p2pMainnet-Test.sol



/*
@dev: P2P smart contract ISLAMI
*/




pragma solidity = 0.8.17;
   using SafeMath for uint256;
 
   uint256 constant MAX_UINT = 2**256 - 1;

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

contract Swap{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public slippage = 1;

    function getPriceBuy(address _pool, address _sender, uint256 _amount, uint256 _slippage) public view returns(uint256 _Price){
        (uint256 receivedBaseAmount,) = IDODOV2(_pool).querySellQuote(_sender, _amount);
        uint256 minReturnAmount = receivedBaseAmount.mul(100 - _slippage).div(100);
        return(minReturnAmount);
    }
    function getPriceSell(address _pool, address _sender, uint256 _amount, uint256 _slippage) public view returns(uint256 _Price){
        (uint256 receivedQuoteAmount,) = IDODOV2(_pool).querySellBase(_sender, _amount);
        uint256 minReturnAmount = receivedQuoteAmount.mul(100 - _slippage).div(100);
        return(minReturnAmount);
    }

    address USDCpool = 0x9723520d16690075e80cd8108f7C474784F96bCe; //ISLAMI pool on DODO
    address USDTpool = 0x14afbB9E6Ab4Ab761f067fA131e46760125301Fc;
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address dodoApprove = 0x6D310348d5c12009854DFCf72e0DF9027e8cb4f4; //Dodo Approve Address
    address dodoProxy = 0xa222e6a71D1A1Dd5F279805fbe38d5329C1d0e70; //Dodo proxy address

    function useDodoSwapV2(address fromToken, address toToken, uint256 _amount, uint256 _slippage, uint256 directions) internal {
        address dodoV2Pool = 0x9723520d16690075e80cd8108f7C474784F96bCe;
        if(fromToken == USDT || toToken == USDT){
            dodoV2Pool = USDTpool;
        }
        uint256 minAmount;
        if(_slippage < slippage){
            _slippage = slippage;
        }
        // check swap if buy or sell
        IERC20(fromToken).transferFrom(msg.sender, address(this), _amount);
        if(directions == 0 || directions == 1){
            minAmount = getPriceBuy(dodoV2Pool, msg.sender, _amount, slippage);
        }
        else{
            minAmount = getPriceSell(dodoV2Pool, msg.sender, _amount, slippage);
        }
        //check dodo pair
        address[] memory dodoPairs = new address[](1); //one-hop
        dodoPairs[0] = dodoV2Pool;
        //set dead line
        uint256 deadline = block.timestamp + 60 * 10;
        //approve tokens 
        _generalApproveMax(fromToken, dodoApprove, _amount);
        // get return amount
        uint256 returnAmount = IDODOProxy(dodoProxy).dodoSwapV2TokenToToken(
            fromToken,
            toToken,
            _amount,
            minAmount,
            dodoPairs,
            directions,
            false,
            deadline
        );
        IERC20(toToken).safeTransfer(msg.sender, returnAmount);
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
contract ISLAMIp2p is Swap {

/*
@dev: Private values
*/  
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address public feeReceiver;
    address public constant burn = 0x000000000000000000000000000000000000dEaD;

    IERC20 ISLAMI = IERC20(0x9c891326Fd8b1a713974f73bb604677E1E63396D);

    uint256 public orN; //represents order number created
    uint256 public sellOrders;
    uint256 public buyOrders;
    uint256 public totalOrders;
    uint256 public maxOrders = 60;
    uint256 public canceledOrders;
    uint256 public ISLAMIinOrder;
    uint256 public USDinOrder;
    uint256 public burned;
    uint256 private maxISLAMI;
    uint256 constant private ISLAMIdcml = 10**7;
    uint256 constant private USDdcml = 10**6;

    uint256 public activationFee = 1000*10**7;
    uint256 public p2pFee = 1;
    uint256 public feeFactor = 1000;
    uint256 public range = 30;

    struct orderDetails{
        uint256 orderType; // 1 = sell , 2 = buy
        uint256 orderNumber;
        address sB; //seller or buyer
        IERC20 orderCurrency;
        uint256 orderFalseAmount;
        uint256 remainAmount;
        uint256 orderPrice;
        uint256 currencyFalseAmount;
        uint256 remainCurrency;
        uint256 dateCreated;
        uint256 orderLife;
        bool orderStatus; // represents if order is completed or not
    }
    struct userHistory{
        uint256 ordersCount;
        uint256 sold;
        uint256 bought;
    }

    event orderCreated(address OrderOwner, uint256 Type, uint256 Amount, uint256 Price, IERC20 Currency);
    event orderCancelled(address OrderOwner, uint256 Type);
    event orderBuy(address OrderOwner, address OrderTaker, uint256 Amount, uint256 Price);
    event orderSell(address OrderOwner, address OrderTaker, uint256 Amount, uint256 Price);
    event ISLAMIswap(string Type, uint256 Amount, address Swaper);

    mapping(address => orderDetails) public p2p;
    mapping(address => uint256) public monopoly;
    mapping(address => userHistory) public userOrders;
    mapping(address => bool) public canCreateOrder;
    mapping(address => uint256) public isActivated;

    orderDetails[] public OrderDetails;
    /*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(){
        feeReceiver = msg.sender;
        orN = 0;
        maxISLAMI = 75000 * ISLAMIdcml;
    }
    function setMaxISLAMI(uint256 _newMax) external{
        require(msg.sender == feeReceiver, "Not authorized to change Max");
        maxISLAMI = _newMax * ISLAMIdcml;
    }
    /*function getSell(uint256 _amountISLAMI) public view returns(uint256 _price){
        _price = getPriceSell(USDCpool, address(this), _amountISLAMI, 1);
        return(_price);
    }
    function getBuy(uint256 _amountUSDC) public view returns(uint256 _price){
        _price = getPriceBuy(USDCpool, address(this), _amountUSDC, 1);
        return(_price);
    }*/
    function ISLAMIprice() public view returns(uint256 _price){
        _price = getPriceSell(USDCpool, address(this), 10000000, 1);
        return(_price);
    }
    function swapISLAMI(uint256 _type, address _currency, uint256 _amount, uint256 _slippage) external{
        string memory Type;
        address _fromToken;
        address _toToken;
        uint256 amount;
        if(_type == 0 || _type == 1){
            Type = "Buy";
            _fromToken = _currency;
            _toToken = address(ISLAMI);
            amount = _amount * USDdcml;
        }
        else{
            Type = "Sell";
            _fromToken = address(ISLAMI);
            _toToken = _currency;
            amount = _amount * ISLAMIdcml;
            require(amount <= maxISLAMI, "Price impact is too high");
        }
        useDodoSwapV2(_fromToken, _toToken, amount, _slippage, _type);
        emit ISLAMIswap(Type, amount, msg.sender);
    }
    function changeFee(uint256 _activationFee, uint256 _p2pFee, uint256 _feeFactor) external {
        require(msg.sender == feeReceiver, "Not authorized to change fee");
        require(_p2pFee >= 1 && _feeFactor >= 100,"Fee can't be zero");
        activationFee = _activationFee.mul(ISLAMIdcml);
        p2pFee = _p2pFee;
        feeFactor = _feeFactor;
    }
    function changeRange(uint256 _range) external{
        require(msg.sender == feeReceiver, "Not authorized to change fee");
        range = _range;
    }
    function activateP2P() external nonReentrant{
        require(isActivated[msg.sender] != 1, "User P2P is already activated!");
        //require approve from ISLAMI smart contract
        ISLAMI.transferFrom(msg.sender, burn, activationFee);
        canCreateOrder[msg.sender] = true;
        isActivated[msg.sender] = 1;
        burned += activationFee;
    }
    function createOrder(
        uint256 _type, 
        uint256 _islamiAmount, 
        uint256 _currencyAmount, 
        IERC20 _currency
        ) 
        public 
        nonReentrant
        {
        require(monopoly[msg.sender] < block.timestamp, "Monopoly not allowed");
        require(canCreateOrder[msg.sender] == true, "User have an active order");
        require(_type == 1 || _type == 2, "Type not found (Buy or Sell)");
        totalOrders++;
        orN++;
        uint256 _price;
        uint256 _p2pFee;
        p2p[msg.sender].orderLife = block.timestamp.add(3 days);
        //monopoly[msg.sender] = block.timestamp.add(3 days).add(1 hours);
        p2p[msg.sender].orderNumber = orN;
        p2p[msg.sender].sB = msg.sender;
        p2p[msg.sender].orderType = _type;
        p2p[msg.sender].dateCreated = block.timestamp;
        p2p[msg.sender].orderFalseAmount = _islamiAmount;
        p2p[msg.sender].orderCurrency = _currency;
        p2p[msg.sender].currencyFalseAmount = _currencyAmount;
        uint256 currencyAmount = _currencyAmount.mul(USDdcml);
        _price = currencyAmount.div(_islamiAmount);
        uint256 dexPrice = ISLAMIprice();
        uint256 _limit = dexPrice.mul(range).div(100);
        uint256 _up = dexPrice.add(_limit);
        uint256 _down = dexPrice.sub(_limit);
        require(_price < _up && _price > _down, "behing range");
        p2p[msg.sender].orderPrice = _price;
        if(_type == 1){ //sell ISLAMI
            p2p[msg.sender].remainAmount = _islamiAmount.mul(ISLAMIdcml);
            _p2pFee = _islamiAmount.mul(ISLAMIdcml).mul(p2pFee).div(feeFactor);
            //require approve from ISLAMICOIN contract
            ISLAMI.transferFrom(msg.sender, address(this), _islamiAmount.mul(ISLAMIdcml));
            ISLAMI.transferFrom(msg.sender, burn, _p2pFee);
            ISLAMIinOrder += _islamiAmount.mul(ISLAMIdcml);
            sellOrders++;
            burned += _p2pFee;
        }
        else if(_type == 2){ //buy ISLAMI
            p2p[msg.sender].remainCurrency = _currencyAmount.mul(USDdcml);
            _p2pFee = _currencyAmount.mul(USDdcml).mul(p2pFee).div(feeFactor);
            _currency.transferFrom(msg.sender, address(this), _currencyAmount.mul(USDdcml));
            _currency.transferFrom(msg.sender, feeReceiver, _p2pFee);
            USDinOrder += _currencyAmount.mul(USDdcml);
            buyOrders++;
        }
        OrderDetails.push(orderDetails
        (
                _type,
                orN, 
                msg.sender,
                _currency, 
                _islamiAmount.mul(ISLAMIdcml), 
                _islamiAmount.mul(ISLAMIdcml),
                _price,
                _currencyAmount.mul(USDdcml),
                _currencyAmount.mul(USDdcml),
                p2p[msg.sender].dateCreated,
                p2p[msg.sender].orderLife,
                false
                )
                );
        canCreateOrder[msg.sender] = false;
        userOrders[msg.sender].ordersCount++;
        emit orderCreated(msg.sender, _type, _islamiAmount, _price, _currency);
    }
    function getOrders() public view returns (orderDetails[] memory){
        return OrderDetails;
    }
    function adminCancel(uint256 _orderIndex, address _orderOwner) external{
        require(msg.sender == feeReceiver, "not admin");
        fixOrders(_orderIndex);
        deleteOrder(_orderOwner);
        delete p2p[_orderOwner];
        canCreateOrder[_orderOwner] = true;
        canceledOrders++;
        emit orderCancelled(_orderOwner, p2p[_orderOwner].orderType);
    }
    function forceCancel(uint256 _orderIndex, address _orderOwner) internal{
        fixOrders(_orderIndex);
        deleteOrder(_orderOwner);
        delete p2p[_orderOwner];
        canCreateOrder[_orderOwner] = true;
        canceledOrders++;
        emit orderCancelled(_orderOwner, p2p[_orderOwner].orderType);
    }
    function superCancel() public{
        uint256 _orderCancelled = 0;
        for(uint i = 0; i < OrderDetails.length -1; i++){
            address _orderOwner = OrderDetails[i].sB;
            if(OrderDetails[i].orderLife < block.timestamp){
                fixOrders(i);
                deleteOrder(_orderOwner);
                canceledOrders++;
                _orderCancelled = 1;
                delete p2p[_orderOwner];
                canCreateOrder[_orderOwner] = true;
            }
        }
        if(_orderCancelled != 1){
            revert("Orders life is normal");
        }
    }
    function cancelOrder() external{
        uint256 _orderCancelled = 0;
        uint256 _orderIndex = OrderDetails.length -1;
        if(OrderDetails[_orderIndex].sB == msg.sender){
            forceCancel(_orderIndex, msg.sender);
        }
        else{
            for(uint i = 0; i < OrderDetails.length -1; i++){
            if(OrderDetails[i].sB == msg.sender){
                fixOrders(i);
                deleteOrder(msg.sender);
                _orderCancelled = 1;
                emit orderCancelled(msg.sender, p2p[msg.sender].orderType);
                //if(block.timestamp < p2p[msg.sender].orderLife.sub(410)){ // (45 hours){
                    monopoly[msg.sender] = block.timestamp.add(300);//(1 hours);
                //}
                break;
            }
         }
         if(_orderCancelled != 1){
            revert("No user order found");
         }
         else{
            canceledOrders++;
         }
        }
    }
    //user can cancel order and retrive remaining amounts
    function deleteOrder(address _orderOwner) internal{
        if(p2p[_orderOwner].orderType == 1){
            uint256 amount = p2p[_orderOwner].remainAmount;
            if(amount > 0){
                ISLAMI.transfer(_orderOwner, amount);
            }
            sellOrders--;
        }
        else if(p2p[_orderOwner].orderType == 2){
            uint256 amount = p2p[_orderOwner].remainCurrency;
            if(amount > 0){
                IERC20 currency = p2p[_orderOwner].orderCurrency;
                currency.transfer(_orderOwner, amount);
            }
            buyOrders--;
        }
        delete p2p[_orderOwner];
        canCreateOrder[_orderOwner] = true;
        
    }
    function fixOrders(uint256 _orderIndex) internal {
        OrderDetails[_orderIndex] = OrderDetails[OrderDetails.length - 1];
        OrderDetails.pop();
        totalOrders--;
    }
    function orderFilled(address _orderOwner) internal{
        for(uint i = 0; i < OrderDetails.length - 1; i++){
            if(OrderDetails[i].sB == _orderOwner){
                fixOrders(i);
            }
        }
        delete p2p[_orderOwner];
    }
    //user can take full order or partial
    function takeOrder(address _orderOwner, uint256 _amount) external nonReentrant{
        IERC20 _currency = p2p[_orderOwner].orderCurrency;
        address seller = p2p[_orderOwner].sB;
        uint256 priceUSD = p2p[_orderOwner].orderPrice;
        uint256 toPay = _amount.mul(priceUSD);//.mul(ISLAMIdcml);
        uint256 amountUSD = _amount.mul(USDdcml);
        uint256 amountISLAMI = _amount.mul(ISLAMIdcml);
        uint256 toReceive = amountUSD.div(priceUSD).mul(ISLAMIdcml);
        uint256 _p2pFee;
        require(_currency.balanceOf(msg.sender) >= toPay, "Not enought USD");
        require(p2p[_orderOwner].orderStatus != true, "Order was completed");
        if(p2p[_orderOwner].orderType == 1){//Take sell
        require(amountISLAMI <= p2p[_orderOwner].remainAmount, "Seller has less ISLAMI than order");
        _p2pFee = amountISLAMI.mul(p2pFee).div(feeFactor);
        ISLAMI.transfer(burn, _p2pFee);
        ISLAMIinOrder -= amountISLAMI;
        burned += _p2pFee;
        //require approve from currency(USDT, USDC) contract
        _currency.transferFrom(msg.sender, seller, toPay); 
        ISLAMI.transfer(msg.sender, amountISLAMI.sub(_p2pFee));
        userOrders[msg.sender].bought += amountISLAMI;
        userOrders[seller].sold += amountISLAMI;
          if(amountISLAMI == p2p[_orderOwner].remainAmount){
                p2p[_orderOwner].orderStatus = true;
                canCreateOrder[seller] = true;
                orderFilled(seller);
                sellOrders--;
            }
            p2p[_orderOwner].remainAmount -= amountISLAMI;
            emit orderBuy(_orderOwner, msg.sender, amountISLAMI, priceUSD);
        }
        else if(p2p[_orderOwner].orderType == 2){//Take buy
        require(amountUSD <= p2p[_orderOwner].remainCurrency, "Seller has less USD than order");
        _p2pFee = amountUSD.mul(p2pFee).div(feeFactor);
        _currency.transfer(feeReceiver, _p2pFee);
        USDinOrder -= amountUSD;
        //require approve from ISLAMICOIN contract
        ISLAMI.transferFrom(msg.sender, seller, toReceive);
        _currency.transfer(msg.sender, amountUSD.sub(_p2pFee));
        userOrders[msg.sender].sold += toReceive;
        userOrders[seller].bought += toReceive;
          if(amountUSD == p2p[_orderOwner].remainCurrency){
                p2p[_orderOwner].orderStatus = true;
                canCreateOrder[seller] = true;
                orderFilled(seller);
                buyOrders--;
            }
            p2p[_orderOwner].remainCurrency -= amountUSD;
            emit orderSell(_orderOwner, msg.sender, amountISLAMI, priceUSD);
        }
    }
}
 

               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
               **********************************************************/