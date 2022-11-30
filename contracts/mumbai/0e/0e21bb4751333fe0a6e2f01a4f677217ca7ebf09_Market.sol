/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.15;

/// All the arctic contracts that get deployed.

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

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

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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

interface IAccessControlledAndUpgradeable {
  function ADMIN_ROLE() external returns (bytes32);
}

// import "forge-std/console2.sol";

abstract contract AccessControlledAndUpgradeable is Initializable, AccessControlUpgradeable, UUPSUpgradeable, IAccessControlledAndUpgradeable {
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @notice Initializes the contract when called by parent initializers.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init(address initialAdmin) internal onlyInitializing {
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _AccessControlledAndUpgradeable_init_unchained(initialAdmin);
  }

  /// @notice Initializes the contract for contracts that already call both __AccessControl_init
  ///         and _UUPSUpgradeable_init when initializing.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init_unchained(address initialAdmin) internal {
    require(initialAdmin != address(0));
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(UPGRADER_ROLE, initialAdmin);
  }

  /// @notice Authorizes an upgrade to a new address.
  /// @dev Can only be called by addresses wih UPGRADER_ROLE
  function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}
}

contract AccessControlledAndUpgradeableModifiers is AccessControlledAndUpgradeable {
  modifier adminOnly() virtual {
    _checkRole(ADMIN_ROLE, msg.sender);
    _;
  }
}

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

/// @notice this is an exact copy/paste of the Proxy contract from the OpenZeppelin library, only difference is that it is NON-PAYABLE!
///         unfortunately there is no way to override a payable function to be nonPayable - see: https://github.com/ethereum/solidity/issues/11253

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
abstract contract ProxyNonPayable {
  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internal call site, it will return directly to the external caller.
   */
  //slither-disable-next-line assembly-usage
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
  fallback() external virtual {
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

interface IMarketCommon {
  // TODO: streamline this struct, maybe all that is needed is `latestExecutedEpochIndex`??
  struct EpochInfo {
    uint32 latestExecutedEpochIndex;
    // Reference to Chainlink Index
    uint80 latestExecutedOracleRoundId; // TODO: check if storing this is more gas costly than verifying it each time with the orocle manager.
  }

  enum PoolType {
    SHORT,
    LONG,
    FLOAT,
    LAST // useful for getting last element of enum, commonly used in cpp/c also eg: https://stackoverflow.com/a/2102615
  }

  struct BatchedActions {
    uint128 paymentToken_deposit;
    uint128 poolToken_redeem;
  }

  // TODO: This is meant to be static config, now that we are using leverage as a dynamic variable, maybe we should pack it with poolValue?
  struct PoolFixedConfig {
    address token;
    int96 leverage;
  }

  // TODO think how to pack this more efficiently
  struct Pool {
    uint256 value;
    // first element is for even epochs and second element for odd epochs
    BatchedActions[2] batchedAmount;
    PoolFixedConfig fixedConfig;
  }

  // TODO: think how to pack this.
  struct UserAction {
    uint32 correspondingEpoch;
    uint112 amount;
    uint112 nextEpochAmount;
  }

  // TODO: it is likely we don't want to use this struct anymore.
  struct ValueChangeAndFunding {
    int256 valueChange;
    int256[2] fundingAmount;
    uint256 underBalancedSideType;
    int256 floatPoolLeverage;
  }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface AggregatorV3InterfaceS {
  struct LatestRoundData {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
  }

  function latestRoundData() external view returns (LatestRoundData memory);

  function getRoundData(uint80 data) external view returns (LatestRoundData memory);
}

// Depolyed on polygon at: https://polygonscan.com/address/0xcb3a66ed5f43eb3676826597fa49b47ba9d8df81#readContract
contract MultiPriceGetter {
  function searchForEarliestIndex(AggregatorV3InterfaceS oracle, uint80 earliestKnownOracleIndex)
    public
    view
    returns (uint80 earliestOracleIndex, uint256 numberOfOracleUpdatesScanned)
  {
    AggregatorV3InterfaceS.LatestRoundData memory correctResult = oracle.getRoundData(earliestKnownOracleIndex);

    // Can see if searching 1,000,000 entries is fine or too much for the node
    for (; numberOfOracleUpdatesScanned < 1_000_000; ++numberOfOracleUpdatesScanned) {
      AggregatorV3InterfaceS.LatestRoundData memory currentResult = oracle.getRoundData(--earliestKnownOracleIndex);

      // Check if there was a 'phase change' AND the `_currentOracleUpdateTimestamp` is zero.
      if ((correctResult.roundId >> 64) != (earliestKnownOracleIndex >> 64) && correctResult.answer == 0) {
        // Check 5 phase changes at maximum.
        for (int256 phaseChangeChecker = 0; phaseChangeChecker < 5 && correctResult.answer == 0; ++phaseChangeChecker) {
          // startId = (((startId >> 64) + 1) << 64) | uint80(uint64(startId));
          earliestKnownOracleIndex -= (1 << 64); // ie add 2^64

          currentResult = oracle.getRoundData(earliestKnownOracleIndex);
        }
      }

      if (correctResult.answer == 0) {
        break;
      }

      correctResult = currentResult;
    }

    earliestOracleIndex = correctResult.roundId;
  }

  function getRoundDataMulti(
    AggregatorV3InterfaceS oracle,
    uint80 startId,
    uint256 numberToFetch
  ) public view returns (AggregatorV3InterfaceS.LatestRoundData[] memory result) {
    result = new AggregatorV3InterfaceS.LatestRoundData[](numberToFetch);
    AggregatorV3InterfaceS.LatestRoundData memory latestRoundData = oracle.latestRoundData();

    for (uint256 i = 0; i < numberToFetch && startId <= latestRoundData.roundId; ++i) {
      result[i] = oracle.getRoundData(startId);

      // Check if there was a 'phase change' AND the `_currentOracleUpdateTimestamp` is zero.
      if ((latestRoundData.roundId >> 64) != (startId >> 64) && result[i].answer == 0) {
        // NOTE: if the phase changes, then we want to correct the phase of the update.
        //       There is no guarantee that the phaseID won't increase multiple times in a short period of time (hence the while loop).
        //       But chainlink does promise that it will be sequential.
        while (result[i].answer == 0) {
          // startId = (((startId >> 64) + 1) << 64) | uint80(uint64(startId));
          startId += (1 << 64); // ie add 2^64

          result[i] = oracle.getRoundData(startId);
        }
      }
      ++startId;
    }
  }
}

// TODO: can probably remove this import - temporarily here for refactor work

/*
 * Manages price feeds from different oracle implementations.
 */
interface IOracleManagerFixedEpoch {
  error EmptyArrayOfIndexes();

  error InvalidOracleExecutionRoundId(uint80 oracleRoundId);

  error InvalidOraclePrice(int256 oraclePrice);

  function chainlinkOracle() external view returns (AggregatorV3Interface);

  function oracleDecimals() external view returns (uint8);

  function initialEpochStartTimestamp() external view returns (uint256);

  function EPOCH_LENGTH() external view returns (uint256);

  function MINIMUM_EXECUTION_WAIT_THRESHOLD() external view returns (uint256);

  function getCurrentEpochIndex() external view returns (uint256);

  function getEpochStartTimestamp() external view returns (uint256);

  function validateAndReturnMissedEpochInformation(
    uint32 _latestExecutedEpochIndex,
    uint80 latestExecutedOracleIndex,
    uint80[] memory oracleRoundIdsToExecute
  ) external view returns (int256 previousPrice, int256[] memory prices);
}

interface IRegistry {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event RegistryArctic(address admin);

  event SeparateMarketCreated(string name, string symbol, address market, uint32 marketIndex);

  function separateMarketContracts(uint32) external view returns (address);

  function latestMarket() external view returns (uint32);

  function gems() external view returns (address);

  function marketUpdateIndex(uint32) external view returns (uint256);
}

interface IMarketExtendedCore is IMarketCommon {
  struct SinglePoolInitInfo {
    string name;
    string symbol;
    PoolType poolType;
    uint8 poolTier;
    address token;
    uint96 leverage;
  }
  // Without this struct we get stack to deep errors. Grouping the data helps!
  struct InitializePoolsParams {
    SinglePoolInitInfo[] initPools;
    uint256 initialEffectiveLiquidityToSeedEachPool;
    address seederAndAdmin;
    uint32 _marketIndex;
    address oracleManager;
    address liquidityManager;
  }

  enum ConfigType {
    marketOracleUpdate,
    fundingRateMultiplier
  }

  struct OracleUpdate {
    IOracleManagerFixedEpoch prevOracle;
    IOracleManagerFixedEpoch newOracle;
  }
  struct FundingRateUpdate {
    uint256 prevMultiplier;
    uint256 newMultiplier;
  }

  event ConfigChange(ConfigType indexed configChangeType, bytes data);

  event MintingPauseChange(bool isPaused);

  event SeparateMarketLaunchedAndSeeded(
    uint32 marketIndex,
    address admin,
    address oracleManager,
    address liquidityManager,
    address paymentToken,
    int256 initialAssetPrice
  );

  event TierAdded(SinglePoolInitInfo newTier, uint256 initialSeed);

  function initializePools(InitializePoolsParams memory params) external returns (bool);

  function updateMarketOracle(OracleUpdate memory oracleConfig) external;

  function gems() external view returns (address);

  function registry() external view returns (IRegistry);

  function pauseMinting() external;

  function unpauseMinting() external;

  function changeMarketFundingRateMultiplier(FundingRateUpdate memory fundingRateConfig) external;
}

interface IMarketExtendedView is IMarketCommon {
  function get_mintingPaused() external view returns (bool);

  function get_marketDeprecated() external view returns (bool);

  function getSeederAddress() external view returns (address);

  function getPoolTokenAddress(IMarketCommon.PoolType poolType, uint256 index) external view returns (address);

  function get_maxPercentChange() external view returns (int256);

  function get_fundingRateMultiplier_e18() external view returns (uint256);

  function get_even_batchedAmountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256);

  function get_odd_batchedAmountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256);

  function get_even_batchedAmountPoolToken_redeem(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256);

  function get_odd_batchedAmountPoolToken_redeem(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256);

  function get_effectiveLiquidityForPoolType() external view returns (uint128[2] memory);
}

interface IMarketExtended is IMarketExtendedCore, IMarketExtendedView {}

interface IMarketTieredLeverageCore is IAccessControlledAndUpgradeable {
  // custom errors

  error MintingPaused();

  error MarketDeprecated();

  error InvalidAddress(address invalidAddress);

  error InvalidActionAmount(uint112 amount);

  error MarketStale(uint32 currentEpoch, uint32 latestExecutedEpoch);

  // events

  event Deposit(uint8 indexed poolId, uint112 depositAdded, uint256 fee, address indexed user, uint32 indexed epoch);

  event Redeem(uint8 indexed poolId, uint112 synthRedeemed, address indexed user, uint32 indexed epoch);

  // TODO URGENT: think of edge-case where this is in EWT. Maybe just handled by the backend.
  event ExecuteEpochSettlementMintUser(uint8 indexed poolId, address indexed user, uint32 indexed epochSettledUntil, uint256 amountPoolTokenMinted);

  event ExecuteEpochSettlementRedeemUser(
    uint8 indexed poolId,
    address indexed user,
    uint32 indexed epochSettledUntil,
    uint256 amountPaymentTokenRecieved
  );

  struct PoolState {
    uint8 poolId;
    uint256 tokenPrice;
    int256 value;
  }
  event EpochUpdated(uint32 indexed epoch, int256 underlyingAssetPrice, int256 valueChange, int256[2] fundingAmount, PoolState[] poolStates);

  event MarketDeprecation();

  // External calls

  function updateSystemStateUsingValidatedOracleRoundIds(uint80[] memory oracleRoundIdsToExecute) external;

  function mintLongFor(
    uint256 pool,
    uint112 amount,
    address user
  ) external;

  function mintShortFor(
    uint256 pool,
    uint112 amount,
    address user
  ) external;

  function mintFloatPoolFor(uint112 amount, address user) external;

  function redeemLong(uint256 pool, uint112 amount) external;

  function redeemShort(uint256 pool, uint112 amount) external;

  function redeemFloatPool(uint112 amount) external;

  function mintLong(uint256 pool, uint112 amount) external;

  function mintShort(uint256 pool, uint112 amount) external;

  function mintFloatPool(uint112 amount) external;

  function settlePoolUserMints(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external;

  function settlePoolUserRedeems(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external;

  function deprecateMarket() external;

  function exitDeprecatedMarket(address user) external;

  function paymentToken() external view returns (address);
}

interface IMarketTieredLeverageView {
  // Getters
  function numberOfPoolsOfType(IMarketCommon.PoolType) external view returns (uint256);

  function get_oracleManager() external view returns (IOracleManagerFixedEpoch);

  function get_pool(IMarketCommon.PoolType, uint256) external view returns (IMarketCommon.Pool memory);

  function get_pool_value(IMarketCommon.PoolType, uint256) external view returns (uint256);

  function get_pool_token(IMarketCommon.PoolType, uint256) external view returns (address);

  function get_pool_leverage(IMarketCommon.PoolType, uint256) external view returns (int96);

  function get_liquidityManager() external view returns (address);

  function get_userAction_depositPaymentToken(
    address,
    IMarketCommon.PoolType,
    uint256
  ) external view returns (IMarketCommon.UserAction memory);

  function get_userAction_redeemPoolToken(
    address,
    IMarketCommon.PoolType,
    uint256
  ) external view returns (IMarketCommon.UserAction memory);

  function get_poolToken_priceSnapshot(
    uint32,
    IMarketCommon.PoolType,
    uint256
  ) external view returns (uint256);

  function get_epochInfo() external view returns (IMarketCommon.EpochInfo memory);

  function getUsersConfirmedButNotSettledPoolTokenBalance(
    address user,
    IMarketCommon.PoolType poolType,
    uint8 poolTier
  ) external view returns (uint256 confirmedButNotSettledBalance);
}

interface IMarketTieredLeverage is
  IMarketTieredLeverageCore,
  IMarketTieredLeverageView //TODO delete these once upgrade is complete (next deployment)
{}

interface IMarket is IMarketTieredLeverage, IMarketExtended {}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

/// @notice Manages yield accumulation for the market contract. Each market is deployed with its own yield manager to simplify the bookkeeping, as different markets may share a payment token and yield pool.
interface ILiquidityManager {
  // /// @notice Deposits the given amount of payment tokens into this yield manager.
  // /// @param amount Amount of payment token to deposit
  // function depositPaymentToken(uint256 amount) external;

  /// @notice Allows the market to pay out a user from tokens already withdrawn from Aave
  /// @param user User to recieve the payout
  /// @param amount Amount of payment token to pay to user
  function transferPaymentTokensToUser(address user, uint256 amount) external;
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
@title PoolToken
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
*/
interface IPoolToken is IERC20Upgradeable {
  function initialize(
    IMarketExtended.SinglePoolInitInfo memory poolInfo,
    address upgrader,
    uint32 _marketIndex,
    uint8 _poolTier
  ) external;

  function mint(address, uint256) external;

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function burn(uint256 amount) external;
}

interface IGEMS {
  function initialize() external;

  function gm(address) external;

  function GEM_ROLE() external returns (bytes32);

  function balanceOf(address) external returns (uint256);
}

// import "@prb/math/contracts/PRBMathUD60x18.sol";

library MathUintFloat {
  /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
  /// fixed-point number.
  /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
  /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
  /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
  /// @return The product as an unsigned 60.18-decimal fixed-point number.
  function mul(uint256 x, uint256 y) internal pure returns (uint256) {
    // TODO: try use the mulDiv function from 'openZeppelin'
    // TODO: try use the mulDiv function from 'prb-math'
    // NOTE: this truncates rather than rounds the result:
    // return (x * y) / 1e18;
    return Math.mulDiv(x, y, 1e18);
  }

  /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
  /// @dev
  /// Requirements:
  /// - The denominator cannot be zero.
  ///
  /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
  /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
  /// @return The quotient as an unsigned 60.18-decimal fixed-point number.
  function div(uint256 x, uint256 y) internal pure returns (uint256) {
    // return (x * 1e18) / y;
    return Math.mulDiv(x, 1e18, y);
  }
}

contract MarketStorage is IMarketCommon {
  /*╔═════════════════════════════╗
    ║          VARIABLES          ║
    ╚═════════════════════════════╝*/

  /* ══════ Fixed-precision constants ══════ */
  uint256 constant SECONDS_IN_A_YEAR_e18 = 315576e20;

  uint256 constant longTypeIndex = uint256(PoolType.LONG);
  uint256 constant shortTypeIndex = uint256(PoolType.SHORT);
  uint256 constant floatTypeIndex = uint256(PoolType.FLOAT);
  uint256 constant maxTypeIndex = uint256(PoolType.LAST);

  /// @dev an empty allocation of storage for use in future upgrades - inspiration from OZ:
  ///      https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/10f0f1a95b1b0fd5520351886bae7a03490f1056/contracts/token/ERC20/ERC20Upgradeable.sol#L361
  uint256[45] private __openingstorageGap;

  /* ══════ Global state ══════ */
  address internal liquidityManager = address(0);
  IOracleManagerFixedEpoch internal oracleManager = IOracleManagerFixedEpoch(address(0));

  EpochInfo internal epochInfo;

  uint256[45] private __marketStateGap;

  uint256 internal fundingRateMultiplier_e18 = 0; // TODO: should we pack this in a struct (maybe with the max percentage change, or EpochInfo)? Could it be constant/immutable?

  // max percent change in price per epoch where 1e18 is 100% price movement.
  int256 internal maxPercentChange = 0;

  bool internal mintingPaused = false;
  bool internal marketDeprecated = false;

  uint256 public stabilityFee_basisPoints;
  // first element is for even epochs and second element for odd epochs
  uint256[2] public feesToDistribute;

  uint256[45] private __globalStorageGap;

  /* ══════ Pool state ══════ */

  // mapping from epoch number -> pooltype -> array of price snapshot
  // TODO - experiment with `uint128[8]` and check gas efficiency.
  mapping(uint256 => mapping(IMarketCommon.PoolType => uint256[8])) internal poolToken_priceSnapshot;

  mapping(IMarketCommon.PoolType => IMarketCommon.Pool[8]) internal pools;

  uint256[16] internal _numberOfPoolsOfType = [0];
  uint256 internal _totalNumberOfPools = 0;

  uint256[45] private __poolStorageGap;

  /* ══════ User specific ══════ */

  //User Address => IMarketCommon.PoolType => UserAction Array
  mapping(address => mapping(IMarketCommon.PoolType => IMarketCommon.UserAction[8])) internal userAction_depositPaymentToken;
  //User Address => IMarketCommon.PoolType => UserAction Array
  mapping(address => mapping(IMarketCommon.PoolType => IMarketCommon.UserAction[8])) internal userAction_redeemPoolToken;

  uint256[45] private __userStorageGap;

  uint128[2] effectiveLiquidityForPoolType;
}

contract MarketTieredLeverageLogic is AccessControlledAndUpgradeableModifiers, IMarketCommon, IMarketTieredLeverageCore, MarketStorage {
  using SafeERC20 for IERC20;
  using MathUintFloat for uint256;
  using SignedMath for int256;

  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  function gemCollectingModifierLogic(address user) internal {
    // TODO: fix me - on market deploy, make new market have GEM minter role.
    IGEMS(gems).gm(user);
  }

  modifier gemCollecting(address user) {
    gemCollectingModifierLogic(user);
    _;
  }

  modifier checkMarketNotDeprecated() {
    if (marketDeprecated) revert MarketDeprecated();
    _;
  }

  IRegistry immutable registry; // original core contract
  address immutable gems;
  address public immutable paymentToken;

  constructor(address _paymentToken, IRegistry _registry) {
    if (_paymentToken == address(0)) revert InvalidAddress({invalidAddress: _paymentToken});
    if (address(_registry) == address(0)) revert InvalidAddress({invalidAddress: address(_registry)});

    paymentToken = _paymentToken;

    registry = _registry; // original core contract
    gems = _registry.gems();
  }

  /*╔══════════════════════════════╗
    ║       GETTER FUNCTIONS       ║
    ╚══════════════════════════════╝*/
  /// @notice - this assumes that we will never have more than 16 tier types, and 16 tiers of a given tier type.
  // TODO move this to a library - can then me used by shifting contract as well.
  function _packPoolId(PoolType poolType, uint8 poolTier) internal pure virtual returns (uint8) {
    return (uint8(poolType) << 4) | poolTier;
  }

  /*╔═══════════════════════════════╗
    ║     UPDATING SYSTEM STATE     ║
    ╚═══════════════════════════════╝*/

  /// @notice This calculates the value transfer from the overbalanced to underbalanced side (i.e. the funding rate)
  /// This is a further incentive measure to balanced markets. This may be present on some and not other pool token markets.
  /// @param overbalancedValue Side with more liquidity.
  /// @param underbalancedValue Side with less liquidity.
  /// @return fundingAmount The amount the overbalanced side needs to pay the underbalanced.
  function _calculateFundingAmount(
    uint256 overbalancedIndex,
    uint256 overbalancedValue,
    uint256 underbalancedValue
  ) internal view virtual returns (int256[2] memory fundingAmount) {
    /*
    baseFunding exists based on the size of capital and happens regardless of balance.
    additionalFunding scales as the imbalance of liquidity does. 
    The split of the total funding is borne predominently by the overbalanced side. 
    */
    uint256 baseFunding = ((overbalancedValue + underbalancedValue) * fundingRateMultiplier_e18 * oracleManager.EPOCH_LENGTH()) /
      (SECONDS_IN_A_YEAR_e18 * 1e18);

    uint256 additionalFunding = ((overbalancedValue - underbalancedValue) * fundingRateMultiplier_e18 * oracleManager.EPOCH_LENGTH()) /
      (SECONDS_IN_A_YEAR_e18 * 1e18);

    uint256 totalFunding = (baseFunding + additionalFunding);

    uint256 overbalancedFunding = (totalFunding * overbalancedValue) / (overbalancedValue + underbalancedValue);
    uint256 underbalancedFunding = totalFunding - overbalancedFunding;

    if (overbalancedIndex == shortTypeIndex) fundingAmount = [-int256(overbalancedFunding), int256(underbalancedFunding)];
    else fundingAmount = [-int256(underbalancedFunding), int256(overbalancedFunding)];
  }

  function _getValueChangeAndFundingTranche(
    uint256 effectiveValueLong,
    uint256 effectiveValueShort,
    int256 previousPrice,
    int256 currentPrice
  ) internal view returns (ValueChangeAndFunding memory rebalanceParams) {
    // now we need to set the floating tranche and adjust the totalEffectiveLiquidity accordingly.
    uint256 floatPoolLiquidity = pools[PoolType.FLOAT][0].value;
    rebalanceParams.floatPoolLeverage = ((int256(effectiveValueShort) - int256(effectiveValueLong)) * 1e18) / int256(floatPoolLiquidity);

    if (rebalanceParams.floatPoolLeverage > 5e18) rebalanceParams.floatPoolLeverage = 5e18;
    else if (rebalanceParams.floatPoolLeverage < -5e18) rebalanceParams.floatPoolLeverage = -5e18;

    // NOTE/TODO - we are dividing by previous price before multiplying by multiplying the result - check there isn't any accuracy lost or that it is insignificant!
    int256 priceMovement = (1e18 * (currentPrice - previousPrice)) / previousPrice;
    if (priceMovement > maxPercentChange) priceMovement = maxPercentChange;
    else if (priceMovement < -maxPercentChange) priceMovement = -maxPercentChange;

    if (effectiveValueShort > effectiveValueLong) {
      rebalanceParams.fundingAmount = _calculateFundingAmount(shortTypeIndex, effectiveValueShort, effectiveValueLong);
      rebalanceParams.valueChange =
        (priceMovement * int256(effectiveValueLong + ((uint256(rebalanceParams.floatPoolLeverage) * floatPoolLiquidity) / 1e18))) /
        1e18;
      rebalanceParams.underBalancedSideType = longTypeIndex;
    } else {
      rebalanceParams.fundingAmount = _calculateFundingAmount(longTypeIndex, effectiveValueLong, effectiveValueShort);
      rebalanceParams.valueChange =
        (priceMovement * int256(effectiveValueShort + ((uint256(-rebalanceParams.floatPoolLeverage) * floatPoolLiquidity) / 1e18))) /
        1e18;
      rebalanceParams.underBalancedSideType = shortTypeIndex;
    }
  }

  /// @notice Reblances the pool given the epoch execution information and can also perform batched actions from the epoch.
  // TODO: return poolStates and emit the epoch event one level up (and don't pass through `epochPrice`).
  function _rebalancePoolsAndExecuteBatchedActionsTranche(
    uint32 epochIndex,
    uint128[2] memory totalEffectiveLiquidityPoolType,
    ValueChangeAndFunding memory rebalanceParams
  ) internal returns (uint128[2] memory nextTotalEffectiveLiquidityPoolType, PoolState[] memory poolStates) {
    poolStates = new PoolState[](_totalNumberOfPools);
    uint8 currentPoolStateIndex;

    totalEffectiveLiquidityPoolType[rebalanceParams.underBalancedSideType] += uint128(
      (uint256(pools[PoolType.FLOAT][0].value) * SignedMath.abs(int256(rebalanceParams.floatPoolLeverage))) / 1e18
    );

    // calculate how much to distribute to winning side and extract from losing side (and do save result)
    for (uint256 poolType = shortTypeIndex; poolType < maxTypeIndex; ++poolType) {
      for (uint256 poolTier = 0; poolTier < _numberOfPoolsOfType[poolType]; ++poolTier) {
        int256 poolValue = int256(pools[PoolType(poolType)][poolTier].value);
        PoolFixedConfig memory poolFixedConfig = pools[PoolType(poolType)][poolTier].fixedConfig;

        // calculate funding and pay it here. Long and Short pools pay it. Float pool recieves it.

        if (poolType != floatTypeIndex) {
          poolValue +=
            ((poolValue * poolFixedConfig.leverage) * (rebalanceParams.valueChange - rebalanceParams.fundingAmount[poolType])) /
            int256(uint256(totalEffectiveLiquidityPoolType[poolType]) * 1e18);
        } else {
          poolValue +=
            ((poolValue * rebalanceParams.floatPoolLeverage * rebalanceParams.valueChange) /
              (int256(uint256(totalEffectiveLiquidityPoolType[uint256(rebalanceParams.underBalancedSideType)]) * 1e18))) +
            -rebalanceParams.fundingAmount[0] +
            rebalanceParams.fundingAmount[1] +
            int256(feesToDistribute[epochIndex & 1]);

          feesToDistribute[epochIndex & 1] = 0;
        }

        uint256 tokenSupply = IPoolToken(poolFixedConfig.token).totalSupply();
        uint256 price = uint256(poolValue).div(tokenSupply);

        poolValue += _processAllBatchedEpochActions(epochIndex, PoolType(poolType), poolTier, price, poolFixedConfig.token);

        if (poolType != floatTypeIndex)
          nextTotalEffectiveLiquidityPoolType[poolType] += uint128(
            (uint256(poolValue) * uint256(int256(poolFixedConfig.leverage > 0 ? poolFixedConfig.leverage : -poolFixedConfig.leverage))) / 1e18
          ); // this isn't needed to be written for the floating tranche

        pools[PoolType(poolType)][poolTier].value = uint256(poolValue);

        poolToken_priceSnapshot[epochIndex][PoolType(poolType)][poolTier] = price;

        poolStates[currentPoolStateIndex++] = PoolState({
          poolId: _packPoolId(PoolType(poolType), uint8(poolTier)),
          tokenPrice: price,
          value: poolValue
        });
      }
    }
  }

  function updateSystemStateUsingValidatedOracleRoundIds(uint80[] memory oracleRoundIdsToExecute) external virtual checkMarketNotDeprecated {
    uint32 latestExecutedEpochIndex = epochInfo.latestExecutedEpochIndex;
    (int256 previousPrice, int256[] memory epochPrices) = oracleManager.validateAndReturnMissedEpochInformation(
      // TODO: optimize this - there is lots of loading from storage here. Maybe group these items in a struct together nicely (also reading storage in the require at the top)
      latestExecutedEpochIndex,
      epochInfo.latestExecutedOracleRoundId,
      oracleRoundIdsToExecute
    );

    uint256 numberOfEpochsToExecute = epochPrices.length;

    uint128[2] memory totalEffectiveLiquidityPoolType = effectiveLiquidityForPoolType;
    for (
      uint256 i = 0;
      i < numberOfEpochsToExecute; /* i is incremented later in scope*/

    ) {
      ValueChangeAndFunding memory rebalanceParams = _getValueChangeAndFundingTranche(
        totalEffectiveLiquidityPoolType[longTypeIndex],
        totalEffectiveLiquidityPoolType[shortTypeIndex],
        // this is the previous execution price, not the previous oracle update price
        previousPrice,
        epochPrices[i]
      );

      previousPrice = epochPrices[i];

      PoolState[] memory poolStates;
      (totalEffectiveLiquidityPoolType, poolStates) = _rebalancePoolsAndExecuteBatchedActionsTranche(
        latestExecutedEpochIndex + uint32(++i),
        totalEffectiveLiquidityPoolType,
        rebalanceParams
      );

      emit EpochUpdated(latestExecutedEpochIndex + uint32(i), previousPrice, rebalanceParams.valueChange, rebalanceParams.fundingAmount, poolStates);
    }

    effectiveLiquidityForPoolType = totalEffectiveLiquidityPoolType;

    epochInfo = EpochInfo({
      latestExecutedEpochIndex: latestExecutedEpochIndex + uint32(numberOfEpochsToExecute),
      latestExecutedOracleRoundId: oracleRoundIdsToExecute[oracleRoundIdsToExecute.length - 1]
    });
  }

  /*╔═══════════════════════════╗
    ║       MINT POSITION       ║
    ╚═══════════════════════════╝*/

  /// @notice Calculates the fees for the mint amount depending on the market
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  function _calculateStabilityFees(uint256 amount) internal view returns (uint256 amountFees) {
    // stability fee is based on effectiveLiquidity added (takes into account leverage)
    amountFees = (amount * stabilityFee_basisPoints) / (10000);
  }

  /// @notice Allows users to mint pool token assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @dev We have to check market not deprecated after system state update because that is the function that determines whether the market should be deprecated.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint pool token assets at next price.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function _mint(
    uint112 amount,
    address user,
    PoolType poolType,
    uint256 poolTier
  )
    internal
    // TODO: can delete `checkMarketNotDeprecated` since a deprecated market is ALWAYS also paused!
    gemCollecting(user)
    checkMarketNotDeprecated
  {
    if (mintingPaused) revert MintingPaused();
    // Due to get amount of payment token calculation we must have amount * 1e18 > poolTokenPriceInPaymentTokens
    //   otherwise we get 0
    // In fact, all the decimals of amount * 1e18 that are less than poolTokenPriceInPaymentTokens
    //   get cut off
    if (amount < 1e18) revert InvalidActionAmount(amount);

    uint256 fees = _calculateStabilityFees((amount * SignedMath.abs(pools[poolType][poolTier].fixedConfig.leverage)) / 1e18);

    amount -= uint112(fees);

    // TODO: should this function not return a uint32 (rather than a uint256) since it is always a timestamp?
    uint32 currentEpoch = uint32(oracleManager.getCurrentEpochIndex());
    if (currentEpoch > epochInfo.latestExecutedEpochIndex + 2)
      revert MarketStale({currentEpoch: currentEpoch, latestExecutedEpoch: epochInfo.latestExecutedEpochIndex});

    settlePoolUserMints(user, poolType, poolTier);

    IERC20(paymentToken).safeTransferFrom(msg.sender, liquidityManager, amount);

    UserAction memory userAction = userAction_depositPaymentToken[user][poolType][poolTier];

    /// TODO: think: userAction.amount > 0 <IFF> userAction.correspondingEpoch <= currentEpoch
    if (userAction.amount > 0 && userAction.correspondingEpoch < currentEpoch) {
      userAction.nextEpochAmount += amount;
    } else {
      userAction.amount += amount;
      userAction.correspondingEpoch = currentEpoch;
    }

    // NOTE: `currentEpoch & 1` and `currentEpoch % 2` are equivalent, but the former is more efficient using bitwise operations.
    pools[poolType][poolTier].batchedAmount[currentEpoch & 1].paymentToken_deposit += amount;
    feesToDistribute[currentEpoch & 1] += fees;

    userAction_depositPaymentToken[user][poolType][poolTier] = userAction;

    emit Deposit(_packPoolId(poolType, uint8(poolTier)), amount, fees, user, currentEpoch);
  }

  /// @notice Allows users to mint long pool token assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  function mintLong(uint256 poolTier, uint112 amount) external {
    _mint(amount, msg.sender, PoolType.LONG, poolTier);
  }

  /// @notice Allows users to mint short pool token assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  function mintShort(uint256 poolTier, uint112 amount) external {
    _mint(amount, msg.sender, PoolType.SHORT, poolTier);
  }

  /// @notice Allows users to mint float pool token assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  function mintFloatPool(uint112 amount) external {
    _mint(amount, msg.sender, PoolType.FLOAT, 0);
  }

  /// @notice Allows mint long pool token assets for a market on behalf of some user. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  /// @param user Address of the user.
  function mintLongFor(
    uint256 poolTier,
    uint112 amount,
    address user
  ) external override {
    _mint(amount, user, PoolType.LONG, poolTier);
  }

  /// @notice Allows mint short pool token assets for a market on behalf of some user. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  /// @param user Address of the user.
  function mintShortFor(
    uint256 poolTier,
    uint112 amount,
    address user
  ) external override {
    _mint(amount, user, PoolType.SHORT, poolTier);
  }

  /// @notice Allows mint float pool token assets for a market on behalf of some user. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param amount Amount of payment tokens in that token's lowest denomination for which to mint pool token assets at next price.
  /// @param user Address of the user.
  function mintFloatPoolFor(uint112 amount, address user) external override {
    _mint(amount, user, PoolType.FLOAT, 0);
  }

  /*╔═══════════════════════════╗
    ║       REDEEM POSITION     ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to mint pool token assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @dev We have to check market not deprecated after system state update because that is the function that determines whether the market should be deprecated.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint pool token assets at next price.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function _redeem(
    uint112 amount,
    address user,
    PoolType poolType,
    uint256 poolTier
  ) internal virtual gemCollecting(user) checkMarketNotDeprecated {
    if (amount < 1e6) revert InvalidActionAmount(amount);

    uint32 currentEpoch = uint32(oracleManager.getCurrentEpochIndex());
    if (currentEpoch > epochInfo.latestExecutedEpochIndex + 2)
      revert MarketStale({currentEpoch: currentEpoch, latestExecutedEpoch: epochInfo.latestExecutedEpochIndex});

    settlePoolUserRedeems(user, poolType, poolTier);

    //slither-disable-next-line unchecked-transfer
    IPoolToken(pools[poolType][poolTier].fixedConfig.token).transferFrom(user, address(this), amount);

    UserAction memory userAction = userAction_redeemPoolToken[user][poolType][poolTier];

    if (userAction.amount > 0 && userAction.correspondingEpoch < currentEpoch) {
      userAction.nextEpochAmount += amount;
    } else {
      userAction.amount += amount;
      userAction.correspondingEpoch = currentEpoch;
    }

    // NOTE: `currentEpoch & 1` and `currentEpoch % 2` are equivalent, but the former is more efficient using bitwise operations.
    pools[poolType][poolTier].batchedAmount[currentEpoch & 1].poolToken_redeem += amount;

    userAction_redeemPoolToken[user][poolType][poolTier] = userAction;

    emit Redeem(_packPoolId(poolType, uint8(poolTier)), amount, user, currentEpoch);
  }

  /// @notice Allows users to mint long pool token assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint pool token assets at next price.
  function redeemLong(uint256 poolTier, uint112 amount) external {
    _redeem(amount, msg.sender, PoolType.LONG, poolTier);
  }

  /// @notice Allows users to redeem short pool token assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param poolTier leveraged poolTier index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to redeem pool token assets at next price.
  function redeemShort(uint256 poolTier, uint112 amount) external {
    _redeem(amount, msg.sender, PoolType.SHORT, poolTier);
  }

  /// @notice Allows users to redeem float pool token assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to redeem pool token assets at next price.
  function redeemFloatPool(uint112 amount) external {
    _redeem(amount, msg.sender, PoolType.SHORT, 0);
  }

  /*╔═════════════════════╗
    ║  USER SETTLEMENTS   ║
    ╚═════════════════════╝*/

  //Add hook to guarentee upkeep if performed before calling this function
  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their mints during that epoch to that user.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function settlePoolUserMints(
    address user,
    PoolType poolType,
    uint256 poolTier
  ) public {
    /*
      NOTE: please reflect any changes made to this function to the `getUsersConfirmedButNotSettledPoolTokenBalance` function too.
    */
    UserAction memory userAction = userAction_depositPaymentToken[user][poolType][poolTier];

    // Case if the primary order can be executed.
    if (userAction.correspondingEpoch != 0 && userAction.correspondingEpoch <= epochInfo.latestExecutedEpochIndex) {
      uint256 poolToken_price = poolToken_priceSnapshot[userAction.correspondingEpoch][poolType][poolTier];
      uint256 amountPoolTokenToMint = uint256(userAction.amount).div(poolToken_price);

      // If user has a mint in MEWT simply bump it one slot.
      if (userAction.nextEpochAmount > 0) {
        uint32 secondaryOrderEpoch = userAction.correspondingEpoch + 1;

        // need to check if we can also execute this
        if (secondaryOrderEpoch <= epochInfo.latestExecutedEpochIndex) {
          // then also execute
          poolToken_price = poolToken_priceSnapshot[secondaryOrderEpoch][poolType][poolTier];
          amountPoolTokenToMint += uint256(userAction.nextEpochAmount).div(poolToken_price);

          userAction.amount = 0;
          userAction.correspondingEpoch = 0;
        } else {
          userAction.amount = userAction.nextEpochAmount;
          userAction.correspondingEpoch = secondaryOrderEpoch;
        }
        // has to zero as either executed or bumped to primary slot
        userAction.nextEpochAmount = 0;
      } else {
        // If user has no pending mints then simply wipe
        userAction.amount = 0;
        userAction.correspondingEpoch = 0;
      }

      //slither-disable-next-line unchecked-transfer
      IPoolToken(pools[poolType][poolTier].fixedConfig.token).transfer(user, amountPoolTokenToMint);

      userAction_depositPaymentToken[user][poolType][poolTier] = userAction;

      emit ExecuteEpochSettlementMintUser(_packPoolId(poolType, uint8(poolTier)), user, epochInfo.latestExecutedEpochIndex, amountPoolTokenToMint);
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their redeems during that epoch to that user.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index
  function settlePoolUserRedeems(
    address user,
    PoolType poolType,
    uint256 poolTier
  ) public {
    UserAction memory userAction = userAction_redeemPoolToken[user][poolType][poolTier];

    // Case if the primary order can be executed.
    if (userAction.amount > 0 && userAction.correspondingEpoch <= epochInfo.latestExecutedEpochIndex) {
      uint256 poolToken_price = poolToken_priceSnapshot[userAction.correspondingEpoch][poolType][poolTier];

      uint256 amountPaymentTokenToSend = uint256(userAction.amount).mul(poolToken_price);

      // If user has a redeem in MEWT simply bump it one slot.
      if (userAction.nextEpochAmount > 0) {
        uint32 secondaryOrderEpoch = userAction.correspondingEpoch + 1;

        // need to check if we can also execute this
        if (secondaryOrderEpoch <= epochInfo.latestExecutedEpochIndex) {
          // then also execute
          poolToken_price = poolToken_priceSnapshot[secondaryOrderEpoch][poolType][poolTier];
          amountPaymentTokenToSend += uint256(userAction.nextEpochAmount).mul(poolToken_price);

          userAction.amount = 0;
          userAction.correspondingEpoch = 0;
        } else {
          userAction.amount = userAction.nextEpochAmount;
          userAction.correspondingEpoch = secondaryOrderEpoch;
        }
        // has to zero as either executed or bumped to primary slot
        userAction.nextEpochAmount = 0;
      } else {
        // If user has no pending redeems then simply wipe
        userAction.amount = 0;
        userAction.correspondingEpoch = 0;
      }

      ILiquidityManager(liquidityManager).transferPaymentTokensToUser(user, amountPaymentTokenToSend);

      userAction_redeemPoolToken[user][poolType][poolTier] = userAction;

      emit ExecuteEpochSettlementRedeemUser(
        _packPoolId(poolType, uint8(poolTier)),
        user,
        epochInfo.latestExecutedEpochIndex,
        amountPaymentTokenToSend
      );
    }
  }

  /*╔═══════════════════╗
    ║   BATCH ACTIONS   ║
    ╚═══════════════════╝*/

  /// @notice Either mints or burns pool token supply.
  /// @param poolToken Address of the pool token.
  /// @param changeInPoolTokensTotalSupply Positive indicates amount to be minted and negative indicates amount to be burned.
  function _handleChangeInPoolTokensTotalSupply(address poolToken, int256 changeInPoolTokensTotalSupply) internal virtual {
    if (changeInPoolTokensTotalSupply > 0) {
      IPoolToken(poolToken).mint(address(this), uint256(changeInPoolTokensTotalSupply));
    } else if (changeInPoolTokensTotalSupply < 0) {
      IPoolToken(poolToken).burn(uint256(-changeInPoolTokensTotalSupply));
    }
  }

  /// @notice For a given pool, updates the value depending on the batched deposits and redeems that took place during the epoch
  /// @param associatedEpochIndex Index of epoch where the batched actions were performed.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier leveraged poolTier index.
  /// @param price Price of the pool token.
  function _processAllBatchedEpochActions(
    uint256 associatedEpochIndex,
    PoolType poolType,
    uint256 poolTier,
    uint256 price,
    address poolToken
  ) internal returns (int256 changeInMarketValue_inPaymentToken) {
    // QUESTION: is it worth the gas saving this storage pointer - we only use 'pool' twice in this function.
    Pool storage pool = pools[poolType][poolTier];

    BatchedActions memory batch = pool.batchedAmount[associatedEpochIndex & 1];

    // save some gas if there is nothing to do
    if (batch.paymentToken_deposit > 0 || batch.poolToken_redeem > 0) {
      changeInMarketValue_inPaymentToken = int128(batch.paymentToken_deposit) - int256(uint256(batch.poolToken_redeem).mul(price));

      int256 changeInSupply_poolToken = int256(uint256(batch.paymentToken_deposit).div(price)) - int128(batch.poolToken_redeem);

      pool.batchedAmount[associatedEpochIndex & 1] = BatchedActions(0, 0);

      _handleChangeInPoolTokensTotalSupply(poolToken, changeInSupply_poolToken);
    }
  }

  /*╔═══════════════════════════╗
    ║ DEPRECATED MARKET ACTIONS ║
    ╚═══════════════════════════╝*/
  function _deprecateMarket() internal {
    ValueChangeAndFunding memory emptyValueChangeAndFunding;

    // Here we rebalance the market twice with zero price change (so the pool tokens don't change price) but all outstanding
    _rebalancePoolsAndExecuteBatchedActionsTranche(epochInfo.latestExecutedEpochIndex + 1, effectiveLiquidityForPoolType, emptyValueChangeAndFunding);
    _rebalancePoolsAndExecuteBatchedActionsTranche(epochInfo.latestExecutedEpochIndex + 2, effectiveLiquidityForPoolType, emptyValueChangeAndFunding);

    epochInfo.latestExecutedEpochIndex += 2;
    marketDeprecated = true;
    mintingPaused = true;
    emit MarketDeprecation();
  }

  /// @notice This function will auto-deprecate the market if there are no updates for more than 10 days.
  /// @dev 10 days should be enough time for the team to make an informed decision on how to handle this error.
  function deprecateMarketNoOracleUpdates() external {
    require(((oracleManager.getCurrentEpochIndex() - epochInfo.latestExecutedEpochIndex) * oracleManager.EPOCH_LENGTH()) > 10 days);

    _deprecateMarket();
  }

  function deprecateMarket() external adminOnly {
    _deprecateMarket();
  }

  /// @notice Allows users to exit the market after it has been deprecated
  /// @param user Users address to remove from the market
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  function _exitDeprecatedMarket(address user, PoolType poolType) internal {
    // NOTE we don't want the seeder to redeem because it could lead to division by 0 when the last person exits
    require(user != address(0) && user != address(420), "User can't be 0 or seeder");

    uint256 maxPoolIndex = _numberOfPoolsOfType[uint256(poolType)];
    for (uint8 poolIndex = 0; poolIndex < maxPoolIndex; poolIndex++) {
      // execute all outstanding mint&redeems that were made before deprecation
      settlePoolUserMints(user, poolType, poolIndex);
      settlePoolUserRedeems(user, poolType, poolIndex);

      // redeem all user's pool tokens
      IPoolToken poolToken = IPoolToken(pools[poolType][poolIndex].fixedConfig.token);
      uint256 balance = poolToken.balanceOf(user);
      if (balance > 0) {
        //slither-disable-next-line unchecked-transfer
        poolToken.transferFrom(user, address(this), balance);
        poolToken.burn(balance);

        uint256 amount = balance.mul(poolToken_priceSnapshot[epochInfo.latestExecutedEpochIndex][poolType][poolIndex]);
        ILiquidityManager(liquidityManager).transferPaymentTokensToUser(user, amount);
      }
    }
  }

  /// @notice Allows users to exit the market after it has been deprecated
  /// @param user Users address to remove from the market
  function exitDeprecatedMarket(address user) external {
    // NOTE we check market deprecation after updating system state 'cause it may be that this
    //  particular update is the one that deprecates the market
    require(marketDeprecated, "Market is not deprecated");

    _exitDeprecatedMarket(user, PoolType.SHORT);
    _exitDeprecatedMarket(user, PoolType.LONG);
  }
}

contract MarketTieredLeverageCore is MarketTieredLeverageLogic, ProxyNonPayable {
  IMarketExtended public immutable nonCoreFunctionsDelegatee;

  constructor(
    IMarketExtended nonCoreFunctionsDelegateeContract,
    address paymentToken,
    IRegistry registry
  ) MarketTieredLeverageLogic(paymentToken, registry) {
    require(address(nonCoreFunctionsDelegateeContract) != address(0));
    nonCoreFunctionsDelegatee = nonCoreFunctionsDelegateeContract;

    // Add this so that this contract can be detected as a proxy by things such as etherscan.
    StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = address(nonCoreFunctionsDelegatee);

    require(registry == nonCoreFunctionsDelegatee.registry());
  }

  /// @dev Required to delegate non-core-function calls to the MarketExtended contract using the OpenZeppelin proxy.
  function _implementation() internal view override returns (address) {
    return address(nonCoreFunctionsDelegatee);
  }
}

/// @dev This contract is contains a set of non-core functions for the MarketTieredLeverage contract that are not important enough to be included in the core contract.
contract MarketExtendedCore is AccessControlledAndUpgradeableModifiers, MarketStorage, IMarketExtendedCore {
  using SafeERC20 for IERC20;

  IRegistry public immutable registry; // original core contract
  address public immutable gems;
  address public immutable paymentToken;

  constructor(address _paymentToken, IRegistry _registry) {
    require(_paymentToken != address(0) && address(_registry) != address(0));
    paymentToken = _paymentToken;
    registry = _registry; // original core contract
    gems = registry.gems();
  }

  /////////////////////////
  // Simple getter functions
  /////////////////////////

  /// @notice Returns the total liquidity in the market
  /// @return totalValueRealizedInMarket total liquidity in all pools on both sides
  function getTotalValueRealizedInMarket() external view returns (uint256 totalValueRealizedInMarket) {
    for (uint8 poolType = uint8(PoolType.SHORT); poolType <= uint8(PoolType.LONG); poolType++) {
      uint256 maxPoolTier = _numberOfPoolsOfType[poolType];
      for (uint256 poolTier = 0; poolTier < maxPoolTier; poolTier++) {
        totalValueRealizedInMarket += pools[PoolType(poolType)][poolTier].value;
      }
    }
  }

  /*╔═══════════════════════╗
    ║       INITIALIZE      ║
    ╚═══════════════════════╝*/

  /// @notice Initialize pools in the market
  /// @dev Can only be called by registry contract
  /// @param params struct containing addresses of dependency contracts and other market initialization parameters
  /// @return initializationSuccess bool value indicating whether initialization was successful.
  function initializePools(InitializePoolsParams memory params) external override initializer returns (bool initializationSuccess) {
    require(msg.sender == address(registry), "Not registry");
    require(
      // You require at least 1e12 (1 payment token with 12 decimal places) of the underlying payment token to seed the market.
      params.initialEffectiveLiquidityToSeedEachPool >= 1e12,
      "Insufficient market seed"
    );
    require(params.seederAndAdmin != address(0) && params.oracleManager != address(0) && params.liquidityManager != address(0));
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(params.seederAndAdmin);

    oracleManager = IOracleManagerFixedEpoch(params.oracleManager);
    liquidityManager = params.liquidityManager;

    epochInfo.latestExecutedEpochIndex = uint32(oracleManager.getCurrentEpochIndex() - 1);

    (uint80 latestRoundId, int256 initialAssetPrice, , , ) = oracleManager.chainlinkOracle().latestRoundData();
    epochInfo.latestExecutedOracleRoundId = latestRoundId;

    // Ie default max percentage change is 19.99% (for the 5x FLOAT tier)
    // given general deviation threshold of 0.5% for most oracle price feeds
    // price movements greater than 20% are extremely unlikely and so maintaining a hard cap of 19.99% on price changes is reasonable.
    maxPercentChange = 1999e14;

    emit SeparateMarketLaunchedAndSeeded(
      params._marketIndex,
      params.seederAndAdmin,
      address(oracleManager),
      liquidityManager,
      paymentToken,
      initialAssetPrice
    );

    for (uint256 i = 0; i < params.initPools.length; i++) {
      //Mike NOTE 2nd param should be actual liquidity,
      _addPoolToExistingMarket(params.initPools[i], params.initialEffectiveLiquidityToSeedEachPool, params.seederAndAdmin, params._marketIndex);
    }

    // Return true to drastically reduce chance of making mistakes with this.
    initializationSuccess = true;
  }

  /*╔═══════════════════╗
    ║       ADMIN       ║
    ╚═══════════════════╝*/

  /// @notice Update oracle for a market
  /// @dev Can only be called by the current admin.
  /// @param oracleConfig Address of the replacement oracle manager.
  function updateMarketOracle(OracleUpdate memory oracleConfig) external adminOnly {
    // NOTE: we could also upgrade this contract to reference the new oracle potentially and have it as immutable
    // If not a oracle contract this would break things.. Test's arn't validating this
    // Ie require isOracle interface - ERC165

    // This check helps make sure that config changes are deliberate.
    require(oracleConfig.prevOracle == oracleManager, "Incorrect prev oracle");

    oracleManager = oracleConfig.newOracle;
    emit ConfigChange(ConfigType.marketOracleUpdate, abi.encode(oracleConfig));
  }

  /// @notice Update the yearly funding rate multiplier for the market
  /// @dev Can only be called by the current admin.
  /// @param fundingRateConfig New funding rate multiplier
  function changeMarketFundingRateMultiplier(FundingRateUpdate memory fundingRateConfig) external adminOnly {
    require(fundingRateConfig.newMultiplier <= 5e19, "funding rate must be <= 5000%");

    // This check helps make sure that config changes are deliberate.
    require(fundingRateConfig.prevMultiplier == fundingRateMultiplier_e18, "Incorrect prev oracle");

    fundingRateMultiplier_e18 = fundingRateConfig.newMultiplier;
    emit ConfigChange(ConfigType.fundingRateMultiplier, abi.encode(fundingRateConfig));
  }

  /// TODO pack the parameters into a struct in future to be aligned with initializePools function above.
  /// @notice Add a pool to an existing market.
  /// @dev Can only be called by the current admin.
  /// @param initPool initialization info for the new pool
  /// @param initialActualLiquidityForNewPool initial effective liquidity to be added to new pool at initialization
  /// @param seederAndAdmin address of pool seeder and admin
  /// @param _marketIndex index of the market
  //slither-disable-next-line costly-operations-inside-a-loop
  function _addPoolToExistingMarket(
    SinglePoolInitInfo memory initPool,
    uint256 initialActualLiquidityForNewPool,
    address seederAndAdmin,
    uint32 _marketIndex
  ) internal {
    require(
      // You require at least 1e12 (1 payment token with 12 decimal places) of the underlying payment token to seed the market.
      initialActualLiquidityForNewPool >= 1e12,
      "Insufficient market seed"
    );
    require(_numberOfPoolsOfType[uint256(initPool.poolType)] < 8, "val > max num of pools for side");
    require(seederAndAdmin != address(0));
    require(initPool.token != address(0), "Pool token address incorrect");
    require((initPool.leverage >= 1e18 && initPool.leverage <= 10e18) || initPool.poolType == PoolType.FLOAT, "Pool leverage out of bounds");

    SinglePoolInitInfo memory poolInfo = initPool;
    // TODO: I think if we should add this back (it does nothing for any pool less that 5x - and that is the max leverage setting currently (in the require).
    uint256 tierPriceMovementThresholdAbsolute = PoolType.FLOAT == initPool.poolType ? 0.1999e18 : (1e36 / poolInfo.leverage) - 1e14;

    maxPercentChange = int256(Math.min(uint256(maxPercentChange), tierPriceMovementThresholdAbsolute));

    IPoolToken(initPool.token).initialize(initPool, seederAndAdmin, _marketIndex, uint8(_numberOfPoolsOfType[uint256(initPool.poolType)]));

    IPoolToken(initPool.token).mint(address(420), initialActualLiquidityForNewPool);

    Pool storage pool = pools[initPool.poolType][_numberOfPoolsOfType[uint256(initPool.poolType)]];
    // TODO: pass in leverage as a uint96 type and confirm last type.
    if (PoolType.FLOAT == initPool.poolType) {}
    pool.fixedConfig = PoolFixedConfig(initPool.token, (initPool.poolType == PoolType.SHORT ? -int96(initPool.leverage) : int96(initPool.leverage)));
    pool.value = initialActualLiquidityForNewPool;

    require(_numberOfPoolsOfType[uint256(initPool.poolType)]++ == poolInfo.poolTier, "incorrect pool tier");
    ++_totalNumberOfPools; // Mike NOTE why is this incrementing every time a new tier is added?

    emit TierAdded(poolInfo, initialActualLiquidityForNewPool);

    IERC20(paymentToken).safeTransferFrom(seederAndAdmin, liquidityManager, initialActualLiquidityForNewPool);

    if (initPool.poolType != PoolType.FLOAT)
      effectiveLiquidityForPoolType[uint256(initPool.poolType)] += uint128((initialActualLiquidityForNewPool * initPool.leverage) / 1e18);
  }

  function addPoolToExistingMarket(
    SinglePoolInitInfo memory initPool,
    uint256 initialActualLiquidityForNewPool,
    address seederAndAdmin,
    uint32 _marketIndex
  ) external adminOnly {
    _addPoolToExistingMarket(initPool, initialActualLiquidityForNewPool, seederAndAdmin, _marketIndex);
  }

  function pauseMinting() external adminOnly {
    mintingPaused = true;
    emit MintingPauseChange(mintingPaused);
  }

  function unpauseMinting() external adminOnly {
    require(!marketDeprecated, "can't unpause deprecated market");
    mintingPaused = false;
    emit MintingPauseChange(mintingPaused);
  }
}

contract MarketExtended is MarketExtendedCore, IMarketExtended {
  constructor(address _paymentToken, IRegistry _registry) MarketExtendedCore(_paymentToken, _registry) {}

  /// @notice Purely a convenience function to get the seeder address. Used in testing.
  function getSeederAddress() external pure returns (address) {
    return address(420);
  }

  /// @notice Purely a convenience function to get the pool token address. Used in testing.
  function getPoolTokenAddress(IMarketCommon.PoolType poolType, uint256 index) external view returns (address) {
    return pools[poolType][index].fixedConfig.token;
  }

  /// @notice Returns the number of pools of poolType i.e. Long or Short
  /// @param isLong true for long, false for short
  function getNumberOfPools(bool isLong) external view returns (uint256) {
    if (isLong) {
      return _numberOfPoolsOfType[uint8(IMarketCommon.PoolType.LONG)];
    } else {
      return _numberOfPoolsOfType[uint8(IMarketCommon.PoolType.SHORT)];
    }
  }

  /// @notice Returns batched deposit amount in payment token for even numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_even_batchedAmountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].batchedAmount[0].paymentToken_deposit);
  }

  /// @notice Returns batched deposit amount in payment token for odd numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_odd_batchedAmountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].batchedAmount[1].paymentToken_deposit);
  }

  /// @notice Returns batched redeem amount in pool token for even numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_even_batchedAmountPoolToken_redeem(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].batchedAmount[0].poolToken_redeem);
  }

  /// @notice Returns batched redeem amount in pool token for odd numbered epochs.
  /// @param poolType indicates either Long or Short pool type
  /// @param pool index of the pool on the market side
  function get_odd_batchedAmountPoolToken_redeem(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].batchedAmount[1].poolToken_redeem);
  }

  function get_batchedAmountPaymentToken_deposit(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].batchedAmount[oracleManager.getCurrentEpochIndex() & 1].paymentToken_deposit);
  }

  function get_batchedAmountPoolToken_redeem(IMarketCommon.PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].batchedAmount[oracleManager.getCurrentEpochIndex() & 1].poolToken_redeem);
  }

  function get_mintingPaused() external view returns (bool) {
    return mintingPaused;
  }

  function get_marketDeprecated() external view returns (bool) {
    return marketDeprecated;
  }

  function get_maxPercentChange() external view returns (int256) {
    return maxPercentChange;
  }

  function get_fundingRateMultiplier_e18() external view returns (uint256) {
    return fundingRateMultiplier_e18;
  }

  function get_effectiveLiquidityForPoolType() external view returns (uint128[2] memory) {
    return effectiveLiquidityForPoolType;
  }
}

contract Market is MarketTieredLeverageCore, IMarketTieredLeverage {
  using MathUintFloat for uint256;

  constructor(
    IMarketExtended _nonCoreFunctionsDelegatee,
    address _paymentToken,
    IRegistry registry
  ) MarketTieredLeverageCore(_nonCoreFunctionsDelegatee, _paymentToken, registry) {}

  /// @notice Returns the balance of user actions in epochs which have been executed but not yet distributed to users.
  /// @dev Prices have a fixed 18 decimals.
  /// @param user Address of user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return confirmedButNotSettledBalance Returns balance of user actions in epochs which have been executed but not yet distributed to users.
  function getUsersConfirmedButNotSettledPoolTokenBalance(
    address user,
    IMarketCommon.PoolType poolType,
    uint8 poolTier
  ) external view returns (uint256 confirmedButNotSettledBalance) {
    /* NOTE:
      This function is the exact same logic/structure as settlePoolUserMints with lines of code commented out for setting state variables.
      We have left those commented out lines of code in the function so that this is easy to see. In particular this is why the team has decided to keep this function "OUT OF SCOPE" for the audit.
      Every comment labled with unused_from_settlePoolUserMints is code that came from the other version of this function.
    */
    IMarketCommon.UserAction memory userAction = userAction_depositPaymentToken[user][poolType][poolTier];

    // Case if the primary order can be executed.
    if (userAction.correspondingEpoch != 0 && userAction.correspondingEpoch <= epochInfo.latestExecutedEpochIndex) {
      uint256 poolToken_price = poolToken_priceSnapshot[userAction.correspondingEpoch][poolType][poolTier];

      /* unused_from_settlePoolUserMints
      address poolToken = pools[poolType][poolTier].token;
      */

      confirmedButNotSettledBalance = uint256(userAction.amount).div(poolToken_price);

      // If user has a mint in MEWT simply bump it one slot.
      if (userAction.nextEpochAmount > 0) {
        uint32 secondaryOrderEpoch = userAction.correspondingEpoch + 1;

        // need to check if we can also execute this
        if (secondaryOrderEpoch <= epochInfo.latestExecutedEpochIndex) {
          // then also execute
          poolToken_price = poolToken_priceSnapshot[secondaryOrderEpoch][poolType][poolTier];
          confirmedButNotSettledBalance += uint256(userAction.nextEpochAmount).div(poolToken_price);

          /* unused_from_settlePoolUserMints
          userAction.amount = 0;
          userAction.correspondingEpoch = 0;
        } else {
          userAction.amount = userAction.nextEpochAmount;
          userAction.correspondingEpoch = secondaryOrderEpoch;
          */
        }
        /* unused_from_settlePoolUserMints
        // has to zero as either executed or bumped to primary slot
        userAction.nextEpochAmount = 0;
      } else {
        // If user has no pending mints then simply wipe
        userAction.amount = 0;
        userAction.correspondingEpoch = 0;
        */
      }

      /* unused_from_settlePoolUserMints
      //slither-disable-next-line unchecked-transfer
      IPoolToken(poolToken).transfer(user, amountPoolTokenToMint);

      userAction_depositPaymentToken[user][poolType][poolTier] = userAction;

      emit ExecuteEpochSettlementMintUser(packPoolId(poolType, uint8(poolTier)), user, epochInfo.latestExecutedEpochIndex);
      */
    }
  }

  /// @notice Returns the number of pools of poolType i.e. Long or Short
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @return numberOfPoolsOfType Number of pools of poolType
  function numberOfPoolsOfType(IMarketCommon.PoolType poolType) external view returns (uint256) {
    return _numberOfPoolsOfType[uint8(poolType)];
  }

  /// @notice Returns the interface of OracleManager for the market
  /// @return oracleManager OracleManager interface
  function get_oracleManager() external view returns (IOracleManagerFixedEpoch) {
    return oracleManager;
  }

  /// @notice Returns the address of the YieldManager for the market
  /// @return liquidityManager address of the YieldManager
  function get_liquidityManager() external view returns (address) {
    return liquidityManager;
  }

  /// @notice Returns the deposit action in payment tokens of provided user for the given poolType and poolTier.
  /// @dev Action amounts have a fixed 18 decimals.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return userAction_depositPaymentToken Outstanding deposit action by user for the given poolType and poolTier.
  function get_userAction_depositPaymentToken(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external view returns (IMarketCommon.UserAction memory) {
    return userAction_depositPaymentToken[user][poolType][poolTier];
  }

  /// @notice Returns the redeem action in pool tokens of provided user for the given poolType and poolTier.
  /// @dev Action amounts have a fixed 18 decimals.
  /// @param user Address of the user.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return userAction_redeemPoolToken Outstanding redeem action by user for the given poolType and poolTier.
  function get_userAction_redeemPoolToken(
    address user,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external view returns (IMarketCommon.UserAction memory) {
    return userAction_redeemPoolToken[user][poolType][poolTier];
  }

  /// @notice Returns the pool struct given poolType and poolTier.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return pools Struct containing information about the pool i.e. value, leverage etc.
  function get_pool_value(IMarketCommon.PoolType poolType, uint256 poolTier) external view returns (uint256) {
    return pools[poolType][poolTier].value;
  }

  function get_pool(IMarketCommon.PoolType poolType, uint256 poolTier) external view returns (IMarketCommon.Pool memory) {
    return pools[poolType][poolTier];
  }

  function get_pool_token(IMarketCommon.PoolType poolType, uint256 poolTier) external view returns (address) {
    return pools[poolType][poolTier].fixedConfig.token;
  }

  function get_pool_leverage(IMarketCommon.PoolType poolType, uint256 poolTier) external view returns (int96) {
    return pools[poolType][poolTier].fixedConfig.leverage;
  }

  /// @notice Returns the price of the pool token given poolType and poolTier.
  /// @dev Prices have a fixed 18 decimals.
  /// @param epoch Number of epoch that has been executed.
  /// @param poolType an enum representing the type of poolTier for eg. LONG or SHORT.
  /// @param poolTier The index of the pool in the side.
  /// @return poolToken_priceSnapshot Price of the pool tokens in the pool.
  function get_poolToken_priceSnapshot(
    uint32 epoch,
    IMarketCommon.PoolType poolType,
    uint256 poolTier
  ) external view returns (uint256) {
    return poolToken_priceSnapshot[epoch][poolType][poolTier];
  }

  /// @notice Returns the epochInfo struct.
  /// @return epochInfo Struct containing info about the latest executed epoch and previous epoch.
  function get_epochInfo() external view returns (IMarketCommon.EpochInfo memory) {
    return epochInfo;
  }
}

/*
background: This is an experimental, quickly hashed together contract.
It will never hold value of any kind.

The goal is that a future version of this contract becomes a proper keeper contract.

For now no effort has been put into making it conform to the proper keeper interface etc.
*/


interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

library OracleManagerUtils {
  //// Types:
  // NOTE: this struct is used to reduce stack usage and fix coverage.
  // it does use more gas though :/ Coverage is more important than gas optimization currently.
  struct MissedEpochExecution {
    bool _isSearchingForuint80;
    uint80 _currentOracleRoundId;
    uint32 _currentMissedEpochPriceUpdatesArrayIndex;
  }

  function _shouldOracleUpdateExecuteEpoch(
    IOracleManagerFixedEpoch oracleManager,
    uint256 currentEpochStartTimestamp,
    uint256 previousOracleUpdateTimestamp,
    uint256 currentOracleUpdateTimestamp
  ) internal view returns (bool) {
    //Don't use price for execution because MEWT has not expired yet
    //current price update epoch is ahead of MEWT so we check if the previous value
    //occurred before MEWT to validate that this is the correct price update to use

    //  first condition checks for whether the oracle price update occurs before Minimum Execution Wait Threshold is expired.
    return
      (previousOracleUpdateTimestamp < currentEpochStartTimestamp + oracleManager.MINIMUM_EXECUTION_WAIT_THRESHOLD()) &&
      (currentOracleUpdateTimestamp >= currentEpochStartTimestamp + oracleManager.MINIMUM_EXECUTION_WAIT_THRESHOLD());
  }

  /// @notice Calculates number of epochs which have missed system state update, due to bot failing
  /// @dev Called by internal function to decide how many epoch execution info (oracle price update details) should be returned
  /// @dev It is "maximum" as this is just the upper
  /// @param _latestExecutedEpochIndex index of the most recently executed epoch
  function _getMaximumNumberOfMissedEpochs(
    IOracleManagerFixedEpoch oracleManager,
    uint256 _latestExecutedEpochIndex,
    uint256 latestOraclePriceUpdateTime
  ) internal view returns (uint256 _numberOfMissedEpochs) {
    _numberOfMissedEpochs = oracleManager.getCurrentEpochIndex() - _latestExecutedEpochIndex - 1;

    if (_numberOfMissedEpochs == 0) return 0;

    // Checks for whether the oracle price update occurs before Minimum Execution Wait Threshold is expired.
    if (latestOraclePriceUpdateTime < oracleManager.getEpochStartTimestamp() + oracleManager.MINIMUM_EXECUTION_WAIT_THRESHOLD()) {
      _numberOfMissedEpochs -= 1;
    }
  }

  /// @notice returns an array of info on each epoch price update that was missed
  /// @dev This function gets executed in a system update on the market contract
  /// @param _latestExecutedEpochIndex the most recent epoch index in which a price update has been executed
  /// @param _previousOracleUpdateIndex the "roundId" used to reference the most recently executed oracle price on chainlink
  // TODO Scrutinize this function works!
  function getMissedEpochPriceUpdates(
    IOracleManagerFixedEpoch oracleManager,
    uint32 _latestExecutedEpochIndex,
    uint80 _previousOracleUpdateIndex,
    uint256 _numberOfUpdatesToTryFetch
  ) public view returns (uint80[] memory _missedEpochOracleRoundIds) {
    AggregatorV3Interface chainlinkOracle = oracleManager.chainlinkOracle();
    AggregatorV3InterfaceS.LatestRoundData memory latestRoundData = AggregatorV3InterfaceS(address(chainlinkOracle)).latestRoundData();

    // check whether latestRoundData.startedAt is before end point of previous epoch
    // if met, then break
    if (oracleManager.getEpochStartTimestamp() - oracleManager.EPOCH_LENGTH() > latestRoundData.startedAt) {
      _missedEpochOracleRoundIds = new uint80[](0);

      return (_missedEpochOracleRoundIds);
    }
    uint256 _numberOfMissedEpochs = Math.min(
      _getMaximumNumberOfMissedEpochs(oracleManager, _latestExecutedEpochIndex, latestRoundData.startedAt),
      _numberOfUpdatesToTryFetch
    );

    _missedEpochOracleRoundIds = new uint80[](_numberOfMissedEpochs);

    if (_numberOfMissedEpochs == 0) {
      return (_missedEpochOracleRoundIds);
    }

    MissedEpochExecution memory _missedEpochExecution = MissedEpochExecution({
      _isSearchingForuint80: true,
      _currentOracleRoundId: _previousOracleUpdateIndex + 1,
      _currentMissedEpochPriceUpdatesArrayIndex: 0
    });

    //  Start at the timestamp of the first epoch index after the latest executed epoch index
    // We add 1 to get the end timestamp of the latest executed epoch, then another 1 to get the next epoch, hence we add 2.
    latestRoundData.startedAt = (uint256(_latestExecutedEpochIndex) + 2) * oracleManager.EPOCH_LENGTH() + oracleManager.initialEpochStartTimestamp();

    // Called outside of the loop and then updated on each iteration within the loop
    (, , uint256 _previousOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(_previousOracleUpdateIndex);

    while (_missedEpochExecution._isSearchingForuint80 && latestRoundData.roundId >= _missedEpochExecution._currentOracleRoundId) {
      (, , uint256 _currentOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(_missedEpochExecution._currentOracleRoundId);

      // Check if there was a 'phase change' AND the `_currentOracleUpdateTimestamp` is zero.
      if ((latestRoundData.roundId >> 64) != (_previousOracleUpdateIndex >> 64) && _currentOracleUpdateTimestamp == 0) {
        // NOTE: if the phase changes, then we want to correct the phase of the update.
        //       There is no guarantee that the phaseID won't increase multiple times in a short period of time (hence the while loop).
        //       But chainlink does promise that it will be sequential.
        while (_currentOracleUpdateTimestamp == 0) {
          _missedEpochExecution._currentOracleRoundId =
            (((_missedEpochExecution._currentOracleRoundId >> 64) + 1) << 64) |
            uint80(uint64(_missedEpochExecution._currentOracleRoundId));

          (, , _currentOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(_missedEpochExecution._currentOracleRoundId);
        }
      }
      if (_shouldOracleUpdateExecuteEpoch(oracleManager, latestRoundData.startedAt, _previousOracleUpdateTimestamp, _currentOracleUpdateTimestamp)) {
        // check whether oracle update is after end point of next epoch
        // if met, break the loop and send back the false
        // Checks for whether the oracle price update happened before end of current epoch end timestamp
        if (_currentOracleUpdateTimestamp > latestRoundData.startedAt + oracleManager.EPOCH_LENGTH()) {
          uint80[] memory truncatedMissedEpochOracleRoundIds = new uint80[](_missedEpochExecution._currentMissedEpochPriceUpdatesArrayIndex);
          for (uint256 i = 0; i < _missedEpochExecution._currentMissedEpochPriceUpdatesArrayIndex; i++) {
            truncatedMissedEpochOracleRoundIds[i] = _missedEpochOracleRoundIds[i];
          }
          return (truncatedMissedEpochOracleRoundIds);
        } else {
          _missedEpochOracleRoundIds[_missedEpochExecution._currentMissedEpochPriceUpdatesArrayIndex] = _missedEpochExecution._currentOracleRoundId;
        }

        // Increment to the next array index and the correct timestamp
        _missedEpochExecution._currentMissedEpochPriceUpdatesArrayIndex += 1;
        latestRoundData.startedAt += uint32(oracleManager.EPOCH_LENGTH());

        // Check that we have retrieved all the missed epoch updates that we are searching
        // for and end the while loop
        if (_missedEpochExecution._currentMissedEpochPriceUpdatesArrayIndex == _numberOfMissedEpochs) {
          _missedEpochExecution._isSearchingForuint80 = false;
        }
      }

      //Previous oracle update timestamp can be reassigned to the current for the next iteration
      _previousOracleUpdateTimestamp = _currentOracleUpdateTimestamp;
      _missedEpochExecution._currentOracleRoundId++;
    }
  }

  /// @notice Returns oracle information for executing historical epoch(s)
  /// @param latestExecutedEpochIndex the most recent epoch index in which a price update has been executed
  /// @param latestExecutedOracleRoundId the "roundId" used to reference the most recently executed oracle price on chainlink
  /// @return missedEpochOracleRoundIds list of epoch execution information
  function getOracleInfoForSystemStateUpdate(
    IOracleManagerFixedEpoch oracleManager,
    uint32 latestExecutedEpochIndex,
    uint80 latestExecutedOracleRoundId
  ) external view returns (uint80[] memory missedEpochOracleRoundIds) {
    uint256 numberOfEpochsSinceLastEpoch = (oracleManager.getCurrentEpochIndex() - latestExecutedEpochIndex) * oracleManager.EPOCH_LENGTH();

    // If the oracle falls more than 6 epochs behind it will only return 6 of them (but catch up 6 at a time).
    //      And 30 for mumbai (because it can handle bigger transactions)
    if (numberOfEpochsSinceLastEpoch > (6 * (block.chainid == 80001 ? 5 : 1))) {
      numberOfEpochsSinceLastEpoch = 6 * (block.chainid == 80001 ? 5 : 1);
    }

    missedEpochOracleRoundIds = getMissedEpochPriceUpdates(
      oracleManager,
      latestExecutedEpochIndex,
      latestExecutedOracleRoundId,
      numberOfEpochsSinceLastEpoch
    );
  }

  /// @notice Returns start timestamp of current epoch
  /// @return getEpochStartTimestamp start timestamp of the current epoch
  function getEpochStartTimestamp(IOracleManagerFixedEpoch oracleManager, uint32 epochIndex) external view returns (uint256) {
    return (uint256(epochIndex) * oracleManager.EPOCH_LENGTH()) + oracleManager.initialEpochStartTimestamp();
  }
}

// TODO: add 'time delay' capability to the upkeep so that we can run both keepers (gelato, chainlink, and our own) but with different trigger points.
contract KeeperArctic is AccessControlledAndUpgradeable, KeeperCompatibleInterface {
  IRegistry public registry;
  uint256 public _stakerDeprecated;

  mapping(uint32 => uint256) public _updateTimeThresholdInSecondsDeprecated;
  mapping(uint32 => uint256) public _percentChangeThresholdDeprecated;
  mapping(uint32 => uint256) public _batchPaymentTokenValueThresholdDeprecated;

  function initialize(address _admin, address _registry) external initializer {
    registry = IRegistry(_registry);

    _AccessControlledAndUpgradeable_init(_admin);
  }

  function setRegistry(address _registry) external onlyRole(ADMIN_ROLE) {
    registry = IRegistry(_registry);
  }

  function performUpkeep(bytes calldata dataForUpkeep) external {
    (IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) = abi.decode(dataForUpkeep, (IMarketTieredLeverage, uint80[]));
    market.updateSystemStateUsingValidatedOracleRoundIds(missedEpochsOracleRoundIds);
  }

  // Functian that the keeper calls
  function updateSystemStateForMarket(IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) external {
    market.updateSystemStateUsingValidatedOracleRoundIds(missedEpochsOracleRoundIds);
  }

  function shouldUpdateMarketCore()
    public
    view
    returns (
      bool shouldUpdate,
      IMarketTieredLeverage market,
      uint80[] memory missedEpochsOracleRoundIds
    )
  {
    uint256 latestMarket = registry.latestMarket();
    for (uint32 index = 1; index <= latestMarket; index++) {
      market = IMarketTieredLeverage(registry.separateMarketContracts(index));
      IOracleManagerFixedEpoch oracleManager = market.get_oracleManager();
      IMarketCommon.EpochInfo memory epochInfo = market.get_epochInfo();

      uint80[] memory _missedEpochOracleRoundIds = OracleManagerUtils.getOracleInfoForSystemStateUpdate(
        oracleManager,
        epochInfo.latestExecutedEpochIndex,
        epochInfo.latestExecutedOracleRoundId
      );

      if (_missedEpochOracleRoundIds.length > 0) {
        missedEpochsOracleRoundIds = new uint80[](_missedEpochOracleRoundIds.length);
        for (uint256 i = 0; i < _missedEpochOracleRoundIds.length; i++) {
          missedEpochsOracleRoundIds[i] = _missedEpochOracleRoundIds[i];
        }
        return (true, market, missedEpochsOracleRoundIds);
      }
    }
  }

  function shouldUpdateMarketCallable() external returns (bool canExec, bytes memory execPayload) {
    (bool shouldUpdate, IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) = shouldUpdateMarketCore();
    if (shouldUpdate) {
      return (true, abi.encodeCall(this.updateSystemStateForMarket, (market, missedEpochsOracleRoundIds)));
    }
    registry = registry; //prevents warning about view function
    return (false, "");
  }

  function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
    (bool shouldUpdate, IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) = shouldUpdateMarketCore();
    if (shouldUpdate) {
      return (true, abi.encode(market, missedEpochsOracleRoundIds));
    }
    return (false, "");
  }

  function shouldUpdateMarket() external view returns (bool canExec, bytes memory execPayload) {
    (bool shouldUpdate, IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) = shouldUpdateMarketCore();
    if (shouldUpdate) {
      return (true, abi.encodeCall(this.updateSystemStateForMarket, (market, missedEpochsOracleRoundIds)));
    }
    return (false, "");
  }

  // Test code - only for debugging
  event TestUpdateSystemStateForMarket(address indexed market, uint80[] missedEpochsOracleRoundIds);

  // Functian that the keeper calls
  function updateSystemStateForMarketTest(IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) external {
    emit TestUpdateSystemStateForMarket(address(market), missedEpochsOracleRoundIds);
  }

  function shouldUpdateMarketTest() external view returns (bool canExec, bytes memory execPayload) {
    (bool shouldUpdate, IMarketTieredLeverage market, uint80[] memory missedEpochsOracleRoundIds) = shouldUpdateMarketCore();

    if (shouldUpdate) {
      return (true, abi.encodeCall(this.updateSystemStateForMarketTest, (market, missedEpochsOracleRoundIds)));
    }

    return (false, "");
  }

  uint256[100] __testGap;

  uint256 public currentTestUpdate;
  event TestKeeperExecuted(uint256 indexed currentTestUpdddate);

  function updateCurrentTestUpdate(uint256 _currentTestUpdate) external {
    currentTestUpdate = _currentTestUpdate;
    emit TestKeeperExecuted(_currentTestUpdate);
  }

  function gelatoTest() external view returns (bool, bytes memory execPayload) {
    //slither-disable-next-line block-timestamp
    if (currentTestUpdate < block.timestamp / 60) {
      return (true, abi.encodeCall(this.updateCurrentTestUpdate, block.timestamp / 60));
    } else {
      return (false, "");
    }
  }
}

/// DEV ONLY:

/**
 **** visit https://float.capital *****
 */

/// @title Core logic of Float Protocal markets
/// @author float.capital
/// @notice visit https://float.capital for more info
/// @dev All functions in this file are currently `virtual`. This is NOT to encourage inheritance.
/// It is merely for convenince when unit testing.
/// @custom:auditors This contract balances long and short sides.
contract Registry is IRegistry, AccessControlledAndUpgradeable {
  /*╔═════════════════════════════╗
    ║          VARIABLES          ║
    ╚═════════════════════════════╝*/

  /* ══════ Global state ══════ */
  uint32 public override latestMarket;

  address public gems;

  uint256[45] private __globalStateGap;

  /* ══════ Market specific ══════ */
  mapping(uint32 => bool) public marketExists;
  mapping(uint32 => uint256) public override marketUpdateIndex;

  struct PoolTokenPriceInPaymentToken {
    // this has a maximum size of `2^128=3.4028237e+38` units of payment token which is amply sufficient for our markets
    uint128 price_long;
    uint128 price_short;
  }
  mapping(uint32 => mapping(uint256 => PoolTokenPriceInPaymentToken)) public poolToken_priceSnapshot;

  /* ══════ User specific ══════ */
  mapping(uint32 => mapping(address => uint256)) public userNextPrice_currentUpdateIndex;

  mapping(uint32 => mapping(bool => mapping(address => uint256))) public userNextPrice_paymentToken_depositAmount;
  mapping(uint32 => mapping(bool => mapping(address => uint256))) public userNextPrice_poolToken_redeemAmount;
  mapping(uint32 => mapping(bool => mapping(address => uint256))) public userNextPrice_poolToken_toShiftAwayFrom_marketSide;

  mapping(uint32 => address) public separateMarketContracts;

  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  modifier adminOnly() {
    _checkRole(ADMIN_ROLE, msg.sender);
    _;
  }

  /*╔═════════════════════════════╗
    ║       CONTRACT SET-UP       ║
    ╚═════════════════════════════╝*/

  /// @notice Initializes the contract.
  /// @dev Calls OpenZeppelin's initializer modifier.
  /// @param _admin Address of the admin role.
  /// @param _gems Address of the gems contract.
  function initialize(address _admin, address _gems) external virtual initializer {
    require(_admin != address(0) && _gems != address(0));
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(_admin);
    gems = _gems;
    IGEMS(gems).initialize();

    emit RegistryArctic(_admin);
  }

  /*╔════════════════════════════╗
    ║     MARKET REGISTRATION    ║
    ╚════════════════════════════╝*/

  function registerPoolMarketContract(
    string memory name,
    string memory symbol,
    IMarketTieredLeverage marketContract,
    uint256 initialEffectiveLiquidityToSeedEachPool,
    address oracleManager,
    address liquidityManager,
    IMarketExtended.SinglePoolInitInfo[] memory launchPools
  ) external adminOnly {
    uint32 marketIndex = ++latestMarket;

    emit SeparateMarketCreated(name, symbol, address(marketContract), marketIndex);
    require(
      IMarketExtended(address(marketContract)).initializePools(
        IMarketExtendedCore.InitializePoolsParams(
          launchPools,
          initialEffectiveLiquidityToSeedEachPool,
          msg.sender,
          marketIndex,
          oracleManager,
          liquidityManager
        )
      ),
      "registering pool market failed"
    );
    separateMarketContracts[marketIndex] = address(marketContract);
    marketExists[marketIndex] = true;

    AccessControlledAndUpgradeable(gems).grantRole(IGEMS(gems).GEM_ROLE(), address(marketContract));
  }
}

/**
@title PoolTokenMarketUpgradeable
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
@dev Logic for price tracking contained in Market contracts
     The contract inherits from ERC20PresetMinterPauser.sol
*/
// NOTE: the `AccessControlledAndUpgradeable` isn't the first thing inherited from in these contracts (like in other float contracts)
contract PoolTokenMarketUpgradeable is
  IPoolToken,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  AccessControlledAndUpgradeable,
  ERC20PermitUpgradeable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @notice Address of the market contract, a deployed market.sol
  address public immutable market;

  uint256[2] __deprecatedVariableSpace;
  /// @notice Identifies which market in minter the token is for.
  uint32 public marketIndex;
  /// @notice Whether the token is a long token or short token for its market.
  IMarketCommon.PoolType public poolType;
  uint8 public poolTier;

  /// Upgradability - implementation constructor:
  constructor(address _market) initializer {
    require(_market != address(0));
    market = _market;
  }

  /// @notice Creates an instance of the contract.
  /// @dev Should only be called by TokenFactory.sol for our system.
  /// @param poolInfo info about the token the token is long or short (or other future type) for its market.
  /// @param upgrader Address of contract with permission to upgrade this contract.
  /// @param _marketIndex Which market the token is for.
  function initialize(
    IMarketExtended.SinglePoolInitInfo memory poolInfo,
    address upgrader,
    uint32 _marketIndex,
    uint8 _poolTier
  ) external initializer {
    require(msg.sender == market);
    assert(poolInfo.token == address(this));
    _AccessControlledAndUpgradeable_init(upgrader);
    __ERC20_init(poolInfo.name, poolInfo.symbol);
    __ERC20Burnable_init();
    __ERC20Permit_init(poolInfo.name);

    _setupRole(MINTER_ROLE, market);

    marketIndex = _marketIndex;
    poolType = poolInfo.poolType;
    //slither-disable-next-line missing-events-arithmetic
    poolTier = _poolTier;
  }

  /*╔══════════════════════════════════════════════════════╗
    ║    FUNCTIONS INHERITED BY ERC20PresetMinterPauser    ║
    ╚══════════════════════════════════════════════════════╝*/

  function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
    return ERC20Upgradeable.totalSupply();
  }

  /** 
  @notice Mints a number of pool tokens for an address.
  @dev Can only be called by addresses with a minter role. 
        This should correspond to the Long Short contract.
  @param to The address for which to mint the tokens for.
  @param amount Amount of pool tokens to mint in wei.
  */
  function mint(address to, uint256 amount) external override onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  /// @notice Burns or destroys a number of held pool tokens for an address.
  /// @dev Modified to only allow Long Short to burn tokens on redeem.
  /// @param amount The amount of tokens to burn in wei.
  function burn(uint256 amount) public override(ERC20BurnableUpgradeable, IPoolToken) onlyRole(MINTER_ROLE) {
    super._burn(_msgSender(), amount);
  }

  /** 
  @notice Overrides the default ERC20 transferFrom.
  @dev To allow users to avoid approving market contract when redeeming tokens,
       minter has a virtual infinite allowance.
  @param sender User for which to transfer tokens.
  @param recipient Recipient of the transferred tokens.
  @param amount Amount of tokens to transfer in wei.
  */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override(ERC20Upgradeable, IPoolToken) returns (bool) {
    if (recipient == market && msg.sender == market) {
      // If it to minter and msg.sender is minter don't perform additional transfer checks.
      ERC20Upgradeable._transfer(sender, recipient, amount);
      return true;
    }

    return ERC20Upgradeable.transferFrom(sender, recipient, amount);
  }

  /** 
  @param recipient Receiver of the tokens
  @param amount Number of tokens
  */
  function transfer(address recipient, uint256 amount) public override(ERC20Upgradeable, IPoolToken) returns (bool) {
    return ERC20Upgradeable.transfer(recipient, amount);
  }

  /** 
  @notice Overrides the OpenZeppelin _beforeTokenTransfer hook
  @dev Ensures that this contract's accounting reflects all the senders's outstanding
       tokens from next price actions before any token transfer occurs.
       Removal of pausing functionality of ERC20PresetMinterPausable is intentional.
  @param sender User for which tokens are to be transferred for.
  @param to Receiver of the tokens
  @param amount Number of tokens
  */
  function _beforeTokenTransfer(
    address sender,
    address to,
    uint256 amount
  ) internal override {
    if (sender != market && sender != address(0)) {
      IMarketTieredLeverage(market).settlePoolUserMints(sender, poolType, poolTier);
    }
    super._beforeTokenTransfer(sender, to, amount);
  }

  /**
  @notice Gets the pool token balance of the user in wei.
  @dev To automatically account for next price actions which have been confirmed but not settled,
        includes any outstanding tokens owed by minter.
  @param account The address for which to get the balance of.
  */
  function balanceOf(address account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
    return
      ERC20Upgradeable.balanceOf(account) +
      IMarketTieredLeverageView(market).getUsersConfirmedButNotSettledPoolTokenBalance(account, poolType, poolTier);
  }
}

/** Contract giving user GEMS*/

// Inspired by https://github.com/andrecronje/rarity/blob/main/rarity.sol

/** @title GEMS */
contract GEMS is AccessControlledAndUpgradeable, IGEMS {
  bytes32 public constant GEM_ROLE = keccak256("GEM_ROLE");

  uint200 constant gems_per_day = 250e18;
  uint40 constant DAY = 1 days;

  mapping(address => uint256) public gems_deprecated;
  mapping(address => uint256) public streak_deprecated;
  mapping(address => uint256) public lastActionTimestamp_deprecated;

  // Pack all this data into a single struct.
  struct UserGemData {
    uint16 streak; // max 179 years - if someone reaches this streack, go them 🚀
    uint40 lastActionTimestamp; // will run out on February 20, 36812 (yes, the year 36812 - btw uint32 lasts untill the year 2106)
    uint200 gems; // this is big enough to last 6.4277522e+39 (=2^200/250e18) days 😆
  }
  mapping(address => UserGemData) userGemData;

  event GemsCollected(address user, uint256 gems, uint256 streak);

  function initialize() public initializer {
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(msg.sender);

    _setupRole(GEM_ROLE, msg.sender);
  }

  // Only called once per user
  function attemptUserUpgrade(address user) internal returns (UserGemData memory transferedUserGemData) {
    uint256 usersCurrentGems = gems_deprecated[user];
    if (usersCurrentGems > 0) {
      transferedUserGemData = UserGemData(uint16(streak_deprecated[user]), uint40(lastActionTimestamp_deprecated[user]), uint200(usersCurrentGems));

      // resut old data (save some gas 😇)
      streak_deprecated[user] = 0;
      lastActionTimestamp_deprecated[user] = 0;
      gems_deprecated[user] = 0;
    }
  }

  // Say gm and get gems_deprecated by performing an action in market contract
  function gm(address user) external {
    UserGemData memory userData = userGemData[user];
    uint256 userslastActionTimestamp = uint256(userData.lastActionTimestamp);
    if (userslastActionTimestamp == 0) {
      // this is either a user migrating to the more efficient struct OR a brand new user.
      //      in both cases, this branch will only ever execute once!
      userData = attemptUserUpgrade(user);
      userslastActionTimestamp = uint256(userData.lastActionTimestamp);
    }

    uint256 blocktimestamp = block.timestamp;

    unchecked {
      if (blocktimestamp - userslastActionTimestamp >= DAY) {
        if (hasRole(GEM_ROLE, msg.sender)) {
          // Award gems_deprecated
          userData.gems += gems_per_day;

          // Increment streak_deprecated
          if (blocktimestamp - userslastActionTimestamp < 2 * DAY) {
            userData.streak += 1;
          } else {
            userData.streak = 1; // reset streak_deprecated to 1
          }

          userData.lastActionTimestamp = uint40(blocktimestamp);
          userGemData[user] = userData; // update storage once all updates are complete!

          emit GemsCollected(user, uint256(userData.gems), uint256(userData.streak));
        }
      }
    }
  }

  function balanceOf(address account) public view returns (uint256 balance) {
    balance = uint256(userGemData[account].gems);
    if (balance == 0) {
      balance = gems_deprecated[account];
    }
  }

  function getGemData(address account) public view returns (UserGemData memory gemData) {
    gemData = userGemData[account];
    if (gemData.gems == 0) {
      gemData = UserGemData(uint16(streak_deprecated[account]), uint40(lastActionTimestamp_deprecated[account]), uint200(gems_deprecated[account]));
    }
  }
}

/*
 * Implementation of an OracleManager that fetches prices from a Chainlink aggregate price feed.
 */
contract OracleManagerFixedEpoch is IOracleManagerFixedEpoch {
  // Global state.
  AggregatorV3Interface public immutable override chainlinkOracle;

  uint8 public immutable override oracleDecimals;
  uint256 public immutable initialEpochStartTimestamp; // Timestamp that epoch 0 STARTED at.
  uint256 public immutable MINIMUM_EXECUTION_WAIT_THRESHOLD; // This value can only be upgraded via contract upgrade.
  uint256 public immutable EPOCH_LENGTH; // No mechanism exists currently to upgrade this value. Additional contract work+testing needed to make this have flexibility.

  ////////////////////////////////////
  ///// CONTRACT SET-UP //////////////
  ////////////////////////////////////
  constructor(
    address _chainlinkOracle,
    uint256 epochLength,
    uint256 minimumExecutionWaitThreshold
  ) {
    chainlinkOracle = AggregatorV3Interface(_chainlinkOracle);
    oracleDecimals = chainlinkOracle.decimals();
    MINIMUM_EXECUTION_WAIT_THRESHOLD = minimumExecutionWaitThreshold;
    EPOCH_LENGTH = epochLength;

    // NOTE: along with the getCurrentEpochIndex function this assignment gives an initial epoch index of 1,
    //         and this is set at the time of deployment of this contract
    //         i.e. calling getCurrentEpochIndex() at the end of this constructor will give a value of 1.
    initialEpochStartTimestamp = getEpochStartTimestamp() - epochLength;
  }

  ////////////////////////////////////
  ///// IMPLEMENTATION ///////////////
  ////////////////////////////////////

  /// @notice Returns start timestamp of current epoch
  /// @return getEpochStartTimestamp start timestamp of the current epoch
  function getEpochStartTimestamp() public view returns (uint256) {
    //Eg. If EPOCH_LENGTH is 10min, then the epoch will change at 11:00, 11:10, 11:20 etc.
    // NOTE: we intentianally divide first to truncate the insignificant digits.
    //slither-disable-next-line divide-before-multiply
    return (block.timestamp / EPOCH_LENGTH) * EPOCH_LENGTH;
  }

  /// @notice Returns index of the current epoch based on block.timestamp
  /// @dev Called by internal functions to get current epoch index
  /// @return getCurrentEpochIndex the current epoch index
  //slither-disable-next-line block-timestamp
  function getCurrentEpochIndex() external view returns (uint256) {
    return (getEpochStartTimestamp() - initialEpochStartTimestamp) / EPOCH_LENGTH;
  }

  function validateAndReturnMissedEpochInformation(
    uint32 latestExecutedEpochIndex,
    // TODO: we could just pass in the previous epoch's ID in and validate it, rather than storing it in MarketTieredLeverage. Might save some gas?
    uint80 latestExecutedOracleRoundId,
    uint80[] memory oracleRoundIdsToExecute
  ) public view returns (int256 previousPrice, int256[] memory missedEpochPriceUpdates) {
    uint256 lengthOfEpochsToExecute = oracleRoundIdsToExecute.length;

    if (lengthOfEpochsToExecute == 0) revert EmptyArrayOfIndexes();

    (, previousPrice, , , ) = chainlinkOracle.getRoundData(latestExecutedOracleRoundId);

    missedEpochPriceUpdates = new int256[](lengthOfEpochsToExecute);

    uint256 relevantEpochStartTimestampWithMEWT = ((uint256(latestExecutedEpochIndex) + 2) * EPOCH_LENGTH) +
      MINIMUM_EXECUTION_WAIT_THRESHOLD +
      initialEpochStartTimestamp;

    for (uint32 i = 0; i < lengthOfEpochsToExecute; i++) {
      // Get correct data
      (, int256 currentOraclePrice, uint256 currentOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(oracleRoundIdsToExecute[i]);

      // Get Previous round data to validate correctness.
      // TODO: this doesn't take into account phase changes!
      (, , uint256 previousOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(oracleRoundIdsToExecute[i] - 1);

      // Check if there was a 'phase change' AND the `_currentOraclePrice` is zero.
      if ((oracleRoundIdsToExecute[i] >> 64) > (latestExecutedOracleRoundId >> 64) && previousOracleUpdateTimestamp == 0) {
        // NOTE: if the phase changes, then we want to correct the phase of the update.
        //       There is no guarantee that the phaseID won't increase multiple times in a short period of time (hence the while loop).
        //       But chainlink does promise that it will be sequential.
        // View how phase changes happen here: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.7/dev/AggregatorProxy.sol#L335
        while (previousOracleUpdateTimestamp == 0) {
          // NOTE: re-using this variable to keep gas costs low for this edge case.
          latestExecutedOracleRoundId = (((latestExecutedOracleRoundId >> 64) + 1) << 64) | uint64(oracleRoundIdsToExecute[i] - 1);

          (, , previousOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(latestExecutedOracleRoundId);
        }
      }

      // This checks that the oracle indexes are in the correct order and that they don't skip a single epoch.
      if (
        previousOracleUpdateTimestamp >= relevantEpochStartTimestampWithMEWT ||
        currentOracleUpdateTimestamp < relevantEpochStartTimestampWithMEWT ||
        currentOracleUpdateTimestamp >= relevantEpochStartTimestampWithMEWT + EPOCH_LENGTH
      ) revert InvalidOracleExecutionRoundId({oracleRoundId: oracleRoundIdsToExecute[i]});

      if (currentOraclePrice <= 0) revert InvalidOraclePrice({oraclePrice: currentOraclePrice});

      missedEpochPriceUpdates[i] = currentOraclePrice;

      relevantEpochStartTimestampWithMEWT += EPOCH_LENGTH;
    }
  }
}

/*
 * ChainlinkAggregatorFaster is a wrapper around the real chainlink aggregator that simulates price updates at a faster rate
 * than the chainlink aggregator. These faster prices are useful on testnet when we want chainlink to update faster, and
 * do it in a deterministic way.
 */
contract ChainlinkAggregatorFaster is AggregatorV3Interface, AccessControlledAndUpgradeable {
  // Admin contracts.
  AggregatorV3Interface public immutable baseChainlinkAggregator;
  uint8 public immutable override decimals;
  uint256 public immutable override version;
  string public constant override description = "A wrapper around a chainlink oracel to help simulate faster oracle updates";

  /// @dev - if this value is updating once an hour on average (every 60 minutes), then a speedup factor of 60 would make the oracle update every minute on average.
  uint256 public immutable speedupFactor;
  // @dev - the number of seconds that the fast update will take.
  uint256 public immutable fastOracleUpdateLength;

  int256 offset;

  struct RoundData {
    uint80 answeredInRound;
    int256 answer;
    uint256 setAt;
  }
  mapping(uint80 => RoundData) public roundData;

  constructor(
    AggregatorV3Interface _baseChainlinkAggregator,
    uint256 _speedupFactor,
    uint256 _fastOracleUpdateLength
  ) {
    baseChainlinkAggregator = _baseChainlinkAggregator;
    speedupFactor = _speedupFactor;
    fastOracleUpdateLength = _fastOracleUpdateLength;

    decimals = _baseChainlinkAggregator.decimals();
    version = _baseChainlinkAggregator.version();
  }

  ////////////////////////////////////
  /////////// MODIFIERS //////////////
  ////////////////////////////////////

  ////////////////////////////////////
  ///// CONTRACT SET-UP //////////////
  ////////////////////////////////////

  function setup(address admin) public initializer {
    _AccessControlledAndUpgradeable_init(admin);
  }

  ////////////////////////////////////
  ///// IMPLEMENTATION ///////////////
  ////////////////////////////////////

  /// @dev Pseudo randomly generates a value between 99e16 and 101e16 from the roundId, can be used to create price 'noise'.
  // slither-disable-next-line weak-prng
  function changePriceUpOrDownByLessThan1Percent(int256 currentPrice, uint80 roundId) public pure returns (int256) {
    return (currentPrice * (1e18 + int256((uint256(keccak256(abi.encode(roundId))) % 2e16)) - 1e16)) / 1e18;
  }

  function determinePredictedUpdatedAtTime(uint256 chainlinkOracleSubIndex, uint256 updatedAtSource) internal view returns (uint256 updatedAt) {
    updatedAt = updatedAtSource + Math.min((chainlinkOracleSubIndex * fastOracleUpdateLength), (speedupFactor - 1) * fastOracleUpdateLength);
  }

  function getRoundDataFromChainlinkData(
    uint256 chainlinkOracleSubIndex,
    uint80 roundIdSource,
    int256 answerSource,
    uint256 updatedAtSource,
    uint80 _answeredInRoundSource
  )
    public
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    if (chainlinkOracleSubIndex > speedupFactor || chainlinkOracleSubIndex == 0) {
      return (roundIdSource * uint80(speedupFactor), answerSource, updatedAtSource, updatedAtSource, _answeredInRoundSource);
    } else {
      updatedAt = determinePredictedUpdatedAtTime(chainlinkOracleSubIndex, updatedAtSource);
      startedAt = updatedAt; // always keep these equal in the simulation.

      roundId = (roundIdSource * uint80(speedupFactor)) + uint80(chainlinkOracleSubIndex);

      // Randomly deviates within +/-1% of the answer.
      answer = changePriceUpOrDownByLessThan1Percent(answerSource, roundId);

      return (roundId, answer, startedAt, updatedAt, 1);
    }
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint80 roundIdImplementation, , , , ) = baseChainlinkAggregator.latestRoundData();

    uint80 chainLinkOriginalId = _roundId / uint80(speedupFactor);

    if (chainLinkOriginalId > roundIdImplementation) {
      revert("RoundId too high");
    }

    (uint80 roundIdSource, int256 answerSource, , uint256 updatedAtSource, uint80 _answeredInRoundSource) = baseChainlinkAggregator.getRoundData(
      chainLinkOriginalId
    );

    if (chainLinkOriginalId < roundIdImplementation) {
      (, , , uint256 updatedAtNext, ) = baseChainlinkAggregator.getRoundData(chainLinkOriginalId + 1);
      updatedAt = determinePredictedUpdatedAtTime(uint256(_roundId) % (speedupFactor), updatedAtSource);

      if (updatedAt >= updatedAtNext) {
        (, int256 answerNext, uint256 startedAtNext, , uint80 _answeredInRoundNext) = baseChainlinkAggregator.getRoundData(chainLinkOriginalId + 1);

        return (_roundId, answerNext, startedAtNext, updatedAtNext, _answeredInRoundNext);
      }
    }

    return getRoundDataFromChainlinkData(_roundId % uint80(speedupFactor), roundIdSource, answerSource, updatedAtSource, _answeredInRoundSource);
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint80 roundIdSource, int256 answerSource, , uint256 updatedAtSource, uint80 _answeredInRoundSource) = baseChainlinkAggregator.latestRoundData();

    return
      getRoundDataFromChainlinkData(
        (block.timestamp - updatedAtSource) / fastOracleUpdateLength,
        roundIdSource,
        answerSource,
        updatedAtSource,
        _answeredInRoundSource
      );
  }
}

// Logic:
// Users call shift function with amount of pool token to shift from a market and target market.
// The contract immediately takes receipt of these tokens and intiates a redeem with the tokens.
// Once the next epoch for that market ends, the keeper will take receipt of the dai and immediately,
// Mint a position with all the dai received in the new market on the users behalf.
// We create a mintFor function on float that allows you to mint a position on another users behalf
// Think about shifts from the same market in consecutive epochs and how this should work

/** @title Shifting Contract */
contract Shifting is AccessControlledAndUpgradeable {
  using MathUintFloat for uint256;

  address public paymentToken;
  uint256 public constant SHIFT_ORDER_MAX_BATCH_SIZE = 20;

  // TODO: determine if this event is needed by the graph. Might be fine to save gas and infer that it is a shift action by patterns, or to omit parts of the event.
  event ShiftActionCreated(
    uint112 amountOfPoolToken,
    address indexed marketFrom,
    uint8 poolTypeFrom,
    address indexed marketTo,
    uint8 poolTypeTo,
    uint32 correspondingEpoch,
    address indexed user
  );

  struct ShiftAction {
    uint112 amountOfPoolToken;
    address marketFrom;
    IMarketCommon.PoolType poolTypeFrom;
    uint8 poolTierFrom;
    address marketTo;
    IMarketCommon.PoolType poolTypeTo;
    uint8 poolTierTo;
    uint32 correspondingEpoch;
    address user;
    bool isExecuted;
  }

  // address of market -> chronilogical list of shift orders
  mapping(address => mapping(uint256 => ShiftAction)) public shiftOrdersForMarket;
  mapping(address => uint256) public latestIndexForShiftAction;
  mapping(address => uint256) public latestExecutedShiftOrderIndex;

  mapping(address => bool) public validMarket;
  address[] public validMarketArray;

  function initialize(address _admin, address _paymentToken) external initializer {
    _AccessControlledAndUpgradeable_init(_admin);
    require(_paymentToken != address(0));
    paymentToken = _paymentToken;
  }

  /// @notice - this assumes that we will never have more than 16 tier types, and 16 tiers of a given tier type.
  // TODO: find a way to re-use the same function from the Market contract (less code duplication)
  function packPoolId(IMarketCommon.PoolType poolType, uint8 poolTier) internal pure virtual returns (uint8) {
    return (uint8(poolType) << 4) | poolTier;
  }

  function addValidMarket(address _market) external onlyRole(ADMIN_ROLE) {
    require(!validMarket[_market], "Market already valid");
    require(paymentToken == IMarket(_market).paymentToken(), "Require same payment token");
    validMarket[_market] = true;
    validMarketArray.push(_market);
    require(IERC20(paymentToken).approve(_market, type(uint256).max), "aprove failed");
  }

  function removeValidMarket(address _market) external onlyRole(ADMIN_ROLE) {
    require(validMarket[_market], "Market not valid");
    require(latestExecutedShiftOrderIndex[_market] == latestIndexForShiftAction[_market], "require no pendings shifts"); // This condition can be DDOS.

    validMarket[_market] = false;
    // TODO implement delete from the validMarketArray
  }

  function _getPoolTokenPrice(
    address market,
    IMarketCommon.PoolType poolType,
    uint256 poolIndex
  ) internal view returns (uint256) {
    uint32 currentExecutedEpoch = IMarket(market).get_epochInfo().latestExecutedEpochIndex;

    uint256 price = IMarket(market).get_poolToken_priceSnapshot(currentExecutedEpoch, poolType, poolIndex);

    return price;
  }

  function _getAmountInPaymentToken(
    address _marketFrom,
    IMarketCommon.PoolType poolType,
    uint256 poolIndex,
    uint112 amountPoolToken
  ) internal view returns (uint112) {
    uint256 poolTokenPriceInPaymentTokens = uint256(_getPoolTokenPrice(_marketFrom, poolType, poolIndex));
    return uint112((uint256(amountPoolToken) * poolTokenPriceInPaymentTokens) / 1e18);
  }

  function _validateShiftOrder(
    uint112 _amountOfPoolToken,
    address _marketFrom,
    IMarketCommon.PoolType _poolTypeFrom,
    uint8 _poolTierFrom,
    address _marketTo,
    IMarketCommon.PoolType _poolTypeTo,
    uint8 _poolTierTo
  ) internal view {
    require(validMarket[_marketFrom], "invalid from market");
    require(validMarket[_marketTo], "invalid to market");
    require(_poolTypeFrom == IMarketCommon.PoolType.LONG || _poolTypeFrom == IMarketCommon.PoolType.SHORT, "Bad pool type from");
    require(_poolTypeTo == IMarketCommon.PoolType.LONG || _poolTypeTo == IMarketCommon.PoolType.SHORT, "Bad pool type to");

    // NOTE: this transaction will fail if the from token is non-existent later in the function. No need to check here.
    address tokenTo = IMarket(_marketTo).get_pool_token(_poolTypeTo, _poolTierTo);

    require(tokenTo != address(0), "to pool does not exist");

    require(_getAmountInPaymentToken(_marketFrom, _poolTypeFrom, _poolTierFrom, _amountOfPoolToken) >= 10e18, "invalid shift amount"); // requires at least 10e18 worth of DAI to shift the position.
    // This is important as position may still gain or lose value on current value
    // until the redeem is final. If this is the case the 1e18 mint limit on the market could
    // be violated bruicking the shifter if not careful.
  }

  function shiftOrder(
    uint112 _amountOfPoolToken,
    address _marketFrom,
    IMarketCommon.PoolType _poolTypeFrom,
    uint8 _poolTierFrom,
    address _marketTo,
    IMarketCommon.PoolType _poolTypeTo,
    uint8 _poolTierTo
  ) external {
    // Note add fees

    _validateShiftOrder(_amountOfPoolToken, _marketFrom, _poolTypeFrom, _poolTierFrom, _marketTo, _poolTypeTo, _poolTierTo);

    // User sends tokens to this contract. Will require approval or signature.
    address token = IMarket(address(_marketFrom)).getPoolTokenAddress(_poolTypeFrom, _poolTierFrom);

    //slither-disable-next-line unchecked-transfer
    IPoolToken(token).transferFrom(msg.sender, address(this), _amountOfPoolToken);

    // Redeem needs to execute upkeep otherwise stale epoch for order may be used
    if (_poolTypeFrom == IMarketCommon.PoolType.LONG) {
      IMarket(_marketFrom).redeemLong(_poolTierFrom, _amountOfPoolToken);
    } else if (_poolTypeFrom == IMarketCommon.PoolType.SHORT) {
      IMarket(_marketFrom).redeemShort(_poolTierFrom, _amountOfPoolToken);
    }

    uint32 currentEpochIndex = uint32(IMarket(_marketFrom).get_oracleManager().getCurrentEpochIndex());

    uint256 newLatestIndexForShiftAction = latestIndexForShiftAction[_marketFrom] + 1;
    latestIndexForShiftAction[_marketFrom] = newLatestIndexForShiftAction;

    shiftOrdersForMarket[_marketFrom][newLatestIndexForShiftAction] = ShiftAction({
      amountOfPoolToken: _amountOfPoolToken,
      marketFrom: _marketFrom,
      poolTypeFrom: _poolTypeFrom,
      poolTierFrom: _poolTierFrom,
      marketTo: _marketTo,
      poolTypeTo: _poolTypeTo,
      poolTierTo: _poolTierTo,
      correspondingEpoch: currentEpochIndex, // pull current epoch from the market (upkeep must happen first)
      user: msg.sender,
      isExecuted: false
    });

    emit ShiftActionCreated(
      _amountOfPoolToken,
      _marketFrom,
      packPoolId(_poolTypeFrom, _poolTierFrom),
      _marketTo,
      packPoolId(_poolTypeTo, _poolTierTo),
      currentEpochIndex,
      msg.sender
    );
  }

  function _shouldExecuteShiftOrder()
    internal
    view
    returns (
      bool canExec,
      address market,
      uint256 executeUpUntilAndIncludingThisIndex
    )
  {
    for (uint32 index = 0; index < validMarketArray.length; index++) {
      market = validMarketArray[index];
      uint256 _latestExecutedShiftOrderIndex = latestExecutedShiftOrderIndex[market];
      uint256 _latestIndexForShiftAction = latestIndexForShiftAction[market];

      if (_latestExecutedShiftOrderIndex == _latestIndexForShiftAction) {
        continue; // skip to next market, no outstanding orders to check.
      }

      uint32 latestExecutedEpochIndex = IMarket(market).get_epochInfo().latestExecutedEpochIndex;

      executeUpUntilAndIncludingThisIndex = _latestExecutedShiftOrderIndex;
      uint256 orderDepthToSearch = Math.min(_latestIndexForShiftAction, _latestExecutedShiftOrderIndex + SHIFT_ORDER_MAX_BATCH_SIZE);
      for (uint256 batchIndex = _latestExecutedShiftOrderIndex + 1; batchIndex <= orderDepthToSearch; batchIndex++) {
        // stop if more than 10.
        ShiftAction memory _shiftOrder = shiftOrdersForMarket[market][batchIndex];
        if (_shiftOrder.correspondingEpoch <= latestExecutedEpochIndex) {
          executeUpUntilAndIncludingThisIndex++;
        } else {
          break; // exit loop, no orders after will satisfy this condition.
        }
      }
      if (executeUpUntilAndIncludingThisIndex > _latestExecutedShiftOrderIndex) {
        return (true, market, executeUpUntilAndIncludingThisIndex);
      }
    }
    return (false, address(0), 0);
  }

  function shouldExecuteShiftOrder() external view returns (bool _canExec, bytes memory execPayload) {
    (bool canExec, address market, uint256 executeUpUntilAndIncludingThisIndex) = _shouldExecuteShiftOrder();

    return (canExec, abi.encodeCall(this.executeShiftOrder, (market, executeUpUntilAndIncludingThisIndex)));
  }

  function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
    (bool canExec, address market, uint256 executeUpUntilAndIncludingThisIndex) = _shouldExecuteShiftOrder();

    return (canExec, abi.encode(market, executeUpUntilAndIncludingThisIndex));
  }

  function _executeShiftOrder(address _marketFrom, uint256 _executeUpUntilAndIncludingThisIndex) internal {
    // First claim all oustanding DAI.

    uint256 indexOfNextShiftToExecute = latestExecutedShiftOrderIndex[_marketFrom] + 1;
    require(_executeUpUntilAndIncludingThisIndex >= indexOfNextShiftToExecute, "Cannot execute past");

    for (uint256 _indexOfShift = indexOfNextShiftToExecute; _indexOfShift <= _executeUpUntilAndIncludingThisIndex; _indexOfShift++) {
      ShiftAction memory _shiftOrder = shiftOrdersForMarket[_marketFrom][_indexOfShift];

      // TODO: this code is inefficient if we end up settling the same pool multiple times.
      //       we should pass in an array of the pools we want to settle to keep this lean.
      // https://github.com/Float-Capital/monorepo/issues/3462#issuecomment-1266872958
      IMarket(_marketFrom).settlePoolUserRedeems(address(this), _shiftOrder.poolTypeFrom, _shiftOrder.poolTierFrom);

      require(!_shiftOrder.isExecuted, "Shift already executed"); //  Redundant but wise to have
      shiftOrdersForMarket[_marketFrom][_indexOfShift].isExecuted = true;

      // Calculate the collateral amount to be used for the new mint.
      uint256 poolToken_price = IMarket(_shiftOrder.marketFrom).get_poolToken_priceSnapshot(
        _shiftOrder.correspondingEpoch,
        _shiftOrder.poolTypeFrom,
        _shiftOrder.poolTierFrom
      );
      assert(poolToken_price != 0); // should in theory enforce that the latestExecutedEpoch on the market is >= _shiftOrderEpoch.
      uint256 amountPaymentTokenToMint = uint256(_shiftOrder.amountOfPoolToken).mul(poolToken_price); // could save gas and do this calc here.

      if (_shiftOrder.poolTypeTo == IMarketCommon.PoolType.LONG) {
        IMarket(_shiftOrder.marketTo).mintLongFor(_shiftOrder.poolTierTo, uint112(amountPaymentTokenToMint), _shiftOrder.user);
      } else if (_shiftOrder.poolTypeTo == IMarketCommon.PoolType.SHORT) {
        IMarket(_shiftOrder.marketTo).mintShortFor(_shiftOrder.poolTierTo, uint112(amountPaymentTokenToMint), _shiftOrder.user);
      }
    }

    latestExecutedShiftOrderIndex[_marketFrom] = _executeUpUntilAndIncludingThisIndex;
  }

  function executeShiftOrder(address _marketFrom, uint256 _executeUpUntilAndIncludingThisIndex) external {
    _executeShiftOrder(_marketFrom, _executeUpUntilAndIncludingThisIndex);
  }

  function performUpkeep(bytes calldata dataForUpkeep) external {
    (address marketFrom, uint256 executeUpUntilAndIncludingThisIndex) = abi.decode(dataForUpkeep, (address, uint256));

    _executeShiftOrder(marketFrom, executeUpUntilAndIncludingThisIndex);
  }
}

contract ShiftingProxy is AccessControlledAndUpgradeableModifiers {
  Shifting public currentShifter;

  event ChangeShifter(Shifting newShifter);

  function initialize(Shifting _currentShifter) external initializer {
    _AccessControlledAndUpgradeable_init(msg.sender);

    currentShifter = _currentShifter;
    emit ChangeShifter(_currentShifter);
  }

  function changeShifter(Shifting _currentShifter) external adminOnly {
    currentShifter = _currentShifter;
    emit ChangeShifter(_currentShifter);
  }

  function shouldExecuteShiftOrder() external view returns (bool _canExec, bytes memory execPayload) {
    return currentShifter.shouldExecuteShiftOrder();
  }

  function checkUpkeep(bytes calldata data) external view returns (bool upkeepNeeded, bytes memory performData) {
    return currentShifter.checkUpkeep(data);
  }

  function executeShiftOrder(address _marketFrom, uint256 _executeUpUntilAndIncludingThisIndex) external {
    currentShifter.executeShiftOrder(_marketFrom, _executeUpUntilAndIncludingThisIndex);
  }

  function performUpkeep(bytes calldata dataForUpkeep) external {
    currentShifter.performUpkeep(dataForUpkeep);
  }
}