// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity ^0.8.9;

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IFilmioProjectV1.sol";
import "./VariableDataV1.sol";

// SPDX-License-Identifier: MIT

contract FilmioProjectV1 is VariableDataV1, ERC2771Recipient, IFilmioProjectV1 {
    // lock the implementation contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initialisation section

    function initialize(address _trustedForwarder) public initializer {
        require(_trustedForwarder != address(0), "FilmioProjectV1: trustedForwarder address is zero");

        __Ownable_init();
        _setTrustedForwarder(_trustedForwarder);
        ratingId = 1;
        evaluationId = 1;
    }

    //for changing trustedForwarder address
    function setTruestedForwarder(address _trustedForwarder) public onlyOwner {
        require(_trustedForwarder != address(0), "FilmioProjectV1: trustedForwarder address is zero");
        _setTrustedForwarder(_trustedForwarder);

        emit TrustedForwarderModified(_trustedForwarder);
    }

    /**
     * @dev sets the question ids for a project evaluation
     *
     * @param projectId project Id.
     * @param questionIds questions Ids in the format "{id_1}-{id_2}-...-{id_n}" e.g. "5-232-12"
     *
     * Requirements:
     * - only owner can set questions.
     *
     * Emits a {evaluationQuestionsSet} event.
     */
    function setEvaluationQuestions(uint256 projectId, string memory questionIds) external onlyOwner {
        require(bytes(questionIds).length > 0, "FilmioProjectV1: questions are empty");

        projectEvaluationQuestions[projectId] = questionIds;

        emit EvaluationQuestionsSet(projectId, questionIds);
    }

    /**
     * @dev creates lock.
     *
     * @param projectId address.
     *
     * Requirements:
     * - only owner can create lock.
     *
     * Returns
     * - boolean.
     *
     * Emits a {lockCreated} event.
     */
    function createLock(uint256 projectId) external {
        require(
            projectLockDetails[projectId].projectId == 0 && projectId != 0,
            "Lock already created for this project"
        );

        LockDetails memory newLock = LockDetails(projectId, block.timestamp);
        projectLockDetails[projectId] = newLock;
        projects.push(projectId);

        emit LockCreated(projectId, _msgSender());
    }

    /**
     * @dev create update for a project.
     *
     * @param projectId project Id.
     * @param remark remark.
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - boolean.
     *
     * Emits a {updateCreated} event.
     */

    function createUpdate(uint256 projectId, string memory remark) external {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exists");

        Update memory newUpdate = Update(projectId, remark, block.timestamp);
        projectUpdateDetails[projectId].push(newUpdate);

        emit UpdateCreated(projectId, remark, _msgSender());
    }

    /**
     * @dev creates evaluation for a project.
     *
     * @param projectId project Id.
     * @param rating rating for all given questions
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - boolean.
     *
     * Emits a {evaluationCreated} event.
     */
    function createEvaluation(uint256 projectId, uint256 rating) external {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exists");

        require(projectEvaluation[projectId].account == address(0), "Project is already evaluated by user");

        require(strlen(projectEvaluationQuestions[projectId]) > 0, "Questions are not set for this project yet");

        require(
            validateEvaluationQuestions(projectEvaluationQuestions[projectId], rating),
            "Questions Ids and/or rating are not valid/compatible"
        );

        EvaluateDetails memory evaluation = EvaluateDetails(
            evaluationId,
            projectEvaluationQuestions[projectId],
            projectId,
            rating,
            _msgSender()
        );
        projectEvaluation[projectId] = evaluation;

        EvaluateDetails memory userEval = EvaluateDetails(
            evaluationId,
            projectEvaluationQuestions[projectId],
            projectId,
            rating,
            _msgSender()
        );

        userEvaluation[_msgSender()].push(userEval);

        evaluationIndicies[evaluationId] = userEvaluation[_msgSender()].length;

        evaluationId += 1;

        emit EvaluationCreated(
            evaluationId - 1,
            projectId,
            projectEvaluationQuestions[projectId],
            rating,
            _msgSender()
        );
    }

    /**
     * @dev modifies evaluation for a project.
     *
     * @param projectId project Id.
     * @param rating new rating for all given questions
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - boolean.
     *
     * Emits a {evaluationModified} event.
     */

    function modifyEvaluation(uint256 projectId, uint256 rating) external {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exist");

        require(projectEvaluation[projectId].rating != rating, "Provided rating is the same as previous");

        require(strlen(projectEvaluationQuestions[projectId]) > 0, "Questions are not set for this project yet");

        require(
            validateEvaluationQuestions(projectEvaluationQuestions[projectId], rating),
            "Questions Ids and/or rating are not valid/compatible"
        );

        uint256 _evaluationId = projectEvaluation[projectId].evaluationId;

        uint256 evaludationIndex = evaluationIndicies[_evaluationId];

        require(evaludationIndex > 0, "Evaluation does not exist");

        evaludationIndex -= 1;

        require(
            evaludationIndex < userEvaluation[_msgSender()].length,
            "Not allowed to modify this evaluation or evaluation does not exist"
        );

        require(
            userEvaluation[_msgSender()][evaludationIndex].projectId == projectId,
            "User is not allowed to modify this evaluation"
        );

        require(projectEvaluation[projectId].projectId == projectId, "no data found");

        EvaluateDetails memory modifiedEvaluation = EvaluateDetails(
            _evaluationId,
            projectEvaluationQuestions[projectId],
            projectId,
            rating,
            _msgSender()
        );

        projectEvaluation[projectId] = modifiedEvaluation;
        userEvaluation[_msgSender()][evaludationIndex] = modifiedEvaluation;

        emit EvaluationModified(_evaluationId, projectId, projectEvaluationQuestions[projectId], rating, _msgSender());
    }

    /**
     * @dev  create rating for a project.
     *
     * @param projectId project Id.
     * @param userRating rating (1 to 5)
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - boolean.
     *
     * Emits a {ratingAdded} event.
     */

    function createRating(uint256 projectId, uint256 userRating) external {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exists");
        require(userRating >= 1 && userRating <= 5, "Rating needs to be between 1 to 5");

        require(
            userRatings[_msgSender()].projectRating[projectId] == 0,
            "The project has already been rated by the User"
        );

        RatingDetails memory newRating = RatingDetails(
            ratingId,
            _msgSender(),
            userRating,
            false,
            block.timestamp,
            projectId
        );

        ratingDetails[ratingId] = newRating;
        ratingById[projectId].push(ratingId);

        userRatings[_msgSender()].projectRating[projectId] = ratingId;
        userRatings[_msgSender()].ratingIds.push(ratingId);
        userRatings[_msgSender()].projectsRated.push(projectId);
        userRatings[_msgSender()].user = _msgSender();

        ratingId += 1;
        emit RatingAdded(projectId, userRating, _msgSender());
    }

    /**
     * @dev modify rating for a project.
     *
     * @param projectId project Id.
     * @param userRating rating (1 to 5)
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - boolean.
     *
     * Emits a {ratingModified} event.
     */

    function modifyRating(uint256 projectId, uint256 userRating) external {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exists");
        require(userRating >= 1 && userRating <= 5, "Rating needs to be between 1 to 5");
        require(userRatings[_msgSender()].projectRating[projectId] != 0, "User has not yet rated this Project.");

        uint256 updateRatingIds = userRatings[_msgSender()].projectRating[projectId];

        require(ratingDetails[updateRatingIds].reviewGiven == false, "Review has been given, cannot modify rating");

        ratingDetails[updateRatingIds].rating = userRating;
        ratingDetails[updateRatingIds].timestamp = block.timestamp;

        emit RatingModified(projectId, userRating, _msgSender());
    }

    /**
     * @dev add review for a project.
     *
     * @param projectId project Id.
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - boolean.
     *
     * Emits a {reviewGiven} event.
     */

    function addReview(uint256 projectId) external {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exists");

        uint256 ratingIndex = userRatings[_msgSender()].projectRating[projectId];

        require(ratingDetails[ratingIndex].reviewGiven == false, "Review already given");
        require(ratingIndex > 0, "Rating must be given before review");

        ratingDetails[ratingIndex].reviewGiven = true;

        emit ReviewGiven(projectId, _msgSender());
    }

    //This function returns rating details for a prticular project
    /**
     * @dev returns rating details for a prticular project.
     *
     * @param projectId project Id.
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - rating details
     */
    function ratingOfProject(uint256 projectId) external view returns (RatingDetails[] memory) {
        require(projectLockDetails[projectId].projectId == projectId && projectId != 0, "Project does not exists");
        uint256[] memory projectRatingIdss = ratingById[projectId];
        return getRatingDetails(projectRatingIdss);
    }

    /**
     * @dev  returns rating details given by user.
     *
     * @param user address.
     *
     * Requirements:
     * - Project Id must be created.
     *
     * Returns
     * - rating details
     */
    function ratingByUser(address user) external view returns (RatingDetails[] memory) {
        uint256[] memory projectRatingIdss = userRatings[user].ratingIds;
        return getRatingDetails(projectRatingIdss);
    }

    /**
     * @dev private function to get rating details.
     */
    function getRatingDetails(uint256[] memory _ratingNumbers) private view returns (RatingDetails[] memory) {
        RatingDetails[] memory ratings = new RatingDetails[](_ratingNumbers.length);
        for (uint i = 0; i < _ratingNumbers.length; i++) {
            RatingDetails memory rating = ratingDetails[_ratingNumbers[i]];
            ratings[i] = rating;
        }
        return (ratings);
    }

    /**
     * @dev returns all project Ids.
     *
     * Returns
     * - All project Ids
     */
    function getAllProjectID() external view returns (uint256[] memory) {
        return (projects);
    }

    /**
     * @dev checks if a given project id exists
     *
     * @param projectId project Id.
     *
     * Returns
     * - True/False
     */
    function doesProjectExist(uint256 projectId) external view returns (bool) {
        return projectId != 0 && projectLockDetails[projectId].projectId == projectId;
    }

    // This two are internal functions, they are required for eip 2771
    // when openzepplin ownable or upgrade functionalities are used

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Recipient) returns (address sender) {
        sender = ERC2771Recipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Recipient) returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }

    /*
     * @dev This function is used to validate the questions Ids and rating
     *
     * @param questionsIds questions Ids
     * @param rating rating
     *
     * Returns
     * - True/False
     */
    function validateEvaluationQuestions(string memory questionsIds, uint256 rating) internal pure returns (bool) {
        string memory ratingString = Strings.toString(rating);

        uint numQuestions = 1;
        uint questionsIdsLength = strlen(questionsIds);

        if (questionsIdsLength == 0) {
            return false;
        }

        for (uint i; i < questionsIdsLength; i++) {
            bytes1 char = bytes(questionsIds)[i];

            // checks if all character are either numbers or the character '-'
            if (!((char >= 0x30 && char <= 0x39) || char == 0x2d)) {
                return false;
            }

            if (char == 0x2d) {
                // check for '-'
                numQuestions += 1;
            }
        }

        if (strlen(ratingString) != numQuestions) {
            return false;
        }

        return true;
    }

    // This function is used to get the length of a string
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 byteLength = bytes(s).length;
        for (len = 0; i < byteLength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

interface IFilmioProjectV1 {
    function doesProjectExist(uint256 projectId) external view returns (bool);
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// SPDX-License-Identifier: MIT

contract VariableDataV1 is OwnableUpgradeable {
    // struct for storing lock details
    struct LockDetails {
        uint256 projectId;
        uint256 createdAt;
    }

    // mapping of project Id with lock details
    mapping(uint256 => LockDetails) public projectLockDetails;

    // project Ids that have been created
    uint256[] internal projects;

    // struct for storing remark udated
    struct Update {
        uint256 projectId;
        string remark;
        uint256 timestamp;
    }

    // mapping of project Id with update struct array
    mapping(uint256 => Update[]) public projectUpdateDetails;

    // struct for storing Evaluation details
    struct EvaluateDetails {
        uint256 evaluationId;
        string questionIds;
        uint256 projectId;
        uint256 rating;
        address account;
    }

    // mapping of project Id with Evaluation questions ids
    mapping(uint256 => string) public projectEvaluationQuestions;

    // mapping of project Id with Evaluation struct
    mapping(uint256 => EvaluateDetails) public projectEvaluation;

    // mapping of user to Evaluation struct
    mapping(address => EvaluateDetails[]) public userEvaluation;

    // mapping from evaluation Id to its index in its user evaluation array
    mapping(uint256 => uint256) public evaluationIndicies;

    // storing Rating details in struct
    struct RatingDetails {
        uint256 ratingId;
        address user;
        uint256 rating;
        bool reviewGiven;
        uint256 timestamp;
        uint256 projectId;
    }

    // storing rating details w.r.t user address
    struct User {
        address user;
        uint256[] projectsRated;
        uint256[] ratingIds;
        mapping(uint256 => uint256) projectRating;
    }

    // mapping of Rating Id w.r.t rating details
    mapping(uint256 => RatingDetails) public ratingDetails;

    // mapping of project Id w.r.t rating Ids array
    mapping(uint256 => uint256[]) public ratingById;

    // mapping of user w.r.t to user struct details
    mapping(address => User) public userRatings;

    // rating Id counter
    uint256 public ratingId;

    // evaluation Id counter
    uint256 public evaluationId;

    // gap for future variables (upgrades)
    uint256[50] __gap;

    /**
     * @dev Emitted when new rating is created.
     */

    event RatingAdded(uint256 projectId, uint256 userrating, address givenBy);

    /**
     * @dev Emitted when rating is modified.
     */

    event RatingModified(uint256 projectId, uint256 userrating, address modifiedBy);

    /**
     * @dev Emitted when review is given.
     */

    event ReviewGiven(uint256 projectId, address givenBy);

    /**
     * @dev Emitted when evaluation is created.
     */

    event EvaluationCreated(uint256 evaluationId, uint256 projectId, string questionIds, uint256 rating, address user);

    /**
     * @dev Emitted when evaluation is modified.
     */

    event EvaluationModified(uint256 evaluationId, uint256 projectId, string questionIds, uint256 rating, address user);

    /**
     * @dev Emitted when new update is created.
     */

    event UpdateCreated(uint256 projectId, string remark, address createdBy);

    /**
     * @dev Emitted when new lock is created.
     */

    event LockCreated(uint256 projectId, address createdBy);

    /**
     * @dev Emitted when trusted forwarder address is modified.
     */

    event TrustedForwarderModified(address forwarder);

    /**
     * @dev Emitted when evaluation questions are set.
     */

    event EvaluationQuestionsSet(uint256 projectId, string questionIds);
}