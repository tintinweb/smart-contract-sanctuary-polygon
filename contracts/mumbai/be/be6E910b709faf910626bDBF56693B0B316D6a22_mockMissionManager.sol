// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "AccessControl.sol";
import "IMissionManager.sol";
import "IRentalPool.sol";
import "IWalletFactory.sol";
import "IGamingWallet.sol";
import "NFTRental.sol";

contract mockMissionManager is IMissionManager, AccessControl {
  IRentalPool public rentalPool;
  IWalletFactory public walletFactory;

  mapping(string => NFTRental.Mission) public readyMissions;
  mapping(string => NFTRental.Mission) public ongoingMissions;
  mapping(string => NFTRental.MissionDates) public missionDates;
  mapping(address => string[]) public tenantOngoingMissionUuid;
  mapping(address => string[]) public tenantReadyMissionUuid;

  modifier onlyRentalPool() {
    require(
      msg.sender == address(rentalPool),
      'Only Rental Pool is authorized'
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
    readyMissions[mission.uuid] = mission;
    tenantReadyMissionUuid[mission.tenant].push(mission.uuid);
    missionDates[mission.uuid] = NFTRental.MissionDates({
      postDate: block.timestamp,
      startDate: 0,
      stopDate: 0
    });
    emit MissionPosted(mission);
  }

  function cancelMission(string calldata _uuid) external onlyRentalPool {
    NFTRental.Mission memory curMission = readyMissions[_uuid];
    _rmReadyMissionUuid(curMission.tenant, _uuid);
    emit MissionCanceled(curMission);
  }

  function startMission(string calldata _uuid) external override {
    NFTRental.Mission memory missionToStart = readyMissions[_uuid];
    require(msg.sender == missionToStart.tenant, 'Not mission tenant');
    require(
      !tenantHasOngoingMissionForDapp(msg.sender, missionToStart.dappId),
      'Tenant already have ongoing mission for dapp'
    );
    _createWalletIfRequired();
    address _gamingWalletAddress = walletFactory.getGamingWallet(msg.sender);
    rentalPool.sendStartingMissionNFT(
      missionToStart.uuid,
      _gamingWalletAddress
    );
    tenantOngoingMissionUuid[msg.sender].push(_uuid);
    ongoingMissions[missionToStart.uuid] = missionToStart;
    _rmReadyMissionUuid(msg.sender, _uuid);
    delete readyMissions[missionToStart.uuid];
    missionDates[missionToStart.uuid].startDate = block.timestamp;
    emit MissionStarted(missionToStart);
  }

  function stopMission(string calldata _uuid) external override {
    NFTRental.Mission memory curMission = ongoingMissions[_uuid];
    require(msg.sender == curMission.owner, 'Not mission owner');
    missionDates[curMission.uuid].stopDate = block.timestamp;
    emit MissionTerminating(curMission);
  }

  function terminateMission(string calldata _uuid)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(isTerminatingFunction(_uuid), 'Mission is not terminating');
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

  function getReadyMission(string calldata _uuid)
    external
    view
    override
    returns (NFTRental.Mission memory mission)
  {
    return readyMissions[_uuid];
  }

  function getMissionStatus(string calldata _uuid)
    public
    view
    override
    returns (string memory missionStatus)
  {
    if (readyMissions[_uuid].owner != address(0)) {
      return 'ready';
    } else if (ongoingMissions[_uuid].owner != address(0)) {
      if (missionDates[_uuid].stopDate > 0) {
        return 'terminating';
      } else {
        return 'ongoing';
      }
    } else if (missionDates[_uuid].postDate > 0) {
      if (missionDates[_uuid].startDate > 0) {
        return 'terminated';
      } else {
        return 'canceled';
      }
    } else {
      return 'nonExisting';
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

  function getTenantReadyMissionUuid(address _tenant)
    public
    view
    override
    returns (string[] memory readyMissionsUuids)
  {
    return tenantReadyMissionUuid[_tenant];
  }

  function retrieveTenantOngoingMissions(address _tenant)
    public
    view
    override
    returns (NFTRental.Mission[] memory tenantOngoingMission)
  {
    string[] memory tenantOngoingMissionsUuid = tenantOngoingMissionUuid[
      _tenant
    ];
    NFTRental.Mission[] memory tenantOngoingMissions = new NFTRental.Mission[](
      tenantOngoingMissionsUuid.length
    );
    for (uint256 i; i < tenantOngoingMissionsUuid.length; i++) {
      tenantOngoingMissions[i] = ongoingMissions[tenantOngoingMissionsUuid[i]];
    }
    return tenantOngoingMissions;
  }

  function retrieveTenantReadyMissions(address _tenant)
    public
    view
    override
    returns (NFTRental.Mission[] memory tenantReadyMission)
  {
    string[] memory tenantReadyMissionsUuid = tenantReadyMissionUuid[_tenant];
    NFTRental.Mission[] memory tenantReadyMissions = new NFTRental.Mission[](
      tenantReadyMissionsUuid.length
    );
    for (uint256 i; i < tenantReadyMissionsUuid.length; i++) {
      tenantReadyMissions[i] = readyMissions[tenantReadyMissionsUuid[i]];
    }
    return tenantReadyMissions;
  }

  function tenantHasOngoingMissionForDapp(
    address _tenant,
    string memory _dappId
  ) public view override returns (bool hasMissionForDapp) {
    string[] memory tenantMissionsUuid = tenantOngoingMissionUuid[_tenant];
    for (uint32 i; i < tenantMissionsUuid.length; i++) {
      NFTRental.Mission memory curMission = ongoingMissions[
        tenantMissionsUuid[i]
      ];
      if (keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))) {
        return true;
      }
    }
    return false;
  }

  function tenantHasReadyMissionForDapp(address _tenant, string memory _dappId)
    public
    view
    override
    returns (bool hasMissionForDapp)
  {
    string[] memory tenantMissionsUuid = tenantReadyMissionUuid[_tenant];
    for (uint32 i; i < tenantMissionsUuid.length; i++) {
      NFTRental.Mission memory curMission = readyMissions[
        tenantMissionsUuid[i]
      ];
      if (keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))) {
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
    return missionDates[_uuid].stopDate > 0;
  }

  function getTenantReadyMissionUuidIndex(
    address _tenant,
    string calldata _uuid
  ) public view override returns (uint256 uuidPosition) {
    string[] memory list = tenantReadyMissionUuid[_tenant];
    for (uint32 i; i < list.length; i++) {
      if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
        return i;
      }
    }
    return list.length + 1;
  }

  function getTenantOngoingMissionUuidIndex(
    address _tenant,
    string calldata _uuid
  ) public view override returns (uint256 uuidPosition) {
    string[] memory list = tenantOngoingMissionUuid[_tenant];
    for (uint32 i; i < list.length; i++) {
      if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
        return i;
      }
    }
    return list.length + 1;
  }

  function isMissionPosted(string calldata _uuid)
    public
    view
    override
    returns (bool)
  {
    return missionDates[_uuid].postDate > 0;
  }

  function _createWalletIfRequired() internal {
    if (!walletFactory.hasGamingWallet(msg.sender)) {
      walletFactory.createWallet(msg.sender);
    }
  }

  function _rmMissionUuid(address _tenant, string calldata _uuid) internal {
    uint256 index = getTenantOngoingMissionUuidIndex(_tenant, _uuid);
    uint256 ongoingMissionLength = tenantOngoingMissionUuid[_tenant].length;
    tenantOngoingMissionUuid[_tenant][index] = tenantOngoingMissionUuid[
      _tenant
    ][ongoingMissionLength - 1];
    tenantOngoingMissionUuid[_tenant].pop();
    delete ongoingMissions[_uuid];
  }

  function _rmReadyMissionUuid(address _tenant, string calldata _uuid)
    internal
  {
    uint256 index = getTenantReadyMissionUuidIndex(_tenant, _uuid);
    uint256 readyMissionLength = tenantReadyMissionUuid[_tenant].length;
    tenantReadyMissionUuid[_tenant][index] = tenantReadyMissionUuid[_tenant][
      readyMissionLength - 1
    ];
    tenantReadyMissionUuid[_tenant].pop();
    delete readyMissions[_uuid];
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
          'NFT is not staked'
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
      'Incorrect lengths in tokenIds and collections'
    );
    require(_tokenIds[0][0] != 0, 'At least one NFT required');
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Management contract for NFT rentals.
// This mostly stores rental agreements and does the transfer with the wallet contracts
interface IMissionManager {
    event MissionPosted(NFTRental.Mission mission);

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

    function startMission(string calldata _uuid) external;

    function stopMission(string calldata _uuid) external;

    function terminateMission(string calldata _uuid) external;

    function getOngoingMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission calldata mission);

    function getReadyMission(string calldata _uuid)
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

    function getTenantReadyMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function tenantHasReadyMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function isTerminatingFunction(string calldata _uuid)
        external
        view
        returns (bool);

    function retrieveTenantReadyMissions(address _tenant)
        external
        view
        returns (NFTRental.Mission[] memory tenantReadyMissions);

    function retrieveTenantOngoingMissions(address _tenant)
        external
        view
        returns (NFTRental.Mission[] memory tenantOngoingMissions);

    function getTenantReadyMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function getTenantOngoingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function isMissionPosted(string calldata _uuid)
        external
        view
        returns (bool);
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

    struct MissionDates {
        uint256 postDate;
        uint256 startDate;
        uint256 stopDate;
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

    function whitelistMultipleOwners(address[] calldata _owners) external;

    function removeMultipleWhitelistedOwners(address[] calldata _owners)
        external;

    function postMissions(NFTRental.Mission[] calldata newMission) external;

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external;

    function cancelReadyMission(string calldata _uuid) external;

    function batchCancelReadyMission(string[] calldata _uuid) external;

    function isNFTStaked(
        address collection,
        address owner,
        uint256 tokenId
    ) external view returns (bool isStaked);

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted);
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