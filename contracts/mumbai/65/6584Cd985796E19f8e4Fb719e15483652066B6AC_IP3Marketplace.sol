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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IP3MarketplaceErrors {

    /// @dev Listing validation
    error InvalidPaymentToken(address);
    error ListingNotExist();
    error ListingExist();
    error InvalidLicensor();
    error InvalidTimeBaseStartPrice();
    error InvalidQuantityStartPrice();
    error InvalidSignature();
    error InvalidBulkSignature();
    error LicenseTypeNotActive(uint);
    error LicenseTypeNotSupport();
    error ZeroAddress();
    error InvalidNftOwner(uint8);
  

    /// @dev purchase timeBase license validation
    error InvalidTimeWindow();
    error LicenseTimeOverDue();
    error LessAllowedMinTime();
    error OverAllowedMaxTime();

    /// @dev purchase quantityBase license validation
    error LessAllowedMinQuantity();
    error OverAllowedMaxQuantity();

    /// @dev purchase general check
    error NotInListingPaymentToken();
    error BelowMinPrice();
    error ZeroMinPrice();
    
    // access validation
    error InvalidOperator();
   
    

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NFT, ListingIP, Licensor, LicensedInfo, LicenseType, License} from "../structs/IP3MarketplaceStruct.sol";

interface IP3MarketplaceEvents {
    // listing events
    event CreateListing(bytes32 indexed hashedNFT, ListingIP listingIP);
    event UpdateListing(bytes32 indexed hashedNFT, NFT nft);
    event CreateBulkListing(uint256 listCount);
    event CancelListing(bytes32 indexed hashedNFT);

    // purchase events
    event PurchaseLicense(
        bytes32 indexed hashedNFT,
        bytes32 indexed hashedLicense,
        address indexed licenseeAddress,
        License license,
        LicenseType licenseType,
        uint256 termPrice
    );
    event BulkPurchaseLicense(uint256 purchaseCount);

    // claim revenue and manage fee events
    event ClaimRevenue(
        address indexed claimAddress,
        uint256 claimRevenue
    );
    event ClaimRevenueLock(bool indexed flag);
    event ClaimManageFee(address indexed claimAddress, uint256 claimRevenue);
    event ClaimManageFeeLock(bool indexed flag);

    // update external contract address
    event UpdateSmartEngineContract(address indexed smartEngineContract);
    event UpdateSignatureCheckerContract(
        address indexed signatureCheckerContract
    );
    event UpdatePaymentToken(
        address indexed paymentToken
    );
    event UpdateDelegateCashContract(address indexed delegateCashContract);
    event UpdateWarmContract(address indexed warmContract);

    event UpdateLockOperator(address indexed lockOperator);

    event UpdateManageFee();
    event UpdatePurchaseConditions();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NFT, CreateListInput, ListingIP, Licensor, LicensedInfo, LicenseType} from "../structs/IP3MarketplaceStruct.sol";

import {IP3MarketplaceEvents} from "../interfaces/IP3MarketplaceEvents.sol";
import {IP3MarketplaceErrors} from "../interfaces/IP3MarketplaceErrors.sol";

interface IP3MarketplaceInterface is
    IP3MarketplaceEvents,
    IP3MarketplaceErrors
{
    function createListing(CreateListInput calldata _listInput) external;

    function createBulkListing(CreateListInput[] calldata _listInputs) external;

    function cancelListing(NFT memory nft, bytes memory signature) external;

    function purchaseLicense(
        NFT calldata _nft,
        LicenseType _licenseType,
        bytes calldata _term
    ) external;

    function lazyListingAndPurchaseLicense(
        CreateListInput calldata _createListInput,
        LicenseType _licenseType,
        bytes calldata _term
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

interface IP3SignatureCheckerInterface {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct CreateList {
        string chainId;
        address NFTAddress;
        uint256 tokenId;
        address licensorAddress;
        uint8 walletDelegation;
        uint256 minStartPrice;
        address paymentToken;
        string metadataUri;
        uint256 salt;
    }

    struct UpdateList {
        string chainId;
        address NFTAddress;
        uint256 tokenId;
    }

    struct CancelList {
        string chainId;
        address NFTAddress;
        uint256 tokenId;
    }

    function verifyCreateList(
        CreateList calldata createListParams,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    function verifyCreateBulkList(
        CreateList calldata createListParams,
        bytes32[] calldata proof,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    function verifyUpdateList(
        UpdateList calldata updateListParams,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    function verifyCancelList(
        CancelList calldata cancelListParams,
        bytes calldata signature,
        address signer
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LicenseType} from "../structs/IP3MarketplaceStruct.sol";
import {DynamicPriceParams, StartPriceParams} from "../structs/SmarPriceStruct.sol";

interface IP3SmartPriceEngineInterface {
    function computeLicensedPrice(
        LicenseType licenseType,
        uint256 count,
        uint256 currentStartPrice
    ) external view returns (uint256);

    function updateStartingPrice(
        LicenseType lincenseType,
        uint256 latestTimeStamp,
        uint256 latestStartPrice,
        uint256 minThresholdPrice
    ) external view returns (uint256);

    function getPriceParams(
        LicenseType licenseType
    ) external view returns (DynamicPriceParams memory, StartPriceParams memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface DelegateCashInterface {
    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface WarmInterface {
    /**
     *
     * @param contractAddress the ERC721 contract address
     * @param tokenId the tokenId uner this ERC721 contract
     */
    function ownerOf(
        address contractAddress,
        uint256 tokenId
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ClaimInfo} from "../../structs/IP3MarketplaceStruct.sol";

/// @dev Library for claimInfo operation logic
library ClaimableMapLogic {
    function addNewClaimInfo(
        bytes32 hashedLicense,
        uint256 reward,
        mapping(bytes32 => ClaimInfo) storage claimInfo
    ) internal {
        require(
            (claimInfo[hashedLicense].isClaimed == false) &&
                (claimInfo[hashedLicense].claimableAmount == 0),
            "LICENSE EXISTED"
        );
        claimInfo[hashedLicense].claimableAmount = reward;
    }

    /// @dev set the isCliamed to true
    function setClaimed(
        bytes32 hashedLicense,
        mapping(bytes32 => ClaimInfo) storage claimInfo
    ) internal {
        require(
            claimInfo[hashedLicense].claimableAmount != 0,
            "LICENSE NOT FOUND"
        );

        require(claimInfo[hashedLicense].isClaimed == false, "ALREADY CLAIM");

        claimInfo[hashedLicense].isClaimed = true;
    }

    function isClaimed(
        bytes32 hashedLicense,
        mapping(bytes32 => ClaimInfo) storage claimInfo
    ) internal view returns (bool) {
        return claimInfo[hashedLicense].isClaimed;
    }

    function getClaimAmount(
        bytes32 hashedLicense,
        mapping(bytes32 => ClaimInfo) storage claimInfo
    ) internal view returns (uint256) {
        return claimInfo[hashedLicense].claimableAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NFT} from "../../structs/IP3MarketplaceStruct.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import {DelegateCashInterface} from "../../interfaces/walletDelegate/DelegateCashInterface.sol";
import {WarmInterface} from "../../interfaces/walletDelegate/WarmInterface.sol";

library WalletDelegateLogic {
    /**
     * @notice validate NFT collection ownership when user use delegate cash
     * @param nft the NFT struct
     * @param delegateWallet delegate wallet address
     * @param delegateCashInstance the delegate cash contract address
     */
    function validateERC721OwnershipUsingDelegateCash(
        NFT memory nft,
        address delegateWallet,
        DelegateCashInterface delegateCashInstance
    ) internal view returns (bool) {
        address tokenOwner = IERC721Upgradeable(nft.NFTAddress).ownerOf(
            nft.tokenId
        );
        return
            _validateERC721Contract(nft.NFTAddress) &&
            delegateCashInstance.checkDelegateForToken(
                delegateWallet,
                tokenOwner,
                nft.NFTAddress,
                nft.tokenId
            );
    }

    /**
     *
     * @param nft NFT struct
     * @param delegateWallet wallet address taht use warm.xyz
     * @param warmInstance warm.xyz contract address
     */
    function validateERC721OwnershipUsingWarm(
        NFT memory nft,
        address delegateWallet,
        WarmInterface warmInstance
    ) internal view returns (bool) {
        return
            _validateERC721Contract(nft.NFTAddress) &&
            (warmInstance.ownerOf(nft.NFTAddress, nft.tokenId) ==
                delegateWallet);
    }

    /**
     * @notice validate nft ownership without using delegate wallet
     * @param nft NFT struct
     * @param tokenOwner address that directlry holds the NFT
     */
    function validateERC721Ownership(
        NFT memory nft,
        address tokenOwner
    ) internal view returns (bool) {
        return
            _validateERC721Contract(nft.NFTAddress) &&
            IERC721Upgradeable(nft.NFTAddress).ownerOf(nft.tokenId) ==
            tokenOwner;
    }

    function _validateERC721Contract(
        address contractAddress
    ) internal view returns (bool) {
        bytes4 interfaceId = 0x80ac58cd;
        return
            ERC165CheckerUpgradeable.supportsInterface(
                contractAddress,
                interfaceId
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SignatureCheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {TransactionRecord, TimeBaseTerm, QuantityBaseTerm, NFT, CreateListInput, PurchaseLicenseInput, LazyListingAndPurchaseLicenseInput, ListingIP, License, Licensor, LicensedInfo, LicenseType, ClaimInfo, LicenseTransactionRecord, ManageFee, PurchaseConditions, WalletDelegation, SignatureVersion} from "../structs/IP3MarketplaceStruct.sol";
import {IP3MarketplaceInterface} from "../interfaces/IP3MarketplaceInterface.sol";
import {IP3SignatureCheckerInterface} from "../interfaces/IP3SignatureCheckerInterface.sol";
import {IP3SmartPriceEngineInterface} from "../interfaces/IP3SmartPriceEngineInterface.sol";
import {ClaimableMapLogic} from "../libraries/logic/ClaimableMapLogic.sol";

import {DynamicPriceParams, StartPriceParams} from "../structs/SmarPriceStruct.sol";

import {WalletDelegateLogic, DelegateCashInterface, WarmInterface} from "../libraries/logic/WalletDelegateLogic.sol";

/// @dev main contract for IP3 marketplace
contract IP3Marketplace is IP3MarketplaceInterface, OwnableUpgradeable {
    using SignatureCheckerUpgradeable for address;
    using AddressUpgradeable for address;

    // interfaces for external contracts
    IP3SignatureCheckerInterface public signatureCheckerContract;
    IP3SmartPriceEngineInterface public smartEngineContract;
    DelegateCashInterface public delegateCashContract;
    WarmInterface public warmContract;
    IERC20Upgradeable public paymentToken;

    // storage mapping
    mapping(bytes32 => ListingIP) internal listingIPsMap; // hashed NFT => listings
    mapping(bytes32 => License) internal licenseMap; // hash of License => license
    //
    mapping(bytes32 => LicenseTransactionRecord) internal licenseRecordMap; // hash of NFT => LicenseTransactionRecord
    mapping(bytes32 => ClaimInfo) internal claimableMap; // hash of Licnense => isClaimed
    uint256 managedFeeBalance; //balance of platform manage fee

    // licenseType
    mapping(bytes32 => TimeBaseTerm) timeBaseTermMap;
    mapping(bytes32 => QuantityBaseTerm) quantityBaseTermMap;

    // set for NFT have transactional record (hash nft)
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    EnumerableSetUpgradeable.Bytes32Set internal nftOnRecord;

    // protocol manage fee
    ManageFee public manageFee;

    PurchaseConditions public purchaseConditions;

    uint256 public licenseId;
    bool public claimRevenueLock;
    bool public claimManageFeeLock;

    // new stable variable must append below!
    address lockOperator;

    /*//////////////////////////////////////////////////////////////
                    INITIALIZATION FUNCTION
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _manageFeeAddress,
        address _lockOperator,
        IP3SignatureCheckerInterface _signatureChecker,
        IP3SmartPriceEngineInterface _smartPriceEngine,
        IERC20Upgradeable _paymentToken
    ) public initializer {
        __Ownable_init();

        licenseId = 1;

        signatureCheckerContract = IP3SignatureCheckerInterface(
            _signatureChecker
        );

        smartEngineContract = IP3SmartPriceEngineInterface(_smartPriceEngine);
        paymentToken = _paymentToken;

        manageFee = ManageFee({
            basisPoint: 3000,
            feeDecimal: 10 ** 4,
            feeAddress: _manageFeeAddress
        });

        purchaseConditions = PurchaseConditions({
            minTime: 1 days,
            maxTime: 30 days,
            minQuantity: 1,
            maxQuantity: 100,
            minPendingTime: 0 days
        });

        lockOperator =  _lockOperator;
    }

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/
    
    /// @dev Checks whether a listing exists.
    modifier onlyLockOperator() {
        
        if (address(msg.sender) == address(0) || address(msg.sender) != address(lockOperator)) {
            revert InvalidOperator();
        }
        _;
    }
    /// @dev Checks whether a listing exists.
    modifier onlyExistingListing(NFT memory _nft) {
        bytes32 hashedNFT = _hashNft(_nft);
        if (address(listingIPsMap[hashedNFT].paymentToken) == address(0)) {
            revert ListingNotExist();
        }
        _;
    }

    /// @dev Checks non zero address
    modifier notZeroAddress(address _address) {
        if (address(_address) == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    modifier onlyValidPaymentToken(address _paymentToken) {
        if (_paymentToken != address(paymentToken)) {
            revert InvalidPaymentToken(_paymentToken);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                    LISTING OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creating listing for NFT IP
    /// currently support two types of license:
    /// 1. Time based for the certain period 2. Quantity based for count of IPs
    /// @dev IP owner list IP for authorizing others to use.
    /// This would allow for extension of license type if needed.
    /// @param _listInput struct of CreateListInput
    function createListing(CreateListInput calldata _listInput) public {
        _validateListing(_listInput);

        bytes32 hashedNFT = _hashNft(_listInput.nft);

        ListingIP storage _newListingIP = listingIPsMap[hashedNFT];

        _newListingIP.nft = _listInput.nft;
        _newListingIP.licensor = _listInput.licensor;

        // !!! Please push new license type at the end based on the order in enum LicenseType
        // when creating listing, the last two (latestStartPrice and lastActive)
        // are zeros as placehoders

        _newListingIP.licensedInfo = LicensedInfo(
            _listInput.minStartPrice,
            0,
            0
        );

        _newListingIP.paymentToken = _listInput.paymentToken;
        _newListingIP.metadataUri = _listInput.metadataUri;
        _newListingIP.salt = _listInput.salt;

        nftOnRecord.add(hashedNFT);

        emit CreateListing(hashedNFT, _newListingIP);
    }

    /// @notice Creating listing for multiple NFT IP
    /// @dev IP owner list multiple IPs for authorizing others to use in one transaction.
    /// @param _listInputs array of CreateListInput
    function createBulkListing(CreateListInput[] calldata _listInputs) public {
        for (uint256 i = 0; i < _listInputs.length; i++) {
            createListing(_listInputs[i]);
        }
        emit CreateBulkListing(_listInputs.length);
    }

    /// @notice Cancel listing
    /// @dev IP owner delist the existing IP.
    /// It is used when user want to reset the listing such as the minimum price
    /// @param _nft NFT struct
    /// @param _signature use for verification
    function cancelListing(
        NFT memory _nft,
        bytes memory _signature
    ) external onlyExistingListing(_nft) {
        _validateCancel(_nft, _signature);
        bytes32 hashedNFT = _hashNft(_nft);
        delete listingIPsMap[hashedNFT];
        nftOnRecord.remove(hashedNFT);
        emit CancelListing(hashedNFT);
    }

    /*//////////////////////////////////////////////////////////////
                    PURCHASE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Purchase IP license from the listing
    /// @dev Let's a wallet purchase IP license from a listing
    /// @param _nft NFT struct
    /// @param _licenseType license type to purchase
    /// @param _term Term struct contain the purchase term info based on the license type
    function purchaseLicense(
        NFT calldata _nft,
        LicenseType _licenseType,
        bytes calldata _term
    ) public onlyExistingListing(_nft) {
        // listing ownership validation
        bytes32 hashedNFT = _hashNft(_nft);
        ListingIP memory listingIP = listingIPsMap[hashedNFT];

        if (
            !_validateOwnership(
                listingIP.nft,
                listingIP.licensor.licensorAddress,
                listingIP.licensor.walletDelegation
            )
        ) {
            revert InvalidLicensor();
        }

        if (_licenseType == LicenseType.Time) {
            // Time term validation
            _purchaseByTime(listingIP, _term, msg.sender);
        } else if (_licenseType == LicenseType.Quantity) {
            // Quantity term validation
            _purchaseByQuantity(listingIP, _term, msg.sender);
        } else {
            revert LicenseTypeNotSupport();
        }
    }

    /// @notice purchase time based license
    /// @dev purchase time based license
    /// @param listingIP ListingIP struct
    /// @param timeTerm time based term info
    /// @param licensee purchaser for this IP
    function _purchaseByTime(
        ListingIP memory listingIP,
        bytes calldata timeTerm,
        address licensee
    ) internal {
        // validation
        // check license time range

        (uint256 licenseStartTime, uint256 licenseEndTime) = abi.decode(
            timeTerm,
            (uint256, uint256)
        );

        TimeBaseTerm memory term = TimeBaseTerm(
            licenseStartTime,
            licenseEndTime,
            address(paymentToken)
        );

        _validationTimebasePurchase(term, listingIP);

        bytes32 hashedNft = _hashNft(listingIP.nft);

        // get current start price
        uint256 currentStartPrice;

        // check if has record on-chain, if not default is 0
        // if has record on-chain

        uint256 lastActive = listingIP.licensedInfo.lastActive;

        if (lastActive != 0) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPriceByType(
                hashedNft,
                LicenseType.Time
            );
        } else {
            // new NFT to be licenced
            // get the start price from the input
            currentStartPrice = listingIP.licensedInfo.minStartPrice;
        }

        // update the start price into listingIPsMap
        listingIPsMap[hashedNft]
            .licensedInfo
            .latestStartPrice = currentStartPrice;

        // update the latest active with current block timestamp into listingIPsMap
        listingIPsMap[hashedNft].licensedInfo.lastActive = block.timestamp;

        // calculate the transaction value
        // compute the current termPrice by smart price engine
        uint256 termedPrice = smartEngineContract.computeLicensedPrice(
            LicenseType.Time,
            term.licenseEndTime - term.licenseStartTime,
            currentStartPrice
        );

        // register into the timeBaseTermMap
        timeBaseTermMap[_hashLicense(licenseId)] = term;

        {
            // create new license
            License memory newLicense = License(
                licenseId,
                listingIP.nft,
                listingIP.licensor,
                listingIP.metadataUri,
                licensee,
                LicenseType.Time,
                termedPrice,
                term.paymentToken
            );

            licenseId += 1;
            // excute the transaction
            _excutePurchase(newLicense, licensee);
        }
    }

    /// @notice purchase quantity based license
    /// @dev purchase quantity based license
    /// @param listingIP ListingIP struct
    /// @param quantityTerm quantitiy based Term info
    /// @param licensee purchaser for this IP
    function _purchaseByQuantity(
        ListingIP memory listingIP,
        bytes calldata quantityTerm,
        address licensee
    ) internal {
        // validation
        // check license quantity

        (uint256 licenseStartTime, uint256 count) = abi.decode(
            quantityTerm,
            (uint256, uint256)
        );

        QuantityBaseTerm memory term = QuantityBaseTerm(
            licenseStartTime,
            count,
            address(paymentToken)
        );
        _validationQuantitybasePurchase(term);

        bytes32 hashedNft = _hashNft(listingIP.nft);

        // get current start price
        uint256 currentStartPrice;

        // check if has record on-chain, if not default is 0
        // if has record on-chain
        uint256 lastActive = listingIP.licensedInfo.lastActive;

        if (lastActive != 0) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPriceByType(
                hashedNft,
                LicenseType.Quantity
            );
        } else {
            // new NFT to be licenced
            // get the start price from the input
            currentStartPrice = listingIP.licensedInfo.minStartPrice;
        }

        // update the start price into listingIPsMap
        listingIPsMap[hashedNft]
            .licensedInfo
            .latestStartPrice = currentStartPrice;

        // update the latest active with current block timestamp into listingIPsMap
        listingIPsMap[hashedNft].licensedInfo.lastActive = block.timestamp;

        // calculate the transaction value
        // compute the current termPrice by smart price engine
        uint256 termedPrice = smartEngineContract.computeLicensedPrice(
            LicenseType.Quantity,
            term.count,
            currentStartPrice
        );

        // register into the quantityBaseTermMap
        quantityBaseTermMap[_hashLicense(licenseId)] = term;

        // create new license
        License memory newLicense = License(
            licenseId,
            listingIP.nft,
            listingIP.licensor,
            listingIP.metadataUri,
            licensee,
            LicenseType.Quantity,
            termedPrice,
            term.paymentToken
        );

        licenseId += 1;
        // excute the transaction
        _excutePurchase(newLicense, licensee);
    }

    /// @notice Create listing and then purchase the license based on this newly created IP listing
    /// @dev Two transactions combined together. First, the listing created on-chain; second, purchase the IP license from this listing
    /// @param _createListInput struct of CreateListInput
    /// @param _licenseType LicenseType struct
    /// @param _term Term struct contain the purchase term info based on the license type
    function lazyListingAndPurchaseLicense(
        CreateListInput calldata _createListInput,
        LicenseType _licenseType,
        bytes calldata _term
    ) public {
        createListing(_createListInput);
        purchaseLicense(_createListInput.nft, _licenseType, _term);
    }

    /// @notice Purchase multiple IP in one transaction.
    /// @dev The IPs could be both onchain and offchain, thus, the input are two arrays, one for onchain ips, another one for lazyPurchase ips
    /// @param _purchaseLicenseInputs array of purchaseLicenseInput
    /// @param _lazyListingAndPurchaseLicenseInputs array of lazyListingAndPurchaseLicenseInput
    function bulkPurchase(
        PurchaseLicenseInput[] calldata _purchaseLicenseInputs,
        LazyListingAndPurchaseLicenseInput[]
            calldata _lazyListingAndPurchaseLicenseInputs
    ) external {
        for (uint256 i = 0; i < _purchaseLicenseInputs.length; i++) {
            purchaseLicense(
                _purchaseLicenseInputs[i]._nft,
                _purchaseLicenseInputs[i]._licenseType,
                _purchaseLicenseInputs[i]._term
            );
        }
        for (
            uint256 i = 0;
            i < _lazyListingAndPurchaseLicenseInputs.length;
            i++
        ) {
            lazyListingAndPurchaseLicense(
                _lazyListingAndPurchaseLicenseInputs[i]._createListInput,
                _lazyListingAndPurchaseLicenseInputs[i]._licenseType,
                _lazyListingAndPurchaseLicenseInputs[i]._term
            );
        }
        emit BulkPurchaseLicense(
            _purchaseLicenseInputs.length +
                _lazyListingAndPurchaseLicenseInputs.length
        );
    }

    /*//////////////////////////////////////////////////////////////
                    LICENSE OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function _hashLicense(uint256 _licenseId) internal pure returns (bytes32) {
        bytes32 hashedLicense = keccak256(abi.encodePacked(_licenseId));

        return hashedLicense;
    }

    /// @notice Excution of license purchase
    /// @dev Handle purchase revenue distribution
    /// @param license License struct for the license to be purchased
    /// @param licensee purchaser address
    function _excutePurchase(
        License memory license,
        address licensee
    ) internal {
        // register the license under the nft to licenseMap
        bytes32 hashedLicense = _hashLicense(license.id);
        licenseMap[hashedLicense] = license;

        // fee to management address
        uint256 termedPrice = license.price;
        uint256 fee = _calculateFee(termedPrice);
        managedFeeBalance += fee;

        // received for licensor after decution fee
        uint256 licensorOwn = termedPrice - fee;

        // add the claim info
        ClaimableMapLogic.addNewClaimInfo(
            hashedLicense,
            licensorOwn,
            claimableMap
        );

        bytes32 hashedNft = _hashNft(license.nft);

        // update the license record with transaction count and revenue

        if (
            license.licenseType == LicenseType.Time ||
            license.licenseType == LicenseType.Quantity
        ) {
            licenseRecordMap[hashedNft]
                .transactionRecords[license.licenseType]
                .totalTransactionCount += 1;

            licenseRecordMap[hashedNft]
                .transactionRecords[license.licenseType]
                .totalTransactionRevenue += termedPrice;
        } else {
            revert("INVALID PURCHASE OPTION");
        }

        // balance validation
        _validateERC20BalAndAllowance(
            licensee,
            license.paymentToken,
            termedPrice
        );

        // put transfer at the end to prevent the reentry attack
        IERC20Upgradeable(license.paymentToken).transferFrom(
            licensee,
            address(this),
            termedPrice
        );

        emit PurchaseLicense(
            hashedNft,
            hashedLicense,
            licensee,
            license,
            license.licenseType,
            termedPrice
        );
    }

    function _validationTimebasePurchase(
        TimeBaseTerm memory term,
        ListingIP memory listingIP
    ) internal view {
        if (term.licenseEndTime <= term.licenseStartTime) {
            revert InvalidTimeWindow();
        }

        if (term.licenseEndTime <= block.timestamp) {
            revert LicenseTimeOverDue();
        }

        uint256 duration = term.licenseEndTime - term.licenseStartTime;

        if (duration < purchaseConditions.minTime) {
            revert LessAllowedMinTime();
        }

        if (duration > purchaseConditions.maxTime) {
            revert OverAllowedMaxTime();
        }

        if (!_isInListingPayment(term.paymentToken, listingIP.paymentToken)) {
            revert NotInListingPaymentToken();
        }
    }

    function _validationQuantitybasePurchase(
        QuantityBaseTerm memory term
    ) internal view {
        if (term.count < purchaseConditions.minQuantity) {
            revert LessAllowedMinQuantity();
        }

        if (term.count > purchaseConditions.maxQuantity) {
            revert OverAllowedMaxQuantity();
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LISTING VALIDATIONS
    //////////////////////////////////////////////////////////////*/
    /// Todo: add delegate features, delegate contract
    /// @notice validation listing cancellation
    /// @dev only the current NFT ownership can cancel listing
    function _validateCancel(
        NFT memory nft,
        bytes memory signature
    ) internal view {
        bytes32 hashedNFT = _hashNft(nft);
        ListingIP storage listingIP = listingIPsMap[hashedNFT];

        // check if listingIP on record
        if (listingIP.paymentToken == address(0)) {
            revert ListingNotExist();
        }

        // only current nft owner with correct wallet delegation option allow to delete listing
        if (
            !(
                _validateOwnership(
                    listingIP.nft,
                    msg.sender,
                    listingIP.licensor.walletDelegation
                )
            )
        ) {
            revert InvalidNftOwner(uint8(listingIP.licensor.walletDelegation));
        }

        require(
            signatureCheckerContract.verifyCancelList(
                IP3SignatureCheckerInterface.CancelList(
                    nft.chainId,
                    nft.NFTAddress,
                    nft.tokenId
                ),
                signature,
                msg.sender
            ),
            "INVALID SIGNATURE"
        );
    }

    /// @dev Validate listing to check if meet the create listing criteria
    /// @notice Currently support:
    ///     listing already exist
    ///     NFT holder verfication
    ///     LicenseType conditions
    ///     Paymentoken in whitelist
    ///     Signature verfication: dependes on single, or bulk listing

    function _validateListing(
        CreateListInput calldata listInput
    ) internal view onlyValidPaymentToken(listInput.paymentToken) {
        // check if listing already exist
        bytes32 hashedNFT = _hashNft(listInput.nft);
        if (listingIPsMap[hashedNFT].licensor.licensorAddress != address(0)) {
            revert ListingExist();
        }

        /**
         * check:
         *  minStartPrice ( > 0)
         */

        if (listInput.minStartPrice <= 0) {
            revert ZeroMinPrice();
        }

        // check if valid NFT holder
        if (
            !_validateOwnership(
                listInput.nft,
                listInput.licensor.licensorAddress,
                listInput.licensor.walletDelegation
            )
        ) {
            revert InvalidLicensor();
        }

        // check if valid signature
        IP3SignatureCheckerInterface.CreateList
            memory createList = IP3SignatureCheckerInterface.CreateList(
                listInput.nft.chainId,
                listInput.nft.NFTAddress,
                listInput.nft.tokenId,
                listInput.licensor.licensorAddress,
                uint8(listInput.licensor.walletDelegation),
                listInput.minStartPrice,
                listInput.paymentToken,
                listInput.metadataUri,
                listInput.salt
            );

        if (listInput.signatures.signatureVersion == SignatureVersion.Single) {
            if (
                !signatureCheckerContract.verifyCreateList(
                    createList,
                    listInput.signatures.signature,
                    listInput.licensor.licensorAddress
                )
            ) {
                revert InvalidSignature();
            }
        } else {
            // in bulk merkel signature verfication
            if (
                !signatureCheckerContract.verifyCreateBulkList(
                    createList,
                    listInput.signatures.proof,
                    listInput.signatures.signature,
                    listInput.licensor.licensorAddress
                )
            ) {
                revert InvalidBulkSignature();
            }
        }
    }

    /// @dev _validateUpdate(nft, listStartTime, listEndTime)
    function _validateUpdate(
        NFT memory nft,
        bytes calldata signature
    ) internal view {
        bytes32 hashedNFT = _hashNft(nft);

        // check if valid NFT holder
        ListingIP memory listingIP = listingIPsMap[hashedNFT];

        if (
            !_validateOwnership(
                listingIP.nft,
                listingIP.licensor.licensorAddress,
                listingIP.licensor.walletDelegation
            )
        ) {
            revert InvalidLicensor();
        }

        // verify Signatures
        if (
            signatureCheckerContract.verifyUpdateList(
                IP3SignatureCheckerInterface.UpdateList(
                    nft.chainId,
                    nft.NFTAddress,
                    nft.tokenId
                ),
                signature,
                listingIP.licensor.licensorAddress
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @dev Validates that `_addrToCheck` owns and has approved markeplace to transfer the appropriate amount of currency
    function _validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view onlyValidPaymentToken(_currency) {
        require(
            IERC20Upgradeable(_currency).balanceOf(_addrToCheck) >=
                _currencyAmountToCheckAgainst &&
                IERC20Upgradeable(_currency).allowance(
                    _addrToCheck,
                    address(this)
                ) >=
                _currencyAmountToCheckAgainst,
            "NOT SUFFICIENT BAL"
        );
    }

    function _validateOwnership(
        NFT memory nft,
        address tokenOwner,
        WalletDelegation delegation
    ) internal view returns (bool) {
        // check if valid NFT holder

        if (WalletDelegateLogic.validateERC721Ownership(nft, tokenOwner)) {
            return true;
        }

        if (delegation == WalletDelegation.None) {
            return false;
        } else if (delegation == WalletDelegation.WarmXYZ) {
            return
                WalletDelegateLogic.validateERC721OwnershipUsingWarm(
                    nft,
                    tokenOwner,
                    warmContract
                );
        } else if (delegation == WalletDelegation.DelegateCash) {
            return
                WalletDelegateLogic.validateERC721OwnershipUsingDelegateCash(
                    nft,
                    tokenOwner,
                    delegateCashContract
                );
        } else {
            revert("WALLET DELEGATION NOT SUPPORTED"); // delegation wallet not support yet
        }
    }

    function _hashNft(NFT memory nft) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(nft.chainId, nft.NFTAddress, nft.tokenId)
            );
    }

    function _isValidPaymentToken(
        address _paymentToken
    ) internal view returns (bool) {
        return address(paymentToken) == _paymentToken;
    }

    /// check if paymentToken in Term is the same as it in the Listing
    function _isInListingPayment(
        address _paymentTokenInTerm,
        address _paymenTokenInListing
    ) internal pure returns (bool) {
        return _paymentTokenInTerm == _paymenTokenInListing;
    }

    /*//////////////////////////////////////////////////////////////
                    CLAIM REVENUE
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim revenue generated from the license purchase
    /// @dev claim of array of hashed licenses with the same paymentToken
    /// @param _licenseIds arrays of hashedLicense
    // TODO: use array of NFT structs to as inputs
    // TODO: use msg.sender to find if have claimable revenue
    // TODO: paymentToken may not needed since this info included in the license struct
    function claimRevenue(uint256[] memory _licenseIds) external {
        require(!claimRevenueLock, "LOCKED");

        uint256 totalBalance = 0;
        uint256 size = _licenseIds.length;

        for (uint256 i = 0; i < size; i++) {
            bytes32 hashedLicense = _hashLicense(_licenseIds[i]);
            if (
                checkIsClaimAndHoder(msg.sender, hashedLicense) &&
                (isValidByTerm(hashedLicense))
            ) {
                ClaimableMapLogic.setClaimed(hashedLicense, claimableMap);
                totalBalance += ClaimableMapLogic.getClaimAmount(
                    hashedLicense,
                    claimableMap
                );
            }
        }

        require(totalBalance > 0, "ZERO BALANCE");

        IERC20Upgradeable(paymentToken).transfer(msg.sender, totalBalance);

        emit ClaimRevenue(msg.sender, totalBalance);
    }

    /**
     * @notice Query revenue generated by licenses that can be claimed NOW by the input address
     * @dev the `_countLicense` is required as the `licenseIds` needs to have a size to allocate memory
     * @param holderAddress address to claim the revenue
     * @return array of license to claim the revenue, the total claimable revenue
     */
    function getCurrentClaimableLicenses(
        address holderAddress
    ) external view returns (uint256[] memory, uint256) {
        uint256 availableCount = _countLicense(holderAddress, true);

        uint256[] memory licenseIds = new uint256[](availableCount);
        uint counter = 0;

        // the total claimable revenue
        uint256 totalClaimable = 0;

        for (uint256 i = 0; i <= licenseId; i++) {
            bytes32 hashedLicense = _hashLicense(i);
            if (
                checkIsClaimAndHoder(holderAddress, hashedLicense) &&
                (isValidByTerm(hashedLicense))
            ) {
                totalClaimable += ClaimableMapLogic.getClaimAmount(
                    hashedLicense,
                    claimableMap
                );

                licenseIds[counter] = i;
                counter++;
            }
        }

        return (licenseIds, totalClaimable);
    }

    /**
     * @notice Query revenue generated by licenses that can be claimed later by the input address
     * @dev the `_countLicense` is required as the `licenseIds` needs to have a size to allocate memory
     * @param holderAddress address to claim the revenue
     * @return array of license to claim the revenue, the total claimable revenue
     */
    function getFutureClaimableLicenses(
        address holderAddress
    ) external view returns (uint256[] memory, uint256) {
        uint256 availableCount = _countLicense(holderAddress,false);

        uint256[] memory licenseIds = new uint256[](availableCount);
        uint counter = 0;

        // the total claimable revenue
        uint256 totalClaimable = 0;

        for (uint256 i = 0; i <= licenseId; i++) {
            bytes32 hashedLicense = _hashLicense(i);
            if (
                checkIsClaimAndHoder(holderAddress, hashedLicense) &&
                (!isValidByTerm(hashedLicense))
            ) {
                totalClaimable += ClaimableMapLogic.getClaimAmount(
                    hashedLicense,
                    claimableMap
                );

                licenseIds[counter] = i;
                counter++;
            }
        }

        return (licenseIds, totalClaimable);
    }

    /**
     * @notice count the avaliable license
     * @dev requirements: 1. license not already claim; 2. holder address still hold this nft
     * @param holderAddress  holder address
     * @param isCurrent if current claimable or future claimable (locked currently by term)
     */
    function _countLicense(
        address holderAddress,
        bool isCurrent
    ) internal view returns (uint256) {
        // find the return size
        uint256 count = 0;

        // iterate all license based on the license id to search
        for (uint256 i = 0; i <= licenseId; i++) {
            // check if current IP holder
            if (checkIsClaimAndHoder(holderAddress, _hashLicense(i))) {
                // check if current claimable and validate by term
                if (isCurrent && (isValidByTerm(_hashLicense(i)))) {
                    count += 1;
                }
                // check if future claimable and still locked by term
                if (!isCurrent && (!isValidByTerm(_hashLicense(i)))) {
                    count += 1;
                }
            }
        }

        return count;
    }

    function checkIsClaimAndHoder(
        address holderAddress,
        bytes32 hashedLicense
    ) internal view returns (bool) {
        if (!isNotClaimed(hashedLicense)) {
            return false;
        }

        // filter if the authroizer or claim has current own the NFT addreess
        if (!isNFTHolder(hashedLicense, holderAddress)) {
            return false;
        }

        return true;
    }

    /**
     * @notice check if this license not claimed already, or
     * @param hashedLicense hashed license
     */
    function isNotClaimed(bytes32 hashedLicense) internal view returns (bool) {
        if (ClaimableMapLogic.isClaimed(hashedLicense, claimableMap)) {
            return false;
        }
        return true;
    }

    function isNFTHolder(
        bytes32 hashedLicense,
        address holderAddress
    ) internal view returns (bool) {
        NFT memory nft = licenseMap[hashedLicense].nft;

        Licensor memory licensorOnRecord = licenseMap[hashedLicense].licensor;

        // not valid ERC721 contract address
        // check if current holder as licensorAddress on record or the input claimAddress

        return
            _validateOwnership(
                nft,
                holderAddress,
                licensorOnRecord.walletDelegation
            );
    }

    function isValidByTerm(bytes32 hashedLicense) internal view returns (bool) {
        LicenseType licenseType = licenseMap[hashedLicense].licenseType;

        uint256 needValidTime;

        if (licenseType == LicenseType.Time) {
            needValidTime = timeBaseTermMap[hashedLicense].licenseEndTime;
        } else {
            needValidTime = quantityBaseTermMap[hashedLicense].licenseStartTime;
        }

        // if by time
        if (licenseType == LicenseType.Time) {
            if (needValidTime > block.timestamp) {
                return false;
            }
            return true;
        } else if (licenseType == LicenseType.Quantity) {
            // by quantity: only allow claim after minPendingTime in days
            if (
                needValidTime + purchaseConditions.minPendingTime >
                block.timestamp
            ) {
                return false;
            }
            return true;
        } else {
            // other lincense types not suppported yet
            return false;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    Transaction Fee Distribution
    //////////////////////////////////////////////////////////////*/
    function claimManageFee() external {
        require(!claimManageFeeLock, "LOCKED");
        require(msg.sender == manageFee.feeAddress, "NOT ALLOWED");
        require(managedFeeBalance > 0, "ZERO BALANCE");

        uint256 claimBalance = managedFeeBalance;
        managedFeeBalance = 0;

        IERC20Upgradeable(paymentToken).transfer(msg.sender, claimBalance);

        emit ClaimManageFee(msg.sender, claimBalance);
    }

    function getManagedFeeBalance() external view returns (uint256) {
        return managedFeeBalance;
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        uint256 fee = (manageFee.basisPoint * _amount) / manageFee.feeDecimal;
        return fee;
    }

    function updateManageFee(ManageFee memory _managefee) public onlyOwner {
        manageFee = _managefee;
        emit UpdateManageFee();
    }

    /*//////////////////////////////////////////////////////////////
                    Lock Set
    //////////////////////////////////////////////////////////////*/
    function setClaimRevenueLock(bool flag) external onlyLockOperator {
        claimRevenueLock = flag;
        emit ClaimRevenueLock(flag);
    }

    function setClaimManageFeeLock(bool flag) external onlyLockOperator {
        claimManageFeeLock = flag;
        emit ClaimManageFeeLock(flag);
    }

    /*//////////////////////////////////////////////////////////////
                    SETTER PRICE AND PURCHASE PARAMS
    //////////////////////////////////////////////////////////////*/

    function updatePurchaseConditions(
        PurchaseConditions memory _purchaseConditions
    ) public onlyOwner {
        purchaseConditions = _purchaseConditions;
        emit UpdatePurchaseConditions();
    }

    /*//////////////////////////////////////////////////////////////
                    GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getLicenseRecordMap(
        bytes32 hashedNFTInfo
    ) external view returns (TransactionRecord[] memory) {
        uint size = uint(type(LicenseType).max) + 1;
        TransactionRecord[] memory txRecords = new TransactionRecord[](size);
        for (uint i = 0; i < size; i++) {
            txRecords[i] = getLicenseRecordMapByType(
                LicenseType(i),
                hashedNFTInfo
            );
        }

        return txRecords;
    }

    function getLicenseRecordMapByType(
        LicenseType licenseType,
        bytes32 hashedNFTInfo
    ) public view returns (TransactionRecord memory) {
        return licenseRecordMap[hashedNFTInfo].transactionRecords[licenseType];
    }

    function getLicenseMap(
        bytes32 hashedLicense
    ) external view returns (License memory) {
        return licenseMap[hashedLicense];
    }

    function getCurrentStartPriceAllNFT()
        public
        view
        returns (bytes32[] memory, uint256[][] memory)
    {
        uint256 size = nftOnRecord.length();
        bytes32[] memory hashedNfts = new bytes32[](size);
        uint256[][] memory prices = new uint256[][](size);

        for (uint256 i = 0; i < size; i++) {
            hashedNfts[i] = nftOnRecord.at(i);
            prices[i] = getCurrentStartPrice(hashedNfts[i]);
        }

        return (hashedNfts, prices);
    }

    function getCurrentStartPrice(
        bytes32 hashedNft
    ) public view returns (uint256[] memory) {
        uint size = uint(type(LicenseType).max) + 1;
        uint256[] memory priceAllTypes = new uint256[](size);

        for (uint i = 0; i < size; i++) {
            priceAllTypes[i] = getCurrentStartingPriceByType(
                hashedNft,
                LicenseType(i)
            );
        }
        return priceAllTypes;
    }

    function getCurrentStartingPriceByType(
        bytes32 hashedNft,
        LicenseType licenseType
    ) internal view returns (uint256) {
        ListingIP memory listingIP = listingIPsMap[hashedNft];

        uint256 currentStartPrice = smartEngineContract.updateStartingPrice(
            licenseType,
            listingIP.licensedInfo.lastActive,
            listingIP.licensedInfo.latestStartPrice,
            listingIP.licensedInfo.minStartPrice
        );

        return currentStartPrice;
    }

    function getNftHash(NFT memory nft) public pure returns (bytes32) {
        return _hashNft(nft);
    }

    /*//////////////////////////////////////////////////////////////
                    GET PRICE PARAMS
    //////////////////////////////////////////////////////////////*/
    function getPriceParams(
        LicenseType _licenseType
    )
        external
        view
        returns (DynamicPriceParams memory, StartPriceParams memory)
    {
        return smartEngineContract.getPriceParams(_licenseType);
    }

    /*//////////////////////////////////////////////////////////////
                    UPDATE EXTERNAL CONTRACTS
    //////////////////////////////////////////////////////////////*/
    function updateSignatureCheckerContract(
        IP3SignatureCheckerInterface _signatureCheckerContract
    ) external notZeroAddress(address(_signatureCheckerContract)) onlyOwner {
        signatureCheckerContract = _signatureCheckerContract;

        emit UpdateSignatureCheckerContract(address(signatureCheckerContract));
    }

    function updateSmartEngineContract(
        IP3SmartPriceEngineInterface _smartEngineContract
    ) external notZeroAddress(address(_smartEngineContract)) onlyOwner {
        smartEngineContract = _smartEngineContract;

        emit UpdateSmartEngineContract(address(smartEngineContract));
    }

    function updatePaymentTokenAddress(
        IERC20Upgradeable _paymentToken
    ) external notZeroAddress(address(_paymentToken)) onlyOwner {
        paymentToken = _paymentToken;

        emit UpdatePaymentToken(address(paymentToken));
    }

    function updateDelegateCashContract(
        DelegateCashInterface _delegateCashContract
    ) external notZeroAddress(address(_delegateCashContract)) onlyOwner {
        delegateCashContract = _delegateCashContract;

        emit UpdateDelegateCashContract(address(delegateCashContract));
    }

    function updateWarmContract(
        WarmInterface _warmContract
    ) external notZeroAddress(address(_warmContract)) onlyOwner {
        warmContract = _warmContract;

        emit UpdateWarmContract(address(warmContract));
    }


    function updateLockOperator(address _operator) external onlyOwner {
        lockOperator = _operator;

        emit UpdateLockOperator(_operator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice new enum must append at the end!!!
enum LicenseType {
    Time,
    Quantity
}

/// @notice new enum must append at the end!!!
enum SignatureVersion {
    Single,
    Bulk
}

/// @notice new enum must append at the end!!!
enum WalletDelegation {
    None,
    WarmXYZ,
    DelegateCash
}

/**
 * @notice This struct defines the data structure of an NFT (Non-Fungible Token).
 *
 * @title NFT
 * @param chainId The NFT associated with the IP listing.
 * @param NFTAddress The address of the contract where the NFT is deployed.
 * @param tokenId  The unique identifier id of the NFT.
 */
struct NFT {
    string chainId;
    address NFTAddress;
    uint256 tokenId;
}

struct Signatures {
    SignatureVersion signatureVersion;
    bytes32[] proof; // for bulk listing merkle tree verification
    bytes signature;
}

/**
 * @notice input struct for createListing fuction
 * @param nft  The NFT associated with the IP listing.
 * @param licensor The IP licensor information including licensor address, claimer address and wallet delegation type.
 * @param licenseTypeSwitch if this license supports license types (e.g., time based, quantity based).
 * @param minStartPrice licenser provide the minimum license price that can not be lower than this.
 * @param paymentToken the stablecoin payment token(ERC20) address.
 * @param signatures siganture for create list verfication.
 * @param metadataUri the enpoint for where the license info stored.
 * @param salt the random integer to signature verification.
 */
struct CreateListInput {
    NFT nft;
    Licensor licensor;
    uint256 minStartPrice;
    address paymentToken;
    Signatures signatures;
    string metadataUri;
    uint256 salt;
}

struct PurchaseLicenseInput {
    NFT _nft;
    LicenseType _licenseType;
    bytes _term;
}

struct LazyListingAndPurchaseLicenseInput {
    CreateListInput _createListInput;
    LicenseType _licenseType;
    bytes _term;
}

/**
 * @notice This struct defines the authorized listing IP.
 *
 * @title ListingIP
 * @param nft The NFT associated with the IP listing.
 * @param licensor The IP licensor information including licensor address, claimer address and wallet delegation type
 * @param licensedInfos  An array of license information for each type for the IP.
 * @param paymentToken The payment token address accepted the licensor.
 * @param metadataUri The URI to be displayed for the listing IP (e.g. Terms and Conditions, instructions of use, etc.)
 * @param salt A random number or an identifier for the listing, one possible use case is it can be used to identify the IP listed from which dapp
 */
struct ListingIP {
    NFT nft;
    Licensor licensor;
    LicensedInfo licensedInfo;
    address paymentToken;
    string metadataUri;
    uint256 salt;
}

/**
 * @notice This struct defines the data structure of an IP licensor.
 *
 * @title Licensor
 * @param licensorAddress The address of the IP licensor.
 * @param walletDelegation  The wallet delegation of the IP licensor.
 */
struct Licensor {
    address licensorAddress; // licensor
    WalletDelegation walletDelegation; // Enum could be updated for upgradable
}

/**
 * @notice This struct defines the data structure of a licensed information.
 *
 * @title LicensedInfo
 * @param latestStartPrice  The latest starting price for the license.
 * @param lastActive  The timestamp of the last activity for the license.
 */
struct LicensedInfo {
    uint256 minStartPrice;
    uint256 latestStartPrice;
    uint256 lastActive; // last active timestamp
}

/**
 * @notice term condition when purchase time-based license
 */
struct TimeBaseTerm {
    uint256 licenseStartTime;
    uint256 licenseEndTime;
    address paymentToken;
}

/**
 * @notice term condition when purchase quantity-based license
 */
struct QuantityBaseTerm {
    uint256 licenseStartTime;
    uint256 count;
    address paymentToken;
}

/**
 * @notice This struct defines the data structure of an IP license.
 *
 * @title License
 * @param id The unique ID of the license.
 * @param nft The NFT associated with the license.
 * @param licensor The licensor of the license.
 * @param metadataUri The URI of the license's metadata.
 * @param licensee The address of the licensee who owns the license.
 * @param licenseType The type of license.
 * @param price The price of the license.
 * @param paymentToken The address of the payment token.
 */
struct License {
    uint256 id;
    NFT nft;
    Licensor licensor;
    string metadataUri;
    address licensee;
    LicenseType licenseType;
    uint256 price;
    address paymentToken;
}

/// @notice not differentiate paymentTokens as all of those expected to be stable coins
struct TransactionRecord {
    uint256 totalTransactionCount;
    uint256 totalTransactionRevenue;
}

/// @notice keep track the current total TransactionRecord info
struct LicenseTransactionRecord {
    mapping(LicenseType => TransactionRecord) transactionRecords; // licenseType => TransactionRecord
}

/// @notice licensor claim revenue
/// mapping(bytes32 => LicenseTransactionRecord), key is hash of LicnenseId
struct ClaimInfo {
    uint256 claimableAmount;
    bool isClaimed;
}

/**
 * @notice protocol fees related
 */
struct ManageFee {
    uint256 basisPoint; // e.g. 100 -> 1%
    uint256 feeDecimal; // use to compute the manage fee in each transaction.
    address feeAddress; // the address to receive the manage fee.
}

struct PurchaseConditions {
    uint256 minTime; // min time allow for purchase time-based license
    uint256 maxTime; // max time allow for purchase time-based license
    uint256 minQuantity; // min quantity allow for purchase quantity-based license
    uint256 maxQuantity; // max quantity allow for purchase quantity-based license
    uint256 minPendingTime; // cool time for claim by quantity-based license
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LicenseType} from "./IP3MarketplaceStruct.sol";

/**
 * @dev contol the discount ratio based on the number of days in time-based license, and quantity in quantity in quantity-based license
 * @param maxDiscount maximum discount ratio
 * @param alpha control the discount rate
 * @param maximum license price
 */
struct DynamicPriceParams {
    uint256 maxDiscount;
    uint256 alpha; 
    uint256 maxThresholdPrice; 
}

/**
 * @dev 
 * @param incrementByTx increase price rate per transaction (e.g. 0.1 usd increase after each transaction)
 * @param discountPerTime price decrease rate per day (e.g. 0.1 usd increase per day)
 * @param price decrease NOT take effect before days setting (for example, set to 5, then only after 5 days no purchase, the price start to decrease)
 */
struct StartPriceParams {
    uint256 incrementByTx;   
    uint256 discountPerTime; 
    uint256 discountDelay; 
}

struct ComputeLicensedPriceInput {
    LicenseType licenseType;
    uint256 units;
    uint256 currentStartPrice;
    uint256 maxDiscount;
    uint256 alpha;
    uint256 maxThresholdPrice;
}

struct UpdateStartPriceInput {
    uint256 latestTimeStamp;
    uint256 latestStartPrice;
    uint256 minThresholdPrice;
    uint256 incrementByTx;
    uint256 discountPerTime;
    uint256 discountDelay;
}