// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./LootClassification2.sol";

contract Dungeon3 is Ownable
{
    enum RaiderType
    {
        Loot,
        MLoot,
        GLoot
    }

    uint constant MAX_RAIDS_PER_DUNGEON = 1000;

    uint256[16] public _dungeons;
    uint256 _nextDungeonCompleteRank;
    mapping(uint256 => uint256) _raids; // maps tokenId => packed raid data
    uint256[16] _lastRaidForDungeon;
    LootClassification internal _lootClassification;
    mapping(address => bool) public _relayAddresses;
    mapping(address => uint256) public replayNonce;
    bool public _raidingLocked;
    mapping(address => uint256) public _lastRaidForAddress; // address => last free raid block number
    uint256 public _blocksBetweenRaids;

    modifier onlyRelay {
        require(_relayAddresses[msg.sender], "RELAY_ONLY");
        _;
    }

    string constant _EnemiesTag = "ENEMIES";
    uint256 constant ENEMY_COUNT = 18;
    string[] private _enemies = [
        // vulnerable to Warriors
        "Orcs",
        "Giant Spiders",
        "Trolls",
        "Zombies",
        "Giant Rats",

        // vulnerable to Hunters
        "Minotaurs",
        "Werewolves",
        "Berserkers",
        "Goblins",
        "Gnomes",

        // vulnerable to Mages   (wands)
        "Ghouls",
        "Wraiths",
        "Skeletons",
        "Revenants",

        // vulnerable to Mages   (books)
        "Necromancers",
        "Warlocks",
        "Wizards",
        "Druids"
    ];

    string constant _TrapsTag = "TRAPS";
    uint256 constant TRAP_COUNT = 15;
    string[] private _traps = [

        // vulnerable to Mages
        "Trap Doors",
        "Poison Darts",
        "Flame Jets",
        "Poisoned Well",
        "Falling Net",

        // vulnerable to Hunters
        "Blinding Light",
        "Lightning Bolts",
        "Pendulum Blades",
        "Snake Pits",
        "Poisonous Gas",

        // vulnerable to Warrirors
        "Lava Pits",
        "Burning Oil",
        "Fire-Breathing Gargoyle",
        "Hidden Arrows",
        "Spiked Pits"
    ];

    string constant _MonsterTag = "MONSTERS";
    uint256 constant MONSTER_COUNT = 15;
    string[] private _bossMonsters = [
        // vulnerable to Warrirors
        "Golden Dragon",
        "Black Dragon",
        "Bronze Dragon",
        "Red Dragon",
        "Wyvern",

        // vulnerable to Hunters
        "Fire Giant",
        "Storm Giant",
        "Ice Giant",
        "Frost Giant",
        "Hill Giant",

        // vulnerable to Mages
        "Ogre",
        "Skeleton Lords",
        "Knights of Chaos",
        "Lizard Kings",
        "Medusa"
    ];

    string constant _ArtefactTag = "ARTEFACTS";
    uint256 constant ARTEFACT_COUNT = 15;
    string[] private _artefacts = [

        // vulnerable to Warrirors
        "The Purple Orb of Zhang",
        "The Horn of Calling",
        "The Wondrous Twine of Ping",
        "The Circle of Squares",
        "The Scroll of Serpents",

        // vulnerable to Hunters
        "The Rod of Runes",
        "Crystal of Crimson Light",
        "Oil of Darkness",
        "Bonecrusher Bag",
        "Mirror of Madness",

        // vulnerable to Mages
        "Ankh of the Ancients",
        "The Wand of Fear",
        "The Tentacles of Terror",
        "The Altar of Ice",
        "The Creeping Hand"
    ];

    string constant _PassagewaysTag = "PASSAGEWAYS";
    uint256 constant PASSAGEWAYS_COUNT = 15;
    string[] private _passageways = [

        // vulnerable to Warrirors
        "Crushing Walls",
        "Loose Logs",
        "Rolling Rocks",
        "Spiked Floor",
        "Burning Coals",

         // vulnerable to Hunters
        "The Hidden Pit of Doom",
        "The Sticky Stairs",
        "The Bridge of Sorrow",
        "The Maze of Madness",
        "The Flooded Tunnel",

        // vulnerable to Mages
        "The Floor of Fog",
        "The Frozen Floor",
        "The Shifting Sands",
        "The Trembling Trap",
        "The Broken Glass Floor"
    ];

    string constant _RoomsTag = "ROOMS";
    uint256 constant ROOM_COUNT = 15;
    string[] private _rooms = [

        // vulnerable to Warrirors
        "Room of Undead Hands",
        "Room of the Stone Claws",
        "Room of Poison Arrows",
        "Room of the Iron Bear",
        "Room of the Wandering Worm",

        // vulnerable to Hunters
        "Room of the Infernal Beast",
        "Room of the Infected Slime",
        "Room of the Horned Rats",
        "Room of the Flaming Hounds",
        "Room of the Million Maggots",

        // vulnerable to Mages
        "Room of the Flaming Pits",
        "Room of the Rabid Flesh Eaters",
        "Room of the Grim Golem",
        "Room of the Chaos Firebreathers",
        "Room of the Nightmare Clones"
    ];

    string constant _TheSoullessTag = "SOULLESS";
    uint256 constant SOULLESS_COUNT = 3;
    string[] private _theSoulless = [

        "Lich Queen",
        "Zombie Lord",
        "The Grim Reaper"
    ];

    string constant _DemiGodTag = "ELEMENTS";
    uint256 constant DEMIGOD_COUNT = 5;
    string[] private _demiGods = [

        "The Bone Demon",
        "The Snake God",
        "The Howling Banshee",
        "Demonspawn",
        "The Elementals"
    ];

    function getTraitIndex(uint256 seed, string memory traitName, uint256 traitCount) public pure returns (uint256)
    {
        return pluckDungeonTrait(seed, traitName, traitCount);
    }

    function getTraitName(uint256 seed, string memory traitName, string[] storage traitList) private view returns (string memory)
    {
        if (seed == 0) {
            return ""; // unrevealed
        }
        uint256 index = getTraitIndex(seed, traitName, traitList.length);
        return traitList[index];
    }

    function pluckDungeonTrait(uint256 seed, string memory keyPrefix, uint256 traitCount) internal pure returns (uint256)
    {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(seed))));

        uint256 index = rand % traitCount;
        return index;
    }

    constructor(
        uint[8] memory startHitPoints,
        address lootClassificationAddress,
        uint256 blocksBetweenRaids
    )
    {
        _lootClassification = LootClassification(lootClassificationAddress);
        // _relic = Relic(relicAddress);

        _nextDungeonCompleteRank = 0;

        _raidingLocked = true;
        _blocksBetweenRaids = blocksBetweenRaids;

        uint256[3] memory startSeeds;

        for (uint16 dungeonId = 0; dungeonId < 16; dungeonId++)
        {
            startSeeds[0] = newLevelSeed(dungeonId, 0);
            _dungeons[dungeonId] = packDungeon(16, startHitPoints, startSeeds);
        }
    }

    event Raid
    (
        uint256 indexed dungeonId,
        RaiderType raiderType,
        uint256 raidTokenId,
        uint256[8] damage,
        address ownerAddress
    );

    function packRaidKey(
        RaiderType raidTokenType,
        uint256 raidTokenId
    ) public pure returns (
        uint256 packed
    ) {
        packed |= uint256(uint8(raidTokenType)) << 128;
        packed |= uint256(uint128(raidTokenId));
    }

    function unpackRaidKey(
        uint256 packed
    ) public pure returns (
        RaiderType raidTokenType,
        uint256 raidTokenId
    ) {
        raidTokenType = RaiderType(uint8(packed >> 128));
        raidTokenId = uint256(uint128(packed));
    }

    // raidTokens is an array of 8 lootTokenIds used to raid
    // tokenId is the id of the parent token
    function raidDungeon(
        uint dungeonId,
        uint256 tokenId,
        uint256[8] memory raidTokenIds,
        RaiderType raiderType,
        uint8 order,
        address ownerAddress)
        public onlyRelay
    {
        require(!_raidingLocked, "raiding is locked");

        uint256 raiderKey = packRaidKey(raiderType, tokenId);
        require(_raids[raiderKey] == 0, "loot already used in a raid");

        require(dungeonId < _dungeons.length, "invalid dungeon");

        require(canRaid(ownerAddress), "wait interval between raids not met");

        (uint256 rank,
        uint256[8] memory dungeonHitPoints,
        uint256[3] memory seeds) = unpackDungeon(_dungeons[dungeonId]);

        require(rank == _dungeons.length, "dungeon already complete");

        uint256 dungeonLevel = _getDungeonLevel(dungeonHitPoints);
        require(dungeonLevel == _getRaiderLevel(raiderType), "incorrect loot for level");

        uint256[9] memory raidHitPoints = getRaidHitPoints(
            dungeonId,
            seeds,
            dungeonHitPoints,
            tokenId,
            raidTokenIds,
            order,
            raiderType
        );
        require(raidHitPoints[8] > 0, "raid would have no affect");

        for (uint i = 0; i < 8; i++) {
            // it's safe to blind delete the raidHitPoints from the dungeonHitPoints
            // because the getRaidHitPoints already limits them to dungeonHitPoints
            dungeonHitPoints[i] -= raidHitPoints[i];
        }

        setRaid(raiderKey, dungeonId, raidHitPoints[8]);

        uint256 dungeonLevelAfterRaid = _getDungeonLevel(dungeonHitPoints);
        if (dungeonLevelAfterRaid == 3) { // level 3 == "complete"
            rank = _nextDungeonCompleteRank;
            _nextDungeonCompleteRank++;
        } else if (dungeonLevelAfterRaid > dungeonLevel) {
            seeds[dungeonLevelAfterRaid] = newLevelSeed(dungeonId, dungeonLevelAfterRaid);
        }

        _dungeons[dungeonId] = packDungeon(rank, dungeonHitPoints, seeds);

        _lastRaidForAddress[ownerAddress] = block.number;

        emit Raid(dungeonId, raiderType, tokenId,  [
            raidHitPoints[0],
            raidHitPoints[1],
            raidHitPoints[2],
            raidHitPoints[3],
            raidHitPoints[4],
            raidHitPoints[5],
            raidHitPoints[6],
            raidHitPoints[7]],
            ownerAddress);
    }

    function setRaid(uint256 raidKey, uint dungeonId, uint256 raidScore) private
    {
        (RaiderType prevRaidTokenType, uint256 prevRaidTokenId) = unpackRaidKey(_lastRaidForDungeon[dungeonId]);
        _raids[raidKey] = packRaid(dungeonId, raidScore, prevRaidTokenType, prevRaidTokenId);
        _lastRaidForDungeon[dungeonId] = raidKey;
    }

    function newLevelSeed(uint dungeonId, uint level) public view returns (uint256)
    {
        return (uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            dungeonId,
            level
        ))) % 4000) + 1;
    }

    function withdraw() public onlyOwner
    {
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "failed to send");
    }

    function setRaidingLock(bool locked) external onlyOwner
    {
        _raidingLocked = locked;
    }

    function packRaid(
        uint256 dungeonId,
        uint256 raidScore,
        RaiderType prevRaidTokenType,
        uint256 prevRaidTokenId
    ) private pure returns(
        uint256 packed
    ) {
        packed = dungeonId
        | raidScore << 16
        | uint256(prevRaidTokenType) << 32
        | prevRaidTokenId << 64;
        return packed;
    }

    function unpackRaid(
        uint256 packed
    ) private pure returns(
        uint256 dungeonId,
        uint256 raidScore,
        RaiderType prevRaidTokenType,
        uint256 prevRaidTokenId
    ) {
        dungeonId = (packed >> 0) & 0xff;
        raidScore = (packed >> 16) & 0xffff;
        prevRaidTokenType = RaiderType((packed >> 32) & 0xf);
        prevRaidTokenId = (packed >> 64) & 0xffffffff;
    }

    function packDungeon(uint256 rank, uint256[8] memory hitPoints, uint256[3] memory seeds)
        private pure returns(uint256 packed)
    {
        packed = rank
        | (hitPoints[0] << 8)
        | (hitPoints[1] << 21)
        | (hitPoints[2] << 34)
        | (hitPoints[3] << 47)
        | (hitPoints[4] << 60)
        | (hitPoints[5] << 73)
        | (hitPoints[6] << 86)
        | (hitPoints[7] << 99);
        packed = packed
        | (seeds[0] << 112)
        | (seeds[1] << 125)
        | (seeds[2] << 138);
        return packed;
    }

    function unpackDungeon(uint256 packed)
        private pure returns(uint256 rank, uint256[8] memory hitPoints, uint256[3] memory seeds)
    {
        rank = packed & 0xff;
        hitPoints[0] = (packed >> 8) & 0x1fff;
        hitPoints[1] = (packed >> 21) & 0x1fff;
        hitPoints[2] = (packed >> 34) & 0x1fff;
        hitPoints[3] = (packed >> 47) & 0x1fff;
        hitPoints[4] = (packed >> 60) & 0x1fff;
        hitPoints[5] = (packed >> 73) & 0x1fff;
        hitPoints[6] = (packed >> 86) & 0x1fff;
        hitPoints[7] = (packed >> 99) & 0x1fff;
        seeds[0] = (packed >> 112) & 0x1fff;
        seeds[1] = (packed >> 125) & 0x1fff;
        seeds[2] = (packed >> 138) & 0x1fff;
    }

    struct DungeonInfo
    {
        uint256 id;
        uint256 orderIndex;
        string enemies;
        string traps;
        string bossMonster;
        string artefact;
        string passageways;
        string rooms;
        string theSoulless;
        string demiGod;
        uint256[8] hitPoints;
        bool isOpen;
        uint256 level;
        uint256 rank;
        uint256[3] seeds;
    }

    function getDungeons() public view returns(DungeonInfo[16] memory dungeons)
    {
        for (uint dungeonId = 0; dungeonId < 16; ++dungeonId)
        {
            dungeons[dungeonId] = getDungeon(dungeonId);
        }

        return dungeons;
    }

    function getDungeon(uint dungeonId) public view returns(DungeonInfo memory dungeonInfo)
    {
        (uint256 rank, uint256[8] memory remainingHitPoints, uint256[3] memory seeds) = unpackDungeon(_dungeons[dungeonId]);
        dungeonInfo.id = dungeonId;
        dungeonInfo.orderIndex = getDungeonOrderIndex(dungeonId);
        dungeonInfo.enemies = getTraitName(seeds[0], _EnemiesTag, _enemies);
        dungeonInfo.theSoulless = getTraitName(seeds[0], _TheSoullessTag, _theSoulless);
        dungeonInfo.demiGod = getTraitName(seeds[0], _DemiGodTag, _demiGods);
        dungeonInfo.passageways = getTraitName(seeds[1], _PassagewaysTag, _passageways);
        dungeonInfo.rooms = getTraitName(seeds[1], _RoomsTag, _rooms);
        dungeonInfo.traps = getTraitName(seeds[2], _TrapsTag, _traps);
        dungeonInfo.bossMonster = getTraitName(seeds[2], _MonsterTag, _bossMonsters);
        dungeonInfo.artefact = getTraitName(seeds[2], _ArtefactTag, _artefacts);
        dungeonInfo.hitPoints = remainingHitPoints;
        dungeonInfo.isOpen = rank == _dungeons.length;
        dungeonInfo.level = _getDungeonLevel(remainingHitPoints);
        dungeonInfo.seeds = seeds;
        dungeonInfo.rank = rank;
        return dungeonInfo;
    }

    struct Claim
    {
        uint dungeonId;
        uint dungeonRank;
        uint256 raidTokenId;
        RaiderType raidTokenType;
        uint8 raidRank;
        uint256 raidScore;
        uint count;
    }

    function getDungeonClaims(uint dungeonId) public view returns (Claim[MAX_RAIDS_PER_DUNGEON] memory claims, uint len)
    {
        // fetch dungeon info
        (uint256 dungeonRank,,) = unpackDungeon(_dungeons[dungeonId]);
        require(dungeonRank != _dungeons.length, "dungeon still open");
        // get last raid for dungeon
        uint256 raidKey = _lastRaidForDungeon[dungeonId];
        // build list of all raids as claims
        while (raidKey != 0) {
            (RaiderType raidTokenType, uint256 raidTokenId) = unpackRaidKey(raidKey);
            (,uint256 raidScore, RaiderType prevRaidTokenType, uint256 prevRaidTokenId) = unpackRaid(_raids[raidKey]);
            claims[len].dungeonId = dungeonId;
            claims[len].dungeonRank = dungeonRank;
            claims[len].raidTokenId = raidTokenId;
            claims[len].raidTokenType = raidTokenType;
            claims[len].raidScore = (raidScore * 1000000) + (MAX_RAIDS_PER_DUNGEON - len); // primarily damage, secondary raid order
            raidKey = packRaidKey(RaiderType(prevRaidTokenType), prevRaidTokenId);
            len++;
            require(len < MAX_RAIDS_PER_DUNGEON, "too many raids");
        }
        // sort raids by score desc
        _sortClaims(claims, int(0), int(len - 1));
        // slice first 84 raids, raidRank=0
        uint maxWin = len < 84 ? len : 84;
        uint j = 0;
        for (j = 0; j<maxWin; j++) {
            claims[j].raidRank = 0;
            claims[j].count = 1;
        }
        // slice next 330 raids, raidRank=1
        uint maxRun = len < 414 ? len : 414;
        for (j = 84; j<maxRun; j++) {
            claims[j].raidRank = 1;
            claims[j].count = 1;
        }
    }

    function _sortClaims(Claim[MAX_RAIDS_PER_DUNGEON] memory claims, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = claims[uint(left + (right - left) / 2)].raidScore;
        while (i <= j) {
            while (claims[uint(i)].raidScore > pivot) i++;
            while (pivot > claims[uint(j)].raidScore) j--;
            if (i <= j) {
                (claims[uint(i)], claims[uint(j)]) = (claims[uint(j)], claims[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) {
            _sortClaims(claims, left, j);
        }
        if (i < right) {
            _sortClaims(claims, i, right);
        }
    }

    function getDungeonOrderIndex(uint dungeonId) pure public returns (uint)
    {
        return dungeonId % 16;
    }

    // returns current "level" of dungeon 0,1,2
    // returns 3 for completed dungeon
    function _getDungeonLevel(uint256[8] memory remainingHitPoints) pure public returns (uint256)
    {
        if (remainingHitPoints[0] != 0 || remainingHitPoints[6] != 0 || remainingHitPoints[7] != 0) {
            // Enemies=0
            // The Soulless=6
            // DemiGods=7
            return 0;
        } else if (remainingHitPoints[4] != 0 || remainingHitPoints[5] != 0) {
            // Passageways=4
            // Rooms=5
            return 1;
        } else if (remainingHitPoints[1] != 0 || remainingHitPoints[3] != 0 || remainingHitPoints[2] != 0) {
            // Traps=1
            // Artefacts=3
            // Boss Monster=2
            return 2;
        } else {
            // Dungeon Conquered
            return 3;
        }
    }

    function _getRaiderLevel(RaiderType raiderType) pure public returns (uint256)
    {
        if (raiderType == RaiderType.Loot) {
            return 0;
        } else if (raiderType == RaiderType.MLoot) {
            return 1;
        } else if (raiderType == RaiderType.GLoot) {
            return 2;
        }
        require(false, "invalid raider type");
        return 999;
    }

    function _getItemHitPoints(
        uint256 dungeonId,
        uint256 seed,
        uint256[6] memory lootComponents,
        string memory traitName,
        uint256 traitCount,
        LootClassification.Type lootType) internal view returns(uint)
    {
        uint256 dungeonTraitIndex = getTraitIndex(seed, traitName, traitCount);
        uint256 lootTypeIndex = lootComponents[0];

        // Hit points awarded for following
        // perfect match: 20
        // class match with high enough rank: 20
        // order match: 40
        // order match "+1": 20
        // rating added on top if other scoring is > 0

        bool orderMatch = lootComponents[1] == (getDungeonOrderIndex(dungeonId) + 1);
        uint256 hpScore;

        if (orderMatch)
        {
            hpScore = 40;
            if (lootComponents[4] > 0)
            {
                hpScore += 20;
            }
        }

        if (lootTypeIndex == 0xff)
        {
            // this is a lost mana item, which will not score anything for itme matching or rating
            return hpScore;
        }

        if (dungeonTraitIndex == lootTypeIndex)
        {
            // perfect match (and presumed class match)
            hpScore += 40;
        }
        else
        {
            // there is an order match but not direct hit
            // if the item is of the correct class and more powerful than exact macth get the order orderScore
            LootClassification.Class dungeonClass = _lootClassification.getClass(lootType, dungeonTraitIndex);
            LootClassification.Class lootClass = _lootClassification.getClass(lootType, lootTypeIndex);
            if (dungeonClass == lootClass && dungeonClass != LootClassification.Class.Any)
            {
                uint256 dungeonRank = _lootClassification.getRank(lootType, dungeonTraitIndex);
                uint256 lootRank = _lootClassification.getRank(lootType, lootTypeIndex);

                if (lootRank <= dungeonRank)
                {
                    // class hit of high enough rank
                    hpScore += 20;
                }
            }
        }

        if (hpScore > 0)
        {
            // rating == level * greatness
            uint256 rating = _lootClassification.getLevel(lootType, lootTypeIndex) * lootComponents[5];
            hpScore += rating;
        }

        return hpScore;
    }

    function applyRaidItem(
        uint raidIndex,
        uint256 raidScore,
        uint256 maxScore,
        uint256[9] memory results) pure private
    {
        uint256 score = (raidScore > maxScore) ? maxScore : raidScore;
        results[raidIndex] = score;
        results[8] += score;
    }

    function _getItemHitPointsGeneric(
            uint256 dungeonId,
            uint256 seed,
            uint256 lootTokenId,
            uint256[6] memory lostMana,
            string memory dungeonTypeTag,
            uint256 dungeonTypeCount,
            LootClassification.Type lootType,
            function (uint256) external pure returns (uint256[6] memory) componentFunc
        )
        view private returns (uint256)
    {
        uint256[6] memory components;
        if (lootTokenId > 0)
        {
            components = componentFunc(lootTokenId);
        }
        else
        {
            components = lostMana;
        }
        return _getItemHitPoints(dungeonId, seed, components, dungeonTypeTag, dungeonTypeCount, lootType);
    }

    // itemIds is the list of 8 inventory ids used to raid
    // tokenId is the parent NFT id
    function getCurrentRaidHitPoints(
        uint256 dungeonId,
        uint256 tokenId,
        uint256[8] memory itemIds,
        uint8 order,
        RaiderType raiderType) view public returns(uint256[9] memory)
    {
        (,uint256[8] memory currentHitPoints, uint256[3] memory seeds) = unpackDungeon(_dungeons[dungeonId]);
        return getRaidHitPoints(dungeonId, seeds, currentHitPoints, tokenId, itemIds, order, raiderType);
    }

    // returns an array of 8 hitpoints these raids would achieved plus a total in the 9th array slot
    // lootTokens is an array of 8 raidTokenIds in inventory
    // orderOverride is used if any of the raidTokenIds are 0 (which is the case of gLoot lost mana items)
    function getRaidHitPoints(
        uint256 dungeonId,
        uint256[3] memory seeds,
        uint256[8] memory currentHitPoints,
        uint256 parentTokenId,
        uint256[8] memory lootTokens,
        uint8 orderOverride,
        RaiderType raiderType) view public returns(uint256[9] memory)
    {
        uint256[9] memory results;

        uint256 raiderKey = packRaidKey(raiderType, parentTokenId);
        if (_raids[raiderKey] != 0)
        {
            return results; // no effect if already used
        }
        uint256 level = _getRaiderLevel(raiderType);
        if (level == 3) {
            return results; // no effect if dungeon already conquered
        }

        if (seeds[level] == 0) {
            return results; // no effect if level not unlocked
        }

        uint256[8] memory itemScores;
        uint256[6] memory lostMana =
            [
                0xff,  // no valid item
                uint256(orderOverride), // order from genesis loot
                0, // no prefix 1
                0, // no prefix 2
                0, // no + 1
                15 // assumed greatness 15
            ];

        LootClassification lootClassification = _lootClassification;

        if (level == 0) {
            // Enemies=0
            // The Soulless=6
            // DemiGods=7
            itemScores[0] = _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[0], lostMana,
                _EnemiesTag, ENEMY_COUNT,
                LootClassification.Type.Weapon, lootClassification.weaponComponents);
            itemScores[6] =  _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[6], lostMana,
                _TheSoullessTag, SOULLESS_COUNT,
                LootClassification.Type.Neck, lootClassification.neckComponents);
            itemScores[7] =  _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[7], lostMana,
                _DemiGodTag, DEMIGOD_COUNT,
                LootClassification.Type.Ring, lootClassification.ringComponents);
        } else if (level == 1) {
            // Passageways=4
            // Rooms=5
            itemScores[4] =  _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[4], lostMana,
                _PassagewaysTag, PASSAGEWAYS_COUNT,
                LootClassification.Type.Foot, lootClassification.footComponents);
            itemScores[5] =  _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[5], lostMana,
                _RoomsTag, ROOM_COUNT,
                LootClassification.Type.Hand, lootClassification.handComponents);
        } else if (level == 2) {
            // Traps=1
            // Artefacts=3
            // Boss Monster=2
            itemScores[1] = _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[1], lostMana,
                _TrapsTag, TRAP_COUNT,
                LootClassification.Type.Chest, lootClassification.chestComponents);
            itemScores[3] =  _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[3], lostMana,
                _ArtefactTag, ARTEFACT_COUNT,
                LootClassification.Type.Waist, lootClassification.waistComponents);
            itemScores[2] =  _getItemHitPointsGeneric(
                dungeonId, seeds[level], lootTokens[2], lostMana,
                _MonsterTag, MONSTER_COUNT,
                LootClassification.Type.Head, lootClassification.headComponents);
        }

        for (uint i = 0; i < 8; i++)
        {
            applyRaidItem(i, itemScores[i], currentHitPoints[i], results);
        }

        return results;
    }

    function getDungeonCount() view public returns(uint256)
    {
        if (_dungeons.length == 0)
        {
            return 99;
        }
        return _dungeons.length;
    }

    function setRelayAddress(address relayAddress, bool active) public onlyOwner
    {
        _relayAddresses[relayAddress] = active;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function canRaid(address account) public view returns(bool)
    {
        return (block.number - _lastRaidForAddress[account]) >= _blocksBetweenRaids;
    }

    function setBlocksBetweenRaids(uint256 blocksBetweenRaids) external onlyOwner
    {
        _blocksBetweenRaids = blocksBetweenRaids;
    }

    function setLastRaidForAddress(address account, uint256 blockNumber) external onlyRelay
    {
        _lastRaidForAddress[account] = blockNumber;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
pragma solidity ^0.8.0;

// v2 of LootClassification copied from https://github.com/playmint/loot-classification/tree/f8d64e4ea071585cbb505ed795491573ad5f9135

/*
LootCLassification.sol
Lootverse Utility contract to classifyitems found in Loot (For Adventurers) Bags.

See OG Loot Contract for lists of all possible items.
https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7

All functions are made public incase they are useful but the expected use is through the main
3 classification functions:

- getRank()
- getClass()
- getMaterial()
- getLevel()

Each of these take an item 'Type' (weapon, chest, head etc.) 
and an index into the list of all possible items of that type as found in the OG Loot contract.

The LootComponents(0x3eb43b1545a360d1D065CB7539339363dFD445F3) contract can be used to get item indexes from Loot bag tokenIDs.
The code from LootComponents is copied into this contract and rewritten for gas efficiency
So a typical use might be:

// get weapon classification for loot bag# 1234
{
    LootClassification classification = 
        LootClassification(_TBD_);

    uint256[5] memory weaponComponents = classification.weaponComponents(1234);
    uint256 index = weaponComponents[0];

    LootClassification.Type itemType = LootClassification.Type.Weapon;
    LootClassification.Class class = classification.getClass(itemType, index);
    LootClassification.Material material = classification.getMaterial(itemType, index);
    uint256 rank = classification.getRank(itemType, index);
    uint256 level = classification.getLevel(itemType, index);
}
*/
contract LootClassification
{
    enum Type
    {
        Weapon,
        Chest,
        Head,
        Waist,
        Foot,
        Hand,
        Neck,
        Ring
    }
    
    enum Material
    {
        Heavy,
        Medium,
        Dark,
        Light,
        Cloth,
        Hide,
        Metal,
        Jewellery
    }
    
    enum Class
    {
        Warrior,
        Hunter,
        Mage,
        Any
    }
    
    uint256 constant public WeaponLastHeavyIndex = 4;
    uint256 constant public WeaponLastMediumIndex = 9;
    uint256 constant public WeaponLastDarkIndex = 13;
    
    function getWeaponMaterial(uint256 index) pure public returns(Material)
    {
        if (index <= WeaponLastHeavyIndex)
            return Material.Heavy;
        
        if (index <= WeaponLastMediumIndex)
            return Material.Medium;
        
        if (index <= WeaponLastDarkIndex)
            return Material.Dark;
        
        return Material.Light;
    }
    
    function getWeaponRank(uint256 index) pure public returns (uint256)
    {
        if (index <= WeaponLastHeavyIndex)
            return index + 1;
        
        if (index <= WeaponLastMediumIndex)
            return index - 4;
        
        if (index <= WeaponLastDarkIndex)
            return index - 9;
        
        return index -13;
    }
    
    uint256 constant public ChestLastClothIndex = 4;
    uint256 constant public ChestLastLeatherIndex = 9;
    
    function getChestMaterial(uint256 index) pure public returns(Material)
    {
        if (index <= ChestLastClothIndex)
            return Material.Cloth;
        
        if (index <= ChestLastLeatherIndex)
            return Material.Hide;
        
        return Material.Metal;
    }
    
    function getChestRank(uint256 index) pure public returns (uint256)
    {
        if (index <= ChestLastClothIndex)
            return index + 1;
        
        if (index <= ChestLastLeatherIndex)
            return index - 4;
        
        return index - 9;
    }
    
    // Head, waist, foot and hand items all follow the same classification pattern,
    // so they are generalised as armour.
    uint256 constant public ArmourLastMetalIndex = 4;
    uint256 constant public ArmourLasLeatherIndex = 9;
    
    function getArmourMaterial(uint256 index) pure public returns(Material)
    {
        if (index <= ArmourLastMetalIndex)
            return Material.Metal;
        
        if (index <= ArmourLasLeatherIndex)
            return Material.Hide;
        
        return Material.Cloth;
    }
    
    function getArmourRank(uint256 index) pure public returns (uint256)
    {
        if (index <= ArmourLastMetalIndex)
            return index + 1;
        
        if (index <= ArmourLasLeatherIndex)
            return index - 4;
        
        return index - 9;
    }
    
    function getRingRank(uint256 index) pure public returns (uint256)
    {
        if (index > 2)
            return 1;
        else 
            return index + 1;
    }
    
    function getNeckRank(uint256 /*index*/) pure public returns (uint256)
    {
        return 1;
    }
    
    function getMaterial(Type lootType, uint256 index) pure public returns (Material)
    {
         if (lootType == Type.Weapon)
            return getWeaponMaterial(index);
            
        if (lootType == Type.Chest)
            return getChestMaterial(index);
            
        if (lootType == Type.Head ||
            lootType == Type.Waist ||
            lootType == Type.Foot ||
            lootType == Type.Hand)
        {
            return getArmourMaterial(index);
        }
            
        return Material.Jewellery;
    }
    
    function getClass(Type lootType, uint256 index) pure public returns (Class)
    {
        Material material = getMaterial(lootType, index);
        return getClassFromMaterial(material);
    }

    function getClassFromMaterial(Material material) pure public returns (Class)
    {   
        if (material == Material.Heavy || material == Material.Metal)
            return Class.Warrior;
            
        if (material == Material.Medium || material == Material.Hide)
            return Class.Hunter;
            
        if (material == Material.Dark || material == Material.Light || material == Material.Cloth)
            return Class.Mage;
            
        return Class.Any;
        
    }
    
    function getRank(Type lootType, uint256 index) pure public returns (uint256)
    {
        if (lootType == Type.Weapon)
            return getWeaponRank(index);
            
        if (lootType == Type.Chest)
            return getChestRank(index);
        
        if (lootType == Type.Head ||
            lootType == Type.Waist ||
            lootType == Type.Foot ||
            lootType == Type.Hand)
        {
            return getArmourRank(index);
        }
        
        if (lootType == Type.Ring)
            return getRingRank(index);
            
        return getNeckRank(index);  
    }

    function getLevel(Type lootType, uint256 index) pure public returns (uint256)
    {
        if (lootType == Type.Chest ||
            lootType == Type.Weapon ||
            lootType == Type.Head ||
            lootType == Type.Waist ||
            lootType == Type.Foot ||
            lootType == Type.Hand)
        {
            return 6 - getRank(lootType, index);
        } else {
            return 4 - getRank(lootType, index); 
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    /*
    Gas efficient implementation of LootComponents
    https://etherscan.io/address/0x3eb43b1545a360d1D065CB7539339363dFD445F3#code
    The actual names are not needed when retreiving the component indexes only
    Header comment from orignal follows:

    // SPDX-License-Identifier: Unlicense
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[6] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
        [5] = Greatness
    
    See the item and attribute tables below for corresponding IDs.
    */

    uint256 constant WEAPON_COUNT = 18;
    uint256 constant CHEST_COUNT = 15;
    uint256 constant HEAD_COUNT = 15;
    uint256 constant WAIST_COUNT = 15;
    uint256 constant FOOT_COUNT = 15;
    uint256 constant HAND_COUNT = 15;
    uint256 constant NECK_COUNT = 3;
    uint256 constant RING_COUNT = 5;
    uint256 constant SUFFIX_COUNT = 16;
    uint256 constant NAME_PREFIX_COUNT = 69;
    uint256 constant NAME_SUFFIX_COUNT = 18;

    function random(string memory input) internal pure returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function weaponComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "WEAPON", WEAPON_COUNT);
    }
    
    function chestComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "CHEST", CHEST_COUNT);
    }
    
    function headComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "HEAD", HEAD_COUNT);
    }
    
    function waistComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "WAIST", WAIST_COUNT);
    }

    function footComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "FOOT", FOOT_COUNT);
    }
    
    function handComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "HAND", HAND_COUNT);
    }
    
    function neckComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "NECK", NECK_COUNT);
    }
    
    function ringComponents(uint256 tokenId) public pure returns (uint256[6] memory) 
    {
        return tokenComponents(tokenId, "RING", RING_COUNT);
    }

    function tokenComponents(uint256 tokenId, string memory keyPrefix, uint256 itemCount) 
        internal pure returns (uint256[6] memory) 
    {
        uint256[6] memory components;
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        
        components[0] = rand % itemCount;
        components[1] = 0;
        components[2] = 0;
        
        components[5] = rand % 21; //aka greatness
        if (components[5] > 14) {
            components[1] = (rand % SUFFIX_COUNT) + 1;
        }
        if (components[5] >= 19) {
            components[2] = (rand % NAME_PREFIX_COUNT) + 1;
            components[3] = (rand % NAME_SUFFIX_COUNT) + 1;
            if (components[5] == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
    }

    function toString(uint256 value) internal pure returns (string memory) 
    {
        // Inspired by OraclizeAPI's implementation - MIT license
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