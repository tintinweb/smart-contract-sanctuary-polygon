// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

// ____________________________,▄████████████████████▌▄____________________________
// _______________________▌████▀╙ ________█▌_________┴▀████▌_______________________
// ___________________▓███╝_██____________█▌_____________██╙████___________________
// ________________███▀______██___________█▌____________██_____╙███,_______________
// _____________▓██┘__________██__________█▌___________█▌__________███_____________
// ___________███______________█▌_________█▌__________█▌_____________███___________
// _________██╨_██▌_____________█▌________█▌_________██____________▄██'└▀█_________
// _______▄█▀_____███____________█▄_______█▌________██___________▓██_____╙██_______
// ______██_________▀██__________└█─______█▌_______██__________███_________██______
// ____,█▀____________╙▀█_________╝█______█▌______▓█_________██▀____________╙█▄____
// ___╓█▀________________██▄_______╫█▄██████████▌▓█_______,█▀╙_______________ █▌___
// ___████▌,_______________██▌___████╜__________╙████___▄██'________________,▓██▄__
// __█▌___└█████▄____________████╙__________________¬████______________▄████▌┘_└█__
// _█▌_________¬▀████▄______,██▀██_____________________██▄_______,▓████▀ _______██_
// _█ _______________▀████▄▓█'___╙▀█_____________________██_▄████▌╙______________█▄
// █▌_____________________██_______ ██▄___________________██▀ ___________________█▌
// ██_____________________█T__________██▌__________________█_____________________▐█
// █▄____________________╟█_____________███________________██_____________________█
// ████████████████████████_______________▀██______________████████████████████████
// █▌_____________________█_________________╙▀█____________█▌____________________ █
// █▌_____________________██__________________ ██▄________▓█_____________________▓█
// ▐█_________________▌██████____________________██▌_____▄████▄__________________██
// _█▌__________╓▓████╜ ____██_____________________███__██____╝████▌____________]█_
// _└█_____▄████▀└___________╙██_____________________▀██▌__________╙████▌,______█▌_
// __██████▀________________██▀└███▄______________,███╙╙▀█,_____________└█████▄█▌__
// ___██_________________,█▀╙______███████▓▓███████└_____'██▄________________¬██___
// ____██______________▄██'_______▄█______█▌ ____╙█_________██▌______________██____
// _____▀█▄__________▓██_________▐█_______█▌______╩█__________███___________██_____
// ______ ██_______███__________╓█─_______█▌_______██___________▀██_______██╙______
// ________▓█▌___██▀___________┌█L________█▌________██____________╙▀█___▄██________
// __________███▀╙_____________█▀_________█▌_________██______________████__________
// ____________▀██____________█▀__________█▌__________██____________███____________
// ______________└███________█▀___________█▌___________█▌________▓██▀______________
// _________________╙███▌___██____________█▌___________ █▄___▄███╜_________________
// _____________________▀████▄____________█▌____________╠████▀ ____________________
// __________________________▀███████▄▄▄,_█▌_,▄▄▄▓██████▌└_________________________

import 'openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';
import 'openzeppelin-contracts-upgradeable/contracts/access/AccessControlEnumerableUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721BurnableUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/utils/CountersUpgradeable.sol';
import 'medallion/IOwnable.sol';

/// @notice Community Pass V1
contract CommunityPassV1 is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable,
    IOwnable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice Delegated admin role
    bytes32 public constant DELEGATE_ADMIN_ROLE = keccak256('DELEGATE_ADMIN_ROLE');

    /// @notice Delegated issuer role
    bytes32 public constant DELEGATE_ISSUER_ROLE = keccak256('DELEGATE_ISSUER_ROLE');

    /// @notice The contract metadata URI
    string private _contractURI;

    /// @notice The token metadata URI
    string private _tokenURI;

    /// @notice Track token IDs
    CountersUpgradeable.Counter private _currentTokenId;

    /// @notice maintain pass => issuance (anon) history
    mapping(uint256 => uint256) private _issuedAt;

    /// @notice maintain pass => transfer (anon) history
    mapping(uint256 => uint256[]) private _transferredAt;

    /// @notice Disable direct initialization
    /// @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the community pass implementation
    /// @param name_ The ERC721 name
    /// @param symbol_ The ERC721 symbol
    /// @param contractURI_ The contract metadata URI
    /// @param tokenURI_ The token metadata URI
    /// @param owner_ The contract owner address
    /// @param delegateAdmin_ The delegated admin address
    /// @param delegateIssuer_ The delegated issuer address
    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata contractURI_,
        string calldata tokenURI_,
        address owner_,
        address delegateAdmin_,
        address delegateIssuer_
    ) public initializer {
        // Initialize inherited contracts
        __ERC721_init_unchained(name_, symbol_);
        __AccessControlEnumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __ERC721Enumerable_init_unchained();

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _grantRole(DELEGATE_ADMIN_ROLE, delegateAdmin_);
        _grantRole(DELEGATE_ISSUER_ROLE, delegateIssuer_);

        // Define hierarchy of roles
        _setRoleAdmin(DELEGATE_ISSUER_ROLE, DELEGATE_ADMIN_ROLE);

        // Optimise for gas
        _currentTokenId.increment();

        // Set ERC721 metadata URIs
        _contractURI = contractURI_;
        _tokenURI = tokenURI_;
    }

    /// @notice Issues a community pass to the recipient address
    /// @dev Only callable by DELEGATE_ISSUER_ROLE
    /// @dev Cannot be called directly, must be called through ERC1967 proxy
    /// @return uint256 The newly issued tokenId
    function privateIssueToRecipient(address recipient)
        public
        onlyProxy
        onlyRole(DELEGATE_ISSUER_ROLE)
        returns (uint256)
    {
        return _issueTo(recipient);
    }

    /// @notice Amends the contract URI
    /// @dev Only callable by DELEGATE_ADMIN_ROLE
    /// @param newContractURI The new contract metadata URI
    function amendContractURI(string calldata newContractURI) public onlyRole(DELEGATE_ADMIN_ROLE) {
        _contractURI = newContractURI;
    }

    /// @notice Amends the token URI shared by all tokens
    /// @dev Only callable by DELEGATE_ADMIN_ROLE
    /// @param newTokenURI The new token metadata URI
    function amendTokenURI(string calldata newTokenURI) public onlyRole(DELEGATE_ADMIN_ROLE) {
        _tokenURI = newTokenURI;
    }

    /// @notice Withdraws arbitrary ERC721 tokens to the receipient address
    /// @dev only callable by DELEGATE_ADMIN_ROLE
    /// @param tokenContractAddress The token contract address of the token to withdraw
    /// @param tokenId The token id to withdraw
    /// @param recipientAddress The account to transfer to
    function withdrawERC721(
        address tokenContractAddress,
        uint256 tokenId,
        address recipientAddress
    ) public onlyRole(DELEGATE_ADMIN_ROLE) {
        require(recipientAddress != address(0), 'CommunityPass: transfer to zero address');
        IERC721(tokenContractAddress).safeTransferFrom(address(this), recipientAddress, tokenId);
    }

    /// @notice Withdraws arbitrary ERC20 tokens to the receipient address
    /// @dev only callable by DELEGATE_ADMIN_ROLE
    /// @param tokenContractAddress The token contract address of the token to withdraw
    /// @param amount The amount of tokens to withdraw
    /// @param recipientAddress The account to transfer to
    function withdrawERC20(
        address tokenContractAddress,
        uint256 amount,
        address recipientAddress
    ) public onlyRole(DELEGATE_ADMIN_ROLE) {
        require(recipientAddress != address(0), 'CommunityPass: transfer to zero address');
        IERC20(tokenContractAddress).transfer(recipientAddress, amount);
    }

    /// @notice Withdraws native token to receipient address
    /// @dev only callable by DELEGATE_ADMIN_ROLE
    /// @param amount The amount of native token to withdraw
    /// @param recipientAddress The account to transfer to
    function withdrawNativeToken(uint256 amount, address recipientAddress) public onlyRole(DELEGATE_ADMIN_ROLE) {
        require(recipientAddress != address(0), 'CommunityPass: transfer to zero address');
        payable(recipientAddress).transfer(amount);
    }

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Provides a contract metadata URI for marketplaces
    /// @return string The contract metadata URI
    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    /// @inheritdoc ERC721Upgradeable
    /// @dev replaces the usual dynamic token URI with a static one
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ownerOf(tokenId) != address(0), 'CommunityPass: invalid token ID');

        return _tokenURI;
    }

    /// @notice Get the issuance (anon) history for a token
    /// @param tokenId The tokenId
    /// @return uint256 When the token was issued
    function issuedAt(uint256 tokenId) public view returns (uint256) {
        return _issuedAt[tokenId];
    }

    /// @notice Get the transfer (anon) history for a token
    /// @param tokenId The tokenId
    /// @param index The transfer index to return history for
    /// @return uint256 When the token was issued
    function transferredAt(uint256 tokenId, uint256 index) public view returns (uint256) {
        require(index < _transferredAt[tokenId].length, 'CommunityPass: out of bounds');
        return _transferredAt[tokenId][index];
    }

    /// @notice Get the number of times a token has been transferred
    /// @param tokenId The tokenId
    /// @return uint256
    function numTransfers(uint256 tokenId) public view returns (uint256) {
        return _transferredAt[tokenId].length;
    }

    /// @inheritdoc IOwnable
    function owner() public view override returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0) {
            return address(0x00);
        }

        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /// @inheritdoc ERC721Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Authorize the caller to upgrade the implementation
    /// @dev Only callable by DELEGATE_ADMIN_ROLE
    /// @dev See https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/proxy/utils/UUPSUpgradeable.sol
    function _authorizeUpgrade(address) internal override onlyRole(DELEGATE_ADMIN_ROLE) {}

    /// @notice Issues a Community Pass
    /// @param recipient The recipient address
    /// @return uint256 The newly issued tokenId
    function _issueTo(address recipient) internal returns (uint256) {
        uint256 newTokenId = _currentTokenId.current();
        _safeMint(recipient, newTokenId);
        _currentTokenId.increment();

        return newTokenId;
    }

    /// @notice Override to emit OwnershipTransferred event
    /// @inheritdoc AccessControlEnumerableUpgradeable
    function _grantRole(bytes32 role, address account) internal virtual override {
        address oldOwner;
        if (role == DEFAULT_ADMIN_ROLE) {
            if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) > 0) {
                oldOwner = getRoleMember(DEFAULT_ADMIN_ROLE, 0);
            }
        }

        super._grantRole(role, account);
        if (role == DEFAULT_ADMIN_ROLE) {
            emit IOwnable.OwnershipTransferred(oldOwner, account);
        }
    }

    /// @inheritdoc ERC721Upgradeable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // maintain (anon) history
        _transferredAt[tokenId].push(block.timestamp);
        if (from == address(0)) {
            _issuedAt[tokenId] = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

/// @notice Interface for Ownable
/// @dev See: https://docs.opensea.io/docs/1-structuring-your-smart-contract#using-ownable
interface IOwnable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @notice Returns the address of the current owner
  /// @return address The current owner
  function owner() external view returns (address);

  /// @notice Transfers ownership of the contract to a new account (`newOwner`)
  /// @dev Can only be called by the current owner
  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

// ____________________________,▄████████████████████▌▄____________________________
// _______________________▌████▀╙ ________█▌_________┴▀████▌_______________________
// ___________________▓███╝_██____________█▌_____________██╙████___________________
// ________________███▀______██___________█▌____________██_____╙███,_______________
// _____________▓██┘__________██__________█▌___________█▌__________███_____________
// ___________███______________█▌_________█▌__________█▌_____________███___________
// _________██╨_██▌_____________█▌________█▌_________██____________▄██'└▀█_________
// _______▄█▀_____███____________█▄_______█▌________██___________▓██_____╙██_______
// ______██_________▀██__________└█─______█▌_______██__________███_________██______
// ____,█▀____________╙▀█_________╝█______█▌______▓█_________██▀____________╙█▄____
// ___╓█▀________________██▄_______╫█▄██████████▌▓█_______,█▀╙_______________ █▌___
// ___████▌,_______________██▌___████╜__________╙████___▄██'________________,▓██▄__
// __█▌___└█████▄____________████╙__________________¬████______________▄████▌┘_└█__
// _█▌_________¬▀████▄______,██▀██_____________________██▄_______,▓████▀ _______██_
// _█ _______________▀████▄▓█'___╙▀█_____________________██_▄████▌╙______________█▄
// █▌_____________________██_______ ██▄___________________██▀ ___________________█▌
// ██_____________________█T__________██▌__________________█_____________________▐█
// █▄____________________╟█_____________███________________██_____________________█
// ████████████████████████_______________▀██______________████████████████████████
// █▌_____________________█_________________╙▀█____________█▌____________________ █
// █▌_____________________██__________________ ██▄________▓█_____________________▓█
// ▐█_________________▌██████____________________██▌_____▄████▄__________________██
// _█▌__________╓▓████╜ ____██_____________________███__██____╝████▌____________]█_
// _└█_____▄████▀└___________╙██_____________________▀██▌__________╙████▌,______█▌_
// __██████▀________________██▀└███▄______________,███╙╙▀█,_____________└█████▄█▌__
// ___██_________________,█▀╙______███████▓▓███████└_____'██▄________________¬██___
// ____██______________▄██'_______▄█______█▌ ____╙█_________██▌______________██____
// _____▀█▄__________▓██_________▐█_______█▌______╩█__________███___________██_____
// ______ ██_______███__________╓█─_______█▌_______██___________▀██_______██╙______
// ________▓█▌___██▀___________┌█L________█▌________██____________╙▀█___▄██________
// __________███▀╙_____________█▀_________█▌_________██______________████__________
// ____________▀██____________█▀__________█▌__________██____________███____________
// ______________└███________█▀___________█▌___________█▌________▓██▀______________
// _________________╙███▌___██____________█▌___________ █▄___▄███╜_________________
// _____________________▀████▄____________█▌____________╠████▀ ____________________
// __________________________▀███████▄▄▄,_█▌_,▄▄▄▓██████▌└_________________________

import 'openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';
import 'openzeppelin-contracts-upgradeable/contracts/access/AccessControlEnumerableUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';

import './IAccessControlProviderV1.sol';
import './IAccessControlSubscriberV1.sol';
import './IOwnableV1.sol';

contract AccessControlProviderV1 is
    Initializable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    IOwnableV1,
    IAccessControlProviderV1
{
    /// @notice Owner role
    bytes32 public constant OWNER_ROLE = DEFAULT_ADMIN_ROLE;

    /// @notice Admin role
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    /// @notice Operator role
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    /// @notice List of subscribers
    address[] private _subscribers;

    /// @notice Mapping of subscriber address to position in list
    mapping(address => uint256) private _subscribersIndex;

    /// @notice Disable direct initialization
    /// @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the access control provider
    /// @param owner_ The owner address
    /// @param admin_ The admin address
    /// @param operator_ The operator address
    function __AccessControlProviderV1_init(
        address owner_,
        address admin_,
        address operator_
    ) public virtual initializer {
        // Initialize inherited contracts
        __AccessControlEnumerable_init_unchained();

        // Grant roles
        _grantRole(OWNER_ROLE, owner_);
        _grantRole(ADMIN_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, operator_);

        // Define hierarchy of roles
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
    }

    /* -------------------------------- OWNER ------------------------------- */

    /// @notice Transfer ownership to new owner
    /// @dev Only callable by OWNER_ROLE
    function transferOwnership(address newOwner) public onlyRole(OWNER_ROLE) {
        _grantRole(OWNER_ROLE, newOwner);
        _revokeRole(OWNER_ROLE, _msgSender());
    }

    /* -------------------------------- ADMIN ------------------------------- */

    /// @notice Authorize the caller to upgrade the implementation
    /// @dev Only callable by ADMIN_ROLE
    /// @dev See https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/proxy/utils/UUPSUpgradeable.sol
    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}

    /* ------------------------------ OPERATOR ------------------------------ */

    /// @inheritdoc IAccessControlProviderV1
    function subscribe(address subscriber) public onlyRole(OPERATOR_ROLE) {
        if (_isSubscribed(subscriber)) {
            return;
        }

        require(
            IERC165(subscriber).supportsInterface(type(IAccessControlSubscriberV1).interfaceId),
            'Provider: invalid subscriber'
        );

        _subscribersIndex[subscriber] = _subscribers.length;
        _subscribers.push(subscriber);
    }

    /// @inheritdoc IAccessControlProviderV1
    function unsubscribe(address subscriber) public onlyRole(OPERATOR_ROLE) {
        if (!_isSubscribed(subscriber)) {
            return;
        }

        address lastSubscriber = _subscribers[_subscribers.length - 1];
        _subscribers.pop();

        uint256 subscriberIndex = _subscribersIndex[subscriber];
        if (subscriberIndex < _subscribers.length) {
            _subscribers[subscriberIndex] = lastSubscriber;
            _subscribersIndex[lastSubscriber] = subscriberIndex;
        }
    }

    /* ------------------------------- PUBLIC ------------------------------- */

    /// @notice Get the current list of subscribers
    /// @return address[] The list of subscribers
    function subscribers() public view returns (address[] memory) {
        return _subscribers;
    }

    /// @inheritdoc IOwnableV1
    function owner() public view override returns (address) {
        if (getRoleMemberCount(OWNER_ROLE) == 0) {
            return address(0x00);
        }

        return getRoleMember(OWNER_ROLE, 0);
    }

    /// @inheritdoc AccessControlEnumerableUpgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IOwnableV1).interfaceId ||
            interfaceId == type(IAccessControlProviderV1).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* ------------------------------ INTERNAL ------------------------------ */

    /// @notice Override to emit OwnershipTransferred event
    /// @inheritdoc AccessControlEnumerableUpgradeable
    function _grantRole(bytes32 role, address account) internal virtual override {
        address oldOwner;
        if (role == OWNER_ROLE) {
            if (getRoleMemberCount(OWNER_ROLE) > 0) {
                oldOwner = getRoleMember(OWNER_ROLE, 0);
            }
        }

        super._grantRole(role, account);
        if (role == OWNER_ROLE) {
            _transferOwnership(oldOwner, account);
        }
    }

    function _isSubscribed(address subscriber) private view returns (bool) {
        uint256 subscriberIndex = _subscribersIndex[subscriber];
        if (subscriberIndex >= _subscribers.length) {
            return false;
        }

        return _subscribers[subscriberIndex] == subscriber;
    }

    function _transferOwnership(address oldOwner, address newOwner) internal {
        emit OwnershipTransferred(oldOwner, newOwner);
        for (uint256 i = 0; i < _subscribers.length; i++) {
            try IAccessControlSubscriberV1(_subscribers[i]).onOwnershipTransferred(oldOwner, newOwner) {} catch {}
        }
    }

    /// @dev Reserved space to allow future versions to add new variables
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import 'openzeppelin-contracts/contracts/access/IAccessControlEnumerable.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';
import 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol';

import './IAccessControlProviderV1.sol';
import './IAccessControlSubscriberV1.sol';
import './IOwnableV1.sol';

abstract contract AccessControlSubscriberV1 is
    Initializable,
    ContextUpgradeable,
    IERC165,
    IAccessControlSubscriberV1,
    IOwnableV1
{
    /// @notice Owner role
    bytes32 public constant OWNER_ROLE = 0x00;

    /// @notice Admin role
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    /// @notice Operator role
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    /// @notice Access control provider address
    address private _provider;

    /// @notice Initializes the access control subscriber
    /// @dev Requires that provider implements IAccessControlEnumerable, IAccessControlProviderV1 and IOwnableV1
    /// @param provider_ The access control provider address
    function __AccessControlSubscriberV1_init(address provider_) public virtual initializer {
        __Context_init_unchained();

        require(
            IERC165(provider_).supportsInterface(type(IAccessControlEnumerable).interfaceId),
            'Subscriber: invalid provider'
        );
        require(
            IERC165(provider_).supportsInterface(type(IAccessControlProviderV1).interfaceId),
            'Subscriber: invalid provider'
        );
        require(IERC165(provider_).supportsInterface(type(IOwnableV1).interfaceId), 'Subscriber: invalid provider');
        _provider = provider_;
    }

    /// @notice Use external access control to gate access to functionality
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /* ------------------------------- PUBLIC ------------------------------- */

    /// @inheritdoc IAccessControlSubscriberV1
    function onOwnershipTransferred(address oldOwner, address newOwner) public {
        require(_msgSender() == _provider, 'Subscriber: unauthorized');
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IAccessControlSubscriberV1).interfaceId;
    }

    /// @inheritdoc IOwnableV1
    function owner() public view override returns (address) {
        return IOwnableV1(_provider).owner();
    }

    /* ------------------------------ INTERNAL ------------------------------ */

    /// @notice Revert with a standard message if account is missing role
    /// @dev See AccessControlUpgradeable._checkRole
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!IAccessControlEnumerable(_provider).hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        ' is missing role ',
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IAccessControlProviderV1 {
    /// @notice Subscribe subscriber to provider
    /// @dev Subscriber must implement IAccessControlSubscriberV1
    /// @dev This is a no-op if the subscriber is already subscribed
    function subscribe(address subscriber) external;

    /// @notice Unsubscribe subscriber from provider
    /// @dev This is a no-op if the subscriber is not already subscribed
    function unsubscribe(address subscriber) external;

    /// @notice Transfer ownership to new owner
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IAccessControlSubscriberV1 {
  /// @notice Called when provider ownership changes
  /// @dev Expect reverts to be ignored
  function onOwnershipTransferred(address oldOwner, address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

/// @notice Interface for Ownable
/// @dev See: https://docs.opensea.io/docs/1-structuring-your-smart-contract#using-ownable
interface IOwnableV1 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Returns the address of the current owner
    /// @return address The current owner
    function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC1967Proxy, IERC1822Proxiable} from 'openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol';
import {UUPSUpgradeable} from 'openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol';
import {OwnableUpgradeable, Initializable} from 'openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';

import {AccessControlProviderV1} from 'medallion/brevity/access/AccessControlProviderV1.sol';
import {ProofV1} from 'medallion/brevity/proof/ProofV1.sol';
import {CommunityPassV1} from 'medallion/CommunityPassV1.sol';
import {ICommunityFactoryV1} from './ICommunityFactoryV1.sol';

/// @title CommunityFactoryV1
/// @notice This contract is responsible for deploying new communities, which are comprised of an AccessControlProviderV1, ProofV1, and CommunityPassV1. This
/// contract also provides a mapping of artist name to the deployed contracts for the given artist.
/// @dev This contract is upgradeable via the UUPS pattern, but can also support changing the implementation of the deployable contracts, without upgrading the factory itself,
///  providing the deployable contracts not differ in their intialization parameters across versions.
contract CommunityFactoryV1 is UUPSUpgradeable, Initializable, OwnableUpgradeable, ICommunityFactoryV1 {
    /// @notice The address of the current implementation of ProductV1
    address private _currentAccessControlImplementation;
    /// @notice The address of the current implementation of ProofV1
    address private _currentProofImplementation;
    /// @notice The address of the current implementation of CommunityPassV1
    address private _currentCommunityPassImplementation;

    /// @notice Emitted when a new instance of AccessControlProviderV1 is deployed
    event DeployedAccessControlProvider(address indexed accessControlProvider);

    /// @notice Emitted when a new instance of ProofV1 is deployed
    event DeployedProof(address indexed proof);

    /// @notice Emitted when a new instance of CommunityPassV1 is deployed
    event DeployedCommunityPass(address indexed communityPass);

    /// @notice Emitted when the implementation of AccessControlProviderV1 is upgraded
    /// @param oldImplementation The address of the old implementation
    /// @param newImplementation The address of the new implementation
    event AccessControlProviderImplementationUpgrade(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// @notice Emitted when the implementation of ProofV1 is upgraded
    /// @param oldImplementation The address of the old implementation
    /// @param newImplementation The address of the new implementation
    event ProofImplementationUpgrade(address indexed oldImplementation, address indexed newImplementation);

    /// @notice Emitted when the implementation of CommunityPassV1 is upgraded
    /// @param oldImplementation The address of the old implementation
    /// @param newImplementation The address of the new implementation
    event CommunityPassImplementationUpgrade(address indexed oldImplementation, address indexed newImplementation);

    constructor() {
        _disableInitializers();
    }

    /// @notice stores and returns the deployed instance of AccessControlProviderV1 for a given artist
    mapping(bytes32 => address) private _accessControlProvider;

    /// @notice stores and returns the deployed instance of CommunityPassV1 for a given artist
    mapping(bytes32 => address) private _communityPass;

    /// @notice stores and returns the deployed instances of ProofV1 for a given artist
    mapping(bytes32 => address[]) private _proofs;

    /// @notice initializes this contract, called once upon deployment
    /// @param owner_ The owner of this contract
    /// @param currentaAccessControlImplementation_ The address of the current implementation of AccessControlProviderV1
    /// @param currentProofImplementation_ The address of the current implementation of ProofV1
    /// @param currentCommunityPassImplementation_ The address of the current implementation of CommunityPassV1
    function __CommunityFactory_init(
        address owner_,
        address currentaAccessControlImplementation_,
        address currentProofImplementation_,
        address currentCommunityPassImplementation_
    ) public virtual initializer {
        __Ownable_init();
        transferOwnership(owner_);
        _currentAccessControlImplementation = currentaAccessControlImplementation_;
        _currentProofImplementation = currentProofImplementation_;
        _currentCommunityPassImplementation = currentCommunityPassImplementation_;
    }

    /// @inheritdoc ICommunityFactoryV1
    function deployAccessControlProvider(
        string memory artist_,
        address owner_,
        address admin_,
        address operator_
    ) public onlyOwner returns (address) {
        ERC1967Proxy accessControl = new ERC1967Proxy(
            _currentAccessControlImplementation,
            abi.encodeCall(AccessControlProviderV1.__AccessControlProviderV1_init, (owner_, admin_, operator_))
        );

        _accessControlProvider[keccak256(abi.encodePacked(artist_))] = address(accessControl);

        emit DeployedAccessControlProvider(address(accessControl));

        return address(accessControl);
    }

    /// @inheritdoc ICommunityFactoryV1
    function deployProof(
        string memory artist_,
        string memory proofName_,
        string memory proofSymbol_,
        string memory proofContractURI_,
        address accessControlProvider_
    ) public onlyOwner returns (address) {
        require(
            _accessControlProvider[keccak256(abi.encodePacked(artist_))] != address(0),
            'CommunityFactoryV1: accessControlProvider not deployed'
        );

        ERC1967Proxy proof = new ERC1967Proxy(
            _currentProofImplementation,
            abi.encodeCall(
                ProofV1.__ProofV1_init,
                (proofName_, proofSymbol_, proofContractURI_, accessControlProvider_)
            )
        );

        _proofs[keccak256(abi.encodePacked(artist_))].push(address(proof));

        emit DeployedProof(address(proof));

        return address(proof);
    }

    /// @inheritdoc ICommunityFactoryV1
    function deployCommunityPass(
        string memory artist_,
        string memory communityPassName_,
        string memory communityPassSymbol_,
        string memory communityPassContractURI_,
        string memory communityPassTokenURI_,
        address owner_,
        address admin_,
        address operator_
    ) public onlyOwner returns (address) {
        require(
            _accessControlProvider[keccak256(abi.encodePacked(artist_))] != address(0),
            'CommunityFactoryV1: accessControlProvider not deployed'
        );

        ERC1967Proxy communityPass = new ERC1967Proxy(
            _currentCommunityPassImplementation,
            abi.encodeCall(
                CommunityPassV1.initialize,
                (
                    communityPassName_,
                    communityPassSymbol_,
                    communityPassContractURI_,
                    communityPassTokenURI_,
                    owner_,
                    admin_,
                    operator_
                )
            )
        );

        _communityPass[keccak256(abi.encodePacked(artist_))] = address(communityPass);

        emit DeployedCommunityPass(address(communityPass));

        return address(communityPass);
    }

    /// @inheritdoc ICommunityFactoryV1
    function addCommunityDeployments(
        string memory artist_,
        address accessControlProvider_,
        address communityPass_,
        address[] memory proofs_
    ) public onlyOwner {
        _accessControlProvider[keccak256(abi.encodePacked(artist_))] = accessControlProvider_;
        _communityPass[keccak256(abi.encodePacked(artist_))] = communityPass_;
        _proofs[keccak256(abi.encodePacked(artist_))] = proofs_;
    }

    /// @inheritdoc ICommunityFactoryV1
    function changeAccessControlProviderImplementation(address newAccessControlImplementation_) public onlyOwner {
        _verifyImplementation(newAccessControlImplementation_);

        emit AccessControlProviderImplementationUpgrade(
            _currentAccessControlImplementation,
            newAccessControlImplementation_
        );

        _currentAccessControlImplementation = newAccessControlImplementation_;
    }

    /// @inheritdoc ICommunityFactoryV1
    function changeProofImplementation(address newProofImplementation_) public onlyOwner {
        _verifyImplementation(newProofImplementation_);

        emit ProofImplementationUpgrade(_currentProofImplementation, newProofImplementation_);

        _currentProofImplementation = newProofImplementation_;
    }

    /// @inheritdoc ICommunityFactoryV1
    function changeCommunityPassImplementation(address newCommunityPassImplementation_) public onlyOwner {
        _verifyImplementation(newCommunityPassImplementation_);

        emit CommunityPassImplementationUpgrade(_currentCommunityPassImplementation, newCommunityPassImplementation_);

        _currentCommunityPassImplementation = newCommunityPassImplementation_;
    }

    /// @inheritdoc ICommunityFactoryV1
    function getCommunityDeployments(
        string memory artist_
    ) public view returns (address accessControlProvider, address communityPass, address[] memory proofs) {
        accessControlProvider = _accessControlProvider[keccak256(abi.encodePacked(artist_))];

        communityPass = _communityPass[keccak256(abi.encodePacked(artist_))];

        proofs = _proofs[keccak256(abi.encodePacked(artist_))];

        return (accessControlProvider, communityPass, proofs);
    }

    /// @dev Returns the storage slot that the provided proxiable contract should use to store the implementation,
    /// and verifies that it matches the expected value.
    function _verifyImplementation(address implementation_) internal view {
        try IERC1822Proxiable(implementation_).proxiableUUID() returns (bytes32 slot) {
            require(slot == _IMPLEMENTATION_SLOT, 'ERC1967Upgrade: unsupported proxiableUUID');
        } catch {
            revert('ERC1967Upgrade: new implementation is not UUPS');
        }
    }

    /// @notice Authorize the caller to upgrade the implementation
    /// @dev See https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/proxy/utils/UUPSUpgradeable.sol
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface ICommunityFactoryV1 {
    /// @notice Deploys a new instance of AccessControlProviderV1 for the given `artist_`
    /// @param artist_ The artist name
    /// @param owner_ The address to be assigned the owner role within AccessControlProviderV1
    /// @param admin_ The address to be assigned the admin role within AccessControlProviderV1
    /// @param operator_ The address to be assigned the operator role within AccessControlProviderV1
    function deployAccessControlProvider(
        string memory artist_,
        address owner_,
        address admin_,
        address operator_
    ) external returns (address);

    /// @notice Deploys a new instance of ProofV1 for the given `artist_`
    /// @param artist_ The artist name
    /// @param proofName_ The name to be assigned to the ProofV1 contract
    /// @param proofSymbol_ The symbol to be assigned to the ProofV1 contract
    /// @param proofContractURI_ The contract URI to be assigned to the ProofV1 contract
    /// @param accessControlProvider_ The address of the AccessControlProviderV1 which will control the instance of ProofV1
    function deployProof(
        string memory artist_,
        string memory proofName_,
        string memory proofSymbol_,
        string memory proofContractURI_,
        address accessControlProvider_
    ) external returns (address);

    /// @notice Deploys a new instance of CommunityPassV1 for the given `artist_`
    /// @param artist_ The artist name
    /// @param communityPassName_ The name to be assigned to the CommunityPassV1 contract
    /// @param communityPassSymbol_ The symbol to be assigned to the CommunityPassV1 contract
    /// @param communityPassContractURI_ The contract URI to be assigned to the CommunityPassV1 contract
    /// @param communityPassTokenURI_ The token URI to be assigned to the CommunityPassV1 contract
    /// @param owner_ The address to be assigned the owner role within CommunityPassV1
    /// @param admin_ The address to be assigned the admin role within CommunityPassV1
    /// @param operator_ The address to be assigned the operator role within CommunityPassV1
    /// @dev note: the community pass contract does not adhere to the AccessControlProviderV1 pattern
    function deployCommunityPass(
        string memory artist_,
        string memory communityPassName_,
        string memory communityPassSymbol_,
        string memory communityPassContractURI_,
        string memory communityPassTokenURI_,
        address owner_,
        address admin_,
        address operator_
    ) external returns (address);

    /// @notice Adds a new community to the mapping of artist name to community deployments
    /// @param artist_ The artist name
    /// @param accessControlProvider_ The address of the AccessControlProviderV1
    /// @param communityPass_ The address of the CommunityPassV1
    /// @param proofs_ The addresses of any ProofV1 deployments
    /// @dev a house keeping function for backwards compatability with previously deployed communities
    function addCommunityDeployments(
        string memory artist_,
        address accessControlProvider_,
        address communityPass_,
        address[] memory proofs_
    ) external;

    /// @notice Changes the implementation of AccessControlProviderV1
    /// @param newAccessControlImplementation_ The address of the new implementation
    function changeAccessControlProviderImplementation(address newAccessControlImplementation_) external;

    /// @notice Changes the implementation of ProofV1
    /// @param newProofImplementation_ The address of the new implementation
    function changeProofImplementation(address newProofImplementation_) external;

    /// @notice Changes the implementation of CommunityPassV1
    /// @param newCommunityPassImplementation_ The address of the new implementation
    function changeCommunityPassImplementation(address newCommunityPassImplementation_) external;

    /// @notice Returns the address of the community for a given artist
    /// @param artist_ The artist name
    /// @return accessControlProvider The address of the AccessControlProviderV1
    /// @return communityPass The address of the CommunityPassV1
    /// @return proofs The addresses of any ProofV1 deployments
    function getCommunityDeployments(
        string memory artist_
    ) external view returns (address accessControlProvider, address communityPass, address[] memory proofs);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IProofV1 {
    /* ------------------------------ OPERATOR ------------------------------ */

    /// @notice Creates a new collection
    /// @dev Only callable by OPERATOR_ROLE
    /// @param collectionId A unique identifier for the new collection
    /// @param newCollectionURI The collection metadata URI
    /// @param issueLimit Per address limit for the collection, zero is unlimited
    function createCollection(
        bytes32 collectionId,
        string calldata newCollectionURI,
        uint256 issueLimit
    ) external;

    /// @notice Issues a new token for a specific collection
    /// @dev Only callable by OPERATOR_ROLE
    /// @param recipient The token recipient
    /// @param collectionId The collection id
    /// @return uint256 The new tokenId
    function issue(address recipient, bytes32 collectionId) external returns (uint256);

    /// @notice Issues multiple tokens for a specific collection
    /// @dev Reverts if any individual issue fails, e.g. due to eligibility
    /// @param recipients The token recipients
    /// @param collectionId The collection id
    /// @return uint256 The new tokenId
    function issueMany(address[] calldata recipients, bytes32 collectionId) external returns (uint256[] memory);

    /* ------------------------------- PUBLIC ------------------------------- */

    /// @notice Overload balanceOf for collections
    /// @param owner The owner address
    /// @param collectionId The collection id
    /// @return uint256 The owner's balance for the collection
    function balanceOf(address owner, bytes32 collectionId) external view returns (uint256);

    /// @notice Get the collection id for a specfic token
    /// @param tokenId The tokenId
    /// @return bytes32 The collection id
    function tokenCollection(uint256 tokenId) external view returns (bytes32);

    /// @notice Get the number of product collections
    /// @return uint256 The number of collections
    function totalCollections() external view returns (uint256);

    /// @notice Get total issued tokens for a collection
    /// @param collectionId The collection id
    /// @return uint256 The total supply for the provided collection
    function totalSupply(bytes32 collectionId) external view returns (uint256);

    /// @notice Get the collection by index
    /// @dev Used for enumeration
    /// @param index The collection index
    function collectionByIndex(uint256 index) external view returns (bytes32);

    /// @notice Return the collection metadata URI
    /// @param collectionId The collection identifier
    /// @return string The collection metadata URI
    function collectionURI(bytes32 collectionId) external view returns (string memory);

    /// @notice Check if a recipient is eligible to receive the proof
    /// @param recipient The recipient address
    /// @return bool Whether the recipient is eligible to receive the proof
    function isEligible(address recipient, bytes32 collectionId) external view returns (bool);

    /// @notice Get the sequential index of a token within a collection
    /// @param collectionId The collection id
    /// @param tokenId The token id
    /// @return uint256 The sequential index of the token within the collection
    function tokenCollectionIndex(bytes32 collectionId, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

// ____________________________,▄████████████████████▌▄____________________________
// _______________________▌████▀╙ ________█▌_________┴▀████▌_______________________
// ___________________▓███╝_██____________█▌_____________██╙████___________________
// ________________███▀______██___________█▌____________██_____╙███,_______________
// _____________▓██┘__________██__________█▌___________█▌__________███_____________
// ___________███______________█▌_________█▌__________█▌_____________███___________
// _________██╨_██▌_____________█▌________█▌_________██____________▄██'└▀█_________
// _______▄█▀_____███____________█▄_______█▌________██___________▓██_____╙██_______
// ______██_________▀██__________└█─______█▌_______██__________███_________██______
// ____,█▀____________╙▀█_________╝█______█▌______▓█_________██▀____________╙█▄____
// ___╓█▀________________██▄_______╫█▄██████████▌▓█_______,█▀╙_______________ █▌___
// ___████▌,_______________██▌___████╜__________╙████___▄██'________________,▓██▄__
// __█▌___└█████▄____________████╙__________________¬████______________▄████▌┘_└█__
// _█▌_________¬▀████▄______,██▀██_____________________██▄_______,▓████▀ _______██_
// _█ _______________▀████▄▓█'___╙▀█_____________________██_▄████▌╙______________█▄
// █▌_____________________██_______ ██▄___________________██▀ ___________________█▌
// ██_____________________█T__________██▌__________________█_____________________▐█
// █▄____________________╟█_____________███________________██_____________________█
// ████████████████████████_______________▀██______________████████████████████████
// █▌_____________________█_________________╙▀█____________█▌____________________ █
// █▌_____________________██__________________ ██▄________▓█_____________________▓█
// ▐█_________________▌██████____________________██▌_____▄████▄__________________██
// _█▌__________╓▓████╜ ____██_____________________███__██____╝████▌____________]█_
// _└█_____▄████▀└___________╙██_____________________▀██▌__________╙████▌,______█▌_
// __██████▀________________██▀└███▄______________,███╙╙▀█,_____________└█████▄█▌__
// ___██_________________,█▀╙______███████▓▓███████└_____'██▄________________¬██___
// ____██______________▄██'_______▄█______█▌ ____╙█_________██▌______________██____
// _____▀█▄__________▓██_________▐█_______█▌______╩█__________███___________██_____
// ______ ██_______███__________╓█─_______█▌_______██___________▀██_______██╙______
// ________▓█▌___██▀___________┌█L________█▌________██____________╙▀█___▄██________
// __________███▀╙_____________█▀_________█▌_________██______________████__________
// ____________▀██____________█▀__________█▌__________██____________███____________
// ______________└███________█▀___________█▌___________█▌________▓██▀______________
// _________________╙███▌___██____________█▌___________ █▄___▄███╜_________________
// _____________________▀████▄____________█▌____________╠████▀ ____________________
// __________________________▀███████▄▄▄,_█▌_,▄▄▄▓██████▌└_________________________

import 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol';

import 'medallion/brevity/token/NFTV1.sol';

import './IProofV1.sol';

contract ProofV1 is Initializable, NFTV1, IProofV1 {
    using StringsUpgradeable for uint256;

    /// @notice list of all collections
    bytes32[] private _collections;

    /// @notice mapping of collectionId to 1-indexed position in list of collections
    mapping(bytes32 => uint256) private _collectionsIndex;

    /// @notice mapping of tokenId to collectionId
    mapping(uint256 => bytes32) private _tokenCollection;

    /// @notice mapping of collectionId to tokenIds
    mapping(bytes32 => uint256[]) private _collectionTokens;

    /// @notice mapping of tokenId to index in collection token list
    mapping(uint256 => uint256) private _tokenCollectionIndex;

    /// @notice Limit the number of proofs which can be issued to an address
    mapping(bytes32 => uint256) private _collectionIssueLimit;

    /// @notice Mapping of collectionId to metadata URI
    mapping(bytes32 => string) private _collectionURIs;

    /// @notice Mapping owner address to collection token count
    mapping(bytes32 => mapping(address => uint256)) private _collectionBalances;

    /// @notice Disable direct initialization
    /// @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the proof implementation
    /// @param name_ The ERC721 name
    /// @param symbol_ The ERC721 symbol
    /// @param contractURI_ The contract metadata URI
    /// @param accessControlProvider_ The access control provider address
    function __ProofV1_init(
        string calldata name_,
        string calldata symbol_,
        string calldata contractURI_,
        address accessControlProvider_
    ) public virtual initializer {
        __NFTV1_init(name_, symbol_, contractURI_, contractURI_, accessControlProvider_);
    }

    /* -------------------------------- OWNER ------------------------------- */

    /* -------------------------------- ADMIN ------------------------------- */

    /// @notice Amends the collection URI shared by all collection tokens
    /// @dev Only callable by ADMIN_ROLE
    /// @param collectionId The collectionId
    /// @param newCollectionURI The new collection metadata URI
    function amendCollectionURI(bytes32 collectionId, string calldata newCollectionURI) public onlyRole(ADMIN_ROLE) {
        _checkCollectionExists(collectionId);
        _collectionURIs[collectionId] = newCollectionURI;
    }

    /* ------------------------------ OPERATOR ------------------------------ */

    /// @inheritdoc IProofV1
    function createCollection(
        bytes32 collectionId,
        string calldata newCollectionURI,
        uint256 issueLimit
    ) public onlyRole(OPERATOR_ROLE) {
        require(!_collectionExists(collectionId), 'Proof: collection already exists');

        _collections.push(collectionId);
        _collectionsIndex[collectionId] = _collections.length; // 1-indexed
        _collectionURIs[collectionId] = newCollectionURI;
        _collectionIssueLimit[collectionId] = issueLimit;
    }

    /// @inheritdoc IProofV1
    function issue(address recipient, bytes32 collectionId) public onlyRole(OPERATOR_ROLE) returns (uint256) {
        _checkCollectionExists(collectionId);
        require(isEligible(recipient, collectionId), 'Proof: ineligible');

        return _issue(recipient, collectionId);
    }

    /// @inheritdoc IProofV1
    function issueMany(address[] calldata recipients, bytes32 collectionId)
        public
        onlyRole(OPERATOR_ROLE)
        returns (uint256[] memory)
    {
        _checkCollectionExists(collectionId);
        uint256[] memory tokenIds = new uint256[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            require(isEligible(recipients[i], collectionId), 'Proof: ineligible');
            tokenIds[i] = _issue(recipients[i], collectionId);
        }

        return tokenIds;
    }

    /* ------------------------------- PUBLIC ------------------------------- */

    /// @inheritdoc IProofV1
    function balanceOf(address owner, bytes32 collectionId) public view returns (uint256) {
        _checkCollectionExists(collectionId);

        return _collectionBalances[collectionId][owner];
    }

    /// @inheritdoc IProofV1
    function tokenCollection(uint256 tokenId) public view returns (bytes32) {
        _checkTokenExists(tokenId);

        return _tokenCollection[tokenId];
    }

    /// @inheritdoc IProofV1
    function totalCollections() public view returns (uint256) {
        return _collections.length;
    }

    /// @inheritdoc IProofV1
    function totalSupply(bytes32 collectionId) public view returns (uint256) {
        _checkCollectionExists(collectionId);

        return _collectionTokens[collectionId].length;
    }

    /// @inheritdoc IProofV1
    function collectionByIndex(uint256 index) public view returns (bytes32) {
        require(index >= 0 && index < _collections.length, 'Proof: out of bounds');

        return _collections[index];
    }

    /// @inheritdoc IProofV1
    function collectionURI(bytes32 collectionId) public view virtual override returns (string memory) {
        _checkCollectionExists(collectionId);

        return _collectionURIs[collectionId];
    }

    /// @inheritdoc IProofV1
    function isEligible(address recipient, bytes32 collectionId) public view returns (bool) {
        uint256 issueLimit = _collectionIssueLimit[collectionId];

        return issueLimit == 0 || balanceOf(recipient, collectionId) < issueLimit;
    }

    /// @inheritdoc IProofV1
    function tokenCollectionIndex(bytes32 collectionId, uint256 tokenId) public view returns (uint256) {
        _checkCollectionExists(collectionId);
        _checkTokenExists(tokenId);

        return _tokenCollectionIndex[tokenId];
    }

    /// @inheritdoc ERC721Upgradeable
    /// @dev Replaces static NFT token URI with collection specific one
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _checkTokenExists(tokenId);
        bytes32 collectionId = tokenCollection(tokenId);

        return _collectionURIs[collectionId];
    }

    /* ------------------------------ INTERNAL ------------------------------ */

    /// @notice Assigns collection to tokenId
    /// @dev Does not check if the token exists
    /// @param tokenId The tokenId
    /// @param collectionId The collectionId
    function _assignCollection(uint256 tokenId, bytes32 collectionId) internal {
        _checkCollectionExists(collectionId);

        _tokenCollection[tokenId] = collectionId;
        _tokenCollectionIndex[tokenId] = _collectionTokens[collectionId].length;
        _collectionTokens[collectionId].push(tokenId);
    }

    /// @inheritdoc NFTV1
    function _authorizeIssue(address recipient) internal virtual override {}

    /// @notice Check if collection exists
    /// @dev Reverts if collection doesn't exist
    /// @param collectionId The collectionId
    function _checkCollectionExists(bytes32 collectionId) internal view {
        require(_collectionExists(collectionId), 'Proof: invalid collection');
    }

    /// @notice Check if collection exists
    /// @param collectionId The collectionId
    /// @return bool Whether the collection exists
    function _collectionExists(bytes32 collectionId) internal view returns (bool) {
        return _collectionsIndex[collectionId] > 0;
    }

    /// @notice Issues a new token and assigns the provided collectionId
    /// @dev Does not check that the collection exists before assigning
    /// @param recipient The token recipient
    /// @param collectionId The collectionId
    /// @return uint256 The new tokenId
    function _issue(address recipient, bytes32 collectionId) internal returns (uint256) {
        uint256 tokenId = _issue(recipient);
        _assignCollection(tokenId, collectionId);
        _collectionBalances[collectionId][recipient]++;

        return tokenId;
    }

    /// @dev Reserved space to allow future versions to add new variables
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[42] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface INFTHistoryV1 {
    /// @notice Get the issuance (anon) history for a token
    /// @dev Reverts for non-existant tokens
    /// @param tokenId The tokenId
    /// @return uint256 When the token was issued
    function issuedAt(uint256 tokenId) external view returns (uint256);

    /// @notice Get the transfer (anon) history for a token
    /// @dev An index of -1 refers to the most recent transfer
    /// @dev Reverts for non-existant tokens
    /// @param tokenId The tokenId
    /// @param index The transfer index to return history for
    /// @return uint256 When the token was issued
    function transferredAt(uint256 tokenId, int256 index) external view returns (uint256);

    /// @notice Get the number of times a token has been transferred
    /// @dev Reverts for non-existant tokens
    /// @param tokenId The tokenId
    /// @return uint256
    function numTransfers(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface INFTMetadataV1 {
    /// @notice Provides a contract metadata URI for marketplaces
    /// @return string The contract metadata URI
    function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import 'openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';
import 'openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721BurnableUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import 'openzeppelin-contracts-upgradeable/contracts/utils/CountersUpgradeable.sol';

import 'medallion/brevity/access/AccessControlSubscriberV1.sol';
import 'medallion/brevity/utils/RescueFundsV1.sol';

import './INFTHistoryV1.sol';
import './INFTMetadataV1.sol';

abstract contract NFTV1 is
    Initializable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlSubscriberV1,
    RescueFundsV1,
    UUPSUpgradeable,
    INFTHistoryV1,
    INFTMetadataV1
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice Track tokenIds
    CountersUpgradeable.Counter private _currentTokenId;

    /// @notice The contract metadata URI
    string private _contractURI;

    /// @notice The token metadata URI
    string private _tokenURI;

    /// @notice maintain tokenId => issuance (anon) history
    mapping(uint256 => uint256) private _issuedAt;

    /// @notice maintain tokenId => transfer (anon) history
    mapping(uint256 => uint256[]) private _transferredAt;

    /// @notice Initializes the NFT implementation
    /// @param name_ The ERC721 name
    /// @param symbol_ The ERC721 symbol
    /// @param contractURI_ The contract metadata URI
    /// @param tokenURI_ The token metadata URI
    /// @param accessControlProvider_ The access control provider address
    function __NFTV1_init(
        string calldata name_,
        string calldata symbol_,
        string calldata contractURI_,
        string calldata tokenURI_,
        address accessControlProvider_
    ) public virtual initializer {
        // Initialize inherited contracts
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Burnable_init_unchained();
        __ERC721Enumerable_init_unchained();
        __AccessControlSubscriberV1_init(accessControlProvider_);

        // Set ERC721 metadata URIs
        _contractURI = contractURI_;
        _tokenURI = tokenURI_;

        // Optimise for gas
        _currentTokenId.increment();
    }

    /* -------------------------------- OWNER ------------------------------- */

    /* -------------------------------- ADMIN ------------------------------- */

    /// @notice Amends the contract URI
    /// @dev Only callable by ADMIN_ROLE
    /// @param newContractURI The new contract metadata URI
    function amendContractURI(string calldata newContractURI) public onlyRole(ADMIN_ROLE) {
        _contractURI = newContractURI;
    }

    /// @notice Amends the token URI shared by all tokens
    /// @dev Only callable by ADMIN_ROLE
    /// @param newTokenURI The new token metadata URI
    function amendTokenURI(string calldata newTokenURI) public onlyRole(ADMIN_ROLE) {
        _tokenURI = newTokenURI;
    }

    /// @inheritdoc RescueFundsV1
    /// @dev Only callable by ADMIN_ROLE
    function _authorizeRescue() internal virtual override onlyRole(ADMIN_ROLE) {}

    /// @inheritdoc UUPSUpgradeable
    /// @dev Only callable by ADMIN_ROLE
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(ADMIN_ROLE) {}

    /* ------------------------------ OPERATOR ------------------------------ */

    /* ------------------------------- PUBLIC ------------------------------- */

    /// @inheritdoc INFTMetadataV1
    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    /// @inheritdoc ERC721Upgradeable
    /// @dev replaces the usual dynamic token URI with a static one
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _checkTokenExists(tokenId);

        return _tokenURI;
    }

    /// @inheritdoc INFTHistoryV1
    function numTransfers(uint256 tokenId) public view returns (uint256) {
        return _transferredAt[tokenId].length;
    }

    /// @inheritdoc INFTHistoryV1
    function issuedAt(uint256 tokenId) public view returns (uint256) {
        require(numTransfers(tokenId) > 0, 'NFT: out of bounds');

        return _issuedAt[tokenId];
    }

    /// @inheritdoc INFTHistoryV1
    function transferredAt(uint256 tokenId, int256 index) public view returns (uint256) {
        require(index >= -1, 'NFT: out of bounds');
        require(numTransfers(tokenId) > 0, 'NFT: out of bounds');

        uint256 uIndex;
        if (index == -1) {
            uIndex = _transferredAt[tokenId].length - 1;
        } else {
            uIndex = uint256(index);
        }
        require(uIndex < _transferredAt[tokenId].length, 'NFT: out of bounds');

        return _transferredAt[tokenId][uIndex];
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlSubscriberV1)
        returns (bool)
    {
        return
            interfaceId == type(INFTHistoryV1).interfaceId ||
            interfaceId == type(INFTMetadataV1).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            AccessControlSubscriberV1.supportsInterface(interfaceId);
    }

    /* ------------------------------ INTERNAL ------------------------------ */

    /// @notice Function that should revert when recipient is not authorized to receive the NFT
    /// @dev This should be implemented with a modifer like onlyRole
    function _authorizeIssue(address recipient) internal virtual;

    /// @inheritdoc ERC721Upgradeable
    /// @dev Overrides to maintain (anon) history
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // maintain (anon) history
        _transferredAt[tokenId].push(block.timestamp);
        if (from == address(0)) {
            _issuedAt[tokenId] = block.timestamp;
        }
    }

    /// @notice Check if the token exists
    /// @dev Reverts if the token doesn't exist
    function _checkTokenExists(uint256 tokenId) internal view {
        require(_exists(tokenId), 'NFT: invalid token');
    }

    /// @notice Issues a token
    /// @param recipient The recipient address
    /// @return uint256 The newly issued tokenId
    function _issue(address recipient) internal returns (uint256) {
        _authorizeIssue(recipient);

        uint256 newTokenId = _currentTokenId.current();
        _safeMint(recipient, newTokenId);
        _currentTokenId.increment();

        return newTokenId;
    }

    /// @dev Reserved space to allow future versions to add new variables
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

abstract contract RescueFundsV1 {
    /// @notice Withdraws arbitrary ERC721 tokens to the receipient address
    /// @dev Runs authorization check before proceeding
    /// @param tokenContractAddress The token contract address of the token to withdraw
    /// @param tokenId The tokenId to withdraw
    /// @param recipientAddress The account to transfer to
    function withdrawERC721(
        address tokenContractAddress,
        uint256 tokenId,
        address recipientAddress
    ) public {
        _authorizeRescue();
        require(recipientAddress != address(0), 'Rescue: transfer to zero address');
        IERC721(tokenContractAddress).safeTransferFrom(address(this), recipientAddress, tokenId);
    }

    /// @notice Withdraws arbitrary ERC20 tokens to the receipient address
    /// @dev Runs authorization check before proceeding
    /// @param tokenContractAddress The token contract address of the token to withdraw
    /// @param amount The amount of tokens to withdraw
    /// @param recipientAddress The account to transfer to
    function withdrawERC20(
        address tokenContractAddress,
        uint256 amount,
        address recipientAddress
    ) public {
        _authorizeRescue();
        require(recipientAddress != address(0), 'Rescue: transfer to zero address');
        IERC20(tokenContractAddress).transfer(recipientAddress, amount);
    }

    /// @notice Withdraws native token to receipient address
    /// @dev Runs authorization check before proceeding
    /// @param amount The amount of native token to withdraw
    /// @param recipientAddress The account to transfer to
    function withdrawNativeToken(uint256 amount, address recipientAddress) public {
        _authorizeRescue();
        require(recipientAddress != address(0), 'Rescue: transfer to zero address');
        payable(recipientAddress).transfer(amount);
    }

    /// @notice Function that should revert when msg.sender is not authorized to rescue funds
    /// @dev This should be implemented with a modifer like onlyRole
    function _authorizeRescue() internal virtual;
}