// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../kernel/interfaces/IKernel.sol";
import "../libraries/Exceptions.sol";
import "./UpgradeableApp.sol";

abstract contract App is UpgradeableApp, Initializable {
    IKernel internal _kernel;
    uint8 private _nextRoleId = 0;

    uint256[99] private __gap;

    event Init(IKernel kernel);
    event Upgrade(address code);

    modifier requirePermission(uint8 permissionId) {
        require(_hasPermission(permissionId), Exceptions.INVALID_AUTHORIZATION_ERROR);
        _;
    }

    modifier onlyKernel() {
        require(msg.sender == address(_kernel), Exceptions.INVALID_AUTHORIZATION_ERROR);
        _;
    }

    function upgrade(address appCode) external onlyKernel {
        _getImplementationSlot().value = appCode;

        emit Upgrade(appCode);
    }

    function implementation() external view returns (address) {
        return _getImplementationSlot().value;
    }

    function __App_init(IKernel kernel) internal onlyInitializing {
        _kernel = kernel;

        emit Init(kernel);
    }

    function _initNextRole() internal returns (uint8) {
        assert(_nextRoleId < 15);

        return _nextRoleId++;
    }

    function _hasPermission(uint8 permissionId) internal view returns (bool) {
        return _kernel.hasPermission(msg.sender, address(this), permissionId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./UpgradeableApp.sol";

contract AppProxy is Proxy, UpgradeableApp {
    uint256[100] private __gap;

    constructor(address implementation_) {
        _getImplementationSlot().value = implementation_;
    }

    function _implementation() internal view override returns (address) {
        return _getImplementationSlot().value;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract UpgradeableApp {
    bytes32 private constant _IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("co.superdao.app.proxy.implementation")) - 1);

    uint256[100] private __gap;

    function _getImplementationSlot() internal pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./interfaces/IACL.sol";
import "../libraries/Permission.sol";
import "../libraries/Exceptions.sol";
import "./BaseStorage.sol";

contract ACL is BaseStorage, IACL {
    uint8 constant ACL_SLOT_SIZE = 16;
    uint8 public immutable KERNEL_ADMIN = _initNextRole();

    uint256[100] private __gap;

    function addPermission(
        bytes32 requesterAppId,
        bytes32 appId,
        uint8 permissionId
    ) external requirePermission(KERNEL_ADMIN) {
        _addPermission(requesterAppId, appId, permissionId);
    }

    function removePermission(
        bytes32 requesterAppId,
        bytes32 appId,
        uint8 permissionId
    ) external requirePermission(KERNEL_ADMIN) {
        _removePermission(requesterAppId, appId, permissionId);
    }

    function getPermissions(bytes32 entity, bytes32 app) external view returns (bytes2) {
        (uint16 row, uint256 column) = _calculateIndex(_appInfo[entity].index);

        return _appInfo[app].slots[row][column];
    }

    function hasPermission(
        address entityAddress,
        address appAddress,
        uint8 permissionId
    ) external view returns (bool) {
        bytes2 permissions = Permission._getCode(permissionId);

        bytes32 entityId = _appIdByAddress[entityAddress];
        bytes32 appId = _appIdByAddress[appAddress];

        require(_appInfo[entityId].addr == entityAddress, Exceptions.INVARIANT_ERROR);
        require(_appInfo[appId].addr == appAddress, Exceptions.INVARIANT_ERROR);

        (uint16 row, uint256 column) = _calculateIndex(_appInfo[entityId].index);

        return (_appInfo[appId].slots[row][column] & permissions) == permissions;
    }

    function _addPermission(
        bytes32 requesterAppId,
        bytes32 appId,
        uint8 permissionId
    ) internal {
        (uint16 row, uint256 column) = _calculateIndex(_appInfo[requesterAppId].index);

        _appInfo[appId].slots[row][column] |= Permission._getCode(permissionId);
    }

    function _removePermission(
        bytes32 requesterAppId,
        bytes32 appId,
        uint8 permissionId
    ) internal {
        (uint16 row, uint256 column) = _calculateIndex(_appInfo[requesterAppId].index);

        _appInfo[appId].slots[row][column] ^= Permission._getCode(permissionId);
    }

    function _calculateIndex(uint16 index) private pure returns (uint16, uint256) {
        uint16 row = index / ACL_SLOT_SIZE;
        uint256 column = index % ACL_SLOT_SIZE;

        return (row, column);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./ACL.sol";
import "./BaseStorage.sol";
import "./interfaces/IAppManager.sol";
import "../apps/AppProxy.sol";

contract AppManager is ACL, IAppManager {
    string constant APP_WAS_INITED_ERROR = "APP_WAS_INITED";

    uint8 constant SLOT_SIZE = 16;

    uint256[100] private __gap;

    function deployApp(
        bytes32 id,
        address appCode,
        bytes calldata data
    ) external requirePermission(KERNEL_ADMIN) returns (address) {
        address appProxy = address(new AppProxy(appCode));
        _setApp(id, appProxy, true);

        (bool success, ) = appProxy.call(data);
        require(success, Exceptions.INVALID_INITIALIZATION_ERROR);

        return appProxy;
    }

    function connectApp(
        bytes32 id,
        address appAddress,
        bool isNative
    ) external requirePermission(KERNEL_ADMIN) {
        _setApp(id, appAddress, isNative);
    }

    function resetApp(
        bytes32 id,
        address appAddress,
        bool isNative
    ) external requirePermission(KERNEL_ADMIN) {
        _resetApp(id, appAddress, isNative);
    }

    function getAppAddress(bytes32 id) external view returns (address) {
        return _appInfo[id].addr;
    }

    function _resetApp(
        bytes32 id,
        address app,
        bool isNative
    ) internal {
        delete _appIdByAddress[_appInfo[id].addr];

        _appInfo[id].addr = app;
        _appInfo[id].isActive = true;
        _appInfo[id].isNative = isNative;

        _appIdByAddress[app] = id;
    }

    function _setApp(
        bytes32 id,
        address app,
        bool isNative
    ) internal {
        require(_appInfo[id].addr == address(0x00) && _appIdByAddress[app] == bytes32(0), APP_WAS_INITED_ERROR);

        _appInfo[id].addr = app;
        _appInfo[id].index = _nextIndex;
        _appInfo[id].isActive = true;
        _appInfo[id].isNative = isNative;

        _appIdByAddress[app] = id;
        _nextIndex++;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../apps/App.sol";
import "./interfaces/IKernel.sol";

contract BaseStorage is ContextUpgradeable, App {
    struct AppInfo {
        address addr;
        uint16 index;
        bool isActive;
        bool isNative;
        mapping(uint16 => bytes2[16]) slots;
    }

    uint16 internal _nextIndex;
    mapping(address => bytes32) internal _appIdByAddress;
    mapping(bytes32 => AppInfo) internal _appInfo;

    uint256[97] private __gap;

    function __BaseStorage_init() internal onlyInitializing {
        __App_init(IKernel(address(this)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./ACL.sol";
import "./AppManager.sol";
import "../updateManager/IUpdateManager.sol";
import "../libraries/AppsIds.sol";
import "../libraries/Exceptions.sol";
import "./interfaces/IKernel.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Kernel is Initializable, AppManager, IKernel {
    IUpdateManager internal _updateManager;

    function initialize(IUpdateManager updateManager, address sudo) external initializer {
        __BaseStorage_init();
        _setApp(AppsIds.KERNEL, address(this), true);
        _setApp(AppsIds.SUDO, sudo, false);
        _addPermission(AppsIds.SUDO, AppsIds.KERNEL, KERNEL_ADMIN);
        _updateManager = updateManager;
    }

    function getUpdateManager() external view returns (address) {
        return address(_updateManager);
    }

    function upgradeAppCode(bytes32 id, address appCode) external requirePermission(KERNEL_ADMIN) {
        require(_appInfo[id].isNative && _appInfo[id].addr != address(0x00), Exceptions.INVARIANT_ERROR);

        App app = App(_appInfo[id].addr);
        app.upgrade(appCode);
    }

    function upgradeApp(bytes32 id) external requirePermission(KERNEL_ADMIN) {
        require(_appInfo[id].isNative && _appInfo[id].addr != address(0x00), Exceptions.INVARIANT_ERROR);

        App app = App(_appInfo[id].addr);

        address newCode = _updateManager.getLastAppCode(id);

        require(app.implementation() != newCode, Exceptions.INVARIANT_ERROR);

        app.upgrade(newCode);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

interface IACL {
    function addPermission(
        bytes32 entity,
        bytes32 app,
        uint8 permission
    ) external;

    function removePermission(
        bytes32 entity,
        bytes32 app,
        uint8 permission
    ) external;

    function getPermissions(bytes32 entity, bytes32 app) external view returns (bytes2);

    function hasPermission(
        address entityAddress,
        address appAddress,
        uint8 permissionId
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

interface IAppManager {
    function deployApp(
        bytes32 id,
        address appCode,
        bytes memory data
    ) external returns (address);

    function connectApp(
        bytes32 id,
        address appAddress,
        bool isNative
    ) external;

    function resetApp(
        bytes32 id,
        address appAddress,
        bool isNative
    ) external;

    function getAppAddress(bytes32 id) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./IACL.sol";
import "./IAppManager.sol";

interface IKernel is IACL, IAppManager {
    function getUpdateManager() external view returns (address);

    function upgradeApp(bytes32 id) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

library AppsIds {
    bytes32 constant KERNEL = keccak256(abi.encodePacked("KERNEL"));
    bytes32 constant SUDO = keccak256(abi.encodePacked("SUDO"));
    bytes32 constant ERC721 = keccak256(abi.encodePacked("ERC721"));
    bytes32 constant ADMIN_CONTROLLER = keccak256(abi.encodePacked("ADMIN")); //TODO: renamde admin to ADMIN_CONTROLLER
    bytes32 constant ERC721_OPEN_SALE = keccak256(abi.encodePacked("ERC721_OPEN_SALE"));
    bytes32 constant ERC721_WHITELIST_SALE = keccak256(abi.encodePacked("ERC721_WHITELIST_SALE"));
    bytes32 constant TREASURY = keccak256("WALLET"); //TODO: rename wallet to TREASURY
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Exceptions {
    string constant INVALID_INITIALIZATION_ERROR = "INITIALIZATION";
    string constant INVALID_AUTHORIZATION_ERROR = "AUTHORIZATION";
    string constant INVARIANT_ERROR = "INVARIANT";
    string constant VALIDATION_ERROR = "VALIDATION";
    string constant UNAVAILABLE_ERROR = "UNAVAILABLE";
    string constant NOT_ACTIVE_ERROR = "NOT_ACTIVE";
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

library Permission {
    string constant INVALID_PERMISSION_ID_ERROR = "INVALID_PERMISSION_ID";

    function _getCode(uint8 id) internal pure returns (bytes2) {
        require(id < 16, INVALID_PERMISSION_ID_ERROR);
        return bytes2(uint16(1 << id));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

interface IUpdateManager {
    function upgrade(address appCode) external;

    function setAppCode(bytes32 app, address code) external;

    function getLastAppCode(bytes32 app) external view returns (address);

    function getAppCodeHistory(bytes32 app) external view returns (address[] memory);
}