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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
pragma solidity ^0.8.16;

import {AccountMessages} from "../message.sol";

interface IAccountsCreateEndowment {
    function createEndowment(
        AccountMessages.CreateEndowmentRequest memory curDetails
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {Validator} from "../lib/validator.sol";
import {AccountStorage} from "../storage.sol";
import {AccountMessages} from "../message.sol";
import {RegistrarStorage} from "../../registrar/storage.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {IRegistrar} from "../../registrar/interface/IRegistrar.sol";
import {IAxelarGateway} from "./../interface/IAxelarGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IAccountsDepositWithdrawEndowments {
    function depositDonationMatchErC20(
        uint256 curId,
        address curToken,
        uint256 curAmount
    ) external;

    function depositEth(
        AccountMessages.DepositRequest memory curDetails
    ) external payable;

    //Pending
    function depositERC20(
        AccountMessages.DepositRequest memory curDetails,
        address curTokenaddress,
        uint256 curAmount
    ) external;

    function withdraw(
        uint256 curId,
        AngelCoreStruct.AccountType acctType,
        address curBeneficiary,
        address[] memory curTokenaddress,
        uint256[] memory curAmount
    ) external;

    function harvest(address vaultAddr) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountMessages} from "../message.sol";
import {AccountStorage} from "../storage.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface IAccountsQuery {
    function queryTokenAmount(
        uint256 curId,
        AngelCoreStruct.AccountType curAccountType,
        address curTokenaddress
    ) external view returns (uint256 tokenAmount);

    function queryEndowmentDetails(
        uint256 curId
    ) external view returns (AccountStorage.Endowment memory endowment);

    function queryConfig()
        external
        view
        returns (AccountMessages.ConfigResponse memory config);

    function queryState(
        uint256 curId
    )
        external
        view
        returns (AccountMessages.StateResponse memory stateResponse);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    struct VaultActionData {
        bytes4 strategyId;
        bytes4 selector;
        uint32[] accountIds;
        address token;
        uint256 lockAmt;
        uint256 liqAmt;
    }

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(
        string memory symbol
    ) external view returns (uint256);

    function tokenMintAmount(
        string memory symbol
    ) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(
        string memory symbol
    ) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(
        string[] calldata symbols,
        uint256[] calldata limits
    ) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;

    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountStorage} from "../storage.sol";

library LibAccounts {
    bytes32 constant AP_ACCOUNTS_DIAMOND_STORAGE_POSITION =
        keccak256("accounts.diamond.storage");

    function diamondStorage()
        internal
        pure
        returns (AccountStorage.State storage ds)
    {
        bytes32 position = AP_ACCOUNTS_DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library Validator {

    function addressChecker(address curAddr1) internal pure returns(bool){
        if(curAddr1 == address(0)){
            return false;
        }
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library AccountMessages {
    struct CreateEndowmentRequest {
        address owner; // address that originally setup the endowment account
        bool withdrawBeforeMaturity; // endowment allowed to withdraw funds from locked acct before maturity date
        uint256 maturityTime; // datetime int of endowment maturity
        uint256 maturityHeight; // block equiv of the maturity_datetime
        string name; // name of the Endowment
        AngelCoreStruct.Categories categories; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP CW3 Multisig can set/update)
        uint256 tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP CW3 Multisig can set/update)
        AngelCoreStruct.EndowmentType endow_type;
        string logo;
        string image;
        // AngelCoreStruct.Member[] cw4_members;
        address[] cw4_members;
        bool kycDonorsOnly;
        AngelCoreStruct.Threshold cw3Threshold;
        AngelCoreStruct.Duration cw3MaxVotingPeriod;
        address[] whitelistedBeneficiaries;
        address[] whitelistedContributors;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        AngelCoreStruct.EndowmentFee earningsFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee aumFee;
        AngelCoreStruct.DaoSetup dao;
        bool createDao;
        uint256 proposalLink;
        AngelCoreStruct.SettingsController settingsController;
        uint256 parent;
        address[] maturityWhitelist;
        bool ignoreUserSplits;
        AngelCoreStruct.SplitDetails splitToLiquid;
    }

    struct UpdateEndowmentSettingsRequest {
        uint256 id;
        bool donationMatchActive;
        address[] whitelistedBeneficiaries;
        address[] whitelistedContributors;
        address[] maturity_whitelist_add;
        address[] maturity_whitelist_remove;
        AngelCoreStruct.SplitDetails splitToLiquid;
        bool ignoreUserSplits;
    }
    struct UpdateEndowmentControllerRequest {
        uint256 id;
        AngelCoreStruct.SettingsPermission endowmentController;
        AngelCoreStruct.SettingsPermission name;
        AngelCoreStruct.SettingsPermission image;
        AngelCoreStruct.SettingsPermission logo;
        AngelCoreStruct.SettingsPermission categories;
        AngelCoreStruct.SettingsPermission kycDonorsOnly;
        AngelCoreStruct.SettingsPermission splitToLiquid;
        AngelCoreStruct.SettingsPermission ignoreUserSplits;
        AngelCoreStruct.SettingsPermission whitelistedBeneficiaries;
        AngelCoreStruct.SettingsPermission whitelistedContributors;
        AngelCoreStruct.SettingsPermission maturityWhitelist;
        AngelCoreStruct.SettingsPermission earningsFee;
        AngelCoreStruct.SettingsPermission depositFee;
        AngelCoreStruct.SettingsPermission withdrawFee;
        AngelCoreStruct.SettingsPermission aumFee;
    }

    struct UpdateEndowmentStatusRequest {
        uint256 endowmentId;
        uint256 status;
        AngelCoreStruct.Beneficiary beneficiary;
    }

    struct UpdateEndowmentDetailsRequest {
        uint256 id; /// u32,
        address owner; /// Option<String>,
        bool kycDonorsOnly; /// Option<bool>,
        AngelCoreStruct.EndowmentType endow_type; /// Option<String>,
        string name; /// Option<String>,
        AngelCoreStruct.Categories categories; /// Option<Categories>,
        uint256 tier; /// Option<u8>,
        string logo; /// Option<String>,
        string image; /// Option<String>,
        AngelCoreStruct.RebalanceDetails rebalance;
    }

    struct Strategy {
        string vault; // Vault SC Address
        uint256 percentage; // percentage of funds to invest
    }

    struct UpdateProfileRequest {
        uint256 id;
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        string facebook;
        string twitter;
        string linkedin;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///TODO: response struct should be below this

    struct ConfigResponse {
        address owner;
        string version;
        address registrarContract;
    }

    struct StateResponse {
        AngelCoreStruct.DonationsReceived donationsReceived;
        bool closingEndowment;
        AngelCoreStruct.Beneficiary closingBeneficiary;
    }

    struct EndowmentBalanceResponse {
        AngelCoreStruct.BalanceInfo tokensOnHand; //: BalanceInfo,
        address[] invested_locked_string; //: Vec<(String, Uint128)>,
        uint128[] invested_locked_amount;
        address[] invested_liquid_string; //: Vec<(String, Uint128)>,
        uint128[] invested_liquid_amount;
    }

    struct EndowmentEntry {
        uint256 id; // u32,
        address owner; // String,
        AngelCoreStruct.EndowmentStatus status; // EndowmentStatus,
        AngelCoreStruct.EndowmentType endow_type; // EndowmentType,
        string name; // Option<String>,
        string logo; // Option<String>,
        string image; // Option<String>,
        AngelCoreStruct.Tier tier; // Option<Tier>,
        AngelCoreStruct.Categories categories; // Categories,
        string proposalLink; // Option<u64>,
    }

    struct EndowmentListResponse {
        EndowmentEntry[] endowments;
    }

    struct ProfileResponse {
        string name; // String,
        string overview; // String,
        AngelCoreStruct.Categories categories; // Categories,
        uint256 tier; // Option<u8>,
        string logo; // Option<String>,
        string image; // Option<String>,
        string url; // Option<String>,
        string registrationNumber; // Option<String>,
        string countryOfOrigin; // Option<String>,
        string streetAddress; // Option<String>,
        string contactEmail; // Option<String>,
        AngelCoreStruct.SocialMedialUrls socialMediaUrls; // SocialMedialUrls,
        uint16 numberOfEmployees; // Option<u16>,
        string averageAnnualBudget; // Option<String>,
        string annualRevenue; // Option<String>,
        string charityNavigatorRating; // Option<String>,
    }

    struct EndowmentDetailsResponse {
        address owner; //: Addr,
        address dao;
        address daoToken;
        string description;
        AngelCoreStruct.AccountStrategies strategies;
        AngelCoreStruct.EndowmentStatus status;
        AngelCoreStruct.EndowmentType endow_type;
        uint256 maturityTime;
        AngelCoreStruct.OneOffVaults oneoffVaults;
        AngelCoreStruct.RebalanceDetails rebalance;
        address donationMatchContract;
        bool kycDonorsOnly;
        address[] maturityWhitelist;
        bool depositApproved;
        bool withdrawApproved;
        uint256 pendingRedemptions;
        string logo;
        string image;
        string name;
        AngelCoreStruct.Categories categories;
        uint256 tier;
        uint256 copycatStrategy;
        uint256 proposalLink;
        uint256 parent;
        AngelCoreStruct.SettingsController settingsController;
    }

    struct DepositRequest {
        uint256 id;
        uint256 lockedPercentage;
        uint256 liquidPercentage;
    }

    struct UpdateEndowmentFeeRequest {
        uint256 id;
        AngelCoreStruct.EndowmentFee earningsFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee aumFee;
    }

    enum DonationMatchEnum {
        HaloTokenReserve,
        Cw20TokenReserve
    }

    struct DonationMatchData {
        address reserveToken;
        address uniswapFactory;
        uint24 poolFee;
    }

    struct DonationMatch {
        DonationMatchEnum enumData;
        DonationMatchData data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library AccountStorage {
    struct Config {
        address owner;
        address registrarContract;
        uint256 nextAccountId;
        uint256 maxGeneralCategoryId;
    }

    struct Endowment {
        address owner;
        string name; // name of the Endowment
        AngelCoreStruct.Categories categories; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP CW3 Multisig can set/update)
        uint256 tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP CW3 Multisig can set/update)
        AngelCoreStruct.EndowmentType endow_type;
        string logo;
        string image;
        AngelCoreStruct.EndowmentStatus status;
        bool depositApproved; // approved to receive donations & transact
        bool withdrawApproved; // approved to withdraw funds
        uint256 maturityTime; // datetime int of endowment maturity
        //OG:AngelCoreStruct.AccountStrategies
        // uint256 strategies; // vaults and percentages for locked/liquid accounts donations where auto_invest == TRUE
        AngelCoreStruct.AccountStrategies strategies;
        AngelCoreStruct.OneOffVaults oneoffVaults; // vaults not covered in account startegies (more efficient tracking of vaults vs. looking up allll vaults)
        AngelCoreStruct.RebalanceDetails rebalance; // parameters to guide rebalancing & harvesting of gains from locked/liquid accounts
        bool kycDonorsOnly; // allow owner to state a preference for receiving only kyc'd donations (where possible) //TODO:
        uint256 pendingRedemptions; // number of vault redemptions currently pending for this endowment
        uint256 copycatStrategy; // endowment ID to copy their strategy
        uint256 proposalLink; // link back the CW3 Proposal that created an endowment
        address dao;
        address daoToken;
        bool donationMatchActive; //TODO: check this de we need to do this
        address donationMatchContract;
        address[] whitelistedBeneficiaries;
        address[] whitelistedContributors;
        address[] maturityWhitelist;
        AngelCoreStruct.EndowmentFee earningsFee; //TODO: we can remove all this
        AngelCoreStruct.EndowmentFee withdrawFee; //TODO: we can remove all this
        AngelCoreStruct.EndowmentFee depositFee; //TODO: we can remove all this
        AngelCoreStruct.EndowmentFee aumFee; //TODO: we can remove all this
        AngelCoreStruct.SettingsController settingsController; //TODO: we can remove all this
        uint256 parent; //TODO: not using this one also
        bool ignoreUserSplits;
        AngelCoreStruct.SplitDetails splitToLiquid;
    }

    ///TODO: Have changed name from state to endowmentState to manage solidity code
    struct EndowmentState {
        AngelCoreStruct.DonationsReceived donationsReceived;
        AngelCoreStruct.BalanceInfo balances;
        bool closingEndowment;
        AngelCoreStruct.Beneficiary closingBeneficiary;
    }

    struct AllowanceData {
        uint256 height;
        uint256 timestamp;
        bool expires;
        uint256 allowanceAmount;
        bool configured;
    }

    struct State {
        mapping(uint256 => uint256) DAOTOKENBALANCE;
        mapping(uint256 => EndowmentState) STATES;
        mapping(uint256 => Endowment) ENDOWMENTS;
        mapping(uint256 => AngelCoreStruct.Profile) PROFILES;
        //owner -> spender -> token -> Allowance Struct
        mapping(address => mapping(address => mapping(address => AllowanceData))) ALLOWANCES;
        Config config;
        address subDao;
        address gateway;
        address gasRevicer;
        bool reentrancyGuardLocked;
        //1 => Locked => GOLDFINCH => 10000
        //endowmentId => accountType => vault => balance
        mapping(bytes4 => string) stratagyId;

        mapping(uint256 => mapping(AngelCoreStruct.AccountType => mapping(string => uint256))) vaultBalance;
    }
}

contract Storage {
    AccountStorage.State state;
}

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.16;
// import {RegistrarStorage} from "../storage.sol";
// import {RegistrarMessages} from "../message.sol";
// import {AngelCoreStruct} from "../../struct.sol";

// interface IRegistrar {
//     function queryConfig()
//         external
//         view
//         returns (RegistrarStorage.Config memory);

//     function queryNetworkConnection(
//         uint256 chainId
//     ) external view returns (AngelCoreStruct.NetworkInfo memory);

//     function queryVaultDetails(
//         address vaultAddr
//     ) external view returns (AngelCoreStruct.YieldVault memory);

//     function queryVaultList(
//         uint256 network,
//         AngelCoreStruct.EndowmentType endowmentType,
//         AngelCoreStruct.AccountType accountType,
//         AngelCoreStruct.VaultType vaultType,
//         AngelCoreStruct.BoolOptional approved,
//         uint256 startAfter,
//         uint256 limit
//     ) external view returns (AngelCoreStruct.YieldVault[] memory);

//     function updateConfig(
//         RegistrarMessages.UpdateConfigRequest memory curDetails
//     ) external returns (bool);

//     function updateNetworkConnections(
//         AngelCoreStruct.NetworkInfo memory networkInfo,
//         string memory action
//     ) external returns (bool);

//     function updateOwner(address newOwner) external returns (bool);

//     function vaultAdd(
//         RegistrarMessages.VaultAddRequest memory curDetails
//     ) external returns (bool);

//     function vaultRemove(address vaultAddr) external returns (bool);

//     function vaultUpdate(
//         address vaultAddr,
//         bool approved,
//         AngelCoreStruct.EndowmentType[] memory restrictedFrom
//     ) external returns (bool);

//     function queryFee(string memory name) external returns (uint256);

//     function testQuery() external view returns (address[] memory);

//     function testQueryStruct()
//         external
//         view
//         returns (AngelCoreStruct.YieldVault[] memory);

//     function queryVaultListBg(
//         uint256 network,
//         AngelCoreStruct.EndowmentType endowmentType,
//         AngelCoreStruct.AccountType accountType,
//         AngelCoreStruct.VaultType vaultType,
//         AngelCoreStruct.BoolOptional approved,
//         uint256 startAfter,
//         uint256 limit
//     ) external view returns (AngelCoreStruct.YieldVault[] memory);
// }

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";

interface IRegistrar {
    function updateConfig(
        RegistrarMessages.UpdateConfigRequest memory curDetails
    ) external;

    function updateOwner(address newOwner) external;

    function updateFees(
        RegistrarMessages.UpdateFeeRequest memory curDetails
    ) external;

    function vaultAdd(
        RegistrarMessages.VaultAddRequest memory curDetails
    ) external;

    function vaultRemove(string memory _stratagyName) external;

    function vaultUpdate(
        string memory _stratagyName,
        bool curApproved,
        AngelCoreStruct.EndowmentType[] memory curRestrictedfrom
    ) external;

    function updateNetworkConnections(
        AngelCoreStruct.NetworkInfo memory networkInfo,
        string memory action
    ) external;

    // Query functions for contract

    function queryConfig()
        external
        view
        returns (RegistrarStorage.Config memory);

    function testQuery() external view returns (string[] memory);

    function testQueryStruct()
        external
        view
        returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultListDep(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) external view returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultList(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) external view returns (AngelCoreStruct.YieldVault[] memory);

    function queryVaultDetails(
        string memory _stratagyName
    ) external view returns (AngelCoreStruct.YieldVault memory response);

    function queryNetworkConnection(
        uint256 chainId
    ) external view returns (AngelCoreStruct.NetworkInfo memory response);

    function queryFee(
        string memory name
    ) external view returns (uint256 response);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
    struct InstantiateRequest {
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        AngelCoreStruct.SplitDetails splitToLiquid;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address router;
        address axelerGateway;
    }

    struct UpdateConfigRequest {
        address accountsContract;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        string[] approved_charities;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        uint256 collectorShare;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        // WASM CODES -> EVM -> Solidity Implementation contract addresses
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov token (basic CW20) wasm code
        address subdaoBondingTokenCode; // subdao gov token (w/ bonding-curve) wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        // CONTRACT ADSRESSES
        address indexFundContract;
        address govContract;
        address treasury;
        address donationMatchCharitesContract;
        address donationMatchEmitter;
        address haloToken;
        address haloTokenLpContract;
        address charitySharesContract;
        address fundraisingContract;
        address applicationsReview;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct VaultAddRequest {
        // chainid of network
        uint256 network;
        string stratagyName;
        address inputDenom;
        address yieldToken;
        AngelCoreStruct.EndowmentType[] restrictedFrom;
        AngelCoreStruct.AccountType acctType;
        AngelCoreStruct.VaultType vaultType;
    }

    struct UpdateFeeRequest {
        string[] keys;
        // TODO Change to decimal
        uint256[] values;
    }

    struct ConfigResponse {
        address owner;
        uint256 version;
        address accountsContract;
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        address indexFund;
        AngelCoreStruct.SplitDetails splitToLiquid;
        address haloToken;
        address govContract;
        address charitySharesContract;
        uint256 cw3Code;
        uint256 cw4Code;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address applicationsReview;
        address swapsRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
    struct Config {
        address owner; // AP TEAM MULTISIG
        //Application review multisig
        address applicationsReview; // Endowment application review team's CW3 (set as owner to start). Owner can set and change/revoke.
        address indexFundContract;
        address accountsContract;
        address treasury;
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov cw20 token wasm code
        address subdaoBondingTokenCode; // subdao gov bonding curve token wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
        address donationMatchEmitter;
        AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
        //TODO: pending check
        address haloToken; // TerraSwap HALO token addr
        address haloTokenLpContract;
        address govContract; // AP governance contract
        address collectorAddr; // Collector address for new fee
        uint256 collectorShare;
        address charitySharesContract;
        AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
        //PROTOCOL LEVEL
        address fundraisingContract;
        AngelCoreStruct.RebalanceDetails rebalance;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct State {
        Config config;
        mapping(string => AngelCoreStruct.YieldVault) VAULTS;
        string[] VAULT_POINTERS;
        mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
        mapping(string => uint256) FEES;
    }
}

contract Storage {
    RegistrarStorage.State state;
    bool initilized = false;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
    enum AccountType {
        Locked,
        Liquid,
        None
    }

    enum Tier {
        None,
        Level1,
        Level2,
        Level3
    }

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    ///TODO: by default are not internal need to create a custom internal function for this refer :- https://ethereum.stackexchange.com/questions/21155/how-to-expose-enum-in-solidity-contract
    enum EndowmentType {
        Charity,
        Normal,
        None
    }

    enum EndowmentStatus {
        Inactive,
        Approved,
        Frozen,
        Closed
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage curAvailible,
        uint256[] storage cerAvailibleAmount, 
        string memory curToken
    ) public {
        bool check = true;
        for (uint8 j = 0; j < curAvailible.length; j++) {
            if (
                keccak256(abi.encodePacked(curAvailible[j])) ==
                keccak256(abi.encodePacked(curToken))
            ) {
                check = false;
            }
        }
        if (check) {
            curAvailible.push(curToken);
            cerAvailibleAmount.push(0);
        }
    }

    struct RebalanceDetails {
        bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
        bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
        bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    }

    function rebalanceDetailsDefaut()
        public
        pure
        returns (RebalanceDetails memory)
    {
        RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
            rebalanceLiquidInvestedProfits: false,
            lockedInterestsToLiquid: false,
            interest_distribution: 20,
            lockedPrincipleToLiquid: false,
            principle_distribution: 0
        });

        return _tempRebalanceDetails;
    }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct Cw20CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        // Coin[] native;
        uint256[] Cw20CoinVerified_amount;
        address[] Cw20CoinVerified_addr;
        // Cw20CoinVerified[] cw20;
    }

    function addToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            curTemp.Cw20CoinVerified_addr.push(curTokenaddress);
            curTemp.Cw20CoinVerified_amount.push(curAmount);
        }
    }

    function addTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            GenericBalance memory new_temp = GenericBalance({
                coinNativeAmount: curTemp.coinNativeAmount,
                Cw20CoinVerified_amount: new uint256[](
                    curTemp.Cw20CoinVerified_amount.length + 1
                ),
                Cw20CoinVerified_addr: new address[](
                    curTemp.Cw20CoinVerified_addr.length + 1
                )
            });
            for (uint256 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
                new_temp.Cw20CoinVerified_addr[i] = curTemp
                    .Cw20CoinVerified_addr[i];
                new_temp.Cw20CoinVerified_amount[i] = curTemp
                    .Cw20CoinVerified_amount[i];
            }
            new_temp.Cw20CoinVerified_addr[
                curTemp.Cw20CoinVerified_addr.length
            ] = curTokenaddress;
            new_temp.Cw20CoinVerified_amount[
                curTemp.Cw20CoinVerified_amount.length
            ] = curAmount;
            return new_temp;
        } else return curTemp;
    }

    function subToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
    }

    function subTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
        return curTemp;
    }

    function splitBalance(
        uint256[] storage cw20Coin,
        uint256 splitFactor
    ) public view returns (uint256[] memory) {
        uint256[] memory curTemp = new uint256[](cw20Coin.length);
        for (uint8 i = 0; i < cw20Coin.length; i++) {
            uint256 result = SafeMath.div(cw20Coin[i], splitFactor);
            curTemp[i] = result;
        }

        return curTemp;
    }

    function receiveGenericBalance(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] storage curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] memory curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function deductTokens(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curDeducttokenfor,
        uint256 curDeductamount
    ) public pure returns (uint256[] memory) {
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curDeducttokenfor) {
                require(curAmount[i] > curDeductamount, "Insufficient Funds");
                curAmount[i] -= curDeductamount;
            }
        }

        return curAmount;
    }

    function getTokenAmount(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curTokenaddress
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curTokenaddress) {
                amount = curAmount[i];
            }
        }

        return amount;
    }

    struct AllianceMember {
        string name;
        string logo;
        string website;
    }

    function genericBalanceDefault()
        public
        pure
        returns (GenericBalance memory)
    {
        GenericBalance memory empty;
        return empty;
    }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint256 id;
    }

    struct IndexFund {
        uint256 id;
        string name;
        string description;
        uint256[] members;
        bool rotatingFund; // set a fund as a rotating fund
        //Fund Specific: over-riding SC level setting to handle a fixed split value
        // Defines the % to split off into liquid account, and if defined overrides all other splits
        uint256 splitToLiquid;
        // Used for one-off funds that have an end date (ex. disaster recovery funds)
        uint256 expiryTime; // datetime int of index fund expiry
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
    }

    struct BeneficiaryData {
        uint256 id;
        address addr;
    }

    enum BeneficiaryEnum {
        EndowmentId,
        IndexFund,
        Wallet,
        None
    }

    struct Beneficiary {
        BeneficiaryData data;
        BeneficiaryEnum enumData;
    }

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory curTemp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({id: 0, addr: address(0)})
        });

        return curTemp;
    }

    struct SocialMedialUrls {
        string facebook;
        string twitter;
        string linkedin;
    }

    struct Profile {
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        SocialMedialUrls socialMediaUrls;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///CHanges made for registrar contract

    struct SplitDetails {
        uint256 max;
        uint256 min;
        uint256 defaultSplit; // for when a split parameter is not provided
    }

    function checkSplits(
        SplitDetails memory registrarSplits,
        uint256 userLocked,
        uint256 userLiquid,
        bool userOverride
    ) public pure returns (uint256, uint256) {
        // check that the split provided by a non-TCA address meets the default
        // requirements for splits that is set in the Registrar contract
        if (
            userLiquid > registrarSplits.max ||
            userLiquid < registrarSplits.min ||
            userOverride == true
        ) {
            return (
                100 - registrarSplits.defaultSplit,
                registrarSplits.defaultSplit
            );
        } else {
            return (userLocked, userLiquid);
        }
    }

    struct AcceptedTokens {
        address[] cw20;
    }

    function cw20Valid(
        address[] memory cw20,
        address token
    ) public pure returns (bool) {
        bool check = false;
        for (uint8 i = 0; i < cw20.length; i++) {
            if (cw20[i] == token) {
                check = true;
            }
        }

        return check;
    }

    struct NetworkInfo {
        string name;
        uint256 chainId;
        address router;
        address axelerGateway;
        string ibcChannel; // Should be removed
        string transferChannel;
        address gasReceiver; // Should be removed
        uint256 gasLimit; // Should be used to set gas limit
    }

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    struct YieldVault {
        string addr; // vault's contract address on chain where the Registrar lives/??
        uint256 network; // Points to key in NetworkConnections storage map
        address inputDenom; //?
        address yieldToken; //?
        bool approved;
        EndowmentType[] restrictedFrom;
        AccountType acctType;
        VaultType vaultType;
    }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct ThresholdData {
        uint256 weight;
        uint256 percentage;
        uint256 threshold;
        uint256 quorum;
    }
    enum ThresholdEnum {
        AbsoluteCount,
        AbsolutePercentage,
        ThresholdQuorum
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    //TODO: remove if not needed
    // function durationAfter(Duration memory data)
    //     public
    //     view
    //     returns (Expiration memory)
    // {
    //     if (data.enumData == DurationEnum.Height) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atHeight,
    //                 data: ExpirationData({
    //                     height: block.number + data.data.height,
    //                     time: 0
    //                 })
    //             });
    //     } else if (data.enumData == DurationEnum.Time) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atTime,
    //                 data: ExpirationData({
    //                     height: 0,
    //                     time: block.timestamp + data.data.time
    //                 })
    //             });
    //     } else {
    //         revert("Duration not configured");
    //     }
    // }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
    }

    struct Threshold {
        ThresholdEnum enumData;
        ThresholdData data;
    }

    enum CurveTypeEnum {
        Constant,
        Linear,
        SquarRoot
    }

    //TODO: remove if unused
    // function getReserveRatio(CurveTypeEnum curCurveType)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     if (curCurveType == CurveTypeEnum.Linear) {
    //         return 500000;
    //     } else if (curCurveType == CurveTypeEnum.SquarRoot) {
    //         return 660000;
    //     } else {
    //         return 1000000;
    //     }
    // }

    struct CurveTypeData {
        uint128 value;
        uint256 scale;
        uint128 slope;
        uint128 power;
    }

    struct CurveType {
        CurveTypeEnum curve_type;
        CurveTypeData data;
    }

    enum TokenType {
        ExistingCw20,
        NewCw20,
        BondingCurve
    }

    struct DaoTokenData {
        address existingCw20Data;
        uint256 newCw20InitialSupply;
        string newCw20Name;
        string newCw20Symbol;
        CurveType bondingCurveCurveType;
        string bondingCurveName;
        string bondingCurveSymbol;
        uint256 bondingCurveDecimals;
        address bondingCurveReserveDenom;
        uint256 bondingCurveReserveDecimals;
        uint256 bondingCurveUnbondingPeriod;
    }

    struct DaoToken {
        TokenType token;
        DaoTokenData data;
    }

    struct DaoSetup {
        uint256 quorum; //: Decimal,
        uint256 threshold; //: Decimal,
        uint256 votingPeriod; //: u64,
        uint256 timelockPeriod; //: u64,
        uint256 expirationPeriod; //: u64,
        uint128 proposalDeposit; //: Uint128,
        uint256 snapshotPeriod; //: u64,
        DaoToken token; //: DaoToken,
    }

    struct Delegate {
        address Addr;
        uint256 expires; // datetime int of delegation expiry
    }

    function canTakeAction(
        Delegate storage self,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        if (
            sender == self.Addr &&
            (self.expires == 0 || envTime <= self.expires)
        ) {
            return true;
        } else {
            return false;
        }
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 feePercentage;
        bool active;
    }

    struct SettingsPermission {
        bool ownerControlled;
        bool govControlled;
        bool modifiableAfterInit;
        Delegate delegate;
    }

    function setDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        address delegateAddr,
        uint256 delegateExpiry
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov)
        ) {
            self.delegate = Delegate({
                Addr: delegateAddr,
                expires: delegateExpiry
            });
        }
    }

    function revokeDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            self.delegate = Delegate({Addr: address(0), expires: 0});
        }
    }

    function canChange(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public view returns (bool) {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            return self.modifiableAfterInit;
        }
        return false;
    }

    struct SettingsController {
        SettingsPermission endowmentController;
        SettingsPermission strategies;
        SettingsPermission whitelistedBeneficiaries;
        SettingsPermission whitelistedContributors;
        SettingsPermission maturityWhitelist;
        SettingsPermission maturityTime;
        SettingsPermission profile;
        SettingsPermission earningsFee;
        SettingsPermission withdrawFee;
        SettingsPermission depositFee;
        SettingsPermission aumFee;
        SettingsPermission kycDonorsOnly;
        SettingsPermission name;
        SettingsPermission image;
        SettingsPermission logo;
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    function getPermissions(
        SettingsController storage _tempObject,
        string memory name
    ) public view returns (SettingsPermission storage) {
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("endowmentController"))
        ) {
            return _tempObject.endowmentController;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityWhitelist"))
        ) {
            return _tempObject.maturityWhitelist;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("splitToLiquid"))
        ) {
            return _tempObject.splitToLiquid;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("ignoreUserSplits"))
        ) {
            return _tempObject.ignoreUserSplits;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("strategies"))
        ) {
            return _tempObject.strategies;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedBeneficiaries"))
        ) {
            return _tempObject.whitelistedBeneficiaries;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedContributors"))
        ) {
            return _tempObject.whitelistedContributors;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityTime"))
        ) {
            return _tempObject.maturityTime;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("profile"))
        ) {
            return _tempObject.profile;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("earningsFee"))
        ) {
            return _tempObject.earningsFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("withdrawFee"))
        ) {
            return _tempObject.withdrawFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("depositFee"))
        ) {
            return _tempObject.depositFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("aumFee"))
        ) {
            return _tempObject.aumFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("kycDonorsOnly"))
        ) {
            return _tempObject.kycDonorsOnly;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("name"))
        ) {
            return _tempObject.name;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("image"))
        ) {
            return _tempObject.image;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("logo"))
        ) {
            return _tempObject.logo;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("categories"))
        ) {
            return _tempObject.categories;
        } else {
            revert("InvalidInputs");
        }
    }

    // None at the start as pending starts at 1 in ap rust contracts (in cw3 core)
    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./storage.sol";
import {ICharityApplication} from "./interface/ICharityApplication.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AngelCoreStruct} from "../../core/struct.sol";
import {IAccountsCreateEndowment} from "../../core/accounts/interface/IAccountsCreateEndowment.sol";
import {IAccountsQuery} from "../../core/accounts/interface/IAccountsQuery.sol";
import {IAccountsDepositWithdrawEndowments} from "../../core/accounts/interface/IAccountsDepositWithdrawEndowments.sol";
import {AccountStorage} from "../../core/accounts/storage.sol";
import {AccountMessages} from "../../core/accounts/message.sol";

/**
 * @title IMultiSig
 * @dev Interface for MultiSig contract
 */
interface IMultiSig {
    function getOwners() external view returns (address[] memory);
}

library CharityApplicationLib {
    function proposeCharity(
        AccountMessages.CreateEndowmentRequest memory charityApplication,
        string memory meta,
        uint256 proposalCounter,
        mapping(uint256 => CharityApplicationsStorage.CharityApplicationProposal)
            storage proposals,
        CharityApplicationsStorage.Config storage config
    ) public {
        uint256 proposalId = proposalCounter;

        proposalCounter++;

        require(
            proposals[proposalId].status ==
                CharityApplicationsStorage.Status.None,
            "Already exists"
        );

        // charity check
        if (
            charityApplication.endow_type !=
            AngelCoreStruct.EndowmentType.Charity
        ) {
            revert("Unauthorized");
        }

        // set explicitly to 0 (None) regardless of what user passes
        charityApplication.maturityTime = 0;

        if (charityApplication.categories.sdgs.length == 0) {
            revert("Invalid UN SDG inputs given");
        }

        // check all sdgs id

        for (
            uint256 i = 0;
            i < charityApplication.categories.sdgs.length;
            i++
        ) {
            if (
                charityApplication.categories.sdgs[i] > 17 ||
                charityApplication.categories.sdgs[i] == 0
            ) {
                revert("Invalid UN SDG inputs given");
            }
        }

        proposals[proposalId] = CharityApplicationsStorage
            .CharityApplicationProposal({
                proposalId: proposalId,
                proposer: msg.sender,
                charityApplication: charityApplication,
                meta: meta,
                expiry: block.timestamp + config.proposalExpiry,
                status: CharityApplicationsStorage.Status.Pending
            });
    }
}

/**
 * @title CharityApplication
 * @notice Contract for managing charity applications, sent by public to open a charity endowment on AP
 * @dev Charity Applications have to be approved by AP Team multisig
 * @dev Contract for managing charity applications
 */
contract CharityApplication is
    CharityStorage,
    ICharityApplication,
    ERC165,
    ReentrancyGuard
{
    /*
     * Modifiers
     */
    modifier onlyApplicationsMultisig() {
        require(
            config.applicationMultisig == msg.sender,
            "Only Applications Team"
        );
        _;
    }

    // Check if proposal is not expired
    modifier notExpired(uint256 proposalId) {
        require(proposals[proposalId].expiry > block.timestamp, "is expired");
        _;
    }

    // Check if proposal is pending
    modifier isPending(uint256 proposalId) {
        require(
            proposals[proposalId].status ==
                CharityApplicationsStorage.Status.Pending,
            "not pending"
        );
        _;
    }

    // Check if proposal is approved
    modifier isApproved(uint256 proposalId) {
        require(
            proposals[proposalId].status ==
                CharityApplicationsStorage.Status.Approved,
            "not approved"
        );
        _;
    }

    /// @dev Receive function allows to deposit ether.
    receive() external payable override {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    /// @dev Fallback function allows to deposit ether.
    fallback() external payable override {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

    // seed asset will always be USDC
    bool initialized = false;

    /**
     * @notice Initialize the charity applications contract
     * where people can send applications to open a charity endowment on AP
     * @dev seed asset will always be USDC
     * @dev Initialize the contract
     * @param curExpiry Proposal expiry time in seconds
     * @param curApplicationmultisig AP Team multisig address
     * @param curAccountscontract Accounts contract address
     * @param curSeedsplittoliquid Seed split to liquid
     * @param curNewendowgasmoney New endow gas money
     * @param curGasamount Gas amount
     * @param curFundseedasset Fund seed asset
     * @param curSeedasset Seed asset
     * @param curSeedassetamount Seed asset amount
     */
    function initialize(
        uint256 curExpiry,
        address curApplicationmultisig,
        address curAccountscontract,
        uint256 curSeedsplittoliquid,
        bool curNewendowgasmoney,
        uint256 curGasamount,
        bool curFundseedasset,
        address curSeedasset,
        uint256 curSeedassetamount
    ) public {
        require(!initialized, "already initialized");
        initialized = true;
        proposalCounter = 1;
        config.applicationMultisig = curApplicationmultisig;
        config.accountsContract = curAccountscontract;
        config.seedSplitToLiquid = curSeedsplittoliquid;
        config.newEndowGasMoney = curNewendowgasmoney;
        config.gasAmount = curGasamount;
        config.fundSeedAsset = curFundseedasset;
        config.seedAsset = curSeedasset;
        config.seedAssetAmount = curSeedassetamount;
        if (curExpiry == 0)
            config.proposalExpiry = 4 * 24 * 60 * 60; // 4 days in seconds
        else config.proposalExpiry = curExpiry;

        emit InitilizedCharityApplication(config);
    }

    /**
     * @notice propose a charity to be opened on AP
     * @dev propose a charity to be opened on AP
     * @param charityApplication Charity application
     * @param meta Meta (URL of Metadata)
     */
    function proposeCharity(
        AccountMessages.CreateEndowmentRequest memory charityApplication,
        string memory meta
    ) public override nonReentrant {
        CharityApplicationLib.proposeCharity(
            charityApplication,
            meta,
            proposalCounter,
            proposals,
            config
        );
        proposalCounter++;
        emit CharityProposed(
            msg.sender,
            proposalCounter - 1,
            charityApplication,
            meta
        );
    }

    /**
     * @notice function called by AP Team to approve a charity application
     * @dev function called by AP Team to approve a charity application
     * @param proposalId id of the proposal to be approved
     */

    function approveCharity(
        uint256 proposalId
    )
        public
        override
        nonReentrant
        onlyApplicationsMultisig
        isPending(proposalId)
        notExpired(proposalId)
    {
        proposals[proposalId].status = CharityApplicationsStorage
            .Status
            .Approved;

        uint256 endowmentId = _executeCharity(proposalId);

        emit CharityApproved(proposalId, endowmentId);
    }

    /**
     * @notice function called by AP Team to reject a charity application
     * @dev function called by AP Team to reject a charity application
     * @param proposalId id of the proposal to be rejected
     */
    function rejectCharity(
        uint256 proposalId
    )
        public
        override
        nonReentrant
        onlyApplicationsMultisig
        isPending(proposalId)
        notExpired(proposalId)
    {
        proposals[proposalId].status = CharityApplicationsStorage
            .Status
            .Rejected;

        emit CharityRejected(proposalId);
    }

    // Internal function that executes create endowment request based on proposal data
    /**
     * @notice Internal function that executes create endowment request based on proposal data
     * @dev Internal function that executes create endowment request based on proposal data
     * @param proposalId id of the proposal to be executed
     */
    function _executeCharity(
        uint256 proposalId
    ) internal isApproved(proposalId) notExpired(proposalId) returns (uint256) {
        uint256 endowmentId = IAccountsCreateEndowment(config.accountsContract)
            .createEndowment(proposals[proposalId].charityApplication);

        if (config.newEndowGasMoney) {
            //query endowments from accounts contract and get the owner address
            AccountStorage.Endowment memory endowDetails = IAccountsQuery(
                config.accountsContract
            ).queryEndowmentDetails(endowmentId);

            // TODO: Test this in remix
            // query owner multisig to find the first signer
            address payable signer = payable(
                IMultiSig(endowDetails.owner).getOwners()[0]
            );

            require(signer != address(0), "SignNotSet");

            // check ethereum balance on this contract
            uint256 balance = address(this).balance;

            if (balance > config.gasAmount) {
                // transfer ether to them and emit gas fee event
                (bool success, ) = signer.call{value: config.gasAmount}(
                    "FailedGas"
                );

                if (!success) {
                    revert("FailedGas");
                }
            } else {
                revert("FailedGas");
            }
            emit GasSent(endowmentId, signer, config.gasAmount);
        }

        if (config.fundSeedAsset) {
            // check seed asset balance
            uint256 bal = IERC20(config.seedAsset).balanceOf(address(this));

            if (bal > config.seedAssetAmount) {
                // call deposit on accounts

                require(
                    IERC20(config.seedAsset).approve(
                        config.accountsContract,
                        config.seedAssetAmount
                    ),
                    "Approve failed"
                );

                IAccountsDepositWithdrawEndowments(config.accountsContract)
                    .depositERC20(
                        AccountMessages.DepositRequest({
                            id: endowmentId,
                            lockedPercentage: 100 - config.seedSplitToLiquid,
                            liquidPercentage: config.seedSplitToLiquid
                        }),
                        config.seedAsset,
                        config.seedAssetAmount
                    );
                // emit seed asset event
                emit SeedAssetSent(
                    endowmentId,
                    config.seedAsset,
                    config.seedAssetAmount
                );
            }
        }

        return endowmentId;
    }

    //update config function which updates config if the supplied input parameter is not null or 0
    /**
     * @notice update config function which updates config if the supplied input parameter is not null or 0
     * @dev update config function which updates config if the supplied input parameter is not null or 0
     * @param curExpiry expiry time for proposals
     * @param curApplicationmultisig address of AP Team multisig
     * @param curAccountscontract address of accounts contract
     * @param curSeedsplittoliquid percentage of seed asset to be sent to liquid
     * @param curNewendowgasmoney boolean to check if gas money is to be sent
     * @param curGasamount amount of gas to be sent
     * @param curFundseedasset boolean to check if seed asset is to be sent
     * @param curSeedasset address of seed asset
     * @param curSeedassetamount amount of seed asset to be sent
     */
    function updateConfig(
        uint256 curExpiry,
        address curApplicationmultisig,
        address curAccountscontract,
        uint256 curSeedsplittoliquid,
        bool curNewendowgasmoney,
        uint256 curGasamount,
        bool curFundseedasset,
        address curSeedasset,
        uint256 curSeedassetamount
    ) public override nonReentrant onlyApplicationsMultisig {
        if (curExpiry != 0) config.proposalExpiry = curExpiry;
        if (curApplicationmultisig != address(0))
            config.applicationMultisig = curApplicationmultisig;
        if (curAccountscontract != address(0))
            config.accountsContract = curAccountscontract;
        if (curSeedsplittoliquid != 0 && curSeedsplittoliquid <= 100)
            config.seedSplitToLiquid = curSeedsplittoliquid;
        if (
            curNewendowgasmoney ||
            (curNewendowgasmoney == false && config.newEndowGasMoney == true)
        ) config.newEndowGasMoney = curNewendowgasmoney;
        if (curGasamount != 0) config.gasAmount = curGasamount;
        if (curFundseedasset) config.fundSeedAsset = curFundseedasset;
        if (curSeedasset != address(0)) config.seedAsset = curSeedasset;
        if (curSeedassetamount != 0)
            config.seedAssetAmount = curSeedassetamount;
    }

    function queryConfig()
        public
        view
        returns (CharityApplicationsStorage.Config memory)
    {
        return config;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
// import {MultiSigStorage} from "../storage.sol";
import {AccountMessages} from "../../../core/accounts/message.sol";
import "./../storage.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract ICharityApplication is IERC165 {
    /*
     * Events
     */

    event InitilizedCharityApplication(
        CharityApplicationsStorage.Config updatedConfig
    );

    event CharityProposed(
        address indexed proposer,
        uint256 indexed proposalId,
        AccountMessages.CreateEndowmentRequest charityApplication,
        string meta
    );

    event CharityApproved(
        uint256 indexed proposalId,
        uint256 indexed endowmentId
    );

    event CharityRejected(uint256 indexed proposalId);

    event Deposit(address indexed sender, uint256 value);

    // event emitted when gas is sent to endowments first member
    event GasSent(
        uint256 indexed endowmentId,
        address indexed member,
        uint256 amount
    );

    // event emitted when seed funding is given to endowment
    event SeedAssetSent(
        uint256 indexed endowmentId,
        address indexed asset,
        uint256 amount
    );

    // For storing mattic to send gas fees
    /// @dev Receive function allows to deposit ether.
    receive() external payable virtual;

    // For storing mattic to send gas fees
    /// @dev Fallback function allows to deposit ether.
    fallback() external payable virtual;

    function proposeCharity(
        AccountMessages.CreateEndowmentRequest memory charityApplication,
        string memory meta
    ) public virtual;

    function approveCharity(uint256 proposalId) public virtual;

    function rejectCharity(uint256 proposalId) public virtual;

    function updateConfig(
        uint256 curExpiry,
        address curApteammultisig,
        address curAccountscontract,
        uint256 curSeedsplittoliquid,
        bool curNewendowgasmoney,
        uint256 curGasamount,
        bool curFundseedasset,
        address curSeedasset,
        uint256 curSeedassetamount
    ) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {AccountMessages} from "../../core/accounts/message.sol";

library CharityApplicationsStorage {
    enum Status {
        None,
        Pending,
        Approved,
        Rejected
    }

    struct CharityApplicationProposal {
        uint256 proposalId;
        address proposer;
        AccountMessages.CreateEndowmentRequest charityApplication;
        string meta;
        uint256 expiry;
        Status status;
    }

    struct Config {
        uint256 proposalExpiry;
        address applicationMultisig;
        address accountsContract;
        uint256 seedSplitToLiquid;
        bool newEndowGasMoney;
        uint256 gasAmount;
        bool fundSeedAsset;
        address seedAsset;
        uint256 seedAssetAmount;
    }
}

contract CharityStorage {
    /*
     *  Storage
     */
    mapping(uint256 => CharityApplicationsStorage.CharityApplicationProposal)
        public proposals;
    CharityApplicationsStorage.Config public config;
    uint256 proposalCounter;
}