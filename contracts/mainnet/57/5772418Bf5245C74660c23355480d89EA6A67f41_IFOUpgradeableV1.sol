// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import {IWrapperToNative} from "./interfaces/IWrapperToNative.sol";
import {IWMATIC} from "./interfaces/IWMATIC.sol";

contract IFOUpgradeableV1 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IWMATIC;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	// address that'll receive the first payout after IFO ends
	address public escrowAddress;

	// address receiving rest of funds raised
	address public receiverAddress;

	// The raising token
	IERC20Upgradeable public depositToken;

	// The offering token
	IERC20Upgradeable public offeringToken;

	// The block number when IFO starts
	uint256 public startTime;

	// The block number when IFO ends
	uint256 public endTime;

	/// @dev check before final deployment
	// timespan to withdraw deposits in
	uint256 public escrowDuration;

	/// @dev check before final deployment
	// timespan to withdraw deposits in
	uint256 public vestingDuration;

	// last time of calling withdrawl
	uint256 public lastRewardTime;

	// amount withdrawn in runningTime span
	uint256 public sentAmount;

	// in percentage => 0.1% = 10
	uint256 public devFees;
	address public devFeesAddress;

	// in percentage => 0.1% = 10
	uint256 public protocolFees;
	address public protocolFeesAddress;

	// whether initialize function is called
	bool public initialized;

	// reward percentage to send to escrow
	uint256 public escrowRatio;

	// whether payment sent to escrow
	bool public sentToEscrow;

	// address => amount deposited
	mapping(address => uint256) public amount;

	// address => vested reward tokens user has claimed
	mapping(address => uint256) public released;

	// address => whether user has claimed unused deposit tokens
	mapping(address => bool) public claimedUnusedDeposit;

	// address => whether refund has been sent to a contributor
	bool public refundSent;

	// total amount of raising tokens need to be raised
	uint256 public raisingAmount;

	// total amount of offeringToken that will offer
	uint256 public offeringAmount;

	/// @notice unused since upgrade, use `getAmounts` function instead
	// max amount of offeringToken that will be distributed in case of underflow or overflow
	uint256 public distributionAmount;

	// total amount of raising tokens that have already raised
	uint256 public totalAmount;

	/// @notice unused since upgrade, use `getAmounts` function instead
	// excess amount raised that will be sent back to users thus should not be withdrawn
	uint256 public excessAmount;

	// percentage which determines whether to refund or accept the contribution
	uint256 public refundThreshold;

	// participants
	address[] public usersList;

	// The proxy contract to convert Wrapped to native
	IWrapperToNative public nativeConvertor;

	// wrapped native token address
	IWMATIC public WMATIC;

	function initialize(IWMATIC _WMATIC, IWrapperToNative _nativeConvertor) public initializer {
		__Ownable_init();
		__ReentrancyGuard_init();

		WMATIC = _WMATIC;
		nativeConvertor = _nativeConvertor;
	}

	event Deposit(address indexed user, uint256 amount);
	event Released(address indexed user, uint256 amount);
	event ClaimUnusedDeposit(address indexed user, uint256 refundingAmount);
	event Withdraw(uint256 amount);

	/// @dev Using non-upgradable initializer because of contructor error
	/// @dev {ticketKeeper} address can also be updated by owner if it is a private pool
	/// @dev In values using percentage below, 1% is denoted as 100, 0.1% as 10, 0.01% as 1
	/// @dev To make the pool support NATIVE i.e. MATIC deposit, specify the {_depositToken} as {WMATIC} address, make sure {WMATIC} address in contract is correct
	/// @param _depositToken The token to be contributed by user
	/// @param _offeringToken The token that will be distributed after IFO ending
	/// @param _startTime Unix timestamp of IFO starting
	/// @param _endTime Unix timestamp of IFO ending
	/// @param _offeringAmount Amount of {_offeringToken} being distributed among buyers after IFO end
	/// @param _raisingAmount Amount of {_depositToken} that is supposed to be raised
	/// @param _devFees Percentage of raised amount to be sent to {_devFeesAddress} after IFO end
	/// @param _protocolFees Percentage of raised amount to be sent to {_protocolFeesAddress} after IFO end
	/// @param _escrowRatio Percentage of raised amount to be sent to {_escrowAddress} after IFO end
	/// @param _devFeesAddress Address to send {_devFees} to
	/// @param _protocolFeesAddress Address to send {_protocolFees} to
	/// @param _escrowAddress Address to send {_escrowRatio} amount to
	/// @param _receiverAddress Address that will recieve the funds collected after IFO end over a span of specified {runningTime}
	/// @param _escrowDuration Escrow duration for user deposits withdrawl (in seconds)
	/// @param _vestingDuration The reward token vesting duration (in seconds)
	function updateDetails(
		IERC20Upgradeable _depositToken,
		IERC20Upgradeable _offeringToken,
		uint256 _startTime,
		uint256 _endTime,
		uint256 _offeringAmount,
		uint256 _raisingAmount,
		uint256 _devFees,
		uint256 _protocolFees,
		uint256 _escrowRatio,
		address _devFeesAddress,
		address _protocolFeesAddress,
		address _escrowAddress,
		address _receiverAddress,
		uint256 _escrowDuration,
		uint256 _vestingDuration
	) external notInitialized onlyOwner {
		depositToken = _depositToken;
		offeringToken = _offeringToken;
		startTime = _startTime;
		endTime = _endTime;

		offeringAmount = _offeringAmount;
		raisingAmount = _raisingAmount;
		devFees = _devFees;
		protocolFees = _protocolFees;
		escrowRatio = _escrowRatio;

		devFeesAddress = _devFeesAddress;
		protocolFeesAddress = _protocolFeesAddress;
		escrowAddress = _escrowAddress;
		receiverAddress = _receiverAddress;

		lastRewardTime = _endTime;

		escrowDuration = _escrowDuration;
		vestingDuration = _vestingDuration;
		refundThreshold = 8000; // 80%

		WMATIC.approve(address(nativeConvertor), type(uint256).max);
	}

	/// @notice restrict function to only be called until IFO is started
	modifier notStarted() {
		require(block.timestamp < startTime, "IFO already started");
		_;
	}

	/// @notice restrict initializer to be called only once
	modifier notInitialized() {
		require(!initialized, "Launchpad: Already initialized");
		_;
		initialized = true;
	}

	/// @notice publicly callable function to deposit to IFO
	/// @dev call this function after converting MATIC to WMATIC for pools that supports native deposit
	function deposit(uint256 _amount) public nonReentrant {
		require(_amount > 0, "No amount sent");
		depositToken.transferFrom(_msgSender(), address(this), _amount);
		_deposit(_amount);
	}

	/// @notice claim rewardTokens vested till current block.timestamp
	function release() external nonReentrant {
		require(block.timestamp > endTime, "IFO not ended");
		require(amount[_msgSender()] > 0, "No deposits found");

		uint256 releaseableAmount = releaseable(_msgSender());
		require(releaseableAmount > 0, "No releaseable funds");

		if (releaseableAmount > 0) {
			offeringToken.safeTransfer(_msgSender(), releaseableAmount);
		}

		released[_msgSender()] = released[_msgSender()].add(releaseableAmount);
		emit Released(_msgSender(), releaseableAmount);
	}

	function claimUnusedDeposit(bool sendNative) external nonReentrant {
		require(block.timestamp > endTime, "IFO not ended");
		require(amount[_msgSender()] > 0, "No deposits found");
		require(!claimedUnusedDeposit[_msgSender()], "Already withdrawn");

		uint256 refundingTokenAmount = getRefundingAmount(_msgSender());

		if (refundingTokenAmount > 0) {
			if (sendNative) {
				nativeConvertor.withdrawTo(_msgSender(), refundingTokenAmount);
			} else {
				depositToken.safeTransfer(_msgSender(), refundingTokenAmount);
			}
		}

		claimedUnusedDeposit[_msgSender()] = true;
		emit ClaimUnusedDeposit(_msgSender(), refundingTokenAmount);
	}

	function processRefundsIfAny(bool forced) external nonReentrant {
		require(block.timestamp > endTime, "IFO not ended");
		require(!refundSent, "Refunds already sent");
		bool thresholdNotReached = totalAmount < raisingAmount.mul(refundThreshold).div(10000);

		if (forced) require(_msgSender() == owner(), "Ownable: caller is not the owner");
		else require(thresholdNotReached, "IFO Succeeded: No need to refund");

		for (uint256 i; i < usersList.length; i++) {
			address user = usersList[i];
			if (amount[user] > 0) nativeConvertor.withdrawTo(user, amount[user]);
		}
		refundSent = true;
	}

	/// @notice Allocation 100_000 means 0.1(10%), 1 means 0.000_001(0.0001%), 1_000_000 means 1(100%)
	function getUserAllocation(address _user) public view returns (uint256) {
		if (totalAmount > 0) {
			return amount[_user].mul(1e12).div(totalAmount).div(1e6);
		}
	}

	/// @notice get the amount of IFO token you will get
	function getOfferingAmount(address _user) public view returns (uint256) {
		if (totalAmount > raisingAmount) {
			uint256 allocation = getUserAllocation(_user);
			return offeringAmount.mul(allocation).div(1e6);
		} else {
			return amount[_user].mul(offeringAmount).div(raisingAmount);
		}
	}

	/// @notice Get the amount of lp token you will be refunded
	function getRefundingAmount(address _user) public view returns (uint256) {
		if (totalAmount <= raisingAmount) return 0;

		uint256 allocation = getUserAllocation(_user);
		uint256 payAmount = raisingAmount.mul(allocation).div(1e6);

		return amount[_user].sub(payAmount);
	}

	/// @notice No. of users who participated in IFO
	function usersListLength() external view returns (uint256) {
		return usersList.length;
	}

	function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
		if (_fromTime > _toTime) return 0;
		return _toTime.sub(_fromTime).mul(_totalDepositAmount().div(escrowDuration));
	}

	/// @dev returns the amount of devFees & protocolFees to use in further calc
	function getFeeParticulars() public view returns (uint256 devFeesAmount, uint256 escrowFeesAmount, uint256 protocolFeesAmount) {
		devFeesAmount = _amountToUse().mul(devFees).div(10000);
		escrowFeesAmount = _amountToUse().mul(escrowRatio).div(10000);
		protocolFeesAmount = _amountToUse().mul(protocolFees).div(10000);
	}

	function timelyWithdraw() external {
		uint256 remainingBalance = _totalDepositAmount() - sentAmount;

		require(block.timestamp > endTime, "IFO not ended");
		require(remainingBalance > 0, "No balance");

		if (!sentToEscrow) {
			(uint256 devFeesAmount, uint256 escrowFeesAmount, uint256 protocolFeesAmount) = getFeeParticulars();

			depositToken.safeTransfer(devFeesAddress, devFeesAmount);
			depositToken.safeTransfer(escrowAddress, escrowFeesAmount);
			depositToken.safeTransfer(protocolFeesAddress, protocolFeesAmount);

			(, uint256 _distributionAmount) = getAmounts();
			if (_distributionAmount < offeringAmount && offeringToken.balanceOf(address(this)) > 0) {
				offeringToken.safeTransfer(receiverAddress, offeringAmount.sub(_distributionAmount));
			}

			lastRewardTime = block.timestamp;
			sentToEscrow = true;

			emit Withdraw(escrowFeesAmount + devFeesAmount + protocolFeesAmount);
		} else {
			uint256 rewardAmount = getGeneratedReward(lastRewardTime, block.timestamp);

			rewardAmount = remainingBalance < rewardAmount ? remainingBalance : rewardAmount;

			sentAmount = sentAmount.add(rewardAmount);

			depositToken.safeTransfer(receiverAddress, rewardAmount);

			lastRewardTime = block.timestamp;
			emit Withdraw(rewardAmount);
		}
	}

	// Only Owner functions

	function setWMATICAddress(IWMATIC _WMATIC) external onlyOwner {
		WMATIC = _WMATIC;
		_WMATIC.approve(address(nativeConvertor), type(uint256).max);
	}

	function setEscrowRatio(uint256 _escrowRatio) external onlyOwner {
		escrowRatio = _escrowRatio;
	}

	function setDevFees(uint256 _devFees) external onlyOwner {
		devFees = _devFees;
	}

	function setProtocolFees(uint256 _protocolFees) external onlyOwner {
		protocolFees = _protocolFees;
	}

	function setNativeConvertor(IWrapperToNative _nativeConvertor) external onlyOwner {
		nativeConvertor = _nativeConvertor;
		WMATIC.approve(address(_nativeConvertor), type(uint256).max);
	}

	function setDepositToken(IERC20Upgradeable _depositToken) external onlyOwner {
		depositToken = _depositToken;
	}

	function setOfferingToken(IERC20Upgradeable _offeringToken) external onlyOwner {
		offeringToken = _offeringToken;
	}

	function setDevFeesAddress(address _devFeesAddress) external onlyOwner {
		devFeesAddress = _devFeesAddress;
	}

	function setProtocolFeesAddress(address _protocolFeesAddress) external onlyOwner {
		protocolFeesAddress = _protocolFeesAddress;
	}

	function setEscrowAddress(address _escrowAddress) external onlyOwner {
		escrowAddress = _escrowAddress;
	}

	function setReceiverAddress(address _receiverAddress) external onlyOwner {
		receiverAddress = _receiverAddress;
	}

	function setOfferingAmount(uint256 _offeringAmount) external notStarted onlyOwner {
		offeringAmount = _offeringAmount;
	}

	function setRaisingAmount(uint256 _raisingAmount) external notStarted onlyOwner {
		raisingAmount = _raisingAmount;
	}

	function setStartTime(uint256 _startTime) external notStarted onlyOwner {
		startTime = _startTime;
	}

	function setEndTime(uint256 _endTime) external notStarted onlyOwner {
		endTime = _endTime;
	}

	function setRefundThreshold(uint256 _refundThreshold) external onlyOwner {
		refundThreshold = _refundThreshold;
	}

	function returnOfferingToken(address sendTo) external onlyOwner {
		uint256 offeringTokenBalance = offeringToken.balanceOf(address(this));
		offeringToken.safeTransfer(sendTo, offeringTokenBalance);
	}

	/// @notice Only to be called in emergency case, owner will have to manually refund all the deposits
	function haltIFO(address payable sendTo) external onlyOwner {
		uint256 wmaticBalance = WMATIC.balanceOf(address(this));
		if (wmaticBalance > 0) WMATIC.safeTransfer(sendTo, wmaticBalance);

		uint256 depositTokenBalance = depositToken.balanceOf(address(this));
		if (depositTokenBalance > 0) depositToken.safeTransfer(sendTo, depositTokenBalance);

		uint256 offeringTokenBalance = offeringToken.balanceOf(address(this));
		if (offeringTokenBalance > 0) offeringToken.safeTransfer(sendTo, offeringTokenBalance);

		(bool success, ) = sendTo.call{value: address(this).balance}(new bytes(0));
		require(success, "Failed sending MATIC to given address");
	}

	function vestedAmount(address _user) public view returns (uint256) {
		uint256 amountToUser = getOfferingAmount(_user);

		// IFO still active
		if (block.timestamp < endTime) return 0;

		if (block.timestamp > endTime + vestingDuration) {
			return amountToUser;
		} else {
			return (amountToUser * (block.timestamp - endTime)) / vestingDuration;
		}
	}

	function releaseable(address _user) public view returns (uint256) {
		return vestedAmount(_user).sub(released[_user]);
	}

	function getAmounts() public view returns (uint256 _excessAmount, uint256 _distributionAmount) {
		address[] memory _usersList = usersList;

		for (uint256 i; i < _usersList.length; ++i) {
			_excessAmount = _excessAmount.add(getRefundingAmount(_usersList[i]));
			_distributionAmount = _distributionAmount.add(getOfferingAmount(_usersList[i]));
		}
	}

	// Internal functions & Fallback

	function _deposit(uint256 _amount) internal {
		require(block.timestamp >= startTime, "Sale not started");
		require(block.timestamp <= endTime, "Sale ended");

		if (amount[_msgSender()] == 0) {
			usersList.push(address(_msgSender()));
		}

		amount[_msgSender()] = amount[_msgSender()].add(_amount);
		totalAmount = totalAmount.add(_amount);

		// _updateExcessAndDistributionAmount();

		emit Deposit(_msgSender(), _amount);
	}

	// function _updateExcessAndDistributionAmount() internal {
	// 	address[] memory _usersList = usersList;
	// 	uint256 _distributionAmount;
	// 	uint256 _excessAmount;

	// 	for (uint256 i; i < _usersList.length; i++) {
	// 		_excessAmount = _excessAmount.add(getRefundingAmount(_usersList[i]));
	// 		_distributionAmount = _distributionAmount.add(getOfferingAmount(_usersList[i]));
	// 	}

	// 	excessAmount = _excessAmount;
	// 	distributionAmount = _distributionAmount;
	// }

	function _totalDepositAmount() internal view returns (uint256) {
		(uint256 devFeesAmount, uint256 escrowFeesAmount, uint256 protocolFeesAmount) = getFeeParticulars();

		return _amountToUse() - (devFeesAmount + escrowFeesAmount + protocolFeesAmount);
	}

	function _amountToUse() internal view returns (uint256) {
		(uint256 _excessAmount, ) = getAmounts();
		return totalAmount - _excessAmount;
	}

	receive() external payable {
		require(msg.value > 0, "No amount sent");
		require(address(depositToken) == address(WMATIC), "Cannot send to a NON NATIVE pool");

		WMATIC.deposit{value: msg.value}();
		_deposit(msg.value);
	}
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWMATIC is IERC20Upgradeable {
	function deposit() external payable;

	function withdraw(uint256) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

interface IWrapperToNative {
	function withdrawTo(address recipient, uint256 value) external;
}