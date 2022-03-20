// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/Interfaces.sol";

contract MapManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant GROUP_SIZE = 6;

    event GroupCreated(
        uint256 groupId,
        uint256 mapId,
        bool isPrivate,
        address leader,
        address[] invites
    );
    event GroupInvitesUpdated(uint256 groupId, address[] invites);
    event GroupJoined(uint256 groupId, uint256 beastId);
    event GroupLeft(uint256 groupId, uint256 beastId);
    event GroupStarted(uint256 groupId, uint256 endTime);
    event BeastStaked(uint256 beastId, bool isStaked, address owner);
    event GroupRewardClaimed(uint256 groupId, uint256 beastId);
    event MapRegister(
        uint256 id,
        uint16 duration,
        uint256 price,
        uint8 levelRequirement,
        uint8 minGroupSize,
        uint16[GROUP_SIZE] requiredClasses,
        uint64 itemTypeId,
        uint8 itemDropProbability,
        uint64 skullReward,
        uint64 expReward
    );

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    enum GroupState {
        OFF,
        IDLE,
        STARTED,
        FINISHED
    }

    struct Group {
        uint256 id;
        uint256 mapId;
        address leader;
        bool isPrivate;
        uint256 endTime;
        EnumerableSetUpgradeable.UintSet beasts;
        EnumerableSetUpgradeable.UintSet classes;
        EnumerableSetUpgradeable.AddressSet invites;
        GroupState state;
    }

    struct PublicGroup {
        address leader;
        uint256 mapId;
        uint256 endTime;
        GroupState state;
        bool isPrivate;
    }

    struct Map {
        uint256 id;
        uint16 duration;
        uint256 price;
        uint8 levelRequirement;
        uint8 minGroupSize;
        uint16[GROUP_SIZE] requiredClasses;
        uint64 itemTypeId;
        uint8 itemDropProbability;
        uint64 skullReward;
        uint64 expReward;
    }

    mapping(uint256 => Map) private _maps;
    EnumerableSetUpgradeable.UintSet private _mapIds;
    uint256 private _groupIds;
    mapping(uint256 => Group) private _groups;
    mapping(uint256 => address) private _beastOwners;
    mapping(uint256 => uint256) private _beastsCurrentGroup;
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _playerBeastsInGroup;
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _playerGroupInvites;
    IBeast private _beast;
    IRagnarokERC20 private _skull;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAddresses(address _beastAddress, address _skullAddress)
        external
        onlyOwner
    {
        _beast = IBeast(_beastAddress);
        _skull = IRagnarokERC20(_skullAddress);
    }

    function stakeBeast(uint256 beastId) external {
        _beast.transferFrom(msg.sender, address(this), beastId);
        _beastOwners[beastId] = msg.sender;

        emit BeastStaked(beastId, true, msg.sender);
    }

    function unstakeBeast(uint256 beastId)
        external
        onlyBeastOwner(beastId)
        onlyBeastsWithoutGroup(beastId)
    {
        _beast.transferFrom(address(this), msg.sender, beastId);
        _beastOwners[beastId] = address(0);

        emit BeastStaked(beastId, false, msg.sender);
    }

    function registerMap(Map calldata map) external onlyOwner {
        _maps[map.id] = map;
        _mapIds.add(map.id);

        emit MapRegister(
            map.id,
            map.duration,
            map.price,
            map.levelRequirement,
            map.minGroupSize,
            map.requiredClasses,
            map.itemTypeId,
            map.itemDropProbability,
            map.skullReward,
            map.expReward
        );
    }

    function registerMapRaw(
        uint256 id,
        uint16 duration,
        uint256 price,
        uint8 levelRequirement,
        uint8 minGroupSize,
        uint16[GROUP_SIZE] calldata requiredClasses,
        uint64 itemTypeId,
        uint8 itemDropProbability,
        uint64 skullReward,
        uint64 expReward
    ) external onlyOwner {
        _maps[id] = Map(
            id,
            duration,
            price,
            levelRequirement,
            minGroupSize,
            requiredClasses,
            itemTypeId,
            itemDropProbability,
            skullReward,
            expReward
        );
        _mapIds.add(id);

        emit MapRegister(
            id,
            duration,
            price,
            levelRequirement,
            minGroupSize,
            requiredClasses,
            itemTypeId,
            itemDropProbability,
            skullReward,
            expReward
        );
    }

    function createPublicInstance(uint256 mapId)
        external
        onlyExistingMaps(mapId)
        returns (uint256)
    {
        Map memory map = _maps[mapId];
        if (map.price > 0)
            _skull.transferFrom(msg.sender, address(this), map.price);

        _groupIds++;
        uint256 newGroupId = _groupIds;
        Group storage newGroup = _groups[newGroupId];
        newGroup.id = newGroupId;
        newGroup.leader = msg.sender;
        newGroup.mapId = mapId;
        newGroup.state = GroupState.IDLE;

        emit GroupCreated(
            newGroup.id,
            newGroup.mapId,
            newGroup.isPrivate,
            newGroup.leader,
            newGroup.invites.values()
        );

        return newGroupId;
    }

    function createPrivateInstance(uint256 mapId, address[] calldata invites)
        external
        onlyExistingMaps(mapId)
        returns (uint256)
    {
        Map memory map = _maps[mapId];
        if (map.price > 0)
            _skull.transferFrom(msg.sender, address(this), map.price);

        _groupIds++;
        uint256 newGroupId = _groupIds;
        Group storage newGroup = _groups[newGroupId];
        newGroup.id = newGroupId;
        newGroup.leader = msg.sender;
        newGroup.mapId = mapId;
        newGroup.state = GroupState.IDLE;
        newGroup.isPrivate = true;
        _inviteToGroup(newGroup, msg.sender);
        for (uint256 index = 0; index < invites.length; index++) {
            _inviteToGroup(newGroup, invites[index]);
        }

        emit GroupCreated(
            newGroup.id,
            newGroup.mapId,
            newGroup.isPrivate,
            newGroup.leader,
            newGroup.invites.values()
        );

        return newGroupId;
    }

    function inviteToGroup(uint256 groupId, address[] memory invites)
        external
        onlyLeader(groupId)
        onlyIdleGroups(groupId)
    {
        Group storage group = _groups[groupId];
        for (uint256 index = 0; index < invites.length; index++) {
            _inviteToGroup(group, invites[index]);
        }

        emit GroupInvitesUpdated(groupId, group.invites.values());
    }

    function revokeInviteToGroup(uint256 groupId, address[] memory revokes)
        external
        onlyLeader(groupId)
        onlyIdleGroups(groupId)
    {
        Group storage group = _groups[groupId];
        for (uint256 index = 0; index < revokes.length; index++) {
            _revokeInviteToGroup(group, revokes[index]);
        }

        emit GroupInvitesUpdated(groupId, group.invites.values());
    }

    function joinGroup(uint256 groupId, uint256 beastId)
        external
        onlyBeastOwner(beastId)
        onlyBeastsWithoutGroup(beastId)
        onlyIdleGroups(groupId)
        onlyGroupHasSlots(groupId)
        onlyInvited(groupId)
    {
        Group storage group = _groups[groupId];
        Map memory map = _maps[group.mapId];
        require(
            _beast.getBeastLevel(beastId) >= map.levelRequirement,
            "not enough lvl"
        );

        if (map.price > 0)
            _skull.transferFrom(msg.sender, address(this), map.price);

        _beastsCurrentGroup[beastId] = groupId;
        _playerBeastsInGroup[msg.sender].add(beastId);

        EnumerableSetUpgradeable.UintSet storage groupBeasts = group.beasts;
        groupBeasts.add(beastId);

        uint16 classNumberRepresentation = _beast
            .getBeastClassNumberRepresentation(beastId);

        group.classes.add(classNumberRepresentation);

        emit GroupJoined(groupId, beastId);
    }

    function leaveGroup(uint256 beastId)
        external
        onlyStakedBeasts(beastId)
        onlyBeastOwner(beastId)
        onlyBeastsWithGroup(beastId)
    {
        uint256 groupId = _beastsCurrentGroup[beastId];
        Group storage group = _groups[groupId];
        require(group.state == GroupState.IDLE, "E00: Group already started");

        _beastsCurrentGroup[beastId] = 0;
        _playerBeastsInGroup[msg.sender].remove(beastId);

        EnumerableSetUpgradeable.UintSet storage groupBeasts = group.beasts;
        groupBeasts.remove(beastId);

        uint16 classNumberRepresentation = _beast
            .getBeastClassNumberRepresentation(beastId);
        group.classes.remove(classNumberRepresentation);

        emit GroupLeft(groupId, beastId);
    }

    function startGroup(uint256 groupId)
        external
        onlyIdleGroups(groupId)
        onlyLeader(groupId)
    {
        Group storage group = _groups[groupId];
        uint256 groupSize = group.beasts.length();
        Map memory map = _maps[group.mapId];
        require(groupSize >= map.minGroupSize, "group too small");

        uint16[GROUP_SIZE] memory requiredClasses = map.requiredClasses;

        for (uint256 index = 0; index < requiredClasses.length; index++) {
            if (requiredClasses[index] == 0) break;
            require(
                group.classes.contains(requiredClasses[index]),
                "missing class"
            );
        }

        _skull.burn(map.price * groupSize);
        group.endTime = block.timestamp + map.duration;
        group.state = GroupState.STARTED;
        address[] memory invites = group.invites.values();
        for (uint256 index = 0; index < invites.length; index++) {
            _playerGroupInvites[invites[index]].remove(groupId);
        }

        emit GroupStarted(groupId, group.endTime);
    }

    function claimReward(uint256 beastId)
        external
        onlyBeastOwner(beastId)
        onlyBeastsWithGroup(beastId)
    {
        uint256 groupId = _beastsCurrentGroup[beastId];
        Group storage group = _groups[groupId];
        Map memory map = _maps[group.mapId];
        require(group.state != GroupState.IDLE, "E00: Unstarted group");
        if (group.state != GroupState.FINISHED) {
            require(group.endTime <= block.timestamp, "not finished");
        }
        group.state = GroupState.FINISHED;
        _playerBeastsInGroup[msg.sender].remove(beastId);
        _beastsCurrentGroup[beastId] = 0;
        _beast.giveExperience(beastId, map.expReward);
        _skull.mint(msg.sender, map.skullReward);
        emit GroupRewardClaimed(group.id, beastId);
    }

    /*///////////////////////////////////////////////////////////////
                    GETTERS
    //////////////////////////////////////////////////////////////*/

    function getGroupSize(uint256 groupId) external view returns (uint256) {
        return _getGroupSize(groupId);
    }

    function getMap(uint256 mapId)
        external
        view
        onlyExistingMaps(mapId)
        returns (Map memory)
    {
        return _maps[mapId];
    }

    function getMaps() external view returns (Map[] memory) {
        uint256 mapsCount = _mapIds.length();
        Map[] memory maps = new Map[](mapsCount);
        for (uint256 index = 0; index < _mapIds.length(); index++) {
            maps[index] = _maps[_mapIds.at(index)];
        }
        return maps;
    }

    function getGroup(uint256 groupId)
        external
        view
        returns (PublicGroup memory)
    {
        PublicGroup memory result;
        Group storage group = _groups[groupId];
        result.leader = group.leader;
        result.mapId = group.mapId;
        result.endTime = group.endTime;
        result.isPrivate = group.isPrivate;
        result.state = group.state;
        return result;
    }

    function getBeastCurrentGroupId(uint256 beastId)
        external
        view
        returns (uint256)
    {
        return _beastsCurrentGroup[beastId];
    }

    function getGroupBeasts(uint256 groupId)
        external
        view
        returns (uint256[] memory)
    {
        return _groups[groupId].beasts.values();
    }

    function getGroupClasses(uint256 groupId)
        external
        view
        returns (uint256[] memory)
    {
        return _groups[groupId].classes.values();
    }

    function getPlayerBeastsInGroup(address player)
        external
        view
        returns (uint256[] memory)
    {
        return _playerBeastsInGroup[player].values();
    }

    function getPlayerInvites(address player)
        external
        view
        returns (uint256[] memory)
    {
        return _playerGroupInvites[player].values();
    }

    /*///////////////////////////////////////////////////////////////
                    PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _getGroupSize(uint256 groupId) private view returns (uint256) {
        return _groups[groupId].beasts.length();
    }

    function _revokeInviteToGroup(Group storage group, address invited)
        private
    {
        group.invites.remove(invited);
        _playerGroupInvites[invited].remove(group.id);
    }

    function _inviteToGroup(Group storage group, address invited) private {
        group.invites.add(invited);
        _playerGroupInvites[invited].add(group.id);
    }

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyLeader(uint256 groupId) {
        require(
            _groups[groupId].leader == msg.sender,
            "E01: Only the leader can exacute this action"
        );
        _;
    }

    modifier onlyBeastOwner(uint256 beastId) {
        require(
            _beastOwners[beastId] == msg.sender,
            "E02: Only the owner can exacute this action"
        );
        _;
    }

    modifier onlyStakedBeasts(uint256 beastId) {
        require(
            _beastOwners[beastId] != address(0),
            "E03: The beast is not staked"
        );
        _;
    }

    modifier onlyBeastsWithoutGroup(uint256 beastId) {
        require(
            _beastsCurrentGroup[beastId] == 0,
            "E04: The beast is in a group"
        );
        _;
    }

    modifier onlyBeastsWithGroup(uint256 beastId) {
        require(
            _beastsCurrentGroup[beastId] != 0,
            "E05: The beast is not in a group"
        );
        _;
    }

    modifier onlyGroupHasSlots(uint256 groupId) {
        require(_getGroupSize(groupId) < 6, "E06: The group is full");
        _;
    }

    modifier onlyExistingMaps(uint256 mapId) {
        require(_maps[mapId].id != 0, "E07: The map does not exists");
        _;
    }

    modifier onlyIdleGroups(uint256 groupId) {
        require(
            _groups[groupId].state == GroupState.IDLE,
            "E08: The group is not IDLE"
        );
        _;
    }

    modifier onlyInvited(uint256 groupId) {
        require(
            !_groups[groupId].isPrivate ||
                _groups[groupId].invites.contains(msg.sender),
            "E09: The group is private"
        );
        _;
    }

    // MANDATORY OVERRIDES

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../SharedLib.sol";

interface IRagnarokItem {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getItemStats(uint256 itemId)
        external
        view
        returns (SharedLib.Stats memory);

    function getItemType(uint256 itemId)
        external
        view
        returns (SharedLib.ItemType memory);
}

interface IRagnarokERC20 {
    function balanceOf(address from) external view returns (uint256 balance);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function mint(address from, uint256 amount) external;

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IFreyjaRelic {
    function burn(uint256 id, uint256 amount) external;

    function burnBatch(uint256[] calldata ids, uint256[] memory amounts)
        external;

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatchFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

interface IBeast {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function transfer(address to, uint256 id) external;

    function ownerOf(uint256 id) external returns (address owner);

    function mint(address to, uint256 tokenid) external;

    function getBeastLevel(uint256 beastId) external view returns (uint8);

    function getBeastClassNumberRepresentation(uint256 beastId)
        external
        view
        returns (uint16);

    function giveExperience(uint256 beastId, uint64 experience) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.7;

library SharedLib {
    uint256 public constant FACTIONS = 6;
    uint256 public constant CLASSES = FACTIONS * 2;
    uint256 public constant ITEM_SLOTS = 4;

    struct Item {
        uint8 level;
        uint256 itemTypeId;
    }

    struct ItemType {
        uint256 id;
        uint8 levelRequirement;
        uint16[CLASSES] classes;
        uint8[ITEM_SLOTS] slots;
    }

    struct BeastModifier {
        uint8 expModifier;
        uint8 goldModifier;
        uint8 dropModifier;
        uint8 speed;
    }

    struct Stats {
        uint16 hp;
        uint16 mana;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
    }

    function classToNumberRepresentation(uint8 faction, uint8 class)
        internal
        pure
        returns (uint16)
    {
        if (class == 0) {
            return 0;
        }
        return uint16(faction * FACTIONS + class);
    }

    function numberRepresentationToFaction(uint16 numberRepresentation)
        internal
        pure
        returns (uint8)
    {
        return uint8(numberRepresentation / FACTIONS);
    }

    function numberRepresentationToClass(uint16 numberRepresentation)
        internal
        pure
        returns (uint8)
    {
        return uint8(numberRepresentation % FACTIONS);
    }
}