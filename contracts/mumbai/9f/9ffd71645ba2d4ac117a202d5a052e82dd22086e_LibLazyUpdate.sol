// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

enum PlanetType {PLANET, SILVER_MINE, RUINS, TRADING_POST, SILVER_BANK}
enum PlanetEventType {ARRIVAL}
enum SpaceType {NEBULA, SPACE, DEEP_SPACE, DEAD_SPACE}
enum UpgradeBranch {DEFENSE, RANGE, SPEED}

struct Player {
    bool isInitialized;
    address player;
    uint256 initTimestamp;
    uint256 homePlanetId;
    uint256 lastRevealTimestamp;
    uint256 score;
    uint256 spaceJunk;
    uint256 spaceJunkLimit;
    bool claimedShips;
}

struct Planet {
    address owner;
    uint256 range;
    uint256 speed;
    uint256 defense;
    uint256 population;
    uint256 populationCap;
    uint256 populationGrowth;
    uint256 silverCap;
    uint256 silverGrowth;
    uint256 silver;
    uint256 planetLevel;
    PlanetType planetType;
    bool isHomePlanet;
}

struct RevealedCoords {
    uint256 locationId;
    uint256 x;
    uint256 y;
    address revealer;
}

struct PlanetExtendedInfo {
    bool isInitialized;
    uint256 createdAt;
    uint256 lastUpdated;
    uint256 perlin;
    SpaceType spaceType;
    uint256 upgradeState0;
    uint256 upgradeState1;
    uint256 upgradeState2;
    uint256 hatLevel;
    bool hasTriedFindingArtifact;
    uint256 prospectedBlockNumber;
    bool destroyed;
    uint256 spaceJunk;
}

struct PlanetExtendedInfo2 {
    bool isInitialized;
    uint256 pausers;
    address invader;
    uint256 invadeStartBlock;
    address capturer;
}

// For DFGetters
struct PlanetData {
    Planet planet;
    PlanetExtendedInfo info;
    PlanetExtendedInfo2 info2;
    RevealedCoords revealedCoords;
}

struct AdminCreatePlanetArgs {
    uint256 location;
    uint256 perlin;
    uint256 level;
    PlanetType planetType;
    bool requireValidLocationId;
}

struct PlanetEventMetadata {
    uint256 id;
    PlanetEventType eventType;
    uint256 timeTrigger;
    uint256 timeAdded;
}

enum ArrivalType {Unknown, Normal, Photoid, Wormhole}

struct DFPInitPlanetArgs {
    uint256 location;
    uint256 perlin;
    uint256 level;
    uint256 TIME_FACTOR_HUNDREDTHS;
    SpaceType spaceType;
    PlanetType planetType;
    bool isHomePlanet;
}

struct DFPMoveArgs {
    uint256 oldLoc;
    uint256 newLoc;
    uint256 maxDist;
    uint256 popMoved;
    uint256 silverMoved;
    uint256 movedArtifactId;
    uint256 abandoning;
    address sender;
}

struct DFPFindArtifactArgs {
    uint256 planetId;
    uint256 biomebase;
    address coreAddress;
}

struct DFPCreateArrivalArgs {
    address player;
    uint256 oldLoc;
    uint256 newLoc;
    uint256 actualDist;
    uint256 effectiveDistTimesHundred;
    uint256 popMoved;
    uint256 silverMoved;
    uint256 travelTime;
    uint256 movedArtifactId;
    ArrivalType arrivalType;
}

struct DFTCreateArtifactArgs {
    uint256 tokenId;
    address discoverer;
    uint256 planetId;
    ArtifactRarity rarity;
    Biome biome;
    ArtifactType artifactType;
    address owner;
    // Only used for spaceships
    address controller;
}

struct ArrivalData {
    uint256 id;
    address player;
    uint256 fromPlanet;
    uint256 toPlanet;
    uint256 popArriving;
    uint256 silverMoved;
    uint256 departureTime;
    uint256 arrivalTime;
    ArrivalType arrivalType;
    uint256 carriedArtifactId;
    uint256 distance;
}

struct PlanetDefaultStats {
    string label;
    uint256 populationCap;
    uint256 populationGrowth;
    uint256 range;
    uint256 speed;
    uint256 defense;
    uint256 silverGrowth;
    uint256 silverCap;
    uint256 barbarianPercentage;
}

struct Upgrade {
    uint256 popCapMultiplier;
    uint256 popGroMultiplier;
    uint256 rangeMultiplier;
    uint256 speedMultiplier;
    uint256 defMultiplier;
}

// for NFTs
enum ArtifactType {
    Unknown,
    Monolith,
    Colossus,
    Spaceship,
    Pyramid,
    Wormhole,
    PlanetaryShield,
    PhotoidCannon,
    BloomFilter,
    BlackDomain,
    ShipMothership,
    ShipCrescent,
    ShipWhale,
    ShipGear,
    ShipTitan
}

enum ArtifactRarity {Unknown, Common, Rare, Epic, Legendary, Mythic}

// for NFTs
struct Artifact {
    bool isInitialized;
    uint256 id;
    uint256 planetDiscoveredOn;
    ArtifactRarity rarity;
    Biome planetBiome;
    uint256 mintedAtTimestamp;
    address discoverer;
    ArtifactType artifactType;
    // an artifact is 'activated' iff lastActivated > lastDeactivated
    uint256 activations;
    uint256 lastActivated;
    uint256 lastDeactivated;
    uint256 wormholeTo; // location id
    address controller; // space ships can be controlled regardless of which planet they're on
}

// for artifact getters
struct ArtifactWithMetadata {
    Artifact artifact;
    Upgrade upgrade;
    Upgrade timeDelayedUpgrade; // for photoid canons specifically.
    address owner;
    uint256 locationId; // 0 if planet is not deposited into contract or is on a voyage
    uint256 voyageId; // 0 is planet is not deposited into contract or is on a planet
}

enum Biome {
    Unknown,
    Ocean,
    Forest,
    Grassland,
    Tundra,
    Swamp,
    Desert,
    Ice,
    Wasteland,
    Lava,
    Corrupted
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Library imports
import {ABDKMath64x64} from "../vendor/libraries/ABDKMath64x64.sol";

// Storage imports
import {LibStorage, GameStorage} from "./LibStorage.sol";

// Type imports
import {
    Planet,
    PlanetExtendedInfo,
    PlanetExtendedInfo2,
    PlanetType,
    PlanetEventMetadata,
    PlanetEventType,
    ArrivalData,
    ArrivalType,
    Artifact
} from "../DFTypes.sol";

library LibLazyUpdate {
    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function _updateSilver(
        uint256 updateToTime,
        Planet memory planet,
        PlanetExtendedInfo memory planetExtendedInfo
    ) private pure {
        // This function should never be called directly and should only be called
        // by the refresh planet function. This require is in place to make sure
        // no one tries to updateSilver on non silver producing planet.
        require(
            planet.planetType == PlanetType.SILVER_MINE,
            "Can only update silver on silver producing planet"
        );
        if (planet.owner == address(0)) {
            // unowned planet doesn't gain silver
            return;
        }

        if (planet.silver < planet.silverCap) {
            uint256 _timeDiff = updateToTime - planetExtendedInfo.lastUpdated;
            uint256 _silverMined = planet.silverGrowth * _timeDiff;

            uint256 _maxSilver = planet.silverCap;
            uint256 _currentSilver = planet.silver + _silverMined;
            planet.silver = _maxSilver < _currentSilver ? _maxSilver : _currentSilver;
        }
    }

    function _updatePopulation(
        uint256 updateToTime,
        Planet memory planet,
        PlanetExtendedInfo memory planetExtendedInfo,
        PlanetExtendedInfo2 memory planetExtendedInfo2
    ) private pure {
        if (planet.owner == address(0)) {
            // unowned planet doesn't increase in population
            return;
        }

        int128 _timeElapsed =
            ABDKMath64x64.sub(
                ABDKMath64x64.fromUInt(updateToTime),
                ABDKMath64x64.fromUInt(planetExtendedInfo.lastUpdated)
            );

        int128 _one = ABDKMath64x64.fromUInt(1);

        int128 _denominator =
            ABDKMath64x64.add(
                ABDKMath64x64.mul(
                    ABDKMath64x64.exp(
                        ABDKMath64x64.div(
                            ABDKMath64x64.mul(
                                ABDKMath64x64.mul(
                                    ABDKMath64x64.fromInt(-4),
                                    ABDKMath64x64.fromUInt(planet.populationGrowth)
                                ),
                                _timeElapsed
                            ),
                            ABDKMath64x64.fromUInt(planet.populationCap)
                        )
                    ),
                    ABDKMath64x64.sub(
                        ABDKMath64x64.div(
                            ABDKMath64x64.fromUInt(planet.populationCap),
                            ABDKMath64x64.fromUInt(planet.population)
                        ),
                        _one
                    )
                ),
                _one
            );

        uint256 newPopulation =
            ABDKMath64x64.toUInt(
                ABDKMath64x64.div(ABDKMath64x64.fromUInt(planet.populationCap), _denominator)
            );

        // If paused, no energy growth
        if (planetExtendedInfo2.pausers > 0 && newPopulation > planet.population) {
            return;
        }

        planet.population = newPopulation;

        // quasars have 0 energy growth, so they have 0 energy decay as well
        // so don't allow them to become overful
        if (planet.planetType == PlanetType.SILVER_BANK || planetExtendedInfo2.pausers > 0) {
            if (planet.population > planet.populationCap) {
                planet.population = planet.populationCap;
            }
        }
    }

    function updatePlanet(
        uint256 updateToTime,
        Planet memory planet,
        PlanetExtendedInfo memory planetExtendedInfo,
        PlanetExtendedInfo2 memory planetExtendedInfo2
    )
        public
        pure
        returns (
            Planet memory,
            PlanetExtendedInfo memory,
            PlanetExtendedInfo2 memory
        )
    {
        _updatePopulation(updateToTime, planet, planetExtendedInfo, planetExtendedInfo2);

        if (planet.planetType == PlanetType.SILVER_MINE) {
            _updateSilver(updateToTime, planet, planetExtendedInfo);
        }

        planetExtendedInfo.lastUpdated = updateToTime;

        return (planet, planetExtendedInfo, planetExtendedInfo2);
    }

    // assumes that the planet last updated time is equal to the arrival time trigger
    function applyArrival(
        Planet memory planet,
        PlanetExtendedInfo2 memory planetExtendedInfo2,
        ArrivalData memory arrival
    ) private pure returns (uint256 newArtifactOnPlanet, Planet memory) {
        // checks whether the planet is owned by the player sending ships
        if (arrival.player == planet.owner) {
            // simply increase the population if so
            planet.population = planet.population + arrival.popArriving;
        } else {
            if (arrival.arrivalType == ArrivalType.Wormhole) {
                // if this is a wormhole arrival to a planet that isn't owned by the initiator of
                // the move, then don't move any energy
            } else if (planet.population > (arrival.popArriving * 100) / planet.defense) {
                // handles if the planet population is bigger than the arriving ships
                // simply reduce the amount of planet population by the arriving ships
                planet.population =
                    planet.population -
                    ((arrival.popArriving * 100) / planet.defense);
            } else {
                // handles if the planet population is equal or less the arriving ships
                // reduce the arriving ships amount with the current population and the
                // result is the new population of the planet now owned by the attacking
                // player

                /**
                  This is the zero address so that ships moving to an unowned planet with
                  no barbarians don't cause the planet to be conquered by the ship's controller.
                 */
                planet.owner = arrival.player == address(0) ? planet.owner : arrival.player;
                planet.population =
                    arrival.popArriving -
                    ((planet.population * planet.defense) / 100);
                if (planet.population == 0) {
                    // make sure pop is never 0
                    planet.population = 1;
                }
            }
        }

        // quasars have 0 energy growth, so they have 0 energy decay as well
        // so don't allow them to become overful
        if (planet.planetType == PlanetType.SILVER_BANK || planetExtendedInfo2.pausers > 0) {
            if (planet.population > planet.populationCap) {
                planet.population = planet.populationCap;
            }
        }

        uint256 _maxSilver = planet.silverCap;
        uint256 _nextSilver = planet.silver + arrival.silverMoved;
        planet.silver = _maxSilver < _nextSilver ? _maxSilver : _nextSilver;

        return (arrival.carriedArtifactId, planet);
    }

    function applyPendingEvents(
        uint256 currentTimestamp,
        Planet memory planet,
        PlanetExtendedInfo memory planetExtendedInfo,
        PlanetExtendedInfo2 memory planetExtendedInfo2,
        PlanetEventMetadata[] memory events
    )
        public
        view
        returns (
            Planet memory,
            PlanetExtendedInfo memory,
            PlanetExtendedInfo2 memory,
            uint256[24] memory
        )
    {
        // first 12 are event ids to remove
        // last 12 are artifact ids that are new on the planet
        uint256[24] memory eventIdsAndArtifacts;

        uint256 numEventsToRemove = 0;
        uint256 numNewArtifactsOnPlanet = 0;
        uint256 earliestEventTime = 0;
        uint256 earliestEventIndex = 0;

        do {
            if (events.length == 0 || planetExtendedInfo.destroyed) {
                break;
            }

            // set to to the upperbound of uint256
            earliestEventTime = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

            // loops through the array and find the earliest event time that hasn't already been applied
            for (uint256 i = 0; i < events.length; i++) {
                if (events[i].timeTrigger < earliestEventTime) {
                    bool shouldApply = true;

                    // checks if this event has already been applied.
                    for (
                        uint256 alreadyRemovedIdx = 0;
                        alreadyRemovedIdx < numEventsToRemove;
                        alreadyRemovedIdx++
                    ) {
                        if (eventIdsAndArtifacts[alreadyRemovedIdx] == events[i].id) {
                            shouldApply = false;
                            break;
                        }
                    }

                    if (shouldApply) {
                        earliestEventTime = events[i].timeTrigger;
                        earliestEventIndex = i;
                    }
                }
            }

            // only process the event if it occurs before the current time and the timeTrigger is not 0
            // which comes from uninitialized PlanetEventMetadata
            if (
                events[earliestEventIndex].timeTrigger <= currentTimestamp &&
                earliestEventTime !=
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            ) {
                (planet, planetExtendedInfo, planetExtendedInfo2) = updatePlanet(
                    events[earliestEventIndex].timeTrigger,
                    planet,
                    planetExtendedInfo,
                    planetExtendedInfo2
                );

                if (events[earliestEventIndex].eventType == PlanetEventType.ARRIVAL) {
                    eventIdsAndArtifacts[numEventsToRemove++] = events[earliestEventIndex].id;

                    uint256 newArtifactId;
                    (newArtifactId, planet) = applyArrival(
                        planet,
                        planetExtendedInfo2,
                        gs().planetArrivals[events[earliestEventIndex].id]
                    );

                    if (newArtifactId != 0) {
                        eventIdsAndArtifacts[12 + numNewArtifactsOnPlanet++] = newArtifactId;
                    }
                }
            }
        } while (earliestEventTime <= currentTimestamp);

        return (planet, planetExtendedInfo, planetExtendedInfo2, eventIdsAndArtifacts);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Type imports
import {
    Planet,
    PlanetExtendedInfo,
    PlanetExtendedInfo2,
    PlanetEventMetadata,
    PlanetDefaultStats,
    Upgrade,
    RevealedCoords,
    Player,
    ArrivalData,
    Artifact
} from "../DFTypes.sol";

struct WhitelistStorage {
    bool enabled;
    uint256 drip;
    mapping(address => bool) allowedAccounts;
    mapping(bytes32 => bool) allowedKeyHashes;
    address[] allowedAccountsArray;
}

struct GameStorage {
    // Contract housekeeping
    address diamondAddress;
    // admin controls
    bool paused;
    uint256 TOKEN_MINT_END_TIMESTAMP;
    uint256 planetLevelsCount;
    uint256[] planetLevelThresholds;
    uint256[] cumulativeRarities;
    uint256[] initializedPlanetCountByLevel;
    // Game world state
    uint256[] planetIds;
    uint256[] revealedPlanetIds;
    address[] playerIds;
    uint256 worldRadius;
    uint256 planetEventsCount;
    uint256 miscNonce;
    mapping(uint256 => Planet) planets;
    mapping(uint256 => RevealedCoords) revealedCoords;
    mapping(uint256 => PlanetExtendedInfo) planetsExtendedInfo;
    mapping(uint256 => PlanetExtendedInfo2) planetsExtendedInfo2;
    mapping(uint256 => uint256) artifactIdToPlanetId;
    mapping(uint256 => uint256) artifactIdToVoyageId;
    mapping(address => Player) players;
    // maps location id to planet events array
    mapping(uint256 => PlanetEventMetadata[]) planetEvents;
    // maps event id to arrival data
    mapping(uint256 => ArrivalData) planetArrivals;
    mapping(uint256 => uint256[]) planetArtifacts;
    // Artifact stuff
    mapping(uint256 => Artifact) artifacts;
    // Capture Zones
    uint256 nextChangeBlock;
}

// Game config
struct GameConstants {
    bool ADMIN_CAN_ADD_PLANETS;
    bool WORLD_RADIUS_LOCKED;
    uint256 WORLD_RADIUS_MIN;
    uint256 MAX_NATURAL_PLANET_LEVEL;
    uint256 TIME_FACTOR_HUNDREDTHS; // speedup/slowdown game
    uint256 PERLIN_THRESHOLD_1;
    uint256 PERLIN_THRESHOLD_2;
    uint256 PERLIN_THRESHOLD_3;
    uint256 INIT_PERLIN_MIN;
    uint256 INIT_PERLIN_MAX;
    uint256 SPAWN_RIM_AREA;
    uint256 BIOME_THRESHOLD_1;
    uint256 BIOME_THRESHOLD_2;
    uint256[10] PLANET_LEVEL_THRESHOLDS;
    uint256 PLANET_RARITY;
    bool PLANET_TRANSFER_ENABLED;
    uint256 PHOTOID_ACTIVATION_DELAY;
    uint256 LOCATION_REVEAL_COOLDOWN;
    uint8[5][10][4] PLANET_TYPE_WEIGHTS; // spaceType (enum 0-3) -> planetLevel (0-9) -> planetType (enum 0-4)
    uint256 SILVER_SCORE_VALUE;
    uint256[6] ARTIFACT_POINT_VALUES;
    // Space Junk
    bool SPACE_JUNK_ENABLED;
    /**
      Total amount of space junk a player can take on.
      This can be overridden at runtime by updating
      this value for a specific player in storage.
    */
    uint256 SPACE_JUNK_LIMIT;
    /**
      The amount of junk that each level of planet
      gives the player when moving to it for the
      first time.
    */
    uint256[10] PLANET_LEVEL_JUNK;
    /**
      The speed boost a movement receives when abandoning
      a planet.
    */
    uint256 ABANDON_SPEED_CHANGE_PERCENT;
    /**
      The range boost a movement receives when abandoning
      a planet.
    */
    uint256 ABANDON_RANGE_CHANGE_PERCENT;
    // Capture Zones
    uint256 GAME_START_BLOCK;
    bool CAPTURE_ZONES_ENABLED;
    uint256 CAPTURE_ZONE_COUNT;
    uint256 CAPTURE_ZONE_CHANGE_BLOCK_INTERVAL;
    uint256 CAPTURE_ZONE_RADIUS;
    uint256[10] CAPTURE_ZONE_PLANET_LEVEL_SCORE;
    uint256 CAPTURE_ZONE_HOLD_BLOCKS_REQUIRED;
    uint256 CAPTURE_ZONES_PER_5000_WORLD_RADIUS;
}

// SNARK keys and perlin params
struct SnarkConstants {
    bool DISABLE_ZK_CHECKS;
    uint256 PLANETHASH_KEY;
    uint256 SPACETYPE_KEY;
    uint256 BIOMEBASE_KEY;
    bool PERLIN_MIRROR_X;
    bool PERLIN_MIRROR_Y;
    uint256 PERLIN_LENGTH_SCALE; // must be a power of two up to 8192
}

/**
 * All of Dark Forest's game storage is stored in a single GameStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "darkforest.game.storage")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.gameStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.gameStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the game
    bytes32 constant GAME_STORAGE_POSITION = keccak256("darkforest.storage.game");
    bytes32 constant WHITELIST_STORAGE_POSITION = keccak256("darkforest.storage.whitelist");
    // Constants are structs where the data gets configured on game initialization
    bytes32 constant GAME_CONSTANTS_POSITION = keccak256("darkforest.constants.game");
    bytes32 constant SNARK_CONSTANTS_POSITION = keccak256("darkforest.constants.snarks");
    bytes32 constant PLANET_DEFAULT_STATS_POSITION =
        keccak256("darkforest.constants.planetDefaultStats");
    bytes32 constant UPGRADE_POSITION = keccak256("darkforest.constants.upgrades");

    function gameStorage() internal pure returns (GameStorage storage gs) {
        bytes32 position = GAME_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function whitelistStorage() internal pure returns (WhitelistStorage storage ws) {
        bytes32 position = WHITELIST_STORAGE_POSITION;
        assembly {
            ws.slot := position
        }
    }

    function gameConstants() internal pure returns (GameConstants storage gc) {
        bytes32 position = GAME_CONSTANTS_POSITION;
        assembly {
            gc.slot := position
        }
    }

    function snarkConstants() internal pure returns (SnarkConstants storage sc) {
        bytes32 position = SNARK_CONSTANTS_POSITION;
        assembly {
            sc.slot := position
        }
    }

    function planetDefaultStats() internal pure returns (PlanetDefaultStats[] storage pds) {
        bytes32 position = PLANET_DEFAULT_STATS_POSITION;
        assembly {
            pds.slot := position
        }
    }

    function upgrades() internal pure returns (Upgrade[4][3] storage upgrades) {
        bytes32 position = UPGRADE_POSITION;
        assembly {
            upgrades.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.gameStorage()` to just `gs()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function gs() internal pure returns (GameStorage storage) {
        return LibStorage.gameStorage();
    }

    function ws() internal pure returns (WhitelistStorage storage) {
        return LibStorage.whitelistStorage();
    }

    function gameConstants() internal pure returns (GameConstants storage) {
        return LibStorage.gameConstants();
    }

    function snarkConstants() internal pure returns (SnarkConstants storage) {
        return LibStorage.snarkConstants();
    }

    function planetDefaultStats() internal pure returns (PlanetDefaultStats[] storage) {
        return LibStorage.planetDefaultStats();
    }

    function upgrades() internal pure returns (Upgrade[4][3] storage) {
        return LibStorage.upgrades();
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/**
 * Vendored on December 23, 2021 from:
 * https://github.com/abdk-consulting/abdk-libraries-solidity/blob/d8817cb/ABDKMath64x64.sol
 */
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}