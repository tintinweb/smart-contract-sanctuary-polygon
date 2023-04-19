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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract FDFRisk is Initializable{
    uint256 private riskBase;

    uint256 public riskLevelPre = 0;

    struct RiskLevel {
        uint256 open;
        uint256 start;
        uint256 next;
        uint256 close;
    }

    struct Risk {
        uint256 startTime;
        uint256 riskNum;
        bool  riskFreeze;
        bool riskLevelNext;
    }

    Risk private risk;

    RiskLevel[] private riskLevels;

    function initialize(uint256 baseAmount) public onlyInitializing {
        risk = Risk(0,0,false,false);
        if (baseAmount == 0) {
            baseAmount = 10_000e6;
        }
        riskBase = baseAmount;
        initRiskLevel();
    }

    function initRiskLevel() private {
        RiskLevel memory rl1 = RiskLevel(50 * riskBase,35 * riskBase,20 * riskBase,75 * riskBase);
        riskLevels.push(rl1);
        RiskLevel memory rl2 = RiskLevel(250 * riskBase,150 * riskBase,100 * riskBase,250 * riskBase);
        riskLevels.push(rl2);
        RiskLevel memory rl3 = RiskLevel(500 * riskBase,250 * riskBase,100 * riskBase,500 * riskBase);
        riskLevels.push(rl3);
    }

    function getRisk() public view returns(Risk memory) {
        return risk;
    }

    function updateRiskLevel(uint256 amount) internal {
        if (amount >= riskLevels[2].open && riskLevelPre == 2) {
            riskLevelPre = 3;
        }
        if (amount >= riskLevels[1].open && riskLevelPre == 1) {
            riskLevelPre = 2;
        }
        if (amount >= riskLevels[0].open && riskLevelPre == 0) {
            riskLevelPre = 1;
        }

        if (riskLevelPre == 0) {
            return;
        }

        if (riskLevelPre == 1) {
            if (amount >= riskLevels[0].close) {
                closeRisk();
                return;
            }

            if (amount < riskLevels[0].start && amount >= riskLevels[0].next && !risk.riskLevelNext) {
                exeRiskLevel1();
            }

            if (amount < riskLevels[0].next) {
                exeRiskLevel2();
            }
        }
        if (riskLevelPre == 2) {
            if (amount >= riskLevels[1].close) {
                closeRisk();
                return;
            }

            if (amount < riskLevels[1].start && amount >= riskLevels[1].next && !risk.riskLevelNext) {
                exeRiskLevel1();
            }

            if (amount < riskLevels[1].next) {
                exeRiskLevel2();
            }

        }
        if (riskLevelPre == 3) {
            if (amount >= riskLevels[2].close) {
                closeRisk();
                return;
            }

            if (amount < riskLevels[2].start && amount >= riskLevels[2].next && !risk.riskLevelNext) {
                exeRiskLevel1();
            }

            if (amount < riskLevels[2].next) {
                exeRiskLevel2();
            }
        }
    }

    function closeRisk() private {
        risk.riskLevelNext = false;
        risk.riskFreeze = false;
        risk.startTime = 0;
    }
    function exeRiskLevel1() private {
        if (risk.startTime == 0) {
            risk.startTime = block.timestamp;
        }
        if (!risk.riskFreeze && !risk.riskLevelNext) {
            risk.riskFreeze = true;
            risk.riskNum = risk.riskNum + 1;
        }
    }
    function exeRiskLevel2() private {
        if (risk.startTime == 0) {
            risk.startTime = block.timestamp;
        }
        if (!risk.riskLevelNext) {
            risk.riskFreeze = true;
            risk.riskLevelNext = true;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "./FDFRisk.sol";

contract Mutual is FDFRisk,Ownable{
    using SafeMath for uint256;

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'FDFStaking: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    address public  defaultRefer;

    uint256 private constant sysDevPercents = 70;
    address public  sysDev;

    uint256 private constant insurancePercents = 30;
    address public  insurance;

    uint256 private constant foundationPercents = 100;
    address public  foundation;

    uint256 private constant marketECOPercents = 100;
    address public  marketECO;

    uint256 private constant minDeposit = 100e6; //usdt

    uint256 private  timeStep;
    uint256 private  dayPerCycle;
    uint256 private  maxAddFreeze;
    uint256 private constant referDepth = 10;

    uint256 private constant staticPercents = 2250;
    uint256 private constant baseDivider = 10000;

    uint256 private constant realPercents = 70; // / 100
    uint256 private constant splitPercents = 30; // / 100

    uint256 private constant splitTransferPercents = 10; // / 100

    uint256[referDepth] private invitePercents = [500, 100, 200, 300, 100, 200, 200, 200, 100, 100];

    uint256[5] private levelMaxDeposit = [500e6,1000e6,1500e6,2000e6,2500e6];
    uint256[5] private levelMinDeposit = [100e6,500e6,1000e6,1500e6,2000e6];
    uint256[5] private levelTeam = [0, 20, 40, 60, 120];
    uint256[5] private levelInvite = [0, 5000e6, 10_000e6, 15_000e6, 50_000e6];

    struct RewardInfo {
        uint256 freezeCapitals;
        uint256 capitals;
        uint256 riskCapitals;
        bool    isSplitUse;

        uint256 level1;
        uint256 level25;

        uint256 unfreezeLevel68;
        uint256 freezeTotalLevel68;

        uint256 unfreezeLevel910;
        uint256 freezeTotalLevel910;

        uint256 transferSplit;

        uint256 debtWithdraw;
        uint256 debtSplit;
    }


    struct UserRewardInfo {
        uint256 freezeCapitals;
        uint256 totalCapitals;
        uint256 totalStatic;
        uint256 totalLevel1;
        uint256 totalLevel25;
        uint256 totalLevel68;
        uint256 totalLevel910;
        uint256 totalFreeze;
        uint256 freezeSplit;
        uint256 totalRevenue;
        uint256 pendingSplit;
        uint256 pendingWithdraw;
    }

    struct UserInfo {
        address referrer;
        uint256 registers;
        address addr;
        uint256 startTime;
        uint256 level;
        uint256 maxDeposit;
        uint256 totalHisDeposit;
        uint256 totalTeamDeposit;
        uint256 totalLevel11Deposit;
        uint256 riskNum;
        uint256 unfreezeIndex;

        uint256 teamNum;
        uint256 level1Nums;

        uint256 otherTeamDeposit;
        address maxTeamAddr;
        uint256 maxTeamDeposit;
    }

    struct OrderInfo {
        address addr;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool isUnFreeze;
    }

    struct SysInfo{
        address  usdtAddr;
        uint256  startTime;
        uint256  lastTime;
        uint256  totalStakingUser;
        uint256  totalRegisterUser;
        uint256  balance;
    }

    SysInfo private sysInfo;

    mapping(address => UserInfo) private userInfo;
    address[] public users;

    mapping(address=> OrderInfo[]) private orderInfos;

    mapping(address => RewardInfo) private rewardInfo;

    mapping(address => mapping(address => uint256[])) private freezeLevel610;

    mapping(address => address[]) private downLevel1Users;

    OrderInfo[] private orders;

    IERC20 private  usdt;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);

    modifier onlyRegister() {
        require(userInfo[msg.sender].referrer != address(0), "req register");
        _;
    }

    function initialize(address usdtAddr,address admin,
        address sys,address ins,address found, address market, uint256 timesDay,uint256 baseAmount) public initializer {

        FDFRisk.initialize(baseAmount);

        if (usdtAddr == address(0)) {
            usdtAddr = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        }
        usdt = IERC20(usdtAddr);

        if (timesDay == 0) {
            timesDay = 1 days;
        }
        timeStep = timesDay;
        dayPerCycle = 15 * timeStep;
        maxAddFreeze = 45 * timeStep + dayPerCycle;

        sysInfo.startTime = block.timestamp;
        sysInfo.lastTime = block.timestamp;

        if (admin == address(0)) {
            admin = 0x880075B511b0e88D354c197f1f8C1FF44B9C089F;
        }
        defaultRefer = admin;

        if (sys == address(0)) {
            sys = 0xdB72168d4a200b5aFe04Cf10eBf47Ee93cd08555;
        }
        sysDev = sys;

        if (ins == address(0)) {
            ins = 0x408416B87Cd4e83BA1Bda5f6f2B4139E43202e6f;
        }
        insurance = ins;

        if (found == address(0)) {
            found = 0xbd888488df0712491810235F4e8648c8a5EC8608;
        }
        foundation = found;

        if (market == address(0)) {
            market = 0xe2433b048beB2B078b05e47897dd1314Ff0dd801;
        }
        marketECO = market;

        _transferOwnership(defaultRefer);
    }

    function register(address ref_) external{
        require(msg.sender != defaultRefer &&
        userInfo[msg.sender].referrer == address(0) &&
        (userInfo[ref_].referrer != address(0) || ref_ == defaultRefer) &&
        ref_ != address(0) && msg.sender != ref_,"sender err");

        UserInfo storage user = userInfo[msg.sender];
        user.addr = msg.sender;
        user.referrer = ref_;
        users.push(msg.sender);

        address ref = ref_;
        for (uint i =0; i<referDepth; i++) {
            UserInfo storage userRef = userInfo[ref];
            userRef.registers++;
            ref = userRef.referrer;
            if (ref == address(0)) {
                break;
            }
        }
        emit Register(msg.sender, ref_);
    }

    function deposit(uint256 _amount) external onlyRegister {
        require(_amount > 0,"zero amount");
        bool success = usdt.transferFrom(msg.sender, address(this), _amount);
        require(success,"transferFrom failed");

        _deposit(msg.sender, _amount);

        emit Deposit(msg.sender, _amount);
    }

    function depositBySplit(uint256 _amount) external onlyRegister {
        require(!rewardInfo[msg.sender].isSplitUse, "used split");

        rewardInfo[msg.sender].isSplitUse = true;

        require(_amount > 0,"zero amount");

        (uint256 pendingSplit,,) = userPendingAmount(msg.sender);

        require(pendingSplit >= _amount,"insufficient integral");

        rewardInfo[msg.sender].debtSplit = rewardInfo[msg.sender].debtSplit.add(_amount);

        _deposit(msg.sender, _amount);

        emit DepositBySplit(msg.sender, _amount);
    }

    function withdraw() external lock {
        (,uint256 pendingAmount,) = userPendingAmount(msg.sender);
        RewardInfo storage ri = rewardInfo[msg.sender];

        ri.debtWithdraw = ri.debtWithdraw.add(pendingAmount);
        usdt.transfer(msg.sender,pendingAmount);
    }

    function transferSplit(address to,uint256 _amount) external lock {
        require(_amount > 0,"zero amount");
        require(to != address(0),"addr is zero");

        RewardInfo storage ri = rewardInfo[msg.sender];
        (uint256 pendingSplit,,) = userPendingAmount(msg.sender);
        uint256 newAmount = _amount.add(_amount.mul(splitTransferPercents).div(100));
        require(pendingSplit >= newAmount,"insufficient integral");

        ri.debtSplit = ri.debtSplit.add(newAmount);
        rewardInfo[to].transferSplit = rewardInfo[to].transferSplit.add(_amount);
    }

    function _deposit(address _userAddr, uint256 _amount) private {

        UserInfo memory user = userInfo[_userAddr];
        require(_amount % minDeposit == 0 && _amount >= user.maxDeposit, "amount less or not mod");
        require(_amount >= levelMinDeposit[user.level] &&
            _amount <= levelMaxDeposit[user.level],"amount level err");

        _distributeAmount(_amount);

        (bool isUnFreeze, uint256 newAmount) = _unfreezeCapitalOrReward(msg.sender,_amount);

        _updateLevelReward(msg.sender,_amount,isUnFreeze);

        bool isNew = _updateUserInfo(_userAddr,_amount,isUnFreeze);

        _updateTeamInfos(msg.sender,newAmount,isNew);

        super.updateRiskLevel(usdt.balanceOf(address(this)));
    }

    function _distributeAmount(uint256 _amount) private {
        uint256 sysDevAmount = _amount.mul(sysDevPercents).div(baseDivider);
        uint256 insuranceAmount = _amount.mul(insurancePercents).div(baseDivider);
        uint256 foundationAmount = _amount.mul(foundationPercents).div(baseDivider);
        uint256 marketECOAmount = _amount.mul(marketECOPercents).div(baseDivider);

        usdt.transfer(sysDev,sysDevAmount);
        usdt.transfer(insurance,insuranceAmount);
        usdt.transfer(foundation,foundationAmount);
        usdt.transfer(marketECO,marketECOAmount);
    }

    function _updateUserInfo(address _userAddr,uint256 _amount,bool isUnFreeze) private returns(bool){
        UserInfo storage user = userInfo[_userAddr];
        bool isNew;
        if(user.maxDeposit == 0) {
            user.startTime = block.timestamp;
            isNew = true;
            sysInfo.totalStakingUser++;
        }

        if (_amount > user.maxDeposit) {
            user.maxDeposit = _amount;
        }

        Risk memory risk = getRisk();

        if (risk.riskFreeze && !risk.riskLevelNext && user.riskNum < risk.riskNum && !isUnFreeze) {
            user.riskNum = user.riskNum.add(1);
        }

        for (uint256 i = levelMinDeposit.length - 1; i >0; i--) {
            if (user.maxDeposit >= levelMinDeposit[i] &&
            user.teamNum >= levelTeam[i] &&
            user.maxTeamDeposit >= levelInvite[i] &&
                user.totalTeamDeposit.sub(user.maxTeamDeposit) >= levelInvite[i]) {

                if (user.level != i) {
                    user.level = i;
                }

                break;
            }
        }
        return isNew;
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount) private returns(bool isUnFreeze,uint256 newAmount) {

        RewardInfo storage ri = rewardInfo[_userAddr];
        uint256 addFreeze = dayPerCycle.add(orderInfos[_userAddr].length.mul(timeStep));
        if(addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(addFreeze);
        OrderInfo memory orderIn = OrderInfo(_userAddr,_amount, block.timestamp, unfreezeTime, false);
        orderInfos[_userAddr].push(orderIn);
        orders.push(orderIn);
        ri.freezeCapitals = ri.freezeCapitals.add(_amount);

        if (orderInfos[_userAddr].length <= 1) {
            return (false, _amount);
        }

        UserInfo storage user = userInfo[_userAddr];
        OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];

        if (block.timestamp < order.endTime || order.isUnFreeze) {
            return (false, _amount);
        }

        order.isUnFreeze = true;
        user.unfreezeIndex = user.unfreezeIndex.add(1);

        ri.freezeCapitals = ri.freezeCapitals.sub(order.amount);
        newAmount = _amount.sub(order.amount);

        (,,bool isStaticRisk) = userTotalRevenue(_userAddr);
        if (!isStaticRisk) {
            ri.capitals = ri.capitals.add(order.amount);
        }else{
            ri.riskCapitals = ri.riskCapitals.add(order.amount);
        }

        return (true,newAmount);
    }

    function _updateLevelReward(address _userAddr, uint256 _amount, bool _isUnFreeze) private {
        address upline = _userAddr;
        for (uint256 i =0; i < referDepth; i++) {
            upline = userInfo[upline].referrer;
            if (upline == address(0)) {
                return;
            }

            if (orderInfos[upline].length == 0) {
                continue;
            }

            uint256 newAmount;
            OrderInfo memory latestUpOrder = orderInfos[upline][orderInfos[upline].length.sub(1)];
            uint256 maxFreezing = latestUpOrder.endTime > block.timestamp ? latestUpOrder.amount : 0;
            if(maxFreezing < _amount){
                newAmount = maxFreezing;
            }else{
                newAmount = _amount;
            }

            if (newAmount == 0) {
                continue;
            }
            _updateReward(_userAddr,upline,i,newAmount,_isUnFreeze);
        }
    }

    function _updateReward(address _userAddr,address upline,uint256 i, uint256 newAmount, bool _isUnFreeze) private {

        UserInfo memory upuser = userInfo[upline];

        (, bool isRisk,) = userTotalRevenue(upline);

        RewardInfo storage ri = rewardInfo[upline];

        uint256 reward = newAmount.mul(invitePercents[i]).div(baseDivider);
        if (i == 0) {
            if (!isRisk) {
                ri.level1 = ri.level1.add(reward);
            }
            return;
        }

        if (upuser.level >= 1 && i == 1) {
            if (!isRisk) {
                ri.level25 = ri.level25.add(reward);
            }
            return;
        }

        if (upuser.level >= 2 && i == 2) {
            if (!isRisk) {
                ri.level25 = ri.level25.add(reward);
            }
            return;
        }

        if (upuser.level >= 3 && i == 3) {
            if (!isRisk) {
                ri.level25 = ri.level25.add(reward);
            }
            return;
        }

        if (upuser.level >= 3 && i == 4) {
            if (!isRisk) {
                ri.level25 = ri.level25.add(reward);
            }
            return;
        }

        if (upuser.level < 4) {
            return;
        }

        freezeLevel610[upline][_userAddr].push(reward);
        if (i < 8) {
            ri.freezeTotalLevel68 = ri.freezeTotalLevel68.add(reward);
        }else{
            ri.freezeTotalLevel910 = ri.freezeTotalLevel910.add(reward);
        }

        if (_isUnFreeze) {
            uint256 len = freezeLevel610[upline][_userAddr].length;
            if (len >0) {
                uint256 freeAmount = freezeLevel610[upline][_userAddr][len - 1];
                if (i < 8) {
                    if (!isRisk) {
                        ri.unfreezeLevel68 = ri.unfreezeLevel68.add(freeAmount);
                    }
                    ri.freezeTotalLevel68 = ri.freezeTotalLevel68.sub(freeAmount);
                }else {
                    if (!isRisk) {
                        ri.unfreezeLevel910 = ri.unfreezeLevel910.add(freeAmount);
                    }
                    ri.freezeTotalLevel910 = ri.freezeTotalLevel910.sub(freeAmount);
                }
            }
        }
    }

    function _updateTeamInfos(address _userAddr, uint256 _amount, bool _isNew) private {

        if (_amount == 0) {
            return;
        }

        address downline = _userAddr;
        address upline = userInfo[_userAddr].referrer;
        if (upline == address(0)) return;

        if (_isNew) {
            userInfo[upline].level1Nums = userInfo[upline].level1Nums.add(1);
            downLevel1Users[upline].push(msg.sender);
        }

        for(uint256 i = 0; i < referDepth; i++) {
            UserInfo storage downUser = userInfo[downline];
            UserInfo storage upUser = userInfo[upline];

            if (_isNew) {
                upUser.teamNum = upUser.teamNum.add(1);
            }

            RewardInfo memory downReward = rewardInfo[downline];

            upUser.totalTeamDeposit = upUser.totalTeamDeposit.add(_amount);


            if (i == referDepth - 1) {
                upUser.totalLevel11Deposit = upUser.totalLevel11Deposit.add(_amount);
            }

            uint256 downTotalTeamDeposit = downReward.freezeCapitals.add(downUser.totalTeamDeposit);
            downTotalTeamDeposit = downTotalTeamDeposit.sub(downUser.totalLevel11Deposit);

            if (upUser.maxTeamAddr != downline) {
                if (upUser.maxTeamDeposit < downTotalTeamDeposit) {
                    upUser.maxTeamAddr = downline;
                    upUser.maxTeamDeposit = downTotalTeamDeposit;
                }
            }else {
                upUser.maxTeamDeposit = downTotalTeamDeposit;
            }

            for (uint256 lv = levelMinDeposit.length - 1; lv >0; lv--) {
                if (upUser.maxDeposit >= levelMinDeposit[lv] &&
                upUser.teamNum >= levelTeam[lv] &&
                upUser.maxTeamDeposit >= levelInvite[lv] &&
                    upUser.totalTeamDeposit.sub(upUser.maxTeamDeposit) >= levelInvite[lv]) {
                    if (upUser.level != lv) {
                        upUser.level = lv;
                    }
                    break;
                }
            }

            if(upline == defaultRefer) break;
            downline = upline;
            upline = userInfo[upline].referrer;
        }
    }

    function userPendingAmount(address _user) private view returns (uint256, uint256, uint256) {
        RewardInfo memory ri = rewardInfo[_user];

        (uint256 totalRevenue,,)= userTotalRevenue(_user);

        return (totalRevenue.mul(splitPercents).div(100).add(ri.transferSplit).sub(ri.debtSplit),
        ri.capitals.add(ri.riskCapitals).add(totalRevenue.mul(realPercents).div(100)).sub(ri.debtWithdraw),
        totalRevenue);
    }

    function userTotalRevenue(address _userAddr) private view returns(uint256 totalRevenue,bool isRisk,bool isStaticRisk) {
        RewardInfo memory ri = rewardInfo[_userAddr];

        uint256 staticReward =  ri.capitals.mul(staticPercents).div(baseDivider);

        totalRevenue = staticReward.add(ri.level1).add(ri.level25)
        .add(ri.unfreezeLevel68).add(ri.unfreezeLevel910);

        Risk memory risk = getRisk();

        UserInfo memory user = userInfo[_userAddr];

        if (!risk.riskFreeze || (risk.startTime != 0 && user.startTime > risk.startTime) ||
        totalRevenue < ri.freezeCapitals || (!risk.riskLevelNext && user.riskNum >= risk.riskNum)) {
            isRisk = false;
        }else {
            isRisk = true;
        }

        if (!risk.riskFreeze || (risk.startTime != 0 && user.startTime > risk.startTime) ||
        totalRevenue < ri.freezeCapitals) {
            isStaticRisk = false;
        }else {
            isStaticRisk = true;
        }

        return (totalRevenue, isRisk ,isStaticRisk);
    }

    function userRewardInfo(address _user) external view returns(UserRewardInfo memory) {
        RewardInfo memory ri = rewardInfo[_user];

        uint256 staticExpect = ri.freezeCapitals.mul(staticPercents).div(baseDivider);

        (uint256 pendingSplit,uint256 pendingWithDraw, uint256 totalRevenue) = userPendingAmount(_user);

        UserRewardInfo memory uri = UserRewardInfo(
            ri.freezeCapitals,
            ri.capitals.add(ri.riskCapitals),
            ri.capitals.mul(staticPercents).div(baseDivider).mul(realPercents).div(100),
            ri.level1.mul(realPercents).div(100),
            ri.level25.mul(realPercents).div(100),
            ri.unfreezeLevel68.mul(realPercents).div(100),
            ri.unfreezeLevel910.mul(realPercents).div(100),

            ri.freezeCapitals.add(
                    staticExpect.add(ri.freezeTotalLevel68).add(ri.freezeTotalLevel910).mul(realPercents).div(100)
                ),

            staticExpect.add(ri.freezeTotalLevel68).add(ri.freezeTotalLevel910).mul(splitPercents).div(100),

            totalRevenue,
            pendingSplit,
            pendingWithDraw
        );

        return uri;
    }

    function userOrder(address _user,uint256 index) external view returns(OrderInfo memory) {
        return orderInfos[_user][index];
    }

    function userOrders(address _user) external view returns(OrderInfo[] memory) {
        return orderInfos[_user];
    }

    function userOrderLen(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getOrders() external view returns(OrderInfo[] memory) {
        uint256 size;
        if (orders.length > 10) {
            size = 10;
        }else {
            size = orders.length;
        }

        OrderInfo[] memory ors = new OrderInfo[](size);
        for (uint256 i=0; i<size; i++) {
            ors[i] = orders[orders.length - i - 1];
        }
        return ors;
    }

    function downLevel1UserAddrs(address _user) external view returns(address[] memory) {
        return downLevel1Users[_user];
    }

    function userDownLevel1(address _user,uint256 _start,uint256 _nums) external view returns(UserInfo[] memory)  {
        UserInfo[] memory userIn = new  UserInfo[](_nums);
        for (uint256 i = 0; i < _nums; i++) {
            address addr = downLevel1Users[_user][i+_start];
            userIn[i] = userInfoPer(addr);
        }
        return userIn;
    }

    function userInfoPer(address _user) public view returns(UserInfo memory) {
        UserInfo memory user = userInfo[_user];
        RewardInfo memory ri = rewardInfo[_user];

        user.otherTeamDeposit = user.totalTeamDeposit.sub(user.maxTeamDeposit);
        user.totalTeamDeposit = ri.freezeCapitals.add(user.totalTeamDeposit);
        user.totalHisDeposit = ri.freezeCapitals.add(ri.capitals).add(ri.riskCapitals);

        return user;
    }

    function getSysInfo() external view returns(SysInfo memory) {
        SysInfo memory sys = sysInfo;
        sys.usdtAddr = address(usdt);
        sys.balance = usdt.balanceOf(address(this));
        sys.totalRegisterUser = users.length;
        return sys;
    }
}