/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: No License (None)
// No permissions granted before Wednesday, 29 May 2024, then GPL-3.0 after this date.

/**
 * ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗   ██╗   ██╗██╗███████╗██╗     ██████╗ ███████╗██████╗
 * ████╗  ██║██║████╗  ██║     ██║██╔══██╗  ╚██╗ ██╔╝██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗
 * ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║   ╚████╔╝ ██║█████╗  ██║     ██║  ██║█████╗  ██████╔╝
 * ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║    ╚██╔╝  ██║██╔══╝  ██║     ██║  ██║██╔══╝  ██╔══██╗
 * ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║     ██║   ██║███████╗███████╗██████╔╝███████╗██║  ██║
 * ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝     ╚═╝   ╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝
 *                                   Yield like a Ninja!
 *
 *
 * We are committed to working with Black/White hats. If you find an issue then please reach
 * out quoting reference 'NyPtvPolygonWmaticQiMaiFarmV3StrategyToUsdc'
 *
 * https://discord.yielder.ninja
 * https://twitter.com/NinjaYielder
 */

pragma solidity ^0.8.0;

interface IStrategy {
  function deposit() external;

  function withdraw(uint256 _amount) external;

  function harvest() external returns (uint256);

  function balanceOf() external view returns (uint256);

  function estimateHarvest() external view returns (uint256 profit, uint256 callFeeToUser);

  function retireStrategy() external;

  function panic() external;

  function pause() external;

  function unpause() external;
}

interface IAccessControlUpgradeable {
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;
}

interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

library AddressUpgradeable {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

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

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

abstract contract Initializable {
  uint8 private _initialized;

  bool private _initializing;

  event Initialized(uint8 version);

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

  modifier reinitializer(uint8 version) {
    require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}

abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

  uint256[50] private __gap;
}

library StringsUpgradeable {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  function toString(uint256 value) internal pure returns (string memory) {
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

  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

interface IERC165Upgradeable {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }

  uint256[50] private __gap;
}

abstract contract AccessControlUpgradeable is
  Initializable,
  ContextUpgradeable,
  IAccessControlUpgradeable,
  ERC165Upgradeable
{
  function __AccessControl_init() internal onlyInitializing {}

  function __AccessControl_init_unchained() internal onlyInitializing {}

  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members[account];
  }

  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

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

  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }

  uint256[49] private __gap;
}

library EnumerableSetUpgradeable {
  struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);

      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      if (lastIndex != toDeleteIndex) {
        bytes32 lastValue = set._values[lastIndex];

        set._values[toDeleteIndex] = lastValue;

        set._indexes[lastValue] = valueIndex;
      }

      set._values.pop();

      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    return set._values[index];
  }

  function _values(Set storage set) private view returns (bytes32[] memory) {
    return set._values;
  }

  struct Bytes32Set {
    Set _inner;
  }

  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    return _values(set._inner);
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  function values(AddressSet storage set) internal view returns (address[] memory) {
    bytes32[] memory store = _values(set._inner);
    address[] memory result;

    assembly {
      result := store
    }

    return result;
  }

  struct UintSet {
    Set _inner;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }

  function values(UintSet storage set) internal view returns (uint256[] memory) {
    bytes32[] memory store = _values(set._inner);
    uint256[] memory result;

    assembly {
      result := store
    }

    return result;
  }
}

abstract contract AccessControlEnumerableUpgradeable is
  Initializable,
  IAccessControlEnumerableUpgradeable,
  AccessControlUpgradeable
{
  function __AccessControlEnumerable_init() internal onlyInitializing {}

  function __AccessControlEnumerable_init_unchained() internal onlyInitializing {}

  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
    return _roleMembers[role].at(index);
  }

  function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
    return _roleMembers[role].length();
  }

  function _grantRole(bytes32 role, address account) internal virtual override {
    super._grantRole(role, account);
    _roleMembers[role].add(account);
  }

  function _revokeRole(bytes32 role, address account) internal virtual override {
    super._revokeRole(role, account);
    _roleMembers[role].remove(account);
  }

  uint256[49] private __gap;
}

interface IERC1822ProxiableUpgradeable {
  function proxiableUUID() external view returns (bytes32);
}

interface IBeaconUpgradeable {
  function implementation() external view returns (address);
}

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

  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
    assembly {
      r.slot := slot
    }
  }

  function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
    assembly {
      r.slot := slot
    }
  }

  function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
    assembly {
      r.slot := slot
    }
  }

  function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
    assembly {
      r.slot := slot
    }
  }
}

abstract contract ERC1967UpgradeUpgradeable is Initializable {
  function __ERC1967Upgrade_init() internal onlyInitializing {}

  function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

  bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  event Upgraded(address indexed implementation);

  function _getImplementation() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  function _setImplementation(address newImplementation) private {
    require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
    StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
  }

  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
    _upgradeTo(newImplementation);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(newImplementation, data);
    }
  }

  function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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

  bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  event AdminChanged(address previousAdmin, address newAdmin);

  function _getAdmin() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
  }

  function _setAdmin(address newAdmin) private {
    require(newAdmin != address(0), "ERC1967: new admin is the zero address");
    StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
  }

  function _changeAdmin(address newAdmin) internal {
    emit AdminChanged(_getAdmin(), newAdmin);
    _setAdmin(newAdmin);
  }

  bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

  event BeaconUpgraded(address indexed beacon);

  function _getBeacon() internal view returns (address) {
    return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
  }

  function _setBeacon(address newBeacon) private {
    require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
    require(
      AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
      "ERC1967: beacon implementation is not a contract"
    );
    StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
  }

  function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
    _setBeacon(newBeacon);
    emit BeaconUpgraded(newBeacon);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
    }
  }

  function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
    require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
  }

  uint256[50] private __gap;
}

abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
  function __UUPSUpgradeable_init() internal onlyInitializing {}

  function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

  address private immutable __self = address(this);

  modifier onlyProxy() {
    require(address(this) != __self, "Function must be called through delegatecall");
    require(_getImplementation() == __self, "Function must be called through active proxy");
    _;
  }

  modifier notDelegated() {
    require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
    _;
  }

  function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
    return _IMPLEMENTATION_SLOT;
  }

  function upgradeTo(address newImplementation) external virtual onlyProxy {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
  }

  function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, data, true);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual;

  uint256[50] private __gap;
}

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
  event Paused(address account);

  event Unpaused(address account);

  bool private _paused;

  function __Pausable_init() internal onlyInitializing {
    __Pausable_init_unchained();
  }

  function __Pausable_init_unchained() internal onlyInitializing {
    _paused = false;
  }

  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }

  modifier whenPaused() {
    _requirePaused();
    _;
  }

  function paused() public view virtual returns (bool) {
    return _paused;
  }

  function _requireNotPaused() internal view virtual {
    require(!paused(), "Pausable: paused");
  }

  function _requirePaused() internal view virtual {
    require(paused(), "Pausable: not paused");
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  uint256[49] private __gap;
}

abstract contract NYBaseProfitTakingStrategyV2 is
  IStrategy,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  PausableUpgradeable
{
  uint256 public constant PERCENT_DIVISOR = 10_000;

  uint256 public constant ONE_YEAR = 365 days;

  uint256 public constant UPGRADE_TIMELOCK = 1 hours;

  uint256 public lastHarvestTimestamp;

  uint256 public upgradeProposalTime;

  bytes32 public constant KEEPER = keccak256("KEEPER");
  bytes32 public constant STRATEGIST = keccak256("STRATEGIST");
  bytes32 public constant GUARDIAN = keccak256("GUARDIAN");
  bytes32 public constant ADMIN = keccak256("ADMIN");
  bytes32[] private cascadingAccess;

  address public vault;
  address public treasury;
  address public strategistRemitter;

  uint256 public constant MAX_FEE = 1000;
  uint256 public constant MAX_SECURITY_FEE = 100;
  uint256 public constant STRATEGIST_MAX_FEE = 1000;

  uint256 public totalFee;
  uint256 public callFee;
  uint256 public treasuryFee;
  uint256 public strategistFee;
  uint256 public securityFee;

  event FeesUpdated(uint256 newCallFee, uint256 newTreasuryFee, uint256 newStrategistFee);
  event StrategyHarvest(
    address indexed harvester,
    uint256 underlyingTokenCount,
    uint256 harvestSeconds,
    uint256 sentToVault
  );
  event StrategistRemitterUpdated(address newStrategistRemitter);
  event TotalFeeUpdated(uint256 newFee);

  constructor() initializer {}

  function __NYBaseProfitTakingStrategy_init(
    address _vault,
    address _treasury,
    address _strategistRemitter,
    address[] memory _strategists,
    address[] memory _multisigRoles
  ) internal onlyInitializing {
    __UUPSUpgradeable_init();
    __AccessControlEnumerable_init();
    __Pausable_init_unchained();

    totalFee = 500;
    callFee = 500;
    treasuryFee = 9500;
    strategistFee = 1053;
    securityFee = 10;

    vault = _vault;
    treasury = _treasury;
    strategistRemitter = _strategistRemitter;

    for (uint256 i = 0; i < _strategists.length; i++) {
      _grantRole(STRATEGIST, _strategists[i]);
    }

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, _multisigRoles[0]);
    _grantRole(ADMIN, _multisigRoles[1]);
    _grantRole(GUARDIAN, _multisigRoles[2]);

    cascadingAccess = [DEFAULT_ADMIN_ROLE, ADMIN, GUARDIAN, STRATEGIST, KEEPER];
    clearUpgradeCooldown();
  }

  function deposit() public override whenNotPaused {
    _deposit();
  }

  function withdraw(uint256 _amount) external override {
    require(msg.sender == vault);
    require(_amount != 0);
    require(_amount <= balanceOf());

    uint256 withdrawFee = (_amount * securityFee) / PERCENT_DIVISOR;
    _amount -= withdrawFee;

    _withdraw(_amount);
  }

  function harvest() external override whenNotPaused returns (uint256 callerFee) {
    require(lastHarvestTimestamp != block.timestamp);

    uint256 harvestSeconds = lastHarvestTimestamp > 0 ? block.timestamp - lastHarvestTimestamp : 0;
    lastHarvestTimestamp = block.timestamp;

    uint256 sentToVault;
    uint256 underlyingTokenCount;
    (callerFee, underlyingTokenCount, sentToVault) = _harvestCore();

    emit StrategyHarvest(msg.sender, underlyingTokenCount, harvestSeconds, sentToVault);
  }

  function balanceOf() public view virtual override returns (uint256);

  function retireStrategy() external override {
    _atLeastRole(STRATEGIST);
    _retireStrategy();
  }

  function panic() external override {
    _atLeastRole(GUARDIAN);
    _reclaimUnderlying();
    pause();
  }

  function pause() public override {
    _atLeastRole(GUARDIAN);
    _pause();
  }

  function unpause() external override {
    _atLeastRole(ADMIN);
    _unpause();
    deposit();
  }

  function updateTotalFee(uint256 _totalFee) external {
    _atLeastRole(DEFAULT_ADMIN_ROLE);
    require(_totalFee <= MAX_FEE);
    totalFee = _totalFee;
    emit TotalFeeUpdated(totalFee);
  }

  function updateFees(uint256 _callFee, uint256 _treasuryFee, uint256 _strategistFee) external returns (bool) {
    _atLeastRole(DEFAULT_ADMIN_ROLE);
    require(_callFee + _treasuryFee == PERCENT_DIVISOR);
    require(_strategistFee <= STRATEGIST_MAX_FEE);

    callFee = _callFee;
    treasuryFee = _treasuryFee;
    strategistFee = _strategistFee;
    emit FeesUpdated(callFee, treasuryFee, strategistFee);
    return true;
  }

  function updateSecurityFee(uint256 _securityFee) external {
    _atLeastRole(DEFAULT_ADMIN_ROLE);
    require(_securityFee <= MAX_SECURITY_FEE);
    securityFee = _securityFee;
  }

  function updateTreasury(address newTreasury) external returns (bool) {
    _atLeastRole(DEFAULT_ADMIN_ROLE);
    treasury = newTreasury;
    return true;
  }

  function updateStrategistRemitter(address _newStrategistRemitter) external {
    _atLeastRole(DEFAULT_ADMIN_ROLE);
    require(_newStrategistRemitter != address(0));
    strategistRemitter = _newStrategistRemitter;
    emit StrategistRemitterUpdated(_newStrategistRemitter);
  }

  function initiateUpgradeCooldown() external {
    _atLeastRole(STRATEGIST);
    upgradeProposalTime = block.timestamp;
  }

  function clearUpgradeCooldown() public {
    _atLeastRole(GUARDIAN);
    upgradeProposalTime = block.timestamp + (ONE_YEAR * 100);
  }

  function _authorizeUpgrade(address) internal override {
    _atLeastRole(DEFAULT_ADMIN_ROLE);
    require(upgradeProposalTime + UPGRADE_TIMELOCK < block.timestamp);
    clearUpgradeCooldown();
  }

  function _atLeastRole(bytes32 role) internal view {
    uint256 numRoles = cascadingAccess.length;
    uint256 specifiedRoleIndex;
    for (uint256 i = 0; i < numRoles; i++) {
      if (role == cascadingAccess[i]) {
        specifiedRoleIndex = i;
        break;
      } else if (i == numRoles - 1) {
        revert();
      }
    }

    for (uint256 i = 0; i <= specifiedRoleIndex; i++) {
      if (hasRole(cascadingAccess[i], msg.sender)) {
        break;
      } else if (i == specifiedRoleIndex) {
        revert();
      }
    }
  }

  function _onlyStrategistOrOwner() internal view {
    require(hasRole(STRATEGIST, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
  }

  function _deposit() internal virtual;

  function _withdraw(uint256 _amount) internal virtual;

  function _harvestCore()
    internal
    virtual
    returns (uint256 callerFee, uint256 underlyingTokenCount, uint256 sentToVault);

  function _reclaimUnderlying() internal virtual;

  function _retireStrategy() internal virtual;
}

interface IERC20Upgradeable {
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20PermitUpgradeable {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function nonces(address owner) external view returns (uint256);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20Upgradeable {
  using AddressUpgradeable for address;

  function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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

  function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

library MathUpgradeable {
  enum Rounding {
    Down,
    Up,
    Zero
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a & b) + (a ^ b) / 2;
  }

  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a == 0 ? 0 : (a - 1) / b + 1;
  }

  function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
    unchecked {
      uint256 prod0;
      uint256 prod1;
      assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      if (prod1 == 0) {
        return prod0 / denominator;
      }

      require(denominator > prod1);

      uint256 remainder;
      assembly {
        remainder := mulmod(x, y, denominator)

        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      uint256 twos = denominator & (~denominator + 1);
      assembly {
        denominator := div(denominator, twos)

        prod0 := div(prod0, twos)

        twos := add(div(sub(0, twos), twos), 1)
      }

      prod0 |= prod1 * twos;

      uint256 inverse = (3 * denominator) ^ 2;

      inverse *= 2 - denominator * inverse;
      inverse *= 2 - denominator * inverse;
      inverse *= 2 - denominator * inverse;
      inverse *= 2 - denominator * inverse;
      inverse *= 2 - denominator * inverse;
      inverse *= 2 - denominator * inverse;

      result = prod0 * inverse;
      return result;
    }
  }

  function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
    uint256 result = mulDiv(x, y, denominator);
    if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
      result += 1;
    }
    return result;
  }

  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 result = 1;
    uint256 x = a;
    if (x >> 128 > 0) {
      x >>= 128;
      result <<= 64;
    }
    if (x >> 64 > 0) {
      x >>= 64;
      result <<= 32;
    }
    if (x >> 32 > 0) {
      x >>= 32;
      result <<= 16;
    }
    if (x >> 16 > 0) {
      x >>= 16;
      result <<= 8;
    }
    if (x >> 8 > 0) {
      x >>= 8;
      result <<= 4;
    }
    if (x >> 4 > 0) {
      x >>= 4;
      result <<= 2;
    }
    if (x >> 2 > 0) {
      result <<= 1;
    }

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

  function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
    uint256 result = sqrt(a);
    if (rounding == Rounding.Up && result * result < a) {
      result += 1;
    }
    return result;
  }
}

interface IMasterChef {
  function deposit(uint256 _pid, uint256 _amount) external;

  function emergencyWithdraw(uint256 _pid) external;

  function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

  function withdraw(uint256 _pid, uint256 _amount) external;

  function pending(uint256 _pid, address _to) external view returns (uint256);
}

interface IUniswapV2Router02 {
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IVault {
  function depositProfitTokenForUsers(uint256 _amount) external;
}

contract NyPtvPolygonWmaticQiMaiFarmV3StrategyToUsdc is NYBaseProfitTakingStrategyV2 {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public constant MAX_SLIPPAGE = 9700;

  uint256 public constant POOL_ID = 1;
  address public constant MAI_FARM_V3 = address(0xcC54AfCeCD0d89e0B2db58f5d9e58468E7aD20dc);
  address public constant MAI_FINANCE_ROUTER = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

  address public constant QI = address(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);
  address public constant USDC = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
  address public constant WETH = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  address public constant QUICK = address(0xB5C064F955D8e7F38fE0460C556a72987494eE17);
  address public constant LP_TOKEN = address(0x9A8b2601760814019B7E6eE0052E25f1C623D1E6);
  address public constant LP_TOKEN_0 = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
  address public constant LP_TOKEN_1 = address(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);

  address[] public qiToUsdcPath;

  function initialize(
    address _vault,
    address _treasury,
    address _strategistRemitter,
    address[] memory _strategists,
    address[] memory _multisigRoles
  ) public initializer {
    __NYBaseProfitTakingStrategy_init(_vault, _treasury, _strategistRemitter, _strategists, _multisigRoles);
    qiToUsdcPath = [QI, QUICK, WETH, USDC];
  }

  function _deposit() internal override {
    uint256 underlyingBalance = IERC20Upgradeable(LP_TOKEN).balanceOf(address(this));
    if (underlyingBalance != 0) {
      IERC20Upgradeable(LP_TOKEN).safeIncreaseAllowance(MAI_FARM_V3, underlyingBalance);
      IMasterChef(MAI_FARM_V3).deposit(POOL_ID, underlyingBalance);
    }
  }

  function _withdraw(uint256 _amount) internal override {
    uint256 underlyingBalance = IERC20Upgradeable(LP_TOKEN).balanceOf(address(this));
    if (underlyingBalance < _amount) {
      IMasterChef(MAI_FARM_V3).withdraw(POOL_ID, _amount - underlyingBalance);
    }
    IERC20Upgradeable(LP_TOKEN).safeTransfer(vault, _amount);
  }

  function _harvestCore()
    internal
    override
    returns (uint256 callerFee, uint256 underlyingTokenCount, uint256 sentToVault)
  {
    IMasterChef(MAI_FARM_V3).deposit(POOL_ID, 0);
    _swapFarmEmissionTokens();
    callerFee = _chargeFees();
    underlyingTokenCount = balanceOf();
    sentToVault = _sendYieldToVault();
  }

  function _swapFarmEmissionTokens() internal {
    IERC20Upgradeable qi = IERC20Upgradeable(QI);
    uint256 qiBalance = qi.balanceOf(address(this));
    if (qiToUsdcPath.length < 2 || qiBalance == 0) {
      return;
    }
    qi.safeIncreaseAllowance(MAI_FINANCE_ROUTER, qiBalance);

    uint256[] memory amounts = IUniswapV2Router02(MAI_FINANCE_ROUTER).getAmountsOut(qiBalance, qiToUsdcPath);
    uint256 amountOutMin = (amounts[amounts.length - 1] * MAX_SLIPPAGE) / PERCENT_DIVISOR;

    IUniswapV2Router02(MAI_FINANCE_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      qiBalance,
      amountOutMin,
      qiToUsdcPath,
      address(this),
      block.timestamp
    );
  }

  function _chargeFees() internal returns (uint256 callerFee) {
    IERC20Upgradeable usdc = IERC20Upgradeable(USDC);
    uint256 fee = (usdc.balanceOf(address(this)) * totalFee) / PERCENT_DIVISOR;
    if (fee != 0) {
      callerFee = (fee * callFee) / PERCENT_DIVISOR;
      uint256 treasuryFeeToVault = (fee * treasuryFee) / PERCENT_DIVISOR;
      uint256 feeToStrategist = (treasuryFeeToVault * strategistFee) / PERCENT_DIVISOR;
      treasuryFeeToVault -= feeToStrategist;
      usdc.safeTransfer(msg.sender, callerFee);
      usdc.safeTransfer(treasury, treasuryFeeToVault);
      usdc.safeTransfer(strategistRemitter, feeToStrategist);
    }
  }

  function _sendYieldToVault() internal returns (uint256 sentToVault) {
    sentToVault = IERC20Upgradeable(USDC).balanceOf(address(this));
    IERC20Upgradeable(USDC).approve(vault, sentToVault);
    IVault(vault).depositProfitTokenForUsers(sentToVault);
  }

  function balanceOf() public view override returns (uint256) {
    (uint256 amount, ) = IMasterChef(MAI_FARM_V3).userInfo(POOL_ID, address(this));
    return amount + IERC20Upgradeable(LP_TOKEN).balanceOf(address(this));
  }

  function _reclaimUnderlying() internal override {
    IMasterChef(MAI_FARM_V3).emergencyWithdraw(POOL_ID);
  }

  function estimateHarvest() external view override returns (uint256 profit, uint256 callFeeToUser) {
    uint256 pendingReward = IMasterChef(MAI_FARM_V3).pending(POOL_ID, address(this));
    uint256 totalRewards = pendingReward + IERC20Upgradeable(QI).balanceOf(address(this));
    if (totalRewards != 0) {
      profit += IUniswapV2Router02(MAI_FINANCE_ROUTER).getAmountsOut(totalRewards, qiToUsdcPath)[1];
    }

    profit += IERC20Upgradeable(USDC).balanceOf(address(this));

    uint256 usdcFee = (profit * totalFee) / PERCENT_DIVISOR;
    callFeeToUser = (usdcFee * callFee) / PERCENT_DIVISOR;
    profit -= usdcFee;
  }

  function _retireStrategy() internal override {
    _harvestCore();

    (uint256 poolBal, ) = IMasterChef(MAI_FARM_V3).userInfo(POOL_ID, address(this));
    if (poolBal != 0) {
      IMasterChef(MAI_FARM_V3).withdraw(POOL_ID, poolBal);
    }

    uint256 underlyingBalance = IERC20Upgradeable(LP_TOKEN).balanceOf(address(this));
    if (underlyingBalance != 0) {
      IERC20Upgradeable(LP_TOKEN).safeTransfer(vault, underlyingBalance);
    }
  }
}