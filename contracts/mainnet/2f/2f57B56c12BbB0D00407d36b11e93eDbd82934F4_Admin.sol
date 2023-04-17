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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import './lib/Models.sol' as Models;

/**
 * @title Events Tokens Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/Event.sol
 */
interface IEvent is IERC721 {
    /// @dev for publishing new Events
    function safeMint(address to, string calldata uri) external returns (uint256);

    /// @dev for deleting Events
    function burn(uint256 eventId) external;

    // @dev for editing Event metadata
    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external;
}

/**
 * @title Ticket Marketplace Contract Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/TicketMarketplace.sol
 */
interface ITicketMarketplace {
    function modifyCreatorRoyaltyOnEvent(uint256 eventId, uint256 creatorRoyalty) external;

    function publishTicketsForOrganizer(
        uint256 eventId,
        address organizer,
        Models.NewAssetSaleInfo[] calldata tickets,
        Models.MembershipsInfo calldata memberships,
        address[] calldata transferAllowances
    ) external returns (uint256[] memory ticketIds);

    function deleteEvent(uint256 eventId) external;

    function changeEventOwnerInTicketsForEvent(uint256 eventId, address newOwner) external;

    function setAsk(
        uint256 ticketId,
        uint256 ticketPrice,
        uint256 amount,
        address erc20address,
        address ticketOwner,
        address[] memory transferAllowances
    ) external;

    function setTicketUriBatch(uint256[] memory ticketIds, string[] calldata newUris) external;

    function ticketCreator(uint256 ticketId) external view returns (address);

    function eventOfTicket(uint256 ticketId) external view returns (uint256);

    function offers(address seller, uint256 ticketId) external view returns (uint256, uint256);

    function tokenPaymentType(address owner, uint256 ticketId) external view returns (address);
}

/**
 * @title Ticket Tokens Interface
 * @dev See https://github.com/Fanz-events/contracts/blob/main/src/Tickets.sol
 */
interface ITicket is IERC1155 {
    /// @dev for publishing new Tickets
    function mintBatch(
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        string[] calldata uris,
        bytes memory data
    ) external;

    /// @dev for deleting Tickets
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    // @dev for editing Tickets metadata
    function setUri(uint256 tokenId, string calldata tokenURI) external;
}

/**
 * @title The Fanz's Admin
 * @dev The Fanz's Admin is a smart contract that allows you manage events and royalties.
 * @author The Fanz's Team. See https://fanz.events/
 * Features: create/delete events and tickets, buy and sell tickets, modify royalties.
 */
contract Admin is Initializable, OwnableUpgradeable, PausableUpgradeable {
    /* Storage */

    /// @dev Fanz's Royalty for primary sales
    uint16 public primaryMarketplaceRoyalty;

    /// @dev Fanz's Royalty for secondary sales
    uint16 public secondaryMarketplaceRoyalty;

    /// @dev Reference to Ticket (ERC1155) contract
    address public ticketMarketplaceAddress;

    /// @dev Reference to Event (ERC721) contract
    address public eventAddress;

    /// @dev ERC721 or ERC1155 Memberships allowed to claim tickets (ticketId => AllowedMemberships model)
    mapping(uint256 => Models.AllowedMemberships) private _membershipsAllowedForTicket;

    /// @dev Saves which events are paused (eventId => isPaused)
    mapping(uint256 => bool) public pausedEvents;

    // @dev Saves which addresses are collaborator of the event.
    mapping(uint256 => mapping(address => bool)) public collaborators;

    /// @dev Save ticket booking by user and from who is reserved
    mapping(uint256 => mapping(address => mapping(address => uint256))) public bookedTickets;

    /// @dev Reference to Ticket (ERC1155) contract
    address public ticketAddress;

    // @dev Fixed fees by erc20 address.
    mapping(address => uint256) public fixedFees;

    /// @dev Addresses allowed to book tickets by ticketId by seller
    mapping(uint256 => mapping(address => address[])) private _transferAllowances;

    /* Events */

    /// @dev Event emitted when a new event is created
    event EventCreated(uint256 indexed eventId, address organizer, string uri);

    /// @dev Event emitted when an event's URI is modified
    event EventEdited(uint256 indexed eventId, string newUri);

    /// @dev Event emitted when an event is deleted
    event EventDeleted(uint256 indexed eventId);

    /// @dev Event emitted when an event is paused
    event EventPaused(uint256 indexed eventId);

    /// @dev Event emitted when an event is unpaused
    event EventUnpaused(uint256 indexed eventId);

    /// @dev Event emmited when an event's ownership is transferred
    event EventOwnershipTransferred(uint256 indexed eventId, address newOwner);

    /// @dev Event emmited when a membership is linked to tickets
    event MembershipAssignedToTicket(uint256 indexed ticketId, address contractAddress, uint256[] ids);

    /// @dev Event emmited when a membership is removed from tickets
    event MembershipRemovedFromTicket(uint256 indexed ticketId, address contractAddress);

    /// @dev Event emmited when a membership token id is removed from tickets
    event MembershipTokenIdRemovedFromTicket(uint256 indexed ticketId, address contractAddress, uint256 tokenId);

    /// @dev Event emmited when the default primary marketplace royalty is modified
    event PrimaryMarketRoyaltyModified(uint256 newRoyalty);

    /// @dev Event emmited when the default secondary marketplace royalty is modified
    event SecondaryMarketRoyaltyModified(uint256 newRoyalty);

    /// @dev Event emmited when the primary marketplace royalty is modified on an event
    event PrimaryMarketRoyaltyModifiedOnEvent(uint256 indexed eventId, uint256 newRoyalty);

    /// @dev Event emmited when the secondary marketplace royalty is modified on an event
    event SecondaryMarketRoyaltyModifiedOnEvent(uint256 indexed eventId, uint256 newRoyalty);

    /// @dev Event emmited when the creator royalty is modified on an event
    event CreatorRoyaltyModifiedOnEvent(uint256 indexed eventId, uint256 newRoyalty);

    /// @dev Event emmited when a collaborator is added to an event
    event CollaboratorAdded(uint256 indexed eventId, address indexed collaborator);

    /// @dev Event emmited when a collaborator is removed from an event
    event CollaboratorRemoved(uint256 indexed eventId, address indexed collaborator);

    /// @dev Event emmited when is force to cancel metadata in graph
    event MetadataCancelation(uint256 indexed id, string entityType);

    /// @dev Event emmited when a ticket reservation is done
    event BookedTicket(uint256 indexed ticketId, address ticketOwner, address ticketBuyer, uint256 amount);

    /// @dev Event emitted when a booked ticket is transfered
    event BookedTicketTransfered(uint256 indexed ticketId, address ticketOwner, address ticketBuyer);

    /// @dev Event emitted when ticket booking is canceled
    event CancelTicketBooking(uint256 indexed ticketId, address ticketOwner, address ticketBuyer);

    /// @dev Event emitted when fixed fee for an erc20 address is setted
    event FixedFeeForERC20Setted(address indexed addr, uint256 indexed fee);

    /* Modifiers */

    /// @dev Verifies that the sender is either the marketplace's owner or the given event's creator.
    modifier onlyEventCreatorOrOwner(uint256 eventId) {
        require(IEvent(eventAddress).ownerOf(eventId) == msg.sender || this.owner() == msg.sender, 'Not allowed!');
        _;
    }

    /// @dev Verifies that the sender is either the marketplace's owner, the given event's creator or a collaborator.
    modifier onlyEventCreatorOrCollaboratorOrOwner(uint256 eventId) {
        require(
            IEvent(eventAddress).ownerOf(eventId) == msg.sender || collaborators[eventId][msg.sender] == true || this.owner() == msg.sender,
            'Not allowed!'
        );
        _;
    }

    /// @dev Verifies that the sender is either the given event's creator or a collaborator.
    modifier onlyEventCreatorOrCollaborator(uint256 eventId) {
        require(IEvent(eventAddress).ownerOf(eventId) == msg.sender || collaborators[eventId][msg.sender] == true, 'Not allowed!');
        _;
    }

    /// @dev Verifies that the sender is the given event's creator.
    modifier onlyEventCreator(uint256 eventId) {
        require(IEvent(eventAddress).ownerOf(eventId) == msg.sender, 'Only creator is allowed!');
        _;
    }

    /// @dev Verifies that the sender is the Event contract.
    modifier onlyEventContract() {
        require(eventAddress == msg.sender, 'Only Event contract is allowed!');
        _;
    }

    modifier onlyTicketMarketplace() {
        require(ticketMarketplaceAddress == msg.sender, 'Only marketplace is allowed!');
        _;
    }

    modifier hasTransferAllowance(uint256 ticketId, address ticketOwner) {
        bool isAllowed = ticketOwner == msg.sender;
        for (uint256 i = 0; i < _transferAllowances[ticketId][ticketOwner].length; i++) {
            isAllowed = isAllowed || _transferAllowances[ticketId][ticketOwner][i] == msg.sender;
        }
        require(isAllowed, 'Not allowed');
        _;
    }

    /* Initializer */

    /**
     *  @dev Initializer.
     *  @param _ticketMarketplaceAddress Address of the Ticket Marketplace contract
     *  @param _eventAddress Address of the Event contract
     */
    function initialize(
        address _ticketMarketplaceAddress,
        address _eventAddress,
        address _ticketAdresss,
        uint8 version
    ) external reinitializer(version) {
        require(msg.sender == owner() || version == 1, 'Only owner can reinitialize');
        if (version == 1) {
            primaryMarketplaceRoyalty = 1500; // Initially 15% for primary sales
            secondaryMarketplaceRoyalty = 750; // Initially 7.5% for secondary sales
        }

        ticketMarketplaceAddress = _ticketMarketplaceAddress;
        eventAddress = _eventAddress;
        ticketAddress = _ticketAdresss;

        if (version == 1) {
            __Ownable_init();
            __Pausable_init();
        }
    }

    /* External */

    /**
     *  @dev Creates a new event.
     *  @param organizer The owner of the event
     *  @param eventUri URI of the event containing event's metadata (IPFS)
     *  @param tickets Ticket's information (metadata's uri, amount to sell, price, etc.)
     */
    function createEvent(
        address organizer,
        string memory eventUri,
        Models.NewAssetSaleInfo[] calldata tickets,
        Models.MembershipsInfo calldata memberships,
        address[] calldata _collaborators
    ) external whenNotPaused returns (uint256) {
        uint256 eventId = IEvent(eventAddress).safeMint(organizer, eventUri);

        emit EventCreated(eventId, organizer, eventUri);
        for (uint256 i = 0; i < _collaborators.length; i++) {
            _addCollaborator(eventId, _collaborators[i]);
        }

        if (tickets.length > 0) {
            ITicketMarketplace(ticketMarketplaceAddress).publishTicketsForOrganizer(eventId, organizer, tickets, memberships, _collaborators);
        }

        return eventId;
    }

    /**
     *  @dev Modifies an event's URI.
     *  @param eventId The id of the event to be deleted
     *  @param newUri The new URI
     */
    function setEventUri(uint256 eventId, string calldata newUri) external whenNotPaused onlyEventCreatorOrCollaboratorOrOwner(eventId) {
        IEvent(eventAddress).setTokenURI(eventId, newUri);

        emit EventEdited(eventId, newUri);
    }

    /**
     *  @dev Modifies an event's URI.
     *  @param eventId The id of the event to be deleted
     *  @param newUri The new URI
     */
    function setEventUriAndTicketsUri(
        uint256 eventId,
        string calldata newUri,
        uint256[] calldata ticketIds,
        string[] calldata newTicketUris
    ) external whenNotPaused onlyEventCreatorOrCollaboratorOrOwner(eventId) {
        ITicketMarketplace(ticketMarketplaceAddress).setTicketUriBatch(ticketIds, newTicketUris);

        IEvent(eventAddress).setTokenURI(eventId, newUri);

        emit EventEdited(eventId, newUri);
    }

    /**
     *  @dev Pauses an event
     *  @param eventId The id of the event to be paused
     */
    function pauseEvent(uint256 eventId) external whenNotPaused onlyEventCreatorOrCollaborator(eventId) {
        pausedEvents[eventId] = true;

        emit EventPaused(eventId);
    }

    /**
     *  @dev UnPauses an event
     *  @param eventId The id of the event to be unpaused
     */
    function unpauseEvent(uint256 eventId) external whenNotPaused onlyEventCreatorOrCollaborator(eventId) {
        pausedEvents[eventId] = false;

        emit EventUnpaused(eventId);
    }

    /**
     *  @dev Assign memberships to tickets.
     *  @param ticketsIds The ids of the tickets to assign memberships to
     *  @param memberships The memberships contract's addresses to be assigned for each ticket
     */
    function assignMemberships(
        uint256[] calldata ticketsIds,
        address[][] calldata memberships,
        uint256[][][] calldata tokenIds
    ) external whenNotPaused {
        for (uint256 i = 0; i < ticketsIds.length; i++) {
            require(
                msg.sender == ticketMarketplaceAddress ||
                    msg.sender == ITicketMarketplace(ticketMarketplaceAddress).ticketCreator(ticketsIds[i]),
                'Only Marketplace or creator!'
            );
            for (uint256 j = 0; j < memberships[i].length; j++) {
                require(
                    ERC165Checker.supportsInterface(memberships[i][j], type(IERC1155).interfaceId) ||
                        ERC165Checker.supportsInterface(memberships[i][j], type(IERC721).interfaceId),
                    'Should be ERC721 or ERC1155!'
                );

                _membershipsAllowedForTicket[ticketsIds[i]].allowedByAddress[memberships[i][j]] = true;
                if (ERC165Checker.supportsInterface(memberships[i][j], type(IERC1155).interfaceId)) {
                    require(tokenIds[i][j].length > 0, 'ERC1155 requires tokenIds!');
                }
                for (uint256 k = 0; k < tokenIds[i][j].length; k++) {
                    _membershipsAllowedForTicket[ticketsIds[i]].tokenIdsAmountAllowedByAddress[memberships[i][j]]++;
                    _membershipsAllowedForTicket[ticketsIds[i]].allowedTokenIds[memberships[i][j]][tokenIds[i][j][k]] = true;
                }
                emit MembershipAssignedToTicket(ticketsIds[i], memberships[i][j], tokenIds[i][j]);
            }
        }
    }

    /**
     *  @dev Removes a membership for a given ticket.
     *  @param ticketId The id of ticket
     *  @param contractAddress The address of memberships contract to remove
     */
    function disallowMembershipForTicket(uint256 ticketId, address contractAddress) external {
        require(
            msg.sender == ticketMarketplaceAddress || msg.sender == ITicketMarketplace(ticketMarketplaceAddress).ticketCreator(ticketId),
            'Only Marketplace or creator!'
        );
        _membershipsAllowedForTicket[ticketId].allowedByAddress[contractAddress] = false;
        emit MembershipRemovedFromTicket(ticketId, contractAddress);
    }

    /**
     *  @dev Removes a membership for a given ticket.
     *  @param ticketId The id of ticket
     *  @param contractAddress The address of memberships contract to remove
     */
    function disallowMembershipTokenIdForTicket(
        uint256 ticketId,
        address contractAddress,
        uint256 tokenId
    ) external {
        require(
            msg.sender == ticketMarketplaceAddress || msg.sender == ITicketMarketplace(ticketMarketplaceAddress).ticketCreator(ticketId),
            'Only Marketplace or creator!'
        );
        if (_membershipsAllowedForTicket[ticketId].allowedTokenIds[contractAddress][tokenId] == true) {
            _membershipsAllowedForTicket[ticketId].tokenIdsAmountAllowedByAddress[contractAddress]--;
            _membershipsAllowedForTicket[ticketId].allowedTokenIds[contractAddress][tokenId] = false;
            emit MembershipTokenIdRemovedFromTicket(ticketId, contractAddress, tokenId);
        } else {
            revert('TokenId not allowed!');
        }
    }

    /**
     *  @dev Modifies the owner of a given event  to 'newOwner'
     *  This function can be called only by Event contract in case of an safeTransferFrom
     *  in order to syncronize events ownership in the Marketplace.
     *  @param eventId The id of the event whose owner will be modified
     *  @param newOwner The new owner of the event (will recieve future royalties)
     */
    function changeEventOwnership(uint256 eventId, address newOwner) external whenNotPaused onlyEventContract {
        ITicketMarketplace(ticketMarketplaceAddress).changeEventOwnerInTicketsForEvent(eventId, newOwner);
        emit EventOwnershipTransferred(eventId, newOwner);
    }

    /**
     *  @dev Deletes an event.
     *  @param eventId The id of the event to be deleted
     */
    function deleteEvent(uint256 eventId) external whenNotPaused onlyEventCreatorOrCollaboratorOrOwner(eventId) {
        ITicketMarketplace(ticketMarketplaceAddress).deleteEvent(eventId);

        IEvent(eventAddress).burn(eventId);

        emit EventDeleted(eventId);
    }

    /**
     *  @dev Modifies Primary Marketplace royalty for future events.
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifyPrimaryMarketplaceRoyalty(uint16 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        primaryMarketplaceRoyalty = newMarketplaceRoyalty;
        emit PrimaryMarketRoyaltyModified(newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies Secondary Marketplace royalty for future events.
     *  @param newMarketplaceRoyalty The new royalty to be setted
     */
    function modifySecondaryMarketplaceRoyalty(uint16 newMarketplaceRoyalty) external onlyOwner whenNotPaused {
        secondaryMarketplaceRoyalty = newMarketplaceRoyalty;
        emit SecondaryMarketRoyaltyModified(newMarketplaceRoyalty);
    }

    /**
     *  @dev Modifies creator's royalty for a given Event.
     *  @dev This function modifies the creator's royalty for all available tickets in the given event.
     *  @param eventId The id of the event whose royalty will be modified
     *  @param newCreatorRoyalty The new royalty to be setted
     */
    function modifyCreatorRoyaltyOnEvent(uint256 eventId, uint256 newCreatorRoyalty) external onlyEventCreator(eventId) whenNotPaused {
        ITicketMarketplace(ticketMarketplaceAddress).modifyCreatorRoyaltyOnEvent(eventId, newCreatorRoyalty);

        emit CreatorRoyaltyModifiedOnEvent(eventId, newCreatorRoyalty);
    }

    /**
     *  @dev Returns true if a membership is allowed for a given ticket.
     */
    function isMembershipAllowedForTicket(uint256 ticketId, address contractAddress) external view returns (bool) {
        return _membershipsAllowedForTicket[ticketId].allowedByAddress[contractAddress];
    }

    /**
     *  @dev Returns true if a membership token id is allowed for a given ticket.
     */
    function isTokenIdAllowedForTicket(
        uint256 ticketId,
        address contractAddress,
        uint256 tokenId
    ) external view returns (bool) {
        return
            _membershipsAllowedForTicket[ticketId].allowedByAddress[contractAddress] &&
            (_membershipsAllowedForTicket[ticketId].tokenIdsAmountAllowedByAddress[contractAddress] == 0 ||
                _membershipsAllowedForTicket[ticketId].allowedTokenIds[contractAddress][tokenId]);
    }

    /**
     *  @dev Returns true if a membership token id is needed for a given ticket.
     */
    function isTokenIdNeededForTicket(uint256 ticketId, address contractAddress) external view returns (bool) {
        return _membershipsAllowedForTicket[ticketId].tokenIdsAmountAllowedByAddress[contractAddress] > 0;
    }

    /**
     *  @dev Force to change indexStatus in graph for specified ticket o event
     */
    function forceMetadataCancelation(string calldata entityType, uint256 id) external {
        require(
            keccak256(abi.encodePacked(entityType)) == keccak256('TICKET') || keccak256(abi.encodePacked(entityType)) == keccak256('EVENT'),
            'Invalid item type'
        );

        uint256 eventId = id;
        if (keccak256(abi.encodePacked(entityType)) == keccak256('TICKET')) {
            eventId = ITicketMarketplace(ticketMarketplaceAddress).eventOfTicket(id);
        }

        require(
            IEvent(eventAddress).ownerOf(eventId) == msg.sender || collaborators[eventId][msg.sender] == true || this.owner() == msg.sender,
            'Not allowed!'
        );

        emit MetadataCancelation(id, entityType);
    }

    /**
     * @dev Function to book ticket for certain user selled from a specific owner.
     * @param ticketId ticketId to be booked.
     * @param ticketOwner address that will sell the ticket
     * @param ticketBuyer address that will buy the ticket
     * @param amount amount that will be used
     */
    function bookTicket(
        uint256 ticketId,
        address ticketOwner,
        address ticketBuyer,
        uint256 amount
    ) external whenNotPaused hasTransferAllowance(ticketId, ticketOwner) {
        require(pausedEvents[ITicketMarketplace(ticketMarketplaceAddress).eventOfTicket(ticketId)] == false, 'Event is paused.');
        require(ticketOwner != ticketBuyer, 'Ticket buyer must be different');

        (uint256 ticketOfferedAmount, uint256 ticketPrice) = ITicketMarketplace(ticketMarketplaceAddress).offers(ticketOwner, ticketId);
        address ticketTokenPaymentType = ITicketMarketplace(ticketMarketplaceAddress).tokenPaymentType(ticketOwner, ticketId);

        require(ticketOfferedAmount >= amount, 'Not enoguh tickets');
        require(ticketPrice > 0, 'Free tickets cant be booked');
        require(amount > 0, 'Amount must be bigger than 0');
        require(bookedTickets[ticketId][ticketOwner][ticketBuyer] == 0, 'Have booked tickets');

        address[] memory allowances = _transferAllowances[ticketId][ticketOwner];

        ITicketMarketplace(ticketMarketplaceAddress).setAsk(
            ticketId,
            ticketPrice,
            ticketOfferedAmount - amount,
            ticketTokenPaymentType,
            ticketOwner,
            allowances
        );

        ITicket(ticketAddress).safeTransferFrom(ticketOwner, address(owner()), ticketId, amount, '');

        bookedTickets[ticketId][ticketOwner][ticketBuyer] = amount;

        emit BookedTicket(ticketId, ticketOwner, ticketBuyer, amount);
    }

    function transferBookedTicket(
        uint256 ticketId,
        address ticketOwner,
        address ticketBuyer
    ) external whenNotPaused hasTransferAllowance(ticketId, ticketOwner) {
        require(pausedEvents[ITicketMarketplace(ticketMarketplaceAddress).eventOfTicket(ticketId)] == false, 'Event is paused.');

        require(bookedTickets[ticketId][ticketOwner][ticketBuyer] > 0, 'Booking info does not apply');

        uint256 amount = bookedTickets[ticketId][ticketOwner][ticketBuyer];
        bookedTickets[ticketId][ticketOwner][ticketBuyer] = 0;

        ITicket(ticketAddress).safeTransferFrom(address(owner()), ticketBuyer, ticketId, amount, '');

        emit BookedTicketTransfered(ticketId, ticketOwner, ticketBuyer);
    }

    function cancelTicketBooking(
        uint256 ticketId,
        address ticketOwner,
        address ticketBuyer
    ) external whenNotPaused hasTransferAllowance(ticketId, ticketOwner) {
        require(pausedEvents[ITicketMarketplace(ticketMarketplaceAddress).eventOfTicket(ticketId)] == false, 'Event is paused.');
        require(bookedTickets[ticketId][ticketOwner][ticketBuyer] > 0, 'Booking info does not apply');

        (uint256 ticketOfferedAmount, uint256 ticketPrice) = ITicketMarketplace(ticketMarketplaceAddress).offers(ticketOwner, ticketId);
        address ticketTokenPaymentType = ITicketMarketplace(ticketMarketplaceAddress).tokenPaymentType(ticketOwner, ticketId);

        uint256 amount = bookedTickets[ticketId][ticketOwner][ticketBuyer];
        bookedTickets[ticketId][ticketOwner][ticketBuyer] = 0;

        address[] memory allowances = _transferAllowances[ticketId][ticketOwner];

        ITicket(ticketAddress).safeTransferFrom(address(owner()), ticketOwner, ticketId, amount, '');

        ITicketMarketplace(ticketMarketplaceAddress).setAsk(
            ticketId,
            ticketPrice,
            ticketOfferedAmount + amount,
            ticketTokenPaymentType,
            ticketOwner,
            allowances
        );

        emit CancelTicketBooking(ticketId, ticketOwner, ticketBuyer);
    }

    function setTransferAllowances(
        uint256 ticketId,
        address ticketOwner,
        address[] calldata allowedAddresses
    ) external whenNotPaused onlyTicketMarketplace {
        delete _transferAllowances[ticketId][ticketOwner];
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            _transferAllowances[ticketId][ticketOwner].push(allowedAddresses[i]);
        }
    }

    function transferTicketFromOwner(
        uint256 ticketId,
        address ticketOwner,
        address recipient,
        uint256 amount
    ) external whenNotPaused hasTransferAllowance(ticketId, ticketOwner) {
        uint256 balance = ITicket(ticketAddress).balanceOf(msg.sender, ticketId);
        require(balance > amount, 'Sender has no ticket.');
        (uint256 ticketOfferedAmount, uint256 ticketPrice) = ITicketMarketplace(ticketMarketplaceAddress).offers(ticketOwner, ticketId);
        if (ticketOfferedAmount > balance - amount) {
            address[] memory allowances = _transferAllowances[ticketId][ticketOwner];
            address ticketTokenPaymentType = ITicketMarketplace(ticketMarketplaceAddress).tokenPaymentType(ticketOwner, ticketId);
            address owner = ticketOwner;

            ITicketMarketplace(ticketMarketplaceAddress).setAsk(
                ticketId,
                ticketPrice,
                balance - amount,
                ticketTokenPaymentType,
                owner,
                allowances
            );
        }

        ITicket(ticketAddress).safeTransferFrom(ticketOwner, recipient, ticketId, amount, '');
    }

    function userHasTransferAllowance(
        uint256 ticketId,
        address ticketOwner,
        address user
    ) external view returns (bool) {
        for (uint256 i = 0; i < _transferAllowances[ticketId][ticketOwner].length; i++) {
            if (_transferAllowances[ticketId][ticketOwner][i] == user) {
                return true;
            }
        }
        return false;
    }

    function transferSellingTicketFromOwner(
        uint256 ticketId,
        address ticketOwner,
        address recipient,
        uint256 amount
    ) external whenNotPaused hasTransferAllowance(ticketId, ticketOwner) {
        (uint256 ticketOfferedAmount, uint256 ticketPrice) = ITicketMarketplace(ticketMarketplaceAddress).offers(ticketOwner, ticketId);
        require(ticketOfferedAmount > amount, 'Sender has no ticket.');

        address[] memory allowances = _transferAllowances[ticketId][ticketOwner];
        address ticketTokenPaymentType = ITicketMarketplace(ticketMarketplaceAddress).tokenPaymentType(ticketOwner, ticketId);
        address owner = ticketOwner;

        ITicketMarketplace(ticketMarketplaceAddress).setAsk(
            ticketId,
            ticketPrice,
            ticketOfferedAmount - amount,
            ticketTokenPaymentType,
            owner,
            allowances
        );

        ITicket(ticketAddress).safeTransferFrom(ticketOwner, recipient, ticketId, amount, '');
    }

    /* public */

    /**
     *  @dev Pauses the contract in case of an emergency. Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *  @dev Re-plays the contract in case a prior emergency has been solved. Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *  @dev Adds an Collaborator (amount for allowed addresses) for a ticket
     */
    function addCollaborator(uint256 eventId, address collaborator) public whenNotPaused onlyEventCreator(eventId) {
        _addCollaborator(eventId, collaborator);
    }

    /**
     *  @dev Removes an Collaborator (amount for allowed addresses) for a ticket
     */
    function removeCollaborator(uint256 eventId, address collaborator) public whenNotPaused onlyEventCreator(eventId) {
        require(collaborators[eventId][collaborator] == true, 'Collaborator not found!');
        collaborators[eventId][collaborator] = false;
        emit CollaboratorRemoved(eventId, collaborator);
    }

    /**
     *  @dev Adds an Collaborator (amount for allowed addresses) for a ticket
     */
    function setFixedFeesForERC20(address addr, uint256 fee) external onlyOwner whenNotPaused {
        fixedFees[addr] = fee;
        emit FixedFeeForERC20Setted(addr, fee);
    }

    /**
     *  @dev Adds an Collaborator (amount for allowed addresses) for a ticket
     */
    function _addCollaborator(uint256 eventId, address collaborator) internal {
        require(collaborators[eventId][collaborator] == false, 'Collaborator already setted!');
        collaborators[eventId][collaborator] = true;
        emit CollaboratorAdded(eventId, collaborator);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/* Structs */

/// @dev Properties assigned to a particular ticket, including royalties and sellable status.
struct AssetProperties {
    uint256 creatorRoyalty;
    uint256 primaryMarketRoyalty;
    uint256 secondaryMarketRoyalty;
    address creator;
    bool isResellable;
}

/// @dev A particular sale Models.Offer made by a owner, including price and amount.
struct Offer {
    uint256 amount;
    uint256 price;
}

/// @dev all required information for publishing a new ticket.
struct NewAssetSaleInfo {
    uint256 amount;
    uint256 price;
    uint256 royalty;
    uint256 amountToSell;
    bool isResellable;
    string uri;
    bool isPrivate;
    AllowanceInput[] allowances;
    address erc20token;
}

/// @dev ERC721 & ERC1155 memberships management.
struct AllowedMemberships {
    mapping(address => bool) allowedByAddress;
    mapping(address => uint256) tokenIdsAmountAllowedByAddress;
    mapping(address => mapping(uint256 => bool)) allowedTokenIds;
}

/// @dev Memberships input management.
struct MembershipsInfo {
    address[][] addresses;
    uint256[][][] ids;
}

/// @dev Allowance pools e.g. for custom claiming rights for tickets.
struct Allowance {
    uint256 amount;
    mapping(address => bool) allowed;
}

/// @dev Allowance pools input e.g. for custom claiming rights for tickets.
struct AllowanceInput {
    uint256 amount;
    address[] allowedAddresses;
}