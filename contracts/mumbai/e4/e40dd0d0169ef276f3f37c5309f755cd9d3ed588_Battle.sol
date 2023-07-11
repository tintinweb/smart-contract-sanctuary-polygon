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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
interface IERC165Upgradeable {
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
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IBattle.sol";
import "./cryptocaps-minter/interfaces/ICryptoCapsNFT.sol";
import "./interfaces/IUserRegistry.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Battle is IBattle, OwnableUpgradeable, IERC1155ReceiverUpgradeable {
    address backendAddress;
    ICryptoCapsNFT cryptocapsNFT;
    uint256 ticketsForBattleAmount;
    IUserRegistry userRegistry;

    function initialize(
        address _backendAddress,
        address cryptocapsNFTAddress,
        uint256 _ticketsForBattleAmount,
        address userRegistryAddress
    ) external initializer {
        backendAddress = _backendAddress;
        cryptocapsNFT = ICryptoCapsNFT(cryptocapsNFTAddress);
        ticketsForBattleAmount = _ticketsForBattleAmount;
        userRegistry = IUserRegistry(userRegistryAddress);
        __Ownable_init();
    }

    // INTERFACE INHERITED FUNCTIONS

    ///@dev see IERC165Upgradeable.sol
    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            interfaceId == type(IBattle).interfaceId;
    }

    ///@dev see IERC1155ReceiverUpgradeable.sol
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    ///@dev see IERC1155ReceiverUpgradeable.sol
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    // END INTERFACE INHERITED FUNCTIONS

    // STATE-CHANGING FUNCTIONS

    /**
     * @dev Checks if the set`s arrays lengths match to each other.
     * @param set NFT set to check.
     * @return true if lengths match, false otherwise.
     */
    function _isSetConsistent(
        NFTSet calldata set
    ) internal pure returns (bool) {
        return
            set.collections.length == set.rarities.length &&
            set.rarities.length == set.numbers.length &&
            set.numbers.length == set.amounts.length;
    }

    /**
     * @dev Calls CryptoCapsNFT contract to get ids of set`s NFTs.
     * @param set NFT set to get ids.
     * @return ids of the NFTs in the set.
     * @dev Throws {IBattle.IncosistentSet} if set is malformed.
     */
    function _getSetIds(
        NFTSet calldata set
    ) internal view returns (uint256[] memory ids) {
        if (!_isSetConsistent(set)) revert IncosistentSet();
        ids = new uint256[](set.collections.length);
        for (uint256 i = 0; i < set.collections.length; i++) {
            ids[i] = cryptocapsNFT.getId(
                set.collections[i],
                set.rarities[i],
                set.numbers[i]
            );
        }
    }

    ///@inheritdoc IBattle
    function startBattle(
        address firstPlayer,
        address secondPlayer,
        NFTSet calldata firstPlayerSet,
        NFTSet calldata secondPlayerSet
    ) external override {
        if (!cryptocapsNFT.isApprovedForAll(firstPlayer, address(this)))
            revert NotApproved(firstPlayer);
        if (!cryptocapsNFT.isApprovedForAll(secondPlayer, address(this)))
            revert NotApproved(secondPlayer);

        uint256[] memory firstPlayerSetIds = _getSetIds(firstPlayerSet);
        uint256[] memory secondPlayerSetIds = _getSetIds(secondPlayerSet);

        userRegistry.spendTickets(firstPlayer, ticketsForBattleAmount);
        userRegistry.spendTickets(secondPlayer, ticketsForBattleAmount);

        cryptocapsNFT.safeBatchTransferFrom(
            firstPlayer,
            address(this),
            firstPlayerSetIds,
            firstPlayerSet.amounts,
            ""
        );

        cryptocapsNFT.safeBatchTransferFrom(
            secondPlayer,
            address(this),
            secondPlayerSetIds,
            secondPlayerSet.amounts,
            ""
        );
        //TODO: Add ticket price upgrade in user registry
        //TODO: Add minimal bid check
    }

    ///@inheritdoc IBattle
    function endBattle(
        address firstPlayer,
        address secondPlayer,
        NFTSet calldata firstPlayerSet,
        NFTSet calldata secondPlayerSet
    ) external override {
        uint256[] memory firstPlayerSetIds = _getSetIds(firstPlayerSet);
        uint256[] memory secondPlayerSetIds = _getSetIds(secondPlayerSet);

        cryptocapsNFT.safeBatchTransferFrom(
            address(this),
            firstPlayer,
            firstPlayerSetIds,
            firstPlayerSet.amounts,
            ""
        );

        cryptocapsNFT.safeBatchTransferFrom(
            address(this),
            secondPlayer,
            secondPlayerSetIds,
            secondPlayerSet.amounts,
            ""
        );
    }

    // END STATE-CHANGING FUNCTIONS

    // MAINTENANCE FUNCTIONS

    /**
     * @notice Sets new user registry.
     * @param userRegistryAddress address of the new registry.
     * @dev Could only be called by the contract owner (see {OwnableUpgradeable.owner}),
     * throws error otherwise.
     */
    function setUserRegistry(address userRegistryAddress) external onlyOwner {
        userRegistry = IUserRegistry(userRegistryAddress);
    }

    /**
     * @notice Sets new tickets amount required to start battle.
     * @param _ticketsForBattleAmount new tickets amount.
     * @dev Could only be called by the contract owner (see {OwnableUpgradeable.owner}),
     * throws error otherwise.
     */
    function setTicketsForBattleAmount(
        uint256 _ticketsForBattleAmount
    ) external onlyOwner {
        ticketsForBattleAmount = _ticketsForBattleAmount;
    }

    /**
     * @notice Sets new backend address.
     * @param _backendAddress new new backend address.
     * @dev Could only be called by the contract owner (see {OwnableUpgradeable.owner}),
     * throws error otherwise.
     */
    function setBackendAddress(address _backendAddress) external onlyOwner {
        backendAddress = _backendAddress;
    }

    // END MAINTENANCE FUNCTIONS
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICryptoCapsNFT is IERC1155 {
    function getId(
        uint128 collection,
        uint8 rarity,
        uint120 number
    ) external pure returns (uint256 res);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../lib/Types/NFTSet.sol";

/**
 * @title Interface for contract that starts/finishes battles and transfers NFT.
 * @author pchn
 * @notice See realization: `./contracts/Battle.sol`.
 */
interface IBattle {
    // ERRORS

    error NotApproved(address player);
    error IncosistentSet();

    // END ERRORS

    // EVENTS

    event BattleStarted(
        address indexed firstPlayer,
        address indexed secondPlayer,
        NFTSet firstPlayerSet,
        NFTSet secondPlayerSet
    );

    event BattleEnded(
        address indexed firstPlayer,
        address indexed secondPlayer,
        NFTSet firstPlayerSet,
        NFTSet secondPlayerSet
    );

    // END EVENTS

    // STATE-CHANGING FUNCTIONS

    /**
     * @notice Called by back-end server to initialize the battle.
     * @notice Transfers specified NFTs from both players to this contract.
     * NFTs are released after the battle ends.
     * @param firstPlayer address of the first player.
     * @param secondPlayer address of the second player.
     * @param firstPlayerSet NFT set of the first player.
     * @param secondPlayerSet NFT set of the second player
     * @dev Throws {IBattle.NotApproved} is NFTs are not approved by players.
     * @dev Throws {IBattle.IncosistentSet} if set is malformed.
     */
    function startBattle(
        address firstPlayer,
        address secondPlayer,
        NFTSet calldata firstPlayerSet,
        NFTSet calldata secondPlayerSet
    ) external;

    /**
     * @notice Called by back-end server to end the battle.
     * @notice Transfers specified NFTs to both players from this contract.
     * @param firstPlayer address of the first player.
     * @param secondPlayer address of the second player.
     * @param firstPlayerSet NFT set of the first player.
     * @param secondPlayerSet NFT set of the second player
     * @dev Throws {IBattle.IncosistentSet} if set is malformed.
     */
    function endBattle(
        address firstPlayer,
        address secondPlayer,
        NFTSet calldata firstPlayerSet,
        NFTSet calldata secondPlayerSet
    ) external;

    // END STATE-CHANGING FUNCTIONS
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "../lib/TransferHelper.sol";
import "../lib/Decimals.sol";

/**
 * @title Interface for contract that can hold registry of some abstract tickets bought by users,
 * as well as sell or spend them.
 * @author pchn
 * @notice See realization: `./contracts/UserRegistry.sol`.
 */
interface IUserRegistry {
    //ERRORS

    error InsufficientFunds(uint256 requiredFunds, uint256 providedFunds);
    error CallRestricted();

    //END ERRORS

    //EVENTS

    event TicketsBoughtForEth(
        address indexed buyer,
        uint256 indexed amount,
        uint256 indexed ticketPrice
    );
    event TicketsBoughtForERC20(
        address indexed buyer,
        uint256 indexed amount,
        uint256 indexed ticketPrice
    );
    event TicketsSpent(address indexed userAddress, uint256 indexed amount);
    event TicketPriceInGasTokenChanged(uint256 indexed newPrice);
    event TicketPriceInERC20TokenChanged(uint256 indexed newPrice);

    //END EVENTS

    //STATE VARIABLES

    /**
     * @notice Returns tickets balance of user with specified address.
     * @param userAddress address of user to get balance for.
     */
    function ticketsBalance(
        address userAddress
    ) external view returns (uint256 _ticketsBalance);

    /**
     * @notice Returns address of ERC20 token used for payments.
     * @return _paymentTokenAddress address of ERC20 token used for payments.
     */
    function paymentTokenAddress()
        external
        view
        returns (address _paymentTokenAddress);

    //END STATE VARIABLES

    //STATE-CHANGING FUNCTIONS

    /**
     * @notice Sells required amount of tickets to msg.sender. Tickets could be sold
     * for native token or ERC20 token used for payments (see {IUserRegistry.paymentTokenAddress}).
     * @param ticketsAmount amount of tickets to sell.
     * @dev Function checks whether the msg.value is equal to zero or not.
     * If msg.value is greater than zero than selling for native token is supposed,
     * otherwise function will transfer payment token from msg.sender.
     * @dev Amount of token to pay is calculated using relative ticket
     * price (see {IUserRegistry.ticketPrice}).
     * @dev Throws {IUserRegistry.InsufficientFunds} error if insufficient amount fo tokens provided.
     * @dev See {TransferHelper.smartTransferFrom}.
     * @dev Emits {TransferHelper.TicketsBoughtForEth} or {TransferHelper.TicketsBoughtForERC20} event.
     */
    function buyTickets(uint256 ticketsAmount) external payable;

    /**
     * @notice Used by battle contract to spend user`s tickets for battle.
     * @param userAddress address of user to spend tickets from.
     * @param ticketsAmount amount of tickets to spend.
     * @dev Throws {IUserRegistry.InsufficientFunds} if `ticketsAmount`
     * exceeds user`s balance (see {IUserRegistry.ticketsBalance}).
     * @dev Throws {IUserRegistry.CallRestricted} if called from address
     * different from battle contract`s address.
     * @dev Emits {TransferHelper.TicketsSpent} event.
     */
    function spendTickets(address userAddress, uint256 ticketsAmount) external;

    //END STATE-CHANGING FUNCTIONS

    //MAINTENANCE FUNCTIONS

    /**
     * @notice Used to update ticket price according to current native token price.
     * @param newPrice new ticket price in native token.
     * @dev Throws {IUserRegistry.CallRestricted} if called from address
     * different from battle contract`s address.
     * @dev Emits {IUserRegistry.TicketPriceInGasTokenChanged} event.
     */
    function updateTicketPriceInGasToken(uint256 newPrice) external;

    //END MAINTENANCE FUNCTIONS

    //VIEW FUNCTIONS

    /**
     * @notice Returns price for 1 ticket in native and in ERC20 payment token currencies.
     * @return _ticketPriceInGasToken price for 1 token in native token currency.
     * @return _ticketPriceInErc20Token price for 1 token in ERC20 payment token currency.
     * @dev Prices are multiplied by 1e18 (see {Decimals.priceDecimals}).
     */
    function ticketPrice()
        external
        view
        returns (
            uint256 _ticketPriceInGasToken,
            uint256 _ticketPriceInErc20Token
        );

    //END VIEW FUNCTIONS
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Some predifined precision constants.
library Decimals {
    uint256 constant priceDecimals = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Helper methods for interacting with ERC20 tokens and sending
 * ETH that do not consistently return true/false.
 */
library TransferHelper {
    //ERRORS

    error ApproveFailed(address token, address from, address to, uint256 value);
    error EthTransferFailed(address from, address to, uint256 value);
    error TokenTransferFailed(
        address token,
        address from,
        address to,
        uint256 value
    );
    error TransferFromFailed(
        address token,
        address from,
        address to,
        uint256 value
    );

    //END ERRORS

    //MAIN FUNCTIONS

    /**
     * @notice Approves specified amount of specified token to specified address.
     * @param token token to approve.
     * @param to address to approve to.
     * @param value amount of tokens to approve.
     * @dev Throws {TransferHelper.ApproveFailed} on failure.
     */
    function smartApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.approve.selector /*0x095ea7b3*/,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert ApproveFailed({
                token: token,
                from: address(this),
                to: to,
                value: value
            });
    }

    /**
     * @notice Transfers specified amount of native token to specified address.
     * @param to address to transfer native token to.
     * @param value amount of native token to transfer.
     * @dev Throws {TransferHelper.EthTransferFailed} on failure.
     */
    function smartTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success)
            revert EthTransferFailed({
                from: address(this),
                to: to,
                value: value
            });
    }

    /**
     * @notice Transfers specified amount of specified ERC20 token
     * to specified address.
     * @param token address of ERC20 token to transfer.
     * @param to address to transfer ERC20 token to.
     * @param value amount of ERC20 token to transfer.
     * @dev Throws {TransferHelper.TokenTransferFailed} on failure.
     */
    function smartTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transfer.selector /*0xa9059cbb*/,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TokenTransferFailed({
                token: token,
                from: address(this),
                to: to,
                value: value
            });
    }

    /**
     * @notice Transfers specified amount of specified ERC20 token from
     * specified address to specified address.
     * @param token address of ERC20 token to transfer.
     * @param from address to transfer ERC20 token from.
     * @param to address to transfer ERC20 token to.
     * @param value amount of ERC20 token to transfer.
     */
    function smartTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector /*0x23b872dd*/,
                from,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFromFailed({
                token: token,
                from: from,
                to: to,
                value: value
            });
    }

    //END MAIN FUNCTIONS
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Struct to identify NFT sets for battle.
struct NFTSet {
    uint128[] collections;
    uint8[] rarities;
    uint120[] numbers;
    uint256[] amounts;
}