// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IAmpliFrensContribution} from "./interfaces/IAmpliFrensContribution.sol";
import {IAmpliFrensProfile} from "./interfaces/IAmpliFrensProfile.sol";
import {IAmpliFrensNFT} from "./interfaces/IAmpliFrensNFT.sol";
import {IAmpliFrensSBT} from "./interfaces/IAmpliFrensSBT.sol";
import {IAmpliFrensFacade} from "./interfaces/IAmpliFrensFacade.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";

/**
 * @title AmpliFrensFacade
 * @author Lucien Akchoté
 *
 * @notice Serves as the main entrypoint for the AmpliFrens project
 *
 * @dev Must be covered by a proxy contract as it is upgradeable
 */
contract AmpliFrensFacade is Initializable, PausableUpgradeable, AccessControlUpgradeable, IERC165, IAmpliFrensFacade {
    IAmpliFrensContribution internal immutable _contribution;
    IAmpliFrensProfile internal immutable _profile;
    IAmpliFrensNFT internal immutable _nft;
    IAmpliFrensSBT internal immutable _sbt;

    constructor(
        IAmpliFrensContribution contribution,
        IAmpliFrensProfile profile,
        IAmpliFrensNFT nft,
        IAmpliFrensSBT sbt
    ) {
        _contribution = contribution;
        _profile = profile;
        _nft = nft;
        _sbt = sbt;
    }

    function initialize(address adminAddress) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    /// @inheritdoc IAmpliFrensFacade
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory) {
        return (_sbt.isMintingIntervalMet(), "");
    }

    /// @inheritdoc IAmpliFrensFacade
    function performUpkeep(bytes calldata) external whenNotPaused {
        _sbt.mint(_contribution.topContribution());
    }

    /// @inheritdoc IAmpliFrensFacade
    function setSBTBaseURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _sbt.setBaseURI(uri);
    }

    /// @inheritdoc IAmpliFrensFacade
    function createUserProfile(DataTypes.Profile calldata profile) external whenNotPaused {
        _profile.createProfile(profile);
    }

    /// @inheritdoc IAmpliFrensFacade
    function updateUserProfile(DataTypes.Profile calldata profile) external whenNotPaused {
        _profile.updateProfile(profile);
    }

    /// @inheritdoc IAmpliFrensFacade
    function deleteUserProfile(address _address) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _profile.deleteProfile(_address);
    }

    /// @inheritdoc IAmpliFrensFacade
    function blacklistUserProfile(address _address, bytes32 reason)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        _profile.blacklist(_address, reason);
    }

    /// @inheritdoc IAmpliFrensFacade
    function upvoteContribution(uint256 contributionId) external whenNotPaused {
        _contribution.upvote(contributionId);
    }

    /// @inheritdoc IAmpliFrensFacade
    function downvoteContribution(uint256 contributionId) external whenNotPaused {
        _contribution.downvote(contributionId);
    }

    /// @inheritdoc IAmpliFrensFacade
    function removeContribution(uint256 contributionId) external whenNotPaused {
        _contribution.remove(contributionId);
    }

    /// @inheritdoc IAmpliFrensFacade
    function updateContribution(uint256 contributionId, DataTypes.Contribution calldata contribution)
        external
        whenNotPaused
    {
        _contribution.update(contributionId, contribution.category, contribution.title, contribution.url);
    }

    /// @inheritdoc IAmpliFrensFacade
    function createContribution(DataTypes.Contribution calldata contribution) external whenNotPaused {
        _contribution.create(contribution.category, contribution.title, contribution.url);
    }

    /// @inheritdoc IAmpliFrensFacade
    function resetContributions() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _contribution.reset();
    }

    /// @inheritdoc IAmpliFrensFacade
    function mintNFT(address to, string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _nft.mint(to, uri);
    }

    /// @inheritdoc IAmpliFrensFacade
    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _nft.transferNFT(from, to, tokenId);
    }

    /// @inheritdoc IAmpliFrensFacade
    function setNFTBaseURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _nft.setBaseURI(uri);
    }

    /// @inheritdoc IAmpliFrensFacade
    function setNFTGlobalRoyalties(address receiver, uint96 feeNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        _nft.setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @inheritdoc IAmpliFrensFacade
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc IAmpliFrensFacade
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc IAmpliFrensFacade
    function uriSBT(uint256 id) external view returns (string memory) {
        return _sbt.tokenURI(id);
    }

    /// @inheritdoc IAmpliFrensFacade
    function getUserProfile(address _address) external view returns (DataTypes.Profile memory) {
        return _profile.getProfile(_address);
    }

    /// @inheritdoc IAmpliFrensFacade
    function getContribution(uint256 contributionId) external view returns (DataTypes.Contribution memory) {
        return _contribution.getContribution(contributionId);
    }

    /// @inheritdoc IAmpliFrensFacade
    function uriNft(uint256 id) external view returns (string memory) {
        return _nft.tokenURI(id);
    }

    /// @inheritdoc IAmpliFrensFacade
    function balanceOfSBT(address _address) external view returns (uint256) {
        return _sbt.balanceOf(_address);
    }

    /// @inheritdoc IAmpliFrensFacade
    function ownerOfSBT(uint256 token) external view returns (address) {
        return _sbt.ownerOf(token);
    }

    /// @inheritdoc IAmpliFrensFacade
    function idSBTOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        return _sbt.tokenOfOwnerByIndex(owner, index);
    }

    /// @inheritdoc IAmpliFrensFacade
    function getSBTById(uint256 id) external view returns (DataTypes.Contribution memory) {
        return _sbt.tokenById(id);
    }

    /// @inheritdoc IAmpliFrensFacade
    function totalSBTs() external view returns (uint256) {
        return _sbt.emittedCount();
    }

    /// @inheritdoc IAmpliFrensFacade
    function totalSBTHolders() external view returns (uint256) {
        return _sbt.holdersCount();
    }

    /// @inheritdoc IAmpliFrensFacade
    function getProfileBlacklistReason(address _address) external view returns (bytes32) {
        return _profile.getBlacklistReason(_address);
    }

    /// @inheritdoc IAmpliFrensFacade
    function hasUserProfile(address _address) external view returns (bool) {
        return _profile.hasProfile(_address);
    }

    /// @inheritdoc IAmpliFrensFacade
    function getContributions() external view returns (DataTypes.Contribution[] memory) {
        return _contribution.getContributions();
    }

    /// @inheritdoc IAmpliFrensFacade
    function topContribution() external view returns (DataTypes.Contribution memory) {
        return _contribution.topContribution();
    }

    /// @inheritdoc IAmpliFrensFacade
    function totalContributions() external view returns (uint256) {
        return _contribution.contributionsCount();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(AccessControlUpgradeable, IERC165)
        returns (bool)
    {
        return
            type(IAmpliFrensFacade).interfaceId == interfaceId ||
            type(IERC165).interfaceId == interfaceId ||
            type(IAccessControlUpgradeable).interfaceId == interfaceId;
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensContribution
 * @author Lucien Akchoté
 *
 * @notice Handles the day to day operations for interacting with contributions
 */
interface IAmpliFrensContribution {
    /// @dev Events related to contributions interaction
    event Upvoted(address indexed from, uint256 indexed contributionId, uint256 timestamp);
    event Downvoted(address indexed from, uint256 indexed contributionId, uint256 timestamp);
    event Updated(address indexed from, uint256 indexed contributionId, uint256 timestamp);

    /**
     * @notice Upvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution to upvote
     */
    function upvote(uint256 contributionId) external;

    /**
     * @notice Downvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to downvote
     */
    function downvote(uint256 contributionId) external;

    /**
     * @notice Remove the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to delete
     */
    function remove(uint256 contributionId) external;

    /**
     * @notice Update the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to update
     * @param category The contribution's updated category
     * @param title The contribution's updated title
     * @param url The contribution's updated url
     */
    function update(
        uint256 contributionId,
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url
    ) external;

    /**
     * @notice Create a contribution
     *
     * @param category The contribution's category
     * @param title The contribution's title
     * @param url The contribution's url
     */
    function create(
        DataTypes.ContributionCategory category,
        bytes32 title,
        string calldata url
    ) external;

    /// @notice Reset the contributions
    function reset() external;

    /**
     * @notice Get the total contributions
     *
     * @return Total contributions of type `DataTypes.Contribution`
     */
    function getContributions() external view returns (DataTypes.Contribution[] memory);

    /**
     * @notice Get the contribution with id `contributionId`
     *
     * @param contributionId The id of the contribution to retrieve
     * @return Contribution with id `contributionId` of type `DataTypes.Contribution`
     */
    function getContribution(uint256 contributionId) external view returns (DataTypes.Contribution memory);

    /**
     * @notice Get the most upvoted contribution
     *
     * @return `DataTypes.Contribution`
     */
    function topContribution() external view returns (DataTypes.Contribution memory);

    /**
     * @notice Return the total number of contributions
     *
     * @return Number of contributions
     */
    function contributionsCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensProfile
 * @author Lucien Akchoté
 *
 * @notice Handles the common use cases for interacting with profiles
 */
interface IAmpliFrensProfile {
    /**
     * @notice Event that is emitted when a profile is blacklisted
     *
     * @param _address The profile's address blacklisted
     * @param reason   The reason of the blacklist
     * @param timestamp The time when blacklisting occured
     */
    event ProfileBlacklisted(address indexed _address, bytes32 indexed reason, uint256 timestamp);

    /**
     * @notice Event that is emitted when a profile is created
     *
     * @param _address The profile's address created
     * @param timestamp The time when profile creation occurred
     */
    event ProfileCreated(address indexed _address, uint256 timestamp);

    /**
     * @notice Event that is emitted when a profile is updated
     *
     * @param _address The profile's address updated
     * @param timestamp The time when profile update occurred
     */
    event ProfileUpdated(address indexed _address, uint256 timestamp);

    /**
     * @notice Event that is emitted when a profile is deleted
     *
     * @param _address The profile's address deleted
     */
    event ProfileDeleted(address indexed _address, uint256 timestamp);

    /**
     * @notice Create a profile for address `msg.sender`
     *
     * @param profile `DataTypes.Profile` containing the profile data
     */
    function createProfile(DataTypes.Profile calldata profile) external;

    /**
     * @notice Update a profile for address `msg.sender`
     *
     * @param profile `DataTypes.Profile` containing the profile data
     */
    function updateProfile(DataTypes.Profile calldata profile) external;

    /**
     * @notice Delete the profile of address `_address`
     *
     * @param _address The address's profile to delete
     */
    function deleteProfile(address _address) external;

    /**
     * @notice Get a profile if applicable for address `_address`
     *
     * @return `DataTypes.Profile` data
     */
    function getProfile(address _address) external view returns (DataTypes.Profile memory);

    /**
     * @notice Blacklist a profile with address `_address` for reason `reason`
     *
     * @param _address The profile's address to blacklist
     * @param reason The reason of the blacklist
     */
    function blacklist(address _address, bytes32 reason) external;

    /**
     * @notice Get the blacklist reason for address `_address`
     *
     * @param _address The profile's address to query
     * @return The reason of the blacklist
     */
    function getBlacklistReason(address _address) external view returns (bytes32);

    /**
     * @notice Get a profile by its username `username`
     *
     * @return `DataTypes.Profile` containing the profile data
     */
    function getProfileByUsername(bytes32 username) external view returns (DataTypes.Profile memory);

    /**
     * @notice Check if address `_address` has a profile
     *
     * @return True or false
     */
    function hasProfile(address _address) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title IAmpliFrensNFT
 * @author Lucien Akchoté
 *
 * @notice Handles specific functions to add over the IERC721 and IERC721Metadata interfaces
 */
interface IAmpliFrensNFT is IERC721, IERC721Metadata {
    /**
     * @notice Mint an NFT for address `to`
     *
     * @param to The address to mint the NFT
     * @param uri The URI of the NFT
     */
    function mint(address to, string memory uri) external;

    /**
     * @notice Transfer an NFT from address `from` to address `to`
     *
     * @param from The current owner's address for the NFT
     * @param to The new owner's address for the NFT
     * @param tokenId The token id to transfer
     */
    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Set the default royalty for entire NFT collection
     *
     * @dev Warning : not enforceable, it depends on the exchange policies where NFTs are traded
     *
     * @param receiver The address to receive royalty fees
     * @param feeNumerator The royalty fee
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /**
     * @notice Set the base URI `uri` for tokens, it should end with a "/"
     *
     * @param uri The base URI
     */
    function setBaseURI(string calldata uri) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensSBT
 * @author Lucien Akchoté
 *
 * @notice Base interface for EIP-4671 Metadata
 *
 * More details on https://eips.ethereum.org/EIPS/eip-4671
 */
interface IAmpliFrensSBT {
    /**
     *  @notice Event emitted when a token `tokenId` is minted for `owner`
     */
    event Minted(address indexed owner, uint256 indexed tokenId, uint256 timestamp);

    /**
     *  @notice Event emitted when token `tokenId` of `owner` is revoked
     */
    event Revoked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);

    /**
     * @notice Mints the Soulbound Token to recipient `DataTypes.Contribution.author`
     *
     * @param contribution Contribution of the day data contained in struct `DataTypes.Contribution`
     */
    function mint(DataTypes.Contribution calldata contribution) external;

    /**
     * @notice Revoke the token id `tokenId` in case of abuse or error
     *
     * @param tokenId The token ID to revoke
     */
    function revoke(uint256 tokenId) external;

    /**
     * @notice Count all valid tokens assigned to an owner
     *
     * @param owner Address for whom to query the balance
     * @return Number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Check if minting interval has been met
     *
     * @return True or false
     */
    function isMintingIntervalMet() external view returns (bool);

    /**
     * @notice Get the owner of the token with id `tokenId`
     *
     * @param tokenId Identifier of the token
     * @return Address of the owner of `tokenId`
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Check if the token with id `tokenId` hasn't been revoked
     *
     * @param tokenId Identifier of the token
     * @return True if the token is valid, false otherwise
     */
    function isValid(uint256 tokenId) external view returns (bool);

    /**
     * @notice Check if an address owns a valid token in the contract
     *
     * @param owner Address for whom to check the ownership
     * @return True if `owner` has a valid token, false otherwise
     */
    function hasValid(address owner) external view returns (bool);

    /// @return emittedCount Number of tokens emitted
    function emittedCount() external view returns (uint256);

    /// @return holdersCount Number of token holders
    function holdersCount() external view returns (uint256);

    /**
     * @notice Get the id of a token using its position in the owner's list
     *
     * @param owner Address for whom to get the token
     * @param index Index of the token
     * @return tokenId of the token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @notice Get the contribution associated with token of id `id`
     *
     * @param id The token id
     * @return Contribution of type `DataTypes.Contribution`
     */
    function tokenById(uint256 id) external view returns (DataTypes.Contribution memory);

    /**
     * @notice Get a tokenId by it's index, where 0 <= index < total()
     *
     * @param index Index of the token
     * @return tokenId of the token
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /// @return Descriptive name of the tokens in this contract
    function name() external view returns (string memory);

    /// @return An abbreviated name of the tokens in this contract
    function symbol() external view returns (string memory);

    /**
     * @notice URI to query to get the token's metadata
     *
     * @param tokenId Identifier of the token
     * @return URI for the token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Get the contribution status for address `_address`
     *
     * @param _address The address to retrieve contribution status
     */
    function getStatus(address _address) external view returns (DataTypes.FrenStatus);

    /**
     * @notice Set the base URI `uri` for tokens, it should end with a "/"
     *
     * @param uri The base URI
     */
    function setBaseURI(string calldata uri) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensHub
 * @author Lucien Akchoté
 *
 * @notice Interface for the main entrypoint of the contract
 */
interface IAmpliFrensFacade {
    /**
     * //////////////////////////////////////////////////
     * @dev Start of Keeper (cron-like) related functions
     * //////////////////////////////////////////////////
     *
     *  @notice Check if automated minting of soulbound tokens
     *  for the contribution of the day needs to be done
     *
     *  @dev Used by Chainlink Keeper to know if keeper needs to be triggered
     *
     *  @param checkData bytes that will be used as input parameter
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Perform the automated minting of soulbound tokens
     * for the contribution of the day
     *
     * @dev Used by Chainlink Keeper to perform cron logic
     * (in our case: automated minting of soulbound tokens)
     *
     * @param performData bytes that will be used as input parameter
     */
    function performUpkeep(bytes calldata performData) external;

    /**
     * /////////////////////////////////////////////////////
     * @dev Start of Soulbound token (SBT) related functions
     * /////////////////////////////////////////////////////
     *
     * @notice Set the Soulbound token base URI
     *
     * @param uri The new base uri for the Soulbound tokens
     */
    function setSBTBaseURI(string calldata uri) external;

    /**
     * @notice Get the contribution associated with token of id `id`
     *
     * @param id The token id
     * @return Contribution of type `DataTypes.Contribution`
     */
    function getSBTById(uint256 id) external view returns (DataTypes.Contribution memory);

    /// @return emittedCount Number of soulbound tokens emitted
    function totalSBTs() external view returns (uint256);

    /// @return holdersCount Number of token holders
    function totalSBTHolders() external view returns (uint256);

    /**
     * @notice Get the URI of Soulbound token with id `id`
     *
     * @param id The id of the Soulbound token to query URI for
     *
     * @return The NFT's URI
     */
    function uriSBT(uint256 id) external view returns (string memory);

    /**
     * @notice Count all valid soulbound tokens assigned to an owner
     *
     * @param _address Address for whom to query the balance
     * @return Number of tokens owned by `owner`
     */
    function balanceOfSBT(address _address) external view returns (uint256);

    /**
     * @notice Get the owner of a soulbound oken
     *
     * @param token Identifier of the token
     * @return Address of the owner of `tokenId`
     */
    function ownerOfSBT(uint256 token) external view returns (address);

    /**
     * @notice Get the id of a token with the index `index` in the owner's list
     *
     * @param owner Address for whom to get the token
     * @param index Index of the token
     * @return tokenId of the token
     */
    function idSBTOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * ///////////////////////////////////////
     * @dev Start of profile related functions
     * ///////////////////////////////////////
     *
     * @notice Create a profile for address `msg.sender`
     *
     * @param profile `DataTypes.Profile` containing the profile data
     */
    function createUserProfile(DataTypes.Profile calldata profile) external;

    /**
     * @notice Update the profile of address `msg.sender`
     *
     * @param profile `DataTypes.Profile` containing the profile data
     */
    function updateUserProfile(DataTypes.Profile calldata profile) external;

    /**
     * @notice Delete the profile of address `_address`
     *
     * @param _address The address's profile to delete
     */
    function deleteUserProfile(address _address) external;

    /**
     * @notice Blacklist a profile with address `_address`
     *
     * @param _address The profile's address to blacklist
     * @param reason The reason of the blacklist
     */
    function blacklistUserProfile(address _address, bytes32 reason) external;

    /**
     * @notice Get the profile if applicable for address `_address`
     *
     * @return `DataTypes.Profile` data
     */
    function getUserProfile(address _address) external view returns (DataTypes.Profile memory);

    /**
     * @notice Get the blacklist reason for address `_address`
     *
     * @param _address The profile's address to query
     * @return The reason of the blacklist
     */
    function getProfileBlacklistReason(address _address) external view returns (bytes32);

    /**
     * @notice Check if address `_address` has a profile
     *
     * @return True or false
     */
    function hasUserProfile(address _address) external view returns (bool);

    /**
     * ////////////////////////////////////////////
     * @dev Start of contribution related functions
     * ////////////////////////////////////////////
     *
     * @notice Upvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution to upvote
     */
    function upvoteContribution(uint256 contributionId) external;

    /**
     * @notice Downvote the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to downvote
     */
    function downvoteContribution(uint256 contributionId) external;

    /**
     * @notice Post the contribution with id `contributionId`
     *
     * @param contribution Contribution containing data of type `DataTypes.Contribution`
     */
    function createContribution(DataTypes.Contribution calldata contribution) external;

    /**
     * @notice Remove the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to upvote
     */
    function removeContribution(uint256 contributionId) external;

    /**
     * @notice Update the contribution with id `contributionId`
     *
     * @param contributionId The contribution id to update
     * @param contribution The updated contribution data
     */
    function updateContribution(uint256 contributionId, DataTypes.Contribution calldata contribution) external;

    /// @notice Reset the contributions
    function resetContributions() external;

    /**
     * @notice Get the total contributions
     *
     * @return Total contributions of type `DataTypes.Contribution`
     */
    function getContributions() external view returns (DataTypes.Contribution[] memory);

    /**
     * @notice Get the contribution with id `contributionId`
     *
     * @param contributionId The id of the contribution to retrieve
     * @return Contribution with id `contributionId` of type `DataTypes.Contribution`
     */
    function getContribution(uint256 contributionId) external view returns (DataTypes.Contribution memory);

    /**
     * @notice Get today's most upvoted contribution
     *
     * @return `DataTypes.Contribution`
     */
    function topContribution() external view returns (DataTypes.Contribution memory);

    /**
     * @notice Return the total number of contributions
     *
     * @return Number of contributions
     */
    function totalContributions() external view returns (uint256);

    /**
     * ///////////////////////////////////
     * @dev Start of NFT related functions
     * ///////////////////////////////////
     *
     * @notice Mint an NFT for address `to`
     *
     * @param to The address to mint the NFT
     * @param uri The URI of the NFT
     */
    function mintNFT(address to, string memory uri) external;

    /**
     * @notice Transfer the NFT with id `tokenId` from address `from` to address `to`
     */
    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Set the NFT base URI
     *
     * @param uri The new base uri for the NFTs
     */
    function setNFTBaseURI(string calldata uri) external;

    /**
     * @notice Set the default royalty for entire NFT collection
     *
     * @dev Warning : not enforceable, it depends on the exchange policies where NFTs are traded
     *
     * @param receiver The address to receive royalty fees
     * @param feeNumerator The royalty fee
     */
    function setNFTGlobalRoyalties(address receiver, uint96 feeNumerator) external;

    /**
     * @notice Get the URI of NFT with id `id`
     *
     * @param id The id of the NFT to get the URI for
     *
     * @return The NFT's URI
     */
    function uriNft(uint256 id) external view returns (string memory);

    /**
     * //////////////////////////////////////////////////
     * @dev Start of contract lifecycle related functions
     * //////////////////////////////////////////////////
     *
     *  @notice Pause critical functions
     */
    function pause() external;

    /**
     *  @notice Perform the automated minting of soulbound tokens for the contribution of the day
     */
    function unpause() external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title DataTypes
 * @author Lucien Akchoté
 *
 * @notice A standard library of data types used throughout AmpliFrens
 */
library DataTypes {
    /// @notice Contain the different statuses depending on tokens earnt
    enum FrenStatus {
        Anon,
        Degen,
        Pepe,
        Contributoor,
        Aggregatoor,
        Oracle
    }

    /// @notice Contain the different contributions categories
    enum ContributionCategory {
        NFT,
        Article,
        DeFi,
        Security,
        Thread,
        GameFi,
        Video,
        Misc
    }

    /**
     *  @notice Contain the basic information of a contribution
     *
     *  @dev Use tight packing to save up on storage cost
     *  4 storage slots used (string takes up 64 bytes or 2 slots in the storage)
     */
    struct Contribution {
        address author; /// @dev 20 bytes
        ContributionCategory category; /// @dev 1 byte
        bool valid; /// @dev 1 byte
        uint64 timestamp; /// @dev 8 bytes
        int16 votes; /// @dev 2 bytes
        bytes32 title; /// @dev 32 bytes
        string url; /// @dev 64 bytes
    }

    /// @notice Contain the basic information of a profile
    struct Profile {
        bytes32 lensHandle;
        bytes32 discordHandle;
        bytes32 twitterHandle;
        bytes32 username;
        bytes32 email;
        string websiteUrl;
        bool valid;
    }

    /// @notice These time-related variables are used in conjunction to determine when minting function can be called
    struct MintingInterval {
        uint256 lastBlockTimestamp;
        uint256 mintInterval;
    }

    /// @notice Contain contributions data
    struct Contributions {
        mapping(uint256 => DataTypes.Contribution) contribution;
        mapping(uint256 => mapping(address => bool)) upvoted;
        mapping(uint256 => mapping(address => bool)) downvoted;
        address[] upvoterAddresses;
        address[] downvoterAddresses;
        uint256[] upvotedIds;
        uint256[] downvotedIds;
        address adminAddress;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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