// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.2) (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFeeRecipient {
  function baseRate() external view returns (uint256);

  function getBorrowingFee(uint256 _amount) external view returns (uint256);

  function calcDecayedBaseRate(uint256 _currentBaseRate) external view returns (uint256);

  /**
     @dev is called to make the FeeRecipient contract transfer the fees to itself. It will use transferFrom to get the
     fees from the msg.sender
     @param _amount the amount in Wei of fees to transfer
     */
  function takeFees(uint256 _amount) external returns (bool);

  function increaseBaseRate(uint256 _increase) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/constants.sol";

interface ILiquidationPool {
  function collateral() external view returns (uint256);

  function debt() external view returns (uint256);

  function liqTokenRate() external view returns (uint256);

  function claimCollateralAndDebt(uint256 _unclaimedCollateral, uint256 _unclaimedDebt) external;

  function approveTrove(address _trove) external;

  function unapproveTrove(address _trove) external;

  function liquidate() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";

interface IMintableToken is IERC20, IOwnable {
  function mint(address recipient, uint256 amount) external;

  function burn(uint256 amount) external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function approve(address spender, uint256 amount) external override returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./IMintableToken.sol";

interface IMintableTokenOwner is IOwnable {
  function token() external view returns (IMintableToken);

  function mint(address _recipient, uint256 _amount) external;

  function transferTokenOwnership(address _newOwner) external;

  function addMinter(address _newMinter) external;

  function revokeMinter(address _minter) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function getAmountOut(
    uint256 amountIn,
    address token0,
    address token1
  ) external view returns (uint256 amountOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/constants.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITroveFactory.sol";
import "./IMintableToken.sol";

interface IStabilityPoolBase {
  function factory() external view returns (ITroveFactory);

  function stableCoin() external view returns (IMintableToken);

  function bonqToken() external view returns (IERC20);

  function totalDeposit() external view returns (uint256);

  function withdraw(uint256 _amount) external;

  function deposit(uint256 _amount) external;

  function redeemReward() external;

  function liquidate() external;

  function setBONQPerMinute(uint256 _bonqPerMinute) external;

  function setBONQAmountForRewards() external;

  function getDepositorBONQGain(address _depositor) external view returns (uint256);

  function getWithdrawableDeposit(address staker) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IStabilityPoolBase.sol";

interface IStabilityPoolUniswap is IStabilityPoolBase {
  function arbitrage(
    uint256 _amountIn,
    address[] calldata _path,
    uint24[] calldata _fees,
    uint256 expiry
  ) external;

  function setRouter(address _router) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";

interface ITokenPriceFeed is IOwnable {
  struct TokenInfo {
    address priceFeed;
    uint256 mcr;
    uint256 mrf; // Maximum Redemption Fee
  }

  function tokenPriceFeed(address) external view returns (address);

  function tokenPrice(address _token) external view returns (uint256);

  function mcr(address _token) external view returns (uint256);

  function mrf(address _token) external view returns (uint256);

  function setTokenPriceFeed(
    address _token,
    address _priceFeed,
    uint256 _mcr,
    uint256 _maxRedemptionFeeBasisPoints
  ) external;

  function emitPriceUpdate(
    address _token,
    uint256 _priceAverage,
    uint256 _pricePoint
  ) external;

  event NewTokenPriceFeed(address _token, address _priceFeed, string _name, string _symbol, uint256 _mcr, uint256 _mrf);
  event PriceUpdate(address token, uint256 priceAverage, uint256 pricePoint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";
import "./ITroveFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrove is IOwnable {
  function factory() external view returns (ITroveFactory);

  function token() external view returns (IERC20);

  // solhint-disable-next-line func-name-mixedcase
  function TOKEN_PRECISION() external view returns (uint256);

  function mcr() external view returns (uint256);

  function collateralization() external view returns (uint256);

  function collateralValue() external view returns (uint256);

  function collateral() external view returns (uint256);

  function recordedCollateral() external view returns (uint256);

  function debt() external view returns (uint256);

  function netDebt() external view returns (uint256);

  //  function rewardRatioSnapshot() external view returns (uint256);

  function initialize(
    //    address _factory,
    address _token,
    address _troveOwner
  ) external;

  function increaseCollateral(uint256 _amount, address _newNextTrove) external;

  function decreaseCollateral(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) external;

  function borrow(
    address _recipient,
    uint256 _amount,
    address _newNextTrove
  ) external;

  function repay(uint256 _amount, address _newNextTrove) external;

  function redeem(address _recipient, address _newNextTrove)
    external
    returns (uint256 _stableAmount, uint256 _collateralRecieved);

  function setArbitrageParticipation(bool _state) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";
import "./ITokenPriceFeed.sol";
import "./IMintableToken.sol";
import "./IMintableTokenOwner.sol";
import "./IFeeRecipient.sol";
import "./ILiquidationPool.sol";
import "./IStabilityPoolBase.sol";
import "./ITrove.sol";

interface ITroveFactory {
  /* view */
  function lastTrove(address _trove) external view returns (address);

  function firstTrove(address _trove) external view returns (address);

  function nextTrove(address _token, address _trove) external view returns (address);

  function prevTrove(address _token, address _trove) external view returns (address);

  function containsTrove(address _token, address _trove) external view returns (bool);

  function stableCoin() external view returns (IMintableToken);

  function tokenOwner() external view returns (IMintableTokenOwner);

  function tokenToPriceFeed() external view returns (ITokenPriceFeed);

  function feeRecipient() external view returns (IFeeRecipient);

  function troveCount(address _token) external view returns (uint256);

  function totalDebt() external view returns (uint256);

  function totalCollateral(address _token) external view returns (uint256);

  function totalDebtForToken(address _token) external view returns (uint256);

  function liquidationPool(address _token) external view returns (ILiquidationPool);

  function stabilityPool() external view returns (IStabilityPoolBase);

  function arbitragePool() external view returns (address);

  function getRedemptionFeeRatio(address _trove) external view returns (uint256);

  function getRedemptionFee(uint256 _feeRatio, uint256 _amount) external pure returns (uint256);

  function getBorrowingFee(uint256 _amount) external view returns (uint256);

  /* state changes*/
  function createTrove(address _token) external returns (ITrove trove);

  function createTroveAndBorrow(
    address _token,
    uint256 _collateralAmount,
    address _recipient,
    uint256 _borrowAmount,
    address _nextTrove
  ) external;

  function removeTrove(address _token, address _trove) external;

  function insertTrove(address _trove, address _newNextTrove) external;

  function updateTotalCollateral(
    address _token,
    uint256 _amount,
    bool _increase
  ) external;

  function updateTotalDebt(uint256 _amount, bool _borrow) external;

  function setStabilityPool(address _stabilityPool) external;

  function setArbitragePool(address _arbitragePool) external;

  // solhint-disable-next-line var-name-mixedcase
  function setWETH(address _WETH, address _liquidationPool) external;

  function increaseCollateralNative(address _trove, address _newNextTrove) external payable;

  /* utils */
  function emitLiquidationEvent(
    address _token,
    address _trove,
    address stabilityPoolLiquidation,
    uint256 collateral
  ) external;

  function emitTroveCollateralUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization
  ) external;

  function emitTroveDebtUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization,
    uint256 _feePaid
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import "./callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStabilityPoolBase.sol";
import "./interfaces/ITroveFactory.sol";
import "./interfaces/ITrove.sol";
import "./interfaces/IMintableToken.sol";
import "./utils/BONQMath.sol";
import "./interfaces/IRouter.sol";

/// @title is used to liquidate troves and reward depositors with collateral redeemed
contract StabilityPoolBase is
  IStabilityPoolBase,
  UUPSUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  Constants
{
  using BONQMath for uint256;
  using SafeERC20 for IERC20;

  struct TokenToS {
    address tokenAddress;
    uint256 S_value;
  }

  struct TokenToUint256 {
    address tokenAddress;
    uint256 value;
  }

  struct Snapshots {
    TokenToS[] tokenToSArray;
    uint256 P;
    uint256 G;
    uint128 scale;
    uint128 epoch;
  }

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  ITroveFactory public immutable override factory;
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  IMintableToken public immutable override stableCoin;
  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  IERC20 public immutable override bonqToken;

  uint256 public override totalDeposit;

  mapping(address => uint256) public collateralToLastErrorOffset;
  uint256 public lastStableCoinLossErrorOffset;

  mapping(address => uint256) public deposits;
  mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct

  uint256 public bonqPerMinute;
  uint256 public totalBONQRewardsLeft;
  uint256 public latestBONQRewardTime;
  // Error tracker for the error correction in the BONQ redistribution calculation
  uint256 public lastBONQError;
  /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
   * after a series of liquidations have occurred, each of which cancel some StableCoin debt with the deposit.
   *
   * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
   * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
   */
  uint256 public P;

  uint256 public constant SCALE_FACTOR = 1e9;

  uint256 public constant SECONDS_IN_ONE_MINUTE = 60;

  // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
  uint128 public currentScale;

  // With each offset that fully empties the Pool, the epoch is incremented by 1
  uint128 public currentEpoch;

  /* Collateral Gain sum 'S': During its lifetime, each deposit d_t earns an Collateral gain of ( d_t * [S - S_t] )/P_t, where S_t
   * is the depositor's snapshot of S taken at the time t when the deposit was made.
   *
   * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
   *
   * - The inner mapping records the sum S at different scales
   * - The outer mapping records the (scale => sum) mappings, for different epochs.
   */
  mapping(uint128 => mapping(uint128 => TokenToS[])) public epochToScaleToTokenToSum;

  /*
   * Similarly, the sum 'G' is used to calculate BONQ gains. During it's lifetime, each deposit d_t earns a BONQ gain of
   *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
   *
   *  BONQ reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
   *  In each case, the BONQ reward is issued (i.e. G is updated), before other state changes are made.
   */
  mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

  event Deposit(address _contributor, uint256 _amount);
  event TotalDepositUpdated(uint256 _newValue);
  event Withdraw(address _contributor, uint256 _amount);
  event Arbitrage(address[] _path, uint256 _amountIn, uint256 _amountOut);

  // solhint-disable-next-line event-name-camelcase
  event BONQRewardRedeemed(address _contributor, uint256 _amount);
  event BONQRewardIssue(uint256 issuance, uint256 _totalBONQRewardsLeft);
  event BONQPerMinuteUpdated(uint256 _newAmount);
  event TotalBONQRewardsUpdated(uint256 _newAmount);
  // solhint-disable-next-line event-name-camelcase
  event CollateralRewardRedeemed(
    address _contributor,
    address _tokenAddress,
    uint256 _amount,
    uint256 _collateralPrice
  );
  event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _G, uint256 _newDepositValue);

  /* solhint-disable event-name-camelcase */
  event P_Updated(uint256 _P);
  event S_Updated(address _tokenAddress, uint256 _S, uint128 _epoch, uint128 _scale);
  event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
  /* solhint-disable event-name-camelcase */
  event EpochUpdated(uint128 _currentEpoch);
  event ScaleUpdated(uint128 _currentScale);

  /// @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable
  constructor(address _factory, address _bonqToken) {
    require(_factory != address(0x0), "3f8955 trove factory must not be address 0x0");
    require(_bonqToken != address(0x0), "3f8955 bonq token must not be address 0x0");
    factory = ITroveFactory(_factory);
    stableCoin = IMintableToken(address(ITroveFactory(_factory).stableCoin()));
    bonqToken = IERC20(_bonqToken);
    // to prevent contract implementation to be reinitialized by someone else
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    P = DECIMAL_PRECISION;
  }

  /// @dev make the contract upgradeable by its owner
  function _authorizeUpgrade(address) internal override onlyOwner {}

  /// @dev to deposit StableCoin into StabilityPool this must be protected against a reentrant attack from the arbitrage
  /// @param  _amount amount to deposit
  function deposit(uint256 _amount) public override nonReentrant {
    // address depositor = msg.sender;
    require(_amount > 0, "d87c1 deposit amount must be bigger than zero");

    stableCoin.transferFrom(msg.sender, address(this), _amount);
    uint256 initialDeposit = deposits[msg.sender];
    _redeemReward();

    Snapshots memory snapshots = depositSnapshots[msg.sender];

    uint256 compoundedDeposit = _getCompoundedDepositFromSnapshots(initialDeposit, snapshots);
    // uint256 newValue = compoundedDeposit + _amount;
    uint256 newTotalDeposit = totalDeposit + _amount;
    totalDeposit = newTotalDeposit;

    _updateDepositAndSnapshots(msg.sender, compoundedDeposit + _amount);

    emit Deposit(msg.sender, _amount);
    emit TotalDepositUpdated(newTotalDeposit);
  }

  /// @dev to withdraw StableCoin that was not spent if this function is called in a reentrantway during arbitrage  it
  /// @dev would skew the token allocation and must be protected against
  /// @param  _amount amount to withdraw
  function withdraw(uint256 _amount) public override nonReentrant {
    uint256 contributorDeposit = deposits[msg.sender];
    require(_amount > 0, "f6c8a withdrawal amount must be bigger than 0");
    require(contributorDeposit > 0, "f6c8a user has no deposit");
    _redeemReward();

    Snapshots memory snapshots = depositSnapshots[msg.sender];

    uint256 compoundedDeposit = _getCompoundedDepositFromSnapshots(contributorDeposit, snapshots);
    uint256 calculatedAmount = compoundedDeposit.min(_amount);

    uint256 newValue = compoundedDeposit - calculatedAmount;

    totalDeposit = totalDeposit - calculatedAmount;

    _updateDepositAndSnapshots(msg.sender, newValue);

    stableCoin.transfer(msg.sender, calculatedAmount);
    emit Withdraw(msg.sender, calculatedAmount);
    emit TotalDepositUpdated(totalDeposit);
  }

  /// @dev to withdraw collateral rewards earned after liquidations
  /// @dev this function does not provide an opportunity for a reentrancy attack
  function redeemReward() public override {
    Snapshots memory snapshots = depositSnapshots[msg.sender];
    uint256 contributorDeposit = deposits[msg.sender];

    uint256 compoundedDeposit = _getCompoundedDepositFromSnapshots(contributorDeposit, snapshots);
    _redeemReward();
    _updateDepositAndSnapshots(msg.sender, compoundedDeposit);
  }

  /// @dev liquidates trove, must be called from that trove
  /// @dev this function does not provide an opportunity for a reentrancy attack even though it would make the arbitrage
  /// @dev fail because of the lowering of the stablecoin balance
  /// @notice must be called by the valid trove
  function liquidate() public override {
    ITrove trove = ITrove(msg.sender);
    IERC20 collateralToken = IERC20(trove.token());
    address collateralTokenAddress = address(collateralToken);
    ITroveFactory factory_cached = factory;
    require(
      factory_cached.containsTrove(address(collateralToken), msg.sender),
      "StabilityPool:liquidate: must be called from a valid trove"
    );
    uint256 troveDebt = trove.debt();
    uint256 totalStableCoin = totalDeposit; // cached to save an SLOAD
    uint256 troveCollateral = trove.collateral();

    collateralToken.safeTransferFrom(address(trove), address(this), troveCollateral);
    (uint256 collateralGainPerUnitStaked, uint256 stableCoinLossPerUnitStaked) = _computeRewardsPerUnitStaked(
      collateralTokenAddress,
      troveCollateral,
      troveDebt,
      totalStableCoin
    );
    _updateRewardSumAndProduct(collateralTokenAddress, collateralGainPerUnitStaked, stableCoinLossPerUnitStaked);
    _triggerBONQdistribution();

    stableCoin.burn(troveDebt);
    uint256 newTotalDeposit = totalStableCoin - troveDebt;
    totalDeposit = newTotalDeposit;
    emit TotalDepositUpdated(newTotalDeposit);
    factory_cached.emitLiquidationEvent(address(collateralToken), msg.sender, address(this), troveCollateral);
  }

  /// @dev gets current deposit of msg.sender
  function getWithdrawableDeposit(address staker) public view override returns (uint256) {
    uint256 initialDeposit = deposits[staker];
    Snapshots memory snapshots = depositSnapshots[staker];
    return _getCompoundedDepositFromSnapshots(initialDeposit, snapshots);
  }

  /// @dev gets collateral reward of msg.sender
  /// @param _token collateral token address
  function getCollateralReward(address _token, address _depositor) external view returns (uint256) {
    Snapshots memory _snapshots = depositSnapshots[_depositor];
    uint256 _initialDeposit = deposits[_depositor];

    uint128 epochSnapshot = _snapshots.epoch;
    uint128 scaleSnapshot = _snapshots.scale;

    TokenToS[] memory tokensToSum_cached = epochToScaleToTokenToSum[epochSnapshot][scaleSnapshot];
    uint256 tokenArrayLength = tokensToSum_cached.length;

    TokenToS memory cachedS;
    for (uint128 i = 0; i < tokenArrayLength; i++) {
      TokenToS memory S = tokensToSum_cached[i];
      if (S.tokenAddress == _token) {
        cachedS = S;
        break;
      }
    }
    if (cachedS.tokenAddress == address(0)) return 0;
    uint256 relatedSValue_snapshot;
    for (uint128 i = 0; i < _snapshots.tokenToSArray.length; i++) {
      TokenToS memory S_snapsot = _snapshots.tokenToSArray[i];
      if (S_snapsot.tokenAddress == _token) {
        relatedSValue_snapshot = S_snapsot.S_value;
        break;
      }
    }
    TokenToS[] memory nextTokensToSum_cached = epochToScaleToTokenToSum[epochSnapshot][scaleSnapshot + 1];
    uint256 nextScaleS;
    for (uint128 i = 0; i < nextTokensToSum_cached.length; i++) {
      TokenToS memory nextScaleTokenToS = nextTokensToSum_cached[i];
      if (nextScaleTokenToS.tokenAddress == _token) {
        nextScaleS = nextScaleTokenToS.S_value;
        break;
      }
    }

    uint256 P_Snapshot = _snapshots.P;

    uint256 collateralGain = _getCollateralGainFromSnapshots(
      _initialDeposit,
      cachedS.S_value,
      nextScaleS,
      relatedSValue_snapshot,
      P_Snapshot
    );

    return collateralGain;
  }

  /// @dev gets BONQ reward of _depositor
  /// @param _depositor user address
  function getDepositorBONQGain(address _depositor) external view override returns (uint256) {
    uint256 totalBONQRewardsLeft_cached = totalBONQRewardsLeft;
    uint256 totalStableCoin = totalDeposit;
    if (totalBONQRewardsLeft_cached == 0 || bonqPerMinute == 0 || totalStableCoin == 0) {
      return 0;
    }

    uint256 _bonqIssuance = bonqPerMinute * ((block.timestamp - latestBONQRewardTime) / SECONDS_IN_ONE_MINUTE);
    if (totalBONQRewardsLeft_cached < _bonqIssuance) {
      _bonqIssuance = totalBONQRewardsLeft_cached;
    }

    uint256 bonqGain = (_bonqIssuance * DECIMAL_PRECISION + lastBONQError) / totalStableCoin;
    uint256 marginalBONQGain = bonqGain * P;

    return _getDepositorBONQGain(_depositor, marginalBONQGain);
  }

  /// @dev sets amount of BONQ per minute for rewards
  function setBONQPerMinute(uint256 _bonqPerMinute) external override onlyOwner {
    _triggerBONQdistribution();
    bonqPerMinute = _bonqPerMinute;
    emit BONQPerMinuteUpdated(bonqPerMinute);
  }

  /// @dev sets total amount of BONQ to be rewarded (pays per minute until reaches the amount rewarded)
  function setBONQAmountForRewards() external override onlyOwner {
    _triggerBONQdistribution();
    totalBONQRewardsLeft = bonqToken.balanceOf(address(this));
    emit TotalBONQRewardsUpdated(totalBONQRewardsLeft);
  }

  function _redeemReward() private {
    _redeemCollateralReward();
    _triggerBONQdistribution();
    _redeemBONQReward();
  }

  function _redeemCollateralReward() internal {
    address depositor = msg.sender;
    TokenToUint256[] memory depositorCollateralGains = _getDepositorCollateralGains(depositor);
    _sendCollateralRewardsToDepositor(depositorCollateralGains);
  }

  function _redeemBONQReward() internal {
    address depositor = msg.sender;
    uint256 depositorBONQGain = _getDepositorBONQGain(depositor, 0);
    _sendBONQRewardsToDepositor(depositorBONQGain);
    emit BONQRewardRedeemed(depositor, depositorBONQGain);
  }

  /// @dev updates user deposit snapshot data for new deposit value
  function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) private {
    deposits[_depositor] = _newValue;
    if (_newValue == 0) {
      delete depositSnapshots[_depositor];
      emit DepositSnapshotUpdated(_depositor, 0, 0, 0);
      return;
    }
    uint128 cachedEpoch = currentEpoch;
    uint128 cachedScale = currentScale;
    TokenToS[] storage cachedTokenToSArray = epochToScaleToTokenToSum[cachedEpoch][cachedScale]; // TODO: maybe remove and read twice?
    uint256 cachedP = P;
    uint256 cachedG = epochToScaleToG[cachedEpoch][cachedScale];

    depositSnapshots[_depositor].tokenToSArray = cachedTokenToSArray; // TODO
    depositSnapshots[_depositor].P = cachedP;
    depositSnapshots[_depositor].G = cachedG;
    depositSnapshots[_depositor].scale = cachedScale;
    depositSnapshots[_depositor].epoch = cachedEpoch;
    emit DepositSnapshotUpdated(_depositor, cachedP, cachedG, _newValue);
  }

  function _updateRewardSumAndProduct(
    address _collateralTokenAddress,
    uint256 _collateralGainPerUnitStaked,
    uint256 _stableCoinLossPerUnitStaked
  ) internal {
    assert(_stableCoinLossPerUnitStaked <= DECIMAL_PRECISION);

    uint128 currentScaleCached = currentScale;
    uint128 currentEpochCached = currentEpoch;
    uint256 currentS;
    uint256 currentSIndex;
    bool _found;
    TokenToS[] memory currentTokenToSArray = epochToScaleToTokenToSum[currentEpochCached][currentScaleCached];
    for (uint128 i = 0; i < currentTokenToSArray.length; i++) {
      if (currentTokenToSArray[i].tokenAddress == _collateralTokenAddress) {
        currentS = currentTokenToSArray[i].S_value;
        currentSIndex = i;
        _found = true;
      }
    }
    /*
     * Calculate the new S first, before we update P.
     * The Collateral gain for any given depositor from a liquidation depends on the value of their deposit
     * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
     *
     * Since S corresponds to Collateral gain, and P to deposit loss, we update S first.
     */
    uint256 marginalCollateralGain = _collateralGainPerUnitStaked * P;
    uint256 newS = currentS + marginalCollateralGain;
    if (currentTokenToSArray.length == 0 || !_found) {
      TokenToS memory tokenToS;
      tokenToS.S_value = newS;
      tokenToS.tokenAddress = _collateralTokenAddress;
      epochToScaleToTokenToSum[currentEpochCached][currentScaleCached].push() = tokenToS;
    } else {
      epochToScaleToTokenToSum[currentEpochCached][currentScaleCached][currentSIndex].S_value = newS;
    }
    emit S_Updated(_collateralTokenAddress, newS, currentEpochCached, currentScaleCached);
    _updateP(_stableCoinLossPerUnitStaked, true);
  }

  function _updateP(uint256 _stableCoinChangePerUnitStaked, bool loss) internal {
    /*
     * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool StableCoin in the liquidation.
     * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - StableCoinLossPerUnitStaked)
     */
    uint256 newProductFactor;
    if (loss) {
      newProductFactor = uint256(DECIMAL_PRECISION - _stableCoinChangePerUnitStaked);
    } else {
      newProductFactor = uint256(DECIMAL_PRECISION + _stableCoinChangePerUnitStaked);
    }
    uint256 currentP = P;
    uint256 newP;
    // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
    if (newProductFactor == 0) {
      currentEpoch += 1;
      emit EpochUpdated(currentEpoch);
      currentScale = 0;
      emit ScaleUpdated(0);
      newP = DECIMAL_PRECISION;

      // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
    } else if ((currentP * newProductFactor) / DECIMAL_PRECISION < SCALE_FACTOR) {
      newP = (currentP * newProductFactor * SCALE_FACTOR) / DECIMAL_PRECISION;
      currentScale += 1;
      emit ScaleUpdated(currentScale);
    } else {
      newP = (currentP * newProductFactor) / DECIMAL_PRECISION;
    }

    assert(newP > 0);
    P = newP;

    emit P_Updated(newP);
  }

  /// @dev updates G when new BONQ amount is issued
  /// @param _bonqIssuance new BONQ issuance amount
  function _updateG(uint256 _bonqIssuance) internal {
    uint256 totalStableCoin = totalDeposit; // cached to save an SLOAD
    /*
     * When total deposits is 0, G is not updated. In this case, the BONQ issued can not be obtained by later
     * depositors - it is missed out on, and remains in the balanceof the Stability Pool.
     *
     */
    if (totalStableCoin == 0 || _bonqIssuance == 0) {
      return;
    }

    uint256 bonqPerUnitStaked;
    bonqPerUnitStaked = _computeBONQPerUnitStaked(_bonqIssuance, totalStableCoin);

    uint256 marginalBONQGain = bonqPerUnitStaked * P;
    uint128 currentEpoch_cached = currentEpoch;
    uint128 currentScale_cached = currentScale;

    uint256 newEpochToScaleToG = epochToScaleToG[currentEpoch_cached][currentScale_cached] + marginalBONQGain;
    epochToScaleToG[currentEpoch_cached][currentScale_cached] = newEpochToScaleToG;

    emit G_Updated(newEpochToScaleToG, currentEpoch_cached, currentScale_cached);
  }

  function _getDepositorCollateralGains(address _depositor) internal view returns (TokenToUint256[] memory) {
    uint256 initialDeposit = deposits[_depositor];
    if (initialDeposit == 0) {
      TokenToUint256[] memory x;
      return x;
    }

    Snapshots memory snapshots = depositSnapshots[_depositor];

    TokenToUint256[] memory gainPerCollateralArray = _getCollateralGainsArrayFromSnapshots(initialDeposit, snapshots);
    return gainPerCollateralArray;
  }

  function _getCollateralGainsArrayFromSnapshots(uint256 _initialDeposit, Snapshots memory _snapshots)
    internal
    view
    returns (TokenToUint256[] memory)
  {
    /*
     * Grab the sum 'S' from the epoch at which the stake was made. The Collateral gain may span up to one scale change.
     * If it does, the second portion of the Collateral gain is scaled by 1e9.
     * If the gain spans no scale change, the second portion will be 0.
     */
    uint128 epochSnapshot = _snapshots.epoch;
    uint128 scaleSnapshot = _snapshots.scale;
    TokenToS[] memory tokensToSum_cached = epochToScaleToTokenToSum[epochSnapshot][scaleSnapshot];
    uint256 tokenArrayLength = tokensToSum_cached.length;
    TokenToUint256[] memory CollateralGainsArray = new TokenToUint256[](tokenArrayLength);
    for (uint128 i = 0; i < tokenArrayLength; i++) {
      TokenToS memory S = tokensToSum_cached[i];
      uint256 relatedS_snapshot;
      for (uint128 j = 0; j < _snapshots.tokenToSArray.length; j++) {
        TokenToS memory S_snapsot = _snapshots.tokenToSArray[j];
        if (S_snapsot.tokenAddress == S.tokenAddress) {
          relatedS_snapshot = S_snapsot.S_value;
          break;
        }
      }
      TokenToS[] memory nextTokensToSum_cached = epochToScaleToTokenToSum[epochSnapshot][scaleSnapshot + 1];
      uint256 nextScaleS;
      for (uint128 j = 0; j < nextTokensToSum_cached.length; j++) {
        TokenToS memory nextScaleTokenToS = nextTokensToSum_cached[j];
        if (nextScaleTokenToS.tokenAddress == S.tokenAddress) {
          nextScaleS = nextScaleTokenToS.S_value;
          break;
        }
      }
      uint256 P_Snapshot = _snapshots.P;

      CollateralGainsArray[i].value = _getCollateralGainFromSnapshots(
        _initialDeposit,
        S.S_value,
        nextScaleS,
        relatedS_snapshot,
        P_Snapshot
      );
      CollateralGainsArray[i].tokenAddress = S.tokenAddress;
    }

    return CollateralGainsArray;
  }

  function _getCollateralGainFromSnapshots(
    uint256 initialDeposit,
    uint256 S,
    uint256 nextScaleS,
    uint256 S_Snapshot,
    uint256 P_Snapshot
  ) internal pure returns (uint256) {
    uint256 firstPortion = S - S_Snapshot;
    uint256 secondPortion = nextScaleS / SCALE_FACTOR;
    uint256 collateralGain = (initialDeposit * (firstPortion + secondPortion)) / P_Snapshot / DECIMAL_PRECISION;

    return collateralGain;
  }

  function _getDepositorBONQGain(address _depositor, uint256 _marginalBONQGain) internal view returns (uint256) {
    uint256 initialDeposit = deposits[_depositor];
    if (initialDeposit == 0) {
      return 0;
    }
    Snapshots memory _snapshots = depositSnapshots[_depositor];
    /*
     * Grab the sum 'G' from the epoch at which the stake was made. The BONQ gain may span up to one scale change.
     * If it does, the second portion of the BONQ gain is scaled by 1e9.
     * If the gain spans no scale change, the second portion will be 0.
     */
    uint256 firstEpochPortion = epochToScaleToG[_snapshots.epoch][_snapshots.scale];
    uint256 secondEpochPortion = epochToScaleToG[_snapshots.epoch][_snapshots.scale + 1];
    if (_snapshots.epoch == currentEpoch) {
      if (_snapshots.scale == currentScale) firstEpochPortion += _marginalBONQGain;
      if (_snapshots.scale + 1 == currentScale) secondEpochPortion += _marginalBONQGain;
    }
    uint256 gainPortions = firstEpochPortion - _snapshots.G + secondEpochPortion / SCALE_FACTOR;

    return (initialDeposit * (gainPortions)) / _snapshots.P / DECIMAL_PRECISION;
  }

  /// @dev gets compounded deposit of the user
  function _getCompoundedDepositFromSnapshots(uint256 _initialStake, Snapshots memory _snapshots)
    internal
    view
    returns (uint256)
  {
    uint256 snapshot_P = _snapshots.P;

    // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
    if (_snapshots.epoch < currentEpoch) {
      return 0;
    }

    uint256 compoundedStake;
    uint128 scaleDiff = currentScale - _snapshots.scale;

    /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
     * account for it. If more than one scale change was made, then the stake has decreased by a factor of
     * at least 1e-9 -- so return 0.
     */
    uint256 calculatedSnapshotP = snapshot_P == 0 ? DECIMAL_PRECISION : snapshot_P;
    if (scaleDiff == 0) {
      compoundedStake = (_initialStake * P) / calculatedSnapshotP;
    } else if (scaleDiff == 1) {
      compoundedStake = (_initialStake * P) / calculatedSnapshotP / SCALE_FACTOR;
    } else {
      // if scaleDiff >= 2
      compoundedStake = 0;
    }

    /*
     * If compounded deposit is less than a billionth of the initial deposit, return 0.
     *
     * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
     * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
     * than it's theoretical value.
     *
     * Thus it's unclear whether this line is still really needed.
     */
    if (compoundedStake < _initialStake / 1e9) {
      return 0;
    }

    return compoundedStake;
  }

  /// @dev Compute the StableCoin and Collateral rewards. Uses a "feedback" error correction, to keep
  /// the cumulative error in the P and S state variables low:s
  function _computeRewardsPerUnitStaked(
    address _collateralTokenAddress,
    uint256 _collToAdd,
    uint256 _debtToOffset,
    uint256 _totalStableCoinDeposits
  ) internal returns (uint256 collateralGainPerUnitStaked, uint256 stableCoinLossPerUnitStaked) {
    /*
     * Compute the StableCoin and Collateral rewards. Uses a "feedback" error correction, to keep
     * the cumulative error in the P and S state variables low:
     *
     * 1) Form numerators which compensate for the floor division errors that occurred the last time this
     * function was called.
     * 2) Calculate "per-unit-staked" ratios.
     * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
     * 4) Store these errors for use in the next correction when this function is called.
     * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
     */
    uint256 collateralNumerator = _collToAdd * DECIMAL_PRECISION + collateralToLastErrorOffset[_collateralTokenAddress];

    assert(_debtToOffset <= _totalStableCoinDeposits);
    if (_debtToOffset == _totalStableCoinDeposits) {
      stableCoinLossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
      lastStableCoinLossErrorOffset = 0;
    } else {
      uint256 stableCoinLossNumerator = _debtToOffset * DECIMAL_PRECISION - lastStableCoinLossErrorOffset;
      /*
       * Add 1 to make error in quotient positive. We want "slightly too much" StableCoin loss,
       * which ensures the error in any given compoundedStableCoinDeposit favors the Stability Pool.
       */
      stableCoinLossPerUnitStaked = stableCoinLossNumerator / _totalStableCoinDeposits + 1;
      lastStableCoinLossErrorOffset = stableCoinLossPerUnitStaked * _totalStableCoinDeposits - stableCoinLossNumerator;
    }

    collateralGainPerUnitStaked = collateralNumerator / _totalStableCoinDeposits;
    collateralToLastErrorOffset[_collateralTokenAddress] =
      collateralNumerator -
      collateralGainPerUnitStaked *
      _totalStableCoinDeposits;

    return (collateralGainPerUnitStaked, stableCoinLossPerUnitStaked);
  }

  /// @dev distributes BONQ per minutes that was not spent yet
  function _triggerBONQdistribution() internal {
    uint256 issuance = _issueBONQRewards();
    _updateG(issuance);
  }

  function _issueBONQRewards() internal returns (uint256) {
    uint256 newBONQRewardTime = block.timestamp;
    uint256 totalBONQRewardsLeft_cached = totalBONQRewardsLeft;
    if (totalBONQRewardsLeft_cached == 0 || bonqPerMinute == 0 || totalDeposit == 0) {
      latestBONQRewardTime = newBONQRewardTime;
      return 0;
    }

    uint256 timePassedInMinutes = (newBONQRewardTime - latestBONQRewardTime) / SECONDS_IN_ONE_MINUTE;
    uint256 issuance = bonqPerMinute * timePassedInMinutes;
    if (totalBONQRewardsLeft_cached < issuance) {
      issuance = totalBONQRewardsLeft_cached; // event will capture that 0 tokens left
    }
    uint256 newTotalBONQRewardsLeft = totalBONQRewardsLeft_cached - issuance;
    totalBONQRewardsLeft = newTotalBONQRewardsLeft;
    latestBONQRewardTime = newBONQRewardTime;

    emit BONQRewardIssue(issuance, newTotalBONQRewardsLeft);

    return issuance;
  }

  function _computeBONQPerUnitStaked(uint256 _bonqIssuance, uint256 _totalStableCoinDeposits)
    internal
    returns (uint256)
  {
    /*
     * Calculate the BONQ-per-unit staked.  Division uses a "feedback" error correction, to keep the
     * cumulative error low in the running total G:
     *
     * 1) Form a numerator which compensates for the floor division error that occurred the last time this
     * function was called.
     * 2) Calculate "per-unit-staked" ratio.
     * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
     * 4) Store this error for use in the next correction when this function is called.
     * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
     */
    uint256 bonqNumerator = _bonqIssuance * DECIMAL_PRECISION + lastBONQError;

    uint256 bonqPerUnitStaked = bonqNumerator / _totalStableCoinDeposits;
    lastBONQError = bonqNumerator - (bonqPerUnitStaked * _totalStableCoinDeposits);

    return bonqPerUnitStaked;
  }

  /// @dev transfers collateral rewards tokens precalculated to the depositor
  function _sendCollateralRewardsToDepositor(TokenToUint256[] memory _depositorCollateralGains) internal {
    for (uint256 i = 0; i < _depositorCollateralGains.length; i++) {
      if (_depositorCollateralGains[i].value == 0) {
        continue;
      }
      IERC20 collateralToken = IERC20(_depositorCollateralGains[i].tokenAddress);
      collateralToken.safeTransfer(msg.sender, _depositorCollateralGains[i].value);
      uint256 collateralPrice = factory.tokenToPriceFeed().tokenPrice(address(collateralToken));
      emit CollateralRewardRedeemed(
        msg.sender,
        _depositorCollateralGains[i].tokenAddress,
        _depositorCollateralGains[i].value,
        collateralPrice
      );
    }
  }

  /// @dev transfers BONQ amount to the user
  function _sendBONQRewardsToDepositor(uint256 _bonqGain) internal {
    bonqToken.transfer(msg.sender, _bonqGain);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";
import "./interfaces/IStabilityPoolUniswap.sol";
import "./interfaces/uniswap/IUniswapV3Router.sol";
import "./stability-pool-base.sol";

/// @title is used to liquidate troves and reward depositors with collateral redeemed
contract StabilityPoolUniswap is StabilityPoolBase, IStabilityPoolUniswap {
  IUniswapV3Router public router;

  constructor(address _factory, address _bonqToken) StabilityPoolBase(_factory, _bonqToken) {}

  /// @dev use the DEX router to trigger a swap that starts and ends with the stable coin and yields more coins than it
  /// @dev requied as input. This function could be subject to a reentrant attack from a malicious token in the DEX
  /// @param  _amountIn start amount
  /// @param  _path calldata[]
  /// @param  _fees calldata[] fees array in correct order
  function arbitrage(
    uint256 _amountIn,
    address[] calldata _path,
    uint24[] calldata _fees,
    uint256 expiry
  ) public override nonReentrant {
    require(_path[0] == address(stableCoin), "eafe8 must start with stable coin");
    require(_path[_path.length - 1] == address(stableCoin), "eafe8 must end with stable coin");
    require(block.timestamp < expiry || expiry == 0, "92852 too late");
    // if the deadline was not set it is set to NOW - as the swap will happen in the same block it will be soon enough
    uint256 startBalance = stableCoin.balanceOf(address(this));
    // the swap must yield at least 1 coin (in ETH parlance: 1 Wei) more than what was put in and the TX has 10 minutes to execute
    IUniswapV3Router.ExactInputParams memory swapParams = IUniswapV3Router.ExactInputParams(
      _constructUniswapPath(_path, _fees),
      address(this),
      _amountIn,
      _amountIn + 1
    );
    router.exactInput(swapParams);
    uint256 amountOut = stableCoin.balanceOf(address(this)) - startBalance;
    // increase P by the arbitrage gain / total deposit
    _updateP((amountOut * DECIMAL_PRECISION) / totalDeposit, false);
    uint256 newTotalDeposit = totalDeposit + amountOut;
    totalDeposit = newTotalDeposit;
    emit Arbitrage(_path, _amountIn, amountOut);
    emit TotalDepositUpdated(newTotalDeposit);
  }

  /// @dev set the DEX router to be used for arbitrage functions
  function setRouter(address _router) public override onlyOwner {
    router = IUniswapV3Router(_router);
    stableCoin.approve(_router, MAX_INT);
  }

  /// @dev constructs uniswap swap path from arrays of tokens and pool fees
  /// @param  _path address[] of tokens
  /// @param  _fees uint24[] of pool fees
  function _constructUniswapPath(address[] memory _path, uint24[] memory _fees)
    private
    pure
    returns (bytes memory pathBytesString)
  {
    pathBytesString = abi.encodePacked(_path[0]);
    for (uint256 i = 0; i < _fees.length; i++) {
      pathBytesString = abi.encodePacked(pathBytesString, _fees[i], _path[i + 1]);
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";

library BONQMath {
  uint256 public constant DECIMAL_PRECISION = 1e18;
  uint256 public constant MAX_INT = 2**256 - 1;

  uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;

  /// @dev return the smaller of two numbers
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /// @dev return the bigger of two numbers
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  /**
   * @dev Multiply two decimal numbers and use normal rounding rules:
   *  -round product up if 19'th mantissa digit >= 5
   *  -round product down if 19'th mantissa digit < 5
   *
   * Used only inside the exponentiation, _decPow().
   */
  function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
    uint256 prod_xy = x * y;

    decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
  }

  /**
   * @dev Exponentiation function for 18-digit decimal base, and integer exponent n.
   *
   * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
   *
   * Called by function that represent time in units of minutes:
   * 1) IFeeRecipient.calcDecayedBaseRate
   *
   * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
   * "minutes in 1000 years": 60 * 24 * 365 * 1000
   *
   * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
   * negligibly different from just passing the cap, since:
   * @param _base number to exponentially increase
   * @param _minutes power in minutes passed
   */
  function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
    if (_minutes > 525600000) {
      _minutes = 525600000;
    } // cap to avoid overflow

    if (_minutes == 0) {
      return DECIMAL_PRECISION;
    }

    uint256 y = DECIMAL_PRECISION;
    uint256 x = _base;
    uint256 n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n / 2;
      } else {
        // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n - 1) / 2;
      }
    }

    return decMul(x, y);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Constants {
  uint256 public constant DECIMAL_PRECISION = 1e18;
  uint256 public constant LIQUIDATION_RESERVE = 1e18;
  uint256 public constant MAX_INT = 2**256 - 1;

  uint256 public constant PERCENT = (DECIMAL_PRECISION * 1) / 100; // 1%
  uint256 public constant PERCENT10 = PERCENT * 10; // 10%
  uint256 public constant PERCENT_05 = PERCENT / 2; // 0.5%
  uint256 public constant BORROWING_RATE = PERCENT_05;
  uint256 public constant MAX_BORROWING_RATE = (DECIMAL_PRECISION * 5) / 100; // 5%
}