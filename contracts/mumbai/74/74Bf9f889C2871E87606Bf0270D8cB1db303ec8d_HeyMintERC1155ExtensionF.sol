// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = keccak256(
    "diamond.storage.eip.712.permit"
);

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly {
        diamondStorage.slot := slot
    }
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
///      when using with a proxy, due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    bytes32 immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 immutable _NAME_HASH;
    bytes32 immutable _VERSION_HASH;

    constructor(string memory name, string memory version) {
        _EIP_712_DOMAIN_TYPEHASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _NAME_HASH = keccak256(bytes(name));
        _VERSION_HASH = keccak256(bytes(version));
    }

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
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
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner)
                revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC1155 = keccak256("diamond.storage.erc1155");

    function s() pure returns (ERC1155DS storage diamondStorage) {
        bytes32 slot = DIAMOND_STORAGE_ERC1155;
        assembly {
            diamondStorage.slot := slot
        }
    }

    struct ERC1155DS {
        mapping(address => mapping(uint256 => uint256)) balanceOf;
        mapping(address => mapping(address => bool)) isApprovedForAll;
    }

// ------------- errors

    error NotAuthorized();
    error LengthMismatch();
    error UnsafeRecipient();

/// @title ERC1155 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate ERC1155 (https://github.com/Rari-Capital/solmate)
abstract contract ERC1155UDS is EIP712PermitUDS("ERC1155Permit", "1") {
    ERC1155DS private __storageLayout; // storage layout for upgrade compatibility checks

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

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

    /* ------------- virtual ------------- */

    function uri(uint256 id) public view virtual returns (string memory);

    /* ------------- view ------------- */

    function balanceOf(
        address owner,
        uint256 id
    ) public view virtual returns (uint256) {
        return s().balanceOf[owner][id];
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        if (owners.length != ids.length) revert LengthMismatch();

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = s().balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function isApprovedForAll(
        address operator,
        address owner
    ) public view returns (bool) {
        return s().isApprovedForAll[operator][owner];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
        interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /* ------------- public ------------- */

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (msg.sender != from && !s().isApprovedForAll[from][msg.sender])
            revert NotAuthorized();

        s().balanceOf[from][id] -= amount;
        s().balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                msg.sender,
                from,
                id,
                amount,
                data
            ) != ERC1155TokenReceiver.onERC1155Received.selector
        ) revert UnsafeRecipient();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual {
        if (ids.length != amounts.length) revert LengthMismatch();
        if (msg.sender != from && !s().isApprovedForAll[from][msg.sender])
            revert NotAuthorized();

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length;) {
            id = ids[i];
            amount = amounts[i];

            s().balanceOf[from][id] -= amount;
            s().balanceOf[to][id] += amount;

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                amounts,
                data
            ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert UnsafeRecipient();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        s().balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                amount,
                data
            ) != ERC1155TokenReceiver.onERC1155Received.selector
        ) revert UnsafeRecipient();
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength;) {
            s().balanceOf[to][ids[i]] += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (
            to.code.length == 0
                ? to == address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                msg.sender,
                address(0),
                ids,
                amounts,
                data
            ) != ERC1155TokenReceiver.onERC1155BatchReceived.selector
        ) revert UnsafeRecipient();
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength;) {
            s().balanceOf[from][ids[i]] -= amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        s().balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, Data} from "../libraries/HeyMintStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HeyMintERC1155ExtensionF is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ FREE CLAIM ============

    /**
     * @notice To be updated by contract owner to allow free claiming tokens
     * @param _tokenId The id of the token to update
     * @param _freeClaimActive If true tokens can be claimed for free
     */
    function setFreeClaimState(uint16 _tokenId, bool _freeClaimActive) external onlyOwner {
        TokenConfig storage tokenCfg = HeyMintStorage.state().tokens[_tokenId];
        if (_freeClaimActive) {
            require(
                tokenCfg.freeClaimContractAddress != address(0),
                "NOT_CONFIGURED"
            );
            require(tokenCfg.mintsPerFreeClaim != 0, "NOT_CONFIGURED");
        }
        tokenCfg.freeClaimActive = _freeClaimActive;
    }

    /**
     * @notice Set the contract address of the NFT eligible for free claim
     * @param _tokenId The id of the token to update
     * @param _freeClaimContractAddress The new contract address
     */
    function setFreeClaimContractAddress(
        uint16 _tokenId,
        address _freeClaimContractAddress
    ) external onlyOwner {
        HeyMintStorage
        .state()
        .tokens[_tokenId]
        .freeClaimContractAddress = _freeClaimContractAddress;
    }

    /**
     * @notice Update the number of free mints claimable per token redeemed from the external ERC721 contract
     * @param _tokenId The id of the token to update
     * @param _mintsPerFreeClaim The new number of free mints per token redeemed
     */
    function updateMintsPerFreeClaim(
        uint16 _tokenId,
        uint8 _mintsPerFreeClaim
    ) external onlyOwner {
        HeyMintStorage.state().tokens[_tokenId].mintsPerFreeClaim = _mintsPerFreeClaim;
    }

    /**
     * @notice Check if an array of tokens is eligible for free claim
     * @param _tokenId The id of the token on this contract
     * @param _claimTokenIds The ids of the tokens to check
     */
    function checkFreeClaimEligibility(
        uint16 _tokenId,
        uint256[] calldata _claimTokenIds
    ) external view returns (bool[] memory) {
        Data storage data = HeyMintStorage.state().data;
        bool[] memory eligible = new bool[](_claimTokenIds.length);
        for (uint256 i = 0; i < _claimTokenIds.length; i++) {
            eligible[i] = !data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]];
        }
        return eligible;
    }

    /**
     * @notice Free claim token when msg.sender owns the token in the external contract
     * @param _tokenId The id of the token to mint
     * @param _claimTokenIds The ids of the tokens to redeem
     */
    function freeClaim(
        uint16 _tokenId,
        uint256[] calldata _claimTokenIds
    ) external payable nonReentrant {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 tokenIdsLength = _claimTokenIds.length;
        uint256 totalMints = tokenIdsLength * state.tokens[_tokenId].mintsPerFreeClaim;
        require(
            state.tokens[_tokenId].freeClaimContractAddress != address(0),
            "NOT_CONFIGURED"
        );
        require(state.tokens[_tokenId].mintsPerFreeClaim != 0, "NOT_CONFIGURED");
        require(state.tokens[_tokenId].freeClaimActive, "NOT_ACTIVE");
        require(
            state.data.totalSupply[_tokenId] + totalMints <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        if (state.cfg.heyMintFeeActive) {
            uint256 heymintFee = totalMints * heymintFeePerToken();
            require(msg.value == heymintFee, "PAYMENT_INCORRECT");
            (bool success,) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }
        IERC721 ExternalERC721FreeClaimContract = IERC721(
            state.tokens[_tokenId].freeClaimContractAddress
        );
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            require(
                ExternalERC721FreeClaimContract.ownerOf(_claimTokenIds[i]) ==
                msg.sender,
                "MUST_OWN_TOKEN"
            );
            require(
                !state.data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]],
                "TOKEN_ALREADY_CLAIMED"
            );
            state.data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]] = true;
        }
        _mint(msg.sender, _tokenId, totalMints, "");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Data, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC1155UDS} from "./ERC1155UDS.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUDS} from "./OwnableUDS.sol";
import {PausableUDS} from "./PausableUDS.sol";
import {ReentrancyGuardUDS} from "./ReentrancyGuardUDS.sol";
import {RevokableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";

/**
 * @title HeyMintERC1155Upgradeable
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This contract contains shared logic to be inherited by all implementation contracts
 */
contract HeyMintERC1155Upgradeable is
ERC1155UDS,
OwnableUDS,
PausableUDS,
ReentrancyGuardUDS,
RevokableOperatorFiltererUpgradeable
{
    using HeyMintStorage for HeyMintStorage.State;

    uint256 public constant defaultHeymintFeePerToken = 0.0007 ether;
    address public constant heymintPayoutAddress =
    0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;

    // ============ BASE FUNCTIONALITY ============

    function uri(uint256 _id) public view virtual override(ERC1155UDS) returns (string memory)
    {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 id = uint16(_id);
        if (bytes(state.tokens[id].tokenUri).length > 0) {
            return string.concat(state.tokens[id].tokenUri, "{id}");
        }
        return string.concat(state.cfg.uriBase, "{id}");
    }

    /**
     * @notice Returns the owner of the contract
     */
    function owner()
    public
    view
    virtual
    override(OwnableUDS, RevokableOperatorFiltererUpgradeable)
    returns (address)
    {
        return OwnableUDS.owner();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    /**
     * @notice Returns true if the contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
    public
    view
    virtual
    override(ERC1155UDS)
    returns (bool)
    {
        // Supports the following interfaceIds:
        // - ERC-1155: 0xd9b67a26
        // - IERC2981: 0x2a55205a
        // - IERC165: 0x01ffc9a7
        return
        ERC1155UDS.supportsInterface(interfaceId) ||
        type(IERC2981Upgradeable).interfaceId == interfaceId ||
        type(IERC165Upgradeable).interfaceId == interfaceId;
    }

    // ============ HEYMINT FEE ============

    /**
     * @notice Returns the HeyMint fee per token. If the fee is active but 0, the default fee is returned
     */
    function heymintFeePerToken() public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 fee = state.data.heymintFeePerToken;
        return !state.cfg.heyMintFeeActive ? 0 : fee == 0 ? defaultHeymintFeePerToken : fee;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view virtual returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_PAUSABLE = keccak256("diamond.storage.pausable");

function s() pure returns (PausableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_PAUSABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct PausableDS {
    uint256 paused;
}

// ------------- errors

error Paused();
error AlreadyPaused();
error AlreadyUnpaused();

/// @title Puasable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
contract PausableUDS {
    PausableDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- internal ------------- */

    function _pause() internal {
        if (s().paused == 2) revert AlreadyPaused();

        s().paused = 2;
    }

    function _unpause() internal {
        if (s().paused != 2) revert AlreadyUnpaused();

        s().paused = 1;
    }

    /* ------------- modifier ------------- */

    modifier notPaused() {
        if (s().paused == 2) revert Paused();

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_REENTRANCY_GUARD = keccak256("diamond.storage.reentrancy.guard");

function s() pure returns (ReentrancyGuardDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_REENTRANCY_GUARD;
    assembly {
        diamondStorage.slot := slot
    }
}

struct ReentrancyGuardDS {
    uint256 locked;
}

// ------------- errors

error ReentrancyNotPermitted();

/// @title Reentrancy Guard (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ReentrancyGuardUDS {
    ReentrancyGuardDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- modifier ------------- */

    modifier nonReentrant() {
        if (s().locked == 2) revert ReentrancyNotPermitted();

        s().locked = 2;

        _;

        s().locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

    struct BaseConfig {
        // Used to create a default HeyMint Launchpad URI for token metadata to save gas over setting a custom URI and increase fetch reliability
        uint24 projectId;
        // The base URI for all token metadata
        string uriBase;
        // If true, the default CORI subscription address will be used to enforce royalties with the Operator Filter Registry
        bool enforceRoyalties;
        // The royalty payout percentage in basis points
        uint16 royaltyBps;
        // If true, HeyMint fees will be charged for minting tokens
        bool heyMintFeeActive;
        // The address used to sign and validate presale mints
        address presaleSignerAddress;
    }

    struct TokenConfig {
        uint16 tokenId;
        // Maximum supply of tokens that can be minted
        uint16 maxSupply;
        // If true tokens can be minted in the public sale
        bool publicSaleActive;
        // The price of a token in the public sale in 1/100,000 ETH - e.g. 1 = 0.00001 ETH, 100,000 = 1 ETH - multiply by 10^13 to get correct wei amount
        uint32 publicPrice;
        // The number of tokens that can be minted in the public sale per address
        uint8 publicMintsAllowedPerAddress;
        // If enabled, automatic start and stop times for the public sale will be enforced, otherwise ignored
        bool usePublicSaleTimes;
        // The automatic start time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
        uint32 publicSaleStartTime;
        // The automatic end time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
        uint32 publicSaleEndTime;
        // If true tokens can be minted in the presale
        bool presaleActive;
        // The price of a token in the presale in 1/100,000 ETH
        uint32 presalePrice;
        // Total number of tokens available for minting in the presale
        uint16 presaleMaxSupply;
        // The number of tokens that can be minted in the presale per address
        uint8 presaleMintsAllowedPerAddress;
        // If enabled, automatic start and stop times for the presale will be enforced, otherwise ignored
        bool usePresaleTimes;
        // The automatic start time for the presale (if usePresaleTimes is true and presaleActive is true)
        uint32 presaleStartTime;
        // The automatic end time for the presale (if usePresaleTimes is true and presaleActive is true)
        uint32 presaleEndTime;
        // The uri for this token (defaults to using uriBase if not set).
        string tokenUri;
        // TODO: Considering putting TokenAdvancedConfig in a separate struct/mapping?
        // Free claim
        address freeClaimContractAddress; // TODO: confirm this addr is per token & not per collection.
        uint16 mintsPerFreeClaim;
        bool freeClaimActive;
        // Burn to mint
        uint32 burnPayment;
        uint16 mintsPerBurn;
        bool burnClaimActive;
        // Soulbinding
        bool soulbindingActive;
        // If set, the UTC timestamp in seconds until which tokens are refundable for refundPrice
        uint32 refundEndsAt; // TODO: should we be careful to ensure that this cannot be decreased or removed by the owner?
        // The amount returned to a user in a token refund in 1/100,000 ETH
        uint32 refundPrice;
    }

    struct AdvancedConfig {
        // Optional address where royalties are paid out. If not set, royalties are paid to the contract owner.
        address royaltyPayoutAddress;
        // The respective share of funds to be sent to each address in payoutAddresses in basis points
        uint16[] payoutBasisPoints;
        // The addresses to which funds are sent when a token is sold. If empty, funds are sent to the contract owner.
        address[] payoutAddresses;
        // Custom address that is allowed to call the 'creditCardMint' function.
        address creditCardMintAddress;
        // Soulbinding
        bool soulbindAdminTransfersPermanentlyDisabled;
        address soulboundAdminAddress;
        // The address where refunded tokens are returned. If not set, refunded tokens are sent to the contract owner.
        address refundAddress;
    }

    struct Data {
        // ============ BASE FUNCTIONALITY ============
        // All token ids on the contract
        uint16[] tokenIds;
        // HeyMint fee to be paid per minted token (if not set, defaults to defaultHeymintFeePerToken)
        uint256 heymintFeePerToken;
        // Keeps track of if advanced config settings have been initialized to prevent setting multiple times
        bool advancedConfigInitialized;
        // Keeps track of how many of each token have been minted.
        mapping(uint16 => uint16) totalSupply;
        // Keeps track of how many tokens each address has minted.
        mapping(address => mapping(uint16 => uint16)) tokensMintedByAddress;
        // If minting a token has been permanently disabled.
        mapping(uint16 => bool) tokenMintingPermanentlyDisabled;
        // Keeps track of token ids that have been used for free claim.
        mapping(uint16 => mapping(uint256 => bool)) tokenFreeClaimUsed;
        // Used to allow an admin to transfer soulbound tokens when necessary
        bool soulboundAdminTransferInProgress;
        // Used to determine the amount withdrawable for a specific token id after the refund period expires
        mapping(uint16 => uint256) totalPaidPerToken;
    }

    struct BurnToken {
        // The contract address of the token to be burned
        address contractAddress;
        // The type of contract - 1 = ERC-721, 2 = ERC-1155
        uint8 tokenType;
        // The number of tokens to burn per mint
        uint8 tokensPerBurn;
        // The ID of the token on an ERC-1155 contract eligible for burn; unused for ERC-721
        uint16 tokenId;
    }

library HeyMintStorage {
    struct State {
        string name;
        string symbol;
        BaseConfig cfg;
        mapping(uint16 => TokenConfig) tokens;
        mapping(uint16 => BurnToken[]) burnTokens;
        AdvancedConfig advCfg;
        Data data;
    }

    bytes32 internal constant STORAGE_SLOT =
    keccak256("heymint.launchpad.storage.erc1155");

    function state() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title  OperatorFiltererUpgradeable
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry when the init function is called.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
    /// @notice Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }

    /**
     * @dev A helper modifier to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper modifier to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

/**
 * @title  Upgradeable storage layout for RevokableOperatorFiltererUpgradeable.
 * @notice Upgradeable contracts must use a storage layout that can be used across upgrades.
 *         Only append new variables to the end of the layout.
 */
library RevokableOperatorFiltererUpgradeableStorage {
    struct Layout {
        /// @dev Whether the OperatorFilterRegistry has been revoked.
        bool _isOperatorFilterRegistryRevoked;
    }

    /// @dev The storage slot for the layout.
    bytes32 internal constant STORAGE_SLOT = keccak256("RevokableOperatorFiltererUpgradeable.contracts.storage");

    /// @dev The layout of the storage.
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently opt out of the OperatorFilterRegistry. The Registry
 *         itself has an "unregister" function, but if the contract is ownable, the owner can re-register at any point.
 *         As implemented, this abstract contract allows the contract owner to toggle the
 *         isOperatorFilterRegistryRevoked flag in order to permanently bypass the OperatorFilterRegistry checks.
 */
abstract contract RevokableOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    using RevokableOperatorFiltererUpgradeableStorage for RevokableOperatorFiltererUpgradeableStorage.Layout;

    error OnlyOwner();
    error AlreadyRevoked();

    event OperatorFilterRegistryRevoked();

    function __RevokableOperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe) internal {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(subscriptionOrRegistrantToCopy, subscribe);
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual override {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (
            !RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked
                && address(OPERATOR_FILTER_REGISTRY).code.length > 0
        ) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /**
     * @notice Disable the isOperatorFilterRegistryRevoked flag. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() external {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        if (RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked) {
            revert AlreadyRevoked();
        }
        RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked = true;
        emit OperatorFilterRegistryRevoked();
    }

    function isOperatorFilterRegistryRevoked() public view returns (bool) {
        return RevokableOperatorFiltererUpgradeableStorage.layout()._isOperatorFilterRegistryRevoked;
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);
}