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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface INameRegistry {
    function get(uint8 key) external view returns (address);
    function set(uint8 key, address value) external;
    function administrator() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IStartrailRegistryV1 {
  /*
   * Events
   */
  event CreateSRR(
    uint256 indexed tokenId,
    SRR registryRecord,
    bytes32 metadataDigest
  );
  event UpdateSRR(
    uint256 indexed tokenId,
    SRR registryRecord
  );
  event UpdateSRRMetadataDigest(
    uint256 indexed tokenId,
    bytes32 metadataDigest
  );
  event Provenance(
    uint256 indexed tokenId,
    address indexed from,
    address indexed to,
    string historyMetadataDigest,
    string historyMetadataURI
  );

  event Provenance(
    uint256 indexed tokenId,
    address indexed from,
    address indexed to,
    uint256 customHistoryId,
    string historyMetadataDigest,
    string historyMetadataURI
  );

  event SRRCommitment(
    uint256 indexed tokenId,
    address owner,
    bytes32 commitment
  );
  event SRRCommitment(
    uint256 indexed tokenId,
    address owner,
    bytes32 commitment,
    uint256 customHistoryId
  );
  event SRRCommitmentCancelled(
    uint256 indexed tokenId
  );
  event CreateCustomHistoryType(
    uint256 indexed id,
    string historyType
  );
  event CreateCustomHistory(
    uint256 indexed id,
    string name,
    uint256 customHistoryTypeId,
    bytes32 metadataDigest
  );

  /**
   * Structs
   */
  struct SRR {
    bool isPrimaryIssuer;
    address artistAddress;
    address issuer;
  }

  /**
   * Functions
   */
  function createSRR(
    bool isPrimaryIssuer,
    address artistAddress,
    bytes32 metadataDigest
  ) external;

  function createSRRFromLicensedUser(
    bool isPrimaryIssuer,
    address artistAddress,
    bytes32 metadataDigest
  ) external returns (uint256);

  function createSRRFromBulk(
    bool isPrimaryIssuer,
    address artistAddress,
    bytes32 metadataDigest,
    address issuerAddress
  ) external returns (uint256);

  function updateSRRFromLicensedUser(
    uint256 tokenId,
    bool isPrimaryIssuer,
    address artistAddress
  ) external returns (uint256);

  function updateSRRMetadata(uint256 tokenId, bytes32 metadataDigest)
    external;

  function approveSRRByCommitment(
    uint256 tokenId,
    bytes32 commitment,
    string memory historyMetadataDigest
  ) external;

  function approveSRRByCommitment(
    uint256 tokenId,
    bytes32 commitment,
    string memory historyMetadataDigest,
    uint256 customHistoryId
  ) external;
  function cancelSRRCommitment(uint256 tokenId) external;

  function transferSRRByReveal(
    address to,
    bytes32 reveal,
    uint256 tokenId
  ) external;

  function setNameRegistryAddress(address nameRegistry) external;

  function setTokenURIParts(string memory URIPrefix, string memory URIPostfix)
    external;
  
  function addCustomHistoryType(string memory historyTypeName) external returns (uint256 id);

  function writeCustomHistory(string memory name,uint256 historyTypeId, bytes32 metadataDigest) external returns (uint256 id);

  // Second transfer related functions removed from this LUM release
  // function approveFromAdmin(address to, uint256 tokenId) external;
  
  // function transferSRR(
  //   address to,
  //   uint256 tokenId,
  //   string memory historyMetadataDigest,
  //   uint256 customHistoryId
  // ) external;

  // function transferSRR(
  //   address to,
  //   uint256 tokenId,
  //   string memory historyMetadataDigest
  // ) external;

  /*
   * View functions
   */

  function getSRRCommitment(uint256 tokenId) external view returns (
    bytes32 commitment,
    string memory historyMetadataDigest,
    uint256 customHistoryId
  );

  function getSRR(uint256 tokenId)
    external
    view
    returns (SRR memory registryRecord, bytes32 metadataDigest);

  function getSRROwner(uint256 tokenId) external view returns (address);
  
  function getCustomHistoryNameById(uint256 id) external view returns (string memory);

  // function getCustomHistoryTypeIdByName(string memory historyTypeName) external view returns (uint256 historyTypeId);

  function tokenURI(string memory metadataDigests)
    external
    view
    returns (string memory);

  function getTokenId(bytes32 metadataDigest,address artistAddress) external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IStartrailRegistryV23 {
    /*
     * Events
     */

    event CreateSRR(
        uint256 indexed tokenId,
        SRR registryRecord,
        string metadataCID,
        bool lockExternalTransfer
    );

    event UpdateSRR(
        uint256 indexed tokenId,
        bool isPrimaryIssuer,
        address artistAddress,
        address sender
    );

    event UpdateSRRMetadataDigest(uint256 indexed tokenId, string metadataCID);

    event History(uint256[] tokenIds, uint256[] customHistoryIds);

    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string historyMetadataHash,
        string historyMetadataURI,
        bool isIntermediary
    );

    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 customHistoryId,
        string historyMetadataHash,
        string historyMetadataURI,
        bool isIntermediary
    );

    event SRRCommitment(
        uint256 indexed tokenId,
        address owner,
        bytes32 commitment
    );

    event SRRCommitment(
        uint256 indexed tokenId,
        address owner,
        bytes32 commitment,
        uint256 customHistoryId
    );

    event SRRCommitmentCancelled(uint256 indexed tokenId);

    event CreateCustomHistoryType(uint256 indexed id, string historyType);

    event CreateCustomHistory(
        uint256 indexed id,
        string name,
        uint256 customHistoryTypeId,
        string metadataCID
    );

    event UpdateCustomHistory(
        uint256 indexed id,
        string name,
        string metadataCID
    );

    event LockExternalTransfer(uint256 indexed tokenId, bool flag);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * Royalty events
     */
    event RoyaltiesSet(uint256 indexed tokenId, RoyaltyInfo royalty);

    /*
     * Legacy Events
     * - were emitted in previous versions of the contract
     * - leave here so they appear in ABI and can be indexed by the subgraph
     */

    event CreateSRR(
        uint256 indexed tokenId,
        SRR registryRecord,
        bytes32 metadataDigest
    );

    event UpdateSRR(uint256 indexed tokenId, SRR registryRecord);

    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string historyMetadataHash,
        string historyMetadataURI
    );

    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 customHistoryId,
        string historyMetadataHash,
        string historyMetadataURI
    );

    event ProvenanceDateMigrationFix(
        uint256 indexed tokenId,
        uint256 originTimestamp
    );

    event CreateSRR(
        uint256 indexed tokenId,
        SRR registryRecord,
        bytes32 metadataDigest,
        bool lockExternalTransfer
    );

    event UpdateSRRMetadataDigest(
        uint256 indexed tokenId,
        bytes32 metadataDigest
    );

    event CreateCustomHistory(
        uint256 indexed id,
        string name,
        uint256 customHistoryTypeId,
        bytes32 metadataDigest
    );

    event UpdateCustomHistory(
        uint256 indexed id,
        string name,
        bytes32 metadataDigest
    );

    /**
     * Structs
     */
    struct SRR {
        bool isPrimaryIssuer;
        address artistAddress;
        address issuer;
    }

    struct RoyaltyInfo {
        address receiver;
        // max basis points value 10000 fits inside uint16
        //   AND
        // address size + uint16 size < one slot [256]
        uint16 basisPoints;
    }

    /**
     * Functions
     */

    function createSRRFromLicensedUser(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        bool lockExternalTransfer
    ) external;

    // backward compatibility
    function createSRRFromLicensedUser(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        bool lockExternalTransfer,
        address to
    ) external;

    function createSRRFromLicensedUser(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        string memory metadataCID,
        bool lockExternalTransfer,
        address to,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) external;

    // backward compatibility
    function createSRRFromBulk(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        address issuerAddress,
        bool lockExternalTransfer
    ) external returns (uint256);

    function createSRRFromBulk(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        string memory metadataCID,
        address issuerAddress,
        bool lockExternalTransfer,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) external returns (uint256);

    function updateSRR(
        uint256 tokenId,
        bool isPrimaryIssuer,
        address artistAddress
    ) external;

    function updateSRRMetadata(uint256 tokenId, bytes32 metadataDigest)
        external;

    function updateSRRMetadata(uint256 tokenId, string memory metadataCID)
        external;

    function updateSRRRoyalty(
        uint256 tokenId,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) external;

    function updateSRRRoyaltyReceiverMulti(
        uint256[] calldata tokenIds,
        address royaltyReceiver
    ) external;

    function approveSRRByCommitment(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash
    ) external;

    function approveSRRByCommitment(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash,
        uint256 customHistoryId
    ) external;

    function cancelSRRCommitment(uint256 tokenId) external;

    function approveSRRByCommitmentFromBulk(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash,
        uint256 customHistoryId
    ) external;

    function transferSRRByReveal(
        address to,
        bytes32 reveal,
        uint256 tokenId,
        bool isIntermediary
    ) external;

    function setNameRegistryAddress(address nameRegistry) external;

    function setTokenURIParts(string memory URIPrefix, string memory URIPostfix)
        external;

    function addCustomHistoryType(string memory historyTypeName) external;

    function writeCustomHistory(
        string memory name,
        uint256 historyTypeId,
        bytes32 metadataDigest
    ) external;

    function writeCustomHistory(
        string memory name,
        uint256 historyTypeId,
        string memory metadataCID
    ) external;

    function updateCustomHistory(
        uint256 customHistoryId,
        string memory name,
        bytes32 metadataDigest
    ) external;

    function updateCustomHistory(
        uint256 customHistoryId,
        string memory name,
        string memory metadataCID
    ) external;

    function addHistory(
        uint256[] calldata tokenIds,
        uint256[] calldata customHistoryIds
    ) external;

    /*
     * View functions
     */

    function getSRRCommitment(uint256 tokenId)
        external
        view
        returns (
            bytes32 commitment,
            string memory historyMetadataHash,
            uint256 customHistoryId
        );

    function getSRR(uint256 tokenId)
        external
        view
        returns (SRR memory registryRecord, bytes32 metadataDigest);

    function getCustomHistoryNameById(uint256 id)
        external
        view
        returns (string memory);

    function tokenURI(string memory metadataDigests)
        external
        view
        returns (string memory);

    function contractURI() external view returns (string memory);

    function setContractURI(string memory _contractURI) external;

    function setLockExternalTransfer(uint256 tokenId, bool flag) external;

    function lockExternalTransfer(uint256 tokenId) external view returns (bool);

    function transferFromWithProvenance(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external;

    function transferOwnership(address newOwner) external;

    function transferFromWithProvenanceFromBulk(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library IDGeneratorV3 {
    uint256 private constant ID_CAP = 10 ** 12;

    /**
     * @dev generate determined tokenId
     * @param metadataDigest bytes32 metadata digest of token
     * @return uint256 tokenId
     */
    function generate(bytes32 metadataDigest, address artistAddress)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(metadataDigest, artistAddress))
            ) % ID_CAP;
    }

    /**
     * @dev generate determined tokenId
     * @param metadataCID string a cid of ipfs
     * @return uint256 tokenId
     */
    function generate(string memory metadataCID, address artistAddress)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(metadataCID, artistAddress))
            ) % ID_CAP;
    }

}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

import "./IEIP2771Recipient.sol";


/**
 * @title A base contract to be inherited by any contract that wants to receive
 *        transactions relayed through the MetaTxForwarder.
 *
 * @dev A subclass must use "msgSender()" instead of "msg.sender".
 *
 * NOTE: This contract is originally from:
 *   https://github.com/opengsn/forwarder/blob/master/contracts/BaseRelayRecipient.sol
 *
 * NOTE: The above is referenced on the EIP-2711 spec:
 *   https://eips.ethereum.org/EIPS/eip-2771
 */
abstract contract EIP2771BaseRecipient is IEIP2771Recipient {
  // Forwarder singleton we accept calls from.
  //
  // Store the trusted forwarder address in a slot.
  //
  // This slot value is from keccak256('trustedForwarder').
  bytes32 internal constant 
    TRUSTED_FORWARDER_ADDRESS_SLOT = 0x222cb212229f0f9bcd249029717af6845ea3d3a84f22b54e5744ac25ef224c92;

  /*
   * require a function to be called through GSN only
   */
  modifier trustedForwarderOnly() {
    require(
      msg.sender == getTrustedForwarder(),
      "Function can only be called through the trusted Forwarder"
    );
    _;
  }

  function isTrustedForwarder(address forwarder)
    public
    override
    view
    returns (bool)
  {
    return forwarder == getTrustedForwarder();
  }

  /**
   * @dev return address of the trusted forwarder.
   */
  function getTrustedForwarder() public view returns (address trustedForwarder) {
    bytes32 slot = TRUSTED_FORWARDER_ADDRESS_SLOT;
    assembly {
      trustedForwarder := sload(slot)
    }
  }

  /**
   * @dev set address of the trusted forwarder.
   */
  function _setTrustedForwarder(address _trustedForwarder) internal {
    require(_trustedForwarder != address(0));
    bytes32 slot = TRUSTED_FORWARDER_ADDRESS_SLOT;
    assembly {
      sstore(slot, _trustedForwarder)
    }
  }

  /**
   * @dev return the sender of this call.
   * if the call came through our trusted forwarder, return the original sender.
   * otherwise, return `msg.sender`.
   * should be used in the contract anywhere instead of msg.sender
   */
  function msgSender()
    internal
    override
    view
    returns (address ret)
  {
    if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
      // At this point we know that the sender is a trusted forwarder,
      // so we trust that the last bytes of msg.data are the verified sender address.
      // extract sender address from the end of msg.data
      assembly {
        ret := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return msg.sender;
    }
  }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

/**
 * @title A contract must implement this interface in order to support relayed
 *        transaction from MetaTxForwarder.
 *
 * @dev It is better to inherit the EIP2771BaseRecipient as the implementation.
 *
 * NOTE: This contract is originally from:
 *   https://github.com/opengsn/forwarder/blob/master/contracts/interfaces/IRelayRecipient.sol
 *
 * One modification to the original:
 *   - removed versionRecipient as it is not in the EIP2771 spec. and as yet
 *     we don't have a use case for this
 */
abstract contract IEIP2771Recipient {
  /**
   * @dev return if the forwarder is trusted to forward relayed transactions to us.
   * the forwarder is required to verify the sender's signature, and verify
   * the call is not a replay.
   */
  function isTrustedForwarder(address forwarder)
    public
    virtual
    view
    returns (bool);

  /**
   * @dev return the sender of this call.
   * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
   * of the msg.data.
   * otherwise, return `msg.sender`
   * should be used in the contract anywhere instead of msg.sender
   */
  function msgSender() internal virtual view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

contract Contracts {
    uint8 internal constant ADMINISTRATOR = 1;
    uint8 internal constant ADMIN_PROXY = 2;
    uint8 internal constant LICENSED_USER_MANAGER = 3;
    uint8 internal constant STARTRAIL_REGISTRY = 4;
    uint8 internal constant BULK_ISSUE = 5;
    uint8 internal constant META_TX_FORWARDER = 6;
    uint8 internal constant BULK_TRANSFER = 7;
    uint8 internal constant BULK = 8;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * Startrail contracts were deployed with an older version of
 * Initializable.sol from the package {at}openzeppelin/contracts-ethereum-package.
 * It was a version from the semver '^3.0.0'. 
 * 
 * That older version contained a storage gap however the new
 * {at}openzeppelin/contracts-upgradeable version does not.
 * 
 * This contract inserts the storage gap so that storage aligns in the
 * contracts that used that older version. 
 */
abstract contract InitializableWithGap is Initializable {
    uint256[50] private ______gap;   
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../proxy/utils/InitializableWithGap.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721UpgradeSafe is
    InitializableWithGap,
    ContextUpgradeable,
    ERC165,
    IERC721,
    IERC721Metadata
{
    using SafeMath for uint256;
    using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    // mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    // EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from tokenId to owner
    mapping(uint256 => address) public _tokenOwner;

    // Token counts for balanceOf
    mapping(address => uint256) private _ownedTokensCount;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId || 
               super.supportsInterface(interfaceId);
    }

    // function __ERC721_init(string memory name, string memory symbol) internal initializer {
    //     __Context_init_unchained();
    //     __ERC165_init_unchained();
    //     __ERC721_init_unchained(name, symbol);
    // }

    // function __ERC721_init_unchained(string memory name, string memory symbol) internal initializer {

    //     _name = name;
    //     _symbol = symbol;

    //     // register the supported interfaces to conform to ERC721 via ERC165
    //     _registerInterface(_INTERFACE_ID_ERC721);
    //     _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    //     // _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    // }

    function __ERC721_init_from_SR(string memory name_, string memory symbol_)
        internal
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public override view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        // return _holderTokens[owner].length();
        return _ownedTokensCount[owner];
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public override view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: owner query for nonexistent token"
        );
        return _tokenOwner[tokenId];
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If a base URI is set (via {_setBaseURI}), it is added as a prefix to the
     * token's own URI (via {_setTokenURI}).
     *
     * If there is a base URI but no token URI, the token's ID will be used as
     * its URI when appending it to the base URI. This pattern for autogenerated
     * token URIs can lead to large gas savings.
     *
     * .Examples
     * |===
     * |`_setBaseURI()` |`_setTokenURI()` |`tokenURI()`
     * | ""
     * | ""
     * | ""
     * | ""
     * | "token.uri/123"
     * | "token.uri/123"
     * | "token.uri/"
     * | "123"
     * | "token.uri/123"
     * | "token.uri/"
     * | ""
     * | "token.uri/<tokenId>"
     * |===
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId)
        public
        override(IERC721Metadata)
        virtual
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    // /**
    //  * @dev Gets the token ID at a given index of the tokens list of the requested owner.
    //  * @param owner address owning the tokens list to be accessed
    //  * @param index uint256 representing the index to be accessed of the requested tokens list
    //  * @return uint256 token ID at the given index of the tokens list owned by the requested address
    //  */
    // function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    //     return _holderTokens[owner].at(index);
    // }

    // /**
    //  * @dev Gets the total amount of tokens stored by the contract.
    //  * @return uint256 representing the total amount of tokens
    //  */
    // function totalSupply() public view override returns (uint256) {
    //     // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
    //     return _tokenOwners.length();
    // }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    // function tokenByIndex(uint256 index) public view override returns (uint256) {
    //     (uint256 tokenId, ) = _tokenOwners.at(index);
    //     return tokenId;
    // }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId)
        public
        override
        view
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        override
        virtual
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        // return _tokenOwners.contains(tokenId);
        return _tokenOwner[tokenId] != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
        _tokenOwner[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    
    /**
     * @dev Internal function to update token ownership information ONLY.
     * NOTE: exists only to support migration from mainnet to Polygon. In this
     *       process we bypass the usual checks and event emissions and write
     *       data directly to state.
     * @param owner The address of the owner
     * @param tokenId uint256 ID of the token to be saved 
     */
    function _setOwnerFromMigration(address owner, uint256 tokenId) internal virtual {
        require(owner != address(0), "ERC721: migration with ownership to the zero address");
        require(!_exists(tokenId), "ERC721: token already migrated");
        _ownedTokensCount[owner] = _ownedTokensCount[owner].add(1);
        _tokenOwner[tokenId] = owner;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _ownedTokensCount[owner] = _ownedTokensCount[owner].sub(1);
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);

        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: If all token IDs share a prefix (for example, if your URIs look like
     * `https://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            )
        );
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    // Visibility changed to internal from private in order to access this 
    // function from StartrailRegistry
    function _approve(address to, uint256 tokenId) internal { 
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - when `from` is zero, `tokenId` will be minted for `to`.
     * - when `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    uint256[41] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "../common/IStartrailRegistryV1.sol";

/**
 * @title IStartrailRegistryMigrationV2 - events from the migration
 *
 * @dev Events required to migrate tokens to the new chain. The functions
 *      were removed for this V2 version.
 */
interface IStartrailRegistryMigrationV2 {
  /*
   * Events ERC721
   */

  event TransferFromMigration(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId,
    uint256 originTimestamp,
    bytes32 originTxHash
  );

  /*
   * Events StartrailRegistry
   */

  event MigrateSRR(
    uint256 indexed tokenId,
    string originChain
  );

  event CreateSRRFromMigration(
    uint256 indexed tokenId,
    IStartrailRegistryV1.SRR registryRecord,
    bytes32 metadataDigest,
    uint256 originTimestamp,
    bytes32 originTxHash
  );
  event UpdateSRRFromMigration(
    uint256 indexed tokenId,
    IStartrailRegistryV1.SRR registryRecord,
    uint256 originTimestamp,
    bytes32 originTxHash
  );
  event UpdateSRRMetadataDigestFromMigration(
    uint256 indexed tokenId,
    bytes32 metadataDigest,
    uint256 originTimestamp,
    bytes32 originTxHash
  );
  event ProvenanceFromMigration(
    uint256 indexed tokenId,
    address indexed from,
    address indexed to,
    uint256 timestamp,
    string historyMetadataDigest,
    string historyMetadataURI,
    uint256 originTimestamp,
    bytes32 originTxHash
  );

  event ProvenanceFromMigration(
    uint256 indexed tokenId,
    address indexed from,
    address indexed to,
    uint256 timestamp,
    uint256 customHistoryId,
    string historyMetadataDigest,
    string historyMetadataURI,
    uint256 originTimestamp,
    bytes32 originTxHash
  );

  event SRRCommitmentFromMigration(
    address owner,
    bytes32 commitment,
    uint256 tokenId,
    uint256 originTimestamp,
    bytes32 originTxHash
  );
  event SRRCommitmentFromMigration(
    address owner,
    bytes32 commitment,
    uint256 tokenId,
    uint256 customHistoryId,
    uint256 originTimestamp,
    bytes32 originTxHash
  );
  event SRRCommitmentCancelledFromMigration(
    uint256 tokenId,
    uint256 originTimestamp,
    bytes32 originTxHash
  );
  event CreateCustomHistoryFromMigration(
    uint256 indexed id,
    string name,
    uint256 customHistoryTypeId,
    bytes32 metadataDigest,
    string originChain,
    uint256 originTimestamp,
    bytes32 originTxHash
  );

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * Library to support Meta Transactions from OpenSea.
 * see https://docs.opensea.io/docs/polygon-basic-integration#meta-transactions
 *
 * NOTE: we leave 'functionSignature' in to ensure compatibility with OpenSea
 *   (especially as it's part of the typehash) but it should be "calldata".
 */
library OpenSeaMetaTransactionLibrary {
    using SafeMath for uint256;

    // External data to be passed in from the stateful contract
    struct OpenSeaMetaTransactionStorage {
        mapping(address => uint256) nonces;
        bytes32 domainSeperator;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature; // sic: is calldata - see library level comment
    }

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature // sic: is calldata - see library level comment
    );

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    string private constant ERC712_VERSION = "1";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );

    function setDomainSeparator(
        OpenSeaMetaTransactionStorage storage self,
        string memory name
    )
        internal
    {
        self.domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator(
        OpenSeaMetaTransactionStorage storage self
    ) public view returns (bytes32) {
        return self.domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function executeMetaTransaction(
        OpenSeaMetaTransactionStorage storage self,
        address userAddress,
        bytes memory functionSignature, // sic: is calldata - see library level comment
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: self.nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(self, userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        self.nonces[userAddress] = self.nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it
        // from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function getNonce(
        OpenSeaMetaTransactionStorage storage self,
        address user
    ) public view returns (uint256 nonce) {
        nonce = self.nonces[user];
    }

    function verify(
        OpenSeaMetaTransactionStorage storage self,
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "MetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(self, hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }


    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
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

    /**
     * Accept message hash and returns hash message in EIP712 compatible form.
     * So that it can be used to recover signer from signature signed using
     * EIP712 formatted meta tx data.
     */
    function toTypedMessageHash(
        OpenSeaMetaTransactionStorage storage self,
        bytes32 messageHash
    )
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(self), messageHash)
            );
    }

    function msgSenderFromEIP2771MsgData(bytes calldata msgData)
        public
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msgData;
            uint256 index = msgData.length;
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

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

/**
 * Library to move logic off the main contract because it became too large to
 * deploy.
 */
library StartrailRegistryLibraryV1 {

    function tokenURIFromBytes32(
        bytes32 _metadataDigest,
        string memory _uriPrefix,
        string memory _uriPostfix
    )
        public
        pure
        returns (string memory)
    {
        string memory metadataDigestStr = bytes32ToString(_metadataDigest);
        return string(
            abi.encodePacked(
                _uriPrefix,
                "0x",
                metadataDigestStr,
                _uriPostfix
            )
        );
    }

    function tokenURIFromString(
        string memory _metadataDigest,
        string memory _uriPrefix,
        string memory _uriPostfix
    )
        public
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                _uriPrefix,
                _metadataDigest,
                _uriPostfix
            )
        );
    }

    /**
     * Convert a bytes32 into a string by manually converting each hex digit
     * to it's corresponding string codepoint.
     */
    function bytes32ToString(bytes32 _b32)
        internal
        pure
        returns
        (string memory)
    {
        string memory res = new string(64);
        for (uint8 i; i < 32; i++) {
            uint256 hex1 = uint8(_b32[i] >> 4);
            uint256 hex2 = uint8((_b32[i] << 4) >> 4);
            uint256 char1 = hex1 + (hex1 < 10 ? 48 : 87);
            uint256 char2 = hex2 + (hex2 < 10 ? 48 : 87);
            assembly {
                let chPtr := add(mul(i, 2), add(res, 32))
                mstore8(chPtr, char1)
                mstore8(add(chPtr, 1), char2)
            }
        }
        return res;
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../proxy/utils/InitializableWithGap.sol";
import "../common/INameRegistry.sol";
import "../common/IStartrailRegistryV23.sol";
import "../lib/IDGeneratorV3.sol";
import "../metaTx/eip2771/EIP2771BaseRecipient.sol";
import "../name/Contracts.sol";
import "./Storage.sol";
import "./ERC721.sol";
import "./IStartrailRegistryMigrationV2.sol";
import "./OpenSeaMetaTransactionLibrary.sol";
import "./StartrailRegistryLibraryV1.sol";

interface ILicensedUserManager {
    function isActiveWallet(address walletAddress) external pure returns (bool);
}

contract StartrailRegistryV23 is
    Contracts,
    IStartrailRegistryV23,
    IStartrailRegistryMigrationV2,
    InitializableWithGap,
    Storage,
    ERC721UpgradeSafe,
    EIP2771BaseRecipient,
    IERC2981
{
    /*
     * Constants
     */
    // Static
    uint256 private constant SRR_GLOBAL_SLOT = 0;
    // types
    bytes32 private constant _SRR = keccak256("registryRecord");
    bytes32 private constant _HISTORY = keccak256("historyProvenance");

    // values
    bytes32 private constant _IS_PRIMARY_ISSUER = keccak256("isPrimaryIssuer");
    bytes32 private constant _ISSUER = keccak256("issuer");
    bytes32 private constant _ARTIST_ADDRESS = keccak256("artistAddress");
    bytes32 private constant _COMMITMENT = keccak256("commitment");

    // metadata
    bytes32 private constant _URI_PREFIX = keccak256("URIPrefix");
    bytes32 private constant _URI_POSTFIX = keccak256("URIPostfix");
    bytes32 private constant _METADATA_HASH = keccak256("metadataDigest");

    // contract-level metadata
    bytes32 private constant _CONTRACT_URI = keccak256("contractURI");

    // custom history
    bytes32 private constant _CUSTOM_HISTORY = keccak256("customHistory");
    bytes32 private constant _CUSTOM_HISTORY_NAME =
        keccak256("customHistoryName");
    // flag to disable standard ERC721 transfer method
    bytes32 private constant _LOCK_EXTERNAL_TRANSFER =
        keccak256("lockExternalTransfer");

    bytes32 private constant _OPENSEA_PROXY_ADDRESS =
        keccak256("openSeaProxyAddress");
    bytes32 private constant _OPENSEA_APPROVE_ALL_KILL_SWITCH =
        keccak256("openSeaApproveAllKillSwitch");

    uint256 private constant _NO_CUSTOM_HISTORY = 0;

    /*
     * State
     */

    address public nameRegistryAddress;

    //Custom History key
    uint256 private customHistoryCount = 1;
    uint256 private customHistoryTypeCount = 0;

    // custom history type vs id mapping
    mapping(uint256 => string) public customHistoryTypeNameById;
    mapping(string => uint256) public customHistoryTypeIdByName;

    // Maximum combination of token * history id that can be emitted
    uint256 public maxCombinedHistoryRecords;

    // owner address it is required for arranging the contract meta data in opensea
    address public owner;

    // OpenSea Meta Transaction integration and storage
    using OpenSeaMetaTransactionLibrary for OpenSeaMetaTransactionLibrary.OpenSeaMetaTransactionStorage;

    OpenSeaMetaTransactionLibrary.OpenSeaMetaTransactionStorage
        private openSeaMetaTx;

    /**
     * Royalties
     * marked `public` to provide direct read access to the basis points.
     * required for proposed SBINFT implementation AND
     * it's handy to have this lookup as royaltyInfo doesn't show this.
     * although it could be derived: `royaltyInfo(tokenId, 1 ether);
     */
    mapping(uint256 => RoyaltyInfo) public royalties;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721UpgradeSafe)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*
     * Modifiers (as functions to save deployment gas - see
     *   https://ethereum.org/en/developers/tutorials/downsizing-contracts-to-fight-the-contract-size-limit/#remove-modifiers
     * )
     */

    function onlyAdministrator() private view {
        require(isAdministrator(), "Caller is not the Startrail Administrator");
    }

    function onlyIssuerOrArtistOrAdministrator(uint256 tokenId) private view {
        if (!isAdministrator()) {
            if (!isIssuer(tokenId)) {
                require(
                    isArtist(tokenId),
                    "Caller is not the Startrail Administrator or an Issuer or an Artist"
                );
            }
        }
    }

    function onlyLicensedUserOrAdministrator() private view {
        if (!isAdministrator()) {
            require(
                ILicensedUserManager(
                    INameRegistry(nameRegistryAddress).get(
                        Contracts.LICENSED_USER_MANAGER
                    )
                ).isActiveWallet(msgSender()),
                "Caller is not the Startrail Administrator or a LicensedUser"
            );
        }
    }

    // for bytecode optimize.
    // if the same code is inlined multiple times, it adds up in size and that size limit can be hit easily.
    function onlyBulk() private view {
        INameRegistry nr = INameRegistry(nameRegistryAddress);
        require(
            nr.get(BULK) == msg.sender ||
                nr.get(BULK_ISSUE) == msg.sender ||
                nr.get(BULK_TRANSFER) == msg.sender,
            "The sender is not the Bulk related contract"
        );
    }

    function onlyIssuerOrAdministrator(uint256 tokenId) private view {
        require(
            msgSender() == _addressStorage[tokenId][_SRR][_ISSUER] ||
                isAdministrator(),
            "This is neither a issuer nor the admin"
        );
    }

    /**
     * Guarantee the caller is the owner of the token (see msgSender() - this
     * will be a proxied LicensedUser request in most cases) or the
     * Administrator.
     *
     * This check will throw if the token does not exist (see ownerOf).
     */
    function onlySRROwnerOrAdministrator(uint256 tokenId) private view {
        require(
            ownerOf(tokenId) == msgSender() || isAdministrator(),
            "Sender is neither a SRR owner nor the admin"
        );
    }

    function tokenExists(uint256 tokenId) private view {
        require(
            ERC721UpgradeSafe._exists(tokenId),
            "The tokenId does not exist"
        );
    }

    function customHistoryIdExists(uint256 customHistoryId) private view {
        require(
            bytes(getCustomHistoryNameById(customHistoryId)).length != 0,
            "The custom history id does not exist"
        );
    }

    function requireCustomHistoryName(string memory name) private pure {
        require(bytes(name).length != 0, "The custom history name is required");
    }

    function externalTransferNotLocked(uint256 tokenId) private view {
        require(
            !_boolStorage[tokenId][_SRR][_LOCK_EXTERNAL_TRANSFER],
            "Transfer is locked for this token"
        );
    }

    /**
     * @dev Initializes the address of the nameRegistry contract
     * @param nameRegistry address of the NameRegistry
     * @param trustedForwarder address of the EIP2771 forwarder which will be the LUM contract
     * @param name token name eg. 'Startrail Registry Record'
     * @param symbol token code eg. SRR
     * @param URIPrefix string of the URI prefix of the scheme where SRR metadata is saved
     * @param URIPostfix string of the URI postfix of the scheme
     */

    // COMMENT OUT as this is only required on deployment the first time and
    //    leaving this in just adds dead bytecode to subsequent implementations

    // function initialize(
    //     address nameRegistry,
    //     address trustedForwarder,
    //     string memory name,
    //     string memory symbol,
    //     string memory URIPrefix,
    //     string memory URIPostfix
    // ) public initializer {
    //     nameRegistryAddress = nameRegistry;
    //     _setTrustedForwarder(trustedForwarder);
    //     ERC721UpgradeSafe.__ERC721_init_from_SR(name, symbol);
    //     _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_PREFIX] = URIPrefix;
    //     _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_POSTFIX] = URIPostfix;
    // }

    /**
     * @dev Change the EIP2711 trusted forwarder address
     * @param forwarder address of the forwarder contract
     */
    function setTrustedForwarder(address forwarder) external {
        onlyAdministrator();
        _setTrustedForwarder(forwarder);
    }

    /**
     * @dev Change the maxCombinedHistoryRecords for emitHistory
     * @param maxRecords new maximum
     */
    function setMaxCombinedHistoryRecords(uint256 maxRecords) external {
        onlyAdministrator();
        maxCombinedHistoryRecords = maxRecords;
    }

    function isAdministrator() private view returns (bool) {
        return
            INameRegistry(nameRegistryAddress).administrator() == msgSender();
    }

    function isIssuer(uint256 tokenId) private view returns (bool) {
        return msgSender() == _addressStorage[tokenId][_SRR][_ISSUER];
    }

    function isArtist(uint256 tokenId) private view returns (bool) {
        return msgSender() == _addressStorage[tokenId][_SRR][_ARTIST_ADDRESS];
    }

    /**
     * @dev Creates a registryRecord of an artwork from LicensedUser wallet
     * @param isPrimaryIssuer address of the issuer user contract
     * @param artistAddress address of the artist contract
     * @param metadataDigest bytes32 of metadata hash
     * @param lockExternalTransfer_ bool of the flag to disable standard ERC721 transfer methods
     */
    function createSRRFromLicensedUser(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        bool lockExternalTransfer_
    ) public override(IStartrailRegistryV23) trustedForwarderOnly {
        _createSRR(
            isPrimaryIssuer,
            artistAddress,
            metadataDigest,
            "",
            msgSender(),
            lockExternalTransfer_,
            address(0),
            0
        );
    }

    /**
     * backward compatibility
     * @dev Creates a registryRecord of an artwork from LicensedUser wallet and transfers it to the recipient
     * @param isPrimaryIssuer address of the issuer user contract
     * @param artistAddress address of the artist contract
     * @param metadataDigest bytes32 of metadata hash
     * @param lockExternalTransfer_ bool of the flag to disable standard ERC721 transfer methods
     * @param to the address this token will be transferred to after the creation
     */
    function createSRRFromLicensedUser(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        bool lockExternalTransfer_,
        address to
    ) public override(IStartrailRegistryV23) trustedForwarderOnly {
        uint256 tokenId = _createSRR(
            isPrimaryIssuer,
            artistAddress,
            metadataDigest,
            "",
            msgSender(),
            lockExternalTransfer_,
            address(0),
            0
        );
        if (to != address(0)) {
            ERC721UpgradeSafe._transfer(msgSender(), to, tokenId);
        }
    }

    /**
     * @dev Creates a registryRecord of an artwork from LicensedUser wallet and transfers it to the recipient
     * @param isPrimaryIssuer address of the issuer user contract
     * @param artistAddress address of the artist contract
     * @param metadataDigest bytes32 of metadata hash used by detect if createSRR is duplicate
     * @param metadataCID string of ipfs cid
     * @param lockExternalTransfer_ bool of the flag to disable standard ERC721 transfer methods
     * @param to the address this token will be transferred to after the creation
     * @param royaltyReceiver royalty receiver
     * @param royaltyBasisPoints royalty basis points
     */
    function createSRRFromLicensedUser(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        string memory metadataCID,
        bool lockExternalTransfer_,
        address to,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) public override(IStartrailRegistryV23) trustedForwarderOnly {
        uint256 tokenId = _createSRR(
            isPrimaryIssuer,
            artistAddress,
            metadataDigest,
            metadataCID,
            msgSender(),
            lockExternalTransfer_,
            royaltyReceiver,
            royaltyBasisPoints
        );
        if (to != address(0)) {
            ERC721UpgradeSafe._transfer(msgSender(), to, tokenId);
        }
    }

    // backward compatibility
    function createSRRFromBulk(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        address issuerAddress,
        bool lockExternalTransfer_
    ) public override(IStartrailRegistryV23) returns (uint256) {
        onlyBulk();
        return
            _createSRR(
                isPrimaryIssuer,
                artistAddress,
                metadataDigest,
                "",
                issuerAddress,
                lockExternalTransfer_,
                address(0),
                0
            );
    }

    function createSRRFromBulk(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigest,
        string memory metadataCID,
        address issuerAddress,
        bool lockExternalTransfer_,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) public override(IStartrailRegistryV23) returns (uint256) {
        onlyBulk();
        return
            _createSRR(
                isPrimaryIssuer,
                artistAddress,
                metadataDigest,
                metadataCID,
                issuerAddress,
                lockExternalTransfer_,
                royaltyReceiver,
                royaltyBasisPoints
            );
    }

    /**
     * @dev Register an approval to transfer ownership by commitment scheme
     *      where the caller is a Bulk contract
     * @param tokenId SRR id
     * @param commitment commitment hash
     * @param historyMetadataHash history metadata digest or cid
     * @param customHistoryId custom history to link the transfer too
     */
    function approveSRRByCommitmentFromBulk(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash,
        uint256 customHistoryId
    ) public override(IStartrailRegistryV23) {
        onlyBulk();
        _approveSRRByCommitment(
            tokenId,
            commitment,
            historyMetadataHash,
            customHistoryId
        );
    }

    function transferFromWithProvenanceFromBulk(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external override(IStartrailRegistryV23) {
        onlyBulk();
        _transferFromWithProvenance(
            to,
            tokenId,
            historyMetadataHash,
            customHistoryId,
            isIntermediary
        );
    }

    /**
     * @dev Updates the registryRecord
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param isPrimaryIssuer boolean whether the user is a primary issuer
     * @param artistAddress artists LUW
     */
    function updateSRR(
        uint256 tokenId,
        bool isPrimaryIssuer,
        address artistAddress
    ) external override(IStartrailRegistryV23) {
        tokenExists(tokenId);
        onlyIssuerOrArtistOrAdministrator(tokenId);
        _saveSRR(tokenId, isPrimaryIssuer, artistAddress);

        emit UpdateSRR(tokenId, isPrimaryIssuer, artistAddress, msgSender());
    }

    /**
     * @dev Updates the SRR metadata
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param metadataDigest bytes32 of the metadata hash
     */
    function updateSRRMetadata(uint256 tokenId, bytes32 metadataDigest)
        external
        override(IStartrailRegistryV23)
    {
        tokenExists(tokenId);
        onlyIssuerOrArtistOrAdministrator(tokenId);
        _bytes32Storage[tokenId][_SRR][_METADATA_HASH] = metadataDigest;
        emit UpdateSRRMetadataDigest(tokenId, metadataDigest);
    }

    /**
     * @dev Updates the SRR metadata
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param metadataCID string of ipfs cid
     */
    function updateSRRMetadata(uint256 tokenId, string memory metadataCID)
        external
        override(IStartrailRegistryV23)
    {
        tokenExists(tokenId);
        onlyIssuerOrArtistOrAdministrator(tokenId);
        _stringStorage[tokenId][_SRR][_METADATA_HASH] = metadataCID;
        emit UpdateSRRMetadataDigest(tokenId, metadataCID);
    }

    /**
     * @dev Updates the SRR Royalty
     * Only apply to srrs created with royalty info
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param royaltyReceiver royalty receiver
     * @param royaltyBasisPoints royalty basis points
     */
    function updateSRRRoyalty(
        uint256 tokenId,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) external override(IStartrailRegistryV23) {
        tokenExists(tokenId);
        onlyIssuerOrArtistOrAdministrator(tokenId);

        RoyaltyInfo memory royalty = royalties[tokenId];
        if (royalty.receiver != address(0)) {
            _saveRoyalties(tokenId, royaltyBasisPoints, royaltyReceiver);
            emit RoyaltiesSet(tokenId, RoyaltyInfo(
                royaltyReceiver,
                royaltyBasisPoints
            ));
        }
    }

    /**
     * @dev Updates the SRR Royalty Receiver from multi token ids
     * Only apply to srrs created with royalty info
     * @param tokenIds  token ids
     * @param royaltyReceiver royalty receiver
     */
    function updateSRRRoyaltyReceiverMulti(
        uint256[] calldata tokenIds,
        address royaltyReceiver
    ) external override(IStartrailRegistryV23) {
        onlyAdministrator();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenExists(tokenIds[i]);

            RoyaltyInfo memory royalty = royalties[tokenIds[i]];
            if (royalty.receiver != address(0)) {
                _saveRoyalties(
                    tokenIds[i],
                    royalty.basisPoints,
                    royaltyReceiver
                );
                
                emit RoyaltiesSet(tokenIds[i], RoyaltyInfo(
                    royaltyReceiver,
                    royalty.basisPoints
                ));
            }
        }
    }

    /**
     * @dev Approves the given commitment hash to transfer the SRR
     * @param tokenId uint256 ID of the SRR
     * @param commitment bytes32 of the commitment hash
     * @param historyMetadataHash string of the history metadata digest or cid
     */
    function approveSRRByCommitment(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash
    ) external override(IStartrailRegistryV23) {
        onlySRROwnerOrAdministrator(tokenId);
        _approveSRRByCommitment(
            tokenId,
            commitment,
            historyMetadataHash,
            _NO_CUSTOM_HISTORY
        );
    }

    /**
     * @dev Approves the given commitment hash to transfer the SRR with custom history id
     * @param tokenId uint256 ID of the SRR
     * @param commitment bytes32 of the commitment hash
     * @param historyMetadataHash string of the history metadata digest or cid
     * @param customHistoryId to map with custom history
     */
    function approveSRRByCommitment(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash,
        uint256 customHistoryId
    ) external override(IStartrailRegistryV23) {
        onlySRROwnerOrAdministrator(tokenId);
        customHistoryIdExists(customHistoryId);
        _approveSRRByCommitment(
            tokenId,
            commitment,
            historyMetadataHash,
            customHistoryId
        );
    }

    /**
     * @dev Cancels the current commitment of a given SRR
     * @param tokenId uint256 ID of the SRR
     */
    function cancelSRRCommitment(uint256 tokenId)
        external
        override(IStartrailRegistryV23)
    {
        onlySRROwnerOrAdministrator(tokenId);
        _clearSRRCommitment(tokenId);
        emit SRRCommitmentCancelled(tokenId);
    }

    /**
     * @dev Transfers the ownership of a given SRR ID to another address.
     * @param to address to receive the ownership
     * @param reveal bytes32 of the reveal hash value to restore the commitment value
     * @param tokenId uint256 ID of the SRR to be transferred
     * @param isIntermediary bool flag of the intermediary default is false
     */
    function transferSRRByReveal(
        address to,
        bytes32 reveal,
        uint256 tokenId,
        bool isIntermediary
    ) external override(IStartrailRegistryV23) {
        tokenExists(tokenId);

        bytes32 commitment;
        (commitment, , ) = getSRRCommitment(tokenId);
        require(
            keccak256(abi.encodePacked(reveal)) == commitment,
            "Hash of reveal doesn't match"
        );

        address from = ownerOf(tokenId);

        _historyProvenance(
            tokenId,
            from,
            to,
            _stringStorage[tokenId][_HISTORY][_METADATA_HASH],
            _uintStorage[tokenId][_HISTORY][_CUSTOM_HISTORY],
            isIntermediary
        );

        _clearSRRCommitment(tokenId);

        ERC721UpgradeSafe._transfer(from, to, tokenId);
    }

    /**
     * @dev Associating custom histories with SRRs
     * @param tokenIds Array of SRR token IDs
     * @param customHistoryIds Array of customHistoryIds
     */
    function addHistory(
        uint256[] calldata tokenIds,
        uint256[] calldata customHistoryIds
    ) external override(IStartrailRegistryV23) {
        onlyLicensedUserOrAdministrator();
        require(
            tokenIds.length * customHistoryIds.length <=
                maxCombinedHistoryRecords,
            "maximum number of combined tokens and histories exceeded"
        );

        uint16 i;

        for (i = 0; i < tokenIds.length; i++) {
            require(
                ERC721UpgradeSafe._exists(tokenIds[i]),
                "one of the tokenIds does not exist"
            );
            onlyIssuerOrArtistOrAdministrator(tokenIds[i]);
        }

        for (i = 0; i < customHistoryIds.length; i++) {
            // REVERTs inside this call if the id does not exist
            customHistoryIdExists(customHistoryIds[i]);
        }

        emit History(tokenIds, customHistoryIds);
    }

    /**
     * @dev Sets the addresses of the reference
     * @param nameRegistry address of the NameRegistry
     */
    function setNameRegistryAddress(address nameRegistry)
        external
        override(IStartrailRegistryV23)
    {
        require(nameRegistry != address(0), "nameRegistry cannot be 0 address");
        onlyAdministrator();
        nameRegistryAddress = nameRegistry;
    }

    /**
     * @dev Sets the URI info of the scheme where SRR metadata is saved
     * @param URIPrefix string of the URI prefix of the scheme
     * @param URIPostfix string of the URI postfix of the scheme
     */
    function setTokenURIParts(string memory URIPrefix, string memory URIPostfix)
        external
        override(IStartrailRegistryV23)
    {
        onlyAdministrator();
        _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_PREFIX] = URIPrefix;
        _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_POSTFIX] = URIPostfix;
    }

    /**
     * @dev Gets the registryRecord related with the tokenId
     * @param tokenId uint256 ID of StartrailRegistry
     * @return registryRecord dataset / metadataDigest
     */
    function getSRR(uint256 tokenId)
        public
        view
        override(IStartrailRegistryV23)
        returns (SRR memory registryRecord, bytes32 metadataDigest)
    {
        tokenExists(tokenId);
        registryRecord.isPrimaryIssuer = _boolStorage[tokenId][_SRR][
            _IS_PRIMARY_ISSUER
        ];
        registryRecord.artistAddress = _addressStorage[tokenId][_SRR][
            _ARTIST_ADDRESS
        ];
        registryRecord.issuer = _addressStorage[tokenId][_SRR][_ISSUER];
        metadataDigest = _bytes32Storage[tokenId][_SRR][_METADATA_HASH];
    }

    /**
     * @dev Gets the given commitment hash to transfer the SRR
     * @param tokenId uint256 ID of StartrailRegistry
     * @return commitment details
     */
    function getSRRCommitment(uint256 tokenId)
        public
        view
        override(IStartrailRegistryV23)
        returns (
            bytes32 commitment,
            string memory historyMetadataHash,
            uint256 customHistoryId
        )
    {
        tokenExists(tokenId);
        commitment = _bytes32Storage[tokenId][_SRR][_COMMITMENT];
        historyMetadataHash = _stringStorage[tokenId][_HISTORY][_METADATA_HASH];
        customHistoryId = _uintStorage[tokenId][_HISTORY][_CUSTOM_HISTORY];
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     * @param tokenId id of token to return metadata string for
     * @return URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bool isCID = isNotEmptyString(
            _stringStorage[tokenId][_SRR][_METADATA_HASH]
        );
        if (isCID) {
            return
                StartrailRegistryLibraryV1.tokenURIFromString(
                    _stringStorage[tokenId][_SRR][_METADATA_HASH],
                    "ipfs://",
                    ""
                );
        } else {
            return
                StartrailRegistryLibraryV1.tokenURIFromBytes32(
                    _bytes32Storage[tokenId][_SRR][_METADATA_HASH],
                    _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_PREFIX],
                    _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_POSTFIX]
                );
        }
    }

    /**
     * @dev Gets URI where the matadata is saved
     * @param metadataDigest string of metadata digests with 0x prefix or metadata cid
     * @return URI
     */
    function tokenURI(string memory metadataDigest)
        public
        view
        override(IStartrailRegistryV23)
        returns (string memory)
    {
        // length == 0x + 64, it's metadataDigest not ipfs cid
        if (bytes(metadataDigest).length == 66) {
            return
                StartrailRegistryLibraryV1.tokenURIFromString(
                    metadataDigest,
                    _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_PREFIX],
                    _stringStorage[SRR_GLOBAL_SLOT][_SRR][_URI_POSTFIX]
                );
        } else {
            // it's cid
            return
                StartrailRegistryLibraryV1.tokenURIFromString(
                    metadataDigest,
                    "ipfs://",
                    ""
                );
        }
    }

    /**
     * @dev add history type before creating history id: exhibition
     * @param historyTypeName name of the custom history type
     */
    function addCustomHistoryType(string memory historyTypeName)
        external
        override(IStartrailRegistryV23)
    {
        onlyAdministrator();
        require(
            customHistoryTypeIdByName[historyTypeName] == 0,
            "History type with the same name already exists"
        );

        customHistoryTypeCount++;

        customHistoryTypeNameById[customHistoryTypeCount] = historyTypeName;
        customHistoryTypeIdByName[historyTypeName] = customHistoryTypeCount;

        emit CreateCustomHistoryType(customHistoryTypeCount, historyTypeName);
    }

    /**
     * @dev Write custom history id: exhibition
     * @param name of the custom history
     * @param customHistoryTypeId of the custom history
     * @param metadataDigest representing custom history
     */
    function writeCustomHistory(
        string memory name,
        uint256 customHistoryTypeId,
        bytes32 metadataDigest
    ) public override(IStartrailRegistryV23) {
        onlyAdministrator();

        require(
            bytes(customHistoryTypeNameById[customHistoryTypeId]).length != 0,
            "The custom history type id does not exist"
        );

        customHistoryCount++;

        _stringStorage[customHistoryCount][_CUSTOM_HISTORY][
            _CUSTOM_HISTORY_NAME
        ] = name;
        emit CreateCustomHistory(
            customHistoryCount,
            name,
            customHistoryTypeId,
            metadataDigest
        );
    }

    /**
     * @dev Write custom history id: exhibition
     * @param name of the custom history
     * @param customHistoryTypeId of the custom history
     * @param metadataCID representing custom history
     */
    function writeCustomHistory(
        string memory name,
        uint256 customHistoryTypeId,
        string memory metadataCID
    ) public override(IStartrailRegistryV23) {
        onlyAdministrator();

        require(
            bytes(customHistoryTypeNameById[customHistoryTypeId]).length != 0,
            "The custom history type id does not exist"
        );

        customHistoryCount++;

        _stringStorage[customHistoryCount][_CUSTOM_HISTORY][
            _CUSTOM_HISTORY_NAME
        ] = name;
        emit CreateCustomHistory(
            customHistoryCount,
            name,
            customHistoryTypeId,
            metadataCID
        );
    }

    /**
     * @dev update custom history id: exhibition
     * @param customHistoryId of the custom history to update
     * @param name of the custom history
     * @param metadataDigest representing custom history
     */
    function updateCustomHistory(
        uint256 customHistoryId,
        string memory name,
        bytes32 metadataDigest
    ) public override(IStartrailRegistryV23) {
        onlyAdministrator();

        // REVERTs inside this call if the id does not exist
        customHistoryIdExists(customHistoryId);

        requireCustomHistoryName(name);

        if (
            keccak256(bytes(getCustomHistoryNameById(customHistoryId))) !=
            keccak256(bytes(name))
        ) {
            _stringStorage[customHistoryId][_CUSTOM_HISTORY][
                _CUSTOM_HISTORY_NAME
            ] = name;
        }

        emit UpdateCustomHistory(customHistoryId, name, metadataDigest);
    }

    /**
     * @dev update custom history id: exhibition
     * @param customHistoryId of the custom history to update
     * @param name of the custom history
     * @param metadataCID representing custom history ipfs cid
     */
    function updateCustomHistory(
        uint256 customHistoryId,
        string memory name,
        string memory metadataCID
    ) public override(IStartrailRegistryV23) {
        onlyAdministrator();

        // REVERTs inside this call if the id does not exist
        customHistoryIdExists(customHistoryId);

        requireCustomHistoryName(name);

        if (
            keccak256(bytes(getCustomHistoryNameById(customHistoryId))) !=
            keccak256(bytes(name))
        ) {
            _stringStorage[customHistoryId][_CUSTOM_HISTORY][
                _CUSTOM_HISTORY_NAME
            ] = name;
        }

        emit UpdateCustomHistory(customHistoryId, name, metadataCID);
    }

    /**
     * @dev Gets custom history name by id
     * @param id uint256 of customHistoryId
     * @return custom history name
     */
    function getCustomHistoryNameById(uint256 id)
        public
        view
        override(IStartrailRegistryV23)
        returns (string memory)
    {
        return _stringStorage[id][_CUSTOM_HISTORY][_CUSTOM_HISTORY_NAME];
    }

    /*
     * private functions
     */
    function _createSRR(
        bool isPrimaryIssuer,
        address artistAddress,
        bytes32 metadataDigestBytes32,
        string memory metadataCID, // `calldata` triggers compiler bug #7929
        address sender,
        bool lockExternalTransfer_,
        address royaltyReceiver,
        uint16 royaltyBasisPoints
    ) private returns (uint256 tokenId) {
        bool isCID = isNotEmptyString(metadataCID);

        // check if SRR already exists on chain for artist and metadata combination
        // it's needed for the situation happens if a user send the tx to this contract directly
        require(
            !ERC721UpgradeSafe._exists(
                IDGeneratorV3.generate(metadataDigestBytes32, artistAddress)
            ),
            "SRR already exists on chain for artist/metadata combination"
        );
        require(
            !ERC721UpgradeSafe._exists(
                IDGeneratorV3.generate(metadataCID, artistAddress)
            ),
            "SRR already exists on chain for artist/metadata combination"
        );

        if (royaltyReceiver != address(0)) {
            require(
                royaltyBasisPoints <= 10000,
                "ERC2981: royalty fee will exceed salePrice"
            );
        }

        tokenId = isCID
            ? IDGeneratorV3.generate(metadataCID, artistAddress)
            : IDGeneratorV3.generate(metadataDigestBytes32, artistAddress);

        ERC721UpgradeSafe._mint(sender, tokenId);

        _addressStorage[tokenId][_SRR][_ISSUER] = sender;

        if (isCID) {
            _stringStorage[tokenId][_SRR][_METADATA_HASH] = metadataCID;
        } else {
            _bytes32Storage[tokenId][_SRR][
                _METADATA_HASH
            ] = metadataDigestBytes32;
        }

        _boolStorage[tokenId][_SRR][
            _LOCK_EXTERNAL_TRANSFER
        ] = lockExternalTransfer_;

        _saveSRR(tokenId, isPrimaryIssuer, artistAddress);

        if (isCID) {
            emit CreateSRR(
                tokenId,
                SRR(isPrimaryIssuer, artistAddress, sender),
                metadataCID,
                lockExternalTransfer_
            );
        } else {
            emit CreateSRR(
                tokenId,
                SRR(isPrimaryIssuer, artistAddress, sender),
                metadataDigestBytes32,
                lockExternalTransfer_
            );
        }

        if (royaltyReceiver != address(0)) {
            _saveRoyalties(tokenId, royaltyBasisPoints, royaltyReceiver);
            emit RoyaltiesSet(tokenId, RoyaltyInfo(
                royaltyReceiver,
                royaltyBasisPoints
            ));
        }
    }

    /**
     * @dev Saves the registryRecord
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param isPrimaryIssuer boolean whether the user is a primary issuer
     */
    function _saveSRR(
        uint256 tokenId,
        bool isPrimaryIssuer,
        address artistAddress
    ) private {
        _addressStorage[tokenId][_SRR][_ARTIST_ADDRESS] = artistAddress;
        _boolStorage[tokenId][_SRR][_IS_PRIMARY_ISSUER] = isPrimaryIssuer;
    }

    function _approveSRRByCommitment(
        uint256 tokenId,
        bytes32 commitment,
        string memory historyMetadataHash,
        uint256 customHistoryId
    ) private {
        // If approve has already been called then emit event that signifies
        // that prior approval is cancelled.
        if (_bytes32Storage[tokenId][_SRR][_COMMITMENT] != "") {
            emit SRRCommitmentCancelled(tokenId);
        }
        _bytes32Storage[tokenId][_SRR][_COMMITMENT] = commitment;
        _stringStorage[tokenId][_HISTORY][_METADATA_HASH] = historyMetadataHash;
        if (customHistoryId == _NO_CUSTOM_HISTORY) {
            emit SRRCommitment(tokenId, ownerOf(tokenId), commitment);
        } else {
            _uintStorage[tokenId][_HISTORY][_CUSTOM_HISTORY] = customHistoryId;
            emit SRRCommitment(
                tokenId,
                ownerOf(tokenId),
                commitment,
                customHistoryId
            );
        }
    }

    function _historyProvenance(
        uint256 tokenId,
        address from,
        address to,
        string memory historyMetadataHash,
        uint256 customHistoryId, // adding this to support common private function to use emit history provenance
        bool isIntermediary
    ) private {
        string memory historyMetadataURI = tokenURI(historyMetadataHash);
        if (customHistoryId != _NO_CUSTOM_HISTORY) {
            emit Provenance(
                tokenId,
                from,
                to,
                customHistoryId,
                historyMetadataHash,
                historyMetadataURI,
                isIntermediary
            );
        } else {
            emit Provenance(
                tokenId,
                from,
                to,
                historyMetadataHash,
                historyMetadataURI,
                isIntermediary
            );
        }
    }

    function _clearSRRCommitment(uint256 tokenId) private {
        _bytes32Storage[tokenId][_SRR][_COMMITMENT] = "";
        _stringStorage[tokenId][_HISTORY][_METADATA_HASH] = "";
        _uintStorage[tokenId][_HISTORY][_CUSTOM_HISTORY] = 0;
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * This function overwrites transferFrom with the externalTransferNotLocked modifier.
     * If lockExternalTransfer of tokenId is true, the transfer is reverted.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        externalTransferNotLocked(tokenId);
        ERC721UpgradeSafe.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * This function overwrites safeTransferFrom with the externalTransferNotLocked modifier.
     * If lockExternalTransfer of tokenId is true, the transfer is reverted.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        externalTransferNotLocked(tokenId);
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * This function overwrites safeTransferFrom with the externalTransferNotLocked modifier.
     * If lockExternalTransfer of tokenId is true, the transfer is reverted.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        externalTransferNotLocked(tokenId);
        ERC721UpgradeSafe.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * This function is used when the transfer target is EOA by meta transaction feature.
     * And this feture is to record the provenance at the same time as safeTransferFrom is executed.
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param historyMetadataHash string of the history metadata digest or cid
     * @param customHistoryId to map with custom history
     * @param isIntermediary bool flag of the intermediary default is false
     */
    function transferFromWithProvenance(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external override(IStartrailRegistryV23) {
        onlySRROwnerOrAdministrator(tokenId);
        _transferFromWithProvenance(
            to,
            tokenId,
            historyMetadataHash,
            customHistoryId,
            isIntermediary
        );
    }

    function _transferFromWithProvenance(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) private {
        address from = ownerOf(tokenId);
        _historyProvenance(
            tokenId,
            from,
            to,
            historyMetadataHash,
            customHistoryId,
            isIntermediary
        );
        ERC721UpgradeSafe._safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * This function overwrites approve with the externalTransferNotLocked modifier.
     * If lockExternalTransfer of tokenId is true, the approval is reverted.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public override {
        externalTransferNotLocked(tokenId);
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner, "ERC721: approval to current owner");

        require(
            _msgSender() == tokenOwner ||
                isApprovedForAll(tokenOwner, _msgSender()) ||
                isAdministrator(),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Disable standard ERC721 transfer method
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param flag bool of the flag to disable standard ERC721 transfer methods
     */
    function setLockExternalTransfer(uint256 tokenId, bool flag)
        external
        override(IStartrailRegistryV23)
    {
        onlyIssuerOrAdministrator(tokenId);
        tokenExists(tokenId);
        _boolStorage[tokenId][_SRR][_LOCK_EXTERNAL_TRANSFER] = flag;
        emit LockExternalTransfer(tokenId, flag);
    }

    /**
     * @dev Get the flag to disable standard ERC721 transfer method
     * @param tokenId uint256 of StartrailRegistryRecordID
     */
    function lockExternalTransfer(uint256 tokenId)
        public
        view
        override(IStartrailRegistryV23)
        returns (bool)
    {
        return _boolStorage[tokenId][_SRR][_LOCK_EXTERNAL_TRANSFER];
    }

    /**************************************************************************
     *
     * OpenSea integration related functions
     *
     *************************************************************************/

    /**************************************************************************
     * contractURI
     *
     * For contract level metadata in OpenSea
     *************************************************************************/

    /**
     * @dev OpenSea specific function to provide contract level or "storefront"
     *   metadata.
     * see https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI()
        external
        view
        override(IStartrailRegistryV23)
        returns (string memory)
    {
        return _stringStorage[SRR_GLOBAL_SLOT][_SRR][_CONTRACT_URI];
    }

    /**
     * @dev Setter enabling admin to change the contract metadata URI
     */
    function setContractURI(string memory _contractURI)
        external
        override(IStartrailRegistryV23)
    {
        onlyAdministrator();
        _stringStorage[SRR_GLOBAL_SLOT][_SRR][_CONTRACT_URI] = _contractURI;
    }

    /**************************************************************************
     * Ownership
     *
     * For signatures to OpenSea that set contract level properties. This
     * can't be a contract address as OpenSea doesn't support that. So we will
     * set an EOA here that can sign messages from the OpenSea DApp.
     *************************************************************************/

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner. Follows the standard Ownable
     * naming for the event.
     */
    function transferOwnership(address newOwner)
        public
        override(IStartrailRegistryV23)
    {
        onlyAdministrator();
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**************************************************************************
     * Transfers and Approvals
     *
     * Override isApprovedAll to whitelist OpenSea addresses to approve(),
     * transferFrom() and safeTransferFrom tokens.
     *************************************************************************/

    /**
     * @dev Standard ERC721.isApprovedForAll with an additional whitelisting
     *   of OpenSea addresses registered with their ProxyRegistry contract.
     */
    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        // see docs here: https://docs.opensea.io/docs/polygon-basic-integration#code-example-for-erc721
        if (
            _boolStorage[SRR_GLOBAL_SLOT][_SRR][
                _OPENSEA_APPROVE_ALL_KILL_SWITCH
            ] ==
            false &&
            getOpenSeaProxyAddress() == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(tokenOwner, operator);
    }

    /**
     * @dev Turn on / off the kill switch for OpenSea isApprovedForAll ability.
     *
     * Basically a kill switch if we find the ProxyRegistry is compromised or
     * rogue or something.
     */
    function setOpenSeaApproveAllKillSwitch(bool on) public {
        onlyAdministrator();
        _boolStorage[SRR_GLOBAL_SLOT][_SRR][
            _OPENSEA_APPROVE_ALL_KILL_SWITCH
        ] = on;
    }

    /**************************************************************************
     * Meta Transactions
     *
     * Enable meta transactions that trigger approvals and transfers so
     * OpenSea users can send gas-less transactions.
     *
     * NOTE: these are entirely separate from the Startrail meta transactions
     *   which operate on Startrail specific functions.
     *************************************************************************/

    /**
     * @dev Setup OpenSea meta transaction integration details.
     *
     * Should be a one time function but we make it possible for the admin to
     * change this after the fact here in case we need to do that.
     */
    function setOpenSeaMetaTxIntegration(
        address proxyRegistryAddress,
        string calldata name
    ) public {
        onlyAdministrator();
        _addressStorage[SRR_GLOBAL_SLOT][_SRR][
            _OPENSEA_PROXY_ADDRESS
        ] = proxyRegistryAddress;
        openSeaMetaTx.setDomainSeparator(name);
    }

    /**
     * @dev Execute a meta transaction on one of the ERC721 approve/transfer functions.
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory callData,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public returns (bytes memory) {
        return
            openSeaMetaTx.executeMetaTransaction(
                userAddress,
                callData,
                sigR,
                sigS,
                sigV
            );
    }

    /**
     * @dev Get next meta-tx nonce by user.
     */
    function getNonce(address user) public view returns (uint256) {
        return openSeaMetaTx.nonces[user];
    }

    /**
     * @dev Get the chain id if callers building the signatures require this.
     *
     * In reality they should be aware of what chain they are sending too. But
     * not sure if OpenSea requires this getter to build the meta transaction
     * so making it public and available here to be sure.
     */
    function getChainId() public view returns (uint256) {
        return OpenSeaMetaTransactionLibrary.getChainId();
    }

    /**
     * @dev Get the domain seperator
     */
    function getDomainSeperator() public view returns (bytes32) {
        return openSeaMetaTx.getDomainSeperator();
    }

    /**
     * @dev Get the registered OpenSea proxy address
     */
    function getOpenSeaProxyAddress() public view returns (address) {
        return _addressStorage[SRR_GLOBAL_SLOT][_SRR][_OPENSEA_PROXY_ADDRESS];
    }

    /**
     * Override ERC721._msgSender to enable EIP2771 lookups for meta
     * transactions on the ERC721 functions transferFrom, safeTransferFrom,
     * approve, setApprovalForAll.
     *
     * NOTE: this function is distinct from the EIP2771BaseReceipient.msgSender
     * which is used for EIP2771 forwards for Startrail meta transactions
     * forwarded by the Startrail MetaTxForwarder.
     */
    function _msgSender() internal view override returns (address sender) {
        return
            OpenSeaMetaTransactionLibrary.msgSenderFromEIP2771MsgData(msg.data);
    }

    function isNotEmptyString(string memory _string)
        internal
        pure
        returns (bool)
    {
        return bytes(_string).length > 0;
    }

    /**
     * @dev Saves the Royalty
     * @param tokenId uint256 of StartrailRegistryRecordID
     * @param basisPoints uint16
     * @param receiver address
     */
    function _saveRoyalties(
        uint256 tokenId,
        uint16 basisPoints,
        address receiver
    ) private {
        require(
            receiver != address(0),
            "ERC2981: royalty receiver can not be address(0)"
        );

        require(
            basisPoints <= 10000,
            "ERC2981: royalty fee will exceed salePrice"
        );

        tokenExists(tokenId);

        royalties[tokenId] = RoyaltyInfo(receiver, basisPoints);
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *  The default receiver address 0x75194F40c5337d218A6798B02BbB34500a653A16 is what we use for OpenSea.
     *  For all environments like QA, STG and production. As we set the default royalty to 0, this shouldn’t matter.
     *  @param _tokenId - the NFT asset queried for royalty information
     *  @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *  @return receiver - address of who should be sent the royalty payment
     *  @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.receiver == address(0)) {
            royalty = RoyaltyInfo(
                0x75194F40c5337d218A6798B02BbB34500a653A16,
                0
            );
        }
        
        uint256 royaltyAmount = (_salePrice * royalty.basisPoints) / 10000;

        return (royalty.receiver, royaltyAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

contract Storage {
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => address)))
        internal _addressStorage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => uint256)))
        internal _uintStorage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => bool)))
        internal _boolStorage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => int256)))
        internal _intStorage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => bytes)))
        internal _bytesStorage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => bytes32)))
        internal _bytes32Storage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => string)))
        internal _stringStorage;
    mapping(uint256 => mapping(bytes32 => mapping(bytes32 => uint8)))
        internal _uint8Storage;
}