/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// File: contracts/RNGQuest.sol


pragma solidity ^0.8.19;

/// @dev Apeiron
/// @title RandomNumberGenerationQuest
contract RandomNumberGenerationQuest {
    uint256 private constant PERCENT_DIVIDER = 1e3;
    uint256 private nonce;

    constructor() {}

    /// @notice Returns the result status of a quest, that is success or failure.
    /// @param index Quest index, which is also its difficulty.
    /// @param rarity Weapon rarity to consider in the formula.
    /// @return (status as hash, result as bool).
    function questResultStatus(uint256 index, uint128 rarity) internal returns (bytes32, bool) {
        uint256 probability_failure = questSuccessProbability(index, rarity) * PERCENT_DIVIDER;
        uint256 random_number = generateNumber();
        bool result = random_number <= probability_failure;
        bytes32 status = result ? keccak256("SUCCESS") : keccak256("FAILURE");

        require(rarity < 10, "Q: invalid weapon rarity.");

        return (status, result);
    }

    /// @notice Returns the result status of a quest, that is success or failure.
    /// @dev Adding a % success bonus is as easy as adding a number on top of this function.
    /// @param index Quest index, which is also its overall difficulty.
    /// @param rarity Weapon rarity to increase the probability of success.
    /// @return (status as hash, result as bool).
    function questSuccessProbability(uint256 index, uint128 rarity) internal pure returns (uint256) {
        uint256 size = 8;
        uint256[] memory probability_success = new uint256[](size); 
        uint256 bonus_for_rarity = rarity * 5; // up to 45% bonus

        probability_success[0] = 50; // 50% chance of success
        probability_success[1] = 40; // 40% chance of success
        probability_success[2] = 35; // 35% chance of success
        probability_success[3] = 50; // 50% chance of success
        probability_success[4] = 30; // 30% chance of success
        probability_success[5] = 40; // 40% chance of success
        probability_success[6] = 10; // 10% chance of success
        probability_success[7] = 30; // 30% chance of success

        require(index < size, "Q: Out of bound.");

        return probability_success[index] + bonus_for_rarity;
    }

    /// @notice Returns the result reward type, which is either ether or chests.
    /// @dev Pseudo-random number generation is satisfyingly random, as it uses non-deterministic variables.
    /// @dev 50% chance of returning true or false.
    /// @return Chests (true) or ether (false);
    function questResultRewardType() internal returns (bool) {
        uint256 probability = 50 * PERCENT_DIVIDER;
        uint256 random_number = generateNumber();

        return random_number <= probability;
    }

    /// @notice Returns a random number from 0 to 100.
    /// @dev Pseudo-random number generation is satisfyingly random, as it uses non-deterministic variables.
    /// @dev Minimum starts at min * percent_divider, to max * percent_divider.
    /// @return ether.
    function generateNumber() internal returns (uint256) {
        uint256 max = 100 * PERCENT_DIVIDER;
        uint256 random_number = uint256(keccak256(abi.encodePacked(block.prevrandao, block.difficulty, block.timestamp, block.coinbase, msg.sender, nonce++)));

        return random_number % max;
    }

    /// @notice Returns a random number from 0 to max.
    /// @dev Pseudo-random number generation is satisfyingly random, as it uses non-deterministic variables.
    /// @param _max Maximum number of the random number generation.
    /// @return ether.
    function generateNumberWithMax(uint256 _max) internal returns (uint256) {
        uint256 max = _max; // percent divider must be computed before function execution unlike generateNumber
        uint256 random_number = uint256(keccak256(abi.encodePacked(block.prevrandao, block.difficulty, block.timestamp, block.coinbase, msg.sender, nonce++)));

        return random_number % max;
    }
}
// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: contracts/IMain.sol


pragma solidity ^0.8.19;



struct Weapon {
  uint256 id;
  uint128 rarity;
  uint256 variation;
  bool destroyed;
}

struct Player {
  uint256 id;
  uint256 chests;
  uint256 weapon_equipped;
  uint256 quest_end;
}

interface IMain is IERC721Upgradeable {
  function getPlayer(address player) external view returns (Player memory);
  function getWeapon(uint256 id) external view returns (Weapon memory);
  function getWeaponOwner(uint256 id) external view returns (address);
  function getWeaponRarity(uint256 id) external view returns (uint128);
  function getWeaponEquipped(address player) external view returns (Weapon memory);
  function getWeaponsOwned(uint256 id) external view returns (Weapon[] memory weapons_owned);
  function getWeaponExistence(uint256 id) external view returns (bool);
  function getShareholders() external pure returns (address[] memory shareholders, uint256[] memory percents);
  function getShare(uint256 shareholder, uint256 amount) external pure returns (uint256);

  function startQuest(address _player, uint256 end) external;
  function completeQuest(address _player) external;
  function rewardChests(address _player, uint256 rewarded_chests) external;

  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function approve(address _to, uint256 _tokenId) external;
}
// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;






/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;




/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: contracts/quest.sol


pragma solidity ^0.8.19;


// THIS IS TESTNET. \\






contract Quest is RandomNumberGenerationQuest, UUPSUpgradeable, OwnableUpgradeable, IERC721ReceiverUpgradeable {
  /// @dev Quest logs for each player.
  struct QuestLog {
    uint256 id; // Unique ID for the quest.
    uint256 weapon_id; // Weapon token ID that is staked.
    uint256 index; // chosen quest index
    uint256 end; // end timestamp for the quest
    bytes32 status; // keccak256("ACTIVE") or keccak256("SUCCESS") or keccak256("FAILURE")
    uint256 index_text; // success or failure index to be interpretred by the frontend
  }

  /// @dev Data tracking of free quests.
  struct QuestFree {
    uint256 count; // number of free quests started per week
    uint256 date_weekly; // x free quests a week
  }

  /// @dev Rewards received by players, withdrawable.
  struct ReceivedRewards {
    uint256 as_ether;
    uint256 as_chests;
  }

  uint256 quest_count;
  QuestFree quest_free;
  uint256 quest_mul;
  IMain public MAIN;
  mapping(address => uint256) public player_quest_last_id;
  mapping(address => mapping(uint256 => QuestLog)) public quest_log;
  mapping(address => ReceivedRewards) public received_rewards;

  bool initialized;

  mapping(address => uint256) public player_quest_failed;
  mapping(address => uint256) public player_quest_succeeded;
 
  uint256[47] private __gap;

  /// @notice Initializes the smart contract.
  /// @dev Triggered on upgrades.
  /// @param main Main contract address to point to.
  function initialize(address main) initializer public {
    require(!initialized, "Already initialized.");

    __Ownable_init();

    MAIN = IMain(main);

    quest_free = QuestFree(0, block.timestamp);
    initialized = true;
  }

  event StartedQuest(uint256 indexed index, address indexed player, uint256 indexed weapon, uint128 rarity, uint256 variation);
  event StoppedQuest(uint256 id, uint256 indexed index, address indexed player);
  event CompletedQuestFailure(uint256 id, uint256 indexed index, address indexed player, uint256 indexed weapon, uint128 rarity, uint256 variation);
  event CompletedQuestSucceedChests(uint256 id, uint256 indexed index, address indexed player, uint256 indexed weapon, uint128 rarity, uint256 variation, uint256 reward);
  event CompletedQuestSucceedEther(uint256 id, uint256 indexed index, address indexed player, uint256 indexed weapon, uint128 rarity, uint256 variation, uint256 reward);

  /// @notice Changes quest rewards multiplier, up to 200%;
  /// @dev Used to adapt rewards to market analysis.
  /// @param mul New quest rewards multiplier.
  function setRewardsMul(uint256 mul) external onlyOwner payable {
    require(mul <= 200, "Rewards can't be set higher than 200%.");

    quest_mul = mul;
  }

  /// @notice Starts a quest by choosing an index. The player must have a character and have a weapon equipped.
  /// @dev Verifications are done right here, and not on startQuest from the main contract.
  /// @param index Quest index.
  function start(uint256 index) external payable {
    Player memory player = MAIN.getPlayer(_msgSender());
    Weapon memory weapon = MAIN.getWeaponEquipped(_msgSender());
    uint256 last_id = player_quest_last_id[_msgSender()];
    QuestLog storage quest = quest_log[_msgSender()][last_id];
    uint256 end = getQuestEndTime(index);
    uint256 cost = getQuestCost(index);
    uint256 days_since_weekly = (block.timestamp - quest_free.date_weekly) / 1 days;

    require(msg.value == cost, "Invalid ether value.");
    require(index < 8, "Unknown quest.");
    require(player.id != 0, "You must create a character.");
    require(player.weapon_equipped != 0, "Equip a weapon to start a quest.");
    require(player.quest_end == 0, "You are already doing a quest.");
    if (index == 0 && days_since_weekly < 7) require(quest_free.count < getQuestFreeMax(), "Free quest limit exceeded.");

    quest.id = last_id;
    quest.weapon_id = weapon.id;
    quest.index = index;
    quest.end = end;
    quest.status = keccak256("ACTIVE");
    quest_count++;

    if (index == 0) {
      if (days_since_weekly >= 7) {
        quest_free.count = 1;
        quest_free.date_weekly = block.timestamp;
      }

      else {
        quest_free.count++;
      }
    }

    MAIN.startQuest(_msgSender(), end);
    MAIN.safeTransferFrom(_msgSender(), address(this), weapon.id);

    _distributeEquity(msg.value);

    emit StartedQuest(index, _msgSender(), player.weapon_equipped, weapon.rarity, weapon.variation);
  }

  /// @notice Completes the last quest the player is doing.
  /// @dev Verifications are done right here, and not on completeQuest from the main contract.
  function complete() external {
    Player memory player = MAIN.getPlayer(_msgSender());
    Weapon memory weapon = MAIN.getWeaponEquipped(_msgSender());
    uint256 last_id = player_quest_last_id[_msgSender()];
    QuestLog storage quest = quest_log[_msgSender()][last_id];
    ReceivedRewards storage rewards = received_rewards[_msgSender()];
    (bytes32 status, uint256 index_text, bool result, bool chests) = _getQuestResult(quest.index);
    (uint256 rewards_ether, uint256 rewards_chest) = getQuestRewards(quest.index);

    require(player.quest_end != 0, "You are not running a quest.");
    require(player.quest_end <= block.timestamp, "Your quest is not finished.");

    quest.status = status;
    quest.end = 0;
    quest.index_text = index_text;
    ++player_quest_last_id[_msgSender()];

    MAIN.completeQuest(_msgSender());
    MAIN.approve(_msgSender(), quest.weapon_id);
    MAIN.safeTransferFrom(address(this), _msgSender(), quest.weapon_id);

    if (result) {
      ++player_quest_succeeded[_msgSender()];

      if ((chests && rewards_chest == 0) || (!chests && rewards_ether > 0)) { // reward is chest and rewards_chest is zero OR is a ether reward
        // then player is rewarded with ether
        rewards.as_ether += rewards_ether;

        emit CompletedQuestSucceedEther(quest.id, quest.index, _msgSender(), player.weapon_equipped, weapon.rarity, weapon.variation, rewards_ether);
      }

      else if ((!chests && rewards_ether == 0) || (chests && rewards_chest > 0)) { // reward is ether and rewards_ether is zero OR is a chest reward
        // then player is rewarded with chests
        rewards.as_chests += rewards_chest;

        emit CompletedQuestSucceedChests(quest.id, quest.index, _msgSender(), player.weapon_equipped, weapon.rarity, weapon.variation, rewards_chest);
      }

    }

    else { // quest is a failure
      rewards.as_chests += 0; 
      ++player_quest_failed[_msgSender()];

      emit CompletedQuestFailure(quest.id, quest.index, _msgSender(), player.weapon_equipped, weapon.rarity, weapon.variation);

    }
  }

  /// @notice Terminate a quest before it's complete.
  function cancel() external {
    Player memory player = MAIN.getPlayer(_msgSender());
    uint256 last_id = player_quest_last_id[_msgSender()];
    QuestLog storage quest = quest_log[_msgSender()][last_id];

    require(player.quest_end != 0, "You are not running a quest.");
    require(player.quest_end > block.timestamp, "Your quest is finished.");

    quest.status = keccak256("FAILURE");
    quest.end = 0;
    ++player_quest_last_id[_msgSender()];

    MAIN.completeQuest(_msgSender());
    MAIN.approve(_msgSender(), quest.weapon_id);
    MAIN.safeTransferFrom(address(this), _msgSender(), quest.weapon_id);

    emit StoppedQuest(quest.id, quest.index, _msgSender());
  }
 
  /// @notice Withdraw chest rewarded from quests.
  /// @dev Chests are rewarded from the main contract.
  function withdrawRewardChests() external {
    ReceivedRewards storage rewards = received_rewards[_msgSender()];
    uint256 chests = rewards.as_chests;

    require(chests > 0, "No chest rewards.");

    rewards.as_chests = 0;

    MAIN.rewardChests(_msgSender(), chests);
  }

  /// @notice Withdraw chest rewarded from quests.
  /// @dev Chests are rewarded from the main contract.
  function withdrawRewardEthers() external {
    ReceivedRewards storage rewards = received_rewards[_msgSender()];
    uint256 ethers = rewards.as_ether;

    require(ethers > 0, "No ether rewards.");

    rewards.as_ether = 0;

    payable(_msgSender()).transfer(ethers);
  }

  /// @notice Send equity from purchased chests to shareholders accordingly.
  /// @dev We ignore the returned value from send() because we don't want a shareholder to be an account that can't receive ether, as this would cause the transaction to revert.
  /// @param value Ether value to distribute.
  function _distributeEquity(uint256 value) private {
    (address[] memory shareholders, uint256[] memory percents) = MAIN.getShareholders();

    for (uint256 i = 0; i < shareholders.length; i++) {
      payable(shareholders[i]).send(MAIN.getShare(i, value));
    }
  }

  /// @notice Returns the result of a quest.
  /// @param index Quest index.
  /// @return Hashed quest status, its text index, whether it succeeded or not and whether the rewards is as ether or chests.
  function _getQuestResult(uint256 index) private returns (bytes32, uint256, bool, bool) {
    Weapon memory weapon = MAIN.getWeaponEquipped(_msgSender());
    (bytes32 status, bool result) = RandomNumberGenerationQuest.questResultStatus(index, weapon.rarity);
    (uint256 success_max, uint256 failure_max) = getQuestTextMax();
    bool chests = RandomNumberGenerationQuest.questResultRewardType();
    uint256 index_text_max;

    if (result) index_text_max = success_max;
    else index_text_max = failure_max;

    uint256 index_text = RandomNumberGenerationQuest.generateNumberWithMax(index_text_max);

    return (status, index_text, result, chests);
  }

  /// @notice Returns information of an active quest from a given user account and an id.
  /// @param id Quest ID relative to the user.
  /// @param account User account.
  /// @return All data of the active quest.
  function getQuestInfo(uint256 id, address account) external view returns (QuestLog memory) {
    return quest_log[account][id];
  }

  /// @notice Returns the last quest ID of a player.
  /// @param account User account.
  /// @return Last ID.
  function getLastQuestID(address account) external view returns (uint256) {
    return player_quest_last_id[account];
  }

  /// @notice Returns the end timestamp for a quest.
  /// @param index Quest index.
  /// @return The end timestamp for a quest given a quest index and rarity.
  function getQuestEndTime(uint256 index) public view returns (uint256) {
    uint256 duration = getQuestDuration(index);

    return duration + block.timestamp;
  }

  /// @notice Returns chest & ether rewards.
  /// @param index Quest index.
  /// @return Rewards as ether & chest.
  function getQuestRewards(uint256 index) public view returns (uint256, uint256) {
    uint256 size = 8;
    uint[] memory rewards_ether = new uint[](size);
    uint[] memory rewards_chest = new uint[](size);

    require(index < size, "R: Out of bound.");

    rewards_ether[0] = 0;
    rewards_ether[1] = 0;
    rewards_ether[2] = 0.001 ether; 
    rewards_ether[3] = 0; 
    rewards_ether[4] = 0.002 ether;
    rewards_ether[5] = 0.003 ether;
    rewards_ether[6] = 0.004 ether;
    rewards_ether[7] = 0.005 ether;

    rewards_chest[0] = 1;
    rewards_chest[1] = 1;
    rewards_chest[2] = 2;
    rewards_chest[3] = 2;
    rewards_chest[4] = 3;
    rewards_chest[5] = 4;
    rewards_chest[6] = 5;
    rewards_chest[7] = 5;

    return (rewards_ether[index] * quest_mul / 100, rewards_chest[index] * quest_mul / 100);
  }

  /// @notice Returns quest cost as ether given an index.
  /// @param index Quest index.
  /// @return Quest as ether.
  function getQuestCost(uint256 index) public pure returns (uint256) {
    uint256 size = 8;
    uint[] memory cost = new uint[](size);

    require(index < size, "Q: Out of bound.");

    cost[0] = 0;
    cost[1] = 0.001 ether;
    cost[2] = 0.002 ether;
    cost[3] = 0.003 ether;
    cost[4] = 0.004 ether;
    cost[5] = 0.005 ether;
    cost[6] = 0.006 ether;
    cost[7] = 0.007 ether;

    return cost[index];
  }

  /// @notice Returns quest duration given an index.
  /// @param index Quest index.
  /// @return Quest duration as a unix timestamp.
  function getQuestDuration(uint256 index) public pure returns (uint256) {
    uint256 size = 8;
    uint[] memory duration = new uint[](size);

    require(index < size, "D: Out of bound.");

    duration[0] = 0.1 days;
    duration[1] = 0.2 days;
    duration[2] = 0.4 days;
    duration[3] = 0.6 days;
    duration[4] = 0.8 days;
    duration[5] = 0.12 days;
    duration[6] = 0.14 days;
    duration[7] = 0.16 days;

    return duration[index];
  }

  /// @notice Returns the maximum index of text for failure or success.
  /// @return Success & Failure max indexes.
  function getQuestTextMax() public pure returns (uint256, uint256) {
    return (24, 24);
  }

  /// @notice Returns whether the given quest is active or not..
  /// @param id Quest ID relative to the user.
  /// @param account User account.
  /// @return Active (true) or not (false).
  function getQuestActive(uint256 id, address account) public view returns (bool) {
    return quest_log[account][id].status == keccak256("ACTIVE");
  }

  /// @notice Returns whether the given quest is a success or failure.
  /// @dev (false, false) => Failure
  /// @dev (false, true) => Active
  /// @dev (true, false) => Success
  /// @dev (false, false) can also be returned if the quest doesn't exist.
  /// @param id Quest ID relative to the user.
  /// @param account User account.
  /// @return Success (true) or failure (false), second returned value is whether it's active or not.
  function getQuestSuccessOrFailure(uint256 id, address account) public view returns (bool, bool) {
    return (quest_log[account][id].status == keccak256("SUCCESS"), getQuestActive(id, account));
  }

  /// @notice Returns the maximum number of started free quests per week.
  /// @return Amount of free quests a week.
  function getQuestFreeMax() public pure returns (uint256) {
    return 20;
  }

  /// @notice Returns the number of free quests remaining.
  /// @return Amount of free quests remaining.
  function getQuestFreeRemaining() public view returns (uint256) {
    return getQuestFreeMax() - quest_free.count;
  }

  /// @notice Returns the freee quest weekly timestamp.
  /// @return Weekly timestamp, refreshed every week.
  function getQuestFreeWeekLast() public view returns (uint256) {
    return quest_free.date_weekly;
  }

  /// @notice Upgrading the contract allows us to keep building, improving and expanding the game.
  /// @dev This allows upgrade of the contract.
  /// @param implementation New implementation address.
  function _authorizeUpgrade(address implementation) internal onlyOwner override {}

  /// @notice Adds support for receiving NFTs, required for the staking mechanism.
  /// @param _operator Operator of the token.
  /// @param _from Token sender..
  /// @param _tokenId Token ID.
  /// @param _data Transaction data..
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}