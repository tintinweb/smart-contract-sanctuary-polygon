// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

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
        __ERC1967Upgrade_init_unchained();
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-2612: permit - 712-signed approvals
 *
 * @notice A function permit extending ERC-20 which allows for approvals to be made via secp256k1 signatures.
 *      This kind of “account abstraction for ERC-20” brings about two main benefits:
 *        - transactions involving ERC-20 operations can be paid using the token itself rather than ETH,
 *        - approve and pull operations can happen in a single transaction instead of two consecutive transactions,
 *        - while adding as little as possible over the existing ERC-20 standard.
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-2612#specification
 */
interface EIP2612 {
	/**
	 * @notice EIP712 domain separator of the smart contract. It should be unique to the contract
	 *      and chain to prevent replay attacks from other domains, and satisfy the requirements of EIP-712,
	 *      but is otherwise unconstrained.
	 */
	function DOMAIN_SEPARATOR() external view returns (bytes32);

	/**
	 * @notice Counter of the nonces used for the given address; nonce are used sequentially
	 *
	 * @dev To prevent from replay attacks nonce is incremented for each address after a successful `permit` execution
	 *
	 * @param owner an address to query number of used nonces for
	 * @return number of used nonce, nonce number to be used next
	 */
	function nonces(address owner) external view returns (uint);

	/**
	 * @notice For all addresses owner, spender, uint256s value, deadline and nonce, uint8 v, bytes32 r and s,
	 *      a call to permit(owner, spender, value, deadline, v, r, s) will set approval[owner][spender] to value,
	 *      increment nonces[owner] by 1, and emit a corresponding Approval event,
	 *      if and only if the following conditions are met:
	 *        - The current blocktime is less than or equal to deadline.
	 *        - owner is not the zero address.
	 *        - nonces[owner] (before the state update) is equal to nonce.
	 *        - r, s and v is a valid secp256k1 signature from owner of the message:
	 *
	 * @param owner token owner address, granting an approval to spend its tokens
	 * @param spender an address approved by the owner (token owner)
	 *      to spend some tokens on its behalf
	 * @param value an amount of tokens spender `spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-3009: Transfer With Authorization
 *
 * @notice A contract interface that enables transferring of fungible assets via a signed authorization.
 *      See https://eips.ethereum.org/EIPS/eip-3009
 *      See https://eips.ethereum.org/EIPS/eip-3009#specification
 */
interface EIP3009 {
	/**
	 * @dev Fired whenever the nonce gets used (ex.: `transferWithAuthorization`, `receiveWithAuthorization`)
	 *
	 * @param authorizer an address which has used the nonce
	 * @param nonce the nonce used
	 */
	event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever the nonce gets cancelled (ex.: `cancelAuthorization`)
	 *
	 * @dev Both `AuthorizationUsed` and `AuthorizationCanceled` imply the nonce
	 *      cannot be longer used, the only difference is that `AuthorizationCanceled`
	 *      implies no smart contract state change made (except the nonce marked as cancelled)
	 *
	 * @param authorizer an address which has cancelled the nonce
	 * @param nonce the nonce cancelled
	 */
	event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @notice Returns the state of an authorization, more specifically
	 *      if the specified nonce was already used by the address specified
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte data
	 *      unique to the authorizer's address
	 *
	 * @param authorizer    Authorizer's address
	 * @param nonce         Nonce of the authorization
	 * @return true if the nonce is used
	 */
	function authorizationState(
		address authorizer,
		bytes32 nonce
	) external view returns (bool);

	/**
	 * @notice Execute a transfer with a signed authorization
	 *
	 * @param from          Payer's address (Authorizer)
	 * @param to            Payee's address
	 * @param value         Amount to be transferred
	 * @param validAfter    The time after which this is valid (unix time)
	 * @param validBefore   The time before which this is valid (unix time)
	 * @param nonce         Unique nonce
	 * @param v             v of the signature
	 * @param r             r of the signature
	 * @param s             s of the signature
	 */
	function transferWithAuthorization(
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @notice Receive a transfer with a signed authorization from the payer
	 *
	 * @dev This has an additional check to ensure that the payee's address matches
	 *      the caller of this function to prevent front-running attacks.
	 * @dev See https://eips.ethereum.org/EIPS/eip-3009#security-considerations
	 *
	 * @param from          Payer's address (Authorizer)
	 * @param to            Payee's address
	 * @param value         Amount to be transferred
	 * @param validAfter    The time after which this is valid (unix time)
	 * @param validBefore   The time before which this is valid (unix time)
	 * @param nonce         Unique nonce
	 * @param v             v of the signature
	 * @param r             r of the signature
	 * @param s             s of the signature
	 */
	function receiveWithAuthorization(
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @notice Attempt to cancel an authorization
	 *
	 * @param authorizer    Authorizer's address
	 * @param nonce         Nonce of the authorization
	 * @param v             v of the signature
	 * @param r             r of the signature
	 * @param s             s of the signature
	 */
	function cancelAuthorization(
		address authorizer,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20Spec.sol";
import "./ERC165Spec.sol";

/**
 * @title ERC1363 Interface
 *
 * @dev Interface defining a ERC1363 Payable Token contract.
 *      Implementing contracts MUST implement the ERC1363 interface as well as the ERC20 and ERC165 interfaces.
 */
interface ERC1363 is ERC20, ERC165  {
	/*
	 * Note: the ERC-165 identifier for this interface is 0xb0202a11.
	 * 0xb0202a11 ===
	 *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
	 *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
	 *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
	 *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
	 *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
	 *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
	 */

	/**
	 * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @return true unless throwing
	 */
	function transferAndCall(address to, uint256 value) external returns (bool);

	/**
	 * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @param data bytes Additional data with no specified format, sent in call to `to`
	 * @return true unless throwing
	 */
	function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool);

	/**
	 * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @return true unless throwing
	 */
	function transferFromAndCall(address from, address to, uint256 value) external returns (bool);


	/**
	 * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
	 * @param from address The address which you want to send tokens from
	 * @param to address The address which you want to transfer to
	 * @param value uint256 The amount of tokens to be transferred
	 * @param data bytes Additional data with no specified format, sent in call to `to`
	 * @return true unless throwing
	 */
	function transferFromAndCall(address from, address to, uint256 value, bytes memory data) external returns (bool);

	/**
	 * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
	 * and then call `onApprovalReceived` on spender.
	 * @param spender address The address which will spend the funds
	 * @param value uint256 The amount of tokens to be spent
	 */
	function approveAndCall(address spender, uint256 value) external returns (bool);

	/**
	 * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
	 * and then call `onApprovalReceived` on spender.
	 * @param spender address The address which will spend the funds
	 * @param value uint256 The amount of tokens to be spent
	 * @param data bytes Additional data with no specified format, sent in call to `spender`
	 */
	function approveAndCall(address spender, uint256 value, bytes memory data) external returns (bool);
}

/**
 * @title ERC1363Receiver Interface
 *
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *      from ERC1363 token contracts.
 */
interface ERC1363Receiver {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
	 * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the receipt of ERC1363 tokens
	 *
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 *      after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
	 *      transfer. Return of other than the magic value MUST result in the
	 *      transaction being reverted.
	 *      Note: the token contract address is always the message sender.
	 *
	 * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
	 * @param from address The address which are token transferred from
	 * @param value uint256 The amount of tokens transferred
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
	 *      unless throwing
	 */
	function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external returns (bytes4);
}

/**
 * @title ERC1363Spender Interface
 *
 * @dev Interface for any contract that wants to support `approveAndCall`
 *      from ERC1363 token contracts.
 */
interface ERC1363Spender {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
	 * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the approval of ERC1363 tokens
	 *
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 *      after an `approve`. This function MAY throw to revert and reject the
	 *      approval. Return of other than the magic value MUST result in the
	 *      transaction being reverted.
	 *      Note: the token contract address is always the message sender.
	 *
	 * @param owner address The address which called `approveAndCall` function
	 * @param value uint256 The amount of tokens to be spent
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
	 *      unless throwing
	 */
	function onApprovalReceived(address owner, uint256 value, bytes memory data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Mintable ERC721
 *
 * @notice Defines mint capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
interface MintableERC721 {
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}

/**
 * @title Burnable ERC721
 *
 * @notice Defines burn capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
interface BurnableERC721 {
	/**
	 * @notice Destroys the token with token ID specified
	 *
	 * @dev Should be accessible publicly by token owners.
	 *      May have a restricted access handled by the implementation
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) external;
}

/**
 * @title With Base URI
 *
 * @notice A marker interface for the contracts having the baseURI() function
 *      or public string variable named baseURI
 *      NFT implementations like TinyERC721, or ShortERC721 are example of such smart contracts
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
interface WithBaseURI {
	/**
	 * @dev Usually used in NFT implementations to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 */
	function baseURI() external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @dev Copy of the Zeppelin's library:
 *      https://github.com/gnosis/openzeppelin-solidity/blob/master/contracts/AddressUtils.sol
 */
library AddressUtils {

	/**
	 * @notice Checks if the target address is a contract
	 *
	 * @dev It is unsafe to assume that an address for which this function returns
	 *      false is an externally-owned account (EOA) and not a contract.
	 *
	 * @dev Among others, `isContract` will return false for the following
	 *      types of addresses:
	 *        - an externally-owned account
	 *        - a contract in construction
	 *        - an address where a contract will be created
	 *        - an address where a contract lived, but was destroyed
	 *
	 * @param addr address to check
	 * @return whether the target address is a contract
	 */
	function isContract(address addr) internal view returns (bool) {
		// a variable to load `extcodesize` to
		uint256 size = 0;

		// XXX Currently there is no better way to check if there is a contract in an address
		// than to check the size of the code at that address.
		// See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
		// TODO: Check this again before the Serenity release, because all addresses will be contracts.
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			// retrieve the size of the code at address `addr`
			size := extcodesize(addr)
		}

		// positive size indicates a smart contract address
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Array Utils
 *
 * @notice Solidity doesn't always work with arrays in an optimal way.
 *      This library collects functions helping to optimize gas usage
 *      when working with arrays in Solidity.
 *
 * @dev One of the most important use cases for arrays is "tight" arrays -
 *      arrays which store values significantly less than 256-bits numbers
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
library ArrayUtils {
	/**
	 * @dev Pushes `n` 32-bits values sequentially into storage allocated array `data`
	 *      starting from the 32-bits value `v0`
	 *
	 * @dev Optimizations comparing to non-assembly implementation:
	 *      - reads+writes to array size slot only once (instead of `n` times)
	 *      - reads from the array data slots only once (instead of `7n/8` times)
	 *      - writes into array data slots `n/8` times (instead of `n` times)
	 *
	 * @dev Maximum gas saving estimate: ~3n sstore, or 15,000 * n
	 *
	 * @param data storage array pointer to an array of 32-bits elements
	 * @param v0 first number to push into the array
	 * @param n number of values to push, pushes [v0, ..., v0 + n - 1]
	 */
	function push32(uint32[] storage data, uint32 v0, uint32 n) internal {
		// we're going to write 32-bits values into 256-bits storage slots of the array
		// each 256-slot can store up to 8 32-bits sub-blocks, it can also be partially empty
		assembly {
			// for dynamic arrays their slot (array.slot) contains the array length
			// array data is stored separately in consequent storage slots starting
			// from the slot with the address keccak256(array.slot)

			// read the array length into `len` and increase it by `n`
			let len := sload(data.slot)
			sstore(data.slot, add(len, n))

			// find where to write elements and store this location into `loc`
			// load array storage slot number into memory onto position 0,
			// calculate the keccak256 of the slot number (first 32 bytes at position 0)
			// - this will point to the beginning of the array,
			// so we add array length divided by 8 to point to the last array slot
			mstore(0, data.slot)
			let loc := add(keccak256(0, 32), div(len, 8))

			// if we start writing data into already partially occupied slot (`len % 8 != 0`)
			// we need to modify the contents of that slot: read it and rewrite it
			let offset := mod(len, 8)
			if not(iszero(offset)) {
				// how many 32-bits sub-blocks left in the slot
				let left := sub(8, offset)
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// load the contents of the first slot (partially occupied)
				let v256 := sload(loc)
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `(j + offset) * 32` bits, length: 32-bits
					// v256 |= (v0 + j) << (j + offset) * 32
					v256 := or(v256, shl(mul(add(j, offset), 32), add(v0, j)))
				}
				// write first slot back, it can be still partially occupied, it can also be full
				sstore(loc, v256)
				// update `loc`: move to the next slot
				loc := add(loc, 1)
				// update `v0`: increment by number of values pushed
				v0 := add(v0, left)
				// update `n`: decrement by number of values pushed
				n := sub(n, left)
			}

			// rest of the slots (if any) are empty and will be only written to
			// write the array in 256-bits (8x32) slots
			// `i` iterates [0, n) with the 256-bits step, which is 8 taken `n` is 32-bits long
			for { let i := 0 } lt(i, n) { i := add(i, 8) } {
				// how many 32-bits sub-blocks left in the slot
				let left := 8
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// init the 256-bits slot value
				let v256 := 0
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `j * 32` bits, length: 32-bits
					// v256 |= (v0 + i + j) << j * 32
					v256 := or(v256, shl(mul(j, 32), add(v0, add(i, j))))
				}
				// write slot `i / 8`
				sstore(add(loc, div(i, 8)), v256)
			}
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 *
 * @dev Copy of the Zeppelin's library:
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e/contracts/utils/cryptography/ECDSA.sol
 */
library ECDSA {
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
	 *
	 * Documentation for signature generation:
	 * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
	 * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
	 */
	function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
		// Divide the signature in r, s and v variables
		bytes32 r;
		bytes32 s;
		uint8 v;

		// Check the signature length
		// - case 65: r,s,v signature (standard)
		// - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
		if (signature.length == 65) {
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				r := mload(add(signature, 0x20))
				s := mload(add(signature, 0x40))
				v := byte(0, mload(add(signature, 0x60)))
			}
		}
		else if (signature.length == 64) {
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				let vs := mload(add(signature, 0x40))
				r := mload(add(signature, 0x20))
				s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
				v := add(shr(255, vs), 27)
			}
		}
		else {
			revert("invalid signature length");
		}

		return recover(hash, v, r, s);
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
		// EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
		// unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
		// the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
		// signatures from current libraries generate a unique signature with an s-value in the lower half order.
		//
		// If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
		// with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
		// vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
		// these malleable signatures as well.
		require(
			uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
			"invalid signature 's' value"
		);
		require(v == 27 || v == 28, "invalid signature 'v' value");

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(hash, v, r, s);
		require(signer != address(0), "invalid signature");

		return signer;
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
pragma solidity 0.8.7;

/**
 * @title String Utils Library
 *
 * @dev Library for working with strings, primarily converting
 *      between strings and integer types
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
library StringUtils {
	/**
	 * @dev Converts a string to unsigned integer using the specified `base`
	 * @dev Throws on invalid input
	 *      (wrong characters for a given `base`)
	 * @dev Throws if given `base` is not supported
	 * @param a string to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return i a number representing given string
	 */
	function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// convert string into bytes for convenient iteration
		bytes memory buf = bytes(a);

		// iterate over the string (bytes buffer)
		for(uint256 p = 0; p < buf.length; p++) {
			// extract the digit
			uint8 digit = uint8(buf[p]) - 0x30;

			// if digit is greater then 10 - mind the gap
			// see `itoa` function for more details
			if(digit > 10) {
				// remove the gap
				digit -= 7;
			}

			// check if digit meets the base
			require(digit < base);

			// move to the next digit slot
			i *= base;

			// add digit to the result
			i += digit;
		}

		// return the result
		return i;
	}

	/**
	 * @dev Converts a integer to a string using the specified `base`
	 * @dev Throws if given `base` is not supported
	 * @param i integer to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return a a string representing given integer
	 */
	function itoa(uint256 i, uint8 base) internal pure returns (string memory a) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// for zero input the result is "0" string for any base
		if(i == 0) {
			return "0";
		}

		// bytes buffer to put ASCII characters into
		bytes memory buf = new bytes(256);

		// position within a buffer to be used in cycle
		uint256 p = 0;

		// extract digits one by one in a cycle
		while(i > 0) {
			// extract current digit
			uint8 digit = uint8(i % base);

			// convert it to an ASCII code
			// 0x20 is " "
			// 0x30-0x39 is "0"-"9"
			// 0x41-0x5A is "A"-"Z"
			// 0x61-0x7A is "a"-"z" ("A"-"Z" XOR " ")
			uint8 ascii = digit + 0x30;

			// if digit is greater then 10,
			// fix the 0x3A-0x40 gap of punctuation marks
			// (7 characters in ASCII table)
			if(digit >= 10) {
				// jump through the gap
				ascii += 7;
			}

			// write character into the buffer
			buf[p++] = bytes1(ascii);

			// move to the next digit
			i /= base;
		}

		// `p` contains real length of the buffer now,
		// allocate the resulting buffer of that size
		bytes memory result = new bytes(p);

		// copy the buffer in the reversed order
		for(p = 0; p < result.length; p++) {
			// copy from the beginning of the original buffer
			// to the end of resulting smaller buffer
			result[result.length - p - 1] = buf[p];
		}

		// construct string and return
		return string(result);
	}

	/**
	 * @dev Concatenates two strings `s1` and `s2`, for example, if
	 *      `s1` == `foo` and `s2` == `bar`, the result `s` == `foobar`
	 * @param s1 first string
	 * @param s2 second string
	 * @return s concatenation result s1 + s2
	 */
	function concat(string memory s1, string memory s2) internal pure returns (string memory s) {
		// an old way of string concatenation (Solidity 0.4) is commented out
/*
		// convert s1 into buffer 1
		bytes memory buf1 = bytes(s1);
		// convert s2 into buffer 2
		bytes memory buf2 = bytes(s2);
		// create a buffer for concatenation result
		bytes memory buf = new bytes(buf1.length + buf2.length);

		// copy buffer 1 into buffer
		for(uint256 i = 0; i < buf1.length; i++) {
			buf[i] = buf1[i];
		}

		// copy buffer 2 into buffer
		for(uint256 j = buf1.length; j < buf2.length; j++) {
			buf[j] = buf2[j - buf1.length];
		}

		// construct string and return
		return string(buf);
*/

		// simply use built in function
		return string(abi.encodePacked(s1, s2));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./XCCERC20.sol";
import "./PatchOwnershipNFT.sol";
import "../interfaces/EIP3009.sol";
import "../utils/UpgradeableAccessControl.sol";

/**
 * @title Treecoin Patch Factory
 *
 * @notice When creating an new Patch, Patch details will be registerd and OwnershipNFT token will
 *      be created using this smart contract.
 *      An OwnershipNFT will be sent to one primary owner of Patch and later Owner will distribute
 *	 	Patch Ownership token to all other sub-owner of Patch.
 */
contract PatchFactory is UpgradeableAccessControl {

	/// @dev Patch Token address list
	address[] public patchTokenList;

	/// @dev Patch Token Mapping by index of PatchID
	mapping(uint256 => address) public patchTokenbyPatchID;

    /// @dev Patch Token Mapping by index of PatchID
	mapping(address => uint256) public patchIDbyPatchToken;

    /// @dev Patch Event Mapping by index of PatchID
	mapping(uint256 => PatchEventInfo[]) public patchEventDetails;

	/// @dev Patch Details Mapping by index of PatchID
	mapping(uint256 => PatchInfo) public patchDetails;

	/// @dev Treasury Wallet address where XCC token will be sent
	address public treasuryWallet;

	/// @dev admin Fee
	uint256 public adminFee;

    /// @dev Registered Patch Count
    uint256 public totalPatchRegistered;

	/// @dev XCC-G token contract address
	address public XCC_Gold;

    /// @dev XCC-S token contract address
	address public XCC_Silver;

    /// @dev XCC-B token contract address
	address public XCC_Bronze;

	/// @dev Enables config manager to edit configurable parameters
	uint32 public constant ROLE_CONFIG_MANAGER = 0x0001_0000;

	/// @dev Enables token manager to update role for PatchOwnerShip token
	uint32 public constant ROLE_PO_TOKEN_MANAGER = 0x0002_0000;

	/// @dev Enables token manager to update role for PatchOwnerShip token
	uint32 public constant ROLE_PATCH_REGISTRY_MANAGER = 0x0004_0000;

	/// @dev Enables token manager to update role for PatchOwnerShip token
	uint32 public constant ROLE_PATCH_EVENT_MANAGER = 0x0008_0000;

	/// @dev Token Distributor helper address
	address public tokenDistributor;

	/// @dev Struct to store Patch information
	struct PatchInfo {
		uint256 patchId;
        string patchName;
        string patchDetailURI;
		address patchInitialOwner;
        address ownershipTokenAddress;
        uint256 noOfEventRegistered;
		uint256 patchRegistrationTime;
		uint256 totalCO2OffSet;
		uint256 treePlantedArea;
		uint256 treeVolume;
        bool isPatchActive;
		uint256[][] patchGeoFenceDetails;
	}

    /// @dev Struct to store Patch Event information
	struct PatchEventInfo {
        uint256 patchId;
        uint256 co2OffsetAmt;
        uint256 eventPeriod;
		address emitedToken;
        uint256 emittedTokenAmt;
        uint256 eventRegistrationTime;
		uint256 oldTreeVolume;
		uint256 newTreeVolume;
        uint256 khatamReportId;
        string khatamReportURI;
	}

	/// @dev PatchRegistered event will be emit from registerPatch() function
	event PatchRegistered(
				address indexed _user,
				uint256 indexed _patchId,
				string _patchName,
				string _patchDetailURI,
				uint256 _treePlantedArea,
				uint256 _treeVolume,
				address _initialOwner,
				address _ownershipTokenAddr,
				uint256[][] _patchGeoFenceDetails,
				uint256 _patchRegisterationTime
			);

	/// @dev PatchEventRegistered event will be emit from registerEvent() function
	event PatchEventRegistered(
				address indexed _user,
				uint256 indexed _patchId,
				uint256 _co2OffsetAmt,
				uint256 _treeVolume,
				uint256 _eventPeriod,
				address _emitedToken,
				uint256 _emittedTokenAmt,
				uint256 _eventRegistrationTime
			);

	/// @dev PatchDeactivated event will be emit from deactivatePatch() function
	event PatchDeactivated(
				address indexed _user,
				uint256 indexed _patchId
			);

	/// @dev PatchActivated event will be emit from activatePatch() function
	event PatchActivated(
				address indexed _user,
				uint256 indexed _patchId
			);

	/// @dev PatchDetailsUpdated event will be emit from updatePatchDetails() function
	event PatchDetailsUpdated(
				address indexed _user,
				uint256 indexed _patchId,
				string _patchName,
				string _patchDetailURI,
				uint256 _treePlantedArea,
				uint256 _treeVolume,
				uint256[][] _patchGeoFenceDetails
			);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *	  see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @dev Binds PatchFactory instance to already deployed
	 *	  XCC-G, XCC-S and XCC-B token instances
	 *
	 * @param _xccGold address of deployed XCC_GOLD token
	 * @param _xccSilver address of deployed XCC_SILVER token
	 * @param _xccBronze address of deployed XCC_BRONZE token
	 * @param _treasuryWallet address of treasury where XCC token will be sent
	 */
	function postConstruct(
		address _xccGold,
		address _xccSilver,
		address _xccBronze,
		address _treasuryWallet
	) public virtual initializer {
		require(_xccGold != address(0), "_xccGold address is not set");
		require(_xccSilver != address(0), "_xccSilver address is not set");
		require(_xccBronze != address(0), "_xccBronze address is not set");
		require(_treasuryWallet != address(0), "_treasuryWallet address is not set");

		// update smart contract internal state
		XCC_Gold = _xccGold;
		XCC_Silver = _xccSilver;
		XCC_Bronze = _xccBronze;
		treasuryWallet = _treasuryWallet;

		// 1% admin fee will taken when new event is register
		adminFee = 100;
		// execute all parent initializers in cascade
		UpgradeableAccessControl._postConstruct(msg.sender);
	}

	/**
	 * @notice Updates the role for given ownershipToken
	 * @param _ownershipToken Token address
	 * @param _to address of user to grant a role
	 * @param _role bitmask representing a set of permissions to
	 *		 enable/disable for a user specified
	 */
	function updateTokenRole(address _ownershipToken, address _to, uint256 _role) public virtual {
		// verify executor is allowed to share token  roles
		require(isSenderInRole(ROLE_PO_TOKEN_MANAGER), "access denied");
		// verify executor has the roles they want to share
		require(isSenderInRole(_role), "no role");

		// execute role update
		PatchOwnershipNFT(_ownershipToken).updateRole(_to, _role);
	}

	/**
	 * @notice Updates XCC Token address
	 * @param _xccToken Token address
	 * @param _type token type(1: XCC-GOld/2: XCC-Silver/3: XCC-Bronze)
	 */
	function updateXccToken(address _xccToken, uint256 _type) public virtual {
		// verify executor is allowed to share token  roles
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");
		
		if (_type == 1) {
			XCC_Gold = _xccToken;
		} else if (_type == 2) {
			XCC_Silver = _xccToken;
		} else if (_type ==3 ) {
			XCC_Bronze = _xccToken;
		}
	}
		
	/**
	 * @notice Register the new Patch
	 * @param _patchName Name of Patch
	 * @param _patchDetailURI patch detail URI link
	 * @param _ownershipTokenAddr Ownership NFT token Address
	 * @param _treePlantedArea tree planted Area in metric
	 * @param _treeVolume planted tree Volume
	 * @param _initialOwner address of Patch Initial owner on which O-NFT token will be minted
	 * @param _patchGeoFenceDetails patch geo fense details
	 * @return (uint256) PatchId of newly register patch
	 */
	function registerPatch(
		string memory _patchName,
		string memory _patchDetailURI,
		uint256 _treePlantedArea,
		uint256 _treeVolume,
		address _ownershipTokenAddr,
		address _initialOwner,
		uint256[][] memory _patchGeoFenceDetails
	) public virtual returns (uint256) {

		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_PATCH_REGISTRY_MANAGER), "access denied");

		require(bytes(_patchName).length != 0, "Invalid _patchName!!");
		require(bytes(_patchDetailURI).length != 0, "Invalid _patchDetailURI!!");
		require(_ownershipTokenAddr != address(0), "Invalid _ownershipTokenAddr");
		require(_initialOwner != address(0), "Invalid _initialOwner!!");
		require(_patchGeoFenceDetails.length != 0, "Invalid _patchGeoFenceDetails!!");

		PatchInfo memory newPatch;
		newPatch.patchName = _patchName;
		newPatch.patchDetailURI = _patchDetailURI;
		newPatch.treePlantedArea = _treePlantedArea;
		newPatch.treeVolume = _treeVolume;
		newPatch.patchGeoFenceDetails = _patchGeoFenceDetails;
		newPatch.patchInitialOwner = _initialOwner;
		newPatch.ownershipTokenAddress = _ownershipTokenAddr;
		newPatch.patchRegistrationTime = block.timestamp;
		newPatch.isPatchActive = true;
		newPatch.noOfEventRegistered = 0;

		totalPatchRegistered++;
		newPatch.patchId = totalPatchRegistered;
		patchTokenList.push(_ownershipTokenAddr);

		patchTokenbyPatchID[newPatch.patchId] = _ownershipTokenAddr;
		patchIDbyPatchToken[_ownershipTokenAddr] = newPatch.patchId;

		patchDetails[newPatch.patchId] = newPatch;

		MintableERC721(_ownershipTokenAddr).mintBatch(_initialOwner, 1, 100);

		emit PatchRegistered(msg.sender,
							newPatch.patchId,
							_patchName,
							_patchDetailURI,
							_treePlantedArea,
							_treeVolume,
							_initialOwner,
							_ownershipTokenAddr,
							_patchGeoFenceDetails,
							block.timestamp);

		return totalPatchRegistered;
	}
  
	/**
	 * @notice Register the new Event
	 * @param _patchId Name of Patch
	 * @param _co2OffsetAmt CO2 Offseted in particular period of event
	 * @param _treeVolume tree volume planted on land
	 * @param _eventPeriod Recorded Event Period
	 * @param _emitedToken token address which will be release for particular event(XCC-G/XCC-S/XCC-B)
	 * @param _emittedTokenAmt emited token Amount
	 * @param _eventRegistrationTime Event registration time
	 * @param _khatamReportId Khatam report ID 
	 * @param _khatamReportURI Khatam report URI
	 */
	function registerEvent(
		uint256 _patchId,
		uint256 _co2OffsetAmt,
		uint256 _treeVolume,
		uint256 _eventPeriod,
		address _emitedToken,
		uint256 _emittedTokenAmt,
		uint256 _eventRegistrationTime,
		uint256 _khatamReportId,
		string memory _khatamReportURI
	) public virtual {

		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_PATCH_EVENT_MANAGER), "access denied");

		require(_patchId <= totalPatchRegistered,"Invalid PatchId!!");
		require(patchDetails[_patchId].isPatchActive, "Patch is In-Active!!");
		require(_co2OffsetAmt > 0, "Invalid _co2OffsetAmt!!");
		require(_eventPeriod > 0, "Invalid _eventPeriod!!");
		require(_emitedToken == XCC_Gold ||
				_emitedToken == XCC_Silver ||
				_emitedToken == XCC_Bronze, "Invalid _emitedToken!!");
		require(_emittedTokenAmt > 0 , "Invalid _emittedTokenAmt!!");
		require(_eventRegistrationTime > patchDetails[_patchId].patchRegistrationTime, "Invalid _eventRegistrationTime!!");	

		PatchEventInfo memory newEvent;
		newEvent.patchId = _patchId;
		newEvent.co2OffsetAmt = _co2OffsetAmt;
		newEvent.oldTreeVolume = patchDetails[_patchId].treeVolume;
		newEvent.newTreeVolume = _treeVolume;
		newEvent.eventPeriod = _eventPeriod;
		newEvent.emitedToken = _emitedToken;
		newEvent.emittedTokenAmt = _emittedTokenAmt;
		newEvent.eventRegistrationTime = _eventRegistrationTime;
		newEvent.khatamReportId = _khatamReportId;
		newEvent.khatamReportURI = _khatamReportURI;

		patchDetails[_patchId].noOfEventRegistered++;
		patchDetails[_patchId].totalCO2OffSet += _co2OffsetAmt;
		patchDetails[_patchId].treeVolume = _treeVolume;
		patchEventDetails[_patchId].push(newEvent);

		uint256 adminShare = (_emittedTokenAmt * adminFee) / 10000;
		XCCERC20(_emitedToken).mint(tokenDistributor, _emittedTokenAmt - adminShare);
		if (adminShare > 0){
			XCCERC20(_emitedToken).mint(treasuryWallet, adminShare);
		}
		

		emit PatchEventRegistered(msg.sender,
								_patchId,
								_co2OffsetAmt,
								_treeVolume,
								_eventPeriod,
								_emitedToken,
								_emittedTokenAmt,
								_eventRegistrationTime
							);
	}

	/**
	 * @notice Register the new Event in Batch
	 * @param _patchId Name of Patch
	 * @param _co2OffsetAmt CO2 Offseted in particular period of event
	 * @param _treeVolume tree volume planted on land
	 * @param _eventPeriod Recorded Event Period
	 * @param _emitedToken token address which will be release for particular event(XCC-G/XCC-S/XCC-B)
	 * @param _emittedTokenAmt emited token Amount
	 * @param _eventRegistrationTime Event registration time
	 * @param _khatamReportId Khatam report ID 
	 * @param _khatamReportURI Khatam report URI
	 */
	function registerEventInBatch(
		uint256[] memory _patchId,
		uint256[] memory _co2OffsetAmt,
		uint256[] memory _treeVolume,
		uint256[] memory _eventPeriod,
		address[] memory _emitedToken,
		uint256[] memory _emittedTokenAmt,
		uint256[] memory _eventRegistrationTime,
		uint256[] memory _khatamReportId,
		string[] memory _khatamReportURI
	) public virtual {
		for (uint256 i = 0; i < _patchId.length; i++) {
			registerEvent(_patchId[i],
						_co2OffsetAmt[i],
						_treeVolume[i],
						_eventPeriod[i],
						_emitedToken[i],
						_emittedTokenAmt[i],
						_eventRegistrationTime[i],
						_khatamReportId[i],
						_khatamReportURI[i]);
		}
	}


	/**
	 * @notice Update Ownership Token Base URI
	 * @param _ownershipToken Ownership Token address
	 * @param _baseURI Ownership Token base URI
	 **/
	function updateOwnershipTokenBaseURI(
		address _ownershipToken,
		string memory _baseURI
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");

		require(patchIDbyPatchToken[_ownershipToken] > 0,"Invalid ownership Token Address");
		require(patchDetails[patchIDbyPatchToken[_ownershipToken]].isPatchActive, "Patch is In-Active!!");

		PatchOwnershipNFT(_ownershipToken).setBaseURI(_baseURI);
	}

	/**
	 * @notice De-active/De-register patch
	 * @param _patchId Patch ID
	 **/
	function deactivatePatch(
		uint256 _patchId
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");

		require(_patchId <= totalPatchRegistered,"Invalid PatchId!!");
		require(patchDetails[_patchId].isPatchActive, "Patch is In-Active!!");

		patchDetails[_patchId].isPatchActive = false;

		emit PatchDeactivated(msg.sender, _patchId);
	}

	/**
	 * @notice active/Re-register patch
	 * @param _patchId Patch ID
	 **/
	function activatePatch(
		uint256 _patchId
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");

		require(_patchId <= totalPatchRegistered,"Invalid PatchId!!");
		require(!patchDetails[_patchId].isPatchActive, "Patch is Active!!");

		patchDetails[_patchId].isPatchActive = true;

		emit PatchActivated(msg.sender, _patchId);
	}

	/**
	 * @notice Updates Tree-coin treasury wallet
	 * @param _treasuryWallet New treasury wallet address
	 **/
	function updateTreasuryWallet(
		address _treasuryWallet
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");
		require(_treasuryWallet != address(0), "Invalid _treasuryWallet address!!");

		treasuryWallet = _treasuryWallet;
	}

	/**
	 * @notice Updates Tree-coin tokenDistributor wallet
	 * @param _distributorWallet New tokenDistributor wallet address
	 **/
	function updateDistributorWallet(
		address _distributorWallet
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");
		require(_distributorWallet != address(0), "Invalid _treasuryWallet address!!");

		tokenDistributor = _distributorWallet;
	}

	/**
	 * @notice Updates Tree-coin admin Fee percentage
	 * @param _adminFee admin Fee in percentage with 2 decimal Precision
	 **/
	function updateAdminFee(
		uint256 _adminFee
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");
		require(_adminFee <= 1000, "admin cann't be > 10% !!");

		adminFee = _adminFee;
	}

	/**
	 * @notice Updates Patch details
	 * @param _patchId Patch ID
	 * @param _patchName Name of Patch
	 * @param _patchDetailURI patch detail URI link
	 * @param _treePlantedArea tree planted Area in metric
	 * @param _treeVolume planted tree Volume
	 * @param _patchGeoFenceDetails patch geo fense details
	 **/
	function updatePatchDetails(
		uint256 _patchId,
		string memory _patchName,
		string memory _patchDetailURI,
		uint256 _treePlantedArea,
		uint256 _treeVolume,
		uint256[][] memory _patchGeoFenceDetails
	) public virtual {
		require(isSenderInRole(ROLE_CONFIG_MANAGER), "access denied");

		require(_patchId <= totalPatchRegistered,"Invalid PatchId!!");
		require(patchDetails[_patchId].isPatchActive, "Patch is In-Active!!");

		if (bytes(_patchName).length != 0) {
			patchDetails[_patchId].patchName = _patchName;
		}

		if (bytes(_patchDetailURI).length != 0) {
			patchDetails[_patchId].patchDetailURI = _patchDetailURI;
		}

		if (_treePlantedArea != 0) {
			patchDetails[_patchId].treePlantedArea = _treePlantedArea;
		}

		if (_treeVolume !=0 ) {
			patchDetails[_patchId].treeVolume = _treeVolume;
		}

		if (_patchGeoFenceDetails.length != 0) {
			patchDetails[_patchId].patchGeoFenceDetails = _patchGeoFenceDetails;
		}

		emit PatchDetailsUpdated(msg.sender,
							_patchId,
							_patchName,
							_patchDetailURI,
							_treePlantedArea,
							_treeVolume,
							_patchGeoFenceDetails
						);
	}

	/**
	 * @notice Get length of token address list created
	 * @return (uint256) Returns the token address list length
	 */
	function getTokenListLength() external view virtual returns (uint256) {
		return patchTokenList.length;
	}

	/**
	 * @notice Get Patch geo-fence details
	 * @param  _patchId patchId of patch
	 * @return (uint256[][]) Returns the 2-d array contain geo-fence details
	 */
	function getPatchGeoFenceDetails(uint256 _patchId) external view virtual returns (uint256[][] memory) {
		return patchDetails[_patchId].patchGeoFenceDetails;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./TinyERC721.sol";

/**
 * @title Patch Ownership NFT 
 *
 * @notice Patch Ownership NFT is an ERC721 token used as landed holding identity
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
contract PatchOwnershipNFT is TinyERC721 {

	/// @dev Bitmask representing all the possible features
	uint256 private constant FULL_FEATURE_MASK = 0xFFFF;

	/**
	 * @dev Constructs/deploys ERC721 with the name and symbol specified
	 *
	 * @param _name name of the token to be accessible as `name()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 * @param _symbol token symbol to be accessible as `symbol()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 */
	constructor(string memory _name, string memory _symbol) TinyERC721(_name, _symbol) {
		// Enable all features of Patch Ownership contract
        updateFeatures(FULL_FEATURE_MASK);	
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC721Spec.sol";
import "../interfaces/TreeCoinERC721Spec.sol";
import "../lib/AddressUtils.sol";
import "../lib/ArrayUtils.sol";
import "../lib/StringUtils.sol";
import "../lib/ECDSA.sol";
import "../utils/AccessControl.sol";

/**
 * @title Tiny ERC721
 *
 * @notice Tiny ERC721 defines an NFT with a very small (up to 32 bits) ID space.
 *      ERC721 enumeration support requires additional writes to the storage:
 *      - when transferring a token in order to update the NFT collections of
 *        the previous and next owners,
 *      - when minting/burning a token in order to update global NFT collection
 *
 * @notice Reducing NFT ID space to 32 bits allows
 *      - to eliminate the need to have and to write to two additional storage mappings
 *        (also achievable with the 48 bits ID space)
 *      - for batch minting optimization by writing 8 tokens instead of 5 at once into
 *        global/local collections
 *
 * @notice This smart contract is designed to be inherited by concrete implementations,
 *      which are expected to define token metadata, auxiliary functions to access the metadata,
 *      and explicitly define token minting interface, which should be built on top
 *      of current smart contract internal interface
 *
 * @notice Fully ERC721-compatible with all optional interfaces implemented (metadata, enumeration),
 *      see https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev ERC721: contract has passed adopted OpenZeppelin ERC721 tests
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC721/ERC721.behavior.js
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC721/extensions/ERC721URIStorage.test.js
 *
 * @dev A note on token URI: there are major differences on how token URI behaves comparing to Zeppelin impl:
 *      1. A token URI can be set for non-existing token for pre-allocation purposes,
 *         still the URI will be deleted once token is burnt
 *      2. If token URI is set, base URI has no affect on the token URI, the two are not concatenated,
 *         base URI is used to construct the token URI only if the latter was not explicitly set
 *
 * @dev Supports EIP-712 powered permits - permit() - approve() with signature.
 *      Supports EIP-712 powered operator permits - permitForAll() - setApprovalForAll() with signature.
 *
 * @dev EIP712 Domain:
 *      name: PatchERC721
 *      version: not in use, omitted (name already contains version)
 *      chainId: EIP-155 chain id
 *      verifyingContract: deployed contract address
 *      salt: permitNonces[owner], where owner is an address which allows operation on their tokens
 *
 * @dev Permit type:
 *      owner: address
 *      operator: address
 *      tokenId: uint256
 *      nonce: uint256
 *      deadline: uint256
 *
 * @dev Permit typeHash:
 *        keccak256("Permit(address owner,address operator,uint256 tokenId,uint256 nonce,uint256 deadline)")
 *
 * @dev PermitForAll type:
 *      owner: address
 *      operator: address
 *      approved: bool
 *      nonce: uint256
 *      deadline: uint256
 *
 * @dev PermitForAll typeHash:
 *        keccak256("PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)")
 *
 * @dev See https://eips.ethereum.org/EIPS/eip-712
 * @dev See usage examples in tests: erc721_permits.js
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
abstract contract TinyERC721 is ERC721Enumerable, ERC721Metadata, WithBaseURI, MintableERC721, BurnableERC721, AccessControl {
	// enable push32 optimization for uint32[]
	using ArrayUtils for uint32[];

	/**
	 * @notice ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 *
	 * @inheritdoc ERC721Metadata
	 */
	string public override name;

	/**
	 * @notice ERC-20 compatible abbreviated name for a collection of NFTs in this contract
	 *
	 * @inheritdoc ERC721Metadata
	 */
	string public override symbol;

	/**
	 * @notice Current implementation includes a function `decimals` that returns uint8(0)
	 *      to be more compatible with ERC-20
	 *
	 * @dev ERC20 compliant token decimals is equal to zero since ERC721 token is non-fungible
	 *      and therefore non-divisible
	 */
	uint8 public constant decimals = 0;

	/**
	 * @notice Ownership information for all the tokens in existence
	 *
	 * @dev Maps `Token ID => Token ID Global Index | Token ID Local Index | Token Owner Address`, where
	 *      - Token ID Global Index denotes Token ID index in the array of all the tokens,
	 *      - Token ID Local Index denotes Token ID index in the array of all the tokens owned by the owner,
	 *      - Token ID indexes are 32 bits long,
	 *      - `|` denotes bitwise concatenation of the values
	 * @dev Token Owner Address for a given Token ID is lower 160 bits of the mapping value
	 */
	mapping(uint256 => uint256) internal tokens;

	/**
	 * @notice Enumerated collections of the tokens owned by particular owners
	 *
	 * @dev We call these collections "Local" token collections
	 *
	 * @dev Maps `Token Owner Address => Owned Token IDs Array`
	 *
	 * @dev Token owner balance is the length of their token collection:
	 *      `balanceOf(owner) = collections[owner].length`
	 */
	mapping(address => uint32[]) internal collections;

	/**
	 * @notice An array of all the tokens in existence
	 *
	 * @dev We call this collection "Global" token collection
	 *
	 * @dev Array with all Token IDs, used for enumeration
	 *
	 * @dev Total token supply `tokenSupply` is the length of this collection:
	 *      `totalSupply() = allTokens.length`
	 */
	uint32[] internal allTokens;

	/**
	 * @notice Mapping from tokenId to last snap time
	 *
	 * @dev Store timestamp of transfer event of particular tokenId
	 */
    mapping(uint256 => uint256) public _lastSnap;
    
	/**
	 * @notice Mapping from tokenId to epoch index
	 *
	 * @dev Store counter of number of transfered event of 
	 *		particular tokenId
	 */
    mapping(uint256 => uint256) public _generatedEpochs;
    
	/**
	 * @notice Mapping from TokenId to epoch data of index
	 *
	 * @dev Store counter of number of transfered event of 
	 *		particular tokenId
	 */
    mapping(uint256 => mapping(uint256 => Epoch)) public _epochData;

	/**
	 * @notice Sturcture which hold token transfer details
	 *
	 * @dev Epoch Data will be used to transfer token holding time, 
	 *		based on which XCC will be distributed.
	 */
    struct Epoch {
        uint256 start;
        uint256 end;
        address HolderAddr;
    }
	
	/**
	 * @notice Addresses approved by token owners to transfer their tokens
	 *
	 * @dev `Maps Token ID => Approved Address`, where
	 *      Approved Address is an address allowed transfer ownership for the token
	 *      defined by Token ID
	 */
	mapping(uint256 => address) internal approvals;

	/**
	 * @notice Addresses approved by token owners to transfer all their tokens
	 *
	 * @dev Maps `Token Owner Address => Operator Address => Approval State` - true/false (approved/not), where
	 *      - Token Owner Address is any address which may own tokens or not,
	 *      - Operator Address is any other address which may own tokens or not,
	 *      - Approval State is a flag indicating if Operator Address is allowed to
	 *        transfer tokens owned by Token Owner Address o their behalf
	 */
	mapping(address => mapping(address => bool)) internal approvedOperators;

	/**
	 * @dev A record of nonces for signing/validating signatures in EIP-712 based
	 *      `permit` and `permitForAll` functions
	 *
	 * @dev Each time the nonce is used, it is increased by one, meaning reordering
	 *      of the EIP-712 transactions is not possible
	 *
	 * @dev Inspired by EIP-2612 extension for ERC20 token standard
	 *
	 * @dev Maps token owner address => token owner nonce
	 */
	mapping(address => uint256) public permitNonces;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public override baseURI = "";

	/**
	 * @dev Optional mapping for token URIs to be returned as is when `tokenURI()`
	 *      is called; if mapping doesn't exist for token, the URI is constructed
	 *      as `base URI + token ID`, where plus (+) denotes string concatenation
	 */
	mapping(uint256 => string) internal _tokenURIs;

	/**
	 * @dev 32 bit token ID space is optimal for batch minting in batches of size 8
	 *      8 * 32 = 256 - single storage slot in global/local collection(s)
	 */
	uint8 public constant BATCH_SIZE_MULTIPLIER = 8;

	/**
	 * @notice Enables ERC721 transfers of the tokens
	 *      (transfer by the token owner himself)
	 * @dev Feature FEATURE_TRANSFERS must be enabled in order for
	 *      `transferFrom()` function to succeed when executed by token owner
	 */
	uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

	/**
	 * @notice Enables ERC721 transfers on behalf
	 *      (transfer by someone else on behalf of token owner)
	 * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
	 *      `transferFrom()` function to succeed whe executed by approved operator
	 * @dev Token owner must call `approve()` or `setApprovalForAll()`
	 *      first to authorize the transfer on behalf
	 */
	uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0004;

	/**
	 * @notice Enables approved operators to burn tokens on behalf of their owners
	 *
	 * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
	 *      `burn()` function to succeed when called by approved operator
	 */
	uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0008;

	/**
	 * @notice Enables approvals on behalf (permits via an EIP712 signature)
	 * @dev Feature FEATURE_PERMITS must be enabled in order for
	 *      `permit()` function to succeed
	 */
	uint32 public constant FEATURE_PERMITS = 0x0000_0010;

	/**
	 * @notice Enables operator approvals on behalf (permits for all via an EIP712 signature)
	 * @dev Feature FEATURE_OPERATOR_PERMITS must be enabled in order for
	 *      `permitForAll()` function to succeed
	 */
	uint32 public constant FEATURE_OPERATOR_PERMITS = 0x0000_0020;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0004_0000;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "PatchERC721"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable DOMAIN_SEPARATOR;

	/**
	 * @notice EIP-712 permit (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Permit(address owner,address operator,uint256 tokenId,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_TYPEHASH = 0xee2282d7affd5a432b221a559e429129347b0c19a3f102179a5fb1859eef3d29;

	/**
	 * @notice EIP-712 permitForAll (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_FOR_ALL_TYPEHASH = 0x47ab88482c90e4bb94b82a947ae78fa91fb25de1469ab491f4c15b9a0a2677ee;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string _oldVal, string _newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param _tokenId token ID which URI was updated
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 _tokenId, string _oldVal, string _newVal);

	/**
	 * @dev Constructs/deploys ERC721 instance with the name and symbol specified
	 *
	 * @param _name name of the token to be accessible as `name()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 * @param _symbol token symbol to be accessible as `symbol()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 */
	constructor(string memory _name, string memory _symbol) {
		// set the name
		name = _name;

		// set the symbol
		symbol = _symbol;

		// build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		// note: we specify contract version in its name
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("PatchERC721")), block.chainid, address(this)));
	}

	/**
	 * @dev Verifies if token is transferable (i.e. can change ownership, allowed to be transferred);
	 *      The default behaviour is to always allow transfer if token exists
	 *
	 * @dev Implementations may modify the default behaviour based on token metadata
	 *      if required
	 *
	 * @param _tokenId ID of the token to check if it's transferable
	 * @return true if token is transferable, false otherwise
	 */
	function isTransferable(uint256 _tokenId) public view virtual returns(bool) {
		// validate token existence
		require(exists(_tokenId), "token doesn't exist");

		// generic implementation returns true if token exists
		return true;
	}

	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @inheritdoc MintableERC721
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) public override view returns(bool) {
		// read ownership information and return a check if it's not zero (set)
		return tokens[_tokenId] != 0;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		// construct the interface support from required and optional ERC721 interfaces
		return interfaceId == type(ERC165).interfaceId
			|| interfaceId == type(ERC721).interfaceId
			|| interfaceId == type(ERC721Metadata).interfaceId
			|| interfaceId == type(ERC721Enumerable).interfaceId
			|| interfaceId == type(MintableERC721).interfaceId
			|| interfaceId == type(BurnableERC721).interfaceId;
	}

	// ===== Start: ERC721 Metadata =====


	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @dev Returns token URI if it was previously set with `setTokenURI`,
	 *      otherwise constructs it as base URI + token ID
	 *
	 * @inheritdoc ERC721Metadata
	 */
	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		// verify token exists
		require(exists(_tokenId), "token doesn't exist");

		// read the token URI for the token specified
		string memory _tokenURI = _tokenURIs[_tokenId];

		// if token URI is set
		if(bytes(_tokenURI).length > 0) {
			// just return it
			return _tokenURI;
		}

		// if base URI is not set
		if(bytes(baseURI).length == 0) {
			// return an empty string
			return "";
		}

		// otherwise concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_tokenId, 10));
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);

		// and update token URI
		_tokenURIs[_tokenId] = _tokenURI;
	}

	// ===== End: ERC721 Metadata =====

	// ===== Start: ERC721, ERC721Enumerable Getters (view functions) =====


	/**
	 * @inheritdoc ERC721
	 */
	function balanceOf(address _owner) public view override returns (uint256) {
		// check `_owner` address is set
		require(_owner != address(0), "zero address");

		// derive owner balance for the their owned tokens collection
		// as the length of that collection
		return collections[_owner].length;
	}

	/**
	 * @inheritdoc ERC721
	 */
	function ownerOf(uint256 _tokenId) public view override returns (address) {
		// derive ownership information of the token from the ownership mapping
		// by extracting lower 160 bits of the mapping value as an address
		address owner = address(uint160(tokens[_tokenId]));

		// verify owner/token exists
		require(owner != address(0), "token doesn't exist");

		// return owner address
		return owner;
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function totalSupply() public view override returns (uint256) {
		// derive total supply value from the array of all existing tokens
		// as the length of this array
		return allTokens.length;
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function tokenByIndex(uint256 _index) public view override returns (uint256) {
		// index out of bounds check
		require(_index < totalSupply(), "index out of bounds");

		// find the token ID requested and return
		return allTokens[_index];
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view override returns (uint256) {
		// index out of bounds check
		require(_index < balanceOf(_owner), "index out of bounds");

		// find the token ID requested and return
		return collections[_owner][_index];
	}

	/**
	 * @inheritdoc ERC721
	 */
	function getApproved(uint256 _tokenId) public view override returns (address) {
		// verify token specified exists
		require(exists(_tokenId), "token doesn't exist");

		// read the approval value and return
		return approvals[_tokenId];
	}

	/**
	 * @inheritdoc ERC721
	 */
	function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
		// read the approval state value and return
		return approvedOperators[_owner][_operator];
	}

	// ===== End: ERC721, ERC721Enumerable Getters (view functions) =====

	// ===== Start: ERC721 mutative functions (transfers, approvals) =====


	/**
	 * @dev Batch Safe Transfer token ID specified
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @param _from an address from where token will transfered 
	 * @param _to an address to which token will be transfer
	 * @param _tokenId array of tokenID of the token to Transfer
	 * @param _data array of additional data with no specified format, sent in call to `_to`
	 */
	 function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenId, bytes[] memory _data) public {
		for(uint256 i = 0; i < _tokenId.length; i++){
			// Transfer token
			safeTransferFrom(_from, _to, _tokenId[i], _data[i]);
		}
	 }

	/**
	 * @inheritdoc ERC721
	 */
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
		// delegate call to unsafe transfer on behalf `transferFrom()`
		transferFrom(_from, _to, _tokenId);

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// check it supports ERC721 interface - execute onERC721Received()
			bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);

			// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
			// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
			require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
		}
	}

	/**
	 * @inheritdoc ERC721
	 */
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
		// delegate call to overloaded `safeTransferFrom()`, set data to ""
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	/**
	 * @dev Batch Transfer token ID specified
	 *
	 * @param _from an address from where token will transfered 
	 * @param _to an address to which token will be transfer
	 * @param _tokenId array of tokenID of the token to Transfer
	 */
	 function batchTransferFrom(address _from, address _to, uint256[] memory _tokenId) public {
		for(uint256 i = 0; i < _tokenId.length; i++){
			// Transfer token
			transferFrom(_from, _to, _tokenId[i]);
		}
	 } 

	/**
	 * @inheritdoc ERC721
	 */
	function transferFrom(address _from, address _to, uint256 _tokenId) public override {
		// if `_from` is equal to sender, require transfers feature to be enabled
		// otherwise require transfers on behalf feature to be enabled
		require(_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)
		     || _from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
		        _from == msg.sender? "transfers are disabled": "transfers on behalf are disabled");

		// validate destination address is set
		require(_to != address(0), "zero address");

		// validate token ownership, which also
		// validates token existence under the hood
		require(_from == ownerOf(_tokenId), "access denied");

		// verify operator (transaction sender) is either token owner,
		// or is approved by the token owner to transfer this particular token,
		// or is approved by the token owner to transfer any of his tokens
		require(_from == msg.sender || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "access denied");

		// transfer is not allowed for a locked token
		require(isTransferable(_tokenId), "locked token");

		// Register token holding Epcho
		_beforeTokenTransfer(_from, _to, _tokenId);

		// if required, move token ownership,
		// update old and new owner's token collections accordingly:
		if(_from != _to) {
			// remove token from old owner's collection (also clears approval)
			__removeLocal(_tokenId);
			// add token to the new owner's collection
			__addLocal(_tokenId, _to);
		}
		// even if no real changes are required, approval needs to be erased
		else {
			// clear token approval (also emits an Approval event)
			__clearApproval(_from, _tokenId);
		}

		// fire ERC721 transfer event
		emit Transfer(_from, _to, _tokenId);
	}

	/**
	 * @inheritdoc ERC721
	 */
	function approve(address _approved, uint256 _tokenId) public override {
		// make an internal approve - delegate to `__approve`
		__approve(msg.sender, _approved, _tokenId);
	}

	/**
	 * @dev Powers the meta transaction for `approve` - EIP-712 signed `permit`
	 *
	 * @dev Approves address called `_operator` to transfer token `_tokenId`
	 *      on behalf of the `_owner`
	 *
	 * @dev Zero `_operator` address indicates there is no approved address,
	 *      and effectively removes an approval for the token specified
	 *
	 * @dev `_owner` must own token `_tokenId` to grant the permission
	 * @dev Throws if `_operator` is a self address (`_owner`),
	 *      or if `_tokenId` doesn't exist
	 *
	 * @param _owner owner of the token `_tokenId` to set approval on behalf of
	 * @param _operator an address approved by the token owner
	 *      to spend token `_tokenId` on its behalf
	 * @param _tokenId token ID operator `_approved` is allowed to
	 *      transfer on behalf of the token owner
	 */
	function __approve(address _owner, address _operator, uint256 _tokenId) private {
		// get token owner address
		address owner = ownerOf(_tokenId);

		// approving owner address itself doesn't make sense and is not allowed
		require(_operator != owner, "self approval");

		// only token owner or/and approved operator can set the approval
		require(_owner == owner || isApprovedForAll(owner, _owner), "access denied");

		// update the approval
		approvals[_tokenId] = _operator;

		// emit an event
		emit Approval(owner, _operator, _tokenId);
	}

	/**
	 * @inheritdoc ERC721
	 */
	function setApprovalForAll(address _operator, bool _approved) public override {
		// make an internal approve - delegate to `__approveForAll`
		__approveForAll(msg.sender, _operator, _approved);
	}

	/**
	 * @dev Powers the meta transaction for `setApprovalForAll` - EIP-712 signed `permitForAll`
	 *
	 * @dev Approves address called `_operator` to transfer any tokens
	 *      on behalf of the `_owner`
	 *
	 * @dev `_owner` must not necessarily own any tokens to grant the permission
	 * @dev Throws if `_operator` is a self address (`_owner`)
	 *
	 * @param _owner owner of the tokens to set approval on behalf of
	 * @param _operator an address to add to the set of authorized operators, i.e.
	 *      an address approved by the token owner to spend tokens on its behalf
	 * @param _approved true if the operator is approved, false to revoke approval
	 */
	function __approveForAll(address _owner, address _operator, bool _approved) private {
		// approving tx sender address itself doesn't make sense and is not allowed
		require(_operator != _owner, "self approval");

		// update the approval
		approvedOperators[_owner][_operator] = _approved;

		// emit an event
		emit ApprovalForAll(_owner, _operator, _approved);
	}

	/**
	 * @dev Clears approval for a given token owned by a given owner,
	 *      emits an Approval event
	 *
	 * @dev Unsafe: doesn't check the validity of inputs (must be kept private),
	 *      assuming the check is done by the caller
	 *      - token existence
	 *      - token ownership
	 *
	 * @param _owner token owner to be logged into Approved event as is
	 * @param _tokenId token ID to erase approval for and to log into Approved event as is
	 */
	function __clearApproval(address _owner, uint256 _tokenId) internal {
		// clear token approval
		delete approvals[_tokenId];
		// emit an ERC721 Approval event:
		// "When a Transfer event emits, this also indicates that the approved
		// address for that NFT (if any) is reset to none."
		emit Approval(_owner, address(0), _tokenId);
	}

	// ===== End: ERC721 mutative functions (transfers, approvals) =====

	// ===== Start: Meta-transactions Support =====


	/**
	 * @notice Change or reaffirm the approved address for an NFT on behalf
	 *
	 * @dev Executes approve(_operator, _tokenId) on behalf of the token owner
	 *      who EIP-712 signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_tokenId` as the allowance of `_operator` over `_owner` token,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Emits `Approval` event in the same way as `approve` does
	 *
	 * @dev Requires:
	 *     - `_operator` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `permitNonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the token to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _operator new approved NFT controller
	 * @param _tokenId token ID to approve
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address _owner, address _operator, uint256 _tokenId, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
		// verify permits are enabled
		require(isFeatureEnabled(FEATURE_PERMITS), "permits are disabled");

		// derive signer of the EIP712 Permit message, and
		// update the nonce for that particular signer to avoid replay attack!!! ----------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_TYPEHASH, _owner, _operator, _tokenId, permitNonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		__approve(_owner, _operator, _tokenId);
	}

	/**
	 * @notice Enable or disable approval for a third party ("operator") to manage
	 *      all of owner's assets - on behalf
	 *
	 * @dev Executes setApprovalForAll(_operator, _approved) on behalf of the owner
	 *      who EIP-712 signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_operator` as the token operator for `_owner` tokens,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Emits `ApprovalForAll` event in the same way as `setApprovalForAll` does
	 *
	 * @dev Requires:
	 *     - `_operator` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `permitNonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the tokens to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _operator an address to add to the set of authorized operators, i.e.
	 *      an address approved by the token owner to spend tokens on its behalf
	 * @param _approved true if the operator is approved, false to revoke approval
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permitForAll(address _owner, address _operator, bool _approved, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
		// verify permits are enabled
		require(isFeatureEnabled(FEATURE_OPERATOR_PERMITS), "operator permits are disabled");

		// derive signer of the EIP712 PermitForAll message, and
		// update the nonce for that particular signer to avoid replay attack!!! --------------------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_FOR_ALL_TYPEHASH, _owner, _operator, _approved, permitNonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		__approveForAll(_owner, _operator, _approved);
	}

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	// ===== End: Meta-transactions Support =====

	// ===== Start: mint/burn support =====


	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) public override {
		// delegate to unsafe mint
		mint(_to, _tokenId);

		// make it safe: execute `onERC721Received`

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// check it supports ERC721 interface - execute onERC721Received()
			bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data);

			// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
			// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
			require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
		}
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) public override {
		// delegate to `safeMint` with empty data
		safeMint(_to, _tokenId, "");
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) public override {
		// delegate to unsafe mint
		mintBatch(_to, _tokenId, n);

		// make it safe: execute `onERC721Received`

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// onERC721Received: for each token minted
			for(uint256 i = 0; i < n; i++) {
				// check it supports ERC721 interface - execute onERC721Received()
				bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId + i, _data);

				// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
				// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
				require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
			}
		}
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) public override {
		// delegate to `safeMint` with empty data
		safeMintBatch(_to, _tokenId, n, "");
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) public override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// verify the inputs

		// verify destination address is set
		require(_to != address(0), "zero address");
		// verify the token ID is "tiny" (32 bits long at most)
		require(uint32(_tokenId) == _tokenId, "token ID overflow");

		// verify token doesn't yet exist
		require(!exists(_tokenId), "already minted");

		// Register token holding Epcho
		_beforeTokenTransfer(address(0), _to, _tokenId);

		// create token ownership record,
		// add token to `allTokens` and new owner's collections
		// add token to both local and global collections (enumerations)
		__addToken(_tokenId, _to);

		// fire ERC721 transfer event
		emit Transfer(address(0), _to, _tokenId);
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) public override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// verify the inputs

		// verify destination address is set
		require(_to != address(0), "zero address");
		// verify n is set properly
		require(n > 1, "n is too small");
		// verify the token ID is "tiny" (32 bits long at most)
		require(uint32(_tokenId) == _tokenId, "token ID overflow");
		require(uint32(_tokenId + n - 1) == _tokenId + n - 1, "n-th token ID overflow");

		// verification: for each token to be minted
		for(uint256 i = 0; i < n; i++) {
			// verify token doesn't yet exist
			require(!exists(_tokenId + i), "already minted");

			// Register token holding Epcho
			_beforeTokenTransfer(address(0), _to, _tokenId + i);
		}

		// create token ownership records,
		// add tokens to `allTokens` and new owner's collections
		// add tokens to both local and global collections (enumerations)
		__addTokens(_to, _tokenId, n);

		// events: for each token minted
		for(uint256 i = 0; i < n; i++) {
			// fire ERC721 transfer event
			emit Transfer(address(0), _to, _tokenId + i);
		}
	}

	/**
	 * @dev Destroys the token with token ID specified
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) public override {
		// read token owner data
		// verifies token exists under the hood
		address _from = ownerOf(_tokenId);

		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// if `_from` is equal to sender, require own burns feature to be enabled
			// otherwise require burns on behalf feature to be enabled
			require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
			     || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
			        _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

			// verify sender is either token owner, or approved by the token owner to burn tokens
			require(_from == msg.sender || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "access denied");
		}

		// Register token holding Epcho
		_beforeTokenTransfer(msg.sender, address(0x0), _tokenId);

		// remove token ownership record (also clears approval),
		// remove token from both local and global collections
		__removeToken(_tokenId);

		// delete token URI mapping
		delete _tokenURIs[_tokenId];

		// fire ERC721 transfer event
		emit Transfer(_from, address(0), _tokenId);
	}

	// ===== End: mint/burn support =====

	// ===== Start: Epcho Data support =====

	/**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * @dev Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 *
	 * @param _from old owner address of token
	 * @param _to new owner address to add token to
	 * @param _tokenId token ID to add
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {
		if (_from != _to) {
			_epochData[_tokenId][_generatedEpochs[_tokenId]] = Epoch(_lastSnap[_tokenId], block.timestamp, _from);
			_generatedEpochs[_tokenId]++;
			_lastSnap[_tokenId] = block.timestamp;
		}
    }

	// ===== End: Epcho Data support =====

	// ----- Start: auxiliary internal/private functions -----

	/**
	 * @dev Adds token to the new owner's collection (local),
	 *      used internally to transfer existing tokens, to mint new
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to add
	 * @param _to new owner address to add token to
	 */
	function __addLocal(uint256 _tokenId, address _to) internal virtual {
		// get a reference to the collection where token goes to
		uint32[] storage destination = collections[_to];

		// update local index and ownership, do not change global index
		tokens[_tokenId] = tokens[_tokenId]
			//  |unused |global | local | ownership information (address)      |
			& 0x00000000FFFFFFFF000000000000000000000000000000000000000000000000
			| uint192(destination.length) << 160 | uint160(_to);

		// push token into the local collection
		destination.push(uint32(_tokenId));
	}

	/**
	 * @dev Add token to both local and global collections (enumerations),
	 *      used internally to mint new tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to add
	 * @param _to new owner address to add token to
	 */
	function __addToken(uint256 _tokenId, address _to) internal virtual {
		// get a reference to the collection where token goes to
		uint32[] storage destination = collections[_to];

		// update token global and local indexes, ownership
		tokens[_tokenId] = uint224(allTokens.length) << 192 | uint192(destination.length) << 160 | uint160(_to);

		// push token into the collection
		destination.push(uint32(_tokenId));

		// push it into the global `allTokens` collection (enumeration)
		allTokens.push(uint32(_tokenId));
	}

	/**
	 * @dev Add tokens to both local and global collections (enumerations),
	 *      used internally to mint new tokens in batches
	 *
	 * @dev Token IDs to be added: [_tokenId, _tokenId + n)
	 *      n is expected to be greater or equal 2, but this is not checked
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _to new owner address to add token to
	 * @param _tokenId first token ID to add
	 * @param n how many tokens to add, sequentially increasing the _tokenId
	 */
	function __addTokens(address _to, uint256 _tokenId, uint256 n) internal virtual {
		// get a reference to the collection where tokens go to
		uint32[] storage destination = collections[_to];

		// for each token to be added
		for(uint256 i = 0; i < n; i++) {
			// update token global and local indexes, ownership
			tokens[_tokenId + i] = uint224(allTokens.length + i) << 192 | uint192(destination.length + i) << 160 | uint160(_to);
		}

		// push tokens into the local collection
		destination.push32(uint32(_tokenId), uint32(n));
		// push tokens into the global `allTokens` collection (enumeration)
		allTokens.push32(uint32(_tokenId), uint32(n));
	}

	/**
	 * @dev Removes token from owner's local collection,
	 *      used internally to transfer or burn existing tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to remove
	 */
	function __removeLocal(uint256 _tokenId) internal virtual {
		// read token data, containing global and local indexes, owner address
		uint256 token = tokens[_tokenId];

		// get a reference to the token's owner collection (local)
		uint32[] storage source = collections[address(uint160(token))];

		// token index within the collection
		uint32 i = uint32(token >> 160);

		// get an ID of the last token in the collection
		uint32 sourceId = source[source.length - 1];

		// if the token we're to remove from the collection is not the last one,
		// we need to move last token in the collection into index `i`
		if(i != source.length - 1) {
			// we put the last token in the collection to the position released

			// update last token local index to point to proper place in the collection
			// preserve global index and ownership info
			tokens[sourceId] = tokens[sourceId]
				//  |unused |global | local | ownership information (address)      |
				& 0x00000000FFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
				| uint192(i) << 160;

			// put it into the position `i` within the collection
			source[i] = sourceId;
		}

		// trim the collection by removing last element
		source.pop();

		// clear token approval (also emits an Approval event)
		__clearApproval(address(uint160(token)), _tokenId);
	}

	/**
	 * @dev Removes token from both local and global collections (enumerations),
	 *      used internally to burn existing tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to remove
	 */
	function __removeToken(uint256 _tokenId) internal virtual {
		// remove token from owner's (local) collection first
		__removeLocal(_tokenId);

		// token index within the global collection
		uint32 i = uint32(tokens[_tokenId] >> 192);

		// delete the token
		delete tokens[_tokenId];

		// get an ID of the last token in the collection
		uint32 lastId = allTokens[allTokens.length - 1];

		// if the token we're to remove from the collection is not the last one,
		// we need to move last token in the collection into index `i`
		if(i != allTokens.length - 1) {
			// we put the last token in the collection to the position released

			// update last token global index to point to proper place in the collection
			// preserve local index and ownership info
			tokens[lastId] = tokens[lastId]
				//  |unused |global | local | ownership information (address)      |
				& 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
				| uint224(i) << 192;

			// put it into the position `i` within the collection
			allTokens[i] = lastId;
		}

		// trim the collection by removing last element
		allTokens.pop();
	}

	// ----- End: auxiliary internal/private functions -----
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC1363Spec.sol";
import "../interfaces/EIP2612.sol";
import "../interfaces/EIP3009.sol";
import "../utils/AccessControl.sol";
import "../lib/AddressUtils.sol";
import "../lib/ECDSA.sol";

/**
 * @title XCC ERC20 Token
 *
 * @notice XCC is the native utility token of the TreeCoin Protocol.
 *
 * @notice Token Summary:
 *      - Symbol: XCC
 *      - Name: XCC
 *      - Decimals: 18
 *      - Initial/maximum total supply:  // TODO: [DEFINE]
 *      - Initial supply holder (initial holder) address: // TODO: [DEFINE]
 *		- Mintable: XCC token will be mintable by Patch-Factory Contract
 *      - Burnable: existing tokens may get destroyed, total supply may decrease
 *
 * @dev Smart contract doesn't use safe math. All arithmetic operations are overflow/underflow safe.
 *      Additionally, Solidity 0.8.7 enforces overflow/underflow safety.
 *
 * @dev Reviewed
 *      ERC-20   - according to https://eips.ethereum.org/EIPS/eip-20
 *      ERC-1363 - according to https://eips.ethereum.org/EIPS/eip-1363
 *      EIP-2612 - according to https://eips.ethereum.org/EIPS/eip-2612
 *      EIP-3009 - according to https://eips.ethereum.org/EIPS/eip-3009
 *
 * @dev Reference implementations "used":
 *      - Atomic allowance:    https://github.com/OpenZeppelin/openzeppelin-contracts
 *      - Unlimited allowance: https://github.com/0xProject/protocol
 *                             https://github.com/OpenZeppelin/openzeppelin-contracts
 *      - ERC-1363:            https://github.com/vittominacori/erc1363-payable-token
 *      - EIP-2612:            https://github.com/Uniswap/uniswap-v2-core
 *      - EIP-3009:            https://github.com/centrehq/centre-tokens
 *                             https://github.com/CoinbaseStablecoin/eip-3009
 *      - Meta transactions:   https://github.com/0xProject/protocol
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
contract XCCERC20 is ERC1363, EIP2612, EIP3009, AccessControl {

	/**
	 * @notice Name of the token:
	 *
	 * @notice ERC20 name of the token (long name)
	 *
	 * @dev ERC20 `function name() public view returns (string)`
	 *
	 * @dev Field is declared public: getter name() is created when compiled,
	 *      it returns the name of the token.
	 */
	string public name;

	/**
	 * @notice Symbol of the token
	 *
	 * @notice ERC20 symbol of that token (short name)
	 *
	 * @dev ERC20 `function symbol() public view returns (string)`
	 *
	 * @dev Field is declared public: getter symbol() is created when compiled,
	 *      it returns the symbol of the token
	 */
	string public symbol;

	/**
	 * @notice Decimals of the token: 18
	 *
	 * @dev ERC20 `function decimals() public view returns (uint8)`
	 *
	 * @dev Field is declared public: getter decimals() is created when compiled,
	 *      it returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `6`, a balance of `1,500,000` tokens should
	 *      be displayed to a user as `1,5` (`1,500,000 / 10 ** 6`).
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including balanceOf() and transfer().
	 */
	uint8 public constant decimals = 18;

	/**
	 * @notice Total supply of the token: initially 10,000,000,000,
	 *      with the potential to decline over time as some tokens may get burnt but not minted
	 *
	 * @dev ERC20 `function totalSupply() public view returns (uint256)`
	 *
	 * @dev Field is declared public: getter totalSupply() is created when compiled,
	 *      it returns the amount of tokens in existence.
	 */
	uint256 public override totalSupply;

	/**
	 * @dev A record of all the token balances
	 * @dev This mapping keeps record of all token owners:
	 *      owner => balance
	 */
	mapping(address => uint256) private tokenBalances;

	/**
	 * @dev A record of nonces for signing/validating signatures in EIP-2612 `permit`
	 *
	 * @dev Note: EIP2612 doesn't imply a possibility for nonce randomization like in EIP-3009
	 *
	 * @dev Maps delegate address => delegate nonce
	 */
	mapping(address => uint256) public override nonces;

	/**
	 * @dev A record of used nonces for EIP-3009 transactions
	 *
	 * @dev A record of used nonces for signing/validating signatures
	 *      in `delegateWithAuthorization` for every delegate
	 *
	 * @dev Maps authorizer address => nonce => true/false (used unused)
	 */
	mapping(address => mapping(bytes32 => bool)) private usedNonces;

	/**
	 * @notice A record of all the allowances to spend tokens on behalf
	 * @dev Maps token owner address to an address approved to spend
	 *      some tokens on behalf, maps approved address to that amount
	 * @dev owner => spender => value
	 */
	mapping(address => mapping(address => uint256)) private transferAllowances;

	/**
	 * @notice Enables ERC20 transfers of the tokens
	 *      (transfer by the token owner himself)
	 * @dev Feature FEATURE_TRANSFERS must be enabled in order for
	 *      `transfer()` function to succeed
	 */
	uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

	/**
	 * @notice Enables ERC20 transfers on behalf
	 *      (transfer by someone else on behalf of token owner)
	 * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
	 *      `transferFrom()` function to succeed
	 * @dev Token owner must call `approve()` first to authorize
	 *      the transfer on behalf
	 */
	uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

	/**
	 * @dev Defines if the default behavior of `transfer` and `transferFrom`
	 *      checks if the receiver smart contract supports ERC20 tokens
	 * @dev When feature FEATURE_UNSAFE_TRANSFERS is enabled the transfers do not
	 *      check if the receiver smart contract supports ERC20 tokens,
	 *      i.e. `transfer` and `transferFrom` behave like `unsafeTransferFrom`
	 * @dev When feature FEATURE_UNSAFE_TRANSFERS is disabled (default) the transfers
	 *      check if the receiver smart contract supports ERC20 tokens,
	 *      i.e. `transfer` and `transferFrom` behave like `transferFromAndCall`
	 */
	uint32 public constant FEATURE_UNSAFE_TRANSFERS = 0x0000_0004;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

	/**
	 * @notice Enables approved operators to burn tokens on behalf of their owners
	 *
	 * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
	 *      `burn()` function to succeed when called by approved operator
	 */
	uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

	/**
	 * @notice Enables ERC-1363 transfers with callback
	 * @dev Feature FEATURE_ERC1363_TRANSFERS must be enabled in order for
	 *      ERC-1363 `transferFromAndCall` functions to succeed
	 */
	uint32 public constant FEATURE_ERC1363_TRANSFERS = 0x0000_0020;

	/**
	 * @notice Enables ERC-1363 approvals with callback
	 * @dev Feature FEATURE_ERC1363_APPROVALS must be enabled in order for
	 *      ERC-1363 `approveAndCall` functions to succeed
	 */
	uint32 public constant FEATURE_ERC1363_APPROVALS = 0x0000_0040;

	/**
	 * @notice Enables approvals on behalf (EIP2612 permits
	 *      via an EIP712 signature)
	 * @dev Feature FEATURE_EIP2612_PERMITS must be enabled in order for
	 *      `permit()` function to succeed
	 */
	uint32 public constant FEATURE_EIP2612_PERMITS = 0x0000_0080;

	/**
	 * @notice Enables meta transfers on behalf (EIP3009 transfers
	 *      via an EIP712 signature)
	 * @dev Feature FEATURE_EIP3009_TRANSFERS must be enabled in order for
	 *      `transferWithAuthorization()` function to succeed
	 */
	uint32 public constant FEATURE_EIP3009_TRANSFERS = 0x0000_0100;

	/**
	 * @notice Enables meta transfers on behalf (EIP3009 transfers
	 *      via an EIP712 signature)
	 * @dev Feature FEATURE_EIP3009_RECEPTIONS must be enabled in order for
	 *      `receiveWithAuthorization()` function to succeed
	 */
	uint32 public constant FEATURE_EIP3009_RECEPTIONS = 0x0000_0200;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice ERC20 receivers are allowed to receive tokens without ERC20 safety checks,
	 *      which may be useful to simplify tokens transfers into "legacy" smart contracts
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled addresses having
	 *      `ROLE_ERC20_RECEIVER` permission are allowed to receive tokens
	 *      via `transfer` and `transferFrom` functions in the same way they
	 *      would via `unsafeTransferFrom` function
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_RECEIVER` permission
	 *      doesn't affect the transfer behaviour since
	 *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
	 * @dev ROLE_ERC20_RECEIVER is a shortening for ROLE_UNSAFE_ERC20_RECEIVER
	 */
	uint32 public constant ROLE_ERC20_RECEIVER = 0x0004_0000;

	/**
	 * @notice ERC20 senders are allowed to send tokens without ERC20 safety checks,
	 *      which may be useful to simplify tokens transfers into "legacy" smart contracts
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled senders having
	 *      `ROLE_ERC20_SENDER` permission are allowed to send tokens
	 *      via `transfer` and `transferFrom` functions in the same way they
	 *      would via `unsafeTransferFrom` function
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_SENDER` permission
	 *      doesn't affect the transfer behaviour since
	 *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
	 * @dev ROLE_ERC20_SENDER is a shortening for ROLE_UNSAFE_ERC20_SENDER
	 */
	uint32 public constant ROLE_ERC20_SENDER = 0x0008_0000;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "XCC-G"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable override DOMAIN_SEPARATOR;

	/**
	 * @notice EIP-712 permit (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	/**
	 * @notice EIP-712 TransferWithAuthorization (EIP-3009) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

	/**
	 * @notice EIP-712 ReceiveWithAuthorization (EIP-3009) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

	/**
	 * @notice EIP-712 CancelAuthorization (EIP-3009) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
	bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

	/**
	 * @dev Fired in mint() function
	 *
	 * @param by an address which minted some tokens (transaction sender)
	 * @param to an address the tokens were minted to
	 * @param value an amount of tokens minted
	 */
	event Minted(address indexed by, address indexed to, uint256 value);

	/**
	 * @dev Fired in burn() function
	 *
	 * @param by an address which burned some tokens (transaction sender)
	 * @param from an address the tokens were burnt from
	 * @param value an amount of tokens burnt
	 */
	event Burnt(address indexed by, address indexed from, uint256 value);

	/**
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Similar to ERC20 Transfer event, but also logs an address which executed transfer
	 *
	 * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
	 *
	 * @param by an address which performed the transfer
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed by, address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Similar to ERC20 Approve event, but also logs old approval value
	 *
	 * @dev Fired in approve(), increaseAllowance(), decreaseAllowance() functions,
	 *      may get fired in transfer functions
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param oldValue previously granted amount of tokens to transfer on behalf
	 * @param value new granted amount of tokens to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 oldValue, uint256 value);

	/**
	 * @dev Deploys the token smart contract,
	 *      assigns initial token supply to the address specified
	 * @param _name name of the token to be accessible as `name()`,
	 * @param _symbol token symbol to be accessible as `symbol()`,
	 */
	constructor(string memory _name, string memory _symbol) {

		// name of the token
		name = _name;
		// token symbol
		symbol = _symbol;

		// build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		// note: we specify contract version in its name
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("XCC")), block.chainid, address(this)));
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface(s) and super interface(s) (if any)
		return interfaceId == type(ERC165).interfaceId
		    || interfaceId == type(ERC20).interfaceId
		    || interfaceId == type(ERC1363).interfaceId
		    || interfaceId == type(EIP2612).interfaceId
		    || interfaceId == type(EIP3009).interfaceId;
	}

	// ===== Start: ERC-1363 functions =====

	/**
	 * @notice Transfers some tokens and then executes `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return true unless throwing
	 */
	function transferAndCall(address _to, uint256 _value) public override returns (bool) {
		// delegate to `transferFromAndCall` passing `msg.sender` as `_from`
		return transferFromAndCall(msg.sender, _to, _value);
	}

	/**
	 * @notice Transfers some tokens and then executes `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onTransferReceived call to `_to`
	 * @return true unless throwing
	 */
	function transferAndCall(address _to, uint256 _value, bytes memory _data) public override returns (bool) {
		// delegate to `transferFromAndCall` passing `msg.sender` as `_from`
		return transferFromAndCall(msg.sender, _to, _value, _data);
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to` and then executes `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return true unless throwing
	 */
	function transferFromAndCall(address _from, address _to, uint256 _value) public override returns (bool) {
		// delegate to `transferFromAndCall` passing empty data param
		return transferFromAndCall(_from, _to, _value, "");
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to` and then executes a `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onTransferReceived call to `_to`
	 * @return true unless throwing
	 */
	function transferFromAndCall(address _from, address _to, uint256 _value, bytes memory _data) public override returns (bool) {
		// ensure ERC-1363 transfers are enabled
		require(isFeatureEnabled(FEATURE_ERC1363_TRANSFERS), "ERC1363 transfers are disabled");

		// first delegate call to `unsafeTransferFrom` to perform the unsafe token(s) transfer
		unsafeTransferFrom(_from, _to, _value);

		// after the successful transfer - check if receiver supports
		// ERC1363Receiver and execute a callback handler `onTransferReceived`,
		// reverting whole transaction on any error
		_notifyTransferred(_from, _to, _value, _data, false);

		// function throws on any error, so if we're here - it means operation successful, just return true
		return true;
	}

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner, then executes a `onApprovalReceived` callback on `_spender`
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Caller must not necessarily own any tokens to grant the permission
	 *
	 * @dev Throws if `_spender` is an EOA or a smart contract which doesn't support ERC1363Spender interface
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approveAndCall(address _spender, uint256 _value) public override returns (bool) {
		// delegate to `approveAndCall` passing empty data
		return approveAndCall(_spender, _value, "");
	}

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner, then executes a callback on `_spender`
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Caller must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onApprovalReceived call to `_spender`
	 * @return success true on success, throws otherwise
	 */
	function approveAndCall(address _spender, uint256 _value, bytes memory _data) public override returns (bool) {
		// ensure ERC-1363 approvals are enabled
		require(isFeatureEnabled(FEATURE_ERC1363_APPROVALS), "ERC1363 approvals are disabled");

		// execute regular ERC20 approve - delegate to `approve`
		approve(_spender, _value);

		// after the successful approve - check if receiver supports
		// ERC1363Spender and execute a callback handler `onApprovalReceived`,
		// reverting whole transaction on any error
		_notifyApproved(_spender, _value, _data);

		// function throws on any error, so if we're here - it means operation successful, just return true
		return true;
	}

	/**
	 * @dev Auxiliary function to invoke `onTransferReceived` on a target address
	 *      The call is not executed if the target address is not a contract; in such
	 *      a case function throws if `allowEoa` is set to false, succeeds if it's true
	 *
	 * @dev Throws on any error; returns silently on success
	 *
	 * @param _from representing the previous owner of the given token value
	 * @param _to target address that will receive the tokens
	 * @param _value the amount mount of tokens to be transferred
	 * @param _data [optional] data to send along with the call
	 * @param allowEoa indicates if function should fail if `_to` is an EOA
	 */
	function _notifyTransferred(address _from, address _to, uint256 _value, bytes memory _data, bool allowEoa) private {
		// if recipient `_to` is EOA
		if (!AddressUtils.isContract(_to)) {
			// ensure EOA recipient is allowed
			require(allowEoa, "EOA recipient");

			// exit if successful
			return;
		}

		// otherwise - if `_to` is a contract - execute onTransferReceived
		bytes4 response = ERC1363Receiver(_to).onTransferReceived(msg.sender, _from, _value, _data);

		// expected response is ERC1363Receiver(_to).onTransferReceived.selector
		// bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
		require(response == ERC1363Receiver(_to).onTransferReceived.selector, "invalid onTransferReceived response");
	}

	/**
	 * @dev Auxiliary function to invoke `onApprovalReceived` on a target address
	 *      The call is not executed if the target address is not a contract; in such
	 *      a case function throws if `allowEoa` is set to false, succeeds if it's true
	 *
	 * @dev Throws on any error; returns silently on success
	 *
	 * @param _spender the address which will spend the funds
	 * @param _value the amount of tokens to be spent
	 * @param _data [optional] data to send along with the call
	 */
	function _notifyApproved(address _spender, uint256 _value, bytes memory _data) private {
		// ensure recipient is not EOA
		require(AddressUtils.isContract(_spender), "EOA spender");

		// otherwise - if `_to` is a contract - execute onApprovalReceived
		bytes4 response = ERC1363Spender(_spender).onApprovalReceived(msg.sender, _value, _data);

		// expected response is ERC1363Spender(_to).onApprovalReceived.selector
		// bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
		require(response == ERC1363Spender(_spender).onApprovalReceived.selector, "invalid onApprovalReceived response");
	}
	// ===== End: ERC-1363 functions =====

	// ===== Start: ERC20 functions =====

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @inheritdoc ERC20
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) public view override returns (uint256 balance) {
		// read the balance and return
		return tokenBalances[_owner];
	}

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) public override returns (bool success) {
		// just delegate call to `transferFrom`,
		// `FEATURE_TRANSFERS` is verified inside it
		return transferFrom(msg.sender, _to, _value);
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
		// depending on `FEATURE_UNSAFE_TRANSFERS` we execute either safe (default)
		// or unsafe transfer
		// if `FEATURE_UNSAFE_TRANSFERS` is enabled
		// or receiver has `ROLE_ERC20_RECEIVER` permission
		// or sender has `ROLE_ERC20_SENDER` permission
		if(isFeatureEnabled(FEATURE_UNSAFE_TRANSFERS)
			|| isOperatorInRole(_to, ROLE_ERC20_RECEIVER)
			|| isSenderInRole(ROLE_ERC20_SENDER)) {
			// we execute unsafe transfer - delegate call to `unsafeTransferFrom`,
			// `FEATURE_TRANSFERS` is verified inside it
			unsafeTransferFrom(_from, _to, _value);
		}
		// otherwise - if `FEATURE_UNSAFE_TRANSFERS` is disabled
		// and receiver doesn't have `ROLE_ERC20_RECEIVER` permission
		else {
			// we execute safe transfer - delegate call to `safeTransferFrom`, passing empty `_data`,
			// `FEATURE_TRANSFERS` is verified inside it
			safeTransferFrom(_from, _to, _value, "");
		}

		// both `unsafeTransferFrom` and `safeTransferFrom` throw on any error, so
		// if we're here - it means operation successful,
		// just return true
		return true;
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to` and then executes `onTransferReceived` callback
	 *      on the receiver if it is a smart contract (not an EOA)
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onTransferReceived call to `_to` in case if its a smart contract
	 * @return true unless throwing
	 */
	function safeTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) public returns (bool) {
		// first delegate call to `unsafeTransferFrom` to perform the unsafe token(s) transfer
		unsafeTransferFrom(_from, _to, _value);

		// after the successful transfer - check if receiver supports
		// ERC1363Receiver and execute a callback handler `onTransferReceived`,
		// reverting whole transaction on any error
		_notifyTransferred(_from, _to, _value, _data, true);

		// function throws on any error, so if we're here - it means operation successful, just return true
		return true;
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev In contrast to `transferFromAndCall` doesn't check recipient
	 *      smart contract to support ERC20 tokens (ERC1363Receiver)
	 * @dev Designed to be used by developers when the receiver is known
	 *      to support ERC20 tokens but doesn't implement ERC1363Receiver interface
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 * @dev Returns silently on success, throws otherwise
	 *
	 * @param _from token sender, token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to token receiver, an address to transfer tokens to
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 */
	function unsafeTransferFrom(address _from, address _to, uint256 _value) public {
		// make an internal transferFrom - delegate to `__transferFrom`
		__transferFrom(msg.sender, _from, _to, _value);
	}

	/**
	 * @dev Powers the meta transactions for `unsafeTransferFrom` - EIP-3009 `transferWithAuthorization`
	 *      and `receiveWithAuthorization`
	 *
	 * @dev See `unsafeTransferFrom` and `transferFrom` soldoc for details
	 *
	 * @param _by an address executing the transfer, it can be token owner itself,
	 *      or an operator previously approved with `approve()`
	 * @param _from token sender, token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to token receiver, an address to transfer tokens to
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 */
	function __transferFrom(address _by, address _from, address _to, uint256 _value) private {
		// if `_from` is equal to sender, require transfers feature to be enabled
		// otherwise require transfers on behalf feature to be enabled
		require(_from == _by && isFeatureEnabled(FEATURE_TRANSFERS)
		     || _from != _by && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
		        _from == _by? "transfers are disabled": "transfers on behalf are disabled");

		// non-zero source address check - Zeppelin
		// obviously, zero source address is a client mistake
		// it's not part of ERC20 standard but it's reasonable to fail fast
		// since for zero value transfer transaction succeeds otherwise
		require(_from != address(0), "transfer from the zero address");

		// non-zero recipient address check
		require(_to != address(0), "transfer to the zero address");

		// sender and recipient cannot be the same
		require(_from != _to, "sender and recipient are the same (_from = _to)");

		// sending tokens to the token smart contract itself is a client mistake
		require(_to != address(this), "invalid recipient (transfer to the token smart contract itself)");

		// according to ERC-20 Token Standard, https://eips.ethereum.org/EIPS/eip-20
		// "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
		if(_value == 0) {
			// emit an ERC20 transfer event
			emit Transfer(_from, _to, _value);

			// don't forget to return - we're done
			return;
		}

		// no need to make arithmetic overflow check on the _value - by design of mint()

		// in case of transfer on behalf
		if(_from != _by) {
			// read allowance value - the amount of tokens allowed to transfer - into the stack
			uint256 _allowance = transferAllowances[_from][_by];

			// verify sender has an allowance to transfer amount of tokens requested
			require(_allowance >= _value, "transfer amount exceeds allowance");

			// we treat max uint256 allowance value as an "unlimited" and
			// do not decrease allowance when it is set to "unlimited" value
			if(_allowance < type(uint256).max) {
				// update allowance value on the stack
				_allowance -= _value;

				// update the allowance value in storage
				transferAllowances[_from][_by] = _allowance;

				// emit an improved atomic approve event
				emit Approval(_from, _by, _allowance + _value, _allowance);

				// emit an ERC20 approval event to reflect the decrease
				emit Approval(_from, _by, _allowance);
			}
		}

		// verify sender has enough tokens to transfer on behalf
		require(tokenBalances[_from] >= _value, "transfer amount exceeds balance");

		// perform the transfer:
		// decrease token owner (sender) balance
		tokenBalances[_from] -= _value;

		// increase `_to` address (receiver) balance
		tokenBalances[_to] += _value;

		// emit an improved transfer event (arXiv:1907.00903)
		emit Transfer(_by, _from, _to, _value);

		// emit an ERC20 transfer event
		emit Transfer(_from, _to, _value);
	}

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) public override returns (bool success) {
		// make an internal approve - delegate to `__approve`
		__approve(msg.sender, _spender, _value);

		// operation successful, return true
		return true;
	}

	/**
	 * @dev Powers the meta transaction for `approve` - EIP-2612 `permit`
	 *
	 * @dev Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the `_owner`
	 *
	 * @dev `_owner` must not necessarily own any tokens to grant the permission
	 * @dev Throws if `_spender` is a zero address
	 *
	 * @param _owner owner of the tokens to set approval on behalf of
	 * @param _spender an address approved by the token owner
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 */
	function __approve(address _owner, address _spender, uint256 _value) private {
		// non-zero spender address check - Zeppelin
		// obviously, zero spender address is a client mistake
		// it's not part of ERC20 standard but it's reasonable to fail fast
		require(_spender != address(0), "approve to the zero address");

		// read old approval value to emmit an improved event (arXiv:1907.00903)
		uint256 _oldValue = transferAllowances[_owner][_spender];

		// perform an operation: write value requested into the storage
		transferAllowances[_owner][_spender] = _value;

		// emit an improved atomic approve event (arXiv:1907.00903)
		emit Approval(_owner, _spender, _oldValue, _value);

		// emit an ERC20 approval event
		emit Approval(_owner, _spender, _value);
	}

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
		// read the value from storage and return
		return transferAllowances[_owner][_spender];
	}

	// ===== End: ERC20 functions =====

	// ===== Start: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903) =====

	/**
	 * @notice Increases the allowance granted to `spender` by the transaction sender
	 *
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Throws if value to increase by is zero or too big and causes arithmetic overflow
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens to increase by
	 * @return success true on success, throws otherwise
	 */
	function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
		// read current allowance value
		uint256 currentVal = transferAllowances[msg.sender][_spender];

		// non-zero _value and arithmetic overflow check on the allowance
		unchecked {
			// put operation into unchecked block to display user-friendly overflow error message for Solidity 0.8+
			require(currentVal + _value > currentVal, "zero value approval increase or arithmetic overflow");
		}

		// delegate call to `approve` with the new value
		return approve(_spender, currentVal + _value);
	}

	/**
	 * @notice Decreases the allowance granted to `spender` by the caller.
	 *
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Throws if value to decrease by is zero or is greater than currently allowed value
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens to decrease by
	 * @return success true on success, throws otherwise
	 */
	function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
		// read current allowance value
		uint256 currentVal = transferAllowances[msg.sender][_spender];

		// non-zero _value check on the allowance
		require(_value > 0, "zero value approval decrease");

		// verify allowance decrease doesn't underflow
		require(currentVal >= _value, "ERC20: decreased allowance below zero");

		// delegate call to `approve` with the new value
		return approve(_spender, currentVal - _value);
	}

	// ===== End: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903) =====

	// ===== Start: Minting/burning extension =====

	/**
	 * @dev Mints (creates) some tokens to address specified
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @dev Throws on overflow, if totalSupply + _value doesn't fit into uint256
	 *
	 * @param _to an address to mint tokens to
	 * @param _value an amount of tokens to mint (create)
	 */
	function mint(address _to, uint256 _value) public {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// non-zero recipient address check
		require(_to != address(0), "zero address");

		// non-zero _value and arithmetic overflow check on the total supply
		// this check automatically secures arithmetic overflow on the individual balance
		unchecked {
			// put operation into unchecked block to display user-friendly overflow error message for Solidity 0.8+
			require(totalSupply + _value > totalSupply, "zero value or arithmetic overflow");
		}

		// uint192 overflow check (required by voting delegation)
		require(totalSupply + _value <= type(uint192).max, "total supply overflow (uint192)");

		// perform mint:
		// increase total amount of tokens value
		totalSupply += _value;

		// increase `_to` address balance
		tokenBalances[_to] += _value;

		// fire a minted event
		emit Minted(msg.sender, _to, _value);

		// emit an improved transfer event (arXiv:1907.00903)
		emit Transfer(msg.sender, address(0), _to, _value);

		// fire ERC20 compliant transfer event
		emit Transfer(address(0), _to, _value);
	}

	/**
	 * @dev Burns (destroys) some tokens from the address specified
	 *
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _from an address to burn some tokens from
	 * @param _value an amount of tokens to burn (destroy)
	 */
	function burn(address _from, uint256 _value) public {
		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// if `_from` is equal to sender, require own burns feature to be enabled
			// otherwise require burns on behalf feature to be enabled
			require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
			     || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
			        _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

			// in case of burn on behalf
			if(_from != msg.sender) {
				// read allowance value - the amount of tokens allowed to be burnt - into the stack
				uint256 _allowance = transferAllowances[_from][msg.sender];

				// verify sender has an allowance to burn amount of tokens requested
				require(_allowance >= _value, "burn amount exceeds allowance");

				// we treat max uint256 allowance value as an "unlimited" and
				// do not decrease allowance when it is set to "unlimited" value
				if(_allowance < type(uint256).max) {
					// update allowance value on the stack
					_allowance -= _value;

					// update the allowance value in storage
					transferAllowances[_from][msg.sender] = _allowance;

					// emit an improved atomic approve event (arXiv:1907.00903)
					emit Approval(msg.sender, _from, _allowance + _value, _allowance);

					// emit an ERC20 approval event to reflect the decrease
					emit Approval(_from, msg.sender, _allowance);
				}
			}
		}

		// at this point we know that either sender is ROLE_TOKEN_DESTROYER or
		// we burn own tokens or on behalf (in latest case we already checked and updated allowances)
		// we have left to execute balance checks and burning logic itself

		// non-zero burn value check
		require(_value != 0, "zero value burn");

		// non-zero source address check - Zeppelin
		require(_from != address(0), "burn from the zero address");

		// verify `_from` address has enough tokens to destroy
		// (basically this is a arithmetic overflow check)
		require(tokenBalances[_from] >= _value, "burn amount exceeds balance");

		// perform burn:
		// decrease `_from` address balance
		tokenBalances[_from] -= _value;

		// decrease total amount of tokens value
		totalSupply -= _value;

		// fire a burnt event
		emit Burnt(msg.sender, _from, _value);

		// emit an improved transfer event (arXiv:1907.00903)
		emit Transfer(msg.sender, _from, address(0), _value);

		// fire ERC20 compliant transfer event
		emit Transfer(_from, address(0), _value);
	}

	// ===== End: Minting/burning extension =====

	// ===== Start: EIP-2612 functions =====

	/**
	 * @inheritdoc EIP2612
	 *
	 * @dev Executes approve(_spender, _value) on behalf of the owner who EIP-712
	 *      signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_value` as the allowance of `_spender` over `_owner` tokens,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Inherits the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *      vulnerability in the same way as ERC20 `approve`, use standard ERC20 workaround
	 *      if this might become an issue:
	 *      https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
	 *
	 * @dev Emits `Approval` event(s) in the same way as `approve` does
	 *
	 * @dev Requires:
	 *     - `_spender` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `nonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the tokens to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _spender an address approved by the token owner
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address _owner, address _spender, uint256 _value, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public override {
		// verify permits are enabled
		require(isFeatureEnabled(FEATURE_EIP2612_PERMITS), "EIP2612 permits are disabled");

		// derive signer of the EIP712 Permit message, and
		// update the nonce for that particular signer to avoid replay attack!!! --------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		__approve(_owner, _spender, _value);
	}

	// ===== End: EIP-2612 functions =====

	// ===== Start: EIP-3009 functions =====

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Checks if specified nonce was already used
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte values
	 *      unique to the authorizer's address
	 *
	 * @dev Alias for usedNonces(authorizer, nonce)
	 *
	 * @param _authorizer an address to check nonce for
	 * @param _nonce a nonce to check
	 * @return true if the nonce was used, false otherwise
	 */
	function authorizationState(address _authorizer, bytes32 _nonce) public override view returns (bool) {
		// simply return the value from the mapping
		return usedNonces[_authorizer][_nonce];
	}

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Execute a transfer with a signed authorization
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _value amount to be transferred
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function transferWithAuthorization(
		address _from,
		address _to,
		uint256 _value,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		// ensure EIP-3009 transfers are enabled
		require(isFeatureEnabled(FEATURE_EIP3009_TRANSFERS), "EIP3009 transfers are disabled");

		// derive signer of the EIP712 TransferWithAuthorization message
		address signer = __deriveSigner(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _value, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// delegate call to `__transferFrom` - execute the logic required
		__transferFrom(signer, _from, _to, _value);
	}

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Receive a transfer with a signed authorization from the payer
	 *
	 * @dev This has an additional check to ensure that the payee's address
	 *      matches the caller of this function to prevent front-running attacks.
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _value amount to be transferred
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function receiveWithAuthorization(
		address _from,
		address _to,
		uint256 _value,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		// verify EIP3009 receptions are enabled
		require(isFeatureEnabled(FEATURE_EIP3009_RECEPTIONS), "EIP3009 receptions are disabled");

		// derive signer of the EIP712 ReceiveWithAuthorization message
		address signer = __deriveSigner(abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _value, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");
		require(_to == msg.sender, "access denied");

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// delegate call to `__transferFrom` - execute the logic required
		__transferFrom(signer, _from, _to, _value);
	}

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Attempt to cancel an authorization
	 *
	 * @param _authorizer transaction authorizer
	 * @param _nonce unique random nonce to cancel (mark as used)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function cancelAuthorization(
		address _authorizer,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		// derive signer of the EIP712 ReceiveWithAuthorization message
		address signer = __deriveSigner(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, _authorizer, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _authorizer, "invalid signature");

		// cancel the nonce supplied (verify, mark as used, emit event)
		__useNonce(_authorizer, _nonce, true);
	}

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	/**
	 * @dev Auxiliary function to use/cancel the nonce supplied for a given authorizer:
	 *      1. Verifies the nonce was not used before
	 *      2. Marks the nonce as used
	 *      3. Emits an event that the nonce was used/cancelled
	 *
	 * @dev Set `_cancellation` to false (default) to use nonce,
	 *      set `_cancellation` to true to cancel nonce
	 *
	 * @dev It is expected that the nonce supplied is a randomly
	 *      generated uint256 generated by the client
	 *
	 * @param _authorizer an address to use/cancel nonce for
	 * @param _nonce random nonce to use
	 * @param _cancellation true to emit `AuthorizationCancelled`, false to emit `AuthorizationUsed` event
	 */
	function __useNonce(address _authorizer, bytes32 _nonce, bool _cancellation) private {
		// verify nonce was not used before
		require(!usedNonces[_authorizer][_nonce], "invalid nonce");

		// update the nonce state to "used" for that particular signer to avoid replay attack
		usedNonces[_authorizer][_nonce] = true;

		// depending on the usage type (use/cancel)
		if(_cancellation) {
			// emit an event regarding the nonce cancelled
			emit AuthorizationCanceled(_authorizer, _nonce);
		}
		else {
			// emit an event regarding the nonce used
			emit AuthorizationUsed(_authorizer, _nonce);
		}
	}

	// ===== End: EIP-3009 functions =====
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Upgradeable Access Control List // ERC1967Proxy
 *
 * @notice Access control smart contract provides an API to check
 *      if a specific operation is permitted globally and/or
 *      if a particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable public functions
 *      of the smart contract (used by a wide audience).
 * @notice User roles are designed to control the access to restricted functions
 *      of the smart contract (used by a limited set of maintainers).
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @dev This is an upgradeable version of the ACL, based on Zeppelin implementation for ERC1967,
 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
 *      see https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
 *
 * @author Unblock Technolabs (Vijay Bhayani)
 */
// TODO: add version history: 2018-2021
abstract contract UpgradeableAccessControl is UUPSUpgradeable {
	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
	 *      the amount of storage used by a contract always adds up to the 50.
	 *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;

	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @notice Upgrade manager is responsible for smart contract upgrades,
	 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
	 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
	 *
	 * @dev Role ROLE_UPGRADE_MANAGER allows passing the _authorizeUpgrade() check
	 * @dev Role ROLE_UPGRADE_MANAGER has single bit at position 254 enabled
	 */
	uint256 public constant ROLE_UPGRADE_MANAGER = 0x4000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @dev UUPS initializer, sets the contract owner to have full privileges
	 *
	 * @dev Can be executed only in constructor during deployment,
	 *      reverts when executed in already deployed contract
	 *
	 * @dev IMPORTANT:
	 *      this function MUST be executed during proxy deployment (in proxy constructor),
	 *      otherwise it renders useless and cannot be executed at all,
	 *      resulting in no admin control over the proxy and no possibility to do future upgrades
	 *
	 * @param _owner smart contract owner having full privileges
	 */
	function _postConstruct(address _owner) internal virtual initializer {
		// ensure this function is execute only in constructor
		require(!AddressUpgradeable.isContract(address(this)), "invalid context");

		// grant owner full privileges
		userRoles[_owner] = FULL_PRIVILEGES_MASK;

		// fire an event
		emit RoleUpdated(msg.sender, _owner, FULL_PRIVILEGES_MASK, FULL_PRIVILEGES_MASK);
	}

	/**
	 * @notice Returns an address of the implementation smart contract,
	 *      see ERC1967Upgrade._getImplementation()
	 *
	 * @return the current implementation address
	 */
	function getImplementation() public view virtual returns (address) {
		// delegate to `ERC1967Upgrade._getImplementation()`
		return _getImplementation();
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns (uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns (uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns (bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns (bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns (bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns (bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}

	/**
	 * @inheritdoc UUPSUpgradeable
	 */
	function _authorizeUpgrade(address) internal virtual override {
		// caller must have a permission to upgrade the contract
		require(isSenderInRole(ROLE_UPGRADE_MANAGER), "access denied");
	}
}