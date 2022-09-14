// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/Interfaces.sol";
import "./SharedLib.sol";

contract MapManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint8 public constant GROUP_SIZE = 6;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    enum GroupState {
        OFF,
        IDLE,
        STARTED,
        FINISHED
    }

    struct GroupStats {
        uint16 con;
        uint16 str;
        uint16 dex;
        uint16 wis;
        uint16 intell;
    }

    struct Group {
        uint240 id;
        uint16 mapId;
        address leader;
        uint256 endTime;
        bool isPrivate;
        EnumerableSetUpgradeable.UintSet beasts;
        EnumerableSetUpgradeable.AddressSet invites;
        GroupState state;
        GroupStats stats;
    }

    struct PublicGroup {
        uint256 id;
        uint16 mapId;
        address leader;
        uint256 endTime;
        bool isPrivate;
        BeastState[] beasts;
        address[] invites;
        GroupState state;
        uint256 tears;
        GroupStats stats;
    }

    struct Map {
        uint16 id;
        uint16 duration;
        uint256 price;
        uint8 levelRequirement;
        uint8 minGroupSize;
        uint16[GROUP_SIZE] requiredClasses;
        uint64 itemTypeId;
        uint8 itemDropProbability;
        uint256 skullReward;
        uint32 expReward;
        uint32 newDuration;
        bool isEpic;
    }

    struct BeastState {
        uint256 representation;
        uint240 groupId;
        uint16 beastId;
    }

    uint16 private _mapIds;
    uint240 private _groupIds;
    mapping(uint16 => Map) private _maps;
    mapping(uint240 => Group) private _groups;
    mapping(uint16 => BeastState) private _beastStates;
    mapping(address => EnumerableSetUpgradeable.UintSet) private _playerGroups;
    mapping(address => EnumerableSetUpgradeable.UintSet) private _playerBeasts;
    address public beastAddress;
    address public skullAddress;
    address public tearAddress;
    mapping(uint240 => uint256) private _groupTears;
    // V2
    address public randomOracleAddress;
    address public consumableAddress;
    mapping(uint240 => bytes32) private _groupRequestIds;

    function initialize() public initializer {
        __Ownable_init();
    }

    function stakeBeastBatch(uint256[] memory beastIds) external {
        IBeast(beastAddress).pull(msg.sender, beastIds);
    }

    function pullCallback(address owner, uint256[] calldata ids) external {
        require(msg.sender == beastAddress, "not-allowed");
        for (uint256 index = 0; index < ids.length; index++) {
            _stakeBeast(uint16(ids[index]), owner);
        }
    }

    function unstakeBeastBatch(uint16[] memory beastIds) external {
        for (uint256 index = 0; index < beastIds.length; index++) {
            _unstakeBeast(beastIds[index]);
        }
    }

    function _stakeBeast(uint16 beastId, address owner) internal {
        _beastStates[beastId] = BeastState({
            representation: IBeast(beastAddress).getBeastRepresentation(beastId),
            groupId: 0,
            beastId: beastId
        });
        _playerBeasts[owner].add(beastId);
    }

    function _unstakeBeast(uint16 beastId) internal onlyBeastOwner(beastId) {
        require(_beastStates[beastId].groupId == 0, "in group");
        IBeast(beastAddress).transferFrom(address(this), msg.sender, beastId);
        _playerBeasts[msg.sender].remove(beastId);
    }

    function createPublicInstance(uint16 mapId) public onlyExistingMaps(mapId) returns (uint256) {
        _groupIds++;
        uint240 newGroupId = _groupIds;
        Group storage newGroup = _groups[newGroupId];
        newGroup.id = newGroupId;
        newGroup.leader = msg.sender;
        newGroup.mapId = mapId;
        newGroup.state = GroupState.IDLE;

        _playerGroups[msg.sender].add(newGroupId);
        return newGroupId;
    }

    function createPrivateInstance(uint16 mapId, address[] calldata invites)
        external
        onlyExistingMaps(mapId)
        returns (uint240)
    {
        _groupIds++;
        uint240 newGroupId = _groupIds;
        Group storage newGroup = _groups[newGroupId];
        newGroup.id = newGroupId;
        newGroup.leader = msg.sender;
        newGroup.mapId = mapId;
        newGroup.state = GroupState.IDLE;
        newGroup.isPrivate = true;
        newGroup.invites.add(msg.sender);
        for (uint256 index = 0; index < invites.length; index++) {
            newGroup.invites.add(invites[index]);
        }

        _playerGroups[msg.sender].add(newGroupId);
        return newGroupId;
    }

    function deleteGroup(uint240 groupId) external {
        Group storage group = _groups[groupId];
        require(group.leader == msg.sender, "only leader");
        require(group.beasts.length() == 0, "group not empty");
        require(group.state == GroupState.IDLE, "E00: Group already started");
        _playerGroups[msg.sender].remove(groupId);
    }

    function invite(uint240 groupId, address[] calldata invites) external {
        Group storage group = _groups[groupId];
        require(group.leader == msg.sender, "only leader");
        for (uint256 index = 0; index < invites.length; index++) {
            address invitedAddress = invites[index];
            group.invites.add(invitedAddress);
            _playerGroups[invitedAddress].add(groupId);
        }
    }

    function revokeInvite(uint240 groupId, address[] calldata revokes) external {
        Group storage group = _groups[groupId];
        require(group.leader == msg.sender, "only leader");
        uint256[] memory groupBeasts = group.beasts.values();
        for (uint256 index = 0; index < revokes.length; index++) {
            address revokedAddress = revokes[index];
            group.invites.remove(revokedAddress);

            if (!_isAnyBeastFromPlayer(groupBeasts, revokedAddress)) {
                _playerGroups[revokedAddress].remove(groupId);
            }
        }
    }

    function joinGroup(uint240 groupId, uint16 beastId) external {
        _joinGroup(groupId, beastId);
    }

    function joinGroupBatch(uint240 groupId, uint16[] memory beastIds) external {
        for (uint256 index = 0; index < beastIds.length; index++) {
            _joinGroup(groupId, beastIds[index]);
        }
    }

    function _joinGroup(uint240 groupId, uint16 beastId) internal onlyBeastOwner(beastId) {
        BeastState storage beastState = _beastStates[beastId];
        Group storage group = _groups[groupId];
        require(group.state == GroupState.IDLE, "started");
        require(group.beasts.length() < GROUP_SIZE, "full");
        require(!group.isPrivate || group.invites.contains(msg.sender), "private");
        Map memory map = _maps[group.mapId];
        SharedLib.Beast memory beast = SharedLib.representationToBeast(_beastStates[beastId].representation);
        require(beast.level >= map.levelRequirement, "not enough lvl");

        if (map.price > 0) IRagnarokERC20(skullAddress).transferFrom(msg.sender, address(this), map.price);

        beastState.groupId = groupId;

        EnumerableSetUpgradeable.UintSet storage groupBeasts = group.beasts;
        groupBeasts.add(beastId);
        group.stats.con += uint8(beast.stats.con);
        group.stats.str += uint8(beast.stats.str);
        group.stats.dex += uint8(beast.stats.dex);
        group.stats.wis += uint8(beast.stats.wis);
        group.stats.intell += uint8(beast.stats.intell);
        _playerGroups[msg.sender].add(groupId);
    }

    function leaveGroup(uint16 beastId) external {
        _leaveGroup(beastId);
    }

    function _leaveGroup(uint16 beastId) internal onlyBeastOwner(beastId) {
        uint240 groupId = _beastStates[beastId].groupId;
        require(groupId != 0, "not in group");
        Group storage group = _groups[groupId];
        require(group.state == GroupState.IDLE, "started");
        Map memory map = _maps[group.mapId];
        if (map.price > 0) IRagnarokERC20(skullAddress).transfer(msg.sender, map.price);

        _beastStates[beastId].groupId = 0;

        EnumerableSetUpgradeable.UintSet storage groupBeasts = group.beasts;
        SharedLib.Beast memory beast = SharedLib.representationToBeast(_beastStates[beastId].representation);
        groupBeasts.remove(beastId);

        group.stats.con -= uint8(beast.stats.con);
        group.stats.str -= uint8(beast.stats.str);
        group.stats.dex -= uint8(beast.stats.dex);
        group.stats.wis -= uint8(beast.stats.wis);
        group.stats.intell -= uint8(beast.stats.intell);

        if (group.leader != msg.sender && !_isAnyBeastFromPlayer(groupBeasts.values(), msg.sender)) {
            _playerGroups[msg.sender].remove(groupId);
        }
    }

    function offerTears(uint240 groupId, uint256 amount) external {
        uint16 mapId = _groups[groupId].mapId;
        bool isEpic = _maps[mapId].isEpic;
        uint256 maxTears = isEpic ? 2000 ether : 120 ether;
        require(_groupTears[groupId] + amount <= maxTears, "max tears");
        IRagnarokERC20(tearAddress).transferFrom(msg.sender, address(this), amount);
        IRagnarokERC20(tearAddress).burn((amount * 90) / 100);
        _groupTears[groupId] += amount;
    }

    function startGroup(uint240 groupId) external {
        Group storage group = _groups[groupId];
        require(group.state == GroupState.IDLE, "group started");
        require(group.leader == msg.sender, "only leader");
        uint256 groupSize = group.beasts.length();
        Map memory map = _maps[group.mapId];
        require(groupSize >= map.minGroupSize, "group too small");

        IRagnarokERC20(skullAddress).burn((map.price * groupSize * 90) / 100);
        uint256 timeReduction = map.isEpic ? 0 : ((_groupTears[groupId] / 1 ether) * 60); // 1 minute per tear
        group.endTime = block.timestamp + map.duration + map.newDuration - timeReduction;
        group.state = GroupState.STARTED;
        if (map.itemTypeId > 0) {
            _groupRequestIds[groupId] = IRandomOracle(randomOracleAddress).requestRandomNumber();
        }
    }

    function claimAllGroups() external {
        uint256[] memory groups = _playerGroups[msg.sender].values();

        for (uint256 index = 0; index < groups.length; index++) {
            uint240 groupId = uint240(groups[index]);
            Group storage group = _groups[groupId];
            if (group.state != GroupState.IDLE && group.endTime < block.timestamp) {
                _claimGroup(group, false);
            }
        }
    }

    function claimGroup(uint240 groupId) external {
        require(_playerGroups[msg.sender].contains(groupId), "not in group");
        Group storage group = _groups[groupId];
        _claimGroup(group, false);
    }

    function claimGroupAndRerun(uint240 groupId) external {
        require(_playerGroups[msg.sender].contains(groupId), "not in group");
        Group storage group = _groups[groupId];
        _claimGroup(group, true);
    }

    function _claimGroup(Group storage group, bool reRun) internal {
        require(group.state != GroupState.IDLE, "not started");
        require(group.endTime < block.timestamp, "not finished");
        group.state = GroupState.FINISHED;
        Map memory map = _maps[group.mapId];
        (uint32 experience, uint256 skull, , uint256 items) = groupRewards(group.id);
        uint256[] memory groupBeasts = group.beasts.values();
        uint8 playerBeastsInGroup;
        for (uint256 index = 0; index < groupBeasts.length; index++) {
            uint16 beastId = uint16(groupBeasts[index]);
            if (_playerBeasts[msg.sender].contains(beastId)) {
                BeastState storage beastState = _beastStates[beastId];
                beastState.representation = IBeast(beastAddress).giveExperience(beastId, experience);
                beastState.groupId = reRun ? beastState.groupId : 0;
                playerBeastsInGroup++;
            }
        }

        require(!reRun || playerBeastsInGroup == groupBeasts.length, "can't rerun");

        if (items > 0) {
            IRagnarokConsumable(consumableAddress).mint(msg.sender, map.itemTypeId, items);
        }
        IRagnarokERC20(skullAddress).mint(msg.sender, skull);

        if (!reRun) {
            _playerGroups[msg.sender].remove(group.id);
        } else {
            IRagnarokERC20(skullAddress).transferFrom(msg.sender, address(this), map.price * playerBeastsInGroup);
            IRagnarokERC20(skullAddress).burn((map.price * playerBeastsInGroup * 90) / 100);
            IRagnarokERC20(tearAddress).transferFrom(msg.sender, address(this), _groupTears[group.id]);
            IRagnarokERC20(tearAddress).burn((_groupTears[group.id] * 90) / 100);
            uint256 timeReduction = map.isEpic ? 0 : ((_groupTears[group.id] / 1 ether) * 60); // 1 minute per tear
            timeReduction = timeReduction;
            group.endTime = block.timestamp + map.duration + map.newDuration - timeReduction;
            group.state = GroupState.STARTED;
            if (map.itemTypeId > 0) {
                _groupRequestIds[group.id] = IRandomOracle(randomOracleAddress).requestRandomNumber();
            }
        }
    }

    function getGroupDrops(uint240 groupId, address wallet) external view returns (uint256, uint256[] memory) {
        Group storage group = _groups[groupId];
        require(group.state != GroupState.IDLE, "not started");
        require(group.endTime < block.timestamp, "not finished");
        Map memory map = _maps[group.mapId];
        if (map.itemTypeId == 0) {
            return (0, new uint256[](0));
        }
        uint256[] memory groupBeasts = group.beasts.values();
        uint256[] memory drops = new uint256[](groupBeasts.length);
        uint256 randomSeed = IRandomOracle(randomOracleAddress).getRandomNumber(_groupRequestIds[group.id]);
        for (uint256 index = 0; index < groupBeasts.length; index++) {
            drops[index] = _getRandomNumber(randomSeed, index, 100, wallet);
        }
        return (randomSeed, drops);
    }

    function groupRewards(uint240 groupId)
        public
        view
        returns (
            uint32 experience,
            uint256 skull,
            uint256 itemTypeId,
            uint256 items
        )
    {
        Group storage group = _groups[groupId];
        require(group.state != GroupState.IDLE, "not started");
        require(group.endTime < block.timestamp, "not finished");
        Map memory map = _maps[group.mapId];
        itemTypeId = map.itemTypeId;
        experience = (map.expReward * (100 + group.stats.intell / 5)) / 100;
        skull = (map.skullReward * (100 + group.stats.con / 5)) / 100;
        uint256[] memory groupBeasts = group.beasts.values();
        uint8 playerBeastsInGroup;
        for (uint256 index = 0; index < groupBeasts.length; index++) {
            uint16 beastId = uint16(groupBeasts[index]);
            if (_playerBeasts[msg.sender].contains(beastId)) {
                playerBeastsInGroup++;
            }
        }
        skull = skull * playerBeastsInGroup;

        if (map.itemTypeId != 0) {
            uint256 randomSeed = IRandomOracle(randomOracleAddress).getRandomNumber(_groupRequestIds[group.id]);
            uint16 bonus = map.isEpic ? uint16(_groupTears[groupId] / 200 ether) : 0;
            uint16 itemDropProbability = map.itemDropProbability + (group.stats.wis / 10) + bonus;
            for (uint256 index = 0; index < playerBeastsInGroup; index++) {
                if (_getRandomNumber(randomSeed, index, 100, msg.sender) < itemDropProbability) {
                    items++;
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    ADMIN
    //////////////////////////////////////////////////////////////*/

    function setAddresses(
        address _beastAddress,
        address _skullAddress,
        address _tearAddress,
        address _randomOracleAddress,
        address _consumableAddress
    ) external onlyOwner {
        beastAddress = _beastAddress;
        skullAddress = _skullAddress;
        tearAddress = _tearAddress;
        randomOracleAddress = _randomOracleAddress;
        consumableAddress = _consumableAddress;
    }

    function withdraw(
        address to,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IRagnarokERC20(tokenAddress).transfer(to, amount);
    }

    function registerMapRaw(
        uint32 duration,
        uint256 price,
        uint8 levelRequirement,
        uint8 minGroupSize,
        uint16[GROUP_SIZE] calldata requiredClasses,
        uint64 itemTypeId,
        uint8 itemDropProbability,
        uint256 skullReward,
        uint32 expReward,
        bool isEpic
    ) external onlyOwner {
        _mapIds++;
        uint16 id = _mapIds;
        require(_maps[id].id == 0, "existing map");

        _maps[id] = Map(
            id,
            0,
            price,
            levelRequirement,
            minGroupSize,
            requiredClasses,
            itemTypeId,
            itemDropProbability,
            skullReward,
            expReward,
            duration,
            isEpic
        );
    }

    function updateMapRaw(
        uint16 id,
        uint32 duration,
        uint256 price,
        uint8 levelRequirement,
        uint8 minGroupSize,
        uint16[GROUP_SIZE] calldata requiredClasses,
        uint64 itemTypeId,
        uint8 itemDropProbability,
        uint256 skullReward,
        uint32 expReward,
        bool isEpic
    ) external onlyOwner {
        require(_maps[id].id != 0, "invalid map");
        _maps[id] = Map(
            id,
            0,
            price,
            levelRequirement,
            minGroupSize,
            requiredClasses,
            itemTypeId,
            itemDropProbability,
            skullReward,
            expReward,
            duration,
            isEpic
        );
    }

    /*///////////////////////////////////////////////////////////////
                    GETTERS
    //////////////////////////////////////////////////////////////*/

    function getMap(uint16 mapId) external view onlyExistingMaps(mapId) returns (Map memory) {
        return _maps[mapId];
    }

    function getMaps() external view returns (Map[] memory) {
        Map[] memory maps = new Map[](_mapIds);
        for (uint16 index = 1; index <= _mapIds; index++) {
            maps[index] = _maps[index];
        }
        return maps;
    }

    function getStakedBeasts(address player) external view returns (uint256[] memory) {
        return _playerBeasts[player].values();
    }

    function getGroups(address player) public view returns (PublicGroup[] memory) {
        uint256[] memory playerGroups = _playerGroups[player].values();
        PublicGroup[] memory publicGroups = new PublicGroup[](playerGroups.length);

        for (uint256 index = 0; index < playerGroups.length; index++) {
            uint240 groupId = uint240(playerGroups[index]);
            Group storage group = _groups[groupId];
            publicGroups[index] = PublicGroup({
                id: groupId,
                mapId: group.mapId,
                leader: group.leader,
                endTime: group.endTime,
                isPrivate: group.isPrivate,
                beasts: _getBeastStates(group.beasts.values()),
                invites: group.invites.values(),
                state: group.state,
                tears: _groupTears[groupId],
                stats: group.stats
            });
        }

        return publicGroups;
    }

    function getPlayerState(address player) external view returns (PublicGroup[] memory, uint256[] memory) {
        PublicGroup[] memory groups = getGroups(player);
        uint256[] memory beasts = _playerBeasts[player].values();
        return (groups, beasts);
    }

    function getGroup(uint240 groupId) external view returns (PublicGroup memory) {
        Group storage group = _groups[groupId];
        return
            PublicGroup({
                id: groupId,
                mapId: group.mapId,
                leader: group.leader,
                endTime: group.endTime,
                isPrivate: group.isPrivate,
                beasts: _getBeastStates(group.beasts.values()),
                invites: group.invites.values(),
                state: group.state,
                tears: _groupTears[groupId],
                stats: group.stats
            });
    }

    function isOwnerOfBeast(address player, uint256 beastId) external view returns (bool) {
        return _playerBeasts[player].contains(beastId) && _beastStates[uint16(beastId)].groupId == 0;
    }

    /*///////////////////////////////////////////////////////////////
                    PRIVATE
    //////////////////////////////////////////////////////////////*/

    function _getBeastStates(uint256[] memory beastIds) internal view returns (BeastState[] memory) {
        BeastState[] memory beastStates = new BeastState[](beastIds.length);
        for (uint256 index = 0; index < beastIds.length; index++) {
            beastStates[index] = _beastStates[uint16(beastIds[index])];
        }
        return beastStates;
    }

    function _isAnyBeastFromPlayer(uint256[] memory beastIds, address player) internal view returns (bool) {
        for (uint256 index = 0; index < beastIds.length; index++) {
            uint16 beastId = uint16(beastIds[index]);
            if (_playerBeasts[player].contains(beastId)) {
                return true;
            }
        }
        return false;
    }

    function _getRandomNumber(
        uint256 seed,
        uint256 nonce,
        uint256 limit,
        address wallet
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, nonce, wallet))) % limit;
    }

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBeastOwner(uint16 beastId) {
        require(_playerBeasts[msg.sender].contains(beastId), "only beast owner");
        _;
    }

    modifier onlyExistingMaps(uint16 mapId) {
        require(_maps[mapId].id != 0, "E07: The map does not exists");
        _;
    }

    // MANDATORY OVERRIDES

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
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
    function mint(address to, uint16 id) external;

    function mintRandom(
        address to,
        uint16 rarity,
        uint256 randomSeed
    ) external;

    function getItemsByRarity(uint16 rarity) external view returns (uint16[] memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function getItemType(uint16 itemTypeId) external view returns (uint256);
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
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(uint256 id, uint256 amount) external;

    function burnBatch(uint256[] calldata ids, uint256[] memory amounts) external;

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

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;
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

    function getBeastClassNumberRepresentation(uint256 beastId) external view returns (uint16);

    function giveExperience(uint256 beastId, uint32 experience) external returns (uint256);

    function getBeastRepresentation(uint256 beastId) external view returns (uint256);

    function pull(address owner, uint256[] calldata ids) external;
}

interface IRagnarokConsumable {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

interface IERC721Puller {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface IRandomOracle {
    function getRandomNumber(bytes32 requestId) external view returns (uint256);

    function requestRandomNumber() external returns (bytes32 requestId);
}

interface IBeastStaker {
    function getStakedBeasts(address player) external view returns (uint256[] memory);

    function isOwnerOfBeast(address player, uint256 beastId) external view returns (bool);
}

interface IExperienceTable {
    function getLevelUpExperience(uint8 currentLvl) external pure returns (uint32);

    function getNewBeastLevel(uint8 currentLvl, uint32 newExperience) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SharedLib {
    uint256 public constant FACTIONS = 6;
    uint256 public constant CLASSES = FACTIONS * 2;

    struct Stats {
        uint256 hp;
        uint256 mana;
        uint256 con;
        uint256 str;
        uint256 dex;
        uint256 wis;
        uint256 intell;
    }

    struct TightStats {
        uint16 hp;
        uint16 mana;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
    }

    struct AdditionalStats {
        Stats relic;
        Stats assignment;
    }

    struct Beast {
        uint256 level;
        uint256 experience;
        uint256 faction;
        uint256 class;
        Stats stats;
        uint256 slot0;
        uint256 slot1;
        uint256 slot2;
        uint256 slot3;
    }

    struct TightBeast {
        uint8 level;
        uint32 experience;
        uint8 faction;
        uint8 class;
        uint16 hp;
        uint16 mana;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
        uint16 slot0;
        uint16 slot1;
        uint16 slot2;
        uint16 slot3;
    }

    function statsToRepresentation(Stats memory stats) internal pure returns (uint256) {
        uint256 representation = uint256(stats.hp);
        representation |= stats.mana << 16;
        representation |= stats.con << 32;
        representation |= stats.str << 40;
        representation |= stats.dex << 48;
        representation |= stats.wis << 56;
        representation |= stats.intell << 64;

        return representation;
    }

    function representationToStats(uint256 representation) internal pure returns (Stats memory stats) {
        stats.hp = uint16(representation);
        stats.mana = uint16(representation >> 16);
        stats.con = uint8(representation >> 32);
        stats.str = uint8(representation >> 40);
        stats.dex = uint8(representation >> 48);
        stats.wis = uint8(representation >> 56);
        stats.intell = uint8(representation >> 64);
    }

    function beastToRepresentation(Beast memory beast) internal pure returns (uint256) {
        uint256 representation = uint256(beast.level);
        representation |= beast.experience << 8;
        representation |= beast.faction << 40;
        representation |= beast.class << 48;

        representation |= beast.stats.hp << 56;
        representation |= beast.stats.mana << 72;
        representation |= beast.stats.con << 88;
        representation |= beast.stats.str << 96;
        representation |= beast.stats.dex << 104;
        representation |= beast.stats.wis << 112;
        representation |= beast.stats.intell << 120;
        representation |= beast.slot0 << 136;
        representation |= beast.slot1 << 152;
        representation |= beast.slot2 << 168;
        representation |= beast.slot3 << 184;

        return representation;
    }

    function representationToBeast(uint256 representation) internal pure returns (Beast memory beast) {
        beast.level = uint8(representation);
        beast.experience = uint32(representation >> 8);
        beast.faction = uint8(representation >> 40);
        beast.class = uint8(representation >> 48);
        beast.stats = representationToStats(representation >> 56);
        beast.slot0 = uint16(representation >> 136); // this leaves a uint8 empty slot
        beast.slot1 = uint16(representation >> 152);
        beast.slot2 = uint16(representation >> 168);
        beast.slot3 = uint16(representation >> 184);
    }

    function additionalStatsToRepresentation(AdditionalStats memory additionalStats) internal pure returns (uint256) {
        uint256 representation = uint256(statsToRepresentation(additionalStats.relic));
        representation |= statsToRepresentation(additionalStats.assignment) << 72;

        return representation;
    }

    function representationToAdditionalStats(uint256 representation)
        internal
        pure
        returns (AdditionalStats memory additionalStats)
    {
        additionalStats.relic = representationToStats(representation);
        additionalStats.assignment = representationToStats(representation >> 72);
    }

    struct ItemType {
        uint256 rarity;
        uint256 levelRequirement;
        uint256 con;
        uint256 str;
        uint256 dex;
        uint256 wis;
        uint256 intell;
        uint256[4] slots;
        uint256[6] classes;
    }
    struct TightItemType {
        uint8 rarity;
        uint8 levelRequirement;
        uint8 con;
        uint8 str;
        uint8 dex;
        uint8 wis;
        uint8 intell;
        uint8[4] slots;
        uint8[6] classes;
    }

    function itemTypeToRepresentation(ItemType memory itemType) internal pure returns (uint256) {
        uint256 representation = uint256(itemType.rarity);
        representation |= itemType.levelRequirement << 8;
        representation |= itemType.con << 16;
        representation |= itemType.str << 32;
        representation |= itemType.dex << 40;
        representation |= itemType.wis << 48;
        representation |= itemType.intell << 56;
        uint8 lastPosition = 56;
        for (uint256 index = 0; index < 4; index++) {
            lastPosition += 8;
            representation |= itemType.slots[index] << lastPosition;
        }
        for (uint256 index = 0; index < 6; index++) {
            lastPosition += 8;
            representation |= itemType.classes[index] << lastPosition;
        }

        return representation;
    }

    function itemTypeToStats(ItemType memory itemType) internal pure returns (Stats memory stats) {
        stats.con = itemType.con;
        stats.str = itemType.str;
        stats.dex = itemType.dex;
        stats.wis = itemType.wis;
        stats.intell = itemType.intell;
    }

    function representationToItemType(uint256 representation) internal pure returns (ItemType memory itemType) {
        itemType.rarity = uint8(representation);
        itemType.levelRequirement = uint8(representation >> 8);
        itemType.con = uint8(representation >> 16);
        itemType.str = uint8(representation >> 32);
        itemType.dex = uint8(representation >> 40);
        itemType.wis = uint8(representation >> 48);
        itemType.intell = uint8(representation >> 56);
        uint8 lastPosition = 56;
        for (uint256 index = 0; index < 4; index++) {
            lastPosition += 8;
            itemType.slots[index] = uint8(representation >> lastPosition);
        }
        for (uint256 index = 0; index < 6; index++) {
            lastPosition += 8;
            itemType.classes[index] = uint8(representation >> lastPosition);
        }
    }

    function classToNumberRepresentation(uint8 faction, uint8 class) internal pure returns (uint8) {
        if (class == 0) {
            return 0;
        }
        return uint8(faction * FACTIONS + class);
    }

    function numberRepresentationToFaction(uint16 numberRepresentation) internal pure returns (uint8) {
        return uint8(numberRepresentation / FACTIONS);
    }

    function numberRepresentationToClass(uint8 numberRepresentation) internal pure returns (uint8) {
        return uint8(numberRepresentation % FACTIONS);
    }
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