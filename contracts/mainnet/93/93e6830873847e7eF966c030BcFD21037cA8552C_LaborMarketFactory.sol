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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { NBadgeAuthInterface } from '../interfaces/auth/NBadgeAuthInterface.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract NBadgeAuth is NBadgeAuthInterface, Initializable {
    /// @dev The address of the Labor Market deployer.
    address public deployer;

    /// @dev The list of nodes that are allowed to call this contract.
    mapping(bytes4 => Node) internal sigToNode;

    /// @notice Ensure that the caller has permission to use this function.
    modifier requiresAuth() virtual {
        /// @dev Confirm the user has permission to run this function.
        require(isAuthorized(msg.sender, msg.sig), 'NBadgeAuth::requiresAuth: Not authorized');

        _;
    }

    /**
     * @notice Initialize the contract with the deployer and the N-Badge module.
     * @param _deployer The address of the deployer.
     * @param _sigs The list of function signatures N-Badge is applied to.
     * @param _nodes The list of nodes that are allowed to call this contract.
     */
    function __NBadgeAuth_init(
        address _deployer,
        bytes4[] calldata _sigs,
        Node[] calldata _nodes
    ) internal onlyInitializing {
        /// @notice Set the local deployer of the Labor Market.
        deployer = _deployer;

        /// @notice Announce the change in access configuration.
        emit OwnershipTransferred(address(0), _deployer);

        /// @dev Initialize the contract.
        __NBadgeAuth_init_unchained(_sigs, _nodes);
    }

    /**
     * @notice Initialize the contract with the deployer and the N-Badge module.
     * @param _nodes The list of nodes that are allowed to call this contract.
     */
    function __NBadgeAuth_init_unchained(bytes4[] calldata _sigs, Node[] calldata _nodes) internal onlyInitializing {
        /// @notice Ensure that the arrays provided are of equal lengths.
        require(_sigs.length == _nodes.length, 'NBadgeAuth::__NBadgeAuth_init_unchained: Invalid input');

        /// @dev Load the loop stack.
        uint256 i;

        /// @notice Loop through all of the signatures provided and load in the access management.
        for (i; i < _sigs.length; i++) {
            /// @dev Initialize all the nodes related to each signature.
            sigToNode[_sigs[i]] = _nodes[i];
        }
    }

    /**
     * @dev Determines if a user has the required credentials to call a function.
     * @param _node The node to check.
     * @param _user The user to check.
     * @return True if the user has the required credentials, false otherwise.
     */
    function _canCall(
        Node memory _node,
        address _user,
        address
    ) internal view returns (bool) {
        /// @dev Load in the first badge to warm the slot.
        Badge memory badge = _node.badges[0];

        /// @dev Load in the stack.
        uint256 points;
        uint256 i;

        /// @dev Determine if the user has met the proper conditions of access.
        for (i; i < _node.badges.length; i++) {
            /// @dev Step through the nodes until we have enough points or we run out.
            badge = _node.badges[i];

            /// @notice Determine the balance of the Badge the user.
            uint256 balance = badge.badge.balanceOf(_user, badge.id);

            /// @notice If the user has sufficient balance, account for the balance in points.
            if (badge.min <= balance && badge.max >= balance) points += badge.points;

            /// @notice If enough points have been accumulated, terminate the loop.
            if (points >= _node.required) i = _node.badges.length;

            /// @notice Keep on swimming.
        }

        /// @notice Return if the user has met the required points.
        return points >= _node.required;
    }

    /**
     * See {NBadgeAuthInterface-isAuthorized}.
     */
    function isAuthorized(address user, bytes4 _sig) public view virtual returns (bool) {
        /// @notice Load in the established for this function.
        Node memory node = sigToNode[_sig];

        /// @notice If no configuration was set, the access of the function is open to the public.
        bool global = node.badges.length == 0;

        /// @notice Determine and return if a user has permission to call the function.
        return (global || _canCall(node, user, address(this))) || (user == deployer && node.deployerAllowed);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helper interfaces.
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface NBadgeAuthInterface {
    /// @notice The schema of node in the authority graph.
    struct Badge {
        IERC1155 badge;
        uint256 id;
        uint256 min;
        uint256 max;
        uint256 points;
    }

    /// @notice Access definition for a signature.
    struct Node {
        bool deployerAllowed;
        uint256 required;
        Badge[] badges;
    }

    /// @notice Announces when the contract gets a new owner.
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// @notice Announces the permission definition of the contract.
    event NodesUpdated(bytes4[] sigs, Node[] nodes);

    /**
     * @notice Determine if a user has the required credentials to call a function.
     * @param user The user to check.
     * @param sig The signature of the function to check.
     * @return authorized as `true` if the user has the required credentials, `false` otherwise.
     */
    function isAuthorized(address user, bytes4 sig) external view returns (bool authorized);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface EnforcementCriteriaInterface {
    /// @notice Announces the definition of the criteria configuration.
    event EnforcementConfigured(address indexed _market, uint256[] _auxiliaries, uint256[] _alphas, uint256[] _betas);

    /// @notice Announces change in Submission reviews.
    event SubmissionReviewed(
        address indexed _market,
        uint256 indexed _requestId,
        uint256 indexed _submissionId,
        uint256 intentChange,
        uint256 earnings,
        uint256 remainder,
        bool newSubmission
    );

    /**
     * @notice Set the configuration for a Labor Market using the generalized parameters.
     * @param _auxiliaries The auxiliary parameters for the Labor Market.
     * @param _alphas The alpha parameters for the Labor Market.
     * @param _betas The beta parameters for the Labor Market.
     */
    function setConfiguration(
        uint256[] calldata _auxiliaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas
    ) external;

    /**
     * @notice Submit a new score for a submission.
     * @param _requestId The ID of the request.
     * @param _submissionId The ID of the submission.
     * @param _score The score of the submission.
     * @param _availableShare The amount of the $pToken available for this submission.
     * @param _enforcer The individual submitting the score.
     */
    function enforce(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        uint256 _availableShare,
        address _enforcer
    ) external returns (bool, uint24);

    /**
     * @notice Retrieve and distribute the rewards for a submission.
     * @param _requestId The ID of the request.
     * @param _submissionId The ID of the submission.
     * @return amount The amount of $pToken to be distributed.
     * @return requiresSubmission Whether or not the submission requires a new score.
     */
    function rewards(uint256 _requestId, uint256 _submissionId)
        external
        returns (uint256 amount, bool requiresSubmission);

    /**
     * @notice Retrieve the amount of $pToken owed back to the Requester.
     * @param _requestId The ID of the request.
     * @return amount The amount of $pToken owed back to the Requester.
     */
    function remainder(uint256 _requestId) external returns (uint256 amount);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helpers interfaces.
import { EnforcementCriteriaInterface } from './enforcement/EnforcementCriteriaInterface.sol';
import { NBadgeAuthInterface } from './auth/NBadgeAuthInterface.sol';

interface LaborMarketFactoryInterface {
    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(address indexed marketAddress, address indexed deployer, address indexed implementation);

    /**
     * @notice Allows an individual to deploy a new Labor Market.
     * @param _deployer The address of the individual intended to own the Labor Market.
     * @param _uri The internet-accessible uri of the Labor Market.
     * @param _criteria The address of enforcement criteria contract.
     * @param _auxilaries The array of uints configuring the application of enforcement.
     * @param _alphas The array of uints configuring the application of enforcement.
     * @param _betas The array of uints configuring the application of enforcement.
     * @param _sigs The array of bytes4 configuring the functions with applied permissions.
     * @param _nodes The array of nodes configuring permission definition.
     * @return laborMarketAddress The address of the newly created Labor Market.
     */
    function createLaborMarket(
        address _deployer,
        string calldata _uri,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        NBadgeAuthInterface.Node[] calldata _nodes
    ) external returns (address laborMarketAddress);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helper interfaces.
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { EnforcementCriteriaInterface } from './enforcement/EnforcementCriteriaInterface.sol';
import { NBadgeAuthInterface } from './auth/NBadgeAuthInterface.sol';

interface LaborMarketInterface {
    /// @notice Schema definition of a Request.
    struct ServiceRequest {
        uint48 signalExp;
        uint48 submissionExp;
        uint48 enforcementExp;
        uint64 providerLimit;
        uint64 reviewerLimit;
        uint256 pTokenProviderTotal;
        uint256 pTokenReviewerTotal;
        IERC20 pTokenProvider;
        IERC20 pTokenReviewer;
    }

    /// @notice Schema definition of the state a Request may be in.
    /// @dev Used to track signal:attendance rates.
    struct ServiceSignalState {
        uint64 providers;
        uint64 reviewers;
        uint64 providersArrived;
        uint64 reviewersArrived;
    }

    /// @notice Emitted when labor market parameters are updated.
    event LaborMarketConfigured(address deployer, string uri, address criteria);

    /// @notice Announces when a new Request has been configured inside a Labor Market.
    event RequestConfigured(
        address indexed requester,
        uint256 indexed requestId,
        uint48 signalExp,
        uint48 submissionExp,
        uint48 enforcementExp,
        uint64 providerLimit,
        uint64 reviewerLimit,
        uint256 pTokenProviderTotal,
        uint256 pTokenReviewerTotal,
        IERC20 pTokenProvider,
        IERC20 pTokenReviewer,
        string uri
    );

    /// @notice Announces when a Request has been signaled by a Provider.
    event RequestSignal(address indexed signaler, uint256 indexed requestId);

    /// @notice Announces when a Reviewer signals interest in reviewing a Request.
    event ReviewSignal(address indexed signaler, uint256 indexed requestId, uint256 indexed quantity);

    /// @notice Announces when a Request has been fulfilled by a Provider.
    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        string uri
    );

    /// @notice Announces when a Submission for a Request has been reviewed.
    event RequestReviewed(
        address indexed reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 reviewId,
        uint256 reviewScore,
        string uri
    );

    /// @notice Announces when a Provider has claimed earnings for a Submission.
    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 payAmount,
        address to
    );

    /// @notice Announces the status of the remaining balance of a Request.
    event RemainderClaimed(address claimer, uint256 indexed requestId, address indexed to, bool indexed settled);

    /// @notice Announces when a Request has been withdrawn (cancelled) by the Requester.
    event RequestWithdrawn(uint256 indexed requestId);

    /**
     * @notice Initializes the newly deployed Labor Market contract.
     * @dev An initializer can only be called once and will throw if called twice in place of the constructor.
     * @param _deployer The address of the deployer.
     * @param _uri The internet-accessible uri of the Labor Market.
     * @param _criteria The enforcement criteria module used for this Labor Market.
     * @param _auxilaries The auxiliary values for the ennforcement criteria that is being used.
     * @param _alphas The alpha values for the enforcement criteria that is being used.
     * @param _betas The beta values for the enforcement criteria that is being used.
     * @param _sigs The signatures of the functions with permission gating.
     * @param _nodes The node definitions that are allowed to perform the functions with permission gating.
     */
    function initialize(
        address _deployer,
        string calldata _uri,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        NBadgeAuthInterface.Node[] calldata _nodes
    ) external;

    /**
     * @notice Submit a new Request to a Marketplace.
     * @param _request The Request being submit for work in the Labor Market.
     * @param _uri The internet-accessible URI of the Request.
     * @return requestId The id of the Request established onchain.
     */
    function submitRequest(
        uint8 _blockNonce,
        ServiceRequest calldata _request,
        string calldata _uri
    ) external returns (uint256 requestId);

    /**
     * @notice Signals interest in fulfilling a service Request.
     * @param _requestId The id of the Request the caller is signaling intent for.
     */
    function signal(uint256 _requestId) external;

    /**
     * @notice Signals interest in reviewing a Submission.
     * @param _requestId The id of the Request a Reviewer would like to assist in maintaining.
     * @param _quantity The amount of Submissions a Reviewer has intent to manage.
     */
    function signalReview(uint256 _requestId, uint24 _quantity) external;

    /**
     * @notice Allows a Provider to fulfill a Request.
     * @param _requestId The id of the Request being fulfilled.
     * @param _uri The internet-accessible uri of the Submission data.
     * @return submissionId The id of the Submission for the respective Request.
     */
    function provide(uint256 _requestId, string calldata _uri) external returns (uint256 submissionId);

    /**
     * @notice Allows a maintainer to participate in grading a Submission.
     * @param _requestId The id of the Request being fulfilled.
     * @param _submissionId The id of the Submission.
     * @param _score The score of the Submission.
     */
    function review(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        string calldata _uri
    ) external;

    /**
     * @notice Allows a Provider to claim earnings for a Request Submission after enforcement.
     * @dev When you want to determine what the earned amount is, you can use this
     *      function with a static call to determine the qausi-state of claiming.
     * @param _requestId The id of the Request being fulfilled.
     * @param _submissionId The id of the Submission.
     * @return success Whether or not the claim was successful.
     * @return amount The amount of tokens earned by the Submission.
     */
    function claim(uint256 _requestId, uint256 _submissionId) external returns (bool success, uint256 amount);

    /**
     * @notice Allows a Requester to claim the remainder of funds not allocated to participants.
     * @dev This model has been implemented to allow for bulk distribution of unclaimed rewards to
     *      assist in keeping the economy as healthy as possible.
     * @param _requestId The id of the Request.
     */
    function claimRemainder(uint256 _requestId)
        external
        returns (
            bool pTokenProviderSuccess,
            bool pTokenReviewerSuccess,
            uint256 pTokenProviderSurplus,
            uint256 pTokenReviewerSurplus
        );

    /**
     * @notice Allows a Requester to withdraw a Request and refund the pToken.
     * @param _requestId The id of the Request being withdrawn.
     */
    function withdrawRequest(uint256 _requestId) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from './interfaces/LaborMarketInterface.sol';
import { NBadgeAuth } from './auth/NBadgeAuth.sol';

/// @dev Helper interfaces
import { EnforcementCriteriaInterface } from './interfaces/enforcement/EnforcementCriteriaInterface.sol';

/// @dev Helper libraries.
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract LaborMarket is LaborMarketInterface, NBadgeAuth {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The enforcement criteria module used for this Labor Market.
    EnforcementCriteriaInterface internal criteria;

    /// @dev Primary struct containing the definition of a Request.
    mapping(uint256 => ServiceRequest) public requestIdToRequest;

    /// @dev State id for a user relative to a single Request.
    mapping(uint256 => mapping(address => uint24)) public requestIdToAddressToPerformance;

    /// @dev Tracking the amount of Provider and Reviewer interested that has been signaled.
    mapping(uint256 => ServiceSignalState) public requestIdToSignalState;

    /// @dev Definition of active Provider submissions for a request.
    mapping(uint256 => EnumerableSet.AddressSet) internal requestIdToProviders;

    /// @dev Prevent implementation from being initialized.
    constructor() {
        _disableInitializers();
    }

    /**
     * See {LaborMarketInterface-initialize}.
     */
    function initialize(
        address _deployer,
        string calldata _uri,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        Node[] calldata _nodes
    ) external override initializer {
        /// @dev Initialize the access controls of N-Badge.
        __NBadgeAuth_init(_deployer, _sigs, _nodes);

        /// @dev Configure the Labor Market enforcement criteria module.
        criteria = _criteria;

        /// @notice Set the auxiliary value for the criteria that is being used.
        /// @dev This is stored as a relative `uint256` however you may choose to bitpack
        ///      this value with a segment of smaller bits which is only measurable by
        ///      enabled enforcement criteria.
        /// @dev Cross-integration of newly connected modules CANNOT be audited therefore,
        ///      all onus and liability of the integration is on the individual market
        ///      instantiator and the module developer. Risk is mitigated by the fact that
        ///      the module developer is required to deploy the module and the market
        ///      instantiator is required to deploy the market.
        criteria.setConfiguration(_auxilaries, _alphas, _betas);

        /// @dev Announce the configuration of the Labor Market.
        emit LaborMarketConfigured(_deployer, _uri, address(criteria));
    }

    /**
     * See {LaborMarketInterface-submitRequest}.
     */
    function submitRequest(
        uint8 _blockNonce,
        ServiceRequest calldata _request,
        string calldata _uri
    ) public virtual requiresAuth returns (uint256 requestId) {
        /// @notice Ensure the timestamps of the Request phases are valid.
        require(
            block.timestamp < _request.signalExp &&
                _request.signalExp < _request.submissionExp &&
                _request.submissionExp < _request.enforcementExp,
            'LaborMarket::submitRequest: Invalid timestamps'
        );

        /// @notice Ensure the Reviewer and Provider limit are not zero.
        require(_request.providerLimit > 0 && _request.reviewerLimit > 0, 'LaborMarket::submitRequest: Invalid limits');

        /// @notice Generate the uuid for the Request using the nonce, timestamp and address.
        requestId = uint256(bytes32(abi.encodePacked(_blockNonce, uint88(block.timestamp), uint160(msg.sender))));

        /// @notice Ensure the Request does not already exist.
        require(requestIdToRequest[requestId].signalExp == 0, 'LaborMarket::submitRequest: Request already exists');

        /// @notice Store the Request in the Labor Market.
        requestIdToRequest[requestId] = _request;

        /// @notice Announce the creation of a new Request in the Labor Market.
        emit RequestConfigured(
            msg.sender,
            requestId,
            _request.signalExp,
            _request.submissionExp,
            _request.enforcementExp,
            _request.providerLimit,
            _request.reviewerLimit,
            _request.pTokenProviderTotal,
            _request.pTokenReviewerTotal,
            _request.pTokenProvider,
            _request.pTokenReviewer,
            _uri
        );

        /// @notice Determine the active balances of the tokens held.
        /// @notice Get the balance of tokens denoted for providers.
        uint256 providerBalance = _request.pTokenProvider.balanceOf(msg.sender);

        /// @notice Provide the funding for the Request.
        if (_request.pTokenProviderTotal > 0) {
            /// @dev Transfer the Provider tokens that support the compensation of the Request.
            _request.pTokenProvider.transferFrom(msg.sender, address(this), _request.pTokenProviderTotal);

            /// @notice Ensure the Provider balance is correct.
            require(
                _request.pTokenProvider.balanceOf(msg.sender) == providerBalance - _request.pTokenProviderTotal,
                'LaborMarket::submitRequest: Invalid Provider balance.'
            );
        }

        /// @notice Retrieve the balance of Reviewer tokens.
        /// @dev Is calculated down here as Provider and Reviewer token may be the same.
        uint256 reviewerBalance = _request.pTokenReviewer.balanceOf(msg.sender);

        /// @notice Provide the funding for the Request to incentivize Reviewers.
        if (_request.pTokenReviewerTotal > 0) {
            /// @dev Transfer the Reviewer tokens that support the compensation of the Request.
            _request.pTokenReviewer.transferFrom(msg.sender, address(this), _request.pTokenReviewerTotal);

            /// @notice Ensure the Reviewer balance is correct.
            require(
                _request.pTokenReviewer.balanceOf(msg.sender) == reviewerBalance - _request.pTokenReviewerTotal,
                'LaborMarket::submitRequest: Invalid Provider balance.'
            );
        }
    }

    /**
     * See {LaborMarketInterface-signal}.
     */
    function signal(uint256 _requestId) public virtual requiresAuth {
        /// @dev Pull the Request out of the storage slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the signal phase is still active.
        require(
            block.timestamp <= requestIdToRequest[_requestId].signalExp,
            'LaborMarket::signal: Signal deadline passed'
        );

        /// @dev Retrieve the state of the Providers for this Request.
        ServiceSignalState storage signalState = requestIdToSignalState[_requestId];

        /// @dev Confirm the maximum number of Providers is never exceeded.
        require(signalState.providers + 1 <= request.providerLimit, 'LaborMarket::signal: Exceeds signal limit');

        /// @notice Increment the number of Providers that have signaled.
        ++signalState.providers;

        /// @notice Get the performance state of the user.
        uint24 performance = requestIdToAddressToPerformance[_requestId][msg.sender];

        /// @notice Require the user has not signaled.
        /// @dev Get the first bit of the user's signal value.
        require(performance & 0x3 == 0, 'LaborMarket::signal: Already signaled');

        /// @notice Set the first two bits of the performance state to 1 to indicate the user has signaled
        ///         without affecting the rest of the performance state.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits of the performance state to 1 to indicate the user has signaled.
            0x1;

        /// @notice Announce the signaling of a Provider.
        emit RequestSignal(msg.sender, _requestId);
    }

    /**
     * See {LaborMarketInterface-signalReview}.
     */
    function signalReview(uint256 _requestId, uint24 _quantity) public virtual requiresAuth {
        /// @dev Pull the Request out of the storage slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the enforcement phase is still active.
        require(block.timestamp <= request.enforcementExp, 'LaborMarket::signalReview: Enforcement deadline passed');

        /// @dev Retrieve the state of the Providers for this Request.
        ServiceSignalState storage signalState = requestIdToSignalState[_requestId];

        /// @notice Ensure the signal limit is not exceeded.
        require(
            signalState.reviewers + _quantity <= request.reviewerLimit,
            'LaborMarket::signalReview: Exceeds signal limit'
        );

        /// @notice Increment the number of Reviewers that have signaled.
        signalState.reviewers += _quantity;

        /// @notice Get the performance state of the caller.
        uint24 performance = requestIdToAddressToPerformance[_requestId][msg.sender];

        /// @notice Get the intent of the Reviewer.
        /// @dev Shift the performance value to the right by two bits and then mask down to
        ///      the next 22 bits with an overlap of 0x3fffff.
        uint24 reviewIntent = ((performance >> 2) & 0x3fffff);

        /// @notice Ensure that we are the intent will not overflow the 22 bits saved for the quantity.
        /// @dev Mask the `_quantity` down to 22 bits to prevent overflow and user error.
        require(
            reviewIntent + (_quantity & 0x3fffff) <= 4_194_304,
            'LaborMarket::signalReview: Exceeds maximum signal value'
        );

        /// @notice Update the intent of reviewing by summing already signaled quantity with the new quantity
        ///         and then shift it to the left by two bits to make room for the intent of providing.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Set the last 22 bits of the performance state to the sum of the current intent and the new quantity.
            ((reviewIntent + _quantity) << 2) |
            /// @dev Keep the first two bits of the performance state the same.
            (performance & 0x3);

        /// @notice Announce the signaling of a Reviewer.
        emit ReviewSignal(msg.sender, _requestId, _quantity);
    }

    /**
     * See {LaborMarketInterface-provide}.
     */
    function provide(uint256 _requestId, string calldata _uri) public virtual returns (uint256 submissionId) {
        /// @dev Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Require the submission phase is still active.
        require(block.timestamp <= request.submissionExp, 'LaborMarket::provide: Submission deadline passed');

        /// @notice Get the performance state of the caller.
        uint24 performance = requestIdToAddressToPerformance[_requestId][msg.sender];

        /// @notice Ensure that the Provider has signaled, but has not already submitted.
        /// @dev Get the first two bits of the user's performance value.
        ///      0: Not signaled, 1: Signaled, 2: Submitted.
        require(performance & 0x3 == 1, 'LaborMarket::provide: Not signaled');

        /// @dev Add the Provider to the list of submissions.
        requestIdToProviders[_requestId].add(msg.sender);

        /// @dev Set the submission ID to reflect the Providers address.
        submissionId = uint256(uint160(msg.sender));

        /// @dev Provider has submitted and set the value of the first two bits to 2.
        requestIdToAddressToPerformance[_requestId][msg.sender] =
            /// @dev Keep the last 22 bits but clear the first two bits.
            (performance & 0xFFFFFC) |
            /// @dev Set the first two bits to 2.
            0x2;

        /// @dev Add signal state to the request.
        requestIdToSignalState[_requestId].providersArrived += 1;

        /// @notice Announce the submission of a Provider.
        emit RequestFulfilled(msg.sender, _requestId, submissionId, _uri);
    }

    /**
     * See {LaborMarketInterface-review}.
     */
    function review(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        string calldata _uri
    ) public virtual {
        /// @notice Determine the number-derived id of the caller.
        uint256 reviewId = uint256(uint160(msg.sender));

        /// @notice Ensure that no one is grading their own Submission.
        require(_submissionId != reviewId, 'LaborMarket::review: Cannot review own submission');

        /// @notice Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the Request is still in the enforcement phase.
        require(block.timestamp <= request.enforcementExp, 'LaborMarket::review: Enforcement deadline passed');

        /// @notice Make the external call into the enforcement module to submit the callers score.
        (bool newSubmission, uint24 intentChange) = criteria.enforce(
            _requestId,
            _submissionId,
            _score,
            request.pTokenProviderTotal / request.providerLimit,
            msg.sender
        );

        /// @notice If the user is submitting a "new score" according to the module, then deduct their signal.
        /// @dev This implicitly enables the ability to have an enforcement criteria that supports
        ///       many different types of scoring rubrics, but also "submitting a score multiple times."
        ///       In the case that only one response from each reviewer is wanted, then the enforcement
        ///       criteria should return `true` to indicate signal deduction is owed at all times.
        if (newSubmission) {
            /// @notice Calculate the active intent value of the Reviewer.
            uint24 intent = requestIdToAddressToPerformance[_requestId][msg.sender];

            /// @notice Get the remaining signal value of the Reviewer.
            /// @dev Uses the last 22 bits of the performance value by shifting over 2 values and then
            ///      masking down to the last 22 bits with an overlap of 0x3fffff.
            uint24 remainingIntent = (requestIdToAddressToPerformance[_requestId][msg.sender] >> 2) & 0x3fffff;

            /// @notice Ensure the Reviewer is not exceeding their signaled intent.
            require(remainingIntent > 0, 'LaborMarket::review: Not signaled');

            /// @notice Lower the bitpacked value representing the remaining signal value of
            ///         the caller for this Request.
            /// @dev This bitwise shifts shifts 22 bits to the left to clear the previous value
            ///      and then bitwise ORs the remaining signal value minus 1 to the left by 2 bits.
            requestIdToAddressToPerformance[_requestId][msg.sender] =
                /// @dev Keep all the bits besides the 22 bits that represent the remaining signal value.
                (intent & 0x3) |
                /// @dev Shift the remaining signal value minus 1 to the left by 2 bits to fill the 22.
                ((remainingIntent - intentChange) << 2);

            /// @dev Decrement the total amount of enforcement capacity needed to finalize this Request.
            requestIdToSignalState[_requestId].reviewersArrived += intentChange;

            /// @notice Determine if the Request incentivized Reviewers to participate.
            if (request.pTokenReviewerTotal > 0)
                /// @notice Transfer the tokens from the Market to the Reviewer.
                request.pTokenReviewer.transfer(msg.sender, request.pTokenReviewerTotal / request.reviewerLimit);

            /// @notice Announce the new submission of a score by a maintainer.
            emit RequestReviewed(msg.sender, _requestId, _submissionId, reviewId, _score, _uri);
        }
    }

    /**
     * See {LaborMarketInterface-claim}.
     */
    function claim(uint256 _requestId, uint256 _submissionId) external returns (bool success, uint256) {
        /// @notice Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @notice Ensure the Request is no longer in the enforcement phase.
        require(block.timestamp >= request.enforcementExp, 'LaborMarket::claim: Enforcement deadline not passed');

        /// @notice Get the rewards attributed to this Submission.
        (uint256 amount, bool requiresSubmission) = criteria.rewards(_requestId, _submissionId);

        /// @notice Ensure the Submission has funds to claim.
        if (amount != 0) {
            /// @notice Recover the address by truncating the Submission id.
            address provider = address(uint160(_submissionId));

            /// @notice Remove the Submission from the list of Submissions.
            /// @dev This is done before the transfer to prevent reentrancy attacks.
            bool removed = requestIdToProviders[_requestId].remove(provider);

            /// @dev Allow the enforcement criteria to perform any additional logic.
            require(!requiresSubmission || removed, 'LaborMarket::claim: Invalid submission claim');

            /// @notice Transfer the pTokens to the network participant.
            /// @dev Update health status for bulk processing offchain.
            success = request.pTokenProvider.transfer(provider, amount);

            /// @notice Announce the claiming of a service provider reward.
            emit RequestPayClaimed(msg.sender, _requestId, _submissionId, amount, provider);
        }

        /// @notice If there were no funds to claim, acknowledge the failure of the transfer
        ///         and return false without blocking the transaction.

        /// @notice Return the amount of pTokens claimed.
        return (success, amount);
    }

    /**
     * See {LaborMarketInterface-claimRemainder}.
     */
    function claimRemainder(uint256 _requestId)
        public
        virtual
        returns (
            bool pTokenProviderSuccess,
            bool pTokenReviewerSuccess,
            uint256 pTokenProviderSurplus,
            uint256 pTokenReviewerSurplus
        )
    {
        /// @dev Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @dev Ensure the Request is no longer in the enforcement phase.
        require(
            block.timestamp >= request.enforcementExp,
            'LaborMarket::claimRemainder: Enforcement deadline not passed'
        );

        /// @notice Get the signal state of the Request.
        ServiceSignalState storage signalState = requestIdToSignalState[_requestId];

        /// @notice Determine the amount of available Provider payments never redeemed.
        pTokenProviderSurplus =
            (request.providerLimit - signalState.providersArrived) *
            (request.pTokenProviderTotal / request.providerLimit);

        /// @notice Determine the amount of available Reviewer payments never redeemed.
        pTokenReviewerSurplus =
            (request.reviewerLimit - signalState.reviewersArrived) *
            (request.pTokenReviewerTotal / request.reviewerLimit);

        /// @notice Determine the amount of undistributed money remaining in the Request.
        /// @dev This accounts for funds that were attempted to be earned, but failed to be by
        ///      not meeting the enforcement standards of the criteria module enabled.
        pTokenProviderSurplus += criteria.remainder(_requestId);

        /// @dev Pull the address of the Requester out of storage.
        address requester = address(uint160(_requestId));

        /// @notice Redistribute the Provider allocated funds that were not earned.
        if (pTokenProviderSurplus != 0) {
            /// @notice Transfer the remainder of the deposit funds back to the requester.
            request.pTokenProvider.transfer(requester, pTokenProviderSurplus);

            /// @dev Bubble up the success to the return.
            pTokenProviderSuccess = true;
        }

        /// @notice Redistribute the Reviewer allocated funds that were not earned.
        if (pTokenReviewerSurplus != 0) {
            /// @notice Transfer the remainder of the deposit funds back to the Requester.
            request.pTokenReviewer.transfer(requester, pTokenReviewerSurplus);

            /// @notice Bubble up the success to the return.
            pTokenReviewerSuccess = true;
        }

        /// @notice Announce a simple event to allow for offchain processing.
        if (pTokenProviderSuccess || pTokenReviewerSuccess) {
            /// @dev Determine if there will be a remainder after the claim.
            bool settled = pTokenProviderSurplus == 0 && pTokenReviewerSurplus == 0;

            /// @notice Announce the claiming of a service requester reward.
            emit RemainderClaimed(msg.sender, _requestId, requester, settled);
        }

        /// @notice If there were no funds to reclaim, acknowledge the failure of the claim
        ///         and return false without blocking the transaction.
    }

    /**
     * See {LaborMarketInterface-withdrawRequest}.
     */
    function withdrawRequest(uint256 _requestId) public virtual {
        /// @dev Get the Request out of storage to warm the slot.
        ServiceRequest storage request = requestIdToRequest[_requestId];

        /// @dev Ensure that only the Requester may withdraw the Request.
        require(address(uint160(_requestId)) == msg.sender, 'LaborMarket::withdrawRequest: Not requester');

        /// @dev Require that the Request does not have any signal state.
        require(
            (requestIdToSignalState[_requestId].providers |
                requestIdToSignalState[_requestId].reviewers |
                requestIdToSignalState[_requestId].providersArrived |
                requestIdToSignalState[_requestId].reviewersArrived) == 0,
            'LaborMarket::withdrawRequest: Already active'
        );

        /// @dev Initialize the refund amounts before clearing storage.
        uint256 pTokenProviderRemainder = request.pTokenProviderTotal;
        uint256 pTokenReviewerRemainder = request.pTokenReviewerTotal;

        /// @notice Delete the Request and prevent further action.
        delete request.signalExp;
        delete request.submissionExp;
        delete request.enforcementExp;
        delete request.providerLimit;
        delete request.reviewerLimit;
        delete request.pTokenProviderTotal;
        delete request.pTokenReviewerTotal;

        /// @notice Return the Provider payment token back to the Requester.
        if (pTokenProviderRemainder > 0) request.pTokenProvider.transfer(msg.sender, pTokenProviderRemainder);

        /// @notice Return the Reviewer payment token back to the Requester.
        if (pTokenReviewerRemainder > 0) request.pTokenReviewer.transfer(msg.sender, pTokenReviewerRemainder);

        /// @dev Delete the pToken interface references.
        delete request.pTokenProvider;
        delete request.pTokenReviewer;

        /// @dev Announce the withdrawal of a Request.
        emit RequestWithdrawn(_requestId);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarket } from './LaborMarket.sol';
import { LaborMarketFactoryInterface } from './interfaces/LaborMarketFactoryInterface.sol';

/// @dev Helper libraries.
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';

/// @dev Helpers interfaces.
import { EnforcementCriteriaInterface } from './interfaces/enforcement/EnforcementCriteriaInterface.sol';
import { NBadgeAuthInterface } from './interfaces/auth/NBadgeAuthInterface.sol';

/**
 * @title LaborMarketFactory
 * @dev Version: v2.0.0+unaudited (All usage is at your own risk!)
 * @author @flipsidecrypto // @metricsdao
 * @author @sftchance // @masonchain // @drakedanner // @jimmyerstech
 * @notice This factory contract instantiates new local versions of a Labor Market based on the configuration provided. The factory contract is
 *         intended to be deployed once and then used to deploy many Labor Markets to enable cross-market liquidity products.
 */
contract LaborMarketFactory is LaborMarketFactoryInterface {
    using Clones for address;

    /// @notice The address of the source contract for the paternal Labor Market.
    address public immutable implementation;

    /// @notice Instantiate the Labor Market Factory with an immutable implementation address.
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * See {LaborMarketFactoryInterface-createLaborMarket}.
     */
    function createLaborMarket(
        address _deployer,
        string calldata _uri,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        NBadgeAuthInterface.Node[] calldata _nodes
    ) public virtual returns (address laborMarketAddress) {
        /// @notice Get the address of the target.
        address marketAddress = implementation.clone();

        /// @notice Interface with the newly created contract to initialize it.
        LaborMarket laborMarket = LaborMarket(marketAddress);

        /// @notice Deploy the clone contract to serve as the Labor Market.
        laborMarket.initialize(_deployer, _uri, _criteria, _auxilaries, _alphas, _betas, _sigs, _nodes);

        /// @notice Announce the creation of the Labor Market.
        emit LaborMarketCreated(marketAddress, _deployer, implementation);

        /// @notice Return the address of the newly created Labor Market.
        return marketAddress;
    }
}