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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IBastionV2} from "./interfaces/IBastionV2.sol";
import {IFlashLiquidityFactory} from "./interfaces/IFlashLiquidityFactory.sol";
import {IFlashLiquidityRouter} from "./interfaces/IFlashLiquidityRouter.sol";
import {IFlashLiquidityPair} from "./interfaces/IFlashLiquidityPair.sol";
import {ILiquidFarm} from "./interfaces/ILiquidFarm.sol";
import {ILiquidFarmFactory} from "./interfaces/ILiquidFarmFactory.sol";
import {IPegSwap} from "./interfaces/IPegSwap.sol";
import {Recoverable, IERC20, SafeERC20} from "./types/Recoverable.sol";

contract BastionV2 is IBastionV2, Recoverable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable factory;
    address public immutable router;
    address public immutable farmFactory;
    address private immutable linkTokenERC20;
    address private immutable linkTokenERC667;
    address private immutable pegSwap;
    uint256 public immutable whitelistDelay = 3 days;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public whitelistReqTimestamp;
    mapping(address => bool) public isExtManagerSetter;

    constructor(
        address _governor,
        address _factory,
        address _router,
        address _farmFactory,
        address _linkTokenERC20,
        address _linkTokenERC667,
        address _pegSwap,
        uint256 _transferGovernanceDelay,
        uint256 _withdrawalDelay
    ) Recoverable(_governor, _transferGovernanceDelay, _withdrawalDelay) {
        factory = _factory;
        router = _router;
        farmFactory = _farmFactory;
        linkTokenERC20 = _linkTokenERC20;
        linkTokenERC667 = _linkTokenERC667;
        pegSwap = _pegSwap;
    }

    function requestWhitelisting(address[] calldata _recipients) external onlyGovernor whenNotPaused {
        for(uint256 i = 0; i < _recipients.length; i++) {
            if(isWhitelisted[_recipients[i]]) revert AlreadyWhitelisted();
            whitelistReqTimestamp[_recipients[i]] = block.timestamp;
        }
    }

    function executeWhitelisting(address[] calldata _recipients) external onlyGovernor whenNotPaused {
        uint256 _whitelistDelay = whitelistDelay;
        for(uint256 i = 0; i < _recipients.length; i++) {
            uint256 _timestamp = whitelistReqTimestamp[_recipients[i]];
            if(whitelistReqTimestamp[_recipients[i]] == 0) revert NotRequested();
            if(block.timestamp - _timestamp < _whitelistDelay) revert TooEarly();
            isWhitelisted[_recipients[i]] = true;
            whitelistReqTimestamp[_recipients[i]] = 0;
        }
    }

    function removeFromWhitelist(address[] calldata _recipients) external onlyGovernor {
        for(uint256 i = 0; i < _recipients.length; i++) {
            if(!isWhitelisted[_recipients[i]]) revert NotWhitelisted();
            isWhitelisted[_recipients[i]] = false;
        }
    }

    function setPairManager(address _pair, address _manager) public {
        if(!isExtManagerSetter[msg.sender]) revert NotManagerSetter();
        IFlashLiquidityFactory(factory).setPairManager(_pair, _manager);
    }

    function setMainManagerSetter(address _managerSetter) external onlyGovernor {
        IFlashLiquidityFactory(factory).setPairManagerSetter(_managerSetter);
    }

    function setExtManagerSetter(address _extManagerSetter, bool _enabled) external onlyGovernor {
        isExtManagerSetter[_extManagerSetter] = _enabled;
        emit ExtManagerSetterChanged(_extManagerSetter  , _enabled);
    }

    function transferToWhitelisted(
        address _recipient, 
        address[] calldata _tokens, 
        uint256[] calldata _amounts
    ) external onlyGovernor whenNotPaused {
        if(!isWhitelisted[_recipient]) revert NotWhitelisted();
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(
                _recipient,
                _amounts[i]
            );
        }
        emit TransferredToWhitelisted(_recipient, _tokens, _amounts);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata _path
    ) external onlyGovernor whenNotPaused {
        IERC20 _token1 = IERC20(_path[0]);
        _token1.safeIncreaseAllowance(router, amountIn);
        uint256[] memory amounts = IFlashLiquidityRouter(router).swapExactTokensForTokens(
            amountIn,
            amountOut,
            _path,
            address(this),
            block.timestamp
        );
        _token1.approve(router, 0);
        emit Swapped(_path[0], _path[_path.length - 1], amounts[0], amounts[amounts.length - 1]);
    }

    function swapOnLockedPair(
        uint256 amountIn,
        uint256 amountOut,
        address fromToken,
        address toToken
    ) external onlyGovernor whenNotPaused {
        IFlashLiquidityFactory _factory = IFlashLiquidityFactory(factory);
        IFlashLiquidityPair pair = IFlashLiquidityPair(_factory.getPair(fromToken, toToken));
        address _manager = pair.manager();
        if(address(pair) == address(0) || _manager == address(0)) revert CannotConvert();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(9994);
        _factory.setPairManager(address(pair), address(this));
        if (fromToken == pair.token0()) {
            amountOut = amountInWithFee.mul(reserve1) / reserve0.mul(10000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, address(this), new bytes(0));
        } else {
            amountOut = amountInWithFee.mul(reserve0) / reserve1.mul(10000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, address(this), new bytes(0));
        }

        _factory.setPairManager(address(pair), _manager);
        emit Swapped(fromToken, toToken, amountIn, amountOut);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    )
        external
        onlyGovernor
        whenNotPaused
    {
        IERC20(tokenA).safeIncreaseAllowance(router, amountADesired);
        IERC20(tokenB).safeIncreaseAllowance(router, amountBDesired);
        (uint256 amountA, uint256 amountB, ) = IFlashLiquidityRouter(router).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            block.timestamp
        );
        IERC20(tokenA).approve(router, 0);
        IERC20(tokenB).approve(router, 0);
        emit AddedLiquidity(tokenA, tokenB, amountA, amountB);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external onlyGovernor whenNotPaused {
        IFlashLiquidityFactory _factory = IFlashLiquidityFactory(factory);
        IERC20 pair = IERC20(_factory.getPair(tokenA, tokenB));
        pair.safeIncreaseAllowance(router, liquidity);
        (uint256 amountA, uint256 amountB) = IFlashLiquidityRouter(router).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            block.timestamp
        );
        pair.approve(router, 0);
        emit RemovedLiquidity(tokenA, tokenB, amountA, amountB);
    }

    function stakeLpTokens(address lpToken, uint256 amount)
        external
        onlyGovernor
        whenNotPaused
    {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(lpToken);
        if(_farm == address(0)) revert FarmNotDeployed();
        IERC20 _lpToken = IERC20(lpToken);
        _lpToken.safeIncreaseAllowance(_farm, amount);
        ILiquidFarm(_farm).stake(amount);
        _lpToken.approve(_farm, 0);
        emit Staked(lpToken, amount);
    }

    function unstakeLpTokens(address lpToken, uint256 amount) external onlyGovernor whenNotPaused {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(lpToken);
        if(_farm == address(0)) revert FarmNotDeployed();
        ILiquidFarm(_farm).withdraw(amount);
        emit Unstaked(lpToken, amount);
    }

    function claimStakingRewards(address lpToken) external onlyGovernor whenNotPaused {
        ILiquidFarmFactory _arbFarmFactory = ILiquidFarmFactory(farmFactory);
        address _farm = _arbFarmFactory.lpTokenFarm(lpToken);
        if(_farm == address(0)) revert FarmNotDeployed();
        ILiquidFarm(_farm).getReward();
        emit ClaimedRewards(lpToken);
    }

    function swapLinkToken(bool toERC667, uint256 amount) external onlyGovernor whenNotPaused {
        address source;
        address dest;
        if (toERC667) {
            source = linkTokenERC20;
            dest = linkTokenERC667;
        } else {
            source = linkTokenERC667;
            dest = linkTokenERC20;
        }
        IERC20(source).safeIncreaseAllowance(pegSwap, amount);
        IPegSwap(pegSwap).swap(amount, source, dest);
        IERC20(source).approve(pegSwap, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBastionV2 {
    error CannotConvert();
    error FarmNotDeployed();
    error NotWhitelisted();
    error AlreadyWhitelisted();
    error NotManagerSetter();
    
    event TransferredToWhitelisted(
        address indexed _recipient,
        address[] indexed _tokens,
        uint256[] indexed _amounts
    );
    event AddedLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event RemovedLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    event Swapped(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event Staked(address indexed stakingToken, uint256 indexed amount);
    event Unstaked(address indexed stakingToken, uint256 indexed amount);
    event ClaimedRewards(address indexed stakingToken);
    event ExtManagerSetterChanged(address indexed setter, bool indexed isSetter);

    function router() external view returns (address);
    function farmFactory() external view returns (address);
    function requestWhitelisting(address[] calldata _recipients) external;
    function executeWhitelisting(address[] calldata _recipients) external;
    function removeFromWhitelist(address[] calldata _recipients) external;
    function setPairManager(address _pair, address _manager) external;
    function setMainManagerSetter(address _mainManagerSetter) external;
    function setExtManagerSetter(address _extManagerSetter, bool _enabled) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata _path
    ) external;

    function swapOnLockedPair(
        uint256 amountIn,
        uint256 amountOut,
        address fromToken,
        address toToken
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external;

    function stakeLpTokens(address lpToken, uint256 amount) external;
    function unstakeLpTokens(address lpToken, uint256 amount) external;
    function claimStakingRewards(address lpToken) external;
    function swapLinkToken(bool toERC667, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function managerSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setPairManager(address _pair, address _manager) external;
    function setPairManagerSetter(address _managerSetter) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function manager() external view returns (address);
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
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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
    function setPairManager(address) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IFlashLiquidityRouter01.sol";

interface IFlashLiquidityRouter is IFlashLiquidityRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLiquidityRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IFlashBorrower.sol";

interface ILiquidFarm {
    error StakingZero();
    error WithdrawingZero();
    error FlashLoanNotRepaid();
    error TransferLocked(uint256 _unlockTime);

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event LogFlashLoan(
        address indexed borrower,
        address indexed receiver,
        address indexed rewardsToken,
        uint256 amount,
        uint256 fee
    );
    event FreeFlashloanerChanged(address indexed flashloaner, bool indexed free);

    function farmsFactory() external view returns (address);

    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function transferLock() external view returns (uint32);

    function getTransferUnlockTime(address _account) external view returns (uint64);

    function lastClaimedRewards(address _account) external view returns (uint64);

    function earned(address account) external view returns (uint256);

    function earnedRewardToken(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILiquidFarmFactory {
    error AlreadyDeployed();

    event FarmDeployed(address indexed _stakingToken, address indexed _rewardsToken);

    function lpTokenFarm(address _stakingToken) external view returns (address);

    function isFreeFlashLoan(address sender) external view returns (bool);

    function setFreeFlashLoan(address _target, bool _isExempted) external;

    function deploy(
        string memory name,
        string memory symbol,
        address stakingToken,
        address rewardsToken
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPegSwap {
    function swap(
        uint256 amount,
        address source,
        address target
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Governable {
    address public governor;
    address public pendingGovernor;
    uint256 public govTransferReqTimestamp;
    uint256 public immutable transferGovernanceDelay;

    error ZeroAddress();
    error NotAuthorized();
    error TooEarly();

    event GovernanceTrasferred(address indexed _oldGovernor, address indexed _newGovernor);
    event PendingGovernorChanged(address indexed _pendingGovernor);

    constructor(address _governor, uint256 _transferGovernanceDelay) {
        governor = _governor;
        transferGovernanceDelay = _transferGovernanceDelay;
        emit GovernanceTrasferred(address(0), _governor);
    }

    function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
        if (_pendingGovernor == address(0)) revert ZeroAddress();
        pendingGovernor = _pendingGovernor;
        govTransferReqTimestamp = block.timestamp;
        emit PendingGovernorChanged(_pendingGovernor);
    }

    function transferGovernance() external {
        address _newGovernor = pendingGovernor;
        address _oldGovernor = governor;
        if (_newGovernor == address(0)) revert ZeroAddress();
        if (msg.sender != _oldGovernor && msg.sender != _newGovernor) revert NotAuthorized();
        if (block.timestamp - govTransferReqTimestamp < transferGovernanceDelay) revert TooEarly();
        pendingGovernor = address(0);
        governor = _newGovernor;
        emit GovernanceTrasferred(_oldGovernor, _newGovernor);
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) revert NotAuthorized();
        _;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Governable} from "./Governable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Recoverable is Governable {
    using SafeERC20 for IERC20;
    bool public paused;
    uint256 public withdrawalRequestTimestamp;
    uint256 public immutable withdrawalDelay;
    address public withdrawalRecipient;

    error NotPaused();
    error Paused();
    error NotRequested();
    error AlreadyRequested(); 

    event EmergencyWithdrawalRequested(address indexed _recipient);
    event EmergencyWithdrawalCompleted(address indexed _recipient);
    event EmergencyWithdrawalAborted(address indexed _recipient);
    event WithdrawalRecipientChanged(address indexed _recipient);

    constructor(
        address _governor,
        uint256 _transferGovernanceDelay,
        uint256 _withdrawalDelay
    ) Governable(_governor, _transferGovernanceDelay) {
        withdrawalDelay = _withdrawalDelay;
    }

    function pause() external onlyGovernor whenNotPaused {
        paused = true;
    }

    function unpause() external onlyGovernor whenPaused {
        paused = false;
        withdrawalRequestTimestamp = 0;
    }

    function requestEmergencyWithdrawal(address _withdrawalRecipient)
        external
        onlyGovernor
        whenPaused
        whenNotEmergency
    {
        if(_withdrawalRecipient == address(0)) revert ZeroAddress();
        withdrawalRecipient = _withdrawalRecipient;
        withdrawalRequestTimestamp = block.timestamp;
        emit EmergencyWithdrawalRequested(_withdrawalRecipient);
    }

    function abortEmergencyWithdrawal() external onlyGovernor whenPaused whenEmergency {
        withdrawalRequestTimestamp = 0;
        emit EmergencyWithdrawalAborted(withdrawalRecipient);
    }

    function emergencyWithdraw(address[] calldata _tokens, uint256[] calldata _amounts)
        external
        onlyGovernor
        whenPaused
        whenEmergency
    {
        if(block.timestamp - withdrawalRequestTimestamp < withdrawalDelay) revert TooEarly();
        address _recipient = withdrawalRecipient;
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(_recipient, _amounts[i]);
        }
        emit EmergencyWithdrawalCompleted(_recipient);
    }

    modifier whenPaused() {
        if(!paused) revert NotPaused();
        _;
    }

    modifier whenNotPaused() {
        if(paused) revert Paused();
        _;
    }

    modifier whenEmergency() {
        if(withdrawalRequestTimestamp == 0) revert NotRequested();
        _;
    }

    modifier whenNotEmergency() {
        if(withdrawalRequestTimestamp != 0) revert AlreadyRequested();
        _;
    }
}