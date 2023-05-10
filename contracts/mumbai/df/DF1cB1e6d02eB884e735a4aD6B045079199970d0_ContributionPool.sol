// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
interface IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/Constants.sol";
import "../utils/ExchangeRateProxyInterface.sol";
import "../router/GeniusRouter.sol";
import "./ContributionPoolVesting.sol";
import "../utils/InvestmentBlacklist.sol";
import "../utils/ExchangeRateProxy.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ContributionPool is OwnableUpgradeable {


    enum ContributionPoolStatus {
        OPEN,
        CLOSED
    }

    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    
    GeniusRouter public geniusRouter;
    InvestmentBlacklist public investmentBlacklist;
    address public processorAddress;
    uint256 public buyRatio;

    ExchangeRateProxy[] public inputTokenExchangeRateProxyList;
    address[] public inputTokenAddressList;
    address public outputTokenAddress;

    address[] public outputAddresses;
    uint256[] public outputRatios;

    uint256[] public discountAmountMax;
    uint256[] public discountPercentage;

    uint256 public vestingLockingTime;
    uint256 public vestingReleaseInterval;
    uint256 public vestingReleaseCount;
    ContributionPoolStatus public poolStatus;
    
    address public vestingImplementation;
    mapping(address => bool) public isContributionVesting;

    event BuyTokens(address indexed senderAddress, address vestingContractAddress, uint256 inputTokenIndex, uint256 amountIn, uint256 amountOut);

    modifier onlyProcessor() {
        require(
            processorAddress == msg.sender,
            "Only the processor call this function"
        );
        _;
    }  

    modifier onlyOpenPool() {
        require(
            poolStatus == ContributionPoolStatus.OPEN,
            "The pool is not open."
        );
        _;
    }      

    function initialize() public initializer {        
        __Ownable_init_unchained();
    }

    function setVestingImplementation(address _vestingImplementation) external onlyOwner {
        require(_vestingImplementation != address(0), "VestingImplementation cannot be the zero address");
        vestingImplementation = _vestingImplementation;
    }

    function updatePoolStatus(
        ContributionPoolStatus _poolStatus
    ) onlyOwner external {
        poolStatus = _poolStatus;
    }

    function configureTokens(
        address _outputTokenAddress,
        address[] memory _inputTokenAddressList,
        address[] memory _inputTokenExchangeRateProxyList
    ) onlyOwner external {
        require(_inputTokenExchangeRateProxyList.length == _inputTokenAddressList.length,"Please pass the exchange rate for each input token");
        outputTokenAddress = _outputTokenAddress;
        inputTokenAddressList = _inputTokenAddressList;
        
        delete inputTokenExchangeRateProxyList;
        for (uint i=0; i < _inputTokenExchangeRateProxyList.length; i++) {
            inputTokenExchangeRateProxyList.push(ExchangeRateProxy(_inputTokenExchangeRateProxyList[i]));
        }
    }
    
    function configureContracts(
        address _geniusRouter,
        address _investmentBlacklist) onlyOwner external {
        geniusRouter = GeniusRouter(_geniusRouter);
        investmentBlacklist =  InvestmentBlacklist(_investmentBlacklist);
    }

    function configureWallets(address _processorAddress) onlyOwner external {
        processorAddress = _processorAddress;
    }

    function configureVesting(
        uint256 _vestingLockingTime,
        uint256 _vestingReleaseInterval,
        uint256 _vestingReleaseCount
    ) onlyOwner external {
        vestingLockingTime = _vestingLockingTime;
        vestingReleaseInterval = _vestingReleaseInterval;
        vestingReleaseCount = _vestingReleaseCount;
    }

    function configureDiscount(
        uint256[] memory _discountAmountMax, 
        uint256[] memory _discountPercentage) external onlyOwner {
        require(_discountAmountMax.length == _discountPercentage.length, "Amounts and discounts length don't match");
        discountAmountMax = _discountAmountMax;
        discountPercentage = _discountPercentage;
    }

    function getExchangeRate(uint256 _inputTokenIndex) view public returns (uint256 _exchangeRate) {
        return inputTokenExchangeRateProxyList[_inputTokenIndex].getExchangeRate();
    }

    function calculateOutputForInput(
        uint256 _inputTokenIndex, 
        uint256 _inputAmount) view public returns (uint256 _outputAmount, uint256 _discountedOutputAmount) {              
        _outputAmount = inputTokenExchangeRateProxyList[_inputTokenIndex].getAmountsOut(_inputAmount);
        uint256 discount = getDiscountForAmount(_inputAmount);  
        _discountedOutputAmount = _outputAmount.add((_outputAmount.mul(discount)).div(BASIS_POINT));
        return (_outputAmount, _discountedOutputAmount);
    }

    function buyTokens(
        uint256 _inputTokenIndex,
        uint256 _inputAmount) onlyOpenPool external {
        require(!investmentBlacklist.isBlacklisted(msg.sender),"Investor is blacklisted");
        (uint256 _outputAmount, uint256 _discountedOutputAmount) = calculateOutputForInput(_inputTokenIndex,_inputAmount);
    
        require(geniusRouter.processPayment(inputTokenAddressList[_inputTokenIndex], msg.sender, address(this), _inputAmount) ,"Cannot process input token");
        
        ContributionPoolVesting vesting = ContributionPoolVesting(Clones.clone(address(vestingImplementation)));
        vesting.configure(
            msg.sender,
            _discountedOutputAmount,
            vestingLockingTime,
            vestingReleaseInterval,
            vestingReleaseCount
        );

        // ContributionPoolVesting vesting = new ContributionPoolVesting(
        //     msg.sender,
        //     _discountedOutputAmount,
        //     vestingLockingTime,
        //     vestingReleaseInterval,
        //     vestingReleaseCount                    
        // );
        isContributionVesting[address(vesting)] = true;
        
        require(IERC20(outputTokenAddress).transfer(address(vesting), _discountedOutputAmount), "Cannot process output token");
        emit BuyTokens(msg.sender, address(vesting), _inputTokenIndex, _inputAmount, _discountedOutputAmount);
        
        uint256 instantBuyAmount = _inputAmount.mul(buyRatio).div(BASIS_POINT);
        if (instantBuyAmount > 0) { 
            ExchangeRateProxy exchangeProxy = inputTokenExchangeRateProxyList[_inputTokenIndex];            
            uint256 pathsLength = exchangeProxy.getQuickswapPathsLength();
            address[] memory paths = new address[](pathsLength);
            for (uint256 i = 0; i < pathsLength; i++) {
                paths[i] = exchangeProxy.quickswapPaths(i);
            }

            QuickswapInterface(exchangeProxy.getQuickswapRouterAddress()).swapExactTokensForTokens(
                instantBuyAmount,
                exchangeProxy.getAmountsOut(instantBuyAmount),
                paths,
                address(this),
                block.timestamp
            );
        }        
    }

    function createVestingContract(
        address _beneficiary,
        uint256 _outputAmount,
        uint256 _vestingLockingTime,
        uint256 _vestingReleaseInterval,
        uint256 _vestingReleaseCount
    ) public onlyOwner {
        ContributionPoolVesting vesting = ContributionPoolVesting(Clones.clone(address(vestingImplementation)));
        vesting.configure(
            _beneficiary,
            _outputAmount,
            _vestingLockingTime,
            _vestingReleaseInterval,
            _vestingReleaseCount   
        );        
        isContributionVesting[address(vesting)] = true; 
        require(geniusRouter.processPayment(outputTokenAddress, msg.sender, address(vesting), _outputAmount),"Cannot process payment");
    }

    function approveQuickswapRouter(uint256 _amount, address _quickswapRouteraddress, address _tokenContractAddress) external onlyOwner {
        IERC20(_tokenContractAddress).approve(_quickswapRouteraddress, _amount);
    }

    function withdrawInputTokens(uint256 _inputTokenIndex, address _destinationAddress, uint256 _amount) external onlyOwner {
        IERC20(inputTokenAddressList[_inputTokenIndex]).transfer(_destinationAddress, _amount);
    }

    function withdrawOutputTokens(address _destinationAddress, uint256 _amount) external onlyOwner {
        IERC20(outputTokenAddress).transfer(_destinationAddress, _amount);
    }

    function distributeTokens(uint256 _inputTokenIndex, uint256 _amount) external onlyProcessor {
        for (uint256 index = 0; index < outputAddresses.length; index++) {
            address outputAddress = outputAddresses[index];
            uint256 outputAmount = _amount.mul(outputRatios[index]).div(BASIS_POINT);
            require(outputAddress != address(0), "Cannot send to null address");
            IERC20(inputTokenAddressList[_inputTokenIndex]).transfer(outputAddress, outputAmount);
        }
    }

    function setDistributionAddresses(uint256 _buyRatio, address[] memory _outputAddresses, uint256[] memory _outputRatios) external onlyOwner {
        require(_outputAddresses.length == _outputRatios.length, "Address and ratio length dont match");
        outputAddresses = _outputAddresses;
        outputRatios = _outputRatios;
        buyRatio = _buyRatio;
        require(getTotalOutputRatio() == BASIS_POINT, "Total ratio is not 1");
    }
    

    function getDiscountForAmount(uint256 _amount) public view returns (uint256 discount) {
        for (uint256 index = 0; index < discountAmountMax.length; index++) {
            if (_amount < discountAmountMax[index]) {
                return discountPercentage[index];
            }
        }
        return 0;
    }
    
    function getTotalOutputRatio() public view returns (uint256 totalRatio) {
        for (uint256 index = 0; index < outputAddresses.length; index++) {
            totalRatio = totalRatio.add(outputRatios[index]);
        }
        return totalRatio;
    }

    function routerAddress() external view returns (address) {
        return address(geniusRouter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ContributionPoolInterface {
    function outputTokenAddress() external view returns (address);
    function routerAddress() external view returns (address);
    function processorAddress() external view returns (address);
    function isContributionVesting(address _vesting) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/Constants.sol";
import "./ContributionPoolInterface.sol";

contract ContributionPoolVesting is OwnableUpgradeable {

    using SafeMathUpgradeable for uint256;

    ContributionPoolInterface public contributionPool;

    address public beneficiaryAddress;
    address public tokenAddress;
    uint256 public tokenAmount;
    uint256 public vestingLockingTime;
    uint256 public vestingReleaseInterval;
    uint256 public vestingReleaseCount;
    uint256 public vestingReleaseItemAmount;
    uint256 public vestingReleasedAmount;

    uint256 public createdAt;
    event TokensReleased(uint256 _releasedAmount);

    modifier onlyProcessor() {
        require(
            contributionPool.processorAddress() == msg.sender,
            "Only the processor can call this function."
        );
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function configure(        
        address _beneficiaryAddress,
        uint256 _tokenAmount,
        uint256 _vestingLockingTime,
        uint256 _vestingReleaseInterval,
        uint256 _vestingReleaseCount) public initializer {
        contributionPool = ContributionPoolInterface(msg.sender);
        tokenAddress = contributionPool.outputTokenAddress();

        beneficiaryAddress = _beneficiaryAddress;
        tokenAmount = _tokenAmount;        
        vestingLockingTime = _vestingLockingTime;
        vestingReleaseInterval = _vestingReleaseInterval;
        vestingReleaseCount = _vestingReleaseCount;
        vestingReleaseItemAmount = _tokenAmount.div(vestingReleaseCount);

        IERC20Upgradeable(tokenAddress).approve(contributionPool.routerAddress(), MAX_INT);
        createdAt = block.timestamp;
    }    

    function releaseableAmount() view public returns (uint256) { 
        uint256 timePassed = (block.timestamp).sub(createdAt);
        if (timePassed < vestingLockingTime) {
            return 0;
        }
        timePassed = timePassed.sub(vestingLockingTime);
        uint256 intervals = timePassed.div(vestingReleaseInterval);
        intervals++;
        if (intervals >= vestingReleaseCount) {
            intervals = vestingReleaseCount;
        }
        uint256 totalAmount = vestingReleaseItemAmount.mul(intervals);
        return totalAmount.sub(vestingReleasedAmount);
    }

    function releaseTokens() public {
        require(beneficiaryAddress != address(0), "The vesting deposit doesn't have a beneficiary");
        uint256 amount = releaseableAmount();
        require(amount>0, "There are no tokens to be released");
        require(IERC20Upgradeable(tokenAddress).transfer(beneficiaryAddress, amount),"Cannot process transfer");        
        vestingReleasedAmount = vestingReleasedAmount.add(amount);
        emit TokensReleased(amount);
    }

    function setBeneficiaryAddress(address _beneficiaryAddress) external onlyProcessor {
        require(beneficiaryAddress == address(0),"Can only set the beneficiary if it's null");
        beneficiaryAddress = _beneficiaryAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/ExchangeRateProxyInterface.sol";
import "../utils/InvestmentReferral.sol";

contract GeniusRouter is OwnableUpgradeable {

    using SafeMathUpgradeable for uint256;

    ExchangeRateProxyInterface public exchangeRateProxy;
    address public routerManager;
    mapping (address => bool) public isPaymentProcessor;
    InvestmentReferral public investmentReferral;

    function initialize(address _routerManager, address _exchangeRateProxy, address _investmentReferralAddress,address[] memory _paymentProcessors) public initializer {        
        __Ownable_init_unchained();
        _configureRouter(_routerManager, _exchangeRateProxy, _investmentReferralAddress, _paymentProcessors);
    }

    function configureRouter(address _routerManager, address _exchangeRateProxy, address _investmentReferralAddress, address[] memory _paymentProcessors) external onlyOwner {
        _configureRouter(_routerManager, _exchangeRateProxy, _investmentReferralAddress, _paymentProcessors);
    }    

    function _configureRouter(address _routerManager, address _exchangeRateProxy, address _investmentReferralAddress, address[] memory _paymentProcessors) internal {
        routerManager = _routerManager;
        exchangeRateProxy = ExchangeRateProxyInterface(_exchangeRateProxy);
        investmentReferral = InvestmentReferral(_investmentReferralAddress);
        for(uint i = 0; i<_paymentProcessors.length; i++) {
            isPaymentProcessor[_paymentProcessors[i]] = true;
        }
    }

    event InvestmentPoolCreated(address indexed investmentPoolFactoryAddress, address indexed investmentPoolAddress);
    event InvestmentCreated(uint256 _inputTokenIndex, address indexed investmentPoolFactoryAddress, address indexed investmentPoolAddress, uint256 investmentIndex);
    event RetrievedRewards(address indexed investmentPoolFactoryAddress, address indexed investmentPoolAddress, uint256 investmentIndex, uint256 amount);
    event RetrievedPrincipal(address indexed investmentPoolFactoryAddress, address indexed investmentPoolAddress, uint256 investmentIndex, uint256 amount);
    event RetrievedAffiliateRewards(address indexed investmentPoolFactoryAddress, address indexed investmentPoolAddress, uint256 investmentIndex, uint256 amount);
    event BuyTokens(address indexed senderAddress, uint256 amountIn, uint256 amountOut);
    event InvestmentTransfer(address indexed investmentPoolFactoryAddress, address indexed investmentPoolAddress, uint256 investmentIndex, address newAddress);

    struct ScheduledPayment {
        address tokenContractAddress;
        address fromAddress;
        address toAddress;
        uint256 amount;
        uint256 scheduledTimestamp;
        bool completed;
    }

    ScheduledPayment[] scheduledPayments;

    modifier onlyPaymentProcessor() {
        require(
            isPaymentProcessor[msg.sender],
            "Only a payment processor can call this function"
        );
        _;
    }

    modifier onlyRouterManager() {
        require(
            msg.sender == routerManager,
            "Only a router manager can call this function"
        );
        _;
    }

    function checkTokenApproval(address _tokenAddress, address _walletAddress) external view returns (uint256 _allowance) {
        return IERC20(_tokenAddress).allowance(_walletAddress,address(this));
    }    

    function registerPaymentProcessor(address _paymentProcessor) external onlyRouterManager {
        isPaymentProcessor[_paymentProcessor] = true;
    }

    function removePaymentProcessor(address _paymentProcessor) external onlyRouterManager {
        isPaymentProcessor[_paymentProcessor] = false;
    }

    function emitInvestmentPoolCreatedEvent(address _investmentPoolFactoryAddress, address _investmentPoolAddress) public onlyPaymentProcessor {
        emit InvestmentPoolCreated(_investmentPoolFactoryAddress, _investmentPoolAddress);
    }

    function emitInvestmentCreatedEvent(uint256 _inputTokenIndex, address _investmentPoolFactoryAddress, address _investmentPoolAddress, uint256 _investmentIndex) public onlyPaymentProcessor {
        emit InvestmentCreated(_inputTokenIndex, _investmentPoolFactoryAddress, _investmentPoolAddress, _investmentIndex);
    }

    function emitRetrievedRewardsEvent(address _investmentPoolFactoryAddress, address _investmentPoolAddress, uint256 _investmentIndex, uint256 _amount) public onlyPaymentProcessor {
        emit RetrievedRewards(_investmentPoolFactoryAddress, _investmentPoolAddress, _investmentIndex, _amount);
    }

    function emitRetrievedPrincipalEvent(address _investmentPoolFactoryAddress, address _investmentPoolAddress, uint256 _investmentIndex, uint256 _amount) public onlyPaymentProcessor {
        emit RetrievedPrincipal(_investmentPoolFactoryAddress, _investmentPoolAddress, _investmentIndex, _amount);
    }

    function emitRetrievedAffiliateRewardsEvent(address _investmentPoolFactoryAddress, address _investmentPoolAddress, uint256 _investmentIndex, uint256 _amount) public onlyPaymentProcessor {
        emit RetrievedAffiliateRewards(_investmentPoolFactoryAddress, _investmentPoolAddress, _investmentIndex, _amount);
    }    

    function emitBuyTokensEvent(address _senderAddress, uint256 _amountIn, uint256 _amountOut) public onlyPaymentProcessor {
        emit BuyTokens(_senderAddress, _amountIn, _amountOut);
    }

    function emitInvestmentTransfer(address _investmentPoolAddress, uint256 _investmentIndex, address _newAddress) public onlyPaymentProcessor {
        emit InvestmentTransfer(msg.sender, _investmentPoolAddress, _investmentIndex, _newAddress);
    }

    function schedulePayment(address _tokenContractAddress, address _fromAddress, address _toAddress, uint256 _amount, uint256 _scheduledTimestamp) public onlyPaymentProcessor {
        ScheduledPayment memory payment = ScheduledPayment(
            _tokenContractAddress,
            _fromAddress,
            _toAddress,
            _amount,
            _scheduledTimestamp,
            false
        );
        scheduledPayments.push(payment);
    }

    function processScheduledPayment(uint256 _scheduledPaymentIndex) public {
        ScheduledPayment memory payment = scheduledPayments[_scheduledPaymentIndex];
        require((payment.completed == false && payment.scheduledTimestamp < block.timestamp),"Cannot process scheduled payment");
        require (IERC20(payment.tokenContractAddress).transferFrom(payment.fromAddress, payment.toAddress, payment.amount),"Cannot process payment");
        payment.completed = true;
        scheduledPayments[_scheduledPaymentIndex] = payment;
    }

    function processPayment(address _tokenAddress, address _fromAddress, address _toAddress, uint256 _amount) public onlyPaymentProcessor returns (bool) {
        return IERC20(_tokenAddress).transferFrom(_fromAddress, _toAddress, _amount);
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
uint256 constant BASIS_POINT = 10000;
uint256 constant MILI_BASIS_POINT = 10000000;
uint256 constant WEI_IN_ETHER = 1000000000000000000;
uint256 constant SECONDS_IN_YEAR = 60 * 60 * 24 * 365;
uint256 constant MAX_INT = 2**256 - 1;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Constants.sol";

interface QuickswapInterface {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract ExchangeRateProxy is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public fixedExchangeRate;
    address public quickswapRouterAddress;
    address[] public quickswapPaths;
    uint256 constant quoteTokenUnit = 1000000;
    uint256 constant baseTokenUnit = 1000000000000000000;

    function initialize(uint256 _fixedExchangeRate, address _quickswapRouterAddress, address[] memory _quickswapPaths) public initializer {           
        __Ownable_init_unchained();
        fixedExchangeRate = _fixedExchangeRate;
        quickswapRouterAddress = _quickswapRouterAddress;
        quickswapPaths = _quickswapPaths;             
    }

    function currentExchangeRate() internal view returns (uint256) {
        if (fixedExchangeRate != 0) {
            return fixedExchangeRate;
        }
        return QuickswapInterface(quickswapRouterAddress).getAmountsOut(1, quickswapPaths)[1];
    }
    
    function configureQuickswap(uint256 _fixedExchangeRate, address _quickswapRouterAddress, address[] memory _quickswapPaths) external onlyOwner {
        fixedExchangeRate = _fixedExchangeRate;
        quickswapRouterAddress = _quickswapRouterAddress;
        quickswapPaths = _quickswapPaths;        
    }    

    function getExchangeRate() public view returns (uint256 _exchangeRate) {
        return currentExchangeRate();
    }

    function getAmountsOut(uint256 _amountIn) public view returns (uint256 _amountOut) {
        if (fixedExchangeRate != 0) {
            return _amountIn.mul(fixedExchangeRate).div(WEI_IN_ETHER);
        }
        return QuickswapInterface(quickswapRouterAddress).getAmountsOut(_amountIn, quickswapPaths)[1];
    }

    function getAmountsOutSingleUnitPrice(uint256 _amountIn) public view returns (uint256 _amountOut) {
        if (fixedExchangeRate != 0) {
            return _amountIn.mul(fixedExchangeRate).div(WEI_IN_ETHER);
        }
        
        uint256 outputForUnit = QuickswapInterface(quickswapRouterAddress).getAmountsOut(quoteTokenUnit, quickswapPaths)[1];
        uint256 unitsPurchased = _amountIn.div(quoteTokenUnit);

        return outputForUnit.mul(unitsPurchased);
    }    

    function getAmountsInSingleUnitPrice(uint256 _amountOut) public view returns (uint256 _amountIn) {
        if (fixedExchangeRate != 0) {
            return _amountOut.mul(WEI_IN_ETHER).div(fixedExchangeRate);
        }        
        uint256 outputForUnit = QuickswapInterface(quickswapRouterAddress).getAmountsIn(baseTokenUnit, quickswapPaths)[0];
        uint256 unitsPurchased = _amountOut.div(baseTokenUnit);

        return outputForUnit.mul(unitsPurchased);
    }        

    function getAmountsIn(uint256 _amountOut) public view returns (uint256 _amountIn) {
        if (fixedExchangeRate != 0) {
            return _amountOut.mul(WEI_IN_ETHER).div(fixedExchangeRate);
        }        
        return QuickswapInterface(quickswapRouterAddress).getAmountsIn(_amountOut, quickswapPaths)[0];        
    }    

    function instantSwapTokens(uint256 _amountIn) public returns (uint[] memory amounts) {
        return QuickswapInterface(quickswapRouterAddress).swapExactTokensForTokens(_amountIn, getAmountsOut(_amountIn), quickswapPaths, msg.sender, block.timestamp);
    }

    function getQuickswapRouterAddress() public view returns (address _quickswapRouterAddress) {
        return quickswapRouterAddress;
    }

    function getQuickswapPathsLength() public view returns(uint count) {
       return quickswapPaths.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ExchangeRateProxyInterface {
    function getAmountsOut(uint256 _amountIn) external view returns (uint256 _amountOut);
    function getAmountsIn(uint256 _amountOut) external view returns (uint256 _amountIn);
    function getExchangeRate() external view returns (uint256 _exchangeRate);

    function getQuickswapRouterAddress() external returns (address _quickswapRouterAddress);
    function instantSwapTokens(uint256 _amountIn) external returns (uint[] memory _amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract InvestmentBlacklist is OwnableUpgradeable {
    mapping (address => bool) public blacklist;
    address public blacklistManager;

    event InvestorBlacklisted(
        address indexed investorAddress,
        bool blacklisted
    );

    modifier onlyBlacklistManager() {
        require(
            blacklistManager == msg.sender,
            "Only the blacklist manager can call this function"
        );
        _;
    }

    function initialize(address _blacklistManager) public initializer {
        __Ownable_init_unchained();
        blacklistManager = _blacklistManager;        
    }    

    function setBlacklist(address _investorAddress, bool _blacklisted) onlyBlacklistManager external {
        require(_investorAddress != address(0), "Investor address cannot be null");
        blacklist[_investorAddress] = _blacklisted;
        emit InvestorBlacklisted(_investorAddress, _blacklisted);
    }

    function setBlacklistList(address[] memory _investorAddresses, bool _blacklisted) onlyBlacklistManager external {
        for (uint i=0; i < _investorAddresses.length; i++) {
            require(_investorAddresses[i] != address(0), "Address is null");
            blacklist[_investorAddresses[i]] = _blacklisted;
            emit InvestorBlacklisted(_investorAddresses[i], _blacklisted);
        }
    }    

    function setBlacklistManager(address _blacklistManager) onlyOwner external {
        blacklistManager = _blacklistManager;
    }

    function isBlacklisted(address _investorAddress) public view returns (bool _blacklisted) {
        return blacklist[_investorAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract InvestmentReferral is OwnableUpgradeable {
    mapping (address => address) public referrals;
    address public referralManager;

    event ReferralCreated(
        address indexed childAddress,
        address indexed parentAddress
    );

    modifier onlyReferralManager() {
        require(
            referralManager == msg.sender,
            "Only the referral manager can call this function"
        );
        _;
    }

    function initialize(address _referralManager) public initializer {
        __Ownable_init_unchained();
        referralManager = _referralManager;        
    }    

    function setReferral(address _childAddress, address _parentAddress) onlyReferralManager external {
        require(_childAddress != address(0) && 
                _parentAddress != address(0),
                "Child or parent address is null"
        );
        referrals[_childAddress] = _parentAddress;
        emit ReferralCreated(_childAddress, _parentAddress);
    }

    function setReferralList(address[] memory _childAddresses, address _parentAddress) onlyReferralManager external {
        require(_parentAddress != address(0), "Parent address is null");
        for (uint i=0; i < _childAddresses.length; i++) {
            require(_childAddresses[i] != address(0), "Child address is null");
            referrals[_childAddresses[i]] = _parentAddress;
            emit ReferralCreated(_childAddresses[i], _parentAddress);
        }
    }    

    function setReferralManager(address _referralManager) onlyOwner external {
        referralManager = _referralManager;
    }

    function getReferral(address _childAddress) public view returns (address parentAddress) {
        return referrals[_childAddress];
    }
}