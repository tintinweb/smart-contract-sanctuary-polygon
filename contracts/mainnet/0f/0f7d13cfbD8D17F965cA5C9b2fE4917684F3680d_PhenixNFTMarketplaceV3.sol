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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PhenixNFTMarketplaceV3 is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    uint256 constant FXP_BASE = 100000;

    uint256 private _items;

    uint256 public serviceFeePercentage;
    uint256 public maxRoyaltyFeePercentage;
    uint256 public discountNftPercentage;
    uint256 public maxDiscountNftPercentage;
    address public discountNftAddress;

    enum Status {
        AVAILABLE,
        SOLD,
        RETURNED
    }
    enum SaleMethod {
        WITH_ETH,
        WITH_ERC20
    }

    struct MarketplaceItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 priceETH;
        uint256 priceERC20;
        address payableERC20;
        Status status;
        SaleMethod method;
    }

    struct Royalties {
        uint256 royaltyPercentage;
        address royaltyReceiver;
    }

    struct MarketplaceItemOffer {
        uint256 itemId;
        address offerer;
        uint256 offerAmount;
        uint256 paidAmount;
        uint256 expiryTimestamp;
        Status status;
        SaleMethod method;
    }

    struct MarketplaceCollectionOffer {
        uint256 itemId;
        address contractAdress;
        address offerer;
        uint256 offerAmount;
        uint256 paidAmount;
        uint256 expiryTimestamp;
        Status status;
        SaleMethod method;
    }

    mapping(uint256 => MarketplaceItem) public idToMarketplaceItem;

    // Marketplace Item Index => Marketplace Item Offer (Array)
    mapping(uint256 => MarketplaceItemOffer[]) public itemOffers;

    // NFT Contract Address => Marketplace Collection Offer (Array)
    mapping(address => MarketplaceCollectionOffer[]) public collectionOffers;

    // User Address => Marketplace Item Offer (Array)
    mapping(address => MarketplaceItemOffer[]) public userItemOffers;

    // User Address  => Marketplace Collection Offer (Array)
    mapping(address => MarketplaceCollectionOffer[])
        public userCollectionOffers;

    mapping(address => bool) public permittedERC20Address;
    mapping(address => Royalties) public nftContractRoyalties;
    mapping(address => bool) public marketplaceAdmin;

    mapping(address => uint256) public claimableETHRoyalties;
    mapping(address => uint256) public usedNonces;
    mapping(address => uint256[]) public userListings;

    mapping(address => mapping(address => uint256))
        public claimableERC20Royalties;

    event MarketplaceItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 priceETH,
        uint256 priceERC20,
        address payableERC20
    );

    event ETHRoyaltiesClaimed(address indexed claimer, uint256 amount);
    event ERC20RoyaltiesClaimed(
        address indexed claimer,
        address indexed token,
        uint256 amount
    );

    modifier isAdmin() {
        require(
            marketplaceAdmin[msg.sender] || msg.sender == owner(),
            "Not admin"
        );
        _;
    }

    function initialize(
        uint256 _serviceFeePercentage,
        uint256 _maxRoyaltyFeePercentage,
        uint256 _discountNftPercentage,
        uint256 _maxDiscountNftPercentage,
        address _discountNftAddress
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        serviceFeePercentage = _serviceFeePercentage;
        maxRoyaltyFeePercentage = _maxRoyaltyFeePercentage;
        discountNftPercentage = _discountNftPercentage;
        maxDiscountNftPercentage = _maxDiscountNftPercentage;
        discountNftAddress = _discountNftAddress;
    }

    function canMoveMarketplaceItem(uint256 itemId) public view returns (bool) {
        return idToMarketplaceItem[itemId].status == Status.AVAILABLE;
    }

    function setServiceFeePercentage(
        uint256 _feePercentage,
        uint256 _feePercentageDenominator
    ) external onlyOwner {
        serviceFeePercentage =
            (_feePercentage * FXP_BASE) /
            _feePercentageDenominator;
    }

    function setNftDiscountPercentage(
        uint256 _nftDiscountPercentage,
        uint256 _maxNftDiscountPercentage,
        uint256 _nftDiscountPerecentageDenominator
    ) external onlyOwner {
        discountNftPercentage =
            (_nftDiscountPercentage * FXP_BASE) /
            _nftDiscountPerecentageDenominator;
        maxDiscountNftPercentage =
            (_maxNftDiscountPercentage * FXP_BASE) /
            _nftDiscountPerecentageDenominator;
    }

    function setNftDiscountAddress(
        address _discountNftAddress
    ) external onlyOwner {
        discountNftAddress = _discountNftAddress;
    }

    function setMarketplaceAdmin(
        address _address,
        bool _status
    ) external onlyOwner {
        marketplaceAdmin[_address] = _status;
    }

    // Sets Ownable contract royalty fees as contract owner
    function setNftRoyaltyFeeAsContractOwner(
        address nftContract,
        address feeReceiver,
        uint256 royaltyFeePercentage,
        uint256 royaltyFeeDenominator
    ) external {
        require(
            Ownable(nftContract).owner() == msg.sender,
            "Not owner of contract."
        );

        _setNftRoyaltyFee(
            nftContract,
            feeReceiver,
            royaltyFeePercentage,
            royaltyFeeDenominator
        );
    }

    // Sets contract royalty fees as admin
    function setNftRoyaltyFeeAsAdmin(
        address nftContract,
        address feeReceiver,
        uint256 royaltyFeePercentage,
        uint256 royaltyFeeDenominator
    ) external isAdmin {
        _setNftRoyaltyFee(
            nftContract,
            feeReceiver,
            royaltyFeePercentage,
            royaltyFeeDenominator
        );
    }

    function _setNftRoyaltyFee(
        address nftContract,
        address feeReceiver,
        uint256 royaltyFeePercentage,
        uint256 royaltyFeeDenominator
    ) internal {
        uint256 feePercentage = royaltyFeePercentage != 0
            ? (royaltyFeePercentage * FXP_BASE) / royaltyFeeDenominator
            : 0;

        require(
            feePercentage <= maxRoyaltyFeePercentage,
            "Fee exceeds marketplace limit."
        );

        nftContractRoyalties[nftContract] = Royalties(
            feePercentage,
            feeReceiver
        );
    }

    function setPermittedERC20Address(
        address erc20Address,
        bool status
    ) external onlyOwner {
        permittedERC20Address[erc20Address] = status;
    }

    function claimETHRoyalties() external {
        _claimETHRoyalties(msg.sender);
    }

    function claimETHRoyaltiesAsAdmin(
        address royaltyReceiver
    ) external isAdmin {
        _claimETHRoyalties(royaltyReceiver);
    }

    function claimERC20Royalties(address erc20address) external {
        _claimERC20Royalties(msg.sender, erc20address);
    }

    function claimERC20RoyaltiesAsAdmin(
        address royaltyReceiver,
        address erc20address
    ) external isAdmin {
        _claimERC20Royalties(royaltyReceiver, erc20address);
    }

    function _claimETHRoyalties(address royaltyReceiver) internal nonReentrant {
        require(claimableETHRoyalties[royaltyReceiver] > 0, "No ETH to claim.");
        uint256 amountToClaim = claimableETHRoyalties[royaltyReceiver];
        claimableETHRoyalties[royaltyReceiver] = 0;

        (bool success, ) = payable(royaltyReceiver).call{value: amountToClaim}(
            ""
        );

        require(success, "Transfer failed");

        emit ETHRoyaltiesClaimed(royaltyReceiver, amountToClaim);
    }

    function _claimERC20Royalties(
        address royaltyReceiver,
        address erc20address
    ) internal nonReentrant {
        require(
            claimableERC20Royalties[royaltyReceiver][erc20address] > 0,
            "No ERC20 to claim."
        );
        uint256 amountToClaim = claimableERC20Royalties[royaltyReceiver][
            erc20address
        ];
        claimableERC20Royalties[royaltyReceiver][erc20address] = 0;

        IERC20(erc20address).transferFrom(
            address(this),
            royaltyReceiver,
            amountToClaim
        );

        emit ERC20RoyaltiesClaimed(
            royaltyReceiver,
            erc20address,
            amountToClaim
        );
    }

    // places an item for sale on the marketplace
    function createMarketplaceItem(
        address nftContract,
        uint256 tokenId,
        uint256 priceETH,
        uint256 priceERC20,
        address payableERC20
    ) external {
        _createMarketplaceItem(
            nftContract,
            tokenId,
            priceETH,
            priceERC20,
            payableERC20,
            msg.sender
        );
    }

    function createMarketplaceItemWithPermission(
        address nftContract,
        uint256 tokenId,
        uint256 priceETH,
        uint256 priceERC20,
        address payableERC20,
        address ownerAddress,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                nftContract,
                tokenId,
                priceETH,
                priceERC20,
                payableERC20,
                ownerAddress,
                nonce
            )
        );

        require(nonce == usedNonces[ownerAddress], "Invalid Nonce");

        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(prefixedHash, signature);

        require(signer == ownerAddress, "Invalid signature provided.");

        _createMarketplaceItem(
            nftContract,
            tokenId,
            priceETH,
            priceERC20,
            payableERC20,
            ownerAddress
        );

        usedNonces[ownerAddress]++;
    }

    function _createMarketplaceItem(
        address nftContract,
        uint256 tokenId,
        uint256 priceETH,
        uint256 priceERC20,
        address payableERC20,
        address ownerAddress
    ) internal {
        require(
            (priceETH > 0 && priceERC20 == 0) ||
                (priceERC20 > 0 && priceETH == 0),
            "Either priceETH or priceERC20 must be greater than 0, but not both"
        );

        require(
            permittedERC20Address[payableERC20] || payableERC20 == address(0),
            "Invalid ERC20 Token Address Provided"
        );

        uint256 itemId = _items;
        _items += 1;

        SaleMethod selectedSaleMethod = priceETH > 0
            ? SaleMethod.WITH_ETH
            : SaleMethod.WITH_ERC20;

        idToMarketplaceItem[itemId] = MarketplaceItem(
            itemId,
            nftContract,
            tokenId,
            ownerAddress,
            address(0),
            priceETH,
            priceERC20,
            payableERC20,
            Status.AVAILABLE,
            selectedSaleMethod
        );

        IERC721(nftContract).transferFrom(ownerAddress, address(this), tokenId);
        userListings[ownerAddress].push(itemId);

        emit MarketplaceItemCreated(
            itemId,
            nftContract,
            tokenId,
            ownerAddress,
            address(0),
            priceETH,
            priceERC20,
            payableERC20
        );
    }

    function getUserNftPrice(
        address userAddress,
        uint256 baseCost
    ) public view returns (uint256) {
        if (baseCost == 0) {
            return 0;
        }

        uint256 discountedServiceFee = getDiscountedServiceFee(
            baseCost,
            userAddress
        );
        return baseCost.add(discountedServiceFee);
    }

    function createMarketplaceSaleWithETH(
        uint256[] calldata itemIds
    ) external payable {
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < itemIds.length; i++) {
            totalPrice = totalPrice.add(
                getUserNftPrice(
                    msg.sender,
                    idToMarketplaceItem[itemIds[i]].priceETH
                )
            );
        }

        require(msg.value == totalPrice, "Insufficient amount provided.");

        for (uint256 i = 0; i < itemIds.length; i++) {
            require(
                idToMarketplaceItem[itemIds[i]].method == SaleMethod.WITH_ETH,
                "Item cannot be sold with ETH."
            );

            _handleFundDistribution(
                idToMarketplaceItem[itemIds[i]].priceETH,
                itemIds[i],
                msg.sender,
                SaleMethod.WITH_ETH
            );
            _createMarketplaceSale(itemIds[i], msg.sender);
        }
    }

    function createMarketplaceSaleWithERC20(
        uint256[] calldata itemIds
    ) external {
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < itemIds.length; i++) {
            require(
                canMoveMarketplaceItem(itemIds[i]),
                "Item already sold or returned."
            );
            totalPrice = totalPrice.add(
                getUserNftPrice(
                    msg.sender,
                    idToMarketplaceItem[itemIds[i]].priceERC20
                )
            );
        }

        for (uint256 i = 0; i < itemIds.length; i++) {
            require(
                idToMarketplaceItem[itemIds[i]].method == SaleMethod.WITH_ERC20,
                "Item cannot be sold with ERC20."
            );

            require(
                idToMarketplaceItem[itemIds[i]].payableERC20 != address(0) &&
                    idToMarketplaceItem[itemIds[i]].priceERC20 != 0,
                "ERC20 Sale not available."
            );

            _handleFundDistribution(
                idToMarketplaceItem[itemIds[i]].priceERC20,
                itemIds[i],
                msg.sender,
                SaleMethod.WITH_ERC20
            );
            _createMarketplaceSale(itemIds[i], msg.sender);
        }
    }

    function createMarketplaceOfferWithETH(
        uint256 itemId,
        uint256 amount,
        uint256 expiryTimestamp
    ) external payable {
        require(
            canMoveMarketplaceItem(itemId),
            "Item already sold or returned."
        );

        require(
            expiryTimestamp > block.timestamp,
            "Expiry time has already past."
        );

        uint256 requiredAmount = getUserNftPrice(msg.sender, amount);
        require(
            amount > 0 && msg.value == requiredAmount,
            "Insufficient ETH value."
        );
        require(
            idToMarketplaceItem[itemId].method == SaleMethod.WITH_ETH,
            "Sale Method not available"
        );

        MarketplaceItemOffer memory itemOffer = MarketplaceItemOffer(
            itemId,
            msg.sender,
            msg.value,
            requiredAmount,
            expiryTimestamp,
            Status.AVAILABLE,
            SaleMethod.WITH_ETH
        );

        itemOffers[itemId].push(itemOffer);
        userItemOffers[msg.sender].push(itemOffer);
    }

    function createMarketplaceOfferWithERC20(
        uint256 itemId,
        uint256 amount,
        uint256 expiryTimestamp
    ) external {
        require(
            canMoveMarketplaceItem(itemId),
            "Item already sold or returned."
        );

        require(
            expiryTimestamp > block.timestamp,
            "Expiry time has already past."
        );
        require(amount > 0, "ERC20 amount must be greater than 0.");
        require(
            idToMarketplaceItem[itemId].method == SaleMethod.WITH_ERC20,
            "Sale Method not available"
        );

        uint256 requiredAmount = getUserNftPrice(msg.sender, amount);
        IERC20(idToMarketplaceItem[itemId].payableERC20).transferFrom(
            msg.sender,
            address(this),
            requiredAmount
        );

        MarketplaceItemOffer memory itemOffer = MarketplaceItemOffer(
            itemId,
            msg.sender,
            amount,
            requiredAmount,
            expiryTimestamp,
            Status.AVAILABLE,
            SaleMethod.WITH_ERC20
        );

        itemOffers[itemId].push(itemOffer);
        userItemOffers[msg.sender].push(itemOffer);
    }

    function createMarketplaceCollectionOfferWithETH(
        address nftContract,
        uint256 amount,
        uint256 expiryTimestamp
    ) external payable {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry time has already past."
        );

        uint256 requiredAmount = getUserNftPrice(msg.sender, amount);
        require(
            amount > 0 && msg.value == requiredAmount,
            "Insufficient ETH value."
        );

        MarketplaceCollectionOffer
            memory collectionOffer = MarketplaceCollectionOffer(
                0,
                nftContract,
                msg.sender,
                amount,
                requiredAmount,
                expiryTimestamp,
                Status.AVAILABLE,
                SaleMethod.WITH_ETH
            );

        collectionOffers[nftContract].push(collectionOffer);
        userCollectionOffers[msg.sender].push(collectionOffer);
    }

    function acceptMarketplaceItemOffer(
        uint256 itemId,
        uint256 offerId
    ) external {
        require(
            canMoveMarketplaceItem(itemId),
            "Item already sold or returned."
        );
        require(
            msg.sender == idToMarketplaceItem[itemId].seller,
            "Caller is not seller of item."
        );

        require(
            itemOffers[itemId][offerId].status == Status.AVAILABLE &&
                itemOffers[itemId][offerId].expiryTimestamp > block.timestamp,
            "Offer no longer available."
        );

        itemOffers[itemId][offerId].status = Status.SOLD;

        _handleFundDistribution(
            itemOffers[itemId][offerId].offerAmount,
            itemId,
            itemOffers[itemId][offerId].offerer,
            itemOffers[itemId][offerId].method
        );
        _createMarketplaceSale(itemId, itemOffers[itemId][offerId].offerer);
    }

    function acceptMarketplaceCollectionOffer(
        uint256 itemId,
        uint256 offerId
    ) external {
        require(
            canMoveMarketplaceItem(itemId),
            "Item already sold or returned."
        );
        require(
            msg.sender == idToMarketplaceItem[itemId].seller,
            "Caller is not seller of item."
        );

        require(
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .status ==
                Status.AVAILABLE &&
                collectionOffers[idToMarketplaceItem[itemId].nftContract][
                    offerId
                ].expiryTimestamp >
                block.timestamp,
            "Offer no longer available."
        );

        collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
            .status = Status.SOLD;

        _handleFundDistribution(
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .offerAmount,
            itemId,
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .offerer,
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .method
        );
        _createMarketplaceSale(
            itemId,
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .offerer
        );
    }

    function refundMarketplaceCollectionOffer(
        uint256 itemId,
        uint256 offerId
    ) external {
        require(
            canMoveMarketplaceItem(itemId),
            "Item already sold or returned."
        );

        require(
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .status == Status.AVAILABLE,
            "Offer no longer available."
        );
        require(
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .offerer == msg.sender,
            "Caller is not creator of offer."
        );

        collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
            .status = Status.RETURNED;

        if (
            collectionOffers[idToMarketplaceItem[itemId].nftContract][offerId]
                .method == SaleMethod.WITH_ETH
        ) {
            (bool success, ) = payable(
                collectionOffers[idToMarketplaceItem[itemId].nftContract][
                    offerId
                ].offerer
            ).call{
                value: collectionOffers[
                    idToMarketplaceItem[itemId].nftContract
                ][offerId].paidAmount
            }("");

            require(success, "Transfer failed");
        }
    }

    function refundMarketplaceItemOffer(
        uint256 itemId,
        uint256 offerId
    ) external {
        require(
            canMoveMarketplaceItem(itemId),
            "Item already sold or returned."
        );

        require(
            itemOffers[itemId][offerId].status == Status.AVAILABLE,
            "Offer no longer available."
        );
        require(
            itemOffers[itemId][offerId].offerer == msg.sender,
            "Caller is not creator of offer."
        );

        itemOffers[itemId][offerId].status = Status.RETURNED;

        if (itemOffers[itemId][offerId].method == SaleMethod.WITH_ETH) {
            (bool success, ) = payable(itemOffers[itemId][offerId].offerer)
                .call{value: itemOffers[itemId][offerId].paidAmount}("");

            require(success, "Transfer failed");
        } else {
            IERC20(idToMarketplaceItem[itemId].payableERC20).transferFrom(
                address(this),
                itemOffers[itemId][offerId].offerer,
                itemOffers[itemId][offerId].paidAmount
            );
        }
    }

    function refundMarketplaceItems(uint256[] calldata itemIds) external {
        for (uint256 i = 0; i < itemIds.length; i++) {
            require(
                canMoveMarketplaceItem(itemIds[i]),
                "Item already sold or returned."
            );

            require(
                msg.sender == idToMarketplaceItem[itemIds[i]].seller ||
                    msg.sender == owner(),
                "Caller is not seller."
            );

            idToMarketplaceItem[itemIds[i]].status = Status.RETURNED;
            IERC721(idToMarketplaceItem[itemIds[i]].nftContract).transferFrom(
                address(this),
                idToMarketplaceItem[itemIds[i]].seller,
                idToMarketplaceItem[itemIds[i]].tokenId
            );
        }
    }

    function _createMarketplaceSale(
        uint256 itemId,
        address ownerAddress
    ) internal {
        IERC721(idToMarketplaceItem[itemId].nftContract).transferFrom(
            address(this),
            ownerAddress,
            idToMarketplaceItem[itemId].tokenId
        );

        idToMarketplaceItem[itemId].owner = ownerAddress;
        idToMarketplaceItem[itemId].status = Status.SOLD;
    }

    function _handleFundDistribution(
        uint256 amount,
        uint256 itemId,
        address ownerAddress,
        SaleMethod method
    ) internal {
        uint256 creatorAllocation = getRoyaltyAllocation(amount, itemId);
        uint256 serviceAllocation = getDiscountedServiceFee(
            amount,
            ownerAddress
        );

        if (creatorAllocation > 0) {
            address royaltyReceiver = nftContractRoyalties[
                idToMarketplaceItem[itemId].nftContract
            ].royaltyReceiver;

            if (method == SaleMethod.WITH_ETH) {
                claimableETHRoyalties[royaltyReceiver] = claimableETHRoyalties[
                    royaltyReceiver
                ].add(creatorAllocation);
            } else {
                claimableERC20Royalties[royaltyReceiver][
                    idToMarketplaceItem[itemId].payableERC20
                ] = claimableERC20Royalties[royaltyReceiver][
                    idToMarketplaceItem[itemId].payableERC20
                ].add(creatorAllocation);
            }
        }

        if (serviceAllocation > 0) {
            if (method == SaleMethod.WITH_ETH) {
                claimableETHRoyalties[owner()] = claimableETHRoyalties[owner()]
                    .add(serviceAllocation);
            } else {
                claimableERC20Royalties[owner()][
                    idToMarketplaceItem[itemId].payableERC20
                ] = claimableERC20Royalties[owner()][
                    idToMarketplaceItem[itemId].payableERC20
                ].add(serviceAllocation);
            }
        }

        uint256 sellerAllocation = amount.sub(creatorAllocation);

        if (method == SaleMethod.WITH_ETH) {
            (bool success, ) = payable(idToMarketplaceItem[itemId].seller).call{
                value: sellerAllocation
            }("");

            require(success, "Transfer failed");
        } else {
            IERC20(idToMarketplaceItem[itemId].payableERC20).transferFrom(
                ownerAddress,
                address(this),
                amount
            );

            IERC20(idToMarketplaceItem[itemId].payableERC20).transfer(
                idToMarketplaceItem[itemId].seller,
                sellerAllocation
            );
        }
    }

    function getMarketplaceItemOffers(
        uint256 itemId,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (MarketplaceItemOffer[] memory) {
        if (startIndex == 0 && endIndex == 0) {
            return itemOffers[itemId];
        } else {
            MarketplaceItemOffer[]
                memory offersInRange = new MarketplaceItemOffer[](
                    endIndex - startIndex + 1
                );
            uint256 index = 0;
            for (uint256 i = startIndex; i <= endIndex; i++) {
                offersInRange[index] = itemOffers[itemId][i];
                index++;
            }
            return offersInRange;
        }
    }

    function getMarketplaceCollectionOffers(
        address nftContractAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (MarketplaceCollectionOffer[] memory) {
        if (startIndex == 0 && endIndex == 0) {
            return collectionOffers[nftContractAddress];
        } else {
            MarketplaceCollectionOffer[]
                memory offersInRange = new MarketplaceCollectionOffer[](
                    endIndex - startIndex + 1
                );
            uint256 index = 0;
            for (uint256 i = startIndex; i <= endIndex; i++) {
                offersInRange[index] = collectionOffers[nftContractAddress][i];
                index++;
            }
            return offersInRange;
        }
    }

    function getUserMarketplaceItemOffers(
        address userAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (MarketplaceItemOffer[] memory) {
        if (startIndex == 0 && endIndex == 0) {
            return userItemOffers[userAddress];
        } else {
            MarketplaceItemOffer[]
                memory offersInRange = new MarketplaceItemOffer[](
                    endIndex - startIndex + 1
                );
            uint256 index = 0;
            for (uint256 i = startIndex; i <= endIndex; i++) {
                offersInRange[index] = userItemOffers[userAddress][i];
                index++;
            }
            return offersInRange;
        }
    }

    function getUserMarketplaceCollectionOffers(
        address userAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (MarketplaceCollectionOffer[] memory) {
        if (startIndex == 0 && endIndex == 0) {
            return userCollectionOffers[userAddress];
        } else {
            MarketplaceCollectionOffer[]
                memory offersInRange = new MarketplaceCollectionOffer[](
                    endIndex - startIndex + 1
                );
            uint256 index = 0;
            for (uint256 i = startIndex; i <= endIndex; i++) {
                offersInRange[index] = userCollectionOffers[userAddress][i];
                index++;
            }
            return offersInRange;
        }
    }

    function getMarketplaceItemCount() external view returns (uint256) {
        return _items;
    }

    function getRoyaltyAllocation(
        uint256 amount,
        uint256 itemId
    ) public view returns (uint256) {
        return
            nftContractRoyalties[idToMarketplaceItem[itemId].nftContract]
                .royaltyPercentage != 0
                ? amount
                    .mul(
                        nftContractRoyalties[
                            idToMarketplaceItem[itemId].nftContract
                        ].royaltyPercentage
                    )
                    .div(FXP_BASE)
                : 0;
    }

    function getDiscountedServiceFee(
        uint256 amount,
        address userAddress
    ) public view returns (uint256) {
        uint256 serviceFee = serviceFeePercentage != 0
            ? amount.mul(serviceFeePercentage).div(FXP_BASE)
            : 0;

        uint256 _nftBalance = IERC721(discountNftAddress).balanceOf(
            userAddress
        );

        if (_nftBalance != 0 && serviceFee != 0) {
            uint256 _discountAmount = serviceFee
                .mul(discountNftPercentage)
                .div(FXP_BASE)
                .mul(_nftBalance);

            uint256 _maxDiscountAmount = serviceFee
                .mul(maxDiscountNftPercentage)
                .div(FXP_BASE);

            if (_discountAmount > _maxDiscountAmount) {
                _discountAmount = _maxDiscountAmount;
            }

            return serviceFee.sub(_discountAmount);
        }

        return serviceFee;
    }

    function getMarketplaceItems(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (MarketplaceItem[] memory) {
        uint256 currentIndex = 0;
        uint256 totalSize = endIndex.sub(startIndex);

        MarketplaceItem[] memory items = new MarketplaceItem[](totalSize);

        for (uint256 i = startIndex; i < endIndex; i++) {
            MarketplaceItem storage currentItem = idToMarketplaceItem[i];
            items[currentIndex++] = currentItem;
        }
        return items;
    }

    function getMarketplaceItem(
        uint256 index
    ) external view returns (MarketplaceItem memory) {
        return idToMarketplaceItem[index];
    }

    function getUserListings(
        address userAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (MarketplaceItem[] memory) {
        uint256 numListings = userListings[userAddress].length;
        if (startIndex == 0 && endIndex == 0) {
            startIndex = 1;
            endIndex = numListings;
        }
        require(endIndex <= numListings, "End index out of range");
        MarketplaceItem[] memory items = new MarketplaceItem[](
            endIndex - startIndex + 1
        );
        uint256 index = 0;
        for (uint256 i = startIndex - 1; i < endIndex; i++) {
            items[index] = idToMarketplaceItem[userListings[userAddress][i]];
            index++;
        }
        return items;
    }

    receive() external payable {}
}