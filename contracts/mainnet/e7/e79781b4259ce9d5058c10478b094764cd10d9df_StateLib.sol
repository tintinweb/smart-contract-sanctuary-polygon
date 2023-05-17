// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

uint256 constant MAX_SMT_DEPTH = 64;

interface IState {
    /**
     * @dev Struct for public interfaces to represent a state information.
     * @param id An identity.
     * @param state A state.
     * @param replacedByState A state, which replaced this state for the identity.
     * @param createdAtTimestamp A time when the state was created.
     * @param replacedAtTimestamp A time when the state was replaced by the next identity state.
     * @param createdAtBlock A block number when the state was created.
     * @param replacedAtBlock A block number when the state was replaced by the next identity state.
     */
    struct StateInfo {
        uint256 id;
        uint256 state;
        uint256 replacedByState;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST root information.
     * @param root This GIST root.
     * @param replacedByRoot A root, which replaced this root.
     * @param createdAtTimestamp A time, when the root was saved to blockchain.
     * @param replacedAtTimestamp A time, when the root was replaced by the next root in blockchain.
     * @param createdAtBlock A number of block, when the root was saved to blockchain.
     * @param replacedAtBlock A number of block, when the root was replaced by the next root in blockchain.
     */
    struct GistRootInfo {
        uint256 root;
        uint256 replacedByRoot;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST proof information.
     * @param root This GIST root.
     * @param existence A flag, which shows if the leaf index exists in the GIST.
     * @param siblings An array of GIST sibling node hashes.
     * @param index An index of the leaf in the GIST.
     * @param value A value of the leaf in the GIST.
     * @param auxExistence A flag, which shows if the auxiliary leaf exists in the GIST.
     * @param auxIndex An index of the auxiliary leaf in the GIST.
     * @param auxValue An value of the auxiliary leaf in the GIST.
     */
    struct GistProof {
        uint256 root;
        bool existence;
        uint256[MAX_SMT_DEPTH] siblings;
        uint256 index;
        uint256 value;
        bool auxExistence;
        uint256 auxIndex;
        uint256 auxValue;
    }

    /**
     * @dev Retrieve last state information of specific id.
     * @param id An identity.
     * @return The state info.
     */
    function getStateInfoById(uint256 id) external view returns (StateInfo memory);

    /**
     * @dev Retrieve state information by id and state.
     * @param id An identity.
     * @param state A state.
     * @return The state info.
     */
    function getStateInfoByIdAndState(
        uint256 id,
        uint256 state
    ) external view returns (StateInfo memory);

    /**
     * @dev Retrieve the specific GIST root information.
     * @param root GIST root.
     * @return The GIST root info.
     */
    function getGISTRootInfo(uint256 root) external view returns (GistRootInfo memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IStateTransitionVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view returns (bool r);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../state/StateV2.sol";
import "./SmtLib.sol";

/// @title A common functions for arrays.
library ArrayUtils {
    /**
     * @dev Calculates bounds for the slice of the array.
     * @param arrLength An array length.
     * @param start A start index.
     * @param length A length of the slice.
     * @param limit A limit for the length.
     * @return The bounds for the slice of the array.
     */
    function calculateBounds(
        uint256 arrLength,
        uint256 start,
        uint256 length,
        uint256 limit
    ) internal pure returns (uint256, uint256) {
        require(length > 0, "Length should be greater than 0");
        require(length <= limit, "Length limit exceeded");
        require(start < arrLength, "Start index out of bounds");

        uint256 end = start + length;
        if (end > arrLength) {
            end = arrLength;
        }

        return (start, end);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

library PoseidonUnit1L {
    function poseidon(uint256[1] calldata) public pure returns (uint256) {}
}

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata) public pure returns (uint256) {}
}

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

library PoseidonUnit4L {
    function poseidon(uint256[4] calldata) public pure returns (uint256) {}
}

library PoseidonUnit5L {
    function poseidon(uint256[5] calldata) public pure returns (uint256) {}
}

library PoseidonUnit6L {
    function poseidon(uint256[6] calldata) public pure returns (uint256) {}
}

library SpongePoseidon {
    uint32 constant BATCH_SIZE = 6;

    function hash(uint256[] calldata values) public pure returns (uint256) {
        uint256[BATCH_SIZE] memory frame = [uint256(0), 0, 0, 0, 0, 0];
        bool dirty = false;
        uint256 fullHash = 0;
        uint32 k = 0;
        for (uint32 i = 0; i < values.length; i++) {
            dirty = true;
            frame[k] = values[i];
            if (k == BATCH_SIZE - 1) {
                fullHash = PoseidonUnit6L.poseidon(frame);
                dirty = false;
                frame = [uint256(0), 0, 0, 0, 0, 0];
                frame[0] = fullHash;
                k = 1;
            } else {
                k++;
            }
        }
        if (dirty) {
            // we haven't hashed something in the main sponge loop and need to do hash here
            fullHash = PoseidonUnit6L.poseidon(frame);
        }
        return fullHash;
    }
}

library PoseidonFacade {
    function poseidon1(uint256[1] calldata el) public pure returns (uint256) {
        return PoseidonUnit1L.poseidon(el);
    }

    function poseidon2(uint256[2] calldata el) public pure returns (uint256) {
        return PoseidonUnit2L.poseidon(el);
    }

    function poseidon3(uint256[3] calldata el) public pure returns (uint256) {
        return PoseidonUnit3L.poseidon(el);
    }

    function poseidon4(uint256[4] calldata el) public pure returns (uint256) {
        return PoseidonUnit4L.poseidon(el);
    }

    function poseidon5(uint256[5] calldata el) public pure returns (uint256) {
        return PoseidonUnit5L.poseidon(el);
    }

    function poseidon6(uint256[6] calldata el) public pure returns (uint256) {
        return PoseidonUnit6L.poseidon(el);
    }

    function poseidonSponge(uint256[] calldata el) public pure returns (uint256) {
        return SpongePoseidon.hash(el);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./Poseidon.sol";
import "./ArrayUtils.sol";

/// @title A sparse merkle tree implementation, which keeps tree history.
// Note that this SMT implementation can manage duplicated roots in the history,
// which may happen when some leaf change its value and then changes it back to the original value.
// Leaves deletion is not supported, although it should be possible to implement it in the future
// versions of this library, without changing the existing state variables
// In this way all the SMT data may be preserved for the contracts already in production.
library SmtLib {
    /**
     * @dev Max return array length for SMT root history requests
     */
    uint256 public constant ROOT_INFO_LIST_RETURN_LIMIT = 1000;

    /**
     * @dev Max depth hard cap for SMT
     * We can't use depth > 256 because of bits number limitation in the uint256 data type.
     */
    uint256 public constant MAX_DEPTH_HARD_CAP = 256;

    /**
     * @dev Enum of SMT node types
     */
    enum NodeType {
        EMPTY,
        LEAF,
        MIDDLE
    }

    /**
     * @dev Sparse Merkle Tree data
     * Note that we count the SMT depth starting from 0, which is the root level.
     *
     * For example, the following tree has a maxDepth = 2:
     *
     *     O      <- root level (depth = 0)
     *    / \
     *   O   O    <- depth = 1
     *  / \ / \
     * O  O O  O  <- depth = 2
     */
    struct Data {
        mapping(uint256 => Node) nodes;
        RootEntry[] rootEntries;
        mapping(uint256 => uint256[]) rootIndexes; // root => rootEntryIndex[]
        uint256 maxDepth;
        bool initialized;
        // This empty reserved space is put in place to allow future versions
        // of the SMT library to add new Data struct fields without shifting down
        // storage of upgradable contracts that use this struct as a state variable
        // (see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps)
        uint256[45] __gap;
    }

    /**
     * @dev Struct of the node proof in the SMT.
     * @param root This SMT root.
     * @param existence A flag, which shows if the leaf index exists in the SMT.
     * @param siblings An array of SMT sibling node hashes.
     * @param index An index of the leaf in the SMT.
     * @param value A value of the leaf in the SMT.
     * @param auxExistence A flag, which shows if the auxiliary leaf exists in the SMT.
     * @param auxIndex An index of the auxiliary leaf in the SMT.
     * @param auxValue An value of the auxiliary leaf in the SMT.
     */
    struct Proof {
        uint256 root;
        bool existence;
        uint256[] siblings;
        uint256 index;
        uint256 value;
        bool auxExistence;
        uint256 auxIndex;
        uint256 auxValue;
    }

    /**
     * @dev Struct for SMT root internal storage representation.
     * @param root SMT root.
     * @param createdAtTimestamp A time, when the root was saved to blockchain.
     * @param createdAtBlock A number of block, when the root was saved to blockchain.
     */
    struct RootEntry {
        uint256 root;
        uint256 createdAtTimestamp;
        uint256 createdAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent SMT root info.
     * @param root This SMT root.
     * @param replacedByRoot A root, which replaced this root.
     * @param createdAtTimestamp A time, when the root was saved to blockchain.
     * @param replacedAtTimestamp A time, when the root was replaced by the next root in blockchain.
     * @param createdAtBlock A number of block, when the root was saved to blockchain.
     * @param replacedAtBlock A number of block, when the root was replaced by the next root in blockchain.
     */
    struct RootEntryInfo {
        uint256 root;
        uint256 replacedByRoot;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct of SMT node.
     * @param NodeType type of node.
     * @param childLeft left child of node.
     * @param childRight right child of node.
     * @param Index index of node.
     * @param Value value of node.
     */
    struct Node {
        NodeType nodeType;
        uint256 childLeft;
        uint256 childRight;
        uint256 index;
        uint256 value;
    }

    using BinarySearchSmtRoots for Data;
    using ArrayUtils for uint256[];

    /**
     * @dev Reverts if root does not exist in SMT roots history.
     * @param root SMT root.
     */
    modifier onlyExistingRoot(Data storage self, uint256 root) {
        require(rootExists(self, root), "Root does not exist");
        _;
    }

    /**
     * @dev Add a leaf to the SMT
     * @param i Index of a leaf
     * @param v Value of a leaf
     */
    function addLeaf(Data storage self, uint256 i, uint256 v) external onlyInitialized(self) {
        Node memory node = Node({
            nodeType: NodeType.LEAF,
            childLeft: 0,
            childRight: 0,
            index: i,
            value: v
        });

        uint256 prevRoot = getRoot(self);
        uint256 newRoot = _addLeaf(self, node, prevRoot, 0);

        _addEntry(self, newRoot, block.timestamp, block.number);
    }

    /**
     * @dev Get SMT root history length
     * @return SMT history length
     */
    function getRootHistoryLength(Data storage self) external view returns (uint256) {
        return self.rootEntries.length;
    }

    /**
     * @dev Get SMT root history
     * @param startIndex start index of history
     * @param length history length
     * @return array of RootEntryInfo structs
     */
    function getRootHistory(
        Data storage self,
        uint256 startIndex,
        uint256 length
    ) external view returns (RootEntryInfo[] memory) {
        (uint256 start, uint256 end) = ArrayUtils.calculateBounds(
            self.rootEntries.length,
            startIndex,
            length,
            ROOT_INFO_LIST_RETURN_LIMIT
        );

        RootEntryInfo[] memory result = new RootEntryInfo[](end - start);

        for (uint256 i = start; i < end; i++) {
            result[i - start] = _getRootInfoByIndex(self, i);
        }
        return result;
    }

    /**
     * @dev Get the SMT node by hash
     * @param nodeHash Hash of a node
     * @return A node struct
     */
    function getNode(Data storage self, uint256 nodeHash) public view returns (Node memory) {
        return self.nodes[nodeHash];
    }

    /**
     * @dev Get the proof if a node with specific index exists or not exists in the SMT.
     * @param index A node index.
     * @return SMT proof struct.
     */
    function getProof(Data storage self, uint256 index) external view returns (Proof memory) {
        return getProofByRoot(self, index, getRoot(self));
    }

    /**
     * @dev Get the proof if a node with specific index exists or not exists in the SMT for some historical tree state.
     * @param index A node index
     * @param historicalRoot Historical SMT roof to get proof for.
     * @return Proof struct.
     */
    function getProofByRoot(
        Data storage self,
        uint256 index,
        uint256 historicalRoot
    ) public view onlyExistingRoot(self, historicalRoot) returns (Proof memory) {
        uint256[] memory siblings = new uint256[](self.maxDepth);
        // Solidity does not guarantee that memory vars are zeroed out
        for (uint256 i = 0; i < self.maxDepth; i++) {
            siblings[i] = 0;
        }

        Proof memory proof = Proof({
            root: historicalRoot,
            existence: false,
            siblings: siblings,
            index: index,
            value: 0,
            auxExistence: false,
            auxIndex: 0,
            auxValue: 0
        });

        uint256 nextNodeHash = historicalRoot;
        Node memory node;

        for (uint256 i = 0; i <= self.maxDepth; i++) {
            node = getNode(self, nextNodeHash);
            if (node.nodeType == NodeType.EMPTY) {
                break;
            } else if (node.nodeType == NodeType.LEAF) {
                if (node.index == proof.index) {
                    proof.existence = true;
                    proof.value = node.value;
                    break;
                } else {
                    proof.auxExistence = true;
                    proof.auxIndex = node.index;
                    proof.auxValue = node.value;
                    proof.value = node.value;
                    break;
                }
            } else if (node.nodeType == NodeType.MIDDLE) {
                if ((proof.index >> i) & 1 == 1) {
                    nextNodeHash = node.childRight;
                    proof.siblings[i] = node.childLeft;
                } else {
                    nextNodeHash = node.childLeft;
                    proof.siblings[i] = node.childRight;
                }
            } else {
                revert("Invalid node type");
            }
        }
        return proof;
    }

    /**
     * @dev Get the proof if a node with specific index exists or not exists in the SMT by some historical timestamp.
     * @param index Node index.
     * @param timestamp The latest timestamp to get proof for.
     * @return Proof struct.
     */
    function getProofByTime(
        Data storage self,
        uint256 index,
        uint256 timestamp
    ) public view returns (Proof memory) {
        RootEntryInfo memory rootInfo = getRootInfoByTime(self, timestamp);
        return getProofByRoot(self, index, rootInfo.root);
    }

    /**
     * @dev Get the proof if a node with specific index exists or not exists in the SMT by some historical block number.
     * @param index Node index.
     * @param blockNumber The latest block number to get proof for.
     * @return Proof struct.
     */
    function getProofByBlock(
        Data storage self,
        uint256 index,
        uint256 blockNumber
    ) external view returns (Proof memory) {
        RootEntryInfo memory rootInfo = getRootInfoByBlock(self, blockNumber);
        return getProofByRoot(self, index, rootInfo.root);
    }

    function getRoot(Data storage self) public view onlyInitialized(self) returns (uint256) {
        return self.rootEntries[self.rootEntries.length - 1].root;
    }

    /**
     * @dev Get root info by some historical timestamp.
     * @param timestamp The latest timestamp to get the root info for.
     * @return Root info struct
     */
    function getRootInfoByTime(
        Data storage self,
        uint256 timestamp
    ) public view returns (RootEntryInfo memory) {
        require(timestamp <= block.timestamp, "No future timestamps allowed");

        return
            _getRootInfoByTimestampOrBlock(
                self,
                timestamp,
                BinarySearchSmtRoots.SearchType.TIMESTAMP
            );
    }

    /**
     * @dev Get root info by some historical block number.
     * @param blockN The latest block number to get the root info for.
     * @return Root info struct
     */
    function getRootInfoByBlock(
        Data storage self,
        uint256 blockN
    ) public view returns (RootEntryInfo memory) {
        require(blockN <= block.number, "No future blocks allowed");

        return _getRootInfoByTimestampOrBlock(self, blockN, BinarySearchSmtRoots.SearchType.BLOCK);
    }

    /**
     * @dev Returns root info by root
     * @param root root
     * @return Root info struct
     */
    function getRootInfo(
        Data storage self,
        uint256 root
    ) public view onlyExistingRoot(self, root) returns (RootEntryInfo memory) {
        uint256[] storage indexes = self.rootIndexes[root];
        uint256 lastIndex = indexes[indexes.length - 1];
        return _getRootInfoByIndex(self, lastIndex);
    }

    /**
     * @dev Retrieve duplicate root quantity by id and state.
     * If the root repeats more that once, the length may be greater than 1.
     * @param root A root.
     * @return Root root entries quantity.
     */
    function getRootInfoListLengthByRoot(
        Data storage self,
        uint256 root
    ) public view returns (uint256) {
        return self.rootIndexes[root].length;
    }

    /**
     * @dev Retrieve root infos list of duplicated root by id and state.
     * If the root repeats more that once, the length list may be greater than 1.
     * @param root A root.
     * @param startIndex The index to start the list.
     * @param length The length of the list.
     * @return Root Root entries quantity.
     */
    function getRootInfoListByRoot(
        Data storage self,
        uint256 root,
        uint256 startIndex,
        uint256 length
    ) public view onlyExistingRoot(self, root) returns (RootEntryInfo[] memory) {
        uint256[] storage indexes = self.rootIndexes[root];
        (uint256 start, uint256 end) = ArrayUtils.calculateBounds(
            indexes.length,
            startIndex,
            length,
            ROOT_INFO_LIST_RETURN_LIMIT
        );

        RootEntryInfo[] memory result = new RootEntryInfo[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = _getRootInfoByIndex(self, indexes[i]);
        }

        return result;
    }

    /**
     * @dev Checks if root exists
     * @param root root
     * return true if root exists
     */
    function rootExists(Data storage self, uint256 root) public view returns (bool) {
        return self.rootIndexes[root].length > 0;
    }

    /**
     * @dev Sets max depth of the SMT
     * @param maxDepth max depth
     */
    function setMaxDepth(Data storage self, uint256 maxDepth) public {
        require(maxDepth > 0, "Max depth must be greater than zero");
        require(maxDepth > self.maxDepth, "Max depth can only be increased");
        require(maxDepth <= MAX_DEPTH_HARD_CAP, "Max depth is greater than hard cap");
        self.maxDepth = maxDepth;
    }

    /**
     * @dev Gets max depth of the SMT
     * return max depth
     */
    function getMaxDepth(Data storage self) external view returns (uint256) {
        return self.maxDepth;
    }

    /**
     * @dev Initialize SMT with max depth and root entry of an empty tree.
     * @param maxDepth Max depth of the SMT.
     */
    function initialize(Data storage self, uint256 maxDepth) external {
        require(!isInitialized(self), "Smt is already initialized");
        setMaxDepth(self, maxDepth);
        _addEntry(self, 0, 0, 0);
        self.initialized = true;
    }

    modifier onlyInitialized(Data storage self) {
        require(isInitialized(self), "Smt is not initialized");
        _;
    }

    function isInitialized(Data storage self) public view returns (bool) {
        return self.initialized;
    }

    function _addLeaf(
        Data storage self,
        Node memory newLeaf,
        uint256 nodeHash,
        uint256 depth
    ) internal returns (uint256) {
        if (depth > self.maxDepth) {
            revert("Max depth reached");
        }

        Node memory node = self.nodes[nodeHash];
        uint256 nextNodeHash;
        uint256 leafHash = 0;

        if (node.nodeType == NodeType.EMPTY) {
            leafHash = _addNode(self, newLeaf);
        } else if (node.nodeType == NodeType.LEAF) {
            leafHash = node.index == newLeaf.index
                ? _addNode(self, newLeaf)
                : _pushLeaf(self, newLeaf, node, depth);
        } else if (node.nodeType == NodeType.MIDDLE) {
            Node memory newNodeMiddle;

            if ((newLeaf.index >> depth) & 1 == 1) {
                nextNodeHash = _addLeaf(self, newLeaf, node.childRight, depth + 1);

                newNodeMiddle = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: node.childLeft,
                    childRight: nextNodeHash,
                    index: 0,
                    value: 0
                });
            } else {
                nextNodeHash = _addLeaf(self, newLeaf, node.childLeft, depth + 1);

                newNodeMiddle = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: nextNodeHash,
                    childRight: node.childRight,
                    index: 0,
                    value: 0
                });
            }

            leafHash = _addNode(self, newNodeMiddle);
        }

        return leafHash;
    }

    function _pushLeaf(
        Data storage self,
        Node memory newLeaf,
        Node memory oldLeaf,
        uint256 depth
    ) internal returns (uint256) {
        // no reason to continue if we are at max possible depth
        // as, anyway, we exceed the depth going down the tree
        if (depth >= self.maxDepth) {
            revert("Max depth reached");
        }

        Node memory newNodeMiddle;
        bool newLeafBitAtDepth = (newLeaf.index >> depth) & 1 == 1;
        bool oldLeafBitAtDepth = (oldLeaf.index >> depth) & 1 == 1;

        // Check if we need to go deeper if diverge at the depth's bit
        if (newLeafBitAtDepth == oldLeafBitAtDepth) {
            uint256 nextNodeHash = _pushLeaf(self, newLeaf, oldLeaf, depth + 1);

            if (newLeafBitAtDepth) {
                // go right
                newNodeMiddle = Node(NodeType.MIDDLE, 0, nextNodeHash, 0, 0);
            } else {
                // go left
                newNodeMiddle = Node(NodeType.MIDDLE, nextNodeHash, 0, 0, 0);
            }
            return _addNode(self, newNodeMiddle);
        }

        if (newLeafBitAtDepth) {
            newNodeMiddle = Node({
                nodeType: NodeType.MIDDLE,
                childLeft: _getNodeHash(oldLeaf),
                childRight: _getNodeHash(newLeaf),
                index: 0,
                value: 0
            });
        } else {
            newNodeMiddle = Node({
                nodeType: NodeType.MIDDLE,
                childLeft: _getNodeHash(newLeaf),
                childRight: _getNodeHash(oldLeaf),
                index: 0,
                value: 0
            });
        }

        _addNode(self, newLeaf);
        return _addNode(self, newNodeMiddle);
    }

    function _addNode(Data storage self, Node memory node) internal returns (uint256) {
        uint256 nodeHash = _getNodeHash(node);
        // We don't have any guarantees if the hash function attached is good enough.
        // So, if the node hash already exists, we need to check
        // if the node in the tree exactly matches the one we are trying to add.
        if (self.nodes[nodeHash].nodeType != NodeType.EMPTY) {
            assert(self.nodes[nodeHash].nodeType == node.nodeType);
            assert(self.nodes[nodeHash].childLeft == node.childLeft);
            assert(self.nodes[nodeHash].childRight == node.childRight);
            assert(self.nodes[nodeHash].index == node.index);
            assert(self.nodes[nodeHash].value == node.value);
            return nodeHash;
        }

        self.nodes[nodeHash] = node;
        return nodeHash;
    }

    function _getNodeHash(Node memory node) internal view returns (uint256) {
        uint256 nodeHash = 0;
        if (node.nodeType == NodeType.LEAF) {
            uint256[3] memory params = [node.index, node.value, uint256(1)];
            nodeHash = PoseidonUnit3L.poseidon(params);
        } else if (node.nodeType == NodeType.MIDDLE) {
            nodeHash = PoseidonUnit2L.poseidon([node.childLeft, node.childRight]);
        }
        return nodeHash; // Note: expected to return 0 if NodeType.EMPTY, which is the only option left
    }

    function _getRootInfoByIndex(
        Data storage self,
        uint256 index
    ) internal view returns (RootEntryInfo memory) {
        bool isLastRoot = index == self.rootEntries.length - 1;
        RootEntry storage rootEntry = self.rootEntries[index];

        return
            RootEntryInfo({
                root: rootEntry.root,
                replacedByRoot: isLastRoot ? 0 : self.rootEntries[index + 1].root,
                createdAtTimestamp: rootEntry.createdAtTimestamp,
                replacedAtTimestamp: isLastRoot
                    ? 0
                    : self.rootEntries[index + 1].createdAtTimestamp,
                createdAtBlock: rootEntry.createdAtBlock,
                replacedAtBlock: isLastRoot ? 0 : self.rootEntries[index + 1].createdAtBlock
            });
    }

    function _getRootInfoByTimestampOrBlock(
        Data storage self,
        uint256 timestampOrBlock,
        BinarySearchSmtRoots.SearchType searchType
    ) internal view returns (RootEntryInfo memory) {
        (uint256 index, bool found) = self.binarySearchUint256(timestampOrBlock, searchType);

        // As far as we always have at least one root entry, we should always find it
        assert(found);

        return _getRootInfoByIndex(self, index);
    }

    function _addEntry(
        Data storage self,
        uint256 root,
        uint256 _timestamp,
        uint256 _block
    ) internal {
        self.rootEntries.push(
            RootEntry({root: root, createdAtTimestamp: _timestamp, createdAtBlock: _block})
        );

        self.rootIndexes[root].push(self.rootEntries.length - 1);
    }
}

/// @title A binary search for the sparse merkle tree root history
// Implemented as a separate library for testing purposes
library BinarySearchSmtRoots {
    /**
     * @dev Enum for the SMT history field selection
     */
    enum SearchType {
        TIMESTAMP,
        BLOCK
    }

    /**
     * @dev Binary search method for the SMT history,
     * which searches for the index of the root entry saved by the given timestamp or block
     * @param value The timestamp or block to search for.
     * @param searchType The type of the search (timestamp or block).
     */
    function binarySearchUint256(
        SmtLib.Data storage self,
        uint256 value,
        SearchType searchType
    ) internal view returns (uint256, bool) {
        if (self.rootEntries.length == 0) {
            return (0, false);
        }

        uint256 min = 0;
        uint256 max = self.rootEntries.length - 1;
        uint256 mid;

        while (min <= max) {
            mid = (max + min) / 2;

            uint256 midValue = fieldSelector(self.rootEntries[mid], searchType);
            if (midValue == value) {
                while (mid < self.rootEntries.length - 1) {
                    uint256 nextValue = fieldSelector(self.rootEntries[mid + 1], searchType);
                    if (nextValue == value) {
                        mid++;
                    } else {
                        return (mid, true);
                    }
                }
                return (mid, true);
            } else if (value > midValue) {
                min = mid + 1;
            } else if (value < midValue && mid > 0) {
                // mid > 0 is to avoid underflow
                max = mid - 1;
            } else {
                // This means that value < midValue && mid == 0. So we found nothing.
                return (0, false);
            }
        }

        // The case when the searched value does not exist and we should take the closest smaller value
        // Index in the "max" var points to the root entry with max value smaller than the searched value
        return (max, true);
    }

    /**
     * @dev Selects either timestamp or block field from the root entry struct
     * depending on the search type
     * @param rti The root entry to select the field from.
     * @param st The search type.
     */
    function fieldSelector(
        SmtLib.RootEntry memory rti,
        SearchType st
    ) internal pure returns (uint256) {
        if (st == SearchType.BLOCK) {
            return rti.createdAtBlock;
        } else if (st == SearchType.TIMESTAMP) {
            return rti.createdAtTimestamp;
        } else {
            revert("Invalid search type");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../lib/ArrayUtils.sol";

/// @title Library for state data management.
// It's purpose is to keep records of identity states along with their metadata and history.
library StateLib {
    /**
     * @dev Max return array length for id history requests
     */
    uint256 public constant ID_HISTORY_RETURN_LIMIT = 1000;

    /**
     * @dev Struct for public interfaces to represent a state information.
     * @param id identity.
     * @param state A state.
     * @param replacedByState A state, which replaced this state for the identity.
     * @param createdAtTimestamp A time when the state was created.
     * @param replacedAtTimestamp A time when the state was replaced by the next identity state.
     * @param createdAtBlock A block number when the state was created.
     * @param replacedAtBlock A block number when the state was replaced by the next identity state.
     */
    struct EntryInfo {
        uint256 id;
        uint256 state;
        uint256 replacedByState;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for identity state internal storage representation.
     * @param state A state.
     * @param timestamp A time when the state was committed to blockchain.
     * @param block A block number when the state was committed to blockchain.
     */
    struct Entry {
        uint256 state;
        uint256 timestamp;
        uint256 block;
    }

    /**
     * @dev Struct for storing all the state data.
     * We assume that a state can repeat more than once for the same identity,
     * so we keep a mapping of state entries per each identity and state.
     * @param statesHistories A state history per each identity.
     * @param stateEntries A state metadata of each state.
     */
    struct Data {
        /*
        id => stateEntry[]
        --------------------------------
        id1 => [
            index 0: StateEntry1 {state1, timestamp2, block1},
            index 1: StateEntry2 {state2, timestamp2, block2},
            index 2: StateEntry3 {state1, timestamp3, block3}
        ]
        */
        mapping(uint256 => Entry[]) stateEntries;
        /*
        id => state => stateEntryIndex[]
        -------------------------------
        id1 => state1 => [index0, index2],
        id1 => state2 => [index1]
         */
        mapping(uint256 => mapping(uint256 => uint256[])) stateIndexes;
        // This empty reserved space is put in place to allow future versions
        // of the State contract to add new SmtData struct fields without shifting down
        // storage of upgradable contracts that use this struct as a state variable
        // (see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps)
        uint256[48] __gap;
    }

    /**
     * @dev event called when a state is updated
     * @param id identity
     * @param blockN Block number when the state has been committed
     * @param timestamp Timestamp when the state has been committed
     * @param state Identity state committed
     */
    event StateUpdated(uint256 id, uint256 blockN, uint256 timestamp, uint256 state);

    /**
     * @dev Revert if identity does not exist in the contract
     * @param id Identity
     */
    modifier onlyExistingId(Data storage self, uint256 id) {
        require(idExists(self, id), "Identity does not exist");
        _;
    }

    /**
     * @dev Revert if state does not exist in the contract
     * @param id Identity
     * @param state State
     */
    modifier onlyExistingState(
        Data storage self,
        uint256 id,
        uint256 state
    ) {
        require(stateExists(self, id, state), "State does not exist");
        _;
    }

    /**
     * @dev Add a state to the contract with transaction timestamp and block number.
     * @param id Identity
     * @param state State
     */
    function addState(Data storage self, uint256 id, uint256 state) external {
        _addState(self, id, state, block.timestamp, block.number);
    }

    /**
     * @dev Add a state to the contract with zero timestamp and block number.
     * @param id Identity
     * @param state State
     */
    function addGenesisState(Data storage self, uint256 id, uint256 state) external {
        require(
            !idExists(self, id),
            "Zero timestamp and block should be only in the first identity state"
        );
        _addState(self, id, state, 0, 0);
    }

    /**
     * @dev Retrieve the last state info for a given identity.
     * @param id Identity.
     * @return State info of the last committed state.
     */
    function getStateInfoById(
        Data storage self,
        uint256 id
    ) external view onlyExistingId(self, id) returns (EntryInfo memory) {
        Entry[] storage stateEntries = self.stateEntries[id];
        Entry memory se = stateEntries[stateEntries.length - 1];

        return
            EntryInfo({
                id: id,
                state: se.state,
                replacedByState: 0,
                createdAtTimestamp: se.timestamp,
                replacedAtTimestamp: 0,
                createdAtBlock: se.block,
                replacedAtBlock: 0
            });
    }

    /**
     * @dev Retrieve states quantity for a given identity
     * @param id identity
     * @return states quantity
     */
    function getStateInfoHistoryLengthById(
        Data storage self,
        uint256 id
    ) external view onlyExistingId(self, id) returns (uint256) {
        return self.stateEntries[id].length;
    }

    /**
     * Retrieve state infos for a given identity
     * @param id Identity
     * @param startIndex Start index of the state history.
     * @param length Max length of the state history retrieved.
     * @return A list of state infos of the identity
     */
    function getStateInfoHistoryById(
        Data storage self,
        uint256 id,
        uint256 startIndex,
        uint256 length
    ) external view onlyExistingId(self, id) returns (EntryInfo[] memory) {
        (uint256 start, uint256 end) = ArrayUtils.calculateBounds(
            self.stateEntries[id].length,
            startIndex,
            length,
            ID_HISTORY_RETURN_LIMIT
        );

        EntryInfo[] memory result = new EntryInfo[](end - start);

        for (uint256 i = start; i < end; i++) {
            result[i - start] = _getStateInfoByIndex(self, id, i);
        }

        return result;
    }

    /**
     * @dev Retrieve state info by id and state.
     * Note, that the latest state info is returned,
     * if the state repeats more that once for the same identity.
     * @param id An identity.
     * @param state A state.
     * @return The state info.
     */
    function getStateInfoByIdAndState(
        Data storage self,
        uint256 id,
        uint256 state
    ) external view onlyExistingState(self, id, state) returns (EntryInfo memory) {
        return _getStateInfoByState(self, id, state);
    }

    /**
     * @dev Retrieve state entries quantity by id and state.
     * If the state repeats more that once for the same identity,
     * the length will be greater than 1.
     * @param id An identity.
     * @param state A state.
     * @return The state info list length.
     */
    function getStateInfoListLengthByIdAndState(
        Data storage self,
        uint256 id,
        uint256 state
    ) external view returns (uint256) {
        return self.stateIndexes[id][state].length;
    }

    /**
     * @dev Retrieve state info list by id and state.
     * If the state repeats more that once for the same identity,
     * the length of the list may be greater than 1.
     * @param id An identity.
     * @param state A state.
     * @param startIndex Start index in the same states list.
     * @param length Max length of the state info list retrieved.
     * @return The state info list.
     */
    function getStateInfoListByIdAndState(
        Data storage self,
        uint256 id,
        uint256 state,
        uint256 startIndex,
        uint256 length
    ) external view onlyExistingState(self, id, state) returns (EntryInfo[] memory) {
        uint256[] storage stateIndexes = self.stateIndexes[id][state];
        (uint256 start, uint256 end) = ArrayUtils.calculateBounds(
            stateIndexes.length,
            startIndex,
            length,
            ID_HISTORY_RETURN_LIMIT
        );

        EntryInfo[] memory result = new EntryInfo[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = _getStateInfoByIndex(self, id, stateIndexes[i]);
        }

        return result;
    }

    /**
     * @dev Check if identity exists.
     * @param id Identity
     * @return True if the identity exists
     */
    function idExists(Data storage self, uint256 id) public view returns (bool) {
        return self.stateEntries[id].length > 0;
    }

    /**
     * @dev Check if state exists.
     * @param id Identity
     * @param state State
     * @return True if the state exists
     */
    function stateExists(Data storage self, uint256 id, uint256 state) public view returns (bool) {
        return self.stateIndexes[id][state].length > 0;
    }

    function _addState(
        Data storage self,
        uint256 id,
        uint256 state,
        uint256 _timestamp,
        uint256 _block
    ) internal {
        Entry[] storage stateEntries = self.stateEntries[id];

        stateEntries.push(Entry({state: state, timestamp: _timestamp, block: _block}));
        self.stateIndexes[id][state].push(stateEntries.length - 1);

        emit StateUpdated(id, _block, _timestamp, state);
    }

    /**
     * @dev Get state info by id and state without state existence check.
     * @param id Identity
     * @param state State
     * @return The state info
     */
    function _getStateInfoByState(
        Data storage self,
        uint256 id,
        uint256 state
    ) internal view returns (EntryInfo memory) {
        uint256[] storage indexes = self.stateIndexes[id][state];
        uint256 lastIndex = indexes[indexes.length - 1];
        return _getStateInfoByIndex(self, id, lastIndex);
    }

    function _getStateInfoByIndex(
        Data storage self,
        uint256 id,
        uint256 index
    ) internal view returns (EntryInfo memory) {
        bool isLastState = index == self.stateEntries[id].length - 1;
        Entry storage se = self.stateEntries[id][index];

        return
            EntryInfo({
                id: id,
                state: se.state,
                replacedByState: isLastState ? 0 : self.stateEntries[id][index + 1].state,
                createdAtTimestamp: se.timestamp,
                replacedAtTimestamp: isLastState ? 0 : self.stateEntries[id][index + 1].timestamp,
                createdAtBlock: se.block,
                replacedAtBlock: isLastState ? 0 : self.stateEntries[id][index + 1].block
            });
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/IState.sol";
import "../interfaces/IStateTransitionVerifier.sol";
import "../lib/SmtLib.sol";
import "../lib/Poseidon.sol";
import "../lib/StateLib.sol";

/// @title Set and get states for each identity
contract StateV2 is Ownable2StepUpgradeable, IState {
    /**
     * @dev Version of contract
     */
    string public constant VERSION = "2.1.0";

    // This empty reserved space is put in place to allow future versions
    // of the State contract to inherit from other contracts without a risk of
    // breaking the storage layout. This is necessary because the parent contracts in the
    // future may introduce some storage variables, which are placed before the State
    // contract's storage variables.
    // (see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps)
    // slither-disable-next-line shadowing-state
    // slither-disable-next-line unused-state
    uint256[500] private __gap;

    /**
     * @dev Verifier address
     */
    IStateTransitionVerifier internal verifier;

    /**
     * @dev State data
     */
    StateLib.Data internal _stateData;

    /**
     * @dev Global Identity State Tree (GIST) data
     */
    SmtLib.Data internal _gistData;

    using SmtLib for SmtLib.Data;
    using StateLib for StateLib.Data;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     * @param verifierContractAddr Verifier address
     */
    function initialize(IStateTransitionVerifier verifierContractAddr) public initializer {
        verifier = verifierContractAddr;
        _gistData.initialize(MAX_SMT_DEPTH);
        __Ownable_init();
    }

    /**
     * @dev Set ZKP verifier contract address
     * @param newVerifierAddr Verifier contract address
     */
    function setVerifier(address newVerifierAddr) external onlyOwner {
        verifier = IStateTransitionVerifier(newVerifierAddr);
    }

    /**
     * @dev Change the state of an identity (transit to the new state) with ZKP ownership check.
     * @param id Identity
     * @param oldState Previous identity state
     * @param newState New identity state
     * @param isOldStateGenesis Is the previous state genesis?
     * @param a ZKP proof field
     * @param b ZKP proof field
     * @param c ZKP proof field
     */
    function transitState(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external {
        require(id != 0, "ID should not be zero");
        require(newState != 0, "New state should not be zero");
        require(!stateExists(id, newState), "New state already exists");

        if (isOldStateGenesis) {
            require(!idExists(id), "Old state is genesis but identity already exists");

            // Push old state to state entries, with zero timestamp and block
            _stateData.addGenesisState(id, oldState);
        } else {
            require(idExists(id), "Old state is not genesis but identity does not yet exist");

            StateLib.EntryInfo memory prevStateInfo = _stateData.getStateInfoById(id);
            require(
                prevStateInfo.createdAtBlock != block.number,
                "No multiple set in the same block"
            );
            require(prevStateInfo.state == oldState, "Old state does not match the latest state");
        }

        uint256[4] memory input = [id, oldState, newState, uint256(isOldStateGenesis ? 1 : 0)];
        require(
            verifier.verifyProof(a, b, c, input),
            "Zero-knowledge proof of state transition is not valid"
        );

        _stateData.addState(id, newState);
        _gistData.addLeaf(PoseidonUnit1L.poseidon([id]), newState);
    }

    /**
     * @dev Get ZKP verifier contract address
     * @return verifier contract address
     */
    function getVerifier() external view returns (address) {
        return address(verifier);
    }

    /**
     * @dev Retrieve the last state info for a given identity
     * @param id identity
     * @return state info of the last committed state
     */
    function getStateInfoById(uint256 id) external view returns (IState.StateInfo memory) {
        return _stateEntryInfoAdapter(_stateData.getStateInfoById(id));
    }

    /**
     * @dev Retrieve states quantity for a given identity
     * @param id identity
     * @return states quantity
     */
    function getStateInfoHistoryLengthById(uint256 id) external view returns (uint256) {
        return _stateData.getStateInfoHistoryLengthById(id);
    }

    /**
     * Retrieve state infos for a given identity
     * @param id identity
     * @param startIndex start index of the state history
     * @param length length of the state history
     * @return A list of state infos of the identity
     */
    function getStateInfoHistoryById(
        uint256 id,
        uint256 startIndex,
        uint256 length
    ) external view returns (IState.StateInfo[] memory) {
        StateLib.EntryInfo[] memory stateInfos = _stateData.getStateInfoHistoryById(
            id,
            startIndex,
            length
        );
        IState.StateInfo[] memory result = new IState.StateInfo[](stateInfos.length);
        for (uint256 i = 0; i < stateInfos.length; i++) {
            result[i] = _stateEntryInfoAdapter(stateInfos[i]);
        }
        return result;
    }

    /**
     * @dev Retrieve state information by id and state.
     * @param id An identity.
     * @param state A state.
     * @return The state info.
     */
    function getStateInfoByIdAndState(
        uint256 id,
        uint256 state
    ) external view returns (IState.StateInfo memory) {
        return _stateEntryInfoAdapter(_stateData.getStateInfoByIdAndState(id, state));
    }

    /**
     * @dev Retrieve GIST inclusion or non-inclusion proof for a given identity.
     * @param id Identity
     * @return The GIST inclusion or non-inclusion proof for the identity
     */
    function getGISTProof(uint256 id) external view returns (IState.GistProof memory) {
        return _smtProofAdapter(_gistData.getProof(PoseidonUnit1L.poseidon([id])));
    }

    /**
     * @dev Retrieve GIST inclusion or non-inclusion proof for a given identity for
     * some GIST root in the past.
     * @param id Identity
     * @param root GIST root
     * @return The GIST inclusion or non-inclusion proof for the identity
     */
    function getGISTProofByRoot(
        uint256 id,
        uint256 root
    ) external view returns (IState.GistProof memory) {
        return _smtProofAdapter(_gistData.getProofByRoot(PoseidonUnit1L.poseidon([id]), root));
    }

    /**
     * @dev Retrieve GIST inclusion or non-inclusion proof for a given identity
     * for GIST latest snapshot by the block number provided.
     * @param id Identity
     * @param blockNumber Blockchain block number
     * @return The GIST inclusion or non-inclusion proof for the identity
     */
    function getGISTProofByBlock(
        uint256 id,
        uint256 blockNumber
    ) external view returns (IState.GistProof memory) {
        return
            _smtProofAdapter(_gistData.getProofByBlock(PoseidonUnit1L.poseidon([id]), blockNumber));
    }

    /**
     * @dev Retrieve GIST inclusion or non-inclusion proof for a given identity
     * for GIST latest snapshot by the blockchain timestamp provided.
     * @param id Identity
     * @param timestamp Blockchain timestamp
     * @return The GIST inclusion or non-inclusion proof for the identity
     */
    function getGISTProofByTime(
        uint256 id,
        uint256 timestamp
    ) external view returns (IState.GistProof memory) {
        return _smtProofAdapter(_gistData.getProofByTime(PoseidonUnit1L.poseidon([id]), timestamp));
    }

    /**
     * @dev Retrieve GIST latest root.
     * @return The latest GIST root
     */
    function getGISTRoot() external view returns (uint256) {
        return _gistData.getRoot();
    }

    /**
     * @dev Retrieve the GIST root history.
     * @param start Start index in the root history
     * @param length Length of the root history
     * @return Array of GIST roots infos
     */
    function getGISTRootHistory(
        uint256 start,
        uint256 length
    ) external view returns (IState.GistRootInfo[] memory) {
        SmtLib.RootEntryInfo[] memory rootInfos = _gistData.getRootHistory(start, length);
        IState.GistRootInfo[] memory result = new IState.GistRootInfo[](rootInfos.length);

        for (uint256 i = 0; i < rootInfos.length; i++) {
            result[i] = _smtRootInfoAdapter(rootInfos[i]);
        }
        return result;
    }

    /**
     * @dev Retrieve the length of the GIST root history.
     * @return The GIST root history length
     */
    function getGISTRootHistoryLength() external view returns (uint256) {
        return _gistData.rootEntries.length;
    }

    /**
     * @dev Retrieve the specific GIST root information.
     * @param root GIST root.
     * @return The GIST root information.
     */
    function getGISTRootInfo(uint256 root) external view returns (IState.GistRootInfo memory) {
        return _smtRootInfoAdapter(_gistData.getRootInfo(root));
    }

    /**
     * @dev Retrieve the GIST root information, which is latest by the block provided.
     * @param blockNumber Blockchain block number
     * @return The GIST root info
     */
    function getGISTRootInfoByBlock(
        uint256 blockNumber
    ) external view returns (IState.GistRootInfo memory) {
        return _smtRootInfoAdapter(_gistData.getRootInfoByBlock(blockNumber));
    }

    /**
     * @dev Retrieve the GIST root information, which is latest by the blockchain timestamp provided.
     * @param timestamp Blockchain timestamp
     * @return The GIST root info
     */
    function getGISTRootInfoByTime(
        uint256 timestamp
    ) external view returns (IState.GistRootInfo memory) {
        return _smtRootInfoAdapter(_gistData.getRootInfoByTime(timestamp));
    }

    /**
     * @dev Check if identity exists.
     * @param id Identity
     * @return True if the identity exists
     */
    function idExists(uint256 id) public view returns (bool) {
        return _stateData.idExists(id);
    }

    /**
     * @dev Check if state exists.
     * @param id Identity
     * @param state State
     * @return True if the state exists
     */
    function stateExists(uint256 id, uint256 state) public view returns (bool) {
        return _stateData.stateExists(id, state);
    }

    function _smtProofAdapter(
        SmtLib.Proof memory proof
    ) internal pure returns (IState.GistProof memory) {
        // slither-disable-next-line uninitialized-local
        uint256[MAX_SMT_DEPTH] memory siblings;
        for (uint256 i = 0; i < MAX_SMT_DEPTH; i++) {
            siblings[i] = proof.siblings[i];
        }

        IState.GistProof memory result = IState.GistProof({
            root: proof.root,
            existence: proof.existence,
            siblings: siblings,
            index: proof.index,
            value: proof.value,
            auxExistence: proof.auxExistence,
            auxIndex: proof.auxIndex,
            auxValue: proof.auxValue
        });

        return result;
    }

    function _smtRootInfoAdapter(
        SmtLib.RootEntryInfo memory rootInfo
    ) internal pure returns (IState.GistRootInfo memory) {
        return
            IState.GistRootInfo({
                root: rootInfo.root,
                replacedByRoot: rootInfo.replacedByRoot,
                createdAtTimestamp: rootInfo.createdAtTimestamp,
                replacedAtTimestamp: rootInfo.replacedAtTimestamp,
                createdAtBlock: rootInfo.createdAtBlock,
                replacedAtBlock: rootInfo.replacedAtBlock
            });
    }

    function _stateEntryInfoAdapter(
        StateLib.EntryInfo memory sei
    ) internal pure returns (IState.StateInfo memory) {
        return
            IState.StateInfo({
                id: sei.id,
                state: sei.state,
                replacedByState: sei.replacedByState,
                createdAtTimestamp: sei.createdAtTimestamp,
                replacedAtTimestamp: sei.replacedAtTimestamp,
                createdAtBlock: sei.createdAtBlock,
                replacedAtBlock: sei.replacedAtBlock
            });
    }
}