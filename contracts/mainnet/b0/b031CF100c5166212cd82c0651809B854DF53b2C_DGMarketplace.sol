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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Events.sol";
import "./DGMarketplaceConfig.sol";
import "./OrderManagement.sol";
import "./helpers/IDCL721.sol";
import "./helpers/IERC2981.sol";
import "./helpers/EIP712MetaTransactionUpgradeable.sol";

// File contracts/DGMarketplace.sol

contract DGMarketplace is
    DGMarketplaceConfig,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712MetaTransactionUpgradeable,
    IDGMarketplaceEvents,
    OrderManagement
{
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712Base_init("DGMarketplace", "v1.0");
        feeOwner = msgSender();
        fee = 50000;
        tipsFee = 0;

        adminWallet = 0x355A93EE3781CCF6084C86DAD7921e5e731ad519;
        paperKeyManager = IPaperKeyManager(
            0x43Ca8B5b235A0f607259C8fEACd15f9f06f91878
        );

        router = Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        ICE_token = IERC20(0xc6C855AD634dCDAd23e64DA71Ba85b8C51E5aD7c);
        USDC_token = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    // Controller methods
    function sell(
        address _nftAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices
    ) external nonReentrant {
        address sender = msgSender();
        require(
            _tokenIds.length == _prices.length,
            "DGMarketplace#sell: LENGTH_MISMATCH"
        );
        require(_tokenIds.length < 50, "DGMarketplace#sell: LENGTH_TOO_HIGH");

        (
            bool supportsInterfaceSuccess,
            bytes memory supportsInterfaceResult
        ) = _nftAddress.staticcall(
                abi.encodeWithSelector(SUPPORTS_INTERFACE_SELECTOR, 0x80ac58cd)
            );
        require(
            supportsInterfaceSuccess &&
                abi.decode(supportsInterfaceResult, (bool)),
            "NOT_ERC721"
        );

        (
            bool isApprovedForAllSuccess,
            bytes memory isApprovedForAllResult
        ) = _nftAddress.staticcall(
                abi.encodeWithSelector(
                    IS_APPROVED_FOR_ALL_SELECTOR,
                    sender,
                    address(this)
                )
            );
        require(
            isApprovedForAllSuccess &&
                abi.decode(isApprovedForAllResult, (bool)),
            "Token not approved"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (bool ownerOfSuccess, bytes memory ownerOfResult) = _nftAddress
                .staticcall(
                    abi.encodeWithSelector(OWNER_OF_SELECTOR, _tokenIds[i])
                );

            if (ownerOfSuccess) {
                address actualOwner = abi.decode(ownerOfResult, (address));
                require(actualOwner == sender, "Not the owner of NFTs");
            } else {
                revert("Failed to call ownerOf");
            }

            createOrder(_nftAddress, _tokenIds[i], _prices[i], sender);
        }

        emit Sell(_nftAddress, sender, _tokenIds, _prices);
    }

    function cancel(
        address _nftAddress,
        uint256[] calldata _tokenIds
    ) external nonReentrant {
        address sender = msgSender();
        require(_tokenIds.length < 50, "DGMarketplace#cancel: LENGTH_TOO_HIGH");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (bool ownerOfSuccess, bytes memory ownerOfResult) = _nftAddress
                .staticcall(
                    abi.encodeWithSelector(OWNER_OF_SELECTOR, _tokenIds[i])
                );
            require(ownerOfSuccess, "Failed to call ownerOf");
            address actualOwner = abi.decode(ownerOfResult, (address));
            require(actualOwner == sender, "Not the owner of NFTs");

            cancelOrder(_nftAddress, _tokenIds[i]);
        }
        emit Cancel(_nftAddress, sender, _tokenIds);
    }

    function buy(
        address _nftAddress,
        uint256[] calldata _tokenIds
    ) public nonReentrant {
        address buyer = msgSender();
        address[] memory beneficiaries = new address[](_tokenIds.length);
        require(_tokenIds.length < 50, "DGMarketplace#sell: LENGTH_TOO_HIGH");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            processPurchase(_nftAddress, _tokenIds[i], buyer, buyer);
            beneficiaries[i] = getOrderBeneficiary(_nftAddress, _tokenIds[i]);
        }
        // In the future, this could also be an array of nft addresses with an array of token Ids
        emit Buy(_nftAddress, _tokenIds, buyer, beneficiaries);
    }

    function paperCallback(
        uint256 paymentId,
        address _transferTo,
        address _nftAddress,
        uint256 _tokenId,
        bytes32 _nonce,
        bytes calldata _signature
    )
        external
        payable
        nonReentrant
        onlyPaper(
            keccak256(
                abi.encode(paymentId, _transferTo, _nftAddress, _tokenId)
            ),
            _nonce,
            _signature
        )
    {
        Order memory order = getOrder(_nftAddress, _tokenId);

        USDC_token.transferFrom(
            msg.sender,
            address(this),
            USDC_token.allowance(msg.sender, address(this))
        );

        swapUSDCToIce(USDC_token.balanceOf(address(this)), address(this));

        require(
            order.active == true,
            "DGMarketplace#PaperCallBack: COLLECTION_UNAVAILABLE"
        );

        require(
            ICE_token.balanceOf(address(this)) >= order.price,
            "DGMarketplace#PaperCallBack: ICE amount is lower than price to pay"
        );

        processPurchase(_nftAddress, _tokenId, address(this), _transferTo);

        emit PaperPurchase(
            paymentId,
            _transferTo,
            _nftAddress,
            _tokenId,
            order.beneficiary
        );
    }

    function buyForGift(
        address _nftAddress,
        uint256[] calldata _tokenIds,
        address _transferTo
    ) public nonReentrant {
        address buyer = msgSender();
        address[] memory beneficiaries = new address[](_tokenIds.length);

        require(_tokenIds.length < 50, "DGMarketplace#sell: LENGTH_TOO_HIGH");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            processPurchase(_nftAddress, _tokenIds[i], buyer, _transferTo);
            beneficiaries[i] = getOrderBeneficiary(_nftAddress, _tokenIds[i]);
        }
        emit BuyForGift(
            _nftAddress,
            _tokenIds,
            buyer,
            _transferTo,
            beneficiaries
        );
    }

    function tipToken(address _to, uint256 _amount) public {
        require(_amount > 0, "Amount should be > 0");

        uint256 saleShareAmount = 0;

        if (tipsFee > 0) {
            // Calculate sale share
            saleShareAmount = (_amount * tipsFee) / 1000000;

            // Transfer share amount for marketplace Owner
            require(
                ICE_token.transferFrom(_msgSender(), feeOwner, saleShareAmount),
                "Transfer cut failed"
            );
        }

        // Transfer sale amount to seller
        require(
            ICE_token.transferFrom(
                _msgSender(),
                _to,
                _amount - saleShareAmount
            ),
            "Transfer tip failed"
        );

        emit TippedToken(_to, _msgSender(), _amount, saleShareAmount);
    }

    // Internal functions
    function processPurchase(
        address _nftAddress,
        uint256 _tokenId,
        address _buyer,
        address _recipient
    ) internal {
        Order memory order;

        uint256 saleFee;
        address royaltyBeneficiary;
        uint256 royaltyFee = 0;

        order = getOrder(_nftAddress, _tokenId);

        require(
            order.active = true,
            "DGMarketplace#buy: COLLECTION_UNAVAILABLE"
        );
        require(
            order.beneficiary == IERC721(_nftAddress).ownerOf(_tokenId),
            "Current owner doesnt match seller"
        );

        saleFee = (order.price * fee) / BASE_FEE;

        (
            bool supportsInterfaceSuccess,
            bytes memory supportsInterfaceResult
        ) = _nftAddress.staticcall(
                abi.encodeWithSelector(
                    SUPPORTS_INTERFACE_SELECTOR,
                    ROYALTY_INTERFACE_ID
                )
            );
        bool supportsRoyaltyInterface = supportsInterfaceSuccess &&
            abi.decode(supportsInterfaceResult, (bool));

        if (supportsRoyaltyInterface) {
            (
                bool royaltyInfoSuccess,
                bytes memory royaltyInfoResult
            ) = _nftAddress.staticcall(
                    abi.encodeWithSelector(
                        ROYALTY_INFO_SELECTOR,
                        _tokenId,
                        order.price
                    )
                );
            require(royaltyInfoSuccess, "Failed to call royaltyInfo");
            (royaltyBeneficiary, royaltyFee) = abi.decode(
                royaltyInfoResult,
                (address, uint256)
            );
        } else {
            (bool creatorSuccess, bytes memory creatorResult) = _nftAddress
                .staticcall(abi.encodeWithSelector(CREATOR_SELECTOR));
            if (creatorSuccess) {
                royaltyBeneficiary = abi.decode(creatorResult, (address));
                royaltyFee = ((order.price - saleFee) * 25000) / BASE_FEE;
            }
        }

        if (royaltyFee > 0) {
            require(
                ICE_token.transferFrom(_buyer, royaltyBeneficiary, royaltyFee),
                "DGMarketplace#buy: TRANSFER_ROYALTY_FAILED"
            );
        }
        require(
            ICE_token.transferFrom(
                _buyer,
                order.beneficiary,
                order.price - saleFee - royaltyFee
            ),
            "DGMarketplace#buy: TRANSFER_PRICE_FAILED"
        );
        require(
            ICE_token.transferFrom(_buyer, feeOwner, saleFee),
            "DGMarketplace#buy: TRANSFER_FEES_FAILED"
        );

        deactivateOrder(_nftAddress, _tokenId);

        IERC721(_nftAddress).safeTransferFrom(
            order.beneficiary,
            _recipient,
            _tokenId
        );
    }

    function swapUSDCToIce(uint amount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(USDC_token);
        path[1] = address(ICE_token);

        USDC_token.approve(address(router), amount);

        router.swapExactTokensForTokens(amount, 0, path, to, block.timestamp);
    }

    // Getters & Setters

    function getPrice(
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (uint256) {
        Order memory order = getOrder(_nftAddress, _tokenId);
        return order.price;
    }

    function isActive(
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (bool) {
        Order memory order = getOrder(_nftAddress, _tokenId);

        return (order.beneficiary == IERC721(_nftAddress).ownerOf(_tokenId) &&
            order.active == true &&
            IERC721(_nftAddress).isApprovedForAll(
                IERC721(_nftAddress).ownerOf(_tokenId),
                address(this)
            ));
    }

    function registerPaperKey(address _paperKey) external {
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );
        require(paperKeyManager.register(_paperKey), "Error registering key");
    }

    function setFee(uint32 _newFee) public {
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );
        require(
            _newFee < BASE_FEE,
            "DGMarketplace#setFee: FEE_SHOULD_BE_LOWER_THAN_BASE_FEE"
        );
        require(_newFee != fee, "DGMarketplace#setFee: SAME_FEE");

        emit SetFee(fee, _newFee);
        fee = _newFee;
    }

    function setAdminWallet(address _adminWallet) public {
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );

        adminWallet = _adminWallet;
    }

    function setFeeOwner(address _newFeeOwner) external {
        require(
            _newFeeOwner != address(0),
            "DGMarketplace#setFeeOwner: INVALID_ADDRESS"
        );
        require(
            _newFeeOwner != feeOwner,
            "DGMarketplace#setFeeOwner: SAME_FEE_OWNER"
        );
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );
        feeOwner = _newFeeOwner;
        emit SetFeeOwner(feeOwner, _newFeeOwner);
    }

    function setFeeTips(uint256 _newFee) external {
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );
        require(
            _newFee < 1000000,
            "The owner cut should be between 0 and 999,999"
        );

        tipsFee = _newFee;
        emit SetFeeTips(_newFee);
    }

    // Withdrawables
    function withdrawAll() public payable {
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );

        (bool sent, bytes memory data) = msg.sender.call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    function withdrawERC20(address _token, uint256 _amount) external {
        require(
            msgSender() == adminWallet,
            "DGMarketplace#cancel: FAILED_UNAUTHORIZED"
        );
        IERC20(_token).transfer(feeOwner, _amount);
    }

    // Payable
    fallback() external payable {}

    receive() external payable {}
}

// File: contracts/DGMarketplaceConfig.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/Router.sol";
import "./helpers/IPaperKeyManager.sol";

contract DGMarketplaceConfig is Initializable {
    uint32 public constant BASE_FEE = 1000000;
    uint32 public fee;
    address public feeOwner;

    address public adminWallet;

    uint256 public tipsFee;

    Router public router;
    IERC20 public USDC_token;
    IERC20 public ICE_token;

    IPaperKeyManager public paperKeyManager;

    bytes4 constant ROYALTY_INTERFACE_ID = 0x2a55205a;

    bytes4 constant OWNER_OF_SELECTOR =
        bytes4(keccak256(bytes("ownerOf(uint256)")));
    bytes4 constant SUPPORTS_INTERFACE_SELECTOR =
        bytes4(keccak256(bytes("supportsInterface(bytes4)")));
    bytes4 constant IS_APPROVED_FOR_ALL_SELECTOR =
        bytes4(keccak256(bytes("isApprovedForAll(address,address)")));
    bytes4 constant ROYALTY_INFO_SELECTOR =
        bytes4(keccak256("royaltyInfo(uint256,uint256)"));
    bytes4 constant CREATOR_SELECTOR = bytes4(keccak256("creator()"));

    function initializeConfig() internal initializer {
        feeOwner = msg.sender;
        fee = 50000;
        tipsFee = 0;

        adminWallet = 0x355A93EE3781CCF6084C86DAD7921e5e731ad519;
        paperKeyManager = IPaperKeyManager(
            0x43Ca8B5b235A0f607259C8fEACd15f9f06f91878
        );

        router = Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        ICE_token = IERC20(0xc6C855AD634dCDAd23e64DA71Ba85b8C51E5aD7c);
        USDC_token = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    modifier onlyPaper(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Failed to verify signature");
        _;
    }
}

pragma solidity ^0.8.0;

interface IDGMarketplaceEvents {
    event Sell(
        address _nftAddress,
        address _msgSender,
        uint256[] _tokenIds,
        uint256[] _prices
    );

    event Cancel(address _nftAddress, address _msgSender, uint256[] _tokenIds);

    event Buy(
        address _nftAddress,
        uint256[] _tokenIds,
        address _msgSender,
        address[] beneficiaries
    );
    event BuyForGift(
        address _nftAddress,
        uint256[] _tokenIds,
        address _msgSender,
        address _transferTo,
        address[] beneficiaries
    );
    event PaperPurchase(
        uint256 _paymentId,
        address _transferTo,
        address _nftAddress,
        uint256 _tokenId,
        address beneficiary
    );

    event SetPrice(
        address sender,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    );

    event SetFee(uint256 _oldFee, uint256 _newFee);
    event SetFeeOwner(
        address indexed _oldFeeOwner,
        address indexed _newFeeOwner
    );

    event SetFeeTips(uint256 _newFee);
    event TippedToken(
        address _to,
        address _from,
        uint256 _amount,
        uint256 _feeAmount
    );
}

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity ^0.8.7;

contract EIP712BaseUpgradeable is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    bytes32 internal domainSeperator;

    function __EIP712Base_init(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        __EIP712Base_init_unchained(name, version);
    }

    function __EIP712Base_init_unchained(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            )
        );
    }

    function getChainID() internal pure returns (uint256 id) {
        assembly {
            id := 1 // set to Goerli for now, Mainnet later
        }
    }

    function getDomainSeperator() private view returns (bytes32) {
        return domainSeperator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(
        bytes32 messageHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./EIP712BaseUpgradeable.sol";

abstract contract EIP712MetaTransactionUpgradeable is
    Initializable,
    EIP712BaseUpgradeable
{
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) internal nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function __EIP712MetaTransaction_init() internal onlyInitializing {}

    function __EIP712MetaTransaction_unchained() internal onlyInitializing {}

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        nonces[userAddress] = nonces[userAddress] + 1;

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");

        /*emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );*/

        return returnData;
    }

    function hashMetaTransaction(
        MetaTransaction memory metaTx
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer = ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );

        require(signer != address(0x0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function getNonce(address _user) external view returns (uint256 nonce) {
        nonce = nonces[_user];
    }
}

pragma solidity ^0.8.0;

interface IDCL721 {
    function creator() external view returns (address);
}

pragma solidity ^0.8.0;

interface IERC2981 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

pragma solidity ^0.8.4;

/// @title Paper Key Manager
/// @author Winston Yeo
/// @notice PaperKeyManager makes it easy for developers to restrict certain functions to Paper.
/// @dev Developers are in charge of registering the contract with the initial Paper key. Paper will then help you  automatically rotate and update your key in line with good security hygiene
interface IPaperKeyManager {
    /// @notice Registers a Paper Key to a contract
    /// @dev Registers the @param _paperKey with the caller of the function
    /// @param _paperKey The Paper key that is associated with the checkout. You should be able to find this in the response of the checkout API or on the checkout dashbaord.
    /// @return bool indicating if the @param _paperKey was successfully registered with the calling address
    function register(address _paperKey) external returns (bool);

    /// @notice Verifies if the given @param _data is from Paper and have not been used before
    /// @dev Called as the first line in your function or extracted in a modifier. Refer to the Documentation for more usage details.
    /// @param _hash The bytes32 encoding of the data passed into your function
    /// @param _nonce a random set of bytes Paper passes your function which you forward. This helps ensure that the @param _hash has not been used before.
    /// @param _signature used to verify that Paper was the one who sent the @param _hash
    /// @return bool indicating if the @param _hash was successfully verified
    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external returns (bool);
}

pragma solidity ^0.8.8;

contract Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {}
}

pragma solidity ^0.8.0;

contract OrderManagement {
    struct Order {
        bool active;
        uint256 price;
        address beneficiary;
    }

    mapping(address => mapping(uint256 => Order)) public orderbook;

    function createOrder(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        address _beneficiary
    ) internal {
        Order storage order = orderbook[_nftAddress][_tokenId];
        order.price = _price;
        order.beneficiary = _beneficiary;
        order.active = true;
    }

    function cancelOrder(address _nftAddress, uint256 _tokenId) internal {
        Order storage order = orderbook[_nftAddress][_tokenId];
        order.active = false;
    }

    function getOrder(
        address _nftAddress,
        uint256 _tokenId
    ) internal view returns (Order memory) {
        return orderbook[_nftAddress][_tokenId];
    }

    function deactivateOrder(address _nftAddress, uint256 _tokenId) internal {
        Order storage order = orderbook[_nftAddress][_tokenId];
        order.active = false;
    }

    function getOrderBeneficiary(
        address _nftAddress,
        uint256 _tokenId
    ) internal view returns (address) {
        Order storage order = orderbook[_nftAddress][_tokenId];
        return order.beneficiary;
    }
}