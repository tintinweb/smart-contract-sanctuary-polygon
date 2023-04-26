// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
library StorageSlot {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Caller must be an admin
error OnlyAdmin();
/// @notice Caller cannot remove themselves as admin
error SelfRemoval();

/// @title Shoply Admin Control
contract AdminControl {

    mapping(address => bool) public isAdmin;

    /// @notice Emitted when an admin is added
    /// @param admin The address of the admin
    event AdminAdded(address indexed admin);
    /// @notice Emitted when an admin is removed
    /// @param admin The address of the admin
    event AdminRemoved(address indexed admin);

    modifier onlyAdmin() {
        if (!isAdmin[msg.sender]) {
            revert OnlyAdmin();
        }
        _;
    }

    /// @notice Adds an admin
    /// @dev Emits an AdminAdded event
    /// @param _admin The address of the admin
    function addAdmin(address _admin) external onlyAdmin {
        _addAdmin(_admin);
    }

    /// @notice Removes an admin
    /// @dev Emits an AdminRemoved event
    /// @param _admin The address of the admin to remove
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == msg.sender) {
            revert SelfRemoval();
        }
        isAdmin[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function _addAdmin(address _admin) internal {
        isAdmin[_admin] = true;
        emit AdminAdded(_admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IStoreDeployer.sol";

import { StoreProxy } from "./StoreProxy.sol";

/// @title Shoply Store Deployer
contract StoreDeployer is IStoreDeployer {
    struct Parameters {
        address storeFactory;
        address contractRegistry;
        bytes32 storeName;
        address acceptedCurrency;
    }

    /// @notice The store creation parameters
    Parameters public override parameters;

    /// @dev Deploys a store with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the store.
    /// @param contractRegistry The contract address of the Shoply contract registry
    /// @param storeName The name of the store
    /// @param acceptedCurrency The store's accepted currency
    function _deploy(
        address storeFactory,
        address contractRegistry,
        bytes32 storeName,
        address acceptedCurrency,
        address implementation
    ) internal returns (address store) {
        parameters = Parameters({storeFactory: storeFactory, contractRegistry: contractRegistry, storeName: storeName, acceptedCurrency: acceptedCurrency});
        store = address(new StoreProxy{salt: keccak256(abi.encode(storeName))}
        (implementation, abi.encodeWithSignature("init()")));
        delete parameters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IStoreFactory.sol";
import { AdminControl } from "../access/AdminControl.sol";
import { IContractRegistry } from "./interfaces/IContractRegistry.sol";
import { IDomainRegistry } from "./interfaces/IDomainRegistry.sol";
import { IVersionManager } from "./interfaces/IVersionManager.sol";
import { StoreDeployer } from "./StoreDeployer.sol";
import { IStoreTiers } from "./interfaces/IStoreTiers.sol";

/// @title Shoply Store Factory
contract StoreFactory is IStoreFactory, StoreDeployer, AdminControl, ReentrancyGuard {

    /// @notice The contract registry address
    IContractRegistry public contractRegistry;

    /// @notice Mapping of created stores
    mapping(address => bool) public isStore;
    /// @notice Mapping of store names to store addresses
    mapping(bytes32 => address) public storeAddress;
    /// @notice Mapping of roles granted for a store
    mapping (address => mapping(address => mapping(bytes32 => bool))) public roles;

    constructor() {
        _addAdmin(msg.sender);
    }

    /// @notice Creates a new store
    /// @param storeName The name of the store
    /// @param acceptedCurrency The store's accepted currency
    /// @return store The address of the store
    function createStore(bytes32 storeName, address acceptedCurrency, address referrer, uint256 version) external returns (address store) {
        if (referrer == msg.sender) {
            revert InvalidReferrer();
        }
        address storeOwner = IDomainRegistry(contractRegistry.addressOf("DomainRegistry")).domainOwner(storeName);
        if (storeOwner != msg.sender) {
            revert NotDomainOwner();
        }
        
        if (acceptedCurrency == address(0)) {
            revert InvalidCurrency();
        }

        string memory versionName = IVersionManager(contractRegistry.addressOf("VersionManager")).getVersionAtIndex(version);

        (, IVersionManager.Status status, IVersionManager.BugLevel bugLevel, address implementation,) = IVersionManager(contractRegistry.addressOf("VersionManager")).getVersionDetails(versionName);

        if (status == IVersionManager.Status.DEPRECATED || bugLevel != IVersionManager.BugLevel.NONE) {
            revert VersionInactive();
        }

        store = _createStore(storeName, acceptedCurrency, implementation, referrer);
    }

    /// @notice Sets the contract registry
    /// @param _contractRegistry The address of the contract registry
    function setContractRegistry(address _contractRegistry) external onlyAdmin {
        if (_contractRegistry == address(0)) {
            revert InvalidAddress();
        }
        contractRegistry = IContractRegistry(_contractRegistry);
        emit ContractRegistrySet(_contractRegistry);
    }

    /// @notice Updates a role for a user
    /// @dev Can only be called by a store
    /// @param role The role to update
    /// @param user The user to update the role for
    /// @param status Whether the user has the role
    function updateRole(bytes32 role, address user, bool status) external {
        if (!isStore[msg.sender]) {
            revert NotStore();
        }
        roles[msg.sender][user][role] = status;
        emit RoleUpdated(msg.sender, role, user, status);
    }

    /// @notice Checks if `user` has `role` in `store`
    /// @param store The store address
    /// @param user The user address
    /// @param role The role
    /// @return status Whether the user has the role in the store
    function hasRole(address store, bytes32 role, address user) external view returns (bool status) {
        return roles[store][user][role];
    }

    function _createStore(bytes32 storeName, address acceptedCurrency, address implementation, address referrer) internal returns (address store) {
        if (address(contractRegistry) == address(0)) {
            revert InvalidAddress();
        }
        store = _deploy(address(this), address(contractRegistry), storeName, acceptedCurrency, implementation);
        // Save store referrer for referral bonus
        IStoreTiers storeTiers = IStoreTiers(contractRegistry.addressOf("StoreTiers"));
        storeTiers.setStoreReferrer(store, referrer);
        storeTiers.setInitialMonth(store);

        storeAddress[storeName] = store;
        isStore[store] = true;
        emit StoreCreated(store, storeName);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title Shoply Store Proxy
contract StoreProxy is ERC1967Proxy {
    constructor (address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ZeroAddress();
error InvalidAddress();
error InvalidName();
/// @notice Input arrays must be the same length
error InvalidArrayLengths();

/// @dev Contract Registry interface
interface IContractRegistry {

    /// @notice Emitted when an address pointed to by a contract name is modified
    /// @param contractName The contract name
    /// @param contractAddress The contract address
    event AddressUpdate(bytes32 indexed contractName, address contractAddress);
    
    /// @notice Emitted when the fee address is set
    /// @param feeAddress The fee address
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when price data feeds are set
    /// @param tokens An array of tokens
    /// @param feeds An array of data feeds
    event PriceDataFeedsSet(address[] tokens, address[] feeds);

    /// @notice Emitted when the wrapped native address is set
    /// @param wrappedNative The wrapped native address (e.g. weth)
    event WrappedNativeSet(address wrappedNative);

    function addressOf(bytes32 contractName) external view returns (address);
    function feeAddress() external view returns (address);
    function priceDataFeed(address token) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Interface for the Shoply Domain Registry
/// @dev Domain Registry interface
interface IDomainRegistry {

    /// Function can only be called by the domain owner
    error OnlyDomainOwner();
    /// Function can only be called by an admin
    error OnlyAdmin();
    /// The domain is already registered
    error DomainAlreadyRegistered();
    /// Domain transfers are not allowed
    error TransferNotAllowed();
    /// Price oracle returned an invalid price (<= 0)
    error DomainPriceOracleError();
    /// Cannot register domain with empty name
    error InvalidDomain();
    /// Fee address cannot be the zero address
    error InvalidFeeAddress();
    /// Fee token cannot be the zero address
    error InvalidFeeToken();
    /// Fee token oracle cannot be the zero address
    error InvalidFeeTokenOracle();
    /// Input arrays must have the same length
    error InvalidArrays();

    /// @notice Emitted when a domain is registered
    /// @param domain The domain
    /// @param owner The domain owner
    event DomainRegistered(bytes32 indexed domain, address indexed owner);

    /// @notice Emitted when the fee address is changed
    /// @param feeAddress The new fee address
    event FeeAddressChanged(address indexed feeAddress);

    /// @notice Emitted when the fee token is changed
    /// @param feeToken The new fee token
    /// @param feeTokenDecimals The new fee token decimals
    event FeeTokenChanged(address indexed feeToken, uint8 feeTokenDecimals);

    /// @notice Emitted when the fee token oracle is changed
    /// @param feeTokenOracle The new fee token oracle
    event FeeTokenOracleChanged(address indexed feeTokenOracle);

    /// @notice Emitted when the domain price is changed
    /// @param domainPrice The new domain price
    event DomainPriceChanged(uint256 domainPrice);
    
    function domainOwner(bytes32 domain) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// Interface for the Shoply store deployer
interface IStoreDeployer {

    function parameters() external view returns (
        address storeFactory,
        address contractRegistry,
        bytes32 storeName,
        address acceptedCurrency
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Contract Registry cannot be the zero address
error InvalidAddress();

/// @notice Caller is not the domain owner
error NotDomainOwner();

/// @notice Accepted currency cannot be address zero
error InvalidCurrency();

/// @notice Referrer cannot be address zero or the store owner
error InvalidReferrer();

/// @notice Sender is not a valid store address
error NotStore();

/// @notice Store version is inactive
error VersionInactive();

/// @title Interface for the Shoply store factory
interface IStoreFactory {

    /// @notice Emitted when a store is created
    /// @param store The address of the store
    /// @param domain The domain of the store
    event StoreCreated(address indexed store, bytes32 indexed domain);

    /// @notice Emitted when the contract registry is set
    /// @param contractRegistry The contract registry address
    event ContractRegistrySet(address indexed contractRegistry);

    /// @notice Emitted when a role is granted
    /// @param store The store address
    /// @param role The role
    /// @param account The account
    /// @param hasRole The role status
    event RoleUpdated(address indexed store, bytes32 indexed role, address indexed account, bool hasRole);
    
    function updateRole(bytes32 role, address account, bool hasRole) external;
    function isStore(address store) external view returns (bool status);
    function hasRole(address store, bytes32 role, address user) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Not a valid store
error InvalidStore();
/// @notice The fee address cannot be the zero address
error InvalidFeeAddress();
/// @notice Store Factory cannot be the zero address
error InvalidStoreFactory();
/// @notice Intervals cannot be greater than 12
error InvalidIntervals();
/// @notice The fee token is not supported
error InvalidFeeToken();
/// @notice No allowance for the given discount code
error InvalidDiscountCode();
/// @notice Array lengths are not equal
error InvalidArrayLengths();
/// @notice Payment Failed
error PaymentFailed();
/// @notice Eth Transfer Failed
error EthTransferFailed();

/// @title The interface for the StoreTiers contract
interface IStoreTiers {

    /// @notice Emitted when the fee address is set
    /// @param feeAddress The address of the store platform fee recipient
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when a store platform fee is paid
    /// @param store The address of the store
    /// @param user The address of the user paying the fee
    /// @param intervals The number of 30 day intervals paid
    /// @param tier The tier of the store
    event StorePlatformFeePaid(address indexed store, address indexed user,uint256 intervals, uint256 tier);

    /// @notice Emitted when the story factory is set
    /// @param storeFactory The address of the store factory
    event StoreFactorySet(address storeFactory);

    /// @notice Emitted when a store tier is set
    /// @param store The address of the store
    /// @param tier The new store tier
    /// @param expiration The new store expiration
    event StoreTierSet(address indexed store, uint8 indexed tier, uint256 indexed expiration);

    /// @notice Emitted when a tier cost is set
    /// @param tier The tier
    /// @param cost The cost of the tier
    event TierCostSet(uint8 indexed tier, uint256 indexed cost);

    /// @notice Emitted when a store referrer is set
    /// @param store The address of the store
    /// @param referrer The address of the referrer
    event StoreReferrerSet(address indexed store, address indexed referrer);

    /// @notice Emitted when a referral fee is paid
    /// @param store The address of the store
    /// @param referrer The address of the referrer
    /// @param amount The amount of the referral fee
    event ReferralFeePaid(address indexed store, address indexed referrer, uint256 amount);

    /// @notice Emitted when a fee token is set
    /// @param feeToken The address of the fee token
    /// @param priceFeed The address of the price feed
    event FeeTokenSet(address indexed feeToken, address indexed priceFeed);

    /// @notice Emitted when the contract registry is set
    /// @param contractRegistry The address of the contract registry
    event ContractRegistrySet(address contractRegistry);

    /// @notice Emitted when a store duration is increased without platform fee payment
    /// @param store The address of the store
    /// @param intervals The number of intervals added
    event AdminStoreDurationIncreased(address indexed store, uint256 indexed intervals);

    /// @notice Emitted when discount codes are added
    /// @param hashedCodes The hashed codes
    /// @param discounts The discounts
    event HashedDiscountCodesAdded(bytes32[] hashedCodes, uint256[] discounts);

    /// @notice Emitted when a tier active product limit is set
    /// @param tier The tier
    /// @param activeProductLimit The active product limit for store's in the tier
    event TierActiveProductLimitSet(uint8 indexed tier, uint256 indexed activeProductLimit);

    /// @notice Emitted when new features are added for store tiers
    /// @param tiers An array of tiers
    /// @param features An array of features
    event TierFeaturesAdded(uint8[] tiers, bytes32[] features);

    /// @notice Emitted when features are removed from store tiers
    /// @param tiers An array of tiers
    /// @param features An array of features
    event TierFeaturesRemoved(uint8[] tiers, bytes32[] features);

    function setInitialMonth(address store) external;
    function setStoreReferrer(address store, address referrer) external;
    function setStoreTier(uint8 _tier) external;
    function hasFeature(address store, bytes32 feature) external view returns (bool);
    function storeTiers(address store) external view returns (uint8);
    function activeProductLimit(address store) external view returns (uint256);
    function storeExpiration(address store) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Interface for Shoply Version Manager
/// @dev Version Manager for Shoply Stores
interface IVersionManager {
    /// @notice parameter cannot be the zero address
    error ZeroAddress();
    /// @notice contract is not registered
    error ContractNotRegistered();
    /// @notice version is not registered
    error VersionNotRegistered();
    /// @notice version name cannot be the empty string
    error InvalidVersionName();
    /// @notice contract name cannot be the empty string
    error InvalidContractName();
    /// @notice implementation must be a contract
    error InvalidImplementation();
    /// @notice version is already registered
    error VersionAlreadyRegistered();

    /// @dev Signifies the status of a version
    enum Status {BETA, RC, PRODUCTION, DEPRECATED}

    /// @dev Indicated the highest level of bug found in the version
    enum BugLevel {NONE, LOW, MEDIUM, HIGH, CRITICAL}

    /// @dev A struct to encode version details
    struct Version {
        // the version number string ex. "v1.0"
        string versionName;

        Status status;

        BugLevel bugLevel;
        // the address of the instantiation of the version
        address implementation;
        // the date when this version was registered with the contract
        uint256 dateAdded;
    }

    event VersionAdded(
        string versionName,
        address indexed implementation
    );

    event VersionUpdated(
        string versionName,
        Status status,
        BugLevel bugLevel
    );

    event VersionRecommended(string versionName);

    event RecommendedVersionRemoved();

    function addVersion(
        string calldata versionName,
        Status status,
        address implementation
    ) external;

    function updateVersion(
        string calldata versionName,
        Status status,
        BugLevel bugLevel
    ) external;

    function markRecommendedVersion(
        string calldata versionName
    ) external;

    function removeRecommendedVersion() external;

    function getRecommendedVersion() external view returns (
            string memory versionName,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
    );

    function getVersionCount() external view returns (uint256 count);

    function getVersionAtIndex(uint256 index)
        external
        view
        returns (string memory versionName);

    function getVersionAddress(uint256 index) external view returns (address);

    function getVersionDetails(
        string calldata versionName
    )
        external
        view
        returns (
            string memory versionString,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
        );
}