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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
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
pragma solidity >=0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./interfaces/ISteerPeriphery.sol";
import "./interfaces/IStrategyRegistry.sol";
import "./interfaces/IVaultRegistry.sol";
import "./interfaces/IMultiPositionManager.sol";

/// @title Periphery contract to facilitate common actions on the protocol
/// @author Steer Protocol
/// @dev You can use this contract to enumerate strategy and vault details but also create, join, and leave vaults
/// @dev This function should be used when doing protocol integrations
contract SteerPeriphery is ISteerPeriphery, Initializable, OwnableUpgradeable, UUPSUpgradeable   {
    address internal strategyRegistry;
    address internal vaultRegistry;

    function initialize(address _strategyRegistry, address _vaultRegistry)
        external
        initializer
    {
        __UUPSUpgradeable_init();
        __Ownable_init();
        strategyRegistry = _strategyRegistry;
        vaultRegistry = _vaultRegistry;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @dev Get the strategies by creator
    /// @param _address The creator of the strategies
    /// @return The list of strategies created by the creator
    function strategiesByCreator(address _address)
        public
        view
        returns (IStrategyRegistry.RegisteredStrategy[] memory)
    {
        // Find the userse balance
        uint256 strategyBalance = IStrategyRegistry(strategyRegistry).balanceOf(
            _address
        );

        // Create an array to hold the strategy details
        // which is the same length of the balance of the registered strategies
        IStrategyRegistry.RegisteredStrategy[] memory userStrategies = 
            new IStrategyRegistry.RegisteredStrategy[](strategyBalance);

        // Iterate through the user's strategies and fill the array
        for (uint256 i = 0; i != strategyBalance; i++) {
            // Get token id of a strategy based on the owner and the index of the strategy
            uint256 tokenId = IStrategyRegistry(strategyRegistry)
                .tokenOfOwnerByIndex(_address, i);

            // Using the tokenId, get the strategy details from the strategy registry
            IStrategyRegistry.RegisteredStrategy
                memory strategy = IStrategyRegistry(strategyRegistry)
                    .getRegisteredStrategy(tokenId);

            // Add the strategy to the array based on the loop index
            userStrategies[i] = strategy;
        }

        // Return the array of strategies
        return userStrategies;
    }

    /// @dev Get the vaults using a given strategy
    /// @param _strategyId The strategyId (ERC-721 tokenId)
    /// @return The list of vault details using the strategy
    function vaultsByStrategy(uint256 _strategyId)
        public
        view
        returns (IVaultRegistry.VaultData[] memory)
    {
        // Get the amount of vaults using the strategy
        uint256 vaultCount = IVaultRegistry(vaultRegistry).getVaultCountByStrategyId(
            _strategyId
        );

        // Create an array to hold the vault details
        IVaultRegistry.VaultData[]
            memory strategyVaults = new IVaultRegistry.VaultData[](vaultCount);

        // Iterate through the vaults and fill the array
        for (uint256 i = 0; i != vaultCount; i++) {
            // Retrieve the VaultData struct using the
            // strategyId and the index of the vault for the strategy
            IVaultRegistry.VaultData memory strategy = IVaultRegistry(
                vaultRegistry
            ).getVaultByStrategyAndIndex(_strategyId, i);

            // Add the vault to the array based on the loop index
            strategyVaults[i] = strategy;
        }

        // Return the array of vaults
        return strategyVaults;
    }

    /**
     * @dev Deposits tokens in proportion to the vault's current holdings.
     * @dev These tokens sit in the vault and are not used for liquidity on
     * Uniswap until the next rebalance.
     * @param _vaultAddress The address of the vault to deposit to
     * @param amount0Desired Max amount of token0 to deposit
     * @param amount1Desired Max amount of token1 to deposit
     * @param amount0Min Revert if resulting `amount0` is less than this
     * @param amount1Min Revert if resulting `amount1` is less than this
     * @param to Recipient of shares
     */
    function deposit(
        address _vaultAddress,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external {
        require(
            IVaultRegistry(vaultRegistry).getStrategyCreatorForVault(
                _vaultAddress
            ) != address(0),
            "Vault not present"
        );
        IMultiPositionManager vaultInstance = IMultiPositionManager(_vaultAddress);
        IERC20 token0 = IERC20(vaultInstance.token0());
        IERC20 token1 = IERC20(vaultInstance.token1());
        if (amount0Desired != 0)
            token0.transferFrom(msg.sender, address(this), amount0Desired);
        if (amount1Desired != 0)
            token1.transferFrom(msg.sender, address(this), amount1Desired);
        token0.approve(_vaultAddress, amount0Desired);
        token1.approve(_vaultAddress, amount1Desired);

        (, uint256 amount0, uint256 amount1) = vaultInstance.deposit(
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min,
            to
        );
        uint256 amount0Unused = amount0Desired - amount0;
        uint256 amount1Unused = amount1Desired - amount1;
        if (amount0Unused != 0) token0.transfer(msg.sender, amount0Unused);
        if (amount1Unused != 0) token1.transfer(msg.sender, amount1Unused);
    }

    function vaultDetailsByAddress(address _vault)
        external 
        view
        returns (IMultiPositionManager.VaultDetails memory details)
    {
        IMultiPositionManager vaultInstance = IMultiPositionManager(_vault);

        //Get total amounts, excluding fees
        (uint256 bal0, uint256 bal1) = vaultInstance.getTotalAmounts();

        return IMultiPositionManager.VaultDetails(
            IVaultRegistry(vaultRegistry).beaconTypes(_vault),
            vaultInstance.token0(),
            vaultInstance.token1(),
            IERC20Metadata(_vault).name(),
            IERC20Metadata(_vault).symbol(),
            IERC20Metadata(_vault).decimals(),
            IERC20Metadata(vaultInstance.token0()).name(),
            IERC20Metadata(vaultInstance.token1()).name(),
            IERC20Metadata(vaultInstance.token0()).symbol(),
            IERC20Metadata(vaultInstance.token1()).symbol(),
            IERC20Metadata(vaultInstance.token0()).decimals(),
            IERC20Metadata(vaultInstance.token1()).decimals(),
            IUniswapV3Pool(vaultInstance.pool()).fee(),
            vaultInstance.totalSupply(),
            bal0,
            bal1
        );
    }

    function vaultBalancesByAddressWithFees(address _vault)
        external
        returns (IMultiPositionManager.VaultBalance memory balances)
    {
        IMultiPositionManager vaultInstance = IMultiPositionManager(_vault);
        vaultInstance.poke();
        (uint256 bal0, uint256 bal1) = vaultInstance.getTotalAmounts();

        return IMultiPositionManager.VaultBalance(
            bal0,
            bal1
        );
    }

    function createVaultAndStrategy(
        address strategyCreator,
        string calldata name,
        string calldata execBundle,
        uint128 maxGasCost,
        uint128 maxGasPerAction,
        bytes calldata _params,
        string calldata _beaconName,
        string memory _payloadIpfs
    )external returns(uint256 tokenId,address newVault){
        tokenId = IStrategyRegistry(strategyRegistry).createStrategy(strategyCreator,name,execBundle,maxGasCost,maxGasPerAction);
        newVault = IVaultRegistry(vaultRegistry).createVault(_params,tokenId,_beaconName,_payloadIpfs);
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
pragma solidity ^0.8.10;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IMultiPositionManager is IERC20 {

    struct VaultDetails {
        string vaultType;
        address token0;
        address token1;
        string name;
        string symbol;
        uint256 decimals;
        string token0Name;
        string token1Name;
        string token0Symbol;
        string token1Symbol;
        uint256 token0Decimals;
        uint256 token1Decimals;
        uint256 feeTier;
        uint256 totalLPTokensIssued;
        uint256 token0Balance;
        uint256 token1Balance;
    }

    struct VaultBalance {
        uint256 amountToken0;
        uint256 amountToken1;
    }

    struct LiquidityPositions {
        int24[] lowerTick;
        int24[] upperTick;
        uint16[] relativeWeight;
    }

    /**
     * @dev initializes vault
     * param _orchestrator is address of orchestrator, which has permission to call update.
     * param _params is all other parameters this vault will use.
     * param _tokenName is the name of the LPT of this vault.
     * param _symbol is the symbol of the LPT of this vault.
     * param token0 is address of token0
     * param token1 is address of token1
     * param _FEE is pool fee, how much is charged for a swap
     */
    function initialize(
        address _orchestrator,
        address _steer,
        bytes memory _params
    ) external;

    ///
    /// @dev Deposits tokens in proportion to the vault's current holdings.
    /// @dev These tokens sit in the vault and are not used for liquidity on
    /// Uniswap until the next rebalance.
    /// @param amount0Desired Max amount of token0 to deposit
    /// @param amount1Desired Max amount of token1 to deposit
    /// @param amount0Min Revert if resulting `amount0` is less than this
    /// @param amount1Min Revert if resulting `amount1` is less than this
    /// @param to Recipient of shares
    /// @return shares Number of shares minted
    /// @return amount0 Amount of token0 deposited
    /// @return amount1 Amount of token1 deposited
    ///
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @dev burns each vault position which contains liquidity, updating fees owed to that position.
     * @dev call this before calling getTotalAmounts if total amounts must include fees. There's a function in the periphery to do so through a static call.
     */
    function poke() external;

    /**
     * @dev Withdraws tokens in proportion to the vault's holdings.
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @param to Recipient of tokens
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @dev Internal function to pull funds from pool, update positions if necessary, then deposit funds into pool.
     * @dev reverts if it does not have any liquidity.

     * @dev newPositions requirements:
     * Each lowerTick must be lower than its corresponding upperTick
     * Each lowerTick must be greater than or equal to the tick min (-887272)
     * Each upperTick must be less than or equal to the tick max (887272)
     * All lowerTicks and upperTicks must be divisible by the pool tickSpacing--
        A 0.05% fee pool has tick spacing of 10, 0.3% has tick spacing 60. and 1% has tick spacing 200.)
     */
    function tend(
        LiquidityPositions memory newPositions,
        int256 swapAmount,
        uint160 sqrtPriceLimitX96
    ) external;

    /**
     * @dev Calculates the vault's total holdings of token0 and token1 - in
     *      other words, how much of each token the vault would hold if it withdrew
     *      all its liquidity from Uniswap.
     * @dev this function DOES NOT include fees. To include fees, first poke() and then call getTotalAmounts. There's a function inside the periphery to do so.
     */
    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    //Tokens
    function vaultRegistry() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function accruedSteerFees0() external view returns (uint256);

    function accruedSteerFees1() external view returns (uint256);

    function accruedStrategistFees0() external view returns (uint256);

    function accruedStrategistFees1() external view returns (uint256);

    function maxTotalSupply() external view returns (uint256);
    
    function pool() external view returns (IUniswapV3Pool);

    /**
     * @dev Used to collect accumulated protocol fees.
     */
    function steerCollectFees(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external;

    /**
     * @dev Used to collect accumulated protocol fees.
     */
    function strategistCollectFees(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external;

    /**
     * @dev Removes tokens accidentally sent to this vault.
     */
    function sweep(
        address token,
        uint256 amount,
        address to
    ) external;

    /**
     * @dev Used to change deposit cap for a guarded launch or to ensure
     * vault doesn't grow too large relative to the pool. Cap is on total
     * supply rather than amounts of token0 and token1 as those amounts
     * fluctuate naturally over time.
     */
    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    /**
     * @dev Used to change the MaxTickChange and twapinterval used when checking for flash
     * loans, by default set to 500 ticks and 45 seconds, respectively
     */
    function setTWAPnums(int24 newMax, uint32 newInterval) external;

    /**
     * @dev Removes liquidity in case of emergency.
     */
    function emergencyBurn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external returns(uint256 amount0, uint256 amount1);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;
import "./IVaultRegistry.sol";
import "./IStrategyRegistry.sol";
import "./IMultiPositionManager.sol";
interface ISteerPeriphery {

    function vaultsByStrategy(uint256 _strategyId) external view returns (IVaultRegistry.VaultData[] memory);

    function strategiesByCreator(address _address) external view returns (IStrategyRegistry.RegisteredStrategy[] memory);

    function deposit(
        address _vaultAddress,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external;

    function vaultDetailsByAddress(address _vault)
        external view
        returns (IMultiPositionManager.VaultDetails memory details);

    function vaultBalancesByAddressWithFees(address _vault)
        external
        returns (IMultiPositionManager.VaultBalance memory balances);
    
    function createVaultAndStrategy(
        address strategyCreator,
        string memory name,
        string memory execBundle,
        uint128 maxGasCost,
        uint128 maxGasPerAction,
        bytes memory _params,
        string memory _beaconName,
        string memory _payloadIpfs
    )external returns(uint256 tokenId,address newVault);
    
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IStrategyRegistry is
    IERC721Upgradeable,
    IERC721EnumerableUpgradeable
{
    function getStrategyAddress(uint256 tokenId)
        external
        view
        returns (address);

    function getStrategyOwner(uint256 tokenId) external view returns (address);

    /**
     * @dev Create NFT for execution bundle.
     * @param name The name of the strategy.
     * @param execBundle The IPFS reference of the execution bundle.
     * @return newStrategyTokenId The token ID of the NFT.
     */
    function createStrategy(
        address strategyCreator,
        string memory name,
        string memory execBundle,
        uint128 maxGasCost,
        uint128 maxGasPerAction)
        external
        returns (uint256 newStrategyTokenId);

    //
    // Todo: add to utility library
    //
    function addressToString(address _address)
        external
        pure
        returns (string memory);

    struct RegisteredStrategy {
        uint256 id;
        string name;
        address owner;
        string execBundle; //IPFS reference of execution bundle
        //GasVault stuff
        uint128 maxGasCost;
        uint128 maxGasPerAction;
    }
    
    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getRegisteredStrategy(uint256 tokenId)
        external
        view
        returns (IStrategyRegistry.RegisteredStrategy memory);

    /**
     * @dev parameters users set for what constitutes an acceptable use of their funds. Can only be set by NFT owner.
     * @param _tokenId is the token ID of the execution bundle.
     * @param _maxGasCost is highest acceptable price to pay per gas, in terms of gwei.
     * @param _maxGasPerMethod is max amount of gas to be sent in one method.
     * @param _maxMethods is the maximum number of methods that can be executed in one action.
     */
    function setGasParameters(
        uint256 _tokenId,
        uint128 _maxGasCost,
        uint128 _maxGasPerMethod,
        uint16 _maxMethods
    ) external;

    //function getExecutionBundle(uint256 tokenId) external view returns (string memory);

    function baseURI() external view returns (string memory);

    function burn(uint256 tokenId) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;
pragma abicoder v2;  //Used this because function getAssetSymbols uses string[2]

import "./IStrategyRegistry.sol";
import "../Orchestrator.sol";

interface IVaultRegistry {
    //Total vault count.
    function totalVaultCount() external view returns(uint256);

    function orchestrator() external view returns(Orchestrator);

    function beaconAddresses(string calldata) external view returns(address);

    function beaconTypes(address) external view returns(string memory);

    // Interface for the strategy registry
    function strategyRegistry() external view returns(IStrategyRegistry);

    /**
     * PendingApproval: strategy is submitted but has not yet been approved by the owner
     * PendingThreshold: strategy is approved but has not yet reached the threshold of TVL required
     * Paused: strategy was active but something went wrong, so now it's paused
     * Active: strategy is active and can be used
     * Retired: strategy is retired and can no longer be used
     */
    enum VaultState {
        PendingApproval,
        PendingThreshold,
        Paused,
        Active,
        Retired
    }

    /**
     * @dev all necessary data for vault. Name and symbol are stored in vault's ERC20. Owner is stored with tokenId in StrategyRegistry.
     * tokenId: NFT identifier number
     * vaultAddress: address of vault this describes
     * state: state of the vault.
     */
    struct VaultData {
        VaultState state;
        uint256 tokenId; //NFT ownership of this vault and all others that use vault's exec bundle
        uint256 vaultID; //unique identifier for this vault and strategy token id
        address vaultAddress;
        string payloadIpfs;
    }
        
    /// @dev Vault creation event
    /// @param deployer The address of the deployer
    /// @param vault The address of the vault
    /// @param tokenId ERC721 token id for the vault
    event VaultCreated(
        address deployer,
        address vault,
        string beaconName,
        uint256 indexed tokenId
    );

    /// @dev Vault state change event
    /// @param vault The address of the vault
    /// @param newState The new state of the vault
    event VaultStateChanged(address indexed vault, VaultState newState);

    /// @dev Beacon registeration event
    /// @param _name The name of the beacon getting registered
    /// @param _address The implementation address that this beacon will point to
    /// @param _ipfsHash IPFS hash for the config of this beacon
    event BeaconRegistered(string _name, address _address, string _ipfsHash);

    /// @dev Beacon config updation event
    /// @param _name The name of the beacon getting registered
    /// @param _ipfsHash updated IPFS hash for the config of this beacon
    event BeaconConfigUpdated(string _name, string _ipfsHash);

    
    /// @dev Beacon deregisteration event
    /// @param _name The name of the beacon getting registered
    event BeaconDeregistered(string _name);


    /// @dev intializes the vault registry
    /// @param _orchestrator The address of the orchestrator
    /// @param _strategyRegistry The address of the strategy registry
    function initialize(
        address payable _orchestrator,
        address _strategyRegistry,
        address _internalGovernance
    ) external; 
    
    /// @dev Registers a beacon associated with a new vault type
    /// @param _name The name of the vault type this beacon will be using
    /// @param _address The address of the upgrade beacon
    /// @param _ipfsConfigForBeacon IPFS hash for the config of this beacon
    function registerBeacon(string calldata _name, address _address, string calldata _ipfsConfigForBeacon)
        external;
    
    /// @dev Deploy new beacon for a new vault type AND register it
    /// @param _address The address of the implementation for the beacon
    /// @param _name The name of the beacon (identifier)
    /// @param _ipfsConfigForBeacon IPFS hash for the config of this beacon
    function deployAndRegisterBeacon(address _address, string calldata _name, string calldata _ipfsConfigForBeacon)
        external returns(address);
    
    /// @dev Removes a beacon associated with a vault type
    /// @param _name The name of the beacon (identifier)
    /// @dev This will stop the creation of more vaults of the type provided
    function deregisterBeacon(string calldata _name) external;

    /// @dev Creates a new vault with the given strategy
    /// @dev Registers an execution bundle, mints an NFT and mappings it to execution bundle and it's details.
    /// @param _params is extra parameters in vault.
    /// @param _tokenId is the NFT of the execution bundle this vault will be using.
    /// @param _beaconName beacon identifier of vault type to be created
    /// @dev owner is set as msg.sender.
    function createVault(
        bytes calldata _params,
        uint256 _tokenId,
        string calldata _beaconName,
        string calldata strategyData
    ) external returns(address);

    /// @dev Updates the vault state and emits a VaultStateChanged event
    /// @param _vault The address of the vault
    /// @param _newState The new state of the vault
    /// @dev This function is only available to the registry owner
    function updateVaultState(
        address _vault,
        VaultState _newState
    ) external;

    /// @dev Retrieves the creator of a given vault
    /// @param _vault The address of the vault
    /// @return The address of the creator
    function getStrategyCreatorForVault(address _vault)
        external
        view
        returns (address);

    /// @dev Pauses the minting of the ERC721 tokens for the vault
    /// @dev This function is only available to the pauser role
    function pause() external;

    function unpause() external;

    /// @dev Retrieves the details of a given vault by address
    /// @param _address The address of the vault
    /// @return The details of the vault
    function getVaultDetails(address _address)
        external
        view
        returns (VaultData memory);

    /// @dev Retrieves the vault count by vault token id
    /// @param _tokenId The token id of the vault
    /// @return The count of the vault
    function getVaultCountByStrategyId(uint256 _tokenId)
        external
        view
        returns (uint256);

    /// @dev Retrieves the vault by vault token id and vault index
    /// @param _tokenId The token id of the vault
    /// @param _vaultId The index of the vault
    /// @return Vault details
    function getVaultByStrategyAndIndex(uint256 _tokenId, uint256 _vaultId)
        external
        view
        returns (VaultData memory);
}