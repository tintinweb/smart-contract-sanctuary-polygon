// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IKeeperRegistry.sol";

/**
 * @dev owned by governance contract
 */
contract KeeperRegistry is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IKeeperRegistry
{
    uint256 public maxNumKeepers; //Max # of keepers to allow at a time
    uint256 public currentNumKeepers; //Current # of keepers. This variable may end up being removed, depending on final orchestrator design.

    // Bond token
    IERC20 public bondCoin; //ERC20 token used to provide bonds
    uint256 public bondAmount; //Amount of bondCoin required to become a keeper
    uint256 public freeCoin; //bondcoin no longer affiliated with any keeper (due to slashing etc.)

    /**
     * Slash safety period--if a keeper leaves, this is the amount of time (in seconds) they must 
        wait before they can withdraw their bond.
     */
    uint256 public transferDelay;

    mapping(uint256 => address) public keeperLicenses; // This mapping is pretty much just used to track which licenses are free.
    mapping(address => WorkerDetails) public registry; // Registry of keeper info for keepers and former keepers.

    function initialize(
        address coinAddress,
        uint256 keeperTransferDelay,
        uint256 maxKeepers,
        uint256 bondSize
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        bondCoin = IERC20(coinAddress);
        transferDelay = keeperTransferDelay;
        maxNumKeepers = maxKeepers;
        require(bondSize != 0, "SIZE");
        bondAmount = bondSize;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev setup utility function for owner to add initial keepers. Addresses must each be unique and not hold any bondToken.
     * @param joiners array of addresses to become keepers.
     * note that this function will pull bondToken from the owner equal to bondAmount * numJoiners.
     * note that this function assumes that the keeper registry currently has no keepers. It will revert if this assumption fails.
     */
    function joiningForOwner(address[] calldata joiners) public onlyOwner {
        // Cache last license index
        uint256 lastKeeperLicense = joiners.length + 1;

        // Cache bond amount
        uint256 _bondAmount = bondAmount;

        bondCoin.transferFrom(
            msg.sender,
            address(this),
            _bondAmount * joiners.length
        );

        // Ensure not too many keepers are being added.
        require(joiners.length <= maxNumKeepers, "MAX_KEEPERS");

        // Add each keeper to the registry
        for (uint256 i = 1; i != lastKeeperLicense; i++) {
            //Make sure license is not already claimed by another keeper
            require(keeperLicenses[i] == address(0), "Address not new.");

            // Register keeper to license
            keeperLicenses[1] = joiners[i - 1];

            // Register license (and other info) to keeper
            registry[joiners[i - 1]] = WorkerDetails({
                bondHeld: _bondAmount,
                licenseNumber: i,
                leaveTimestamp: 0
            });
        }

        currentNumKeepers += joiners.length;
    }

    /**
     * @param amount Amount of bondCoin to be deposited.
     * @dev this function has three uses:
        1. If the caller is a keeper, they can increase their bondHeld by amount. This helps to avoid slashing.
        2. If the caller is not a keeper or former keeper, they can attempt to claim a keeper license and become a keeper.
        3. If the caller is a former keeper, they can attempt to cancel their leave request, claim a keeper license, and become a keeper.
        In all 3 cases registry[msg.sender].bondHeld is increased by amount. In the latter 2, msg.sender's bondHeld after the transaction must be >= bondAmount.
     */
    function join(uint256 licenseNumber, uint256 amount) public {
        //Transfer in bond
        if (amount != 0) {
            bondCoin.transferFrom(msg.sender, address(this), amount);
        }

        // Look up msg.sender in the mapping
        WorkerDetails memory _workerDetails = registry[msg.sender];

        if (_workerDetails.licenseNumber != 0) {
            // If they have a license, they're a keeper, and amount will go towards their bondHeld
            registry[msg.sender].bondHeld = _workerDetails.bondHeld + amount;
        } else {
            /*
                Two scenarios here:
                1. If their bondAmount is zero and their leaveTimestamp is zero, they are not yet a keeper, so this is a new address attempting to become a keeper.
                2. If they are queued to leave but have not yet left, they are not a keeper, so this will cancel their leave request (by zeroing out leaveTimestamp) 
                and attempt to make them a keeper.
                Either way the solution is the same -- if their new bondAmount is enough, they become a keeper with no leave date. Otherwise, this function reverts.
            */

            // Make sure requested license is valid and available
            require(
                keeperLicenses[licenseNumber] == address(0),
                "License not available."
            );
            require(licenseNumber != 0, "LICENSE_NUMBER");
            require(licenseNumber <= maxNumKeepers, "LICENSE_NUMBER");

            // Join must be sufficient to become a keeper
            uint256 newBondAmount = _workerDetails.bondHeld + amount;
            require(newBondAmount >= bondAmount, "Insufficient bond amount.");

            currentNumKeepers += 1;

            // Register license/bond amount with keeper
            registry[msg.sender] = WorkerDetails({
                bondHeld: newBondAmount,
                licenseNumber: licenseNumber,
                leaveTimestamp: 0
            });

            // Register keeper with license
            keeperLicenses[licenseNumber] = msg.sender;

            emit permissionChanged(msg.sender, permissionType.FULL);
        }
    }

    function queueToLeave() public {
        WorkerDetails memory _workerDetails = registry[msg.sender];
        require(
            _workerDetails.licenseNumber != 0,
            "msg.sender is already not a keeper."
        );

        //Remove permissions immediately, allow keeper to remove funds once a transferDelay has passed. This ensures that keeper can be slashed if they misbehaved just before leaving.
        registry[msg.sender] = WorkerDetails({
            bondHeld: _workerDetails.bondHeld,
            licenseNumber: 0,
            leaveTimestamp: block.timestamp + transferDelay
        });
        keeperLicenses[_workerDetails.licenseNumber] = address(0);

        // Decrease numKeepers count
        currentNumKeepers -= 1;

        emit permissionChanged(msg.sender, permissionType.NONE);
    }

    /**
     * @dev addresses call this after they have queued to leave and waited the requisite amount of time.
     */
    function leave() external {
        WorkerDetails memory info = registry[msg.sender];
        require(
            info.leaveTimestamp != 0 && info.leaveTimestamp < block.timestamp,
            "LEAVE_DELAY"
        );
        bondCoin.transfer(msg.sender, info.bondHeld);
        delete registry[msg.sender];
    }

    /**
     * @dev returns true if the given address has the power to vote, reverts otherwise. This function is built to be called by the orchestrator.
     */
    function checkLicense(address targetAddress)
        public
        view
        returns (uint256 licenseNumber)
    {
        licenseNumber = registry[targetAddress].licenseNumber;
        require(licenseNumber != 0, "NOT_A_KEEPER");
    }

    /**
     * @dev slashes a keeper, removing their permissions and forfeiting their bond.
     * @param targetKeeper keeper to denounce
     * @param amount amount of bondCoin to slash
     * note that the keeper will only lose their license if, post-slash, their bond held is less than bondAmount.
     */
    function denounce(address targetKeeper, uint256 amount) external onlyOwner {
        WorkerDetails memory _workerDetails = registry[targetKeeper];

        //Remove bondCoin from keeper who is being denounced, add to freeCoin (to be withdrawn by owner)
        uint256 currentBondHeld = _workerDetails.bondHeld;

        // If slash amount is greater than keeper's held bond, just slash 100% of their bond
        if (currentBondHeld < amount) {
            amount = currentBondHeld;
        }

        // Slash keeper's bond by amount
        uint256 newBond = currentBondHeld - amount;
        registry[targetKeeper].bondHeld = newBond;

        // Add keeper's slashed bond tokens to freeCoin
        freeCoin += amount;

        //Remove user as keeper if they are below threshold, and are a keeper
        if (newBond < bondAmount && _workerDetails.licenseNumber != 0) {
            keeperLicenses[_workerDetails.licenseNumber] = address(0);
            registry[targetKeeper].licenseNumber = 0;
            currentNumKeepers -= 1;
        }

        emit permissionChanged(msg.sender, permissionType.SLASHED);
    }

    /**
     * @dev withdraws slashed tokens from the vault and sends them to targetAddress.
     * @param amount amount of bondCoin to withdraw
     * @param targetAddress address receiving the tokens
     */
    function withdrawFreeCoin(uint256 amount, address targetAddress)
        external
        onlyOwner
    {
        freeCoin -= amount;
        bondCoin.transfer(targetAddress, amount);
    }

    /**
     * @dev change bondAmount to a new value.
     * @dev Does not change existing keeper permissions. If the bondAmount is being increased, existing keepers will not be slashed or removed. 
            note, they will still be able to vote until they are slashed.
     * @param amount new bondAmount.
     */
    function changeBondAmount(uint256 amount) external onlyOwner {
        bondAmount = amount;
    }

    /**
     * @dev change numKeepers to a new value. If numKeepers is being reduced, this will not remove any keepers, nor will it change orchestrator requirements.
        However, it will render keeper licenses > maxNumKeepers invalid and their votes will stop counting.
     */
    function changeMaxKeepers(uint16 newNumKeepers) external onlyOwner {
        maxNumKeepers = newNumKeepers;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import "./interfaces/IGasVault.sol";
import "./interfaces/IOrchestrator.sol";
import "./KeeperRegistry.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/*
    note there is no current on-chain method for slashing misbehaving strategies. The worst misbehaving strategies can do is trigger repeated calls to this contract.

    note This contract relies on the assumption that jobs can only be created by vault and strategy creators. The most serious incorrect target addresses (the orchestrator
    address and the gasVault address) are blocked, but other vaults are protected by the keepers themselves.
 */
contract Orchestrator is IOrchestrator, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant actionThresholdPercent = 51; //If an action is approved by >= approvalThresholdPercent members, it is approved

    //Address of GasVault, which is contract used to recompense keepers for gas spent executing actions
    IGasVault internal gasVault;

    //Address of Keeper Registry, which handles keeper verification
    KeeperRegistry internal keeperRegistry;

    uint256 public rewardPerAction;

    /*
        bytes32 is hash of action. Calculated using keccak256(abi.encode(targetAddress, jobEpoch, calldatas))

        Action approval meaning:
        0: Pending
        1: Rejected
        2: Approved
        Both votes and overall approval status follow this standard.
    */
    mapping(bytes32 => ActionState) public actions;

    /*  
        actionHash => uint256 where each bit represents one keeper vote.
    */
    mapping(bytes32 => uint256) public voteBitmaps;

    function initialize(KeeperRegistry _keeperRegistry, uint256 _rewardPerAction)
        external
        initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        keeperRegistry = _keeperRegistry;
        rewardPerAction = _rewardPerAction;
    }

    function setGasVault(address _gasVault) external onlyOwner {
        gasVault = IGasVault(_gasVault);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev set the reward given to operator nodes for their participation in a strategy calculation
     * @param _rewardPerAction is amount of steer token to be earned as a reward, per participating operator node per action.
     */
    function setRewardPerAction(uint256 _rewardPerAction) external onlyOwner {
        rewardPerAction = _rewardPerAction;
    }

    /**
     * @dev vote (if you are a keeper) on a given action proposal
     * @param actionHash is the hash of the action to be voted on
     * @param vote is the vote to be cast. false: reject, true: approve. false only has an effect if the keeper previously voted true. It resets their vote to false.
     */
    function voteOnAction(bytes32 actionHash, bool vote)
        public
    {
        // Get voter keeper license, use to construct bitmap. Revert if no license.
        uint256 license = keeperRegistry.checkLicense(msg.sender);
        uint256 bitmap = 1 << license;
        if (vote) {
            // Add vote to bitmap through OR
            voteBitmaps[actionHash] |= bitmap;
        } else {
            // Remove vote from bitmap through XOR
            voteBitmaps[actionHash] ^= bitmap;
        }
    }

    /**
     * @dev Returns true if an action with given `actionId` is approved by all existing members of the group.
     * It’s up to the contract creators to decide if this method should look at majority votes (based on ownership)
     * or if it should ask consent of all the users irrespective of their ownerships.
     */
    function actionApprovalStatus(bytes32 actionHash) public view returns (bool) {
        uint256 maxLicenseId = keeperRegistry.maxNumKeepers() + 1;
        uint256 yesVotes;
        uint256 voteBitmap = voteBitmaps[actionHash];
        for (uint256 i = 1; i != maxLicenseId; i++) {
            uint256 voteDifference = 1 << i;
            if ((voteBitmap & voteDifference) == voteDifference) {
                yesVotes++;
            }
        }

        uint256 numKeepers = keeperRegistry.currentNumKeepers();
        // If there happen to be no keepers, div by zero error will happen here, preventing actions from being executed.
        if ((yesVotes * 100) / numKeepers >= actionThresholdPercent) {
            return true;
        } else return false;
    }

    /**
     * @dev Executes the action referenced by the given `actionId` as long as it is approved actionThresholdPercent of group.
     * The executeAction executes all methods as part of given action in an atomic way (either all should succeed or none should succeed).
     * Once executed, the action should be set as executed (state=3) so that it cannot be executed again.

     * @param targetAddress is the address which will be receiving the action's calls.
     * @param jobEpoch is the job epoch of this action.
     * @param calldatas is the COMPLETE calldata of each method to be called
     * note that the hash is created using the sliced calldata, but here it must be complete or the method will revert.
     * @param timeIndependentLengths--For each calldata, the number of bytes that is NOT time-sensitive. If no calldatas are time-sensitive, just pass an empty array.
     *
     * Emits an {ActionStateChanged} event.
     * dynamicData is an encoded bytes[] array of data to be appended to each calldata.
     */
    function executeAction(
        address targetAddress,
        uint256 jobEpoch,
        bytes[] calldata calldatas,
        uint256[] calldata timeIndependentLengths
    )
        external
        returns (ActionState)
    {
        //Make sure this action isn't illegal
        require(targetAddress != address(this), "Invalid target address");
        require(targetAddress != address(gasVault), "Invalid target address");

        //Make sure this action is approved and has not yet been executed
        bytes32 newActionHash;
        if (timeIndependentLengths.length == 0) {
            // If none of the data is time-sensitive, just use passed in calldatas
            newActionHash = keccak256(
                abi.encode(targetAddress, jobEpoch, calldatas)
            );
        } else {
            // If some of it is time-sensitive, create a new array using timeIndependentLengths to represent what was originally passed in, then compare that hash instead
            uint256 numCalldatas = timeIndependentLengths.length;

            //Construct original calldatas
            bytes[] memory timeIndependentCalldatas = new bytes[](numCalldatas);
            for (uint256 i = 0; i != numCalldatas; i++) {
                timeIndependentCalldatas[i] = calldatas[i][:timeIndependentLengths[i]];
            }

            //Create hash
            newActionHash = keccak256(
                abi.encode(targetAddress, jobEpoch, timeIndependentCalldatas)
            );
        }

        // Ensure action has not yet been executed
        require(
            actions[newActionHash] == ActionState.PENDING,
            "Action already executed"
        );

        // Have this keeper vote for action. This also checks that the caller is a keeper.
        voteOnAction(newActionHash, true);

        //Check action approval status, execute accordingly.
        bool actionApproved = actionApprovalStatus(newActionHash);
        if (actionApproved) {
            //Set aside gas for this action. Keeper will be reimbursed ((originalGas - [gas remaining when returnGas is called]) * gasPrice) wei.
            uint256 originalGas = gasleft();

            bool success;

            (success, ) = address(this).call{
                gas: gasVault.gasAvailableForTransaction(targetAddress)
            }( //Withdraw required gas from strategy account
                abi.encodeWithSignature(
                    "_executeAction(address,bytes)",
                    targetAddress,
                    abi.encode(calldatas)
                )
            );

            //Reimburse keeper for gas used. It will be stored inside the GasVault.
            gasVault.reimburseGas(targetAddress, originalGas, newActionHash);

            //Record result
            if (success) {
                emit ActionExecuted(
                    newActionHash,
                    _msgSender(),
                    rewardPerAction
                );

                //Set state to completed
                actions[newActionHash] = ActionState.COMPLETED;

                return ActionState.COMPLETED;
            } else {
                emit ActionFailed(newActionHash);

                return ActionState.PENDING;
            }
        } else   {
            revert("Votes lacking; state still pending");
        }
    }

    function _executeAction(
        address targetAddress,
        bytes calldata encodedCalldata
    ) external {
        require(
            msg.sender == address(this),
            "Only Orchestrator can call this function"
        );

        bytes[] memory calldatas = abi.decode(encodedCalldata, (bytes[]));

        for (uint256 i = 0; i != calldatas.length; i++) {
            (bool success, ) = targetAddress.call(calldatas[i]);

            //If any method fails, the action will revert, reverting all other methods but still pulling gas used from the GasVault.
            require(success);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

interface IGasVault {
    event deposited(
        address indexed origin,
        address indexed target,
        uint256 amount
    );
    event withdrawn(
        address indexed targetAddress,
        address indexed to,
        uint256 amount
    );
    event etherUsed(
        address indexed account,
        uint256 amount,
        bytes32 newActionHash
    );

    function deposit(address targetAddress) external payable;

    /**
     * @dev Withdraws given amount of ether from the vault.
     * @param amount Amount of ether to withdraw, in terms of wei.
     */
    function withdraw(
        uint256 amount,
        address targetAddress,
        address to
    ) external;

    function withdraw(uint256 amount, address to) external;

    /**
     * @dev calculates total transactions remaining. What this means is--assuming that each method (action paid for by the strategist/job owner)
     *      costs max amount of gas at max gas price, and uses the max amount of actions, how many transactions can be paid for?
     *      In other words, how many actions can this vault guarantee.
     * @param targetAddress is address actions will be performed on, and address paying gas for those actions.
     * @param highGasEstimate is highest reasonable gas price assumed for the actions
     * @return total transactions remaining, assuming max gas is used in each Method
     */
    function transactionsRemaining(
        address targetAddress,
        uint256 highGasEstimate
    ) external view returns (uint256);

    /**
     * @param targetAddress is address actions will be performed on, and address paying gas for those actions.
     * @return uint256 gasAvailable (representing amount of gas available per Method).
     */
    function gasAvailableForTransaction(address targetAddress)
        external
        view
        returns (uint256);

    /**
     * @param targetAddress is address actions were performed on
     * @param originalGas is gas passed in to the action execution order. Used to calculate gas used in the execution.
     * @dev should only ever be called by the orchestrator. Is onlyOrchestrator. This and setAsideGas are used to pull gas from the vault for strategy executions.
     */
    function reimburseGas(
        address targetAddress,
        uint256 originalGas,
        bytes32 newActionHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

interface IKeeperRegistry {
    enum permissionType {
        NONE,
        FULL,
        SLASHED
    }

    event permissionChanged(
        address indexed _subject,
        permissionType indexed _permissionType
    );
    event leaveQueued(address indexed keeper, uint256 leaveTimestamp);

    /**
     * Any given address can be in one of three different states:
        1. Not a keeper.
        2. A former keeper who is queued to leave, i.e. they no longer have a keeper license but still have some funds locked in the contract. 
        3. A current keeper.
     * Keepers can themselves each be in one of two states:
        1. In good standing. This is signified by bondHeld >= bondAmount.
        2. Not in good standing. 
        If a keepers is not in good standing, they retain their license and ability to vote, but any slash will remove their privileges.
     * The only way for a keeper's bondHeld to drop to 0 is for them to leave or be slashed. Either way they lose their license in the process.
     */
    struct WorkerDetails {
        uint256 bondHeld; // bondCoin held by this keeper.
        uint256 licenseNumber; // Index of this keeper in the license mapping, i.e. which license they own. If they don't own a license, this will be 0.
        uint256 leaveTimestamp; // If this keeper has queued to leave, they can withdraw their bond after this date.
    }

    /**
     * @param coinAddress the address of the ERC20 which will be used for bonds; intended to be Steer token.
     * @param keeperTransferDelay the amount of time (in seconds) between when a keeper relinquishes their license and when they can
            withdraw their funds. Intended to be 2 weeks - 1 month.
     */
    function initialize(
        address coinAddress,
        uint256 keeperTransferDelay,
        uint256 maxKeepers,
        uint256 bondSize
    ) external;

    /**
     * @dev setup utility function for owner to add initial keepers. Addresses must each be unique and not hold any bondToken.
     * @param joiners array of addresses to become keepers.
     * note that this function will pull bondToken from the owner equal to bondAmount * numJoiners.
     */
    function joiningForOwner(address[] calldata joiners) external;

    /**
     * @param amount Amount of bondCoin to be deposited.
     * @dev this function has three uses:
        1. If the caller is a keeper, they can increase their bondHeld by amount.
        2. If the caller is not a keeper or former keeper, they can attempt to claim a keeper license and become a keeper.
        3. If the caller is a former keeper, they can attempt to cancel their leave request, claim a keeper license, and become a keeper.
        In all 3 cases registry[msg.sender].bondHeld is increased by amount. In the latter 2, msg.sender's bondHeld after the transaction must be >= bondAmount.
     */
    function join(uint256 licenseNumber, uint256 amount) external;

    function queueToLeave() external;

    function leave() external;

    /**
     * @dev returns true if the given address has the power to vote, false otherwise. The address has the power to vote if it is within the keeper array.
     */
    function checkLicense(address targetAddress)
        external
        view
        returns (uint256);

    /**
     * @dev slashes a keeper, removing their permissions and forfeiting their bond.
     * @param targetKeeper keeper to denounce
     * @param amount amount of bondCoin to slash
     */
    function denounce(address targetKeeper, uint256 amount) external;

    /**
     * @dev withdraws slashed tokens from the vault and sends them to targetAddress.
     * @param amount amount of bondCoin to withdraw
     * @param targetAddress address receiving the tokens
     */
    function withdrawFreeCoin(uint256 amount, address targetAddress) external;

    /**
     * @dev change bondAmount to a new value.
     * @dev implicitly changes keeper permissions. If the bondAmount is being increased, existing keepers will not be slashed or removed. 
            note, they will still be able to vote until they are slashed.
     * @param amount new bondAmount.
     */
    function changeBondAmount(uint256 amount) external;

    /**
     * @dev change numKeepers to a new value. If numKeepers is being reduced, this will not remove any keepers, nor will it change orchestrator requirements.
        However, it will render keeper licenses > maxNumKeepers invalid and their votes will stop counting.
     */
    function changeMaxKeepers(uint16 newNumKeepers) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

/**
 * @dev Interface of the Orchestrator.
 */
interface IOrchestrator {
    enum ActionState {
        PENDING,
        COMPLETED
    }
    function actionThresholdPercent() external view returns (uint256);

    function rewardPerAction() external view returns (uint256);

    function voteBitmaps(bytes32) external view returns (uint256);

    function setGasVault(address _gasVault) external;

    /**
     * @dev Allows an existing `_member` of the group to vote on an already created action/proposal given by `_actionId`
     * which is open for approval for all members of the group.
     *
     * Emits an {ActionStateChanged} event.
     */
    function voteOnAction(bytes32 actionHash, bool vote) external;

    function actionApprovalStatus(bytes32 actionHash) external view returns (bool);

    /**
     * @dev Executes the action referenced by the given `_actionId` as long as it is approved by all existing members of the group.
     * The executeAction executes all methods as part of given action in an atomic way (either all succeed or none succeed).
     * Once executed, the action is set as executed (ActionState = EXECUTED) so that it cannot be executed again.
     *
     * Emits an {ActionStateChanged} event.
     */
    function executeAction(address targetAddress, uint256 jobEpoch, bytes[] calldata calldatas, uint256[] calldata timeIndependentLengths) external returns (ActionState);

    /**
     * @dev MUST trigger when actions are created.
     */
    event ActionCreated(
        address from,
        bytes32 indexed actionHash,
        address indexed targetAddress,
        uint256 jobEpoch,
        bytes[] calldatas
    );

    /**
     * @dev MUST trigger when actions are executed.
     * @param actionHash: keccak256(targetAddress, jobEpoch, calldatas) used to identify this action
     * @param from: the address of the keeper that executed this action
     * @param rewardPerAction: SteerToken reward for this action, to be supplied to operator nodes.
     */
    event ActionExecuted(
        bytes32 indexed actionHash,
        address from,
        uint256 rewardPerAction
    );

    event ActionRejected(bytes32 indexed actionHash, address from);
    event ActionFailed(bytes32 indexed actionHash);
    event vote(bytes32 indexed actionHash, address indexed from, uint8 approved);
}