// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "AccessControl.sol";
import "IERC20.sol";
import "EnumerableSet.sol";
import "IMissionManager.sol";
import "IRentalPool.sol";
import "IWalletFactory.sol";
import "IGamingWallet.sol";
import "NFTRental.sol";

contract MissionManager is AccessControl, IMissionManager {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    IRentalPool public rentalPool;
    IWalletFactory public walletFactory;

    mapping(string => NFTRental.Mission) public pendingMission;
    mapping(string => NFTRental.Mission) public ongoingMissions;
    EnumerableSet.Bytes32Set private terminatingMissions;
    mapping(address => string[]) public tenantOngoingMissionUuid;
    mapping(address => string[]) public tenantPendingMissionUuid;

    modifier onlyRentalPool() {
        require(
            msg.sender == address(rentalPool),
            "Only Rental Pool is authorized"
        );
        _;
    }

    constructor(address _rentalPoolAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        rentalPool = IRentalPool(_rentalPoolAddress);
    }

    function setWalletFactory(address _walletFactoryAdr)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        walletFactory = IWalletFactory(_walletFactoryAdr);
    }

    // we might want to pass mission uuid instead of gamingWallet address
    function oasisClaimForMission(
        address _gamingWallet,
        address _gameContract,
        bytes calldata data_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes memory) {
        IGamingWallet gamingWallet = IGamingWallet(_gamingWallet);
        bytes memory returnData = gamingWallet.oasisClaimForward(
            _gameContract,
            data_
        );
        return returnData;
    }

    function setMission(NFTRental.Mission memory mission)
        external
        override
        onlyRentalPool
    {
        pendingMission[mission.uuid] = mission;
        tenantPendingMissionUuid[mission.tenant].push(mission.uuid);
        emit MissionCreated(mission);
    }

    function cancelMission(string calldata _uuid) external onlyRentalPool {
        NFTRental.Mission memory curMission = pendingMission[_uuid];
        _rmPendingMissionUuid(curMission.tenant, _uuid);
        emit MissionCanceled(curMission);
    }

    function acceptMission(string calldata _uuid) external override {
        NFTRental.Mission memory missionToAccept = pendingMission[_uuid];
        require(
            !tenantHasOngoingMissionForDapp(msg.sender, missionToAccept.dappId),
            "Tenant already have ongoing mission for the dapp"
        );
        require(msg.sender == missionToAccept.tenant, "Not mission tenant");
        _createWalletIfRequired();
        address _gamingWalletAddress = walletFactory.getGamingWallet(
            msg.sender
        );
        rentalPool.sendStartingMissionNFT(
            missionToAccept.uuid,
            _gamingWalletAddress
        );
        tenantOngoingMissionUuid[msg.sender].push(_uuid);
        ongoingMissions[missionToAccept.uuid] = missionToAccept;
        _rmPendingMissionUuid(msg.sender, _uuid);
        delete pendingMission[missionToAccept.uuid];
        emit MissionStarted(missionToAccept);
    }

    function ownerTerminatingMission(string calldata _uuid) external override {
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        address missionOwner = curMission.owner;
        require(msg.sender == missionOwner, "Not the mission owner");
        terminatingMissions.add(keccak256(abi.encode(_uuid)));
        emit MissionTerminating(curMission);
        // Oasis retrieve event (or go through isMissionTerminating view function)
        // then claim + rewardShare, finaly execute oasisTerminateMission if no reward anymore
    }

    function oasisTerminateMission(string calldata _uuid)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(isTerminatingFunction(_uuid), "Mission is not terminating");
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        address tenant = curMission.tenant;
        address gamingWalletAddress = walletFactory.getGamingWallet(tenant);
        IGamingWallet(gamingWalletAddress).bulkReturnAsset(
            curMission.owner,
            curMission.collections,
            curMission.tokenIds
        );
        _rmMissionUuid(tenant, _uuid);
        emit MissionTerminated(curMission);
    }

    function getOngoingMission(string calldata _uuid)
        external
        view
        override
        returns (NFTRental.Mission memory mission)
    {
        return ongoingMissions[_uuid];
    }

    function getPendingMission(string calldata _uuid)
        external
        view
        override
        returns (NFTRental.Mission memory mission)
    {
        return pendingMission[_uuid];
    }

    function getMissionStatus(string calldata _uuid)
        public
        view
        override
        returns (string memory missionStatus)
    {
        if (pendingMission[_uuid].owner != address(0)) {
            return "pending";
        } else if (ongoingMissions[_uuid].owner != address(0)) {
            if (terminatingMissions.contains(keccak256(abi.encode(_uuid)))) {
                return "terminating";
            } else {
                return "ongoing";
            }
        } else if (IRentalPool(rentalPool).isUuidUsed(_uuid)) {
            return "done";
        } else {
            return "nonExisting";
        }
    }

    function getBatchMissionStatuses(string[] calldata _uuids)
        public
        view
        override
        returns (string[] memory missionStatus)
    {
        uint256 length = _uuids.length;
        string[] memory statuses = new string[](length);
        for (uint256 i; i < length; i++) {
            statuses[i] = getMissionStatus(_uuids[i]);
        }
        return statuses;
    }

    function getTenantOngoingMissionUuid(address _tenant)
        public
        view
        override
        returns (string[] memory ongoingMissionsUuids)
    {
        return tenantOngoingMissionUuid[_tenant];
    }

    function getTenantPendingMissionUuid(address _tenant)
        public
        view
        override
        returns (string[] memory pendingMissionsUuids)
    {
        return tenantPendingMissionUuid[_tenant];
    }

    function retrieveTenantOngoingMissions(address _tenant)
        public
        view
        override
        returns (NFTRental.Mission[] memory tenantOngoingMission)
    {
        string[] memory tenantOngoingMissionsUuid = getTenantOngoingMissionUuid(
            _tenant
        );
        NFTRental.Mission[]
            memory tenantOngoingMissions = new NFTRental.Mission[](
                tenantOngoingMissionsUuid.length
            );
        for (uint256 i; i < tenantOngoingMissionsUuid.length; i++) {
            tenantOngoingMissions[i] = ongoingMissions[
                tenantOngoingMissionsUuid[i]
            ];
        }
        return tenantOngoingMissions;
    }

    function retrieveTenantPendingMissions(address _tenant)
        public
        view
        override
        returns (NFTRental.Mission[] memory pendingMissions)
    {
        string[] memory tenantPendingMissionsUuid = getTenantPendingMissionUuid(
            _tenant
        );
        NFTRental.Mission[]
            memory tenantPendingMissions = new NFTRental.Mission[](
                tenantPendingMissionsUuid.length
            );
        for (uint256 i; i < tenantPendingMissionsUuid.length; i++) {
            tenantPendingMissions[i] = pendingMission[
                tenantPendingMissionsUuid[i]
            ];
        }
        return tenantPendingMissions;
    }

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) public view override returns (bool hasMissionForDapp) {
        string[] memory tenantMissionsUuid = getTenantOngoingMissionUuid(
            _tenant
        );
        for (uint32 i; i < tenantMissionsUuid.length; i++) {
            NFTRental.Mission memory curMission = ongoingMissions[
                tenantMissionsUuid[i]
            ];
            if (
                keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))
            ) {
                return true;
            }
        }
        return false;
    }

    function isTerminatingFunction(string calldata _uuid)
        public
        view
        override
        returns (bool)
    {
        return terminatingMissions.contains(keccak256(abi.encode(_uuid)));
    }

    function getTenantPendingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) public view override returns (uint256 uuidPosition) {
        string[] memory list = tenantPendingMissionUuid[_tenant];
        for (uint32 i; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
                return i;
            }
        }
        return list.length + 1;
    }

    function getTenantMissionUuidIndex(address _tenant, string calldata _uuid)
        public
        view
        override
        returns (uint256 uuidPosition)
    {
        string[] memory list = tenantOngoingMissionUuid[_tenant];
        for (uint32 i; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
                return i;
            }
        }
        return list.length + 1;
    }

    function _createWalletIfRequired() internal {
        if (!walletFactory.hasGamingWallet(msg.sender)) {
            walletFactory.createWallet(msg.sender);
        }
    }

    function _rmMissionUuid(address _tenant, string calldata _uuid) internal {
        uint256 index = getTenantMissionUuidIndex(_tenant, _uuid);
        uint256 ongoingMissionLength = tenantOngoingMissionUuid[_tenant].length;
        tenantOngoingMissionUuid[_tenant][index] = tenantOngoingMissionUuid[
            _tenant
        ][ongoingMissionLength - 1];
        tenantOngoingMissionUuid[_tenant].pop();
        delete ongoingMissions[_uuid];
        terminatingMissions.remove(keccak256(abi.encode(_uuid)));
    }

    function _rmPendingMissionUuid(address _tenant, string calldata _uuid)
        internal
    {
        uint256 index = getTenantPendingMissionUuidIndex(_tenant, _uuid);
        uint256 pendingMissionLength = tenantPendingMissionUuid[_tenant].length;
        tenantPendingMissionUuid[_tenant][index] = tenantPendingMissionUuid[
            _tenant
        ][pendingMissionLength - 1];
        tenantPendingMissionUuid[_tenant].pop();
        delete pendingMission[_uuid];
    }

    function _requireStakedNFT(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal view {
        for (uint32 j = 0; j < _tokenIds.length; j++) {
            for (uint32 k = 0; k < _tokenIds[j].length; k++) {
                require(
                    rentalPool.isNFTStaked(
                        _collections[j],
                        msg.sender,
                        _tokenIds[j][k]
                    ) == true,
                    "NFT is not staked"
                );
            }
        }
    }

    function _verifyParam(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal pure {
        require(
            _collections.length == _tokenIds.length,
            "Incorrect lengths in tokenIds and collections"
        );
        require(_tokenIds[0][0] != 0, "At least one NFT required");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSet {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Management contract for NFT rentals.
// This mostly stores rental agreements and does the transfer with the wallet contracts
interface IMissionManager {
    event MissionCreated(NFTRental.Mission mission);

    event MissionCanceled(NFTRental.Mission mission);

    event MissionStarted(NFTRental.Mission mission);

    event MissionTerminating(NFTRental.Mission mission);

    event MissionTerminated(NFTRental.Mission mission);

    function setWalletFactory(address _walletFactoryAdr) external;

    function oasisClaimForMission(
        address gamingWallet,
        address gameContract,
        bytes calldata data_
    ) external returns (bytes memory);

    function setMission(NFTRental.Mission memory mission) external;

    function cancelMission(string memory _uuid) external;

    function acceptMission(string calldata _uuid) external;

    function ownerTerminatingMission(string calldata _uuid) external;

    function oasisTerminateMission(string calldata _uuid) external;

    function getOngoingMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission calldata mission);

    function getPendingMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission memory mission);

    function getMissionStatus(string calldata _uuid)
        external
        view
        returns (string memory missionStatus);

    function getBatchMissionStatuses(string[] calldata _uuids)
        external
        view
        returns (string[] memory missionStatus);

    function getTenantOngoingMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function getTenantPendingMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function isTerminatingFunction(string calldata _uuid)
        external
        view
        returns (bool);

    function retrieveTenantPendingMissions(address _tenant)
        external
        view
        returns (NFTRental.Mission[] memory pendingMissions);

    function retrieveTenantOngoingMissions(address _tenant)
        external
        view
        returns (NFTRental.Mission[] memory ongoingMissions);

    function getTenantPendingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function getTenantMissionUuidIndex(address _tenant, string calldata _uuid)
        external
        view
        returns (uint256 uuidPosition);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

library NFTRental {
    struct Mission {
        string uuid;
        string dappId;
        address owner;
        address tenant;
        address[] collections;
        uint256[][] tokenIds;
        uint256 tenantShare;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Pool to hold the staked NFTs of one collection that are not currently rented out
interface IRentalPool {
    event NFTStaked(address collection, address owner, uint256 tokenId);

    event NFTUnstaked(address collection, address owner, uint256 tokenId);

    function setMissionManager(address _rentalManager) external;

    function setWalletFactory(address _walletFactory) external;

    function whitelistOwner(address _owner) external;

    function whitelistMultipleOwners(address[] calldata _owners) external;

    function removeWhitelistedOwner(address _owner) external;

    function createMission(NFTRental.Mission calldata newMission) external;

    function createMultipleMissions(NFTRental.Mission[] calldata newMission)
        external;

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external;

    function cancelPendingMission(string calldata _uuid) external;

    function batchCancelPendingMission(string[] calldata _uuid) external;

    function isNFTStaked(
        address collection,
        address owner,
        uint256 tokenId
    ) external view returns (bool isStaked);

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted);

    function isUuidUsed(string calldata uuid)
        external
        view
        returns (bool isUsed);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// Factory to create gaming wallets
interface IWalletFactory {
    event WalletCreated(address owner, address walletAddress);

    function createWallet() external;

    function createWallet(address _owner) external;

    function resetTenantGamingWallet(address _tenant) external;

    function changeRentalPoolAddress(address _rentalPool) external;

    function changeProxyRegistryAddress(address _proxyRegistry) external;

    function addCollectionForDapp(string calldata _dappId, address _collection)
        external;

    function removeCollectionForDapp(
        string calldata _dappId,
        address _collection
    ) external;

    function verifyCollectionForUniqueDapp(
        string calldata _dappId,
        address[] calldata _collections
    ) external view returns (bool uniqueDapp);

    function getGamingWallet(address owner)
        external
        view
        returns (address gamingWalletAddress);

    function hasGamingWallet(address owner)
        external
        view
        returns (bool hasWallet);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

// Generic wallet contract to interact with GamingProxies
// TODO: Implement EIP 1271 to get isValidSignature function for games
interface IGamingWallet {
    event NFTDeposited(address collection, uint256 tokenID);
    event NFTWithdrawn(address collection, uint256 tokenID);
    event NFTReturned(address collection, uint256 tokenID);

    // Functions to interact with the RentalPool for borrowing
    function returnAsset(
        address returnAddress,
        address _collection,
        uint256 _tokenID
    ) external;

    function bulkReturnAsset(
        address returnAddress,
        address[] calldata _collection,
        uint256[][] calldata _tokenID
    ) external;

    // Functions to allow users to deposit own assets
    function depositAsset(address collection, uint256 id) external;

    function withdrawAsset(address collection, uint256 id) external;

    // Generic functions to run delegatecalls with the game proxies
    function forwardCall(address gameContract, bytes calldata data_)
        external
        returns (bytes memory);

    function oasisClaimForward(address gameContract, bytes calldata data_)
        external
        returns (bytes memory);

    function oasisDistributeERC20Rewards(
        address _rewardToken,
        address _rewardReceiver,
        uint256 _rewardAmount
    ) external;

    function oasisDistributeERC721Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId
    ) external;

    function oasisDistributeERC1155Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);

    // Will be overridden to return the owner of the wallet
    function owner() external view returns (address);

    function revenueManager() external view returns (address);
}