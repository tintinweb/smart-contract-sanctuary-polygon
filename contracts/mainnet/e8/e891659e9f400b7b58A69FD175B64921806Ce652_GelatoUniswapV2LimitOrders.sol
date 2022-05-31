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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {UniswapV2Order} from "./structs/UniswapV2Order.sol";
import {_balanceOf} from "./functions/FTokenUtils.sol";
import {
    _canHandleUniswapV2LimitOrder
} from "./functions/uniswap/FLimitOrders.sol";
import {GelatoUniswapV2OrdersVault} from "./GelatoUniswapV2OrdersVault.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GelatoUniswapV2LimitOrders is
    GelatoUniswapV2OrdersVault,
    ReentrancyGuard
{
    modifier onlyGelato() {
        require(address(GELATO) == msg.sender, "GelatoOrdersVault: onlyGelato");
        _;
    }

    constructor(address _gelato, address _wrappedNative)
        GelatoUniswapV2OrdersVault(_gelato, _wrappedNative)
    {} // solhint-disable-line no-empty-blocks

    function fill(UniswapV2Order calldata _order, bytes calldata _auxData)
        external
        override
        onlyGelato
        nonReentrant
    {
        uint256 ownerBalanceBefore = _balanceOf(
            _order.outputToken,
            _order.owner
        );

        // pull order funds and handle swap logic
        // implements Checks Effects Interactions pattern and thus is reentrancy protected
        _fill(_order, _auxData);

        // check limit order conditions
        uint256 ownerBalanceAfter = _balanceOf(
            _order.outputToken,
            _order.owner
        );

        require(
            ownerBalanceAfter - ownerBalanceBefore >= _order.minReturn,
            "GelatoOrdersVault.fill: ISSUFICIENT_OWNER_OUTPUT_TOKEN_BALANCE"
        );

        emit LogFill(
            keyOf(_order),
            _order.owner,
            ownerBalanceAfter - ownerBalanceBefore,
            _auxData
        );
    }

    function canFill(
        uint256 _minReturn,
        UniswapV2Order calldata _order,
        bytes calldata _auxData
    ) external view override returns (bool) {
        return
            isActiveOrder(keyOf(_order)) &&
            _canHandleUniswapV2LimitOrder(
                _order,
                deposits[keyOf(_order)],
                _minReturn,
                WRAPPED_NATIVE,
                _auxData
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {NATIVE} from "./constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IGelato} from "./interfaces/IGelato.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UniswapV2Order} from "./structs/UniswapV2Order.sol";
import {UniswapV2Library} from "./lib/UniswapV2Library.sol";
import {_balanceOf} from "./functions/FTokenUtils.sol";
import {
    IUniswapV2Pair
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IGelatoUniswapV2Orders} from "./interfaces/IGelatoUniswapV2Orders.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

// solhint-disable max-line-length
abstract contract GelatoUniswapV2OrdersVault is IGelatoUniswapV2Orders {
    using Address for address payable;
    // solhint-disable-next-line var-name-mixedcase
    address public immutable WRAPPED_NATIVE;
    // solhint-disable-next-line var-name-mixedcase
    IGelato public immutable GELATO;

    // hashed orders
    mapping(bytes32 => uint256) public deposits;

    event LogDeposit(
        bytes32 indexed key,
        UniswapV2Order order,
        uint256 amountIn
    );

    event LogFill(
        bytes32 indexed key,
        address indexed owner,
        uint256 amountOut,
        bytes auxData
    );

    event LogCancelled(
        bytes32 indexed key,
        address indexed owner,
        uint256 amount
    );

    constructor(address _gelato, address _wrappedNative) {
        WRAPPED_NATIVE = _wrappedNative;
        GELATO = IGelato(_gelato);
    }

    function depositNative(UniswapV2Order calldata _order)
        external
        payable
        virtual
        override
    {
        require(msg.value != 0, "GelatoOrdersVault.depositNative: VALUE_IS_0");
        require(
            _order.inputToken == NATIVE,
            "GelatoOrdersVault.depositNative: WRONG_INPUT_TOKEN"
        );
        require(
            !_isNativeOrWrappedNative(_order.outputToken),
            "GelatoOrdersVault.depositNative: NATIVE_TO_NATIVE"
        );
        bytes32 key = keyOf(_order);
        require(
            !isActiveOrder(key),
            "GelatoOrdersVault.depositNative: ORDER_ALREADY_EXSITS"
        );

        deposits[key] = msg.value;
        emit LogDeposit(key, _order, msg.value);
    }

    function depositToken(UniswapV2Order calldata _order)
        external
        virtual
        override
    {
        require(
            _order.inputToken != NATIVE,
            "GelatoOrdersVault.depositToken: ONLY_ERC20"
        );

        if (_order.inputToken == WRAPPED_NATIVE) {
            require(
                !_isNativeOrWrappedNative(_order.outputToken),
                "GelatoOrdersVault.depositToken: NATIVE_TO_NATIVE"
            );
        }

        uint256 vaultBalanceBefore = IERC20(_order.inputToken).balanceOf(
            address(this)
        );

        IERC20(_order.inputToken).transferFrom(
            msg.sender,
            address(this),
            _order.amountIn
        );

        // don't trust transferFrom
        uint256 vaultBalanceAfter = IERC20(_order.inputToken).balanceOf(
            address(this)
        );
        uint256 amountDeposited = vaultBalanceAfter - vaultBalanceBefore;
        require(
            amountDeposited != 0,
            "GelatoOrdersVault.depositToken: NO_TOKENS_SENT"
        );

        bytes32 key = keyOf(_order);
        require(
            !isActiveOrder(key),
            "GelatoOrdersVault.depositToken: ORDER_ALREADY_EXSITS"
        );

        deposits[key] = amountDeposited;

        emit LogDeposit(key, _order, amountDeposited);
    }

    function cancelOrder(UniswapV2Order calldata _order)
        external
        virtual
        override
    {
        require(
            msg.sender == _order.owner,
            "GelatoOrdersVault.cancelOrder: INVALID_OWNER"
        );
        bytes32 key = keyOf(_order);
        require(
            isActiveOrder(key),
            "GelatoOrdersVault.cancelOrder: INVALID_ORDER"
        );
        uint256 amount = _pullOrder(
            _order.inputToken,
            key,
            payable(msg.sender)
        );

        emit LogCancelled(key, _order.owner, amount);
    }

    function isActiveOrder(bytes32 _key) public view returns (bool) {
        return deposits[_key] != 0;
    }

    function keyOf(UniswapV2Order calldata _order)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_order));
    }

    function _fill(UniswapV2Order calldata _order, bytes calldata _auxData)
        internal
    {
        bytes32 key = keyOf(_order);
        // implements Checks Effects Interactions pattern and thus is reentrancy protected
        require(isActiveOrder(key), "GelatoOrdersVault.fill: INVALID_ORDER");
        (
            uint256 fee,
            address pool,
            address feePool,
            address[] memory path,
            address[] memory feePath
        ) = abi.decode(
                _auxData,
                (uint256, address, address, address[], address[])
            );
        uint256 amount = deposits[key];

        delete deposits[key];
        if (
            _order.inputToken == WRAPPED_NATIVE || _order.inputToken == NATIVE
        ) {
            _swapExactNativeForToken(_order, amount, fee, pool, path);
        } else if (
            _order.outputToken == WRAPPED_NATIVE || _order.outputToken == NATIVE
        ) {
            _swapExactTokenForNative(_order, amount, fee, pool, path);
        } else {
            _swapExactTokenForToken(
                _order,
                amount,
                fee,
                pool,
                feePool,
                path,
                feePath
            );
        }
    }

    function _swapExactNativeForToken(
        UniswapV2Order calldata _order,
        uint256 _amount,
        uint256 _fee,
        address _pool,
        address[] memory _path
    ) internal {
        require(
            _amount > _fee,
            "GelatoOrdersVault.fill: CANT_PAY_RELAYER_FEE_TO_HIGH"
        );
        if (_order.inputToken == NATIVE) {
            IWETH(WRAPPED_NATIVE).deposit{value: _amount - _fee}();
            payable(GELATO.getFeeCollector()).sendValue(_fee);
        } else {
            SafeERC20.safeTransfer(
                IERC20(WRAPPED_NATIVE),
                GELATO.getFeeCollector(),
                _fee
            );
        }

        SafeERC20.safeTransfer(IERC20(WRAPPED_NATIVE), _pool, _amount - _fee);
        // calculate amountsOut for every hop in path based on amountIn
        // swap destination can be _order.owner
        _swapSupportingFeeOnTransferTokens(_path, _order.owner, _order);
    }

    function _swapExactTokenForNative(
        UniswapV2Order calldata _order,
        uint256 _amount,
        uint256 _fee,
        address _pool,
        address[] memory _path
    ) internal {
        uint256 balanceBefore = _balanceOf(WRAPPED_NATIVE, address(this));
        SafeERC20.safeTransfer(IERC20(_order.inputToken), _pool, _amount);
        // swap with destination `address(this)` to then extract fee for `relayer`
        _swapSupportingFeeOnTransferTokens(_path, address(this), _order);

        uint256 amountSwapped = _balanceOf(WRAPPED_NATIVE, address(this)) -
            balanceBefore;

        if (_order.outputToken == NATIVE) {
            IWETH(WRAPPED_NATIVE).withdraw(amountSwapped - _fee);
            payable(_order.owner).sendValue(amountSwapped - _fee);
        } else {
            SafeERC20.safeTransfer(
                IERC20(_order.outputToken),
                _order.owner,
                amountSwapped - _fee
            );
        }
        SafeERC20.safeTransfer(
            IERC20(WRAPPED_NATIVE),
            GELATO.getFeeCollector(),
            _fee
        );
    }

    function _swapExactTokenForToken(
        UniswapV2Order calldata _order,
        uint256 _amount,
        uint256 _feeInNative,
        address _pool,
        address _feePool,
        address[] memory _path,
        address[] memory _feePath
    ) internal {
        // calculate how much inputToken needed to get fee in NATIVE (first index in amounts array)
        uint256 feeInInputToken = IUniswapV2Router02(_order.router)
            .getAmountsIn(_feeInNative, _feePath)[0];

        SafeERC20.safeTransfer(
            IERC20(_order.inputToken),
            _pool,
            _amount - feeInInputToken
        );
        // calculate exact input amount that arrived in `pool`
        // can swap with destination _order.owner because fee was subtracted from amounts
        _swapSupportingFeeOnTransferTokens(_path, _order.owner, _order);
        // needs additional swap to convert `inputToken` to `NATIVE` to be able to pay `relayer`
        // swap token for fee in native
        SafeERC20.safeTransfer(
            IERC20(_order.inputToken),
            _feePool,
            feeInInputToken
        );
        // can swap with destination relayer because relayer accepts WETH
        _swapSupportingFeeOnTransferTokens(
            _feePath,
            GELATO.getFeeCollector(),
            _order
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    // Original work by Uniswap
    // - https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/UniswapV2Router02.sol#L321-L338
    // modified function interface to be able to parse generic factory and initCodeHash
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to,
        UniswapV2Order calldata _order
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(
                UniswapV2Library.pairFor(
                    _order.factory,
                    input,
                    output,
                    _order.initCodeHash
                )
            );
            // modified: remove variable to avoid STD
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountOutput = IUniswapV2Router02(_order.router).getAmountOut(
                    IERC20(input).balanceOf(address(pair)) - reserveInput, // modified: remove variable to avoid STD
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    _order.factory,
                    output,
                    path[i + 2],
                    _order.initCodeHash
                )
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _pullOrder(
        address _inputToken,
        bytes32 _key,
        address _to
    ) private returns (uint256 amount) {
        amount = deposits[_key];
        delete deposits[_key];
        if (_inputToken == NATIVE) {
            (bool success, ) = payable(_to).call{value: amount}("");
            require(
                success,
                "GelatoOrdersVault._pullOrder: SEND_NATIVE_FAILED"
            );
        } else {
            SafeERC20.safeTransfer(IERC20(_inputToken), _to, amount);
        }
    }

    function _isNativeOrWrappedNative(address _token)
        private
        view
        returns (bool)
    {
        return _token == NATIVE || _token == WRAPPED_NATIVE;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {NATIVE} from "../constants/Tokens.sol";

function _balanceOf(address _token, address _account) view returns (uint256) {
    return
        NATIVE == _token
            ? _account.balance
            : IERC20(_token).balanceOf(_account);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {_getAmountOut, _getAmountIn} from "./FUniswapGeneral.sol";
import {NATIVE} from "../../constants/Tokens.sol";
import {UniswapV2Order} from "../../structs/UniswapV2Order.sol";

function _canHandleUniswapV2LimitOrder(
    UniswapV2Order calldata _order,
    uint256 _amountIn,
    uint256 _minReturn,
    address _wrappedNative,
    bytes calldata _auxData
) view returns (bool) {
    (uint256 fee, , , address[] memory path, address[] memory feePath) = abi
        .decode(_auxData, (uint256, address, address, address[], address[]));

    return
        _canHandleBody(
            _order.inputToken,
            _order.outputToken,
            _amountIn,
            _minReturn,
            _order.router,
            _wrappedNative,
            fee,
            path,
            feePath
        );
}

function _canHandleBody(
    address _inToken,
    address _outToken,
    uint256 _amountIn,
    uint256 _minReturn,
    address _uniRouter,
    address _wrappedNative,
    uint256 _fee,
    address[] memory _path,
    address[] memory _feePath
) view returns (bool) {
    if (_inToken == _wrappedNative || _inToken == NATIVE) {
        if (_amountIn <= _fee) return false;
        return _getAmountOut(_amountIn - _fee, _path, _uniRouter) >= _minReturn;
    } else if (_outToken == _wrappedNative || _outToken == NATIVE) {
        uint256 bought = _getAmountOut(_amountIn, _path, _uniRouter);
        if (bought <= _fee) return false;
        return bought - _fee >= _minReturn;
    } else {
        uint256 inTokenFee = _getAmountIn(_fee, _feePath, _uniRouter);
        if (inTokenFee >= _amountIn) return false;
        return
            _getAmountOut(_amountIn - inTokenFee, _path, _uniRouter) >=
            _minReturn;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

function _getAmountOut(
    uint256 _amountIn,
    address[] memory _path,
    address _uniRouter
) view returns (uint256 amountOut) {
    uint256[] memory amountsOut = IUniswapV2Router02(_uniRouter).getAmountsOut(
        _amountIn,
        _path
    );
    amountOut = amountsOut[amountsOut.length - 1];
}

function _getAmountIn(
    uint256 _amountOut,
    address[] memory _path,
    address _uniRouter
) view returns (uint256 amountIn) {
    uint256[] memory amountsIn = IUniswapV2Router02(_uniRouter).getAmountsIn(
        _amountOut,
        _path
    );
    amountIn = amountsIn[0];
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IGelato {
    function getFeeCollector() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {UniswapV2Order} from "../structs/UniswapV2Order.sol";

interface IGelatoUniswapV2Orders {
    function depositNative(UniswapV2Order calldata _order) external payable;

    function depositToken(UniswapV2Order calldata _order) external;

    function cancelOrder(UniswapV2Order calldata _order) external;

    function fill(UniswapV2Order calldata _order, bytes calldata _auxData)
        external;

    function canFill(
        uint256 _minReturn,
        UniswapV2Order calldata _order,
        bytes calldata _auxData
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-3.0

//
// Original work by Uniswap
//  - https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
//
// Author:
//  - NoahZinsmeister <@NoahZinsmeister>

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    // modified function interface to be able to parse generic factory and initCodeHash
    // modified encoding
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCodeHash
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            initCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

struct UniswapV2Order {
    address owner;
    address inputToken;
    address outputToken;
    address factory;
    address router;
    uint256 amountIn;
    uint256 minReturn;
    uint256 salt;
    bytes32 initCodeHash;
}