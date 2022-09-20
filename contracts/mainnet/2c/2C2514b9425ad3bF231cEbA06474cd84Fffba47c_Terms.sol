// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Factory} from "./interfaces/IArrakisV2Factory.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IArrakisV2} from "./interfaces/IArrakisV2.sol";
import {IGasStation} from "./interfaces/IGasStation.sol";
import {TermsStorage} from "./abstracts/TermsStorage.sol";
import {
    SetupPayload,
    IncreaseBalance,
    ExtendingTermData,
    DecreaseBalance,
    Inits
} from "./structs/STerms.sol";
import {InitializePayload} from "./interfaces/IArrakisV2.sol";
import {
    _requireAddressNotZero,
    _getInits,
    _requireTokenMatch,
    _requireIsOwnerOrDelegate,
    _requireIsOwner,
    _getEmolument,
    _requireProjectAllocationGtZero,
    _requireTknOrder,
    _burn
} from "./functions/FTerms.sol";

// solhint-disable-next-line no-empty-blocks
contract Terms is TermsStorage {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line no-empty-blocks
    constructor(IArrakisV2Factory v2factory_) TermsStorage(v2factory_) {}

    /// @notice do all neccesary step to initialize market making.
    // solhint-disable-next-line function-max-lines
    function openTerm(SetupPayload calldata setup_, uint256 mintAmount_)
        external
        payable
        override
        noLeftOver(setup_.token0, setup_.token1)
        returns (address vault)
    {
        _requireAddressNotZero(mintAmount_);
        _requireProjectAllocationGtZero(
            setup_.projectTknIsTknZero,
            setup_.amount0,
            setup_.amount1
        );
        _requireTknOrder(address(setup_.token0), address(setup_.token1));

        {
            Inits memory inits;
            (inits.init0, inits.init1) = _getInits(
                mintAmount_,
                setup_.amount0,
                setup_.amount1
            );

            // Create vaultV2.
            vault = v2factory.deployVault(
                InitializePayload({
                    feeTiers: setup_.feeTiers,
                    token0: address(setup_.token0),
                    token1: address(setup_.token1),
                    owner: address(this),
                    init0: inits.init0,
                    init1: inits.init1,
                    manager: manager,
                    maxTwapDeviation: setup_.maxTwapDeviation,
                    twapDuration: setup_.twapDuration,
                    maxSlippage: setup_.maxSlippage
                }),
                setup_.isBeacon
            );
        }

        IArrakisV2 vaultV2 = IArrakisV2(vault);

        _addVault(setup_.owner, vault);
        if (setup_.delegate != address(0)) _setDelegate(vault, setup_.delegate);
        // Mint vaultV2 token.

        // Call the manager to make it manage the new vault.
        IGasStation(manager).addVault{value: msg.value}(
            vault,
            setup_.datas,
            setup_.strat
        );

        // Transfer to termTreasury the project token emolment.
        setup_.token0.safeTransferFrom(
            msg.sender,
            address(this),
            setup_.amount0
        );
        setup_.token1.safeTransferFrom(
            msg.sender,
            address(this),
            setup_.amount1
        );

        setup_.token0.approve(vault, setup_.amount0);
        setup_.token1.approve(vault, setup_.amount1);

        vaultV2.mint(mintAmount_, address(this));

        IGasStation(manager).toggleRestrictMint(vault);

        emit SetupVault(setup_.owner, vault);
    }

    // solhint-disable-next-line function-max-lines
    function increaseLiquidity(
        IncreaseBalance calldata increaseBalance_, // memory instead of calldata to set values
        uint256 mintAmount_
    )
        external
        override
        noLeftOver(
            increaseBalance_.vault.token0(),
            increaseBalance_.vault.token1()
        )
    {
        _requireAddressNotZero(mintAmount_);
        _requireProjectAllocationGtZero(
            increaseBalance_.projectTknIsTknZero,
            increaseBalance_.amount0,
            increaseBalance_.amount1
        );
        _requireIsOwner(vaults[msg.sender], address(increaseBalance_.vault));

        (uint256 amount0, uint256 amount1) = _burn(
            increaseBalance_.vault,
            address(this),
            resolver
        );

        // Transfer to termTreasury the project token emolment.
        increaseBalance_.vault.token0().safeTransferFrom(
            msg.sender,
            address(this),
            increaseBalance_.amount0
        );
        increaseBalance_.vault.token1().safeTransferFrom(
            msg.sender,
            address(this),
            increaseBalance_.amount1
        );

        increaseBalance_.vault.token0().approve(
            address(increaseBalance_.vault),
            increaseBalance_.amount0 + amount0
        );

        increaseBalance_.vault.token1().approve(
            address(increaseBalance_.vault),
            increaseBalance_.amount1 + amount1
        );

        {
            Inits memory inits;
            (inits.init0, inits.init1) = _getInits(
                mintAmount_,
                increaseBalance_.amount0 + amount0,
                increaseBalance_.amount1 + amount1
            );

            increaseBalance_.vault.setInits(inits.init0, inits.init1);
        }

        IGasStation(manager).toggleRestrictMint(
            address(increaseBalance_.vault)
        );

        increaseBalance_.vault.mint(mintAmount_, address(this));

        IGasStation(manager).toggleRestrictMint(
            address(increaseBalance_.vault)
        );

        emit IncreaseLiquidity(msg.sender, address(increaseBalance_.vault));
    }

    // solhint-disable-next-line function-max-lines
    function extendingTerm(
        ExtendingTermData calldata extensionData_,
        uint256 mintAmount_
    )
        external
        override
        noLeftOver(extensionData_.vault.token0(), extensionData_.vault.token1())
    {
        _requireAddressNotZero(mintAmount_);
        _requireIsOwnerOrDelegate(
            delegateByVaults[address(extensionData_.vault)],
            vaults[msg.sender],
            address(extensionData_.vault)
        );
        require(
            IGasStation(manager)
                .getVaultInfo(address(extensionData_.vault))
                .endOfMM < block.timestamp + 60 * 60 * 24, // solhint-disable-line not-rely-on-time
            "Terms: terms is active."
        );

        (uint256 amount0, uint256 amount1) = _burn(
            extensionData_.vault,
            address(this),
            resolver
        );

        // Transfer to termTreasury the project token emolment.
        extensionData_.vault.token0().safeTransferFrom(
            msg.sender,
            address(this),
            extensionData_.amount0
        );
        extensionData_.vault.token1().safeTransferFrom(
            msg.sender,
            address(this),
            extensionData_.amount1
        );

        uint256 emolumentAmt0 = _getEmolument(amount0, emolument);
        uint256 emolumentAmt1 = _getEmolument(amount1, emolument);
        extensionData_.vault.token0().approve(
            address(extensionData_.vault),
            extensionData_.amount0 + amount0 - emolumentAmt0
        );
        extensionData_.vault.token1().approve(
            address(extensionData_.vault),
            extensionData_.amount1 + amount1 - emolumentAmt1
        );
        if (emolumentAmt0 > 0)
            extensionData_.vault.token0().safeTransfer(
                termTreasury,
                emolumentAmt0
            );
        if (emolumentAmt1 > 0)
            extensionData_.vault.token1().safeTransfer(
                termTreasury,
                emolumentAmt1
            );
        {
            Inits memory inits;
            (inits.init0, inits.init1) = _getInits(
                mintAmount_,
                extensionData_.amount0 + amount0 - emolumentAmt0,
                extensionData_.amount1 + amount1 - emolumentAmt1
            );

            extensionData_.vault.setInits(inits.init0, inits.init1);
        }

        IGasStation(manager).toggleRestrictMint(address(extensionData_.vault));

        extensionData_.vault.mint(mintAmount_, address(this));

        IGasStation(manager).toggleRestrictMint(address(extensionData_.vault));

        IGasStation(manager).expandMMTermDuration(
            address(extensionData_.vault)
        );

        emit ExtendingTerm(
            msg.sender,
            address(extensionData_.vault),
            emolumentAmt0,
            emolumentAmt1
        );
    }

    // solhint-disable-next-line function-max-lines
    function decreaseLiquidity(
        DecreaseBalance calldata decreaseBalance_,
        uint256 mintAmount_
    )
        external
        override
        noLeftOver(
            decreaseBalance_.vault.token0(),
            decreaseBalance_.vault.token1()
        )
    {
        _requireAddressNotZero(mintAmount_);
        _requireIsOwner(vaults[msg.sender], address(decreaseBalance_.vault));

        address me = address(this);

        (uint256 amount0, uint256 amount1) = _burn(
            decreaseBalance_.vault,
            me,
            resolver
        );
        require(
            decreaseBalance_.amount0 < amount0,
            "Terms: send back amount0 > amount0"
        );
        require(
            decreaseBalance_.amount1 < amount1,
            "Terms: send back amount1 > amount1"
        );

        uint256 emolumentAmt0 = _getEmolument(
            decreaseBalance_.amount0,
            emolument
        );
        uint256 emolumentAmt1 = _getEmolument(
            decreaseBalance_.amount1,
            emolument
        );

        {
            IERC20 token0 = decreaseBalance_.vault.token0();
            IERC20 token1 = decreaseBalance_.vault.token1();

            if (emolumentAmt0 > 0)
                token0.safeTransfer(termTreasury, emolumentAmt0);
            if (emolumentAmt1 > 0)
                token1.safeTransfer(termTreasury, emolumentAmt1);

            token0.safeTransfer(
                decreaseBalance_.to,
                decreaseBalance_.amount0 - emolumentAmt0
            );
            token1.safeTransfer(
                decreaseBalance_.to,
                decreaseBalance_.amount1 - emolumentAmt1
            );
            token0.approve(
                address(decreaseBalance_.vault),
                amount0 - decreaseBalance_.amount0
            );
            token1.approve(
                address(decreaseBalance_.vault),
                amount1 - decreaseBalance_.amount1
            );
        }
        {
            (uint256 init0, uint256 init1) = _getInits(
                mintAmount_,
                amount0 - decreaseBalance_.amount0,
                amount1 - decreaseBalance_.amount1
            );
            decreaseBalance_.vault.setInits(init0, init1);
        }

        IGasStation(manager).toggleRestrictMint(
            address(decreaseBalance_.vault)
        );

        decreaseBalance_.vault.mint(mintAmount_, me);

        IGasStation(manager).toggleRestrictMint(
            address(decreaseBalance_.vault)
        );

        emit DecreaseLiquidity(
            msg.sender,
            address(decreaseBalance_.vault),
            emolumentAmt0,
            emolumentAmt1
        );
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function closeTerm(
        IArrakisV2 vault_,
        address to_,
        address newOwner_,
        address newManager_
    )
        external
        override
        requireAddressNotZero(newOwner_)
        requireAddressNotZero(to_)
    {
        uint256 index = _requireIsOwner(vaults[msg.sender], address(vault_));
        address vaultAddr = address(vault_);

        delete vaults[msg.sender][index];

        for (uint256 i = index; i < vaults[msg.sender].length - 1; i++) {
            vaults[msg.sender][i] = vaults[msg.sender][i + 1];
        }
        vaults[msg.sender].pop();

        (uint256 amount0, uint256 amount1) = _burn(
            vault_,
            address(this),
            resolver
        );

        uint256 emolumentAmt0 = _getEmolument(amount0, emolument);
        uint256 emolumentAmt1 = _getEmolument(amount1, emolument);

        if (emolumentAmt0 > 0)
            vault_.token0().safeTransfer(termTreasury, emolumentAmt0);
        if (emolumentAmt1 > 0)
            vault_.token1().safeTransfer(termTreasury, emolumentAmt1);

        if (amount0 > 0)
            vault_.token0().safeTransfer(to_, amount0 - emolumentAmt0);
        if (amount1 > 0)
            vault_.token1().safeTransfer(to_, amount1 - emolumentAmt1);

        IGasStation(manager).removeVault(address(vault_), payable(to_));
        vault_.setManager(IGasStation(newManager_));
        vault_.transferOwnership(newOwner_);

        emit CloseTerm(
            msg.sender,
            vaultAddr,
            amount0,
            amount1,
            to_,
            emolumentAmt0,
            emolumentAmt1
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ITerms} from "../interfaces/ITerms.sol";
import {IArrakisV2Factory} from "../interfaces/IArrakisV2Factory.sol";
import {IArrakisV2Resolver} from "../interfaces/IArrakisV2Resolver.sol";
import {IArrakisV2} from "../interfaces/IArrakisV2.sol";
import {IGasStation} from "../interfaces/IGasStation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/FullMath.sol";
import {
    _getInits,
    _requireTokenMatch,
    _requireIsOwnerOrDelegate,
    _requireIsOwner,
    _getEmolument,
    _requireProjectAllocationGtZero,
    _requireTknOrder,
    _burn
} from "../functions/FTerms.sol";

// solhint-disable-next-line max-states-count
abstract contract TermsStorage is
    ITerms,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IArrakisV2Factory public immutable v2factory;
    mapping(address => address[]) public vaults;
    address public termTreasury;
    address public manager;
    uint16 public emolument;
    IArrakisV2Resolver public resolver;

    // #region no left over.

    // New variable for Proxy.
    mapping(address => address) public delegateByVaults;

    modifier noLeftOver(IERC20 token0_, IERC20 token1_) {
        uint256 token0Balance = token0_.balanceOf(address(this));
        uint256 token1Balance = token1_.balanceOf(address(this));
        _;
        uint256 leftOver0 = token0_.balanceOf(address(this)) - token0Balance;
        uint256 leftOver1 = token1_.balanceOf(address(this)) - token1Balance;
        if (leftOver0 > 0) token0_.transfer(msg.sender, leftOver0);
        if (leftOver1 > 0) token1_.transfer(msg.sender, leftOver1);
    }

    modifier requireAddressNotZero(address addr) {
        require(addr != address(0), "Terms: address Zero");
        _;
    }

    // #endregion no left over.

    constructor(IArrakisV2Factory v2factory_) {
        v2factory = v2factory_;
    }

    function initialize(
        address owner_,
        address termTreasury_,
        uint16 emolument_,
        IArrakisV2Resolver resolver_
    ) external initializer {
        require(emolument < 10000, "Terms: emolument >= 100%.");
        _transferOwnership(owner_);
        termTreasury = termTreasury_;
        emolument = emolument_;
        resolver = resolver_;
    }

    // #region setter.

    function setEmolument(uint16 emolument_) external onlyOwner {
        require(
            emolument_ < emolument,
            "Terms: new emolument >= old emolument"
        );
        emit SetEmolument(emolument, emolument = emolument_);
    }

    function setTermTreasury(address termTreasury_)
        external
        onlyOwner
        requireAddressNotZero(termTreasury_)
    {
        require(termTreasury != termTreasury_, "Terms: already term treasury");
        emit SetTermTreasury(termTreasury, termTreasury = termTreasury_);
    }

    function setResolver(IArrakisV2Resolver resolver_)
        external
        onlyOwner
        requireAddressNotZero(address(resolver_))
    {
        require(
            address(resolver) != address(resolver_),
            "Terms: already resolver"
        );
        emit SetResolver(resolver, resolver = resolver_);
    }

    function setManager(address manager_)
        external
        override
        onlyOwner
        requireAddressNotZero(manager_)
    {
        require(manager_ != manager, "Terms: already manager");
        emit SetManager(manager, manager = manager_);
    }

    // #endregion setter.

    // #region vault config as admin.

    function addPools(IArrakisV2 vault_, uint24[] calldata feeTiers_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.addPools(feeTiers_);

        emit LogAddPools(msg.sender, vaultAddr, feeTiers_);
    }

    function removePools(IArrakisV2 vault_, address[] calldata pools_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.removePools(pools_);

        emit LogRemovePools(msg.sender, vaultAddr, pools_);
    }

    function setMaxTwapDeviation(IArrakisV2 vault_, int24 maxTwapDeviation_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.setMaxTwapDeviation(maxTwapDeviation_);

        emit LogSetMaxTwapDeviation(msg.sender, vaultAddr, maxTwapDeviation_);
    }

    function setTwapDuration(IArrakisV2 vault_, uint24 twapDuration_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.setTwapDuration(twapDuration_);

        emit LogSetTwapDuration(msg.sender, vaultAddr, twapDuration_);
    }

    function setMaxSlippage(IArrakisV2 vault_, uint24 maxSlippage_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.setMaxSlippage(maxSlippage_);

        emit LogSetMaxSlippage(msg.sender, vaultAddr, maxSlippage_);
    }

    // #endregion vault config as admin.

    // #region gasStation config as vault owner.

    function setVaultData(address vault_, bytes calldata data_)
        external
        override
        requireAddressNotZero(vault_)
    {
        address vaultAddr = address(vault_);
        _requireIsOwnerOrDelegate(
            delegateByVaults[vault_],
            vaults[msg.sender],
            vaultAddr
        );
        IGasStation(manager).setVaultData(vault_, data_);

        emit LogSetVaultData(
            delegateByVaults[vault_] != address(0)
                ? delegateByVaults[vault_]
                : msg.sender,
            vaultAddr,
            data_
        );
    }

    function setVaultStratByName(address vault_, string calldata strat_)
        external
        override
        requireAddressNotZero(vault_)
    {
        address vaultAddr = address(vault_);
        _requireIsOwnerOrDelegate(
            delegateByVaults[vault_],
            vaults[msg.sender],
            vaultAddr
        );
        IGasStation(manager).setVaultStraByName(vault_, strat_);

        emit LogSetVaultStratByName(
            delegateByVaults[vault_] != address(0)
                ? delegateByVaults[vault_]
                : msg.sender,
            vaultAddr,
            strat_
        );
    }

    function setDelegate(address vault_, address delegate_) external override {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        _setDelegate(vault_, delegate_);

        emit LogSetDelegate(msg.sender, vaultAddr, delegate_);
    }

    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external override requireAddressNotZero(vault_) {
        address vaultAddr = address(vault_);
        IGasStation gasStation = IGasStation(manager);
        (uint256 balance, , , , ) = gasStation.vaults(vaultAddr);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        gasStation.withdrawVaultBalance(vault_, amount_, to_);

        emit LogWithdrawVaultBalance(msg.sender, vaultAddr, to_, balance);
    }

    // #endregion gasStation config as vault owner.

    // #region internals setter.

    function _addVault(address creator_, address vault_) internal {
        address[] storage vaultsOfCreator = vaults[creator_];

        for (uint256 i = 0; i < vaultsOfCreator.length; i++) {
            require(vaultsOfCreator[i] != vault_, "Terms: vault exist");
        }

        vaultsOfCreator.push(vault_);
        emit AddVault(creator_, vault_);
    }

    function _removeVault(address creator_, address vault_) internal {
        address[] storage vaultsOfCreator = vaults[creator_];

        for (uint256 i = 0; i < vaultsOfCreator.length; i++) {
            if (vaultsOfCreator[i] == vault_) {
                delete vaultsOfCreator[i];
                emit RemoveVault(creator_, vault_);
                return;
            }
        }

        revert("Terms: vault don't exist");
    }

    function _setDelegate(address vault_, address delegate_) internal {
        require(
            delegateByVaults[vault_] != delegate_,
            "Terms: already delegate"
        );

        delegateByVaults[vault_] = delegate_;
        emit DelegateVault(msg.sender, vault_, delegate_);
    }

    // #endregion internals setter.
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2, BurnLiquidity} from "../interfaces/IArrakisV2.sol";
import {IArrakisV2Resolver} from "../interfaces/IArrakisV2Resolver.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/FullMath.sol";

function _burn(
    IArrakisV2 vault_,
    address me,
    IArrakisV2Resolver resolver
) returns (uint256 amount0, uint256 amount1) {
    uint256 balanceOfArrakisTkn = IERC20(address(vault_)).balanceOf(me);

    BurnLiquidity[] memory burnPayload = resolver.standardBurnParams(
        balanceOfArrakisTkn,
        vault_
    );

    (amount0, amount1) = vault_.burn(burnPayload, balanceOfArrakisTkn, me);
}

function _getInits(
    uint256 mintAmount_,
    uint256 amount0_,
    uint256 amount1_
) pure returns (uint256 init0, uint256 init1) {
    init0 = FullMath.mulDiv(amount0_, 1e18, mintAmount_);
    init1 = FullMath.mulDiv(amount1_, 1e18, mintAmount_);
}

function _requireTokenMatch(
    IArrakisV2 vault_,
    IERC20 token0_,
    IERC20 token1_
) view {
    require(
        address(token0_) == address(vault_.token0()),
        "Terms: wrong token0."
    );
    require(
        address(token1_) == address(vault_.token1()),
        "Terms: wrong token1."
    );
}

function _requireIsOwnerOrDelegate(
    address delegate_,
    address[] memory vaults_,
    address vault_
) view {
    if (delegate_ != address(0)) {
        require(msg.sender == delegate_, "Terms: no delegate");
    } else _requireIsOwner(vaults_, vault_);
}

function _requireIsOwner(address[] memory vaults_, address vault_)
    pure
    returns (uint256 index)
{
    bool isOwner;
    (isOwner, index) = _isOwnerOfVault(vaults_, address(vault_));
    require(isOwner, "Terms: not owner");
}

function _isOwnerOfVault(address[] memory vaults_, address vault_)
    pure
    returns (bool, uint256 index)
{
    for (index = 0; index < vaults_.length; index++) {
        if (vaults_[index] == vault_) return (true, index);
    }
    return (false, 0);
}

function _getEmolument(uint256 projectTokenAllocation_, uint16 emolument_)
    pure
    returns (uint256)
{
    return (projectTokenAllocation_ * emolument_) / 10000;
}

function _requireProjectAllocationGtZero(
    bool projectTknIsTknZero_,
    uint256 amount0_,
    uint256 amount1_
) pure {
    require(
        projectTknIsTknZero_ ? amount0_ > 0 : amount1_ > 0,
        "Terms: no project token allocation."
    );
}

function _requireAddressNotZero(uint256 mintAmount_) pure {
    require(mintAmount_ > 0, "Terms: mintAmount zero.");
}

function _requireTknOrder(address token0_, address token1_) pure {
    require(token0_ < token1_, "Terms: tokens order inverted.");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGasStation} from "./IGasStation.sol";

// structs copied from v2-core/contracts/structs/SVaultV2.sol
struct PositionLiquidity {
    uint128 liquidity;
    Range range;
}

struct SwapPayload {
    bytes payload;
    address pool;
    address router;
    uint256 amountIn;
    uint256 expectedMinReturn;
    bool zeroForOne;
}

struct Range {
    int24 lowerTick;
    int24 upperTick;
    uint24 feeTier;
}

struct Rebalance {
    PositionLiquidity[] removes;
    PositionLiquidity[] deposits;
    SwapPayload swap;
}

struct InitializePayload {
    uint24[] feeTiers;
    address token0;
    address token1;
    address owner;
    uint256 init0;
    uint256 init1;
    address manager;
    int24 maxTwapDeviation;
    uint24 twapDuration;
    uint24 maxSlippage;
}

struct BurnLiquidity {
    uint128 liquidity;
    Range range;
}

interface IArrakisV2 {
    function mint(uint256 mintAmount_, address receiver_)
        external
        returns (uint256 amount0, uint256 amount1);

    function rebalance(
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_
    ) external;

    function burn(
        BurnLiquidity[] calldata burns_,
        uint256 burnAmount_,
        address receiver_
    ) external returns (uint256 amount0, uint256 amount1);

    function transferOwnership(address newOwner) external;

    function toggleRestrictMint() external;

    function setInits(uint256 init0_, uint256 init1_) external;

    function addPools(uint24[] calldata feeTiers_) external;

    function removePools(address[] calldata pools_) external;

    function setManager(IGasStation manager_) external;

    function setMaxTwapDeviation(int24 maxTwapDeviation_) external;

    function setTwapDuration(uint24 twapDuration_) external;

    function setMaxSlippage(uint24 maxSlippage_) external;

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function rangeExist(Range calldata range_)
        external
        view
        returns (bool ok, uint256 index);

    function owner() external view returns (address);

    function manager() external view returns (IGasStation);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IArrakisV2Beacon {
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Beacon} from "./IArrakisV2Beacon.sol";
import {InitializePayload} from "./IArrakisV2.sol";

interface IArrakisV2Factory {
    event VaultCreated(address indexed manager, address indexed vault);

    event InitFactory(address implementation);

    function deployVault(InitializePayload calldata params_, bool isBeacon_)
        external
        returns (address vault);

    // #region view functions

    function version() external view returns (string memory);

    function arrakisV2Beacon() external view returns (IArrakisV2Beacon);

    function deployer() external view returns (address);

    function index() external view returns (uint256);

    function numVaultsByDeployer(address deployer_)
        external
        view
        returns (uint256);

    function getVaultsByDeployer(address deployer_)
        external
        view
        returns (address[] memory);

    function getProxyAdmin(address proxy) external view returns (address);

    function getProxyImplementation(address proxy)
        external
        view
        returns (address);

    // #endregion view functions
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2, Rebalance, Range, BurnLiquidity} from "./IArrakisV2.sol";

// structs copied from v2-core/contracts/structs/SVaultV2.sol
struct RangeWeight {
    Range range;
    uint256 weight; // should be between 0 and 100%
}

interface IArrakisV2Resolver {
    function standardRebalance(
        RangeWeight[] memory rangeWeights_,
        IArrakisV2 vaultV2_
    ) external view returns (Rebalance memory rebalanceParams);

    function standardBurnParams(uint256 amountToBurn_, IArrakisV2 vaultV2_)
        external
        view
        returns (BurnLiquidity[] memory burns);

    function getMintAmounts(
        IArrakisV2 vaultV2_,
        uint256 amount0Max_,
        uint256 amount1Max_
    )
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Rebalance, Range} from "./IArrakisV2.sol";
import {IManagerProxyV2} from "./IManagerProxyV2.sol";
import {VaultInfo} from "../structs/SGasStation.sol";

interface IGasStation is IManagerProxyV2 {
    event AddVault(address indexed vault, bytes datas, string strat);

    event RemoveVault(address indexed vault, uint256 sendBack);

    event SetVaultData(address indexed vault, bytes data);

    event SetVaultStrat(address indexed vault, bytes32 strat);

    event WhitelistStrat(address indexed gasStation, string strat);

    event AddOperators(address indexed gasStation, address[] operators);

    event RemoveOperators(address indexed gasStation, address[] operators);

    event UpdateVaultBalance(address indexed vault, uint256 newBalance);

    event ExpandTermDuration(
        address indexed vault,
        uint256 oldMmTermDuration,
        uint256 newMmTermDuration
    );

    event ToggleRestrictMint(address indexed vault);

    event WithdrawVaultBalance(
        address indexed vault,
        uint256 amount,
        address to,
        uint256 newBalance
    );

    event RebalanceVault(address indexed vault, uint256 newBalance);

    // ======== GELATOFIED FUNCTIONS ========
    function rebalance(
        address vault_,
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_,
        uint256 feeAmount_
    ) external;

    // ======= PERMISSIONED OWNER FUNCTIONS =====
    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external;

    function addVault(
        address vault_,
        bytes calldata datas_,
        string calldata strat_
    ) external payable;

    function removeVault(address vault_, address payable to_) external;

    function setVaultData(address vault_, bytes calldata data_) external;

    function setVaultStraByName(address vault_, string calldata strat_)
        external;

    function addOperators(address[] calldata operators_) external;

    function removeOperators(address[] calldata operators_) external;

    function pause() external;

    function unpause() external;

    // ======= PUBLIC FUNCTIONS =====

    function fundVaultBalance(address vault_) external payable;

    function expandMMTermDuration(address vault_) external;

    function toggleRestrictMint(address vault_) external;

    function getVaultInfo(address vault_)
        external
        view
        returns (VaultInfo memory);

    function getWhitelistedStrat() external view returns (bytes32[] memory);

    function vaults(address vault_)
        external
        view
        returns (
            uint256 balance,
            uint256 lastBalance,
            bytes memory datas,
            bytes32 strat,
            uint256 endOfMM
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IManagerProxy {
    // ======= EXTERNAL FUNCTIONS =======
    function fundVaultBalance(address vault) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IManagerProxy} from "./IManagerProxy.sol";

interface IManagerProxyV2 is IManagerProxy {
    function managerFeeBPS() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Factory} from "./IArrakisV2Factory.sol";
import {IArrakisV2Resolver} from "./IArrakisV2Resolver.sol";
import {IArrakisV2} from "./IArrakisV2.sol";
import {IGasStation} from "./IGasStation.sol";
import {
    SetupPayload,
    IncreaseBalance,
    ExtendingTermData,
    DecreaseBalance
} from "../structs/STerms.sol";

interface ITerms {
    // #region events.

    event SetEmolument(uint16 oldEmolument, uint16 newEmolment);
    event SetTermTreasury(address oldTermTreasury, address newTermTreasury);
    event SetManager(address oldManager, address newManager);
    event SetResolver(
        IArrakisV2Resolver oldResolver,
        IArrakisV2Resolver newResolver
    );

    event AddVault(address creator, address vault);
    event RemoveVault(address creator, address vault);
    event DelegateVault(address creator, address vault, address delegate);

    event SetupVault(address creator, address vault);
    event IncreaseLiquidity(address creator, address vault);
    event ExtendingTerm(
        address creator,
        address vault,
        uint256 emolument0,
        uint256 emolument1
    );
    event DecreaseLiquidity(
        address creator,
        address vault,
        uint256 emolument0,
        uint256 emolument1
    );
    event CloseTerm(
        address creator,
        address vault,
        uint256 amount0,
        uint256 amount1,
        address to,
        uint256 emolument0,
        uint256 emolument1
    );

    // #region vault modification events.

    event LogAddPools(address creator, address vault, uint24[] feeTiers);

    event LogRemovePools(address creator, address vault, address[] pools);

    event LogSetMaxTwapDeviation(
        address creator,
        address vault,
        int24 maxTwapDeviation
    );

    event LogSetTwapDuration(
        address creator,
        address vault,
        uint24 twapDuration
    );

    event LogSetMaxSlippage(address creator, address vault, uint24 maxSlippage);

    // #endregion vault modification events.

    // #region GasStation interaction events.

    event LogSetVaultData(address creatorOrDelegate, address vault, bytes data);

    event LogSetVaultStratByName(
        address creatorOrDelegate,
        address vault,
        string strat
    );

    event LogSetDelegate(address creator, address vault, address delegate);

    event LogWithdrawVaultBalance(
        address creator,
        address vault,
        address to,
        uint256 sentBack
    );

    // #endregion GasStation interaction events.

    // #endregion events.

    function openTerm(SetupPayload calldata setup_, uint256 mintAmount_)
        external
        payable
        returns (address vault);

    function increaseLiquidity(
        IncreaseBalance calldata increaseBalance_,
        uint256 mintAmount_
    ) external;

    function extendingTerm(
        ExtendingTermData calldata extensionData_,
        uint256 mintAmount_
    ) external;

    function decreaseLiquidity(
        DecreaseBalance calldata decreaseBalance_,
        uint256 mintAmount_
    ) external;

    function closeTerm(
        IArrakisV2 vault_,
        address to_,
        address newOwner_,
        address newManager_
    ) external;

    // #region Vault configuration functions.

    function addPools(IArrakisV2 vault_, uint24[] calldata feeTiers_) external;

    function removePools(IArrakisV2 vault_, address[] calldata pools_) external;

    function setMaxTwapDeviation(IArrakisV2 vault_, int24 maxTwapDeviation_)
        external;

    function setTwapDuration(IArrakisV2 vault_, uint24 twapDuration_) external;

    function setMaxSlippage(IArrakisV2 vault_, uint24 maxSlippage_) external;

    // #endregion Vault configuration functions.

    // #region GasStation configuration functions.

    function setVaultData(address vault_, bytes calldata data_) external;

    function setVaultStratByName(address vault_, string calldata strat_)
        external;

    function setDelegate(address vault_, address delegate_) external;

    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external;

    function setManager(address manager_) external;

    // #endregion GasStation configuration functions.

    function v2factory() external view returns (IArrakisV2Factory);

    function termTreasury() external view returns (address);

    function manager() external view returns (address);

    function emolument() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct VaultInfo {
    uint256 balance; // prepaid credit for rebalance
    uint256 lastRebalance; // timestamp of the last rebalance
    bytes datas; // custom bytes that can used to store data needed for rebalance.
    bytes32 strat; // strat type
    uint256 endOfMM; // expiry of the Market Making terms.
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2} from "../interfaces/IArrakisV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct SetupPayload {
    // Initialized Payload properties
    uint24[] feeTiers;
    IERC20 token0;
    IERC20 token1;
    bool projectTknIsTknZero;
    address owner;
    int24 maxTwapDeviation;
    uint24 twapDuration;
    uint24 maxSlippage;
    uint256 amount0;
    uint256 amount1;
    bytes datas;
    string strat;
    bool isBeacon;
    address delegate;
}

struct IncreaseBalance {
    IArrakisV2 vault;
    bool projectTknIsTknZero;
    uint256 amount0;
    uint256 amount1;
}

struct ExtendingTermData {
    IArrakisV2 vault;
    bool projectTknIsTknZero;
    uint256 amount0;
    uint256 amount1;
}

struct DecreaseBalance {
    IArrakisV2 vault;
    uint256 amount0;
    uint256 amount1;
    address to;
}

struct Inits {
    uint256 init0;
    uint256 init1;
}