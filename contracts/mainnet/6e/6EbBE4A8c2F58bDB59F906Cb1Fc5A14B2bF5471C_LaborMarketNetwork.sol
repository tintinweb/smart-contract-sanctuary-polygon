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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./TypesAndDecoders.sol";

abstract contract CaveatEnforcer {
    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata tx,
        bytes32 delegationHash
    ) public virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// import "hardhat/console.sol";
import {EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation} from "./CaveatEnforcer.sol";
import {DelegatableCore} from "./DelegatableCore.sol";
import {IDelegatable} from "./interfaces/IDelegatable.sol";

abstract contract Delegatable is IDelegatable, DelegatableCore {
    /// @notice The hash of the domain separator used in the EIP712 domain hash.
    bytes32 public immutable domainHash;

    /**
     * @notice Delegatable Constructor
     * @param contractName string - The name of the contract
     * @param version string - The version of the contract
     */
    constructor(string memory contractName, string memory version) {
        domainHash = getEIP712DomainHash(
            contractName,
            version,
            block.chainid,
            address(this)
        );
    }

    /* ===================================================================================== */
    /* External Functions                                                                    */
    /* ===================================================================================== */

    /// @inheritdoc IDelegatable
    function getDelegationTypedDataHash(Delegation memory delegation)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                GET_DELEGATION_PACKETHASH(delegation)
            )
        );
        return digest;
    }

    /// @inheritdoc IDelegatable
    function getInvocationsTypedDataHash(Invocations memory invocations)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                GET_INVOCATIONS_PACKETHASH(invocations)
            )
        );
        return digest;
    }

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) public pure returns (bytes32) {
        bytes memory encoded = abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract
        );
        return keccak256(encoded);
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        override(IDelegatable, DelegatableCore)
        returns (address)
    {
        Delegation memory delegation = signedDelegation.delegation;
        bytes32 sigHash = getDelegationTypedDataHash(delegation);
        address recoveredSignatureSigner = recover(
            sigHash,
            signedDelegation.signature
        );
        return recoveredSignatureSigner;
    }

    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        public
        view
        returns (address)
    {
        bytes32 sigHash = getInvocationsTypedDataHash(
            signedInvocation.invocations
        );
        address recoveredSignatureSigner = recover(
            sigHash,
            signedInvocation.signature
        );
        return recoveredSignatureSigner;
    }

    // --------------------------------------
    // WRITES
    // --------------------------------------

    /// @inheritdoc IDelegatable
    function contractInvoke(Invocation[] calldata batch)
        external
        override
        returns (bool)
    {
        return _invoke(batch, msg.sender);
    }

    /// @inheritdoc IDelegatable
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        override
        returns (bool success)
    {
        for (uint256 i = 0; i < signedInvocations.length; i++) {
            SignedInvocation calldata signedInvocation = signedInvocations[i];
            address invocationSigner = verifyInvocationSignature(
                signedInvocation
            );
            _enforceReplayProtection(
                invocationSigner,
                signedInvocations[i].invocations.replayProtection
            );
            _invoke(signedInvocation.invocations.batch, invocationSigner);
        }
    }

    /* ===================================================================================== */
    /* Internal Functions                                                                    */
    /* ===================================================================================== */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {EIP712Decoder, EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation, Transaction, ReplayProtection, CaveatEnforcer} from "./CaveatEnforcer.sol";

abstract contract DelegatableCore is EIP712Decoder {
    /// @notice Account delegation nonce manager
    mapping(address => mapping(uint256 => uint256)) internal multiNonce;

    function getNonce(address intendedSender, uint256 queue)
        external
        view
        returns (uint256)
    {
        return multiNonce[intendedSender][queue];
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        returns (address);

    function _enforceReplayProtection(
        address intendedSender,
        ReplayProtection memory protection
    ) internal {
        uint256 queue = protection.queue;
        uint256 nonce = protection.nonce;
        require(
            nonce == (multiNonce[intendedSender][queue] + 1),
            "DelegatableCore:nonce2-out-of-order"
        );
        multiNonce[intendedSender][queue] = nonce;
    }

    function _execute(
        address to,
        bytes memory data,
        uint256 gasLimit,
        address sender
    ) internal returns (bool success) {
        bytes memory full = abi.encodePacked(data, sender);
        assembly {
            success := call(gasLimit, to, 0, add(full, 0x20), mload(full), 0, 0)
        }
    }

    function _invoke(Invocation[] calldata batch, address sender)
        internal
        returns (bool success)
    {
        for (uint256 x = 0; x < batch.length; x++) {
            Invocation memory invocation = batch[x];
            address intendedSender;
            address canGrant;

            // If there are no delegations, this invocation comes from the signer
            if (invocation.authority.length == 0) {
                intendedSender = sender;
                canGrant = intendedSender;
            }

            bytes32 authHash = 0x0;

            for (uint256 d = 0; d < invocation.authority.length; d++) {
                SignedDelegation memory signedDelegation = invocation.authority[
                    d
                ];
                address delegationSigner = verifyDelegationSignature(
                    signedDelegation
                );

                // Implied sending account is the signer of the first delegation
                if (d == 0) {
                    intendedSender = delegationSigner;
                    canGrant = intendedSender;
                }

                require(
                    delegationSigner == canGrant,
                    "DelegatableCore:invalid-delegation-signer"
                );

                Delegation memory delegation = signedDelegation.delegation;
                require(
                    delegation.authority == authHash,
                    "DelegatableCore:invalid-authority-delegation-link"
                );

                // TODO: maybe delegations should have replay protection, at least a nonce (non order dependent),
                // otherwise once it's revoked, you can't give the exact same permission again.
                bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(
                    signedDelegation
                );

                // Each delegation can include any number of caveats.
                // A caveat is any condition that may reject a proposed transaction.
                // The caveats specify an external contract that is passed the proposed tx,
                // As well as some extra terms that are used to parameterize the enforcer.
                for (uint16 y = 0; y < delegation.caveats.length; y++) {
                    CaveatEnforcer enforcer = CaveatEnforcer(
                        delegation.caveats[y].enforcer
                    );
                    bool caveatSuccess = enforcer.enforceCaveat(
                        delegation.caveats[y].terms,
                        invocation.transaction,
                        delegationHash
                    );
                    require(caveatSuccess, "DelegatableCore:caveat-rejected");
                }

                // Store the hash of this delegation in `authHash`
                // That way the next delegation can be verified against it.
                authHash = delegationHash;
                canGrant = delegation.delegate;
            }

            // Here we perform the requested invocation.
            Transaction memory transaction = invocation.transaction;

            require(
                transaction.to == address(this),
                "DelegatableCore:invalid-invocation-target"
            );

            // TODO(@kames): Can we bubble up the error message from the enforcer? Why not? Optimizations?
            success = _execute(
                transaction.to,
                transaction.data,
                transaction.gasLimit,
                intendedSender
            );
            require(success, "DelegatableCore::execution-failed");
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../TypesAndDecoders.sol";

interface IDelegatable {
    /**
     * @notice Allows a smart contract to submit a batch of invocations for processing, allowing itself to be the delegate.
     * @param batch Invocation[] - The batch of invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function contractInvoke(Invocation[] calldata batch)
        external
        returns (bool);

    /**
     * @notice Allows anyone to submit a batch of signed invocations for processing.
     * @param signedInvocations SignedInvocation[] - The batch of signed invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        returns (bool success);

    /**
     * @notice Returns the typehash for this contract's delegation signatures.
     * @param delegation Delegation - The delegation to get the type of
     * @return bytes32 - The type of the delegation
     */
    function getDelegationTypedDataHash(Delegation memory delegation)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the typehash for this contract's invocation signatures.
     * @param invocations Invocations
     * @return bytes32 - The type of the Invocations
     */
    function getInvocationsTypedDataHash(Invocations memory invocations)
        external
        view
        returns (bytes32);

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) external pure returns (bytes32);

    /**
     * @notice Verifies that the given invocation is valid.
     * @param signedInvocation - The signed invocation to verify
     * @return address - The address of the account authorizing this invocation to act on its behalf.
     */
    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        external
        view
        returns (address);

    /**
     * @notice Verifies that the given delegation is valid.
     * @param signedDelegation - The delegation to verify
     * @return address - The address of the account authorizing this delegation to act on its behalf.
     */
    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        external
        view
        returns (address);
}

pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT

contract ECRecovery {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./libraries/ECRecovery.sol";

// BEGIN EIP712 AUTOGENERATED SETUP
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

struct Invocation {
    Transaction transaction;
    SignedDelegation[] authority;
}

bytes32 constant INVOCATION_TYPEHASH = keccak256(
    "Invocation(Transaction transaction,SignedDelegation[] authority)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Invocations {
    Invocation[] batch;
    ReplayProtection replayProtection;
}

bytes32 constant INVOCATIONS_TYPEHASH = keccak256(
    "Invocations(Invocation[] batch,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct SignedInvocation {
    Invocations invocations;
    bytes signature;
}

bytes32 constant SIGNEDINVOCATION_TYPEHASH = keccak256(
    "SignedInvocation(Invocations invocations,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)Invocations(Invocation[] batch,ReplayProtection replayProtection)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Transaction {
    address to;
    uint256 gasLimit;
    bytes data;
}

bytes32 constant TRANSACTION_TYPEHASH = keccak256(
    "Transaction(address to,uint256 gasLimit,bytes data)"
);

struct ReplayProtection {
    uint256 nonce;
    uint256 queue;
}

bytes32 constant REPLAYPROTECTION_TYPEHASH = keccak256(
    "ReplayProtection(uint nonce,uint queue)"
);

struct Delegation {
    address delegate;
    bytes32 authority;
    Caveat[] caveats;
}

bytes32 constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegate,bytes32 authority,Caveat[] caveats)Caveat(address enforcer,bytes terms)"
);

struct Caveat {
    address enforcer;
    bytes terms;
}

bytes32 constant CAVEAT_TYPEHASH = keccak256(
    "Caveat(address enforcer,bytes terms)"
);

struct SignedDelegation {
    Delegation delegation;
    bytes signature;
}

bytes32 constant SIGNEDDELEGATION_TYPEHASH = keccak256(
    "SignedDelegation(Delegation delegation,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)"
);

// END EIP712 AUTOGENERATED SETUP

contract EIP712Decoder is ECRecovery {
    // BEGIN EIP712 AUTOGENERATED BODY. See scripts/typesToCode.js

    // function GET_EIP712DOMAIN_PACKETHASH(EIP712Domain memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         EIP712DOMAIN_TYPEHASH,
    //         _input.name,
    //         _input.version,
    //         _input.chainId,
    //         _input.verifyingContract
    //     );

    //     return keccak256(encoded);
    // }

    function GET_INVOCATION_PACKETHASH(Invocation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATION_TYPEHASH,
            GET_TRANSACTION_PACKETHASH(_input.transaction),
            GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(_input.authority)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(
        SignedDelegation[] memory _input
    ) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_SIGNEDDELEGATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_INVOCATIONS_PACKETHASH(Invocations memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATIONS_TYPEHASH,
            GET_INVOCATION_ARRAY_PACKETHASH(_input.batch),
            GET_REPLAYPROTECTION_PACKETHASH(_input.replayProtection)
        );

        return keccak256(encoded);
    }

    function GET_INVOCATION_ARRAY_PACKETHASH(Invocation[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_INVOCATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    // function GET_SIGNEDINVOCATION_PACKETHASH(SignedInvocation memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         SIGNEDINVOCATION_TYPEHASH,
    //         GET_INVOCATIONS_PACKETHASH(_input.invocations),
    //         keccak256(_input.signature)
    //     );

    //     return keccak256(encoded);
    // }

    function GET_TRANSACTION_PACKETHASH(Transaction memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            TRANSACTION_TYPEHASH,
            _input.to,
            _input.gasLimit,
            keccak256(_input.data)
        );

        return keccak256(encoded);
    }

    function GET_REPLAYPROTECTION_PACKETHASH(ReplayProtection memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            REPLAYPROTECTION_TYPEHASH,
            _input.nonce,
            _input.queue
        );

        return keccak256(encoded);
    }

    function GET_DELEGATION_PACKETHASH(Delegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            DELEGATION_TYPEHASH,
            _input.delegate,
            _input.authority,
            GET_CAVEAT_ARRAY_PACKETHASH(_input.caveats)
        );

        return keccak256(encoded);
    }

    function GET_CAVEAT_ARRAY_PACKETHASH(Caveat[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(encoded, GET_CAVEAT_PACKETHASH(_input[i]));
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_CAVEAT_PACKETHASH(Caveat memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            CAVEAT_TYPEHASH,
            _input.enforcer,
            keccak256(_input.terms)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_PACKETHASH(SignedDelegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            SIGNEDDELEGATION_TYPEHASH,
            GET_DELEGATION_PACKETHASH(_input.delegation),
            keccak256(_input.signature)
        );

        return keccak256(encoded);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// /**
//  * @dev Implementation of the basic standard multi-token.
//  * See https://eips.ethereum.org/EIPS/eip-1155
//  * Originally based on code by Enjin: https://github.com/enjin/erc-1155
//  *
//  * _Available since v3.1._
//  */
// contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
//     using Address for address;

//     // Mapping from token ID to account balances
//     mapping(uint256 => mapping(address => uint256)) private _balances;

//     // Mapping from account to operator approvals
//     mapping(address => mapping(address => bool)) private _operatorApprovals;

//     // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
//     string private _uri;

//     /**
//      * @dev See {_setURI}.
//      */
//     constructor(string memory uri_) {
//         _setURI(uri_);
//     }

//     /**
//      * @dev See {IERC165-supportsInterface}.
//      */
//     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
//         return
//             interfaceId == type(IERC1155).interfaceId ||
//             interfaceId == type(IERC1155MetadataURI).interfaceId ||
//             super.supportsInterface(interfaceId);
//     }

//     /**
//      * @dev See {IERC1155MetadataURI-uri}.
//      *
//      * This implementation returns the same URI for *all* token types. It relies
//      * on the token type ID substitution mechanism
//      * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
//      *
//      * Clients calling this function must replace the `\{id\}` substring with the
//      * actual token type ID.
//      */
//     function uri(uint256) public view virtual override returns (string memory) {
//         return _uri;
//     }

//     /**
//      * @dev See {IERC1155-balanceOf}.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      */
//     function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
//         require(account != address(0), "ERC1155: address zero is not a valid owner");
//         return _balances[id][account];
//     }

//     /**
//      * @dev See {IERC1155-balanceOfBatch}.
//      *
//      * Requirements:
//      *
//      * - `accounts` and `ids` must have the same length.
//      */
//     function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
//         public
//         view
//         virtual
//         override
//         returns (uint256[] memory)
//     {
//         require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

//         uint256[] memory batchBalances = new uint256[](accounts.length);

//         for (uint256 i = 0; i < accounts.length; ++i) {
//             batchBalances[i] = balanceOf(accounts[i], ids[i]);
//         }

//         return batchBalances;
//     }

//     /**
//      * @dev See {IERC1155-setApprovalForAll}.
//      */
//     function setApprovalForAll(address operator, bool approved) public virtual override {
//         _setApprovalForAll(_msgSender(), operator, approved);
//     }

//     /**
//      * @dev See {IERC1155-isApprovedForAll}.
//      */
//     function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
//         return _operatorApprovals[account][operator];
//     }

//     /**
//      * @dev See {IERC1155-safeTransferFrom}.
//      */
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes memory data
//     ) public virtual override {
//         require(
//             from == _msgSender() || isApprovedForAll(from, _msgSender()),
//             "ERC1155: caller is not token owner or approved"
//         );
//         _safeTransferFrom(from, to, id, amount, data);
//     }

//     /**
//      * @dev See {IERC1155-safeBatchTransferFrom}.
//      */
//     function safeBatchTransferFrom(
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     ) public virtual override {
//         require(
//             from == _msgSender() || isApprovedForAll(from, _msgSender()),
//             "ERC1155: caller is not token owner or approved"
//         );
//         _safeBatchTransferFrom(from, to, ids, amounts, data);
//     }

//     /**
//      * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
//      *
//      * Emits a {TransferSingle} event.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      * - `from` must have a balance of tokens of type `id` of at least `amount`.
//      * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
//      * acceptance magic value.
//      */
//     function _safeTransferFrom(
//         address from,
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes memory data
//     ) internal virtual {
//         require(to != address(0), "ERC1155: transfer to the zero address");

//         address operator = _msgSender();
//         uint256[] memory ids = _asSingletonArray(id);
//         uint256[] memory amounts = _asSingletonArray(amount);

//         _beforeTokenTransfer(operator, from, to, ids, amounts, data);

//         uint256 fromBalance = _balances[id][from];
//         require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
//         unchecked {
//             _balances[id][from] = fromBalance - amount;
//         }
//         _balances[id][to] += amount;

//         emit TransferSingle(operator, from, to, id, amount);

//         _afterTokenTransfer(operator, from, to, ids, amounts, data);

//         _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
//     }

//     /**
//      * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
//      *
//      * Emits a {TransferBatch} event.
//      *
//      * Requirements:
//      *
//      * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
//      * acceptance magic value.
//      */
//     function _safeBatchTransferFrom(
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     ) internal virtual {
//         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
//         require(to != address(0), "ERC1155: transfer to the zero address");

//         address operator = _msgSender();

//         _beforeTokenTransfer(operator, from, to, ids, amounts, data);

//         for (uint256 i = 0; i < ids.length; ++i) {
//             uint256 id = ids[i];
//             uint256 amount = amounts[i];

//             uint256 fromBalance = _balances[id][from];
//             require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
//             unchecked {
//                 _balances[id][from] = fromBalance - amount;
//             }
//             _balances[id][to] += amount;
//         }

//         emit TransferBatch(operator, from, to, ids, amounts);

//         _afterTokenTransfer(operator, from, to, ids, amounts, data);

//         _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
//     }

//     /**
//      * @dev Sets a new URI for all token types, by relying on the token type ID
//      * substitution mechanism
//      * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
//      *
//      * By this mechanism, any occurrence of the `\{id\}` substring in either the
//      * URI or any of the amounts in the JSON file at said URI will be replaced by
//      * clients with the token type ID.
//      *
//      * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
//      * interpreted by clients as
//      * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
//      * for token type ID 0x4cce0.
//      *
//      * See {uri}.
//      *
//      * Because these URIs cannot be meaningfully represented by the {URI} event,
//      * this function emits no events.
//      */
//     function _setURI(string memory newuri) internal virtual {
//         _uri = newuri;
//     }

//     /**
//      * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
//      *
//      * Emits a {TransferSingle} event.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
//      * acceptance magic value.
//      */
//     function _mint(
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes memory data
//     ) internal virtual {
//         require(to != address(0), "ERC1155: mint to the zero address");

//         address operator = _msgSender();
//         uint256[] memory ids = _asSingletonArray(id);
//         uint256[] memory amounts = _asSingletonArray(amount);

//         _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

//         _balances[id][to] += amount;
//         emit TransferSingle(operator, address(0), to, id, amount);

//         _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

//         _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
//     }

//     /**
//      * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
//      *
//      * Emits a {TransferBatch} event.
//      *
//      * Requirements:
//      *
//      * - `ids` and `amounts` must have the same length.
//      * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
//      * acceptance magic value.
//      */
//     function _mintBatch(
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     ) internal virtual {
//         require(to != address(0), "ERC1155: mint to the zero address");
//         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

//         address operator = _msgSender();

//         _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

//         for (uint256 i = 0; i < ids.length; i++) {
//             _balances[ids[i]][to] += amounts[i];
//         }

//         emit TransferBatch(operator, address(0), to, ids, amounts);

//         _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

//         _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
//     }

//     /**
//      * @dev Destroys `amount` tokens of token type `id` from `from`
//      *
//      * Emits a {TransferSingle} event.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `from` must have at least `amount` tokens of token type `id`.
//      */
//     function _burn(
//         address from,
//         uint256 id,
//         uint256 amount
//     ) internal virtual {
//         require(from != address(0), "ERC1155: burn from the zero address");

//         address operator = _msgSender();
//         uint256[] memory ids = _asSingletonArray(id);
//         uint256[] memory amounts = _asSingletonArray(amount);

//         _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

//         uint256 fromBalance = _balances[id][from];
//         require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
//         unchecked {
//             _balances[id][from] = fromBalance - amount;
//         }

//         emit TransferSingle(operator, from, address(0), id, amount);

//         _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
//     }

//     /**
//      * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
//      *
//      * Emits a {TransferBatch} event.
//      *
//      * Requirements:
//      *
//      * - `ids` and `amounts` must have the same length.
//      */
//     function _burnBatch(
//         address from,
//         uint256[] memory ids,
//         uint256[] memory amounts
//     ) internal virtual {
//         require(from != address(0), "ERC1155: burn from the zero address");
//         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

//         address operator = _msgSender();

//         _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

//         for (uint256 i = 0; i < ids.length; i++) {
//             uint256 id = ids[i];
//             uint256 amount = amounts[i];

//             uint256 fromBalance = _balances[id][from];
//             require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
//             unchecked {
//                 _balances[id][from] = fromBalance - amount;
//             }
//         }

//         emit TransferBatch(operator, from, address(0), ids, amounts);

//         _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
//     }

//     /**
//      * @dev Approve `operator` to operate on all of `owner` tokens
//      *
//      * Emits an {ApprovalForAll} event.
//      */
//     function _setApprovalForAll(
//         address owner,
//         address operator,
//         bool approved
//     ) internal virtual {
//         require(owner != operator, "ERC1155: setting approval status for self");
//         _operatorApprovals[owner][operator] = approved;
//         emit ApprovalForAll(owner, operator, approved);
//     }

//     /**
//      * @dev Hook that is called before any token transfer. This includes minting
//      * and burning, as well as batched variants.
//      *
//      * The same hook is called on both single and batched variants. For single
//      * transfers, the length of the `ids` and `amounts` arrays will be 1.
//      *
//      * Calling conditions (for each `id` and `amount` pair):
//      *
//      * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * of token type `id` will be  transferred to `to`.
//      * - When `from` is zero, `amount` tokens of token type `id` will be minted
//      * for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
//      * will be burned.
//      * - `from` and `to` are never both zero.
//      * - `ids` and `amounts` have the same, non-zero length.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _beforeTokenTransfer(
//         address operator,
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     ) internal virtual {}

//     /**
//      * @dev Hook that is called after any token transfer. This includes minting
//      * and burning, as well as batched variants.
//      *
//      * The same hook is called on both single and batched variants. For single
//      * transfers, the length of the `id` and `amount` arrays will be 1.
//      *
//      * Calling conditions (for each `id` and `amount` pair):
//      *
//      * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * of token type `id` will be  transferred to `to`.
//      * - When `from` is zero, `amount` tokens of token type `id` will be minted
//      * for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
//      * will be burned.
//      * - `from` and `to` are never both zero.
//      * - `ids` and `amounts` have the same, non-zero length.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _afterTokenTransfer(
//         address operator,
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     ) internal virtual {}

//     function _doSafeTransferAcceptanceCheck(
//         address operator,
//         address from,
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes memory data
//     ) private {
//         if (to.isContract()) {
//             try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
//                 if (response != IERC1155Receiver.onERC1155Received.selector) {
//                     revert("ERC1155: ERC1155Receiver rejected tokens");
//                 }
//             } catch Error(string memory reason) {
//                 revert(reason);
//             } catch {
//                 revert("ERC1155: transfer to non-ERC1155Receiver implementer");
//             }
//         }
//     }

//     function _doSafeBatchTransferAcceptanceCheck(
//         address operator,
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     ) private {
//         if (to.isContract()) {
//             try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
//                 bytes4 response
//             ) {
//                 if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
//                     revert("ERC1155: ERC1155Receiver rejected tokens");
//                 }
//             } catch Error(string memory reason) {
//                 revert(reason);
//             } catch {
//                 revert("ERC1155: transfer to non-ERC1155Receiver implementer");
//             }
//         }
//     }

//     function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
//         uint256[] memory array = new uint256[](1);
//         array[0] = element;

//         return array;
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155} from "lib/solmate/src/tokens/ERC1155.sol";

contract ERC1155FreeMint is ERC1155 {
    string private metadata;

    constructor() {
        metadata = "uri/";
    }

    function uri(uint256) public view override returns (string memory) {
        return metadata;
    }

    function freeMint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _mint(account, id, amount, "");
    }

    function freeBurn(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        _burn(account, id, amount);
    }

    function distribute(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 id
    ) external {
        require(accounts.length == amounts.length, "Invalid input");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amounts[i], "");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract ERC20FreeMint is ERC20("Payment Token", "PAY", 18) {
    constructor() {}

    function freeMint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }

    function freeBurn(address receiver, uint256 amount) external {
        _burn(receiver, amount);
    }

    function distribute(address[] calldata accounts, uint256[] calldata amounts)
        external
    {
        require(accounts.length == amounts.length, "Invalid input");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        address network;
        address enforcementModule;
        address paymentModule;
        string marketUri;
        address delegateBadge;
        uint256 delegateTokenId;
        address maintainerBadge;
        uint256 maintainerTokenId;
        address reputationModule;
        ReputationModuleInterface.ReputationMarketConfig reputationConfig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {LaborMarketConfigurationInterface} from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256[] scores;
        bool reviewed;
    }

    struct ReviewPromise {
        uint256 total;
        uint256 remainder;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);

    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Core dependencies.
import {LaborMarketInterface} from "./interfaces/LaborMarketInterface.sol";
import {OwnableUpgradeable, ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1155HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {Delegatable, DelegatableCore} from "lib/delegatable/Delegatable.sol";

/// @dev Helpers.
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @dev Helper interfaces.
import {LaborMarketNetwork} from "../Network/LaborMarketNetwork.sol";
import {EnforcementCriteriaInterface} from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import {PayCurveInterface} from "../Modules/Payment/interfaces/PayCurveInterface.sol";
import {ReputationModuleInterface} from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Supported interfaces.
import {IERC1155ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarket is
    LaborMarketInterface,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    Delegatable("LaborMarket", "v1.0.0")
{
    /// @dev Performable actions.
    bytes32 public constant HAS_SUBMITTED = keccak256("hasSubmitted");
    bytes32 public constant HAS_CLAIMED = keccak256("hasClaimed");
    bytes32 public constant HAS_CLAIMED_REMAINDER =
        keccak256("hasClaimedRemainder");
    bytes32 public constant HAS_REVIEWED = keccak256("hasReviewed");
    bytes32 public constant HAS_SIGNALED = keccak256("hasSignaled");

    /// @dev The network contract.
    LaborMarketNetwork public network;

    /// @dev The enforcement criteria.
    EnforcementCriteriaInterface public enforcementCriteria;

    /// @dev The payment curve.
    PayCurveInterface public paymentCurve;

    /// @dev The reputation module.
    ReputationModuleInterface public reputationModule;

    /// @dev The address of the ERC1155 token used for delegates.
    IERC1155 public delegateBadge;

    /// @dev The address of the ERC1155 token used for maintainers
    IERC1155 public maintainerBadge;

    /// @dev The configuration of the labor market.
    LaborMarketConfiguration public configuration;

    /// @dev Tracking the signals per service request.
    mapping(uint256 => uint256) public signalCount;

    /// @dev Tracking the service requests.
    mapping(uint256 => ServiceRequest) public serviceRequests;

    /// @dev Tracking the service submissions.
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    /// @dev Tracking the review signals.
    mapping(address => ReviewPromise) public reviewSignals;

    /// @dev Tracking whether an action has been performed.
    mapping(uint256 => mapping(address => mapping(bytes32 => bool)))
        public hasPerformed;

    /// @dev The service request id counter.
    uint256 public serviceId;

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(
        LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made.
    event RequestCreated(
        address indexed requester,
        uint256 indexed requestId,
        string indexed uri,
        address pToken,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(
        address indexed signaler,
        uint256 indexed quantity,
        uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(
        uint256 indexed requestId
    );

    /// @notice emitted when a service request is fulfilled.
    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
        address reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 indexed reviewScore
    );

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed submissionId,
        uint256 indexed payAmount,
        address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(
        address indexed claimer,
        uint256 indexed requestId,
        uint256 remainderAmount
    );

    /*
     * @notice Make sure that only addresses holding the delegate badge can call the function.
     */
    modifier onlyDelegate() {
        require(
            (delegateBadge.balanceOf(
                _msgSender(),
                configuration.delegateTokenId
            ) >= 1),
            "LaborMarket::permittedParticipant: Not a delegate."
        );
        _;
    }

    /*
     * @notice Make sure that only addresses conforming to the reputational barrier can call the function.
     */
    modifier permittedParticipant() {
        uint256 availableRep = _getAvailableReputation();
        require((
                availableRep >= configuration.reputationConfig.submitMin &&
                availableRep < configuration.reputationConfig.submitMax
            ), "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        _;
    }

    /*
     * @notice Make sure that only addresses holding the maintainer badge can call the function.
     */
    modifier onlyMaintainer() {
        require(
            (maintainerBadge.balanceOf(
                _msgSender(),
                configuration.maintainerTokenId
            ) >= 1),
            "LaborMarket::onlyMaintainer: Not a maintainer"
        );
        _;
    }

    /// @notice Initialize the labor market.
    function initialize(LaborMarketConfiguration calldata _configuration)
        external
        override
        initializer
    {
        _setConfiguration(_configuration);
    }

    /**
     * @notice Creates a service request.
     * @param pToken The address of the payment token.
     * @param pTokenQ The quantity of the payment token.
     * @param signalExp The signal deadline expiration.
     * @param submissionExp The submission deadline expiration.
     * @param enforcementExp The enforcement deadline expiration.
     * @param requestUri The uri of the service request data.
     * Requirements:
     * - A user has to be conform to the reputational restrictions imposed by the labor market.
     */
    function submitRequest(
        address pToken,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp,
        string calldata requestUri
    ) external onlyDelegate returns (uint256 requestId) {
        unchecked {
            ++serviceId;
        }

        // Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = IERC20(pToken).balanceOf(address(this));

        IERC20(pToken).transferFrom(_msgSender(), address(this), pTokenQ);

        uint256 pTokenAfter = IERC20(pToken).balanceOf(address(this));

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: pToken,
            pTokenQ: (pTokenAfter - pTokenBefore),
            signalExp: signalExp,
            submissionExp: submissionExp,
            enforcementExp: enforcementExp,
            uri: requestUri
        });

        serviceRequests[serviceId] = serviceRequest;

        emit RequestCreated(
            _msgSender(),
            serviceId,
            requestUri,
            pToken,
            pTokenQ,
            signalExp,
            submissionExp,
            enforcementExp
        );

        return serviceId;
    }

    /**
     * @notice Signals interest in fulfilling a service request.
     * @param requestId The id of the service request.
     */
    function signal(uint256 requestId) external permittedParticipant {
        require(
            block.timestamp <= serviceRequests[requestId].signalExp,
            "LaborMarket::signal: Signal deadline passed."
        );
        require(
            !hasPerformed[requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::signal: Already signaled."
        );

        uint256 signalStake = _baseStake();

        _lockReputation(_msgSender(), signalStake);

        hasPerformed[requestId][_msgSender()][HAS_SIGNALED] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(_msgSender(), requestId, signalStake);
    }

    /**
     * @notice Signals interest in reviewing a submission.
     * @param quantity The amount of submissions a maintainer is willing to review.
     */
    function signalReview(uint256 quantity) external onlyMaintainer {
        require(
            reviewSignals[_msgSender()].remainder == 0,
            "LaborMarket::signalReview: Already signaled."
        );

        uint256 signalStake = _baseStake();

        _lockReputation(_msgSender(), signalStake);

        reviewSignals[_msgSender()].total = quantity;
        reviewSignals[_msgSender()].remainder = quantity;

        emit ReviewSignal(_msgSender(), quantity, signalStake);
    }

    /**
     * @notice Allows a service provider to fulfill a service request.
     * @param requestId The id of the service request being fulfilled.
     * @param uri The uri of the service submission data.
     */
    function provide(uint256 requestId, string calldata uri)
        external
        returns (uint256 submissionId)
    {
        require(
            block.timestamp <= serviceRequests[requestId].submissionExp,
            "LaborMarket::provide: Submission deadline passed."
        );
        require(
            hasPerformed[requestId][_msgSender()][HAS_SIGNALED],
            "LaborMarket::provide: Not signaled."
        );
        require(
            !hasPerformed[requestId][_msgSender()][HAS_SUBMITTED],
            "LaborMarket::provide: Already submitted."
        );

        unchecked {
            ++serviceId;
        }

        ServiceSubmission memory serviceSubmission = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: requestId,
            timestamp: block.timestamp,
            uri: uri,
            scores: new uint256[](0),
            reviewed: false
        });

        serviceSubmissions[serviceId] = serviceSubmission;

        hasPerformed[requestId][_msgSender()][HAS_SUBMITTED] = true;

        _unlockReputation(_msgSender(), _baseStake());

        emit RequestFulfilled(_msgSender(), requestId, serviceId);

        return serviceId;
    }

    /**
     * @notice Allows a maintainer to review a service submission.
     * @param requestId The id of the service request being fulfilled.
     * @param submissionId The id of the service providers submission.
     * @param score The score of the service submission.
     */
    function review(
        uint256 requestId,
        uint256 submissionId,
        uint256 score
    ) external {
        require(
            submissionId <= serviceId,
            "LaborMarket::review: Submission does not exist."
        );
        require(
            block.timestamp <= serviceRequests[requestId].enforcementExp,
            "LaborMarket::review: Enforcement deadline passed."
        );

        require(
            reviewSignals[_msgSender()].remainder > 0,
            "LaborMarket::review: Not signaled."
        );
        require(
            !hasPerformed[submissionId][_msgSender()][HAS_REVIEWED],
            "LaborMarket::review: Already reviewed."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider != _msgSender(),
            "LaborMarket::review: Cannot review own submission."
        );

        score = enforcementCriteria.review(submissionId, score);

        serviceSubmissions[submissionId].scores.push(score);

        if (!serviceSubmissions[submissionId].reviewed)
            serviceSubmissions[submissionId].reviewed = true;

        hasPerformed[submissionId][_msgSender()][HAS_REVIEWED] = true;

        unchecked {
            --reviewSignals[_msgSender()].remainder;
        }

        _unlockReputation(
            _msgSender(),
            (_baseStake()) / reviewSignals[_msgSender()].total
        );

        emit RequestReviewed(_msgSender(), requestId, submissionId, score);
    }

    /**
     * @notice Allows a service provider to claim payment for a service submission.
     * @param submissionId The id of the service providers submission.
     */
    function claim(
        uint256 submissionId,
        address to,
        bytes calldata data
    ) external returns (uint256) {
        require(
            submissionId <= serviceId,
            "LaborMarket::claim: Submission does not exist."
        );
        require(
            !hasPerformed[submissionId][_msgSender()][HAS_CLAIMED],
            "LaborMarket::claim: Already claimed."
        );
        require(
            serviceSubmissions[submissionId].reviewed,
            "LaborMarket::claim: Not reviewed."
        );
        require(
            serviceSubmissions[submissionId].serviceProvider == _msgSender(),
            "LaborMarket::claim: Not service provider."
        );
        require(
            block.timestamp >=
                serviceRequests[serviceSubmissions[submissionId].requestId]
                    .enforcementExp,
            "LaborMarket::claim: Enforcement deadline not passed."
        );

        uint256 curveIndex = (data.length > 0)
            ? enforcementCriteria.verifyWithData(submissionId, data)
            : enforcementCriteria.verify(submissionId);

        uint256 amount = paymentCurve.curvePoint(curveIndex);

        hasPerformed[submissionId][_msgSender()][HAS_CLAIMED] = true;

        IERC20(
            serviceRequests[serviceSubmissions[submissionId].requestId].pToken
        ).transfer(to, amount);

        emit RequestPayClaimed(_msgSender(), submissionId, amount, to);

        return amount;
    }

    /**
     * @notice Allows a service requester to claim the remainder of funds not allocated to service providers.
     * @param requestId The id of the service request.
     */
    function claimRemainder(uint256 requestId) public {
        require(
            serviceRequests[requestId].serviceRequester == _msgSender(),
            "LaborMarket::claimRemainder: Not service requester."
        );
        require(
            block.timestamp >= serviceRequests[requestId].enforcementExp,
            "LaborMarket::claimRemainder: Enforcement deadline not passed."
        );
        require(
            !hasPerformed[requestId][_msgSender()][HAS_CLAIMED_REMAINDER],
            "LaborMarket::claimRemainder: Already claimed."
        );
        uint256 totalClaimable = enforcementCriteria.getRemainder(requestId);

        hasPerformed[requestId][_msgSender()][HAS_CLAIMED_REMAINDER] = true;

        IERC20(serviceRequests[requestId].pToken).transfer(
            _msgSender(),
            totalClaimable
        );

        emit RemainderClaimed(_msgSender(), requestId, totalClaimable);
    }

    /**
     * @notice Allows a service requester to withdraw a request.
     * @param requestId The id of the service requesters request.
     * Requirements:
     * - The request must not have been signaled.
     */
    function withdrawRequest(uint256 requestId) external onlyDelegate {
        require(
            serviceRequests[requestId].serviceRequester == _msgSender(),
            "LaborMarket::withdrawRequest: Not service requester."
        );
        require(
            signalCount[requestId] < 1,
            "LaborMarket::withdrawRequest: Already active."
        );
        address pToken = serviceRequests[requestId].pToken;
        uint256 amount = serviceRequests[requestId].pTokenQ;

        delete serviceRequests[requestId];

        IERC20(pToken).transfer(_msgSender(), amount);

        emit RequestWithdrawn(requestId);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the service request data.
     * @param _requestId The id of the service requesters request.
     */
    function getRequest(uint256 _requestId)
        external
        view
        returns (ServiceRequest memory)
    {
        return serviceRequests[_requestId];
    }

    /**
     * @notice Returns the service submission data.
     * @param _submissionId The id of the service providers submission.
     */
    function getSubmission(uint256 _submissionId)
        external
        view
        returns (ServiceSubmission memory)
    {
        return serviceSubmissions[_submissionId];
    }

    /**
     * @notice Returns the market configuration.
     */
    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory)
    {
        return configuration;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ReputationModule-lockReputation}.
     */
    function _lockReputation(address account, uint256 amount) internal {
        reputationModule.lockReputation(account, amount);
    }

    /**
     * @dev See {ReputationModule-unlockReputation}.
     */
    function _unlockReputation(address account, uint256 amount) internal {
        reputationModule.unlockReputation(account, amount);
    }

    /**
     * @dev See {ReputationModule-freezeReputation}.
     */
    function _freezeReputation(address account, uint256 amount) internal {
        reputationModule.freezeReputation(account, amount);
    }

    /**
     * @dev Handle all the logic for configuration on deployment of a new LaborMarket.
     */
    function _setConfiguration(LaborMarketConfiguration calldata _configuration)
        internal
    {
        /// @dev Connect to the higher level network to pull the active states.
        network = LaborMarketNetwork(_configuration.network);

        /// @dev Configure the Labor Market state control.
        enforcementCriteria = EnforcementCriteriaInterface(
            _configuration.enforcementModule
        );

        /// @dev Configure the Labor Market pay curve.
        paymentCurve = PayCurveInterface(_configuration.paymentModule);

        /// @dev Configure the Labor Market reputation module.
        reputationModule = ReputationModuleInterface(
            _configuration.reputationModule
        );

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_configuration.delegateBadge);
        maintainerBadge = IERC1155(_configuration.maintainerBadge);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit LaborMarketConfigured(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ReputationModule-getAvailableReputation}
     */

    function _getAvailableReputation() internal view returns (uint256) {
        return
            reputationModule.getAvailableReputation(
                address(this),
                _msgSender()
            );
    }

    /**
     * @dev See {ReputationModule-getMarketReputationConfig}
     */

    function _baseStake() internal view returns (uint256) {
        return
            reputationModule
                .getMarketReputationConfig(address(this))
                .signalStake;
    }

    /**
     * @dev Delegatable ETH support
     */
    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore, ContextUpgradeable)
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {PayCurveInterface} from "../Payment/interfaces/PayCurveInterface.sol";

// TODO: Add multiple reviewers (get average)
// TODO: Find good averaging function
// TODO: Find good sorting function

contract Best5EnforcementCriteria {
    /// @notice Best 5 submissions on a curve get paid
    /// @notice Allow any number of submissions
    /// @notice Expects an N=100 curve with a frequency of x, where basepayout multiplier for winning submissions is set by the radius.

    /// @dev Submission format
    struct Submission {
        uint256 submissionId;
        uint256 score;
    }

    /// @dev Tracks all the submissions for a market to a requestId.
    mapping(address => mapping(uint256 => Submission[]))
        public marketSubmissions;

    /// @dev Tracks the winning submissions and their curve index
    mapping(uint256 => uint256) public submissionToIndex;

    /// @dev Tracks whether or not a submission has been paid out
    mapping(address => mapping(uint256 => bool)) public isSorted;

    /// @dev Max amount of winners
    uint256 private constant MAX_WINNERS = 5;

    /**
     * @notice Allows maintainer to review with either 0 (bad) or 1 (good)
     * @param submissionId The submission to review
     * @param score The score to give the submission
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        require(score <= 100, "EnforcementCriteria::review: invalid score");

        Submission memory submission = Submission({
            submissionId: submissionId,
            score: score
        });

        marketSubmissions[msg.sender][getRid(submissionId)].push(submission);

        return score;
    }

    /**
     * @notice Sorts the submissions and returns the index of the submission
     * @param submissionId The submission to verify
     */
    function verify(uint256 submissionId) external returns (uint256) {
        uint256 requestId = getRid(submissionId);

        if (!isSorted[msg.sender][requestId]) {
            sort(requestId);
        }

        return submissionToIndex[submissionId];
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sorts the submissions for a given requestId
    function sort(uint256 requestId) internal {
        for (
            uint256 i;
            i < marketSubmissions[msg.sender][requestId].length;
            ++i
        ) {
            for (
                uint256 j;
                j < marketSubmissions[msg.sender][requestId].length - 1;
                ++j
            ) {
                if (
                    marketSubmissions[msg.sender][requestId][j].score <
                    marketSubmissions[msg.sender][requestId][j + 1].score
                ) {
                    Submission memory temp = marketSubmissions[msg.sender][
                        requestId
                    ][j];
                    marketSubmissions[msg.sender][requestId][
                        j
                    ] = marketSubmissions[msg.sender][requestId][j + 1];
                    marketSubmissions[msg.sender][requestId][j + 1] = temp;
                }
            }
        }

        for (uint256 i = 1; i < 6; i++) {
            submissionToIndex[
                marketSubmissions[msg.sender][requestId][i].submissionId
            ] = i * 20;
        }

        isSorted[msg.sender][requestId] = true;
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the curve index for a given submission.
    function getIndex(uint256 submissionId) external view returns (uint256) {
        return submissionToIndex[submissionId];
    }

    /// @dev Returns the (sorted) submissions for a market
    function getSubmissions(address market, uint256 requestId)
        external
        view
        returns (Submission[] memory)
    {
        return marketSubmissions[market][requestId];
    }

    /// @dev Returns the remainder that is claimable by the requester of a requestId
    function getRemainder(uint256 requestId) public returns (uint256) {
        if (marketSubmissions[msg.sender][requestId].length >= MAX_WINNERS) {
            return 0;
        } else {
            uint256 claimable;

            LaborMarketInterface market = LaborMarketInterface(msg.sender);
            PayCurveInterface curve = PayCurveInterface(
                market.getConfiguration().paymentModule
            );
            uint256 submissions = marketSubmissions[msg.sender][requestId]
                .length;

            for (uint256 i; i < (MAX_WINNERS - submissions); i++) {
                uint256 index = ((submissions + i) + 1) * 20;
                claimable += curve.curvePoint(index);
            }
            return claimable;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {PayCurveInterface} from "../Payment/interfaces/PayCurveInterface.sol";

contract FCFSEnforcementCriteria {
    /// @dev First come first servce on linear decreasing payout curve
    /// @dev First 100 submissions that are marked as good get paid

    mapping(address => mapping(uint256 => uint256)) public submissionToIndex;

    /// @dev Max number of submissions that can be paid out
    uint256 public constant MAX_SCORE = 10;

    /// @dev Tracks the number of submissions per requestId that have been paid out
    mapping(uint256 => uint256) public payCount;

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows maintainer to review with either 0 (bad) or 1 (good)
     * @param submissionId The submission to review
     * @param score The score to give the submission
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        uint256 requestId = getRid(submissionId);

        require(score <= 1, "EnforcementCriteria::review: invalid score");

        if (score > 0 && payCount[requestId] < MAX_SCORE) {
            submissionToIndex[msg.sender][submissionId] = payCount[requestId];

            unchecked {
                payCount[requestId]++;
            }
        }

        return score;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets the curve index of a submission
    function verify(uint256 submissionId) external view returns (uint256) {
        return submissionToIndex[msg.sender][submissionId];
    }

    /// @dev Returns the remainder that is claimable by the requester of a requestId
    function getRemainder(uint256 requestId) public returns (uint256) {
        if (payCount[requestId] >= MAX_SCORE) {
            return 0;
        } else {
            uint256 claimable;
            LaborMarketInterface market = LaborMarketInterface(msg.sender);
            PayCurveInterface curve = PayCurveInterface(
                market.getConfiguration().paymentModule
            );
            for (uint256 i; i < (MAX_SCORE - payCount[requestId]); i++) {
                uint256 index = (payCount[requestId] + i);
                claimable += curve.curvePoint(index);
            }
            return claimable;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface EnforcementCriteriaInterface {
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256);

    function verify(uint256 submissionId) external returns (uint256);

    function verifyWithData(uint256 submissionId, bytes calldata data)
        external
        returns (uint256);

    function getRemainder(uint256 requestId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: look into https://github.com/paulrberg/prb-math
import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";

contract LikertEnforcementCriteria {
    /// @dev Tracks the scores given to service submissions.
    mapping(address => mapping(uint256 => Scores)) private submissionToScores;

    /// @dev Tracks the amount of submitters per Likert scale score for a requestId.
    mapping(address => mapping(uint256 => mapping(Likert => uint256)))
        private bucketCount;

    /// @dev The scoring scale.
    enum Likert {
        BAD,
        OK,
        GOOD
    }

    /// @dev The scores given to a service submission.
    struct Scores {
        uint256[] scores;
        uint256 avg;
    }

    /// @dev The count and allocation per bucket
    struct ClaimableBucket {
        uint256 count;
        uint256 allocation;
    }

    /**
     * @notice Allows a maintainer to review a submission.
     * @param submissionId The submission to review.
     * @param score The score to give the submission.
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        require(
            score <= uint256(Likert.GOOD),
            "EnforcementCriteria::review: invalid score"
        );

        uint256 requestId = getRid(submissionId);

        // Update the bucket count for old score
        if (submissionToScores[msg.sender][submissionId].scores.length != 0) {
            unchecked {
                --bucketCount[msg.sender][requestId][
                    Likert(submissionToScores[msg.sender][submissionId].avg)
                ];
            }
        }

        // Add the new score
        submissionToScores[msg.sender][submissionId].scores.push(score);

        // Calculate the average
        submissionToScores[msg.sender][submissionId].avg = _getAvg(
            submissionToScores[msg.sender][submissionId].scores
        );

        // Update the bucket count for new score
        unchecked {
            ++bucketCount[msg.sender][requestId][
                Likert(submissionToScores[msg.sender][submissionId].avg)
            ];
        }

        return uint256(Likert(score));
    }

    /**
     * @notice Returns the point on the payment curve for a submission.
     * @param submissionId The submission to calculate the point for.
     * @return The point on the payment curve.
     */
    function verify(uint256 submissionId) external view returns (uint256) {
        uint256 x;

        uint256 score = submissionToScores[msg.sender][submissionId].avg;

        uint256 alloc = (1e18 /
            getTotalBucket(msg.sender, Likert(score), getRid(submissionId)));

        LaborMarketInterface market = LaborMarketInterface(msg.sender);
        uint256 pTokens = market
            .getRequest(market.getSubmission(submissionId).requestId)
            .pTokenQ / 1e18;

        if (score == uint256(Likert.BAD)) {
            x = sqrt(alloc * (pTokens * 0));
        } else if (score == uint256(Likert.OK)) {
            x = sqrt(alloc * ((pTokens * 20) / 100));
        } else if (score == uint256(Likert.GOOD)) {
            x = sqrt(alloc * ((pTokens * 80) / 100));
        }

        return x;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the total number of submissions for a given score.
    function getTotalBucket(
        address market,
        Likert score,
        uint256 requestId
    ) internal view returns (uint256) {
        return bucketCount[market][requestId][score];
    }

    /// @notice Returns the sqrt of a number.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        // Stolen from prbmath
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    /// @notice Returns the average of an array of numbers.
    function _getAvg(uint256[] memory scores) internal pure returns (uint256) {
        uint256 cumScore;
        uint256 qScores = scores.length;

        for (uint256 i; i < qScores; ++i) {
            cumScore += scores[i];
        }

        return cumScore / qScores;
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount claimable for a service request.
    function getRemainder(uint256 requestId) public view returns (uint256) {
        uint256 claimable;

        LaborMarketInterface market = LaborMarketInterface(msg.sender);
        uint256 pTokens = market.getRequest(requestId).pTokenQ;

        ClaimableBucket[3] memory buckets = [
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.BAD, requestId),
                allocation: ((pTokens * 0))
            }),
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.OK, requestId),
                allocation: (((pTokens * 20) / 100))
            }),
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.GOOD, requestId),
                allocation: (((pTokens * 80) / 100))
            })
        ];

        for (uint256 i; i < buckets.length; ++i) {
            if (buckets[i].count > 0) {
                claimable += buckets[i].allocation;
            }
        }

        return (pTokens - claimable);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {PayCurveInterface} from "../Payment/interfaces/PayCurveInterface.sol";

contract MerkleEnforcementCriteria is Ownable {
    /// @dev Merkle verification of submissions
    mapping(uint256 => bytes32) public requestToMerkleRoot;

    /// @dev Track indexes of submissions
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public requestToSubmissionToIndex;

    function setRoot(uint256 requestId, bytes32 merkleRoot) public onlyOwner {
        requestToMerkleRoot[requestId] = merkleRoot;
    }

    /**
     * @param submissionId The submission to review
     * @param index The index to give the submission
     */
    function review(uint256 submissionId, uint256 index)
        external
        returns (uint256)
    {
        uint256 requestId = getRid(submissionId);

        requestToSubmissionToIndex[msg.sender][requestId][submissionId] = index;

        return index;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets the curve index of a submission
    /// @dev requires that the submission is in the merkle tree
    function verifyWithData(uint256 submissionId, bytes calldata data)
        external
        view
        returns (uint256)
    {
        uint256 qProofs = data.length / 32;
        bytes32[] memory proofs = new bytes32[](qProofs);

        uint256 requestId = getRid(submissionId);

        assembly {
            // Free memory pointer
            let mptr := mload(0x40)

            // Calldatasize
            let size := calldatasize()

            // Copy relevant calldata to memory
            calldatacopy(mptr, 0x64, size)

            // Start at 0
            let i := 0

            // First element of array at 0x20
            let index := 0x20

            // Empty proof
            let proof := 0x00

            for {

            } lt(mul(i, 0x20), sub(size, 0x64)) {

            } {
                // Fetch proof
                proof := mload(add(mptr, mul(i, 0x20)))

                // Store proof at index in memory
                mstore(add(proofs, index), proof)

                // Increase loop
                i := add(i, 1)
                index := add(index, 0x20)
            }
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(submissionId, msg.sender)))
        );

        bool ok = MerkleProof.verify({
            proof: proofs,
            root: requestToMerkleRoot[requestId],
            leaf: leaf
        });

        require(ok, "EnforcementCriteria::verifyWithData: invalid proof");

        return requestToSubmissionToIndex[msg.sender][requestId][submissionId];
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface PayCurveInterface {
    function curvePoint(uint256 x) 
        external 
        returns (
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { PayCurveInterface } from "./interfaces/PayCurveInterface.sol";

contract PayCurve is 
    PayCurveInterface 
{
    function curvePoint(uint256 x) 
        public 
        pure 
        returns (
            uint256
        ) 
    {
        return x**2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PayCurveInterface } from "./interfaces/PayCurveInterface.sol";

contract PaymentModule {
    modifier onlyMarket() {
        _;
    }

    function earned(
          address payCurve
        , uint256 x
    ) 
        public 
        returns (
            uint256
        ) 
    {
        return PayCurveInterface(payCurve).curvePoint(x);
    }

    function claim(
          address payCurve
        , uint256 x
    ) 
        public 
        returns (
            uint256
        ) 
    {
        uint256 amount = earned(
              payCurve
            , x
        );
        
        return amount;
    }

    function pay() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ReputationEngineInterface {
    struct ReputationAccountInfo {
        uint256 locked;
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function initialize(
          address _module
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external;

    function setDecayConfig(
        uint256 _decayRate,
        uint256 _decayInterval
    ) 
        external;

    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        external;


    function lockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function unlockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function getAvailableReputation(address _account)
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(address _account)
        external
        view
        returns (
            uint256
        );

    function getReputationAccountInfo(address _account)
        external
        view
        returns (
            ReputationAccountInfo memory
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationEngineInterface } from "./ReputationEngineInterface.sol";

interface ReputationModuleInterface {
    struct ReputationMarketConfig {
        address reputationEngine;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    function createReputationEngine(
          address _implementation
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external
        returns (
            address
        );

    function useReputationModule(
          address _laborMarket
        , ReputationMarketConfig calldata _repConfig
    )
        external;

    function setMarketRepConfig(
        ReputationMarketConfig calldata _repConfig
    )
        external;

    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        external;


    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        external;

    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        external;

    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getReputationAccountInfo(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            ReputationEngineInterface.ReputationAccountInfo memory
        );

    function getMarketReputationConfig(address _laborMarket)
        external
        view
        returns (
            ReputationMarketConfig memory
        );

    function getReputationEngine(address _laborMarket) 
        external
        view
        returns (
            address
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationEngineInterface } from "./interfaces/ReputationEngineInterface.sol";

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// TODO: Add the Badger functions for minting and revoking.
// TODO: Should we apply decay on freeze and on unlock? Just on freeze? The getAvailableReputation
//       function accounts for the decay for external checks.
// TODO: Should decayed reputation emit its own event?

contract ReputationEngine is 
      ReputationEngineInterface
    , OwnableUpgradeable
{
    address public module;

    IERC1155 public baseToken;
    uint256 public baseTokenId;

    uint256 public decayRate;
    uint256 public decayInterval;

    mapping(address => ReputationAccountInfo) public accountInfo;

    event ReputationFrozen (
        address indexed account,
        uint256 frozenUntilEpoch
    );

    event ReputationLocked (
        address indexed account,
        uint256 amount
    );

    event ReputationUnlocked (
        address indexed account,
        uint256 amount
    );

    event ReputationDecayed (
        address indexed account,
        uint256 amount
    );

    event ReputationDecayConfigured (
        uint256 decayRate,
        uint256 decayInterval
    );

    modifier onlyModule() {
        require(msg.sender == module, "ReputationToken: Only the module can call this function.");
        _;
    }

    function initialize(
          address _module
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    ) 
        external
        override
        initializer
    {
        module = _module;
        baseToken = IERC1155(_baseToken);
        baseTokenId = _baseTokenId;
        decayRate = _decayRate;
        decayInterval = _decayInterval;
    }

    /**
     * @notice Change the decay parameters of the reputation token.
     * @param _decayRate The amount of reputation decay per epoch.
     * @param _decayInterval The block length of an epoch.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setDecayConfig(
          uint256 _decayRate
        , uint256 _decayInterval
    ) 
        override
        external 
        onlyOwner 
    {
        decayRate = _decayRate;
        decayInterval = _decayInterval;

        emit ReputationDecayConfigured(_decayRate, _decayInterval);
    }

    /**
     * @notice Freeze a user's reputation for a given number of epochs.
     * @param _frozenUntilEpoch The epoch that reputation will no longer be frozen.
     * @dev Calculates decay and applies it before freezing.
     *
     * Requirements:
     * - `_frozenUntilEpoch` must be greater than the current epoch.
     */
    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        override
        external
        onlyModule
    {
        ReputationAccountInfo storage info = accountInfo[_account];
        uint256 decay = getPendingDecay(_account);

        info.frozenUntilEpoch = _frozenUntilEpoch;
        info.locked += decay;
        info.lastDecayEpoch = block.timestamp;

        emit ReputationDecayed(_account, decay);
        emit ReputationFrozen(_account, _frozenUntilEpoch);
    }

    /**
     * @notice Lock reputation for a given account.
     * @param _account The address to lock reputation for.
     * @param _amount The amount of reputation to lock.
     */
    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        external 
        onlyModule
    {
        uint256 decay = getPendingDecay(_account);

        accountInfo[_account].locked += _amount + decay;

        emit ReputationDecayed(_account, decay);
        emit ReputationLocked(_account, _amount);
    }

    /**
     * @notice Reduce the amount of locked reputation for a given account.
     * @param _account The address to retreive decay of.
     * @param _amount The amount of reputation to unlock.
     */
    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        external 
        onlyModule
    {
        uint256 decay = getPendingDecay(_account);

        accountInfo[_account].locked -= _amount + decay;

        emit ReputationDecayed(_account, decay);
        emit ReputationUnlocked(_account, _amount);
    }

    /**
     * @notice Returns the available reputation token balance after accounting for the
     *         amounts locked and pending decay.
     * @param _account The address to query the balance of.
     * Requirements:
     * - If a user's balance is frozen, no reputation is available.
     */
    function getAvailableReputation(address _account)
        override
        external
        view
        returns (
            uint256
        )
    {
        ReputationAccountInfo memory info = accountInfo[_account];

        if (info.frozenUntilEpoch > block.timestamp) return 0;

        uint256 decayed = getPendingDecay(_account);

        return (
            baseToken.balanceOf(
                _account,
                baseTokenId
            ) - info.locked - decayed
        );
    }

    /**
     * @notice Get the amount of reputation of an account that has decayed since 
     *         the last decay epoch.
     * @param _account The address to retreive decay of.
     * @dev This function assumes that anywhere decay is written to storage, the
     *      account's frozenUntilEpoch is set to 0.
     */
    function getPendingDecay(address _account)
        override
        public
        view
        returns (
            uint256
        )
    {
        ReputationAccountInfo memory info = accountInfo[_account];

        if (info.frozenUntilEpoch > block.timestamp || decayRate == 0) {
            return 0;
        }

        return (((block.timestamp - info.lastDecayEpoch - info.frozenUntilEpoch) /
            decayInterval) * decayRate);
    }

    /**
     * @notice Get the reputation info of an account.
     * @param _account The address to retreive reputation info of.
     */
    function getReputationAccountInfo(address _account)
        override
        external
        view
        returns (
            ReputationAccountInfo memory
        )
    {
        return accountInfo[_account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationEngineInterface } from "./interfaces/ReputationEngineInterface.sol";
import { ReputationModuleInterface } from "./interfaces/ReputationModuleInterface.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract ReputationModule is ReputationModuleInterface {
    using Clones for address;

    address public network;

    mapping(address => ReputationMarketConfig) public laborMarketRepConfig;

    event ReputationEngineCreated (
          address indexed reputationEngine
        , address indexed baseToken
        , uint256 indexed baseTokenId
        , address owner
        , uint256 decayRate
        , uint256 decayInterval
    );

    event MarketReputationConfigured (
          address indexed market
        , address indexed reputationEngine
        , uint256 signalStake
        , uint256 submitMin
        , uint256 submitMax
    );

    constructor(
        address _network
    ) {
        network = _network;
    }

    /**
     * @notice Create a new Reputation Token.
     * @param _implementation The address of ReputationEngine implementation.
     * @param _baseToken The address of the base ERC1155.
     * @param _baseTokenId The tokenId of the base ERC1155.
     * @param _decayRate The amount of reputation decay per epoch.
     * @param _decayInterval The block length of an epoch.
     * Requirements:
     * - Only the network can call this function in the factory.
     */
    function createReputationEngine(
          address _implementation
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        override
        external
        returns (
            address
        )
    {
        address reputationEngineAddress = _implementation.clone();

        ReputationEngineInterface reputationEngine = ReputationEngineInterface(
            reputationEngineAddress
        );

        reputationEngine.initialize(
              address(this)
            , _baseToken
            , _baseTokenId
            , _decayRate
            , _decayInterval
        );

        emit ReputationEngineCreated(
              reputationEngineAddress
            , _baseToken
            , _baseTokenId
            , msg.sender
            , _decayRate
            , _decayInterval
        );

        return reputationEngineAddress;
    }

    /**
     * @notice Initialize a new Labor Market as using Reputation.
     * @param _laborMarket The address of the new Labor Market.
     * @param _repConfig The Labor Market level config of Reputation.
     * Requirements:
     * - Only the network can call this function in the factory.
     */
    function useReputationModule(
          address _laborMarket
        , ReputationMarketConfig calldata _repConfig
    )
        override
        public
    {
        require(msg.sender == network, "ReputationModule: Only network can call this.");

        laborMarketRepConfig[_laborMarket] = _repConfig;

        emit MarketReputationConfigured(
              _laborMarket
            , _repConfig.reputationEngine
            , _repConfig.signalStake
            , _repConfig.submitMin
            , _repConfig.submitMax
        );
    }

    /**
     * @notice Change the parameters of the Labor Market Reputation config.
     * @param _repConfig The Labor Market level config of Reputation.
     * @dev This function is only callable by Labor Markets that have already been
     *      initialized with the Reputation module by the Network.
     * Requirements:
     * - The Labor Market must already have a configuration.
     */
    function setMarketRepConfig(
        ReputationMarketConfig calldata _repConfig
    )
        override
        public 
    {
        require(_callerReputationEngine() != address(0), "ReputationModule: This Labor Market does not exist.");

        laborMarketRepConfig[msg.sender] = _repConfig;

        emit MarketReputationConfigured(
              msg.sender
            , _repConfig.reputationEngine
            , _repConfig.signalStake
            , _repConfig.submitMin
            , _repConfig.submitMax
        );
    }

    /**
     * @dev See {reputationEngine-freezeReputation}.
     */
    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    ) 
        override
        public
    {
        _freezeReputation(_callerReputationEngine(), _account, _frozenUntilEpoch);
    }

    /**
     * @dev See {ReputationEngine-lockReputation}.
     * @dev The internal call makes the module the msg.sender which is permissioned
     *      to make balance changes within the ReputationEngine.
     */
    function _freezeReputation(
          address _reputationEngine
        , address _account
        , uint256 _frozenUntilEpoch
    )
        internal
    {
        ReputationEngineInterface(_reputationEngine).freezeReputation(
              _account
            , _frozenUntilEpoch
        );
    }

    /**
     * @dev See {ReputationEngine-lockReputation}.
     */
    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        public
    {
        _lockReputation(_callerReputationEngine(), _account, _amount);
    }

    /**
     * @dev See {ReputationEngine-lockReputation}.
     * @dev The internal call makes the module the msg.sender which is permissioned
     *      to make balance changes within the ReputationEngine.
     */
    function _lockReputation(
          address _reputationEngine
        , address _account
        , uint256 _amount
    ) 
        internal
    {
        ReputationEngineInterface(_reputationEngine).lockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationEngine-unlockReputation}.
     */
    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        public
    {
        _unlockReputation(_callerReputationEngine(), _account, _amount);
    }
    
    /**
     * @dev The internal call makes the module the msg.sender which is permissioned
     *      to make balance changes within the ReputationEngine.
     */
    function _unlockReputation(
          address _reputationEngine
        , address _account
        , uint256 _amount
    ) 
        internal
    {
        ReputationEngineInterface(_reputationEngine).unlockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationEngine-getAvailableReputation}.
     */
    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationEngineInterface(
            getReputationEngine(_laborMarket)
        ).getAvailableReputation(_account);
    }

    /**
     * @dev See {ReputationEngine-getPendingDecay}.
     */
    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationEngineInterface(
            getReputationEngine(_laborMarket)
        ).getPendingDecay(_account);
    }

    /**
     * @dev See {ReputationEngine-getReputationAccountInfo}.
     */
    function getReputationAccountInfo(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            ReputationEngineInterface.ReputationAccountInfo memory
        )
    {
        return ReputationEngineInterface(
            getReputationEngine(_laborMarket)
        ).getReputationAccountInfo(_account);
    }

    /**
     * @notice Retreive the reputation configuration parameters for the Labor Market.
     * @param _laborMarket The address of the Labor Market.
     */
    function getMarketReputationConfig(address _laborMarket)
        override
        public
        view
        returns (
            ReputationMarketConfig memory
        )
    {
        return laborMarketRepConfig[_laborMarket];
    }

    /**
     * @notice Retreive the ReputationEngine implementation for the Labor Market.
     * @param _laborMarket The address of the Labor Market.
     */
    function getReputationEngine(address _laborMarket)
        override
        public
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[_laborMarket].reputationEngine;
    }

    /**
     * @dev Helper function to get the ReputationEngine address for the caller.
     * @dev By limiting the caller to a Labor Market, we can ensure that the
     *      caller is a valid Labor Market and can only interact with its own
     *      ReputationEngine.
     */
    function _callerReputationEngine()
        internal
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[msg.sender].reputationEngine;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {LaborMarketVersionsInterface} from "./LaborMarketVersionsInterface.sol";

interface LaborMarketFactoryInterface is LaborMarketVersionsInterface {
    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
     * @param _deployer The address that will be the deployer of the Labor Market contract.
     * @param _configuration The struct containing the config of the Market being created.
     */
    function createLaborMarket(
        address _implementation,
        address _deployer,
        LaborMarketConfiguration calldata _configuration
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface LaborMarketNetworkInterface {
    function setCapacityImplementation(address _implementation)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {LaborMarketConfigurationInterface} from "../../LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

interface LaborMarketVersionsInterface is LaborMarketConfigurationInterface {
    /*//////////////////////////////////////////////////////////////
                                SCHEMAS
    //////////////////////////////////////////////////////////////*/

    /// @dev The schema of a version.
    struct Version {
        address owner;
        bytes32 licenseKey;
        uint256 amount;
        bool locked;
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows configuration to specific versions.
     * @dev This enables the ability to have Enterprise versions as well as public versions. None of this
     *      state is immutable as a license model may change in the future and updates here do not impact
     *      Labor Markets that are already running.
     * @param _implementation The implementation address.
     * @param _owner The owner of the version.
     * @param _tokenAddress The token address.
     * @param _tokenId The token ID.
     * @param _amount The amount that this user will have to pay.
     * @param _locked Whether or not this version has been made immutable.
     */
    function setVersion(
        address _implementation,
        address _owner,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _locked
    ) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Build the version key for a version and a sender.
     * @dev If the license for a version is updated, then the previous fundings
     *      will be lost and no longer active unless the version is reverted back
     *      to the previous configuration.
     * @param _implementation The implementation address.
     * @return The version key.
     */
    function getVersionKey(address _implementation)
        external
        view
        returns (bytes32);

    /**
     * @notice Builds the license key for a version and a sender.
     * @param _versionKey The version key.
     * @param _sender The message sender address.
     * returns The license key for the message sender.
     */
    function getLicenseKey(bytes32 _versionKey, address _sender)
        external
        pure
        returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Core dependencies.
import { LaborMarketFactoryInterface } from "./interfaces/LaborMarketFactoryInterface.sol";
import { LaborMarketVersions } from "./LaborMarketVersions.sol";
import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";

contract LaborMarketFactory is
      LaborMarketFactoryInterface
    , LaborMarketVersions
{
    constructor(address _implementation)
        LaborMarketVersions(_implementation)
    {}

    /**
     * @notice Allows an individual to deploy a new Labor Market given they meet the version funding requirements.
     * @param _implementation The address of the implementation to be used.
     * @param _deployer The address that will be the deployer of the Labor Market contract.
     * @param _configuration The struct containing the config of the Market being created.
     */
    function createLaborMarket( 
          address _implementation
        , address _deployer
        , LaborMarketConfiguration calldata _configuration
    )
        override
        public
        virtual
        returns (
            address laborMarketAddress
        )
    {
        /// @dev Load the version.
        Version memory version = versions[_implementation];

        /// @dev Get the users license key to determine how much funding has been provided.
        /// @notice Can deploy for someone but must have the cost covered themselves.
        bytes32 licenseKey = getLicenseKey(
              version.licenseKey
            , _msgSender()
        );

        /// @dev Deploy the Labor Market contract for the deployer chosen.
        laborMarketAddress = _createLaborMarket(
              _implementation
            , licenseKey
            , version.amount
            , _deployer
            , _configuration
        );
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Funds a new Labor Market when the license model is enabled and 
     *         the user has transfered their license to this contract. The license, is a 
     *         lifetime license.
     * @param _from The address of the account who owns the created Labor Market.
     * @return Selector response of the license token successful transfer.
     */
    function onERC1155Received(
          address 
        , address _from
        , uint256 _id
        , uint256 _amount
        , bytes memory _data
    ) 
        override 
        public 
        returns (
            bytes4
        ) 
    {
        /// @dev Return the typical ERC-1155 response if transfer is not intended to be a payment.
        if(bytes(_data).length == 0) {
            return this.onERC1155Received.selector;
        }
        
        /// @dev Recover the implementation address from `_data`.
        address implementation = abi.decode(
              _data
            , (address)
        );

        /// @dev Confirm that the token being transferred is the one expected.
        require(
              keccak256(
                  abi.encodePacked(
                        _msgSender()
                      , _id 
                  )
              ) == versions[implementation].licenseKey
            , "LaborMarketFactory::onERC1155Received: Invalid license key."
        );

        /// @dev Get the version license key to track the funding of the msg sender.
        bytes32 licenseKey = getLicenseKey(
              versions[implementation].licenseKey
            , _from
        );

        /// @dev Fund the deployment of the Labor Market contract to 
        ///      the account covering the cost of the payment (not the transaction sender).
        versionKeyToFunded[licenseKey] += _amount;

        /// @dev Return the ERC1155 success response.
        return this.onERC1155Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL PROTOCOL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows protocol Governors to execute protocol level transaction.
     * @dev This enables the ability to execute pre-built transfers without having to 
     *      explicitly define what tokens this contract can receive.
     * @param _to The address to execute the transaction on.
     * @param _data The data to pass to the receiver.
     * @param _value The amount of ETH to send with the transaction.
     */
    function execTransaction(
          address _to
        , bytes calldata _data
        , uint256 _value
    )
        external
        virtual
        payable
        onlyOwner
    {
        /// @dev Make the call.
        (
              bool success
            , bytes memory returnData
        ) = _to.call{value: _value}(_data);

        /// @dev Force that the transfer/transaction emits a successful response. 
        require(
              success
            , string(returnData)
        );
    }

    /**
     * @notice Signals to external callers that this is a Badger contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) 
        override
        public
        view
        returns (
            bool
        ) 
    {
        return (
               _interfaceId == type(LaborMarketFactoryInterface).interfaceId
            || super.supportsInterface(_interfaceId)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LaborMarketNetworkInterface } from "./interfaces/LaborMarketNetworkInterface.sol";
import { LaborMarketFactory } from "./LaborMarketFactory.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketNetwork is LaborMarketFactory {
    IERC20 public capacityToken;

    constructor(
        address _factoryImplementation,
        address _capacityImplementation
    ) LaborMarketFactory(_factoryImplementation) {
        capacityToken = IERC20(_capacityImplementation);
    }

    /**
     * @notice Allows the owner to set the capacity token implementation.
     * @param _implementation The address of the reputation token.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setCapacityImplementation(address _implementation)
        external
        virtual
        onlyOwner
    {
        capacityToken = IERC20(_implementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/// @dev Core dependencies.
import {LaborMarketVersionsInterface} from "./interfaces/LaborMarketVersionsInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @dev Helpers.
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {LaborMarketInterface} from "../LaborMarket/interfaces/LaborMarketInterface.sol";
import {ReputationModuleInterface} from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";

/// @dev Supported interfaces.
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract LaborMarketVersions is
    LaborMarketVersionsInterface,
    Ownable,
    ERC1155Holder
{
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                            PROTOCOL STATE
    //////////////////////////////////////////////////////////////*/

    /// @dev All of the versions that are actively running.
    ///      This also enables the ability to self-fork ones product.
    mapping(address => Version) public versions;

    /// @dev Tracking the versions of deployment that one has funded the cost for.
    mapping(bytes32 => uint256) public versionKeyToFunded;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Announces when a Version configuration is updated through the protocol Factory.
    event VersionUpdated(
        address indexed implementation,
        Version indexed version
    );

    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(
        address indexed marketAddress,
        address indexed owner,
        address indexed implementation
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _implementation) {
        /// @dev Initialize the foundational version of the Labor Market primitive.
        _setVersion(
            _implementation,
            _msgSender(),
            keccak256(abi.encodePacked(address(0), uint256(0))),
            0,
            false
        );
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * See {LaborMarketVersions._setVersion}
     *
     * Requirements:
     * - The caller must be the owner.
     * - If the caller is not the owner, cannot set a Payment Token as they cannot withdraw.
     */
    function setVersion(
        address _implementation,
        address _owner,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _locked
    ) public virtual override {
        /// @dev Load the existing Version object.
        Version memory version = versions[_implementation];

        /// @dev Prevent editing of a version once it has been locked.
        require(
            !version.locked,
            "LaborMarketVersions::_setVersion: Cannot update a locked version."
        );

        /// @dev Only the owner can set the version.
        require(
            version.owner == address(0) || version.owner == _msgSender(),
            "LaborMarketVersions::_setVersion: You do not have permission to edit this version."
        );

        /// @dev Make sure that no exogenous version controllers can set a payment
        ///      as there is not a mechanism for them to withdraw.
        if (_msgSender() != owner()) {
            require(
                _tokenAddress == address(0) && _tokenId == 0 && _amount == 0,
                "LaborMarketVersions::_setVersion: You do not have permission to set a payment token."
            );
        }

        /// @dev Set the version configuration.
        _setVersion(
            _implementation,
            _owner,
            keccak256(abi.encodePacked(_tokenAddress, _tokenId)),
            _amount,
            _locked
        );
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * See {LaborMarketVersionsInterface.getVersionKey}
     */
    function getVersionKey(address _implementation)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return versions[_implementation].licenseKey;
    }

    /**
     * See {LaborMarketsVersionInterface.getLicenseKey}
     */
    function getLicenseKey(bytes32 _versionKey, address _sender)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_versionKey, _sender));
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * See {LaborMarketVersionsInterface.setVersion}
     */
    function _setVersion(
        address _implementation,
        address _owner,
        bytes32 _licenseKey,
        uint256 _amount,
        bool _locked
    ) internal {
        /// @dev Set the version configuration.
        versions[_implementation] = Version({
            owner: _owner,
            licenseKey: _licenseKey,
            amount: _amount,
            locked: _locked
        });

        /// @dev Announce that the version has been updated to index it on the front-end.
        emit VersionUpdated(_implementation, versions[_implementation]);
    }

    /**
     * @notice Creates a new Labor Market to be managed by the deploying address.
     * @param _implementation The address of the implementation to be used.
     * @param _licenseKey The license key of the individual processing the Labor Market creation.
     * @param _versionCost The cost of deploying the version.
     * @param _deployer The address that will be the deployer of the Labor Market contract.
     * @param _configuration The configuration of the Labor Market.
     */
    function _createLaborMarket(
        address _implementation,
        bytes32 _licenseKey,
        uint256 _versionCost,
        address _deployer,
        LaborMarketConfiguration calldata _configuration
    ) internal returns (address) {
        /// @dev Deduct the amount of payment that is needed to cover deployment of this version.
        /// @notice This will revert if an individual has not funded it with at least the needed amount
        ///         to cover the cost of the version.
        /// @dev If deploying a free version or using an exogenous contract, the cost will be
        ///      zero and proceed normally.
        versionKeyToFunded[_licenseKey] -= _versionCost;

        /// @dev Get the address of the target.
        address marketAddress = _implementation.clone();

        /// @dev Interface with the newly created contract to initialize it.
        LaborMarketInterface laborMarket = LaborMarketInterface(marketAddress);

        /// @dev Initialize the Reputation for the Labor Market.
        ReputationModuleInterface(_configuration.reputationModule)
            .useReputationModule(
                marketAddress,
                _configuration.reputationConfig
            );

        /// @dev Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(_configuration);

        /// @dev Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _deployer, _implementation);

        return marketAddress;
    }

    /**
     * @notice Signals to external callers that this is a BadgerVersions contract.
     * @param _interfaceId The interface ID to check.
     * @return True if the interface ID is supported.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return (_interfaceId ==
            type(LaborMarketVersionsInterface).interfaceId ||
            _interfaceId == type(IERC1155Receiver).interfaceId);
    }
}