// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ArraysUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal onlyInitializing {
    }

    function __ERC20Snapshot_init_unchained() internal onlyInitializing {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlotUpgradeable.sol";
import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    using StorageSlotUpgradeable for bytes32;

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
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import {IFactory} from "./IFactory.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// Thrown when a new factory deployment creates a child that was already created
/// by a previous deployment. This should never happen without some kind of
/// precompute such as CREATE2 and is generally unsupported at this time.
error DuplicateChild(address child);

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    /// @dev state to track each deployed contract address. A `Factory` will
    /// never lie about deploying a child, unless `isChild` is overridden to do
    /// so.
    mapping(address => bool) private contracts;

    constructor() {
        // Technically `ReentrancyGuard` is initializable but allowing it to be
        // initialized is a foot-gun as the status will be set to _NOT_ENTERED.
        // This would allow re-entrant behaviour upon initialization of the
        // `Factory` and is unnecessary as the reentrancy guard always restores
        // _NOT_ENTERED after every call anyway.
        _disableInitializers();
    }

    /// Implements `IFactory`.
    ///
    /// `_createChild` hook must be overridden to actually create child
    /// contract.
    ///
    /// Implementers may want to overload this function with a typed equivalent
    /// to expose domain specific structs etc. to the compiled ABI consumed by
    /// tooling and other scripts. To minimise gas costs for deployment it is
    /// expected that the tooling will consume the typed ABI, then encode the
    /// arguments and pass them to this function directly.
    ///
    /// @param data_ ABI encoded data to pass to child contract constructor.
    function _createChild(
        bytes memory data_
    ) internal virtual returns (address);

    /// Implements `IFactory`.
    ///
    /// Calls the `_createChild` hook that inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewChild` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(
        bytes memory data_
    ) public virtual override nonReentrant returns (address) {
        // Create child contract using hook.
        address child_ = _createChild(data_);

        // Ensure the child at this address has not previously been deployed.
        if (contracts[child_]) {
            revert DuplicateChild(child_);
        }

        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewChild` event with child contract address.
        emit IFactory.NewChild(msg.sender, child_);
        return child_;
    }

    /// Implements `IFactory`.
    ///
    /// Checks if address is registered as a child contract of this factory.
    ///
    /// @param maybeChild_ Address of child contract to look up.
    /// @return Returns `true` if address is a contract created by this
    /// contract factory, otherwise `false`.
    function isChild(
        address maybeChild_
    ) external view virtual override returns (bool) {
        return contracts[maybeChild_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewChild` event
    /// containing the new child contract address MUST be emitted.
    /// @param sender `msg.sender` that deployed the contract (factory).
    /// @param child address of the newly deployed child.
    event NewChild(address sender, address child);

    /// Factories that clone a template contract MUST emit an event any time
    /// they set the implementation being cloned. Factories that deploy new
    /// contracts without cloning do NOT need to emit this.
    /// @param sender `msg.sender` that deployed the implementation (factory).
    /// @param implementation address of the implementation contract that will
    /// be used for future clones if relevant.
    event Implementation(address sender, address implementation);

    /// Creates a new child contract.
    ///
    /// @param data_ Domain specific data for the child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_) external returns (address);

    /// Checks if address is registered as a child contract of this factory.
    ///
    /// Addresses that were not deployed by `createChild` MUST NOT return
    /// `true` from `isChild`. This is CRITICAL to the security guarantees for
    /// any contract implementing `IFactory`.
    ///
    /// @param maybeChild_ Address to check registration for.
    /// @return `true` if address was deployed by this contract factory,
    /// otherwise `false`.
    function isChild(address maybeChild_) external view returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../math/SaturatingMath.sol";

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 1e18;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
///
/// Overflows SATURATE rather than error, e.g. scaling max uint256 up will result
/// in max uint256. The max uint256 as decimal is roughly 1e77 so scaling values
/// comparable to 1e18 is unlikely to ever saturate in practise. For a typical
/// use case involving tokens, the entire supply of a token rescaled up a full
/// 18 decimals would still put it "only" in the region of ~1e40 which has a full
/// 30 orders of magnitude buffer before running into saturation issues. However,
/// there's no theoretical reason that a token or any other use case couldn't use
/// large numbers or extremely precise decimals that would push this library to
/// saturation point, so it MUST be treated with caution around the edge cases.
///
/// One case where values could come near the saturation/overflow point is phantom
/// overflow. This is where an overflow happens during the internal logic of some
/// operation like "fixed point multiplication" even though the final result fits
/// within uint256. The fixed point multiplication and division functions are
/// thin wrappers around Open Zeppelin's `mulDiv` function, that handles phantom
/// overflow, reducing the problems of rescaling overflow/saturation to the input
/// and output range rather than to the internal implementation details. For this
/// library that gives an additional full 18 orders of magnitude for safe fixed
/// point multiplication operations.
///
/// Scaling down ANY fixed point decimal also reduces the precision which can
/// lead to  dust or in the worst case trapped funds if subsequent subtraction
/// overflows a rounded-down number. Consider using saturating subtraction for
/// safety against previously downscaled values, and whether trapped dust is a
/// significant issue. If you need to retain full/arbitrary precision in the case
/// of downscaling DO NOT use this library.
///
/// All rescaling and/or division operations in this library require the rounding
/// flag from Open Zeppelin math. This allows and forces the caller to specify
/// where dust sits due to rounding. For example the caller could round up when
/// taking tokens from `msg.sender` and round down when returning them, ensuring
/// that any dust in the round trip accumulates in the contract rather than
/// opening an exploit or reverting and trapping all funds. This is exactly how
/// the ERC4626 vault spec handles dust and is a good reference point in general.
/// Typically the contract holding tokens and non-interactive participants should
/// be favoured by rounding calculations rather than active participants. This is
/// because we assume that an active participant, e.g. `msg.sender`, knowns
/// something we don't and is carefully crafting an attack, so we are most
/// conservative and suspicious of their inputs and actions.
library LibFixedPointMath {
    using Math for uint256;
    using SafeCast for int256;
    using SaturatingMath for uint256;

    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(
        uint256 a_,
        uint256 aDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - aDecimals_;
            }
            return a_.saturatingMul(10 ** decimals_);
        } else {
            unchecked {
                decimals_ = aDecimals_ - FP_DECIMALS;
            }
            return scaleDown(a_, decimals_, rounding_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(
        uint256 a_,
        uint256 targetDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - targetDecimals_;
            }
            return scaleDown(a_, decimals_, rounding_);
        } else {
            unchecked {
                decimals_ = targetDecimals_ - FP_DECIMALS;
            }
            return a_.saturatingMul(10 ** decimals_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` that represents a ratio of
    /// a_:b_ according to the decimals of a and b that MAY NOT be `DECIMALS`.
    /// i.e. a subsequent call to `a_.fixedPointMul(ratio_)` would yield the value
    /// that it would have as though `a_` and `b_` were both `DECIMALS` and we
    /// hadn't rescaled the ratio.
    /// @param ratio_ The ratio to be scaled.
    /// @param aDecimals_ The decimals of the ratio numerator.
    /// @param bDecimals_ The decimals of the ratio denominator.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    function scaleRatio(
        uint256 ratio_,
        uint256 aDecimals_,
        uint256 bDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return
            scaleBy(
                ratio_,
                (int256(bDecimals_) - int256(aDecimals_)).toInt8(),
                rounding_
            );
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by. This is a SIGNED int8
    /// which means it can be negative, and also means that sign extension MUST
    /// be considered if changing it to another type.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(
        uint256 a_,
        int8 scaleBy_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_.saturatingMul(10 ** uint8(scaleBy_));
        } else {
            uint256 scaleDownBy_;
            unchecked {
                scaleDownBy_ = uint8(-1 * scaleBy_);
            }
            return scaleDown(a_, scaleDownBy_, rounding_);
        }
    }

    /// Scales `a_` down by a specified number of decimals, rounding in the
    /// specified direction. Used internally by several other functions in this
    /// lib.
    /// @param a_ The number to scale down.
    /// @param scaleDownBy_ Number of orders of magnitude to scale `a_` down by.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` scaled down by `scaleDownBy_` and rounded.
    function scaleDown(
        uint256 a_,
        uint256 scaleDownBy_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 b_ = 10 ** scaleDownBy_;
        uint256 scaled_ = a_ / b_;
        if (rounding_ == Math.Rounding.Up && a_ != scaled_ * b_) {
            scaled_ += 1;
        }
        return scaled_;
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(
        uint256 a_,
        uint256 b_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return a_.mulDiv(b_, FP_ONE, rounding_);
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(
        uint256 a_,
        uint256 b_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return a_.mulDiv(FP_ONE, b_, rounding_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title SaturatingMath
/// @notice Sometimes we neither want math operations to error nor wrap around
/// on an overflow or underflow. In the case of transferring assets an error
/// may cause assets to be locked in an irretrievable state within the erroring
/// contract, e.g. due to a tiny rounding/calculation error. We also can't have
/// assets underflowing and attempting to approve/transfer "infinity" when we
/// wanted "almost or exactly zero" but some calculation bug underflowed zero.
/// Ideally there are no calculation mistakes, but in guarding against bugs it
/// may be safer pragmatically to saturate arithmatic at the numeric bounds.
/// Note that saturating div is not supported because 0/0 is undefined.
library SaturatingMath {
    /// Saturating addition.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ + b_ and max uint256.
    function saturatingAdd(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return Maximum of a_ - b_ and 0.
    function saturatingSub(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being
            // zero, but the benefit is lost if 'b' is also tested.
            // https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a_ == 0) return 0;
            uint256 c_ = a_ * b_;
            return c_ / a_ != b_ ? type(uint256).max : c_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITierV2
/// @notice `ITierV2` is a simple interface that contracts can implement to
/// provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITierV2`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the time each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the time data is erased for that tier and will be
///     set if/when the tier is regained to the new time.
///   - If a tier is held but the historical time information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
///   - Context can be a list of numbers that MAY pairwise define tiers such as
///     minimum thresholds, or MAY simply provide global context such as a
///     relevant NFT ID for example.
/// - MUST implement `reportTimeForTier`
///   - Functions exactly as `report` but only returns a single time for a
///     single tier
///   - MUST return the same time value `report` would for any given tier and
///     context combination.
///
/// So the four possible states and report values are:
/// - Tier is held and time is known: Timestamp is in the report
/// - Tier is held but time is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
///
/// The reason `context` is specified as a list of values rather than arbitrary
/// bytes is to allow clear and efficient compatibility with interpreter stacks.
/// Some N values can be taken from an interpreter stack and used directly as a
/// context, which would be difficult or impossible to ensure is safe for
/// arbitrary bytes.
interface ITierV2 {
    /// Same as report but only returns the time for a single tier.
    /// Often the implementing contract can calculate a single tier more
    /// efficiently than all 8 tiers. If the consumer only needs one or a few
    /// tiers it MAY be much cheaper to request only those tiers individually.
    /// This DOES NOT apply to all contracts, an obvious example is token
    /// balance based tiers which always return `ALWAYS` or `NEVER` for all
    /// tiers so no efficiency is gained.
    /// The return value is a `uint256` for gas efficiency but the values will
    /// be bounded by `type(uint32).max` as no single tier can report a value
    /// higher than this.
    function reportTimeForTier(
        address account,
        uint256 tier,
        uint256[] calldata context
    ) external view returns (uint256 time);

    /// Returns an 8 tier encoded report of 32 bit timestamps for the given
    /// account.
    ///
    /// Same as `ITier` (legacy interface) but with a list of values for
    /// `context` which allows a single underlying state to present many
    /// different reports dynamically.
    ///
    /// For example:
    /// - Staking ledgers can calculate different tier thresholds
    /// - NFTs can give different tiers based on different IDs
    /// - Snapshot ERC20s can give different reports based on snapshot ID
    ///
    /// `context` supercedes `setTier` function and `TierChange` event from
    /// `ITier` at the interface level.
    function report(
        address account,
        uint256[] calldata context
    ) external view returns (uint256 report);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ReceiptVaultConfig, VaultConfig, ReceiptVault, ShareAction, InvalidId} from "../receipt/ReceiptVault.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@rainprotocol/rain-protocol/contracts/tier/ITierV2.sol";
import "../receipt/IReceiptV1.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/// Thrown when the asset is NOT address zero.
error NonZeroAsset();

/// Thrown when the admin is address zero.
error ZeroAdmin();

/// Thrown when a certification reference a block number in the future that
/// cannot possibly have been seen yet.
/// @param account The certifier that attempted the certify.
/// @param referenceBlockNumber The future block number.
error FutureReferenceBlock(address account, uint256 referenceBlockNumber);

/// Thrown when a 0 certification time is attempted.
/// @param account The certifier that attempted the certify.
error ZeroCertifyUntil(address account);

/// Thrown when the `from` of a token transfer does not have the minimum tier.
/// @param from The token was transferred from this account.
/// @param reportTime The from account had this time in the tier report.
error UnauthorizedSenderTier(address from, uint256 reportTime);

/// Thrown when the `to` of a token transfer does not have the minimum tier.
/// @param to The token was transferred to this account.
/// @param reportTime The to account had this time in the tier report.
error UnauthorizedRecipientTier(address to, uint256 reportTime);

/// Thrown when a transfer is attempted by an unpriviledged account during system
/// freeze due to certification lapse.
/// @param from The account the transfer is from.
/// @param to The account the transfer is to.
/// @param certifiedUntil The (lapsed) certification time justifying the system
/// freeze.
/// @param timestamp Block timestamp of the transaction that is outside
/// certification.
error CertificationExpired(
    address from,
    address to,
    uint256 certifiedUntil,
    uint256 timestamp
);

/// All data required to configure an offchain asset vault except the receipt.
/// Typically the factory should build a receipt contract and transfer ownership
/// to the vault atomically during initialization so there is no opportunity for
/// an attacker to corrupt the initialzation process.
/// @param admin as per `OffchainAssetReceiptVaultConfig`.
/// @param vaultConfig MUST be used by the factory to build a
/// `ReceiptVaultConfig` once the receipt address is known and ownership has been
/// transferred to the vault contract (before initialization).
struct OffchainAssetVaultConfig {
    address admin;
    VaultConfig vaultConfig;
}

/// All data required to construct `OffchainAssetReceiptVault`.
/// @param admin The initial admin has ALL ROLES. It is up to the admin to
/// appropriately delegate and renounce roles or to be a smart contract with
/// formal governance processes. In general a single EOA holding all admin roles
/// is completely insecure and counterproductive as it allows a single address
/// to both mint and audit assets (and many other things).
/// @param receiptVaultConfig Forwarded to ReceiptVault.
struct OffchainAssetReceiptVaultConfig {
    address admin;
    ReceiptVaultConfig receiptVaultConfig;
}

/// @title OffchainAssetReceiptVault
/// @notice Enables curators of offchain assets to create a token that they can
/// arbitrage offchain assets against onchain assets. This allows them to
/// maintain a peg between offchain and onchain markets.
///
/// At a high level this works because the custodian can always profitably trade
/// the peg against offchain markets in both directions.
///
/// Price is higher onchain: Custodian can buy/produce assets offchain and mint
/// tokens then sell the tokens for more than the assets would sell for offchain
/// thus making a profit. The sale of the tokens brings the onchain price down.
/// Price is higher offchain: Custodian can sell assets offchain and
/// buyback+burn tokens onchain for less than the offchain sale, thus making a
/// profit. The token purchase brings the onchain price up.
///
/// In contrast to pure algorithmic tokens and sentiment based stablecoins, a
/// competent custodian can profit "infinitely" to maintain the peg no matter
/// how badly the peg breaks. As long as every token is fully collateralised by
/// liquid offchain assets, tokens can be profitably bought and burned by the
/// custodian all the way to 0 token supply.
///
/// This model is contingent on existing onchain and offchain liquidity
/// and the custodian being competent. These requirements are non-trivial. There
/// are far more incompetent and malicious custodians than competent ones. Only
/// so many bars of gold can fit in a vault, and only so many trees that can
/// live in a forest.
///
/// This contract does not attempt to solve for liquidity and trustworthyness,
/// it only seeks to provide baseline functionality that a competent custodian
/// will need to tackle the problem. The implementation provides:
///
/// - `ReceiptVault` base that allows transparent onchain/offchain audit history
/// - Certifier role that allows for audits of offchain assets that can fail
/// - KYC/membership lists that can restrict who can hold/transfer assets as
///   any Rain `ITierV2` interface
/// - Ability to comply with sanctions/regulators by confiscating assets
/// - `ERC20` shares in the vault that can be traded minted/burned to track a peg
/// - `ERC4626` compliant vault interface (inherited from `ReceiptVault`)
/// - Fine grained standard Open Zeppelin access control for all system roles
/// - Snapshots from `ReceiptVault` exposed under a role to ease potential
///   future migrations or disaster recovery plans.
contract OffchainAssetReceiptVault is ReceiptVault, AccessControl {
    using Math for uint256;

    /// Snapshot event similar to Open Zeppelin `Snapshot` event but with
    /// additional associated data as provided by the snapshotter.
    /// @param sender The `msg.sender` that triggered the snapshot.
    /// @param id The ID of the snapshot that was triggered.
    /// @param data Associated data for the snapshot that was triggered.
    event SnapshotWithData(address sender, uint256 id, bytes data);

    /// Contract has initialized.
    /// @param sender The `msg.sender` constructing the contract.
    /// @param config All initialization config.
    event OffchainAssetReceiptVaultInitialized(
        address sender,
        OffchainAssetReceiptVaultConfig config
    );

    /// A new certification time has been set.
    /// @param sender The certifier setting the new time.
    /// @param certifyUntil The time the system is newly certified until.
    /// Normally this will be a future time but certifiers MAY set it to a time
    /// in the past which will immediately freeze all transfers.
    /// @param referenceBlockNumber The block number that the auditor referenced
    /// to justify the certification.
    /// @param forceUntil Whether the certifier forced the certification time.
    /// @param data The certifier MAY provide additional supporting data such
    /// as an auditor's report/comments etc.
    event Certify(
        address sender,
        uint256 certifyUntil,
        uint256 referenceBlockNumber,
        bool forceUntil,
        bytes data
    );

    /// Shares have been confiscated from a user who is not currently meeting
    /// the ERC20 tier contract minimum requirements.
    /// @param sender The confiscator who is confiscating the shares.
    /// @param confiscatee The user who had their shares confiscated.
    /// @param confiscated The amount of shares that were confiscated.
    /// @param justification The contextual data justifying the confiscation.
    event ConfiscateShares(
        address sender,
        address confiscatee,
        uint256 confiscated,
        bytes justification
    );

    /// A receipt has been confiscated from a user who is not currently meeting
    /// the ERC1155 tier contract minimum requirements.
    /// @param sender The confiscator who is confiscating the receipt.
    /// @param confiscatee The user who had their receipt confiscated.
    /// @param id The receipt ID that was confiscated.
    /// @param confiscated The amount of the receipt that was confiscated.
    /// @param justification The contextual data justifying the confiscation.
    event ConfiscateReceipt(
        address sender,
        address confiscatee,
        uint256 id,
        uint256 confiscated,
        bytes justification
    );

    /// A new ERC20 tier contract has been set.
    /// @param sender `msg.sender` who set the new tier contract.
    /// @param tier New tier contract used for all ERC20 transfers and
    /// confiscations.
    /// @param minimumTier Minimum tier that a user must hold to be eligible
    /// to send/receive/hold shares and be immune to share confiscations.
    /// @param context OPTIONAL additional context to pass to ITierV2 calls.
    /// @param data Associated data for the change in tier config.
    event SetERC20Tier(
        address sender,
        address tier,
        uint256 minimumTier,
        uint256[] context,
        bytes data
    );

    /// A new ERC1155 tier contract has been set.
    /// @param sender `msg.sender` who set the new tier contract.
    /// @param tier New tier contract used for all ERC1155 transfers and
    /// confiscations.
    /// @param minimumTier Minimum tier that a user must hold to be eligible
    /// to send/receive/hold receipts and be immune to receipt confiscations.
    /// @param context OPTIONAL additional context to pass to ITierV2 calls.
    /// @param data Associated data for the change in tier config.
    event SetERC1155Tier(
        address sender,
        address tier,
        uint256 minimumTier,
        uint256[] context,
        bytes data
    );

    /// Rolename for certifiers.
    /// Certifier role is required to extend the `certifiedUntil` time.
    bytes32 public constant CERTIFIER = keccak256("CERTIFIER");
    /// Rolename for certifier admins.
    bytes32 public constant CERTIFIER_ADMIN = keccak256("CERTIFIER_ADMIN");

    /// Rolename for confiscator.
    /// Confiscator role is required to confiscate shares and/or receipts.
    bytes32 public constant CONFISCATOR = keccak256("CONFISCATOR");
    /// Rolename for confiscator admins.
    bytes32 public constant CONFISCATOR_ADMIN = keccak256("CONFISCATOR_ADMIN");

    /// Rolename for depositors.
    /// Depositor role is required to mint new shares and receipts.
    bytes32 public constant DEPOSITOR = keccak256("DEPOSITOR");
    /// Rolename for depositor admins.
    bytes32 public constant DEPOSITOR_ADMIN = keccak256("DEPOSITOR_ADMIN");

    /// Rolename for ERC1155 tierer.
    /// ERC1155 tierer role is required to modify the tier contract for receipts.
    bytes32 public constant ERC1155TIERER = keccak256("ERC1155TIERER");
    /// Rolename for ERC1155 tierer admins.
    bytes32 public constant ERC1155TIERER_ADMIN =
        keccak256("ERC1155TIERER_ADMIN");

    /// Rolename for ERC20 snapshotter.
    /// ERC20 snapshotter role is required to snapshot shares.
    bytes32 public constant ERC20SNAPSHOTTER = keccak256("ERC20SNAPSHOTTER");
    /// Rolename for ERC20 snapshotter admins.
    bytes32 public constant ERC20SNAPSHOTTER_ADMIN =
        keccak256("ERC20SNAPSHOTTER_ADMIN");

    /// Rolename for ERC20 tierer.
    /// ERC20 tierer role is required to modify the tier contract for shares.
    bytes32 public constant ERC20TIERER = keccak256("ERC20TIERER");
    /// Rolename for ERC20 tierer admins.
    bytes32 public constant ERC20TIERER_ADMIN = keccak256("ERC20TIERER_ADMIN");

    /// Rolename for handlers.
    /// Handler role is required to accept tokens during system freeze.
    bytes32 public constant HANDLER = keccak256("HANDLER");
    /// Rolename for handler admins.
    bytes32 public constant HANDLER_ADMIN = keccak256("HANDLER_ADMIN");

    /// Rolename for withdrawers.
    /// Withdrawer role is required to burn shares and receipts.
    bytes32 public constant WITHDRAWER = keccak256("WITHDRAWER");
    /// Rolename for withdrawer admins.
    bytes32 public constant WITHDRAWER_ADMIN = keccak256("WITHDRAWER_ADMIN");

    /// The largest issued id. The next id issued will be larger than this.
    uint256 private highwaterId;

    /// The system is certified until this timestamp. If this is in the past then
    /// general transfers of shares and receipts will fail until the system can
    /// be certified to a future time.
    uint32 private certifiedUntil;

    /// The minimum tier required for an address to receive shares.
    uint8 private erc20MinimumTier;
    /// The minimum tier required for an address to receive receipts.
    uint8 private erc1155MinimumTier;

    /// The `ITierV2` contract that defines the current tier of each address for
    /// the purpose of receiving shares.
    ITierV2 private erc20Tier;
    /// The `ITierV2` contract that defines the current tier of each address for
    /// the purpose of receiving receipts.
    ITierV2 private erc1155Tier;

    /// Optional context to provide to the `ITierV2` contract when calculating
    /// any addresses' tier for the purpose of receiving shares. Global to all
    /// addresses.
    uint256[] private erc20TierContext;
    /// Optional context to provide to the `ITierV2` contract when calculating
    /// any addresses' tier for the purpose of receiving receipts. Global to all
    /// addresses.
    uint256[] private erc1155TierContext;

    /// Initializes the initial admin and the underlying `ReceiptVault`.
    /// The admin provided will be admin of all roles and can reassign and revoke
    /// this as appropriate according to standard Open Zeppelin access control
    /// logic.
    /// @param config_ All config required to initialize.
    function initialize(
        OffchainAssetReceiptVaultConfig memory config_
    ) external initializer {
        __ReceiptVault_init(config_.receiptVaultConfig);
        __AccessControl_init();

        // There is no asset, the asset is offchain.
        if (config_.receiptVaultConfig.vaultConfig.asset != address(0)) {
            revert NonZeroAsset();
        }
        // The config admin MUST be set.
        if (config_.admin == address(0)) {
            revert ZeroAdmin();
        }

        // Define all admin roles. Note that admins can admin each other which
        // is a double edged sword. ANY admin can forcibly take over the entire
        // role by removing all other admins.
        _setRoleAdmin(CERTIFIER, CERTIFIER_ADMIN);
        _setRoleAdmin(CERTIFIER_ADMIN, CERTIFIER_ADMIN);

        _setRoleAdmin(CONFISCATOR, CONFISCATOR_ADMIN);
        _setRoleAdmin(CONFISCATOR_ADMIN, CONFISCATOR_ADMIN);

        _setRoleAdmin(DEPOSITOR, DEPOSITOR_ADMIN);
        _setRoleAdmin(DEPOSITOR_ADMIN, DEPOSITOR_ADMIN);

        _setRoleAdmin(ERC1155TIERER, ERC1155TIERER_ADMIN);
        _setRoleAdmin(ERC1155TIERER_ADMIN, ERC1155TIERER_ADMIN);

        _setRoleAdmin(ERC20SNAPSHOTTER, ERC20SNAPSHOTTER_ADMIN);
        _setRoleAdmin(ERC20SNAPSHOTTER_ADMIN, ERC20SNAPSHOTTER_ADMIN);

        _setRoleAdmin(ERC20TIERER, ERC20TIERER_ADMIN);
        _setRoleAdmin(ERC20TIERER_ADMIN, ERC20TIERER_ADMIN);

        _setRoleAdmin(HANDLER, HANDLER_ADMIN);
        _setRoleAdmin(HANDLER_ADMIN, HANDLER_ADMIN);

        _setRoleAdmin(WITHDRAWER, WITHDRAWER_ADMIN);
        _setRoleAdmin(WITHDRAWER_ADMIN, WITHDRAWER_ADMIN);

        // Grant every admin role to the configured admin.
        _grantRole(CERTIFIER_ADMIN, config_.admin);
        _grantRole(CONFISCATOR_ADMIN, config_.admin);
        _grantRole(DEPOSITOR_ADMIN, config_.admin);
        _grantRole(ERC1155TIERER_ADMIN, config_.admin);
        _grantRole(ERC20SNAPSHOTTER_ADMIN, config_.admin);
        _grantRole(ERC20TIERER_ADMIN, config_.admin);
        _grantRole(HANDLER_ADMIN, config_.admin);
        _grantRole(WITHDRAWER_ADMIN, config_.admin);

        emit OffchainAssetReceiptVaultInitialized(msg.sender, config_);
    }

    /// Apply standard transfer restrictions to receipt transfers.
    /// @inheritdoc ReceiptVault
    function authorizeReceiptTransfer(
        address from_,
        address to_
    ) external view virtual override {
        enforceValidTransfer(
            erc1155Tier,
            erc1155MinimumTier,
            erc1155TierContext,
            from_,
            to_
        );
    }

    /// DO NOT call super `_beforeDeposit` as there are no assets to move.
    /// Highwater needs to witness the incoming id.
    /// @inheritdoc ReceiptVault
    function _beforeDeposit(
        uint256,
        address,
        uint256,
        uint256 id_
    ) internal virtual override {
        highwaterId = highwaterId.max(id_);
    }

    /// DO NOT call super `_afterWithdraw` as there are no assets to move.
    /// @inheritdoc ReceiptVault
    function _afterWithdraw(
        uint256,
        address,
        address owner_,
        uint256,
        uint256 id_ //solhint-disable-next-line no-empty-blocks
    ) internal view virtual override {}

    /// Shares total supply is 1:1 with offchain assets.
    /// Assets aren't real so only way to report this is to return the total
    /// supply of shares.
    /// @inheritdoc ReceiptVault
    function totalAssets() external view virtual override returns (uint256) {
        return totalSupply();
    }

    /// @inheritdoc ReceiptVault
    function _shareRatio(
        address owner_,
        address,
        uint256 id_,
        ShareAction shareAction_
    ) internal view virtual override returns (uint256) {
        if (shareAction_ == ShareAction.Mint) {
            return
                hasRole(DEPOSITOR, owner_)
                    ? _shareRatioUserAgnostic(id_, shareAction_)
                    : 0;
        } else {
            return
                hasRole(WITHDRAWER, owner_)
                    ? _shareRatioUserAgnostic(id_, shareAction_)
                    : 0;
        }
    }

    /// IDs for offchain assets are merely autoincremented. If the minter wants
    /// to track some external ID system as a foreign key they can emit this in
    /// the associated receipt information.
    /// @inheritdoc ReceiptVault
    function _nextId() internal view virtual override returns (uint256) {
        return highwaterId + 1;
    }

    /// Depositors can increase the deposited assets for the existing id of this
    /// receipt. It is STRONGLY RECOMMENDED the redepositor also provides data to
    /// be forwarded to asset information to justify the additional deposit. New
    /// offchain assets MUST NOT redeposit under existing IDs, they MUST be
    /// deposited under a new id instead. The ID preservation provided by
    /// `redeposit` is intended to ensure a consistent audit trail for the
    /// lifecycle of any asset. We do not need a corresponding "rewithdraw"
    /// function because withdrawals already target an ID.
    ///
    /// Note that the existence of `redeposit` and `withdraw` both allow the
    /// potential of two different depositor/withdrawer accounts to apply the
    /// same mint/burn concurrently to the mempool and have both included in a
    /// block inappropriately. Features like this, as well as more fundamental
    /// trust assumptions/limitations offchain, make it impossible to fully
    /// decouple depositors and withdrawers from each other _per token_. The
    /// model is that there are many decoupled tokens each with their own "team"
    /// that can be expected to coordinate to prevent double-mint/burn.
    ///
    /// @param assets_ As per IERC4626 `deposit`.
    /// @param receiver_ As per IERC4626 `deposit`.
    /// @param id_ The existing receipt to despoit additional assets under. Will
    /// mint new ERC20 shares and also increase the held receipt amount 1:1.
    /// @param receiptInformation_ Forwarded to receipt mint and
    /// `receiptInformation`.
    function redeposit(
        uint256 assets_,
        address receiver_,
        uint256 id_,
        bytes calldata receiptInformation_
    ) external returns (uint256) {
        // Only allow redepositing for IDs that exist.
        if (id_ > highwaterId) {
            revert InvalidId(id_);
        }
        _deposit(
            assets_,
            receiver_,
            _calculateDeposit(
                assets_,
                _shareRatio(msg.sender, receiver_, id_, ShareAction.Mint),
                0
            ),
            id_,
            receiptInformation_
        );
        return assets_;
    }

    /// Exposes `ERC20Snapshot` from Open Zeppelin behind a role restricted call.
    /// @param data_ Associated data relevant to the snapshot.
    /// @return The snapshot ID as per Open Zeppelin.
    function snapshot(
        bytes memory data_
    ) external onlyRole(ERC20SNAPSHOTTER) returns (uint256) {
        uint256 id_ = _snapshot();
        emit SnapshotWithData(msg.sender, id_, data_);
        return id_;
    }

    /// `ERC20TIERER` Role restricted setter for all internal state that drives
    /// the erc20 tier restriction logic on transfers.
    /// @param tier_ `ITier` contract to check when receiving shares. MAY be
    /// `address(0)` to disable report checking.
    /// @param minimumTier_ The minimum tier to be held according to `tier_`.
    /// @param context_ Global context to be forwarded with tier checks.
    /// @param data_ Associated data relevant to the change in tier contract.
    function setERC20Tier(
        address tier_,
        uint8 minimumTier_,
        uint256[] calldata context_,
        bytes memory data_
    ) external onlyRole(ERC20TIERER) {
        erc20Tier = ITierV2(tier_);
        erc20MinimumTier = minimumTier_;
        erc20TierContext = context_;
        emit SetERC20Tier(msg.sender, tier_, minimumTier_, context_, data_);
    }

    /// `ERC1155TIERER` Role restricted setter for all internal state that drives
    /// the erc1155 tier restriction logic on transfers.
    /// @param tier_ `ITier` contract to check when receiving receipts. MAY be
    /// `0` to disable report checking.
    /// @param minimumTier_ The minimum tier to be held according to `tier_`.
    /// @param context_ Global context to be forwarded with tier checks.
    /// @param data_ Associated data relevant to the change in tier contract.
    function setERC1155Tier(
        address tier_,
        uint8 minimumTier_,
        uint256[] calldata context_,
        bytes memory data_
    ) external onlyRole(ERC1155TIERER) {
        erc1155Tier = ITierV2(tier_);
        erc1155MinimumTier = minimumTier_;
        erc1155TierContext = context_;
        emit SetERC1155Tier(msg.sender, tier_, minimumTier_, context_, data_);
    }

    /// Certifiers MAY EXTEND OR REDUCE the `certifiedUntil` time. If there are
    /// many certifiers, any certifier can modify the certifiation at any time.
    /// It is STRONGLY RECOMMENDED that certifiers DO NOT set the `forceUntil_`
    /// flag to `true` unless they want to:
    ///
    /// - Potentially override another certifier's concurrent certification
    /// - Reduce the certification time
    ///
    /// The certifier is STRONGLY RECOMMENDED to submit a summary report of the
    /// process and findings used to justify the modified `certifiedUntil` time.
    ///
    /// The certifier MUST provide the block number containing the information
    /// they used to perform the certification. It is entirely possible that
    /// new mints/burns and receipt information becomes available after the
    /// certification process begins, so the certifier MUST specify THEIR highest
    /// seen block at the moment they made their decision. This block cannot be
    /// in the future relative to the moment of certification.
    ///
    /// The certifier is STRONGLY RECOMMENDED to ONLY use publicly available
    /// documents directly referenced by `ReceiptInformation` events to make
    /// their decision. The certifier MUST specify if, when and why private data
    /// was used to inform their certification decision. This is critical for
    /// share holders who inform themselves on the quality of their tokens not
    /// only by the overall audit outcome, but by the integrity of the sum of its
    /// parts in the form of receipt and associated visible information.
    ///
    /// The certifier SHOULD NOT provide a certification time that predates the
    /// timestamp of the reference block, although this is NOT enforced onchain.
    /// This would imply that the system was certified until a time before the
    /// data that informed the certification even existed. DO NOT certify until
    /// a `0` time, any time in the past relative to the current time will have
    /// the same effect on the system (freezing it immediately).
    /// The reason this is NOT enforced onchain is that the certification time is
    /// a timestamp and the reference block number is a block number, these two
    /// time keeping systems are NOT directly interchangeable.
    ///
    /// Note that redundant certifications MAY be submitted. Regardless of the
    /// `forceUntil_` flag the transaction WILL NOT REVERT and the `Certify`
    /// event will be emitted for any valid `certifyUntil_` time. If certifier A
    /// certifies until time X and certifier B certifies until time X - Y then
    /// both certifications will emit an event and time X is the certifiation
    /// date of the system. This encouranges multiple certifications to be sought
    /// in parallel if it helps maintain trust in the overall system.
    ///
    /// @param certifyUntil_ The new `certifiedUntil` time.
    /// @param referenceBlockNumber_ The highest block number that the certifier
    /// has seen at the moment they decided to certify the system.
    /// @param forceUntil_ Whether to force the new certification time even if it
    /// is in the past relative to the existing certification time.
    /// @param data_ Arbitrary data justifying the certification. MAY reference
    /// data available offchain e.g. on IPFS.
    function certify(
        uint256 certifyUntil_,
        uint256 referenceBlockNumber_,
        bool forceUntil_,
        bytes calldata data_
    ) external onlyRole(CERTIFIER) {
        if (certifyUntil_ == 0) {
            revert ZeroCertifyUntil(msg.sender);
        }
        if (referenceBlockNumber_ > block.number) {
            revert FutureReferenceBlock(msg.sender, referenceBlockNumber_);
        }
        // A certifier can set `forceUntil_` to true to force a _decrease_ in
        // the `certifiedUntil` time, which is unusual but MAY need to be done
        // in the case of rectifying a prior mistake.
        if (forceUntil_ || certifyUntil_ > certifiedUntil) {
            certifiedUntil = uint32(certifyUntil_);
        }
        emit Certify(
            msg.sender,
            certifyUntil_,
            referenceBlockNumber_,
            forceUntil_,
            data_
        );
    }

    /// Reverts if some transfer is disallowed. Handles both share and receipt
    /// transfers. Standard logic reverts any transfer that is EITHER to or from
    /// an address that does not have the required tier OR the system is no
    /// longer certified therefore ALL unpriviledged transfers MUST revert.
    ///
    /// Certain exemptions to transfer restrictions apply:
    /// - If a tier contract is not set OR the minimum tier is 0 then tier
    ///   restrictions are ignored.
    /// - Any handler role MAY SEND AND RECEIVE TOKENS AT ALL TIMES BETWEEN
    ///   THEMSELVES AND ANYONE ELSE. Tier and certification restrictions are
    ///   ignored for both sender and receiver when either is a handler. Handlers
    ///   exist to _repair_ certification issues, so MUST be able to transfer
    ///   unhindered.
    /// - `address(0)` is treated as a handler for the purposes of any minting
    ///   and burning that may be required to repair certification blockers.
    /// - Transfers TO a confiscator are treated as handler-like at all times,
    ///   but transfers FROM confiscators are treated as unpriviledged. This is
    ///   to allow potential legal requirements on confiscation during system
    ///   freeze, without assigning unnecessary priviledges to confiscators.
    ///
    /// @param tier_ The tier contract to check reports against.
    /// MAY be `address(0)`.
    /// @param minimumTier_ The minimum tier to check `from_` and `to_` against.
    /// @param tierContext_ Additional context to pass to `tier_` for the report.
    /// @param from_ The token is being transferred from this account.
    /// @param to_ The token is being transferred to this account.
    function enforceValidTransfer(
        ITierV2 tier_,
        uint256 minimumTier_,
        uint256[] memory tierContext_,
        address from_,
        address to_
    ) internal view {
        // Handlers can ALWAYS send and receive funds.
        // Handlers bypass BOTH the timestamp on certification AND tier based
        // restriction.
        if (hasRole(HANDLER, from_) || hasRole(HANDLER, to_)) {
            return;
        }

        // Minting and burning is always allowed as it is controlled via. RBAC
        // separately to the tier contracts. Minting and burning is ALSO valid
        // after the certification expires as it is likely the only way to
        // repair the system and bring it back to a certifiable state.
        if (from_ == address(0) || to_ == address(0)) {
            return;
        }

        // Confiscation is always allowed as it likely represents some kind of
        // regulatory/legal requirement. It may also be required to satisfy
        // certification requirements.
        if (hasRole(CONFISCATOR, to_)) {
            return;
        }

        // Everyone else can only transfer while the certification is valid.
        //solhint-disable-next-line not-rely-on-time
        if (block.timestamp > certifiedUntil) {
            revert CertificationExpired(
                from_,
                to_,
                certifiedUntil,
                block.timestamp
            );
        }

        // If there is a tier contract we enforce it.
        if (address(tier_) != address(0) && minimumTier_ > 0) {
            // The sender must have a valid tier.
            uint256 fromReportTime_ = tier_.reportTimeForTier(
                from_,
                minimumTier_,
                tierContext_
            );
            if (block.timestamp < fromReportTime_) {
                revert UnauthorizedSenderTier(from_, fromReportTime_);
            }
            // The recipient must have a valid tier.
            uint256 toReportTime_ = tier_.reportTimeForTier(
                to_,
                minimumTier_,
                tierContext_
            );
            if (block.timestamp < toReportTime_) {
                revert UnauthorizedRecipientTier(to_, toReportTime_);
            }
        }
    }

    /// Apply standard transfer restrictions to share transfers.
    /// @inheritdoc ReceiptVault
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        enforceValidTransfer(
            erc20Tier,
            erc20MinimumTier,
            erc20TierContext,
            from_,
            to_
        );
        super._beforeTokenTransfer(from_, to_, amount_);
    }

    /// Confiscators can confiscate ERC20 vault shares from `confiscatee_`.
    /// Confiscation BYPASSES TRANSFER RESTRICTIONS due to system freeze and
    /// IGNORES ALLOWANCES set by the confiscatee.
    ///
    /// The LIMITATION ON CONFISCATION is that the confiscatee MUST NOT have the
    /// minimum tier for transfers. I.e. confiscation is a two step process.
    /// First the tokens must be frozen according to due process by the token
    /// issuer (which may be an individual, organisation or many entities), THEN
    /// the confiscation can clear. This prevents rogue/compromised confiscators
    /// from being able to arbitrarily take tokens from users to themselves. At
    /// the least, assuming separate private keys managing the tiers and
    /// confiscation, the two steps require at least two critical security
    /// breaches per attack rather than one.
    ///
    /// Confiscation is a binary event. All shares or zero shares are
    /// confiscated from the confiscatee.
    ///
    /// Typically people DO NOT LIKE having their assets confiscated. It SHOULD
    /// be treated as a rare and extreme action, only taken when all other
    /// avenues/workarounds are explored and exhausted. The confiscator SHOULD
    /// provide their justification of each confiscation, and the general public,
    /// especially token holders SHOULD review and be highly suspect of unjust
    /// confiscation events. If you review and DO NOT agree with a confiscation
    /// you SHOULD NOT continue to hold the token, exiting systems that play fast
    /// and loose with user assets is the ONLY way to discourage such behaviour.
    ///
    /// @param confiscatee_ The address that shares are being confiscated from.
    /// @param data_ The associated justification of the confiscation, and/or
    /// other relevant data.
    /// @return The amount of shares confiscated.
    function confiscateShares(
        address confiscatee_,
        bytes memory data_
    ) external nonReentrant onlyRole(CONFISCATOR) returns (uint256) {
        uint256 confiscatedShares_ = 0;
        if (
            address(erc20Tier) == address(0) ||
            block.timestamp <
            erc20Tier.reportTimeForTier(
                confiscatee_,
                erc20MinimumTier,
                erc20TierContext
            )
        ) {
            confiscatedShares_ = balanceOf(confiscatee_);
            if (confiscatedShares_ > 0) {
                emit ConfiscateShares(
                    msg.sender,
                    confiscatee_,
                    confiscatedShares_,
                    data_
                );
                _transfer(confiscatee_, msg.sender, confiscatedShares_);
            }
        }
        return confiscatedShares_;
    }

    /// Confiscators can confiscate ERC1155 vault receipts from `confiscatee_`.
    /// The process, limitations and logic is identical to share confiscation
    /// except that receipt confiscation is performed per-ID.
    ///
    /// Typically people DO NOT LIKE having their assets confiscated. It SHOULD
    /// be treated as a rare and extreme action, only taken when all other
    /// avenues/workarounds are explored and exhausted. The confiscator SHOULD
    /// provide their justification of each confiscation, and the general public,
    /// especially token holders SHOULD review and be highly suspect of unjust
    /// confiscation events. If you review and DO NOT agree with a confiscation
    /// you SHOULD NOT continue to hold the token, exiting systems that play fast
    /// and loose with user assets is the ONLY way to discourage such behaviour.
    ///
    /// @param confiscatee_ The address that receipts are being confiscated from.
    /// @param id_ The ID of the receipt to confiscate.
    /// @param data_ The associated justification of the confiscation, and/or
    /// other relevant data.
    /// @return The amount of receipt confiscated.
    function confiscateReceipt(
        address confiscatee_,
        uint256 id_,
        bytes memory data_
    ) external nonReentrant onlyRole(CONFISCATOR) returns (uint256) {
        uint256 confiscatedReceiptAmount_ = 0;
        if (
            address(erc1155Tier) == address(0) ||
            block.timestamp <
            erc1155Tier.reportTimeForTier(
                confiscatee_,
                erc1155MinimumTier,
                erc1155TierContext
            )
        ) {
            IReceiptV1 receipt_ = _receipt;
            confiscatedReceiptAmount_ = receipt_.balanceOf(confiscatee_, id_);
            if (confiscatedReceiptAmount_ > 0) {
                emit ConfiscateReceipt(
                    msg.sender,
                    confiscatee_,
                    id_,
                    confiscatedReceiptAmount_,
                    data_
                );
                receipt_.ownerTransferFrom(
                    confiscatee_,
                    msg.sender,
                    id_,
                    confiscatedReceiptAmount_,
                    ""
                );
            }
        }
        return confiscatedReceiptAmount_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../receipt/ReceiptVaultFactory.sol";
import {OffchainAssetReceiptVault, OffchainAssetReceiptVaultConfig, OffchainAssetVaultConfig, ReceiptVaultConfig} from "./OffchainAssetReceiptVault.sol";
import {Receipt, ReceiptFactory} from "../receipt/ReceiptFactory.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// @title OffchainAssetReceiptVaultFactory
/// @notice Factory for creating and deploying `OffchainAssetReceiptVault`.
contract OffchainAssetReceiptVaultFactory is ReceiptVaultFactory {
    constructor(
        ReceiptVaultFactoryConfig memory config_
    )
        ReceiptVaultFactory(config_) //solhint-disable-next-line no-empty-blocks
    {}

    /// @inheritdoc Factory
    function _createChild(
        bytes memory data_
    ) internal virtual override returns (address) {
        OffchainAssetVaultConfig memory offchainAssetVaultConfig_ = abi.decode(
            data_,
            (OffchainAssetVaultConfig)
        );

        address clone_ = Clones.clone(implementation);
        OffchainAssetReceiptVault(clone_).initialize(
            OffchainAssetReceiptVaultConfig(
                offchainAssetVaultConfig_.admin,
                _createReceipt(clone_, offchainAssetVaultConfig_.vaultConfig)
            )
        );
        return clone_;
    }

    /// Typed wrapper for `createChild`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param offchainAssetVaultConfig_ Config for the
    /// `OffchainAssetReceiptVault`.
    /// @return New `OffchainAssetReceiptVault` child contract address.
    function createChildTyped(
        OffchainAssetVaultConfig memory offchainAssetVaultConfig_
    ) external returns (OffchainAssetReceiptVault) {
        return
            OffchainAssetReceiptVault(
                createChild(abi.encode(offchainAssetVaultConfig_))
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title IReceiptOwnerV1
/// @notice Owner of an `IReceiptV1` MUST authorize transfers between peers in
/// addition to being directly responsible for `ownerX` calls.
interface IReceiptOwnerV1 {
    /// Authorise a receipt transfer. `IReceiptOwnerV1` contract MUST REVERT if
    /// the transfer is unauthorized. NOT reverting means the transfer is
    /// authorized.
    /// @param from The address the receipt is being transferred from.
    /// @param to The address the receipt is being transferred to.
    function authorizeReceiptTransfer(address from, address to) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @title IReceiptV1
/// @notice IReceiptV1 is an extension to IERC1155 that requires implementers to
/// provide an interface to allow an owner to UNILATERALLY (e.g. without access
/// or allowance restrictions):
///
/// - mint
/// - burn
/// - transfer
/// - emit data
///
/// The owner MUST implement `IReceiptOwnerV1` to authorize transfers and receipt
/// information. The `IReceiptV1` MUST call the relevant authorization function
/// on the owner for receipt information and standard ERC1155 transfers.
///
/// Earlier versions of `ReceiptVault` implemented the vault as BOTH an ERC1155
/// AND ERC20/4626 vault, which technically worked fine onchain but offchain
/// tooling such as MetaMask seems to only understand a contract implementing one
/// token interface. The combination of `IReceiptV1` and `IReceiptOwnerV1`
/// attempts to emulate the hybrid token model through paired interfaces.
interface IReceiptV1 is IERC1155 {
    /// Emitted when new information is provided for a receipt.
    /// @param sender `msg.sender` emitting the information for the receipt.
    /// @param id Receipt the information is for.
    /// @param information Information for the receipt. MAY reference offchain
    /// data where the payload is large.
    event ReceiptInformation(address sender, uint256 id, bytes information);

    /// The address of the `IReceiptOwnerV1`. This mimics the Open Zeppelin
    /// `Ownable.owner` function signature as it is a very common and popular
    /// implementation. `IReceiptV1` has no opinion on how ownership is
    /// implemented and managed, it only cares that there is some owner.
    /// @return account The owner account.
    function owner() external view returns (address account);

    /// The owner MAY directly mint receipts for any account, ID and amount
    /// without restriction. The data MUST be treated as both ERC1155 data and
    /// receipt information. Overflow MUST revert as usual for ERC1155.
    /// MUST REVERT if the `msg.sender` is NOT the owner.
    /// @param account The account to mint a receipt for.
    /// @param id The receipt ID to mint.
    /// @param amount The amount to mint for the `id`.
    /// @param data The ERC1155 data. MUST be emitted as receipt information.
    function ownerMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /// The owner MAY directly burn receipts for any account, ID and amount
    /// without restriction. Underflow MUST revert as usual for ERC1155.
    /// MUST REVERT if the `msg.sender` is NOT the owner.
    /// @param account The account to burn a receipt for.
    /// @param id The receipt ID to burn.
    /// @param amount The amount to mint for the `id`.
    /// @param data MUST be emitted as receipt information.
    function ownerBurn(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /// The owner MAY directly transfer receipts from and to any account for any
    /// id and amount without restriction. Overflow and underflow MUST revert as
    /// usual for ERC1155.
    /// MUST REVERT if the `msg.sender` is NOT the owner.
    /// @param from The account to transfer from.
    /// @param to The account to transfer to.
    /// @param id The receipt ID
    /// @param amount The amount to transfer between accounts.
    /// @param data The data associated with the transfer as per ERC1155.
    /// MUST NOT be emitted as receipt information.
    function ownerTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /// Emit a `ReceiptInformation` event for some receipt ID with `data` as the
    /// receipt information. ANY `msg.sender` MAY call this, it is up to offchain
    /// processes/indexers to filter unwanted receipt information before display
    /// and consumption.
    /// @param id The receipt ID this information is for.
    /// @param data The data of the receipt information. MAY be ANY data format
    /// or even malicious/garbage data. The indexer is responsible for filtering
    /// unwanted data.
    function receiptInformation(uint256 id, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./IReceiptOwnerV1.sol";
import "./IReceiptV1.sol";

import {ERC1155Upgradeable as ERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @dev the ERC1155 URI is always the pinned metadata on ipfs.
string constant RECEIPT_METADATA_URI = "ipfs://bafkreih7cvpjocgrk7mgdel2hvjpquc26j4jo2jkez5y2qdaojfil7vley";

/// @title Receipt
/// @notice The `IReceiptV1` for a `ReceiptVault`. Standard implementation allows
/// receipt information to be emitted and mints/burns according to ownership and
/// owner authorization.
contract Receipt is IReceiptV1, Ownable, ERC1155 {
    /// Disables initializers so that the clonable implementation cannot be
    /// initialized and used directly outside a factory deployment.
    constructor() {
        _disableInitializers();
    }

    /// Initializes the `Receipt` so that it is usable as a clonable
    /// implementation in `ReceiptFactory`.
    function initialize() external initializer {
        __Ownable_init();
        __ERC1155_init(RECEIPT_METADATA_URI);
    }

    /// @inheritdoc IReceiptV1
    function owner()
        public
        view
        virtual
        override(IReceiptV1, Ownable)
        returns (address)
    {
        return Ownable.owner();
    }

    /// @inheritdoc IReceiptV1
    function ownerMint(
        address account_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _receiptInformation(account_, id_, data_);
        _mint(account_, id_, amount_, data_);
    }

    /// @inheritdoc IReceiptV1
    function ownerBurn(
        address account_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _receiptInformation(account_, id_, data_);
        _burn(account_, id_, amount_);
    }

    /// @inheritdoc IReceiptV1
    function ownerTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _safeTransferFrom(from_, to_, id_, amount_, data_);
    }

    /// Checks with the owner before authorizing transfer IN ADDITION to `super`
    /// inherited checks.
    /// @inheritdoc ERC1155
    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override {
        super._beforeTokenTransfer(
            operator_,
            from_,
            to_,
            ids_,
            amounts_,
            data_
        );
        IReceiptOwnerV1(owner()).authorizeReceiptTransfer(from_, to_);
    }

    /// Emits `ReceiptInformation` if there is any data after checking with the
    /// receipt owner for authorization.
    /// @param account_ The account that is emitting receipt information.
    /// @param id_ The id of the receipt this information is for.
    /// @param data_ The data being emitted as information for the receipt.
    function _receiptInformation(
        address account_,
        uint256 id_,
        bytes memory data_
    ) internal virtual {
        // No data is noop.
        if (data_.length > 0) {
            emit ReceiptInformation(account_, id_, data_);
        }
    }

    /// @inheritdoc IReceiptV1
    function receiptInformation(
        uint256 id_,
        bytes memory data_
    ) external virtual {
        _receiptInformation(msg.sender, id_, data_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Factory} from "@rainprotocol/rain-protocol/contracts/factory/Factory.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {Receipt} from "./Receipt.sol";

/// @title ReceiptFactory
/// @notice Factory that builds `Receipt` children and is ostensibly used by the
/// `ReceiptVaultFactory` so ownership assignment MUST be handled by the caller
/// of `createChild`.
contract ReceiptFactory is Factory {
    /// Implementation address that will be cloned when creating child contracts.
    address public immutable implementation;

    /// Builds the `Receipt` reference implementation that all children will be
    /// a proxy to.
    constructor() {
        address implementation_ = address(new Receipt());
        implementation = implementation_;
        emit Implementation(msg.sender, implementation_);
    }

    /// The owner is `msg.sender` because this is intended to be used by the
    /// `ReceiptVaultFactory` which will subsequently and atomically assign
    /// ownership to the `ReceiptVault` that it creates.
    /// @inheritdoc Factory
    function _createChild(
        bytes memory
    ) internal virtual override returns (address) {
        address clone_ = Clones.clone(implementation);
        Receipt(clone_).initialize();
        Receipt(clone_).transferOwnership(msg.sender);
        return clone_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ERC20SnapshotUpgradeable as ERC20Snapshot} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {IERC4626Upgradeable as IERC4626} from "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MulticallUpgradeable as Multicall} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "./IReceiptV1.sol";
import "@rainprotocol/rain-protocol/contracts/math/LibFixedPointMath.sol";
import "./IReceiptOwnerV1.sol";

/// Thrown when an ID can't be deposited or withdrawn.
/// @param id The invalid ID.
error InvalidId(uint256 id);

/// Thrown when the share ratio does not meet the minimum share ratio.
error MinShareRatio(uint256 minShareRatio, uint256 shareRatio);

/// Thrown when depositing 0 asset amount.
error ZeroAssetsAmount();

/// Thrown when minting 0 shares amount.
error ZeroSharesAmount();

/// Thrown when receiver of minted shares is address zero.
error ZeroReceiver();

/// Thrown when owner of shares withdrawn is address zero.
error ZeroOwner();

/// Thrown when depositing assets under ID zero.
error ZeroID();

/// Thrown when the receipt vault does not own the receipt.
error WrongOwner(address vault, address receipt);

/// Represents the action being taken on shares, ostensibly for calculating a
/// ratio.
enum ShareAction {
    Mint,
    Burn
}

/// All config required to initialize `ReceiptVault` except the receipt address.
/// Included as a field on `ReceiptVaultConfig` which is the full initialization
/// config struct. This is used by the `ReceiptVaultFactory` which will create a
/// new receipt in the same transaction and build the full `ReceiptVaultConfig`.
/// @param asset As per ERC4626.
/// @param name As per ERC20.
/// @param symbol As per ERC20.
struct VaultConfig {
    address asset;
    string name;
    string symbol;
}

/// All config required to initialize `ReceiptVault`.
/// @param receipt The `Receipt` e.g. built by `ReceiptVaultFactory` that is
/// owned by the `ReceiptVault` as an `IReceiptOwnerV1`.
/// @param vaultConfig all the vault configuration as `VaultConfig`.
struct ReceiptVaultConfig {
    address receipt;
    VaultConfig vaultConfig;
}

/// @title ReceiptVault
/// @notice The workhorse that binds several abstract concepts together into the
/// specific concrete implemenation of our working system.
///
/// - Implementing an ERC4626 standard vault with assets and shares
/// - where the shares are minted 1:1 with an ERC1155 receipt NFT across many IDs
/// - and each ID is associated with a specific deposit event
/// - that records arbitrary offchain data for decentralised commentary per-ID
/// - such that shares can be freely treated as standard onchain fungible assets
/// - and can be burned at any time, but only 1:1 with their creation event
/// - by forcing the burner to hold and burn both a receipt and some shares for
///   every burn.
///
/// The specifics of share/asset ratios on mints/burns, additional authorization
/// logic, transfer restrictions, etc. are all extensible and overridable through
/// inheritance and standard Open Zeppelin hooks from the underlying contracts.
///
/// Note that the receipt implementation is a separate contract as we found
/// during development that combining ERC20 and ERC1155 on a single contract
/// resulted in poor tooling/wallet support offchain (e.g. MetaMask).
/// Conceptually it is reasonable to consider the minted shares and receipts as
/// a single unit, forming a singular hybrid token model.
///
/// Note also that neither the receipt nor the shares are intended to represent
/// "ownership", whatever that means in your local legal/cultural bubble. The
/// receipt merely represents a right (or perhaps even responsibility) to burn
/// shares, and the shares only represent an expectation that assets associated
/// with the shares' mint event DO NOT MOVE (whatever that means) until/unless
/// those shares are burned.
///
/// Each vault is deployed from a factory as a clone from a reference
/// implementation, allowing for the model to cheaply and freedomly scale
/// horizontally. This allows for some trust/permissioned concessions to be made
/// per-vault as new competing vaults can always be deployed and traded against
/// each other in parallel, allowing trust to be "policed" at the liquidity and
/// free market layer.
contract ReceiptVault is
    IReceiptOwnerV1,
    Multicall,
    ReentrancyGuard,
    ERC20Snapshot,
    IERC4626
{
    using LibFixedPointMath for uint256;
    using SafeERC20 for IERC20;

    /// Similar to receipt information but for the entire vault. Anyone can emit
    /// any data about the vault, it is up to indexers to filter and clients to
    /// interpret the data.
    /// @param sender Sender of the receipt vault information.
    /// @param vaultInformation The vault information.
    event ReceiptVaultInformation(address sender, bytes vaultInformation);

    /// Similar to IERC4626 deposit but with receipt ID and information.
    /// @param sender As per `IERC4626.Deposit`.
    /// @param owner As per `IERC4626.Deposit`.
    /// @param assets As per `IERC4626.Deposit`.
    /// @param shares As per `IERC4626.Deposit`.
    /// @param id As per `IERC1155.TransferSingle`.
    /// @param receiptInformation As per `ReceiptInformation`.
    event DepositWithReceipt(
        address sender,
        address owner,
        uint256 assets,
        uint256 shares,
        uint256 id,
        bytes receiptInformation
    );

    /// Similar to IERC4626 withdraw but with receipt ID.
    /// @param sender As per `IERC4626.Withdraw`.
    /// @param receiver As per `IERC4626.Withdraw`.
    /// @param owner As per `IERC4626.Withdraw`.
    /// @param assets As per `IERC4626.Withdraw`.
    /// @param shares As per `IERC4626.Withdraw`.
    /// @param id As per `IERC1155.TransferSingle`.
    /// @param receiptInformation As per `ReceiptInformation`.
    event WithdrawWithReceipt(
        address sender,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares,
        uint256 id,
        bytes receiptInformation
    );

    /// Underlying ERC4626 asset.
    IERC20 internal _asset;
    /// ERC1155 Receipt owned by this receipt vault for the purpose of tracking
    /// mints and enforcing integrity of subsequent burns.
    IReceiptV1 internal _receipt;

    /// Senders MAY OPTIONALLY set minimum share ratios for ERC4626 deposits.
    /// Alternatively they MAY avoid the gas cost of modifying storage and call
    /// the non-standard equivalent functions that take a minimum share ratio
    /// parameter.
    mapping(address => uint256) public minShareRatios;

    /// Users MAY OPTIONALLY set the receipt ID they want to withdraw as a
    /// two step workflow and call the 4626 standard withdraw functions.
    /// Alternatively they MAY avoid the gas cost of modifying storage and call
    /// the non-standard equivalent functions that take a ID parameter.
    mapping(address => uint256) public withdrawIds;

    /// `ReceiptVault` is intended to be cloned and initialized by a
    /// `ReceiptVaultFactory` so is an implementation contract that can't itself
    /// be initialized.
    constructor() {
        _disableInitializers();
    }

    /// Initialize the `ReceiptVault` and .
    /// @param config_ All config required for initialization.
    // solhint-disable-next-line func-name-mixedcase
    function __ReceiptVault_init(
        ReceiptVaultConfig memory config_
    ) internal virtual {
        __Multicall_init();
        __ReentrancyGuard_init();
        __ERC20_init(config_.vaultConfig.name, config_.vaultConfig.symbol);
        __ERC20Snapshot_init();
        _asset = IERC20(config_.vaultConfig.asset);

        IReceiptV1 receipt_ = IReceiptV1(config_.receipt);
        address receiptOwner_ = receipt_.owner();
        if (receiptOwner_ != address(this)) {
            revert WrongOwner(address(this), receiptOwner_);
        }
        _receipt = receipt_;
    }

    /// Similar to `receiptInformation` on the underlying receipt but for this
    /// vault. Anyone can call this and provide any information. Indexers and
    /// clients MUST take care against corrupt and malicious data.
    /// @param vaultInformation_ The information to emit for this vault.
    function receiptVaultInformation(
        bytes memory vaultInformation_
    ) external virtual {
        emit ReceiptVaultInformation(msg.sender, vaultInformation_);
    }

    /// @inheritdoc IReceiptOwnerV1
    function authorizeReceiptTransfer(
        address,
        address // solhint-disable-next-line no-empty-blocks
    ) external view virtual {
        // Authorize all receipt transfers by default.
    }

    /// Standard check to enforce the minimum share ratio. If the share ratio is
    /// less than the minimum the transaction will revert with `MinShareRatio`.
    /// @param minShareRatio_ The share ratio must be at least this.
    /// @param shareRatio_ The actual share ratio.
    function checkMinShareRatio(
        uint256 minShareRatio_,
        uint256 shareRatio_
    ) internal pure {
        if (shareRatio_ < minShareRatio_) {
            revert MinShareRatio(minShareRatio_, shareRatio_);
        }
    }

    /// Calculate how many `shares_` will be minted in return for `assets_` as
    /// per ERC4626 deposit logic.
    /// @param assets_ Amount of assets being deposited.
    /// @param shareRatio_ The ratio of shares to assets to deposit against.
    /// @param depositMinShareRatio_ The minimum share ratio required by the
    /// depositor. Will error if `shareRatio_` is less than
    /// `depositMinShareRatio_`.
    /// @return shares_ Amount of shares to mint for this deposit.
    function _calculateDeposit(
        uint256 assets_,
        uint256 shareRatio_,
        uint256 depositMinShareRatio_
    ) internal pure virtual returns (uint256) {
        checkMinShareRatio(depositMinShareRatio_, shareRatio_);

        // IRC4626:
        // If (1) it’s calculating how many shares to issue to a user for a
        // certain amount of the underlying tokens they provide, it should
        // round down.
        return assets_.fixedPointMul(shareRatio_, Math.Rounding.Down);
    }

    /// Calculate how many `assets_` are needed to mint `shares_` as per ERC4626
    /// mint logic.
    /// @param shares_ Amount of shares desired to be minted.
    /// @param shareRatio_ The ratio shares are minted at per asset.
    /// @param mintMinShareRatio_ The minimum ratio required by the minter. Will
    /// error if `shareRatio_` is less than `mintMinShareRatio_`.
    /// @return assets_ Amount of assets that must be deposited for this mint.
    function _calculateMint(
        uint256 shares_,
        uint256 shareRatio_,
        uint256 mintMinShareRatio_
    ) internal view virtual returns (uint256) {
        checkMinShareRatio(mintMinShareRatio_, shareRatio_);

        // IERC4626:
        // If (2) it’s calculating the amount of underlying tokens a user has
        // to provide to receive a certain amount of shares, it should
        // round up.
        return shares_.fixedPointDiv(shareRatio_, Math.Rounding.Up);
    }

    /// Calculate how many `shares_` to burn to withdraw `assets_` as per ERC4626
    /// withdraw logic.
    /// @param assets_ Amount of assets being withdrawn.
    /// @param shareRatio_ Ratio of shares to assets to withdraw against.
    /// @return shares_ Amount of shares to burn for this withdrawal.
    function _calculateWithdraw(
        uint256 assets_,
        uint256 shareRatio_
    ) internal pure virtual returns (uint256) {
        // IERC4626:
        // If (1) it’s calculating the amount of shares a user has to supply to
        // receive a given amount of the underlying tokens, it should round up.
        return assets_.fixedPointMul(shareRatio_, Math.Rounding.Up);
    }

    /// Calculate how many `assets_` to withdraw for burning `shares_` as per
    /// ERC4626 redeem logic.
    /// @param shares_ Amount of shares being burned for redemption.
    /// @param shareRatio_ Ratio of shares to assets being redeemed against.
    /// @return assets_ Amount of assets that will be redeemed for the given
    /// shares.
    function _calculateRedeem(
        uint256 shares_,
        uint256 shareRatio_
    ) internal pure virtual returns (uint256) {
        // IERC4626:
        // If (2) it’s determining the amount of the underlying tokens to
        // transfer to them for returning a certain amount of shares, it should
        // round down.
        return shares_.fixedPointDiv(shareRatio_, Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /// Any address can set their own minimum share ratio.
    /// This is optional as the non-standard ERC4626 equivalent functions accept
    /// a minimum share ratio parameter. This facilitates the ERC4626 interface
    /// by adding one additional initial transaction for the user.
    /// @param senderMinShareRatio_ The new minimum share ratio for the
    /// `msg.sender` to be used in subsequent deposit calls.
    function setMinShareRatio(uint256 senderMinShareRatio_) external {
        minShareRatios[msg.sender] = senderMinShareRatio_;
    }

    /// Any address can set their own ID for withdrawals.
    /// This is optional as the non-standard ERC4626 equivalent functions accept
    /// a withdrawal ID parameter. This facilitates the ERC4626 interface
    /// by adding one initial transaction for the user.
    /// @param id_ The new withdrawal id_ for the `msg.sender` to be used
    /// in subsequent withdrawal calls. If the ID does NOT match the ID of a
    /// receipt held by sender then these subsequent withdrawals will fail.
    /// It is the responsibility of the caller to set a valid ID.
    function setWithdrawId(uint256 id_) external {
        withdrawIds[msg.sender] = id_;
    }

    /// This is external NOT public. It is NOT allowed to revert BUT if we were
    /// to calculate anything important internally with this we'd need it to
    /// revert if there was an issue reading total assets.
    /// @inheritdoc IERC4626
    function totalAssets() external view virtual returns (uint256) {
        // There are NO fees so the managed assets are the asset balance of the
        // vault.
        try IERC20(asset()).balanceOf(address(this)) returns (
            // slither puts false positives on `try/catch/returns`.
            // https://github.com/crytic/slither/issues/511
            //slither-disable-next-line
            uint256 assetBalance_
        ) {
            return assetBalance_;
        } catch {
            // It's not clear what the balance should be if querying it is
            // throwing an error. The conservative error in most cases should
            // be 0.
            return 0;
        }
    }

    /// Define the ratio that shares are minted and burned per asset for both
    /// deposit/mint and withdraw/redeem. The rounding will be function specific
    /// as per ERC4626 when the ratio is applied to an absolute value, but the
    /// ratio is defined in terms of who and what is being minted/burned. Sender
    /// is available as `msg.sender` so is NOT an argument to this function.
    /// Share ratios are always number of shares per unit of assets in both mint
    /// and burn scenarios, and are 18 decimal fixed point numbers.
    ///
    /// !param owner_ The owner of assets deposited on deposit and owner of
    /// shares burned on withdraw.
    /// !param receiver_ The receiver of new shares minted on deposit and of
    /// withdrawn assets on withdraw.
    /// @param id_ The receipt ID being minted/burned in tandem with the shares.
    /// @param shareAction_ Encodes whether shares are being minted or burned
    /// (hypothetically or actually) for this ratio calculation.
    /// @return
    function _shareRatio(
        address, // owner_
        address, // receiver_
        uint256 id_,
        ShareAction shareAction_
    ) internal view virtual returns (uint256) {
        return _shareRatioUserAgnostic(id_, shareAction_);
    }

    /// Some functions in ERC4626 mandate the share ratio ignore the user.
    /// Otherwise identical to `_shareRatio`.
    /// !param id_ As per `_shareRatio`.
    /// !param shareAction_ As per `_shareRatio`.
    function _shareRatioUserAgnostic(
        uint256, // id_
        ShareAction // shareAction_
    ) internal view virtual returns (uint256) {
        // Default is 1:1 shares to assets.
        return 1e18;
    }

    /// Defines the next ID that a deposit will mint shares and receipts under.
    /// This MUST NOT be set by `msg.sender` as the `ReceiptVault` itself is
    /// responsible for managing the ID values that bind the minted shares and
    /// the associated receipt. These ID values are NOT necessarily meaningful
    /// to the asset depositor they purely bind mints to future potential burns.
    /// ID values that are meaningful to the depositor can be encoded in the
    /// receipt information that is emitted for offchain indexing via events.
    /// The default behaviour is to bind every mint and burn to the same ID, i.e.
    /// the ID is always `1`. This is almost certainly NOT desired behaviour so
    /// inheriting contracts will need to provide an override.
    /// Used inside ERC4626 functions that MUST NOT REVERT therefore this also
    /// MUST NOT REVERT. However, ID 0 is treated as invalid by default so
    /// returning 0 will revert where it needs to in the default implementation.
    // Not sure why slither flags this as dead code. It is used by both `deposit`
    // and `mint`.
    //slither-disable-next-line dead-code
    function _nextId() internal view virtual returns (uint256) {
        return 1;
    }

    /// The spec demands this function ignores per-user concerns. It seems to
    /// imply minting but doesn't provide a sibling conversion for burning.
    /// > The amount of shares that the Vault would exchange for the amount of
    /// > assets provided
    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets_) external view returns (uint256) {
        return
            _calculateDeposit(
                assets_,
                _shareRatioUserAgnostic(_nextId(), ShareAction.Mint),
                0
            );
    }

    /// The spec demands that this function ignores per-user concerns. It seems
    /// to imply burning but doesn't provide a sibling conversion for minting.
    /// > The amount of assets that the Vault would exchange for the amount of
    /// > shares provided
    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares_) external view returns (uint256) {
        return
            _calculateRedeem(
                shares_,
                // Not clear what a good ID for a hypothetical context free burn
                // should be. Next ID is technically nonsense but we don't have
                // any other ID to prefer either.
                _shareRatioUserAgnostic(_nextId(), ShareAction.Burn)
            );
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address) external pure virtual returns (uint256) {
        // The spec states to return this if there is no deposit limit.
        // Technically a deposit this large would almost certainly overflow
        // somewhere in the process, but it isn't a limit imposed by the vault
        // per-se, it's more that the ERC20 tokens themselves won't handle such
        // large entries on their internal balances. Given typical token
        // total supplies are smaller than this number, this would be a
        // theoretical point only.
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function maxMint(address) external pure virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewDeposit(
        uint256 assets_
    ) external view virtual returns (uint256) {
        return
            _calculateDeposit(
                assets_,
                // Spec doesn't provide us with a receipient but wants a per-user
                // preview so we assume that depositor = receipient.
                _shareRatio(
                    msg.sender,
                    msg.sender,
                    _nextId(),
                    ShareAction.Mint
                ),
                // IERC4626:
                // > MUST NOT revert due to vault specific user/global limits.
                // > MAY revert due to other conditions that would also cause
                // > deposit to revert.
                // Unclear if the min share ratio set by the user for themselves
                // is a "vault specific user limit" or "other conditions that
                // would also cause deposit to revert".
                // The conservative interpretation is that the user will WANT
                // the preview calculation to revert according to their own
                // preferences they set for themselves onchain.
                // If the user did not set a min ratio then the min ratio will
                // be 0 and never revert.
                minShareRatios[msg.sender]
            );
    }

    /// @inheritdoc IERC4626
    function previewMint(
        uint256 shares_
    ) public view virtual returns (uint256) {
        return
            _calculateMint(
                shares_,
                // Spec doesn't provide us with a recipient but wants a per-user
                // preview so we assume that depositor = recipient.
                _shareRatio(
                    msg.sender,
                    msg.sender,
                    _nextId(),
                    ShareAction.Mint
                ),
                // IERC4626:
                // > MUST NOT revert due to vault specific user/global limits.
                // > MAY revert due to other conditions that would also cause mint
                // > to revert.
                // Unclear if the min share ratio set by the user for themselves is
                // a "vault specific user limit" or "other conditions that would
                // also cause mint to revert".
                // The conservative interpretation is that the user will WANT
                // the preview calculation to revert according to their own
                // preferences they set for themselves onchain.
                // If the user did not set a min ratio the min ratio will be 0 and
                // never revert.
                minShareRatios[msg.sender]
            );
    }

    /// If the sender wants to use the ERC4626 `deposit` function and set a
    /// minimum ratio they need to call `setMinShareRatio` first in a separate
    /// call. Alternatively they can use the off-spec overloaded `deposit`
    /// method.
    /// @inheritdoc IERC4626
    function deposit(
        uint256 assets_,
        address receiver_
    ) external returns (uint256) {
        return deposit(assets_, receiver_, minShareRatios[msg.sender], "");
    }

    /// Overloaded `deposit` to allow `depositMinShareRatio_` to be passed
    /// directly without the additional `setMinShareRatio` call, which saves gas
    /// and can provide a better UX overall.
    /// @param assets_ As per IERC4626 `deposit`.
    /// @param receiver_ As per IERC4626 `deposit`.
    /// @param depositMinShareRatio_ Caller can set the minimum share ratio
    /// they'll accept from the oracle, otherwise the transaction is rolled back.
    /// @param receiptInformation_ Forwarded to `receiptInformation` to
    /// optionally emit offchain context about this deposit.
    /// @return shares_ As per IERC4626 `deposit`.
    function deposit(
        uint256 assets_,
        address receiver_,
        uint256 depositMinShareRatio_,
        bytes memory receiptInformation_
    ) public returns (uint256) {
        uint256 id_ = _nextId();
        uint256 shareRatio_ = _shareRatio(
            msg.sender,
            receiver_,
            id_,
            ShareAction.Mint
        );

        uint256 shares_ = _calculateDeposit(
            assets_,
            shareRatio_,
            depositMinShareRatio_
        );

        _deposit(assets_, receiver_, shares_, id_, receiptInformation_);
        return shares_;
    }

    /// Handles minting and emitting events according to spec.
    /// It does NOT do any calculations so shares and assets need to be handled
    /// correctly according to spec including rounding, in the calling context.
    /// Depositing reentrantly is never ok so we restrict that here in the
    /// internal function rather than on the external methods.
    /// @param assets_ As per IERC4626 `deposit`.
    /// @param receiver_ As per IERC4626 `deposit`.
    /// @param shares_ Amount of shares to mint for receiver. MAY be different
    /// due to rounding in different contexts so caller MUST calculate
    /// according to the rounding specification.
    /// @param id_ ID of the 1155 receipt and MUST be provided on withdrawal.
    /// @param receiptInformation_ As per `Receipt` receipt information.
    function _deposit(
        uint256 assets_,
        address receiver_,
        uint256 shares_,
        uint256 id_,
        bytes memory receiptInformation_
    ) internal virtual nonReentrant {
        if (assets_ == 0) {
            revert ZeroAssetsAmount();
        }
        if (shares_ == 0) {
            revert ZeroSharesAmount();
        }
        if (receiver_ == address(0)) {
            revert ZeroReceiver();
        }
        if (id_ == 0) {
            revert InvalidId(0);
        }

        emit IERC4626.Deposit(msg.sender, receiver_, assets_, shares_);
        emit DepositWithReceipt(
            msg.sender,
            receiver_,
            assets_,
            shares_,
            id_,
            receiptInformation_
        );
        _beforeDeposit(assets_, receiver_, shares_, id_);

        // erc20 mint.
        // Slither flags this as reentrant but this function has `nonReentrant`
        // on it from `ReentrancyGuard`.
        //slither-disable-next-line reentrancy-vulnerabilities-3 reentrancy-vulnerabilities-2
        _mint(receiver_, shares_);

        // erc1155 mint.
        // Receiving contracts MUST implement `IERC1155Receiver`.
        _receipt.ownerMint(receiver_, id_, shares_, receiptInformation_);
    }

    /// Hook for additional actions that MUST complete or revert before deposit
    /// is complete. This hook is responsible for any transfer of assets from
    /// the `msg.sender` to the receipt vault IN ADDITION to any other checks that
    /// may revert. As per 4626 the owner of the assets being deposited is always
    /// the `msg.sender`.
    /// @param assets_ Number of assets being deposited.
    /// !param receiver_ Receiver of shares that will be minted.
    /// !param shares_ Amount of shares that will be minted.
    /// !param id_ Recipt ID that will be minted for this deposit.
    function _beforeDeposit(
        uint256 assets_,
        address, // receiver_
        uint256, // shares_
        uint256 // id_
    ) internal virtual {
        // Default behaviour is to move assets before minting shares.
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets_);
    }

    /// If the sender wants to use the ERC4626 `mint` function and set a
    /// minimum share ratio they need to call `setMinShareRatio` first in a
    /// separate call.
    /// Alternatively they can use the off-spec overloaded `mint` method.
    /// @inheritdoc IERC4626
    function mint(
        uint256 shares_,
        address receiver_
    ) external returns (uint256) {
        return mint(shares_, receiver_, minShareRatios[msg.sender], "");
    }

    /// Overloaded version of IERC4626 `mint` that allows directly passing the
    /// minimum share ratio to avoid additional gas and transactions.
    /// @param shares_ As per IERC4626 `mint`.
    /// @param receiver_ As per IERC4626 `mint`.
    /// @param mintMinShareRatio_ Caller can set the minimum ratio they'll accept
    /// minting shares at, otherwise the transaction is rolled back.
    /// @param receiptInformation_ Forwarded to `receiptInformation` to
    /// optionally emit offchain context about this deposit.
    /// @return assets_ As per IERC4626 `mint`.
    function mint(
        uint256 shares_,
        address receiver_,
        uint256 mintMinShareRatio_,
        bytes memory receiptInformation_
    ) public returns (uint256) {
        uint256 id_ = _nextId();
        uint256 shareRatio_ = _shareRatio(
            msg.sender,
            receiver_,
            id_,
            ShareAction.Mint
        );

        uint256 assets_ = _calculateMint(
            shares_,
            shareRatio_,
            mintMinShareRatio_
        );
        _deposit(assets_, receiver_, shares_, id_, receiptInformation_);
        return assets_;
    }

    /// As withdrawal requires a ID the vault deposits are non fungible. This
    /// means the maximum amount of underlying asset that a user can withdraw is
    /// specific to the 1155 receipt they want to burn to handle the withdraw.
    /// A user with multiple receipts will only ever see the maxWithdraw for a
    /// single receipt. For most use cases it would be recommended to call the
    /// overloaded `maxWithdraw` that has the withdraw ID paramaterised. This
    /// can be looped over to build a view over several withdraw IDs.
    /// @inheritdoc IERC4626
    function maxWithdraw(
        address owner_
    ) external view virtual returns (uint256) {
        return maxWithdraw(owner_, withdrawIds[owner_]);
    }

    /// Overloaded `maxWithdraw` that allows passing a receipt id directly. The
    /// id needs to be provided so that we know which ERC1155 balance to
    /// check the withdraw against. The burnable ERC20 is capped per-withdraw
    /// to the balance of a ID-bound ERC1155. If a user has multiple 1155
    /// receipts they will need to call `maxWithdraw` multiple times to
    /// calculate a global withdrawal limit across all receipts.
    /// @param owner_ As per IERC4626 `maxWithdraw`.
    /// @param id_ The reference id to check the max withdrawal against
    /// for a specific receipt the owner presumably holds. Max withdrawal will
    /// be 0 if the user does not hold a receipt.
    /// @return maxAssets_ As per IERC4626 `maxWithdraw`.
    function maxWithdraw(
        address owner_,
        uint256 id_
    ) public view returns (uint256) {
        // Using `_calculateRedeem` instead of `_calculateWithdraw` becuase the
        // latter requires knowing the assets being withdrawn, which is what we
        // are attempting to reverse engineer from the owner's receipt balance.
        return
            _calculateRedeem(
                _receipt.balanceOf(owner_, id_),
                // Assume the owner is hypothetically withdrawing for themselves.
                _shareRatio(owner_, owner_, id_, ShareAction.Burn)
            );
    }

    /// Previewing withdrawal will only calculate the shares required to
    /// withdraw assets against their singular preset withdraw ID. To
    /// calculate many withdrawals for a set of recieipts it is cheaper and
    /// easier to use the overloaded version that allows IDs to be passed in
    /// as arguments.
    /// @inheritdoc IERC4626
    function previewWithdraw(uint256 assets_) external view returns (uint256) {
        return previewWithdraw(assets_, withdrawIds[msg.sender]);
    }

    /// Overloaded version of IERC4626 that allows caller to pass in the ID
    /// to preview. Multiple receipt holders will need to call this function
    /// for each recieipt ID to preview all their withdrawals.
    /// @param assets_ As per IERC4626 `previewWithdraw`.
    /// @param id_ The receipt to preview a withdrawal against.
    /// @return shares_ As per IERC4626 `previewWithdraw`.
    function previewWithdraw(
        uint256 assets_,
        uint256 id_
    ) public view virtual returns (uint256) {
        return
            _calculateWithdraw(
                assets_,
                // Assume that owner and receiver are the sender for a preview
                _shareRatio(msg.sender, msg.sender, id_, ShareAction.Burn)
            );
    }

    /// Withdraws against the current withdraw ID set by the owner.
    /// This enables spec compliant withdrawals but is additional gas and
    /// transactions for the user to set the withdraw ID in storage before
    /// each withdrawal. The overloaded `withdraw` function allows passing in a
    /// receipt ID directly, which may be cheaper and more convenient.
    /// @inheritdoc IERC4626
    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    ) external returns (uint256) {
        return withdraw(assets_, receiver_, owner_, withdrawIds[owner_], "");
    }

    /// Overloaded version of IERC4626 `withdraw` that allows the id to be
    /// passed directly.
    /// @param assets_ As per IERC4626 `withdraw`.
    /// @param receiver_ As per IERC4626 `withdraw`.
    /// @param owner_ As per IERC4626 `withdraw`.
    /// @param id_ As per `_withdraw`.
    /// @param receiptInformation_ As per `_withdraw`.
    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_,
        uint256 id_,
        bytes memory receiptInformation_
    ) public returns (uint256) {
        uint256 shares_ = _calculateWithdraw(
            assets_,
            _shareRatio(owner_, receiver_, id_, ShareAction.Burn)
        );
        _withdraw(
            assets_,
            receiver_,
            owner_,
            shares_,
            id_,
            receiptInformation_
        );
        return shares_;
    }

    /// Handles burning shares, withdrawing assets and emitting events to spec.
    /// It does NOT do any calculations so shares and assets need to be correct
    /// according to spec including rounding, in the calling context.
    /// Withdrawing reentrantly is never ok so we restrict that here in the
    /// internal function rather than on the external methods.
    /// @param assets_ As per IERC4626 `withdraw`.
    /// @param receiver_ As per IERC4626 `withdraw`.
    /// @param owner_ As per IERC4626 `withdraw`.
    /// @param shares_ Caller MUST calculate the correct shares to burn for
    /// withdrawal at `shareRatio_`. It is caller's responsibility to handle
    /// rounding correctly as per 4626 spec.
    /// @param id_ The receipt id to withdraw against. The owner MUST hold the
    /// receipt for the ID in addition to the shares being burned for
    /// withdrawal.
    /// @param receiptInformation_ New receipt information for the withdraw.
    function _withdraw(
        uint256 assets_,
        address receiver_,
        address owner_,
        uint256 shares_,
        uint256 id_,
        bytes memory receiptInformation_
    ) internal nonReentrant {
        if (assets_ == 0) {
            revert ZeroAssetsAmount();
        }
        if (shares_ == 0) {
            revert ZeroSharesAmount();
        }
        if (receiver_ == address(0)) {
            revert ZeroReceiver();
        }
        if (owner_ == address(0)) {
            revert ZeroOwner();
        }
        if (id_ == 0) {
            revert InvalidId(id_);
        }

        emit IERC4626.Withdraw(msg.sender, receiver_, owner_, assets_, shares_);
        emit WithdrawWithReceipt(
            msg.sender,
            receiver_,
            owner_,
            assets_,
            shares_,
            id_,
            receiptInformation_
        );

        // IERC4626:
        // > MUST support a withdraw flow where the shares are burned from owner
        // > directly where owner is msg.sender or msg.sender has ERC-20
        // > approval over the shares of owner.
        // Note that we do NOT require the caller has allowance over the receipt
        // in order to burn the shares to withdraw assets.
        if (owner_ != msg.sender) {
            _spendAllowance(owner_, msg.sender, shares_);
        }

        // ERC20 burn.
        _burn(owner_, shares_);

        // ERC1155 burn.
        _receipt.ownerBurn(owner_, id_, shares_, receiptInformation_);

        // Hook to allow additional withdrawal checks.
        _afterWithdraw(assets_, receiver_, owner_, shares_, id_);
    }

    function _afterWithdraw(
        uint256 assets_,
        address receiver_,
        address,
        uint256,
        uint256
    ) internal virtual {
        // Default is to send assets after burning shares.
        IERC20(asset()).safeTransfer(receiver_, assets_);
    }

    /// Max redemption is only relevant to the currently set withdraw ID for
    /// the owner. Checking a different max redemption requires the owner
    /// setting a different withdraw ID which costs gas and an additional
    /// transaction. The overloaded maxRedeem function allows the ID being
    /// checked against to be passed in directly.
    /// @inheritdoc IERC4626
    function maxRedeem(address owner_) external view returns (uint256) {
        return maxRedeem(owner_, withdrawIds[owner_]);
    }

    /// Overloaded maxRedeem function that allows the redemption ID to be
    /// passed directly. The maximum number of shares that can be redeemed is
    /// simply the balance of the associated receipt NFT the user holds for the
    /// given ID.
    /// @param owner_ As per IERC4626 `maxRedeem`.
    /// @param id_ The reference id to check the owner's 1155 balance for.
    /// @return maxShares_ As per IERC4626 `maxRedeem`.
    function maxRedeem(
        address owner_,
        uint256 id_
    ) public view returns (uint256) {
        return _receipt.balanceOf(owner_, id_);
    }

    /// Preview redeem is only relevant to the currently set withdraw ID for
    /// the caller. The overloaded previewRedeem allows the ID to be passed
    /// directly which may avoid gas costs and additional transactions.
    /// @inheritdoc IERC4626
    function previewRedeem(uint256 shares_) external view returns (uint256) {
        return _calculateRedeem(shares_, withdrawIds[msg.sender]);
    }

    /// Overloaded previewRedeem that allows ID to redeem for to be passed
    /// directly.
    /// @param shares_ As per IERC4626.
    /// @param id_ The receipt id_ to calculate redemption against.
    function previewRedeem(
        uint256 shares_,
        uint256 id_
    ) public view virtual returns (uint256) {
        return _calculateRedeem(shares_, id_);
    }

    /// Redeems with the currently set withdraw ID for the owner. The
    /// overloaded redeem function allows the ID to be passed in rather than
    /// set separately in storage.
    /// @inheritdoc IERC4626
    function redeem(
        uint256 shares_,
        address receiver_,
        address owner_
    ) external returns (uint256) {
        return redeem(shares_, receiver_, owner_, withdrawIds[owner_], "");
    }

    /// Overloaded redeem that allows the ID to redeem with to be passed in.
    /// @param shares_ As per IERC4626 `redeem`.
    /// @param receiver_ As per IERC4626 `redeem`.
    /// @param owner_ As per IERC4626 `redeem`.
    /// @param id_ The reference id to redeem against. The owner MUST hold
    /// a receipt with id_ and it will be used to calculate the share ratio.
    /// @param receiptInformation_ Associated receipt data for the redemption.
    function redeem(
        uint256 shares_,
        address receiver_,
        address owner_,
        uint256 id_,
        bytes memory receiptInformation_
    ) public returns (uint256) {
        uint256 assets_ = _calculateRedeem(
            shares_,
            _shareRatio(owner_, receiver_, id_, ShareAction.Burn)
        );
        _withdraw(
            assets_,
            receiver_,
            owner_,
            shares_,
            id_,
            receiptInformation_
        );
        return assets_;
    }

    /// @inheritdoc ERC20Snapshot
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(from_, to_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Factory} from "@rainprotocol/rain-protocol/contracts/factory/Factory.sol";
import {Receipt, ReceiptFactory} from "../receipt/ReceiptFactory.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./ReceiptVault.sol";

/// Thrown when the provided implementation is address zero.
error ZeroImplementation();

/// Thrown when the provided receipt factory is address zero.
error ZeroReceiptFactory();

/// All config required to construct the `ReceiptVaultFactory`.
/// @param implementation Template contract to clone for each child.
/// @param receiptFactory `ReceiptFactory` to produce receipts for each child.
struct ReceiptVaultFactoryConfig {
    address implementation;
    address receiptFactory;
}

/// @title ReceiptVaultFactory
/// @notice Extends `Factory` with affordances for deploying a receipt and
/// transferring ownership to a `ReceiptVault`. Marked as abstract so that
/// specific receipt vault factories can inherit this with concrete receipt vault
/// child types.
abstract contract ReceiptVaultFactory is Factory {
    /// Emitted when `ReceiptVaultFactory` is constructed with the immutable
    /// config shared for all children.
    /// @param sender `msg.sender` that constructed the factory.
    /// @param config All construction config for the `ReceiptVaultFactory`.
    event Construction(address sender, ReceiptVaultFactoryConfig config);

    /// Template contract to clone for each child.
    address public immutable implementation;
    /// Factory that produces receipts for the receipt vault.
    ReceiptFactory public immutable receiptFactory;

    /// Record the reference implementation to clone for each child and the
    /// `ReceiptFactory` to produce new receipts.
    /// @param config_ All construction config for the factory.
    constructor(ReceiptVaultFactoryConfig memory config_) {
        if (config_.implementation == address(0)) {
            revert ZeroImplementation();
        }
        if (config_.receiptFactory == address(0)) {
            revert ZeroReceiptFactory();
        }

        implementation = config_.implementation;
        receiptFactory = ReceiptFactory(config_.receiptFactory);

        // Implementation is inherited from `Factory`.
        emit Implementation(msg.sender, config_.implementation);
        emit Construction(msg.sender, config_);
    }

    /// Create the receipt for the vault and ensure ownership, then build the
    /// `ReceiptVaultConfig` from the `VaultConfig` with the new receipt merged
    /// in.
    /// @param receiptVault_ The address of the receipt vault the new receipt
    /// will be created for and owned by.
    /// @param config_ Vault config to be merged into the final
    /// `ReceiptVaultConfig`.
    /// @return The config merged with the newly created receipt.
    function _createReceipt(
        address receiptVault_,
        VaultConfig memory config_
    ) internal virtual returns (ReceiptVaultConfig memory) {
        Receipt receipt_ = Receipt(receiptFactory.createChild(""));
        receipt_.transferOwnership(receiptVault_);
        return ReceiptVaultConfig(address(receipt_), config_);
    }
}