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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

import "../utils/constants.sol";

interface IBONQStaking {
  /* view */
  function totalStake() external view returns (uint256);

  function getRewardsTotal() external view returns (uint256);

  function getUnpaidStableCoinGain(address _user) external view returns (uint256);

  /* state changes*/
  function stake(uint256 _amount) external;

  function unstake(uint256 _amount) external;

  function redeemReward(
    uint256 _amount,
    address _troveAddress,
    address _newNextTrove
  ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExternalPriceFeed {
  function token() external view returns (address);

  function price() external view returns (uint256);

  function pricePoint() external view returns (uint256);

  function setPrice(uint256 _price) external;
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

  function liquidationReserve() external view returns (uint256);

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

  function liquidate() external;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWETH {
  function deposit() external payable;

  function approve(address, uint256) external returns (bool);

  function transfer(address _to, uint256 _value) external returns (bool);

  function withdraw(uint256) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./trove-factory.sol";

contract OriginalTroveFactory is TroveFactory {
  function name() public view override returns (string memory) {
    return "Factory V1.0.1";
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITroveFactory.sol";
import "./interfaces/ITrove.sol";
import "./interfaces/IExternalPriceFeed.sol";
import "./interfaces/IMintableTokenOwner.sol";
import "./interfaces/ITokenPriceFeed.sol";
import "./interfaces/IMintableToken.sol";
import "./interfaces/IFeeRecipient.sol";
import "./interfaces/IBONQStaking.sol";
import "./interfaces/ILiquidationPool.sol";
import "./interfaces/IStabilityPoolBase.sol";
import "./interfaces/IWETH.sol";
import "./utils/linked-address-list.sol";
import "./utils/BONQMath.sol";
import "./utils/constants.sol";

abstract contract TroveFactory is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, Constants, ITroveFactory {
  using SafeERC20 for IERC20;
  using LinkedAddressList for LinkedAddressList.List;
  using BONQMath for uint256;

  struct TroveList {
    uint256 totalCollateral;
    uint256 totalDebt;
    ILiquidationPool liquidationPool;
    LinkedAddressList.List list;
  }

  struct RedemptionInfo {
    address collateralToken;
    uint256 stableCoinRedeemed;
    uint256 feeAmount;
    uint256 collateralRedeemed;
    uint256 stableCoinLeft;
    address currentTroveAddress;
    address lastTroveRedeemed;
    ITrove currentRedemptionTrove;
  }

  // the trove lists must be separated by token because we want to keep the troves in order of collateralisation
  // ratio and the token prices do not move in tandem
  IStabilityPoolBase public override stabilityPool;
  address public override arbitragePool;
  mapping(address => TroveList) private _troves;
  IMintableTokenOwner public override tokenOwner;
  ITokenPriceFeed public override tokenToPriceFeed;
  IMintableToken public override stableCoin;
  // solhint-disable-next-line var-name-mixedcase
  IWETH public WETHContract;
  IFeeRecipient public override feeRecipient;
  uint256 public override totalDebt;
  address public troveImplementation;

  event TroveImplementationSet(address previousImplementation, address newImplementation);
  event NewTrove(address trove, address token, address owner);
  event TroveRemoved(address trove);
  event TroveLiquidated(
    address trove,
    address collateralToken,
    uint256 priceAtLiquidation,
    address stabilityPoolLiquidation,
    uint256 collateral
  );
  event TroveInserted(address token, address trove, address referenceTrove, bool before);

  event CollateralUpdate(address token, uint256 totalCollateral);
  event DebtUpdate(address collateral, uint256 totalDebt);
  event Redemption(
    address token,
    uint256 stableAmount,
    uint256 tokenAmount,
    uint256 stableUnspent,
    uint256 startBaseRate,
    uint256 finishBaseRate,
    address lastTroveRedeemed
  );
  event TroveCollateralUpdate(address trove, address token, uint256 newAmount, uint256 newCollateralization);
  event TroveDebtUpdate(
    address trove,
    address actor,
    address token,
    uint256 newAmount,
    uint256 baseRate,
    uint256 newCollateralization,
    uint256 feePaid
  );

  constructor() {
    // to prevent contract implementation to be reinitialized by someone else
    _disableInitializers();
  }

  modifier troveExists(address _token, address _trove) {
    require(containsTrove(_token, _trove), "f9fac the trove has not been created by the factory");
    _;
  }

  // solhint-disable-next-line func-visibility
  function initialize(address _stableCoin, address _feeRecipient) public initializer {
    __Ownable_init();
    __Pausable_init();
    stableCoin = IMintableToken(_stableCoin);
    feeRecipient = IFeeRecipient(_feeRecipient);
    stableCoin.approve(address(feeRecipient), BONQMath.MAX_INT);
  }

  /// @dev make the contract upgradeable by its owner
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function name() public view virtual returns (string memory);

  /**
   * @dev returns the number of troves for specific token
   */
  function troveCount(address _token) public view override returns (uint256) {
    return _troves[_token].list._size;
  }

  /**
   * @dev returns the last trove by maximum collaterization ratio
   */
  function lastTrove(address _token) public view override returns (address) {
    return _troves[_token].list._last;
  }

  /**
   * @dev returns the first trove by minimal collaterization ratio
   */
  function firstTrove(address _token) public view override returns (address) {
    return _troves[_token].list._first;
  }

  /**
   * @dev returns the next trove by collaterization ratio
   */
  function nextTrove(address _token, address _trove) public view override returns (address) {
    return _troves[_token].list._values[_trove].next;
  }

  /**
   * @dev returns the previous trove by collaterization ratio
   */
  function prevTrove(address _token, address _trove) public view override returns (address) {
    return _troves[_token].list._values[_trove].prev;
  }

  /**
   * @dev returns and checks if such trove exists for this token
   */
  function containsTrove(address _token, address _trove) public view override returns (bool) {
    return _troves[_token].list._values[_trove].next != address(0x0);
  }

  /**
   * @dev returns total collateral among all troves for specific token
   */
  function totalCollateral(address _token) public view override returns (uint256) {
    return _troves[_token].totalCollateral;
  }

  /**
   * @dev returns total debt among all troves for specific token
   */
  function totalDebtForToken(address _token) public view override returns (uint256) {
    return _troves[_token].totalDebt;
  }

  /**
   * @dev returns total collateral ratio averaged between troves for specific token
   */
  function tokenCollateralization(address _token) public view returns (uint256) {
    return (_troves[_token].totalCollateral * DECIMAL_PRECISION) / _troves[_token].totalDebt;
  }

  /**
   * @dev returns contract address of LiquidationPool for specific token
   */
  function liquidationPool(address _token) public view override returns (ILiquidationPool) {
    return _troves[_token].liquidationPool;
  }

  /// @dev calculates redemption fee from CR
  /// @param _collateralRatio collateral ratio of the trove
  /// @param _mcr minimal collateral ratio of the trove
  /// @return uint256 resulting fee
  function _getRedemptionFeeRatio(uint256 _collateralRatio, uint256 _mcr) private pure returns (uint256) {
    uint256 extraCR = (_collateralRatio - _mcr).min(_mcr * 15);
    uint256 a = (((extraCR * extraCR) / _mcr) * DECIMAL_PRECISION) / _mcr;
    uint256 b = _mcr * 45 - DECIMAL_PRECISION * 44;
    uint256 tmpMin = (PERCENT10 * DECIMAL_PRECISION) / b;
    uint256 minFee = tmpMin > PERCENT ? tmpMin - PERCENT_05 : PERCENT_05;

    return (a * DECIMAL_PRECISION) / b + minFee;
  }

  /**
   * @dev returns fee from redeeming the amount
   */
  function getRedemptionFeeRatio(address _trove) public view override returns (uint256) {
    address collateral = address(ITrove(_trove).token());
    ITokenPriceFeed ttpf = tokenToPriceFeed;
    uint256 ratio = _getRedemptionFeeRatio(ITrove(_trove).collateralization(), ttpf.mcr(collateral));
    return ratio.min(ttpf.mrf(collateral));
  }

  /**
   * @dev returns fee from redeeming the amount
   */
  function getRedemptionFee(uint256 _feeRatio, uint256 _amount) public pure override returns (uint256) {
    return (_amount * _feeRatio) / DECIMAL_PRECISION;
  }

  /**
   * @dev returns amount to be used in redemption excluding fee,
   */
  function getRedemptionAmount(uint256 _feeRatio, uint256 _amount) public pure returns (uint256) {
    return (_amount * DECIMAL_PRECISION) / (DECIMAL_PRECISION + _feeRatio);
  }

  /**
   * @dev returns fee from borrowing the amount
   */
  function getBorrowingFee(uint256 _amount) public view override returns (uint256) {
    return feeRecipient.getBorrowingFee(_amount);
  }

  function setTroveImplementation(address _troveImplementation) public onlyOwner {
    emit TroveImplementationSet(troveImplementation, _troveImplementation);
    troveImplementation = _troveImplementation;
  }

  /**
   * @dev sets address of the contract for stableCoin issuance
   */
  function setTokenOwner() public onlyOwner {
    IMintableToken stableCoin_cached = stableCoin;
    tokenOwner = IMintableTokenOwner(address(stableCoin_cached.owner()));
    require(tokenOwner.token() == stableCoin_cached, "41642 the StableCoin must be owned by the token owner");
    require(tokenOwner.owner() == address(this), "41642 this contract must be the owner of the token owner");
  }

  /**
   * @dev sets contract address of FeeRecipient
   */
  function setFeeRecipient(address _feeRecipient) public onlyOwner {
    feeRecipient = IFeeRecipient(_feeRecipient);
    stableCoin.approve(address(feeRecipient), BONQMath.MAX_INT);
  }

  /**
   * @dev sets contract address of TokenPriceFeed
   */
  function setTokenPriceFeed(address _tokenPriceFeed) public onlyOwner {
    tokenToPriceFeed = ITokenPriceFeed(_tokenPriceFeed);
  }

  /**
   * @dev sets contract address of LiquidationPool for specific token
   */
  function setLiquidationPool(address _token, address _liquidationPool) public onlyOwner {
    _troves[_token].liquidationPool = ILiquidationPool(_liquidationPool);
  }

  /**
   * @dev sets contract address of StabilityPool
   */
  function setStabilityPool(address _stabilityPool) external override onlyOwner {
    stabilityPool = IStabilityPoolBase(_stabilityPool);
  }

  /**
   * @dev sets contract address of ArbitragePool
   */
  function setArbitragePool(address _arbitragePool) external override onlyOwner {
    arbitragePool = _arbitragePool;
  }

  /**
   * @dev sets contract address of Wrapped native token, along with liquidationPool
   */
  // solhint-disable-next-line var-name-mixedcase
  function setWETH(address _WETH, address _liquidationPool) external override onlyOwner {
    require(address(WETHContract) == address(0x0), "cd9f3 WETH can only be set once");
    WETHContract = IWETH(_WETH);
    setLiquidationPool(_WETH, _liquidationPool);
  }

  /**
   * @dev transfers contract ownership
   * this function is used when a new TroveFactory version is deployed and the same tokens are used. We transfer the
   * ownership of the TokenOwner contract and the new TroveFactory is able to add minters
   */
  function transferTokenOwnership(address _newOwner) public onlyOwner {
    tokenOwner.transferTokenOwnership(_newOwner);
  }

  /**
   * @dev transfers contract ownership
   * this function is used when a new TroveFactory version is deployed and the same tokens are used. We transfer the
   * ownership of the TokenOwner contract and the new TroveFactory is able to add minters
   */
  function transferTokenOwnerOwnership(address _newOwner) public onlyOwner {
    tokenOwner.transferOwnership(_newOwner);
  }

  /**
   * @dev toggles the pause state of the contract
   * if the contract is paused borrowing is disabled
   * and liquidation with Stability Pool is impossible (Community liquidations still allowed)
   */
  function togglePause() public onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /**
   * @dev function to be called from trove to update total collateral value of all troves of this tokens
   * @param _increase bool that indicates "+" or "-" operation
   */
  function updateTotalCollateral(
    address _token,
    uint256 _amount,
    bool _increase
  ) public override troveExists(_token, msg.sender) {
    if (_increase) {
      _troves[_token].totalCollateral += _amount;
    } else {
      _troves[_token].totalCollateral -= _amount;
    }
    emit CollateralUpdate(_token, _troves[_token].totalCollateral);
  }

  /**
   * @dev deposits native token into trove after wrapping the ETH (EWT, AVAX, etc) into WETH (WEWT, WAVAX, etc)
   * @param _trove tove to be deposited in
   * @param _newNextTrove hint for next trove position
   */
  function increaseCollateralNative(address _trove, address _newNextTrove) public payable override {
    ITrove targetTrove = ITrove(_trove);
    IWETH WETHContract_cached = WETHContract;
    require(address(targetTrove.token()) == address(WETHContract_cached), "b8282 not a valid trove");
    WETHContract_cached.deposit{value: msg.value}();
    require(WETHContract.transfer(_trove, msg.value), "b8282 could not transfer the requested amount");
    targetTrove.increaseCollateral(0, _newNextTrove);
  }

  /**
   * @dev creates a trove if the token is supported
   * @param _token any supported token address
   */
  function createTrove(address _token) public override returns (ITrove trove) {
    IMintableTokenOwner tokenOwner_cached = tokenOwner;
    // troves can only be created after the token owner has been set. This is a safety check not security
    require(address(tokenOwner_cached) != address(0x0), "66c10 the token owner must be set");
    require(tokenOwner_cached.owner() == address(this), "66c10 the token owner's owner must be the trove factory");
    // a token without a price feed has a CR of zero and is useless
    require(tokenToPriceFeed.tokenPriceFeed(_token) != address(0x0), "66c10 the token price feed must be set");
    address troveAddress;
    // reassign because state variables can not be used in mstore
    address _troveImplementation = troveImplementation;
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, _troveImplementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      troveAddress := create(0, ptr, 0x37)
    }
    require(troveAddress != address(0), "ERC1167: create failed");

    trove = ITrove(troveAddress);
    //    trove.initialize(address(this), _token, msg.sender);
    trove.initialize(_token, msg.sender);

    require(_troves[_token].list.add(troveAddress, address(0x0), false), "66c10 trove could not be added to the list");
    //allow the trove to transfer from the liquidation pool
    _troves[_token].liquidationPool.approveTrove(troveAddress);
    // allow the trove to mint stableCoin
    tokenOwner_cached.addMinter(troveAddress);

    emit NewTrove(troveAddress, _token, msg.sender);
  }

  /**
   * @dev creates a trove with collateral and borrows from it
   * @param _token any supported token address
   * @param _collateralAmount a positive amount of collateral to transfer from the sender's account or zero
   * @param _recipient is the address to which the newly minted tokens will be transferred
   * @param _borrowAmount the value of the minting
   * @param _nextTrove is the trove that we think will be the next one in the list. This might be off in case there were some other list changing transactions
   */
  function createTroveAndBorrow(
    address _token,
    uint256 _collateralAmount,
    address _recipient,
    uint256 _borrowAmount,
    address _nextTrove
  ) public override {
    ITrove trove = createTrove(_token);
    IERC20(_token).safeTransferFrom(msg.sender, address(trove), _collateralAmount);
    trove.increaseCollateral(0, address(0));
    if (_borrowAmount >= DECIMAL_PRECISION) trove.borrow(_recipient, _borrowAmount, _nextTrove);
  }

  /**
   * @dev remove a trove from the list and send any remaining token balance to the owner
   * @param _trove is the trove which will be removed
   */
  function removeTrove(address _token, address _trove) public override troveExists(_token, _trove) {
    ITrove trove = ITrove(_trove);
    require(
      trove.owner() == msg.sender || _trove == msg.sender,
      "173fa only the owner can remove the trove from the list"
    );
    require(trove.debt() == 0, "173fa repay the debt before removing the trove");
    IERC20 token = IERC20(trove.token());
    trove.setArbitrageParticipation(false);
    uint256 tokenBalance = token.balanceOf(_trove);

    if (tokenBalance > 0) {
      // we can safely decrease the balance to zero with a newNextTrove of 0x0 because the debt is zero and
      // insertTrove will not be called
      // the collateral should be sent to the owner
      // TODO: add test for this case
      trove.decreaseCollateral(trove.owner(), tokenBalance, address(0x0));
    }
    require(_troves[_token].list.remove(_trove), "173fa trove could not be removed from the list");
    tokenOwner.revokeMinter(_trove);
    _troves[_token].liquidationPool.unapproveTrove(_trove);
    emit TroveRemoved(_trove);
  }

  /**
  * @dev trigger the liquidate function on the trove to be able to liquidate troves participating in arbitrage
  */
  function liquidateTrove(address _trove, address _token) public troveExists(_token, _trove) {
    ITrove trove = ITrove(_trove);
    uint256 liquidationReserve = trove.liquidationReserve();
    trove.liquidate();
    stableCoin.transferFrom(_trove, msg.sender, liquidationReserve);
  }

  /**
   * @dev insert a trove in the sorted list of troves. the troves must be sorted by collateralisation ratio CR
   * the sender must be the trove which will be inserted in the list
   * @param _newNextTrove is the trove before which the trove will be added
   */
  function insertTrove(address _token, address _newNextTrove) public override troveExists(_token, msg.sender) {
    require(
      containsTrove(_token, _newNextTrove) || _newNextTrove == address(0),
      "3a669 the trove hint must exist in the list or be 0x0"
    );

    // if now hint is provided we start by trying the last trove in the list
    if (_newNextTrove == address(0)) {
      _newNextTrove = lastTrove(_token);
    }

    // if the NewNextTrove is the same as the trove being changed, then it should be changed to the trove's nextTrove
    // unless the trove is the lastTrove in which case it is changed to the previousTrove
    // insertTrove is never called if there is only one trove in the list
    if (_newNextTrove == msg.sender) {
      address nextTroveAddress = nextTrove(_token, _newNextTrove);
      // the lastTrove has itself as the nextTrove
      _newNextTrove = _newNextTrove != nextTroveAddress ? nextTroveAddress : prevTrove(_token, _newNextTrove);
    }

    ITrove trove = ITrove(msg.sender);
    ITrove ref = ITrove(_newNextTrove);
    bool insertBefore = true;

    // first remove the trove from the list to avoid trying to insert it before or after itself
    require(_troves[_token].list.remove(address(trove)), "3a669 trove could not be removed from the list");
    if (trove.debt() == 0) {
      // troves with zero debt have infinite collateralisation and can be put safely at the end of the list
      require(
        _troves[_token].list.add(address(trove), address(0x0), false),
        "3a669 trove could not be inserted in the list"
      );
      emit TroveInserted(_token, address(trove), address(0x0), false);
    } else {
      uint256 icr = trove.collateralization();
      uint256 refIcr = ref.collateralization();

      if (refIcr >= icr) {
        // if the first trove in the list has a bigger CR then this trove becomes the new first trove. No loop required
        if (_newNextTrove != firstTrove(_token)) {
          do {
            // the previous trove of the new next trove should have a smaller or equal CR to the inserted trove
            // it is cheaper (in gas) to assign the reference to the previous trove and insert after than to check twice for the CR
            // this is why the loop is a "do while" instead of a "while do"
            ref = ITrove(prevTrove(_token, address(ref)));
            refIcr = ref.collateralization();
          } while (refIcr > icr && address(ref) != _troves[_token].list._first);
        }
      }
      // the ICR of the newNextTrove is smaller than the inserted trove's
      else {
        // only loop through the troves if the newNextTrove is not the last
        if (_newNextTrove != lastTrove(_token)) {
          do {
            // the previous trove of the new next trove should have a smaller or equal CR to the inserted trove
            ref = ITrove(nextTrove(_token, address(ref)));
            refIcr = ref.collateralization();
          } while (refIcr < icr && address(ref) != _troves[_token].list._last);
        }
      }

      insertBefore = refIcr > icr;

      require(
        _troves[_token].list.add(address(trove), address(ref), insertBefore),
        "3a669 trove could not be inserted in the list"
      );
      emit TroveInserted(_token, address(trove), address(ref), insertBefore);
    }
  }

  /**
   * @dev redeem all collateral the trove can provide
   * @param _recipient is the trove _recipient to redeem colateral to and take stableCoin from
   */
  function _redeemFullTrove(address _recipient, address _trove)
    internal
    returns (uint256 _stableAmount, uint256 _collateralRecieved)
  {
    return _redeemPartTrove(_recipient, _trove, ITrove(_trove).netDebt(), address(0));
  }

  /**
    @dev redeem collateral from the tove to fit desired stableCoin amount
    @param _recipient is the trove _recipient to redeem colateral to and take stableCoin from
    @param _stableAmount the desired amount of StableCoin to pay for redemption
    @param _newNextTrove hint for the of the nextNewTrove after redemption
    */
  function _redeemPartTrove(
    address _recipient,
    address _trove,
    uint256 _stableAmount,
    address _newNextTrove
  ) internal returns (uint256 stableAmount, uint256 collateralRecieved) {
    ITrove trove = ITrove(_trove);
    stableCoin.transferFrom(_recipient, _trove, _stableAmount);
    return trove.redeem(_recipient, _newNextTrove);
  }

  /**
   * @dev commits full redemptions until troves liquidity is less
   */
  function commitFullRedemptions(RedemptionInfo memory _redInfo, uint256 _maxRate)
    internal
    returns (RedemptionInfo memory)
  {
    ITrove currentRedemptionTrove = ITrove(_redInfo.currentTroveAddress);
    uint256 currentFeeRatio = getRedemptionFeeRatio(_redInfo.currentTroveAddress) + feeRecipient.baseRate();
    uint256 amountStableLeft = getRedemptionAmount(currentFeeRatio, _redInfo.stableCoinLeft);
    while (
      0 < currentRedemptionTrove.netDebt() &&
      currentRedemptionTrove.netDebt() <= amountStableLeft &&
      currentFeeRatio < _maxRate
    ) {
      _redInfo = commitFullRedeem(_redInfo, currentFeeRatio);
      currentFeeRatio = getRedemptionFeeRatio(_redInfo.currentTroveAddress);
      amountStableLeft = getRedemptionAmount(currentFeeRatio, _redInfo.stableCoinLeft);
      currentRedemptionTrove = ITrove(_redInfo.currentTroveAddress);
    }
    return _redInfo;
  }

  /**
   * @dev commits full redemption for the current trove, should be called after checks
   */
  function commitFullRedeem(RedemptionInfo memory _redInfo, uint256 _currentFeeRatio)
    internal
    returns (RedemptionInfo memory)
  {
    address nextTroveAddress = nextTrove(_redInfo.collateralToken, _redInfo.currentTroveAddress);
    (uint256 stblRed, uint256 colRed) = _redeemFullTrove(msg.sender, _redInfo.currentTroveAddress);

    _redInfo.stableCoinRedeemed += stblRed;
    uint256 newFee = getRedemptionFee(_currentFeeRatio, stblRed);
    _redInfo.feeAmount += newFee;
    _redInfo.stableCoinLeft -= stblRed + newFee;
    _redInfo.collateralRedeemed += colRed;
    _redInfo.lastTroveRedeemed = _redInfo.currentTroveAddress;
    _redInfo.currentTroveAddress = nextTroveAddress;
    return _redInfo;
  }

  /**
   * @dev check if the Trove guessed ICR matches and commits partial redemptios
   */
  function commitPartRedeem(
    RedemptionInfo memory _redInfo,
    uint256 _maxRate,
    uint256 _lastTroveCurrentICR,
    address _lastTroveNewPositionHint
  ) internal returns (RedemptionInfo memory) {
    ITrove currentRedemptionTrove = ITrove(_redInfo.currentTroveAddress);
    uint256 currentFeeRatio = getRedemptionFeeRatio(_redInfo.currentTroveAddress) + feeRecipient.baseRate();
    if (currentRedemptionTrove.collateralization() == _lastTroveCurrentICR && currentFeeRatio < _maxRate) {
      uint256 maxLastRedeem = BONQMath.min(
        getRedemptionAmount(currentFeeRatio, _redInfo.stableCoinLeft),
        currentRedemptionTrove.netDebt()
      );
      (uint256 stblRed, uint256 colRed) = _redeemPartTrove(
        msg.sender,
        _redInfo.currentTroveAddress,
        maxLastRedeem,
        _lastTroveNewPositionHint
      );
      _redInfo.stableCoinRedeemed += stblRed;
      uint256 newFee = getRedemptionFee(currentFeeRatio, stblRed);
      _redInfo.feeAmount += newFee;
      _redInfo.stableCoinLeft -= stblRed + newFee;
      _redInfo.collateralRedeemed += colRed;
      _redInfo.lastTroveRedeemed = _redInfo.currentTroveAddress;
    }
    return _redInfo;
  }

  /**
   * @dev redeem desired StableCoin amount for desired collateral tokens
   * @param _stableAmount the desired amount of StableCoin to pay for redemption
   * @param _maxRate is max fee (in % with 1e18 precision) allowed to pay
   * @param _lastTroveCurrentICR ICR of the last trove to be redeemed, if matches then the hint is working and it redeems
   * @param _lastTroveNewPositionHint hint for the of the nextNewTrove after redemption for the latest trove
   */
  function redeemStableCoinForCollateral(
    address _collateralToken,
    uint256 _stableAmount,
    uint256 _maxRate,
    uint256 _lastTroveCurrentICR,
    address _lastTroveNewPositionHint
  ) public {
    IMintableToken stableCoin_cached = stableCoin;
    require(
      ITrove(firstTrove(_collateralToken)).collateralization() > DECIMAL_PRECISION,
      "a7f99 first trove is undercollateralised and must be liquidated"
    );
    require(stableCoin_cached.balanceOf(msg.sender) >= _stableAmount, "a7f99 insufficient Fiat balance");
    require(
      stableCoin_cached.allowance(msg.sender, address(this)) >= _stableAmount,
      "a7f99 StableCoin is not approved for factory"
    );

    IFeeRecipient feeRecipient_cache = feeRecipient;
    RedemptionInfo memory redInfo;
    redInfo.collateralToken = _collateralToken;
    redInfo.stableCoinLeft = _stableAmount;

    redInfo.currentTroveAddress = firstTrove(_collateralToken);
    redInfo = commitFullRedemptions(redInfo, _maxRate);
    redInfo = commitPartRedeem(redInfo, _maxRate, _lastTroveCurrentICR, _lastTroveNewPositionHint);
    if (redInfo.collateralRedeemed > 0) {
      stableCoin_cached.transferFrom(msg.sender, address(this), redInfo.feeAmount);
      feeRecipient_cache.takeFees(redInfo.feeAmount);

      // TODO: increase base rate after each trove redemption
      uint256 startBaseRate = feeRecipient_cache.baseRate();
      uint256 finishBaseRate = feeRecipient_cache.increaseBaseRate(
        (redInfo.stableCoinRedeemed * DECIMAL_PRECISION) / stableCoin_cached.totalSupply()
      );
      emit Redemption(
        _collateralToken,
        redInfo.stableCoinRedeemed,
        redInfo.collateralRedeemed,
        redInfo.stableCoinLeft,
        startBaseRate,
        finishBaseRate,
        redInfo.lastTroveRedeemed
      );
    }
  }

  /**
   * @dev function to be called from trove to change totalDebt
   * @param _borrow indicates if it is borrow or repay/liquidatin
   */
  function updateTotalDebt(uint256 _amount, bool _borrow) public override {
    ITrove trove = ITrove(msg.sender);
    address token = address(trove.token());
    require(containsTrove(token, msg.sender), "fbfd5 not a valid trove");
    if (_borrow) {
      totalDebt += _amount;
      _troves[token].totalDebt += _amount;
    } else {
      totalDebt -= _amount;
      _troves[token].totalDebt -= _amount;
    }
    emit DebtUpdate(token, totalDebt);
  }

  /// @dev to emit Liquidation event, to be called from a trove after liquidation.
  /// @param  _token address of token
  /// @param  _trove address of the Trove
  /// @param  stabilityPoolLiquidation address of StabilityPool, 0x0 if Community LiquidationPool
  /// @param  collateral uint256 amount of collateral
  function emitLiquidationEvent(
    address _token,
    address _trove,
    address stabilityPoolLiquidation,
    uint256 collateral
  ) public override {
    emit TroveLiquidated(_trove, _token, tokenToPriceFeed.tokenPrice(_token), stabilityPoolLiquidation, collateral);
  }

  /// @dev to emit Trove's debt update event, to be called from trove
  /// @param  _token address of token
  /// @param  _newAmount new trove's debt value
  /// @param  _newCollateralization new trove's collateralization value
  function emitTroveDebtUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization,
    uint256 _feePaid
  ) external override {
    emit TroveDebtUpdate(
      address(msg.sender), // solhint-disable-next-line avoid-tx-origin
      address(tx.origin),
      _token,
      _newAmount,
      feeRecipient.baseRate(),
      _newCollateralization,
      _feePaid
    );
  }

  /// @dev to emit Collateral update event, to be called from trove
  /// @param  _token address of token
  /// @param  _newAmount new trove's Collateral value
  /// @param  _newCollateralization new trove's collateralization value
  function emitTroveCollateralUpdate(
    address _token,
    uint256 _newAmount,
    uint256 _newCollateralization
  ) external override {
    emit TroveCollateralUpdate(address(msg.sender), _token, _newAmount, _newCollateralization);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//import "hardhat/console.sol";

/// @title implements LinkedList structure used to store/operate sorted Troves
library LinkedAddressList {
  struct EntryLink {
    address prev;
    address next;
  }

  struct List {
    address _last;
    address _first;
    uint256 _size;
    mapping(address => EntryLink) _values;
  }

  function add(
    List storage _list,
    address _element,
    address _reference,
    bool _before
  ) internal returns (bool) {
    require(
      _reference == address(0x0) || _list._values[_reference].next != address(0x0),
      "79d3d _ref neither valid nor 0x"
    );
    // the lement must not exist in order to be added
    EntryLink storage element_values = _list._values[_element];
    if (element_values.prev == address(0x0)) {
      // the list is empty
      if (_list._last == address(0x0)) {
        // if it is the first element in the list, it refers to itself to indicate this
        element_values.prev = _element;
        element_values.next = _element;
        // the new element is now officially the first
        _list._first = _element;
        // the new element is now officially the last
        _list._last = _element;
      } else {
        if (_before && (_reference == address(0x0) || _reference == _list._first)) {
          // the element should be added as the first element
          address first = _list._first;
          _list._values[first].prev = _element;
          element_values.prev = _element;
          element_values.next = first;
          _list._first = _element;
        } else if (!_before && (_reference == address(0x0) || _reference == _list._last)) {
          // the element should be added as the last element
          address last = _list._last;
          _list._values[last].next = _element;
          element_values.prev = last;
          element_values.next = _element;
          _list._last = _element;
        } else {
          // the element should be inserted in between two elements
          EntryLink memory ref = _list._values[_reference];
          if (_before) {
            element_values.prev = ref.prev;
            element_values.next = _reference;
            _list._values[_reference].prev = _element;
            _list._values[ref.prev].next = _element;
          } else {
            element_values.prev = _reference;
            element_values.next = ref.next;
            _list._values[_reference].next = _element;
            _list._values[ref.next].prev = _element;
          }
        }
      }
      _list._size = _list._size + 1;
      return true;
    }
    return false;
  }

  function remove(List storage _list, address _element) internal returns (bool) {
    EntryLink memory element_values = _list._values[_element];
    if (element_values.next != address(0x0)) {
      if (_element == _list._last && _element == _list._first) {
        // it is the last element in the list
        delete _list._last;
        delete _list._first;
      } else if (_element == _list._first) {
        // simplified process for removing the first element
        address next = element_values.next;
        _list._values[next].prev = next;
        _list._first = next;
      } else if (_element == _list._last) {
        // simplified process for removing the last element
        address new_list_last = element_values.prev;
        _list._last = new_list_last;
        _list._values[new_list_last].next = new_list_last;
      } else {
        // set the previous and next to point to each other
        address next = element_values.next;
        address prev = element_values.prev;
        _list._values[next].prev = prev;
        _list._values[prev].next = next;
      }
      // in any case, delete the element itself
      delete _list._values[_element];
      _list._size = _list._size - 1;
      return true;
    }
    return false;
  }
}